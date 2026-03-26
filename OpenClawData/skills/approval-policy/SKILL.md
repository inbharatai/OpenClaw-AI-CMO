> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: approval-policy
description: Evaluate content against the 4-level approval policy and determine whether to auto-approve, score-gate, send to review, or block. Use when the approval engine needs to make a decision on pending content. Triggers on any content approval evaluation request.
---

# Approval Policy

Evaluate content against the AI CMO approval policy and return a structured decision.

## Default Model

`qwen2.5-coder:7b` — deterministic evaluation, not creative writing.

## Policy Reference

Read the full policy from: `OpenClawData/policies/approval-rules.json`

## Input

You will receive:
1. The content to evaluate (full text)
2. The content's metadata (type, channel, source)
3. Risk scores from risk-scorer (6 dimensions, 0-100 each)
4. Duplication score from duplicate-checker

## Output Format

Return EXACTLY this JSON structure:

```json
{
  "decision": "<auto_approve|score_gate_pass|score_gate_fail|review|block>",
  "level": "<L1|L2|L3|L4>",
  "weighted_score": <number>,
  "max_dimension": <number>,
  "risk_scores": {
    "source_confidence": <0-100>,
    "brand_voice": <0-100>,
    "claim_sensitivity": <0-100>,
    "duplication": <0-100>,
    "platform_risk": <0-100>,
    "data_safety": <0-100>
  },
  "override_triggered": "<rule name or null>",
  "reason": "<1-2 sentence explanation>",
  "action": "<approve_and_queue|hold_for_review|block_and_log>",
  "destination": "<queues/{channel}/approved/ or approvals/review/ or approvals/blocked/>"
}
```

## Decision Logic

Apply in this order (first match wins):

1. **BLOCK CHECK (L4):** If `data_safety > 50` → BLOCK. If any override trigger matches → BLOCK.
2. **L1 CHECK:** If content type is in L1 auto-approve list AND all dimensions < 30 AND weighted average < 25 → AUTO_APPROVE.
3. **L2 CHECK:** If content type is in L2 list AND max dimension < 60 AND weighted average < 45 AND data_safety < 30 → SCORE_GATE_PASS.
4. **L2 FAIL:** If content type is in L2 list but scores exceed thresholds → SCORE_GATE_FAIL → route to REVIEW.
5. **L3 DEFAULT:** Everything else → REVIEW.

## Override Triggers (always block)

- Content contains email addresses or credentials
- Content has no source evidence
- Content states unverifiable claims as facts
- Content matches known spam patterns
- Content targets channels not in approved list

## Rules

1. Be strict — when in doubt, escalate to review rather than auto-approve
2. Always provide a clear reason for the decision
3. The decision must be deterministic given the same inputs
4. Log-friendly output — every decision must be traceable
