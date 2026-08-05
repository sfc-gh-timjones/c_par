-- =============================================================================
-- PAR: 07 - Cortex Search Services
-- Two services backed by PDF documents parsed with AI_PARSE_DOCUMENT:
--   PAR_PLAYBOOK_SEARCH  → customer_success_playbook.pdf, district_onboarding_guide.pdf
--   PAR_KB_SEARCH        → data_privacy_ferpa_guide.pdf, feature_documentation.pdf, it_integration_guide.pdf
--
-- Initial Build (before GitHub repo exists):
--   PDFs must already be PUT to PAR_DOCS_STAGE before running this script.
--   Use snowflake_sql_execute with the PUT commands below (run once):
--
--   PUT file:///path/to/pdfs/customer_success_playbook.pdf  @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/pdfs/data_privacy_ferpa_guide.pdf   @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/pdfs/district_onboarding_guide.pdf  @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/pdfs/feature_documentation.pdf      @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   PUT file:///path/to/pdfs/it_integration_guide.pdf       @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
--   ALTER STAGE CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE REFRESH;
--
-- Post-GitHub rebuild: COPY FILES FROM @git_repo replaces manual PUT.
-- =============================================================================

USE DATABASE CUSTOMER_DEMOS;
USE SCHEMA PAR;
USE WAREHOUSE PAR_WH;

-- ---------------------------------------------------------------------------
-- Stage for all PDFs
-- ---------------------------------------------------------------------------

CREATE OR REPLACE STAGE PAR_DOCS_STAGE
  DIRECTORY = (ENABLE = TRUE)
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
  COMMENT = 'ParentSquare document library for Cortex Search';

-- Copy from Git repo (post-GitHub push; no-op on initial build — PDFs PUT above)
COPY FILES
INTO @CUSTOMER_DEMOS.PAR.PAR_DOCS_STAGE/
FROM @PAR_DEPLOY.GIT.C_PAR_REPO/branches/main/pdfs/
PATTERN = '.*[.]pdf$';

ALTER STAGE PAR_DOCS_STAGE REFRESH;

-- ---------------------------------------------------------------------------
-- Parse & chunk: Playbook docs
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE PAR_PLAYBOOK_DOCS AS
WITH parsed AS (
    SELECT
        RELATIVE_PATH                           AS FILE_NAME,
        AI_PARSE_DOCUMENT(
            TO_FILE('@PAR_DOCS_STAGE', RELATIVE_PATH),
            {'mode': 'LAYOUT', 'page_split': FALSE}
        ):content::STRING                        AS DOC_TEXT
    FROM DIRECTORY(@PAR_DOCS_STAGE)
    WHERE RELATIVE_PATH IN (
        'customer_success_playbook.pdf',
        'district_onboarding_guide.pdf'
    )
),
chunks AS (
    SELECT
        FILE_NAME,
        TRIM(CHUNK.VALUE::STRING)                AS CONTENT,
        CHUNK.INDEX + 1                          AS CHUNK_NUM
    FROM parsed,
         LATERAL FLATTEN(INPUT =>
             SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER(DOC_TEXT, 'none', 1200, 200)
         ) CHUNK
    WHERE LENGTH(TRIM(CHUNK.VALUE::STRING)) > 80
)
SELECT
    ROW_NUMBER() OVER (ORDER BY FILE_NAME, CHUNK_NUM)  AS DOC_ID,
    FILE_NAME                                           AS SOURCE_FILE,
    CASE FILE_NAME
        WHEN 'customer_success_playbook.pdf'  THEN 'Customer Success'
        WHEN 'district_onboarding_guide.pdf'  THEN 'Onboarding'
    END                                                 AS CATEGORY,
    CONCAT(REPLACE(REPLACE(FILE_NAME, '.pdf', ''), '_', ' '),
           ' — Part ', CHUNK_NUM)                       AS TITLE,
    CONTENT
FROM chunks;

-- ---------------------------------------------------------------------------
-- Parse & chunk: Knowledge base docs
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE PAR_KB_DOCS AS
WITH parsed AS (
    SELECT
        RELATIVE_PATH                           AS FILE_NAME,
        AI_PARSE_DOCUMENT(
            TO_FILE('@PAR_DOCS_STAGE', RELATIVE_PATH),
            {'mode': 'LAYOUT', 'page_split': FALSE}
        ):content::STRING                        AS DOC_TEXT
    FROM DIRECTORY(@PAR_DOCS_STAGE)
    WHERE RELATIVE_PATH IN (
        'data_privacy_ferpa_guide.pdf',
        'feature_documentation.pdf',
        'it_integration_guide.pdf'
    )
),
chunks AS (
    SELECT
        FILE_NAME,
        TRIM(CHUNK.VALUE::STRING)                AS CONTENT,
        CHUNK.INDEX + 1                          AS CHUNK_NUM
    FROM parsed,
         LATERAL FLATTEN(INPUT =>
             SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER(DOC_TEXT, 'none', 1200, 200)
         ) CHUNK
    WHERE LENGTH(TRIM(CHUNK.VALUE::STRING)) > 80
)
SELECT
    ROW_NUMBER() OVER (ORDER BY FILE_NAME, CHUNK_NUM)  AS DOC_ID,
    FILE_NAME                                           AS SOURCE_FILE,
    CASE FILE_NAME
        WHEN 'data_privacy_ferpa_guide.pdf'  THEN 'Privacy & Compliance'
        WHEN 'feature_documentation.pdf'     THEN 'Feature Guide'
        WHEN 'it_integration_guide.pdf'      THEN 'IT Integration'
    END                                                 AS CATEGORY,
    CONCAT(REPLACE(REPLACE(FILE_NAME, '.pdf', ''), '_', ' '),
           ' — Part ', CHUNK_NUM)                       AS TITLE,
    CONTENT
FROM chunks;

-- ---------------------------------------------------------------------------
-- Cortex Search Services
-- ---------------------------------------------------------------------------

CREATE OR REPLACE CORTEX SEARCH SERVICE PAR_PLAYBOOK_SEARCH
  ON CONTENT
  ATTRIBUTES TITLE, CATEGORY, SOURCE_FILE
  WAREHOUSE = PAR_WH
  TARGET_LAG = '1 hour'
AS (
    SELECT DOC_ID, TITLE, CATEGORY, SOURCE_FILE, CONTENT
    FROM PAR_PLAYBOOK_DOCS
);

CREATE OR REPLACE CORTEX SEARCH SERVICE PAR_KB_SEARCH
  ON CONTENT
  ATTRIBUTES TITLE, CATEGORY, SOURCE_FILE
  WAREHOUSE = PAR_WH
  TARGET_LAG = '1 hour'
AS (
    SELECT DOC_ID, TITLE, CATEGORY, SOURCE_FILE, CONTENT
    FROM PAR_KB_DOCS
);
