---
name: memory-writer
description: Persist durable operating knowledge to organized workspace memory files. Use when saving brand voice rules, campaign preferences, prompt templates, recurring instructions, lessons learned, important decisions, or project context. Triggers when the user says "remember this", "save this for later", "store this", or when important reusable knowledge is identified during a session.
---

# Memory Writer

Persist important knowledge to Markdown files in the workspace memory folder so it survives across sessions.

## Default Model

`qwen3:8b` — used for summarizing and structuring memory entries when needed.

## Memory Storage Location

```
/Volumes/Expansion/CMO-10million/OpenClawData/memory/
```

## Memory Categories

Each category is a separate Markdown file. Create on first write.

| File | Purpose | Examples |
|---|---|---|
| `brand-voice.md` | Tone, style, personality rules | "Always use casual, confident tone" |
| `campaign-preferences.md` | Recurring campaign settings | "Prefer carousel posts for product launches" |
| `prompt-templates.md` | Reusable prompt patterns | Tested prompts that work well |
| `recurring-instructions.md` | Standing orders | "Always include CTA in captions" |
| `lessons-learned.md` | What worked, what didn't | "Short captions outperform long ones on IG" |
| `decisions-log.md` | Important choices and reasoning | "Chose qwen3:8b for marketing tasks because..." |
| `project-context.md` | Active project summaries | Current campaigns, goals, deadlines |

## Memory Entry Format

Every entry must follow this format:

```markdown
## [YYYY-MM-DD] Brief Title

**Category:** <category name>
**Source:** <where this came from — user instruction, session observation, test result>

<Content of the memory entry>

---
```

Append new entries to the end of the appropriate file. Never overwrite existing entries unless the user explicitly asks to update a specific one.

## When to Write Memory

1. **User explicitly says** "remember this", "save this", "store this for later"
2. **A reusable pattern is identified** — a prompt that worked well, a workflow that succeeded
3. **An important decision is made** — model choice, tool preference, campaign direction
4. **A lesson is learned** — something failed and we know why, or something succeeded unexpectedly
5. **Brand or voice rules are stated** — the user defines how they want content to sound

## When NOT to Write Memory

- Temporary debugging notes
- One-off test results with no future value
- Speculative ideas that haven't been confirmed
- Raw data dumps without summary

## Reading Memory

Before starting marketing, content, or planning tasks, check relevant memory files:

```bash
ls /Volumes/Expansion/CMO-10million/OpenClawData/memory/
```

Read the relevant file(s) to load context before generating output.

## Verification

After writing a memory entry:
1. Confirm the file exists and the entry was appended
2. State: "Memory saved to `<filename>`: <brief title>"
3. Do not claim success without checking the file
