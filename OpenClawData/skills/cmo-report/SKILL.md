> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: cmo-report
description: Generate or show the latest CMO execution report. Use when asked "show today's report", "what happened today", "daily report", or "generate report".
---

# CMO Report

Generate or display the latest daily/weekly/monthly execution report.

## Show Latest Daily Report
```bash
LATEST=$(ls -t /Volumes/Expansion/CMO-10million/OpenClawData/reports/daily/ | head -1)
cat "/Volumes/Expansion/CMO-10million/OpenClawData/reports/daily/$LATEST"
```

## Generate Fresh Report
```bash
/Volumes/Expansion/CMO-10million/OpenClawData/scripts/reporting-engine-v2.sh --type daily
```

## Show Latest Weekly Report
```bash
LATEST=$(ls -t /Volumes/Expansion/CMO-10million/OpenClawData/reports/weekly/ | head -1)
cat "/Volumes/Expansion/CMO-10million/OpenClawData/reports/weekly/$LATEST"
```

## Model
`qwen3:8b`
