-- =============================================================================
-- PAR: 04 - Generate Contacts with Faker (Snowpark Python)
-- Reads district IDs from PAR_DISTRICTS (already populated by script 03)
-- Generates ~1500 realistic, diverse district contacts
-- CREATE PROC → CALL → DROP PROC (self-contained)
-- =============================================================================

USE DATABASE CUSTOMER_DEMOS;
USE SCHEMA PAR;
USE WAREHOUSE PAR_WH;

CREATE OR REPLACE PROCEDURE PAR_GENERATE_CONTACTS(ROW_COUNT INT)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'faker', 'numpy', 'pandas')
HANDLER = 'run'
AS $$
from faker import Faker
import numpy as np
import pandas as pd
from snowflake.snowpark import Session

fake = Faker(['en_US', 'es_MX', 'zh_CN', 'vi_VN', 'ko_KR'])

def run(session: Session, row_count: int) -> str:
    district_ids = [r[0] for r in session.sql(
        "SELECT DISTRICT_ID FROM CUSTOMER_DEMOS.PAR.PAR_DISTRICTS WHERE IS_ACTIVE = TRUE"
    ).collect()]

    if not district_ids:
        return "ERROR: No districts found — run script 03 first"

    roles = np.random.choice(
        ['IT Director', 'Superintendent', 'Communications Director',
         'Data Analyst', 'Assistant Superintendent', 'Business Manager'],
        size=row_count,
        p=[0.25, 0.20, 0.25, 0.15, 0.10, 0.05]
    )

    assigned_districts = np.random.choice(district_ids, size=row_count)

    records = []
    for i in range(row_count):
        locale = np.random.choice(['en_US', 'es_MX', 'zh_CN', 'vi_VN', 'ko_KR'],
                                   p=[0.65, 0.20, 0.07, 0.05, 0.03])
        fake.seed_locale(locale)
        first = fake.first_name()
        last  = fake.last_name()
        domain = np.random.choice([
            'district.edu', 'schools.org', 'k12.edu', 'isd.edu', 'usd.edu'
        ])
        email = f"{first.lower().replace(' ', '')}.{last.lower().replace(' ', '')}{i}@{domain}"
        records.append({
            'DISTRICT_ID': int(assigned_districts[i]),
            'FIRST_NAME':  first,
            'LAST_NAME':   last,
            'EMAIL':       email,
            'ROLE':        str(roles[i]),
            'IS_PRIMARY':  bool(np.random.random() < 0.33)
        })

    df = pd.DataFrame(records)
    session.write_pandas(
        df, 'PAR_CONTACTS',
        database='CUSTOMER_DEMOS', schema='PAR',
        overwrite=True, auto_create_table=False
    )
    return f'Generated {row_count} contacts across {len(district_ids)} districts'
$$;

CALL PAR_GENERATE_CONTACTS(1500);

DROP PROCEDURE PAR_GENERATE_CONTACTS(INT);
