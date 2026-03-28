# Phase 0 + Phase 1 Execution Plan
## Validation & Modular Restructuring
### Date: 2026-03-25

---

## 1. EXECUTIVE SUMMARY

The system is closer to working than it appears, but has one critical bug and several structural issues that must be fixed before anything else.

**Critical finding from the audit:** The approval engine's credential-safety check is **blocking safe content**. In test runs, the LLM returned `"safe": true` and `"action": "pass"`, but the grep pattern checking for the word "safe" in the response triggered a false positive block. This means the approval engine has a parsing bug that blocks almost everything that goes through L2+ scoring, even when the content is clean.

Meanwhile, L1 auto-approve (type-based bypass) works correctly — 24 items were properly auto-approved for discord/linkedin/x/website channels.

**Bottom line:** Fix the approval engine parsing, run one clean end-to-end daily pipeline, set up cron. That's Phase 0. Then modularize for Phase 1.

---

## 2. CURRENT SYSTEM INVENTORY

### Shell Scripts (18 total)

| Script | Lines | Status | Depends On | Called By |
|---|---|---|---|---|
| **daily-pipeline.sh** | 148 | ACTIVE, important | All stage scripts | Cron (not yet configured) |
| **weekly-pipeline.sh** | 135 | ACTIVE, important | skill-runner, approval-engine | Cron (not yet configured) |
| **monthly-pipeline.sh** | 141 | ACTIVE, important | skill-runner | Cron (not yet configured) |
| **intake-processor.sh** | 161 | ACTIVE, important | skill-runner (content-classifier) | daily-pipeline.sh Stage 1 |
| **newsroom-agent.sh** | 119 | ACTIVE, important | skill-runner | daily-pipeline.sh Stage 2a |
| **product-update-agent.sh** | 140 | ACTIVE, important | skill-runner | daily-pipeline.sh Stage 2b |
| **content-agent.sh** | 255 | ACTIVE, important | skill-runner, Python3 (JSON parsing) | daily-pipeline.sh Stage 2c |
| **approval-engine.sh** | 231 | ACTIVE, **HAS BUG** | skill-runner (credential-safety, risk-scorer) | daily-pipeline.sh Stage 3 |
| **distribution-engine.sh** | 274 | ACTIVE, important | socialflow-publisher, policies/ | daily-pipeline.sh Stage 4 |
| **reporting-engine-v2.sh** | 252 | ACTIVE, important | Log files | daily-pipeline.sh Stage 5 |
| **skill-runner.sh** | 102 | ACTIVE, important | model-router, Ollama API | All content scripts |
| **model-router.sh** | 64 | ACTIVE, important | — | skill-runner.sh |
| **workspace-guard.sh** | 53 | ACTIVE, important | — | memory-write.sh |
| **memory-write.sh** | 74 | ACTIVE, underused | workspace-guard | Manual / future auto |
| **generate-report.sh** | 109 | ACTIVE but messy | — | Manual |
| **verify-evidence.sh** | 125 | ACTIVE, important | — | Manual / future auto |
| **task-plan.sh** | 104 | ACTIVE, important | Ollama API | Manual |
| **socialflow-publisher.sh** | 121 | PARTIAL | SocialFlow API | distribution-engine.sh |

### SKILL.md Files (60 total)

All 60 are real prompt templates with YAML frontmatter. Sizes range from 44-107 lines.

| Category | Count | Status |
|---|---|---|
| Foundation | 6 | ACTIVE — consumed by skill-runner.sh |
| Content/Editorial | 15 | ACTIVE — consumed by content-agent.sh |
| Approval/Safety | 8 | ACTIVE — consumed by approval-engine.sh |
| Distribution | 8 | ACTIVE — consumed by distribution-engine.sh |
| Research/Growth | 6 | ACTIVE — consumed by newsroom-agent.sh, monthly-pipeline.sh |
| Meta/Tracking | 4 | ACTIVE — consumed by various scripts |
| Coding/Automation | 11 | ACTIVE — consumed by skill-runner.sh directly |
| Session Compaction | 1 | PARTIAL — not wired into any pipeline script |
| Landing Page Upgrade | 1 | PARTIAL — not wired into pipeline |

**Duplicates / fuzzy overlaps to address:**
- `reporting` vs `daily-briefing` vs `content-performance-tracker` — three skills covering similar ground
- `channel-exporter` vs `channel-adapter` vs `social-queue-packager` — three skills for adapting content to channels
- `human-in-the-loop-approval` vs `approval-policy` — overlapping approval concepts

### Policy Files (4 JSON configs)

| File | Status | Consumed By |
|---|---|---|
| approval-rules.json | ACTIVE but **not fully wired** | approval-engine.sh reads L1 types hardcoded, not from JSON |
| rate-limits.json | ACTIVE but **not fully wired** | distribution-engine.sh uses hardcoded global cap of 15, not JSON |
| brand-voice-rules.json | EXISTS, **not consumed** | No script reads this yet |
| channel-policies.json | EXISTS, **not consumed** | No script reads this yet |

### SocialFlow Integration

| Component | Status |
|---|---|
| FastAPI backend (main.py) | EXISTS, real code |
| OpenClaw bridge API | EXISTS, real endpoints |
| Browser automation modules | EXISTS (LinkedIn, X, Instagram) |
| SQLite database | EXISTS |
| socialflow-publisher.sh | EXISTS, calls SocialFlow API |
| Actual live post to any platform | **NEVER DONE** |

### Content State (from test runs on 2026-03-23)

| Location | File Count | Status |
|---|---|---|
| MarketingToolData/source-notes/ | 10 | Real test inputs |
| MarketingToolData/source-links/ | 6 | Real test inputs |
| MarketingToolData/product-updates/ | 7 | Real test inputs |
| MarketingToolData/website-posts/ | 10 | Generated outputs |
| MarketingToolData/ai-news/ | 3 | Generated outputs |
| MarketingToolData/linkedin/ | 8 | Generated outputs |
| MarketingToolData/discord/ | 9 | Generated outputs |
| MarketingToolData/x/ | 3 | Generated outputs |
| OpenClawData/approvals/approved/ | 1 (log file with 24 entries) | L1 auto-approve working |
| OpenClawData/approvals/blocked/ | ~28 files | **Most are false positives from credential check bug** |
| OpenClawData/approvals/review/ | 1 file + log | L3 review queue working |
| OpenClawData/queues/*/pending/ | 0 | Empty — content was moved by approval engine |
| OpenClawData/queues/*/approved/ | 0 | Empty — distribution never ran on approved files |
| OpenClawData/reports/daily/ | 1 | Working |
| OpenClawData/logs/ | 19 | All scripts log properly |
| OpenClawData/memory/ | 2 | Barely used |

---

## 3. END-TO-END PROOF PLAN

### The Test Sequence

```
Step 1: DROP — Put 3 real source files into intake folders
Step 2: INTAKE — Run intake-processor.sh, verify .meta.json classification
Step 3: PRODUCE — Run content-agent.sh, verify content files + queue/pending/ population
Step 4: APPROVE — Run approval-engine.sh (AFTER fixing the credential check bug), verify correct L1/L2/L3/L4 routing
Step 5: DISTRIBUTE — Run distribution-engine.sh, verify files move to approved → exported
Step 6: REPORT — Run reporting-engine-v2.sh, verify daily report generated
Step 7: FULL — Run daily-pipeline.sh end-to-end, verify all stages chain correctly
Step 8: CRON — Set up launchd plist, verify it fires at scheduled time
```

### Per-Stage Validation

#### Step 1: DROP (Manual)
- **Action:** Place 3 markdown files:
  1. `MarketingToolData/source-notes/phase0-test-feature-launch.md` — a product update note
  2. `MarketingToolData/source-links/phase0-test-ai-news.md` — an AI news link
  3. `MarketingToolData/source-notes/phase0-test-build-log.md` — a founder build log
- **Success:** Files exist and are readable
- **Fail condition:** None (this is manual)

#### Step 2: INTAKE
- **Script:** `intake-processor.sh`
- **Input:** The 3 source files above
- **Expected output:** 3 `.meta.json` files alongside the sources, each with `status: classified`, `content_type`, `priority`, `suggested_channels`
- **Success check:** `find MarketingToolData -name "*.meta.json" -newer <timestamp>` returns 3 files
- **Fail condition:** Ollama not running, skill-runner fails, empty classification response
- **Evidence:** Log in `OpenClawData/logs/intake-processor.log`, `.meta.json` file contents

#### Step 3: PRODUCE
- **Script:** `content-agent.sh`
- **Input:** The 3 `.meta.json` files from Step 2
- **Expected output:** At minimum 3 primary content files + 2-4 channel variants (discord, linkedin) = ~5-7 new files
- **Output locations:** `MarketingToolData/website-posts/`, `MarketingToolData/build-logs/`, `MarketingToolData/ai-news/` + `OpenClawData/queues/*/pending/`
- **Success check:** `queues/website/pending/` has at least 1 file, `queues/discord/pending/` has at least 1 file
- **Fail condition:** Ollama returns empty, skill-runner errors, Python JSON parsing fails
- **Evidence:** Log in `OpenClawData/logs/content-agent.log`, file listings

#### Step 4: APPROVE (requires bug fix first)
- **Script:** `approval-engine.sh`
- **Input:** Files in `queues/*/pending/`
- **Expected output:** Files moved to `queues/*/approved/` (for L1 types) or `approvals/review/` or `approvals/blocked/`
- **Critical test:** A product-update type file with `type: product-update` frontmatter should be L1 auto-approved, NOT blocked by credential check
- **Success check:** At least 2 files in `queues/*/approved/`, approval-log written
- **Fail condition:** The credential-check grep bug blocks everything (the exact bug found in audit)
- **Evidence:** `approval-log-<date>.md`, `block-log-<date>.md`, log file

#### Step 5: DISTRIBUTE
- **Script:** `distribution-engine.sh`
- **Input:** Files in `queues/*/approved/`
- **Expected output:** Files copied to `MarketingToolData/<channel>/` and moved to `ExportsLogs/posted/`
- **Success check:** `ExportsLogs/posted/` has new files, `posting-log.json` has new entries
- **Fail condition:** No approved files exist (Step 4 failed), SocialFlow not running (expected — should fall back to export)
- **Evidence:** `distribution-engine.log`, `posting-log.json`, file listings

#### Step 6: REPORT
- **Script:** `reporting-engine-v2.sh --type daily`
- **Input:** All logs from today's run
- **Expected output:** `reports/daily/daily-report-<date>.md`
- **Success check:** Report file exists and contains accurate counts
- **Fail condition:** Log files missing or empty
- **Evidence:** The report file itself

#### Step 7: FULL PIPELINE
- **Script:** `daily-pipeline.sh`
- **Input:** Fresh source files (different from Step 1 to avoid processed-file skip)
- **Expected:** All 5 stages run in sequence, no fatal errors, final summary shows non-zero counts
- **Success check:** Log shows all stages COMPLETE, queues show movement
- **Fail condition:** Any stage returns non-zero AND blocks subsequent stages
- **Evidence:** `daily-pipeline.log`, final summary output

#### Step 8: CRON
- **Method:** macOS `launchd` plist or `crontab -e`
- **Schedule:** Daily at 8:07 AM (off-minute to avoid collisions)
- **Success check:** Next morning, `daily-pipeline.log` shows an automated run entry
- **Fail condition:** Drive not mounted at cron time, Ollama not running

---

## 4. PROPOSED MODULAR ARCHITECTURE

### Current → Future Module Mapping

```
CURRENT (flat scripts/)              PROPOSED MODULES
─────────────────────               ──────────────────

intake-processor.sh         ──→    MODULE: intake/
newsroom-agent.sh           ──→      intake-processor.sh
product-update-agent.sh     ──→      newsroom-agent.sh
                                     product-update-agent.sh

content-agent.sh            ──→    MODULE: production/
skill-runner.sh             ──→      content-agent.sh
model-router.sh             ──→      skill-runner.sh
                                     model-router.sh

approval-engine.sh          ──→    MODULE: approval/
                                     approval-engine.sh
                                     (policies/*.json read here)

distribution-engine.sh      ──→    MODULE: distribution/
socialflow-publisher.sh     ──→      distribution-engine.sh
                                     socialflow-publisher.sh

generate-report.sh          ──→    MODULE: reporting/
reporting-engine-v2.sh      ──→      reporting-engine-v2.sh
                                     (generate-report.sh merged in)

memory-write.sh             ──→    MODULE: memory/
                                     memory-write.sh
                                     (future: memory-read.sh)

workspace-guard.sh          ──→    MODULE: infra/
verify-evidence.sh          ──→      workspace-guard.sh
task-plan.sh                ──→      verify-evidence.sh
                                     task-plan.sh

daily-pipeline.sh           ──→    MODULE: orchestrator/
weekly-pipeline.sh          ──→      daily-pipeline.sh
monthly-pipeline.sh         ──→      weekly-pipeline.sh
                                     monthly-pipeline.sh

(future)                    ──→    MODULE: intelligence/
                                     ecosystem-scan.sh
                                     gap-analysis.sh
                                     proposal-generator.sh
```

### Module Interfaces (Contracts)

Each module communicates through **files only** — no in-memory state, no sockets, no databases between modules.

| From Module | To Module | Interface |
|---|---|---|
| intake → production | `.meta.json` files in MarketingToolData source dirs |
| production → approval | `.md` files in `queues/*/pending/` |
| approval → distribution | `.md` files in `queues/*/approved/` |
| distribution → reporting | `posting-log.json` + files in `ExportsLogs/posted/` |
| all → reporting | Log files in `OpenClawData/logs/` |
| all → memory | `memory-write.sh` call or direct file write to `memory/` |
| orchestrator → all | Sequential script calls with `--dry-run` support |

### What Should Remain Separate

- **SKILL.md templates** — stay in `skills/` (not inside modules). They're a shared resource.
- **Policy JSONs** — stay in `policies/` (not inside modules). They're configuration.
- **Queue directories** — stay in `queues/` (not inside modules). They're the data flow.
- **Reports** — stay in `reports/`. They're output.

### What Should Be Consolidated

| Current | Proposed |
|---|---|
| `generate-report.sh` (109 lines) + `reporting-engine-v2.sh` (252 lines) | Merge into single `reporting-engine.sh`. The v2 is more complete; v1 can be retired. |
| `reporting` + `daily-briefing` + `content-performance-tracker` SKILL.md | Keep `reporting` and `daily-briefing`, retire `content-performance-tracker` (merge its unique parts into `reporting`) |
| `channel-exporter` + `channel-adapter` + `social-queue-packager` SKILL.md | Keep `channel-adapter` (most specific), retire the other two (their logic is already in content-agent.sh) |

---

## 5. CMO-TO-BUILDER MERGE PLAN

### What Can Be Reused Directly

| CMO Component | Reusable for Builder Intelligence? | How |
|---|---|---|
| **Intake pipeline** | Yes | Builder intake = repo scan results → same classification flow |
| **Content production** | Partially | Builder produces specs/proposals, not social posts — different SKILL.md templates but same skill-runner.sh |
| **Approval engine** | Yes | Builder proposals need feasibility scoring, same L1-L4 model |
| **Distribution** | Partially | Builder distributes to GitHub issues/task boards, not social media — different channel adapters |
| **Reporting** | Yes | Same reporting format works for both |
| **Memory** | Yes | Shared memory layer for brand rules, project context, lessons |
| **Skill runner** | Yes | Same Ollama bridge, different SKILL.md templates |
| **Model router** | Yes | Same routing logic (strategy → qwen3:8b, code → qwen2.5-coder:7b) |

### Abstractions to Introduce NOW (minimal, not overengineered)

1. **Generic intake folder convention:** Any module can drop a `.md` + `.meta.json` pair into a designated intake folder. The intake-processor already supports this — just needs to scan additional directories.

2. **Generic queue convention:** Any content type can flow through `queues/<channel>/pending/` → `approved/`. Builder proposals would use `queues/builder/pending/`.

3. **Skill category tags:** Add a `category:` field to SKILL.md frontmatter (already partially done). This lets the orchestrator query skills by category.

### What Should Remain CMO-Specific

- All 15 content/editorial SKILL.md templates
- Social channel queue folders (queues/linkedin, queues/discord, etc.)
- SocialFlow bridge integration
- Rate limiting per social channel
- Brand voice scoring

### What Should Remain Builder-Specific (future)

- Ecosystem scanner skill + script
- Gap analysis skill + script
- Spec writer skill
- `queues/builder/` for proposals
- GitHub issue creation adapter (future)

### Where Builder Proposals Should Live

```
MarketingToolData/             ← CMO content
BuilderData/                   ← NEW (Phase 1 prep, create empty)
  scans/                       ← repo/site scan results
  opportunities/               ← scored gap analysis
  proposals/                   ← spec drafts
  qa-reports/                  ← QA results for built tools
  docs-drafts/                 ← documentation drafts
```

Create this folder structure now (Phase 1). Populate it later (Phase 2+).

---

## 6. RESTRUCTURING RISKS AND SAFE ORDER

### Top Risks

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| **Breaking the approval engine while fixing the bug** | Pipeline stops working | Medium | Fix the one grep line, test in isolation first |
| **Moving scripts into module dirs breaks path references** | All cross-script calls break | High if done wrong | Do NOT move scripts yet. Phase 1 = document modules, add module headers to scripts. Phase 2 = actually move files. |
| **Deleting "duplicate" skills that are actually used** | Content generation fails | Medium | Before deleting any SKILL.md, grep all scripts for its name |
| **Cron runs when drive is disconnected** | Script errors, partial state | Medium | workspace-guard.sh already checks mount — ensure daily-pipeline.sh calls it first (it does) |
| **Consolidating report scripts loses functionality** | Missing report data | Low | Merge carefully, keep both until v2 is proven |
| **Memory writes corrupt files** | Lost context | Low | memory-write.sh appends, doesn't overwrite — safe pattern |
| **Changing approval thresholds too aggressively** | Unsafe content auto-approved | High | Start conservative (current L1 types), widen slowly with evidence |

### Safest Order of Operations

1. **Fix the approval-engine.sh credential check bug** (one line change, massive impact)
2. **Do NOT move any files or rename any scripts yet**
3. **Run the full e2e proof test** (Steps 1-7 from Section 3)
4. **Set up cron** (Step 8)
5. **Let it run for 3-5 days** with real source material
6. **THEN** add module documentation headers to each script
7. **THEN** create the BuilderData/ folder structure
8. **THEN** consolidate duplicate skills (after verifying which are actually called)
9. **THEN** wire policy JSONs into scripts (replace hardcoded values)
10. **THEN** consider moving scripts into module subdirectories

**Key principle:** Fix → Prove → Document → Then restructure. Never restructure before proving.

---

## 7. PHASE 0 DELIVERABLES

**Phase 0 = Prove the system works end-to-end.**

| # | Deliverable | Success Criteria | Evidence |
|---|---|---|---|
| 0.1 | Fix approval-engine.sh credential check bug | Safe content no longer blocked by false positive | Test run shows L2 score-gated approval working |
| 0.2 | Drop 3 real source files | Files exist in intake folders | `ls` output |
| 0.3 | intake-processor.sh produces classifications | 3 `.meta.json` files with correct types | File contents |
| 0.4 | content-agent.sh produces content | 5-7 content files across channels | Files in queues/*/pending/ |
| 0.5 | approval-engine.sh correctly routes content | At least 2 approved, at least 1 in review, 0 false-positive blocks | approval-log, block-log |
| 0.6 | distribution-engine.sh exports approved content | Files in ExportsLogs/posted/ | posting-log.json entries |
| 0.7 | reporting-engine-v2.sh generates accurate report | daily-report-<date>.md with correct counts | Report file contents |
| 0.8 | daily-pipeline.sh runs all stages successfully | Log shows all stages COMPLETE | daily-pipeline.log |
| 0.9 | Cron job configured and fires | Automated run appears in log next morning | Log timestamp from cron run |
| 0.10 | 3-day unattended run | 3 consecutive daily reports with real content | 3 report files + approval logs |

**Phase 0 is DONE when:** The daily pipeline has run unattended for 3 days, producing real content, with correct approval routing, and accurate reports.

---

## 8. PHASE 1 DELIVERABLES

**Phase 1 = Clean module documentation + Builder Intelligence prep.**

| # | Deliverable | Success Criteria | Evidence |
|---|---|---|---|
| 1.1 | Module documentation headers added to all 18 scripts | Each script has a header block: module, purpose, inputs, outputs, depends-on | Script header comments |
| 1.2 | Module map document created | One document mapping all scripts to modules with dependency graph | `MODULE-MAP.md` file |
| 1.3 | Duplicate skills consolidated | 3 duplicate groups resolved (reporting, channel adapters, approval) | Grep confirms no broken references |
| 1.4 | Policy JSONs wired into approval-engine.sh | L1 types read from JSON, not hardcoded; rate limits read from JSON | Code diff + test run |
| 1.5 | brand-voice-rules.json consumed by approval engine | Brand voice scoring uses real rules | Test run with brand-violating content → caught |
| 1.6 | Memory system activated | memory-write.sh called at end of daily-pipeline.sh | Memory files accumulate daily |
| 1.7 | BuilderData/ folder structure created | Empty folders ready for Phase 2 | `ls` output |
| 1.8 | generate-report.sh merged into reporting-engine-v2.sh | Single reporting script handles all cases | Old script removed, pipeline updated |
| 1.9 | SKILL.md category tags standardized | All 60 SKILL.md files have `category:` in frontmatter | Grep output |
| 1.10 | Weekly and monthly pipelines tested | weekly-pipeline.sh and monthly-pipeline.sh run successfully | Log output + report files |

**Phase 1 is DONE when:** The module map is documented, policies are wired, duplicates are consolidated, memory accumulates, and all three pipeline cadences (daily/weekly/monthly) are proven.

---

## 9. EXACT RECOMMENDED NEXT ACTION SEQUENCE

```
 1. Fix the approval-engine.sh credential check grep bug (one line)
 2. Clear old test data from approvals/blocked/ (archive to ExportsLogs/archive/)
 3. Create 3 fresh real source files for the proof test
 4. Run intake-processor.sh, verify .meta.json files created
 5. Run content-agent.sh, verify content in queues/*/pending/
 6. Run approval-engine.sh, verify correct L1/L2/L3/L4 routing
 7. Run distribution-engine.sh, verify export to posted/
 8. Run reporting-engine-v2.sh --type daily, verify report
 9. Run daily-pipeline.sh end-to-end with NEW source files
10. Set up cron (launchd plist) for daily-pipeline.sh at 8:07 AM
11. Let it run for 3 days with you dropping 1-2 source notes per day
12. After 3 successful days: Phase 0 is DONE
13. Add module headers to all 18 scripts
14. Create MODULE-MAP.md
15. Wire approval-rules.json into approval-engine.sh (replace hardcoded L1 types)
16. Wire rate-limits.json into distribution-engine.sh (replace hardcoded cap)
17. Wire brand-voice-rules.json into approval scoring
18. Consolidate duplicate skills (3 groups)
19. Merge generate-report.sh into reporting-engine-v2.sh
20. Add memory-write.sh call to end of daily-pipeline.sh
21. Create BuilderData/ folder structure (empty, for Phase 2)
22. Test weekly-pipeline.sh end-to-end
23. Test monthly-pipeline.sh end-to-end
24. Phase 1 is DONE
25. ONLY THEN begin Phase 2 (Builder Intelligence)
```

---

## 10. FINAL RECOMMENDATION

### The Single Most Important Fix

**Fix the credential-check grep in approval-engine.sh.** The current code:

```bash
if echo "$CRED_CHECK" | grep -qi '"safe":\s*false\|"action":\s*"block"\|CRITICAL\|credentials found\|API key'; then
```

This matches the word `safe` in `"safe": true` because the grep pattern `"safe"` appears in both the true and false cases. The fix is to match specifically for `"safe": false` or `"safe":false` — not just the presence of the word "safe".

**This one bug is why ~28 files were falsely blocked in test runs while showing `"safe": true` in their block reasons.**

### The Discipline Required

Do not expand the system until the daily pipeline has run unattended for 3 days. The temptation will be to start building Builder Intelligence, add more skills, connect more platforms. Resist it. A proven daily cycle is worth more than 100 unproven features.

### The Path Forward

```
Week 1: Fix bug → prove pipeline → set up cron → run 3 days
Week 2: Modularize → wire policies → consolidate duplicates → test weekly/monthly
Week 3+: Begin Builder Intelligence (Phase 2)
```

This is the world-class path: disciplined, evidence-based, honest.
