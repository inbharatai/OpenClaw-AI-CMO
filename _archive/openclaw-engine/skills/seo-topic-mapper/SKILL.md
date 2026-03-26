---
name: seo-topic-mapper
description: Map SEO keyword opportunities and content topics that can drive organic traffic. Use for content planning, keyword research, and identifying high-value topics. Triggers on SEO research, keyword mapping, or content opportunity identification.
---

# SEO Topic Mapper

Identify high-value content topics based on search intent and keyword opportunities.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/research/`
- Feeds → content-strategy, campaign-calendar-builder, insights-article-writer

## Output Format

```markdown
---
title: "SEO Topic Map — <focus area>"
date: "YYYY-MM-DD"
type: "seo-research"
status: "active"
---

# SEO Topic Map: <Focus Area>

## High-Value Topics

| Topic | Search Intent | Difficulty Est. | Content Type | Priority |
|---|---|---|---|---|
| <topic 1> | <informational/transactional/navigational> | <low/med/high> | <article/comparison/guide> | <high/med/low> |
| <topic 2> | ... | ... | ... | ... |

## Content Clusters

### Cluster: <Main Topic>
- **Pillar:** <main article topic>
- **Supporting:** <3-5 related subtopics>
- **Format:** <best content format>

### Cluster: <Main Topic 2>
- **Pillar:** <main article topic>
- **Supporting:** <3-5 related subtopics>
- **Format:** <best content format>

## Quick Wins

Topics where we can rank with minimal effort:
1. <topic> — <why it's a quick win>
2. <topic> — <why>

## Monthly Content Suggestions

Based on this map, produce these pieces:
1. <specific content piece>
2. <specific content piece>
3. <specific content piece>
```

## Rules

1. Focus on informational intent — we're building authority, not selling directly
2. Suggest specific content pieces, not just keywords
3. Group into clusters for topical authority
4. Prioritize topics where we have genuine expertise
5. Update monthly — SEO landscape changes
6. File naming: `seo-map-YYYY-MM-DD-<focus>.md`
