---
name: build-log-writer
description: Write founder build-in-public log entries from daily work notes, source notes, and accomplishments. Use for weekly build summaries and founder update posts destined for /build-log. Triggers on build-in-public content, founder updates, or weekly build summaries.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Build Log Writer

Write authentic build-in-public log entries that share the journey of building.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/build-logs/`
- Queue → `OpenClawData/queues/website/pending/`

## Output Format

```markdown
---
title: "<build log title — week of YYYY-MM-DD or specific topic>"
date: "YYYY-MM-DD"
section: "build-log"
type: "founder-update"
tags: [<relevant tags>]
approval_level: "L1"
source_file: "<path to source notes>"
status: "pending"
---

# <Title>

## What I Built This Week

<3-5 bullet points of concrete accomplishments>

## What I Learned

<1-2 key lessons, insights, or realizations>

## What's Next

<2-3 things planned for next week>

## Honest Note

<Optional: 1-2 sentences on challenges, doubts, or real feelings about the work>
```

## Writing Rules

1. First person. This is a personal update from the builder.
2. Concrete over abstract — "shipped X feature" beats "made progress"
3. Include both wins and struggles — authenticity is the whole point
4. Maximum 600 words, aim for 300-400
5. No marketing language — this is a build log, not a press release
6. The "Honest Note" section is optional but encouraged — it builds trust
7. File naming: `build-log-YYYY-MM-DD.md`
