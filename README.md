# PAR — ParentSquare Intelligence Demo

A complete Snowflake Intelligence demo for ParentSquare — K-12 family engagement SaaS analytics powered by a Cortex Agent, Semantic View, and Cortex Search over real PDF documents.

---

## What This Demo Shows

ParentSquare is a K-12 communications platform serving 22M+ students. This demo simulates their internal analytics platform on Snowflake — replacing a Redshift + QuickSight stack with Snowflake Intelligence for self-serve district health, revenue, and engagement analytics.

| Layer | What it demonstrates |
|-------|---------------------|
| Cortex Agent (`PAR_AGENT`) | Natural language over structured + unstructured data |
| Semantic View | Governed, AI-ready data model over 6 source tables |
| Cortex Search | PDF document search — CS playbooks + KB articles |
| Synthetic Data | 2M+ rows across 5 source systems (HubSpot, MySQL, Zendesk, Pendo, Billing) |

---

## Quick Start

Complete Steps 1 and 2 and the demo is fully deployed.

### Step 1: Create a Git API Integration & Connect Your Workspace

1. Navigate to **Projects → Workspaces** in Snowsight.
2. Open a blank SQL file and run as `ACCOUNTADMIN`:

```sql
USE ROLE ACCOUNTADMIN;

CREATE API INTEGRATION IF NOT EXISTS GIT_HUB_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/')
  ENABLED = TRUE;
```

3. At the top of the left-hand file pane, click the dropdown arrow next to your workspace name.
4. Select **From Git repository** and fill in:
   - Repository URL: `https://github.com/sfc-gh-timjones/c_par`
   - Workspace name: `PAR Demo`
   - API integration: `GIT_HUB_INTEGRATION`
   - Repository access: **Public repository**
5. Click **Create**.

### Step 2: Deploy the Demo Environment

| Script | What it does |
|--------|--------------|
| `sql/TEARDOWN_AND_REBUILD.sql` | Tears down existing objects, runs all setup scripts (01–09). After this, open Snowflake Intelligence and start the `PAR Assistant`. |

---

## Architecture

```
Data Sources (simulated)
  ├── HubSpot (Fivetran)         → PAR_DISTRICTS, PAR_CONTACTS
  ├── MySQL Product DB (dbt CDC) → PAR_MESSAGES (2M rows), PAR_ATTENDANCE_EVENTS (550K rows)
  ├── Zendesk (Fivetran)         → PAR_SUPPORT_TICKETS (50K rows)
  ├── Pendo (Fivetran)           → PAR_FEATURE_USAGE (500K rows)
  └── Billing System             → PAR_SUBSCRIPTIONS (12K rows)
          ↓
  Analytical Views (5 cross-system views)
          ↓
  PAR_SEMANTIC_VIEW (Cortex Analyst)
  PAR_PLAYBOOK_SEARCH | PAR_KB_SEARCH (Cortex Search — 5 PDFs)
          ↓
  PAR_AGENT (Snowflake Intelligence)
```

---

## Demo Questions (by category)

### District Health & Churn Risk
- "Which districts are at highest churn risk and renewing in the next 90 days?"
- "Show me all districts with health scores below 60"
- "Which districts have family engagement scores below 50?"
- "Who are the top 10 districts by ARR?"
- "Show me districts in California that are Enterprise tier"

### Revenue & Expansion
- "Show ARR trend by month for the last 12 months"
- "What is our total ARR by district tier?"
- "Which districts have had the most expansion revenue this year?"
- "How many districts are on each payment status?"
- "What is the average number of product modules per Enterprise district?"

### Message Delivery & Contactability
- "What is our message delivery rate by channel?"
- "Which channel has the highest delivery rate?"
- "Show me message volume by type over the last 6 months"
- "Which districts sent the most messages last month?"
- "What percentage of messages were sent in Spanish vs English?"

### Attendance Impact
- "How does attendance rate compare between districts with and without the Attendance module?"
- "Show me average attendance rate by district tier"
- "Which districts have the highest chronic absenteeism rates?"
- "What is the attendance trend for Enterprise districts over the past year?"

### Support & Operations
- "What are the most common support ticket categories this quarter?"
- "Which districts have the most open support tickets?"
- "What is our average ticket resolution time by priority?"
- "Show me average CSAT scores by account manager"
- "How many P1 tickets were opened this month?"

### Feature Usage
- "Which features are most used by Enterprise and Strategic districts?"
- "Show me the top 10 features by total event count this month"
- "Which districts are using the ParentSquare Intelligence module?"
- "What is the average number of active users per district for Attendance features?"

### Playbook & Knowledge Base (Cortex Search)
- "What does the playbook say about handling a district with a Health Score below 40?"
- "Walk me through the QBR slide structure"
- "What are the churn risk intervention steps?"
- "What does FERPA say about what data ParentSquare can receive?"
- "How do I set up Google Workspace SSO for a district?"
- "What is the SIS integration process for a new district?"

---

## Data Model

| Table | Source | Rows |
|-------|--------|------|
| PAR_DISTRICTS | HubSpot | 500 |
| PAR_CONTACTS | HubSpot | 1,500 |
| PAR_MESSAGES | MySQL Product DB | 2,000,000 |
| PAR_ATTENDANCE_EVENTS | MySQL Product DB | ~550,000 |
| PAR_SUPPORT_TICKETS | Zendesk | 50,000 |
| PAR_FEATURE_USAGE | Pendo | 500,000 |
| PAR_SUBSCRIPTIONS | Billing | ~12,000 |

See `docs/erd.html` for the interactive entity-relationship diagram.

---

## Development

This demo was built with [Cortex Code](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code) — the same tool ParentSquare plans to use for data exploration and self-serve analytics.
