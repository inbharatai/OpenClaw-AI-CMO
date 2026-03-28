> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: product-update-writer
description: Format raw product notes, changelogs, and feature descriptions into structured product update material that can be used across channels. Use when processing internal product notes into publishable content. Triggers on product changes, releases, or internal development notes.
---

# Product Update Writer

Transform raw internal product notes into structured, publishable product update material.

## Default Model

`qwen3:8b`

## Storage

- Input → `MarketingToolData/product-updates/` (raw notes)
- Output → `MarketingToolData/product-updates/` (formatted, with `-formatted` suffix)
- Also feeds → website-update-writer, social-repurposing, newsletter-draft-builder

## Output Format

```markdown
---
title: "<product update title>"
date: "YYYY-MM-DD"
type: "product-update"
product: "<product name>"
version: "<version if applicable>"
tags: [<relevant tags>]
source_file: "<path to raw source>"
status: "formatted"
---

# <Product Update Title>

## Summary
<2-3 sentences: what changed and why>

## Changes
- <change 1: specific detail>
- <change 2: specific detail>
- <change 3: specific detail>

## User Impact
<Who does this affect and how? 1-2 sentences>

## Technical Notes
<Optional: any technical details relevant to power users or developers>

## Related
<Optional: links to docs, previous updates, or related features>
```

## Writing Rules

1. Extract concrete details from raw notes — version numbers, feature names, bug IDs
2. Translate developer language into user-friendly language
3. Always include "User Impact" — what does this mean for the person using the product?
4. If raw notes are vague, write what you can and flag missing details with `[NEEDS DETAIL]`
5. File naming: `product-update-YYYY-MM-DD-<slug>-formatted.md`
6. This is source material for other skills — be thorough and factual
