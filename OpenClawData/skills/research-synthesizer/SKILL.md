---
name: research-synthesizer
description: Synthesize research from multiple sources into clear, actionable summaries. Use when the user provides articles, data, notes, or documents to be combined into a coherent analysis. Triggers on "synthesize this research", "summarize these sources", "combine these findings", "what does the research say", or any multi-source analysis request.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Research Synthesizer

Combine information from multiple sources into clear, structured, actionable summaries.

## Default Model

`qwen3:8b` — strong at reasoning across sources, identifying patterns, and structured summarization.

## Storage

- Research outputs → `MarketingToolData/research/`
- Key findings also logged to `OpenClawData/memory/lessons-learned.md` when significant

## Synthesis Process

### 1. Gather Sources
- List all input sources with brief descriptions
- Note the type of each source (article, data, interview, report, notes)

### 2. Extract Key Findings
From each source, extract:
- Main argument or finding
- Supporting evidence
- Limitations or caveats
- Relevance to the user's goal

### 3. Identify Patterns
Across all sources:
- What do multiple sources agree on?
- Where do sources disagree?
- What gaps exist in the research?

### 4. Synthesize

Output format:
```markdown
# Research Synthesis: <Topic>

**Date:** YYYY-MM-DD
**Sources:** <count> sources analyzed

## Key Findings
1. <finding> — supported by <sources>
2. <finding> — supported by <sources>
3. <finding> — supported by <sources>

## Consensus Points
- <what most sources agree on>

## Disagreements
- <where sources conflict and why>

## Gaps
- <what's missing from the research>

## Actionable Takeaways
1. <what to do based on this research>
2. <what to do based on this research>

## Sources
1. <source 1> — <brief note>
2. <source 2> — <brief note>
```

## Rules

1. **Never invent findings** — only include what the sources actually say
2. **Cite sources** — every finding must reference which source(s) support it
3. **Acknowledge gaps** — if the research is incomplete, say so
4. **Actionable output** — every synthesis must end with "what to do next"
5. Save to `MarketingToolData/research/synthesis-<date>-<topic>.md`
