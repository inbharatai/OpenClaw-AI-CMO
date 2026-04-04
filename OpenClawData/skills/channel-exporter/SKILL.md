---
name: channel-exporter
description: Format and export approved content into channel-ready packages for each distribution target. Use when moving approved content from queues to export-ready format. Triggers on content export or distribution preparation requests.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Channel Exporter

Format approved content into final, channel-ready packages for distribution.

## Default Model

`qwen2.5-coder:7b` — formatting and file manipulation.

## Storage

- Input → `OpenClawData/queues/{channel}/approved/`
- Output → `ExportsLogs/posted/` (after distribution)
- Export packages → `ExportsLogs/email/ready-to-send/` (for newsletters)

## Export Formats by Channel

### Website
- Format: Markdown with YAML frontmatter
- Ready for: static site generator, CMS paste, manual publish
- Output: stays in `queues/website/approved/` until published

### LinkedIn / X / Facebook
- Format: Plain text file with metadata header
- Include: character count, hashtags, CTA
- Output: `queues/{channel}/approved/` → auto-posted by `publish.sh` via Playwright browser automation

### Instagram
- Format: Caption text + image brief reference
- Include: hashtag block, image brief path
- Output: `MarketingToolData/instagram/`

### Discord
- Format: Webhook-ready JSON payload
- Include: content, embed structure if applicable
- Output: `queues/discord/approved/` for webhook publisher

### Email/Newsletter
- Format: Markdown or HTML
- Include: subject line, preview text, body
- Output: `ExportsLogs/email/ready-to-send/`

### HeyGen
- Format: Structured video brief markdown
- Output: `MarketingToolData/video-briefs/`

## Rules

1. Never modify the content during export — only format and package
2. Always preserve the source frontmatter
3. Add `exported_date` and `export_format` to metadata
4. Log every export to `OpenClawData/logs/export.log`
