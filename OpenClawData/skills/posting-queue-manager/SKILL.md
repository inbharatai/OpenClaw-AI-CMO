> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: posting-queue-manager
description: Manage the content posting queues — track what is pending, approved, posted, and archived across all channels. Use for queue status checks, cleanup, and archive operations. Triggers on queue management, status checks, or archive requests.
---

# Posting Queue Manager

Track and manage content across all channel queues.

## Default Model

`qwen2.5-coder:7b`

## Queue Structure

```
OpenClawData/queues/{channel}/
├── pending/    ← awaiting approval
└── approved/   ← approved, ready for distribution
```

Post-distribution, content is logged to `ExportsLogs/posted/`.

## Operations

### Status Check
List all items in all queues with counts per channel per status.

Output format:
```
QUEUE STATUS — YYYY-MM-DD
Channel      | Pending | Approved | Posted Today
-------------|---------|----------|-----------
website      |    3    |    2     |     1
discord      |    1    |    1     |     2
linkedin     |    2    |    0     |     0
...
TOTAL        |   12    |    5     |     4
```

### Archive
Move approved items older than 7 days to `ExportsLogs/archive/`.

### Cleanup
Remove empty metadata files, orphaned .meta.json files without source.

## Rules

1. Never delete source content — only move or archive
2. Log all queue operations to `OpenClawData/logs/queue-manager.log`
3. Archive preserves full file including frontmatter
