---
name: channel-post-generator
description: Generates platform-native posts with correct length, tone, hook, CTA, and formatting per channel
version: 1.0.0
category: content-production
triggers:
  - generate post
  - write post
  - create content for
inputs:
  - product (required): Product ID from product-registry.json
  - topic (required): Subject, angle, or news hook
  - platform (required): linkedin | x | instagram | discord | reddit
  - content_type (optional): product-update | thought-leadership | educational | news-reaction | behind-the-build | comparison
  - goal (optional): engagement | authority | traffic | community | awareness
outputs:
  - post_text: Final publishable text for the platform
  - hashtags: Platform-appropriate hashtag set
  - image_brief: Image direction if visual is needed
  - approval_metadata: Internal review fields (NOT for publishing)
honest_classification: content-production-tool
---

# Channel Post Generator

## Purpose
Generate a single post optimized for one specific platform. Not a cross-post — a platform-native piece of content.

## Pre-Generation Checklist
Before writing, load and verify:
1. `OpenClawData/strategy/product-truth/{product}.md` — what you CAN and CANNOT say
2. `OpenClawData/strategy/platform-rules/{platform}.md` — format, tone, length, restrictions
3. `OpenClawData/policies/brand-voice-rules.json` — banned phrases, writing rules, scoring
4. `OpenClawData/strategy/brand-knowledge-base.json` — brand identity context

## Platform-Specific Rules

### LinkedIn
- **Length**: 1300 chars optimal, 3000 max
- **Hook**: First 2 lines must work before "see more" fold
- **Tone**: Professional but authentic, founder-first-person
- **Structure**: Short paragraphs (1-2 sentences), generous line breaks
- **Hashtags**: 3-5 at end, relevant only
- **Emojis**: 0-2 max, only if natural
- **NO**: Engagement bait ("agree?", "thoughts?"), humble-bragging, unverified metrics

### X (Twitter)
- **Length**: 280 chars per tweet, 8 max in thread
- **Hook**: First line IS the hook — no preamble
- **Tone**: Sharp, direct, high-signal
- **Structure**: Single tweet or 3-5 tweet thread
- **Hashtags**: 1-3 max, integrated naturally
- **NO**: Hashtag dumping, engagement farming, "1/" thread numbering unless long

### Instagram
- **Length**: 150-300 chars caption (2200 max)
- **Hook**: First line grabs attention in feed preview
- **Tone**: Visual-first, conversational but professional
- **Structure**: Short caption + CTA + hashtags block
- **Hashtags**: 5-15 relevant, in separate block
- **Requires**: Image brief must be generated alongside

### Discord
- **Length**: 2000 chars max
- **Tone**: Community-friendly, direct, helpful
- **Structure**: Short update with key info + link
- **NO**: Marketing-speak, @everyone (unless launch)

### Reddit
- **Length**: Varies by subreddit
- **Tone**: Useful, discussion-oriented, zero hype
- **Structure**: Value-first, question-ending
- **NO**: Self-promotion language, brand mentions without context
- **REQUIRES**: L3 approval always

## Two-Stage Output

### Stage 1: Internal Planning (not published)
```json
{
  "platform": "linkedin",
  "product": "testsprep",
  "content_type": "educational",
  "goal": "authority",
  "hook_options": ["option A", "option B"],
  "cta_options": ["Visit testsprep.in", "Try practice questions"],
  "source_links": ["https://testsprep.in"],
  "claims_used": ["AI-powered test prep for Indian exams"],
  "restricted_claims_avoided": ["guaranteed results"],
  "image_brief": "Clean dashboard showing study progress..."
}
```

### Stage 2: Final Output (this is what gets posted)
Clean, human-readable text ONLY. No JSON. No metadata. No field names.

## Writing Rules
1. Lead with value — what does the reader get?
2. Use active voice
3. Short sentences, short paragraphs, scannable
4. No filler: "In today's fast-paced world...", "It goes without saying..."
5. Specific over vague: numbers, examples, concrete details
6. Honest about limitations — never oversell
7. Builder perspective — we make things, we ship things, we learn things
8. No banned phrases from brand-voice-rules.json

## Quality Checks
- [ ] Post text passes sanitize_post.py validation (no JSON/metadata leaks)
- [ ] Every claim is in product truth file's "Safe Claims" section
- [ ] No restricted claims used without explicit flagging
- [ ] Length is correct for platform
- [ ] Tone matches platform rules
- [ ] CTA is relevant and not aggressive
- [ ] Hashtags are within platform limits
- [ ] No banned phrases from brand-voice-rules.json
