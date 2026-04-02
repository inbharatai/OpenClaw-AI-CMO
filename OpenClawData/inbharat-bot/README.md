# InBharat Bot v3.1

**Your AI-powered strategic operator.** 13 intelligence lanes: scan opportunities, create content, draft outreach, build prototypes, manage leads, monitor communities, and auto-publish — all from one orchestrator.

Last updated: 2026-04-02

---

## Quick Start

```bash
cd /Volumes/Expansion/CMO-10million
bash OpenClawData/inbharat-bot/inbharat-run.sh help
```

Or text OpenClaw on WhatsApp: "create a LinkedIn post about Phoring"

---

## 13 Lanes

| Lane | Command prefix | What it does |
|------|---------------|--------------|
| Media | `media native/video/image/amplify/full` | Create platform-native content |
| Review | `media status/review/approve/reject/publish` | Approve and publish content |
| India Problems | `india-problems scan` | Scan real problems to solve |
| AI Gaps | `ai-gaps scan` | Find gaps in AI market |
| Funding | `funding scan` | Find grants and funding |
| Competitors | `competitor scan` | Analyze AI competitors |
| Ecosystem | `ecosystem scan` | Scan workspace and repos |
| Community | `community scan/engagement/suggest` | Community intelligence |
| Outreach | `outreach research/campaign/status/followup` | Email campaigns |
| Government | `government scan/propose` | Government tenders and proposals |
| Learning | `learning review` | Review feedback, improve quality |
| Prototype | `prototype build/pipeline/launch/package` | Build and ship solutions |
| Reddit | `reddit draft/list/subreddits` | Draft Reddit posts for manual posting |

Plus: `opportunities all`, `leads capture/status`, `revenue process/followups`, `status`

---

## Operating Directives

Bot now runs with autonomous operating directives from `OpenClawData/directives/`:
- Full system prompt with autonomy tiers (Tier 0-3)
- 20 standing founder orders
- 7-role QA chain before publishing
- Self-correction rules (anti-intern behavior)

`bot-config.json` now includes `autonomy_tiers` defining what's fully autonomous vs founder-gated.

---

## Content Creation Flow

```
1. You say: "create a LinkedIn post about Phoring"
2. Bot runs: media native --product phoring --platform linkedin
3. Bot generates content package (JSON) with hook, body, hashtags, CTA
4. Content lands in queues/linkedin/pending/
5. You say: "approve phoring-linkedin-2026-04-01.json"
6. Bot validates claims → checks platform session → posts → archives → logs feedback
```

**Video flow adds steps:**
- After content package, bot generates video brief or HeyGen production brief
- 10 distinct video formats prevent repetitive content
- HeyGen avatar videos for professional talking-head content

---

## Architecture

```
inbharat-run.sh (master orchestrator)
│
├── Media ──────────────► openclaw-media/native-pipeline/ → generate-content.sh
│                        ► openclaw-media/amplify-pipeline/ → amplify-handoff.sh
│                        ► openclaw-media/video-engine/ → generate-video.sh
│                        ► openclaw-media/posting-engine/ → post_{platform}.py
│
├── Intelligence ───────► opportunities/world-scanner.sh (DuckDuckGo + Ollama)
│                        ► gap-finder/gap-finder.sh
│                        ► scanner/ecosystem-scanner.sh
│
├── Outreach ───────────► outreach/outreach-engine.sh (research, campaign, followup)
│
├── Prototype ──────────► prototypes/prototype-builder.sh → scout-build-launch.sh
│
├── Revenue ────────────► leads/lead-capture.sh → revenue/revenue-engine.sh
│
├── Community ──────────► skills/community-intelligence/ (scan, engagement, suggest)
│
├── Learning ───────────► analytics/feedback-collector.sh → weekly summaries
│
├── Government ─────────► government/government-scanner.sh → proposal builder
│
└── Shared
    ├── approval/approval-gate.sh (action classification)
    ├── logging/bot-logger.sh (timestamped logs)
    ├── config/bot-config.json (model config)
    └── skills/ (prompt templates per lane)
```

## Approval Pipeline

| Level | Gate | Examples |
|---|---|---|
| L1 Auto | Type-based bypass | Internal updates, Discord announcements |
| L2 Score | AI scores 0-100, threshold 70 | Blog posts, social content |
| L3 Review | Requires your approval | External emails, partnership outreach |
| L4 Block | Hard-blocked | Credential claims, unverified statistics |

**On approve:** claim validation → session check → post → archive → feedback loop

---

## Models

| Model | Used for | Cost |
|---|---|---|
| qwen3:8b (Ollama) | All content generation, analysis, drafting | Free (local) |
| GPT-OSS 120B (Groq) | Gateway agent conversations | Free tier |
| OpenAI | Image generation only | Per-image |
| HeyGen | Avatar video creation (browser-operated) | Free tier / paid |

---

## Key Paths

| What | Where |
|------|-------|
| Master orchestrator | `inbharat-run.sh` |
| Scan reports | `opportunities/reports/` |
| Email drafts | `outreach/drafts/` |
| Prototypes | `prototypes/builds/` |
| Lead data | `leads/data/` |
| Content queues | `../queues/{platform}/{state}/` |
| Video format library | `../strategy/video-format-library.json` |
| Website context | `../strategy/website-context.md` |
| Logs | `logging/bot-*.log` |

---

## Important Notes

- **External HD must be connected** — everything lives on `/Volumes/Expansion/`
- **Ollama must be running** — powers all AI features
- **Nothing auto-publishes without approval** — approval-first system
- **WhatsApp is the primary interface** — natural language mapping to commands
- **Platform logins needed once** — LinkedIn, X, Instagram via Playwright browser sessions

---

## Daily Auto-Content

The daily auto-content engine (`scripts/daily-auto-content.sh`) runs at 9 AM:
- Rotates through 7 products and 7 content buckets daily
- Generates content for LinkedIn, X, Discord, Instagram Reels, YouTube Shorts
- Blog articles every 3 days, Reddit drafts every 5 days
- Runs intelligence scan (rotating: india-problems, ai-gaps, funding, competitors, ecosystem)
- Sends WhatsApp summary after completion

## Session Management

- Chrome cookies auto-synced to Playwright sessions (`sync-chrome-sessions.sh`)
- Session keepalive runs every 6h, alerts via WhatsApp on expiry
- No manual `--login` needed — sessions maintained from Chrome browser
