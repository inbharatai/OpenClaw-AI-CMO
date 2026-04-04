**Posting Guidelines — Updated 2026-04-04**

## Canonical Publish Path
All live posts MUST go through `publish.sh`. Direct script calls require `--allow-direct-post` flag.

## Policy Enforcement
- `policies/rate-limits.json` is the authoritative policy source
- `policy_enforcer.py` enforces blocked platforms and daily caps at runtime
- Blocked platforms fail closed — no posting regardless of path

## Platform Rules
- LinkedIn: 3/day, 15/week, professional tone, 3-5 hashtags max
- X: 3/day, 15/week, 280 chars, 0-2 hashtags, sharp and direct
- Instagram: 1/day, 5/week, image required, 5-15 hashtags, visual-first
- Discord: 3/day, webhook, community-friendly, 2000 char max
- Reddit: 1/day, NEVER auto-post, L3 manual always

## Brand Sources
- Brand identity: `strategy/brand-knowledge-base.json`
- Product facts: `strategy/product-truth/*.md`
- Platform rules: `strategy/platform-rules/*.md`
- Voice rules: `policies/brand-voice-rules.json`

## Logo
- Primary: `OpenClawData/openclaw-media/assets/images/inbharat-logo.jpg`
- SVG: `assets/brand/inbharat_logo.svg`

## Content Rules
- Every post sanitized via `sanitize_post.py` — no JSON/metadata leakage
- Every image prompt enriched via `enrich_image_prompt.py` — brand-aware
- Always include website link (inbharat.ai) in X posts
- Content must be grounded in product truth files — no invented claims
