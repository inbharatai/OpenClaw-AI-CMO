# Cron / Schedule Plan

## Daily Tasks

| Time | Task | Script | Duration |
|------|------|--------|----------|
| 06:00 | Intake scan (classify new source files) | `intake-processor.sh` | ~1 min |
| 06:05 | Newsroom agent (process AI news) | `newsroom-agent.sh` | ~5 min |
| 06:15 | Product update agent | `product-update-agent.sh` | ~5 min |
| 06:25 | Content production (all channels) | `content-agent.sh` | ~15 min |
| 06:45 | Approval engine | `approval-engine.sh` | ~2 min |
| 06:50 | Distribution (queue + SocialFlow) | `distribution-engine.sh` | ~2 min |
| 07:00 | Daily report | `generate-report.sh` | ~1 min |

**Total daily time**: ~30 minutes (automated, no manual work)

**What you do daily**: Drop 1-2 source notes or links into `data/source-notes/` or `data/source-links/`. The pipeline does the rest.

---

## Weekly Tasks (Mondays)

| Time | Task | Script |
|------|------|--------|
| 08:00 | Weekly roundup post | `weekly-pipeline.sh` |
| 08:30 | "What we built this week" | Included in weekly |
| 09:00 | Editorial calendar update | Included in weekly |
| 09:30 | 1-2 HeyGen video briefs | Included in weekly |
| 10:00 | Newsletter draft | Included in weekly |
| 10:30 | Weekly report | Included in weekly |

---

## Monthly Tasks (1st of month)

| Time | Task | Script |
|------|------|--------|
| 09:00 | Content pillar review | `monthly-pipeline.sh` |
| 09:30 | Campaign theme refresh | Included in monthly |
| 10:00 | SEO topic update | Included in monthly |
| 10:30 | Offer positioning review | Included in monthly |
| 11:00 | Archive cleanup | Included in monthly |
| 11:30 | Performance summary | Included in monthly |
| 12:00 | Next month plan | Included in monthly |

---

## Crontab Setup

```bash
# OpenClaw AI CMO — Cron Schedule
# Add with: crontab -e

# Daily pipeline at 6 AM
0 6 * * * cd /path/to/OpenClaw-AI-CMO && ./openclaw-engine/scripts/daily-pipeline.sh >> logs/cron.log 2>&1

# Weekly pipeline on Mondays at 8 AM
0 8 * * 1 cd /path/to/OpenClaw-AI-CMO && ./openclaw-engine/scripts/weekly-pipeline.sh >> logs/cron.log 2>&1

# Monthly pipeline on 1st at 9 AM
0 9 1 * * cd /path/to/OpenClaw-AI-CMO && ./openclaw-engine/scripts/monthly-pipeline.sh >> logs/cron.log 2>&1
```

---

## Realistic Solo Builder Schedule

You don't need to run everything every day. Here's the minimum:

**Every day** (5 minutes of your time):
- Drop 1 source note about what you built/learned
- Pipeline handles the rest

**Every week** (15 minutes):
- Review the weekly report
- Glance at `approvals/review/` for L3 items
- Approve or reject review queue items

**Every month** (30 minutes):
- Read monthly performance summary
- Adjust content pillars if needed
- Update campaign themes
