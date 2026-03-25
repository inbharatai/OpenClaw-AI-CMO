# InBharat Bot v1.0

**Role:** Central ecosystem intelligence and builder operations bot for the InBharat ecosystem.

## What it does

InBharat Bot scans your ecosystem, identifies gaps and opportunities, generates structured build proposals, and bridges findings into the CMO content pipeline.

## Architecture

```
inbharat-run.sh (orchestrator)
  ├── scanner/ecosystem-scanner.sh    → reads workspace, produces registry
  ├── gap-finder/gap-finder.sh        → analyzes scan, finds gaps/opportunities
  ├── proposal-generator/proposal-generator.sh  → converts findings into proposals
  ├── cmo-bridge/cmo-bridge.sh        → converts proposals into CMO source material
  ├── dashboard/generate-state.sh     → produces state JSON + status report
  ├── approval/approval-gate.sh       → classifies actions by risk level
  └── logging/bot-logger.sh           → shared logging layer
```

## Usage

```bash
# Full cycle: scan → analyze → propose → bridge → status
bash inbharat-run.sh full

# Individual modules
bash inbharat-run.sh scan
bash inbharat-run.sh analyze
bash inbharat-run.sh propose
bash inbharat-run.sh bridge
bash inbharat-run.sh status
```

## Action Classification

| Level | Examples | Auto? |
|-------|---------|-------|
| observe | scan, read files | yes |
| infer | gap analysis, scoring | yes |
| propose | generate proposals | yes |
| act | modify files, create tasks | review required |
| publish | post content, send emails | blocked until approved |

## Models Used

- **qwen3:8b** — reasoning, analysis, writing, proposals
- **qwen2.5-coder:7b** — coding, scripts, technical analysis

## Key Paths

- Config: `config/bot-config.json`
- Scans: `registry/ecosystem-scan-*.md`
- Findings: `gap-finder/findings-*.md`
- Proposals: `proposal-generator/proposals-*.md`
- CMO bridge: `cmo-bridge/bridge-output-*.md`
- Dashboard state: `dashboard/bot-state.json`
- Logs: `logging/bot-YYYY-MM-DD.log`
