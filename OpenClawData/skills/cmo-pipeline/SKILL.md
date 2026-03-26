> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: cmo-pipeline
description: Run the AI CMO daily pipeline end-to-end. Triggers intake, newsroom, product updates, content production, approval scoring, distribution, and reporting. Use when asked to "run pipeline", "run daily", "generate content", or "process source material".
---

# CMO Daily Pipeline

Runs the full AI CMO pipeline from the shell.

## Command

```bash
/Volumes/Expansion/CMO-10million/OpenClawData/scripts/daily-pipeline.sh
```

## What It Does

1. **Intake** — Scans source-notes/, source-links/, product-updates/ for new material and classifies it
2. **Newsroom** — Processes AI news into summaries and channel variants
3. **Product Updates** — Formats product notes into website + social content
4. **Content Production** — Generates remaining content from classified sources
5. **Approval** — Scores all pending content through 4-level approval (auto/score-gate/review/block)
6. **Distribution** — Moves approved content to channel queues and exports
7. **Reporting** — Generates daily execution report

## How to Trigger

Say: "run the daily pipeline" or "process today's content" or "run CMO pipeline"

## Workspace

Root: `/Volumes/Expansion/CMO-10million/`
Logs: `OpenClawData/logs/daily-pipeline.log`
Reports: `OpenClawData/reports/daily/`

## Model

Uses qwen3:8b for content and qwen2.5-coder:7b for technical scoring.

## Important

- External drive must be mounted
- Ollama must be running
- Takes ~30-40 minutes for a full run
- LinkedIn is currently BLOCKED by policy
