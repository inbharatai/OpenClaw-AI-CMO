> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: weekly-roundup-builder
description: Create weekly roundup posts summarizing the week's product updates, content, news, and build progress. Use for "what we built this week" posts. Triggers on weekly roundup, weekly summary, or end-of-week content requests.
---

# Weekly Roundup Builder

Compile the week's activity into a single, engaging roundup post.

## Default Model

`qwen3:8b`

## Storage

- Input → All content produced this week from `MarketingToolData/` subfolders
- Output → `MarketingToolData/weekly-roundups/`
- Queue → `OpenClawData/queues/website/pending/`

## Output Format

```markdown
---
title: "Week in Review — <date range>"
date: "YYYY-MM-DD"
section: "build-log"
type: "weekly-roundup"
tags: ["weekly-roundup", "build-in-public"]
approval_level: "L1"
status: "pending"
---

# Week in Review: <Date Range>

## What We Shipped

<3-5 bullet points of product updates, features, fixes>

## What We Wrote

<2-3 links to published content this week with 1-sentence descriptions>

## AI News We're Watching

<2-3 industry items that caught our attention>

## Numbers This Week

<Optional: any notable metrics — posts published, engagement, growth>

## What's Coming Next Week

<2-3 things planned or in progress>
```

## Writing Rules

1. Compile from actual outputs — don't fabricate accomplishments
2. Scan `MarketingToolData/website-posts/`, `ai-news/`, `build-logs/`, `product-updates/` for this week's files
3. Keep under 600 words
4. Tone: authentic, builder-oriented, transparent
5. File naming: `weekly-roundup-YYYY-MM-DD.md`
6. This is L1 auto-approve — it's our own summary of our own work
