> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: educational-content-builder
description: Write how-to guides, tutorials, explainers, and educational posts for the website /insights section. Use for teaching, explaining concepts, or creating step-by-step guides. Triggers on educational content, how-to, tutorial, or explainer requests.
---

# Educational Content Builder

Create clear, actionable educational content that teaches and builds authority.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/insights/`
- Queue → `OpenClawData/queues/website/pending/`

## Output Format

```markdown
---
title: "<How to / What is / Guide to> <topic>"
date: "YYYY-MM-DD"
section: "insights"
type: "educational"
tags: [<relevant tags>]
approval_level: "L2"
status: "pending"
---

# <Title>

**Reading time:** <X> minutes
**Level:** <Beginner | Intermediate | Advanced>

## Why This Matters

<2-3 sentences: why should the reader care about this topic?>

## <Main Content>

<Structured content using clear headings, numbered steps, or logical sections>

### Step 1 / Section 1
<content>

### Step 2 / Section 2
<content>

### Step 3 / Section 3
<content>

## Key Takeaways

- <takeaway 1>
- <takeaway 2>
- <takeaway 3>

## Try It Yourself

<1-2 sentences: actionable next step the reader can take>
```

## Content Types

| Type | When | Format |
|---|---|---|
| How-to guide | Step-by-step instructions | Numbered steps |
| Explainer | Concept explanation | Sections with analogies |
| Tutorial | Hands-on walkthrough | Code blocks + steps |
| Listicle | Curated list of tools/tips | Numbered items with details |
| Framework | Decision-making framework | Matrix or flowchart description |

## Writing Rules

1. Lead with "why" before "how" — motivate before teaching
2. Use concrete examples, not abstract theory
3. Include a "Try It Yourself" section — make it actionable
4. Reading time estimate based on ~200 words/minute
5. Maximum 1500 words for articles, 800 for quick guides
6. Use code blocks for any technical content
7. File naming: `educational-YYYY-MM-DD-<slug>.md`
