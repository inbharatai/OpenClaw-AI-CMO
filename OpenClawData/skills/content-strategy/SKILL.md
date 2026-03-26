> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: content-strategy
description: Develop content strategies for social media, blogs, email, and marketing campaigns. Use when the user needs a content plan, pillar strategy, audience targeting, messaging framework, or channel strategy. Triggers on "content strategy", "what should I post about", "content pillars", "messaging framework", or any strategic content planning request.
---

# Content Strategy

Develop practical, actionable content strategies rooted in business goals.

## Default Model

`qwen3:8b` — strong at strategic reasoning, audience analysis, and structured planning.

## Storage

- Strategy docs → `MarketingToolData/campaigns/`
- Research inputs → `MarketingToolData/research/`

## Strategy Framework

When building a content strategy, always cover these 6 elements:

### 1. Goal Alignment
- What business goal does this content serve? (awareness, leads, sales, retention)
- What metric will indicate success?

### 2. Audience Definition
- Who is the primary audience?
- What are their pain points, desires, and language patterns?
- Where do they spend time online?

### 3. Content Pillars (3-5 max)
- Define recurring themes that map to audience needs
- Each pillar should connect to a business objective
- Example: "Behind the scenes", "Customer results", "How-to tutorials", "Industry insights"

### 4. Channel Strategy
- Which platforms? (Instagram, LinkedIn, X, TikTok, email, blog)
- What format works best per channel? (carousel, reel, thread, newsletter)
- Posting frequency per channel

### 5. Content Mix
- Ratio of content types: educational / entertaining / promotional / community
- Recommended: 40% educational, 30% entertaining, 20% community, 10% promotional

### 6. Measurement
- KPIs per channel
- Review cadence (weekly/monthly)
- What to do if a pillar underperforms

## Output Format

Save strategies as:
```
MarketingToolData/campaigns/strategy-<YYYY-MM-DD>-<name>.md
```

## Rules

1. Always start by asking about the business goal — no strategy without a goal
2. Keep strategies to 1-2 pages max — actionable, not academic
3. Reference brand-voice memory if it exists: check `OpenClawData/memory/brand-voice.md`
4. Reference campaign preferences if they exist: check `OpenClawData/memory/campaign-preferences.md`
