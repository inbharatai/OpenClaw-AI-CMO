# OpenClaw — Autonomous Executive Operating System

**The AI-powered operating system that runs InBharat's entire growth, content, outreach, and intelligence operation.**

Version 5.0 | Last updated: 2026-04-04 | [github.com/inbharatai/OpenClaw-AI-CMO](https://github.com/inbharatai/OpenClaw-AI-CMO)

[![CI](https://github.com/inbharatai/OpenClaw-AI-CMO/actions/workflows/ci.yml/badge.svg)](https://github.com/inbharatai/OpenClaw-AI-CMO/actions/workflows/ci.yml)

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     FOUNDER (WhatsApp / Terminal)                     │
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
│  │  13 Intelligence Lanes: Media Engine, India Problems,         │   │
│  │  AI Gaps, Funding, Compete Monitor, Ecosystem Scanner,        │   │
│  │  Community Intel, Outreach, Gov & Tenders, Learning,          │   │
│  │  Prototype Builder, Reddit Drafting, Revenue Pipeline         │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                           │                                          │
│  ┌────────────────────────▼─────────────────────────────────────┐   │
│  │  CONTENT FACTORY (openclaw-media/)                            │   │
│  │                                                               │   │
│  │  Generation:          Guardrails:           Publishing:       │   │
│  │  ┌──────────────┐    ┌──────────────────┐  ┌─────────────┐   │   │
│  │  │Ollama qwen3  │    │policy_enforcer.py│  │publish.sh   │   │   │
│  │  │Native Pipeline│    │rate-limits.json  │  │(CANONICAL)  │   │   │
│  │  ├──────────────┤    ├──────────────────┤  ├─────────────┤   │   │
│  │  │DALL-E 3 +    │    │sanitize_post.py  │  │render_post  │   │   │
│  │  │enrich_prompt │    │render_post.py    │  │qa-guardrail │   │   │
│  │  ├──────────────┤    ├──────────────────┤  ├─────────────┤   │   │
│  │  │ffmpeg Video  │    │qa-guardrail.sh   │  │dist-engine  │   │   │
│  │  │HeyGen Briefs │    │claim-validator   │  │(non-browser) │   │   │
│  │  └──────────────┘    │approval L1-L4    │  └─────────────┘   │   │
│  │                      └──────────────────┘                     │   │
│  └───────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Products in Ecosystem

| Product | What it does | Website | Status |
|---|---|---|---|
| **InBharat.ai** | AI consulting, tools & automation for Bharat | [inbharat.ai](https://inbharat.ai) | Live |
| **Sahaayak** | Multilingual AI assistant for Indian users | [sahaayak.ai](https://sahaayak.ai) | Development |
| **Sahaayak Seva** | Public service AI for government schemes | — | Development |
| **TestsPrep** | AI-powered test preparation for Indian exams | [testsprep.in](https://testsprep.in) | Development |
| **UniAssist** | University and higher education AI assistant | [uniassist.ai](https://uniassist.ai) | Development |
| **Phoring** | AI-enhanced communication platform | [phoring.in](https://phoring.in) | Development |
| **CodeIn** | AI coding assistance and education | [codein.pro](https://codein.pro) | Experimental |
| **OpenClaw** | This system — autonomous ops engine | [GitHub](https://github.com/inbharatai/OpenClaw-AI-CMO) | Development |
| **Agent Arcade** | AI agent experimentation platform | [GitHub](https://github.com/inbharatai/agent-arcade-gateway) | Experimental |
| **Sahayak OS** | Framework for deploying AI assistants | — | Experimental |

### Source of Truth
- Product facts: `strategy/product-registry.json` (10 products)
- Product claims: `strategy/product-truth/*.md` (10 files, with safe/restricted claims)
- Brand identity: `strategy/brand-knowledge-base.json`
- Platform rules: `strategy/platform-rules/*.md` (6 files)

---

## Publishing Pipeline (Canonical Path)

Every live post goes through this exact path — no exceptions:

```
Queue (approved/) → POLICY CHECK → CLAIM VALIDATE → SANITIZE → QA GUARDRAIL → RENDER → POST → RECORD
                    policy_enforcer  claim-validator  sanitize_post  qa-guardrail  render_post  post_*.py  policy counter
```

### Enforcement Gates

| Gate | File | What it checks |
|---|---|---|
| **Policy** | `policy_enforcer.py` | `blocked=true`? Daily cap reached? Platform allowed? |
| **Claims** | `claim-validator.sh` | Fabricated stats? Unverified claims? Credentials leaked? |
| **Sanitize** | `sanitize_post.py` | JSON leaks? YAML frontmatter? Template placeholders? Internal metadata? |
| **QA** | `qa-guardrail.sh` | Post too long? Too many hashtags? Banned phrases? |
| **Render** | `render_post.py` | Two-stage: queue file (JSON/MD) → clean human-readable text only |

### Direct Script Protection
Individual posting scripts (`post_linkedin.py`, `post_x.py`, etc.) require `--allow-direct-post` flag for direct invocation. Without it, they refuse to post and log the attempt. Even with the flag, policy enforcement still runs.

---

## Platform Publishing

| Platform | Engine | Posting Mode | Daily Cap | Session |
|---|---|---|---|---|
| **LinkedIn** | `post_linkedin.py` | Playwright | 3/day | `~/.openclaw/browser-sessions/linkedin/` |
| **X/Twitter** | `post_x.py` | Playwright | 3/day | `~/.openclaw/browser-sessions/x/` |
| **Instagram** | `post_instagram.py` | Playwright (mobile) | 1/day | `~/.openclaw/browser-sessions/instagram/` |
| **Discord** | `post_discord.py` | Webhook | 3/day | Keychain: `discord-webhook` |
| **Zoho Mail** | `email_zoho.py` | Playwright (visible) | 1/day | `~/.openclaw/browser-sessions/zoho/` |
| **Reddit** | Draft only | Manual (L3 always) | 1/day | — |
| **Website** | `distribution-engine.sh` | File copy to staging | 3/day | — |
| **HeyGen** | Brief export only | Founder-gated (T3) | 2/day | — |

### Two Publishers, No Overlap

| Script | Handles | Method |
|---|---|---|
| `publish.sh` | LinkedIn, X, Instagram, Discord | Playwright browser automation + webhook |
| `distribution-engine.sh` | Website, email, heygen, medium, substack | File staging + export |

Both enforce `policy_enforcer.py`. Both run `sanitize_post.py`. Neither can touch the other's platforms.

---

## Image Generation

```
Content Package → enrich_image_prompt.py → DALL-E 3 → Post Image
                  (brand colors, product    (or placeholder
                   context, style, negative   fallback if offline)
                   guidance, platform sizing)
```

| Component | What it does |
|---|---|
| `enrich_image_prompt.py` | Transforms generic briefs into brand-aware DALL-E prompts |
| `brand-knowledge-base.json` | Colors, visual style, prohibited styles per product |
| `process-briefs.sh` | Batch processes all image briefs from content packages |
| `generate-image.sh` | Routes to DALL-E 3, local Stable Diffusion, or placeholder |
| `placeholder_generate.py` | Offline branded card generator (loads brand colors from KB) |

---

## Approval System

| Level | Decision | Content Types |
|---|---|---|
| **L1** | Auto-approve | Standard posts, Discord, community updates |
| **L2** | Score-gated | Product claims, industry commentary, social posts |
| **L3** | Founder review | Reddit, HeyGen, bold claims, partnership, outreach |
| **L4** | Hard block | Unverified claims, credentials, PII, legal/political |

Risk scoring: 6 dimensions (source confidence 25%, claim sensitivity 25%, brand voice 15%, data safety 15%, duplication 10%, platform risk 10%).

---

## Cron Schedule

| Time | Job | Script |
|---|---|---|
| 8:07 AM daily | Full CMO pipeline | `daily-pipeline.sh` |
| 9:00 AM daily | Auto-content generation | `daily-auto-content.sh` |

---

## Folder Structure

```
/Volumes/Expansion/CMO-10million/
├── CLAUDE.md                              ← System operating instructions
├── README.md                              ← THIS FILE
├── assets/brand/                          ← Logo files (SVG, PNG)
├── OpenClawData/
│   ├── directives/                        ← Operating directives
│   ├── policies/                          ← rate-limits.json, channel-policies, brand-voice-rules
│   ├── strategy/
│   │   ├── brand-knowledge-base.json     ← Canonical brand identity (10 products)
│   │   ├── product-registry.json         ← Product catalog
│   │   ├── product-truth/*.md            ← Per-product safe/restricted claims + visual identity
│   │   ├── platform-rules/*.md           ← Per-platform format, tone, limits (6 files)
│   │   └── content-templates/*.md        ← Reusable campaign templates (10 files)
│   ├── inbharat-bot/                      ← Intelligence layer (13 lanes)
│   ├── openclaw-media/
│   │   ├── posting-engine/               ← Platform posters + enforcement layer
│   │   │   ├── publish.sh               ← THE canonical publish path
│   │   │   ├── policy_enforcer.py       ← Runtime policy enforcement
│   │   │   ├── sanitize_post.py         ← Content sanitization
│   │   │   ├── render_post.py           ← Two-stage rendering
│   │   │   ├── direct_post_gate.py      ← Gate for direct script calls
│   │   │   ├── metadata_fields.py       ← Shared metadata constants
│   │   │   ├── post_linkedin.py         ← Playwright poster (gated)
│   │   │   ├── post_x.py               ← Playwright poster (gated)
│   │   │   ├── post_instagram.py        ← Playwright poster (gated)
│   │   │   ├── post_discord.py          ← Webhook poster (gated)
│   │   │   └── email_zoho.py           ← Playwright poster
│   │   ├── image-engine/
│   │   │   ├── enrich_image_prompt.py   ← Brand-aware prompt enrichment
│   │   │   ├── dalle_generate.py        ← DALL-E 3 backend
│   │   │   ├── placeholder_generate.py  ← Offline fallback (brand colors from KB)
│   │   │   ├── generate-image.sh        ← Backend router
│   │   │   └── process-briefs.sh        ← Batch processor with enrichment
│   │   ├── native-pipeline/              ← Content generation (Ollama)
│   │   ├── analytics/                    ← Post logs, error screenshots
│   │   └── generated-images/             ← DALL-E 3 output
│   ├── queues/                            ← Per-platform content queues
│   │   └── {platform}/pending|approved|posted|rejected/
│   ├── scripts/
│   │   ├── daily-pipeline.sh            ← Master pipeline orchestrator
│   │   ├── distribution-engine.sh       ← Non-browser distribution (policy-enforced)
│   │   ├── qa-guardrail.sh              ← Pre-publish QA gate
│   │   ├── approval-engine.sh           ← L1-L4 approval scoring
│   │   └── reporting-engine-v2.sh       ← Daily/weekly reports
│   ├── skills/                            ← 75 skill templates
│   ├── security/                          ← Claim validator
│   ├── tests/                             ← test_sanitize_post.py, test_enrich_image_prompt.py
│   ├── reports/                           ← Generated reports
│   └── logs/                              ← Execution + policy enforcement logs
└── MarketingToolData/                     ← Staged website content + research
```

---

## Tech Stack & Cost

| Component | Technology | Cost |
|---|---|---|
| LLM (content gen) | Ollama qwen3:8b (local) | Free |
| LLM (coding) | Ollama qwen2.5-coder:7b (local) | Free |
| Images | DALL-E 3 (OpenAI API) | ~$0.04/image, 10/day cap |
| Video (local) | ffmpeg v7.0 at `~/local/bin/ffmpeg` | Free |
| Video (avatar) | HeyGen | Paid, founder-gated |
| Browser posting | Playwright persistent sessions | Free |
| Discord posting | Webhook (curl) | Free |
| Secrets | macOS Keychain | Free |
| Scheduling | crontab | Free |
| CI/CD | GitHub Actions | Free |

**Estimated monthly cost**: ~$12-15 (DALL-E at max usage). Everything else is free/local.

---

## System Maturity

| Component | Status |
|---|---|
| **Policy enforcement** | Enforced at runtime — `policy_enforcer.py` loads `rate-limits.json`, blocks platforms, enforces caps |
| **Content sanitization** | Active in all posting scripts — strips JSON, metadata, placeholders |
| **Two-stage rendering** | Active in `publish.sh` — queue files rendered to clean text before posting |
| **QA guardrails** | Active in `publish.sh` — length, hashtags, banned phrases checked |
| **Direct post gating** | Active — scripts require `--allow-direct-post`, log all attempts |
| **Brand knowledge base** | Complete — 10 products with visual identity, colors, image rules |
| **Image prompt enrichment** | Active — generic briefs enriched with product context and brand colors |
| **LinkedIn posting** | Playwright, policy-enforced, 3/day cap |
| **X/Twitter posting** | Playwright with overlay dismissal, dropdown clearing, upload waits |
| **Instagram posting** | Playwright with multi-selector caption targeting, Stories detection |
| **Discord posting** | Webhook, fully operational |
| **Daily pipeline** | All stages functional — intake through reporting |
| **Approval engine** | L1-L4 routing with 6-dimension risk scoring |
| **27 unit tests** | Passing — sanitization (15) + image enrichment (12) |

---

## Quick Start

```bash
# 1. Ensure external HD is connected
ls /Volumes/Expansion/CMO-10million

# 2. Start Ollama
ollama serve &

# 3. Check policy status
python3 OpenClawData/openclaw-media/posting-engine/policy_enforcer.py --status

# 4. Check publishing status
bash OpenClawData/openclaw-media/posting-engine/publish.sh --status

# 5. Run full pipeline (dry-run first)
bash OpenClawData/scripts/daily-pipeline.sh --dry-run

# 6. Publish approved content (live)
bash OpenClawData/openclaw-media/posting-engine/publish.sh

# 7. Run tests
python3 OpenClawData/tests/test_sanitize_post.py
python3 OpenClawData/tests/test_enrich_image_prompt.py
```

---

## Troubleshooting

| Issue | Fix |
|---|---|
| Ollama not running | `ollama serve &` |
| External HD not found | Plug in, check `/Volumes/Expansion/` |
| Session expired | `python3 post_<platform>.py --login` |
| DALL-E budget exceeded | Wait for next day or `--force` |
| Platform blocked by policy | Edit `policies/rate-limits.json` — set `blocked: false` |
| Direct post refused | Add `--allow-direct-post` flag (still enforces policy) |
| ffmpeg not found | Already at `~/local/bin/ffmpeg` |
| Zoho headless blocked | Runs visible mode only (by design) |

---

**Built by [Reeturaj Goswami](https://linkedin.com/in/reeturaj-goswami/) | [InBharat.ai](https://inbharat.ai)**
