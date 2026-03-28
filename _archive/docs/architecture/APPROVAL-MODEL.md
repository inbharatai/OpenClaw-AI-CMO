# Approval Model

## Overview

Every piece of content passes through a **4-level policy engine** before it can reach any external platform. This prevents spam, inaccurate claims, and brand damage.

---

## The 4 Levels

### Level 1 — Auto-Approve
**Content is posted automatically with no human review.**

Conditions:
- All risk dimensions score below 30/100
- Weighted average below 25/100
- Content type is low-risk

Content types that qualify:
- Product update summaries (from your own source material)
- Build-in-public logs
- Founder updates
- Discord community announcements
- Simple website updates
- Newsletter snippets derived from already-approved content
- Repurposed content from approved sources

### Level 2 — Score-Gated Auto-Approve
**Content is auto-approved IF it passes scoring thresholds.**

Conditions:
- Weighted average between 25-55
- No single dimension above 60
- Evidence attached
- Brand voice score above minimum

Content types:
- AI news summaries
- Tool comparison posts
- Industry commentary
- Educational posts
- SEO-targeted content

### Level 3 — Review Queue
**Content is held for human review before posting.**

Conditions:
- Any dimension above 60
- Weighted average above 55
- Content flagged by policy rules

Content types:
- Bold or unverifiable claims
- PR-sensitive announcements
- Competitor criticism
- Aggressive sales language
- Uncertain news or rumors
- Platform-sensitive outreach

### Level 4 — Block
**Content is rejected and not posted.**

Conditions:
- Unverifiable claims with no evidence
- Policy violations detected
- Personal/private data detected
- Mass spam patterns
- Content without any source attribution
- Actions targeting non-approved channels

---

## Scoring Dimensions

| Dimension | Weight | What It Measures |
|-----------|--------|-----------------|
| Source Confidence | 25% | Is the source first-party or verified? |
| Claim Sensitivity | 25% | Are there bold, legal, or risky claims? |
| Brand Voice | 15% | Does it match your established tone? |
| Data Safety | 15% | Contains personal data or credentials? |
| Duplication | 10% | Similar to content published recently? |
| Platform Risk | 10% | Could this violate platform rules? |

## Scoring Formula

```
weighted_score = (source * 0.25) + (claims * 0.25) + (voice * 0.15) +
                 (data * 0.15) + (duplication * 0.10) + (platform * 0.10)
```

## Configuration

All rules are in `openclaw-engine/policies/approval-rules.json`. You can adjust:
- Threshold values per level
- Dimension weights
- Content type classifications
- Platform-specific overrides
