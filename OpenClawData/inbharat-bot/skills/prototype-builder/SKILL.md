> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: prototype-builder
description: Generate working prototype code from a problem description. Creates deployable mini-apps, tools, scripts, or demos that solve real problems. Triggers on "build prototype", "create demo", "make a tool for", "prototype", or any request to build a quick solution.
---

# Prototype Builder

Generate working, deployable prototype code that solves a specific problem.

## Default Model

`qwen3:8b`

## Prototype Types

| Type | Stack | Output |
|------|-------|--------|
| Web app | HTML + CSS + JavaScript (single file) | index.html |
| API tool | Python (Flask/FastAPI) | app.py + requirements.txt |
| CLI tool | Python or Bash | tool.py or tool.sh |
| Browser extension | HTML + JS + manifest.json | extension/ directory |
| Data dashboard | HTML + Chart.js | dashboard.html |
| AI-powered tool | Python + Ollama integration | app.py |

## Output Format

Generate a complete, runnable prototype. Output as:

```
===FILE: <filename>===
<file contents>
===END===
```

For multi-file projects, output each file in this format.

## Required Sections in Every Prototype

1. **README comment at top** — what this does, how to run it
2. **Working code** — not pseudocode, not skeleton, actual working code
3. **No external dependencies unless essential** — prefer vanilla JS, stdlib Python
4. **Error handling** — basic try/catch, input validation
5. **Mobile-friendly if web** — use responsive CSS

## InBharat AI Branding (when relevant)

- Title: "Built by InBharat AI"
- Colors: #1a73e8 (blue), #34a853 (green), #ffffff (white)
- Footer: "Powered by InBharat AI — AI for India"
- No heavy branding — keep it subtle and professional

## Rules

1. **Working code only** — every prototype must run without modification
2. **Single-file preferred** — keep it simple, one file if possible
3. **No placeholder comments** — write the actual logic, not "TODO: implement"
4. **Include sample data** — if the app needs data, embed sample data
5. **Solve the actual problem** — don't build a generic template, solve the specific issue described
6. **Keep it under 300 lines** — prototypes should be focused
7. **Include run instructions** — how to start it (python app.py, open index.html, etc.)
8. **No fake APIs** — if it needs an API, use a free one or mock the data realistically
9. **Test-ready** — output should work when saved and run immediately
