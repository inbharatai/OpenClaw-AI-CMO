---
name: human-in-the-loop-approval
description: Require explicit human approval before executing high-impact actions like publishing content, sending emails, deploying code, making purchases, or any irreversible action. Triggers on any action marked as requiring approval, or when the user says "check with me first", "I want to approve this", "don't do anything without my OK".
---

# Human-in-the-Loop Approval

Require explicit human confirmation before executing high-impact or irreversible actions.

## Default Model

N/A — this is a process skill, not an LLM task.

## Actions Requiring Approval

### Always Require Approval
- Publishing content to any platform
- Sending emails or messages on behalf of the user
- Deploying code to production
- Deleting files or data
- Making financial transactions
- Modifying access permissions
- Submitting forms with personal/business data
- Running scripts that modify files in bulk

### Approval Optional (but recommended)
- Creating new files in the workspace
- Running read-only analysis
- Generating draft content (not publishing)
- Internal report generation

## Approval Process

### 1. Present the Action
Before executing, clearly state:
```
ACTION REQUIRING APPROVAL:
What: <exactly what will happen>
Where: <which platform/file/system>
Impact: <what changes>
Reversible: Yes / No / Partially

Approve? (yes/no)
```

### 2. Wait for Response
- **"yes" / "go" / "approved"** → proceed
- **"no" / "stop" / "wait"** → halt and ask what to change
- **Silence / no response** → do NOT proceed

### 3. Log the Decision
After approval or rejection, log to `OpenClawData/approvals/`:

```markdown
[YYYY-MM-DD HH:MM] ACTION: <what>
DECISION: approved | rejected
REASON: <user's reasoning if provided>
```

## Approval Storage

```
/Volumes/Expansion/CMO-10million/OpenClawData/approvals/approvals-YYYY-MM.md
```

One file per month, append entries.

## Rules

1. **When in doubt, ask** — better to over-ask than to act without permission
2. **Never assume approval** — previous approvals don't carry forward
3. **Show what will happen** — the user must understand the action before approving
4. **Log every decision** — approvals and rejections are both valuable records
5. **Irreversible actions always require approval** — no exceptions
6. **Batch approvals are OK** — "approve all 5 posts" is valid if user reviews the list
