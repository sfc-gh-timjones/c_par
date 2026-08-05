"""
Generate synthetic PDFs for PAR (ParentSquare) Cortex Search demo.
Run: python3 generate_pdfs.py
Output: pdfs/  (5 PDFs committed to repo; used by script 07)
"""
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable, Table, TableStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "pdfs")
os.makedirs(OUT_DIR, exist_ok=True)

BRAND_BLUE   = colors.HexColor("#2A5AED")
BRAND_DARK   = colors.HexColor("#1A1A2E")
LIGHT_GRAY   = colors.HexColor("#F5F6FA")


def make_styles():
    base = getSampleStyleSheet()
    return {
        "title":   ParagraphStyle("title",   parent=base["Title"],
                                  fontSize=22, textColor=BRAND_BLUE, spaceAfter=6),
        "h1":      ParagraphStyle("h1",      parent=base["Heading1"],
                                  fontSize=15, textColor=BRAND_BLUE, spaceBefore=14, spaceAfter=4),
        "h2":      ParagraphStyle("h2",      parent=base["Heading2"],
                                  fontSize=12, textColor=BRAND_DARK, spaceBefore=10, spaceAfter=3),
        "body":    ParagraphStyle("body",    parent=base["Normal"],
                                  fontSize=10, leading=15, spaceAfter=6),
        "bullet":  ParagraphStyle("bullet",  parent=base["Normal"],
                                  fontSize=10, leading=14, leftIndent=16, spaceAfter=3,
                                  bulletIndent=6),
        "caption": ParagraphStyle("caption", parent=base["Normal"],
                                  fontSize=8, textColor=colors.gray, spaceAfter=4),
    }


def hr(styles):
    return HRFlowable(width="100%", thickness=1, color=BRAND_BLUE, spaceAfter=8)


def build_doc(path, title, content_fn):
    doc = SimpleDocTemplate(path, pagesize=letter,
                             rightMargin=inch, leftMargin=inch,
                             topMargin=inch, bottomMargin=inch)
    s = make_styles()
    story = [Paragraph(title, s["title"]), hr(s)]
    content_fn(story, s)
    doc.build(story)
    print(f"  Created: {os.path.basename(path)}")


# ============================================================
# 1. Customer Success Playbook
# ============================================================
def playbook_content(story, s):
    story += [
        Paragraph("Purpose", s["h1"]),
        Paragraph(
            "This playbook guides Customer Success Managers (CSMs) through the full district lifecycle — "
            "from onboarding through renewal. Use it to deliver consistent, data-driven engagement that "
            "maximizes family engagement scores, reduces churn, and grows account value.", s["body"]),

        Paragraph("1. New District Onboarding (Days 0–90)", s["h1"]),
        Paragraph("Week 1–2: Technical Setup", s["h2"]),
        Paragraph("• Schedule kick-off call with IT Director and Communications Director.", s["bullet"]),
        Paragraph("• Complete Student Information System (SIS) integration setup: PowerSchool, Infinite Campus, Skyward, or Aeries.", s["bullet"]),
        Paragraph("• Import family contact data; target 95%+ contactability within 14 days.", s["bullet"]),
        Paragraph("• Configure multi-channel delivery: SMS (primary), Email, App Notification, Push.", s["bullet"]),
        Paragraph("• Verify language translation is enabled for top languages in the district.", s["bullet"]),
        Paragraph("Week 3–6: Activation and Training", s["h2"]),
        Paragraph("• Conduct role-based training: Superintendent overview (30 min), Admin power-user (90 min), Teacher quick-start (45 min).", s["bullet"]),
        Paragraph("• Send first parent-welcome message using the New Family Welcome template.", s["bullet"]),
        Paragraph("• Enable Attendance Alerts if district purchased Attendance Management module.", s["bullet"]),
        Paragraph("• Set up Emergency Notification protocol and conduct a test drill.", s["bullet"]),
        Paragraph("Week 7–12: Adoption Review", s["h2"]),
        Paragraph("• Review Family Engagement Score in the ParentSquare Intelligence dashboard.", s["bullet"]),
        Paragraph("• Benchmark Contactability Score against similar-sized districts (target: 90%+).", s["bullet"]),
        Paragraph("• Identify top 3 teachers or administrators as internal champions.", s["bullet"]),

        Paragraph("2. Quarterly Business Review (QBR) Guide", s["h1"]),
        Paragraph("QBR Objectives", s["h2"]),
        Paragraph("QBRs should be held every 90 days with the district's executive sponsor (typically Superintendent or CIO). "
                  "The goal is to tie platform engagement to student outcomes and build the renewal case.", s["body"]),
        Paragraph("Required Data Pulls Before QBR", s["h2"]),
        Paragraph("• Contactability Score trend (current quarter vs. prior quarter).", s["bullet"]),
        Paragraph("• Family Engagement Score by school and grade level.", s["bullet"]),
        Paragraph("• Attendance rate trend if Attendance Management is enabled.", s["bullet"]),
        Paragraph("• Top 5 most-used features and message volume by channel.", s["bullet"]),
        Paragraph("• Open support tickets and average CSAT score.", s["bullet"]),
        Paragraph("QBR Slide Structure", s["h2"]),
        Paragraph("Slide 1: Executive summary — 3 wins, 1 area to improve.", s["bullet"]),
        Paragraph("Slide 2: Contactability and engagement benchmarks vs. peer districts.", s["bullet"]),
        Paragraph("Slide 3: Attendance impact (module adopters only).", s["bullet"]),
        Paragraph("Slide 4: Usage highlights — top features, message volume, language breakdown.", s["bullet"]),
        Paragraph("Slide 5: Upcoming product roadmap items relevant to district priorities.", s["bullet"]),
        Paragraph("Slide 6: Renewal investment summary and expansion opportunity.", s["bullet"]),

        Paragraph("3. Churn Risk Intervention Playbook", s["h1"]),
        Paragraph("Risk Tiers", s["h2"]),
        Paragraph("Health Score below 40 (Critical): CSM must escalate to Director of Customer Success within 24 hours. "
                  "Schedule executive alignment call within 5 business days.", s["bullet"]),
        Paragraph("Health Score 40–59 (Elevated): CSM conducts weekly check-in. Root cause analysis required within 2 weeks.", s["bullet"]),
        Paragraph("Health Score 60–74 (Watch): CSM reviews in next scheduled touchpoint. Document contributing factors.", s["bullet"]),
        Paragraph("Common Churn Signals", s["h2"]),
        Paragraph("• Family Engagement Score drops more than 10 points month-over-month.", s["bullet"]),
        Paragraph("• P1 or P2 support tickets unresolved for more than 48 hours.", s["bullet"]),
        Paragraph("• Staff turnover in Communications Director or IT Director role.", s["bullet"]),
        Paragraph("• Renewal date within 60 days and no renewal conversation initiated.", s["bullet"]),
        Paragraph("• District submits RFP or requests competitor comparison.", s["bullet"]),
        Paragraph("Intervention Steps", s["h2"]),
        Paragraph("Step 1: Review full account health dashboard in the CSM portal.", s["bullet"]),
        Paragraph("Step 2: Listen call — schedule 30-min call; listen-only agenda, no upsell.", s["bullet"]),
        Paragraph("Step 3: Document root cause in CRM (HubSpot). Assign action owners.", s["bullet"]),
        Paragraph("Step 4: Customized recovery plan — training, feature unlock, exec escalation.", s["bullet"]),
        Paragraph("Step 5: 30-day follow-up review with district stakeholder.", s["bullet"]),

        Paragraph("4. Expansion Playbook", s["h1"]),
        Paragraph("Expansion Triggers", s["h2"]),
        Paragraph("• District achieves 95%+ Contactability Score: introduce Intelligence module.", s["bullet"]),
        Paragraph("• Chronic absenteeism is a district priority (>15% chronic absent rate): pitch Attendance Management.", s["bullet"]),
        Paragraph("• District collects fees via paper or check: introduce Payments & Digital Forms.", s["bullet"]),
        Paragraph("• District website is outdated or ADA non-compliant: introduce School Websites.", s["bullet"]),
        Paragraph("Expansion Conversation Guide", s["h2"]),
        Paragraph("Lead with data: 'Districts using our Attendance module see an average 3.2% improvement in attendance rates within 6 months.' "
                  "Reference peer districts in the same state or tier for benchmarking.", s["body"]),

        Paragraph("5. Escalation Matrix", s["h1"]),
        Paragraph("Support escalations above P2 require CSM involvement. CSMs must be CC'd on all P1 tickets and briefed "
                  "within 2 hours of P1 ticket creation. Director of CS must be notified for any Strategic or Enterprise district P1.", s["body"]),
    ]


# ============================================================
# 2. Data Privacy & FERPA Compliance Guide
# ============================================================
def privacy_content(story, s):
    story += [
        Paragraph("Overview", s["h1"]),
        Paragraph(
            "ParentSquare is committed to protecting student and family data in full compliance with FERPA, "
            "COPPA, CIPA, and applicable state privacy laws. This guide explains how district data is handled, "
            "stored, and protected within the ParentSquare platform.", s["body"]),

        Paragraph("1. FERPA Compliance", s["h1"]),
        Paragraph("What is FERPA?", s["h2"]),
        Paragraph("The Family Educational Rights and Privacy Act (FERPA) protects the privacy of student education records. "
                  "ParentSquare operates as a 'school official' under FERPA's legitimate educational interest exception, "
                  "meaning districts may share student data with ParentSquare without additional parental consent.", s["body"]),
        Paragraph("What Data ParentSquare Receives", s["h2"]),
        Paragraph("• Student name, grade level, school, and unique student identifier (no SSN).", s["bullet"]),
        Paragraph("• Family contact information: phone numbers, email addresses, preferred language.", s["bullet"]),
        Paragraph("• Attendance records when the Attendance Management module is active.", s["bullet"]),
        Paragraph("• Emergency contact information and authorized pickup designations.", s["bullet"]),
        Paragraph("What ParentSquare Does NOT Receive", s["h2"]),
        Paragraph("• Academic performance records, grades, or test scores.", s["bullet"]),
        Paragraph("• Disciplinary records, IEP/504 data, or special education classifications.", s["bullet"]),
        Paragraph("• Social Security numbers, financial aid data, or health records.", s["bullet"]),

        Paragraph("2. COPPA Compliance", s["h1"]),
        Paragraph("The Children's Online Privacy Protection Act (COPPA) applies to collection of personal information "
                  "from children under 13. ParentSquare does not create accounts for students — all accounts belong to "
                  "parents, guardians, and school staff. ParentSquare does not knowingly collect personal data directly from minors.", s["body"]),

        Paragraph("3. Data Storage and Security", s["h1"]),
        Paragraph("Infrastructure", s["h2"]),
        Paragraph("• All data is stored on AWS infrastructure in the United States (us-east-1 by default).", s["bullet"]),
        Paragraph("• Data is encrypted at rest (AES-256) and in transit (TLS 1.2+).", s["bullet"]),
        Paragraph("• ParentSquare maintains SOC 2 Type II and ISO 27001 certifications.", s["bullet"]),
        Paragraph("• Annual penetration testing by third-party security firm.", s["bullet"]),
        Paragraph("Data Retention", s["h2"]),
        Paragraph("• Active district data is retained for the duration of the contract plus 90 days.", s["bullet"]),
        Paragraph("• Upon contract termination, district data is purged from production systems within 90 days.", s["bullet"]),
        Paragraph("• Message logs are retained for 7 years for compliance and audit purposes.", s["bullet"]),
        Paragraph("• Attendance data is retained for 3 years after the school year closes.", s["bullet"]),

        Paragraph("4. Data Processing Agreement (DPA)", s["h1"]),
        Paragraph("All districts are required to execute a Data Processing Agreement (DPA) before activating the ParentSquare platform. "
                  "The DPA governs how ParentSquare processes personal data on behalf of the district as a data controller. "
                  "Key DPA provisions include: purpose limitation, data minimization, sub-processor transparency, "
                  "breach notification within 72 hours, and district right to audit.", s["body"]),

        Paragraph("5. Family Rights Under FERPA", s["h1"]),
        Paragraph("• Families have the right to review their student's education records held by ParentSquare.", s["bullet"]),
        Paragraph("• Families may request correction of inaccurate data by contacting their district's IT Director.", s["bullet"]),
        Paragraph("• Families may opt out of receiving non-essential communications by managing preferences in the ParentSquare app.", s["bullet"]),
        Paragraph("• ParentSquare does not sell, rent, or share family data for commercial advertising purposes.", s["bullet"]),

        Paragraph("6. Breach Response Protocol", s["h1"]),
        Paragraph("In the event of a data breach involving student or family data, ParentSquare will notify affected districts "
                  "within 72 hours of confirmed breach discovery. The district must then notify affected families per applicable state law "
                  "(typically within 30–45 days). ParentSquare's Security team provides forensic analysis support and remediation guidance.", s["body"]),

        Paragraph("7. State-Specific Privacy Laws", s["h1"]),
        Paragraph("California (SOPIPA, AB 1584)", s["h2"]),
        Paragraph("ParentSquare complies with California's Student Online Personal Information Protection Act. "
                  "ParentSquare does not use student data for targeted advertising and does not build profiles of students outside of educational purposes.", s["body"]),
        Paragraph("New York (Education Law 2-d)", s["h2"]),
        Paragraph("New York districts must execute a Parents Bill of Rights and include ParentSquare in their Third-Party Contractor list. "
                  "ParentSquare supports NY's data security requirements including role-based access control and audit logging.", s["body"]),
        Paragraph("Other States", s["h2"]),
        Paragraph("ParentSquare monitors and responds to new student data privacy legislation across all 50 states. "
                  "Contact privacy@parentsquare.com for state-specific DPA addendums.", s["body"]),
    ]


# ============================================================
# 3. District Onboarding Guide
# ============================================================
def onboarding_content(story, s):
    story += [
        Paragraph("Welcome to ParentSquare", s["h1"]),
        Paragraph(
            "This guide walks your implementation team through every step of setting up ParentSquare "
            "for your district. Complete all steps in Part 1 before your go-live date.", s["body"]),

        Paragraph("Part 1: Technical Setup (IT Director)", s["h1"]),
        Paragraph("Step 1: SIS Integration", s["h2"]),
        Paragraph("ParentSquare integrates with 80+ Student Information Systems via direct API, SFTP flat file, "
                  "or CSV import. The recommended method is direct SIS integration for real-time roster updates.", s["body"]),
        Paragraph("Supported SIS platforms: PowerSchool, Infinite Campus, Skyward, Aeries, Escholar, Tyler SIS, "
                  "Synergy, Frontline, Skyward Finance, and others.", s["body"]),
        Paragraph("SIS Integration Steps:", s["h2"]),
        Paragraph("1. Submit a SIS Integration Request in the Help Center.", s["bullet"]),
        Paragraph("2. Grant ParentSquare read-only API access or configure SFTP export schedule.", s["bullet"]),
        Paragraph("3. Map your student identifier fields to ParentSquare schema.", s["bullet"]),
        Paragraph("4. Run test sync with 10–50 records; verify family contact accuracy.", s["bullet"]),
        Paragraph("5. Enable nightly full sync or real-time API sync.", s["bullet"]),
        Paragraph("Step 2: Contactability Baseline", s["h2"]),
        Paragraph("After your first SIS sync, review your Contactability Score in the admin dashboard. "
                  "A score below 80% indicates missing phone numbers or email addresses. "
                  "Common fix: export your parent contact list from your SIS and cross-reference against the Missing Contact report.", s["body"]),
        Paragraph("Target: 90%+ contactability before go-live.", s["body"]),
        Paragraph("Step 3: Channel Configuration", s["h2"]),
        Paragraph("• SMS: ParentSquare sends from a dedicated school number. Verify your district's phone number in Settings > School Numbers.", s["bullet"]),
        Paragraph("• Email: Configure your district's sending domain (SPF, DKIM, DMARC records). IT must update DNS within 48 hours.", s["bullet"]),
        Paragraph("• App: Publish your district app branding (logo, colors) in Settings > App Customization.", s["bullet"]),
        Paragraph("Step 4: Staff Accounts", s["h2"]),
        Paragraph("Provision staff accounts via SIS sync or CSV upload. Role types:", s["body"]),
        Paragraph("• School Administrator: Full access to all school-level settings and messages.", s["bullet"]),
        Paragraph("• Teacher: Send classroom updates; view class roster.", s["bullet"]),
        Paragraph("• District Administrator: Cross-school visibility, district announcements, reporting.", s["bullet"]),

        Paragraph("Part 2: Communications Setup (Communications Director)", s["h1"]),
        Paragraph("Message Templates", s["h2"]),
        Paragraph("Create templates for your most-used message types. Required templates for go-live:", s["body"]),
        Paragraph("• School Closure / Emergency Notification template.", s["bullet"]),
        Paragraph("• Back to School welcome message.", s["bullet"]),
        Paragraph("• Attendance Alert (auto-populated if Attendance module is active).", s["bullet"]),
        Paragraph("Language Translation", s["h2"]),
        Paragraph("ParentSquare supports 190+ languages via automatic translation. "
                  "Set your district's default language priority list in Settings > Languages. "
                  "Families will receive messages in their preferred language automatically.", s["body"]),
        Paragraph("Emergency Notification Protocol", s["h2"]),
        Paragraph("Before go-live, conduct a test emergency notification drill:", s["body"]),
        Paragraph("1. Create a test message marked as 'Emergency' type.", s["bullet"]),
        Paragraph("2. Send to all channels simultaneously.", s["bullet"]),
        Paragraph("3. Verify delivery rates within 5 minutes (target: 85%+ delivered within 2 minutes).", s["bullet"]),
        Paragraph("4. Review failure report and update family contact data accordingly.", s["bullet"]),

        Paragraph("Part 3: Attendance Setup (if module purchased)", s["h1"]),
        Paragraph("Attendance Integration", s["h2"]),
        Paragraph("ParentSquare pulls attendance data from your SIS daily. Absences are automatically "
                  "identified and attendance alert messages are triggered based on your configured rules.", s["body"]),
        Paragraph("Default Rules:", s["h2"]),
        Paragraph("• Same-day absence: Alert sent by 9:00 AM local time if student not marked present.", s["bullet"]),
        Paragraph("• Chronic absenteeism threshold: Alert to parent when student misses 10% of school days.", s["bullet"]),
        Paragraph("• Unexcused absence pattern: Escalation to counselor at 3 consecutive unexcused absences.", s["bullet"]),
        Paragraph("Modify these rules in Settings > Attendance > Alert Configuration.", s["body"]),

        Paragraph("Part 4: Go-Live Checklist", s["h1"]),
        Paragraph("Complete all items before activating for your full district:", s["body"]),
        Paragraph("[ ] SIS sync completed and verified (100% of schools)", s["bullet"]),
        Paragraph("[ ] Contactability Score >= 90%", s["bullet"]),
        Paragraph("[ ] Staff accounts provisioned and roles verified", s["bullet"]),
        Paragraph("[ ] Emergency notification test drill completed", s["bullet"]),
        Paragraph("[ ] Language settings configured for top 5 district languages", s["bullet"]),
        Paragraph("[ ] School phone numbers confirmed in Settings", s["bullet"]),
        Paragraph("[ ] First parent-facing message drafted and reviewed", s["bullet"]),
        Paragraph("[ ] CSM kickoff call completed", s["bullet"]),
    ]


# ============================================================
# 4. Feature Documentation Guide
# ============================================================
def feature_content(story, s):
    story += [
        Paragraph("Core Communications", s["h1"]),
        Paragraph("Overview", s["h2"]),
        Paragraph("Core Communications is the foundation of the ParentSquare platform, enabling two-way messaging "
                  "between schools and families across all channels. All ParentSquare subscriptions include Core Communications.", s["body"]),
        Paragraph("Key Features", s["h2"]),
        Paragraph("Direct Messaging: Staff can send individual messages to parents, guardians, or students. "
                  "Messages thread by conversation for easy tracking.", s["bullet"]),
        Paragraph("Post & Newsletter: Create rich-content posts with images, attachments, and event RSVPs. "
                  "Posts are shared to all families in a class, school, or district.", s["bullet"]),
        Paragraph("Group Messaging: Send targeted messages to custom groups (e.g., all Spanish-speaking families, "
                  "all 3rd-grade families, specific clubs).", s["bullet"]),
        Paragraph("Read Receipts: Track which families have opened messages and follow up with unread families.", s["bullet"]),

        Paragraph("Attendance Management", s["h1"]),
        Paragraph("Overview", s["h2"]),
        Paragraph("The Attendance Management module automates absence notifications and chronic absenteeism "
                  "interventions. Districts using this module report an average 3.2% improvement in attendance "
                  "rates within 6 months of activation.", s["body"]),
        Paragraph("How It Works", s["h2"]),
        Paragraph("1. SIS sends daily attendance data to ParentSquare (typically by 8:30 AM).", s["bullet"]),
        Paragraph("2. ParentSquare identifies absent students and triggers automated alerts.", s["bullet"]),
        Paragraph("3. Parents receive a same-day absence notification via their preferred channel.", s["bullet"]),
        Paragraph("4. Parent can respond directly to report excused absence.", s["bullet"]),
        Paragraph("5. Attendance dashboard shows real-time and trend data for administrators.", s["bullet"]),
        Paragraph("Chronic Absenteeism Tracking", s["h2"]),
        Paragraph("Students who miss 10% or more of school days are automatically flagged as chronically absent. "
                  "The system generates a weekly Chronic Absenteeism Report for school counselors and administrators. "
                  "Automated intervention sequences can be configured to escalate at 5%, 10%, and 15% absence thresholds.", s["body"]),

        Paragraph("Mass Notifications & Emergency Alerts", s["h1"]),
        Paragraph("Overview", s["h2"]),
        Paragraph("Send district-wide emergency alerts and mass notifications across all channels simultaneously. "
                  "Messages are delivered within seconds to thousands of families. "
                  "Emergency notifications bypass family opt-out preferences.", s["body"]),
        Paragraph("Use Cases", s["h2"]),
        Paragraph("• School closure (weather, facility emergency).", s["bullet"]),
        Paragraph("• Lockdown or shelter-in-place notification.", s["bullet"]),
        Paragraph("• Utility outage or delayed opening.", s["bullet"]),
        Paragraph("• District-wide event or policy change notification.", s["bullet"]),

        Paragraph("School Websites", s["h1"]),
        Paragraph("Overview", s["h2"]),
        Paragraph("Manage ADA-compliant school and district websites directly within ParentSquare. "
                  "No coding required. Websites automatically surface upcoming events, recent posts, and staff directories.", s["body"]),
        Paragraph("Accessibility", s["h2"]),
        Paragraph("All ParentSquare websites meet WCAG 2.1 AA standards, including screen reader support, "
                  "sufficient color contrast, keyboard navigation, and alt text for all images.", s["body"]),

        Paragraph("Payments & Digital Forms", s["h1"]),
        Paragraph("Overview", s["h2"]),
        Paragraph("Collect payments and digital form signatures within the ParentSquare app. "
                  "Eliminate paper forms and checks. Supports ACH bank transfer, credit/debit card, and PayPal.", s["body"]),
        Paragraph("Common Payment Use Cases", s["h2"]),
        Paragraph("• School lunch payments and balance top-ups.", s["bullet"]),
        Paragraph("• Activity fees, field trip payments, and club dues.", s["bullet"]),
        Paragraph("• Yearbook purchases and merchandise orders.", s["bullet"]),
        Paragraph("• Fundraiser collections.", s["bullet"]),

        Paragraph("ParentSquare Intelligence", s["h1"]),
        Paragraph("Overview", s["h2"]),
        Paragraph("ParentSquare Intelligence is the AI and data layer embedded across the platform. "
                  "It surfaces engagement insights, benchmarks performance, and assists staff with communication.", s["body"]),
        Paragraph("Contactability Benchmark", s["h2"]),
        Paragraph("Compare your district's Contactability Score against anonymized peer districts of similar size and region. "
                  "The benchmark identifies whether you are above or below average and suggests specific actions to improve.", s["body"]),
        Paragraph("AI Message Rewrite", s["h2"]),
        Paragraph("Staff can click 'Rewrite with AI' on any draft message to improve tone, clarity, and readability. "
                  "The AI adjusts reading level, suggests more inclusive language, and improves overall message quality.", s["body"]),
        Paragraph("Conversation Starters", s["h2"]),
        Paragraph("AI-generated follow-up questions are automatically appended to posts, helping parents engage in "
                  "home conversations about school content. Staff can review and edit before sending.", s["body"]),
    ]


# ============================================================
# 5. IT Integration Guide
# ============================================================
def it_content(story, s):
    story += [
        Paragraph("Overview", s["h1"]),
        Paragraph("This guide covers technical integration specifications for connecting ParentSquare "
                  "to your district's existing systems. Intended audience: district IT Directors, "
                  "network administrators, and DevOps engineers.", s["body"]),

        Paragraph("1. SIS Integration Methods", s["h1"]),
        Paragraph("Method A: Direct API Integration (Recommended)", s["h2"]),
        Paragraph("ParentSquare connects directly to your SIS via API for real-time or near-real-time roster sync. "
                  "Supported SIS APIs: PowerSchool (PS API v3), Infinite Campus (Campus API), Skyward REST API, "
                  "Aeries API v3, Frontline SIS.", s["body"]),
        Paragraph("API setup requires:", s["body"]),
        Paragraph("• Read-only API credentials (OAuth 2.0 or API key).", s["bullet"]),
        Paragraph("• Access to student roster, guardian contacts, and enrollment endpoints.", s["bullet"]),
        Paragraph("• IP allowlist for ParentSquare API servers (provided during onboarding).", s["bullet"]),
        Paragraph("Method B: SFTP File Drop", s["h2"]),
        Paragraph("For SIS platforms without direct API support, ParentSquare accepts nightly CSV or flat-file exports "
                  "via SFTP. Files are processed within 30 minutes of receipt.", s["body"]),
        Paragraph("Required SFTP files:", s["body"]),
        Paragraph("• students.csv: student_id, first_name, last_name, grade, school_id", s["bullet"]),
        Paragraph("• guardians.csv: guardian_id, student_id, first_name, last_name, phone, email, language", s["bullet"]),
        Paragraph("• schools.csv: school_id, school_name, principal_name, address, phone", s["bullet"]),
        Paragraph("• staff.csv: staff_id, first_name, last_name, email, role, school_id", s["bullet"]),

        Paragraph("2. Network Requirements", s["h1"]),
        Paragraph("Firewall Configuration", s["h2"]),
        Paragraph("Allow outbound HTTPS (port 443) to *.parentsquare.com. "
                  "ParentSquare does not require inbound connections from the public internet. "
                  "All integrations are initiated outbound from the district network or from ParentSquare's servers.", s["body"]),
        Paragraph("SMS Delivery", s["h2"]),
        Paragraph("SMS messages are delivered via Twilio. No special firewall rules are required for SMS delivery. "
                  "ParentSquare's Twilio short codes and long codes are pre-registered with all major US carriers.", s["body"]),
        Paragraph("Email Deliverability", s["h2"]),
        Paragraph("To maximize email delivery rates, configure the following DNS records:", s["body"]),
        Paragraph("• SPF record: include:_spf.parentsquare.com in your district domain SPF record.", s["bullet"]),
        Paragraph("• DKIM: ParentSquare will provide a DKIM public key during onboarding to add to your DNS.", s["bullet"]),
        Paragraph("• DMARC: Set to 'quarantine' or 'reject' policy after SPF/DKIM are verified.", s["bullet"]),

        Paragraph("3. Single Sign-On (SSO)", s["h1"]),
        Paragraph("ParentSquare supports SSO via Google Workspace and Microsoft Azure AD for staff accounts. "
                  "SSO for staff is configured in Settings > Authentication. Parent and guardian accounts do not support SSO.", s["body"]),
        Paragraph("Google Workspace SSO Setup", s["h2"]),
        Paragraph("1. In Google Admin Console, go to Apps > Web and Mobile Apps.", s["bullet"]),
        Paragraph("2. Add ParentSquare as a SAML app using the metadata URL provided by your CSM.", s["bullet"]),
        Paragraph("3. Map Google attributes: email → email, given_name → first_name, family_name → last_name.", s["bullet"]),
        Paragraph("4. Enable for the appropriate OU (all staff or specific roles).", s["bullet"]),
        Paragraph("5. Test with a pilot user before enabling district-wide.", s["bullet"]),

        Paragraph("4. Privacy Link (PrivateLink / VPC Peering)", s["h1"]),
        Paragraph("For districts with strict network security policies requiring traffic to remain on private networks, "
                  "ParentSquare supports AWS PrivateLink for SIS API integrations. "
                  "PrivateLink keeps data transfer between your SIS and ParentSquare entirely within the AWS backbone "
                  "without traversing the public internet.", s["body"]),
        Paragraph("PrivateLink requires:", s["body"]),
        Paragraph("• AWS account with VPC endpoint support.", s["bullet"]),
        Paragraph("• ParentSquare Service Endpoint name (provided by Technical Support).", s["bullet"]),
        Paragraph("• VPC endpoint policy configured to allow access to the ParentSquare endpoint service.", s["bullet"]),

        Paragraph("5. Data Export / Snowflake Integration", s["h1"]),
        Paragraph("Districts running analytics on Snowflake can receive a nightly export of de-identified engagement "
                  "data via S3 stage drop or Snowflake data share. This enables custom dashboards and analysis "
                  "without requiring direct platform access.", s["body"]),
        Paragraph("Available export tables:", s["body"]),
        Paragraph("• message_delivery_summary: daily delivery rates by school and channel.", s["bullet"]),
        Paragraph("• family_engagement_score: monthly engagement scores by school and grade.", s["bullet"]),
        Paragraph("• attendance_summary: daily attendance rates (requires Attendance module).", s["bullet"]),
        Paragraph("• contactability_by_school: monthly contactability snapshot.", s["bullet"]),
        Paragraph("Contact your CSM to enable Snowflake data export. Additional data sharing agreements may be required.", s["body"]),

        Paragraph("6. API Rate Limits and SLA", s["h1"]),
        Paragraph("• API rate limit: 100 requests/minute per integration account.", s["bullet"]),
        Paragraph("• Bulk sync limit: 50,000 records per batch.", s["bullet"]),
        Paragraph("• Message delivery SLA: 99.5% uptime; P1 incidents resolved within 4 hours.", s["bullet"]),
        Paragraph("• Data processing SLA: Nightly sync completed by 6:00 AM local district time.", s["bullet"]),
    ]


# ============================================================
# Build all 5 PDFs
# ============================================================
DOCS = [
    ("customer_success_playbook.pdf",  "Customer Success Playbook",               playbook_content),
    ("data_privacy_ferpa_guide.pdf",   "Data Privacy & FERPA Compliance Guide",   privacy_content),
    ("district_onboarding_guide.pdf",  "District Onboarding Guide",               onboarding_content),
    ("feature_documentation.pdf",      "Feature Documentation Guide",             feature_content),
    ("it_integration_guide.pdf",       "IT Integration Guide",                    it_content),
]

print("Generating PDFs...")
for filename, title, content_fn in DOCS:
    path = os.path.join(OUT_DIR, filename)
    build_doc(path, title, content_fn)
print(f"\nDone. {len(DOCS)} PDFs written to pdfs/")
