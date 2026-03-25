# Contributing to OpenClaw AI CMO

Thanks for your interest in contributing! This project is built for solo builders, by a solo builder.

---

## How to Contribute

### Reporting Bugs
- Open an issue with the `bug` label
- Include: what you expected, what happened, steps to reproduce
- Include your OS, Python version, Ollama version

### Suggesting Features
- Open an issue with the `enhancement` label
- Describe the use case, not just the feature
- Explain how it fits the solo builder workflow

### Adding a New Skill
1. Create `openclaw-engine/skills/your-skill-name/SKILL.md`
2. Follow the existing skill format (see any skill for reference)
3. Test with `openclaw-engine/scripts/skill-runner.sh your-skill-name`
4. Submit a PR

### Adding a New Platform
1. Add automation class in `socialflow/backend/automation_extended.py`
2. Follow the existing pattern (login, check_login, post methods)
3. Add to `openclaw_bridge.py` supported platforms list
4. Add rate limit config in `openclaw-engine/policies/rate-limits.json`
5. Add channel policy in `openclaw-engine/policies/channel-policies.json`
6. Test with dry_run first
7. Submit a PR

### Improving Documentation
- Fix typos, add examples, improve clarity
- All docs are in `docs/`

---

## Development Setup

```bash
git clone https://github.com/inbharatai/OpenClaw-AI-CMO.git
cd OpenClaw-AI-CMO
./setup.sh
```

## Code Style

- Shell scripts: Use `shellcheck` compatible style
- Python: Follow PEP 8
- Markdown: Use ATX headings, keep lines under 120 chars

## Pull Request Process

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test locally
5. Submit a PR with a clear description

---

## Code of Conduct

Be respectful, constructive, and helpful. We're all here to build useful things.
