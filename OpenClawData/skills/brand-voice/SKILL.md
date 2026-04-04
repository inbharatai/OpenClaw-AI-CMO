---
name: brand-voice
description: Define, maintain, and apply consistent brand voice and tone across all content. Use when creating brand guidelines, reviewing content for voice consistency, or adjusting tone for different audiences/platforms. Triggers on "brand voice", "tone of voice", "how should this sound", "voice guidelines", "make this sound like our brand", or any tone/style consistency request.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Brand Voice

Define and enforce a consistent brand personality across all content.

## Default Model

`qwen3:8b` — strong at tone analysis, style adaptation, and creative writing.

## Storage

- Brand voice rules → `OpenClawData/memory/brand-voice.md`
- Style examples → `MarketingToolData/briefs/`

## Brand Voice Framework

### Voice Dimensions (define each on a spectrum)

1. **Formal ←→ Casual** — How buttoned-up or relaxed?
2. **Serious ←→ Playful** — How much humor or lightness?
3. **Respectful ←→ Irreverent** — How conventional or boundary-pushing?
4. **Enthusiastic ←→ Matter-of-fact** — How much energy and excitement?

### Voice Components

| Component | Definition | Example |
|---|---|---|
| **Personality** | Who is the brand as a person? | "A smart friend who happens to be an expert" |
| **Tone** | How the personality adapts to context | Celebratory for wins, empathetic for problems |
| **Language** | Word choices and patterns | Short sentences, active voice, no jargon |
| **Rhythm** | Sentence structure and pacing | Mix short punchy lines with occasional longer explanations |

## Brand Voice Document Format

When defining brand voice, save to `OpenClawData/memory/brand-voice.md`:

```markdown
# Brand Voice Guide

## Personality
<description>

## Tone Spectrum
- Formal/Casual: <position>
- Serious/Playful: <position>
- Respectful/Irreverent: <position>
- Enthusiastic/Matter-of-fact: <position>

## Do's
- <specific guidance>

## Don'ts
- <specific guidance>

## Example Phrases
- Instead of "X", say "Y"
- Instead of "X", say "Y"

## Platform Adjustments
- Instagram: <tone shift>
- LinkedIn: <tone shift>
- Email: <tone shift>
```

## How to Apply

1. Before writing any content, read `OpenClawData/memory/brand-voice.md`
2. After drafting content, review against the Do's and Don'ts
3. Check that tone matches the platform adjustment rules
4. If no brand voice is defined yet, ask the user to define one using the framework above

## Rules

1. Brand voice overrides default writing style — always apply it
2. Platform adjustments are allowed but must stay within the voice spectrum
3. If the user's request conflicts with brand voice, flag it and ask
4. Update brand-voice.md whenever the user refines their voice
