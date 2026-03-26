---
name: landing-page-upgrade
description: Improve landing pages for better conversion, design, copy, and user experience. Use when the user wants to optimize a landing page, improve conversion rates, rewrite page copy, restructure page layout, or audit a landing page. Triggers on "landing page", "improve this page", "optimize for conversion", "page audit", or any landing page improvement request.
---

# Landing Page Upgrade

Audit and improve landing pages for better conversion, clarity, and user experience.

## Default Model

- Copy and messaging → `qwen3:8b`
- Code and implementation → `qwen2.5-coder:7b`

## Landing Page Audit Checklist

### Above the Fold (first screen)
- [ ] Clear headline — does the visitor know what this is in 5 seconds?
- [ ] Subheadline — does it clarify the benefit?
- [ ] Primary CTA — is there one clear action to take?
- [ ] Visual — does the image/video support the message?
- [ ] No navigation distractions — minimal top nav on landing pages

### Copy Quality
- [ ] Benefits over features
- [ ] Specific outcomes ("Save 5 hours/week" not "Save time")
- [ ] Social proof present (testimonials, numbers, logos)
- [ ] Objection handling (FAQ or reassurance)
- [ ] Consistent voice (matches brand-voice.md)

### Technical
- [ ] Mobile responsive
- [ ] Page load speed (<3 seconds)
- [ ] Forms work correctly
- [ ] CTA buttons are prominent and consistent color
- [ ] No broken links or images

### Conversion Elements
- [ ] Single focused CTA (not competing actions)
- [ ] Urgency or scarcity (if authentic)
- [ ] Trust signals (SSL, guarantees, privacy note)
- [ ] Exit intent or scroll-triggered elements (optional)

## Improvement Output Format

```markdown
# Landing Page Upgrade: <page name/URL>

## Current Issues
1. <issue> → <impact on conversion>

## Recommended Changes
1. <change> → <expected impact>

## Proposed Copy
### New Headline: "<headline>"
### New Subheadline: "<subheadline>"
### New CTA: "<button text>"

## Code Changes Needed
- <file>: <what to change>
```

## Rules

1. **Audit before changing** — always assess current state first
2. **Copy changes go through brand-voice check**
3. **Code changes follow safe-code-edit process**
4. Save audits to `OpenClawData/reports/landing-audit-<date>-<page>.md`
