> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: social-repurposing
description: Repurpose content across platforms and formats. Convert blog posts to social threads, videos to captions, podcasts to carousels, long-form to short-form, and vice versa. Triggers on "repurpose this", "turn this into", "adapt for Instagram/LinkedIn/X/TikTok", or any cross-platform content conversion request.
---

# Social Repurposing

Transform one piece of content into multiple platform-optimized formats.

## Default Model

`qwen3:8b` — excellent at rewriting, tone-shifting, and format adaptation.

## Storage

- Repurposed content → `MarketingToolData/repurposed/`

## Repurposing Matrix

| Source | → Instagram | → LinkedIn | → X/Twitter | → Email | → Blog |
|---|---|---|---|---|---|
| Blog post | Carousel (key points) | Article summary + CTA | Thread (5-7 tweets) | Newsletter excerpt | N/A |
| Video/Reel | Caption + hashtags | Insight post | Quote + link | Video recap | Transcript + commentary |
| Podcast | Quote cards | Key takeaway post | Thread highlights | Show notes | Full transcript |
| Case study | Before/after visual | Results post | Stats thread | Case study email | Expanded version |
| Customer review | Testimonial graphic | Social proof post | Quote tweet | Trust email | Case study |

## Repurposing Process

1. **Identify the core message** — one sentence that captures the original
2. **Select target platforms** — where should this go?
3. **Adapt format** — match the platform's native format
4. **Adjust tone** — match the platform's culture
5. **Add platform hooks** — opening lines that work for that platform
6. **Include CTA** — every piece needs a next step

## Platform Tone Guide

| Platform | Tone | Length | Special |
|---|---|---|---|
| Instagram | Casual, visual, emoji-ok | 150-300 words caption | Hashtags (15-20), hook in first line |
| LinkedIn | Professional, insightful | 200-500 words | No hashtags in body, 3-5 at end |
| X/Twitter | Sharp, punchy, conversational | 280 chars or thread | Threads for depth |
| Email | Personal, direct | 200-400 words | Subject line is everything |
| Blog | Thorough, SEO-aware | 800-1500 words | Headers, subheaders, scannable |

## Rules

1. Always check `OpenClawData/memory/brand-voice.md` before writing
2. Never copy-paste across platforms — each version must feel native
3. Save all outputs to `MarketingToolData/repurposed/repurposed-<date>-<source>.md`
4. Include the source reference in every repurposed piece
