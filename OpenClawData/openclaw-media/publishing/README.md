# Publishing Workflow

## State Transitions
draft → review → approved → scheduled → published

## Publishing Method
All social posting is browser-automation-driven:
- Instagram: browser upload via Chrome automation
- YouTube Shorts: browser upload via Chrome automation
- LinkedIn: browser post via Chrome automation
- X: browser post via Chrome automation
- Discord: webhook (automated, no browser needed)

## Publish-Ready Folders
Content approved for publishing is placed in platform-specific queue folders:
- queues/instagram/approved/
- queues/x/approved/
- queues/discord/approved/
- queues/linkedin/approved/

## Post-Publish
1. Update content package status to "published"
2. Log to posting-log.json
3. Move to queues/{platform}/archive/
4. Signal analytics for tracking
