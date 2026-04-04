# HEARTBEAT

## Status: ACTIVE

## Check Protocol
1. `ps aux | grep openclaw | grep -v grep` → gateway alive?
2. `curl -s --max-time 3 http://127.0.0.1:11434/api/tags | jq -r '.models[].name'` → Ollama?
3. `cat OpenClawData/inbharat-bot/dashboard/bot-status.md` → bot health?
4. `tail -5 OpenClawData/logs/daily-pipeline.log` → last pipeline run?
5. Report: `HEARTBEAT_OK` or `HEARTBEAT_ISSUE: <detail>`

## Ready
- Gateway running (PID 89489)
- Groq GPT-OSS-120B (primary)
- Ollama qwen3:8b (local/pipeline)
- 25 tools, 55 skills
- InBharat Bot (5 modes)
- CMO pipeline (28 scripts, 4 crons loaded)

## Posting Engine — ALL ACTIVE
All social media posting uses Playwright browser automation. NEVER ask for API tokens or passwords.
- X: `python3 /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/post_x.py --text "content"`
- LinkedIn: `python3 /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/post_linkedin.py --text "content"`
- Instagram: `python3 /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/post_instagram.py --file <file> --image <img>`
- Discord: webhook active
- Zoho Email: `python3 /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/email_zoho.py --visible --to <addr> --subject <subj> --body <body>`
- DALL-E 3 images: `bash /Volumes/Expansion/CMO-10million/OpenClawData/scripts/generate-image.sh "prompt" --size square`
- FFmpeg video: `bash /Volumes/Expansion/CMO-10million/OpenClawData/scripts/generate-video-local.sh --type slideshow --images "img1.png img2.png" --output video.mp4`
- Pipeline publish: `bash /Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/posting-engine/publish.sh`

## Known Issues
- WhatsApp: status 499 reconnection loop when idle
- Subagents: non-functional

## Waiting On Owner
- Decision on blocked approval items
