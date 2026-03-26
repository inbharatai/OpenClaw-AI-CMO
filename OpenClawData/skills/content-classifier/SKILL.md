> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: content-classifier
description: Classify raw source material into content types, priority levels, and suggested channels. Use when intake-processor feeds new source notes, links, or product updates for classification. Triggers on any content classification request from the intake pipeline.
---

# Content Classifier

Classify incoming source material into structured categories for the AI CMO content pipeline.

## Default Model

`qwen3:8b` — strong at understanding content context and categorization.

## Classification Output Format

For every piece of source material, output EXACTLY this format:

```
type: <content-type>
priority: <high|medium|low>
channels: <comma-separated list>
approval_level: <L1|L2|L3>
summary: <one-line summary of what this content is about>
```

## Content Types

Classify into exactly ONE of these types:

| Type | When to Use |
|---|---|
| `product-update` | Changes to our product, features, releases, patches, improvements |
| `ai-news` | AI industry news, tool launches, market signals, company announcements |
| `educational` | How-to content, tutorials, explainers, guides |
| `comparison` | Tool vs tool, approach vs approach, before/after |
| `founder-log` | Personal builder updates, reflections, lessons, behind-the-scenes |
| `launch` | Major product launches, big announcements |
| `weekly-roundup` | Aggregated weekly content summary |
| `social-post` | Short-form content designed for social channels |
| `newsletter` | Content specifically for email newsletter |
| `video-brief` | Material suited for video format (HeyGen) |
| `image-brief` | Material that needs visual/image treatment |
| `competitor-signal` | Competitor news, moves, comparisons |
| `opinion` | Industry opinions, hot takes, commentary |

## Priority Levels

| Priority | Criteria |
|---|---|
| `high` | Time-sensitive, launch-related, breaking news, urgent product issue |
| `medium` | Regular updates, planned content, industry commentary |
| `low` | Evergreen content, backlog ideas, non-urgent research |

## Channel Suggestions

Suggest channels from this list (comma-separated, most relevant first):

`website-updates, website-insights, website-build-log, website-news, linkedin, x, facebook, instagram, discord, reddit, medium, substack, email, heygen`

Rules for channel suggestion:
- Product updates → website-updates, discord, linkedin, x
- AI news → website-news, x, linkedin, discord
- Educational → website-insights, medium, linkedin, substack
- Comparisons → website-insights, medium, linkedin
- Founder logs → website-build-log, linkedin, x, substack
- Launches → website-updates, discord, linkedin, x, email, reddit
- Social-native → x, linkedin, instagram, facebook
- Video-suitable → heygen

## Approval Level Suggestion

| Level | When |
|---|---|
| `L1` | First-party product data, build logs, simple updates |
| `L2` | News summaries, commentary, educational, comparisons |
| `L3` | Competitor mentions, bold claims, PR-sensitive |

## Rules

1. Always output the exact format above — no extra text, no explanations
2. Choose ONE content type, not multiple
3. Suggest 2-5 channels, ordered by relevance
4. If content is ambiguous, default to type=`social-post`, priority=`medium`, channels=`website-updates, linkedin, x`
5. If content mentions a specific competitor by name, set approval_level to `L3`
6. If content contains unverifiable claims or rumors, set approval_level to `L3`
