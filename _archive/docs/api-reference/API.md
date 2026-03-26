# SocialFlow API Reference

Base URL: `http://localhost:8000`

---

## OpenClaw Bridge Endpoints

### POST `/api/openclaw/publish`
Publish approved content to a platform.

**Request Body:**
```json
{
  "platform": "linkedin",
  "content": "Your post content here",
  "content_type": "product-update",
  "title": "Optional title (Medium, Substack, Reddit)",
  "subtitle": "Optional subtitle (Substack only)",
  "subreddit": "Optional subreddit (Reddit only)",
  "image_paths": ["path/to/image.png"],
  "approval_level": "L1",
  "source_file": "data/linkedin/my-post.md",
  "dry_run": false
}
```

**Response:**
```json
{
  "success": true,
  "platform": "linkedin",
  "message": "Posted successfully",
  "timestamp": "2026-03-23T10:00:00",
  "source_file": "data/linkedin/my-post.md"
}
```

**Supported platforms**: linkedin, x, twitter, facebook, instagram, discord, reddit, medium, substack, heygen, beehiiv, mailerlite, brevo

---

### POST `/api/openclaw/batch`
Publish multiple items in sequence.

**Request Body:**
```json
{
  "items": [
    {"platform": "linkedin", "content": "Post 1", "content_type": "update"},
    {"platform": "discord", "content": "Post 2", "content_type": "announcement"}
  ]
}
```

**Response:**
```json
{
  "total": 2,
  "succeeded": 2,
  "failed": 0,
  "results": [...]
}
```

---

### GET `/api/openclaw/status`
Check which platforms have active sessions.

**Response:**
```json
{
  "platforms": {
    "linkedin": {"has_session": true, "ready": true, "session_age": "2026-03-23T09:00:00"},
    "x": {"has_session": false, "ready": false},
    "discord": {"has_session": true, "ready": true, "type": "webhook"}
  }
}
```

---

### GET `/api/openclaw/history?limit=50`
Get recent publish history.

---

## Account Management

### POST `/api/accounts`
Add platform credentials (encrypted).

```json
{"platform": "linkedin", "username": "email@example.com", "password": "your-password"}
```

### GET `/api/accounts`
List configured accounts (passwords hidden).

### DELETE `/api/accounts/{platform}`
Remove platform credentials.

---

## Login / Session Management

### POST `/api/login/{platform}`
Initiate browser login for a platform. Opens a browser window for first-time auth.

### GET `/api/session/{platform}`
Check if a platform session is active.

---

## Content Management

### POST `/api/posts`
Create a post in the queue.

### GET `/api/posts?status=draft`
List posts by status (draft, queued, published, failed).

### POST `/api/posts/{id}/publish`
Publish a specific queued post.

---

## Health

### GET `/api/health`
Server health check.

```json
{"status": "healthy", "version": "2.0.0", "uptime": "3h 45m"}
```
