---
name: workspace-guard
description: Enforce workspace safety boundaries. Use before any file operation to verify the target path is inside the approved workspace. Prevents accidental edits, deletions, or writes outside the designated external drive folder. Triggers on file create, edit, delete, move, or any destructive action.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Workspace Guard

Enforce strict workspace boundaries for all file operations. This is the safety foundation for the entire local AI workspace.

## Approved Workspace Root

```
/Volumes/Expansion/CMO-10million/
```

All file operations MUST target paths inside this root. Nothing outside this path should be created, modified, or deleted.

## Allowed Read/Write Areas

| Path | Permissions |
|---|---|
| `OpenClawData/` | Read + Write |
| `OpenClawData/skills/` | Read + Write |
| `OpenClawData/memory/` | Read + Write |
| `OpenClawData/reports/` | Read + Write |
| `OpenClawData/logs/` | Read + Write |
| `OpenClawData/sessions/` | Read + Write |
| `OpenClawData/prompts/` | Read + Write |
| `OpenClawData/approvals/` | Read + Write |
| `MarketingToolData/` | Read + Write |
| `ExportsLogs/` | Read + Write |
| `TempFiles/` | Read + Write |
| `NotesDocs/` | Read + Write |
| `OllamaModels/` | Read only (managed by Ollama) |

## Restricted Paths (NEVER touch)

- `/Users/` (home directory and all subdirectories, except via symlinks)
- `/Volumes/Expansion/` root level files
- Any folder on `/Volumes/Expansion/` outside `CMO-10million/`
- `/Applications/`
- `/System/`
- Any path not starting with `/Volumes/Expansion/CMO-10million/`

## Rules

1. **Before any file write/create/delete**: Verify the target path starts with `/Volumes/Expansion/CMO-10million/`
2. **Before any destructive action** (delete, overwrite, move): State what will be affected and why
3. **If a task requests action outside workspace**: Stop, explain the boundary, and refuse
4. **OllamaModels is read-only**: Do not manually add, remove, or modify files in `OllamaModels/`. Ollama manages this folder
5. **Log denied actions**: When an action is blocked, write a one-line entry to `OpenClawData/logs/workspace-guard.log` with timestamp, attempted path, and reason

## Verification Check

Before proceeding with any file operation, answer these three questions:

1. Does the target path start with `/Volumes/Expansion/CMO-10million/`?
2. Is the target subfolder in the allowed list above?
3. Is this a destructive action that needs explicit confirmation?

If any answer is "no" or uncertain, stop and explain.

## Drive Mount Check

Before any file operation, verify the external drive is mounted:

```bash
test -d /Volumes/Expansion/CMO-10million && echo "MOUNTED" || echo "NOT MOUNTED"
```

If not mounted, stop all operations and warn the user to connect the external drive.
