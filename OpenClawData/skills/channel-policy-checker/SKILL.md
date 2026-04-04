---
name: channel-policy-checker
description: Verify content meets platform-specific rules and guidelines before publishing. Check character limits, hashtag counts, tone requirements, and content restrictions per channel. Triggers on channel compliance checks during approval.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Channel Policy Checker

Verify content complies with platform-specific rules before approval.

## Default Model

`qwen3:8b`

## Policy Reference

Read channel rules from: `OpenClawData/policies/channel-policies.json`

## Input

You will receive:
1. Content text
2. Target channel name
3. Channel policy from channel-policies.json

## Output Format

```json
{
  "channel": "<channel>",
  "compliant": true|false,
  "checks": {
    "character_limit": {"pass": true|false, "actual": <count>, "max": <limit>},
    "tone_match": {"pass": true|false, "notes": "<explanation>"},
    "content_type_valid": {"pass": true|false, "type": "<detected>", "allowed": ["<list>"]},
    "hashtag_count": {"pass": true|false, "actual": <count>, "max": <limit>},
    "guardrails": {"pass": true|false, "violations": ["<any violated rules>"]}
  },
  "platform_risk_score": <0-100>,
  "action": "<pass|fix|block>",
  "fixes_needed": ["<specific fixes if not compliant>"]
}
```

## Channel Checks

| Channel | Key Checks |
|---|---|
| LinkedIn | Max 3000 chars, max 5 hashtags, professional tone, no aggressive sales |
| X | Max 280 chars/tweet, max 8 tweets/thread, max 3 hashtags |
| Facebook | Max 2000 chars, include link if applicable, no clickbait |
| Instagram | Max 2200 chars, 10-15 hashtags, image brief required |
| Discord | Max 2000 chars, no @everyone without L3, community tone |
| Reddit | Match subreddit rules, no overt self-promotion, disclosure required |
| Medium | Min 500 words, subheadings required, cite sources |
| Substack | Clear subject line, subscriber value, personal angle |
| Website | Proper frontmatter, section-appropriate content |

## Rules

1. Fail fast on character limit violations — don't continue checking
2. Tone matching is advisory (flag but don't block on tone alone)
3. Missing required elements (like image brief for Instagram) should block
4. If a fix is possible, suggest the specific fix in `fixes_needed`
5. Platform risk score contributes to the approval engine's overall scoring
