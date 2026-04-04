---
name: carousel-planner
description: Plans multi-slide carousel posts with story arc, slide copy, image direction, and CTA flow
version: 1.0.0
category: content-production
triggers:
  - carousel
  - slide deck
  - multi-slide post
inputs:
  - product (required): Product ID from product-registry.json
  - topic (required): Subject or angle for the carousel
  - platform (required): instagram | linkedin
  - slide_count (optional): Number of slides (default 7, max 10)
  - goal (optional): Campaign objective
outputs:
  - carousel_plan: Structured plan with cover + N slides + CTA
  - image_briefs: Per-slide image direction
  - caption: Platform-appropriate caption text
honest_classification: content-production-tool
---

# Carousel Planner

## Purpose
Plan carousel posts with a clear story arc from hook to CTA. Each slide must earn the swipe to the next.

## Source Material
Before planning, load:
1. `OpenClawData/strategy/product-truth/{product}.md` — safe claims, restricted claims, visual identity
2. `OpenClawData/strategy/brand-knowledge-base.json` — brand colors, visual rules, image types
3. `OpenClawData/strategy/platform-rules/{platform}.md` — format rules, tone, restrictions

## Carousel Structure

### Slide 1: Cover (Hook)
- Bold headline: max 6-8 words
- Must create curiosity or promise value
- Strong visual with brand colors
- No product pitch on cover — earn attention first

### Slides 2-N: Body (Value)
- One idea per slide
- Max 30 words per slide body
- Use ONE of these flow patterns:
  - **Problem → Solution → Proof → CTA** (product-focused)
  - **Myth → Reality → Insight → CTA** (educational)
  - **Step 1 → Step 2 → ... → Result** (how-to)
  - **Before → After → How → CTA** (transformation)
  - **Point 1 → Point 2 → ... → Summary** (listicle)
- Use diagrams/icons for concept slides, screenshots for product slides
- Every slide must have a visual purpose — no text-only walls

### Final Slide: CTA
- Clear call to action
- Product name + website/link
- Single next step for the viewer

## Platform Rules

### Instagram Carousel
- Square (1:1) or 4:5 aspect
- Max 10 slides
- Caption: 150-300 chars, include CTA + 5-10 hashtags
- Hook text on cover must work as thumbnail

### LinkedIn Carousel (PDF)
- Square or 4:5 aspect
- Max 10 slides typical
- Caption: professional tone, 200-500 chars, 3-5 hashtags at end
- First-person narrative in caption preferred

## Output Format

```
CAROUSEL PLAN
─────────────
Product: {product_name}
Platform: {platform}
Flow pattern: {pattern_name}
Total slides: {N}

COVER (Slide 1)
  Headline: {6-8 word hook}
  Visual: {image direction}
  Colors: {brand palette reference}

SLIDE 2
  Title: {short title}
  Body: {max 30 words}
  Visual: {diagram/screenshot/icon direction}

... (repeat for each slide)

CTA SLIDE (Slide N)
  Headline: {action phrase}
  Body: {product name + link}
  Visual: {brand logo + clean background}

CAPTION
  {Platform-appropriate caption text}

IMAGE BRIEF PER SLIDE
  Slide 1: {DALL-E or design brief}
  Slide 2: {brief}
  ...
```

## Quality Checks
- [ ] Every claim is grounded in product truth file
- [ ] No restricted claims used without marking
- [ ] Cover hook creates genuine curiosity (not clickbait)
- [ ] Each slide earns the swipe to the next
- [ ] CTA is relevant and actionable
- [ ] Visual direction matches brand-knowledge-base.json
- [ ] Caption is platform-native (not cross-posted generic)
- [ ] Total text per slide is scannable (< 30 words)
