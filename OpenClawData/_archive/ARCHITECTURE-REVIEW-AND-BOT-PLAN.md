# Architecture Review & Bot Evolution Plan
## Honest Assessment + Future Direction
### Date: 2026-03-25

---

## 1. EXECUTIVE SUMMARY

You have a surprisingly complete foundation. It's not fake — but it's also never been run end-to-end in production. The architecture is sound for a solo builder, but the gap between "files exist" and "system runs autonomously" is the critical gap to close.

**What's real:**
- 18 shell scripts that form a genuine content pipeline (intake → produce → approve → distribute → report)
- 60 SKILL.md prompt templates that feed into Ollama via skill-runner.sh
- 4 JSON policy files (approval rules, rate limits, brand voice, channel policies)
- SocialFlow app (FastAPI + browser automation) with a working OpenClaw bridge API
- Folder structure: queues per channel, approvals with 4 states, memory, reports, logs
- Both Ollama models running (qwen3:8b + qwen2.5-coder:7b)
- Real content has been produced: 56 marketing files, 32 approval files, 7 reports, 19 log files

**What's never been proven:**
- The daily-pipeline.sh has never run fully unattended from cron
- No platform has received an actual auto-post
- SocialFlow bridge exists but has never published to a real platform
- The approval engine has never scored real content through all 4 levels in production
- Memory has only 2 files — the system barely remembers anything yet

**Honest verdict:** You're at ~70% of V1. The remaining 30% is integration testing, cron setup, and closing the "queue → actually posted" gap.

---

## 2. CURRENT STATE REVIEW

### Repository / Codebase Location
- **Workspace:** `/Volumes/Expansion/CMO-10million/`
- **Scripts:** `OpenClawData/scripts/` (18 bash scripts, 53-274 lines each)
- **Skills:** `OpenClawData/skills/` (60 SKILL.md files, 44-107 lines each)
- **Policies:** `OpenClawData/policies/` (4 JSON files — approval, rate limits, brand voice, channel rules)
- **SocialFlow:** `SocialFlow/` (Python FastAPI app with browser-based posting + OpenClaw bridge)
- **Original OpenClaw:** Was at `/Volumes/Expansion/Tools/proclaw.ai/` — **no longer accessible** (drive path changed or removed). The original ProClaw/OpenClaw web app is NOT running. Everything operates through the shell scripts + Ollama directly.

### What Claude Code Sessions Have Built (Verified)
| Component | Files | Real? | Tested? |
|---|---|---|---|
| Shell pipeline scripts (18) | OpenClawData/scripts/*.sh | Yes — real bash logic | Partially (individual scripts tested, full pipeline not) |
| SKILL.md templates (60) | OpenClawData/skills/*/SKILL.md | Yes — real prompt templates | Yes (skill-runner.sh verified with Ollama) |
| Policy configs (4) | OpenClawData/policies/*.json | Yes — well-structured | Not consumed by scripts yet |
| SocialFlow app | SocialFlow/backend/ | Yes — real FastAPI app | Partially (bridge exists, no live posts) |
| OpenClaw bridge API | SocialFlow/backend/openclaw_bridge.py | Yes — real API endpoints | Not tested in production |
| Folder structure | Queues, approvals, memory, reports, logs | Yes — correct layout | Has real files from test runs |
| Desktop reference | ~/Desktop/Important/ | Yes — reference docs | — |

---

## 3. WHAT ALREADY WORKS (High-Value, Preserve)

### A. The Shell Script Pipeline (KEEP — this is the backbone)
The 18 scripts form a real, functional pipeline:

```
intake-processor.sh → content-agent.sh → approval-engine.sh → distribution-engine.sh → generate-report.sh
     ↑                       ↑                    ↑                      ↑
newsroom-agent.sh    model-router.sh      risk scoring           socialflow-publisher.sh
product-update-agent.sh  skill-runner.sh    brand voice check    discord webhook
```

**Why this works:** Each script is 50-275 lines, reads/writes real files, calls Ollama API, and logs actions. This is not placeholder code.

**Orchestrators:**
- `daily-pipeline.sh` (148 lines) — runs the full daily flow
- `weekly-pipeline.sh` (135 lines) — weekly content production
- `monthly-pipeline.sh` (141 lines) — monthly strategy review

### B. The SKILL.md Library (KEEP — prompt engineering foundation)
60 well-structured prompt templates. Each has:
- YAML frontmatter (name, description)
- Clear model assignment
- Input/output format
- Tone/style rules

These are consumed by `skill-runner.sh` which feeds them to Ollama. This pattern works.

### C. The Policy System (KEEP — needs wiring)
4 JSON policy files with real rules:
- `approval-rules.json` — 4-level model with weighted scoring dimensions
- `rate-limits.json` — per-channel caps, email safeguards, intervals
- `brand-voice-rules.json` — tone/style rules
- `channel-policies.json` — per-platform rules

**Problem:** These JSON files exist but the shell scripts may not fully parse and enforce them yet. The approval-engine.sh uses Ollama to score content but may not read the JSON thresholds programmatically.

### D. SocialFlow Bridge (KEEP — needs activation)
Real FastAPI backend with:
- `/api/openclaw/publish` endpoint
- `/api/openclaw/batch` endpoint
- `/api/openclaw/status` endpoint
- Browser-based automation for LinkedIn, Instagram, X
- SQLite database for history
- APScheduler for timed posting

This is a real app, not a stub. But it hasn't posted to any platform yet.

### E. The Folder Architecture (KEEP — well designed)
```
OpenClawData/
  scripts/      ← 18 real scripts
  skills/       ← 60 SKILL.md templates
  policies/     ← 4 JSON policy files
  queues/       ← per-channel output folders (empty — pipeline hasn't distributed yet)
  approvals/    ← 4 states: pending, approved, review, blocked (32 files from test runs)
  memory/       ← 2 files (barely used)
  reports/      ← daily/weekly/monthly (7 files from test runs)
  logs/         ← 19 log files from test runs
  sessions/     ← empty
  prompts/      ← empty

MarketingToolData/
  source-notes/, source-links/, product-updates/  ← intake
  website-posts/, insights/, newsletters/         ← production output
  linkedin/, x/, facebook/, instagram/, discord/  ← channel-specific content
  video-briefs/, image-briefs/                    ← media briefs
  56 total content files from test runs
```

---

## 4. WHAT IS WEAK / BROKEN / MISLEADING

### A. Critical Gaps

| Issue | Severity | Details |
|---|---|---|
| **Pipeline never run end-to-end unattended** | HIGH | daily-pipeline.sh was tested in pieces, never as a full cron-driven daily run |
| **Queues are empty** | HIGH | distribution-engine.sh hasn't actually moved approved content to channel queues |
| **No cron jobs configured** | HIGH | Nothing runs automatically — it's all manual execution |
| **Policy JSON not wired to scripts** | MEDIUM | JSON policies exist but approval-engine.sh may use Ollama scoring instead of reading thresholds from JSON |
| **Memory barely used** | MEDIUM | Only 2 files in memory/. The system doesn't learn or remember across sessions |
| **SocialFlow never posted** | MEDIUM | Bridge code exists, app exists, but zero live posts |
| **No Discord webhook configured** | LOW | Script ready, webhook URL not set |

### B. Structural Weaknesses

| Issue | Details | Fix |
|---|---|---|
| **Script error handling is basic** | Most scripts use simple `set -e` but lack retry logic or graceful degradation | Add proper error trapping per script |
| **No input validation on Ollama responses** | Scripts trust Ollama output blindly — could produce garbage | Add response sanity checks |
| **Duplicate skill coverage** | Some skills overlap (e.g., `reporting` vs `daily-briefing` vs `content-performance-tracker`) | Consolidate or clarify boundaries |
| **No versioning on content** | Once a file is overwritten, the old version is gone | Add date-stamped filenames (some scripts do this, not all) |
| **SocialFlow credentials unencrypted at rest** | Uses Fernet encryption but key management is basic | Acceptable for V1 solo use, needs hardening for V2 |

### C. What Is Misleading (Honest Assessment)

| Claim | Reality |
|---|---|
| "60 skills implemented" | 60 SKILL.md prompt templates exist. They're real prompt engineering but they are NOT runtime plugins. They only execute when called via skill-runner.sh |
| "4-level approval model" | The model is designed. approval-engine.sh exists. But it hasn't processed real content through all 4 levels in production |
| "Multi-agent system" | There are scripts named after agents (newsroom, product, content). They work. But they're sequential scripts, not concurrent agents |
| "Auto-approve works" | The logic is written but the thresholds haven't been calibrated against real content |
| "Distribution to 11 channels" | Distribution-engine.sh has code paths for each channel. But zero actual posts have been made |

**None of this is fake** — the code is real and functional. But calling it "working" when it hasn't completed a real cycle is overstating it.

---

## 5. BEST FUTURE ARCHITECTURE

### The Bot Should Be: One Orchestrator + Modular Skills + External Services

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OPENCLAW BOT ORCHESTRATOR                         │
│                     (daily/weekly/monthly cron)                       │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │  INTAKE       │  │  INTELLIGENCE │  │  PRODUCTION  │              │
│  │  MODULE       │  │  MODULE       │  │  MODULE      │              │
│  │              │  │              │  │              │              │
│  │ source scan  │  │ repo scanner │  │ content gen  │              │
│  │ news collect │  │ site scanner │  │ social adapt │              │
│  │ classify     │  │ gap finder   │  │ newsletter   │              │
│  │ prioritize   │  │ tool scorer  │  │ briefs       │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                  │                  │                      │
│         ▼                  ▼                  ▼                      │
│  ┌──────────────────────────────────────────────────┐               │
│  │              APPROVAL + SAFETY MODULE             │               │
│  │  risk score → brand check → dedup → policy gate   │               │
│  │  L1 auto │ L2 score-gate │ L3 review │ L4 block   │               │
│  └──────────────────────────┬───────────────────────┘               │
│                              │                                       │
│         ┌────────────────────┼────────────────────┐                 │
│         ▼                    ▼                    ▼                 │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ DISTRIBUTION │  │   MEMORY     │  │  REPORTING   │              │
│  │ MODULE       │  │   MODULE     │  │  MODULE      │              │
│  │              │  │              │  │              │              │
│  │ queue mgmt  │  │ brand rules  │  │ daily report │              │
│  │ webhook     │  │ decisions    │  │ weekly review│              │
│  │ SocialFlow  │  │ lessons      │  │ monthly plan │              │
│  │ email export│  │ context      │  │ performance  │              │
│  └─────────────┘  └──────────────┘  └──────────────┘              │
│                                                                      │
│  ┌──────────────────────────────────────────────────┐               │
│  │          NEW: BUILDER INTELLIGENCE MODULE         │               │
│  │  repo scan → feature inventory → gap analysis     │               │
│  │  tool scoring → build proposals → spec drafts     │               │
│  │  QA planning → doc planning → release planning    │               │
│  └──────────────────────────────────────────────────┘               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
        │                    │                     │
        ▼                    ▼                     ▼
   SocialFlow           Ollama API            File System
   (posting)          (qwen3 + coder)        (queues/memory)
```

### Why This Structure

1. **One orchestrator, not many bots** — You're a solo builder. Multiple independent bots create coordination overhead. One orchestrator calling modules is simpler and more debuggable.

2. **Modules = script groups, not microservices** — Each "module" is a set of related shell scripts + SKILL.md templates. No need for Docker, message queues, or service meshes.

3. **External services are bridges, not dependencies** — SocialFlow, Ollama, Discord webhooks are called through simple HTTP. If any is down, the pipeline continues and queues content.

4. **New: Builder Intelligence Module** — This is the evolution you're asking for. Same architecture pattern, new module that scans your repos/sites and proposes what to build next.

---

## 6. RECOMMENDED BOT STRUCTURE INSIDE OPENCLAW

### Should It Be One Bot or Many?

**One orchestrator with pluggable modules.** Here's why:

- Multiple independent bots = multiple cron entries, multiple failure points, multiple memory systems, coordination overhead
- One orchestrator with clear module boundaries = one cron entry, one log stream, one memory system, predictable execution order

### What Should Be What

| Component | Implementation | Why |
|---|---|---|
| **Orchestrator** | daily/weekly/monthly-pipeline.sh | Shell scripts calling modules in order |
| **Skills** | SKILL.md files | Prompt templates consumed by skill-runner.sh |
| **Policies** | JSON files in policies/ | Read by approval scripts, not by Ollama |
| **Memory** | Markdown files in memory/ | Written by memory-write.sh, read by skill context |
| **Modules** | Groups of scripts sharing a purpose | Intake, intelligence, production, approval, distribution, reporting |
| **External services** | SocialFlow, Ollama, Discord webhook | Called via HTTP, failure-tolerant |
| **Cron** | macOS `launchd` plist or crontab | Runs daily-pipeline.sh every morning |

### What Should Stay Inside vs. External

| Inside OpenClaw (file-based) | External (API/service) |
|---|---|
| All content generation | Ollama (model inference) |
| All approval logic | SocialFlow (browser-based posting) |
| All memory/reporting | Discord (webhook posting) |
| All queue management | Email platforms (MailerLite/Brevo API) |
| All policy enforcement | GitHub API (repo scanning — V2) |
| All scheduling | Buffer/Typefully (social scheduling — V2) |

### Draft → Publish Separation

```
DRAFT ZONE (safe, reversible)          PUBLISH ZONE (irreversible, gated)
─────────────────────────              ──────────────────────────────────
MarketingToolData/*                    SocialFlow → actual platform post
OpenClawData/queues/*/                 Discord webhook → actual message
OpenClawData/approvals/pending/        Email API → actual send
OpenClawData/approvals/review/

Everything in the draft zone can be edited, deleted, or held indefinitely.
Moving to publish zone requires passing through approval-engine.sh.
```

### Idea → Promotion Flow

```
1. IDEA        — You drop a note in source-notes/ or source-links/
2. INTAKE      — intake-processor.sh classifies it
3. PRODUCE     — content-agent.sh creates channel-specific drafts
4. VERIFY      — approval-engine.sh scores it
5. APPROVE     — L1/L2 auto, L3 you review, L4 blocked
6. QUEUE       — distribution-engine.sh moves to channel queues
7. PUBLISH     — SocialFlow or manual post from queue
8. REPORT      — generate-report.sh logs what happened
9. MEMORY      — memory-write.sh saves what worked
```

For the **Builder Intelligence** flow (new):
```
1. SCAN        — repo-scanner reads your GitHub repos and websites
2. INVENTORY   — catalogs tools, features, endpoints, docs
3. GAP FIND    — identifies what's missing (MCP adapters, docs, connectors, utilities)
4. SCORE       — ranks opportunities by impact vs. effort
5. PROPOSE     — generates a spec/brief for the top opportunities
6. PLAN        — task-planner creates build steps
7. (BUILD)     — you or the coding model builds it
8. QA          — qa-checklist verifies it works
9. DOC         — docs are drafted
10. PROMOTE    — content pipeline generates launch content
```

---

## 7. CMO + BUILDER BOT UNIFIED DESIGN

### The Key Insight

The CMO pipeline and the Builder Intelligence pipeline share the same structure:

| Stage | CMO Pipeline | Builder Pipeline |
|---|---|---|
| Input | AI news links, product notes, ideas | Repo scans, site audits, gap analysis |
| Classify | Content type (update, news, social, newsletter) | Opportunity type (MCP, connector, tool, doc, feature) |
| Produce | Website posts, social posts, newsletters | Specs, proposals, build plans, doc drafts |
| Approve | Risk score, brand voice, dedup | Feasibility score, priority score, effort estimate |
| Distribute | Channel queues, SocialFlow, Discord | Task boards, GitHub issues, build backlogs |
| Report | What was posted, what was blocked | What was proposed, what was approved, what was built |

### Unified Architecture

Instead of two separate systems, use the **same pipeline** with two intake paths:

```
PATH A: CMO INTAKE                    PATH B: BUILDER INTAKE
──────────────────                    ─────────────────────
source-notes/                          repo scans
source-links/                          site audits
product-updates/                       market gap analysis
AI news links                          community requests
        │                                      │
        └──────────────┬───────────────────────┘
                       │
                       ▼
              UNIFIED PIPELINE
              (classify → produce → approve → distribute → report)
```

The SKILL.md templates handle both:
- `content-strategy` → for CMO content
- `repo-review` + new `ecosystem-scanner` → for builder intelligence
- `opportunity-miner` → already exists, just needs repo/site data as input
- `creative-brief-generator` → for launch/promotion content
- `task-planner` → for build task planning

### What New Skills Are Needed for Builder Intelligence

| Skill | Purpose | Model |
|---|---|---|
| `ecosystem-scanner` | Scan repos + sites, catalog features | qwen2.5-coder:7b |
| `gap-analyzer` | Compare inventory vs. market needs | qwen3:8b |
| `tool-scorer` | Rank opportunities by impact/effort | qwen3:8b |
| `spec-writer` | Generate build specs/proposals | qwen3:8b |
| `doc-planner` | Plan documentation for new tools | qwen3:8b |
| `release-planner` | Plan release notes + launch sequence | qwen3:8b |

These are 6 new SKILL.md files + 2-3 new scripts. Not a major expansion.

---

## 8. RISKS, CONSTRAINTS, AND GUARDRAILS

### Security Risks

| Risk | Severity | Guardrail |
|---|---|---|
| Ollama hallucinates false claims | HIGH | Factuality check in approval pipeline + evidence requirement |
| Auto-posting embarrassing content | HIGH | L2/L3 approval gates + rate limits |
| Credential exposure | MEDIUM | credential-safety-policy + no passwords in scripts + env vars |
| SocialFlow browser automation detected | MEDIUM | Rate limits + natural posting intervals |
| External drive disconnects mid-pipeline | MEDIUM | workspace-guard.sh checks mount at start |

### Repo / Code Risks

| Risk | Severity | Guardrail |
|---|---|---|
| Bot commits bad code | HIGH | Builder bot NEVER auto-commits. It proposes, you approve. |
| Bot opens bad GitHub issues | MEDIUM | All GitHub actions go through L3 review queue |
| Bot scans private repos recklessly | LOW | Workspace guard limits to approved repo paths |

### Automation Risks

| Risk | Severity | Guardrail |
|---|---|---|
| Over-posting to platforms | HIGH | rate-limits.json per channel + daily caps |
| Duplicate content across channels | MEDIUM | duplicate-checker SKILL.md in approval pipeline |
| Spammy community behavior | HIGH | Reddit/HN/Quora are manual-first ALWAYS |
| Promoting unfinished tools | HIGH | Builder pipeline requires QA pass before promotion enters CMO pipeline |

### Reputation Risks

| Risk | Severity | Guardrail |
|---|---|---|
| Publishing about tools that don't work | CRITICAL | Builder pipeline: QA → Doc → THEN promote. Never promote before QA. |
| Tone-deaf AI commentary | HIGH | Brand voice scoring in approval engine |
| False competitor claims | HIGH | L4 block for unverifiable competitor statements |

### Recommended Hard Rules

1. **Never auto-post to Reddit, HN, Quora, or Product Hunt** — always manual
2. **Never promote a tool before QA passes** — builder pipeline gates this
3. **Never send email to unverified lists** — email safeguards in rate-limits.json
4. **Never commit code without review** — builder bot proposes, never pushes
5. **Always log every action** — every script writes to logs/
6. **Always check external drive is mounted** — workspace-guard.sh at pipeline start

---

## 9. PHASED ROLLOUT PLAN

### Phase 0 — Audit and Cleanup (THIS PHASE)
**Purpose:** Understand what's real, fix what's broken, remove what's misleading.
**Status:** This document IS Phase 0.

**Actions needed:**
- Wire policy JSON files into approval-engine.sh (currently it may use Ollama-only scoring)
- Test daily-pipeline.sh end-to-end with real source material
- Configure Discord webhook
- Set up cron job for daily pipeline
- Clean up any duplicate/overlapping skills

**Proof of completion:** daily-pipeline.sh runs from cron, processes 2-3 source notes, produces content, scores it, queues it, writes a report — with no manual intervention.

### Phase 1 — Structure and Modularization
**Purpose:** Organize scripts into clear module groups, standardize interfaces.

**Modules:**
| Module | Scripts |
|---|---|
| Intake | intake-processor.sh, newsroom-agent.sh, product-update-agent.sh |
| Production | content-agent.sh, skill-runner.sh |
| Approval | approval-engine.sh |
| Distribution | distribution-engine.sh, socialflow-publisher.sh |
| Reporting | generate-report.sh, reporting-engine-v2.sh |
| Memory | memory-write.sh |
| Infrastructure | workspace-guard.sh, model-router.sh, verify-evidence.sh, task-plan.sh |

**Expected output:** Each module has a clear README, standardized input/output format, and consistent logging.

**Must prove before moving on:** All modules work independently AND together via daily-pipeline.sh.

### Phase 2 — Intelligence and Discovery (Builder Bot begins)
**Purpose:** Add repo/site scanning capability to the system.

**New scripts:**
- `ecosystem-scan.sh` — scan specified repos and websites
- `gap-analysis.sh` — identify missing tools/features/docs

**New SKILL.md files:**
- ecosystem-scanner, gap-analyzer, tool-scorer

**Dependencies:** Phase 1 complete. Pipeline stable.

**Expected output:** Weekly automated scan of your repos/sites → gap report → opportunity list.

**Must prove:** The scanner finds real gaps (not hallucinated ones) and the opportunity list is actionable.

### Phase 3 — Planning and Proposal Automation
**Purpose:** Turn discovered opportunities into structured proposals.

**New scripts:**
- `proposal-generator.sh` — create build specs from scored opportunities
- `roadmap-updater.sh` — maintain a living roadmap file

**New SKILL.md files:**
- spec-writer, release-planner

**Dependencies:** Phase 2 working. Gap analysis producing real results.

**Expected output:** For each high-scoring opportunity: a spec document with scope, effort estimate, build steps, and success criteria.

**Must prove:** At least 2 proposals that you'd actually want to build.

### Phase 4 — QA / Docs / Release Planning
**Purpose:** Close the loop from "built" to "documented and releasable."

**New scripts:**
- `qa-runner.sh` — run through QA checklist for a tool/feature
- `doc-generator.sh` — generate documentation drafts

**SKILL.md files:** qa-checklist (exists), doc-planner (new)

**Dependencies:** Phase 3 complete. At least 1 tool actually built from a proposal.

**Expected output:** QA report + doc draft for each completed tool.

**Must prove:** A tool goes from proposal → build → QA → docs without falling through cracks.

### Phase 5 — Community / Promotion Workflows
**Purpose:** Connect builder output to CMO pipeline for launch content.

**Integration:** When a tool passes QA + has docs → auto-trigger:
- Website update (product release post)
- Social posts (LinkedIn, X, Discord)
- Newsletter snippet
- Community announcement

**This is where the CMO + Builder pipelines unify.**

**Dependencies:** Phase 4 complete. CMO pipeline running daily from Phase 0/1.

**Expected output:** A new tool release automatically generates 5-8 content pieces across channels.

**Must prove:** One real tool launch flows through the entire system: scan → propose → build → QA → docs → promote.

### Phase 6 — Controlled Autonomy
**Purpose:** Increase automation confidence. Reduce manual touchpoints.

**Actions:**
- Move more content from L2 (score-gated) to L1 (auto-approve) based on track record
- Add feedback loops (memory-write.sh saves what performed well)
- Add scheduling tool integration (Buffer/Typefully for social)
- Add email platform API integration (MailerLite/Brevo)
- Consider GitHub Actions for repo-triggered scans

**Dependencies:** Phases 0-5 stable for at least 2-4 weeks.

**Must prove:** 2+ weeks of daily pipeline runs with < 5% bad content making it through approval.

---

## 10. FINAL RECOMMENDATION

### What Structure to Adopt

**One orchestrator (daily/weekly/monthly pipeline scripts) calling modular script groups, powered by Ollama through SKILL.md templates, with SocialFlow as the posting bridge.**

This is NOT an enterprise microservice architecture. It's a **file-based, shell-orchestrated, AI-powered content and builder operations system**. That's the honest description, and it's the right architecture for a solo builder.

### What to Preserve from Current Setup

| Preserve | Reason |
|---|---|
| All 18 shell scripts | Real logic, well-structured, covers the full pipeline |
| All 60 SKILL.md templates | Good prompt engineering, consistent format |
| 4 JSON policy files | Well-designed safety rules |
| SocialFlow app + bridge | Real posting capability, just needs activation |
| Folder structure | Comprehensive and logical |
| Ollama setup with both models | Working and tested |

### What to Change

| Change | Why |
|---|---|
| Wire JSON policies into approval-engine.sh | Currently may rely on Ollama-only scoring instead of reading thresholds from policy files |
| Consolidate overlapping skills | `reporting` vs `daily-briefing` vs `content-performance-tracker` have fuzzy boundaries |
| Add proper cron setup | Nothing runs automatically yet — this is the #1 gap |
| Run full pipeline end-to-end | Proves everything works together, not just individually |
| Expand memory system | 2 files is not enough — should auto-capture brand decisions, content performance, lessons |

### What to Postpone

| Postpone | Why |
|---|---|
| Direct platform API integrations (LinkedIn API, X API, Meta API) | Complex OAuth, rate limits, TOS risk. Use queue/export + scheduling tools first |
| GitHub Actions integration | Adds infra complexity. Use local cron first |
| Multiple email platform integrations | Start with one (MailerLite or Substack), not four |
| Full Builder Intelligence module | Get CMO pipeline running daily first (Phase 0/1), then add scanner |
| Concurrent multi-agent execution | Sequential pipeline is simpler and sufficient for a solo builder |

### Architecture Decision: Stay Inside or Go External?

**Stay inside OpenClaw (file-based + shell + Ollama) for V1.**

External services should be bridges (SocialFlow, Discord webhook, future APIs), not the core. The core logic — intake, production, approval, distribution, reporting, memory — should remain local, file-based, and under your control.

**When to consider going external:**
- When daily pipeline needs to run even when your Mac is off → move to a VPS or GitHub Actions
- When you need real-time triggers (not cron) → add webhook listeners
- When content volume exceeds what a solo builder reviews → add a web dashboard

**Not yet. Get V1 running daily from cron first.**

### The Single Most Important Next Step

**Run `daily-pipeline.sh` end-to-end with 3 real source notes, verify it produces content, scores it, queues it, and writes a report. Then set it up as a cron job.**

Everything else builds on top of a working daily cycle.
