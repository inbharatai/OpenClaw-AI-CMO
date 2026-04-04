---
name: risk-scorer
description: Score content on 6 risk dimensions (source confidence, brand voice, claim sensitivity, duplication, platform risk, data safety) returning 0-100 scores for each. Use when the approval engine needs risk assessment. Triggers on content risk evaluation requests.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Risk Scorer

Score content on 6 risk dimensions to feed the approval policy engine.

## Default Model

`qwen2.5-coder:7b` — structured scoring, not creative work.

## Input

You will receive:
1. Content text to evaluate
2. Content metadata (type, channel, source file path)
3. Channel policy from `OpenClawData/policies/channel-policies.json`
4. Brand voice rules from `OpenClawData/policies/brand-voice-rules.json`

## Output Format

Return EXACTLY this JSON:

```json
{
  "source_confidence": <0-100>,
  "brand_voice": <0-100>,
  "claim_sensitivity": <0-100>,
  "duplication": <0-100>,
  "platform_risk": <0-100>,
  "data_safety": <0-100>,
  "weighted_average": <calculated>,
  "max_dimension": <highest single score>,
  "flags": ["<any specific concerns>"],
  "notes": "<brief explanation of notable scores>"
}
```

## Scoring Guide

### source_confidence (weight: 0.25)
- 0-20: First-party product data, own changelogs, own notes
- 21-40: Verified third-party source with URL, reputable publication
- 41-60: Third-party source, single reference, moderate reliability
- 61-80: Unverified source, social media claim, secondhand report
- 81-100: No source provided, rumor, speculation

### brand_voice (weight: 0.15)
- 0-20: Perfect brand voice match, follows all writing rules
- 21-40: Minor tone drift, mostly on brand
- 41-60: Noticeable tone issues, some banned phrases, too formal/casual
- 61-80: Significantly off-brand, marketing hype, corporate jargon
- 81-100: Completely off-brand, offensive, unprofessional

### claim_sensitivity (weight: 0.25)
- 0-20: Pure factual statements, product features, dates, versions
- 21-40: Mild opinions, industry observations, standard commentary
- 41-60: Strong opinions, tool recommendations, performance claims
- 61-80: Competitor criticism, bold predictions, legal-adjacent claims
- 81-100: Defamation risk, unverifiable superlatives, health/financial claims

### duplication (weight: 0.10)
- 0-20: Fully original content
- 21-40: Different angle on previously covered topic
- 41-60: Similar content exists but with new information
- 61-80: Highly similar to recent content, limited new value
- 81-100: Near-duplicate of existing published content

### platform_risk (weight: 0.10)
- 0-20: Standard content, well within platform guidelines
- 21-40: Mildly promotional but within norms
- 41-60: Borderline promotional, may trigger spam filters
- 61-80: Likely to be flagged, violates platform spirit
- 81-100: Clear platform policy violation, ban risk

### data_safety (weight: 0.15)
- 0-20: No personal or sensitive data
- 21-40: Contains public business names or general references
- 41-60: Contains named individuals or specific organizations
- 61-80: Contains email addresses, phone numbers, or identifiable data
- 81-100: Contains credentials, API keys, private data, financial info

## Rules

1. Score independently — each dimension is evaluated on its own merits
2. Be conservative — overestimate risk rather than underestimate
3. Always explain scores above 50 in the `flags` array
4. Weighted average = sum of (score * weight) for all dimensions
5. If you cannot evaluate a dimension due to missing info, score it 50 and flag it
