---
name: rate-limit-guard
description: Enforce daily and weekly posting caps per channel. Check current posting counts against rate-limits.json before allowing new posts. Use before any distribution action to verify rate limits. Triggers on rate limit checks during content distribution.
---

# Rate Limit Guard

Enforce posting frequency caps to prevent over-posting and spam behavior.

## Default Model

`qwen2.5-coder:7b` — counting and policy enforcement.

## Policy Reference

Read limits from: `OpenClawData/policies/rate-limits.json`

## Input

You will receive:
1. Channel name
2. Current date/time
3. Posting log for the channel (from `OpenClawData/logs/posting-log.json`)

## Output Format

```json
{
  "channel": "<channel name>",
  "allowed": <true|false>,
  "daily_count": <current posts today>,
  "daily_cap": <max allowed>,
  "weekly_count": <current posts this week>,
  "weekly_cap": <max allowed>,
  "last_post_time": "<ISO timestamp or null>",
  "min_interval_hours": <required gap>,
  "hours_since_last": <calculated>,
  "reason": "<why allowed or blocked>"
}
```

## Enforcement Rules

1. If `daily_count >= daily_cap` → BLOCK, reason: "Daily cap reached"
2. If `weekly_count >= weekly_cap` → BLOCK, reason: "Weekly cap reached"
3. If `hours_since_last < min_interval_hours` → BLOCK, reason: "Too soon since last post"
4. If channel has `auto_post_allowed: false` → flag but don't block (queue/export is still OK)
5. If all checks pass → ALLOW

## Global Caps

Also enforce from rate-limits.json `global` section:
- `max_total_posts_per_day`: 15 across all channels
- `max_total_emails_per_day`: 3
- `cooldown_after_block_hours`: 24 hours after any content is blocked

## Rules

1. This is enforcement, not suggestion — if blocked, content does NOT proceed
2. Always update the posting log after a successful post
3. Log every check (allowed and blocked) to `OpenClawData/logs/rate-limit.log`
