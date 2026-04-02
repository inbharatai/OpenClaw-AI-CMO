# InBharat Operator Bot — Implementation Inventory
**Date:** 2026-03-26 | **Purpose:** Compact decision table for every component

---

## INFRASTRUCTURE

| Component | Current Role | Future Bot Role | Status | Keep? | Safe to Modify? | Priority | Dependency | Notes |
|---|---|---|---|---|---|---|---|---|
| Ollama (qwen3:8b) | Marketing/writing LLM | Content Brain + Community Rewriter + Revenue Drafter | ✅ Running | YES | NO | — | Mac awake, external drive | Do not touch model config |
| Ollama (qwen2.5-coder:7b) | Code/automation LLM | Builder Engine + Task Executor + Script Generator | ✅ Running | YES | NO | — | Mac awake, external drive | Do not touch model config |
| OpenClaw gateway | Agent orchestrator | Central operator runtime | ✅ Running | YES | Config only | — | Node, LaunchAgent | Only modify openclaw.json for new features |
| Agent: main | General assistant | HQ Coordinator | ✅ Working | YES | Config only | — | Gateway | Do not change model or workspace |
| Agent: builder | Coding agent via WhatsApp | Builder Engine + Task Executor | ✅ Working | YES | Config only | — | Gateway, WhatsApp | Route stays: whatsapp→builder |
| WhatsApp | Owner-only command channel | Operator control surface | ✅ Working | YES | NO | — | Gateway, credentials | Allowlist: +919015823397 ONLY |
| Caffeinate | Keep Mac awake | Same | ✅ Running | YES | NO | — | LaunchAgent | Auto-restarts on reboot |
| Git repo | Version control | Same | ✅ Pushed | YES | Add files only | — | GitHub remote | Never force-push |

## PIPELINE SCRIPTS — CONTENT BRAIN

| Component | Current Role | Future Bot Role | Status | Keep? | Safe to Modify? | Priority | Dependency | Notes |
|---|---|---|---|---|---|---|---|---|
| `daily-pipeline.sh` (148L) | Orchestrate daily cycle | Content Brain daily coordinator | ✅ Proven | YES | Extend only | A | Cron, Ollama, all stage scripts | Add community + revenue stages later |
| `intake-processor.sh` (161L) | Classify source material | Content Brain intake | ✅ Proven | YES | Extend only | A | Source notes in MarketingToolData | Add content-lane classification later |
| `content-agent.sh` (255L) | Generate content via Ollama | Asset Builder core | ✅ Proven | YES | Extend only | A | Ollama, model-router | Add --lang param for multilingual |
| `model-router.sh` (64L) | Route to correct model | Content Brain router | ✅ Working | YES | NO | — | Ollama | Simple and correct, leave alone |
| `newsroom-agent.sh` (111L) | AI news collection | Content Brain news intake | ⚠️ Untested solo | YES | Test first | B | Ollama | Test standalone before relying on it |
| `product-update-agent.sh` (133L) | Product change tracking | Content Brain product intake | ⚠️ Untested solo | YES | Test first | B | Ollama | Test standalone before relying on it |
| `task-plan.sh` (104L) | Break goals into tasks | Builder Engine planner | ✅ Working | YES | Extend later | E | Ollama | Base for task-builder.sh |

## PIPELINE SCRIPTS — APPROVAL & SAFETY

| Component | Current Role | Future Bot Role | Status | Keep? | Safe to Modify? | Priority | Dependency | Notes |
|---|---|---|---|---|---|---|---|---|
| `approval-engine.sh` (241L) | Score + gate content | Approval Gate (content + actions) | ✅ Fixed & proven | YES | Extend only | A | Policies, Ollama | Add community-policy + revenue-action scoring later |
| `verify-evidence.sh` (125L) | Check outputs exist | Approval Gate evidence checker | ✅ Working | YES | NO | — | Filesystem | Simple and correct |
| `workspace-guard.sh` (53L) | Path safety | Safety layer | ✅ Working | YES | NO | — | None | Never modify |
| 4 policy JSONs | Approval/voice/channel/rate rules | Expanded policy engine | ✅ Working | YES | Add new policies | B | — | Add community-policy.json, revenue-policy.json later |

## PIPELINE SCRIPTS — DELIVERY & DISTRIBUTION

| Component | Current Role | Future Bot Role | Status | Keep? | Safe to Modify? | Priority | Dependency | Notes |
|---|---|---|---|---|---|---|---|---|
| `distribution-engine.sh` (281L) | Route to queue folders + Discord webhook code | Broadcaster core | ✅ Has real code | YES | Configure | A-B | Discord webhook URL, policies | Webhook code exists, just needs URL |
| `socialflow-publisher.sh` (121L) | Post to SocialFlow | DEPRECATED | ⚠️ Bypassed | Keep file | Mark deprecated | — | — | Add # DEPRECATED header, do not delete |
| 11 queue directories | Channel routing folders | Broadcaster queues | ✅ Ready (empty) | YES | Populate | A | Pipeline output | Will fill when delivery is live |

## PIPELINE SCRIPTS — REPORTING & MEMORY

| Component | Current Role | Future Bot Role | Status | Keep? | Safe to Modify? | Priority | Dependency | Notes |
|---|---|---|---|---|---|---|---|---|
| `generate-report.sh` (109L) | Daily summary | Analyst daily report | ✅ Working | YES | Extend later | B | Pipeline output | Add engagement metrics later |
| `reporting-engine-v2.sh` (252L) | Enhanced reporting | Analyst (unclear) | ⚠️ Unclear | YES | Clarify first | B | — | Determine if it replaces v1 or coexists |
| `memory-write.sh` (74L) | Persist learnings | Identity/Brand Memory | ✅ Working | YES | NO | — | Filesystem | Simple and correct |
| `skill-runner.sh` (102L) | Feed SKILL.md to Ollama | Asset Builder tool | ✅ Working | YES | NO | — | Ollama, skills/ | Simple and correct |
| `weekly-pipeline.sh` (135L) | Weekly batch | Content Brain weekly | ⚠️ Untested | YES | Test first | A | Cron | Must verify in first 3-day cron run |
| `monthly-pipeline.sh` (141L) | Monthly review | Analyst monthly | ⚠️ Untested | YES | Test first | A | Cron | Must verify in first month-end run |

## INBHARAT BOT

| Component | Current Role | Future Bot Role | Status | Keep? | Safe to Modify? | Priority | Dependency | Notes |
|---|---|---|---|---|---|---|---|---|
| `inbharat-run.sh` (71L) | Bot orchestrator | Builder Engine + Community Scout orchestrator | ✅ Proven | YES | Extend later | E | All bot modules | Add community + revenue stages later |
| `ecosystem-scanner.sh` (155L) | Inventory workspace/repos | Builder Engine scanner | ✅ Proven | YES | Extend later | E | gh CLI, filesystem | Add website scanning later |
| `gap-finder.sh` (81L) | Find gaps via Ollama | Builder Engine analyzer | ✅ Proven | YES | NO | E | Ollama, scanner output | Works well |
| `proposal-generator.sh` (88L) | Generate build proposals | Builder Engine proposer | ✅ Proven | YES | NO | E | Ollama, findings | Works well |
| `cmo-bridge.sh` (96L) | Convert proposals to content | Content Brain ↔ Builder bridge | ✅ Proven | YES | NO | E | Ollama, proposals | Works well |
| `generate-state.sh` (113L) | Dashboard JSON + markdown | Analyst dashboard | ✅ Proven | YES | Extend later | E | All bot outputs | Add community + revenue state later |
| `approval-gate.sh` (76L) | Bot action classification | Approval Gate (bot actions) | ✅ Proven | YES | NO | — | Policies | 5-level gate, works well |
| `bot-logger.sh` (31L) | Timestamped logging | Analyst logging | ✅ Proven | YES | NO | — | Filesystem | Simple and correct |

## PROMPT TEMPLATES (64 SKILL.md files)

| Component | Current Role | Future Bot Role | Status | Keep? | Safe to Modify? | Priority | Dependency | Notes |
|---|---|---|---|---|---|---|---|---|
| 13 asset-creation skills | Content variant templates | Asset Builder templates | ✅ Advisory | YES | Add new ones | B | skill-runner.sh | Add community-rewrite, revenue-reply templates later |
| 7 distribution skills | Channel guidance | Broadcaster guidance | ✅ Advisory | YES | NO | — | — | Channel policies JSON is the real enforcement |
| 8 approval/safety skills | Safety guidance | Approval Gate guidance | ✅ Advisory | YES | NO | — | — | Real enforcement is approval-engine.sh |
| 6 research/growth skills | Growth guidance | Community Scout + Revenue templates | ✅ Advisory | YES | Add new ones | C-D | — | Add community-map, lead-qualify templates |
| 6 foundation skills | System ops guidance | Operator foundation | ✅ Advisory | YES | NO | — | — | Workspace guard, router, memory, etc. |
| 14 content/editorial skills | Writing guidance | Content Brain templates | ✅ Advisory | YES | NO | — | — | Already comprehensive |
| 10 other skills | Various | Various | ✅ Advisory | YES | NO | — | — | Low priority to modify |

## DATA STRUCTURES

| Component | Current Role | Future Bot Role | Status | Keep? | Safe to Modify? | Priority | Dependency | Notes |
|---|---|---|---|---|---|---|---|---|
| `OpenClawData/approvals/` | 4-state approval storage | Same + action approvals | ✅ Clean (post-fix) | YES | Add states later | — | approval-engine.sh | 4 approved, 8 blocked, 4 review |
| `OpenClawData/queues/` (11 dirs) | Channel queues | Broadcaster queues | ✅ Ready (empty) | YES | Populate | A | distribution-engine.sh | Will fill when delivery is live |
| `OpenClawData/reports/daily/` | Daily summaries | Analyst reports | ✅ 4 reports | YES | Add types later | — | generate-report.sh | Add weekly/monthly/engagement |
| `OpenClawData/memory/` | Pipeline learnings | Identity/Brand Memory | ✅ 11 files | YES | Add structure later | — | memory-write.sh | Add brand-knowledge-base later |
| `OpenClawData/policies/` | 4 rule files | Expanded policy engine | ✅ Working | YES | Add new policies | C | approval-engine.sh | Add community + revenue policies |
| `OpenClawData/inbharat-bot/` | Bot modules + state | Builder Engine home | ✅ Working | YES | Extend | E | inbharat-run.sh | Add community + revenue modules |
| `MarketingToolData/` (29 subdirs) | Source + output storage | Asset Builder storage | ✅ Structured | YES | Populate | A | Pipeline | Feeds into intake-processor |
| `OpenClawData/logs/` | Execution logs | Analyst logs | ✅ Real | YES | NO | — | All scripts | Never delete logs |
| `OpenClawData/sessions/` | Session state | Session state | ✅ Exists | YES | NO | — | — | Low usage currently |
| `OpenClawData/prompts/` | Prompt storage | Prompt storage | ✅ Exists | YES | NO | — | — | Low usage currently |

## ROOT CLUTTER (from remote repo template)

| Component | Current Role | Future Bot Role | Status | Keep? | Safe to Modify? | Priority | Dependency | Notes |
|---|---|---|---|---|---|---|---|---|
| `/approvals/` | Duplicate of OpenClawData/approvals/ | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/configs/` | Duplicate | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/data/` | Duplicate | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/docs/` | Duplicate | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/exports/` | Duplicate | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/logs/` | Duplicate | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/queues/` | Duplicate | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/reports/` | Duplicate | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/tests/` | Duplicate | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/openclaw-engine/` | From template | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/socialflow/` | From template | None | ❌ Confusing | Move to _archive/ | YES | A | None | From GitHub template |
| `/OpenClaw-local-backup/` | Old clone | None | ❌ Dead weight | Move to _archive/ | YES | A | None | Pre-merge backup |
| `/SocialFlow-local-backup/` | Old backup | None | ❌ Dead weight | Move to _archive/ | YES | A | None | Pre-merge backup |

## MISSING — NOT YET BUILT

| Component | Current Role | Future Bot Role | Status | Keep? | Safe to Modify? | Priority | Dependency | Notes |
|---|---|---|---|---|---|---|---|---|
| `community-scout.sh` | — | Community Scout | ❌ Missing | Build new | — | C | Ollama, community/maps/ | Research communities → create profiles |
| `community-rewriter.sh` | — | Community Operator | ❌ Missing | Build new | — | C | Ollama, community profiles | Rewrite content for community tone |
| `community-operator.sh` | — | Community Operator | ❌ Missing | Build new | — | C | Scout + Rewriter | Decide: post/comment/discuss/observe |
| `lead-capture.sh` | — | Revenue Engine | ❌ Missing | Build new | — | D | Gmail/inbox access | Scan for opportunities |
| `proposal-builder.sh` | — | Revenue Engine | ❌ Missing | Build new | — | D | lead-capture, Ollama | Draft proposals from templates |
| `revenue-engine.sh` | — | Revenue Engine | ❌ Missing | Build new | — | D | leads, proposals | Orchestrate revenue pipeline |
| `engagement-tracker.sh` | — | Analyst | ❌ Missing | Build new | — | D | Manual input initially | Track what worked |
| `task-builder.sh` | — | Builder Engine | ❌ Missing | Build new | — | E | task-plan.sh (base) | Auto-create + execute safe tasks |
| `multilingual-adapter.sh` | — | Multilingual Layer | ❌ Missing | Build new | — | F | Ollama, content-agent | Add --lang param |
| `budget-governor.sh` | — | Budget Governor | ❌ Missing | Build new | — | F | Spend tracking | All local = $0 currently |
| `community/` data dirs | — | Community Intelligence | ❌ Missing | Create | — | C | — | maps/, scores/, rules/, history/ |
| `revenue/` data dirs | — | Revenue Engine | ❌ Missing | Create | — | D | — | leads/, proposals/, opportunities/ |
| `engagement/` data dir | — | Analyst | ❌ Missing | Create | — | D | — | Outcome tracking |
| `budget/` data dir | — | Budget Governor | ❌ Missing | Create | — | F | — | Spend logs |
| `community-policy.json` | — | Community Operator | ❌ Missing | Create | — | C | — | Per-community rules |
| `revenue-policy.json` | — | Revenue Engine | ❌ Missing | Create | — | D | — | Auto vs review actions |

---

## Minimum Safe Implementation Actions I Can Do Now Without Breaking the Current Working System

These are **zero-risk or near-zero-risk** actions that improve the system without touching any working script, config, or pipeline.

### TIER 1 — Do right now (0 risk, 0 dependencies)

| # | Action | What Changes | What It Improves | Risk |
|---|---|---|---|---|
| 1 | Move 13 duplicate root dirs to `_archive/` | Folder organization only | Eliminates confusion between real and template dirs | **Zero** — no script references these |
| 2 | Add `# DEPRECATED` to `socialflow-publisher.sh` line 1 | 1 comment line | Prevents anyone from thinking SocialFlow is active | **Zero** |
| 3 | Create `OpenClawData/community/{maps,scores,rules,history,drafts}/` | Empty folders | Ready for community intelligence work | **Zero** — additive |
| 4 | Create `OpenClawData/revenue/{leads,proposals,opportunities,followups}/` | Empty folders | Ready for revenue engine work | **Zero** — additive |
| 5 | Create `OpenClawData/engagement/` | Empty folder | Ready for analytics work | **Zero** — additive |

### TIER 2 — Do when owner provides input (low risk)

| # | Action | What Changes | What It Improves | Risk | Owner Input Needed |
|---|---|---|---|---|---|
| 6 | Configure Discord webhook in `distribution-engine.sh` | 1 JSON config file | First real external delivery | **Low** | Discord webhook URL |
| 7 | Restore cron from backup | crontab restored | Pipeline runs unattended | **Low** | Owner says "go" |
| 8 | Drop 2 source notes into `MarketingToolData/source-notes/` | 2 new files | Tomorrow's pipeline has input | **Zero** | Owner provides content |

### TIER 3 — Do after first unattended cron run succeeds (low risk)

| # | Action | What Changes | What It Improves | Risk | Prereq |
|---|---|---|---|---|---|
| 9 | Build `community-scout.sh` | New script (no existing code touched) | Community Intelligence foundation | **Zero** — additive | Community folders exist (Tier 1 #3) |
| 10 | Build `community-rewriter.sh` | New script | Community-safe content variants | **Zero** — additive | Scout exists |
| 11 | Hand-map 10 subreddits into `community/maps/` | 10 JSON files | First community profiles | **Zero** — additive | Research time |
| 12 | Build `lead-capture.sh` | New script | Revenue foundation | **Zero** — additive | Gmail read access |
| 13 | Connect Gmail read-only for inbox scanning | MCP or API config | Opportunity detection | **Low** | Gmail MCP already available |

### ABSOLUTE DO-NOT-TOUCH LIST

| Component | Why |
|---|---|
| Any of the 18 CMO scripts | Proven pipeline — modify only by extending |
| Any of the 8 InBharat Bot scripts | Proven cycle — modify only by extending |
| `~/.openclaw/openclaw.json` | Agent config — modify only for new features |
| `OpenClawData/approvals/` | Clean post-fix data |
| `OpenClawData/policies/*.json` | Working rules — only add new files |
| WhatsApp allowlist | Security boundary |
| Git remote | Never force-push |

---

*Execute Tier 1 immediately. Tier 2 when owner provides Discord webhook + says "go". Tier 3 after first successful unattended cron run.*
