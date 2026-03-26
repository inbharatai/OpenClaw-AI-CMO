---
name: discord-webhook-publisher
description: Post approved content to Discord via webhook. Use when distributing approved Discord announcements. Triggers on Discord posting, webhook publishing, or Discord distribution requests.
---

# Discord Webhook Publisher

Post approved Discord announcements via webhook.

## Default Model

`qwen2.5-coder:7b` — builds and sends webhook payloads.

## Configuration

Webhook URL is stored in: `OpenClawData/policies/discord-webhook.json`

Format:
```json
{
  "webhook_url": "<YOUR DISCORD WEBHOOK URL>",
  "bot_name": "OpenClaw CMO",
  "enabled": true
}
```

**SETUP REQUIRED:** You must create this file with your actual Discord webhook URL before this skill can post.

## Input

Approved content from `OpenClawData/queues/discord/approved/`

## Webhook Payload Format

```json
{
  "username": "OpenClaw CMO",
  "content": "<announcement text>",
  "embeds": []
}
```

For content with links, use embeds:
```json
{
  "username": "OpenClaw CMO",
  "content": "<announcement text>",
  "embeds": [{
    "title": "<link title>",
    "url": "<link URL>",
    "color": 5814783
  }]
}
```

## Posting Flow

1. Read approved file from `queues/discord/approved/`
2. Check rate-limit-guard for Discord channel
3. If allowed: build webhook payload, POST via curl
4. Log result to `OpenClawData/logs/posting-log.json`
5. Move file to `ExportsLogs/posted/discord/`
6. If rate limited: leave in approved queue, log reason

## Curl Command Template

```bash
curl -H "Content-Type: application/json" \
     -d '<payload>' \
     "<webhook_url>"
```

## Rules

1. NEVER post without rate limit check
2. NEVER use @everyone without explicit human approval (L3)
3. Log every post attempt (success and failure) with timestamp
4. If webhook returns error, do NOT retry immediately — log and skip
5. Maximum 3 Discord posts per day (per rate-limits.json)
