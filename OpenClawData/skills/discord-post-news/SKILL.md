---
name: discord-post-news
description: Post AI news to Discord channel via webhook. Triggers on /discord-post-news command.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Discord Post News Skill

**Trigger:** `/discord-post-news`

When this skill runs, it should post the *current* AI‑industry brief (the same short 6‑line version you receive on WhatsApp) to the Discord webhook you supplied.

**Steps the model should follow**
1. **Locate the latest newsletter file** in `memory/approval/` whose name matches the pattern `ai-news-*-newsletter.md`. (The most recent file is the one with the latest date prefix.)
2. **Read** that file and extract its first 6‑line summary (the concise bullet list). If the file already contains a short “📰 AI‑Industry Brief” block, use that whole block as the message.
3. **POST** the extracted text to the webhook using `curl`:
   ```bash
   curl -X POST -H "Content-Type: application/json" \
        -d "{\"content\":\"<MESSAGE_TEXT>\"}" \
        WEBHOOK_URL_IN_KEYCHAIN
   ```
   Replace `<MESSAGE_TEXT>` with the text you extracted in step 2 (properly escaped for JSON).

**Safety notes:**
- The webhook URL is hard‑coded (it’s the one you gave me). It will only be used for this single POST.
- No personal or private data is included; only the public brief that you already receive on WhatsApp.
- The `exec` call runs `curl` with a known safe URL, so it’s allowed.

**Response:** After the POST succeeds, send a WhatsApp confirmation such as:
```
✅ Discord post sent for the AI‑news brief (8 AM / 11 PM).
```