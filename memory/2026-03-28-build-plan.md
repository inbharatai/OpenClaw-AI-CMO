# InBharat AI — Build Plan & Responsibility Split
**Date:** Saturday, March 28th, 2026
**Status:** Approved architecture. Implementation-ready.

---

## 1. FINAL RESPONSIBILITY MAP

### OPENCLAW — The Hands
**Role:** Runtime execution engine. Routes messages. Runs tools. Connects channels.

| Owns | Does NOT Own |
|------|-------------|
| Tool execution (exec, read, write, edit) | Business logic |
| Web search (DuckDuckGo) | Content strategy |
| Web fetch (URLs, APIs) | Approval decisions |
| Gmail MCP (draft, read, search) | Lead qualification |
| WhatsApp channel routing | Pipeline orchestration |
| Model hosting (Groq + Ollama) | Task prioritization |
| Session management | Budget decisions |
| Browser tool | Community strategy |

**Invoked by:** InBharat Bot (via `/commands`) and CMO Pipeline (via cron scripts)
**Never invoked directly by:** End users (they talk to InBharat Bot, which uses OpenClaw tools)

---

### INBHARAT BOT — The Brain
**Role:** Founder's right-hand operator. Strategic intelligence. Outreach. Revenue pipeline.

| Module | Function | Status |
|--------|----------|--------|
| **scanner** | Ecosystem scanning (repos, workspace, products) | ✅ Exists |
| **gap-finder** | AI gap analysis from scan data | ✅ Exists |
| **proposal-generator** | Strategic build proposals from gaps | ✅ Exists |
| **cmo-bridge** | Convert proposals → CMO source notes | ✅ Exists |
| **dashboard** | System health + activity dashboard | ✅ Exists |
| **approval** | Approval gate functions | ✅ Exists |
| **tasks** | Task discovery + tracking | ✅ Exists |
| **leads** | Lead capture + qualification | 🔄 Moving from CMO |
| **revenue** | Revenue pipeline management | 🔄 Moving from CMO |
| **outreach** | Email drafting + tracking | 🆕 To build |
| **opportunities** | Opportunity mining + competitor intel | 🔄 Moving from CMO |
| **government** | Gov scheme/RFP/tender scanning | 🆕 To build |

**Commands (via WhatsApp or terminal):**
```
/scan          — Ecosystem scan
/analyze       — Gap analysis
/propose       — Build proposals
/bridge        — Feed proposals to CMO
/status        — System dashboard
/full          — Complete intelligence cycle
/leads         — Show lead pipeline
/leads capture <text>  — Capture new lead
/revenue       — Revenue pipeline status
/outreach draft <context> — Draft outreach email
/outreach track — Show outreach log
/opportunities — Mine opportunities
/competitors   — Competitor analysis
/government    — Scan gov schemes/tenders
```

---

### CMO PIPELINE — The Factory
**Role:** Content production, quality gating, distribution. Runs autonomously on cron.

| Module | Function | Status |
|--------|----------|--------|
| **intake-processor** | Scan sources, classify content | ✅ Working |
| **content-agent** | Generate content from classified sources | ✅ Working |
| **newsroom-agent** | AI news processing | ✅ Working |
| **product-update-agent** | Product update content | ✅ Fixed (SIGPIPE) |
| **approval-engine** | 4-level approval pipeline | ✅ Working |
| **distribution-engine** | Multi-channel distribution | ⚠️ 0 channels active |
| **reporting-engine-v2** | Daily/weekly/monthly reports | ✅ Working |
| **skill-runner** | Ollama skill execution bridge | ✅ Working |
| **model-router** | Model selection (currently no-op) | ⚠️ Both models same |
| **community-scout** | Community profiling | ✅ Working |
| **community-operator** | Community action orchestration | ✅ Working |
| **community-rewriter** | Platform-native content adaptation | ✅ Working |
| **multilingual-adapter** | Language adaptation (EN/AS/HI/BN) | ✅ Working |
| **budget-governor** | Spend tracking + caps | ✅ Working |
| **workspace-guard** | Path security enforcement | ✅ Working |
| **verify-evidence** | File + system health verification | ✅ Working |
| **memory-write** | Structured memory persistence | ✅ Working |
| **socialflow-publisher** | Social API bridge (deprecated) | ⚠️ SocialFlow not running |
| **engagement-tracker** | Event logging + aggregation | ✅ Working |

**Cron schedule:**
- Daily 6 AM: intake → newsroom → product-updates → content → approve → distribute → report
- Monday 8 AM: weekly calendar + roundup + newsletter + video/image briefs + review
- 1st of month 9 AM: pillar review + SEO + campaign + archive cleanup + monthly report

**Scripts REMOVED from CMO (moved to InBharat Bot):**
- lead-capture.sh → InBharat Bot /leads
- proposal-builder.sh → InBharat Bot /revenue
- revenue-engine.sh → InBharat Bot /revenue

**Skills REMOVED from CMO (moved to InBharat Bot):**
- opportunity-miner → InBharat Bot /opportunities
- lead-research → InBharat Bot /leads
- competitor-monitor → InBharat Bot /opportunities

---

## 2. MODULE MAP

### InBharat Bot — After Restructure

```
inbharat-bot/
├── inbharat-run.sh              # Master orchestrator (updated with new modes)
├── config/
│   └── bot-config.json          # Bot configuration
├── scanner/
│   └── ecosystem-scanner.sh     # Ecosystem scanning
├── gap-finder/
│   └── gap-finder.sh            # Gap analysis via Ollama
├── proposal-generator/
│   └── proposal-generator.sh    # Build proposals via Ollama
├── cmo-bridge/
│   └── cmo-bridge.sh            # Proposals → CMO source notes
├── dashboard/
│   ├── generate-state.sh        # Dashboard state generation
│   ├── bot-state.json           # Machine-readable state
│   └── bot-status.md            # Human-readable status
├── approval/
│   └── approval-gate.sh         # Approval classification functions
├── tasks/
│   ├── pending/                 # Active tasks
│   ├── in-progress/
│   ├── done/
│   └── blocked/
├── leads/                       # 🔄 MOVED from CMO
│   ├── lead-capture.sh          # Lead qualification via Ollama
│   └── data/                    # Lead JSON files (moved from revenue/leads/)
├── revenue/                     # 🔄 MOVED from CMO
│   ├── revenue-engine.sh        # Pipeline orchestration
│   ├── proposal-builder.sh      # Proposal generation via Ollama
│   ├── proposals/               # Generated proposals
│   ├── pipeline-state/          # State snapshots
│   └── followups/               # Follow-up tracking
├── outreach/                    # 🆕 NEW
│   ├── outreach-drafter.sh      # Email/message drafting via Ollama
│   ├── outreach-tracker.sh      # JSONL log of all outreach
│   ├── drafts/                  # Draft emails/messages
│   └── log/                     # Outreach activity log
├── opportunities/               # 🔄 MOVED skills from CMO
│   ├── opportunity-scanner.sh   # Opportunity mining wrapper
│   ├── competitor-tracker.sh    # Competitor monitoring wrapper
│   └── reports/                 # Opportunity/competitor reports
├── government/                  # 🆕 NEW
│   ├── gov-scanner.sh           # Gov scheme/tender scanner
│   ├── gov-proposal-writer.sh   # Government proposal drafting
│   ├── schemes/                 # Found schemes/tenders
│   └── proposals/               # Government proposals
├── registry/                    # Ecosystem scan results
├── logging/
│   ├── bot-logger.sh
│   └── bot-YYYY-MM-DD.log
└── skills/                      # 🆕 InBharat Bot's own skills
    ├── opportunity-miner/SKILL.md
    ├── lead-research/SKILL.md
    ├── competitor-monitor/SKILL.md
    ├── professional-email-drafter/SKILL.md    # 🆕 NEW
    ├── government-proposal-writer/SKILL.md    # 🆕 NEW
    └── institutional-outreach-drafter/SKILL.md # 🆕 NEW
```

### CMO Pipeline — After Restructure

```
scripts/                         # Unchanged (minus 3 moved scripts)
├── daily-pipeline.sh
├── weekly-pipeline.sh
├── monthly-pipeline.sh
├── intake-processor.sh
├── content-agent.sh
├── newsroom-agent.sh
├── product-update-agent.sh
├── approval-engine.sh
├── distribution-engine.sh
├── reporting-engine-v2.sh
├── skill-runner.sh
├── model-router.sh
├── community-scout.sh
├── community-operator.sh
├── community-rewriter.sh
├── multilingual-adapter.sh
├── budget-governor.sh
├── socialflow-publisher.sh
├── engagement-tracker.sh
├── workspace-guard.sh
├── verify-evidence.sh
├── memory-write.sh
├── task-builder.sh
├── task-plan.sh
└── generate-report.sh

skills/                          # CMO skills (minus 3 moved to InBharat Bot)
├── 52 remaining marketing/content skills
└── (opportunity-miner, lead-research, competitor-monitor REMOVED)
```

---

## 3. WORKFLOW MAP

### Workflow A: Daily Content Pipeline (CMO, Automated)
```
6:00 AM cron trigger
  → intake-processor.sh: scan sources, classify via Ollama
  → newsroom-agent.sh: generate news content
  → product-update-agent.sh: generate product updates
  → content-agent.sh: generate remaining content
  → approval-engine.sh: L1/L2/L3/L4 scoring
  → distribution-engine.sh: distribute to active channels
  → reporting-engine-v2.sh: generate daily report
```

### Workflow B: Ecosystem Intelligence (InBharat Bot, On-demand)
```
User sends /full (or /scan, /analyze, /propose, /bridge)
  → ecosystem-scanner.sh: scan workspace structure
  → gap-finder.sh: AI analysis of gaps via Ollama
  → proposal-generator.sh: generate build proposals
  → cmo-bridge.sh: convert to CMO source notes
     → source note lands in MarketingToolData/source-notes/
     → next daily pipeline picks it up automatically
  → generate-state.sh: update dashboard
```

### Workflow C: Lead Pipeline (InBharat Bot, On-demand)
```
User sends /leads capture "email from Priya at LearnFlow about AI consulting"
  → lead-capture.sh: qualify via Ollama → JSON in leads/data/
  → If hot lead: auto-trigger proposal-builder.sh
  → User sends /revenue: see pipeline status
  → User sends /outreach draft "follow up with Priya": draft email
  → Draft saved to outreach/drafts/ + logged to outreach/log/
  → User reviews draft, sends via Gmail manually or via Gmail MCP
```

### Workflow D: Government Opportunity (InBharat Bot, On-demand)
```
User sends /government
  → gov-scanner.sh: web_search for Indian gov AI schemes/tenders
  → Results saved to government/schemes/
  → User reviews, sends /government propose <scheme-id>
  → gov-proposal-writer.sh: generate proposal via Ollama
  → Proposal saved to government/proposals/
  → User reviews, sends via email or physical submission
```

### Workflow E: Outreach (InBharat Bot, On-demand)
```
User sends /outreach draft "introduce InBharat to ICDS department"
  → outreach-drafter.sh: load professional-email-drafter skill
  → Ollama generates draft email
  → Draft saved to outreach/drafts/
  → Logged to outreach/log/outreach-YYYY-MM-DD.jsonl
  → User reviews, edits if needed, sends via Gmail
```

### Workflow F: Status Check (InBharat Bot, On-demand)
```
User sends /status
  → generate-state.sh:
     - Check gateway PID
     - Check Ollama models
     - Count scans/findings/proposals/bridges
     - Count leads/proposals/follow-ups
     - Read latest pipeline log
     - Generate bot-state.json + bot-status.md
  → Return dashboard to user
```

---

## 4. EMAIL / GOVERNMENT PROPOSAL FLOW

### Email Outreach Flow
```
TRIGGER: User request via /outreach draft
  │
  ▼
InBharat Bot: outreach-drafter.sh
  │ Loads: professional-email-drafter skill
  │ Context: recipient info, purpose, product context
  │ Model: Ollama qwen3:8b (free, local)
  │
  ▼
DRAFT saved to: outreach/drafts/email-YYYY-MM-DD-<slug>.md
  │ Format: frontmatter (to, subject, purpose, status:draft) + body
  │
  ▼
LOG entry: outreach/log/outreach-YYYY-MM-DD.jsonl
  │ Fields: date, type, recipient, subject, status, draft_file
  │
  ▼
USER REVIEW: Owner reads draft, approves or edits
  │
  ▼
SEND: Two options:
  a) Manual: copy-paste into Gmail
  b) Gmail MCP: OpenClaw gmail_create_draft tool (when configured)
  │
  ▼
TRACK: Update outreach log with sent status + date
```

### Government Proposal Flow
```
TRIGGER: User request via /government
  │
  ▼
InBharat Bot: gov-scanner.sh
  │ Uses: OpenClaw web_search + web_fetch
  │ Searches: Indian gov AI schemes, ICDS, MEITY, Digital India, CSC, tenders
  │ Model: Groq GPT-OSS-120B (for research quality)
  │
  ▼
SCHEMES saved to: government/schemes/scheme-YYYY-MM-DD-<name>.json
  │ Fields: name, department, deadline, eligibility, url, relevance_score
  │
  ▼
USER selects scheme → /government propose <scheme>
  │
  ▼
InBharat Bot: gov-proposal-writer.sh
  │ Loads: government-proposal-writer skill
  │ Context: scheme details + InBharat product capabilities
  │ Model: Ollama qwen3:8b
  │
  ▼
PROPOSAL saved to: government/proposals/proposal-<scheme>-YYYY-MM-DD.md
  │ Format: Indian government proposal structure
  │ (Background, Objectives, Methodology, Team, Budget, Timeline)
  │
  ▼
USER REVIEW → submit physically or via email
```

---

## 5. APPROVAL MODEL

### CMO Content Approval (Unchanged — Working)
```
L1: Auto-approve (build-log, changelog, educational, product-update)
L2: Score-gated (risk scoring across 6 dimensions)
     - max_dimension < 60 AND weighted_avg < 45 AND data_safety < 30 → approve
     - max_dimension > 75 OR data_safety > 35 → block
L3: Human review (everything else)
L4: Safety block (credential/PII detection)
```

### InBharat Bot Approval
```
AUTO-APPROVED (no gate needed):
  - Ecosystem scanning
  - Gap analysis
  - Proposal generation (internal)
  - Dashboard/status
  - Lead capture/qualification
  - Opportunity mining
  - Competitor monitoring
  - Outreach DRAFTING (not sending)
  - Government scheme SCANNING (not proposing)

REQUIRES OWNER APPROVAL:
  - Outreach SENDING (email, WhatsApp to external contacts)
  - Government proposal SUBMISSION
  - Revenue pipeline actions (proposal sending)
  - Any external communication
  - Any destructive git operations
  - Any paid API calls
```

---

## 6. IMPLEMENTATION ROADMAP

### Phase 1: Structural Move (Today — 2 hours)
**Goal:** Move scripts from CMO to InBharat Bot. Create directory structure. No new code.

| # | Task | Time |
|---|------|------|
| 1.1 | Create InBharat Bot directories: leads/, revenue/, outreach/, opportunities/, government/, skills/ | 5 min |
| 1.2 | Copy lead-capture.sh → inbharat-bot/leads/ | 2 min |
| 1.3 | Copy proposal-builder.sh → inbharat-bot/revenue/ | 2 min |
| 1.4 | Copy revenue-engine.sh → inbharat-bot/revenue/ | 2 min |
| 1.5 | Copy opportunity-miner skill → inbharat-bot/skills/ | 2 min |
| 1.6 | Copy lead-research skill → inbharat-bot/skills/ | 2 min |
| 1.7 | Copy competitor-monitor skill → inbharat-bot/skills/ | 2 min |
| 1.8 | Update paths in copied scripts to reference new locations | 15 min |
| 1.9 | Symlink revenue/leads/ data → inbharat-bot/leads/data/ | 2 min |
| 1.10 | Update inbharat-run.sh with new command modes | 20 min |
| 1.11 | Update SOUL.md command routing table | 10 min |
| 1.12 | Update bot-config.json with new modules | 5 min |
| 1.13 | Test: /status, /leads, /revenue all respond | 15 min |

### Phase 2: Outreach Capability (This Week — 3 hours)
**Goal:** Build email drafting + tracking. No external integrations yet.

| # | Task | Time |
|---|------|------|
| 2.1 | Create professional-email-drafter skill (SKILL.md) | 30 min |
| 2.2 | Create outreach-drafter.sh (drafts emails via Ollama) | 45 min |
| 2.3 | Create outreach-tracker.sh (JSONL log + status queries) | 30 min |
| 2.4 | Add /outreach commands to orchestrator | 15 min |
| 2.5 | Create institutional-outreach-drafter skill | 20 min |
| 2.6 | Test: /outreach draft "introduce to ICDS" produces draft | 15 min |
| 2.7 | Test: /outreach track shows log | 10 min |

### Phase 3: Government Scanning (Week 2 — 3 hours)
**Goal:** Build gov scheme/tender discovery + proposal writing.

| # | Task | Time |
|---|------|------|
| 3.1 | Create government-proposal-writer skill (SKILL.md) | 30 min |
| 3.2 | Create gov-scanner.sh (uses web_search for schemes) | 60 min |
| 3.3 | Create gov-proposal-writer.sh (proposals via Ollama) | 45 min |
| 3.4 | Add /government commands to orchestrator | 15 min |
| 3.5 | Test: /government scans and returns real schemes | 20 min |
| 3.6 | Test: /government propose generates proposal | 15 min |

### Phase 4: Distribution Activation (Week 2 — 1 hour)
**Goal:** Get at least one distribution channel live.

| # | Task | Time |
|---|------|------|
| 4.1 | Create Discord server + get webhook URL | 10 min |
| 4.2 | Create discord-webhook.json config | 5 min |
| 4.3 | Run daily pipeline → verify Discord receives post | 15 min |
| 4.4 | Review + purge 80 blocked approval items | 30 min |

### Phase 5: Gmail Integration (Week 3 — 2 hours)
**Goal:** Connect Gmail MCP for draft creation from InBharat Bot.

| # | Task | Time |
|---|------|------|
| 5.1 | Configure Gmail MCP in OpenClaw (OAuth setup) | 45 min |
| 5.2 | Test gmail_create_draft tool via OpenClaw | 15 min |
| 5.3 | Wire outreach-drafter to optionally create Gmail draft | 30 min |
| 5.4 | Test full flow: /outreach draft → Gmail draft appears | 15 min |

### Phase 6: Refinement (Month 2)
**Goal:** Scale operations, add more channels.

| # | Task | Time |
|---|------|------|
| 6.1 | Configure X OAuth for social posting | 2 hours |
| 6.2 | Populate community profiles (5 target communities) | 1 hour |
| 6.3 | Populate memory files from founder input | 1 hour |
| 6.4 | Add pipeline completion WhatsApp notification | 1 hour |
| 6.5 | Consider upgrading pipeline content model (Groq via API) | 2 hours |

---

## 7. FINAL RECOMMENDATION

**The split is clean:**

CMO = factory (content in, content out, cron-driven, autonomous)
InBharat Bot = brain (strategy, research, outreach, leads, proposals, on-demand)
OpenClaw = hands (tools, channels, model hosting, execution)

**Build order by impact:**
1. Move scripts (structural clarity) — Phase 1
2. Build outreach (new capability) — Phase 2
3. Build government scanning (new market) — Phase 3
4. Activate distribution (unblock content) — Phase 4
5. Connect Gmail (outreach delivery) — Phase 5
6. Scale (more channels, communities) — Phase 6

**What NOT to build yet:**
- SocialFlow integration (dead service, use direct APIs instead)
- HeyGen video production (nice-to-have, not urgent)
- Embedding-based memory (file-based works fine)
- Multi-model routing (meaningless until different models added)
- LinkedIn posting (owner blocked it, respect the decision)
