---
title: Content Approval Policy
version: 1.0
last_updated: 2026-03-31
---

# Approval Policy

## Approval Levels

### L1 — Auto-Approved (Internal / Low-Risk)
Items that can be published without human review:
- Build logs on Discord (own server)
- Internal status updates
- Dashboard/report generation
- Source note classification
- Draft generation (not publishing)

### L2 — Score-Gated (Medium Risk)
Items that pass if automated risk scoring clears thresholds:
- Product updates on website
- Discord announcements (own server)
- Educational content (AI Made Simple, Feature Walkthrough)
- Community engagement posts
- Build logs on social platforms

Risk dimensions checked:
- Source confidence (weight: 0.25)
- Brand voice alignment (weight: 0.15)
- Claim sensitivity (weight: 0.25)
- Duplication (weight: 0.10)
- Platform risk (weight: 0.10)
- Data safety (weight: 0.15)

### L3 — Review Required (High Risk)
Items requiring human review before publishing:
- Instagram posts (all types)
- YouTube Shorts
- LinkedIn posts
- X posts and threads
- Product proof content with specific claims
- Competitor mentions
- Founder-associated messaging
- Partnership announcements
- Major milestone claims

### L4 — Hard Stop (Block)
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
