> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: channel-adapter
description: Adapt a single piece of approved content into multiple channel-specific variants (LinkedIn, X, Facebook, Instagram, etc.). Use when repurposing one piece of content across multiple platforms. Triggers on multi-channel content adaptation or cross-platform repurposing requests.
---

# Channel Adapter

Take one piece of content and create properly formatted variants for multiple channels.

## Default Model

`qwen3:8b`

## Storage

- Per-channel outputs → `MarketingToolData/{channel}/`
- Per-channel queues → `OpenClawData/queues/{channel}/pending/`

## Input

The source content to adapt. Must include:
- The original content text
- The source file path
- Target channels (comma-separated)

## Output Format

For EACH target channel, produce a separate file:

```markdown
---
title: "<channel-specific title>"
date: "YYYY-MM-DD"
channel: "<channel name>"
type: "<content type>"
adapted_from: "<source file path>"
approval_level: "<L1|L2>"
status: "pending"
char_count: <number>
---

<Channel-formatted content>
```

## Channel Adaptation Rules

### LinkedIn (max 3000 chars)
- Professional but conversational tone
- Open with a hook or bold statement
- Use line breaks for readability
- End with a question or call to engage
- Max 5 hashtags at the bottom
- No emoji in body text (optional 1 at start)

### X / Twitter (max 280 chars per tweet, max 8 in thread)
- Sharp, direct, high-signal
- If content needs a thread: first tweet is the hook, last is the CTA
- Max 3 hashtags
- Use line breaks within a tweet for readability

### Facebook (max 2000 chars)
- Friendly, accessible, link-forward
- Include the link to full content
- Conversational tone
- Minimal hashtags (0-3)

### Instagram (max 2200 chars)
- Caption must work without the image
- Story-driven or list format
- 10-15 relevant hashtags (in a separate block at the end)
- Include an image brief note: `[IMAGE BRIEF: <describe what image should show>]`

### Discord (max 500 chars)
- Use discord-announcement-writer format
- Community-friendly
- Single emoji prefix

## Writing Rules

1. Each variant must feel native to its platform — not a copy-paste resize
2. Preserve the core message but change the framing, length, and tone
3. LinkedIn is professional-thoughtful, X is sharp-direct, Instagram is visual-story, Discord is casual-community
4. Always include `adapted_from` in frontmatter for traceability
5. File naming: `{channel}-YYYY-MM-DD-<slug>.md`
6. If a channel variant exceeds its character limit, trim — don't just truncate
