-- =============================================================================
-- PAR: 09 - Cortex Agent (PAR_AGENT)
-- FROM SPECIFICATION syntax — required for Snowflake Intelligence UI visibility
-- Tools: ParAnalyst, PlaybookSearch, KBSearch, SendEmail, data_to_chart
-- =============================================================================

USE DATABASE CUSTOMER_DEMOS;
USE SCHEMA PAR;
USE WAREHOUSE PAR_WH;

CREATE OR REPLACE AGENT CUSTOMER_DEMOS.PAR.PAR_AGENT
  COMMENT = 'ParentSquare Intelligence Agent — district health, messaging, revenue, and support analytics'
  PROFILE = '{"display_name": "PAR Assistant", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: claude-sonnet-4-6

  orchestration:
    budget:
      seconds: 360
      tokens: 32000

  instructions:
    system: >
      You are the PAR Assistant — an AI analyst for ParentSquare, a K-12 family engagement SaaS
      platform serving 22 million students across 42,000 schools nationwide.

      ParentSquare sells annual subscriptions to school districts. Districts are the customers.
      The platform sends 10-20 million messages per day to families via SMS, Email, App, and Push.
      Core products include Communications, Attendance Management, Mass Notifications, School Websites,
      Payments, and ParentSquare Intelligence.

      You help the Customer Success, Revenue Operations, Data, and Leadership teams answer
      questions about district health, family engagement, message delivery, ARR trends, attendance
      impact, and support operations.

      Key terminology:
      - Tier: SMB (under 2K students), Mid-Market (2K-10K), Enterprise (10K-50K), Strategic (50K+)
      - Contactability Score: percent of families reachable by at least one channel (0-100)
      - Family Engagement Score: composite measure of how actively families interact with the platform (0-100)
      - Health Score: overall account health indicator (0-100; higher is better)
      - Churn Risk Score: likelihood of non-renewal (0-100; higher is worse)
      - ARR: annual recurring revenue in USD per district
      - NRR: net revenue retention (expansion minus churn as % of prior period ARR)

    orchestration: >
      Route questions as follows:
      - Quantitative questions about districts, messages, ARR, attendance, tickets, or feature usage:
        use ParAnalyst (Cortex Analyst over the semantic view).
      - Questions about customer success processes, churn handling, QBR prep, onboarding steps,
        or expansion strategies: use PlaybookSearch.
      - Questions about FERPA, COPPA, data privacy, compliance, product features, SIS integration,
        network requirements, or IT setup: use KBSearch.
      - When the user asks to email a summary, report, or alert to a recipient: use SendEmail with
        HTML-formatted content.
      - When displaying tabular data with 3+ rows that benefits from visualization: use data_to_chart
        after retrieving data from ParAnalyst.

    response: >
      When generating a bar chart, default to horizontal orientation unless the x-axis represents
      time or dates, or there are 3 or fewer categories. Horizontal bars make category labels
      (district names, feature names, ticket categories, tiers) much easier to read.

    sample_questions:
      - question: "Which districts are at highest churn risk and renewing in the next 90 days?"
        answer: "Uses ParAnalyst to show churn risk score, health score, ARR, and renewal date for at-risk districts."
      - question: "What is our overall message delivery rate by channel?"
        answer: "Uses ParAnalyst to show SMS, Email, App, and Push delivery rates with trend."
      - question: "What does the playbook say about handling a district with a Health Score below 40?"
        answer: "Uses PlaybookSearch to find the churn risk intervention steps and escalation matrix."
      - question: "Show me ARR trend over the last 12 months"
        answer: "Uses ParAnalyst to retrieve monthly ARR, then data_to_chart to visualize as a line chart."
      - question: "Which Enterprise districts have the highest feature usage this month?"
        answer: "Uses ParAnalyst to query feature usage filtered to Enterprise tier."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "ParAnalyst"
        description: >
          Text-to-SQL over the PAR semantic view. Use for all quantitative questions about
          districts, messages, ARR, attendance, support tickets, and feature usage.

    - tool_spec:
        type: "cortex_search"
        name: "PlaybookSearch"
        description: >
          Search the Customer Success Playbook and District Onboarding Guide.
          Use for questions about churn handling, QBR preparation, expansion strategies,
          onboarding steps, escalation procedures, and CSM best practices.

    - tool_spec:
        type: "cortex_search"
        name: "KBSearch"
        description: >
          Search the Knowledge Base: FERPA/COPPA compliance guide, product feature documentation,
          and IT integration guide. Use for questions about data privacy, compliance, product
          features, SIS integration, SSO setup, network requirements, and API specifications.

    - tool_spec:
        type: "generic"
        name: "SendEmail"
        description: >
          Send an HTML email notification or report. Use when the user asks to email a summary,
          alert, or report. Always use HTML-formatted content for clean presentation.
        input_schema:
          type: "object"
          properties:
            TO_ADDRESS:
              type: "string"
              description: "Recipient email address"
            SUBJECT:
              type: "string"
              description: "Email subject line"
            BODY_HTML:
              type: "string"
              description: "HTML body content"
          required: ["TO_ADDRESS", "SUBJECT", "BODY_HTML"]

    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generate a chart from tabular data. Use after retrieving data from ParAnalyst when visualization adds clarity."

  tool_resources:
    ParAnalyst:
      semantic_view: "CUSTOMER_DEMOS.PAR.PAR_SEMANTIC_VIEW"
      execution_environment:
        type: "warehouse"
        warehouse: "PAR_WH"

    PlaybookSearch:
      name: "CUSTOMER_DEMOS.PAR.PAR_PLAYBOOK_SEARCH"
      max_results: "8"
      title_column: "TITLE"
      id_column: "DOC_ID"

    KBSearch:
      name: "CUSTOMER_DEMOS.PAR.PAR_KB_SEARCH"
      max_results: "8"
      title_column: "TITLE"
      id_column: "DOC_ID"

    SendEmail:
      type: "procedure"
      identifier: "CUSTOMER_DEMOS.PAR.SEND_EMAIL"
      execution_environment:
        type: "warehouse"
        warehouse: "PAR_WH"
  $$;

-- Register with Snowflake Intelligence
-- DROP first in case a prior CREATE OR REPLACE left a stale registration
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  DROP AGENT CUSTOMER_DEMOS.PAR.PAR_AGENT;
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT CUSTOMER_DEMOS.PAR.PAR_AGENT;
