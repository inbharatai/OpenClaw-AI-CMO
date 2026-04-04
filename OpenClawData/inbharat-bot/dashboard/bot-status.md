# InBharat Bot — Status v3.3
**Updated:** 2026-04-03 14:05:00

## Health
- Ollama: running (qwen3:8b, qwen2.5-coder:7b)
- Gateway: running (PID 14611, port 18789)
- Health Check: 13 green, 2 yellow, 0 red
- Agent Brain: Groq GPT-OSS-120B
- Skills Loaded: 69

## Agent Roles (all via single builder agent + skills)
- **CMO**: content-strategy, content-calendar, campaign-calendar-builder, posting-queue-manager
- **Content Creator**: product-update-writer, insights-article-writer, educational-content-builder, comparison-post-writer, weekly-roundup-builder
- **Researcher**: ai-news-summarizer, competitor-monitor, research-synthesizer, lead-research, news-source-collector, seo-topic-mapper
- **Brand/QA**: brand-voice, factuality-check, qa-checklist, duplicate-checker, risk-scorer
- **Publisher**: channel-adapter, channel-exporter, social-queue-packager, discord-webhook-publisher, newsletter-exporter
- **Analyst**: content-performance-tracker, reporting, cmo-report, opportunity-miner

## Publishing Queues
- Pending: 5
- Approved: 2
- Publish-Ready: 0
- Posted: 2

## Posting Engine — ALL ACTIVE (Playwright Browser Automation)
NEVER ask for API tokens or passwords. All sessions are persistent.
- LinkedIn: ACTIVE — `python3 post_linkedin.py --text "content" --image /path/to/img.png`
- X/Twitter: ACTIVE — `python3 post_x.py --text "content" --image /path/to/img.png`
- Instagram: ACTIVE — `python3 post_instagram.py --file <file> --image <img>`
- Zoho Email: ACTIVE — `python3 email_zoho.py --visible --to <addr> --subject <subj> --body <body>`
- Discord: ACTIVE — webhook (macOS Keychain)
- Scripts dir: /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/
- Pipeline: `bash publish.sh` or `daily-pipeline.sh` Stage 4

## Image Generation — ACTIVE
- DALL-E 3 via OpenAI API (key in macOS Keychain)
- Script: `bash generate-image.sh --brief "prompt" --size square`
- Fallback: placeholder_generate.py (offline branded cards)
- Brand colors: saffron (#FF9933), white (#FFFFFF), green (#138808), navy blue (#000080)

## Scheduling (Automated)
- Daily pipeline: 8:07 AM (daily-pipeline.sh via cron)
- Daily auto-content: 9:00 AM (daily-auto-content.sh via cron)
- Weekly pipeline: Monday 7:53 AM
- Monthly pipeline: 1st of month 7:42 AM
- Session keepalive: every 6 hours
- Hourly WhatsApp report: every hour
- Gateway: always-on (LaunchAgent)

## Approvals
- In review: 2
- Blocked: 2 (fabricated claims caught by claim-validator)

## Recent Fixes (2026-04-03)
- X posting: anti-detection (user-agent + webdriver spoofing)
- X posting: hashtag autocomplete fix (insertText instead of keyboard.type)
- X posting: post verification (confirms dialog closed before reporting success)
- LinkedIn: anti-detection applied
- Instagram: anti-detection applied
- DALL-E: Keychain lookup fixed
- All 69 skills: frontmatter fixed (was only loading 6)
- SOUL.md: trimmed from 20K to 8.5K (was being truncated)
