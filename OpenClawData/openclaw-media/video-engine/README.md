# OpenClaw Video Engine

Generates branded slide-based videos from content package `video_brief` and `shorts_description` fields.

## Pipeline

```
Content Package (JSON)
  → Extract video_brief / shorts_description
  → Split text into 3-5 key points
  → Generate branded slide PNGs (Playwright or FFmpeg fallback)
  → Generate TTS narration (macOS `say`)
  → Assemble slides + audio into MP4 (FFmpeg)
  → Output: ready for Shorts/Reels/LinkedIn
```

## Requirements

| Tool       | Required | Install                                          |
|------------|----------|--------------------------------------------------|
| FFmpeg     | Yes      | `brew install ffmpeg`                             |
| Python 3   | Yes      | Pre-installed on macOS                            |
| Playwright | No       | `pip install playwright && playwright install chromium` |
| macOS `say`| No       | Built-in (videos will be silent without it)       |

Run `./generate-video.sh --check` to verify your setup.

## Usage

### Single video from text

```bash
./generate-video.sh --brief "AI is transforming rural India" \
    --title "AI for Bharat" \
    --format shorts \
    --output /path/to/video.mp4
```

### Single video from content package

```bash
./generate-video.sh --file /path/to/content-package.json \
    --output /path/to/video.mp4
```

### Batch process all pending briefs

```bash
./process-briefs.sh              # process all
./process-briefs.sh --dry-run    # preview what would be processed
./process-briefs.sh --limit 3    # process at most 3
```

### Python script directly

```bash
python3 script_to_video.py --script "Your text here" \
    --title "Title" --output video.mp4 --format shorts

python3 script_to_video.py --json content-package.json --output video.mp4

python3 script_to_video.py --check   # dependency check
```

## Output Formats

| Format      | Resolution  | Aspect Ratio | Use Case                |
|-------------|-------------|--------------|-------------------------|
| `shorts`    | 1080x1920   | 9:16         | YouTube Shorts, Reels   |
| `landscape` | 1920x1080   | 16:9         | YouTube, LinkedIn Video  |

## Brand Colors

- **Orange**: `#FF6B35` — accents, headings, logo
- **Dark Blue**: `#1A1A2E` — backgrounds
- **White**: `#FFFFFF` — body text

## Directory Structure

```
video-engine/
├── generate-video.sh      # Master CLI script
├── script_to_video.py     # Python video generation engine
├── process-briefs.sh      # Batch processor for content queues
└── README.md              # This file

assets/videos/             # Generated videos land here
```

## How It Works

1. **Text Splitting**: The script is split into 3-5 key points at sentence boundaries.
2. **Slide Generation**: Each point becomes a branded slide. With Playwright, full HTML/CSS slides are rendered. Without it, FFmpeg's `drawtext` filter generates simpler slides.
3. **TTS**: On macOS, the `say` command generates AIFF audio, converted to WAV. On other systems, videos are silent.
4. **Assembly**: FFmpeg combines slide images + audio into an MP4 with the `libx264` codec, `yuv420p` pixel format, and `faststart` for web playback.

## Logs

All operations log to `OpenClawData/logs/video-engine.log`.
