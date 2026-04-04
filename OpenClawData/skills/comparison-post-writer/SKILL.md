---
name: comparison-post-writer
description: Write tool comparison and "X vs Y" posts for the website /insights section. Use when comparing tools, approaches, frameworks, or products. Triggers on comparison requests, "versus" posts, or tool evaluation content.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Comparison Post Writer

Write balanced, useful comparison posts that help readers make informed decisions.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/comparison-posts/` and `MarketingToolData/insights/`
- Queue → `OpenClawData/queues/website/pending/`

## Output Format

```markdown
---
title: "<Tool A> vs <Tool B>: <specific angle>"
date: "YYYY-MM-DD"
section: "insights"
type: "comparison"
tags: [<relevant tags>]
approval_level: "L2"
source_urls: ["<sources used>"]
status: "pending"
---

# <Tool A> vs <Tool B>: <Angle>

**TL;DR:** <1-2 sentence recommendation based on use case>

## What We're Comparing

<1-2 sentences setting context — why this comparison matters>

## <Tool A>

**Best for:** <use case>
**Strengths:**
- <strength 1>
- <strength 2>

**Limitations:**
- <limitation 1>
- <limitation 2>

## <Tool B>

**Best for:** <use case>
**Strengths:**
- <strength 1>
- <strength 2>

**Limitations:**
- <limitation 1>
- <limitation 2>

## Side-by-Side

| Feature | <Tool A> | <Tool B> |
|---|---|---|
| <feature 1> | <detail> | <detail> |
| <feature 2> | <detail> | <detail> |
| <feature 3> | <detail> | <detail> |
| Pricing | <detail> | <detail> |

## Our Take

<2-3 sentences: honest recommendation from a builder perspective>

## When to Choose What

- **Choose <Tool A> if:** <specific scenario>
- **Choose <Tool B> if:** <specific scenario>
```

## Writing Rules

1. Always compare on specific criteria — not vague "which is better"
2. Be fair to both sides — no hit pieces disguised as comparisons
3. If we use one of these tools ourselves, disclose it
4. Cite sources for claims about features and pricing
5. Maximum 1000 words
6. If comparing a competitor to our own product, set approval_level to L3
7. File naming: `comparison-YYYY-MM-DD-<toolA>-vs-<toolB>.md`
