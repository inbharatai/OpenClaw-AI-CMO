---
name: competitor-monitor
description: Track and analyze competitor activity including content, positioning, offers, and strategy. Use when the user wants to monitor competitors, compare strategies, analyze competitor content, or identify competitive advantages. Triggers on "competitor", "competition", "what are they doing", "competitive analysis", "compare with", or any competitor-related research request.
---

# Competitor Monitor

Track competitor activity and extract actionable intelligence.

## Default Model

`qwen3:8b` — strong at strategic analysis, pattern recognition, and comparative reasoning.

## Storage

- Competitor profiles → `MarketingToolData/research/`
- Insights → `OpenClawData/memory/lessons-learned.md`

## Competitor Profile Template

For each competitor, maintain a profile:

```markdown
# Competitor Profile: <Name>

**Last Updated:** YYYY-MM-DD
**Website:** <URL>
**Category:** Direct | Indirect | Aspirational

## Positioning
- **Tagline:** <their main message>
- **Target audience:** <who they serve>
- **Price point:** <pricing tier>
- **Unique claim:** <what they say makes them different>

## Content Strategy
- **Platforms active on:** <list>
- **Posting frequency:** <estimate>
- **Content types:** <what formats they use>
- **Tone:** <how they sound>
- **Top-performing content:** <what seems to get engagement>

## Strengths
- <what they do well>

## Weaknesses
- <where they fall short>

## Opportunities for Us
- <gaps we can exploit>

## Recent Moves
- [YYYY-MM-DD] <what they did>
```

## Competitive Analysis Framework

When comparing multiple competitors:

```markdown
# Competitive Analysis: <Category/Market>

| Factor | Us | Competitor A | Competitor B |
|---|---|---|---|
| Positioning | | | |
| Price | | | |
| Content quality | | | |
| Audience size | | | |
| Unique strength | | | |
| Key weakness | | | |
```

## Rules

1. **Observe, don't copy** — the goal is intelligence, not imitation
2. **Focus on gaps and opportunities** — what are they NOT doing that we can?
3. **Update regularly** — stale competitor data is useless
4. **Be honest about their strengths** — denying competitor advantages doesn't help
5. Save profiles to `MarketingToolData/research/competitor-<name>.md`
