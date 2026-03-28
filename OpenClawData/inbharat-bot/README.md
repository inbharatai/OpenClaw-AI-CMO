# InBharat Bot v2.0

**Your AI-powered right-hand operator.** Scans the world for opportunities, drafts outreach, builds prototypes, and launches them — all from one command.

---

## Quick Start (for beginners)

### Step 1: Make sure Ollama is running

```bash
# Check if Ollama is running
curl -s http://127.0.0.1:11434/api/tags | head -1

# If it shows nothing, start Ollama:
ollama serve &
# Then pull the model (first time only):
ollama pull qwen3:8b
```

### Step 2: Run InBharat Bot

```bash
cd /Volumes/Expansion/CMO-10million
bash OpenClawData/inbharat-bot/inbharat-run.sh help
```

That's it. You're in.

---

## What Can It Do?

| Command | What happens |
|---------|-------------|
| `inbharat-run.sh help` | Show all available commands |
| `inbharat-run.sh status` | System health dashboard |
| `inbharat-run.sh full` | Full intelligence cycle |
| `inbharat-run.sh opportunities all` | Scan the ENTIRE web for opportunities |
| `inbharat-run.sh prototype pipeline` | Find a problem → build a solution → launch it |
| `inbharat-run.sh outreach draft "intro to NITI Aayog"` | Draft a professional email |
| `inbharat-run.sh leads capture "got inquiry from XYZ"` | Capture a business lead |

---

## All Commands

### Intelligence (understand your ecosystem)

```bash
bash inbharat-run.sh full       # Scan → Analyze → Propose → Bridge → Status
bash inbharat-run.sh scan       # Scan your workspace/ecosystem
bash inbharat-run.sh analyze    # Find gaps and opportunities
bash inbharat-run.sh propose    # Generate build proposals
bash inbharat-run.sh bridge     # Feed proposals to CMO content pipeline
bash inbharat-run.sh status     # System health dashboard
```

### World Scanner (find opportunities globally)

```bash
bash inbharat-run.sh opportunities all         # Scan everything
bash inbharat-run.sh opportunities government  # Government schemes, tenders, RFPs
bash inbharat-run.sh opportunities corporate   # Company partnerships
bash inbharat-run.sh opportunities global      # International opportunities
bash inbharat-run.sh opportunities grants      # Grants and funding
bash inbharat-run.sh opportunities problems    # GitHub issues, broken tools, unmet needs
bash inbharat-run.sh opportunities projects    # Small company projects needing help
bash inbharat-run.sh opportunities buildable   # All buildable opportunities combined
bash inbharat-run.sh opportunities custom "AI education rural India"  # Custom search
bash inbharat-run.sh competitors               # AI competitor analysis
bash inbharat-run.sh government scan           # Government-specific scan
bash inbharat-run.sh government propose "scheme name"  # Draft government proposal
```

### Prototypes (build and ship solutions)

```bash
bash inbharat-run.sh prototype build "attendance tracker for Anganwadi workers"
bash inbharat-run.sh prototype launch <build-directory>
bash inbharat-run.sh prototype package <build-directory>    # Zip for deployment
bash inbharat-run.sh prototype pipeline                     # FULL: scan → pick → build → launch
bash inbharat-run.sh prototype pipeline problems            # Scan problems, build best one
bash inbharat-run.sh prototype pipeline custom "query"      # Custom scan, then build
bash inbharat-run.sh prototype list                         # Show all prototypes
```

### Outreach (emails and communication)

```bash
bash inbharat-run.sh outreach draft "introduce InBharat to ICDS for Anganwadi AI"
bash inbharat-run.sh outreach track            # Today's outreach activity
bash inbharat-run.sh outreach track week       # Last 7 days
bash inbharat-run.sh outreach track stats      # Overall outreach stats
```

### Revenue (leads and pipeline)

```bash
bash inbharat-run.sh leads status              # Show lead pipeline
bash inbharat-run.sh leads capture "got inquiry from LearnFlow EdTech about AI tutoring"
bash inbharat-run.sh revenue status            # Revenue pipeline state
bash inbharat-run.sh revenue process           # Process hot leads → generate proposals
bash inbharat-run.sh revenue followups         # Check follow-up queue
```

---

## Architecture

```
inbharat-run.sh (master orchestrator)
│
├── Intelligence
│   ├── scanner/ecosystem-scanner.sh      → reads workspace, produces registry
│   ├── gap-finder/gap-finder.sh          → analyzes scan, finds gaps
│   ├── proposal-generator/proposal-generator.sh  → creates build proposals
│   ├── cmo-bridge/cmo-bridge.sh          → feeds proposals to CMO
│   └── dashboard/generate-state.sh       → health dashboard
│
├── World Scanner
│   └── opportunities/world-scanner.sh    → web search → Ollama analysis
│       ├── Government (India + Global)
│       ├── Corporate partnerships
│       ├── Open source / grants
│       ├── Problems to solve (GitHub, forums)
│       └── Small company projects
│
├── Prototypes
│   ├── prototypes/prototype-builder.sh   → problem → working code
│   ├── prototypes/launcher.sh            → local server / packaging
│   └── prototypes/scout-build-launch.sh  → full pipeline
│
├── Outreach
│   ├── outreach/outreach-drafter.sh      → AI email drafting
│   └── outreach/outreach-tracker.sh      → activity tracking
│
├── Revenue
│   ├── leads/lead-capture.sh             → qualify and store leads
│   ├── revenue/revenue-engine.sh         → pipeline management
│   └── revenue/proposal-builder.sh       → generate sales proposals
│
├── Skills (prompt templates)
│   ├── world-scanner/SKILL.md
│   ├── prototype-builder/SKILL.md
│   ├── professional-email-drafter/SKILL.md
│   ├── opportunity-miner/SKILL.md
│   ├── competitor-monitor/SKILL.md
│   └── lead-research/SKILL.md
│
└── Shared
    ├── logging/bot-logger.sh             → unified logging
    ├── approval/approval-gate.sh         → action classification
    └── config/bot-config.json            → model configuration
```

## How It Works (for non-technical users)

1. **You type a command** → InBharat Bot runs it
2. **Bot searches the web** using DuckDuckGo (free, no API key needed)
3. **Bot feeds search results to AI** (qwen3:8b running locally on your Mac via Ollama)
4. **AI analyzes and produces output** — reports, emails, code, proposals
5. **Everything is saved locally** — drafts, logs, prototypes, reports

No cloud costs. No API fees. Everything runs on your machine.

## Models Used

| Model | Where | Cost |
|-------|-------|------|
| qwen3:8b (Ollama) | All scripts — scanning, drafting, building | Free (local) |
| GPT-OSS 120B (Groq) | OpenClaw agent conversations | Free (Groq API) |

## Key Paths

| What | Where |
|------|-------|
| Bot root | `/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot/` |
| Scan reports | `opportunities/reports/world-scan-*.md` |
| Email drafts | `outreach/drafts/email-*.md` |
| Prototypes | `prototypes/builds/*/` |
| Lead data | `leads/data/*.json` |
| Logs | `logging/bot-YYYY-MM-DD.log` |
| Config | `config/bot-config.json` |

## Important Notes

- **Always `cd /Volumes/Expansion/CMO-10million` before running commands**
- **Ollama must be running** for any AI features to work
- **External HD must be connected** — the entire system lives on `/Volumes/Expansion/`
- The Desktop `OpenClaw-AI-CMO` folder is a stale leftover — safe to delete
- The real workspace is on the external HD at `/Volumes/Expansion/CMO-10million/`
