---
name: content-performance-tracker
description: Track what content was published, where, and gather performance notes over time. Use for content auditing, understanding what works, and informing future strategy. Triggers on performance review, content audit, or "what worked" analysis requests.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Content Performance Tracker

Track published content performance and derive insights for future strategy.

## Default Model

`qwen2.5-coder:7b`

## Storage

- Input → `ExportsLogs/posted/`, `OpenClawData/logs/posting-log.json`
- Output → `MarketingToolData/research/`
- Reports → `OpenClawData/reports/`

## Tracking Format

```markdown
---
title: "Content Performance — <period>"
date: "YYYY-MM-DD"
type: "performance-report"
period: "<weekly|monthly>"
---

# Content Performance: <Period>

## Published Content

| Date | Title | Channel | Type | Notes |
|---|---|---|---|---|
| YYYY-MM-DD | <title> | <channel> | <type> | <any engagement notes> |

## Volume Summary

| Channel | Published | Queued | Blocked |
|---|---|---|---|
| website | X | Y | Z |
| discord | X | Y | Z |
| linkedin | X | Y | Z |
| ... | | | |

## Content Type Distribution

| Type | Count | % of Total |
|---|---|---|
| product-update | X | X% |
| ai-news | X | X% |
| educational | X | X% |

## Observations

<What patterns do you see? What content types were most produced? Any gaps?>

## Recommendations

1. <Do more of X>
2. <Do less of Y>
3. <Try Z next period>
```

## Rules

1. Track from actual posted/exported files — don't fabricate numbers
2. Engagement data must be manually added (we can't scrape platform analytics yet)
3. Focus on what we can measure: volume, type distribution, approval rates, block rates
4. Run weekly and monthly
5. File naming: `performance-YYYY-MM-DD-<period>.md`
