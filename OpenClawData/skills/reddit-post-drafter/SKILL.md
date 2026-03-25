---
name: reddit-post-drafter
description: Draft Reddit-appropriate posts that match subreddit culture and rules. ALWAYS manual-first — never auto-post to Reddit. Use when preparing content for Reddit communities. Triggers on Reddit content preparation or community post drafting.
---

# Reddit Post Drafter

Draft authentic, community-appropriate Reddit posts. NEVER auto-posted.

## Default Model

`qwen3:8b`

## Storage

- Output → `MarketingToolData/reddit/`
- Queue → `OpenClawData/queues/reddit/pending/` (ALWAYS L3 review)

## Output Format

```markdown
---
title: "<reddit post title — specific, not clickbait>"
date: "YYYY-MM-DD"
type: "reddit-post"
target_subreddit: "<r/subreddit>"
post_type: "<text|link|show>"
approval_level: "L3"
status: "pending"
notes: "MANUAL POST ONLY — never auto-post to Reddit"
---

**Subreddit:** r/<subreddit>
**Flair:** <if applicable>

## Title

<The exact title to post — Reddit titles cannot be edited after posting>

## Body

<Post body in Reddit markdown>

## Self-Promotion Disclosure

<If relevant: "Disclosure: I'm the builder of X" — Reddit requires this>

## Pre-Post Checklist

- [ ] Read r/<subreddit> rules
- [ ] Check if similar content was posted recently
- [ ] Verify post matches subreddit culture
- [ ] Ensure self-promotion ratio is healthy (Reddit 10:1 rule)
- [ ] Disclosure included if applicable
```

## Reddit-Specific Rules

1. **NEVER auto-post** — Reddit is manual-first ALWAYS
2. Value-first — every post must provide genuine value to the community
3. No promotional language — Reddit communities detect and punish marketing speak
4. Match the subreddit's tone and culture
5. Include disclosure if content is related to your own product
6. Follow Reddit's 10:1 rule: 10 genuine community contributions for every 1 self-promotional post
7. Don't post the same content to multiple subreddits
8. File naming: `reddit-YYYY-MM-DD-<subreddit>-<slug>.md`

## Tone Guide

| Subreddit Type | Tone |
|---|---|
| Technical (r/programming, r/webdev) | Informative, code-heavy, no fluff |
| Startup (r/startups, r/SaaS) | Authentic, lessons-learned, humble |
| AI (r/artificialintelligence, r/LocalLLaMA) | Technical, specific, opinionated-is-OK |
| General (r/technology) | Accessible, newsworthy, non-promotional |
