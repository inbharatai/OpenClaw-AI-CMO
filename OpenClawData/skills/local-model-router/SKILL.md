---
name: local-model-router
description: Route tasks to the correct local Ollama model. Use when deciding which local LLM to use for a task. Routes strategy, writing, marketing, and planning to qwen3:8b. Routes coding, scripts, automation, and technical tasks to qwen2.5-coder:7b. Triggers on any task that needs local LLM inference.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Local Model Router

Deterministic routing of tasks to the correct local Ollama model. No random selection. Every routing decision is explainable.

## Available Models

| Model | Ollama Name | Strength | Size |
|---|---|---|---|
| Qwen3 8B | `qwen3:8b` | Strategy, writing, marketing, summaries, planning, creative | ~5 GB |
| Qwen2.5 Coder 7B | `qwen2.5-coder:7b` | Coding, scripts, automation, technical edits, file handling | ~4.5 GB |

## Ollama Connection

```
Base URL: http://127.0.0.1:11434
Health check: curl http://127.0.0.1:11434/api/tags
```

## Routing Rules

### Route to qwen3:8b

Use for ANY task involving:
- Marketing strategy or campaign planning
- Content writing (captions, posts, articles, emails)
- Brand voice or tone adjustments
- Rewriting or rephrasing text
- Summarizing documents or conversations
- Creative brainstorming
- Business planning or analysis
- Customer communication drafts
- Research synthesis or reporting

### Route to qwen2.5-coder:7b

Use for ANY task involving:
- Writing code (Python, JavaScript, Bash, etc.)
- Debugging or fixing code
- Script automation
- File parsing or data processing
- API integration logic
- JSON/CSV/data manipulation
- Technical documentation with code examples
- Build/deploy configuration
- Regular expressions or text pattern matching

### Ambiguous Tasks

If a task mixes both types (e.g., "write a Python script that generates marketing captions"):
1. Identify the **primary output format**
2. If the output is **code** → route to `qwen2.5-coder:7b`
3. If the output is **text/content** → route to `qwen3:8b`
4. When truly 50/50, default to `qwen3:8b`

## Fallback Rules

1. If the selected model fails to respond within 60 seconds, retry once
2. If retry fails, try the other model
3. If both models fail, check if Ollama is running: `curl http://127.0.0.1:11434/api/tags`
4. If Ollama is down, report the error clearly — do not fabricate output

## Logging

For every routed task, record in `OpenClawData/logs/model-routing.log`:

```
[TIMESTAMP] Task: <brief description> → Model: <model name> | Reason: <routing reason>
```

## Pre-Flight Check

Before routing any task:

```bash
curl -s http://127.0.0.1:11434/api/tags | grep -o '"name":"[^"]*"'
```

Verify both `qwen3:8b` and `qwen2.5-coder:7b` appear in the output.
