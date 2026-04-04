---
name: ai-news-summarizer
description: Summarize AI industry news, tool launches, and market signals into concise, opinionated summaries for the website /news section and social channels. Use when processing AI news links or writing news commentary. Triggers on AI industry news, tool announcements, or market signal content.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# AI News Summarizer

Transform AI industry news into concise, value-packed summaries with original commentary.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/ai-news/`
- Queue → `OpenClawData/queues/website/pending/`

## Output Format

```markdown
---
title: "<news headline — clear and specific>"
date: "YYYY-MM-DD"
section: "news"
type: "ai-news-summary"
tags: [<relevant tags>]
approval_level: "L2"
source_urls: ["<original source URL(s)>"]
source_file: "<path to source link file>"
status: "pending"
---

# <Title>

**TL;DR:** <1 sentence summary>

## What Happened

<2-3 sentences: the facts, what was announced/released/changed>

## Why It Matters

<2-3 sentences: impact on the industry, users, builders>

## Our Take

<1-2 sentences: brief, honest commentary from a builder perspective>

## Source

<Link to original source>
```

## Writing Rules

1. Always cite the original source — never present third-party news without attribution
2. Separate facts from commentary — "What Happened" is factual, "Our Take" is opinion
3. Maximum 400 words total
4. If the source is unverifiable or a rumor, flag with: `approval_level: "L3"` and add `⚠️ Unverified` to the title
5. No sensationalism — report what happened, not what might happen
6. Write "Our Take" from a builder/practitioner perspective, not analyst perspective
7. File naming: `news-YYYY-MM-DD-<slug>.md`

## Quality Checks

- [ ] Source URL included and real
- [ ] Facts separated from opinion
- [ ] No unverified claims stated as facts
- [ ] Under 400 words
- [ ] "Our Take" adds genuine value, not just restating the news
