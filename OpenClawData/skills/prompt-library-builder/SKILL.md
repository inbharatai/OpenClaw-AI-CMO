---
name: prompt-library-builder
description: Build, organize, and maintain a library of tested prompts for marketing, coding, and operations. Use when saving effective prompts, creating prompt templates, organizing prompts by category, or building a reusable prompt collection. Triggers on "save this prompt", "prompt library", "prompt template", "add to prompts", or any prompt management request.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Prompt Library Builder

Build and maintain an organized library of tested, reusable prompts.

## Default Model

`qwen3:8b` — for crafting and refining prompt templates.

## Storage

- Prompt library → `OpenClawData/prompts/`
- Tested prompts also referenced in `OpenClawData/memory/prompt-templates.md`

## Prompt Categories

Organize prompts into category files:

| File | Category | Examples |
|---|---|---|
| `marketing-prompts.md` | Marketing & content | Caption generation, campaign ideas, repurposing |
| `coding-prompts.md` | Coding & automation | Script templates, debugging, API integration |
| `planning-prompts.md` | Strategy & planning | Task breakdown, campaign planning, research |
| `operations-prompts.md` | Operations & reporting | Reports, checklists, summaries |

## Prompt Template Format

```markdown
### <Prompt Name>

**Category:** <category>
**Model:** qwen3:8b | qwen2.5-coder:7b
**Tested:** yes | no
**Rating:** ★☆☆☆☆ to ★★★★★

**Template:**
```
<the actual prompt with {placeholders} for variable parts>
```

**Variables:**
- `{variable1}` — <description>
- `{variable2}` — <description>

**Example usage:**
```
<filled-in example>
```

**Notes:** <any tips, caveats, or variations>

---
```

## Library Rules

1. **Only save tested prompts** — a prompt must produce good output at least once before being added
2. **Include the model** — which model was this tested on?
3. **Rate honestly** — ★★★ means "works but could be better"
4. **Use placeholders** — make prompts reusable with `{variables}`
5. **Organize by category** — one file per category, not one giant file
6. **Update, don't duplicate** — if a prompt improves, update the existing entry

## Adding a New Prompt

1. Test the prompt with the appropriate model
2. If output is good, save using the template format above
3. Append to the correct category file in `OpenClawData/prompts/`
4. Also add a brief reference in `OpenClawData/memory/prompt-templates.md`
