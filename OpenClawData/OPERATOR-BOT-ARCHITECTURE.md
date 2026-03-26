# InBharat Autonomous Operator Bot — Architecture Document
**Date:** 2026-03-26
**Status:** Architecture + Roadmap (no code changes yet)

---

## A. Executive Summary

The current system is a **proven content generation pipeline** with a working approval engine, local AI models, and an intelligence bot layer. It creates content, scores it, queues it, and reports on it. But it currently operates as a **factory without delivery** — nothing actually reaches the outside world.

To become an autonomous operator bot, the system needs 7 new layers that don't exist yet: delivery, community intelligence, revenue support, task autonomy, multilingual adaptation, budget governance, and engagement analytics. None of these require destroying what exists — they are all additive.

**Current state:** 26 working scripts, 64 prompt templates, 4 policies, 2 agents, WhatsApp connected, gateway running. Cron paused. Zero external publishing. Zero community maps. Zero revenue capture. Zero multilingual support.

**Path forward:** Stabilize → Deliver → Scout → Earn → Build → Translate → Govern.

---

## B. What Already Exists and Should Be Preserved

| Component | Lines/Count | Status | Preserve? |
|---|---|---|---|
| Ollama (qwen3:8b + qwen2.5-coder:7b) | 2 models, ~10GB | ✅ Running | YES |
| OpenClaw gateway | v2026.3.23-2 | ✅ Running | YES |
| 2 agents (main + builder) | Configured | ✅ Working | YES |
| WhatsApp (allowlist +919015823397) | Connected | ✅ Working | YES |
| `daily-pipeline.sh` | 148L | ✅ Proven | YES |
| `intake-processor.sh` | 161L | ✅ Proven | YES |
| `content-agent.sh` | 255L | ✅ Proven | YES |
| `approval-engine.sh` | 241L | ✅ Fixed & proven | YES |
| `distribution-engine.sh` | 281L | ✅ Has real webhook code | YES |
| `model-router.sh` | 64L | ✅ Working | YES |
| `workspace-guard.sh` | 53L | ✅ Working | YES |
| `memory-write.sh` | 74L | ✅ Working | YES |
| `verify-evidence.sh` | 125L | ✅ Working | YES |
| `generate-report.sh` | 109L | ✅ Working | YES |
| `task-plan.sh` | 104L | ✅ Working | YES |
| `skill-runner.sh` | 102L | ✅ Working | YES |
| `newsroom-agent.sh` | 111L | ⚠️ Untested solo | YES |
| `product-update-agent.sh` | 133L | ⚠️ Untested solo | YES |
| `weekly-pipeline.sh` | 135L | ⚠️ Untested | YES |
| `monthly-pipeline.sh` | 141L | ⚠️ Untested | YES |
| `reporting-engine-v2.sh` | 252L | ⚠️ Unclear if used | YES (clarify) |
| `socialflow-publisher.sh` | 121L | ⚠️ Bypassed | Mark deprecated |
| InBharat Bot (8 scripts, 711L total) | Full cycle proven | ✅ Working | YES |
| 64 SKILL.md templates | Advisory prompt context | ✅ Honest disclaimers added | YES |
| 4 policy JSONs | Approval/voice/channel/rate | ✅ Working | YES |
| 11 queue directories | Empty but structured | ✅ Ready | YES |
| 4 daily reports | From test runs | ✅ Real | YES |
| 11 memory files | From pipeline runs | ✅ Real | YES |
| Caffeinate (keep-awake) | Running | ✅ | YES |
| Git repo (554 files) | Pushed to GitHub | ✅ | YES |

---

## C. What Already Supports the Operator-Bot Vision

| Operator Role | Existing Support | Gap |
|---|---|---|
| **Identity/Brand Memory** | 11 memory files + brand-voice policy + IDENTITY.md | Needs structured brand knowledge base |
| **Content Brain** | intake → classify → route → generate pipeline | Needs content lane planning (product vs education vs community) |
| **Asset Builder** | content-agent + skill-runner + 13 asset skills | Needs platform-native format adapters |
| **Broadcaster** | distribution-engine with webhook code + 11 queues | Needs live connections (Discord webhook, platform APIs) |
| **Approval Gate** | 4-level engine + 4 policies | Working. Needs community-policy extension |
| **Reporter** | generate-report + reporting-engine-v2 | Needs engagement/outcome tracking |
| **Builder Intelligence** | InBharat Bot full cycle (scan → analyze → propose) | Working for ecosystem. Needs task execution |

---

## D. What Still Behaves Like a Content Factory Only

| Component | Factory Behavior | Operator Behavior Needed |
|---|---|---|
| distribution-engine.sh | Moves files to folders | POST to real APIs/webhooks |
| Queue system | Empty directories | Content flowing through with delivery status |
| Reports | Activity summaries | Outcome/engagement/revenue metrics |
| Approval engine | Content safety scoring | Action safety scoring (post vs comment vs reply vs wait) |
| Content agent | Generic variants | Platform-native + community-native variants |
| Pipeline | Create → file | Create → approve → publish → track → learn |

---

## E. Missing Layers Required for the Autonomous Operator Bot

### Layer 1: Delivery (Priority: CRITICAL)
**What:** Real outbound to Discord webhook, email, and eventually social APIs
**Why first:** Without delivery, the entire system is internal-only
**Scripts needed:** Platform-specific adapters in distribution-engine or separate
**Minimum V1:** Discord webhook (code exists, needs URL) + email draft via SMTP

### Layer 2: Community Intelligence (Priority: HIGH)
**What:** Community mapping, scoring, rule tracking, posting mode selection
**Scripts needed:** community-scout.sh, community-rewriter.sh
**Data structures:** community/maps/, community/scores/, community/rules/, community/history/
**Minimum V1:** 10 hand-mapped subreddits + 5 Discord servers in JSON profiles

### Layer 3: Community Operator (Priority: HIGH after Layer 2)
**What:** Decide post/comment/discuss/observe per community. Rewrite for tone.
**Scripts needed:** community-operator.sh
**Depends on:** Community maps + community scores
**Minimum V1:** 5 posting modes, warmup tracker, rewrite via Ollama

### Layer 4: Revenue Support (Priority: HIGH)
**What:** Lead capture, opportunity detection, proposal support, follow-up
**Scripts needed:** lead-capture.sh, proposal-builder.sh, revenue-engine.sh
**Data structures:** revenue/leads/, revenue/proposals/, revenue/opportunities/, revenue/followups/
**Minimum V1:** Inbound email scan + opportunity classifier + draft reply generator

### Layer 5: Task/Builder Autonomy (Priority: MEDIUM)
**What:** Detect missing work, create tasks, execute safe ones, escalate complex
**Scripts needed:** task-builder.sh (extends existing task-plan.sh)
**Minimum V1:** Task queue with auto-execute for safe tasks + review queue for risky ones

### Layer 6: Engagement Analytics (Priority: MEDIUM)
**What:** Track what content performed, what communities responded, what converted
**Scripts needed:** engagement-tracker.sh
**Data structures:** engagement/
**Minimum V1:** Manual input of results → automated summary and learning

### Layer 7: Multilingual (Priority: LOW — Phase F)
**What:** English-first, then Assamese, Hindi
**Scripts needed:** multilingual-adapter.sh
**Minimum V1:** Language parameter in content-agent → Ollama generates in target language

### Layer 8: Budget Governor (Priority: LOW — Phase F)
**What:** Track costs, cap spend, ROI awareness
**Scripts needed:** budget-governor.sh
**Data structures:** budget/
**Minimum V1:** All local models = $0 cost. Track only API/service costs if any.

---

## F. Safe Restructuring Recommendations

### DO IMMEDIATELY (zero risk)

1. **Clean root folder:** Move 13 duplicate/dead directories to `_archive/`
   - `approvals/`, `configs/`, `data/`, `docs/`, `exports/`, `logs/`, `queues/`, `reports/`, `tests/` (remote template)
   - `openclaw-engine/`, `socialflow/` (remote template)
   - `OpenClaw-local-backup/`, `SocialFlow-local-backup/` (old backups)

2. **Mark deprecated:** Add `# DEPRECATED` header to `socialflow-publisher.sh`

3. **Clarify reporting:** Document whether `reporting-engine-v2.sh` replaces `generate-report.sh`

### DO WHEN BUILDING NEW LAYERS (low risk)

4. **Create new data directories:**
   ```
   OpenClawData/community/maps/
   OpenClawData/community/scores/
   OpenClawData/community/rules/
   OpenClawData/community/history/
   OpenClawData/community/drafts/
   OpenClawData/revenue/leads/
   OpenClawData/revenue/proposals/
   OpenClawData/revenue/opportunities/
   OpenClawData/revenue/followups/
   OpenClawData/engagement/
   OpenClawData/budget/
   ```

### DO NOT TOUCH

- All 18 CMO scripts
- All 8 InBharat Bot scripts
- All 64 SKILL.md files
- All 4 policy JSONs
- ~/.openclaw/openclaw.json
- OpenClawData/approvals/, queues/, reports/, memory/
- MarketingToolData/
- Git remote

---

## G. Community Intelligence Design

### Community Map JSON Format
```json
{
  "id": "r-LocalLLaMA",
  "platform": "reddit",
  "name": "r/LocalLLaMA",
  "url": "https://reddit.com/r/LocalLLaMA",
  "topic": "Local LLM deployment and tools",
  "audience": "AI builders, hobbyists, researchers",
  "members": "~500K",
  "rules": {
    "self_promotion": "limited, must add value",
    "links_allowed": true,
    "flair_required": false,
    "min_account_age": "none specified"
  },
  "tone": "technical, helpful, show-don't-tell",
  "scores": {
    "relevance": 9,
    "education_openness": 9,
    "founder_openness": 6,
    "tool_openness": 7,
    "risk_of_removal": 4,
    "effort_required": 5
  },
  "posting_mode": "value",
  "warmup_status": "observe",
  "warmup_history": [],
  "posting_history": [],
  "last_scanned": "2026-03-26",
  "notes": "High engagement on benchmarks and comparisons. Avoid marketing language."
}
```

### Posting Modes

| Mode | Behavior | Use When |
|---|---|---|
| **Broadcast** | Post with link, direct promotion | Own channels only (website, newsletter, own Discord) |
| **Value** | Share insight with subtle mention | Friendly communities, after warmup |
| **Discussion** | Start genuine question/discussion | Early reputation building |
| **Comment** | Reply helpfully to existing threads | Reddit karma building, community trust |
| **Observe** | Read and log, do not post | New/unknown communities, high-risk |

### Warmup Progression
```
Week 1: OBSERVE → log 10+ relevant threads
Week 2: COMMENT → 5+ helpful replies, zero links
Week 3: DISCUSSION → 1-2 genuine questions
Week 4+: VALUE → educational content, subtle tool mention
Month 2+: Occasional BROADCAST if community receptive
```

### Community-Safe Rewrite Rules

| Target | Rewrite Strategy |
|---|---|
| Own Discord | Direct, emoji OK, link directly |
| External Discord | Remove marketing, lead with value |
| Reddit | No links in body (put in comment), lead with insight, "here's how" not "we built" |
| Hacker News | Ultra-minimal, show working thing, no landing page links |
| LinkedIn | Professional tone, founder-story angle |
| X/Twitter | Hook + insight + subtle CTA, thread for depth |
| Email outreach | Personalized, reference their work, suggest collaboration |

---

## H. Revenue-Engine Design

### Pipeline: Awareness → Interest → Opportunity → Proposal → Work → Revenue

### Revenue Actions Matrix

| Action | Auto-OK | Review Required | Never Auto |
|---|---|---|---|
| Scan inbox for opportunities | ✅ | | |
| Classify inquiry type | ✅ | | |
| Draft reply to inquiry | ✅ (save as draft) | Send it | |
| Surface hot lead to owner | ✅ | | |
| Create proposal draft | ✅ (save) | Send it | |
| Schedule follow-up reminder | ✅ | | |
| Send follow-up email | | ✅ Always review | |
| Quote pricing | | | ❌ Owner only |
| Accept work/contract | | | ❌ Owner only |
| Process payment | | | ❌ Owner only |

### Lead States
```
NEW → QUALIFIED → CONTACTED → REPLIED → PROPOSAL_SENT → NEGOTIATING → WON/LOST/DEFERRED
```

### Data Structure
```
revenue/
  leads/lead-2026-03-26-companyname.json
  proposals/proposal-2026-03-26-projectname.md
  opportunities/opp-2026-03-26-source.json
  followups/followup-schedule.json
  pipeline-state.json
```

---

## I. Multilingual and Budget-Governor Design

### Multilingual — Phased

| Phase | Languages | Method |
|---|---|---|
| Now | English only | Default |
| Phase F.1 | + Assamese | Ollama with language instruction in prompt |
| Phase F.2 | + Hindi | Same method |
| Later | Others | Add as needed |

**Key rule:** Adapt tone, not just translate literally. Each language gets its own brand-voice variant.

**Implementation:** Add `--lang` parameter to content-agent.sh. Ollama generates in target language. Community maps specify preferred language per community.

### Budget Governor

| Cost Source | Current Cost | Projected |
|---|---|---|
| Ollama (local) | $0 | $0 |
| OpenClaw (OSS) | $0 | $0 |
| Discord webhook | $0 | $0 |
| Email (SMTP) | $0-5/mo | $0-5/mo |
| Social API tools | $0 | $0 (browser-based) |
| Paid APIs later | $0 | Cap at $50/mo |

**Governor logic:** Track cumulative API spend per day/week/month. Alert at 80% of cap. Hard-stop at cap.

**Current reality:** Everything runs local and free. Budget governor is future-proofing, not urgent.

---

## J. Phased Implementation Roadmap

### Phase A: Stabilize (NOW — this week)
**Objective:** Clean workspace, prove pipeline unattended
**Actions:**
1. Move 13 duplicate dirs to `_archive/`
2. Get Discord webhook from owner
3. Restore cron
4. Run 3 unattended daily cycles
5. Verify reports are generated

**Test:** 3 consecutive daily reports with evidence
**Prereqs:** Discord webhook URL, owner drops source notes

### Phase B: First Delivery (Week 2)
**Objective:** First real content leaves the system
**Actions:**
1. Configure Discord webhook in distribution-engine
2. First auto-posted Discord announcement
3. Test email draft generation (SMTP or Gmail draft)
4. Owner logs into X/LinkedIn in Chrome for future use

**Test:** 1 real Discord post from pipeline. 1 email draft created.
**Prereqs:** Phase A complete, Discord webhook active

### Phase C: Community Intelligence (Week 3-4)
**Objective:** Map target communities, build profiles
**Actions:**
1. Create `OpenClawData/community/` structure
2. Manually research 10 subreddits + 5 Discord servers
3. Build community map JSONs
4. Build community-scout.sh (Ollama-assisted analysis)
5. Build community-rewriter.sh (rewrite for tone/rules)
6. Start OBSERVE mode on top 5 communities

**Test:** 5 community profiles scored. 3 rewrites generated.
**Prereqs:** Phase B complete

### Phase D: Revenue Foundation (Week 4-5)
**Objective:** Capture and qualify inbound opportunities
**Actions:**
1. Create `OpenClawData/revenue/` structure
2. Build lead-capture.sh (scan inbox/messages for opportunities)
3. Build proposal-builder.sh (draft proposals from templates)
4. Build follow-up scheduler
5. Connect to Gmail for inbox scanning (read-only)

**Test:** 1 lead captured, 1 proposal drafted, 1 follow-up scheduled
**Prereqs:** Phase B complete (email working)

### Phase E: Builder Autonomy (Week 6+)
**Objective:** Bot creates and executes safe tasks
**Actions:**
1. Extend task-plan.sh into task-builder.sh
2. Auto-detect missing: docs, changelog, README gaps
3. Execute safe tasks (create file, update doc)
4. Escalate risky tasks (code changes, public posts)

**Test:** 3 auto-generated tasks, 1 safely auto-executed
**Prereqs:** Phase A-D stable

### Phase F: Multilingual + Budget (Month 2+)
**Objective:** Hindi/Assamese support, cost tracking
**Actions:**
1. Add `--lang` to content-agent.sh
2. Create Assamese brand-voice profile
3. Build budget-governor.sh
4. Test Assamese content generation via Ollama

**Test:** 1 Assamese post generated with correct tone
**Prereqs:** Phase C-E stable

---

## K. What Must Not Be Broken

1. **18 CMO pipeline scripts** — entire content generation chain
2. **8 InBharat Bot scripts** — intelligence cycle
3. **4 policy JSONs** — approval rules, brand voice, channel policies, rate limits
4. **~/.openclaw/openclaw.json** — agents, WhatsApp, gateway config
5. **Git remote** — must remain pushable
6. **Ollama model storage** — on external drive
7. **Cron backup** — at /tmp/crontab-backup.txt
8. **WhatsApp allowlist** — +919015823397 only
9. **OpenClawData/** — all production data
10. **MarketingToolData/** — all source material and outputs

---

## L. Recommended Next Steps in Exact Order

| # | Action | Type | Risk | Time |
|---|---|---|---|---|
| 1 | Clean root folder (move 13 dirs to `_archive/`) | Cleanup | None | 2 min |
| 2 | Get Discord webhook URL from owner | Owner action | None | 1 min |
| 3 | Configure webhook in distribution-engine | Config | None | 5 min |
| 4 | Restore cron from backup | Config | Low | 1 min |
| 5 | Drop 2 source notes for tomorrow's pipeline | Owner action | None | 2 min |
| 6 | Verify first unattended cron run | Verify | None | Next morning |
| 7 | Verify first Discord auto-post | Verify | None | After step 6 |
| 8 | Create community/ data structure | Additive | None | 2 min |
| 9 | Research and map 10 subreddits | Research | None | 30 min |
| 10 | Build community-scout.sh | New script | None | 20 min |
| 11 | Build community-rewriter.sh | New script | None | 20 min |
| 12 | Create revenue/ data structure | Additive | None | 2 min |
| 13 | Build lead-capture.sh | New script | None | 30 min |
| 14 | Connect Gmail read-only for opportunity scanning | Integration | Low | 15 min |
| 15 | Commit and push all changes | Git | None | 2 min |

**Do NOT do yet:**
- Platform API integrations (complex OAuth)
- Automated cross-posting (needs community maps first)
- Full task autonomy (needs stable pipeline first)
- Multilingual (needs English working perfectly first)
- Budget governor (everything is free right now)

---

*This document is the single source of truth for the InBharat Operator Bot architecture. All implementation should reference this plan. No code changes should contradict it.*
