# Website Content Hub Strategy

## Why Not a Traditional Blog?

A traditional blog implies chronological posts with no structure. For a solo builder's AI product company, a **structured content hub** is more effective for SEO, user trust, and content discovery.

---

## Recommended Structure

```
yourdomain.com/
|
|-- /updates          Product updates, releases, changelogs
|-- /insights         Long-form articles, analysis, deep dives
|-- /news             AI industry news commentary
|-- /lab              Experiments, benchmarks, technical explorations
|-- /build-log        Build-in-public weekly/daily logs
```

### /updates
- **Purpose**: Product release notes, feature announcements, improvements
- **Frequency**: As needed (every release)
- **Tone**: Professional, factual
- **SEO value**: Low (internal stakeholder focus)
- **Auto-level**: L1 (auto-approve)

### /insights
- **Purpose**: Deep analysis, comparisons, educational content
- **Frequency**: 1-2x per week
- **Tone**: Authoritative, educational
- **SEO value**: High (target keywords, long-tail)
- **Auto-level**: L2 (score-gated)

### /news
- **Purpose**: AI industry commentary, tool news, market signals
- **Frequency**: 2-3x per week
- **Tone**: Informed, opinionated
- **SEO value**: Medium (trending topics)
- **Auto-level**: L2 (score-gated)

### /lab
- **Purpose**: Experiments, benchmarks, prototype demos
- **Frequency**: As interesting things happen
- **Tone**: Technical, exploratory
- **SEO value**: Medium (developer audience)
- **Auto-level**: L2 (score-gated)

### /build-log
- **Purpose**: Transparent build-in-public updates
- **Frequency**: Weekly
- **Tone**: Authentic, personal
- **SEO value**: Low (community building focus)
- **Auto-level**: L1 (auto-approve)

---

## Content Format

Each website content file follows this format:

```markdown
---
title: "Your Post Title"
section: updates | insights | news | lab | build-log
date: 2026-03-23
tags: [ai, product, launch]
author: Founder
status: draft | published
---

Content body in markdown...
```

Files are stored in `data/website-posts/` with frontmatter metadata.

---

## Future: Newsletter Archive

When ready, add:
```
/newsletter        Past newsletter issues (read-only archive)
```

This can be auto-generated from `data/newsletters/` content.
