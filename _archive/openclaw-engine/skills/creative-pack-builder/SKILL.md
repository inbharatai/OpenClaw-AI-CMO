---
name: creative-pack-builder
description: Generate complete multi-asset creative packs from one piece of content. Produces carousel, quote cards, thumbnails, story frames, image prompts, and captions — all from one source. Triggers on "create a creative pack", "all visuals for this content", "full visual set", or any request for a complete visual content package.
model: qwen3:8b
---

# Creative Pack Builder

One content idea → complete multi-format visual asset pack.

This is the top-level visual skill. It orchestrates all visual formats into one cohesive output.

## Default Model

`qwen3:8b`

## Storage

- Output → `data/image-briefs/creative-packs/`

## When To Use

Use this when a piece of content needs the FULL visual treatment:
- A product launch needs carousel + quote cards + thumbnail + captions
- A weekly post needs Instagram carousel + LinkedIn image + X card
- A campaign needs a complete visual kit

## Output Format

```markdown
---
title: "Creative Pack — <Topic>"
date: "YYYY-MM-DD"
type: "creative-pack"
source_content: "<path or description>"
campaign: "<campaign name>"
platforms: ["instagram", "linkedin", "x", "youtube", "discord"]
assets_included:
  - carousel (6 slides)
  - quote_cards (3 cards)
  - thumbnail (3 options)
  - story_frames (3 frames)
  - image_prompts (3 prompts)
  - captions (per platform)
status: "ready-for-design"
---

# Creative Pack: <Topic>

## Brand/Design System
- **Primary Color:** <hex or name>
- **Accent Color:** <hex or name>
- **Fonts:** <heading font> / <body font>
- **Style:** <minimal/bold/editorial/dark>
- **Logo Usage:** <bottom-right watermark at 30% opacity>

---

## 1. CAROUSEL (Instagram/LinkedIn)

### Design: 1080x1350, <style>

**Slide 1 — Hook**
- Text: "<max 6 words>"
- Subtext: "<1 line>"
- Visual: <description>

**Slide 2 — Setup**
- Text: "<headline>"
- Body: "<2 sentences>"
- Visual: <description>

**Slide 3 — Point 1**
- Text: "<key point>"
- Body: "<1-2 sentences>"
- Icon: <description>

**Slide 4 — Point 2**
- Text: "<key point>"
- Body: "<1-2 sentences>"
- Icon: <description>

**Slide 5 — Key Insight**
- Text: "<strongest point>"
- Body: "<1-2 sentences>"
- Visual: <highlight treatment>

**Slide 6 — CTA**
- Text: "<action statement>"
- Subtext: "<what they get>"
- Visual: <brand colors + logo>

---

## 2. QUOTE CARDS (3 cards)

### Design: 1080x1080, <style>

**Card A:** "<max 20 word quote>" — <attribution>
  Visual: <background + layout>

**Card B:** "<different angle quote>" — <attribution>
  Visual: <variation>

**Card C:** "<strongest quote>" — <attribution>
  Visual: <hero card — boldest>

---

## 3. THUMBNAIL (3 options)

### Design: 1280x720 (YouTube) / 1200x628 (article)

**Option A — Curiosity:** "<5 word headline>" + "<subtitle>"
  Visual: <face/subject + background>

**Option B — Benefit:** "<value headline>" + "<subtitle>"
  Visual: <different approach>

**Option C — Contrast:** "<X vs Y>" or "<before/after>"
  Visual: <split layout>

---

## 4. STORY FRAMES (Instagram/LinkedIn Stories)

### Design: 1080x1920 (vertical)

**Frame 1 — Teaser**
- Text: "<1 bold statement to hook>"
- Visual: <background + text centered>
- Sticker/Element: <poll, question, or swipe-up prompt>

**Frame 2 — Key Point**
- Text: "<core message>"
- Visual: <supporting graphic>

**Frame 3 — CTA**
- Text: "<action>"
- Visual: <link sticker / swipe prompt / "see post">

---

## 5. AI IMAGE PROMPTS (for Midjourney/DALL-E/Flux)

**Prompt 1:** <Detailed 1-2 sentence image generation prompt. Style, subject, mood, colors, composition.>

**Prompt 2:** <Different angle/approach. Same topic.>

**Prompt 3:** <Abstract/conceptual take. More artistic.>

---

## 6. CAPTIONS (Per Platform)

### Instagram
<150-300 words. Story-driven. Emoji-friendly. 15-20 hashtags at end.>

### LinkedIn
<200-400 words. Professional. Insight-first. 3-5 hashtags.>

### X / Twitter
<Under 280 chars. Sharp. Punchy. Maybe a thread hook.>

### Discord
<50-100 words. Community-friendly. Single emoji prefix.>

### YouTube (description)
<100-200 words. Keywords. Timestamps if applicable.>
```

## Writing Rules

1. One source idea → 6 asset types. That's the whole point.
2. Everything must look like it came from the same campaign — consistent colors, fonts, style.
3. Each asset must work STANDALONE — don't assume people see all of them.
4. Carousel hook > everything else. If slide 1 fails, the whole pack fails.
5. Quote cards must be independently shareable — screenshot-worthy.
6. Thumbnails must be readable at phone-sidebar size.
7. Story frames must work in 3-second attention spans.
8. Image prompts must be specific enough to produce usable results on first try.
9. Captions must feel platform-native, not copy-pasted across channels.
10. File naming: `creative-pack-YYYY-MM-DD-<topic-slug>.md`
