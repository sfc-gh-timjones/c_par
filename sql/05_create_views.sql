-- =============================================================================
-- PAR: 05 - Analytical Views (cross-system joins)
-- =============================================================================

USE DATABASE CUSTOMER_DEMOS;
USE SCHEMA PAR;
USE WAREHOUSE PAR_WH;

-- ---------------------------------------------------------------------------
-- VW_CUSTOMER_HEALTH_360
-- Joins district + subscriptions (latest month) + ticket KPIs + feature usage
-- Primary view for account health and churn risk questions
-- ---------------------------------------------------------------------------

CREATE OR REPLACE VIEW VW_CUSTOMER_HEALTH_360 AS
WITH latest_sub AS (
    SELECT DISTRICT_ID, ARR, MRR, PRODUCTS_ACTIVE, PAYMENT_STATUS,
           EXPANSION_REVENUE, CHURN_REVENUE,
           ROW_NUMBER() OVER (PARTITION BY DISTRICT_ID ORDER BY MONTH_DATE DESC) AS rn
    FROM PAR_SUBSCRIPTIONS
),
ticket_kpis AS (
    SELECT
        DISTRICT_ID,
        COUNT(*)                                                   AS total_tickets_90d,
        COUNT(CASE WHEN STATUS = 'Open' THEN 1 END)               AS open_tickets,
        ROUND(AVG(CSAT_SCORE), 2)                                  AS avg_csat,
        ROUND(AVG(CASE WHEN STATUS IN ('Resolved','Closed')
                       THEN RESOLUTION_HOURS END), 1)              AS avg_resolution_hrs
    FROM PAR_SUPPORT_TICKETS
    WHERE CREATED_AT >= DATEADD('day', -90, CURRENT_TIMESTAMP())
    GROUP BY DISTRICT_ID
),
feature_kpis AS (
    SELECT
        DISTRICT_ID,
        SUM(EVENT_COUNT)                                           AS total_events_30d,
        COUNT(DISTINCT FEATURE_NAME)                               AS distinct_features_used
    FROM PAR_FEATURE_USAGE
    WHERE USAGE_DATE >= DATEADD('month', -1, DATE_TRUNC('month', CURRENT_DATE()))
    GROUP BY DISTRICT_ID
)
SELECT
    d.DISTRICT_ID,
    d.DISTRICT_NAME,
    d.TIER,
    d.STATE_ABBR,
    d.REGION,
    d.STUDENT_COUNT,
    d.FAMILY_COUNT,
    d.ARR,
    d.RENEWAL_DATE,
    d.HEALTH_SCORE,
    d.CHURN_RISK_SCORE,
    d.CONTACTABILITY_SCORE,
    d.FAMILY_ENGAGEMENT_SCORE,
    d.PRODUCTS_COUNT,
    d.ATTENDANCE_MODULE,
    d.WEBSITE_MODULE,
    d.PAYMENTS_MODULE,
    d.MASS_ALERTS_MODULE,
    d.INTELLIGENCE_MODULE,
    d.ACCOUNT_MANAGER,
    d.IS_ACTIVE,
    DATEDIFF('day', CURRENT_DATE(), d.RENEWAL_DATE)   AS days_to_renewal,
    ls.PAYMENT_STATUS,
    ls.PRODUCTS_ACTIVE                                AS active_modules_current,
    COALESCE(tk.total_tickets_90d, 0)                 AS tickets_last_90d,
    COALESCE(tk.open_tickets, 0)                      AS open_tickets,
    tk.avg_csat,
    tk.avg_resolution_hrs,
    COALESCE(fu.total_events_30d, 0)                  AS feature_events_last_30d,
    COALESCE(fu.distinct_features_used, 0)            AS distinct_features_30d
FROM PAR_DISTRICTS d
LEFT JOIN latest_sub ls       ON d.DISTRICT_ID = ls.DISTRICT_ID AND ls.rn = 1
LEFT JOIN ticket_kpis tk      ON d.DISTRICT_ID = tk.DISTRICT_ID
LEFT JOIN feature_kpis fu     ON d.DISTRICT_ID = fu.DISTRICT_ID
WHERE d.IS_ACTIVE = TRUE;

-- ---------------------------------------------------------------------------
-- VW_MESSAGE_DELIVERY
-- Message delivery analytics by channel, district, and time period
-- ---------------------------------------------------------------------------

CREATE OR REPLACE VIEW VW_MESSAGE_DELIVERY AS
SELECT
    m.DISTRICT_ID,
    d.DISTRICT_NAME,
    d.TIER,
    d.STATE_ABBR,
    d.REGION,
    DATE_TRUNC('month', m.SENT_AT)                    AS MESSAGE_MONTH,
    m.CHANNEL,
    m.MESSAGE_TYPE,
    m.LANGUAGE,
    COUNT(*)                                           AS MESSAGES_SENT,
    COUNT(CASE WHEN m.STATUS = 'Delivered' THEN 1 END) AS MESSAGES_DELIVERED,
    COUNT(CASE WHEN m.STATUS = 'Failed'    THEN 1 END) AS MESSAGES_FAILED,
    COUNT(CASE WHEN m.STATUS = 'Bounced'   THEN 1 END) AS MESSAGES_BOUNCED,
    ROUND(COUNT(CASE WHEN m.STATUS = 'Delivered' THEN 1 END)
          * 100.0 / NULLIF(COUNT(*), 0), 2)            AS DELIVERY_RATE_PCT,
    ROUND(AVG(CASE WHEN m.STATUS = 'Delivered'
                   THEN m.DELIVERY_MS END), 0)         AS AVG_DELIVERY_MS
FROM PAR_MESSAGES m
JOIN PAR_DISTRICTS d ON m.DISTRICT_ID = d.DISTRICT_ID
GROUP BY 1,2,3,4,5,6,7,8,9;

-- ---------------------------------------------------------------------------
-- VW_ATTENDANCE_IMPACT
-- Compares attendance trends: districts with vs without attendance module
-- ---------------------------------------------------------------------------

CREATE OR REPLACE VIEW VW_ATTENDANCE_IMPACT AS
SELECT
    a.DISTRICT_ID,
    d.DISTRICT_NAME,
    d.TIER,
    d.STATE_ABBR,
    d.ATTENDANCE_MODULE,
    DATE_TRUNC('month', a.RECORD_DATE)               AS ATTENDANCE_MONTH,
    COUNT(*)                                          AS SCHOOL_DAYS,
    ROUND(AVG(a.ATTENDANCE_RATE), 2)                  AS AVG_ATTENDANCE_RATE,
    SUM(a.TOTAL_ENROLLED)                             AS TOTAL_STUDENT_DAYS_ENROLLED,
    SUM(a.TOTAL_PRESENT)                              AS TOTAL_STUDENT_DAYS_PRESENT,
    ROUND(AVG(a.CHRONIC_ABSENT_COUNT), 0)             AS AVG_CHRONIC_ABSENT,
    ROUND(SUM(a.CHRONIC_ABSENT_COUNT) * 100.0
          / NULLIF(SUM(a.TOTAL_ENROLLED), 0), 2)      AS CHRONIC_ABSENT_RATE_PCT
FROM PAR_ATTENDANCE_EVENTS a
JOIN PAR_DISTRICTS d ON a.DISTRICT_ID = d.DISTRICT_ID
WHERE d.IS_ACTIVE = TRUE
GROUP BY 1,2,3,4,5,6;

-- ---------------------------------------------------------------------------
-- VW_REVENUE_DASHBOARD
-- Monthly ARR, MRR, and NRR trends for revenue analytics
-- ---------------------------------------------------------------------------

CREATE OR REPLACE VIEW VW_REVENUE_DASHBOARD AS
WITH monthly AS (
    SELECT
        s.MONTH_DATE,
        d.TIER,
        d.STATE_ABBR,
        d.REGION,
        COUNT(DISTINCT s.DISTRICT_ID)                                 AS DISTRICTS,
        SUM(s.ARR)                                                    AS TOTAL_ARR,
        SUM(s.MRR)                                                    AS TOTAL_MRR,
        SUM(s.EXPANSION_REVENUE)                                      AS EXPANSION_REVENUE,
        SUM(s.CHURN_REVENUE)                                          AS CHURNED_REVENUE,
        COUNT(CASE WHEN s.PAYMENT_STATUS = 'Overdue' THEN 1 END)      AS OVERDUE_COUNT,
        ROUND(AVG(s.PRODUCTS_ACTIVE), 1)                              AS AVG_MODULES
    FROM PAR_SUBSCRIPTIONS s
    JOIN PAR_DISTRICTS d ON s.DISTRICT_ID = d.DISTRICT_ID
    GROUP BY 1,2,3,4
)
SELECT
    MONTH_DATE,
    TIER,
    STATE_ABBR,
    REGION,
    DISTRICTS,
    TOTAL_ARR,
    TOTAL_MRR,
    EXPANSION_REVENUE,
    CHURNED_REVENUE,
    OVERDUE_COUNT,
    AVG_MODULES,
    ROUND((TOTAL_ARR + EXPANSION_REVENUE - CHURNED_REVENUE)
          * 100.0 / NULLIF(LAG(TOTAL_ARR) OVER (
              PARTITION BY TIER ORDER BY MONTH_DATE), 0), 2)    AS NRR_PCT
FROM monthly;

-- ---------------------------------------------------------------------------
-- VW_SUPPORT_ANALYTICS
-- Support ticket health by tier and district for support team dashboards
-- ---------------------------------------------------------------------------

CREATE OR REPLACE VIEW VW_SUPPORT_ANALYTICS AS
SELECT
    t.DISTRICT_ID,
    d.DISTRICT_NAME,
    d.TIER,
    d.STATE_ABBR,
    d.HEALTH_SCORE,
    DATE_TRUNC('month', t.CREATED_AT)                AS TICKET_MONTH,
    t.CATEGORY,
    t.PRIORITY,
    t.STATUS,
    t.ASSIGNED_TO,
    COUNT(*)                                          AS TICKET_COUNT,
    ROUND(AVG(t.RESOLUTION_HOURS), 1)                AS AVG_RESOLUTION_HRS,
    ROUND(AVG(t.CSAT_SCORE), 2)                      AS AVG_CSAT,
    COUNT(CASE WHEN t.STATUS IN ('Open','In Progress') THEN 1 END) AS OPEN_COUNT,
    COUNT(CASE WHEN t.PRIORITY = 'P1' THEN 1 END)    AS P1_TICKETS,
    COUNT(CASE WHEN t.PRIORITY = 'P2' THEN 1 END)    AS P2_TICKETS
FROM PAR_SUPPORT_TICKETS t
JOIN PAR_DISTRICTS d ON t.DISTRICT_ID = d.DISTRICT_ID
GROUP BY 1,2,3,4,5,6,7,8,9,10;
