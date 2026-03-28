> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: professional-email-drafter
description: Draft professional outreach emails for business development, partnerships, government outreach, institutional introductions, and follow-ups. Triggers on "draft email", "outreach", "introduce us to", "follow up with", "reach out to", or any email/outreach request.
---

# Professional Email Drafter

Draft concise, professional outreach emails with a genuine solo-founder voice.

## Default Model

`qwen3:8b` — strong at professional writing with appropriate formality.

## Email Types

| Type | Tone | Length |
|------|------|--------|
| Cold introduction | Warm but professional, value-first | 150-200 words |
| Partnership proposal | Professional, specific mutual benefit | 200-300 words |
| Government/institutional | Formal, credentials-led | 250-350 words |
| Follow-up | Brief, reference previous context | 80-120 words |
| Thank you / acknowledgment | Warm, specific gratitude | 60-100 words |

## Output Format

```markdown
---
to: <recipient name and organization>
subject: <email subject line>
type: <cold-intro|partnership|government|follow-up|thank-you>
status: draft
date: YYYY-MM-DD
---

<email body>
```

## Rules

1. **No corporate jargon.** No "synergy", "leverage", "circle back", "touch base"
2. **Lead with value.** What do THEY get? Not what you want.
3. **Be specific.** Reference their work, their org, their problem.
4. **Solo founder voice.** Direct, genuine, slightly informal but professional.
5. **Include a clear ask.** What do you want them to do? (reply, call, meeting)
6. **Keep it short.** Nobody reads long cold emails.
7. **No attachments mentioned unless specified.** Don't promise what you can't deliver.
8. **For government emails:** Include relevant credentials, project references, and alignment with government objectives.
9. **For follow-ups:** Reference the previous interaction specifically. Don't repeat the original pitch.

## Context About InBharat AI

Use this when drafting:
- InBharat AI is an Indian AI company building practical AI tools
- Products: Sahaayak (personal AI), SahaayakSeva (Anganwadi AI), Phoring (decision intelligence), TestsPrep (test prep), UniAssist (education)
- Founded by Reeturaj Goswami, solo founder
- Focus: AI for India, practical applications, government and education sectors
- Open-source contributions: OpenClaw (AI agent platform), Claude Skills

## What NOT to do

- Don't lie about team size or capabilities
- Don't promise features that don't exist
- Don't claim partnerships that aren't real
- Don't use "we" if it's a solo founder — use "I" or "InBharat"
- Don't include pricing unless specifically asked
- Don't invent statistics, pilot results, or deployment numbers — only state what's provided in the context
- Don't claim government partnerships or state deployments unless explicitly stated
