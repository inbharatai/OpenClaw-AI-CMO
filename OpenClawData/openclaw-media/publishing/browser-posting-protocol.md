# Browser-Based Publishing Protocol

InBharat Bot posts content to social platforms via Chrome browser automation (MCP tools).
This replaces socialflow-publisher.sh which required API tokens.

## Command: `/media post [platform]`

### Flow:
1. Read approved queue (`queues/<platform>/approved/`) for the target platform
2. If no approved content, check pending and run claim validation + auto-approve L1 items
3. Show the content to the owner for final confirmation
4. Open Chrome → navigate to platform → create post → submit
5. Move file to `posted/` directory
6. Log the action to `post-actions-YYYY-MM-DD.jsonl`

### Platform Posting Steps:

#### LinkedIn (Personal Profile)
1. Navigate to `https://www.linkedin.com`
2. Click "Start a post"
3. Type/paste the post content from `platform_content.linkedin_post`
4. Click "Post" button
5. Confirm posted

#### LinkedIn (Company Page — InBharat AI)
1. Navigate to `https://www.linkedin.com/company/inbharatai/`
2. Click "Start a post" (as page admin)
3. Type/paste content
4. Click "Post"

#### X (Twitter)
1. Navigate to `https://x.com/compose/post` or click compose button
2. Type/paste content from `platform_content.x_tweet` (max 280 chars)
3. If thread content exists in `platform_content.x_thread`, post as thread
4. Click "Post"

#### Instagram
1. Navigate to `https://www.instagram.com`
2. Click "+" (create) button
3. Upload image (if image_brief was fulfilled) or skip if text-only
4. Add caption from `platform_content.instagram_caption`
5. Click "Share"
6. NOTE: Instagram requires an image — text-only posts not supported

#### Discord
1. Use Discord webhook if configured, OR
2. Navigate to Discord server in browser
3. Paste `platform_content.discord_message` in the appropriate channel

## Content Extraction:
- For `.json` files: read `platform_content.<platform>_post` or `platform_content.<platform>_tweet`
- For `.md` files: extract the body text (skip frontmatter)

## Safety Rules:
- ALWAYS show content to owner before posting (Rule 8: publishing requires approval)
- NEVER post content that failed claim validation
- NEVER post fabricated statistics or unverified claims
- If content looks AI-generated/generic, flag it and suggest edits before posting
- Run claim-validator.sh on content before posting even if already approved

## Post-Posting:
- Move file from `approved/` to `posted/`
- Log to `analytics/post-actions-YYYY-MM-DD.jsonl`
- Record in campaign-memory if campaign-linked
