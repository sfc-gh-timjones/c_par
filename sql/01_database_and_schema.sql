-- =============================================================================
-- PAR: 01 - Database, Schema, and Warehouse
-- ParentSquare SI Demo
-- =============================================================================

USE ROLE ACCOUNTADMIN;

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

CREATE DATABASE IF NOT EXISTS CUSTOMER_DEMOS;
CREATE SCHEMA IF NOT EXISTS CUSTOMER_DEMOS.PAR;

CREATE OR REPLACE WAREHOUSE PAR_WH
  WAREHOUSE_SIZE    = 'XSMALL'
  AUTO_SUSPEND      = 30
  AUTO_RESUME       = TRUE
  COMMENT           = 'ParentSquare demo warehouse';

USE DATABASE CUSTOMER_DEMOS;
USE SCHEMA PAR;
USE WAREHOUSE PAR_WH;
