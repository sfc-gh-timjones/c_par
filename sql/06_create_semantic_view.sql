-- =============================================================================
-- PAR: 06 - Semantic View
-- 5 logical entities: districts, messages, tickets, feature_usage, subscriptions
-- 8 VQRs covering district health, message delivery, ARR, attendance, support
-- =============================================================================

USE DATABASE CUSTOMER_DEMOS;
USE SCHEMA PAR;
USE WAREHOUSE PAR_WH;

CREATE OR REPLACE SEMANTIC VIEW PAR_SEMANTIC_VIEW
  TABLES (
    districts     AS CUSTOMER_DEMOS.PAR.PAR_DISTRICTS         PRIMARY KEY (DISTRICT_ID),
    messages      AS CUSTOMER_DEMOS.PAR.PAR_MESSAGES           PRIMARY KEY (MESSAGE_ID),
    tickets       AS CUSTOMER_DEMOS.PAR.PAR_SUPPORT_TICKETS    PRIMARY KEY (TICKET_ID),
    feature_usage AS CUSTOMER_DEMOS.PAR.PAR_FEATURE_USAGE      PRIMARY KEY (USAGE_ID),
    subscriptions AS CUSTOMER_DEMOS.PAR.PAR_SUBSCRIPTIONS      PRIMARY KEY (SUBSCRIPTION_ID),
    attendance    AS CUSTOMER_DEMOS.PAR.PAR_ATTENDANCE_EVENTS  PRIMARY KEY (ATTENDANCE_ID)
  )

  RELATIONSHIPS (
    messages(DISTRICT_ID)      REFERENCES districts,
    tickets(DISTRICT_ID)       REFERENCES districts,
    feature_usage(DISTRICT_ID) REFERENCES districts,
    subscriptions(DISTRICT_ID) REFERENCES districts,
    attendance(DISTRICT_ID)    REFERENCES districts
  )

  FACTS (
    -- Districts
    districts.arr                    AS ARR,
    districts.student_count          AS STUDENT_COUNT,
    districts.family_count           AS FAMILY_COUNT,
    districts.health_score           AS HEALTH_SCORE,
    districts.churn_risk_score       AS CHURN_RISK_SCORE,
    districts.contactability_score   AS CONTACTABILITY_SCORE,
    districts.family_engagement_score AS FAMILY_ENGAGEMENT_SCORE,
    districts.products_count         AS PRODUCTS_COUNT,

    -- Messages
    messages.delivery_ms             AS DELIVERY_MS,

    -- Tickets
    tickets.resolution_hours         AS RESOLUTION_HOURS,
    tickets.csat_score               AS CSAT_SCORE,

    -- Feature Usage
    feature_usage.event_count        AS EVENT_COUNT,
    feature_usage.active_users       AS ACTIVE_USERS,

    -- Subscriptions (note: subscription_arr is the semantic name; physical column is ARR)
    subscriptions.subscription_arr   AS ARR,
    subscriptions.mrr                AS MRR,
    subscriptions.products_active    AS PRODUCTS_ACTIVE,
    subscriptions.expansion_revenue  AS EXPANSION_REVENUE,
    subscriptions.churn_revenue      AS CHURN_REVENUE,

    -- Attendance
    attendance.total_enrolled        AS TOTAL_ENROLLED,
    attendance.total_present         AS TOTAL_PRESENT,
    attendance.attendance_rate       AS ATTENDANCE_RATE,
    attendance.chronic_absent_count  AS CHRONIC_ABSENT_COUNT
  )

  DIMENSIONS (
    -- District dimensions
    districts.district_name          AS DISTRICT_NAME,
    districts.state_abbr             AS STATE,
    districts.region                 AS REGION,
    districts.tier                   AS TIER,
    districts.renewal_date           AS RENEWAL_DATE,
    districts.account_manager        AS ACCOUNT_MANAGER,
    districts.is_active              AS IS_ACTIVE,
    districts.attendance_module      AS ATTENDANCE_MODULE,
    districts.website_module         AS WEBSITE_MODULE,
    districts.payments_module        AS PAYMENTS_MODULE,
    districts.intelligence_module    AS INTELLIGENCE_MODULE,

    -- Message dimensions
    messages.channel                 AS CHANNEL,
    messages.message_status          AS STATUS,
    messages.message_type            AS MESSAGE_TYPE,
    messages.language                AS LANGUAGE,
    messages.sent_at                 AS SENT_AT,

    -- Ticket dimensions
    tickets.ticket_category          AS CATEGORY,
    tickets.priority                 AS PRIORITY,
    tickets.ticket_status            AS STATUS,
    tickets.ticket_created_at        AS CREATED_AT,
    tickets.assigned_to              AS ASSIGNED_TO,

    -- Feature usage dimensions
    feature_usage.feature_name       AS FEATURE_NAME,
    feature_usage.module             AS MODULE,
    feature_usage.usage_date         AS USAGE_DATE,

    -- Subscription dimensions
    subscriptions.month_date         AS SUBSCRIPTION_MONTH,
    subscriptions.payment_status     AS PAYMENT_STATUS,

    -- Attendance dimensions
    attendance.record_date           AS ATTENDANCE_DATE
  )

  METRICS (
    -- District metrics
    districts.total_districts        AS COUNT(districts.DISTRICT_ID),
    districts.total_arr              AS SUM(districts.ARR),
    districts.avg_arr                AS AVG(districts.ARR),
    districts.avg_health_score       AS AVG(districts.HEALTH_SCORE),
    districts.avg_churn_risk         AS AVG(districts.CHURN_RISK_SCORE),
    districts.avg_contactability     AS AVG(districts.CONTACTABILITY_SCORE),
    districts.avg_engagement_score   AS AVG(districts.FAMILY_ENGAGEMENT_SCORE),
    districts.avg_student_count      AS AVG(districts.STUDENT_COUNT),
    districts.total_students         AS SUM(districts.STUDENT_COUNT),

    -- Message metrics
    messages.total_messages          AS COUNT(messages.MESSAGE_ID),
    messages.total_delivered         AS COUNT_IF(messages.STATUS = ''Delivered''),
    messages.total_failed            AS COUNT_IF(messages.STATUS IN (''Failed'', ''Bounced'')),
    messages.avg_delivery_ms         AS AVG(messages.DELIVERY_MS),

    -- Ticket metrics
    tickets.total_tickets            AS COUNT(tickets.TICKET_ID),
    tickets.open_tickets             AS COUNT_IF(tickets.STATUS IN (''Open'', ''In Progress'')),
    tickets.avg_resolution_hours     AS AVG(tickets.RESOLUTION_HOURS),
    tickets.avg_csat                 AS AVG(tickets.CSAT_SCORE),

    -- Feature usage metrics
    feature_usage.total_events       AS SUM(feature_usage.EVENT_COUNT),
    feature_usage.total_active_users AS SUM(feature_usage.ACTIVE_USERS),

    -- Subscription metrics
    subscriptions.total_sub_arr      AS SUM(subscriptions.ARR),
    subscriptions.total_expansion    AS SUM(subscriptions.EXPANSION_REVENUE),
    subscriptions.total_churn_rev    AS SUM(subscriptions.CHURN_REVENUE),
    subscriptions.avg_products       AS AVG(subscriptions.PRODUCTS_ACTIVE),

    -- Attendance metrics
    attendance.avg_attendance_rate   AS AVG(attendance.ATTENDANCE_RATE),
    attendance.total_present         AS SUM(attendance.TOTAL_PRESENT),
    attendance.avg_chronic_absent    AS AVG(attendance.CHRONIC_ABSENT_COUNT)
  )

  COMMENT = 'ParentSquare internal analytics — district health, messaging, revenue, attendance, and support'

  AI_SQL_GENERATION 'ParentSquare is a K-12 family engagement SaaS platform. Districts are school district customers (500 total). Messages are communications sent to families via SMS, Email, App Notification, and Push. Tiers: SMB, Mid-Market, Enterprise, Strategic (by student count and ARR). ARR is annual recurring revenue in USD. Contactability Score and Family Engagement Score are 0-100 scale. Health Score reflects overall account health; Churn Risk Score is inverse (higher = more at risk). Attendance rate is percentage present (0-100). School year runs Aug-May; fiscal year runs Aug-Jul. P1=critical, P2=high, P3=medium, P4=low for ticket priority.'

  AI_QUESTION_CATEGORIZATION 'Route questions about customer success playbooks, onboarding procedures, escalation processes, or compliance policies to the PlaybookSearch or KnowledgeBaseSearch tools instead of the Analyst.'

  AI_VERIFIED_QUERIES (

    top_districts_by_arr AS (
      QUESTION 'What are our top 10 districts by ARR?'
      SQL 'SELECT districts.DISTRICT_NAME, districts.TIER, districts.STATE_ABBR,
                  districts.ARR, districts.HEALTH_SCORE, districts.PRODUCTS_COUNT,
                  districts.RENEWAL_DATE
           FROM districts
           ORDER BY districts.ARR DESC
           LIMIT 10'
      ONBOARDING_QUESTION TRUE
    ),

    message_delivery_by_channel AS (
      QUESTION 'What is our overall message delivery rate by channel?'
      SQL 'SELECT messages.CHANNEL,
                  COUNT(messages.MESSAGE_ID)                                             AS total_messages,
                  COUNT(CASE WHEN messages.STATUS = ''Delivered'' THEN 1 END)            AS delivered,
                  ROUND(COUNT(CASE WHEN messages.STATUS = ''Delivered'' THEN 1 END)
                        * 100.0 / COUNT(messages.MESSAGE_ID), 2)                         AS delivery_rate_pct
           FROM messages
           GROUP BY messages.CHANNEL
           ORDER BY delivery_rate_pct DESC'
      ONBOARDING_QUESTION TRUE
    ),

    districts_at_churn_risk AS (
      QUESTION 'Which districts have elevated churn risk and are renewing in the next 6 months?'
      SQL 'SELECT districts.DISTRICT_NAME, districts.TIER, districts.STATE_ABBR,
                  districts.ARR, districts.HEALTH_SCORE, districts.CHURN_RISK_SCORE,
                  districts.RENEWAL_DATE, districts.ACCOUNT_MANAGER,
                  DATEDIFF(''day'', CURRENT_DATE(), districts.RENEWAL_DATE) AS days_to_renewal
           FROM districts
           WHERE districts.CHURN_RISK_SCORE >= 40
             AND DATEDIFF(''day'', CURRENT_DATE(), districts.RENEWAL_DATE) BETWEEN 0 AND 180
             AND districts.IS_ACTIVE = TRUE
           ORDER BY districts.CHURN_RISK_SCORE DESC, districts.ARR DESC'
      ONBOARDING_QUESTION TRUE
    ),

    attendance_module_impact AS (
      QUESTION 'How does average attendance rate compare between districts with and without the attendance module?'
      SQL 'SELECT districts.ATTENDANCE_MODULE,
                  COUNT(DISTINCT districts.DISTRICT_ID)    AS district_count,
                  ROUND(AVG(attendance.ATTENDANCE_RATE), 2) AS avg_attendance_rate,
                  ROUND(AVG(attendance.CHRONIC_ABSENT_COUNT), 0) AS avg_chronic_absent
           FROM districts
           JOIN attendance ON districts.DISTRICT_ID = attendance.DISTRICT_ID
           GROUP BY districts.ATTENDANCE_MODULE
           ORDER BY districts.ATTENDANCE_MODULE DESC'
    ),

    top_support_categories AS (
      QUESTION 'What are the most common support ticket categories this quarter?'
      SQL 'SELECT tickets.CATEGORY,
                  COUNT(tickets.TICKET_ID)                AS total_tickets,
                  COUNT(CASE WHEN tickets.STATUS IN (''Open'',''In Progress'') THEN 1 END) AS open_tickets,
                  ROUND(AVG(tickets.RESOLUTION_HOURS), 1)  AS avg_resolution_hrs,
                  ROUND(AVG(tickets.CSAT_SCORE), 2)         AS avg_csat
           FROM tickets
           WHERE tickets.CREATED_AT >= DATEADD(''day'', -90, CURRENT_TIMESTAMP())
           GROUP BY tickets.CATEGORY
           ORDER BY total_tickets DESC'
    ),

    feature_adoption_by_tier AS (
      QUESTION 'Which features have the highest usage among Enterprise and Strategic districts?'
      SQL 'SELECT feature_usage.FEATURE_NAME, feature_usage.MODULE,
                  districts.TIER,
                  SUM(feature_usage.EVENT_COUNT)   AS total_events,
                  COUNT(DISTINCT feature_usage.DISTRICT_ID) AS districts_using
           FROM feature_usage
           JOIN districts ON feature_usage.DISTRICT_ID = districts.DISTRICT_ID
           WHERE districts.TIER IN (''Enterprise'', ''Strategic'')
             AND feature_usage.USAGE_DATE >= DATEADD(''month'', -3, DATE_TRUNC(''month'', CURRENT_DATE()))
           GROUP BY feature_usage.FEATURE_NAME, feature_usage.MODULE, districts.TIER
           ORDER BY total_events DESC
           LIMIT 15'
    ),

    monthly_arr_trend AS (
      QUESTION 'Show total ARR trend by month for the last 12 months'
      SQL 'SELECT subscriptions.MONTH_DATE,
                  SUM(subscriptions.ARR)                        AS total_arr,
                  SUM(subscriptions.MRR)                        AS total_mrr,
                  SUM(subscriptions.EXPANSION_REVENUE)          AS expansion_revenue,
                  SUM(subscriptions.CHURN_REVENUE)              AS churn_revenue,
                  COUNT(DISTINCT subscriptions.DISTRICT_ID)     AS paying_districts
           FROM subscriptions
           WHERE subscriptions.MONTH_DATE >= DATEADD(''month'', -12, DATE_TRUNC(''month'', CURRENT_DATE()))
           GROUP BY subscriptions.MONTH_DATE
           ORDER BY subscriptions.MONTH_DATE'
    ),

    low_engagement_districts AS (
      QUESTION 'Which districts have family engagement scores below 50 and are still active?'
      SQL 'SELECT districts.DISTRICT_NAME, districts.TIER, districts.STATE_ABBR,
                  districts.FAMILY_ENGAGEMENT_SCORE, districts.CONTACTABILITY_SCORE,
                  districts.HEALTH_SCORE, districts.PRODUCTS_COUNT, districts.ARR,
                  districts.ACCOUNT_MANAGER, districts.RENEWAL_DATE
           FROM districts
           WHERE districts.FAMILY_ENGAGEMENT_SCORE < 50
             AND districts.IS_ACTIVE = TRUE
           ORDER BY districts.FAMILY_ENGAGEMENT_SCORE ASC
           LIMIT 25'
    )

  );
