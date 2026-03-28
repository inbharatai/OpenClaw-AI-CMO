> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: newsletter-draft-builder
description: Compose weekly newsletter drafts from approved content, news summaries, and product updates. Use when building email newsletters or newsletter snippets. Triggers on newsletter creation, email digest building, or weekly roundup compilation for email.
---

# Newsletter Draft Builder

Compose engaging, value-packed newsletters from the week's approved content.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/newsletters/`
- Queue → `OpenClawData/queues/email/pending/`

## Output Format — Full Newsletter

```markdown
---
title: "<Newsletter title — week of YYYY-MM-DD>"
date: "YYYY-MM-DD"
type: "newsletter-draft"
format: "full"
subject_line: "<under 60 chars, compelling, clear>"
preview_text: "<under 100 chars, complements subject line>"
approval_level: "L2"
source_files: ["<list of source content paths>"]
status: "pending"
---

# <Newsletter Title>

<1-2 sentence personal intro — conversational, warm, brief>

---

## 🛠️ What We Built

<2-3 bullet points of product updates from the week>

## 📰 AI News Worth Knowing

<2-3 curated news items with 1-sentence summaries each>

## 💡 Insight of the Week

<1 paragraph: one valuable insight, tip, or lesson>

## 👉 One Thing to Try

<1 actionable suggestion the reader can do this week>

---

<Brief sign-off — personal, not corporate>

<Unsubscribe note: handled by platform>
```

## Output Format — Snippet (for daily collection)

```markdown
---
title: "<snippet topic>"
date: "YYYY-MM-DD"
type: "newsletter-snippet"
format: "snippet"
category: "<product-update|news|insight|tip>"
source_file: "<path>"
status: "collected"
---

<2-3 sentences of newsletter-ready content>
```

## Writing Rules

1. Newsletters are personal — write like you're emailing one person
2. Subject line under 60 characters, no clickbait, clear value
3. Maximum 800 words for full newsletter
4. Every section should deliver value — if a section is filler, cut it
5. Include links to full posts where relevant
6. End with a single, clear CTA
7. Snippets accumulate during the week; full newsletter compiles them
8. File naming: `newsletter-YYYY-MM-DD.md` or `snippet-YYYY-MM-DD-<topic>.md`
