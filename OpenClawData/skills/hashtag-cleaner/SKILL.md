---
name: hashtag-cleaner
description: Cleans, deduplicates, and enforces platform limits on hashtags
version: 1.0.0
category: qa
triggers:
  - clean hashtags
  - fix hashtags
inputs:
  - hashtags (required): Raw hashtag string or list
  - platform (required): Target platform
outputs:
  - clean_hashtags: Platform-appropriate cleaned hashtag set
honest_classification: qa-utility
---

# Hashtag Cleaner

## Purpose
Take raw hashtags from content generation and produce a clean, platform-appropriate set.

## Platform Limits
- **LinkedIn**: 3-5 hashtags, professional and specific
- **Instagram**: 5-15 hashtags, mix of broad and niche
- **X (Twitter)**: 0-2 hashtags, integrated into text naturally
- **Discord**: 0 hashtags (not a hashtag platform)
- **Reddit**: 0 hashtags (not used on Reddit)

## Cleaning Rules

### Remove
- Duplicate hashtags (case-insensitive)
- Generic/spam hashtags: #AI #Tech #Innovation #Trending #Viral #FYP #ForYou
- Hashtags longer than 30 characters
- Hashtags with special characters (except underscore)
- Competitor brand hashtags
- Hashtags that don't relate to the post content
- Hashtags in ALL CAPS (convert to normal case)

### Keep Priority (highest first)
1. Product-specific: #InBharatAI #TestsPrep #UniAssist #Sahaayak #OpenClaw
2. Topic-specific: #AIinIndia #EdTech #IndianStartups #ExamPrep
3. Industry: #ArtificialIntelligence #MachineLearning #NLP
4. Audience: #IndianDevelopers #Students #Founders

### Format
- Instagram: Separate block below caption, each on own line or space-separated
- LinkedIn: At end of post, space-separated on one line
- X: Inline within tweet text, naturally placed
- Never start a post with hashtags
- Never use more than the platform limit

## Output Format
Return only the cleaned hashtag string, formatted for the target platform.
No JSON. No metadata. Just clean hashtags ready to append.

---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
