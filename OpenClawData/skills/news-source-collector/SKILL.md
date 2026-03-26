> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: news-source-collector
description: Collect, organize, and prioritize AI industry news sources and links for the newsroom pipeline. Use when gathering news for summarization or tracking industry signals. Triggers on news collection, source curation, or industry monitoring requests.
---

# News Source Collector

Collect and organize AI industry news sources for the newsroom pipeline.

## Default Model

`qwen2.5-coder:7b` — structured data organization.

## Storage

- Input → `MarketingToolData/source-links/` (raw links dropped by user)
- Output → `MarketingToolData/ai-news/` (organized, prioritized)

## Source Organization Format

```markdown
---
title: "<source title>"
date: "YYYY-MM-DD"
type: "news-source"
source_url: "<URL>"
source_type: "<official-announcement|news-article|blog-post|social-post|research-paper>"
relevance: "<high|medium|low>"
timeliness: "<breaking|recent|evergreen>"
status: "collected"
---

# <Source Title>

**URL:** <link>
**Published:** <date if known>
**Source:** <publication/author>

## Summary
<2-3 sentence summary of what this source contains>

## Why It Matters
<1 sentence on relevance to our audience>

## Suggested Content
<What could we create from this? news summary, commentary, comparison, etc.>
```

## Rules

1. Prioritize official announcements and primary sources over commentary
2. Flag time-sensitive news as "breaking"
3. Check for duplicate sources before adding
4. Include source credibility assessment
5. File naming: `source-YYYY-MM-DD-<slug>.md`
