-- =============================================================================
-- PAR: 03 - Generate Synthetic Data (SQL GENERATOR)
-- Load order: reference dims → entity dims → facts
-- Script 04 (Faker) runs AFTER this to populate PAR_CONTACTS
-- =============================================================================

USE DATABASE CUSTOMER_DEMOS;
USE SCHEMA PAR;
USE WAREHOUSE PAR_WH;

-- ---------------------------------------------------------------------------
-- 1. PAR_STATES (50 rows)
-- ---------------------------------------------------------------------------

INSERT INTO PAR_STATES (STATE_ABBR, STATE_NAME, REGION) VALUES
  ('AL','Alabama','Southeast'),('AK','Alaska','West'),('AZ','Arizona','Southwest'),
  ('AR','Arkansas','Southeast'),('CA','California','West'),('CO','Colorado','Southwest'),
  ('CT','Connecticut','Northeast'),('DE','Delaware','Northeast'),('FL','Florida','Southeast'),
  ('GA','Georgia','Southeast'),('HI','Hawaii','West'),('ID','Idaho','West'),
  ('IL','Illinois','Midwest'),('IN','Indiana','Midwest'),('IA','Iowa','Midwest'),
  ('KS','Kansas','Midwest'),('KY','Kentucky','Southeast'),('LA','Louisiana','Southeast'),
  ('ME','Maine','Northeast'),('MD','Maryland','Northeast'),('MA','Massachusetts','Northeast'),
  ('MI','Michigan','Midwest'),('MN','Minnesota','Midwest'),('MS','Mississippi','Southeast'),
  ('MO','Missouri','Midwest'),('MT','Montana','West'),('NE','Nebraska','Midwest'),
  ('NV','Nevada','West'),('NH','New Hampshire','Northeast'),('NJ','New Jersey','Northeast'),
  ('NM','New Mexico','Southwest'),('NY','New York','Northeast'),('NC','North Carolina','Southeast'),
  ('ND','North Dakota','Midwest'),('OH','Ohio','Midwest'),('OK','Oklahoma','Southwest'),
  ('OR','Oregon','West'),('PA','Pennsylvania','Northeast'),('RI','Rhode Island','Northeast'),
  ('SC','South Carolina','Southeast'),('SD','South Dakota','Midwest'),('TN','Tennessee','Southeast'),
  ('TX','Texas','Southwest'),('UT','Utah','West'),('VT','Vermont','Northeast'),
  ('VA','Virginia','Southeast'),('WA','Washington','West'),('WV','West Virginia','Southeast'),
  ('WI','Wisconsin','Midwest'),('WY','Wyoming','West');

-- ---------------------------------------------------------------------------
-- 2. PAR_DISTRICT_TIERS (4 rows)
-- ---------------------------------------------------------------------------

INSERT INTO PAR_DISTRICT_TIERS (TIER_NAME, MIN_STUDENTS, MAX_STUDENTS, MIN_ARR, MAX_ARR) VALUES
  ('SMB',         200,   2000,    8000,   30000),
  ('Mid-Market', 2001,  10000,   30000,  120000),
  ('Enterprise', 10001, 50000,  120000,  500000),
  ('Strategic',  50001, 500000, 500000, 2000000);

-- ---------------------------------------------------------------------------
-- 3. PAR_PRODUCT_MODULES (8 rows)
-- ---------------------------------------------------------------------------

INSERT INTO PAR_PRODUCT_MODULES (MODULE_NAME, DESCRIPTION) VALUES
  ('Core Communications',       'Two-way messaging, newsletters, and direct messaging between school and families'),
  ('Attendance Management',     'Automated attendance alerts, intervention workflows, and chronic absenteeism tracking'),
  ('Mass Notifications',        'District-wide emergency alerts, mass notifications with multi-channel delivery'),
  ('School Websites',           'Accessible, ADA-compliant school and district website builder'),
  ('Payments & Digital Forms',  'Online payments for activities, lunch, and fees with digital form collection'),
  ('Virtual Phone',             'School-branded virtual phone numbers with call logging and transcription'),
  ('Classroom Tools',           'Teacher-to-family communication, class updates, and assignment notifications'),
  ('ParentSquare Intelligence', 'AI-powered engagement insights, Contactability benchmarks, and message optimization');

-- ---------------------------------------------------------------------------
-- 4. PAR_DISTRICTS (500 rows)
-- Correlated: tier → ARR, student count, products, health, churn
-- ---------------------------------------------------------------------------

INSERT INTO PAR_DISTRICTS (
    DISTRICT_NAME, STATE_ABBR, REGION, TIER,
    STUDENT_COUNT, FAMILY_COUNT, CONTRACT_START_DATE, RENEWAL_DATE,
    ARR, PRODUCTS_COUNT,
    ATTENDANCE_MODULE, WEBSITE_MODULE, PAYMENTS_MODULE, MASS_ALERTS_MODULE, INTELLIGENCE_MODULE,
    CONTACTABILITY_SCORE, FAMILY_ENGAGEMENT_SCORE, HEALTH_SCORE, CHURN_RISK_SCORE,
    ACCOUNT_MANAGER, IS_ACTIVE
)
WITH base AS (
    SELECT
        SEQ4() + 1                          AS rn,
        UNIFORM(1, 100, RANDOM())           AS tier_roll,
        UNIFORM(1, 100, RANDOM())           AS health_roll,
        UNIFORM(1, 100, RANDOM())           AS products_roll,
        UNIFORM(0, 730, RANDOM())           AS days_ago_start,
        UNIFORM(1, 50,  RANDOM())           AS state_idx
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
),
tiers AS (
    SELECT
        rn, tier_roll, health_roll, products_roll, days_ago_start, state_idx,
        -- Realistic district tier skew: most are SMB/Mid-Market
        CASE
            WHEN tier_roll <= 45 THEN 'SMB'
            WHEN tier_roll <= 75 THEN 'Mid-Market'
            WHEN tier_roll <= 92 THEN 'Enterprise'
            ELSE                      'Strategic'
        END AS tier
    FROM base
),
enriched AS (
    SELECT
        rn, tier, health_roll, products_roll, days_ago_start, state_idx,
        CASE tier
            WHEN 'SMB'         THEN ROUND(UNIFORM(200,   2000,   RANDOM()))
            WHEN 'Mid-Market'  THEN ROUND(UNIFORM(2001,  10000,  RANDOM()))
            WHEN 'Enterprise'  THEN ROUND(UNIFORM(10001, 50000,  RANDOM()))
            ELSE                    ROUND(UNIFORM(50001, 300000, RANDOM()))
        END AS student_count,
        CASE tier
            WHEN 'SMB'         THEN ROUND(UNIFORM(8000,    30000,   RANDOM()), -2)
            WHEN 'Mid-Market'  THEN ROUND(UNIFORM(30000,   120000,  RANDOM()), -2)
            WHEN 'Enterprise'  THEN ROUND(UNIFORM(120000,  500000,  RANDOM()), -2)
            ELSE                    ROUND(UNIFORM(500000, 2000000, RANDOM()), -2)
        END AS arr,
        -- Products: more modules for larger tiers
        CASE
            WHEN products_roll <= 50 THEN 1
            WHEN products_roll <= 75 THEN 2
            WHEN products_roll <= 88 THEN 3
            WHEN products_roll <= 95 THEN 4
            ELSE                          5
        END +
        CASE tier
            WHEN 'SMB'        THEN 0
            WHEN 'Mid-Market' THEN 1
            WHEN 'Enterprise' THEN 2
            ELSE                   3
        END AS products_count,
        -- Health score: higher tiers trend healthier; health_roll adds variance
        GREATEST(20, LEAST(98,
            CASE tier
                WHEN 'SMB'        THEN 50 + health_roll * 0.3
                WHEN 'Mid-Market' THEN 55 + health_roll * 0.3
                WHEN 'Enterprise' THEN 60 + health_roll * 0.3
                ELSE                   65 + health_roll * 0.3
            END
        )) AS health_score
    FROM tiers
)
SELECT
    -- District name: "City/Town Unified School District" pattern
    CONCAT(
        CASE UNIFORM(1,6,RANDOM())
            WHEN 1 THEN ARRAY_CONSTRUCT(
                'Riverside','Lakewood','Greenfield','Maplewood','Sunnydale',
                'Oakdale','Pinecrest','Cedar Falls','Willowbrook','Elmwood'
            )[UNIFORM(0,9,RANDOM())]::VARCHAR
            WHEN 2 THEN ARRAY_CONSTRUCT(
                'Mountain View','Silver Lake','Blue Ridge','Sunset Hills','Prairie View',
                'Valley Ridge','Stone Bridge','Harbor Light','Clear Creek','Twin Pines'
            )[UNIFORM(0,9,RANDOM())]::VARCHAR
            WHEN 3 THEN ARRAY_CONSTRUCT(
                'Lincoln','Jefferson','Roosevelt','Washington','Madison',
                'Franklin','Adams','Monroe','Jackson','Harrison'
            )[UNIFORM(0,9,RANDOM())]::VARCHAR
            WHEN 4 THEN ARRAY_CONSTRUCT(
                'Central','Northern','Southern','Western','Eastern',
                'United','Heritage','Liberty','Pioneer','Legacy'
            )[UNIFORM(0,9,RANDOM())]::VARCHAR
            WHEN 5 THEN ARRAY_CONSTRUCT(
                'Northwood','Southgate','Eastview','Westfield','Hillcrest',
                'Meadowbrook','Springdale','Autumn Ridge','Sunrise','Horizon'
            )[UNIFORM(0,9,RANDOM())]::VARCHAR
            ELSE ARRAY_CONSTRUCT(
                'Lakeview','Crestwood','Millbrook','Stonehaven','Creekside',
                'Whispering Pines','Red Rock','Desert Sun','Ocean View','Forest Hills'
            )[UNIFORM(0,9,RANDOM())]::VARCHAR
        END,
        CASE UNIFORM(1,3,RANDOM())
            WHEN 1 THEN ' Unified School District'
            WHEN 2 THEN ' School District'
            ELSE        ' Public Schools'
        END,
        ' #', rn::VARCHAR
    )                                          AS district_name,
    -- State: weight toward large Ed states
    CASE UNIFORM(1, 20, RANDOM())
        WHEN 1  THEN 'CA' WHEN 2  THEN 'TX' WHEN 3  THEN 'FL' WHEN 4  THEN 'NY'
        WHEN 5  THEN 'IL' WHEN 6  THEN 'PA' WHEN 7  THEN 'OH' WHEN 8  THEN 'GA'
        WHEN 9  THEN 'NC' WHEN 10 THEN 'MI' WHEN 11 THEN 'NJ' WHEN 12 THEN 'VA'
        WHEN 13 THEN 'WA' WHEN 14 THEN 'AZ' WHEN 15 THEN 'CO'
        ELSE ARRAY_CONSTRUCT(
            'AL','AR','CT','IN','IA','KS','KY','LA','MD','MA',
            'MN','MS','MO','NE','NV','NM','OR','SC','TN','WI'
        )[UNIFORM(0, 19, RANDOM())]::VARCHAR
    END                                        AS state_abbr,
    CASE
        WHEN state_abbr IN ('ME','VT','NH','MA','RI','CT','NY','NJ','PA','MD','DE') THEN 'Northeast'
        WHEN state_abbr IN ('FL','GA','SC','NC','VA','WV','AL','MS','TN','KY','AR','LA') THEN 'Southeast'
        WHEN state_abbr IN ('OH','IN','IL','MI','WI','MN','IA','MO','ND','SD','NE','KS') THEN 'Midwest'
        WHEN state_abbr IN ('TX','OK','NM','AZ','CO') THEN 'Southwest'
        ELSE 'West'
    END                                        AS region,
    tier,
    student_count,
    ROUND(student_count * UNIFORM(0.75, 0.90, RANDOM()))  AS family_count,
    DATEADD('day', -days_ago_start - 365, CURRENT_DATE()) AS contract_start_date,
    DATEADD('day', 365 - days_ago_start, CURRENT_DATE())  AS renewal_date,
    arr,
    LEAST(8, products_count)                   AS products_count,
    -- Module flags: correlated with tier/products
    (products_count >= 2)                      AS attendance_module,
    (products_count >= 3)                      AS website_module,
    (products_count >= 4)                      AS payments_module,
    (products_count >= 3 AND UNIFORM(0,1,RANDOM()) > 0.3) AS mass_alerts_module,
    (tier IN ('Enterprise','Strategic') AND UNIFORM(0,1,RANDOM()) > 0.5) AS intelligence_module,
    -- Contactability: 75-99%; lower for newer/smaller districts
    GREATEST(72, LEAST(99.5, ROUND(
        CASE tier
            WHEN 'SMB'        THEN 78 + UNIFORM(0, 15, RANDOM())
            WHEN 'Mid-Market' THEN 82 + UNIFORM(0, 12, RANDOM())
            WHEN 'Enterprise' THEN 88 + UNIFORM(0, 10, RANDOM())
            ELSE                   91 + UNIFORM(0, 8,  RANDOM())
        END, 1
    )))                                        AS contactability_score,
    -- Engagement: health-correlated
    GREATEST(18, LEAST(96, ROUND(health_score * UNIFORM(0.85, 1.05, RANDOM()), 1))) AS family_engagement_score,
    ROUND(health_score, 1)                     AS health_score,
    -- Churn risk: inverse of health; add noise
    GREATEST(2, LEAST(95, ROUND(100 - health_score + UNIFORM(-10, 10, RANDOM()), 1))) AS churn_risk_score,
    -- Account manager pool
    ARRAY_CONSTRUCT(
        'Sarah Chen','Marcus Johnson','Priya Patel','Derek Williams',
        'Amanda Torres','Kevin O''Brien','Natasha Rivera','James Kim',
        'Rachel Goldstein','Tyler Anderson'
    )[UNIFORM(0, 9, RANDOM())]::VARCHAR        AS account_manager,
    (UNIFORM(0, 100, RANDOM()) > 3)            AS is_active  -- ~97% active
FROM enriched;

-- ---------------------------------------------------------------------------
-- 5. PAR_SUBSCRIPTIONS (~12K rows — 500 districts × 24 months)
-- ---------------------------------------------------------------------------

INSERT INTO PAR_SUBSCRIPTIONS (
    DISTRICT_ID, MONTH_DATE, ARR, MRR,
    PRODUCTS_ACTIVE, PAYMENT_STATUS,
    EXPANSION_REVENUE, CHURN_REVENUE
)
WITH months AS (
    SELECT DATEADD('month', -seq_num, DATE_TRUNC('month', CURRENT_DATE())) AS month_date
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS seq_num
        FROM TABLE(GENERATOR(ROWCOUNT => 24))
    )
),
district_months AS (
    SELECT d.DISTRICT_ID, d.ARR, d.TIER, m.month_date
    FROM PAR_DISTRICTS d
    CROSS JOIN months m
    WHERE d.IS_ACTIVE = TRUE
),
with_drift AS (
    SELECT
        DISTRICT_ID, month_date, TIER,
        -- Slight ARR drift over time: recent months closer to current ARR
        ARR * (1 + (DATEDIFF('month', month_date, CURRENT_DATE()) * UNIFORM(-0.003, 0.002, RANDOM()))) AS month_arr
    FROM district_months
)
SELECT
    DISTRICT_ID,
    month_date,
    ROUND(month_arr, -2)                        AS arr,
    ROUND(month_arr / 12, 2)                    AS mrr,
    -- Products active
    CASE TIER
        WHEN 'SMB'        THEN UNIFORM(1, 2, RANDOM())
        WHEN 'Mid-Market' THEN UNIFORM(2, 4, RANDOM())
        WHEN 'Enterprise' THEN UNIFORM(3, 6, RANDOM())
        ELSE                   UNIFORM(4, 8, RANDOM())
    END                                         AS products_active,
    -- Payment status: 95% current
    CASE UNIFORM(1, 100, RANDOM())
        WHEN 1  THEN 'Grace Period'
        WHEN 2  THEN 'Overdue'
        WHEN 3  THEN 'Overdue'
        ELSE         'Current'
    END                                         AS payment_status,
    -- Expansion revenue (new modules added this month)
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 8
        THEN ROUND(UNIFORM(1000, 15000, RANDOM()) * CASE TIER
            WHEN 'SMB'        THEN 0.5
            WHEN 'Mid-Market' THEN 1.0
            WHEN 'Enterprise' THEN 2.5
            ELSE                   5.0
        END, -2)
        ELSE 0
    END                                         AS expansion_revenue,
    -- Churn revenue (modules removed)
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 2
        THEN ROUND(UNIFORM(500, 8000, RANDOM()), -2)
        ELSE 0
    END                                         AS churn_revenue
FROM with_drift;

-- ---------------------------------------------------------------------------
-- 6. PAR_MESSAGES (2,000,000 rows — primary fact table)
-- ---------------------------------------------------------------------------

INSERT INTO PAR_MESSAGES (
    DISTRICT_ID, CHANNEL, STATUS, MESSAGE_TYPE, LANGUAGE, SENT_AT, DELIVERY_MS, FAMILY_ID
)
WITH base AS (
    SELECT
        UNIFORM(1, 500, RANDOM())   AS district_id,
        UNIFORM(1, 100, RANDOM())   AS channel_roll,
        UNIFORM(1, 100, RANDOM())   AS status_roll,
        UNIFORM(1, 100, RANDOM())   AS type_roll,
        UNIFORM(1, 100, RANDOM())   AS lang_roll,
        UNIFORM(1, 730, RANDOM())   AS days_ago,
        UNIFORM(0, 86399, RANDOM()) AS time_secs,
        UNIFORM(1, 999999, RANDOM()) AS family_id
    FROM TABLE(GENERATOR(ROWCOUNT => 2000000))
),
with_channel AS (
    SELECT
        district_id, channel_roll, status_roll, type_roll, lang_roll,
        days_ago, time_secs, family_id,
        -- Channel distribution: SMS most common for K-12
        CASE
            WHEN channel_roll <= 45 THEN 'SMS'
            WHEN channel_roll <= 72 THEN 'Email'
            WHEN channel_roll <= 88 THEN 'App Notification'
            ELSE                         'Push'
        END AS channel
    FROM base
)
SELECT
    district_id,
    channel,
    -- Delivery status: correlated with channel (SMS most reliable)
    CASE channel
        WHEN 'SMS' THEN CASE
            WHEN status_roll <= 91 THEN 'Delivered'
            WHEN status_roll <= 96 THEN 'Failed'
            WHEN status_roll <= 99 THEN 'Pending'
            ELSE                        'Bounced'
        END
        WHEN 'Email' THEN CASE
            WHEN status_roll <= 87 THEN 'Delivered'
            WHEN status_roll <= 94 THEN 'Bounced'
            WHEN status_roll <= 98 THEN 'Failed'
            ELSE                        'Pending'
        END
        WHEN 'App Notification' THEN CASE
            WHEN status_roll <= 78 THEN 'Delivered'
            WHEN status_roll <= 90 THEN 'Failed'
            WHEN status_roll <= 97 THEN 'Pending'
            ELSE                        'Bounced'
        END
        ELSE CASE  -- Push
            WHEN status_roll <= 72 THEN 'Delivered'
            WHEN status_roll <= 88 THEN 'Failed'
            WHEN status_roll <= 97 THEN 'Pending'
            ELSE                        'Bounced'
        END
    END                                 AS status,
    -- Message type: attendance alerts most common
    CASE
        WHEN type_roll <= 35 THEN 'Attendance Alert'
        WHEN type_roll <= 50 THEN 'General Update'
        WHEN type_roll <= 63 THEN 'Newsletter'
        WHEN type_roll <= 73 THEN 'Event Reminder'
        WHEN type_roll <= 82 THEN 'Absence Warning'
        WHEN type_roll <= 89 THEN 'Emergency Notification'
        WHEN type_roll <= 95 THEN 'Payment Reminder'
        ELSE                       'Classroom Update'
    END                                 AS message_type,
    -- Language: English dominant, Spanish second
    CASE
        WHEN lang_roll <= 68 THEN 'English'
        WHEN lang_roll <= 84 THEN 'Spanish'
        WHEN lang_roll <= 88 THEN 'Chinese'
        WHEN lang_roll <= 91 THEN 'Vietnamese'
        WHEN lang_roll <= 93 THEN 'Tagalog'
        WHEN lang_roll <= 95 THEN 'Korean'
        WHEN lang_roll <= 97 THEN 'Arabic'
        ELSE                       'Other'
    END                                 AS language,
    DATEADD('second', -time_secs,
        DATEADD('day', -days_ago, CURRENT_TIMESTAMP()))  AS sent_at,
    -- Delivery time: faster for delivered SMS, slower/null for others
    CASE
        WHEN status_roll <= 72 THEN
            CASE channel
                WHEN 'SMS'   THEN ROUND(UNIFORM(200, 3000, RANDOM()), 0)
                WHEN 'Email' THEN ROUND(UNIFORM(500, 8000, RANDOM()), 0)
                ELSE              ROUND(UNIFORM(300, 5000, RANDOM()), 0)
            END
        ELSE NULL
    END                                 AS delivery_ms,
    family_id
FROM with_channel;

-- ---------------------------------------------------------------------------
-- 7. PAR_ATTENDANCE_EVENTS (~548K rows — 500 districts × 1096 days)
-- ---------------------------------------------------------------------------

INSERT INTO PAR_ATTENDANCE_EVENTS (
    DISTRICT_ID, RECORD_DATE, TOTAL_ENROLLED, TOTAL_PRESENT,
    ATTENDANCE_RATE, CHRONIC_ABSENT_COUNT, EXCUSED_ABSENCES, UNEXCUSED_ABSENCES
)
WITH district_days AS (
    SELECT
        d.DISTRICT_ID,
        d.STUDENT_COUNT,
        d.TIER,
        d.ATTENDANCE_MODULE,
        d.CONTRACT_START_DATE,
        DATEADD('day', -seq_val, CURRENT_DATE()) AS record_date
    FROM PAR_DISTRICTS d
    CROSS JOIN (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS seq_val
        FROM TABLE(GENERATOR(ROWCOUNT => 1096))  -- 3 years
    )
    WHERE DATEADD('day', -seq_val, CURRENT_DATE()) >= d.CONTRACT_START_DATE
      AND DATEADD('day', -seq_val, CURRENT_DATE()) <= CURRENT_DATE()
    -- school days only: Mon-Fri, exclude ~10 weeks holidays
    QUALIFY DAYOFWEEK(DATEADD('day', -seq_val, CURRENT_DATE())) BETWEEN 2 AND 6
),
with_rates AS (
    SELECT
        DISTRICT_ID, STUDENT_COUNT, TIER, ATTENDANCE_MODULE, record_date,
        -- Base attendance rate: attendance module districts trend better
        CASE
            WHEN ATTENDANCE_MODULE = TRUE THEN
                GREATEST(88, LEAST(98, ROUND(93 + UNIFORM(-3, 4, RANDOM()), 1)))
            ELSE
                GREATEST(80, LEAST(95, ROUND(89 + UNIFORM(-5, 4, RANDOM()), 1)))
        END AS att_rate
    FROM district_days
)
SELECT
    DISTRICT_ID,
    record_date,
    STUDENT_COUNT                                           AS total_enrolled,
    ROUND(STUDENT_COUNT * att_rate / 100)                  AS total_present,
    att_rate                                                AS attendance_rate,
    ROUND(STUDENT_COUNT * UNIFORM(0.08, 0.18, RANDOM()))   AS chronic_absent_count,
    ROUND(STUDENT_COUNT * (1 - att_rate/100) * UNIFORM(0.4, 0.65, RANDOM())) AS excused_absences,
    ROUND(STUDENT_COUNT * (1 - att_rate/100) * UNIFORM(0.35, 0.60, RANDOM())) AS unexcused_absences
FROM with_rates;

-- ---------------------------------------------------------------------------
-- 8. PAR_SUPPORT_TICKETS (50,000 rows)
-- ---------------------------------------------------------------------------

INSERT INTO PAR_SUPPORT_TICKETS (
    DISTRICT_ID, CATEGORY, PRIORITY, STATUS,
    CREATED_AT, RESOLVED_AT, RESOLUTION_HOURS, CSAT_SCORE, ASSIGNED_TO
)
WITH base AS (
    SELECT
        UNIFORM(1, 500, RANDOM())   AS district_id,
        UNIFORM(1, 100, RANDOM())   AS cat_roll,
        UNIFORM(1, 100, RANDOM())   AS pri_roll,
        UNIFORM(1, 100, RANDOM())   AS status_roll,
        UNIFORM(1, 100, RANDOM())   AS csat_roll,
        UNIFORM(1, 730, RANDOM())   AS days_ago,
        UNIFORM(0, 86399, RANDOM()) AS time_secs
    FROM TABLE(GENERATOR(ROWCOUNT => 50000))
),
with_priority AS (
    SELECT
        district_id, cat_roll, pri_roll, status_roll, csat_roll, days_ago, time_secs,
        CASE
            WHEN cat_roll <= 22 THEN 'Integration Issue'
            WHEN cat_roll <= 38 THEN 'Feature Request'
            WHEN cat_roll <= 52 THEN 'Bug Report'
            WHEN cat_roll <= 63 THEN 'Training Request'
            WHEN cat_roll <= 73 THEN 'Data Question'
            WHEN cat_roll <= 81 THEN 'Billing Question'
            WHEN cat_roll <= 89 THEN 'Performance Issue'
            ELSE                      'Other'
        END AS category,
        CASE
            WHEN pri_roll <= 5  THEN 'P1'
            WHEN pri_roll <= 20 THEN 'P2'
            WHEN pri_roll <= 55 THEN 'P3'
            ELSE                     'P4'
        END AS priority
    FROM base
),
resolved AS (
    SELECT
        district_id, category, priority, status_roll, csat_roll, days_ago, time_secs,
        CASE
            WHEN status_roll <= 65 THEN 'Closed'
            WHEN status_roll <= 80 THEN 'Resolved'
            WHEN status_roll <= 90 THEN 'In Progress'
            ELSE                        'Open'
        END AS status,
        -- Resolution time correlated with priority
        CASE priority
            WHEN 'P1' THEN ROUND(UNIFORM(1,   8,   RANDOM()), 1)
            WHEN 'P2' THEN ROUND(UNIFORM(4,   24,  RANDOM()), 1)
            WHEN 'P3' THEN ROUND(UNIFORM(8,   72,  RANDOM()), 1)
            ELSE           ROUND(UNIFORM(24,  168, RANDOM()), 1)
        END AS resolution_hours
    FROM with_priority
)
SELECT
    district_id,
    category,
    priority,
    status,
    DATEADD('second', -time_secs, DATEADD('day', -days_ago, CURRENT_TIMESTAMP()))  AS created_at,
    CASE WHEN status IN ('Resolved','Closed')
        THEN DATEADD('hour', resolution_hours,
             DATEADD('second', -time_secs, DATEADD('day', -days_ago, CURRENT_TIMESTAMP())))
        ELSE NULL
    END                                                                              AS resolved_at,
    CASE WHEN status IN ('Resolved','Closed') THEN resolution_hours ELSE NULL END    AS resolution_hours,
    -- CSAT: only on resolved/closed; correlated with resolution speed
    CASE WHEN status IN ('Resolved','Closed') AND csat_roll <= 80
        THEN CASE
            WHEN resolution_hours <= 8  THEN UNIFORM(4, 5, RANDOM())::NUMBER(1)
            WHEN resolution_hours <= 48 THEN UNIFORM(3, 5, RANDOM())::NUMBER(1)
            ELSE                             UNIFORM(2, 4, RANDOM())::NUMBER(1)
        END
        ELSE NULL
    END                                                                              AS csat_score,
    ARRAY_CONSTRUCT(
        'Alex Morgan','Jordan Lee','Taylor Swift','Casey Brooks','Riley Davis',
        'Morgan Walsh','Drew Chen','Sam Patel','Chris Kim','Pat Sullivan'
    )[UNIFORM(0, 9, RANDOM())]::VARCHAR                                              AS assigned_to
FROM resolved;

-- ---------------------------------------------------------------------------
-- 9. PAR_FEATURE_USAGE (500K rows — Pendo events, district-feature-month)
-- ---------------------------------------------------------------------------

INSERT INTO PAR_FEATURE_USAGE (
    DISTRICT_ID, FEATURE_NAME, MODULE, USAGE_DATE, EVENT_COUNT, ACTIVE_USERS
)
WITH features AS (
    SELECT f.feature_name, f.module_name
    FROM (VALUES
        ('Send Mass Notification',      'Mass Notifications'),
        ('Attendance Report View',      'Attendance Management'),
        ('Mark Attendance',             'Attendance Management'),
        ('Send Classroom Update',       'Classroom Tools'),
        ('View Engagement Dashboard',   'Core Communications'),
        ('Direct Message Parent',       'Core Communications'),
        ('Create Newsletter',           'Core Communications'),
        ('Edit School Website',         'School Websites'),
        ('Process Payment',             'Payments & Digital Forms'),
        ('Create Digital Form',         'Payments & Digital Forms'),
        ('Contactability Report',       'ParentSquare Intelligence'),
        ('AI Message Rewrite',          'ParentSquare Intelligence'),
        ('Virtual Phone Call',          'Virtual Phone'),
        ('Emergency Alert Send',        'Mass Notifications'),
        ('Export Attendance Data',      'Attendance Management')
    ) f(feature_name, module_name)
),
months AS (
    SELECT DATEADD('month', -seq_num, DATE_TRUNC('month', CURRENT_DATE())) AS usage_date
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS seq_num
        FROM TABLE(GENERATOR(ROWCOUNT => 24))
    )
),
combos AS (
    SELECT
        d.DISTRICT_ID, d.TIER, d.PRODUCTS_COUNT, d.STUDENT_COUNT,
        f.feature_name, f.module_name, m.usage_date,
        UNIFORM(1, 100, RANDOM()) AS usage_roll
    FROM PAR_DISTRICTS d
    CROSS JOIN features f
    CROSS JOIN months m
    -- Not all districts use all features — sample ~33% of combos
    WHERE UNIFORM(0, 100, RANDOM()) <= 33
    AND d.IS_ACTIVE = TRUE
)
SELECT
    DISTRICT_ID,
    feature_name,
    module_name,
    usage_date,
    -- Event count: bigger districts use more; tier-correlated
    ROUND(
        CASE TIER
            WHEN 'SMB'        THEN UNIFORM(5,   150,  RANDOM())
            WHEN 'Mid-Market' THEN UNIFORM(20,  800,  RANDOM())
            WHEN 'Enterprise' THEN UNIFORM(100, 4000, RANDOM())
            ELSE                   UNIFORM(500, 15000,RANDOM())
        END
    )                                                           AS event_count,
    ROUND(STUDENT_COUNT * UNIFORM(0.005, 0.06, RANDOM()))      AS active_users
FROM combos;
