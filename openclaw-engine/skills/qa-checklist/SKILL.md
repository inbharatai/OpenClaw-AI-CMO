---
name: qa-checklist
description: Generate and run quality assurance checklists for content, code, campaigns, and deliverables before publishing or deploying. Use when the user needs a pre-publish review, pre-launch check, quality gate, or final approval checklist. Triggers on "QA check", "checklist", "before we publish", "pre-launch", "quality check", "review before sending", or any quality gate request.
---

# QA Checklist

Structured quality checks before anything goes live.

## Default Model

- Content QA → `qwen3:8b`
- Code QA → `qwen2.5-coder:7b`

## Pre-Built Checklists

### Content Publishing Checklist
- [ ] Spelling and grammar checked
- [ ] Brand voice consistent (matches `OpenClawData/memory/brand-voice.md`)
- [ ] CTA is clear and present
- [ ] Links work and go to correct destinations
- [ ] Images/media are correct format and quality
- [ ] Hashtags are relevant (if applicable)
- [ ] No sensitive/confidential information exposed
- [ ] Posted to correct platform/account
- [ ] Scheduling time is correct (if scheduled)

### Email Campaign Checklist
- [ ] Subject line is compelling and under 60 characters
- [ ] Preview text is set and useful
- [ ] From name and reply-to are correct
- [ ] Personalization tokens work (no broken {first_name})
- [ ] Unsubscribe link is present and works
- [ ] Links all work and track correctly
- [ ] Mobile rendering looks good
- [ ] Test email sent and reviewed

### Code Deployment Checklist
- [ ] All tests pass
- [ ] No console errors in browser
- [ ] Environment variables are set
- [ ] No hardcoded secrets or API keys
- [ ] Backup exists before deploying
- [ ] Rollback plan is documented
- [ ] Performance check (load time acceptable)

### Campaign Launch Checklist
- [ ] Creative brief approved
- [ ] All content pieces created and reviewed
- [ ] Landing page live and tested
- [ ] Tracking/analytics configured
- [ ] Budget set correctly
- [ ] Target audience defined
- [ ] Start/end dates confirmed
- [ ] Team notified

## Custom Checklist Builder

For any deliverable, generate a checklist by answering:
1. What could go wrong if this is published/deployed as-is?
2. What has gone wrong in the past?
3. What would embarrass us if we missed it?
4. What's irreversible once live?

## Checklist Output Format

```markdown
# QA Checklist: <deliverable name>

**Date:** YYYY-MM-DD
**Type:** Content | Code | Campaign | Email
**Reviewer:** <who is checking>

| # | Check | Status | Notes |
|---|---|---|---|
| 1 | <check item> | ✅ Pass / ❌ Fail / ⚠️ Warning | <detail> |
| 2 | <check item> | | |

**Result:** APPROVED / NEEDS FIXES / BLOCKED

**Issues to Fix:**
1. <issue>
```

## Rules

1. **Every checklist must produce a clear APPROVED or NEEDS FIXES result**
2. **One ❌ Fail = NEEDS FIXES** — no publishing with failures
3. **⚠️ Warnings are judgment calls** — document why you proceed
4. Save completed checklists to `OpenClawData/reports/qa-<date>-<item>.md`
