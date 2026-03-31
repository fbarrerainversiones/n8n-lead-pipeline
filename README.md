# ⚡ n8n Lead Processing Pipeline — AI-Powered Lead Qualification & Routing

A production-grade **n8n workflow** that captures leads from Meta Ads (Facebook/Instagram), qualifies them with **Gemini AI**, stores them in **Supabase**, and sends real-time HTML email alerts. Handles multi-country routing (Ecuador, Colombia, Peru) with automatic phone prefix detection.

> **Status:** ✅ Live in production — processing leads 24/7 since 2025

---

## Architecture

```
┌──────────────┐    Webhook     ┌──────────────────────────────────────┐
│  Meta Ads    │ ──────────────▶│          n8n Workflow (33+ nodes)    │
│  Lead Forms  │                │                                      │
│  (FB + IG)   │                │  ┌─────────┐   ┌──────────────────┐ │
└──────────────┘                │  │ Country  │   │  Gemini 2.5      │ │
                                │  │ Detection│──▶│  Flash AI        │ │
                                │  │ (prefix) │   │  Qualification   │ │
                                │  └─────────┘   └────────┬─────────┘ │
                                │                          │           │
                                │  ┌──────────────────────▼────────┐  │
                                │  │         Supabase              │  │
                                │  │    (PostgreSQL)               │  │
                                │  │  • leads table                │  │
                                │  │  • qualification scores       │  │
                                │  │  • country routing            │  │
                                │  └──────────────┬────────────────┘  │
                                │                  │                   │
                                │  ┌──────────────▼────────────────┐  │
                                │  │     HTML Email Alert          │  │
                                │  │  → Advisor notification       │  │
                                │  │  → Lead summary + score       │  │
                                │  └───────────────────────────────┘  │
                                └──────────────────────────────────────┘
```

## Key Features

- **Meta Ads Integration** — Webhook captures leads from Facebook and Instagram lead forms in real-time
- **AI Qualification** — Gemini 2.5 Flash analyzes lead data and assigns qualification scores based on configurable criteria
- **Multi-Country Routing** — Automatic country detection via phone prefix (+593 Ecuador, +57 Colombia, +51 Peru) with country-specific routing logic
- **Supabase Storage** — All leads persisted in PostgreSQL with full audit trail
- **HTML Email Alerts** — Rich email notifications with lead details, qualification score, and recommended actions
- **Error Handling** — Retry logic, fallback paths, and error notifications for failed processing
- **Duplicate Detection** — Prevents duplicate lead entries from Meta's webhook retry behavior

## Workflow Overview

```
1. TRIGGER       → Meta Ads Webhook receives lead data
2. PARSE         → Extract name, phone, email, form responses
3. DETECT        → Identify country from phone prefix
4. VALIDATE      → Check for duplicates in Supabase
5. QUALIFY       → Send lead context to Gemini AI for scoring
6. STORE         → Insert qualified lead into Supabase
7. NOTIFY        → Send HTML email alert to assigned advisor
8. LOG           → Record processing status and metadata
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Automation | n8n (self-hosted, Docker) |
| AI Model | Google Gemini 2.5 Flash |
| Database | Supabase (PostgreSQL) |
| Lead Source | Meta Ads API (webhooks) |
| Notifications | SMTP (HTML emails) |
| Infrastructure | Ubuntu 24 VPS, Docker, Nginx |
| DNS/CDN | Cloudflare |

## n8n Workflow Nodes (33+)

| Node Type | Purpose |
|-----------|---------|
| Webhook | Receive Meta lead form submissions |
| Set | Parse and normalize lead fields |
| Switch | Route by country prefix |
| IF | Duplicate check logic |
| HTTP Request | Gemini AI API call for qualification |
| Code (JS) | Phone parsing, score calculation |
| Supabase | Insert/query lead records |
| Send Email | HTML-formatted advisor alerts |
| Error Trigger | Catch and log failures |

## How to Deploy

### Prerequisites
- n8n instance (self-hosted or cloud)
- Supabase project with `leads` table
- Google AI API key (Gemini)
- Meta Business Suite with lead forms configured
- SMTP credentials for email alerts

### Setup

1. **Import the workflow:**
   ```
   n8n Dashboard → Import Workflow → Select workflow.json
   ```

2. **Configure credentials in n8n:**
   - Supabase API (URL + service key)
   - Google Gemini (API key via Header Auth)
   - SMTP (email server credentials)

3. **Set up Meta webhook:**
   - Copy the n8n webhook URL
   - Paste in Meta Business Suite → Lead Forms → CRM Integration

4. **Create Supabase table:**
   ```sql
   CREATE TABLE leads (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     full_name TEXT NOT NULL,
     phone TEXT NOT NULL,
     email TEXT,
     country TEXT,
     source TEXT DEFAULT 'meta_ads',
     form_name TEXT,
     qualification_score INTEGER,
     qualification_notes TEXT,
     status TEXT DEFAULT 'new',
     assigned_to TEXT,
     processed_at TIMESTAMPTZ
   );
   ```

5. **Activate the workflow** and test with a sample lead form submission.

## AI Qualification Prompt Structure

The Gemini AI qualification uses a structured prompt that evaluates:

```
- Contact completeness (name, phone, email)
- Phone format validity
- Form response quality (detailed vs generic answers)
- Intent signals from form responses
- Country-specific scoring adjustments
```

Output: Qualification score (1-10) + reasoning + recommended follow-up action.

## Production Lessons Learned

1. **Meta Webhook Retries** — Meta retries failed webhook deliveries, causing duplicate leads. Solved with Supabase UPSERT on phone number + timestamp window.
2. **Gemini Token Limits** — Set `maxOutputTokens: 8192` to prevent truncated qualification responses on leads with long form answers.
3. **Phone Prefix Edge Cases** — Some users enter numbers without country code. Added fallback logic using the lead form's country field.
4. **HTML Email Rendering** — Built custom HTML templates instead of plain text for email alerts. Advisors process leads 3x faster with formatted summaries.
5. **Batch Processing** — For high-volume campaigns, implemented batch concurrency limits to prevent n8n worker saturation.

## Monitoring

- **n8n Execution Log** — All workflow runs are logged with input/output data
- **Supabase Dashboard** — Real-time lead count and status tracking
- **Email Alerts** — Immediate notification on both successful processing and errors

## Customization

This workflow is designed as a **template** — adapt it for any lead-based business:

| Setting | Where to Change |
|---------|----------------|
| Qualification criteria | Gemini system prompt node |
| Country routing rules | Switch node conditions |
| Email template | Send Email node HTML |
| Lead fields | Supabase table schema + Set nodes |
| Notification recipients | Email node "To" field |

## License

MIT

---

**Built by [Francisco Barrera](https://linkedin.com/in/franciscobarrera-ai)** — LLM Engineer & AI Automation Architect
