# Decisions Log

## [2026-03-22] Wave 1 Skills Architecture

**Category:** Architecture
**Source:** Phase A inspection of OpenClaw codebase

Decided to implement 6 Wave 1 skills as SKILL.md files following the existing OpenClaw pattern:
1. workspace-guard — safety boundary enforcement
2. local-model-router — deterministic model routing
3. memory-writer — persistent knowledge storage
4. verification-evidence — proof-based completion
5. task-planner — goal decomposition
6. reporting — execution summaries

Skills stored on external drive at `/Volumes/Expansion/CMO-10million/OpenClawData/skills/` and symlinked to `~/.openclaw/workspace/skills/` for auto-loading.

Model routing defaults:
- qwen3:8b → strategy, writing, marketing, summaries, planning
- qwen2.5-coder:7b → coding, scripts, automation, technical tasks

Ollama base URL: http://127.0.0.1:11434

---
