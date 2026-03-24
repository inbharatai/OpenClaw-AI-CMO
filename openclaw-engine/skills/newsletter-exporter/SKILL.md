---
name: newsletter-exporter
description: Export approved newsletter drafts into platform-ready format for Substack, beehiiv, MailerLite, or Brevo. Prepares the newsletter for manual send or API integration. Triggers on newsletter export or email distribution preparation.
---

# Newsletter Exporter

Export approved newsletter content into platform-ready format.

## Default Model

`qwen2.5-coder:7b`

## Input

Approved newsletters from `OpenClawData/queues/email/approved/`

## Output

`ExportsLogs/email/ready-to-send/`

## Export Formats

### Substack (V1 — manual paste)
```markdown
---
export_format: "substack"
subject: "<subject line>"
subtitle: "<preview text>"
exported_date: "YYYY-MM-DD"
---

<newsletter body in markdown>
```

### beehiiv (V2 — API or paste)
Same as Substack format. beehiiv accepts markdown.

### MailerLite (V2 — API)
```html
<!-- MailerLite ready -->
<subject><subject line></subject>
<body>
<newsletter body converted to simple HTML>
</body>
```

### Brevo (V3 — API)
Similar HTML format with Brevo-specific template markers.

## Export Flow

1. Read approved newsletter from queue
2. Determine target platform (default: Substack in V1)
3. Format content for target platform
4. Save to `ExportsLogs/email/ready-to-send/newsletter-YYYY-MM-DD.md`
5. Log export to `OpenClawData/logs/newsletter-export.log`

## Rules

1. Never auto-send in V1 — export only, manual send
2. Subject line must be under 60 characters
3. Always include the original approval record reference
4. Check rate limits before export (max 1 newsletter/day)
