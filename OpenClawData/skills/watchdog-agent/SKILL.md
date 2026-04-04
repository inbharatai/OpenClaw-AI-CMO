---
name: watchdog-agent
description: Self-healing watchdog that detects failures, applies known fixes, and escalates only what it can't solve
version: 1.0.0
category: operations
triggers:
  - watchdog
  - health check
  - system status
  - fix errors
  - self-heal
inputs:
  - mode (optional): check-only | status | full (default: full)
outputs:
  - health report with problems found and fixes applied
  - escalation log for critical issues
honest_classification: executable-script
---

# Watchdog Agent

## Purpose
Autonomous self-healing agent that runs every 15 minutes. Detects failures across the entire OpenClaw/InBharat Bot ecosystem, applies known fixes without human intervention, and escalates ONLY what it cannot solve.

## What It Checks
1. **Ollama** — is the LLM server running? Can it respond?
2. **Gateway** — is the OpenClaw gateway responding on :18789?
3. **Sessions** — are LinkedIn, X, Instagram, Discord sessions valid?
4. **Queues** — is there a backlog > 20 items? Any stale content > 3 days?
5. **Pipeline** — did the daily pipeline run in the last 26 hours? Any stage failures?
6. **Posting** — are posts actually succeeding? Or all failing?
7. **Disk** — is there < 5GB free?
8. **Zombies** — are there orphaned Playwright browser processes?

## What It Fixes Autonomously
| Problem | Fix | Cooldown |
|---------|-----|----------|
| Ollama down | `ollama serve &` | 5 min |
| Gateway down | Kill + restart via gateway-wrapper.sh | 10 min |
| Sessions expired | Run session-keepalive.sh | 6 hours |
| Zombie Playwright | Kill headless chrome/chromium processes | 2 min |
| Stale content | Archive items > 7 days old | 24 hours |
| Pipeline stale | Re-run daily-pipeline.sh (if past 8 AM) | 24 hours |

## What It Escalates (never auto-fixes)
- ALL sessions expired simultaneously — needs manual re-login
- Disk critically low — needs manual cleanup
- All posting attempts failing — needs investigation
- Security issues — never auto-fixed

## Logs
- `logs/watchdog.log` — full check/fix/report log
- `logs/watchdog-state.json` — state persistence (cooldowns, fix counts)
- `logs/watchdog-escalations.log` — critical issues needing human attention

## Usage
```bash
# Full check + fix cycle (what cron runs)
./watchdog-agent.sh

# Just check, don't fix
./watchdog-agent.sh --check-only

# Show current health summary
./watchdog-agent.sh --status
```

## Cron
```
*/15 * * * * /Volumes/Expansion/CMO-10million/OpenClawData/scripts/watchdog-agent.sh
```

---

> **HONEST CLASSIFICATION:** This is an **executable shell script**, not a prompt template.
> It runs autonomously via cron and takes real recovery actions (restart services, kill processes, archive files).
