> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: discord-announcement-writer
description: Write Discord-formatted announcements from product updates, news, and community updates. Use when producing content for Discord webhook posting. Triggers on Discord announcements, community updates, or any content targeted at Discord.
---

# Discord Announcement Writer

Write concise, community-friendly announcements for Discord channels.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/discord/`
- Queue → `OpenClawData/queues/discord/pending/`

## Output Format

```markdown
---
title: "<announcement title>"
date: "YYYY-MM-DD"
type: "discord-announcement"
category: "<product-update|community-update|news|daily-tip>"
approval_level: "L1"
source_file: "<path to source>"
status: "pending"
webhook_ready: true
---

**<Emoji> <Title>**

<2-4 sentences: what happened, why it matters, what to do>

<Optional: link to full post or resource>
```

## Discord Format Rules

1. Use Discord-flavored markdown: **bold**, *italic*, `code`, > quotes
2. Keep under 500 characters for maximum readability
3. Use ONE relevant emoji at the start — not emoji spam
4. No @everyone unless it's a major launch (flag as L3 if using)
5. Include a link to the full post if the announcement summarizes longer content
6. End with a soft CTA: "Check it out →" or "Thoughts?" — not aggressive marketing

## Emoji Guide

| Category | Emoji |
|---|---|
| Product update | 🛠️ |
| New feature | ✨ |
| Bug fix | 🐛 |
| News | 📰 |
| Community | 👋 |
| Tip | 💡 |
| Launch | 🚀 |
| Warning | ⚠️ |

## Writing Rules

1. Community-first tone — you're talking to people who care about the project
2. No corporate speak — Discord is casual
3. File naming: `discord-YYYY-MM-DD-<slug>.md`
4. One announcement per topic — don't bundle unrelated updates
