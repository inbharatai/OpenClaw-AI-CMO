# Platform Setup Guide

How to connect each platform to OpenClaw AI CMO via SocialFlow.

---

## Important: Use Dedicated Marketing Accounts

**Never use personal accounts.** Create dedicated marketing accounts for each platform:
- `marketing@yourdomain.com` for LinkedIn, Facebook, etc.
- Separate app passwords or dedicated credentials
- These accounts are specifically for automation

---

## Platform Setup

### LinkedIn

**Status**: Ready for auto-posting

```bash
# 1. Start SocialFlow
cd socialflow/backend && python main.py

# 2. Add credentials
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "linkedin", "username": "marketing@yourdomain.com", "password": "your-password"}'

# 3. Login (opens browser for first-time auth)
curl -X POST http://localhost:8000/api/login/linkedin

# 4. Test post (dry run)
curl -X POST http://localhost:8000/api/openclaw/publish \
  -H "Content-Type: application/json" \
  -d '{"platform": "linkedin", "content": "Test post from OpenClaw", "content_type": "test", "dry_run": true}'
```

**Notes**: LinkedIn may require 2FA on first login — complete it in the browser window. Session is saved for future use.

---

### X / Twitter

**Status**: Ready for auto-posting

```bash
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "x", "username": "your-x-handle", "password": "your-password"}'

curl -X POST http://localhost:8000/api/login/x
```

**Notes**: X may show CAPTCHA challenges. Complete them in the browser.

---

### Facebook

**Status**: Ready for auto-posting

```bash
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "facebook", "username": "marketing@yourdomain.com", "password": "your-password"}'

curl -X POST http://localhost:8000/api/login/facebook
```

**Notes**: Facebook may trigger security checkpoints. Complete verification in browser.

---

### Instagram

**Status**: Ready for auto-posting

```bash
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "instagram", "username": "your-ig-handle", "password": "your-password"}'

curl -X POST http://localhost:8000/api/login/instagram
```

**Notes**: Instagram requires image content. Text-only posts are not supported natively.

---

### Discord

**Status**: Ready (via Webhook — no login needed)

```bash
# Create webhook config
cat > socialflow/backend/discord_webhook.json << 'EOF'
{
  "webhook_url": "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"
}
EOF
```

**How to get webhook URL**: Server Settings > Integrations > Webhooks > New Webhook > Copy URL

---

### Reddit

**Status**: Draft-first (manual posting recommended)

```bash
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "reddit", "username": "your-reddit-user", "password": "your-password"}'
```

**Notes**: Reddit is sensitive to automated posting. Use drafts and post manually, especially to maintain karma and avoid bans.

---

### Medium

**Status**: Ready for auto-posting

```bash
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "medium", "username": "your@email.com", "password": "your-password"}'

curl -X POST http://localhost:8000/api/login/medium
```

---

### Substack

**Status**: Ready for auto-posting

```bash
# Add credentials
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "substack", "username": "your@email.com", "password": "your-password"}'

# Configure publication URL
cat > socialflow/backend/substack_config.json << 'EOF'
{
  "publication_url": "https://yourpublication.substack.com"
}
EOF

curl -X POST http://localhost:8000/api/login/substack
```

---

### HeyGen

**Status**: Ready for video brief creation

```bash
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "heygen", "username": "your@email.com", "password": "your-password"}'

curl -X POST http://localhost:8000/api/login/heygen
```

**Notes**: HeyGen integration creates video projects from briefs. Manual review of generated video is recommended.

---

### beehiiv / MailerLite / Brevo

**Status**: Ready for newsletter sending

Same pattern as other platforms:

```bash
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "beehiiv", "username": "your@email.com", "password": "your-password"}'
```

---

## Verifying All Connections

```bash
# Check status of all platforms
curl http://localhost:8000/api/openclaw/status | python -m json.tool
```

This returns which platforms have active sessions and are ready for posting.

---

## Rate Limits

Default daily caps (configurable in `openclaw-engine/policies/rate-limits.json`):

| Platform | Daily Cap | Cooldown |
|----------|----------|----------|
| LinkedIn | 3 posts | 2 hours between posts |
| X/Twitter | 10 posts | 15 minutes |
| Facebook | 3 posts | 2 hours |
| Instagram | 2 posts | 3 hours |
| Discord | 10 messages | 5 minutes |
| Reddit | 2 posts | 4 hours |
| Medium | 1 article | 24 hours |
| Substack | 1 newsletter | 24 hours |
