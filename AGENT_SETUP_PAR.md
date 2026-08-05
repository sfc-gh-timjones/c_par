# PAR Agent Setup & Demo Script

## Overview

The PAR Assistant is a Snowflake Intelligence agent configured for ParentSquare's internal analytics team. It answers questions across 6 data domains using structured analytics (Cortex Analyst over a Semantic View) and document search (Cortex Search over 5 PDF docs).

**Agent name**: `PAR_AGENT`  
**Display name**: PAR Assistant  
**Model**: claude-sonnet-4-6  
**Schema**: `CUSTOMER_DEMOS.PAR`

---

## Tools

| Tool | Type | What it does |
|------|------|------|
| `ParAnalyst` | Cortex Analyst | Text-to-SQL over `PAR_SEMANTIC_VIEW` |
| `PlaybookSearch` | Cortex Search | CS Playbook + Onboarding Guide PDFs |
| `KBSearch` | Cortex Search | Privacy/FERPA + Feature Docs + IT Guide PDFs |
| `SendEmail` | Stored Procedure | Send HTML email via `SEND_EMAIL` proc |
| `data_to_chart` | Built-in | Render charts from tabular query results |

---

## 35 Demo Questions

### Category 1: District Health & Churn Risk

1. "Which districts are at highest churn risk and renewing in the next 90 days?"
2. "Show me all districts with a health score below 60"
3. "Who are the top 10 districts by ARR?"
4. "Which districts have family engagement scores below 50?"
5. "Show me Enterprise and Strategic districts in Texas"
6. "Which districts have had declining health scores over the last 3 months?"
7. "List all at-risk districts managed by Sarah Chen"

### Category 2: Revenue & ARR

8. "Show ARR trend by month for the last 12 months"
9. "What is our total ARR by district tier?"
10. "Which districts have had the most expansion revenue this year?"
11. "What is our NRR trend over the last 6 months?"
12. "How many districts are currently in Grace Period or Overdue payment status?"
13. "Show me ARR by state for our top 10 states"

### Category 3: Message Delivery & Contactability

14. "What is our message delivery rate by channel?"
15. "Which channel has the highest and lowest delivery rates?"
16. "Show me message volume trends over the last 6 months"
17. "What percentage of our messages are sent in Spanish?"
18. "Which districts had the highest volume of failed messages last week?"
19. "What are our top 3 most common message types?"

### Category 4: Attendance Impact

20. "How does attendance rate compare between districts with and without the Attendance module?"
21. "Show me the 10 districts with the highest chronic absenteeism rates"
22. "What is the average attendance rate for Enterprise districts this school year?"
23. "Show attendance trends for Strategic districts over the past 2 years"

### Category 5: Support & Operations

24. "What are the most common support ticket categories this quarter?"
25. "Which districts have the most open P1 or P2 tickets?"
26. "What is average CSAT score by account manager?"
27. "Show me ticket volume by priority for the last 90 days"
28. "How many tickets were opened vs. resolved this month?"

### Category 6: Feature Usage (Pendo)

29. "Which features are most used by Enterprise and Strategic districts?"
30. "Which districts are using the ParentSquare Intelligence module?"
31. "What features have the lowest adoption among Mid-Market districts?"

### Category 7: Document Search — Playbook

32. "What does the Customer Success Playbook say about handling a district with a Health Score below 40?"
33. "Walk me through the QBR slide structure"
34. "What are the expansion triggers for pitching the Attendance module?"

### Category 8: Document Search — Knowledge Base

35. "What are ParentSquare's FERPA data handling obligations?"

---

## Suggested Demo Flow (15 minutes)

**Opening (2 min)**
- Context: "ParentSquare is replacing Redshift + QuickSight with Snowflake Intelligence. Anna's team gets 2-5 ad hoc report requests per day — each taking 30-60 minutes. The goal is self-serve."
- Open Snowflake Intelligence → select PAR Assistant

**Structured Data (6 min)**
- Ask Q1: Churn risk districts (shows Analyst + table output)
- Ask Q8: ARR trend (shows Analyst + data_to_chart rendering a line chart)
- Ask Q14: Delivery rate by channel (shows multi-metric comparison)
- Ask Q20: Attendance module impact (shows the data story — PS drives outcomes)

**Document Search (3 min)**
- Ask Q32: Playbook / churn handling (shows PlaybookSearch with cited source)
- Ask Q35: FERPA question (shows KBSearch for compliance context)

**Email (2 min)**
- "Email me a summary of the at-risk districts with a renewal in the next 60 days" → agent composes HTML report and sends via SendEmail

**Close (2 min)**
- "Anna's team can now answer any of these questions in seconds instead of 30-60 minutes"
- "The semantic view is the governed data dictionary Brian asked for — consistent definitions across CS, RevOps, and Product"
- "This runs on Snowflake — the same platform they're evaluating for Redshift migration"

---

## Key Data Facts (for context in demo)

- 500 simulated school districts (customers), spanning all 50 US states
- Tier breakdown: ~45% SMB, ~30% Mid-Market, ~17% Enterprise, ~8% Strategic
- 2,000,000 messages spanning 2 years; top channel by volume is SMS (45%)
- ~97% of districts are active; churn risk is modeled as inversely correlated with health score
- Districts with the Attendance module average ~93% attendance vs ~89% without
- Avg ARR by tier: SMB ~$19K, Mid-Market ~$75K, Enterprise ~$310K, Strategic ~$1.25M
