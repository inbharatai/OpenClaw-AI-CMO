# InBharat AI — Complete System Guide

**Everything you need to know to use your AI system, explained simply.**

Last updated: 2026-03-28

---

## What Is This System?

You have THREE connected systems that work together:

| System | What it does | Where it lives |
|--------|-------------|----------------|
| **OpenClaw** | The "hands" — runs tools, sends messages, connects to WhatsApp | `~/.openclaw/` (config) |
| **InBharat Bot** | The "brain" — scans for opportunities, drafts emails, builds prototypes | `/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot/` |
| **CMO Pipeline** | The "factory" — generates content (blogs, social posts, SEO) | `/Volumes/Expansion/CMO-10million/OpenClawData/scripts/` |

**Think of it like this:**
- OpenClaw = your phone (the device that runs things)
- InBharat Bot = your business brain (finds opportunities, writes emails, builds apps)
- CMO Pipeline = your content team (writes blogs, social posts, newsletters)

---

## Before You Start (Checklist)

1. **External HD connected?** Check that `/Volumes/Expansion/` exists
   ```bash
   ls /Volumes/Expansion/CMO-10million/
   # Should show: OpenClawData, MarketingToolData, memory, etc.
   ```

2. **Ollama running?** This is the local AI engine
   ```bash
   curl -s http://127.0.0.1:11434/api/tags | python3 -c "import sys,json; print([m['name'] for m in json.load(sys.stdin)['models']])"
   # Should show: ['qwen3:8b']
   ```
   If not running:
   ```bash
   ollama serve &
   ```

3. **OpenClaw gateway running?** (optional — only needed for WhatsApp)
   ```bash
   curl -s http://localhost:18789/health
   ```

---

## How to Use InBharat Bot

### Basic pattern: always start from the workspace

```bash
cd /Volumes/Expansion/CMO-10million
bash OpenClawData/inbharat-bot/inbharat-run.sh <command>
```

### Most useful commands (start here)

| What you want | Command |
|---------------|---------|
| "Show me what's available" | `bash OpenClawData/inbharat-bot/inbharat-run.sh help` |
| "Find me opportunities" | `bash OpenClawData/inbharat-bot/inbharat-run.sh opportunities all` |
| "Find government tenders" | `bash OpenClawData/inbharat-bot/inbharat-run.sh opportunities government` |
| "Find problems I can solve" | `bash OpenClawData/inbharat-bot/inbharat-run.sh opportunities problems` |
| "Find companies needing AI" | `bash OpenClawData/inbharat-bot/inbharat-run.sh opportunities corporate` |
| "Draft an email" | `bash OpenClawData/inbharat-bot/inbharat-run.sh outreach draft "introduce us to NITI Aayog"` |
| "Build me an app" | `bash OpenClawData/inbharat-bot/inbharat-run.sh prototype build "attendance tracker"` |
| "Find a problem and build a solution" | `bash OpenClawData/inbharat-bot/inbharat-run.sh prototype pipeline` |
| "What's the system status?" | `bash OpenClawData/inbharat-bot/inbharat-run.sh status` |
| "Record a new lead" | `bash OpenClawData/inbharat-bot/inbharat-run.sh leads capture "inquiry from XYZ about AI"` |

### Step-by-step examples

#### Example 1: Find opportunities and act on them

```bash
cd /Volumes/Expansion/CMO-10million

# Step 1: Scan for opportunities
bash OpenClawData/inbharat-bot/inbharat-run.sh opportunities all
# → Wait 3-5 minutes. It searches DuckDuckGo and analyzes results.
# → Output: a report in opportunities/reports/world-scan-DATE-all.md

# Step 2: Read the report
cat OpenClawData/inbharat-bot/opportunities/reports/world-scan-$(date +%Y-%m-%d)-all.md

# Step 3: Found a government tender? Draft a proposal email
bash OpenClawData/inbharat-bot/inbharat-run.sh government propose "Vidya Samiksha Kendra AI tender Assam"
# → Output: email draft in outreach/drafts/

# Step 4: Found a company partner? Draft intro email
bash OpenClawData/inbharat-bot/inbharat-run.sh outreach draft "introduce InBharat AI to EdTech company ABC for AI tutoring partnership"
# → Output: email draft ready to copy to Gmail
```

#### Example 2: Build and launch a prototype

```bash
cd /Volumes/Expansion/CMO-10million

# Option A: Tell it what to build
bash OpenClawData/inbharat-bot/inbharat-run.sh prototype build "student test prep quiz app with timer and scoring"
# → Generates working HTML app in prototypes/builds/

# Option B: Let it find a problem and build automatically
bash OpenClawData/inbharat-bot/inbharat-run.sh prototype pipeline
# → Scans web for problems → picks the best one → builds a prototype → launches it

# Launch a prototype locally
bash OpenClawData/inbharat-bot/inbharat-run.sh prototype launch prototypes/builds/2026-03-28-student-test-prep/
# → Opens in your browser at localhost:8090

# Package for deployment
bash OpenClawData/inbharat-bot/inbharat-run.sh prototype package prototypes/builds/2026-03-28-student-test-prep/
# → Creates a .zip file ready to upload to Vercel or Netlify
```

#### Example 3: Manage leads and revenue

```bash
cd /Volumes/Expansion/CMO-10million

# Someone emailed you about AI tutoring? Capture it
bash OpenClawData/inbharat-bot/inbharat-run.sh leads capture "LearnFlow EdTech asked about AI tutoring integration, CEO Priya"

# Check your lead pipeline
bash OpenClawData/inbharat-bot/inbharat-run.sh leads status

# Process hot leads (auto-generates proposals)
bash OpenClawData/inbharat-bot/inbharat-run.sh revenue process

# Check what needs follow-up
bash OpenClawData/inbharat-bot/inbharat-run.sh revenue followups
```

---

## How to Use OpenClaw

OpenClaw is the platform that runs the bot. You mostly don't interact with it directly — it runs in the background and connects to WhatsApp.

### Start OpenClaw

```bash
# It should auto-start via LaunchAgent. Check if it's running:
curl -s http://localhost:18789/health

# If not running, start manually:
cd /Volumes/Expansion/CMO-10million
npx openclaw gateway
```

### OpenClaw via WhatsApp

Once OpenClaw is running and connected to WhatsApp, you can send commands via WhatsApp to your bot. The bot responds using the rules in `SOUL.md`.

**WhatsApp commands:** Same as the command routing table — type `/status`, `/opportunities`, `/outreach draft ...` etc.

### OpenClaw Configuration

Config file: `~/.openclaw/openclaw.json`

| Setting | Current value |
|---------|--------------|
| Workspace | `/Volumes/Expansion/CMO-10million` |
| Primary model | GPT-OSS 120B via Groq (free) |
| Local model | qwen3:8b via Ollama (free) |
| WhatsApp | Enabled, DM only from your number |
| Skills directory | `/Volumes/Expansion/CMO-10million/OpenClawData/skills` |
| Gateway port | 18789 |

### OpenClaw Workspace Files

These files control how the bot behaves when you chat with it:

| File | What it does |
|------|-------------|
| `~/.openclaw/workspace/SOUL.md` | Core rules — response format, command routing, truth layer |
| `~/.openclaw/workspace/IDENTITY.md` | Bot identity — capabilities, known issues |
| `~/.openclaw/workspace/TOOLS.md` | System reference — paths, models, crons |
| `~/.openclaw/workspace/HEARTBEAT.md` | Health check protocol |

---

## How to Use CMO Pipeline

The CMO pipeline auto-generates content. It runs on a schedule via LaunchAgents (cron jobs).

### Automated schedule

| When | What runs | Command |
|------|-----------|---------|
| Daily (6 AM) | Content generation, trend analysis | `bash OpenClawData/scripts/daily-pipeline.sh` |
| Weekly (Monday 8 AM) | Performance report, strategy review | `bash OpenClawData/scripts/weekly-pipeline.sh` |
| Monthly (1st, 9 AM) | Monthly report, content audit | `bash OpenClawData/scripts/monthly-pipeline.sh` |

### Run manually

```bash
cd /Volumes/Expansion/CMO-10million

# Daily pipeline
bash OpenClawData/scripts/daily-pipeline.sh

# Weekly
bash OpenClawData/scripts/weekly-pipeline.sh

# Monthly
bash OpenClawData/scripts/monthly-pipeline.sh
```

### Where content goes

| What | Path |
|------|------|
| Generated content | `OpenClawData/queues/ready/` |
| Awaiting approval | `OpenClawData/approvals/pending/` |
| Published | `OpenClawData/approvals/approved/` |
| Reports | `OpenClawData/reports/` |

---

## Folder Structure (What Goes Where)

```
/Volumes/Expansion/CMO-10million/          ← YOUR WORKSPACE ROOT
│
├── OpenClawData/
│   ├── inbharat-bot/                      ← INBHARAT BOT (the brain)
│   │   ├── inbharat-run.sh               ← Master command (run everything from here)
│   │   ├── scanner/                       ← Ecosystem scanning
│   │   ├── gap-finder/                    ← Gap analysis
│   │   ├── proposal-generator/            ← Build proposals
│   │   ├── cmo-bridge/                    ← Feed to CMO
│   │   ├── dashboard/                     ← Health monitoring
│   │   ├── opportunities/                 ← World scanner + reports
│   │   ├── prototypes/                    ← Built prototypes
│   │   ├── outreach/                      ← Email drafts + logs
│   │   ├── leads/                         ← Business leads
│   │   ├── revenue/                       ← Revenue pipeline
│   │   ├── government/                    ← Government proposals
│   │   ├── skills/                        ← AI prompt templates
│   │   ├── logging/                       ← Bot logs
│   │   ├── approval/                      ← Action classification
│   │   └── config/                        ← Bot configuration
│   │
│   ├── scripts/                           ← CMO PIPELINE (the factory)
│   │   ├── daily-pipeline.sh
│   │   ├── weekly-pipeline.sh
│   │   ├── monthly-pipeline.sh
│   │   ├── skill-runner.sh               ← Runs skills via Ollama
│   │   └── ... (28 scripts total)
│   │
│   ├── skills/                            ← SHARED SKILLS (55 prompt templates)
│   ├── queues/                            ← Content pipeline queues
│   ├── approvals/                         ← Content approval system
│   ├── reports/                           ← Generated reports
│   └── memory/                            ← System memory
│
├── MarketingToolData/                     ← Research and marketing data
├── memory/                                ← Build plans and decisions
└── README.md                              ← THIS FILE
```

---

## Cleaning Up Confusion

### Desktop `OpenClaw-AI-CMO` folder
This is a **stale leftover** from initial setup. It only contains an empty `logs/` folder (4KB). **Safe to delete:**
```bash
rm -rf ~/Desktop/OpenClaw-AI-CMO
```

### Desktop `INBharat Ai` folder
If empty, also safe to delete. The real InBharat Bot lives on the external HD.

### Where is the REAL system?
Everything lives on your **external hard drive** at:
```
/Volumes/Expansion/CMO-10million/
```
Make sure the external HD is plugged in before using any commands.

---

## Troubleshooting

### "Ollama not running"
```bash
ollama serve &
# Wait 5 seconds, then retry your command
```

### "Bot root not found"
Your external HD isn't mounted. Plug it in and check:
```bash
ls /Volumes/Expansion/CMO-10million/
```

### "No search results" / "Very few results"
Check your internet connection. The world scanner uses DuckDuckGo.

### "ERROR: No response from model"
Ollama is running but the model isn't loaded:
```bash
ollama pull qwen3:8b
```

### "jq: command not found"
Install jq:
```bash
brew install jq
```

### "Command not found: python3"
Install Python:
```bash
brew install python3
```

---

## Cost

**Everything is free.**

| Component | Cost |
|-----------|------|
| Ollama (local AI) | Free — runs on your Mac |
| Groq API (GPT-OSS 120B) | Free tier |
| DuckDuckGo (web search) | Free |
| OpenClaw gateway | Free (npm package) |
| All scripts and skills | Free (your own code) |

---

## Summary: The 5 Things You Actually Need to Remember

1. **Always `cd /Volumes/Expansion/CMO-10million` first**
2. **Make sure Ollama is running** (`ollama serve &`)
3. **Use `bash OpenClawData/inbharat-bot/inbharat-run.sh help`** to see all commands
4. **The Desktop CMO folder is junk** — delete it
5. **Everything is free** — no API costs, no cloud fees
