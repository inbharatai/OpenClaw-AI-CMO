---
name: website-publisher-queue
description: Stage approved website content for publishing. Organizes content by section (updates, insights, build-log, news) and prepares it for manual or automated website deployment. Triggers on website publishing, content staging, or site update requests.
---

# Website Publisher Queue

Stage approved website content organized by section for publishing.

## Default Model

`qwen2.5-coder:7b`

## Input

Approved content from `OpenClawData/queues/website/approved/`

## Output Structure

Content is organized into section-specific folders in MarketingToolData:

| Section | Folder | Source Type |
|---|---|---|
| /updates | `MarketingToolData/website-posts/` | product-update, changelog, feature-note |
| /insights | `MarketingToolData/insights/` | ai-commentary, comparison, educational |
| /build-log | `MarketingToolData/build-logs/` | founder-update, weekly-build-summary |
| /news | `MarketingToolData/ai-news/` | ai-news-summary, tool-roundup |

## Publishing Flow

1. Read approved website content
2. Determine section from frontmatter `section:` field
3. Copy to the appropriate MarketingToolData folder
4. Update file status in frontmatter: `status: "ready-to-publish"`
5. Add `staged_date: "YYYY-MM-DD"` to frontmatter
6. Log to `OpenClawData/logs/website-publish.log`

## Rules

1. Content must be approved before staging — never bypass the approval queue
2. Preserve all original frontmatter
3. File naming follows section convention: `{section}-YYYY-MM-DD-{slug}.md`
4. In V1, publishing is manual — you copy from these folders to your website
5. In V2+, this can integrate with a static site generator build script
