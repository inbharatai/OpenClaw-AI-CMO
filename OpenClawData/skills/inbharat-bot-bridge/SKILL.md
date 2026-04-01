> **HONEST CLASSIFICATION:** This is a **command bridge** skill.
> It maps natural language requests to InBharat Bot commands and executes them.
> The actual work happens in shell scripts at `OpenClawData/inbharat-bot/inbharat-run.sh`.

---
name: inbharat-bot-bridge
description: Bridge to InBharat Bot orchestrator. Use this when the user asks you to create content, generate videos, scan for opportunities, research leads, run outreach, check status, approve/reject content, or any InBharat Bot operation. This is the primary command interface. Triggers on any content creation, media generation, publishing, outreach, or intelligence request.
---

# InBharat Bot Bridge

This skill lets you execute InBharat Bot and OpenClaw Media commands from WhatsApp or any channel.

## How to Use

When the user sends a message, map it to the appropriate command below and execute it using bash.

**Executor path:** `bash /Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot/inbharat-run.sh <command>`

## Command Reference

### Content Creation & Media

| User says something like... | Command to run |
|---|---|
| "create content about Phoring" | `media native --product phoring` |
| "create a video about Phoring" | `media native --product phoring --platform shorts` then `media video --file <output>` |
| "create a LinkedIn post about Sahaayak" | `media native --product sahaayak --platform linkedin` |
| "create a Discord update about OpenClaw" | `media native --product openclaw --platform discord` |
| "create an Instagram reel about TestsPrep" | `media native --product testsprep --platform instagram` |
| "generate an image for X" | `media image --brief "<description>"` |
| "generate a video about X" | `media video --brief "<description>" --format shorts` |
| "create a HeyGen video about X" | `generate-video.sh --heygen --file <package>` |
| "amplify the latest campaign" | `media amplify --all` |
| "run full media cycle for Phoring" | `media full --product phoring` |

### Review & Publishing

| User says something like... | Command to run |
|---|---|
| "what's pending?" / "show queue" | `media status` |
| "show me what needs review" | `media review` |
| "approve X" | `media approve <filename>` |
| "approve X but don't publish" | `media approve <filename> --no-publish` |
| "reject X" | `media reject <filename>` |
| "publish everything" | `media publish` |
| "posting history" | `media history` |

### Intelligence & Discovery

| User says something like... | Command to run |
|---|---|
| "scan India problems" | `india-problems scan` |
| "find AI gaps" | `ai-gaps scan` |
| "scan for funding" | `funding scan` |
| "scan competitors" | `competitor scan` |
| "scan ecosystem" | `ecosystem scan` |
| "scan community" | `community scan` |
| "find opportunities" | `opportunities all` |
| "scan government tenders" | `government scan` |
| "learning review" | `learning review` |

### Outreach

| User says something like... | Command to run |
|---|---|
| "research Blume Ventures" | `outreach research "Blume Ventures"` |
| "draft outreach campaign" | `outreach campaign vc-cold-intro vc-india.json` |
| "check outreach status" | `outreach status` |
| "follow up on outreach" | `outreach followup` |
| "show leads" | `outreach leads` |

### Content & Blog

| User says something like... | Command to run |
|---|---|
| "write a blog about X" | `blog generate "X"` |
| "plan a podcast about X" | `podcast plan "X"` |
| "generate a campaign for X" | `campaign generate "X"` |

### System

| User says something like... | Command to run |
|---|---|
| "system status" / "health check" | Run: `bash /Volumes/Expansion/CMO-10million/OpenClawData/scripts/health-check.sh` |
| "dashboard" | `status` |

## Product Name Mapping

When the user mentions a product, map to these slugs:
- InBharat / inbharat.ai → `inbharat`
- Sahaayak → `sahaayak`
- Sahaayak Seva / SahaayakSeva → `sahaayak-seva`
- Phoring / phoring.in → `phoring`
- TestsPrep / testsprep.in → `testsprep`
- UniAssist / uniassist.ai → `uniassist`
- CodeIn → `codein`
- Agent Arcade → `agent-arcade`
- Sahayak OS → `sahayak-os`
- OpenClaw → `openclaw`

## Platform Mapping

- YouTube Shorts / Shorts / Reels → `shorts`
- Instagram / IG → `instagram`
- LinkedIn / LI → `linkedin`
- X / Twitter → `x`
- Discord → `discord`

## Response Format

After running a command:
1. Show the key output (content preview, status summary, etc.)
2. If content was generated, tell the user the filename and ask if they want to approve
3. If approving, mention that auto-publish will run (validate → publish → archive → log)
4. Keep responses concise — this is WhatsApp, not a terminal

## Multi-Step Workflows

For "create a video about Phoring", the full flow is:
1. Run `media native --product phoring --platform shorts` → generates content package with video_brief
2. Show the user the hook/caption/video_brief
3. If user approves the brief, run `media video --file <package.json> --format shorts` → generates MP4
4. Or for HeyGen: run video engine with `--heygen` flag → generates HeyGen production brief
5. Ask user to approve for publishing: `media approve <file>`

## Rules

- ALWAYS show the user what was generated BEFORE publishing
- NEVER auto-approve without user confirmation
- If a command fails, show the error and suggest fixes
- Keep WhatsApp responses under 2000 characters
- Use the command exactly as shown — the orchestrator handles everything
