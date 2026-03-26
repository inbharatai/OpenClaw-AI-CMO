---
name: image-brief-generator
description: Create structured image briefs for visual content across channels. Use when content needs an accompanying image, graphic, or visual asset. Triggers on image brief requests, Instagram content, or any visual content production.
---

# Image Brief Generator

Create clear, actionable image briefs that a designer or AI image tool can execute.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/image-briefs/`

## Output Format

```markdown
---
title: "<brief title>"
date: "YYYY-MM-DD"
type: "image-brief"
for_channel: "<channel this image supports>"
for_content: "<path to the content this image accompanies>"
dimensions: "<recommended dimensions>"
status: "pending"
---

# Image Brief: <Title>

## Context
<1-2 sentences: what content does this image support?>

## Visual Concept
<Describe the image: what should it show, what mood, what style>

## Required Elements
- <element 1: text overlay, logo, product screenshot, etc.>
- <element 2>
- <element 3>

## Style Notes
- Color palette: <colors or "match brand">
- Style: <clean/minimal, bold/graphic, photo-realistic, illustrated>
- Typography: <if text overlay needed>

## Dimensions
- Primary: <e.g., 1080x1080 for Instagram, 1200x628 for LinkedIn>
- Alt: <secondary size if needed>

## Do NOT Include
- <anything that should be avoided>

## Reference
<Optional: link or description of similar images for inspiration>
```

## Dimension Cheat Sheet

| Channel | Dimensions | Notes |
|---|---|---|
| Instagram post | 1080x1080 | Square, high-res |
| Instagram story | 1080x1920 | Vertical |
| LinkedIn post | 1200x628 | Landscape |
| X post | 1200x675 | Landscape |
| Facebook post | 1200x630 | Landscape |
| Website hero | 1600x900 | Wide |
| Discord embed | 800x400 | Compact |

## Writing Rules

1. Be specific enough that someone unfamiliar with the content could create the image
2. Include the channel and dimensions — don't make the designer guess
3. Always reference the content the image supports
4. File naming: `image-brief-YYYY-MM-DD-<slug>.md`
