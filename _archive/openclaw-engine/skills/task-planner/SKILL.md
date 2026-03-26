---
name: task-planner
description: Convert goals into practical step-by-step plans with ordered subtasks, dependencies, outputs, and completion criteria. Use when the user states a goal, project, or multi-step objective. Triggers on "plan this", "break this down", "how should I approach", or any complex goal that needs decomposition.
---

# Task Planner

Convert goals into actionable, ordered plans. Keep plans practical — not bloated.

## Default Model

`qwen3:8b` — used for reasoning about task decomposition and dependencies.

## Plan Storage Location

```
/Volumes/Expansion/CMO-10million/OpenClawData/sessions/
```

Plans are saved as Markdown files: `plan-<YYYY-MM-DD>-<brief-slug>.md`

## Plan Format

Every plan must follow this structure:

```markdown
# Plan: <Goal Title>

**Created:** YYYY-MM-DD
**Status:** active | completed | paused | abandoned
**Estimated steps:** <number>

## Goal
<One clear sentence describing the end state>

## Subtasks

### 1. <Task name>
- **Depends on:** none | task number(s)
- **Model:** qwen3:8b | qwen2.5-coder:7b | none
- **Output:** <what this step produces>
- **Done when:** <specific completion criteria>
- **Status:** pending | in-progress | done | blocked

### 2. <Task name>
- **Depends on:** 1
- **Model:** qwen3:8b | qwen2.5-coder:7b | none
- **Output:** <what this step produces>
- **Done when:** <specific completion criteria>
- **Status:** pending

(repeat for each subtask)

## Notes
<Any important context, constraints, or decisions>
```

## Planning Rules

1. **Max 10 subtasks per plan** — if more are needed, split into separate plans
2. **Each subtask must have a clear "done when"** — no vague criteria
3. **Dependencies must be explicit** — "Depends on: 3" not "do this after the other thing"
4. **Assign a model to each subtask** — use local-model-router rules
5. **Order matters** — subtasks are numbered in execution order
6. **No circular dependencies** — task 3 cannot depend on task 5 if task 5 depends on task 3

## When to Create a Plan

- User states a goal with 3+ steps
- User says "plan this" or "break this down"
- A task is complex enough that jumping in would be risky
- Multiple models or tools are involved

## When NOT to Create a Plan

- Single-step tasks ("write a caption")
- Simple lookups ("what models do I have?")
- The user says "just do it"

## Updating Plans

When a subtask is completed:
1. Update its status to `done`
2. Add evidence reference (file path, output, etc.)
3. Check if any blocked tasks are now unblocked
4. Save the updated plan file

## Verification

After creating a plan:
1. Confirm the plan file was saved to `sessions/`
2. Read back the plan summary: goal + number of subtasks
3. Ask the user if the plan looks right before executing
