> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: website-update-writer
description: Write website /updates posts from product updates, changelogs, and feature notes. Use when producing content for the website updates section. Triggers on product releases, feature announcements, patch notes, or any content destined for /updates.
---

# Website Update Writer

Write clear, concise product update posts for the website /updates section.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/website-posts/`
- Queue → `OpenClawData/queues/website/pending/`

## Output Format

Every update MUST use this template:

```markdown
---
title: "<clear, specific title>"
date: "YYYY-MM-DD"
section: "updates"
type: "<product-update|feature-release|patch-note|changelog>"
tags: [<relevant tags>]
approval_level: "L1"
source_file: "<path to source material>"
status: "pending"
---

# <Title>

<1-2 sentence summary of what changed and why it matters to users>

## What's New

<Bullet points of changes, features, or fixes>

## Why It Matters

<1-2 sentences on user impact>

## What's Next

<Optional: 1 sentence on upcoming related work>
```

## Writing Rules

1. Lead with what changed, not with background context
2. Maximum 500 words, aim for 200-300
3. Use bullet points for multiple changes
4. No marketing hype — factual, helpful, direct
5. Include specific details: version numbers, feature names, metrics if available
6. Write for users who want to know what's new, not for executives
7. Every post must reference its source material in frontmatter
8. File naming: `update-YYYY-MM-DD-<slug>.md`

## Brand Voice Check

Before finalizing, verify:
- [ ] Active voice
- [ ] No banned phrases (check policies/brand-voice-rules.json)
- [ ] Leads with value
- [ ] Specific, not vague
- [ ] Under 500 words
