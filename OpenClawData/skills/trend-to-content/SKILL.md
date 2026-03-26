> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: trend-to-content
description: Convert trending topics, news, and cultural moments into timely content ideas. Use when the user wants to create content around trends, current events, viral moments, or industry news. Triggers on "trending", "what's happening", "newsjack", "turn this trend into content", "content from this news", or any trend-based content creation request.
---

# Trend-to-Content

Turn trending topics and current events into relevant, on-brand content quickly.

## Default Model

`qwen3:8b` — strong at creative adaptation, cultural context, and rapid ideation.

## Storage

- Trend-based content → `MarketingToolData/repurposed/`
- Research → `MarketingToolData/research/`

## Trend-to-Content Process

### 1. Identify the Trend
- What is happening? (one sentence)
- Why is it trending? (cultural moment, news, viral content, seasonal)
- How long will it be relevant? (hours, days, weeks)

### 2. Relevance Check
Answer these before creating content:
- Does this trend connect to our brand/industry?
- Can we add genuine value or perspective?
- Is there a risk of appearing tone-deaf?
- Will this still matter when we publish?

**If any answer is "no" → skip this trend.**

### 3. Content Angle
Pick one angle:
- **Educational:** Explain the trend to our audience
- **Opinion:** Share a unique perspective on the trend
- **Humor:** Create a light, relatable take
- **Application:** Show how the trend applies to our audience's life/work
- **Counter-narrative:** Respectfully challenge the trend

### 4. Speed-to-Market Format
For timely content, use fast formats:
- Instagram Story (create in <10 min)
- X/Twitter post or thread (create in <5 min)
- LinkedIn hot take (create in <15 min)
- Short-form video script (create in <20 min)

## Timeliness Rules

| Trend Lifespan | Action Window | Best Format |
|---|---|---|
| Hours (viral moment) | Post within 2-4 hours | Story, tweet |
| Days (news cycle) | Post within 24 hours | Post, thread, reel |
| Weeks (cultural shift) | Post within 1 week | Blog, carousel, video |
| Ongoing (industry trend) | Anytime | Long-form, series |

## Safety Rules

1. **Never exploit tragedies or sensitive events for marketing**
2. **Check brand voice** — trend content must still sound like the brand
3. **When in doubt, don't post** — missing a trend is better than a bad take
4. **No political content** unless the brand explicitly operates in that space
5. **Credit sources** — if referencing someone else's content, acknowledge it

## Output

Save trend content with source reference:
```
MarketingToolData/repurposed/trend-<YYYY-MM-DD>-<brief-slug>.md
```
