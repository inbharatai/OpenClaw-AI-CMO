#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# generate-video.sh — OpenClaw Video Engine Master Script
#
# Usage:
#   ./generate-video.sh --brief "description" --format shorts --output /path/to/video.mp4
#   ./generate-video.sh --file /path/to/content.json --output /path/to/video.mp4
#   ./generate-video.sh --file /path/to/content.json   (auto-names output)
#   ./generate-video.sh --heygen --file /path/to/content.json  (HeyGen brief)
#   ./generate-video.sh --heygen --file content.json --format linkedin-video-insight
#   ./generate-video.sh --check                         (dependency check)
#
# Environment:
#   VIDEO_ENGINE_DIR — override location of script_to_video.py
#   OPENCLAW_ROOT    — override project root
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIDEO_ENGINE_DIR="${VIDEO_ENGINE_DIR:-$SCRIPT_DIR}"
OPENCLAW_ROOT="${OPENCLAW_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
ASSETS_DIR="$OPENCLAW_ROOT/OpenClawData/openclaw-media/assets/videos"
LOG_DIR="$OPENCLAW_ROOT/OpenClawData/logs"
LOG_FILE="$LOG_DIR/video-engine.log"
PYTHON_SCRIPT="$VIDEO_ENGINE_DIR/script_to_video.py"
HEYGEN_SCRIPT="$VIDEO_ENGINE_DIR/heygen-brief-generator.sh"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [video-engine] $1"
    echo -e "${BLUE}${msg}${NC}" >&2
    mkdir -p "$LOG_DIR"
    echo "$msg" >> "$LOG_FILE"
}

error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [video-engine] ERROR: $1"
    echo -e "${RED}${msg}${NC}" >&2
    mkdir -p "$LOG_DIR"
    echo "$msg" >> "$LOG_FILE"
}

success() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [video-engine] $1"
    echo -e "${GREEN}${msg}${NC}" >&2
    mkdir -p "$LOG_DIR"
    echo "$msg" >> "$LOG_FILE"
}

# ── Dependency Check ─────────────────────────────────────────────────────────
check_deps() {
    local all_ok=true

    echo "OpenClaw Video Engine — Dependency Check"
    echo "========================================="

    # FFmpeg (required)
    if command -v ffmpeg &>/dev/null; then
        echo -e "  ${GREEN}ffmpeg${NC}        $(ffmpeg -version 2>&1 | head -1 | cut -d' ' -f3)"
    else
        echo -e "  ${RED}ffmpeg${NC}        MISSING (required) — install with: brew install ffmpeg"
        all_ok=false
    fi

    # Python 3 (required)
    if command -v python3 &>/dev/null; then
        echo -e "  ${GREEN}python3${NC}       $(python3 --version 2>&1 | cut -d' ' -f2)"
    else
        echo -e "  ${RED}python3${NC}       MISSING (required)"
        all_ok=false
    fi

    # macOS say (optional, for TTS)
    if command -v say &>/dev/null; then
        echo -e "  ${GREEN}say${NC}           available (macOS TTS)"
    else
        echo -e "  ${YELLOW}say${NC}           not available (videos will be silent)"
    fi

    # Playwright (optional, for branded slides)
    if python3 -c "from playwright.sync_api import sync_playwright" 2>/dev/null; then
        echo -e "  ${GREEN}playwright${NC}    available (branded slides)"
    else
        echo -e "  ${YELLOW}playwright${NC}    not available (will use FFmpeg fallback slides)"
    fi

    # script_to_video.py
    if [[ -f "$PYTHON_SCRIPT" ]]; then
        echo -e "  ${GREEN}engine${NC}        $PYTHON_SCRIPT"
    else
        echo -e "  ${RED}engine${NC}        MISSING: $PYTHON_SCRIPT"
        all_ok=false
    fi

    echo ""
    if $all_ok; then
        echo -e "${GREEN}Ready to generate videos.${NC}"
        return 0
    else
        echo -e "${RED}Missing required dependencies. Install them first.${NC}"
        return 1
    fi
}

# ── Usage ────────────────────────────────────────────────────────────────────
usage() {
    cat <<'USAGE'
Usage: generate-video.sh [OPTIONS]

Options:
  --brief TEXT          Video description / narration script
  --title TEXT          Video title (default: "InBharat")
  --file PATH           Path to content-package JSON (extracts video_brief)
  --output PATH         Output MP4 path (auto-generated if omitted)
  --format FORMAT       Video format: "shorts", "landscape", or a HeyGen format name
  --duration SECS       Target duration in seconds (default: 15)
  --heygen              Route to HeyGen brief generator instead of FFmpeg
  --check               Check dependencies and exit
  --help                Show this help

HeyGen Formats (use with --heygen):
  ig-reel-explainer, ig-reel-product-demo, yt-shorts-explainer,
  yt-shorts-problem-solution, linkedin-video-insight,
  linkedin-video-announcement, founder-update-long, product-walkthrough,
  podcast-promo-clip, community-update

Examples:
  ./generate-video.sh --brief "AI is transforming India" --format shorts
  ./generate-video.sh --file content-package.json --output demo.mp4
  ./generate-video.sh --heygen --file content-package.json
  ./generate-video.sh --heygen --file content-package.json --format linkedin-video-insight
  ./generate-video.sh --check
USAGE
}

# ── Parse Arguments ──────────────────────────────────────────────────────────
BRIEF=""
TITLE="InBharat"
INPUT_FILE=""
OUTPUT=""
FORMAT="shorts"
DURATION=15
CHECK_ONLY=false
USE_HEYGEN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --brief)    BRIEF="$2"; shift 2 ;;
        --title)    TITLE="$2"; shift 2 ;;
        --file)     INPUT_FILE="$2"; shift 2 ;;
        --output)   OUTPUT="$2"; shift 2 ;;
        --format)   FORMAT="$2"; shift 2 ;;
        --duration) DURATION="$2"; shift 2 ;;
        --heygen)   USE_HEYGEN=true; shift ;;
        --check)    CHECK_ONLY=true; shift ;;
        --help)     usage; exit 0 ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# ── Dependency check mode ────────────────────────────────────────────────────
if $CHECK_ONLY; then
    check_deps
    exit $?
fi

# ── HeyGen routing ──────────────────────────────────────────────────────────
# When --heygen is specified, delegate to heygen-brief-generator.sh and exit.
if $USE_HEYGEN; then
    if [[ -z "$INPUT_FILE" ]]; then
        error "--heygen requires --file (content package JSON)"
        usage
        exit 1
    fi

    if [[ ! -f "$INPUT_FILE" ]]; then
        error "Content package not found: $INPUT_FILE"
        exit 1
    fi

    if [[ ! -f "$HEYGEN_SCRIPT" ]]; then
        error "HeyGen brief generator not found: $HEYGEN_SCRIPT"
        exit 1
    fi

    log "Routing to HeyGen brief generator..."

    HEYGEN_ARGS=(--file "$INPUT_FILE")

    # Pass --format if it is a HeyGen format name (not "shorts" or "landscape")
    if [[ "$FORMAT" != "shorts" && "$FORMAT" != "landscape" ]]; then
        HEYGEN_ARGS+=(--format "$FORMAT")
    fi

    if bash "$HEYGEN_SCRIPT" "${HEYGEN_ARGS[@]}"; then
        success "HeyGen brief generation complete"
        exit 0
    else
        error "HeyGen brief generation failed"
        exit 1
    fi
fi

# ── Validate inputs ─────────────────────────────────────────────────────────
if [[ -z "$BRIEF" && -z "$INPUT_FILE" ]]; then
    error "Either --brief or --file is required"
    usage
    exit 1
fi

if ! command -v ffmpeg &>/dev/null; then
    error "FFmpeg is required but not found. Install with: brew install ffmpeg"
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    error "Python 3 is required but not found."
    exit 1
fi

if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    error "Video engine script not found: $PYTHON_SCRIPT"
    exit 1
fi

# ── Generate output path if not specified ────────────────────────────────────
if [[ -z "$OUTPUT" ]]; then
    mkdir -p "$ASSETS_DIR"
    TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
    if [[ -n "$INPUT_FILE" ]]; then
        BASENAME="$(basename "$INPUT_FILE" .json)"
        OUTPUT="$ASSETS_DIR/${BASENAME}-${TIMESTAMP}.mp4"
    else
        OUTPUT="$ASSETS_DIR/video-${TIMESTAMP}.mp4"
    fi
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT")"

# ── Route to Python engine ───────────────────────────────────────────────────
log "Starting video generation..."
log "  Format:   $FORMAT"
log "  Duration: ${DURATION}s"
log "  Output:   $OUTPUT"

PYTHON_ARGS=()

if [[ -n "$INPUT_FILE" ]]; then
    if [[ ! -f "$INPUT_FILE" ]]; then
        error "Input file not found: $INPUT_FILE"
        exit 1
    fi
    log "  Source:   $INPUT_FILE"
    PYTHON_ARGS+=(--json "$INPUT_FILE")
else
    log "  Brief:    ${BRIEF:0:80}..."
    PYTHON_ARGS+=(--script "$BRIEF")
fi

PYTHON_ARGS+=(
    --title "$TITLE"
    --output "$OUTPUT"
    --format "$FORMAT"
    --duration "$DURATION"
    --brand
)

START_TIME=$(date +%s)

if python3 "$PYTHON_SCRIPT" "${PYTHON_ARGS[@]}"; then
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    FILE_SIZE=$(ls -lh "$OUTPUT" 2>/dev/null | awk '{print $5}')
    success "Video generated in ${ELAPSED}s: $OUTPUT ($FILE_SIZE)"
    echo "$OUTPUT"
    exit 0
else
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    error "Video generation failed after ${ELAPSED}s"
    exit 1
fi
