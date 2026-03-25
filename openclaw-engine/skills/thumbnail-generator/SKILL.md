---
name: thumbnail-generator
description: Create YouTube thumbnail text packs, article cover images, and social media preview graphics. Each thumbnail has headline text, subtitle, visual direction, and platform-specific sizing. Triggers on thumbnail, cover image, preview graphic, og-image, or featured image requests.
model: qwen3:8b
---

# Thumbnail & Cover Image Generator

Create high-converting thumbnail and cover image text packs.

## Default Model

`qwen3:8b`

## Storage

- Output → `data/image-briefs/thumbnails/`

## Output Format

```markdown
---
title: "<thumbnail set title>"
date: "YYYY-MM-DD"
type: "thumbnail-pack"
variants: <number>
for_content: "<what content this thumbnail supports>"
platform: "<youtube|article|linkedin|og-image>"
status: "ready-for-design"
---

# Thumbnail Pack: <Title>

## Context
<1 sentence — what video/article/post is this thumbnail for?>

---

### OPTION A — CURIOSITY
**Headline:** <Max 5 words — BIG, BOLD>
**Subtitle:** <Max 8 words — smaller, supporting>
**Face/Subject:** <Describe what the main visual element should be>
**Background:** <Color/gradient/scene>
**Emotion:** <What should the viewer FEEL?>
**Layout:** <Text position: left-third / centered / split>
**Dimensions:** 1280x720 (YouTube) | 1200x628 (article) | 1200x675 (X/LinkedIn)

### OPTION B — BENEFIT
**Headline:** <Value proposition — what they'll learn/get>
**Subtitle:** <Supporting context>
**Face/Subject:** <Visual element>
**Background:** <Different from A>
**Emotion:** <Different angle>
**Layout:** <Layout>

### OPTION C — CONTRAST
**Headline:** <Before vs After / Old vs New / Problem vs Solution>
**Subtitle:** <Context>
**Split Layout:** <Left side: problem/before. Right side: solution/after>
**Background:** <Two-tone or split>
**Emotion:** <Transformation>
```

## Thumbnail Psychology

The 3 things that make someone click a thumbnail:
1. **Curiosity gap** — they need to know the answer
2. **Emotional trigger** — surprise, fear of missing out, excitement
3. **Clear value promise** — they know what they'll get

## Headline Formulas That Work

| Formula | Example | Best For |
|---------|---------|----------|
| Number + Outcome | "5 Tools That 10x Growth" | Educational |
| This vs That | "React vs Next.js" | Comparison |
| Question | "Is AI Replacing Devs?" | Curiosity |
| Bold Claim | "I Built an AI CMO" | Story |
| Warning | "Stop Using X" | Contrarian |
| Result | "0 to 10K in 30 Days" | Case study |

## Platform Dimensions

| Platform | Size | Notes |
|----------|------|-------|
| YouTube thumbnail | 1280x720 | Most critical — 90% of click decision |
| YouTube Short cover | 1080x1920 | Vertical, auto-selected from video |
| Article OG image | 1200x628 | Shows in social shares |
| LinkedIn article | 1200x628 | Same as OG |
| X card image | 1200x675 | Slightly taller |
| Instagram preview | 1080x1080 | First frame or cover |

## Writing Rules

1. Max 5 words for main headline — if it won't read at phone-thumbnail size, it's too long
2. Always provide 3 options (A/B/C) — never just one, because the first idea is rarely the best
3. Include the emotional angle — thumbnails are feelings, not information
4. Text must be readable at 150px wide (the size YouTube shows in sidebar)
5. High contrast always — light text on dark, or dark text on light, never medium-on-medium
6. File naming: `thumbnail-YYYY-MM-DD-<content-slug>.md`
