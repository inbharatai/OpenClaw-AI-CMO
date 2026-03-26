---
name: video-brief-generator
description: Create structured video briefs for HeyGen avatar videos and short-form video content. Use when producing video scripts, talking-head outlines, or HeyGen production briefs. Triggers on video brief requests, HeyGen content planning, or short-form video production.
---

# Video Brief Generator

Create production-ready video briefs for HeyGen avatar videos and short-form content.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/video-briefs/`
- Queue → `OpenClawData/queues/heygen/pending/`

## Output Format

```markdown
---
title: "<video title>"
date: "YYYY-MM-DD"
type: "video-brief"
platform: "<heygen|general>"
target_channels: ["<where this video will be posted>"]
duration_target: "<30s|60s|90s|2min>"
approval_level: "L1"
source_file: "<path to source content>"
status: "pending"
---

# Video Brief: <Title>

## Concept
<1-2 sentences: what is this video about and who is it for?>

## Script

### Hook (0-5s)
<Opening line that grabs attention>

### Body (5s-Xs)
<Main content — bullet points or short paragraphs>
<Each point should be 1-2 sentences max>

### CTA (final 5-10s)
<What should the viewer do next?>

## Production Notes

- **Avatar:** <which HeyGen avatar or "default">
- **Background:** <studio, office, custom, or virtual>
- **Tone:** <energetic, calm, professional, casual>
- **Pacing:** <fast for social, moderate for educational>
- **On-screen text:** <any text overlays needed>
- **B-roll notes:** <if any supplementary visuals are needed>

## Platform-Specific Notes

<If this will be a YouTube Short: vertical, under 60s, hook in first 2s>
<If this will be for LinkedIn: professional, 60-90s, value-first>
<If this will be for X: under 60s, direct, shareable>
```

## Duration Guidelines

| Target | Best For |
|---|---|
| 30s | Social clips, announcements, tips |
| 60s | Product demos, news reactions, quick tutorials |
| 90s | Thought leadership, deeper insights |
| 2min | Educational content, walkthroughs |

## Writing Rules

1. Scripts must be speakable — read it aloud to check flow
2. Hook must grab attention in first 3 seconds
3. One idea per video — don't pack multiple topics
4. Use conversational language, not written-essay style
5. Include production notes so HeyGen setup is clear
6. File naming: `video-brief-YYYY-MM-DD-<slug>.md`
7. Keep total script under 300 words for a 2-min video
