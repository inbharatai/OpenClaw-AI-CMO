> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: repo-review
description: Review code repositories for quality, structure, issues, and improvement opportunities. Use when the user wants a code review, project audit, dependency check, or architecture assessment. Triggers on "review this repo", "code review", "audit this project", "check the codebase", or any repository quality assessment request.
---

# Repo Review

Perform structured code repository reviews with actionable findings.

## Default Model

`qwen2.5-coder:7b` — purpose-built for code analysis, pattern recognition, and technical assessment.

## Review Framework

### 1. Structure Check
- Is the project organized logically? (src, tests, config, docs)
- Are there unused or orphaned files?
- Is the naming consistent?

### 2. Dependency Health
- Are dependencies up to date?
- Are there known vulnerabilities? (`npm audit`, `pip audit`)
- Are there unused dependencies?

### 3. Code Quality
- Are there obvious bugs or anti-patterns?
- Is error handling present and consistent?
- Are there hardcoded secrets or credentials?
- Is there code duplication that should be extracted?

### 4. Configuration
- Are environment variables documented?
- Is there a proper .gitignore?
- Are build/deploy configs present and correct?

### 5. Testing
- Do tests exist?
- What's the approximate coverage?
- Are tests passing?

## Review Output Format

```markdown
# Repo Review: <project name>

**Date:** YYYY-MM-DD
**Path:** <repo path>

## Summary
<2-3 sentence overview>

## Findings

### Critical (fix now)
- [ ] <finding>

### Important (fix soon)
- [ ] <finding>

### Nice to Have
- [ ] <finding>

## Strengths
- <what's done well>

## Recommendations
1. <top priority action>
2. <second priority action>
3. <third priority action>
```

## Rules

1. **Stay inside workspace** — only review repos within the approved workspace paths
2. **Don't modify code during review** — review is read-only
3. **Be specific** — "Line 42 in auth.ts has unhandled promise rejection" not "error handling could be better"
4. **Prioritize findings** — critical before cosmetic
5. Save reviews to `OpenClawData/reports/review-<date>-<repo-name>.md`
