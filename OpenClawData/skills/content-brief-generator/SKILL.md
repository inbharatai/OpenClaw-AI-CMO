---
name: content-brief-generator
description: Creates structured content briefs before any content is generated — ensures product, audience, platform, goal are identified
version: 1.0.0
category: content-planning
triggers:
  - content brief
  - plan content
  - brief for
inputs:
  - signal (required): News item, topic, product update, or content idea
  - product (optional): Product ID if known
outputs:
  - content_brief: Structured brief ready for channel-post-generator or carousel-planner
honest_classification: content-planning-tool
---

# Content Brief Generator

## Purpose
Before any content is written or image is generated, this skill creates a structured brief that answers: WHO is this for, WHAT product does it serve, WHERE will it be posted, WHY should the audience care, and WHAT should they do next.

No content should be generated without a brief. If a brief field is unknown, it must be marked as unknown — not guessed.

## Required Brief Fields

```
CONTENT BRIEF
─────────────
Signal:       {what triggered this content — news, update, insight, trend}
Product:      {product ID from product-registry.json, or "ecosystem" for brand-level}
Audience:     {primary target: students, developers, founders, businesses, citizens}
Platform:     {linkedin | x | instagram | discord | reddit | website | newsletter}
Content Type: {product-update | thought-leadership | educational | news-reaction | behind-the-build | comparison | how-it-works | launch | demo}
Campaign Goal:{engagement | authority | traffic | community | awareness | leads}
CTA:          {specific action: visit URL, follow, try product, join community}
Source URLs:   {URLs used as source material — must be real, verified}
Brand Tone:   {from brand-voice-rules.json — e.g., "confident, factual, helpful"}
Image Needed: {yes/no, and if yes: static_post | carousel_cover | infographic | ui_mockup}
Confidence:   {approved | safe-inference | needs-verification}
```

## Decision Logic

### Product Selection
- If content is about a specific product feature/update → that product
- If content is about India AI ecosystem generally → "inbharat" (umbrella)
- If content is about building/founding → "inbharat" with founder angle
- If product is unclear → mark "unknown" and flag for review

### Platform Selection
- Breaking news / quick reaction → X
- Deep insight / professional commentary → LinkedIn
- Visual explainer / product demo → Instagram
- Community update / launch note → Discord
- Helpful discussion → Reddit (L3 approval required)
- Long-form / SEO → website/blog

### Content Type Selection
- New feature or release → product-update
- Opinion on industry trend → thought-leadership
- How something works → educational
- Responding to news → news-reaction
- Sharing build progress → behind-the-build
- Comparing approaches → comparison

### Confidence Levels
- **approved**: Claim exists in product truth file's Safe Claims
- **safe-inference**: Logically follows from approved claims, not an explicit safe claim
- **needs-verification**: Cannot confirm from available sources — DO NOT use in public content

## Quality Checks
- [ ] Product is identified or explicitly marked unknown
- [ ] Audience is specific (not "everyone")
- [ ] Platform matches content type (e.g., not putting a long article on X)
- [ ] CTA is actionable and has a real URL
- [ ] Source URLs are real and accessible
- [ ] No restricted claims included without flagging
- [ ] Image type matches platform requirements
