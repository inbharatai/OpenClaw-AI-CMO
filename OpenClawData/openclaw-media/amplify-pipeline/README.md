# Amplification Pipeline

Converts InBharat Bot discoveries into platform-native social content.

## How It Works
1. Reads campaign briefs from inbharat-bot/handoffs/
2. Validates brief against handoff-schema.json
3. Selects appropriate platforms from brief
4. Generates platform-specific content using skills
5. Packages into content-package format
6. Routes to approval-engine.sh
7. Approved content goes to distribution-engine.sh

## Input
Structured campaign briefs (JSON) from InBharat Bot's campaign-brief-generator skill.

## Output
Platform-native content packages ready for approval and distribution.

## Handoff Types Supported
- India problem discoveries → awareness campaigns
- AI gap findings → thought leadership posts
- Funding/opportunity alerts → community announcements
- Build logs → behind-the-scenes content
- Blog drafts → social snippets
- Ecosystem intelligence → correction/update campaigns
