# Swarm Orchestrator Skill

This skill provides high‑level commands that let you run autonomous, sub‑agent‑driven workflows for outreach, content creation, and periodic summaries. All heavy‑lifting is delegated to short‑lived sub‑agents, while the orchestrator handles coordination, validation, and human approval.

## Commands

- **/swarm run‑outreach** – Collect public contact information for a given region/category, generate a personalized email draft, and (after your approval) send the bulk email.
  ```
  /swarm run‑outreach --region=india --category=vc
  ```
- **/swarm daily‑summary** – Produce the same 6‑line AI‑news + InBharat highlight you already receive, plus a brief note on how many new contacts were added yesterday.
  ```
  /swarm daily‑summary
  ```
- **/swarm refresh‑contacts** – Run the contact collector silently and update the master CSV used by outreach runs.
  ```
  /swarm refresh‑contacts --region=asia
  ```

## How it works

1. The orchestrator spawns sub‑agents via `sessions_spawn` (runtime = subagent) for each atomic step (collector, validator, draft‑maker, sender).
2. Each sub‑agent writes its output to `memory/swarm/` in a well‑defined JSON/CSV format.
3. Before any bulk send the orchestrator posts a WhatsApp summary and waits for a reply of **approve** or **reject**.
4. On approval the sender sub‑agent uses your Zoho SMTP credentials (stored in `~/.openclaw/secrets.json`).
5. All actions are logged to `OpenClawData/logs/swarm.log` for audit.

## Safety

- Only public organization‑level contacts are ever harvested. Private personal emails are filtered out by the validator.
- Every bulk send requires an explicit human approval step.
- The system never bypasses `robots.txt` or CAPTCHAs.
- Secrets are read from the OpenClaw secret store and never committed to the repo.

## Development

- The main entry point is `orchestrator.js`.
- Helper utilities live under `utils/`.
- Templates for drafts are in `templates/`.
- Unit tests are under `tests/` and run on every push via GitHub Actions.
