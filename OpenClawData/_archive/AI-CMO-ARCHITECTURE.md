# AI CMO Architecture — Complete System Design
## For OpenClaw Local-First Solo Builder Setup
### Date: 2026-03-25

---

## 1. EXECUTIVE SUMMARY

**What you have now (verified):**
- Workspace: `/Volumes/Expansion/CMO-10million/`
- Ollama running with `qwen3:8b` (writing/strategy) + `qwen2.5-coder:7b` (code/automation)
- 60 SKILL.md files (prompt templates for Ollama — advisory, not runtime-enforced)
- 18 shell scripts in `OpenClawData/scripts/` (real executable logic)
- Full folder structure: skills/, queues/, approvals/, memory/, reports/, MarketingToolData/
- SocialFlow app (Python backend + frontend) for social media management
- Symlink at `~/.openclaw/workspace/skills` pointing to skills folder

**What SKILL.md files actually are:**
They are structured prompt templates. When you run `skill-runner.sh <skill-name> "input"`, it reads the SKILL.md, feeds it + your input to Ollama, and returns AI output. They are NOT runtime plugins — they are prompt engineering documents that the shell scripts consume.

**What the shell scripts actually do:**
They are the real execution layer. They call Ollama API, route to models, read/write files, log actions, and orchestrate the pipeline. This IS the runtime.

**Architecture reality:**
Your system is a **shell-script-orchestrated, Ollama-powered, file-based content pipeline**. This is honest, practical, and exactly right for a solo builder. No need to pretend it's something else.

---

## 2. AI CMO SYSTEM ARCHITECTURE

```
┌─────────────────────────────────────────────────────────┐
│                    YOU (Solo Builder)                     │
│         Drop source notes, links, logs, ideas            │
│              into MarketingToolData/                      │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              INTAKE LAYER (intake-processor.sh)           │
│  Reads: source-notes/, source-links/, product-updates/   │
│  Classifies content type, writes .meta.json tags         │
│  Model: qwen3:8b                                         │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│           CONTENT PRODUCTION (content-agent.sh)           │
│  Reads classified source + SKILL.md templates             │
│  Produces: website posts, social posts, newsletters,      │
│  briefs, roundups — writes to MarketingToolData/          │
│  Model: qwen3:8b (writing) / qwen2.5-coder:7b (scripts)  │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│          APPROVAL ENGINE (approval-engine.sh)             │
│  Scores content: risk, brand voice, duplication, claims   │
│  Routes to: approved/ | review/ | blocked/                │
│  Auto-approves Level 1, score-gates Level 2               │
│  Model: qwen3:8b                                          │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│        DISTRIBUTION (distribution-engine.sh)              │
│  Reads approved content                                   │
│  Copies to queues/website/, queues/linkedin/, etc.        │
│  Exports to SocialFlow or manual review packs             │
│  Posts via Discord webhook if configured                   │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│             REPORTING (generate-report.sh)                │
│  Writes daily/weekly/monthly reports                      │
│  Tracks: attempted, approved, blocked, posted, exported   │
│  Stores in: OpenClawData/reports/daily|weekly|monthly/    │
└─────────────────────────────────────────────────────────┘
```

---

## 3. MULTI-AGENT STRUCTURE (Mapped to Real Scripts)

| Agent Role | Real Implementation | Model | What It Does |
|---|---|---|---|
| **HQ Coordinator** | `daily-pipeline.sh` / `weekly-pipeline.sh` / `monthly-pipeline.sh` | — (orchestrator) | Runs the right scripts in order, coordinates daily/weekly/monthly flows |
| **Newsroom Agent** | `newsroom-agent.sh` + `ai-news-summarizer` SKILL.md | qwen3:8b | Reads source-links/, ai-news/, produces news summaries |
| **Product Update Agent** | `product-update-agent.sh` + `product-update-writer` SKILL.md | qwen3:8b | Reads product-updates/, build-logs/, generates update content |
| **Content Agent** | `content-agent.sh` + multiple SKILL.md templates | qwen3:8b | Produces all content types from classified sources |
| **Approval Policy Agent** | `approval-engine.sh` + `risk-scorer` / `approval-policy` SKILL.md | qwen3:8b | Scores and routes content through 4-level approval |
| **Distribution Agent** | `distribution-engine.sh` + `socialflow-publisher.sh` | qwen2.5-coder:7b | Moves approved content to queues, exports, webhooks |
| **Reporting Agent** | `generate-report.sh` / `reporting-engine-v2.sh` | qwen3:8b | Generates execution reports with evidence |

---

## 4. WEBSITE CONTENT HUB STRUCTURE

**Recommended sections (no traditional blog needed):**

| Section | URL Path | Content Type | Update Frequency |
|---|---|---|---|
| **Updates** | `/updates` | Product releases, feature announcements, changelogs | 2-3x/week |
| **Insights** | `/insights` | AI commentary, educational posts, comparisons, how-tos | 1-2x/week |
| **News** | `/news` | AI industry news summaries, tool roundups, market signals | 2-3x/week |
| **Build Log** | `/build-log` | "What we built this week", founder journey, behind-the-scenes | 1x/week |
| **Lab** | `/lab` | Experiments, early previews, technical deep dives | 1-2x/month |

**Why this works better than a blog:**
- Each section has a clear purpose (not a chronological dump)
- Easier to repurpose (an /updates post becomes a LinkedIn post, an /insights post becomes a newsletter)
- SEO-friendly with topic clustering
- Newsletter archive can live under /insights or a separate /newsletter later

---

## 5. FULL CHANNEL / PLATFORM MATRIX

| Platform | Funnel Role | Content Type | Automation Status | Frequency | Risk | OpenClaw Action | Guardrails |
|---|---|---|---|---|---|---|---|
| **Website** | Hub/Authority | Updates, insights, news, build logs | **Auto-ready now** (file export to CMS/static site) | Daily-ish | Low | Write files to queues/website/ | Brand voice check |
| **LinkedIn** | Professional reach | Thought leadership, updates, insights | **Queue/export** (copy-paste or Buffer/Typefully) | 3-5x/week | Medium | Write to queues/linkedin/ | No aggressive sales |
| **X/Twitter** | Reach/engagement | Short takes, threads, announcements | **Queue/export** (copy-paste or scheduling tool) | 5-7x/week | Medium | Write to queues/x/ | No controversial claims |
| **Facebook** | Community/broad reach | Updates, articles, announcements | **Queue/export** | 2-3x/week | Low | Write to queues/facebook/ | Basic tone check |
| **Instagram** | Visual brand | Captions, carousels (need images separately) | **Queue/export** | 2-3x/week | Low | Write captions to queues/instagram/ | Needs manual image |
| **Discord** | Community/direct | Announcements, updates, discussions | **Auto-ready now** (webhook) | Daily | Low | `discord-webhook-publisher` script | Rate limit |
| **Reddit** | Authority/SEO | Helpful posts, discussions, AMAs | **Manual-first** (Reddit hates bots) | 1-2x/week | High | Draft to queues/reddit/ | Never auto-post |
| **Medium** | SEO/syndication | Long-form articles, insights | **Queue/export** | 1-2x/month | Low | Write to queues/medium/ | Duplicate content warning |
| **Substack** | Newsletter/audience | Newsletters, digests, deep dives | **Draft/export first** | 1x/week | Low | Write to queues/substack/ + email/ | Sending caps |
| **beehiiv** | Newsletter alternative | Same as Substack | **Later-stage** | — | Low | — | — |
| **MailerLite** | Email campaigns | Campaigns, sequences | **Later-stage** (API available) | — | Medium | — | Rate limits, caps |
| **Brevo** | Transactional + marketing email | Newsletters, automation | **Later-stage** (API available) | — | Medium | — | Rate limits, caps |
| **Product Hunt** | Launch spikes | Launch posts | **Manual-first** (timing matters) | Per launch | High | Draft brief only | Never auto-post |
| **Hacker News** | Technical authority | Technical posts, Show HN | **Manual-first** (community rules strict) | Rarely | Very High | Draft only | Never auto-post |
| **Quora** | SEO/authority | Answers, thought leadership | **Manual-first** | 1-2x/month | Medium | Draft to NotesDocs/ | No self-promo spam |
| **YouTube Shorts** | Video reach | Short clips (need HeyGen/editor) | **Brief only** | 1-2x/month | Low | Video brief to video-briefs/ | Needs manual production |
| **TikTok** | Viral/young audience | Short clips | **Brief only** | Later | Low | Video brief only | Needs manual production |
| **HeyGen** | Video production tool | Avatar videos from briefs | **Brief/export** | As needed | Low | Write brief to video-briefs/ | Needs HeyGen account |

---

## 6. FULL SKILL ARCHITECTURE (60 Skills, Organized)

### FOUNDATION (6 skills — already implemented)
| Skill | SKILL.md | Shell Script | Nature |
|---|---|---|---|
| Workspace Guard | ✅ | workspace-guard.sh | Path enforcement (real) |
| Local Model Router | ✅ | model-router.sh | Routes to correct model (real) |
| Memory Writer | ✅ | memory-write.sh | Persists knowledge to files (real) |
| Verification & Evidence | ✅ | verify-evidence.sh | Checks for proof before marking done (real) |
| Task Planner | ✅ | task-plan.sh | Breaks goals into steps (advisory + file output) |
| Reporting | ✅ | generate-report.sh + reporting-engine-v2.sh | Generates reports (real) |

### CONTENT / EDITORIAL (15 skills)
| Skill | SKILL.md | Used By Script | Model |
|---|---|---|---|
| Website Update Writer | ✅ | content-agent.sh | qwen3:8b |
| Insights/Article Writer | ✅ | content-agent.sh | qwen3:8b |
| AI News Summarizer | ✅ | newsroom-agent.sh | qwen3:8b |
| Product Update Writer | ✅ | product-update-agent.sh | qwen3:8b |
| Social Repurposing | ✅ | content-agent.sh | qwen3:8b |
| Brand Voice Enforcer | ✅ | approval-engine.sh | qwen3:8b |
| Newsletter Draft Builder | ✅ | content-agent.sh | qwen3:8b |
| Weekly Roundup Builder | ✅ | weekly-pipeline.sh | qwen3:8b |
| Comparison Post Writer | ✅ | content-agent.sh | qwen3:8b |
| Educational Content Builder | ✅ | content-agent.sh | qwen3:8b |
| Build Log Writer | ✅ | content-agent.sh | qwen3:8b |
| Creative Brief Generator | ✅ | content-agent.sh | qwen3:8b |
| Video Brief Generator | ✅ | content-agent.sh | qwen3:8b |
| Image Brief Generator | ✅ | content-agent.sh | qwen3:8b |
| Discord Announcement Writer | ✅ | content-agent.sh | qwen3:8b |

### APPROVAL / SAFETY (8 skills)
| Skill | SKILL.md | Used By Script | Model |
|---|---|---|---|
| Approval Policy | ✅ | approval-engine.sh | qwen3:8b |
| Risk Scorer | ✅ | approval-engine.sh | qwen3:8b |
| Duplicate Checker | ✅ | approval-engine.sh | qwen3:8b |
| Factuality Check | ✅ | approval-engine.sh | qwen3:8b |
| Channel Policy Checker | ✅ | approval-engine.sh | qwen3:8b |
| Human Review Queue | ✅ | approval-engine.sh (escalation) | — |
| Rate Limit Guard | ✅ | distribution-engine.sh | — (config-based) |
| Credential Safety Policy | ✅ | distribution-engine.sh | — (config-based) |

### DISTRIBUTION / EXECUTION (7 skills)
| Skill | SKILL.md | Used By Script | Model |
|---|---|---|---|
| Channel Exporter | ✅ | distribution-engine.sh | qwen2.5-coder:7b |
| Channel Adapter | ✅ | distribution-engine.sh | qwen2.5-coder:7b |
| Posting Queue Manager | ✅ | distribution-engine.sh | — |
| Website Publisher Queue | ✅ | distribution-engine.sh | — |
| Discord Webhook Publisher | ✅ | socialflow-publisher.sh | — (webhook call) |
| Newsletter Exporter | ✅ | distribution-engine.sh | — |
| Social Queue Packager | ✅ | distribution-engine.sh | qwen2.5-coder:7b |
| Campaign Calendar Builder | ✅ | weekly-pipeline.sh | qwen3:8b |

### RESEARCH / GROWTH (6 skills)
| Skill | SKILL.md | Used By Script | Model |
|---|---|---|---|
| Trend-to-Content | ✅ | newsroom-agent.sh | qwen3:8b |
| Competitor Monitor | ✅ | newsroom-agent.sh | qwen3:8b |
| Opportunity Miner | ✅ | newsroom-agent.sh | qwen3:8b |
| SEO Topic Mapper | ✅ | monthly-pipeline.sh | qwen3:8b |
| Audience Angle Generator | ✅ | content-agent.sh | qwen3:8b |
| Offer/Funnel Copy Builder | ✅ | content-agent.sh | qwen3:8b |

### META / TRACKING (4 skills)
| Skill | SKILL.md | Used By Script | Model |
|---|---|---|---|
| Content Classifier | ✅ | intake-processor.sh | qwen3:8b |
| Content Performance Tracker | ✅ | reporting-engine-v2.sh | qwen3:8b |
| HQ Coordinator | ✅ | daily-pipeline.sh | qwen3:8b |
| News Source Collector | ✅ | newsroom-agent.sh | qwen3:8b |

### CODING / AUTOMATION (Existing from earlier waves)
| Skill | SKILL.md | Model |
|---|---|---|
| Repo Review | ✅ | qwen2.5-coder:7b |
| Safe Code Edit | ✅ | qwen2.5-coder:7b |
| Landing Page Upgrade | ✅ | qwen2.5-coder:7b |
| Prompt Library Builder | ✅ | qwen3:8b |
| Automation Script Builder | ✅ | qwen2.5-coder:7b |
| Reddit Post Drafter | ✅ | qwen3:8b |
| Session Compaction | ✅ | qwen3:8b |
| Daily Briefing | ✅ | qwen3:8b |
| QA Checklist | ✅ | qwen3:8b |
| Human-in-the-Loop Approval | ✅ | — |
| Lead Research | ✅ | qwen3:8b |

---

## 7. APPROVAL MODEL (4 Levels)

### Level 1 — AUTO-APPROVE (no human needed)
- Product update summaries from your own source material
- Founder/build-log updates
- Repurposed content from already-approved sources
- Discord announcements
- Simple website updates
- Newsletter snippets based on approved content

**Rule:** Source is internal (your notes/logs) + brand voice score > 0.7 + no restricted claims → auto-approve

### Level 2 — SCORE-GATED AUTO-APPROVE (threshold-based)
- AI news summaries
- Tool comparison posts
- Industry commentary
- Educational posts
- SEO posts

**Scoring criteria (all must pass):**
| Check | Threshold |
|---|---|
| Source confidence | ≥ 0.6 |
| Brand voice score | ≥ 0.7 |
| No restricted claims | pass |
| Duplication score | < 0.3 (not too similar to existing) |
| Risk score | < 0.4 |
| Evidence attached | yes |

**If score fails:** → goes to Level 3 review queue

### Level 3 — REVIEW QUEUE (you must approve)
- Bold claims about competitors or industry
- PR-sensitive content
- Competitor criticism
- Aggressive sales language
- Uncertain or breaking news
- Platform-sensitive outreach (Reddit, HN, Quora)

**Stored in:** `OpenClawData/approvals/review/`

### Level 4 — BLOCK (automatic rejection)
- Unverifiable claims
- Rumors without source
- Policy-violating content
- Personal/private data exposure
- Mass spam patterns
- Content without any evidence
- Actions targeting non-approved channels

**Stored in:** `OpenClawData/approvals/blocked/` with reason log

---

## 8. EMAIL / NEWSLETTER ARCHITECTURE

### Accounts
- Dedicated marketing email accounts only (NOT personal)
- These accounts are approved for OpenClaw automation

### Platform Classification

| Platform | Phase | Integration Type | Notes |
|---|---|---|---|
| **Substack** | V1 — Draft/export | Write drafts to queues/substack/, copy-paste to Substack editor | Simplest newsletter start |
| **beehiiv** | V2 — Semi-automated | API available, could auto-draft | Better analytics than Substack |
| **MailerLite** | V2 — Semi-automated | REST API, can create campaigns programmatically | Good free tier |
| **Brevo** | V3 — Full integration | Full API, transactional + marketing | Most powerful, most complex |

### Safety Rules
| Rule | Value |
|---|---|
| Daily sending cap | 50 emails/day max (V1), increase later |
| Rate limit | Max 1 newsletter/day, 3/week |
| Audit log required | Every send logged in OpenClawData/logs/ |
| Allowed domains | Only your marketing domains |
| No destructive actions | No password changes, no account deletion |
| No mass outreach | No cold email blasts without explicit approval |
| Review required for | Any email to > 100 recipients, any new recipient list |

### Newsletter Pipeline
```
Source material → newsletter-draft-builder SKILL.md → qwen3:8b produces draft
→ approval-engine.sh scores it → if approved → queues/email/
→ you copy to Substack/beehiiv/MailerLite → send
→ (V2+) API integration auto-creates draft in platform
```

---

## 9. FULL CONTENT PIPELINE

```
SOURCE INTAKE                    CLASSIFICATION              PRODUCTION
─────────────                    ──────────────              ──────────
source-notes/     ──┐            content-classifier          website-update-writer
source-links/     ──┤            SKILL.md tags each          insights-article-writer
product-updates/  ──┤  intake-   source as:                  ai-news-summarizer
build-logs/       ──┤  processor - product-update             social-repurposing
ai-news/          ──┤  .sh       - ai-news                   newsletter-draft-builder
screenshots/      ──┘            - educational                weekly-roundup-builder
                                 - comparison                 discord-announcement-writer
                                 - founder-log                video-brief-generator
                                 - launch                     image-brief-generator
                                 - social                     build-log-writer
                                 - newsletter                 comparison-post-writer
                                 - video-brief                educational-content-builder
                                 - image-brief                creative-brief-generator
                                                              reddit-post-drafter

VERIFICATION              APPROVAL                DISTRIBUTION           REPORTING
────────────              ────────                ────────────           ─────────
verify-evidence.sh        approval-engine.sh      distribution-engine.sh generate-report.sh
- evidence check          L1: auto-approve        → queues/website/     - what attempted
- source check            L2: score-gated         → queues/linkedin/    - what approved
- duplicate check         L3: review queue         → queues/x/          - what blocked
- brand voice check       L4: block               → queues/discord/     - what posted
- risk scoring                                    → queues/email/       - what exported
- claim check             approved/ → distribute  → queues/reddit/      - evidence
- policy check            review/ → wait for you  → queues/medium/      - next actions
                          blocked/ → logged        → queues/substack/
```

---

## 10. CRON / SCHEDULE PLAN

### DAILY (run daily-pipeline.sh)
| Time | Task | Script/Skill | Duration |
|---|---|---|---|
| 8:00 AM | Collect & classify new source material | intake-processor.sh | ~5 min |
| 8:10 AM | Generate AI news summary (if new links) | newsroom-agent.sh | ~3 min |
| 8:15 AM | Generate 1 website update draft | content-agent.sh --type website-update | ~3 min |
| 8:20 AM | Generate 2-3 social post drafts | content-agent.sh --type social | ~5 min |
| 8:30 AM | Generate 1 Discord announcement | content-agent.sh --type discord | ~2 min |
| 8:35 AM | Generate 1 newsletter snippet | content-agent.sh --type newsletter-snippet | ~2 min |
| 8:40 AM | Run approval engine on all new drafts | approval-engine.sh | ~5 min |
| 8:50 AM | Distribute approved content to queues | distribution-engine.sh | ~3 min |
| 9:00 AM | Generate daily report | generate-report.sh --daily | ~2 min |

**Total daily AI time: ~30 minutes of Ollama processing**
**Your daily manual time: ~15-30 min reviewing queues + posting**

### WEEKLY (run weekly-pipeline.sh — e.g., Monday morning)
| Task | Script/Skill |
|---|---|
| Create weekly editorial calendar | campaign-calendar-builder SKILL.md |
| Produce weekly roundup | weekly-roundup-builder SKILL.md |
| Produce "what we built this week" post | build-log-writer SKILL.md |
| 1-2 HeyGen video briefs | video-brief-generator SKILL.md |
| 1 full newsletter draft | newsletter-draft-builder SKILL.md |
| Weekly growth/performance summary | reporting-engine-v2.sh --weekly |
| Memory consolidation | memory-write.sh --consolidate |

### MONTHLY (run monthly-pipeline.sh — 1st of month)
| Task | Script/Skill |
|---|---|
| Content pillar review | hq-coordinator + content-strategy SKILL.md |
| Campaign theme refresh | creative-brief-generator SKILL.md |
| SEO topic update | seo-topic-mapper SKILL.md |
| Offer positioning update | offer-funnel-copy SKILL.md |
| Archive cleanup | workspace-guard.sh --archive |
| Monthly performance summary | reporting-engine-v2.sh --monthly |
| Next-month plan | task-plan.sh --monthly |

---

## 11. FOLDER-TO-SKILL MAPPING

### MarketingToolData/ (Content Storage)
| Folder | Written By | Read By |
|---|---|---|
| source-notes/ | You (manual) | intake-processor.sh |
| source-links/ | You (manual) | newsroom-agent.sh |
| ai-news/ | newsroom-agent.sh | content-agent.sh |
| product-updates/ | You + product-update-agent.sh | content-agent.sh |
| screenshots/ | You (manual) | content-agent.sh |
| website-posts/ | content-agent.sh | distribution-engine.sh |
| insights/ | content-agent.sh | distribution-engine.sh |
| newsletters/ | content-agent.sh | distribution-engine.sh |
| linkedin/ | content-agent.sh | distribution-engine.sh |
| x/ | content-agent.sh | distribution-engine.sh |
| facebook/ | content-agent.sh | distribution-engine.sh |
| instagram/ | content-agent.sh | distribution-engine.sh |
| discord/ | content-agent.sh | discord-webhook-publisher |
| reddit/ | content-agent.sh | You (manual post) |
| medium/ | content-agent.sh | You (manual post) |
| substack/ | content-agent.sh | You (manual/API) |
| email/ | content-agent.sh | You / MailerLite API |
| video-briefs/ | content-agent.sh | You → HeyGen |
| image-briefs/ | content-agent.sh | You → design tool |
| weekly-roundups/ | weekly-pipeline.sh | distribution-engine.sh |
| build-logs/ | content-agent.sh | distribution-engine.sh |
| comparison-posts/ | content-agent.sh | distribution-engine.sh |

### OpenClawData/ (System Data)
| Folder | Written By | Read By |
|---|---|---|
| skills/*/SKILL.md | Setup (us) | skill-runner.sh, all agent scripts |
| scripts/*.sh | Setup (us) | Cron / manual execution |
| memory/*/ | memory-write.sh | All agent scripts |
| approvals/pending/ | approval-engine.sh | You |
| approvals/approved/ | approval-engine.sh | distribution-engine.sh |
| approvals/blocked/ | approval-engine.sh | reporting |
| approvals/review/ | approval-engine.sh | You |
| queues/*/ | distribution-engine.sh | You / webhook scripts |
| reports/daily/ | generate-report.sh | You |
| reports/weekly/ | reporting-engine-v2.sh | You |
| reports/monthly/ | reporting-engine-v2.sh | You |
| logs/ | All scripts | reporting, debugging |
| sessions/ | Session tracking | reporting |
| prompts/ | prompt-library-builder | skill-runner.sh |
| policies/ | Setup (us) | approval-engine.sh |

---

## 12. AUTO-NOW vs QUEUE vs MANUAL vs LATER MATRIX

| Channel | V1 Status | V2 Target | V3 Target |
|---|---|---|---|
| Website (file export) | **Auto-now** | Auto-now | Auto-now + CMS API |
| Discord (webhook) | **Auto-now** | Auto-now | Auto-now |
| LinkedIn | **Queue/export** | Buffer/Typefully API | LinkedIn API |
| X/Twitter | **Queue/export** | Buffer/Typefully API | X API |
| Facebook | **Queue/export** | Buffer API | Meta API |
| Instagram | **Queue/export** | Buffer API | Meta API |
| Email/Newsletter | **Queue/export** | MailerLite/Brevo API | Full automation |
| Substack | **Queue/export** | Substack API draft | Semi-auto |
| Medium | **Queue/export** | Medium API draft | Semi-auto |
| Reddit | **Manual-first** | Manual-first | Manual-first (always) |
| Product Hunt | **Manual-first** | Manual-first | Manual-first |
| Hacker News | **Manual-first** | Manual-first | Manual-first |
| Quora | **Manual-first** | Manual-first | Manual-first |
| YouTube Shorts | **Brief only** | Brief + HeyGen | Brief + HeyGen |
| TikTok | **Later** | Brief only | Brief + production |
| beehiiv | **Later** | Queue/export | API integration |
| MailerLite | **Later** | API draft | Semi-auto |
| Brevo | **Later** | API draft | Full automation |

---

## 13. IMPLEMENTATION ORDER

### V1 — FOUNDATION (What we have now + polish)
**Status: 90% built. Needs testing and hardening.**

1. ✅ All 60 SKILL.md files created
2. ✅ All 18 shell scripts created
3. ✅ Folder structure complete
4. ✅ Ollama running with both models
5. 🔧 Need: end-to-end pipeline test (daily-pipeline.sh full run)
6. 🔧 Need: Discord webhook configuration
7. 🔧 Need: approval thresholds tuned
8. 🔧 Need: Desktop reference doc updated

### V2 — AUTOMATION + SCHEDULING (Next phase)
1. Set up real cron jobs for daily/weekly/monthly pipelines
2. Connect Buffer or Typefully for social scheduling
3. Connect MailerLite or Brevo API for email drafts
4. Add SocialFlow integration for multi-channel posting
5. Add simple web dashboard (or use SocialFlow's frontend)

### V3 — SCALE + INTELLIGENCE (Later)
1. Direct platform API integrations (LinkedIn, X, Meta)
2. SEO monitoring and auto-topic generation
3. Competitor monitoring with real data sources
4. Performance tracking with analytics integration
5. A/B testing for content variants
6. Advanced HeyGen video pipeline

---

## 14. V1 / V2 / V3 ROLLOUT PLAN

| Phase | Timeline | Focus | Key Deliverable |
|---|---|---|---|
| **V1** | Now | Foundation working end-to-end | daily-pipeline.sh produces real content, approved, queued |
| **V2** | After V1 stable | Scheduling + external tool connections | Cron-driven daily pipeline + at least 1 platform API |
| **V3** | After V2 stable | Scale + intelligence | Multi-platform auto-posting + analytics |

---

## 15. RISKS, SAFEGUARDS, AND BLOCKERS

### Risks
| Risk | Impact | Mitigation |
|---|---|---|
| Ollama quality varies | Bad content published | 4-level approval model + brand voice scoring |
| External drive disconnects | Pipeline breaks | workspace-guard.sh checks mount before running |
| Rate limiting by platforms | Account flagged | rate-limit-guard + daily caps in distribution-engine.sh |
| Content duplication | Looks spammy | duplicate-checker SKILL.md in approval pipeline |
| Model hallucination | False claims published | factuality-check + evidence requirement |
| Over-automation | Loss of authentic voice | Level 3 review queue for anything sensitive |

### Safeguards Already Built
- Workspace guard (path enforcement)
- 4-level approval model
- Rate limiting in distribution
- Credential safety policy
- Evidence requirement for completion
- All actions logged
- Human review queue for medium+ risk

### Current Blockers
1. **No cron jobs configured yet** — pipelines exist but don't run automatically
2. **No Discord webhook URL configured** — script exists but needs your webhook
3. **No platform API keys** — Buffer/Typefully/MailerLite not connected yet
4. **SocialFlow app needs connection to pipeline** — exists but not integrated with queue system
5. **Approval thresholds not tuned** — need real content runs to calibrate

---

## 16. FINAL RECOMMENDATION — BEST FIRST BUILD

**Do this in order:**

1. **Run `daily-pipeline.sh` end-to-end once** — drop 2-3 source notes, run the full pipeline, see what comes out. This validates the entire system in one test.

2. **Configure Discord webhook** — quickest auto-publish win. Drop your webhook URL into the script, auto-post approved Discord content.

3. **Set up a real cron job** — `crontab -e` with daily-pipeline.sh at 8 AM. Now the system runs itself every morning.

4. **Review your first week of queued content** — check queues/linkedin/, queues/x/, queues/website/. Copy-paste the best ones to post manually. This trains your sense of what the system produces.

5. **Tune approval thresholds** — after seeing real output, adjust the brand voice and risk scoring prompts in the SKILL.md files.

6. **Connect one scheduling tool** — Buffer, Typefully, or similar. This bridges "queue file" → "actually scheduled post."

7. **Connect one email platform** — MailerLite free tier. Start with weekly newsletter from queues/email/.

**This gets you a working AI CMO in about 1-2 sessions of setup work.**
