---
name: daily-briefing
description: Generate a daily briefing summarizing active tasks, pending items, recent changes, and priorities. Use at the start of a work session to get oriented, or when the user asks "what's going on", "status update", "daily summary", "what should I focus on today", or any session kickoff request.
---

# Daily Briefing

Generate a quick situational awareness summary at the start of each work session.

## Default Model

`qwen3:8b` — strong at summarization and priority assessment.

## Briefing Process

### 1. Check Active Plans
Read all files in `OpenClawData/sessions/` and list any active plans with pending tasks.

### 2. Check Recent Reports
Read the most recent file(s) in `OpenClawData/reports/` to see what was accomplished last session.

### 3. Check Memory Updates
Check `OpenClawData/memory/` for any recent changes (by file modification date).

### 4. Check System Health
```bash
# Drive mounted?
test -d /Volumes/Expansion/CMO-10million && echo "Drive: OK" || echo "Drive: NOT MOUNTED"

# Ollama running?
curl -s --max-time 3 http://127.0.0.1:11434/api/tags > /dev/null 2>&1 && echo "Ollama: OK" || echo "Ollama: DOWN"

# Models available?
ollama list 2>/dev/null | grep -c "qwen"
```

## Briefing Output Format

```markdown
# Daily Briefing — YYYY-MM-DD

## System Status
- Drive: ✅ Mounted | ❌ Not mounted
- Ollama: ✅ Running | ❌ Down
- Models: ✅ Both available | ⚠️ Missing model(s)

## Active Plans
- <plan name> — <X of Y tasks complete>
- <plan name> — <status>
(or "No active plans")

## Last Session Summary
- <what was done last time>

## Pending Items
1. <most important thing to do>
2. <second most important>
3. <third>

## Recommended Focus Today
<1-2 sentences on what to prioritize>
```

## Rules

1. **Keep it under 30 seconds to read** — this is a glance, not a novel
2. **System status first** — know if your tools work before planning work
3. **Prioritize by impact** — most important pending item first
4. **Be honest about blockers** — if something is stuck, say so
5. Do not save briefings to disk unless the user asks — they're ephemeral
