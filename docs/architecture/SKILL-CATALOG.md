# Skill Catalog — 60 Skills

Every skill is a `SKILL.md` file in `openclaw-engine/skills/<skill-name>/SKILL.md` that defines purpose, inputs, outputs, and the LLM prompt template.

---

## Foundation Skills (6)

| Skill | Purpose | Model |
|-------|---------|-------|
| `workspace-guard` | Enforces all operations stay within project folder | qwen2.5-coder:7b |
| `local-model-router` | Routes tasks to appropriate local LLM | qwen2.5-coder:7b |
| `memory-writer` | Persists decisions, lessons, and context | qwen3:8b |
| `verification-evidence` | Validates claims and attaches evidence | qwen3:8b |
| `task-planner` | Plans multi-step task execution | qwen3:8b |
| `reporting` | Generates pipeline and summary reports | qwen3:8b |

## Content / Editorial Skills (17)

| Skill | Purpose | Model |
|-------|---------|-------|
| `website-update-writer` | Drafts website /updates content | qwen3:8b |
| `insights-article-writer` | Writes long-form /insights articles | qwen3:8b |
| `ai-news-summarizer` | Summarizes AI industry news | qwen3:8b |
| `product-update-writer` | Formats product release notes | qwen3:8b |
| `social-repurposing` | Adapts content for multiple platforms | qwen3:8b |
| `brand-voice` | Enforces consistent brand tone | qwen3:8b |
| `newsletter-draft-builder` | Builds email newsletter drafts | qwen3:8b |
| `weekly-roundup-builder` | Creates weekly summary posts | qwen3:8b |
| `comparison-post-writer` | Writes tool/product comparisons | qwen3:8b |
| `educational-content-builder` | Creates how-to and educational content | qwen3:8b |
| `build-log-writer` | Documents build-in-public progress | qwen3:8b |
| `creative-brief-generator` | Generates campaign creative briefs | qwen3:8b |
| `video-brief-generator` | Creates HeyGen video project briefs | qwen3:8b |
| `image-brief-generator` | Creates image generation briefs | qwen3:8b |
| `content-classifier` | Classifies content by type and channel | qwen3:8b |
| `channel-adapter` | Formats content for specific platforms | qwen3:8b |
| `discord-announcement-writer` | Writes Discord-specific announcements | qwen3:8b |

## Approval / Safety Skills (8)

| Skill | Purpose | Model |
|-------|---------|-------|
| `approval-policy` | Defines and enforces approval rules | qwen3:8b |
| `risk-scorer` | Calculates risk scores across dimensions | qwen3:8b |
| `duplicate-checker` | Detects content too similar to recent posts | qwen2.5-coder:7b |
| `factuality-check` | Verifies claims against available evidence | qwen3:8b |
| `channel-policy-checker` | Validates content against platform rules | qwen3:8b |
| `rate-limit-guard` | Enforces posting frequency limits | qwen2.5-coder:7b |
| `credential-safety-policy` | Prevents plaintext credential exposure | qwen2.5-coder:7b |
| `human-in-the-loop-approval` | Manages L3 review queue for humans | qwen3:8b |

## Distribution Skills (8)

| Skill | Purpose | Model |
|-------|---------|-------|
| `channel-exporter` | Exports content to channel-specific formats | qwen2.5-coder:7b |
| `posting-queue-manager` | Manages posting queues per platform | qwen2.5-coder:7b |
| `website-publisher-queue` | Queues content for website publishing | qwen2.5-coder:7b |
| `discord-webhook-publisher` | Publishes to Discord via webhooks | qwen2.5-coder:7b |
| `newsletter-exporter` | Exports newsletters for email platforms | qwen3:8b |
| `social-queue-packager` | Packages social posts for scheduling | qwen2.5-coder:7b |
| `campaign-calendar-builder` | Builds editorial/campaign calendars | qwen3:8b |
| `content-performance-tracker` | Tracks posting outcomes and metrics | qwen2.5-coder:7b |

## Research / Growth Skills (8)

| Skill | Purpose | Model |
|-------|---------|-------|
| `trend-to-content` | Converts trending topics into content ideas | qwen3:8b |
| `competitor-monitor` | Tracks competitor activities | qwen3:8b |
| `opportunity-miner` | Identifies marketing opportunities | qwen3:8b |
| `seo-topic-mapper` | Maps SEO keywords to content topics | qwen3:8b |
| `audience-angle-generator` | Generates audience-specific content angles | qwen3:8b |
| `offer-funnel-copy` | Writes offer/funnel marketing copy | qwen3:8b |
| `lead-research` | Researches potential leads and markets | qwen3:8b |
| `news-source-collector` | Collects and organizes news sources | qwen3:8b |

## Utility Skills (13)

| Skill | Purpose | Model |
|-------|---------|-------|
| `content-strategy` | Plans content strategy and pillars | qwen3:8b |
| `content-calendar` | Creates content calendars | qwen3:8b |
| `hq-coordinator` | Orchestrates multi-agent workflows | qwen3:8b |
| `daily-briefing` | Generates daily status briefings | qwen3:8b |
| `qa-checklist` | Quality assurance for content | qwen3:8b |
| `session-compaction` | Compresses session history | qwen3:8b |
| `prompt-library-builder` | Builds reusable prompt templates | qwen3:8b |
| `automation-script-builder` | Generates automation scripts | qwen2.5-coder:7b |
| `research-synthesizer` | Synthesizes research findings | qwen3:8b |
| `reddit-post-drafter` | Drafts Reddit-specific content | qwen3:8b |
| `repo-review` | Reviews code repositories | qwen2.5-coder:7b |
| `safe-code-edit` | Safe code modification helper | qwen2.5-coder:7b |
| `landing-page-upgrade` | Improves landing page copy | qwen3:8b |
