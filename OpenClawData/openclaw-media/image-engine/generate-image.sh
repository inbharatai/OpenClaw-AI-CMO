#!/bin/bash
# generate-image.sh -- OpenClaw Image Generation Router
# Routes image briefs to the best available backend.
#
# Usage:
#   ./generate-image.sh --brief "A multilingual AI chatbot interface" --output /path/to/file.png
#   ./generate-image.sh --brief "brief text" --size 1024x1024 --style vivid
#   ./generate-image.sh --brief "brief text"  # auto-generates output path
#
# Backends (tried in order):
#   1. DALL-E 3 API (if API key available)
#   2. Local Stable Diffusion (if running on localhost:7860)
#   3. Placeholder generator (branded card -- always works offline)
#
# Exit codes:
#   0 = success (image generated)
#   1 = all backends failed

set -uo pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
ENGINE_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/image-engine"
ASSETS_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/assets/images"
BOT_ROOT="$WORKSPACE_ROOT/OpenClawData/inbharat-bot"
DATE=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

# Source logger if available
if [ -f "$BOT_ROOT/logging/bot-logger.sh" ]; then
  source "$BOT_ROOT/logging/bot-logger.sh"
else
  bot_log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$2] [image-engine] $3"; }
fi

# ── Parse Arguments ──
BRIEF=""
OUTPUT=""
SIZE="1024x1024"
STYLE="natural"
QUALITY="standard"
BACKEND=""  # auto, dalle, stable-diffusion, placeholder
CONTENT_ID=""

while [ $# -gt 0 ]; do
  case "$1" in
    --brief)      BRIEF="$2"; shift ;;
    --output)     OUTPUT="$2"; shift ;;
    --size)       SIZE="$2"; shift ;;
    --style)      STYLE="$2"; shift ;;
    --quality)    QUALITY="$2"; shift ;;
    --backend)    BACKEND="$2"; shift ;;
    --content-id) CONTENT_ID="$2"; shift ;;
    -h|--help)
      echo "Usage: generate-image.sh --brief \"description\" [--output path] [--size WxH] [--style natural|vivid] [--backend auto|dalle|placeholder]"
      exit 0
      ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
  shift
done

if [ -z "$BRIEF" ]; then
  echo "ERROR: --brief is required"
  echo "Usage: generate-image.sh --brief \"image description\""
  exit 1
fi

# ── Generate output path if not provided ──
mkdir -p "$ASSETS_DIR"

if [ -z "$OUTPUT" ]; then
  # Create a slug from the brief
  SLUG=$(echo "$BRIEF" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-50 | sed 's/-$//')
  if [ -n "$CONTENT_ID" ]; then
    OUTPUT="$ASSETS_DIR/${CONTENT_ID}-${SLUG}.png"
  else
    OUTPUT="$ASSETS_DIR/img-${DATE}-${SLUG}.png"
  fi
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT")"

bot_log "image-engine" "info" "Image generation requested: ${BRIEF:0:80}"

# ── Backend 1: DALL-E 3 ──
try_dalle() {
  bot_log "image-engine" "info" "Trying DALL-E 3 backend..."

  # Map size for DALL-E (only supports specific sizes)
  local DALLE_SIZE="$SIZE"
  case "$SIZE" in
    1024x1024|1024x1792|1792x1024) ;;  # valid DALL-E sizes
    1080x1080|1200x1200) DALLE_SIZE="1024x1024" ;;
    1080x1920|1080x1350) DALLE_SIZE="1024x1792" ;;
    1920x1080|1200x628)  DALLE_SIZE="1792x1024" ;;
    *) DALLE_SIZE="1024x1024" ;;
  esac

  local RESULT
  RESULT=$(python3 "$ENGINE_DIR/dalle_generate.py" \
    --prompt "$BRIEF" \
    --size "$DALLE_SIZE" \
    --style "$STYLE" \
    --quality "$QUALITY" \
    --output "$OUTPUT" 2>&1)
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    bot_log "image-engine" "info" "DALL-E 3 generation succeeded: $OUTPUT"
    echo "$RESULT"
    return 0
  elif [ $EXIT_CODE -eq 2 ]; then
    bot_log "image-engine" "warn" "DALL-E: No API key available, skipping"
    return 1
  elif [ $EXIT_CODE -eq 3 ]; then
    bot_log "image-engine" "warn" "DALL-E: openai package not installed, skipping"
    return 1
  else
    bot_log "image-engine" "warn" "DALL-E: Generation failed (exit $EXIT_CODE)"
    echo "$RESULT" >&2
    return 1
  fi
}

# ── Backend 2: Local Stable Diffusion ──
try_stable_diffusion() {
  local SD_URL="${STABLE_DIFFUSION_URL:-http://127.0.0.1:7860}"

  # Check if Stable Diffusion API is running
  if ! curl -s --max-time 3 "$SD_URL/sdapi/v1/options" >/dev/null 2>&1; then
    bot_log "image-engine" "info" "Stable Diffusion not running at $SD_URL, skipping"
    return 1
  fi

  bot_log "image-engine" "info" "Trying local Stable Diffusion backend..."

  # Parse dimensions
  local W H
  W=$(echo "$SIZE" | cut -dx -f1)
  H=$(echo "$SIZE" | cut -dx -f2)

  # Round to nearest 64 (SD requirement)
  W=$(( (W + 63) / 64 * 64 ))
  H=$(( (H + 63) / 64 * 64 ))

  # Cap at 1024 for SD
  [ "$W" -gt 1024 ] && W=1024
  [ "$H" -gt 1024 ] && H=1024

  local RESPONSE
  export SD_PROMPT="$BRIEF"
  export SD_WIDTH="$W"
  export SD_HEIGHT="$H"
  RESPONSE=$(curl -s --max-time 120 "$SD_URL/sdapi/v1/txt2img" \
    -H "Content-Type: application/json" \
    -d "$(python3 << 'SDEOF'
import json, os
print(json.dumps({
    'prompt': os.environ['SD_PROMPT'],
    'negative_prompt': 'blurry, low quality, distorted, watermark, text errors',
    'width': int(os.environ['SD_WIDTH']),
    'height': int(os.environ['SD_HEIGHT']),
    'steps': 30,
    'cfg_scale': 7.5,
    'sampler_name': 'DPM++ 2M Karras',
}))
SDEOF
)" 2>&1)

  if [ $? -ne 0 ]; then
    bot_log "image-engine" "warn" "Stable Diffusion API call failed"
    return 1
  fi

  # Extract base64 image and save
  local B64_IMAGE
  B64_IMAGE=$(echo "$RESPONSE" | python3 -c "
import sys, json, base64
try:
    data = json.load(sys.stdin)
    images = data.get('images', [])
    if images:
        print(images[0])
    else:
        sys.exit(1)
except:
    sys.exit(1)
" 2>/dev/null)

  if [ $? -ne 0 ] || [ -z "$B64_IMAGE" ]; then
    bot_log "image-engine" "warn" "Stable Diffusion: Failed to parse response"
    return 1
  fi

  echo "$B64_IMAGE" | base64 -d > "$OUTPUT" 2>/dev/null
  if [ $? -eq 0 ] && [ -s "$OUTPUT" ]; then
    bot_log "image-engine" "info" "Stable Diffusion generation succeeded: $OUTPUT"
    echo "Generated image with local Stable Diffusion"
    echo "  Saved: $OUTPUT ($(wc -c < "$OUTPUT" | tr -d ' ') bytes)"
    echo "$OUTPUT"
    return 0
  fi

  bot_log "image-engine" "warn" "Stable Diffusion: Failed to decode image"
  return 1
}

# ── Backend 3: Placeholder Generator ──
try_placeholder() {
  bot_log "image-engine" "info" "Using placeholder generator..."

  # Map size for placeholder (accepts any WxH)
  local PH_SIZE="$SIZE"
  case "$SIZE" in
    1024x1024) PH_SIZE="1080x1080" ;;
    1024x1792) PH_SIZE="1080x1920" ;;
    1792x1024) PH_SIZE="1920x1080" ;;
  esac

  local RESULT
  RESULT=$(python3 "$ENGINE_DIR/placeholder_generate.py" \
    --text "$BRIEF" \
    --size "$PH_SIZE" \
    --output "$OUTPUT" 2>&1)
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    bot_log "image-engine" "info" "Placeholder generation succeeded: $OUTPUT"
    echo "$RESULT"
    return 0
  else
    bot_log "image-engine" "error" "Placeholder generation failed"
    echo "$RESULT" >&2
    return 1
  fi
}

# ── Route to backends ──
GENERATED=false

if [ -n "$BACKEND" ]; then
  # Explicit backend requested
  case "$BACKEND" in
    dalle)
      try_dalle && GENERATED=true
      ;;
    stable-diffusion|sd)
      try_stable_diffusion && GENERATED=true
      ;;
    placeholder)
      try_placeholder && GENERATED=true
      ;;
    auto|"")
      ;; # fall through to auto logic below
    *)
      echo "ERROR: Unknown backend '$BACKEND'. Use: dalle, stable-diffusion, placeholder, auto"
      exit 1
      ;;
  esac
else
  # Auto mode: try backends in priority order
  try_dalle && GENERATED=true

  if [ "$GENERATED" = false ]; then
    try_stable_diffusion && GENERATED=true
  fi

  if [ "$GENERATED" = false ]; then
    try_placeholder && GENERATED=true
  fi
fi

if [ "$GENERATED" = true ]; then
  # Log success
  BACKEND_USED="unknown"
  [ -f "$OUTPUT" ] && BACKEND_USED="generated"

  echo ""
  echo "--- Image Generation Complete ---"
  echo "Output: $OUTPUT"
  [ -f "$OUTPUT" ] && echo "Size: $(wc -c < "$OUTPUT" | tr -d ' ') bytes"
  exit 0
else
  echo ""
  echo "ERROR: All image generation backends failed."
  echo "Brief: $BRIEF"
  exit 1
fi
