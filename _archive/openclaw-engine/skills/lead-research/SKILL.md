---
name: lead-research
description: Research potential leads, partners, collaborators, and target accounts. Use when building prospect lists, researching companies or individuals, preparing for outreach, or qualifying leads. Triggers on "research this lead", "find prospects", "who should we reach out to", "lead list", "prospect research", or any lead/partnership research request.
---

# Lead Research

Research and qualify potential leads, partners, and collaboration targets.

## Default Model

`qwen3:8b` — strong at research synthesis, profile building, and strategic assessment.

## Storage

- Lead profiles → `MarketingToolData/research/`
- Outreach templates → `MarketingToolData/scripts/`

## Lead Research Template

```markdown
# Lead Profile: <Name / Company>

**Date Researched:** YYYY-MM-DD
**Type:** Prospect | Partner | Collaborator | Influencer
**Priority:** High | Medium | Low

## Basic Info
- **Name:** <full name>
- **Company:** <company name>
- **Role:** <their role/title>
- **Location:** <city/country>
- **Website:** <URL>
- **Social:** <relevant profiles>

## Relevance
- **Why this lead:** <why they matter to us>
- **Overlap:** <what we have in common>
- **Their audience:** <who they reach>
- **Their needs:** <what they might need from us>

## Qualification
- **Budget fit:** Yes | No | Unknown
- **Decision maker:** Yes | No | Unknown
- **Timeline:** Active | Future | Unknown
- **Pain point match:** <does our offering solve their problem?>

## Outreach Angle
- **Best channel:** Email | LinkedIn | X | Intro | Event
- **Talking point:** <what to lead with>
- **Value proposition:** <what we offer them specifically>
- **Ask:** <what we want from the conversation>

## Notes
<any additional context>
```

## Lead List Format

For batch research:

```markdown
| Name | Company | Type | Priority | Best Channel | Status |
|---|---|---|---|---|---|
| <name> | <company> | Prospect | High | Email | Not contacted |
```

## Rules

1. **Quality over quantity** — 10 well-researched leads > 100 names
2. **Always include an outreach angle** — research without a plan is wasted
3. **Respect privacy** — use publicly available information only
4. **Check for existing relationships** — don't duplicate outreach
5. **Update status** — track contacted / responded / converted
6. Save to `MarketingToolData/research/leads-<date>-<context>.md`
