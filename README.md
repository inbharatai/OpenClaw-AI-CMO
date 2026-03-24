<p align="center">
  <h1 align="center">OpenClaw AI CMO</h1>
</p>

<p align="center">
  <strong>The Open-Source AI Chief Marketing Officer for Solo Builders</strong><br>
  Local-first content engine + multi-platform distribution + automated scheduling
</p>

<p align="center">
  <a href="#features"><img src="https://img.shields.io/badge/Skills-64-blue?style=flat-square" alt="Skills"/></a>
  <a href="#platforms"><img src="https://img.shields.io/badge/Platforms-12+-green?style=flat-square" alt="Platforms"/></a>
  <a href="#models"><img src="https://img.shields.io/badge/LLM-100%25%20Local-orange?style=flat-square" alt="Local LLM"/></a>
  <a href="#pipeline"><img src="https://img.shields.io/badge/Pipeline-10%20Stage-purple?style=flat-square" alt="Pipeline"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="License"/></a>
  <a href="#"><img src="https://img.shields.io/badge/Cost-$0%2Fmonth-brightgreen?style=flat-square" alt="Cost"/></a>
</p>

<p align="center">
  <a href="docs/guides/QUICKSTART.md">Quickstart</a> |
  <a href="docs/architecture/SYSTEM-ARCHITECTURE.md">Architecture</a> |
  <a href="docs/guides/PLATFORM-SETUP.md">Platform Setup</a> |
  <a href="docs/api-reference/API.md">API Reference</a> |
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

---

## What Is This?

**OpenClaw AI CMO** is a complete, local-first AI marketing operating system. It takes one content idea and turns it into multi-platform posts, visual briefs, newsletters, video scripts, and more — then approves, queues, and distributes them automatically.

**Built for solo builders** who want marketing that runs itself without paying $100-700/month for SaaS tools.

### What It Actually Does

- **You drop a note** ("shipped new API endpoint") into a folder
- **OpenClaw runs a 10-stage pipeline**: classify → enforce calendar → generate content → score quality → approve/block → create visual briefs → distribute to platform queues → report
- **Output**: website post + LinkedIn post + X post + Discord announcement + Instagram carousel brief + newsletter snippet — all from one note
- **Everything runs locally** on your machine with open-source models

This is **not** a SaaS tool. You own and operate the entire system.

---

## How It Works

```
         YOUR INPUT                          OPENCLAW PIPELINE
  (1 source note/idea)                      (10 automated stages)
          │
          ▼
  ┌──────────────┐     ┌───────────────┐     ┌──────────────┐
  │  1. INTAKE   │────▶│ 2. CALENDAR   │────▶│ 3. NEWSROOM  │
  │  scan+classify│    │   ENFORCER    │     │   + PRODUCT   │
  └──────────────┘     │  (gap detect) │     │   AGENTS     │
                       └───────────────┘     └──────┬───────┘
                                                     │
  ┌──────────────┐     ┌───────────────┐     ┌──────▼───────┐
  │  7. VISUAL   │◀────│ 6. APPROVAL   │◀────│ 5. QUALITY   │
  │   BRIEFS     │     │   ENGINE      │     │   SCORER     │
  │ carousel/    │     │ L1-L4 policy  │     │  readability  │
  │ quotes/thumb │     └───────────────┘     │  hook/CTA/fit│
  └──────┬───────┘                           └──────────────┘
         │                                          ▲
         ▼                                          │
  ┌──────────────┐     ┌───────────────┐     ┌──────────────┐
  │ 8. DISTRIBUTE│────▶│  9. REPORT    │     │ 4. CONTENT   │
  │  to queues + │     │  daily/weekly │     │   AGENT      │
  │  SocialFlow  │     │  /monthly     │     │ multi-channel│
  └──────────────┘     └───────────────┘     └──────────────┘
         │
         ▼
  ┌──────────────────────────────────────────┐
  │            SOCIALFLOW ENGINE              │
  │  LinkedIn │ X │ Instagram │ Discord │     │
  │  Facebook │ Reddit │ Medium │ Substack │  │
  │  HeyGen (video) │ Email │ YouTube       │
  └──────────────────────────────────────────┘
```

---

## Features

### Content Engine — 64 Skills

| Category | What It Does |
|----------|-------------|
| **Content Production** | Website updates, articles, AI news summaries, product updates, social repurposing, newsletters, weekly roundups, comparison posts, educational content, build logs |
| **Visual Content** | Carousel packs (slide-by-slide with design system), quote cards (3 styles), thumbnails (A/B/C options), story frames, AI image prompts, full creative packs |
| **Approval & Safety** | 4-level policy engine, risk scoring, duplicate checking, credential detection, PII blocking, channel policy enforcement, rate limiting |
| **Distribution** | Channel-specific formatting, posting queues, SocialFlow bridge, Discord webhooks, newsletter export |
| **Research & Growth** | Trend-to-content, competitor monitoring, SEO topic mapping, audience angles, content strategy |

### Content Intelligence

| Feature | What It Does |
|---------|-------------|
| **Calendar Enforcer** | Checks weekly posting targets per platform. Detects gaps. Auto-creates content production requests when behind schedule. |
| **Quality Scorer** | Scores every piece on readability, hook strength, CTA clarity, platform fit, formatting, uniqueness (0-100). Flags content below threshold. |
| **Analytics Engine** | Tracks post-publish performance: impressions, engagement, reach. Compares by content type and pillar. 5 API endpoints. |
| **Proactive Gap Detection** | Doesn't just wait for source notes — identifies missing platform content and pillar imbalances. |

### SocialFlow Posting Engine

| Platform | Method | Status |
|----------|--------|--------|
| LinkedIn | Browser automation (Playwright) | Ready — awaits credentials |
| X / Twitter | Browser automation (Playwright) | Ready — awaits credentials |
| Instagram | Browser automation (Playwright) | Ready — awaits credentials |
| Facebook | Browser automation (Playwright) | Ready — awaits credentials |
| Discord | Webhook API | Ready — awaits webhook URL |
| Reddit | Browser automation (Playwright) | Ready — draft-first |
| Medium | Browser automation (Playwright) | Ready — awaits credentials |
| Substack | Browser automation (Playwright) | Ready — awaits credentials |
| HeyGen | Browser automation (native adapter) | Ready — awaits credentials |
| beehiiv | Browser automation (Playwright) | Ready — awaits credentials |
| MailerLite | Browser automation (Playwright) | Ready — awaits credentials |
| Brevo | Browser automation (Playwright) | Ready — awaits credentials |

### Pipeline Automation — 10 Stages

| Stage | What It Does | Speed |
|-------|-------------|-------|
| 1. Intake | Scan and classify source files | ~1s |
| 1b. Calendar Enforcer | Check weekly targets, detect content gaps | ~2s |
| 2a. Newsroom Agent | Process AI news into channel variants | ~30s |
| 2b. Product Update Agent | Generate product update posts | ~30s |
| 2c. Content Agent | Multi-channel content production | ~60s |
| 3a. Quality Scorer | Score content quality before approval | ~10s |
| 3b. Approval Engine | 4-level policy scoring (L1 instant, L2 fast, L3 review, L4 block) | ~5s |
| 3c. Visual Brief Generator | Create carousel/quote/thumbnail packs from approved content | ~30s |
| 4. Distribution | Route to platform queues + SocialFlow | ~2s |
| 5. Report | Generate daily/weekly/monthly pipeline reports | ~10s |

### Scheduling — Live on macOS

| Schedule | Trigger | What Runs |
|----------|---------|-----------|
| **Daily** | 6:00 AM (launchd) | Full 10-stage pipeline |
| **Weekly** | Monday 8:00 AM | Weekly roundup, editorial calendar, video briefs, newsletter |
| **Monthly** | 1st of month 9:00 AM | Content pillar review, campaign refresh, performance summary |

---

## Architecture

### 3-Layer Model Router

| Layer | Model | Latency | Used For |
|-------|-------|---------|----------|
| **Fast** | qwen2.5-coder:7b | <5s | Formatting, classification, scoring, approvals |
| **Thinking** | qwen3:8b | 15-60s | Content generation, strategy, articles, complex reasoning |
| **Recorder** | n/a (async) | 0ms | Timing metrics, audit trail, pipeline events |

### Tech Stack

| Component | Technology |
|-----------|-----------|
| Orchestration | OpenClaw CLI (bash) |
| Content Intelligence | 64 SKILL.md prompt files |
| Local LLM | Ollama + qwen3:8b + qwen2.5-coder:7b |
| Posting Engine | SocialFlow (FastAPI + Playwright) |
| Video Generation | HeyGen (browser-based, native SocialFlow adapter) |
| Approval | Regex + fast-model scoring + JSON policy rules |
| Analytics | SQLite + FastAPI REST API |
| Scheduling | macOS launchd (daily/weekly/monthly agents) |
| Visual Content | Carousel/quote-card/thumbnail skill-based text packs |
| Date Grounding | Central date-context.sh injected into all prompts |
| Config | `configs/openclaw.yaml` (models, calendar, pillars, quality gates) |
| Storage | Local filesystem (Markdown + JSON + SQLite) |

---

## Quick Start

### Prerequisites

- macOS (scheduling uses launchd) or Linux (use cron)
- [Ollama](https://ollama.com) installed
- Python 3.9+

### 1. Clone & Setup

```bash
git clone https://github.com/inbharatai/OpenClaw-AI-CMO.git
cd OpenClaw-AI-CMO
./setup.sh
```

### 2. Pull Models

```bash
ollama pull qwen3:8b           # Thinking layer (content generation)
ollama pull qwen2.5-coder:7b   # Fast layer (scoring, formatting)
```

### 3. Configure

```bash
# Edit configs to match your setup
nano configs/openclaw.yaml   # Set timezone, posting targets, content pillar mix
```

### 4. Run Your First Pipeline

```bash
# Drop a source note
echo "Launched new AI-powered analytics dashboard with real-time insights" > data/source-notes/my-first-update.md

# Run the daily pipeline (10 stages)
./openclaw daily

# Or run individual stages
./openclaw intake        # Just intake
./openclaw approve       # Just approval
./openclaw status        # System health check
```

### 5. Start SocialFlow (for posting)

```bash
cd socialflow/backend
pip install -r requirements.txt
playwright install chromium
python main.py
# Dashboard at http://localhost:8000
# API docs at http://localhost:8000/docs
```

### 6. Activate Scheduling

```bash
# Install launchd agents
./openclaw-engine/scripts/install-schedule.sh

# Verify
launchctl list | grep openclaw

# Remove
./openclaw-engine/scripts/install-schedule.sh --uninstall
```

---

## Project Structure

```
OpenClaw-AI-CMO/
├── openclaw                    # Main CLI (./openclaw daily|status|skill...)
├── setup.sh                    # One-command setup
├── configs/
│   └── openclaw.yaml           # Master config (models, calendar, pillars, quality)
│
├── openclaw-engine/            # The AI CMO brain
│   ├── scripts/                # 24 pipeline + utility scripts
│   │   ├── daily-pipeline.sh   # 10-stage daily orchestrator
│   │   ├── calendar-enforcer.sh# Content gap detection
│   │   ├── quality-scorer.sh   # Content quality gate
│   │   ├── visual-brief-generator.sh # Visual content system
│   │   ├── skill-runner.sh     # Executes any skill with local LLM
│   │   ├── layer-router.sh     # Fast/Think/Recorder model routing
│   │   ├── install-schedule.sh # macOS launchd setup
│   │   └── ollama-call.py      # Safe LLM API caller
│   ├── skills/                 # 64 skill definitions (SKILL.md)
│   ├── policies/               # Approval rules, brand voice, rate limits
│   └── memory/                 # Persistent pipeline state
│
├── socialflow/                 # Multi-platform posting engine
│   ├── backend/                # FastAPI server (53 API endpoints)
│   │   ├── main.py             # Server + content generation routes
│   │   ├── automation.py       # LinkedIn, Instagram, X automation
│   │   ├── automation_extended.py # Facebook, Reddit, Medium, Substack, Discord, Email
│   │   ├── heygen_adapter.py   # HeyGen native video adapter + job state machine
│   │   ├── heygen_routes.py    # HeyGen API endpoints
│   │   ├── asset_inventory.py  # Content asset tracking + distribution queue
│   │   ├── analytics_store.py  # Post-publish performance analytics
│   │   ├── visual_content_routes.py # Visual brief generation API
│   │   └── openclaw_bridge.py  # OpenClaw → SocialFlow bridge
│   └── frontend/               # Web dashboard
│
├── data/                       # Content workspace (22 subdirectories)
├── queues/                     # Per-platform approval queues
├── approvals/                  # approved/ blocked/ review/ pending/
├── reports/                    # daily/ weekly/ monthly/
├── logs/                       # Pipeline and scheduling logs
├── exports/                    # Posted content archive
├── tests/                      # Test scripts
└── docs/                       # 13 architecture + guide documents
```

---

## Approval Model

Every piece of content goes through a 4-level policy engine before distribution:

| Level | Name | Action | Examples |
|-------|------|--------|----------|
| **L1** | Auto-Approve | Instant (0ms, no LLM) | Product updates, build logs, Discord announcements |
| **L2** | Score-Gated | Auto if score > threshold (~5s) | AI news, educational posts, comparisons |
| **L3** | Review Queue | Held for human review | Bold claims, competitor content, PR-sensitive |
| **L4** | Block | Rejected automatically | Credentials, PII, unverifiable claims, spam patterns |

**Scoring dimensions:** Source confidence (25%) · Claim sensitivity (25%) · Brand voice (15%) · Data safety (15%) · Duplication (10%) · Platform risk (10%)

---

## Visual Content System

One source idea generates a complete visual content kit:

| Type | Output | Platforms |
|------|--------|-----------|
| **Carousel Pack** | 5-7 slides with design system, per-slide text, visual direction | Instagram, LinkedIn |
| **Quote Cards** | 3 cards with styles, attribution, platform sizing | Instagram, LinkedIn, X |
| **Thumbnails** | 3 A/B/C options with headline formulas | YouTube, articles |
| **Story Frames** | 3-frame story sequences | Instagram, LinkedIn |
| **Image Prompts** | 3 AI image generation prompts | Midjourney, DALL-E, Flux |
| **Creative Pack** | All of the above from one source | All platforms |

---

## Analytics

Post-publish performance tracking with SQLite + REST API:

| Endpoint | What It Does |
|----------|-------------|
| `POST /api/analytics/metrics` | Record post performance data |
| `GET /api/analytics/platform/{name}` | Performance by platform |
| `GET /api/analytics/top-content-types` | Best-performing content types |
| `GET /api/analytics/pillars` | Performance by content pillar |
| `GET /api/analytics/weekly-summary` | Weekly performance overview |

---

## HeyGen Video Integration

HeyGen is integrated as a native SocialFlow adapter (not a side script):

```
Script input → HeyGen job (draft → queued → generating → completed → ready)
                                                              │
                                    ┌─────────────────────────┤
                                    ▼                         ▼
                              Asset Inventory          Platform Queue
                              (SQLite tracked)     IG reel │ YT Short │
                                                   LI post │ X clip  │
                                                   Discord attachment
```

| Feature | Status |
|---------|--------|
| Job state machine (6 states) | Verified |
| Asset inventory registration | Verified |
| Platform-specific distribution (7 rules) | Verified |
| Browser-based auth (Playwright) | Ready — awaits credentials |
| Full lifecycle: create → register → distribute | Verified |

---

## What You Do Daily

| Your Time | What You Do | What OpenClaw Does |
|-----------|-------------|-------------------|
| **2 min** | Drop 1 source note into `data/source-notes/` | Everything else |
| **0 min** | Nothing — pipeline runs at 6 AM | Intake → Calendar check → Generate → Score → Approve → Visual briefs → Distribute → Report |
| **5 min/week** | Review the weekly report, check `approvals/review/` | Weekly roundup, newsletter draft, editorial calendar |

---

## Security & Safety

- All credentials encrypted with Fernet (AES-128-CBC)
- Browser sessions stored locally, never transmitted
- Rate limiting enforced per platform (configurable in `openclaw.yaml`)
- Daily posting caps prevent spam
- No cloud APIs required for core operation
- Workspace guard prevents operations outside project folder
- PII/credential regex detection blocks sensitive content
- Full audit trail for every pipeline run

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  Built by <a href="https://github.com/inbharatai">INBharat AI</a> · <a href="mailto:info@inbharat.ai">info@inbharat.ai</a>
</p>

<p align="center">
  <code>#OpenClaw</code> · <code>#AICMO</code> · <code>#OpenSource</code> · <code>#MarketingAutomation</code> · <code>#SoloBuilder</code> · <code>#LocalAI</code> · <code>#ContentOps</code> · <code>#AIMarketing</code> · <code>#BuildInPublic</code>
</p>
