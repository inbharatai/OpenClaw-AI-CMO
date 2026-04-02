# OpenClaw — Autonomous Executive Operating System

**The AI-powered operating system that runs InBharat's entire growth, content, outreach, and intelligence operation.**

Version 4.2 | Last updated: 2026-04-02 | [github.com/inbharatai/OpenClaw-AI-CMO](https://github.com/inbharatai/OpenClaw-AI-CMO)

[![CI](https://github.com/inbharatai/OpenClaw-AI-CMO/actions/workflows/ci.yml/badge.svg)](https://github.com/inbharatai/OpenClaw-AI-CMO/actions/workflows/ci.yml)

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     FOUNDER (WhatsApp / Terminal)                     │
│  "create a LinkedIn post about Phoring" / "scan for funding"         │
└──────────────────────────┬──────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  OPENCLAW RUNTIME                                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │ Gateway      │  │ WhatsApp     │  │ Browser Automation       │   │
│  │ Port :18789  │→ │ Baileys      │  │ Playwright Sessions      │   │
│  │ Agent Router │  │ Provider     │  │ LinkedIn│X│Insta│Zoho    │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘   │
│                           │                                          │
│  ┌────────────────────────▼─────────────────────────────────────┐   │
│  │  INBHARAT BOT — Internal Intelligence Layer                   │   │
│  │  (NOT a separate platform — runs inside OpenClaw)             │   │
│  │                                                               │   │
│  │  13 Intelligence Lanes:                                       │   │
│  │  ┌─────────┐ ┌──────────┐ ┌───────────┐ ┌──────────────┐    │   │
│  │  │ Media   │ │ India    │ │ AI Gaps   │ │ Funding      │    │   │
│  │  │ Engine  │ │ Problems │ │ Discovery │ │ & Grants     │    │   │
│  │  └─────────┘ └──────────┘ └───────────┘ └──────────────┘    │   │
│  │  ┌─────────┐ ┌──────────┐ ┌───────────┐ ┌──────────────┐    │   │
│  │  │Compete  │ │Ecosystem │ │ Community │ │ Outreach     │    │   │
│  │  │Monitor  │ │ Scanner  │ │ Intel     │ │ & Campaigns  │    │   │
│  │  └─────────┘ └──────────┘ └───────────┘ └──────────────┘    │   │
│  │  ┌─────────┐ ┌──────────┐ ┌───────────┐ ┌──────────────┐    │   │
│  │  │Gov &    │ │ Learning │ │ Prototype │ │ Reddit       │    │   │
│  │  │Tenders  │ │ & Review │ │ Builder   │ │ Drafting     │    │   │
│  │  └─────────┘ └──────────┘ └───────────┘ └──────────────┘    │   │
│  │                         ↕ Revenue & Lead Pipeline             │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                           │                                          │
│  ┌────────────────────────▼─────────────────────────────────────┐   │
│  │  CONTENT FACTORY (openclaw-media/)                            │   │
│  │                                                               │   │
│  │  Generation:          Publishing:          Analytics:         │   │
│  │  ┌──────────────┐    ┌──────────────┐    ┌───────────────┐   │   │
│  │  │Native Pipeline│    │Approval Gate │    │Post Logging   │   │   │
│  │  │(Ollama qwen3) │    │L1→L2→L3→L4  │    │Feedback Loop  │   │   │
│  │  ├──────────────┤    ├──────────────┤    │Performance    │   │   │
│  │  │DALL-E 3      │    │Claim Validate│    └───────────────┘   │   │
│  │  │Image Engine  │    │Brand Check   │                        │   │
│  │  ├──────────────┤    ├──────────────┤                        │   │
│  │  │ffmpeg Video  │    │Queue Manager │                        │   │
│  │  │(local, free) │    │pending→post  │                        │   │
│  │  ├──────────────┤    ├──────────────┤                        │   │
│  │  │HeyGen Briefs │    │Platform Post │                        │   │
│  │  │(gated queue) │    │LinkedIn│X│IG │                        │   │
│  │  └──────────────┘    └──────────────┘                        │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │  OPERATING DIRECTIVES (directives/)                            │   │
│  │  Autonomy Tiers │ QA Chain │ Credential Rules │ Self-Correct  │   │
│  └───────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LIVE PLATFORM CONNECTIONS                                           │
│  ┌──────────┐ ┌────────┐ ┌───────────┐ ┌─────────┐ ┌────────────┐ │
│  │ LinkedIn │ │   X    │ │ Instagram │ │ Discord │ │ Zoho Mail  │ │
│  │ ✅ Live  │ │ ✅ Live│ │ ✅ Live   │ │ ✅ Live │ │ ✅ Live    │ │
│  │Playwright│ │Playwrt │ │Playwright │ │ Webhook │ │ Playwright │ │
│  └──────────┘ └────────┘ └───────────┘ └─────────┘ └────────────┘ │
│  ┌──────────┐                                                       │
│  │ Reddit   │  Draft-only (L3 manual) — no auto-posting             │
│  │ 📝 Draft │                                                       │
│  └──────────┘                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Products in Ecosystem

| Product | What it does | Website | Status |
|---|---|---|---|
| **InBharat.ai** | AI tools company — parent brand | [inbharat.ai](https://inbharat.ai) | Live |
| **Phoring** | Smart communication layer | [phoring.in](https://phoring.in) | Live |
| **TestsPrep** | AI-powered test preparation | [testsprep.in](https://testsprep.in) | Live |
| **UniAssist** | University application assistant | [uniassist.ai](https://uniassist.ai) | Live |
| **Sahaayak** | AI helper for everyday tasks | [sahaayak.ai](https://sahaayak.ai) | Live |
| **CodeIn** | Code learning platform | — | In development |
| **OpenClaw** | This system — autonomous ops engine | [GitHub](https://github.com/inbharatai/OpenClaw-AI-CMO) | Live |
| **Agent Arcade** | AI agent gateway | [GitHub](https://github.com/inbharatai/agent-arcade-gateway) | In development |

### GitHub Repositories (Monitored)
- [inbharatai/OpenClaw-AI-CMO](https://github.com/inbharatai/OpenClaw-AI-CMO)
- [inbharatai/phoring](https://github.com/inbharatai/phoring)
- [inbharatai/agent-arcade-gateway](https://github.com/inbharatai/agent-arcade-gateway)
- [inbharat-ai/uniassist.ai](https://github.com/inbharat-ai/uniassist.ai)
- [inbharat-ai/testsprep.in](https://github.com/inbharat-ai/testsprep.in)
- [inbharatai/sahaayak-ai-public](https://github.com/inbharatai/sahaayak-ai-public)

---

## How It Works

### Content Flow
```
Signal Discovered → Scored → Content Generated → QA Chain (7 roles) → Queued → Approved → Posted
```

### Autonomy Tiers

| Tier | What | Examples |
|---|---|---|
| **T0 — Fully Autonomous** | No approval needed | Text posts, images, carousels, research, drafts, scheduling, community updates, outreach prep |
| **T1 — Approved Connectors** | Uses saved sessions/keys | Browser posting, email drafts, analytics reads |
| **T2 — Ask If Needed** | Real blockers only | Missing secrets, new integrations, threshold exceeded |
| **T3 — Always Gated** | Founder must approve | HeyGen avatar videos, new skill installs, downloads, financial/legal commitments |

### Internal QA Chain (7 Roles)
Every piece of content passes through:
1. **Research Analyst** — verify facts and sources
2. **Strategist** — confirm growth/trust value
3. **Writer** — make it sharp and platform-native
4. **Brand Reviewer** — ecosystem alignment check
5. **Accuracy Reviewer** — reject hallucinations
6. **Publisher** — publish, schedule, or skip
7. **Performance Analyst** — log objectives and compare

---

## Platform Publishing

### Live Connections

| Platform | Engine | How it posts | Session |
|---|---|---|---|
| **LinkedIn** | `post_linkedin.py` | Playwright browser automation | `~/.openclaw/browser-sessions/linkedin/` |
| **X/Twitter** | `post_x.py` | Playwright browser automation | `~/.openclaw/browser-sessions/x/` |
| **Instagram** | `post_instagram.py` | Playwright (mobile UA, image required) | `~/.openclaw/browser-sessions/instagram/` |
| **Discord** | `post_discord.py` | Webhook (curl, no browser) | Keychain: `discord-webhook` |
| **Zoho Mail** | `email_zoho.py` | Playwright (visible mode, Zoho blocks headless) | `~/.openclaw/browser-sessions/zoho/` |
| **Reddit** | Draft only | `inbharat-run.sh reddit draft` | Manual posting (L3) |

### Platform Content Rules

| Platform | Tone | Format | Max Length |
|---|---|---|---|
| **LinkedIn** | Professional, insightful | Text + line breaks, 5 hashtags max | 3000 chars |
| **X** | Sharp, fast, direct | Plain text, 3 hashtags max | 280 chars / 8-tweet threads |
| **Instagram** | Visual-first, engaging | Caption + image/carousel, 10-15 hashtags | 2200 chars |
| **Discord** | Community-friendly | Markdown, embed-friendly | 2000 chars |
| **Reddit** | Genuine, non-promotional | Reddit markdown, value-first | 10000 chars |

### Session Management
- **Keepalive cron**: Every 6 hours — refreshes all sessions
- **Cookie sync**: Chrome cookies → Playwright sessions
- **Re-login**: `python3 post_<platform>.py --login`

---

## Image & Video Generation

```
Content Package
      │
      ├──► DALL-E 3 ──► Post Image (autonomous, $0.04/image, 10/day cap)
      │
      ├──► ffmpeg ────► Text Animation / Slideshow / Quote Card (free, local)
      │
      └──► HeyGen ───► Avatar Video Brief → Founder Queue (Tier 3 gated)
```

| Type | Tool | Cost | Autonomous? |
|---|---|---|---|
| Post images, cards, covers | DALL-E 3 (OpenAI API) | ~$0.04/image | Yes — 10/day budget cap |
| Text animations | ffmpeg (local) | Free | Yes |
| Slideshows with transitions | ffmpeg (local) | Free | Yes |
| Ken Burns zoom | ffmpeg (local) | Free | Yes |
| Quote card videos | ffmpeg (local) | Free | Yes |
| Avatar presenter videos | HeyGen | Paid | No — founder-gated (Tier 3) |

### Commands
```bash
# Images
generate-image.sh "AI brain connected to India map" --size square
generate-image.sh "Educational carousel slide" --size portrait
generate-image.sh --budget  # Check today's spend

# Videos
generate-video-local.sh text "Building AI for India" --size 1080x1920
generate-video-local.sh slideshow img1.png img2.png img3.png
generate-video-local.sh quote "Think like an owner" --author "Reeturaj Goswami"
generate-video-local.sh kenburns photo.png --duration 8
```

---

## Approval System

```
Content Generated
      │
      ▼
┌─────────────────┐
│ Claim Validator  │──► Blocks: fabricated stats, unverified claims, credentials
└────────┬────────┘
         ▼
┌─────────────────┐     ┌──────────────────────┐
│ L1: Auto-Approve│────►│ Standard posts,       │
│                 │     │ Discord, community     │
└─────────────────┘     └──────────────────────┘
┌─────────────────┐     ┌──────────────────────┐
│ L2: Score-Gated │────►│ Product claims,       │
│                 │     │ industry commentary    │
└─────────────────┘     └──────────────────────┘
┌─────────────────┐     ┌──────────────────────┐
│ L3: Review Queue│────►│ Reddit, HeyGen video, │
│                 │     │ bold claims, outreach  │
└─────────────────┘     └──────────────────────┘
┌─────────────────┐     ┌──────────────────────┐
│ L4: Hard Block  │────►│ Unverified funding,   │
│                 │     │ credentials, legal     │
└─────────────────┘     └──────────────────────┘
```

---

## Cron Schedule

| Time | Job | Script |
|---|---|---|
| Every hour (:00) | WhatsApp status report | `hourly-whatsapp-report.sh` |
| Every 6h (0/6/12/18) | Session keepalive | `session-keepalive.sh` |
| 8:07 AM daily | Full CMO pipeline | `daily-pipeline.sh` |
| 9:00 AM daily | Auto-content generation | `daily-auto-content.sh` |
| Monday 7:53 AM | Weekly review | `weekly-pipeline.sh` |
| 1st of month 7:42 AM | Monthly review | `monthly-pipeline.sh` |

---

## Intelligence Commands

### Content & Media
| Command | What it does |
|---|---|
| `media native --product phoring` | Generate content package for Phoring |
| `media native --product sahaayak --platform linkedin` | LinkedIn-specific post |
| `media image --brief "description"` | Generate DALL-E 3 image |
| `media video --file <package>` | Generate video from content package |
| `media status` | Show queue counts |
| `media review` | Show items needing review |
| `media approve <file>` | Approve and publish |
| `media publish` | Publish all approved items |

### Intelligence & Discovery
| Command | What it does |
|---|---|
| `india-problems scan` | Scan for problems AI can solve in India |
| `ai-gaps scan` | Find gaps in AI market |
| `funding scan` | Find grants, programs, funding |
| `competitor scan` | Competitive intelligence |
| `ecosystem scan` | Ecosystem developments |
| `community scan` | Community intelligence |
| `opportunities all` | All opportunity types |

### Outreach & Revenue
| Command | What it does |
|---|---|
| `outreach research "Company"` | Research a target organization |
| `outreach campaign <type> <list>` | Draft outreach campaign |
| `leads capture "inquiry"` | Log a business lead |
| `revenue process` | Process hot leads |

---

## Folder Structure

```
/Volumes/Expansion/CMO-10million/
├── CLAUDE.md                              ← System operating instructions
├── README.md                              ← THIS FILE
├── OpenClawData/
│   ├── directives/                        ← Operating directives (7 files)
│   ├── inbharat-bot/                      ← Intelligence layer
│   │   ├── inbharat-run.sh              ← Master orchestrator (13 lanes)
│   │   ├── skills/                      ← 13 prompt skill templates
│   │   ├── config/bot-config.json       ← Bot configuration
│   │   ├── opportunities/               ← Scanner output
│   │   ├── outreach/                    ← Campaign drafts
│   │   └── leads/                       ← Lead pipeline
│   ├── openclaw-media/                    ← Content factory
│   │   ├── native-pipeline/             ← Content generation (Ollama)
│   │   ├── image-engine/                ← DALL-E 3 + fallbacks
│   │   ├── video-engine/                ← ffmpeg + HeyGen briefs
│   │   ├── posting-engine/              ← Platform posters (5 scripts)
│   │   ├── publishing/                  ← Queue manager + archive
│   │   ├── analytics/                   ← Post logs + feedback
│   │   └── generated-images/            ← DALL-E 3 output
│   ├── queues/                            ← Per-platform content queues
│   │   ├── linkedin/                    ← pending → approved → posted
│   │   ├── x/
│   │   ├── discord/
│   │   ├── instagram/
│   │   ├── reddit/
│   │   ├── website/
│   │   └── heygen/                      ← Avatar video briefs (gated)
│   ├── scripts/                           ← Pipeline scripts
│   ├── skills/                            ← 69 skill templates (all with honest disclaimers)
│   ├── security/                          ← Claim validator
│   ├── strategy/                          ← Product truth, platform rules
│   ├── policies/                          ← Approval rules, brand voice
│   ├── reports/                           ← Generated reports
│   └── logs/                              ← Execution logs
└── MarketingToolData/                     ← Research data
```

---

## Tech Stack & Cost

| Component | Technology | Cost |
|---|---|---|
| LLM (content gen) | Ollama qwen3:8b (local, 8.2B params) | Free |
| LLM (coding) | Ollama qwen2.5-coder:7b (local, 7.6B params) | Free |
| LLM (escalation) | Groq API (referenced, not wired) | Free tier |
| Images | DALL-E 3 (OpenAI API) | ~$0.04/image, 10/day cap |
| Video (local) | ffmpeg v7.0 at `~/local/bin/ffmpeg` | Free |
| Video (avatar) | HeyGen | Paid, founder-gated |
| Browser posting | Playwright persistent sessions | Free |
| Discord posting | Webhook (curl) | Free |
| Web search | DuckDuckGo | Free |
| Secrets | macOS Keychain | Free |
| Scheduling | crontab (6 jobs) | Free |
| CI/CD | GitHub Actions (5 checks) | Free |

### AI Model Usage

| Model | Used By | Cost |
|---|---|---|
| **qwen3:8b** | Content gen, classification, scans, approvals, intelligence lanes | **FREE** (local) |
| **qwen2.5-coder:7b** | Code tasks via model-router | **FREE** (local) |
| **DALL-E 3** | Image gen via `generate-image.sh` (10/day budget cap) | **~$0.04/img** |
| **ffmpeg** | Video gen (slideshow, text, kenburns, quote) | **FREE** (local) |
| **HeyGen** | Avatar video briefs only (Tier 3 gated) | **Paid** |

**Estimated monthly cost**: ~$12 (DALL-E at max usage) + $0 everything else = **< $15/month**

---

## System Maturity (Honest Assessment)

| Component | Status | Maturity |
|---|---|---|
| LinkedIn posting | Tested — posted real content | **Fully verified** |
| X/Twitter posting | Session valid, logic complete | **Integrated, not tested** |
| Instagram posting | Session valid, requires image | **Integrated, not tested** |
| Discord posting | Webhook operational | **Fully verified** |
| Zoho Mail | Session valid (visible mode) | **Integrated, not tested** |
| DALL-E 3 images | Generated real image | **Fully verified** |
| ffmpeg video | Generated real video | **Fully verified** |
| Content generation (Ollama) | Produces JSON packages | **Fully verified** |
| Queue system | Directories populated | **Fully verified** |
| Approval engine | Runs, L1-L4 routing active | **Tested, partial** |
| Daily pipeline | All stages pass (dry-run verified) | **Fully verified** |
| Model routing | qwen3:8b general + qwen2.5-coder:7b code | **Fully verified** |
| Strategy/product-truth | Complete reference docs | **Fully verified** |
| CI/CD | Shell syntax, JSON, skill disclaimers | **Fully verified** |
| Analytics/learning | Logs exist, no engagement data | **Scaffolding** |
| Amplify pipeline | Stub only | **Not implemented** |
| Policy JSON enforcement | Defined but not consumed | **Not integrated** |

---

## Troubleshooting

| Issue | Fix |
|---|---|
| Ollama not running | `ollama serve &` |
| External HD not found | Plug in, check `/Volumes/Expansion/` |
| Session expired | `python3 post_<platform>.py --login` |
| DALL-E budget exceeded | Wait for next day or `--force` |
| Pipeline intake fails (141) | Fixed — SIGPIPE trap added. If persists: `ollama serve &` |
| ffmpeg not found | Already at `~/local/bin/ffmpeg` |
| Zoho headless blocked | Runs visible mode only (by design) |

---

## Quick Start

```bash
# 1. Ensure external HD is connected
ls /Volumes/Expansion/CMO-10million

# 2. Start Ollama
ollama serve &

# 3. Health check
bash OpenClawData/scripts/health-check.sh

# 4. Generate content
bash OpenClawData/openclaw-media/native-pipeline/generate-content.sh --product phoring --platform linkedin

# 5. Check queues
bash OpenClawData/openclaw-media/publishing/post-manager.sh --status

# 6. Publish approved content
bash OpenClawData/openclaw-media/posting-engine/publish.sh
```

---

**Built by [Reeturaj Goswami](https://linkedin.com/in/reeturaj-goswami/) | [InBharat.ai](https://inbharat.ai)**
