-- =============================================================================
-- PAR ASSISTANT — One-Click Deployment
--
-- This script:
--   1. Creates a Git repo integration linked to GitHub
--   2. Tears down any existing demo objects
--   3. Runs all setup scripts (01 → 09) via EXECUTE IMMEDIATE FROM
--
-- Prerequisite: GIT_HUB_INTEGRATION must already exist (created in Quick Start Step 1).
--
-- Initial Build Only (before GitHub push):
--   PDFs must be PUT to the stage manually BEFORE executing script 07.
--   Run these PUT commands via SnowSQL or the tool block below, then continue:
--
--   PUT file:///path/to/ParentSquare_AI/pdfs/customer_success_playbook.pdf  @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/ParentSquare_AI/pdfs/data_privacy_ferpa_guide.pdf   @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/ParentSquare_AI/pdfs/district_onboarding_guide.pdf  @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/ParentSquare_AI/pdfs/feature_documentation.pdf      @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/ParentSquare_AI/pdfs/it_integration_guide.pdf       @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   ALTER STAGE CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE REFRESH;
--
-- Post-push: COPY FILES FROM @git_repo in script 07 handles PDFs automatically.
-- =============================================================================

USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS PAR_DEPLOY_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND   = 60
  AUTO_RESUME    = TRUE;
USE WAREHOUSE PAR_DEPLOY_WH;

CREATE DATABASE IF NOT EXISTS PAR_DEPLOY;
CREATE SCHEMA IF NOT EXISTS PAR_DEPLOY.GIT;

CREATE OR REPLACE GIT REPOSITORY PAR_DEPLOY.GIT.C_PAR_REPO
  API_INTEGRATION = GIT_HUB_INTEGRATION
  ORIGIN          = 'https://github.com/sfc-gh-timjones/c_par';
ALTER GIT REPOSITORY PAR_DEPLOY.GIT.C_PAR_REPO FETCH;

-- Teardown
EXECUTE IMMEDIATE FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/sql/99_teardown.sql;

-- Infrastructure
EXECUTE IMMEDIATE FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/sql/01_database_and_schema.sql;

-- Tables
EXECUTE IMMEDIATE FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/sql/02_create_tables.sql;

-- Synthetic data (SQL GENERATOR — runs before Faker)
EXECUTE IMMEDIATE FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/sql/03_generate_synthetic_data.sql;

-- Contacts (Faker stored proc — reads district IDs from table populated above)
EXECUTE IMMEDIATE FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/sql/04_generate_contacts_faker.sql;

-- Analytical views
EXECUTE IMMEDIATE FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/sql/05_create_views.sql;

-- Semantic view
EXECUTE IMMEDIATE FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/sql/06_create_semantic_view.sql;

-- Cortex Search (COPY FILES from repo pdfs/ + AI_PARSE_DOCUMENT + CREATE CORTEX SEARCH)
EXECUTE IMMEDIATE FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/sql/07_create_cortex_search.sql;

-- Email procedure
EXECUTE IMMEDIATE FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/sql/08_create_email_proc.sql;

-- Cortex Agent
EXECUTE IMMEDIATE FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/sql/09_create_agent.sql;

-- Cleanup deploy infra
DROP DATABASE IF EXISTS PAR_DEPLOY;
DROP WAREHOUSE IF EXISTS PAR_DEPLOY_WH;

SELECT 'PAR SI demo deployed. Open Snowflake Intelligence → PAR Assistant.' AS STATUS;
