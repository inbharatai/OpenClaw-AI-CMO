# Folder-to-Skill Mapping

Which agents/skills read and write to which folders.

---

## Intake Engine

| Action | Folders |
|--------|---------|
| **Reads** | `data/source-notes/`, `data/source-links/`, `data/screenshots/` |
| **Writes** | `.meta.json` sidecar files, `logs/intake-processor.log` |

## Newsroom Agent

| Action | Folders |
|--------|---------|
| **Reads** | `data/source-links/` (tagged files) |
| **Writes** | `data/ai-news/`, `data/discord/`, `data/linkedin/`, `data/x/`, `data/website-posts/` |

## Product Update Agent

| Action | Folders |
|--------|---------|
| **Reads** | `data/source-notes/` (tagged files) |
| **Writes** | `data/product-updates/`, `data/discord/`, `data/linkedin/`, `data/x/`, `data/website-posts/` |

## Content Agent

| Action | Folders |
|--------|---------|
| **Reads** | `data/ai-news/`, `data/product-updates/`, all channel folders |
| **Writes** | `data/linkedin/`, `data/x/`, `data/facebook/`, `data/instagram/`, `data/discord/`, `data/reddit/`, `data/medium/`, `data/substack/`, `data/newsletters/`, `data/website-posts/`, `data/video-briefs/`, `data/image-briefs/` |

## Approval Engine

| Action | Folders |
|--------|---------|
| **Reads** | All `data/<channel>/` folders (new content) |
| **Writes** | `approvals/approved/`, `approvals/blocked/`, `approvals/review/`, `approvals/pending/` |
| **Config** | `openclaw-engine/policies/approval-rules.json` |

## Distribution Engine

| Action | Folders |
|--------|---------|
| **Reads** | `approvals/approved/` |
| **Writes** | `queues/<channel>/`, `exports/posted/`, `exports/email/ready-to-send/` |
| **API** | SocialFlow `http://localhost:8000/api/openclaw/publish` |

## Reporting Engine

| Action | Folders |
|--------|---------|
| **Reads** | `logs/`, `approvals/`, `exports/posted/`, all pipeline logs |
| **Writes** | `reports/daily/`, `reports/weekly/`, `reports/monthly/` |

## Memory Writer

| Action | Folders |
|--------|---------|
| **Reads/Writes** | `openclaw-engine/memory/hq/`, `memory/newsroom/`, `memory/product/`, `memory/content/`, `memory/approval/`, `memory/distribution/`, `memory/reporting/` |

## SocialFlow

| Action | Folders |
|--------|---------|
| **Reads** | Content from OpenClaw bridge API |
| **Writes** | `socialflow/sessions/` (browser sessions), `socialflow/backend/openclaw_bridge_log.json` |
| **Database** | `socialflow/backend/socialflow.db` |

---

## Full Folder Map

```
data/
  source-notes/      ← YOU write here
  source-links/      ← YOU write here
  screenshots/       ← YOU drop files here
  ai-news/           ← Newsroom Agent writes
  product-updates/   ← Product Agent writes
  website-posts/     ← Content Agent writes
  linkedin/          ← Content Agent writes
  x/                 ← Content Agent writes
  facebook/          ← Content Agent writes
  instagram/         ← Content Agent writes
  discord/           ← Content Agent writes
  reddit/            ← Content Agent writes
  medium/            ← Content Agent writes
  substack/          ← Content Agent writes
  newsletters/       ← Content Agent writes
  email/             ← Newsletter Exporter writes
  video-briefs/      ← Content Agent writes
  image-briefs/      ← Content Agent writes
  weekly-roundups/   ← Weekly Pipeline writes
  build-logs/        ← Build Log Writer writes
  comparison-posts/  ← Content Agent writes

approvals/
  pending/           ← Approval Engine writes
  approved/          ← Approval Engine writes (content ready to post)
  blocked/           ← Approval Engine writes (rejected content)
  review/            ← Approval Engine writes (needs human review)

queues/              ← Distribution Engine writes
exports/posted/      ← Distribution Engine writes (archive of posted)
reports/             ← Reporting Engine writes
logs/                ← All agents write logs here
```
