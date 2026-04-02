---
title: Content Approval Policy
version: 2.0
last_updated: 2026-04-02
---

# Approval Policy

Aligned with OpenClaw Autonomy Tiers (see `directives/00-master-system-prompt.md`).

## Approval Levels

### L1 — Auto-Approved (Tier 0 Autonomous)
Published without human review:
- Build logs on Discord (own server)
- Internal status updates
- Dashboard/report generation
- Source note classification
- Draft generation
- Standard LinkedIn posts (AI news, education, build-in-public)
- Standard X posts and threads
- Standard Instagram carousels and visual content
- Discord announcements and community updates
- Blog articles and SEO content
- Newsletter drafts
- Community engagement posts

### L2 — Score-Gated (Tier 0/1 with QA)
Auto-published if internal QA chain passes (7-role review):
- Product updates on website
- YouTube Shorts and Instagram Reels (text/brief content only)
- Educational content with specific product claims
- Industry commentary and comparisons
- Outreach campaign drafts

Risk dimensions checked:
- Source confidence (weight: 0.25)
- Brand voice alignment (weight: 0.15)
- Claim sensitivity (weight: 0.25)
- Duplication (weight: 0.10)
- Platform risk (weight: 0.10)
- Data safety (weight: 0.15)

### L3 — Review Required (Tier 2/3 Gated)
Items requiring founder review before publishing:
- Reddit posts (always manual — platform policy)
- HeyGen avatar video production (Tier 3 — cost gated)
- Founder face or voice content
- Product proof content with bold specific claims
- Competitor attack content
- Partnership announcements
- Major milestone claims
- Content with high claim-sensitivity score (>60)

### L4 — Hard Stop (Always Block)
Items that must NEVER be auto-published:
- Funding claims without verified announcement
- Partnership claims without signed agreement
- "Better than X" comparative claims without benchmarks
- Legal or policy-sensitive statements
- Government-sensitive communications
- Certainty claims without proof ("100% accurate", "guaranteed")
- Credentials, API keys, or personal data detected
- Revenue or financial metrics without verification

## Override Triggers (Always Block)
- Credential or password detected in content
- No source evidence for factual claims
- Unverifiable claim presented as fact
- Spam pattern detected
- Content targets a blocked channel

## Review Process
1. Content generated → risk scored → routed to appropriate level
2. L3+ items placed in `approvals/review/` with risk breakdown
3. Owner reviews in review queue (via CLI or dashboard)
4. Approved items moved to `approvals/approved/` → distribution
5. Blocked items moved to `approvals/blocked/` with rejection reason
6. All decisions logged with timestamp and evidence
