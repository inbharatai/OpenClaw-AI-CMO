---
name: factuality-check
description: Verify claims in content against source material to catch hallucinations and unverified statements. Use during approval pipeline for L2+ content. Triggers on factuality verification requests during content approval.
---

# Factuality Check

Verify claims in generated content against the original source material.

## Default Model

`qwen3:8b` — reasoning about factual claims requires language understanding.

## Input

You will receive:
1. The generated content to check
2. The original source material it was based on

## Output Format

```json
{
  "factuality_score": <0-100>,
  "claims_checked": <count>,
  "claims_verified": <count>,
  "claims_unverified": <count>,
  "claims_contradicted": <count>,
  "findings": [
    {
      "claim": "<the claim from the generated content>",
      "status": "<verified|unverified|contradicted|embellished>",
      "source_evidence": "<what the source actually says, or 'not found in source'>",
      "severity": "<low|medium|high>"
    }
  ],
  "action": "<pass|flag|block>",
  "reason": "<overall assessment>"
}
```

## Scoring

| Score | Meaning |
|---|---|
| 0-20 | All claims verified against source |
| 21-40 | Minor embellishments but core facts correct |
| 41-60 | Some unverified claims mixed with verified ones |
| 61-80 | Significant unverified or embellished claims |
| 81-100 | Contains contradictions or fabricated claims |

## What to Check

1. **Numbers and statistics** — Are they in the source? Are they accurate?
2. **Dates and timelines** — Do they match the source?
3. **Names and attributions** — Correct people, companies, products?
4. **Feature claims** — Does the product actually do what the content says?
5. **Comparisons** — Are comparative claims supported by source data?
6. **Quotes** — Are any quotes accurate and attributed correctly?

## Decision Logic

- Score 0-30: PASS — content is factually grounded
- Score 31-60: FLAG — send to review with specific concerns noted
- Score 61-100: BLOCK — content has factuality issues that could damage credibility

## Rules

1. Only check claims that can be verified against the provided source
2. If a claim is common knowledge and not controversial, score it as verified
3. Embellishment (making something sound better than source supports) is different from fabrication
4. When in doubt, flag rather than pass — false positives are better than publishing false claims
5. Always provide the specific source evidence (or lack thereof) for each finding
