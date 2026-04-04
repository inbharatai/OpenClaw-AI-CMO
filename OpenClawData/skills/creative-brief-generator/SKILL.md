---
name: creative-brief-generator
description: Generate creative briefs for campaigns, content pieces, ads, and marketing projects. Use when starting a new campaign, ad set, content series, or any creative project that needs a structured brief. Triggers on "creative brief", "campaign brief", "write a brief", "brief for", or when starting any new marketing initiative.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Creative Brief Generator

Produce concise, actionable creative briefs that align teams on what to make and why.

## Default Model

`qwen3:8b` — strong at strategic framing, audience definition, and structured output.

## Storage

- Briefs → `MarketingToolData/briefs/`

## Brief Template

```markdown
# Creative Brief: <Project Name>

**Date:** YYYY-MM-DD
**Owner:** <who is responsible>
**Deadline:** <target completion date>

## Objective
<What is this project trying to achieve? One sentence.>

## Background
<2-3 sentences of context. Why now? What led to this?>

## Target Audience
- **Primary:** <who, specifically>
- **Pain point:** <what problem do they have>
- **Desire:** <what outcome do they want>

## Key Message
<The single most important thing the audience should take away. One sentence.>

## Supporting Points
1. <Supporting fact or benefit>
2. <Supporting fact or benefit>
3. <Supporting fact or benefit>

## Tone & Voice
<Reference brand-voice.md or specify for this project>

## Deliverables
- [ ] <specific output 1> (format, platform, dimensions if relevant)
- [ ] <specific output 2>
- [ ] <specific output 3>

## Constraints
- Budget: <if applicable>
- Timeline: <key dates>
- Brand guidelines: <any specific rules>
- Must include: <required elements>
- Must avoid: <things to stay away from>

## Success Metrics
- <KPI 1>
- <KPI 2>

## References & Inspiration
- <link or description of reference material>
```

## Rules

1. Always read `OpenClawData/memory/brand-voice.md` before writing a brief
2. Keep briefs to one page — brevity forces clarity
3. The "Key Message" must be one sentence — if it takes more, it's not clear enough
4. Save to `MarketingToolData/briefs/brief-<YYYY-MM-DD>-<project-name>.md`
5. After generating, ask: "Does this capture the intent? Anything to adjust?"
