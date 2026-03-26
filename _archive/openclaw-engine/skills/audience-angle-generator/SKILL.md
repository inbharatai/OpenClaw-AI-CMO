---
name: audience-angle-generator
description: Generate audience-specific angles and hooks for content. Takes a topic and produces multiple angles tailored to different audience segments. Use when adapting content for different audiences or brainstorming hooks. Triggers on angle generation, hook brainstorming, or audience targeting requests.
---

# Audience Angle Generator

Generate multiple audience-specific angles for a single topic.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/research/`

## Output Format

```markdown
---
title: "Angles: <topic>"
date: "YYYY-MM-DD"
type: "angle-research"
---

# Audience Angles: <Topic>

## Topic
<1 sentence description of the core topic>

## Angles by Audience

### For Developers / Builders
- **Hook:** <attention-grabbing opening>
- **Angle:** <how to frame this for developers>
- **Key message:** <what resonates with this audience>
- **Best channel:** <where to publish this version>

### For Founders / Business Leaders
- **Hook:** <opening>
- **Angle:** <business framing>
- **Key message:** <what matters to them>
- **Best channel:** <where to publish>

### For AI Enthusiasts / Early Adopters
- **Hook:** <opening>
- **Angle:** <innovation framing>
- **Key message:** <what excites them>
- **Best channel:** <where to publish>

### For General Tech Audience
- **Hook:** <opening>
- **Angle:** <accessible framing>
- **Key message:** <broad appeal>
- **Best channel:** <where to publish>

## Recommended Primary Angle
<Which audience angle to prioritize and why>
```

## Rules

1. Each angle must feel genuinely different — not the same thing reworded
2. Hooks should be specific and provocative, not generic
3. Channel recommendations should match audience habits
4. 3-5 audience segments per topic
5. Always recommend a primary angle
