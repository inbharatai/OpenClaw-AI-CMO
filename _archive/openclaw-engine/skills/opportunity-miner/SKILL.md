---
name: opportunity-miner
description: Identify business opportunities from market signals, customer feedback, competitor gaps, trends, and data. Use when looking for new revenue streams, underserved markets, content gaps, product ideas, or partnership opportunities. Triggers on "find opportunities", "what are we missing", "market gaps", "where can we grow", "untapped", or any opportunity discovery request.
---

# Opportunity Miner

Discover actionable business opportunities from available signals and data.

## Default Model

`qwen3:8b` — strong at pattern recognition, strategic reasoning, and creative connection-making.

## Storage

- Opportunity reports → `MarketingToolData/research/`
- High-value findings → `OpenClawData/memory/decisions-log.md`

## Opportunity Sources

Mine these areas for opportunities:

| Source | What to Look For |
|---|---|
| **Competitor gaps** | What are competitors NOT offering? |
| **Customer questions** | What do people keep asking about? |
| **Content gaps** | What topics have no good content? |
| **Market trends** | What's growing that we can serve? |
| **Failed attempts** | What have others tried and failed? Why? |
| **Adjacent markets** | Who else has our audience's attention? |
| **Seasonal patterns** | What recurring needs can we prepare for? |

## Opportunity Assessment Framework

For each opportunity found:

```markdown
### Opportunity: <name>

**Type:** Content | Product | Partnership | Market | Service
**Confidence:** High | Medium | Low
**Effort:** High | Medium | Low
**Potential Impact:** High | Medium | Low

**Description:** <what is this opportunity>
**Evidence:** <what signals point to this>
**Action required:** <what we'd need to do>
**Risk:** <what could go wrong>
**Priority score:** <Impact × Confidence ÷ Effort> (H/M/L)
```

## Prioritization

Rank opportunities by:
1. **High impact + High confidence + Low effort** → Do immediately
2. **High impact + High confidence + High effort** → Plan carefully
3. **High impact + Low confidence** → Research more first
4. **Low impact** → Backlog or ignore

## Rules

1. **Evidence-based only** — every opportunity needs at least one supporting signal
2. **Be realistic about effort** — "easy" opportunities rarely are
3. **Prioritize ruthlessly** — 3 great opportunities > 20 mediocre ones
4. **Check for alignment** — does this fit our brand, audience, and capabilities?
5. Save to `MarketingToolData/research/opportunities-<date>.md`
