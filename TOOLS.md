# TOOLS.md — InBharat Builder Environment

## Workspace

- **Root:** /Volumes/Expansion/CMO-10million
- **Scripts:** OpenClawData/scripts/ (18 CMO pipeline scripts)
- **Bot:** OpenClawData/inbharat-bot/ (scanner, gap-finder, proposals, bridge)
- **Skills:** OpenClawData/skills/ (64 prompt templates)
- **Queues:** OpenClawData/queues/ (12 channel queues)
- **Policies:** OpenClawData/policies/ (4 policy JSONs)

## Shell Commands

```bash
# Git
git clone <url>
git status
git log --oneline

# HTTP fetch
curl -sL <url>

# Ollama inference
curl -s http://127.0.0.1:11434/api/generate -d '{"model":"qwen3:8b","prompt":"..."}'

# InBharat Bot
bash OpenClawData/inbharat-bot/inbharat-run.sh full|scan|analyze|propose|bridge|status

# CMO Pipeline
bash OpenClawData/scripts/daily-pipeline.sh
```

## GitHub Repos

- OpenClaw-AI-CMO, agent-arcade-gateway, claude-skills, phoring
- SocialFlow, sahaayak-ai-public, sahaayakseva-public
- testsprep.in, uniassist.ai, inbharatai

## Models

- qwen3:8b → reasoning, marketing, writing
- qwen2.5-coder:7b → code, scripts, automation
