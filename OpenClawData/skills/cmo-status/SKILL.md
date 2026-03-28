---
name: cmo-status
description: Show the current CMO pipeline status — queue counts, approval state, recent logs, last run time. Use when asked "what's the status", "show queues", "what was posted today", or "pipeline status".
---

# CMO Status Check

Reports on the current state of the AI CMO pipeline.

## What to Check

Run these commands and summarize the results:

### Queue State
```bash
for ch in website discord x facebook instagram reddit medium substack email heygen; do
  pending=$(find "/Volumes/Expansion/CMO-10million/OpenClawData/queues/$ch/pending" -type f -not -name ".*" 2>/dev/null | wc -l | tr -d ' ')
  approved=$(find "/Volumes/Expansion/CMO-10million/OpenClawData/queues/$ch/approved" -type f -not -name ".*" 2>/dev/null | wc -l | tr -d ' ')
  [ "$pending" -gt 0 ] || [ "$approved" -gt 0 ] && echo "$ch: pending=$pending approved=$approved"
done
```

### Approval State
```bash
echo "Pending review: $(find /Volumes/Expansion/CMO-10million/OpenClawData/approvals/review -type f -name '*.md' -not -name '.*' 2>/dev/null | wc -l | tr -d ' ')"
echo "Blocked today: $(find /Volumes/Expansion/CMO-10million/OpenClawData/approvals/blocked -type f -name '*$(date +%Y-%m-%d)*' -not -name '.*' 2>/dev/null | wc -l | tr -d ' ')"
```

### Last Pipeline Run
```bash
tail -5 /Volumes/Expansion/CMO-10million/OpenClawData/logs/daily-pipeline.log
```

### Latest Report
```bash
ls -t /Volumes/Expansion/CMO-10million/OpenClawData/reports/daily/ | head -1
```

## Model
`qwen3:8b`
