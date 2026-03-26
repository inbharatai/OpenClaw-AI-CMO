> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: reporting
description: Generate concise execution reports after completing work. Use after any significant task, session, or multi-step workflow. Triggers on "give me a report", "what did we do", "summarize the session", or automatically after completing a plan or major task.
---

# Reporting

Generate clear, honest execution reports after work is done. No fluff. No fake success.

## Default Model

`qwen3:8b` — used for summarizing execution results into readable reports.

## Report Storage Location

```
/Volumes/Expansion/CMO-10million/OpenClawData/reports/
```

Reports are saved as: `report-<YYYY-MM-DD>-<brief-slug>.md`

## Report Format

```markdown
# Execution Report: <Title>

**Date:** YYYY-MM-DD
**Duration:** <approximate time or session length>
**Status:** completed | partial | failed

## What Was Attempted
<1-3 sentences describing the goal>

## What Succeeded
- <action> → <result with evidence>
- <action> → <result with evidence>

## What Failed
- <action> → <error or reason>
(If nothing failed, write "Nothing failed.")

## Evidence Produced
| Type | Path / Detail |
|---|---|
| File created | `/path/to/file` |
| Log entry | `logs/model-routing.log` line 15 |
| Test result | Model responded correctly to test prompt |

## Files Created or Changed
- `<path>` — <what changed>
- `<path>` — <what changed>

## Recommendations / Next Steps
1. <Next logical action>
2. <Next logical action>

## Models Used
- qwen3:8b: <what it was used for>
- qwen2.5-coder:7b: <what it was used for>
(List only models actually used)
```

## When to Generate a Report

1. After completing a **plan** (from task-planner)
2. After a **multi-step session** with significant work
3. When the user asks: "what did we do?", "give me a summary", "report"
4. After any **failed operation** — failure reports are just as important

## Report Rules

1. **Honesty first** — never inflate results or hide failures
2. **Evidence required** — every claim in the report must reference a file, output, or log
3. **Be concise** — reports should be scannable in under 2 minutes
4. **Include next steps** — always end with what should happen next
5. **Save to disk** — every report gets saved to `reports/` folder

## Quick Session Summary

For lightweight end-of-session summaries (not full reports):

```
SESSION SUMMARY — YYYY-MM-DD
Tasks completed: <count>
Tasks failed: <count>
Key files: <list paths>
Next: <one sentence>
```

## Verification

After generating a report:
1. Confirm the report file exists in `reports/`
2. State the filename and path
3. Confirm evidence references are valid (files exist, logs have entries)
