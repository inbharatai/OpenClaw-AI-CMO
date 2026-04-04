# TOOLS.md — System Reference

## Workspace

```
/Volumes/Expansion/CMO-10million/
├── OpenClawData/
│   ├── inbharat-bot/       # Ecosystem intelligence (8 scripts + orchestrator)
│   ├── scripts/             # CMO pipeline (28 scripts)
│   ├── skills/              # 55 skill definition files (markdown)
│   ├── policies/            # 4 governance policy files
│   ├── queues/              # Distribution queues by channel
│   ├── approvals/           # Approval state (pending/approved/blocked/review)
│   ├── reports/             # Pipeline reports
│   ├── logs/                # Pipeline execution logs
│   └── memory/              # Operational memory files
├── MarketingToolData/       # Content sources and exports
│   ├── source-notes/        # Input material
│   ├── source-links/        # Reference links
│   ├── ai-news/             # AI news items
│   ├── product-updates/     # Product update material
│   └── exports/             # Distribution outputs
├── memory/                  # Daily operational notes
└── skills -> OpenClawData/skills  # Symlink for OpenClaw
```

## Commands

| Command | Path | Status |
|---------|------|--------|
| git | /usr/bin/git | ✅ |
| curl | /usr/bin/curl | ✅ |
| python3 | /usr/bin/python3 (3.9.6) | ✅ |
| python3.11 | ~/.pyenv/versions/3.11.9/bin/python3.11 | ✅ |
| jq | verify with `which jq` | ✅ |
| bash | /bin/bash | ✅ |
| ollama | /usr/local/bin/ollama | ✅ |
| gh | NOT INSTALLED | ❌ |
| brew | NOT INSTALLED | ❌ |

## Models

| Model | Provider | Use |
|-------|----------|-----|
| openai/gpt-oss-120b | Groq | Primary (agent conversations) |
| qwen/qwen3-32b | Groq | Backup |
| llama-3.3-70b-versatile | Groq | Backup |
| qwen3:8b | Ollama local | Pipeline content generation |
| qwen2.5-coder:7b | Ollama local | Installed, untested |

## Crons (LaunchAgent — all loaded)

| Schedule | Script | Status |
|----------|--------|--------|
| Always-on | OpenClaw gateway (port 18789) | ✅ Running (PID 65028) |
| Daily 6 AM | daily-pipeline.sh | ✅ Loaded, runs with failures |
| Monday 8 AM | weekly-pipeline.sh | ✅ Loaded |
| 1st of month 9 AM | monthly-pipeline.sh | ✅ Loaded |

## Posting Engine — ACTIVE

ALL social media posting uses Playwright browser automation. NEVER ask for API tokens or passwords.

| Platform   | Command | Status |
|------------|---------|--------|
| X/Twitter  | `python3 /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/post_x.py --text "content"` | ACTIVE |
| LinkedIn   | `python3 /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/post_linkedin.py --text "content"` | ACTIVE |
| Instagram  | `python3 /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/post_instagram.py --file <file> --image <img>` | ACTIVE |
| Zoho Email | `python3 /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/email_zoho.py --to <addr> --subject <subj> --body <body> --visible` | ACTIVE |
| Discord    | `python3 /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/post_discord.py` | ACTIVE |

Pipeline: `bash /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/publish.sh`

## Image Generation — ACTIVE (DALL-E 3)

API key already in macOS Keychain. NEVER ask for API key. Just run:

```
bash /Volumes/Expansion/CMO-10million/OpenClawData/scripts/generate-image.sh "your prompt" --size square
```

Sizes: `square` (1024x1024), `landscape` (1792x1024), `portrait` (1024x1792)
Output: `/Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/generated-images/`
Budget: 10 images/day (auto-tracked)

## Video Generation — ACTIVE (local FFmpeg)

```
bash /Volumes/Expansion/CMO-10million/OpenClawData/scripts/generate-video-local.sh --type slideshow --images "img1.png img2.png" --output video.mp4
```

Types: `slideshow`, `text`, `kenburns`, `quote`

## Known Issues

1. WhatsApp reconnects with status 499 every ~60s when idle
2. Content quality: qwen3:8b sometimes fabricates statistics
3. Subagents non-functional (3/3 failed with qwen3:8b)

## Safety

- Never modify files outside workspace
- Never auto-publish without approval gate
- Never store API keys in plaintext
- Never claim success without captured output
