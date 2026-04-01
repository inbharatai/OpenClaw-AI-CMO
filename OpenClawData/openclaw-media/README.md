# OpenClaw Media System v2.0

**Two content pipelines, a video engine, and an autonomous posting engine.**

Last updated: 2026-04-01

---

## Two Pipelines

### Pipeline A — Native Social Pipeline
Creates original short-form social content from product context, mission, and content buckets.

```
product-truth + content-bucket + website-context
  → generate-content.sh (Ollama)
  → content-package.json
  → queues/{platform}/pending/
```

**Command:** `bash inbharat-run.sh media native --product phoring --platform linkedin`

### Pipeline B — Amplification Pipeline
Converts structured campaign briefs from InBharat Bot into platform-native social content.

```
bot-handoff → campaign-brief
  → amplify-handoff.sh (Ollama)
  → content-package.json
  → queues/{platform}/pending/
```

**Command:** `bash inbharat-run.sh media amplify --all`

---

## Video Engine

### Capabilities
- **10 video formats:** Hook-Story-CTA, Problem-Solution, Quick Demo, Myth Buster, Before-After, Day in Life, Hot Take, Tutorial, Social Proof, Announcement
- **HeyGen avatar videos:** Browser-operated, production briefs auto-generated
- **Format selector:** Picks best format by platform + use-case, prevents repetition

### Key Files
| File | Purpose |
|---|---|
| `video-engine/generate-video.sh` | Video generation orchestrator |
| `video-engine/format-selector.sh` | Format selection by platform/use-case |
| `video-engine/heygen-brief-generator.sh` | Generate HeyGen production briefs |
| `video-engine/heygen-workflow.md` | Browser automation protocol for HeyGen |
| `../strategy/video-format-library.json` | 10 format definitions with scene structures |

---

## Posting Engine

**Autonomous publishing** — runs after approval, no human-in-the-loop needed.

| Platform | Script | Method |
|---|---|---|
| Discord | `post_discord.py` | Webhook (curl) |
| LinkedIn | `post_linkedin.py` | Playwright browser automation |
| X/Twitter | `post_x.py` | Playwright browser automation |
| Instagram | `post_instagram.py` | Playwright browser automation (mobile viewport) |

### Commands
```bash
./publish.sh                     # Post all approved content
./publish.sh --platform linkedin # Post to specific platform
./publish.sh --dry-run           # Preview without posting
./publish.sh --status            # Check login sessions
./publish.sh --login linkedin    # Log in to a platform (one-time)
```

### Session Setup (one-time)
```bash
python3 posting-engine/post_linkedin.py --login
python3 posting-engine/post_x.py --login
python3 posting-engine/post_instagram.py --login
python3 posting-engine/post_discord.py --setup
```

---

## Approval Flow

```
Content generated → queues/{platform}/pending/
  ↓
Approval engine scores (L1-L4)
  ↓
You approve: "approve filename.json"
  ↓
Auto-publish pipeline:
  1. Claim validation (blocks fabricated stats)
  2. Platform session check
  3. Post via platform poster
  4. Move to posted/
  5. Archive copy
  6. Feed to learning loop
```

### Post Manager
| Command | Action |
|---|---|
| `post-manager.sh status` | Show queue counts |
| `post-manager.sh review` | Show items needing review |
| `post-manager.sh approve <file>` | Approve + auto-publish |
| `post-manager.sh approve <file> --no-publish` | Approve without publishing |
| `post-manager.sh reject <file>` | Reject content |

---

## Analytics & Feedback Loop

```
Posted content → feedback-collector.sh record
  → analytics/feedback-to-bot/posted-YYYY-MM-DD.jsonl
  → Weekly: feedback-collector.sh weekly-summary
  → Learning lane reads summaries → improves future content
```

---

## Safety

- **Claim validator:** Catches fabricated statistics, unverified percentages, credential leaks
- **Website context:** Loaded from `strategy/website-context.md` — ensures factual content
- **Shell injection prevention:** All Python heredocs use quoted EOF + environment variables
- **Approval-first:** Nothing publishes without explicit human approval

---

## Directory Structure

```
openclaw-media/
├── native-pipeline/          ← Original content generation
│   ├── generate-content.sh
│   └── configs/
├── amplify-pipeline/         ← Campaign amplification
│   └── amplify-handoff.sh
├── video-engine/             ← Video generation + HeyGen
│   ├── generate-video.sh
│   ├── format-selector.sh
│   ├── heygen-brief-generator.sh
│   └── heygen-workflow.md
├── posting-engine/           ← Platform posters
│   ├── publish.sh
│   ├── post_discord.py
│   ├── post_linkedin.py
│   ├── post_x.py
│   └── post_instagram.py
├── publishing/               ← Post manager + archive
│   ├── post-manager.sh
│   └── archive/
├── analytics/                ← Feedback loop
│   ├── feedback-collector.sh
│   └── feedback-to-bot/
├── templates/                ← Shared content templates
└── schemas/                  ← JSON schemas
```
