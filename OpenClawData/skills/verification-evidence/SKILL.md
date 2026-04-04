---
name: verification-evidence
description: Prevent false completion claims by requiring evidence for every completed task. Use after any task execution to verify results. Triggers when marking a task as done, generating a completion report, or when the user asks "did that work?" or "prove it". No task is complete without at least one form of evidence.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Verification and Evidence

No task is marked complete without proof. This skill enforces evidence-based completion for all work.

## Core Rule

**Every completed task must include at least one form of evidence.**

No exceptions. If evidence cannot be produced, the task is NOT complete — it is "unverified" or "failed".

## Accepted Evidence Types

| Evidence Type | Example | When to Use |
|---|---|---|
| **File path** | `/Volumes/Expansion/CMO-10million/OpenClawData/reports/2026-03-22-report.md` | File was created or modified |
| **File content snippet** | First 5 lines of created file | New file with specific content |
| **Diff summary** | "Added 15 lines to brand-voice.md" | Existing file was modified |
| **Command output** | Output of `ls`, `cat`, `ollama list` | System state was verified |
| **Log entry** | Timestamp + action from a log file | Action was logged |
| **Test result** | Model response to a test prompt | Model was tested |
| **Error message** | Exact error text | Task failed (still evidence) |

## Completion Report Format

After any non-trivial task, produce a completion block:

```
TASK: <what was attempted>
STATUS: completed | failed | partial
EVIDENCE:
  - <evidence type>: <evidence detail>
  - <evidence type>: <evidence detail>
FILES CHANGED:
  - <path> (created | modified | deleted)
NEXT STEPS: <if any>
```

## Rules

1. **Never say "done" without evidence** — always show what changed
2. **If a file was created**, show the path and confirm it exists with `ls` or `test -f`
3. **If a command was run**, show its output (or relevant excerpt)
4. **If something failed**, show the error — failure with evidence is better than fake success
5. **Partial completion is valid** — say what was done and what remains
6. **Store evidence reports** in `OpenClawData/reports/` for important tasks

## Anti-Patterns to Avoid

- "I've completed the task" (no evidence)
- "The file has been created" (without showing path or verifying)
- "Everything is working" (without a test)
- "Done!" (without any proof)

## Verification Commands

Quick checks to verify common actions:

```bash
# File exists?
test -f <path> && echo "EXISTS" || echo "MISSING"

# File has content?
wc -l <path>

# Ollama model available?
ollama list | grep <model-name>

# Ollama responding?
curl -s http://127.0.0.1:11434/api/tags | head -1

# Drive mounted?
test -d /Volumes/Expansion/CMO-10million && echo "MOUNTED" || echo "NOT MOUNTED"
```
