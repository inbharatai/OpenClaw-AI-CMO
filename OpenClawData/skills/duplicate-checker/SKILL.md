> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: duplicate-checker
description: Check content for duplication or near-duplication against recently published content. Use when the approval engine needs to verify content uniqueness. Triggers on duplicate checking requests during content approval.
---

# Duplicate Checker

Compare new content against recently published material to detect duplicates.

## Default Model

`qwen2.5-coder:7b` — pattern matching and comparison.

## Input

You will receive:
1. The new content to check
2. A list of recently published content titles and summaries (last 30 days)

## Output Format

```json
{
  "duplication_score": <0-100>,
  "is_duplicate": <true|false>,
  "closest_match": "<filename of closest existing content or null>",
  "similarity_type": "<exact|near-duplicate|same-topic-new-angle|unique>",
  "reason": "<brief explanation>"
}
```

## Scoring Guide

| Score | Meaning |
|---|---|
| 0-20 | Fully original — no similar content exists |
| 21-40 | Same topic but clearly different angle, new information |
| 41-60 | Significant overlap — similar points, some new content |
| 61-80 | Near-duplicate — same key messages, minimal new value |
| 81-100 | Exact or near-exact duplicate |

## Rules

1. Compare titles, key phrases, and core message — not just exact text matches
2. Same topic is OK if the angle is genuinely different
3. Repurposed content (e.g., blog post → LinkedIn) is NOT duplication — it's adaptation
4. Score based on value-add: does this content provide something new to the reader?
5. If no comparison content is available, score 0 and note "no comparison data"
