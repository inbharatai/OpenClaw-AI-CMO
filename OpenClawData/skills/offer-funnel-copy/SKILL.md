---
name: offer-funnel-copy
description: Write copy for offers, funnels, landing pages, sales emails, ad copy, CTAs, and conversion-focused content. Use when the user needs sales copy, offer structures, funnel sequences, ad headlines, email sequences, or any persuasion-focused writing. Triggers on "sales copy", "offer", "funnel", "landing page copy", "ad copy", "CTA", "email sequence", "conversion copy", or any sales/persuasion writing request.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Offer & Funnel Copy

Write conversion-focused copy for offers, funnels, ads, and sales sequences.

## Default Model

`qwen3:8b` — strong at persuasive writing, structured sequences, and audience-aware messaging.

## Storage

- Copy outputs → `MarketingToolData/scripts/`
- Campaign context → `MarketingToolData/campaigns/`

## Copy Types

### Offer Structure
```
HOOK: <attention-grabbing opening — problem or desire>
STORY: <brief context — why this matters, what changed>
OFFER: <what they get, clearly stated>
PROOF: <social proof, results, testimonials>
SCARCITY: <why act now — deadline, limited spots, bonus>
CTA: <specific next step — one clear action>
```

### Funnel Email Sequence (5-email default)
1. **Welcome/Value** — deliver on opt-in promise, set expectations
2. **Story/Problem** — share a relatable challenge
3. **Solution/Education** — teach something useful, position your approach
4. **Social Proof** — case studies, results, testimonials
5. **Offer/CTA** — clear offer with urgency

### Ad Copy Framework
- **Headline:** 5-10 words, benefit-driven
- **Primary text:** 2-3 sentences, problem→solution→CTA
- **Description:** 1 sentence supporting the headline
- **CTA button:** Action verb (Get, Start, Claim, Join)

### Landing Page Sections
1. Hero (headline + subheadline + CTA)
2. Problem agitation
3. Solution introduction
4. Features → Benefits
5. Social proof
6. FAQ / Objection handling
7. Final CTA

## Copy Rules

1. **Benefits over features** — "Save 5 hours/week" not "Automated scheduling"
2. **One CTA per piece** — never give multiple competing actions
3. **Read brand-voice.md first** — all copy must match brand personality
4. **Specificity sells** — "127 customers" beats "many customers"
5. **Short paragraphs** — max 3 lines per paragraph in sales copy
6. **Active voice** — "You'll get" not "It will be provided"

## Saving

```
MarketingToolData/scripts/copy-<YYYY-MM-DD>-<type>-<name>.md
```
