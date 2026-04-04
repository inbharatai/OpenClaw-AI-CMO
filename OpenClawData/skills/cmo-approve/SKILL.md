---
name: cmo-approve
description: Show items in the review queue and approve or block them. Use when asked to "approve content", "show review queue", "what needs approval", or "approve item X".
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# CMO Approval Manager

View and manage the content approval queue.

## Review Queue

List items waiting for human review:
```bash
ls /Volumes/Expansion/CMO-10million/OpenClawData/approvals/review/*.md 2>/dev/null | grep -v "^\."
```

## To Approve an Item

Move it from review to the appropriate channel's approved queue:
```bash
mv "/Volumes/Expansion/CMO-10million/OpenClawData/approvals/review/<filename>" "/Volumes/Expansion/CMO-10million/OpenClawData/queues/<channel>/approved/"
```

## To Block an Item

Move it to blocked:
```bash
mv "/Volumes/Expansion/CMO-10million/OpenClawData/approvals/review/<filename>" "/Volumes/Expansion/CMO-10million/OpenClawData/approvals/blocked/"
```

## Safety Rules
- Always show the content before approving
- Never auto-approve items in the review queue without explicit confirmation
- Log every approval/block action

## Model
`qwen3:8b`
