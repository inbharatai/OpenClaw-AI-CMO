# Analytics & Feedback Loop

## Purpose
Track what OpenClaw publishes and feed performance signals back to InBharat Bot.

## Data Flow
1. OpenClaw publishes content → logs to posting-log.json
2. Engagement data entered (manual or API) → engagement/events-*.jsonl
3. InBharat Bot reads analytics → adjusts strategy

## Feedback Signals for InBharat Bot
- Which content buckets get most engagement
- Which platforms perform best
- Which products get most attention
- Which India problems resonate
- Which stakeholder segments respond
- What messaging style works
- What's being under-promoted

## Files
- posting-log.json — Record of all published content
- performance-notes/ — Manual performance observations
- feedback-to-bot/ — Structured signals for InBharat Bot consumption
