# HeyGen Browser Automation Workflow

> OpenClaw Media System -- Avatar Video Production Protocol
>
> Last updated: 2026-04-01

---

## Overview

HeyGen is used for avatar/presenter video creation in the OpenClaw media pipeline.
The founder's cloned voice and avatar already exist in HeyGen.
HeyGen is browser-operated -- no API access is assumed.

All HeyGen videos must pass human review before publishing. No auto-generation
without script review.

---

## Safety Rules

1. **Script review required.** Every script must be read and approved by the founder
   before it is pasted into HeyGen. No blind copy-paste from AI output.
2. **Review before publishing.** Download the rendered video, watch it fully, and
   confirm lip sync, pacing, and accuracy before distributing.
3. **No restricted claims.** Cross-check the content package's `restricted_claims`
   array. Remove any unsupported claims before recording.
4. **Watermark check.** HeyGen free-tier videos may include a watermark. Ensure
   the account tier supports watermark-free export before production runs.
5. **Brand consistency.** Use the OpenClaw/InBharat branded backgrounds and scene
   layouts documented below. Do not use default HeyGen templates unless no custom
   option exists.
6. **File naming.** Always follow the output filename convention:
   `heygen-{format}-{content_id}-{YYYYMMDD}.mp4`
7. **Proof archival.** Save a copy of every rendered video to
   `OpenClawData/openclaw-media/assets/videos/heygen/` before distribution.

---

## Video Formats That Use HeyGen

The following 10 formats require avatar/presenter video via HeyGen:

| # | Format Name                  | Platform     | Duration  | Aspect Ratio | Scene Layout                  |
|---|------------------------------|--------------|-----------|--------------|-------------------------------|
| 1 | `ig-reel-explainer`          | Instagram    | 30-60s    | 9:16         | Presenter full-screen         |
| 2 | `ig-reel-product-demo`       | Instagram    | 30-60s    | 9:16         | Presenter + screenshot overlay|
| 3 | `yt-shorts-explainer`        | YouTube      | 30-60s    | 9:16         | Presenter full-screen         |
| 4 | `yt-shorts-problem-solution` | YouTube      | 30-60s    | 9:16         | Presenter + side content      |
| 5 | `linkedin-video-insight`     | LinkedIn     | 60-90s    | 16:9         | Presenter side-by-side        |
| 6 | `linkedin-video-announcement`| LinkedIn     | 30-60s    | 16:9         | Presenter + branded BG        |
| 7 | `founder-update-long`        | YouTube      | 3-5min    | 16:9         | Presenter + slides            |
| 8 | `product-walkthrough`        | YouTube      | 2-4min    | 16:9         | Presenter overlay on demo     |
| 9 | `podcast-promo-clip`         | Multi        | 30-60s    | 1:1 or 9:16  | Presenter with waveform BG    |
|10 | `community-update`           | Discord/Web  | 60-120s   | 16:9         | Presenter + bullet slides     |

### Formats That Do NOT Use HeyGen

These formats are produced entirely via FFmpeg/script_to_video.py and do not
require avatar generation:

- **`discord-insider-update`** -- Text-based card with branded overlay. No avatar
  presenter. Generated via FFmpeg compositing in generate-video.sh.
- **`x-teaser-cutdown`** -- Short text animation with product screenshots. No
  avatar. Generated via FFmpeg with text burn-in and transitions.

---

## Browser Workflow: Step-by-Step

### Prerequisites

- Chrome or Firefox with HeyGen logged in at https://app.heygen.com
- Founder avatar and cloned voice configured in HeyGen account
- Script text finalized and reviewed (from HeyGen production brief)
- Background assets exported (screenshots, branded slides) in PNG/JPG format

---

### Step 1: Open HeyGen and Start a New Video

1. Navigate to https://app.heygen.com
2. Click **"Create Video"** from the dashboard
3. Select **"Avatar Video"** as the video type
4. Choose **"Instant Avatar"** tab and select the founder's saved avatar

### Step 2: Configure the Workspace

1. Set the **aspect ratio** based on the format:
   - 9:16 for Instagram Reels and YouTube Shorts formats
   - 16:9 for LinkedIn, YouTube long-form, and community updates
   - 1:1 for podcast promo clips (if targeting square format)
2. Set the **video name** using the naming convention:
   `heygen-{format}-{content_id}-{YYYYMMDD}`

### Step 3: Set Up Scene Layout

Choose the layout based on the format's scene layout requirement:

#### Layout A: Presenter Full-Screen

Used by: `ig-reel-explainer`, `yt-shorts-explainer`

1. Select the avatar as the only element
2. Position the avatar centered in frame
3. Set avatar size to fill approximately 60-70% of frame height
4. Apply a solid branded background color (#1a1a2e or #0f0f23)
   or upload a branded gradient background from
   `OpenClawData/openclaw-media/assets/backgrounds/`

#### Layout B: Presenter + Screenshot Overlay

Used by: `ig-reel-product-demo`, `yt-shorts-problem-solution`

1. Position the avatar in the bottom-left or bottom-right (roughly 30% of frame)
2. Click **"Add Element"** > **"Image"**
3. Upload the product screenshot or demo image
4. Position the image in the remaining space (top or opposite side)
5. Resize the image to fill approximately 60% of the frame
6. Apply a slight border-radius or shadow if the platform supports it

#### Layout C: Presenter Side-by-Side

Used by: `linkedin-video-insight`

1. Split the canvas into two halves
2. Place the avatar on the left (approximately 40% width)
3. Add a content panel (image or text card) on the right (approximately 55% width)
4. Upload the relevant chart, infographic, or key-points card
5. Use a neutral dark background behind both elements

#### Layout D: Presenter + Branded Background

Used by: `linkedin-video-announcement`

1. Upload the branded announcement background from
   `OpenClawData/openclaw-media/assets/backgrounds/announcement-bg.png`
2. Position the avatar centered or slightly left
3. Add branded text overlay if HeyGen supports it, or plan to add it in post via FFmpeg

#### Layout E: Presenter + Slides (Multi-Scene)

Used by: `founder-update-long`, `community-update`

1. Create **multiple scenes** in HeyGen (one per slide/talking point)
2. Scene 1: Avatar full-screen with intro/greeting
3. Scenes 2-N: Avatar in corner (picture-in-picture) with slide image as background
   - Upload each slide as a background image
   - Resize avatar to bottom-right corner (approximately 20-25% of frame)
4. Final scene: Avatar full-screen with CTA/closing

#### Layout F: Presenter Overlay on Demo

Used by: `product-walkthrough`

1. Upload the product demo screenshot or screen recording frame as background
2. Position the avatar as a small circle/rectangle in the bottom-right corner
3. Avatar size: approximately 15-20% of frame
4. Ensure the avatar does not obscure critical UI elements in the demo

#### Layout G: Presenter with Waveform Background

Used by: `podcast-promo-clip`

1. Upload the podcast waveform background or audio-visual graphic
2. Position the avatar centered
3. Avatar size: approximately 40-50% of frame
4. Apply the podcast branding colors as background overlay

### Step 4: Enter the Script

1. Click on the avatar or the script input panel
2. Paste the script text from the HeyGen production brief
   - The brief is located in `OpenClawData/queues/heygen/pending/`
   - Use the `script_text` field from the brief JSON
3. Select the **cloned voice** from the voice dropdown
   - Verify it shows the founder's custom voice, not a stock voice
4. Set the speaking **speed/pace**:
   - Normal (1.0x) for explainers and long-form
   - Slightly faster (1.1x) for shorts and reels
5. For multi-scene videos, repeat this for each scene with the corresponding
   segment of the script

### Step 5: Configure Avatar Behavior

1. Set **gestures** based on the brief's `avatar_instructions`:
   - "conversational" -- natural hand gestures enabled
   - "professional" -- minimal gestures, steady posture
   - "enthusiastic" -- more animated gestures and expressions
2. Set **expression**:
   - Default to "friendly" for most formats
   - Use "serious" for problem-statement or challenge-focused content
3. Set **eye contact**: Always set to "camera" (direct eye contact)

### Step 6: Preview and Adjust

1. Click **"Preview"** to generate a low-resolution preview
2. Check the following:
   - Lip sync accuracy with the cloned voice
   - Avatar positioning does not clip or overlap incorrectly
   - Background/overlay assets are visible and correctly placed
   - Script pacing matches the target duration
3. If the preview exceeds the target duration:
   - Trim the script text
   - Increase speaking speed slightly
4. If the preview is too short:
   - Add natural pauses in the script (use "..." or comma breaks)
   - Reduce speaking speed

### Step 7: Render the Video

1. Click **"Submit"** or **"Generate"** to start rendering
2. HeyGen will process the video (typically 2-10 minutes depending on length)
3. Wait for the email notification or check the **"Videos"** tab in HeyGen
4. Do NOT close the browser tab during rendering

### Step 8: Download the Final Video

1. Navigate to **"Videos"** in the HeyGen dashboard
2. Find the completed video by name
3. Click **"Download"** and select the highest quality option (1080p preferred)
4. Save to: `OpenClawData/openclaw-media/assets/videos/heygen/`
5. Use the filename convention:
   `heygen-{format}-{content_id}-{YYYYMMDD}.mp4`

### Step 9: Post-Production (If Needed)

Some formats require additional post-processing after HeyGen export:

1. **Add lower-thirds or text overlays** -- Use FFmpeg:
   ```
   ffmpeg -i heygen-output.mp4 -vf "drawtext=text='Follow @InBharat':fontsize=24:x=50:y=h-80:fontcolor=white" output.mp4
   ```
2. **Add intro/outro bumpers** -- Concatenate with FFmpeg:
   ```
   ffmpeg -f concat -safe 0 -i filelist.txt -c copy final.mp4
   ```
3. **Resize for different platforms** -- Use generate-video.sh with the FFmpeg path
4. **Add captions/subtitles** -- Burn in via FFmpeg drawtext filter

### Step 10: Update Status and Move to Distribution

1. Move the production brief from `queues/heygen/pending/` to `queues/heygen/approved/`
2. Update the content package JSON:
   - Set `heygen_status` to `"rendered"`
   - Set `video_asset_path` to the downloaded file path
3. The distribution engine will pick up the completed video for publishing

---

## Format-Specific Instructions

### 1. ig-reel-explainer (Instagram Reel -- Explainer)

- **Duration:** 30-60 seconds
- **Aspect ratio:** 9:16
- **Layout:** Presenter full-screen (Layout A)
- **Script style:** Hook in first 3 seconds, problem-solution-CTA structure
- **Avatar:** Conversational gestures, friendly expression
- **Background:** Branded gradient or solid dark color
- **Post-production:** Add Instagram-safe text overlays, hashtag card at end

### 2. ig-reel-product-demo (Instagram Reel -- Product Demo)

- **Duration:** 30-60 seconds
- **Aspect ratio:** 9:16
- **Layout:** Presenter + screenshot overlay (Layout B)
- **Script style:** "Let me show you..." format, walk through product UI
- **Avatar:** Professional gestures, positioned bottom-left
- **Background:** Product screenshot fills upper portion
- **Post-production:** May need screenshot zoom/pan effects via FFmpeg

### 3. yt-shorts-explainer (YouTube Short -- Explainer)

- **Duration:** 30-60 seconds
- **Aspect ratio:** 9:16
- **Layout:** Presenter full-screen (Layout A)
- **Script style:** Strong hook, educational content, subscribe CTA
- **Avatar:** Enthusiastic gestures for engagement
- **Background:** Branded gradient, slightly different from IG version
- **Post-production:** Add YouTube-style subscribe button overlay

### 4. yt-shorts-problem-solution (YouTube Short -- Problem/Solution)

- **Duration:** 30-60 seconds
- **Aspect ratio:** 9:16
- **Layout:** Presenter + side content (Layout B)
- **Script style:** "The problem is... here's how we solve it"
- **Avatar:** Serious expression for problem, friendly for solution
- **Background:** Split -- dark for problem statement, lighter for solution
- **Post-production:** Two-tone background transition if not achievable in HeyGen

### 5. linkedin-video-insight (LinkedIn Video -- Insight)

- **Duration:** 60-90 seconds
- **Aspect ratio:** 16:9
- **Layout:** Presenter side-by-side (Layout C)
- **Script style:** Data-driven insight, professional tone, thought leadership
- **Avatar:** Professional gestures, steady eye contact
- **Background:** Chart or data visualization on the right panel
- **Post-production:** Ensure LinkedIn's auto-caption is compatible; add manual captions

### 6. linkedin-video-announcement (LinkedIn Video -- Announcement)

- **Duration:** 30-60 seconds
- **Aspect ratio:** 16:9
- **Layout:** Presenter + branded background (Layout D)
- **Script style:** Announcement structure -- what, why, what's next
- **Avatar:** Professional, slightly enthusiastic
- **Background:** Branded announcement template
- **Post-production:** Add branded lower-third with founder name and title

### 7. founder-update-long (YouTube -- Founder Update)

- **Duration:** 3-5 minutes
- **Aspect ratio:** 16:9
- **Layout:** Presenter + slides, multi-scene (Layout E)
- **Script style:** Conversational, transparent, covers multiple topics
- **Avatar:** Conversational gestures, natural pacing
- **Background:** Intro/outro full-screen, middle scenes with slide backgrounds
- **Scene count:** Typically 5-10 scenes
- **Post-production:** Add chapter markers, intro bumper, subscribe CTA end screen

### 8. product-walkthrough (YouTube -- Product Walkthrough)

- **Duration:** 2-4 minutes
- **Aspect ratio:** 16:9
- **Layout:** Presenter overlay on demo (Layout F)
- **Script style:** Step-by-step tutorial, "click here, then do this"
- **Avatar:** Small overlay in corner, professional gestures
- **Background:** Product UI screenshots or screen recordings
- **Scene count:** One scene per feature/step being demonstrated
- **Post-production:** May overlay actual screen recording underneath with avatar PIP

### 9. podcast-promo-clip (Multi-Platform -- Podcast Promo)

- **Duration:** 30-60 seconds
- **Aspect ratio:** 1:1 (primary) or 9:16 (secondary)
- **Layout:** Presenter with waveform background (Layout G)
- **Script style:** Teaser quote from the podcast episode, "listen now" CTA
- **Avatar:** Conversational, engaging
- **Background:** Audio waveform graphic or podcast cover art
- **Post-production:** Add podcast platform links, episode number overlay

### 10. community-update (Discord/Web -- Community Update)

- **Duration:** 60-120 seconds
- **Aspect ratio:** 16:9
- **Layout:** Presenter + bullet slides, multi-scene (Layout E)
- **Script style:** Informal, community-focused, update/changelog style
- **Avatar:** Friendly and casual gestures
- **Background:** Bullet-point slides with community metrics or updates
- **Scene count:** 3-5 scenes
- **Post-production:** Compress for Discord upload limits (max 25MB for non-Nitro)

---

## Asset Locations

| Asset Type              | Path                                                              |
|-------------------------|-------------------------------------------------------------------|
| Branded backgrounds     | `OpenClawData/openclaw-media/assets/backgrounds/`                 |
| Product screenshots     | `OpenClawData/openclaw-media/assets/screenshots/`                 |
| Slide templates         | `OpenClawData/openclaw-media/assets/slides/`                      |
| Rendered HeyGen videos  | `OpenClawData/openclaw-media/assets/videos/heygen/`               |
| HeyGen production briefs| `OpenClawData/queues/heygen/pending/`                             |
| Approved briefs         | `OpenClawData/queues/heygen/approved/`                            |

---

## Troubleshooting

| Issue                          | Resolution                                                    |
|--------------------------------|---------------------------------------------------------------|
| Avatar lip sync is off         | Re-generate with a shorter script or add punctuation pauses   |
| Video exceeds target duration  | Trim script, increase speed to 1.1x                          |
| Background image is blurry     | Upload at least 1920x1080 for 16:9, 1080x1920 for 9:16       |
| Cloned voice sounds robotic    | Check HeyGen voice settings, ensure correct voice is selected |
| Rendering stuck/failed         | Refresh HeyGen dashboard, re-submit. Check account credits    |
| Watermark on output            | Verify HeyGen subscription tier supports watermark-free export|
