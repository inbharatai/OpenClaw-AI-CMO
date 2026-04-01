# OpenClaw Image Engine

Generates images from content package `image_brief` and `cover_brief` fields.

## Architecture

```
image-engine/
  generate-image.sh        Master router - picks best available backend
  dalle_generate.py        DALL-E 3 backend (requires API key)
  placeholder_generate.py  Offline fallback - branded card generator
  process-briefs.sh        Batch processor - scans queues and generates all
```

## Quick Start

```bash
# Generate a single image (auto-selects backend)
./generate-image.sh --brief "A multilingual AI chatbot interface with rural citizens"

# Force placeholder (no API needed)
./generate-image.sh --brief "Sahaayak logo thumbnail" --backend placeholder

# Batch process all content packages
./process-briefs.sh

# Dry run to see what would be generated
./process-briefs.sh --dry-run
```

## Backends (Priority Order)

1. **DALL-E 3** -- Best quality. Requires `OPENAI_API_KEY` env var or macOS Keychain entry.
2. **Stable Diffusion** -- Local generation. Requires SD WebUI running on `localhost:7860`.
3. **Placeholder** -- Always works offline. Creates branded cards with brief text.

## Setup

### DALL-E (optional)
```bash
# Option A: Environment variable
export OPENAI_API_KEY=sk-...

# Option B: macOS Keychain
security add-generic-password -s "openclaw" -a "openclaw-openai-api-key" -w "sk-..."

# Install Python package
pip3 install openai
```

### Placeholder (recommended minimum)
```bash
# Best output (Playwright)
pip3 install playwright && python3 -m playwright install chromium

# Alternative (Pillow)
pip3 install Pillow

# No install needed -- falls back to HTML file output
```

### Stable Diffusion (optional)
Run AUTOMATIC1111 or similar with `--api` flag on port 7860.

## Output

Images are saved to: `OpenClawData/openclaw-media/assets/images/`

Naming convention:
- Single: `img-YYYY-MM-DD-<slug>.png`
- Batch: `<content-id>-image.png` or `<content-id>-cover.png`

## Integration

The image engine is called automatically by `native-pipeline/generate-content.sh` after content generation. Image generation failures are logged as warnings but do not block content pipeline.
