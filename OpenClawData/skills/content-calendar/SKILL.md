> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: content-calendar
description: Create and manage content calendars for social media, blogs, email, and marketing campaigns. Use when planning what to post, when to post, and organizing content across platforms and dates. Triggers on "content calendar", "posting schedule", "plan my posts", "weekly schedule", "monthly calendar", or any content scheduling request.
---

# Content Calendar

Plan and organize content across platforms, dates, and formats.

## Default Model

`qwen3:8b` — strong at structured planning and scheduling logic.

## Storage

- Calendars → `MarketingToolData/calendars/`

## Calendar Format

Save calendars as Markdown tables:

```markdown
# Content Calendar: <Month Year>

**Platforms:** <list>
**Content pillars:** <list>
**Posting frequency:** <per platform>

| Date | Day | Platform | Pillar | Format | Topic/Hook | Status |
|---|---|---|---|---|---|---|
| 03/24 | Mon | Instagram | Educational | Carousel | 5 tips for... | Draft |
| 03/24 | Mon | LinkedIn | Insights | Text post | Industry trend analysis | Planned |
| 03/25 | Tue | X | Community | Thread | AMA about... | Planned |
| 03/26 | Wed | Instagram | Entertaining | Reel | Behind the scenes | Idea |
| 03/27 | Thu | Email | Promotional | Newsletter | Weekly roundup | Planned |
| 03/28 | Fri | Instagram | Social proof | Story | Customer spotlight | Idea |
```

## Status Values

- **Idea** — concept only, not fleshed out
- **Planned** — topic and format decided
- **Draft** — content written, not reviewed
- **Ready** — reviewed and approved for posting
- **Posted** — live
- **Skipped** — decided not to post

## Planning Rules

1. **Check content-strategy first** — calendar must align with active strategy
2. **Balance pillars** — no single pillar should dominate the week
3. **Platform frequency defaults:**
   - Instagram: 3-5x/week
   - LinkedIn: 2-3x/week
   - X/Twitter: 5-7x/week
   - Email: 1-2x/week
   - Blog: 1-2x/month
4. **Include hooks** — every entry needs at least a topic and opening hook idea
5. **Leave room for reactive content** — don't fill 100% of slots

## Calendar File Naming

```
MarketingToolData/calendars/calendar-<YYYY-MM>-<platform-or-all>.md
```

## Integration Points

- Read `OpenClawData/memory/campaign-preferences.md` for recurring preferences
- Read `MarketingToolData/campaigns/` for active campaign themes
- After creating a calendar, offer to generate drafts for the first week
