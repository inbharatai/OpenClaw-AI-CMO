> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: session-compaction
description: Compact long sessions by summarizing completed work and archiving verbose outputs to keep context clean and focused. Use when a session becomes long, context feels cluttered, or the user says "clean up", "compact this session", "archive what we've done", or when conversation history exceeds practical working length.
---

# Session Compaction

Keep working sessions clean by archiving completed work and summarizing progress.

## Default Model

`qwen3:8b` — strong at summarization and structured compression.

## When to Compact

- Session has been running for 20+ exchanges
- Multiple tasks have been completed
- Context feels cluttered with old outputs
- User asks to "clean up" or "start fresh"

## Compaction Process

### 1. Summarize Completed Work
Create a compact summary of everything done so far:
```markdown
## Session Summary (compacted YYYY-MM-DD HH:MM)

### Completed
1. <task> → <outcome>
2. <task> → <outcome>

### Files Changed
- <path> — <what changed>

### Active/Pending
- <what's still in progress>

### Key Decisions
- <any decisions made during session>
```

### 2. Archive Verbose Outputs
Save full outputs to `OpenClawData/sessions/`:
```
session-archive-YYYY-MM-DD-HHMMSS.md
```

### 3. Carry Forward Context
After compaction, the active context should contain only:
- The compact summary
- Any active/pending tasks
- Current working state

## Rules

1. **Never lose information** — archive everything before compacting
2. **Preserve decisions** — key decisions must survive compaction
3. **Preserve file paths** — all created/modified file paths must survive
4. **Keep pending tasks** — only completed work gets archived
5. Save archives to `OpenClawData/sessions/`
6. This skill is advisory — actual context management depends on the runtime
