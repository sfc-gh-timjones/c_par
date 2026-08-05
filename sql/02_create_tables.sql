-- =============================================================================
-- PAR: 02 - Create Tables
-- Simulated sources: HubSpot (CRM), MySQL Product DB, Zendesk, Pendo, Billing
-- =============================================================================

USE DATABASE CUSTOMER_DEMOS;
USE SCHEMA PAR;
USE WAREHOUSE PAR_WH;

-- ---------------------------------------------------------------------------
-- Reference / Dimension Tables
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE PAR_STATES (
    STATE_ABBR   VARCHAR(2)  NOT NULL PRIMARY KEY,
    STATE_NAME   VARCHAR(50) NOT NULL,
    REGION       VARCHAR(20) NOT NULL   -- Northeast, Southeast, Midwest, Southwest, West
);

CREATE OR REPLACE TABLE PAR_DISTRICT_TIERS (
    TIER_ID      NUMBER      NOT NULL PRIMARY KEY AUTOINCREMENT,
    TIER_NAME    VARCHAR(20) NOT NULL,   -- SMB, Mid-Market, Enterprise, Strategic
    MIN_STUDENTS NUMBER      NOT NULL,
    MAX_STUDENTS NUMBER      NOT NULL,
    MIN_ARR      NUMBER      NOT NULL,
    MAX_ARR      NUMBER      NOT NULL
);

CREATE OR REPLACE TABLE PAR_PRODUCT_MODULES (
    MODULE_ID    NUMBER      NOT NULL PRIMARY KEY AUTOINCREMENT,
    MODULE_NAME  VARCHAR(60) NOT NULL,
    DESCRIPTION  VARCHAR(200)
);

-- ---------------------------------------------------------------------------
-- Core Entity: School Districts (HubSpot accounts / Product DB)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE PAR_DISTRICTS (
    DISTRICT_ID              NUMBER        NOT NULL PRIMARY KEY AUTOINCREMENT,
    DISTRICT_NAME            VARCHAR(100)  NOT NULL,
    STATE_ABBR               VARCHAR(2)    NOT NULL REFERENCES PAR_STATES(STATE_ABBR),
    REGION                   VARCHAR(20),
    TIER                     VARCHAR(20)   NOT NULL,  -- SMB / Mid-Market / Enterprise / Strategic
    STUDENT_COUNT            NUMBER        NOT NULL,
    FAMILY_COUNT             NUMBER        NOT NULL,
    CONTRACT_START_DATE      DATE          NOT NULL,
    RENEWAL_DATE             DATE          NOT NULL,
    ARR                      NUMBER(12,2)  NOT NULL,
    PRODUCTS_COUNT           NUMBER        NOT NULL DEFAULT 1,
    ATTENDANCE_MODULE        BOOLEAN       NOT NULL DEFAULT FALSE,
    WEBSITE_MODULE           BOOLEAN       NOT NULL DEFAULT FALSE,
    PAYMENTS_MODULE          BOOLEAN       NOT NULL DEFAULT FALSE,
    MASS_ALERTS_MODULE       BOOLEAN       NOT NULL DEFAULT FALSE,
    INTELLIGENCE_MODULE      BOOLEAN       NOT NULL DEFAULT FALSE,
    CONTACTABILITY_SCORE     NUMBER(5,2),  -- 0-100; % of families reachable
    FAMILY_ENGAGEMENT_SCORE  NUMBER(5,2),  -- 0-100; composite engagement
    HEALTH_SCORE             NUMBER(5,2),  -- 0-100; composite account health
    CHURN_RISK_SCORE         NUMBER(5,2),  -- 0-100; higher = more at risk
    ACCOUNT_MANAGER          VARCHAR(60),
    IS_ACTIVE                BOOLEAN       NOT NULL DEFAULT TRUE,
    CREATED_AT               TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------------
-- Contacts: District administrators (HubSpot contacts)
-- Populated by Faker stored proc in script 04
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE PAR_CONTACTS (
    CONTACT_ID    NUMBER        NOT NULL PRIMARY KEY AUTOINCREMENT,
    DISTRICT_ID   NUMBER        NOT NULL REFERENCES PAR_DISTRICTS(DISTRICT_ID),
    FIRST_NAME    VARCHAR(60)   NOT NULL,
    LAST_NAME     VARCHAR(60)   NOT NULL,
    EMAIL         VARCHAR(120)  NOT NULL,
    ROLE          VARCHAR(60)   NOT NULL,  -- IT Director, Superintendent, Comms Director, etc.
    IS_PRIMARY    BOOLEAN       NOT NULL DEFAULT FALSE,
    CREATED_AT    TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------------
-- Messages: Core product event table (MySQL Product DB via dbt)
-- 2M rows — simulating 10-20M/day reality at sampled demo scale
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE PAR_MESSAGES (
    MESSAGE_ID    NUMBER        NOT NULL PRIMARY KEY AUTOINCREMENT,
    DISTRICT_ID   NUMBER        NOT NULL REFERENCES PAR_DISTRICTS(DISTRICT_ID),
    CHANNEL       VARCHAR(20)   NOT NULL,  -- SMS, Email, App Notification, Push
    STATUS        VARCHAR(15)   NOT NULL,  -- Delivered, Failed, Bounced, Pending
    MESSAGE_TYPE  VARCHAR(40)   NOT NULL,  -- Attendance Alert, Emergency, Newsletter, etc.
    LANGUAGE      VARCHAR(20)   NOT NULL,  -- English, Spanish, Chinese, etc.
    SENT_AT       TIMESTAMP_NTZ NOT NULL,
    DELIVERY_MS   NUMBER(8,2),             -- milliseconds to deliver; NULL if not delivered
    FAMILY_ID     NUMBER        NOT NULL   -- anonymized family identifier
);

-- ---------------------------------------------------------------------------
-- Attendance Events: Daily district-level summaries (MySQL Product DB)
-- ~550K rows: 500 districts × ~3 school years of daily records
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE PAR_ATTENDANCE_EVENTS (
    ATTENDANCE_ID        NUMBER        NOT NULL PRIMARY KEY AUTOINCREMENT,
    DISTRICT_ID          NUMBER        NOT NULL REFERENCES PAR_DISTRICTS(DISTRICT_ID),
    RECORD_DATE          DATE          NOT NULL,
    TOTAL_ENROLLED       NUMBER        NOT NULL,
    TOTAL_PRESENT        NUMBER        NOT NULL,
    ATTENDANCE_RATE      NUMBER(5,2)   NOT NULL,  -- derived: present / enrolled * 100
    CHRONIC_ABSENT_COUNT NUMBER        NOT NULL,  -- students absent 10%+ of school year
    EXCUSED_ABSENCES     NUMBER        NOT NULL,
    UNEXCUSED_ABSENCES   NUMBER        NOT NULL
);

-- ---------------------------------------------------------------------------
-- Support Tickets: Zendesk data via Fivetran
-- 50K rows
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE PAR_SUPPORT_TICKETS (
    TICKET_ID        NUMBER        NOT NULL PRIMARY KEY AUTOINCREMENT,
    DISTRICT_ID      NUMBER        NOT NULL REFERENCES PAR_DISTRICTS(DISTRICT_ID),
    CATEGORY         VARCHAR(40)   NOT NULL,  -- Integration Issue, Bug Report, Training, etc.
    PRIORITY         VARCHAR(5)    NOT NULL,  -- P1, P2, P3, P4
    STATUS           VARCHAR(20)   NOT NULL,  -- Open, In Progress, Resolved, Closed
    CREATED_AT       TIMESTAMP_NTZ NOT NULL,
    RESOLVED_AT      TIMESTAMP_NTZ,           -- NULL if still open
    RESOLUTION_HOURS NUMBER(8,2),             -- NULL if still open
    CSAT_SCORE       NUMBER(1),               -- 1-5; NULL if unrated
    ASSIGNED_TO      VARCHAR(60)   NOT NULL
);

-- ---------------------------------------------------------------------------
-- Feature Usage: Pendo product analytics events via Fivetran
-- 500K rows: district-feature-month level aggregates
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE PAR_FEATURE_USAGE (
    USAGE_ID      NUMBER   NOT NULL PRIMARY KEY AUTOINCREMENT,
    DISTRICT_ID   NUMBER   NOT NULL REFERENCES PAR_DISTRICTS(DISTRICT_ID),
    FEATURE_NAME  VARCHAR(60) NOT NULL,
    MODULE        VARCHAR(40) NOT NULL,
    USAGE_DATE    DATE     NOT NULL,  -- first of month
    EVENT_COUNT   NUMBER   NOT NULL,
    ACTIVE_USERS  NUMBER   NOT NULL
);

-- ---------------------------------------------------------------------------
-- Subscriptions: Monthly ARR snapshots (internal billing system)
-- ~12K rows: 500 districts × 24 months
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE PAR_SUBSCRIPTIONS (
    SUBSCRIPTION_ID   NUMBER        NOT NULL PRIMARY KEY AUTOINCREMENT,
    DISTRICT_ID       NUMBER        NOT NULL REFERENCES PAR_DISTRICTS(DISTRICT_ID),
    MONTH_DATE        DATE          NOT NULL,  -- first of month
    ARR               NUMBER(12,2)  NOT NULL,
    MRR               NUMBER(10,2)  NOT NULL,
    PRODUCTS_ACTIVE   NUMBER        NOT NULL,
    PAYMENT_STATUS    VARCHAR(20)   NOT NULL,  -- Current, Overdue, Grace Period
    EXPANSION_REVENUE NUMBER(10,2)  NOT NULL DEFAULT 0,
    CHURN_REVENUE     NUMBER(10,2)  NOT NULL DEFAULT 0
);
