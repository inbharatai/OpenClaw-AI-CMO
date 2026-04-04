---
name: social-queue-packager
description: Package approved social media content with all metadata needed for manual posting or future API integration. Creates ready-to-post packages for LinkedIn, X, Facebook, and Instagram. Triggers on social media distribution preparation.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Social Queue Packager

Package approved social content into ready-to-post format per channel.

## Default Model

`qwen2.5-coder:7b`

## Input

Approved social content from `OpenClawData/queues/{linkedin,x,facebook,instagram}/approved/`

## Output

Channel-specific ready-to-post files in `MarketingToolData/{channel}/`

## Package Format

```markdown
---
title: "<post title for reference>"
channel: "<channel>"
date: "YYYY-MM-DD"
status: "ready-to-post"
char_count: <number>
hashtags: [<list>]
has_image_brief: <true|false>
image_brief_path: "<path or null>"
source_content: "<path to original>"
posted: false
posted_date: null
---

<Final post content — ready to copy and paste>
```

## Channel-Specific Packaging

### LinkedIn
- Include character count (max 3000)
- Separate hashtags at bottom
- Note if a link preview will be generated

### X / Twitter
- Include character count (max 280 per tweet)
- If thread: number each tweet, total count
- Mark which tweet is the hook

### Facebook
- Include link if applicable
- Note if image is recommended

### Instagram
- Include hashtag block (separate from caption)
- MUST include image brief reference or path
- Caption must work standalone

## Rules

1. Ready-to-post means literally copy-paste ready — no editing needed
2. Always include character count for character-limited platforms
3. Flag if content exceeds platform limits
4. File naming: `{channel}-ready-YYYY-MM-DD-{slug}.md`
