---
name: image-style-registry
description: Defines image types, visual rules, and prompt patterns for brand-consistent image generation
version: 1.0.0
category: media
triggers:
  - image style
  - visual direction
  - image type
inputs:
  - image_type (required): Type of image needed
  - product (required): Product ID
  - platform (required): Target platform
outputs:
  - style_brief: Visual direction document
  - prompt_template: DALL-E prompt skeleton
honest_classification: media-utility
---

# Image Style Registry

## Purpose
Define exactly what each type of image should look like before any prompt is written.
This skill is the visual equivalent of a content brief — it ensures every image is intentional.

## Image Types and Visual Rules

### static_post
- **Use for**: Single image social media posts
- **Composition**: Single focal point, clean background, brand color accents
- **Text overlay**: Max 8 words headline, or none
- **Aspect**: Instagram 1:1, LinkedIn 1.91:1, X 16:9
- **DALL-E prompt pattern**: `{concept description}. Clean, modern design with {brand_colors}. Single focal composition. Professional quality. {platform} post format.`

### carousel_cover
- **Use for**: First slide of carousel/slide deck
- **Composition**: Bold, eye-catching, centered headline area
- **Text overlay**: Required — 6-8 word headline
- **Aspect**: 1:1 or 4:5
- **DALL-E prompt pattern**: `Bold cover image for carousel about {topic}. {brand_colors} background with space for large headline text. Premium, modern design. Eye-catching and clean.`

### infographic
- **Use for**: Data visualization, process flows, comparison charts
- **Composition**: Grid or flow layout, organized sections
- **Text overlay**: Data points, labels, section headers
- **Aspect**: 4:5 or 1:1
- **Note**: Prefer design tool output over DALL-E for infographics

### ui_mockup
- **Use for**: Product screenshots, interface previews
- **Composition**: Device frame (phone/laptop), real or realistic interface
- **Text overlay**: None (UI has its own text)
- **Aspect**: Match device ratio
- **DALL-E prompt pattern**: `Clean mockup of {product_name} interface on {device}. Showing {feature_description}. Modern UI design with {brand_colors}. Realistic screen content.`
- **Rule**: UI content must be plausible — no fake data that makes false claims

### conceptual_poster
- **Use for**: Abstract concept visualization, thought leadership
- **Composition**: Modern abstract with brand color accents
- **Text overlay**: Optional short tagline
- **Aspect**: Platform-dependent
- **DALL-E prompt pattern**: `Modern, abstract visualization of {concept}. Premium, clean design. {brand_colors} color scheme. Intelligent and sophisticated feel. No text unless specified.`

### product_explainer
- **Use for**: How-it-works visuals, feature breakdowns
- **Composition**: Flow diagram or feature grid
- **Text overlay**: Step labels, feature callouts
- **Aspect**: 16:9 or 1:1
- **DALL-E prompt pattern**: `Clean product explainer visual showing {feature/workflow}. Step-by-step flow or feature grid. {brand_colors}. Professional and scannable.`

### workflow_diagram
- **Use for**: Process flows, architecture diagrams, pipelines
- **Composition**: Left-to-right or top-to-bottom flow, connected nodes
- **Text overlay**: Node labels, connection descriptions
- **Aspect**: 16:9
- **Note**: Prefer code/design tools over DALL-E for technical diagrams

### founder_message
- **Use for**: Founder quotes, personal insights, milestone messages
- **Composition**: Clean background, prominent text area, subtle brand accent
- **Text overlay**: Quote text + attribution
- **Aspect**: 1:1
- **DALL-E prompt pattern**: `Clean, premium card design for founder quote. {brand_colors} accent. Space for text overlay. Professional, personal, trustworthy feel. Minimal design.`

## Global Rules for ALL Image Types
1. Load product colors from `strategy/brand-knowledge-base.json`
2. Check product visual style from `strategy/product-truth/{product}.md`
3. Never generate images with text baked in unless explicitly required — text overlay is added in post-production
4. Never generate fake UI with false metrics or claims
5. Always specify what to AVOID in the prompt (negative guidance)
6. Prefer clean, minimal composition over busy, cluttered designs

## Using with enrich_image_prompt.py
This skill's rules are codified in `strategy/brand-knowledge-base.json` under `image_types`.
The `enrich_image_prompt.py` script reads these rules automatically when `--image-type` is specified.

For manual use: reference this skill when writing image briefs to ensure correct visual direction.
