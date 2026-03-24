---
name: campaign-calendar-builder
description: Build editorial and campaign calendars for weekly and monthly content planning. Use for scheduling content across channels, planning themes, and coordinating multi-channel campaigns. Triggers on calendar creation, editorial planning, or campaign scheduling requests.
---

# Campaign Calendar Builder

Build structured editorial calendars that plan content across channels.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/calendars/`

## Output Format — Weekly Calendar

```markdown
---
title: "Editorial Calendar — Week of <YYYY-MM-DD>"
date: "YYYY-MM-DD"
type: "weekly-calendar"
theme: "<optional weekly theme>"
---

# Editorial Calendar: Week of <Date>

## Weekly Theme
<Optional: 1 sentence theme if applicable>

| Day | Website | LinkedIn | X | Discord | Other |
|---|---|---|---|---|---|
| Mon | <content> | <content> | <content> | <content> | |
| Tue | <content> | | <content> | | |
| Wed | <content> | <content> | <content> | <content> | |
| Thu | | | <content> | | <newsletter> |
| Fri | <content> | <content> | <content> | <content> | |
| Sat | | | | | |
| Sun | <weekly roundup> | | | | |

## Content Pieces to Produce

1. [ ] <specific content piece> — for <channel>
2. [ ] <specific content piece> — for <channel>
3. [ ] <specific content piece> — for <channel>
4. [ ] <weekly roundup> — for website + newsletter
5. [ ] <video brief> — for HeyGen

## Key Dates / Events
<Any relevant launches, events, or deadlines this week>
```

## Output Format — Monthly Calendar

```markdown
---
title: "Monthly Plan — <Month YYYY>"
date: "YYYY-MM-DD"
type: "monthly-calendar"
theme: "<monthly theme>"
---

# Monthly Plan: <Month>

## Theme
<1-2 sentences on this month's focus>

## Content Pillars This Month
1. <pillar 1>
2. <pillar 2>
3. <pillar 3>

## Weekly Breakdown

### Week 1: <focus>
<Key content to produce>

### Week 2: <focus>
<Key content to produce>

### Week 3: <focus>
<Key content to produce>

### Week 4: <focus>
<Key content to produce>

## Monthly Targets
- Website posts: <target count>
- Social posts: <target count>
- Newsletter issues: <target count>
- Video briefs: <target count>

## Campaign / Launch Calendar
| Date | Event | Content Needed |
|---|---|---|
```

## Rules

1. Be realistic for a solo builder — don't overschedule
2. Daily: 1 website post + 1-2 social posts + 1 Discord update
3. Weekly: 1 newsletter + 1 roundup + 1-2 video briefs
4. Monthly: 1 long-form article + 1 comparison + SEO review
5. Leave buffer days — not every day needs maximum output
6. File naming: `calendar-YYYY-MM-DD-<weekly|monthly>.md`
