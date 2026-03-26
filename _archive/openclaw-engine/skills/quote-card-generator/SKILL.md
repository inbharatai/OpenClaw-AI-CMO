---
name: quote-card-generator
description: Extract powerful quotes and create production-ready quote card packs for social media. Each card has quote text, attribution, visual style, dimensions, and design notes. Triggers on quote cards, shareable quotes, thought leadership visuals, or testimonial graphics.
model: qwen3:8b
---

# Quote Card Generator

Create shareable, scroll-stopping quote cards optimized for each platform.

## Default Model

`qwen3:8b`

## Storage

- Output → `data/image-briefs/quote-cards/`

## Output Format

```markdown
---
title: "<quote card set title>"
date: "YYYY-MM-DD"
type: "quote-card-pack"
cards: <number>
source_content: "<path to source>"
platform_targets: ["instagram", "linkedin", "x"]
style: "<minimal|bold|editorial|dark|gradient>"
status: "ready-for-design"
---

# Quote Card Pack: <Title>

## Design System
- **Dimensions:** 1080x1080 (Instagram/LinkedIn) + 1200x675 (X)
- **Background:** <solid color / gradient / textured / photo with overlay>
- **Quote Font:** <serif for elegance, bold sans-serif for impact>
- **Attribution Font:** <lighter weight, smaller size>
- **Brand Mark:** <small logo bottom-right or watermark>

---

### CARD 1
**Quote:** "<Exact text — max 20 words. Punchy. Shareable.>"
**Attribution:** <— Name, Title/Context>
**Visual Style:** <Background description. Color. Mood.>
**Text Layout:** <Centered / left-aligned / with quotation marks graphic>
**Best For:** <Instagram story / LinkedIn feed / X post>

---

### CARD 2
**Quote:** "<Different angle — max 20 words>"
**Attribution:** <— Source>
**Visual Style:** <Variation of card 1 — same system, different accent>
**Text Layout:** <Layout variation>
**Best For:** <Platform>

---

### CARD 3
**Quote:** "<Strongest, most shareable quote — max 15 words>"
**Attribution:** <— Source>
**Visual Style:** <The hero card — boldest design>
**Text Layout:** <Large text. High contrast.>
**Best For:** <All platforms>

---

## Caption Templates

### Instagram
<Quote context + engagement question. 150 words. Hashtags.>

### LinkedIn
<Professional framing of the quote. Why it matters. 200 words.>

### X
<Sharp one-liner + the quote image. Under 200 chars.>
```

## Quote Types

| Type | Tone | Best Source | Platform |
|------|------|-----------|----------|
| **Founder wisdom** | Authentic, reflective | Build logs, lessons learned | LinkedIn, Instagram |
| **Industry insight** | Authoritative, forward-looking | AI news, research | LinkedIn, X |
| **Customer voice** | Social proof, trust | Testimonials, reviews | Instagram, Facebook |
| **Contrarian take** | Bold, provocative | Opinion pieces, debates | X, LinkedIn |
| **Data highlight** | Factual, surprising | Reports, analytics | LinkedIn, X |
| **Motivational** | Inspiring, personal | Founder journey | Instagram story |

## Card Styles

| Style | Background | Font | Mood | Best For |
|-------|------------|------|------|----------|
| **Minimal** | White/light solid | Clean sans-serif | Professional | LinkedIn, Website |
| **Bold** | Solid dark or bright | Heavy sans-serif | Impact | Instagram, X |
| **Editorial** | Muted tone / texture | Serif + sans-serif | Thoughtful | LinkedIn, Medium |
| **Dark** | Near-black / deep navy | White text, bold | Premium | Instagram, YouTube |
| **Gradient** | Color gradient | White bold text | Modern | Instagram, Stories |

## Writing Rules

1. Max 20 words per quote — if it won't fit on a phone screen in large text, it's too long
2. Every quote must be independently shareable — no context needed
3. Remove filler words ruthlessly: "I think that" → cut. "basically" → cut. "in my opinion" → cut.
4. The quote should make someone stop scrolling and think "I need to save this"
5. Attribution must be real — never fabricate quotes
6. Include platform-specific captions — a quote card without a caption is half-finished
7. File naming: `quote-cards-YYYY-MM-DD-<topic-slug>.md`
