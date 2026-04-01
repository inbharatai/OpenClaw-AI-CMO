# OpenClaw + InBharat Bot — Complete System Guide

**Your AI-powered content engine, strategic brain, and autonomous publisher.**

Last updated: 2026-04-01

---

## What Is This System?

You have ONE integrated system with specialized modules:

| Module | Role | Where it lives |
|--------|------|----------------|
| **OpenClaw** | Runtime engine — runs tools, connects WhatsApp, executes commands | `~/.openclaw/` (config) |
| **InBharat Bot** | Strategic brain — 12 intelligence lanes (scan, outreach, prototype, media, community, learning) | `OpenClawData/inbharat-bot/` |
| **OpenClaw Media** | Content factory — 2 pipelines (Native Social + Amplification), video engine, posting engine | `OpenClawData/openclaw-media/` |

**How it works:**
- You text OpenClaw on WhatsApp → it maps your request to InBharat Bot commands → executes → shows you the output → you approve → it auto-publishes

---

## Quick Start

### Option A: WhatsApp (recommended)
Text your OpenClaw WhatsApp bot. Natural language works:
- "create a LinkedIn post about Phoring"
- "what's pending?"
- "approve phoring-linkedin-2026-04-01.json"
- "scan for opportunities"
- "system status"

### Option B: Terminal
```bash
cd /Volumes/Expansion/CMO-10million
bash OpenClawData/inbharat-bot/inbharat-run.sh help
```

---

## Before You Start (Checklist)

1. **External HD connected?** `/Volumes/Expansion/` must exist
2. **Ollama running?** `curl -s http://127.0.0.1:11434/api/tags | head -1`
   - If not: `ollama serve &`
3. **Health check:** `bash OpenClawData/scripts/health-check.sh`

---

## InBharat Bot — 12 Lanes

### Content Creation & Media
| What you want | Command |
|---|---|
| Create content about a product | `media native --product phoring` |
| Create a LinkedIn post | `media native --product sahaayak --platform linkedin` |
| Create a video brief | `media native --product phoring --platform shorts` then `media video --file <output>` |
| Generate a HeyGen avatar video | HeyGen brief via `generate-video.sh --heygen --file <package>` |
| Create an image | `media image --brief "description"` |
| Full media cycle | `media full --product phoring` |
| Amplify a campaign | `media amplify --all` |

### Review & Publishing
| What you want | Command |
|---|---|
| What's pending? | `media status` |
| Show items needing review | `media review` |
| Approve content (auto-publishes) | `media approve <filename>` |
| Approve without publishing | `media approve <filename> --no-publish` |
| Reject content | `media reject <filename>` |
| Publish all approved | `media publish` |
| Posting history | `media history` |

### Intelligence & Discovery
| What you want | Command |
|---|---|
| Scan India problems | `india-problems scan` |
| Find AI gaps | `ai-gaps scan` |
| Scan for funding | `funding scan` |
| Scan competitors | `competitor scan` |
| Scan ecosystem | `ecosystem scan` |
| Community intelligence | `community scan` |
| Find all opportunities | `opportunities all` |
| Government tenders | `government scan` |

### Outreach
| What you want | Command |
|---|---|
| Research a company | `outreach research "Blume Ventures"` |
| Draft outreach campaign | `outreach campaign vc-cold-intro vc-india.json` |
| Check outreach status | `outreach status` |
| Follow up | `outreach followup` |

### Prototypes & Building
| What you want | Command |
|---|---|
| Build a prototype | `prototype build "attendance tracker"` |
| Auto pipeline (scan→build→launch) | `prototype pipeline` |
| Launch locally | `prototype launch <dir>` |

### Revenue & Leads
| What you want | Command |
|---|---|
| Capture a lead | `leads capture "inquiry from XYZ"` |
| Lead pipeline status | `leads status` |
| Process hot leads | `revenue process` |
| Check follow-ups | `revenue followups` |

### System
| What you want | Command |
|---|---|
| Full health check | Run: `bash OpenClawData/scripts/health-check.sh` |
| Dashboard status | `status` |
| Learning review | `learning review` |

---

## Products

| Product | Slug | Website |
|---|---|---|
| InBharat AI | `inbharat` | inbharat.ai |
| Sahaayak | `sahaayak` | — |
| Sahaayak Seva | `sahaayak-seva` | — |
| Phoring | `phoring` | phoring.in |
| TestsPrep | `testsprep` | testsprep.in |
| UniAssist | `uniassist` | uniassist.ai |
| CodeIn | `codein` | — |
| Agent Arcade | `agent-arcade` | — |
| Sahayak OS | `sahayak-os` | — |
| OpenClaw | `openclaw` | — |

---

## Approval System

**4-level approval pipeline:**

| Level | Gate | What happens |
|---|---|---|
| L1 | Auto-approve | Internal updates, Discord posts → auto-approved |
| L2 | Score-gated | AI scores content (0-100). Score ≥ 70 → approved |
| L3 | Review-required | External outreach, claims → needs your approval |
| L4 | Hard-block | Credential claims, unverified stats → blocked |

**On approve:** claim validation → platform session check → post → archive → feedback loop

Nothing auto-publishes without your explicit approval first.

---

## Publishing Platforms

| Platform | Status | Poster |
|---|---|---|
| Discord | Working (webhook) | `post_discord.py` (curl) |
| LinkedIn | Needs login | `post_linkedin.py` (Playwright) |
| X/Twitter | Needs login | `post_x.py` (Playwright) |
| Instagram | Needs login | `post_instagram.py` (Playwright) |

**First-time platform login:**
```bash
cd /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine
python3 post_linkedin.py --login    # Opens browser, you log in once
python3 post_x.py --login
python3 post_instagram.py --login
```

---

## Video Engine

**10 distinct video formats** to prevent repetitive content:
- Hook-Story-CTA, Problem-Solution, Quick Demo, Myth Buster, Before-After
- Day in Life, Hot Take/Opinion, Tutorial Walkthrough, Social Proof, Announcement

**HeyGen avatar videos:** Browser-operated, production briefs generated automatically.

---

## Architecture

```
YOU (WhatsApp / Terminal)
  │
  ▼
OpenClaw Gateway (:18789) → InBharat Bot Bridge (natural language → commands)
  │
  ▼
inbharat-run.sh (master orchestrator — 12 lanes)
  │
  ├── Media Lane ──────────► openclaw-media/
  │                          ├── native-pipeline/ (original content)
  │                          ├── amplify-pipeline/ (campaign amplification)
  │                          ├── video-engine/ (HeyGen, format library)
  │                          └── posting-engine/ (Discord, LinkedIn, X, Instagram)
  │
  ├── Intelligence Lanes ──► opportunities/, competitors/, ecosystem/
  ├── Outreach Lane ───────► outreach/ (email drafts, campaigns)
  ├── Prototype Lane ──────► prototypes/ (scan → build → launch)
  ├── Revenue Lane ────────► leads/, revenue/
  ├── Community Lane ──────► community intelligence
  ├── Learning Lane ───────► analytics/feedback-to-bot/ → weekly summaries
  └── Government Lane ─────► government proposals

Approval Engine (L1-L4) ← claim-validator.sh ← website-context.md
  │
  ▼
Auto-Publish on Approve → posting-engine/ → archive → feedback loop
```

---

## Folder Structure

```
/Volumes/Expansion/CMO-10million/              ← WORKSPACE ROOT
│
├── OpenClawData/
│   ├── inbharat-bot/                          ← STRATEGIC BRAIN
│   │   ├── inbharat-run.sh                   ← Master orchestrator
│   │   ├── skills/                           ← Bot skill templates
│   │   ├── opportunities/                    ← World scanner + reports
│   │   ├── outreach/                         ← Email campaigns
│   │   ├── prototypes/                       ← Built prototypes
│   │   ├── leads/                            ← Business leads
│   │   └── config/                           ← Bot config
│   │
│   ├── openclaw-media/                        ← CONTENT FACTORY
│   │   ├── native-pipeline/                  ← Original content generation
│   │   ├── amplify-pipeline/                 ← Campaign amplification
│   │   ├── video-engine/                     ← HeyGen + video formats
│   │   ├── posting-engine/                   ← Platform posters (Python/Playwright)
│   │   ├── publishing/                       ← Post manager + archive
│   │   └── analytics/                        ← Feedback loop + metrics
│   │
│   ├── queues/                                ← Per-platform content queues
│   │   ├── discord/{pending,approved,posted}
│   │   ├── linkedin/{pending,approved,posted}
│   │   ├── x/{pending,approved,posted}
│   │   └── instagram/{pending,approved,posted}
│   │
│   ├── scripts/                               ← CMO pipeline scripts
│   ├── skills/                                ← Shared prompt templates (70+)
│   ├── security/                              ← Claim validator
│   ├── strategy/                              ← Website context, video format library
│   ├── policies/                              ← Approval rules, brand voice
│   ├── reports/                               ← Generated reports
│   ├── memory/                                ← System memory
│   └── logs/                                  ← Execution logs
│
├── MarketingToolData/                         ← Research data
└── README.md                                  ← THIS FILE
```

---

## Cost

| Component | Cost |
|---|---|
| Ollama (qwen3:8b, local) | Free |
| Groq (gateway agent) | Free tier |
| OpenAI (images only) | Pay per image |
| HeyGen (avatar videos) | Free tier / paid |
| DuckDuckGo (web search) | Free |
| Discord (webhook posting) | Free |
| Playwright (browser posting) | Free |

---

## Troubleshooting

| Issue | Fix |
|---|---|
| "Ollama not running" | `ollama serve &` |
| "Bot root not found" | Plug in external HD, check `/Volumes/Expansion/` |
| "No search results" | Check internet connection |
| "No response from model" | `ollama pull qwen3:8b` |
| "jq: command not found" | `brew install jq` |
| "Session expired" on platform | Re-run `python3 post_<platform>.py --login` |

---

## 5 Things to Remember

1. **Plug in the external HD** before using anything
2. **Ollama must be running** (`ollama serve &`)
3. **WhatsApp is the primary interface** — just text naturally
4. **Nothing publishes without your approval** — approval-first system
5. **Health check:** `bash OpenClawData/scripts/health-check.sh`
