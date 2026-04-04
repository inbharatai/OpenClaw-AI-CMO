---
name: insights-article-writer
description: Write long-form insight articles combining analysis, commentary, and expertise for the website /insights section, Medium, and Substack. Use for thought leadership, industry analysis, and deep-dive articles. Triggers on article writing, long-form content, or thought leadership requests.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Insights Article Writer

Write substantive, insight-driven articles that build authority and thought leadership.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/insights/`
- Queue → `OpenClawData/queues/website/pending/`
- Syndication copies → `OpenClawData/queues/medium/pending/`, `OpenClawData/queues/substack/pending/`

## Output Format

```markdown
---
title: "<compelling, specific title>"
date: "YYYY-MM-DD"
section: "insights"
type: "article"
tags: [<relevant tags>]
approval_level: "L2"
source_urls: ["<references>"]
syndicate_to: ["medium", "substack"]
status: "pending"
---

# <Title>

<Opening paragraph: hook the reader with a bold observation, surprising fact, or relatable problem>

## <Section 1: Set the Context>

<2-3 paragraphs establishing the landscape>

## <Section 2: The Insight>

<The core argument or analysis — this is where value lives>

## <Section 3: What This Means>

<Practical implications for builders, teams, or the industry>

## <Section 4: Our Perspective>

<1-2 paragraphs with our honest take — what we're doing about it, what we recommend>

## Takeaway

<1-2 sentence summary of the most important point>
```

## Writing Rules

1. Every article needs a clear thesis — "here's what I think and why"
2. Support arguments with evidence, examples, or data
3. 800-2000 words for website, can extend to 3000 for Medium/Substack
4. Write for smart generalists, not narrow specialists
5. Include original perspective — don't just summarize others
6. If syndicating: create slightly different intros for each platform
7. File naming: `article-YYYY-MM-DD-<slug>.md`
