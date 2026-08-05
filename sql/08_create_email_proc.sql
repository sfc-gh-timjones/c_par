-- =============================================================================
-- PAR: 08 - Email Notification Procedure
-- =============================================================================

USE DATABASE CUSTOMER_DEMOS;
USE SCHEMA PAR;
USE WAREHOUSE PAR_WH;

CREATE NOTIFICATION INTEGRATION IF NOT EXISTS PAR_EMAIL_INTEGRATION
  TYPE = EMAIL
  ENABLED = TRUE;

CREATE OR REPLACE PROCEDURE CUSTOMER_DEMOS.PAR.SEND_EMAIL(
    TO_ADDRESS  VARCHAR,
    SUBJECT     VARCHAR,
    BODY_HTML   VARCHAR
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
AS $$
from snowflake.snowpark import Session
import snowflake.snowpark.functions as F

def run(session: Session, to_address: str, subject: str, body_html: str) -> str:
    session.sql(f"""
        CALL SYSTEM$SEND_EMAIL(
            'PAR_EMAIL_INTEGRATION',
            '{to_address}',
            '{subject.replace("'", "''")}',
            '{body_html.replace("'", "''")}',
            'text/html'
        )
    """).collect()
    return f'Email sent to {to_address}'
$$;
