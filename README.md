# CMO-10million — OpenClaw AI CMO + InBharat Bot Workspace

## What This Is

A local-first AI CMO and ecosystem intelligence system built on OpenClaw + Ollama, running on macOS with an external drive workspace.

**This is NOT a SaaS product.** It is a working internal operations system for a solo builder.

## Current State (Honest Assessment)

### What Is Real and Working
- **64 SKILL.md files** — prompt templates loaded by OpenClaw's skill system (advisory/context, NOT runtime-enforced code)
- **18 shell scripts** — the actual execution layer (intake, content generation, approval, distribution, reporting)
- **4 policy JSONs** — approval rules, brand voice, channel policies, rate limits
- **InBharat Bot V1** — ecosystem scanner, gap finder, proposal generator, CMO bridge, dashboard state
- **Approval engine** — 4-level content approval (auto/score-gate/review/block)
- **Queue system** — per-channel pending/approved queues for 12 platforms
- **End-to-end pipeline proof** — ran successfully on 2026-03-25
- **Ollama integration** — qwen3:8b (writing/strategy) + qwen2.5-coder:7b (coding/scripts)
- **OpenClaw gateway** — installed and running
- **WhatsApp** — connected to owner's number
- **Git** — initialized with first commit

### What Is NOT Yet Working
- **Unattended cron execution** — cron was set up but is currently PAUSED; no 3-day autonomous proof yet
- **Builder Intelligence bot** — designed only, not implemented
- **Direct platform posting** — no social media accounts connected for auto-posting
- **GitHub repo scanning** — InBharat Bot config has empty repos[] array
- **Website scanning** — InBharat Bot config has empty websites[] array
- **WhatsApp commands** — connected but not wired to trigger bot actions
- **Git remote** — no remote repository configured yet; commits are local only

### What Is Advisory (Not Runtime-Enforced)
- SKILL.md files are prompt context injected into OpenClaw conversations — they guide behavior but don't enforce it programmatically
- The real enforcement comes from shell scripts, policy JSONs, and the approval engine
- "Workspace Guard" is a shell script that checks paths, not a kernel-level sandbox

## Architecture

```
CMO-10million/                          ← Workspace root (external drive)
├── OpenClawData/                       ← Core operations data
│   ├── skills/           (64 SKILL.md) ← OpenClaw prompt templates
│   ├── scripts/          (18 .sh)      ← Actual execution layer
│   ├── policies/         (4 .json)     ← Rules and limits
│   ├── queues/           (12 channels) ← Per-channel content queues
│   ├── approvals/        (4 states)    ← pending/approved/blocked/review
│   ├── reports/          (3 periods)   ← daily/weekly/monthly
│   ├── memory/                         ← Persistent context
│   ├── logs/                           ← Pipeline execution logs
│   ├── sessions/                       ← Session data
│   ├── prompts/                        ← Prompt templates
│   └── inbharat-bot/                   ← Ecosystem intelligence bot
│       ├── inbharat-run.sh             ← Master orchestrator
│       ├── scanner/                    ← Workspace/ecosystem scanner
│       ├── gap-finder/                 ← AI-powered gap analysis
│       ├── proposal-generator/         ← Structured build proposals
│       ├── cmo-bridge/                 ← Proposals → CMO content pipeline
│       ├── dashboard/                  ← State JSON + status reports
│       ├── approval/                   ← 5-level action classification
│       ├── logging/                    ← Shared evidence logger
│       ├── config/                     ← Bot configuration
│       ├── registry/                   ← Scan outputs
│       └── reports/                    ← Bot reports
├── MarketingToolData/                  ← Content production data
│   ├── source-notes/                   ← Raw input material
│   ├── source-links/                   ← News/reference links
│   ├── ai-news/                        ← AI industry content
│   ├── product-updates/                ← Product content
│   ├── website-posts/                  ← Website drafts
│   ├── linkedin/ x/ facebook/ etc.     ← Per-channel content
│   ├── video-briefs/                   ← HeyGen briefs
│   └── image-briefs/                   ← Image briefs
├── OllamaModels/                       ← Model storage (external drive)
├── OpenClaw/                           ← OpenClaw installation
├── SocialFlow/                         ← Social media bridge app
├── ExportsLogs/                        ← Posted/exported content archive
├── TempFiles/                          ← Temporary processing
└── NotesDocs/                          ← Notes and documentation
```

## Pipeline Flow

```
Source Material → Intake Processor → Content Agent → Approval Engine → Distribution → Reports
     ↑                                                    ↑
     |                                                    |
  source-notes/                                    approval-rules.json
  source-links/                                    brand-voice-rules.json
  ai-news/                                         channel-policies.json
                                                   rate-limits.json
```

## InBharat Bot Flow

```
Ecosystem Scanner → Gap Finder → Proposal Generator → CMO Bridge → Pipeline
     ↓                  ↓              ↓                   ↓
  registry/         findings/      proposals/         source-notes/
```

## Models

| Model | Purpose | Size |
|-------|---------|------|
| qwen3:8b | Strategy, writing, marketing, summaries, analysis | ~5 GB |
| qwen2.5-coder:7b | Coding, scripts, automation, technical edits | ~4 GB |

## Key Commands

```bash
# Run daily CMO pipeline
bash OpenClawData/scripts/daily-pipeline.sh

# Run InBharat Bot (full cycle)
bash OpenClawData/inbharat-bot/inbharat-run.sh full

# Run InBharat Bot (individual stages)
bash OpenClawData/inbharat-bot/inbharat-run.sh scan
bash OpenClawData/inbharat-bot/inbharat-run.sh analyze
bash OpenClawData/inbharat-bot/inbharat-run.sh propose
bash OpenClawData/inbharat-bot/inbharat-run.sh bridge
bash OpenClawData/inbharat-bot/inbharat-run.sh status

# Check Ollama
ollama list

# Check cron status
crontab -l
```

## Approval Levels

### CMO Pipeline (Content)
| Level | Behavior | Examples |
|-------|----------|---------|
| L1 Auto-approve | Passes automatically | Own product updates, build logs |
| L2 Score-gated | Auto if score > threshold | AI news, educational posts |
| L3 Review queue | Requires manual review | Bold claims, competitor content |
| L4 Block | Rejected automatically | Unverifiable claims, spam |

### InBharat Bot (Actions)
| Level | Behavior | Examples |
|-------|----------|---------|
| observe | Auto | Scanning, reading files |
| infer | Auto | Gap analysis, scoring |
| propose | Auto | Generating proposals |
| act | Review required | Modifying files, creating tasks |
| publish | Blocked until approved | Posting content, sending emails |

## What Is Needed Next

1. **Connect a git remote** — currently local commits only
2. **Provide Discord webhook URL** — enables auto-posting
3. **Log into social platforms** — for future direct posting
4. **Add GitHub repo URLs** — to InBharat Bot config for repo scanning
5. **Add website URLs** — to InBharat Bot config for site scanning
6. **Restore cron** — currently paused, needs 3-day unattended proof
7. **Wire WhatsApp commands** — to trigger bot actions from phone

## Built With

- OpenClaw (open source AI platform)
- Ollama (local LLM inference)
- Bash shell scripts (execution layer)
- macOS + external drive (workspace)

## License

Private workspace. Not open source.
