---
name: safe-code-edit
description: Make safe, targeted code edits with backup and verification. Use when the user needs to modify code files with safety checks, backups, and diff verification. Triggers on "edit this code", "fix this file", "change this function", "update the code", or any code modification request that requires safety discipline.
---

# Safe Code Edit

Make targeted code changes with safety rails: backup first, edit carefully, verify after.

## Default Model

`qwen2.5-coder:7b` — purpose-built for code editing, syntax awareness, and technical precision.

## Safe Edit Process

### 1. Pre-Edit
- **Read the file** — understand what exists before changing it
- **Identify scope** — what exactly needs to change? (function, block, line)
- **Check workspace guard** — is this file inside the approved workspace?

### 2. Backup
Before any edit, create a backup:
```bash
cp <file> <file>.backup-YYYYMMDD-HHMMSS
```
Store backups in the same directory as the original file.

### 3. Edit
- Make the **minimum change** needed to accomplish the goal
- Do not refactor unrelated code in the same edit
- Preserve existing code style (indentation, naming conventions)

### 4. Verify
After editing:
- **Syntax check** — does the file parse correctly?
- **Diff review** — show what changed
- **Run tests** if available — do existing tests still pass?

### 5. Report
After every edit, produce:
```
FILE: <path>
CHANGE: <what was modified>
BACKUP: <backup file path>
DIFF: <summary of changes>
TESTS: <pass/fail/none>
```

## Rules

1. **Never edit without reading first** — understand before changing
2. **Never edit outside workspace** — workspace-guard rules apply
3. **Always backup** — no exceptions
4. **One logical change per edit** — don't bundle unrelated changes
5. **If uncertain, show the proposed change first** — let the user approve before applying
6. **OllamaModels is off-limits** — never modify model files

## Rollback

If an edit causes problems:
```bash
cp <file>.backup-YYYYMMDD-HHMMSS <file>
```

Always confirm the rollback restored the original state.
