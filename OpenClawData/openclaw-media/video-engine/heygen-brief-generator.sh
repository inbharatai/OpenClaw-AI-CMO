#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# heygen-brief-generator.sh — Generate HeyGen Production Briefs from Content Packages
#
# Takes a content package JSON and produces a structured HeyGen production brief
# with script text, scene breakdown, asset requirements, and avatar instructions.
#
# Usage:
#   ./heygen-brief-generator.sh --file /path/to/content-package.json
#   ./heygen-brief-generator.sh --file /path/to/content-package.json --format linkedin-video-insight
#   ./heygen-brief-generator.sh --file /path/to/content-package.json --dry-run
#
# Environment:
#   OPENCLAW_ROOT    — override project root
#   HEYGEN_QUEUE_DIR — override output directory for briefs
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_ROOT="${OPENCLAW_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
HEYGEN_QUEUE_DIR="${HEYGEN_QUEUE_DIR:-$OPENCLAW_ROOT/OpenClawData/queues/heygen/pending}"
LOG_DIR="$OPENCLAW_ROOT/OpenClawData/logs"
LOG_FILE="$LOG_DIR/video-engine.log"
BOT_ROOT="$OPENCLAW_ROOT/OpenClawData/inbharat-bot"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Logger ───────────────────────────────────────────────────────────────────
# Source bot logger if available, otherwise use local fallback
if [[ -f "$BOT_ROOT/logging/bot-logger.sh" ]]; then
    # shellcheck source=/dev/null
    source "$BOT_ROOT/logging/bot-logger.sh"
else
    bot_log() {
        local component="${1:-heygen-brief}"
        local level="${2:-info}"
        local message="${3:-}"
        local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [$component] $message"
        echo -e "$msg" >&2
        mkdir -p "$LOG_DIR"
        echo "$msg" >> "$LOG_FILE"
    }
fi

log() {
    bot_log "heygen-brief" "info" "$1"
}

error() {
    bot_log "heygen-brief" "error" "$1"
}

success() {
    bot_log "heygen-brief" "info" "$1"
}

# ── Video Format Definitions ────────────────────────────────────────────────
# Lookup function for format properties (compatible with bash 3.x on macOS).
# Returns: aspect_ratio|duration_min|duration_max|layout|scene_type
get_format_def() {
    case "$1" in
        ig-reel-explainer)           echo "9:16|30|60|presenter-fullscreen|single" ;;
        ig-reel-product-demo)        echo "9:16|30|60|presenter-screenshot-overlay|single" ;;
        yt-shorts-explainer)         echo "9:16|30|60|presenter-fullscreen|single" ;;
        yt-shorts-problem-solution)  echo "9:16|30|60|presenter-side-content|single" ;;
        linkedin-video-insight)      echo "16:9|60|90|presenter-side-by-side|single" ;;
        linkedin-video-announcement) echo "16:9|30|60|presenter-branded-bg|single" ;;
        founder-update-long)         echo "16:9|180|300|presenter-slides|multi" ;;
        product-walkthrough)         echo "16:9|120|240|presenter-overlay-demo|multi" ;;
        podcast-promo-clip)          echo "1:1|30|60|presenter-waveform|single" ;;
        community-update)            echo "16:9|60|120|presenter-bullet-slides|multi" ;;
        *)                           echo "" ;;
    esac
}

ALL_HEYGEN_FORMATS="ig-reel-explainer ig-reel-product-demo yt-shorts-explainer yt-shorts-problem-solution linkedin-video-insight linkedin-video-announcement founder-update-long product-walkthrough podcast-promo-clip community-update"

# Formats that do NOT use HeyGen
NON_HEYGEN_FORMATS="discord-insider-update x-teaser-cutdown"

is_non_heygen_format() {
    local fmt="$1"
    for f in $NON_HEYGEN_FORMATS; do
        if [[ "$f" == "$fmt" ]]; then
            return 0
        fi
    done
    return 1
}

# ── Usage ────────────────────────────────────────────────────────────────────
usage() {
    cat <<'USAGE'
Usage: heygen-brief-generator.sh [OPTIONS]

Options:
  --file PATH       Path to content-package JSON (required)
  --format FORMAT   HeyGen video format (auto-detected from package if omitted)
  --dry-run         Print the brief to stdout without saving
  --list-formats    List all available HeyGen video formats
  --help            Show this help

Available Formats:
  ig-reel-explainer           Instagram Reel — Explainer (9:16, 30-60s)
  ig-reel-product-demo        Instagram Reel — Product Demo (9:16, 30-60s)
  yt-shorts-explainer         YouTube Short — Explainer (9:16, 30-60s)
  yt-shorts-problem-solution  YouTube Short — Problem/Solution (9:16, 30-60s)
  linkedin-video-insight      LinkedIn Video — Insight (16:9, 60-90s)
  linkedin-video-announcement LinkedIn Video — Announcement (16:9, 30-60s)
  founder-update-long         YouTube — Founder Update (16:9, 3-5min)
  product-walkthrough         YouTube — Product Walkthrough (16:9, 2-4min)
  podcast-promo-clip          Multi — Podcast Promo (1:1, 30-60s)
  community-update            Discord/Web — Community Update (16:9, 60-120s)

Non-HeyGen formats (FFmpeg only):
  discord-insider-update      Text card, no avatar
  x-teaser-cutdown            Text animation, no avatar
USAGE
}

# ── Parse Arguments ──────────────────────────────────────────────────────────
INPUT_FILE=""
FORMAT_OVERRIDE=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --file)         INPUT_FILE="$2"; shift 2 ;;
        --format)       FORMAT_OVERRIDE="$2"; shift 2 ;;
        --dry-run)      DRY_RUN=true; shift ;;
        --list-formats)
            echo "HeyGen Video Formats:"
            for fmt in $ALL_HEYGEN_FORMATS; do
                IFS='|' read -r ar dmin dmax layout scene <<< "$(get_format_def "$fmt")"
                printf "  %-30s %s  %s-%ss  %s\n" "$fmt" "$ar" "$dmin" "$dmax" "$layout"
            done
            echo ""
            echo "Non-HeyGen formats (FFmpeg only):"
            for fmt in $NON_HEYGEN_FORMATS; do
                echo "  $fmt"
            done
            exit 0
            ;;
        --help)         usage; exit 0 ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# ── Validate inputs ─────────────────────────────────────────────────────────
if [[ -z "$INPUT_FILE" ]]; then
    error "Missing required --file argument"
    usage
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    error "Content package not found: $INPUT_FILE"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    error "jq is required but not found. Install with: brew install jq"
    exit 1
fi

# Validate JSON
if ! jq empty "$INPUT_FILE" 2>/dev/null; then
    error "Invalid JSON in content package: $INPUT_FILE"
    exit 1
fi

# ── Extract content package fields ───────────────────────────────────────────
CONTENT_ID="$(jq -r '.content_id // "unknown"' "$INPUT_FILE")"
PRODUCT="$(jq -r '.product // "unknown"' "$INPUT_FILE")"
BUCKET="$(jq -r '.bucket // "general"' "$INPUT_FILE")"
GOAL="$(jq -r '.goal // ""' "$INPUT_FILE")"
HOOK="$(jq -r '.hook // ""' "$INPUT_FILE")"
SUMMARY="$(jq -r '.summary // ""' "$INPUT_FILE")"
VIDEO_BRIEF="$(jq -r '.video_brief // ""' "$INPUT_FILE")"
CTA="$(jq -r '.cta // ""' "$INPUT_FILE")"
PROOF_REQ="$(jq -r '.proof_requirements // ""' "$INPUT_FILE")"

# Extract restricted claims as a newline-separated list
RESTRICTED_CLAIMS="$(jq -r '(.restricted_claims // []) | join("\n")' "$INPUT_FILE")"

# Extract platforms
PLATFORMS="$(jq -r '(.platforms // []) | join(",")' "$INPUT_FILE")"

log "Processing content package: $CONTENT_ID ($PRODUCT)"

# ── Determine video format ──────────────────────────────────────────────────
detect_format() {
    # If format override is provided, use it
    if [[ -n "$FORMAT_OVERRIDE" ]]; then
        echo "$FORMAT_OVERRIDE"
        return
    fi

    # Check if it's a non-HeyGen format
    if is_non_heygen_format "$FORMAT_OVERRIDE"; then
        error "Format '$FORMAT_OVERRIDE' does not use HeyGen. Use generate-video.sh with FFmpeg instead."
        exit 1
    fi

    # Auto-detect based on platforms and content
    local detected=""
    case "$PLATFORMS" in
        *instagram*)
            if [[ -n "$PROOF_REQ" && "$PROOF_REQ" != "null" ]]; then
                detected="ig-reel-product-demo"
            else
                detected="ig-reel-explainer"
            fi
            ;;
        *shorts*)
            if echo "$GOAL" | grep -qi "problem\|challenge\|gap"; then
                detected="yt-shorts-problem-solution"
            else
                detected="yt-shorts-explainer"
            fi
            ;;
        *linkedin*)
            if echo "$GOAL" | grep -qi "announce\|launch\|release"; then
                detected="linkedin-video-announcement"
            else
                detected="linkedin-video-insight"
            fi
            ;;
        *discord*)
            detected="community-update"
            ;;
        *)
            detected="yt-shorts-explainer"
            ;;
    esac

    echo "$detected"
}

VIDEO_FORMAT="$(detect_format)"

# Validate format
if [[ -n "$FORMAT_OVERRIDE" ]] && is_non_heygen_format "$FORMAT_OVERRIDE"; then
    error "Format '$FORMAT_OVERRIDE' does not use HeyGen. Use generate-video.sh with FFmpeg instead."
    exit 1
fi

FORMAT_DEF_STR="$(get_format_def "$VIDEO_FORMAT")"
if [[ -z "$FORMAT_DEF_STR" ]]; then
    error "Unknown video format: $VIDEO_FORMAT"
    echo "Valid formats:" >&2
    for fmt in $ALL_HEYGEN_FORMATS; do
        echo "  $fmt" >&2
    done
    exit 1
fi

# Parse format definition
IFS='|' read -r ASPECT_RATIO DURATION_MIN DURATION_MAX LAYOUT SCENE_TYPE <<< "$FORMAT_DEF_STR"

log "Selected format: $VIDEO_FORMAT ($ASPECT_RATIO, ${DURATION_MIN}-${DURATION_MAX}s, $LAYOUT)"

# ── Determine avatar instructions based on format ────────────────────────────
get_avatar_instructions() {
    local format="$1"
    local gestures="conversational"
    local expression="friendly"
    local position="center"
    local size="70%"
    local eye_contact="camera"

    case "$format" in
        ig-reel-explainer|yt-shorts-explainer)
            gestures="enthusiastic"
            expression="friendly"
            position="center"
            size="70%"
            ;;
        ig-reel-product-demo)
            gestures="professional"
            expression="friendly"
            position="bottom-left"
            size="30%"
            ;;
        yt-shorts-problem-solution)
            gestures="conversational"
            expression="serious-to-friendly"
            position="center"
            size="60%"
            ;;
        linkedin-video-insight)
            gestures="professional"
            expression="confident"
            position="left"
            size="40%"
            ;;
        linkedin-video-announcement)
            gestures="professional"
            expression="enthusiastic"
            position="center-left"
            size="50%"
            ;;
        founder-update-long)
            gestures="conversational"
            expression="friendly"
            position="center"
            size="70%"
            ;;
        product-walkthrough)
            gestures="professional"
            expression="focused"
            position="bottom-right"
            size="20%"
            ;;
        podcast-promo-clip)
            gestures="conversational"
            expression="engaging"
            position="center"
            size="50%"
            ;;
        community-update)
            gestures="casual"
            expression="friendly"
            position="center"
            size="60%"
            ;;
    esac

    # Output as JSON using environment variables to avoid shell injection
    export AV_GESTURES="$gestures"
    export AV_EXPRESSION="$expression"
    export AV_POSITION="$position"
    export AV_SIZE="$size"
    export AV_EYE_CONTACT="$eye_contact"

    python3 << 'AVATAREOF'
import json, os
print(json.dumps({
    "gestures": os.environ["AV_GESTURES"],
    "expression": os.environ["AV_EXPRESSION"],
    "position": os.environ["AV_POSITION"],
    "size": os.environ["AV_SIZE"],
    "eye_contact": os.environ["AV_EYE_CONTACT"]
}, indent=2))
AVATAREOF
}

AVATAR_JSON="$(get_avatar_instructions "$VIDEO_FORMAT")"

# ── Generate script text ─────────────────────────────────────────────────────
generate_script_text() {
    # Use video_brief if available, otherwise compose from hook + summary + cta
    if [[ -n "$VIDEO_BRIEF" && "$VIDEO_BRIEF" != "null" ]]; then
        echo "$VIDEO_BRIEF"
        return
    fi

    local script_parts=()

    if [[ -n "$HOOK" && "$HOOK" != "null" ]]; then
        script_parts+=("$HOOK")
    fi

    if [[ -n "$SUMMARY" && "$SUMMARY" != "null" ]]; then
        script_parts+=("$SUMMARY")
    fi

    if [[ -n "$CTA" && "$CTA" != "null" ]]; then
        script_parts+=("$CTA")
    fi

    if [[ ${#script_parts[@]} -eq 0 ]]; then
        echo "[SCRIPT NEEDED: No video_brief, hook, summary, or CTA found in content package. Write a script manually.]"
        return
    fi

    printf '%s\n\n' "${script_parts[@]}"
}

SCRIPT_TEXT="$(generate_script_text)"

# ── Determine background/overlay assets needed ──────────────────────────────
get_assets_needed() {
    local format="$1"

    export ASSET_FORMAT="$format"
    export ASSET_PROOF_REQ="$PROOF_REQ"
    export ASSET_PRODUCT="$PRODUCT"

    python3 << 'ASSETSEOF'
import json, os

fmt = os.environ["ASSET_FORMAT"]
proof = os.environ.get("ASSET_PROOF_REQ", "")
product = os.environ.get("ASSET_PRODUCT", "")

assets = []

if fmt in ("ig-reel-product-demo", "yt-shorts-problem-solution", "product-walkthrough"):
    assets.append({
        "type": "screenshot",
        "description": f"{product} product UI screenshot",
        "required": True,
        "recommended_resolution": "1080x1920" if "9:16" in fmt else "1920x1080"
    })

if fmt in ("linkedin-video-insight",):
    assets.append({
        "type": "chart_or_infographic",
        "description": "Data visualization or key-points card for side panel",
        "required": True,
        "recommended_resolution": "960x1080"
    })

if fmt in ("linkedin-video-announcement",):
    assets.append({
        "type": "branded_background",
        "description": "Announcement branded background template",
        "required": True,
        "recommended_resolution": "1920x1080"
    })

if fmt in ("founder-update-long", "community-update"):
    assets.append({
        "type": "slide_deck",
        "description": "Slide images for each talking point (PNG/JPG per slide)",
        "required": True,
        "recommended_resolution": "1920x1080"
    })

if fmt in ("product-walkthrough",):
    assets.append({
        "type": "demo_screenshots",
        "description": "Product demo screenshots for each walkthrough step",
        "required": True,
        "recommended_resolution": "1920x1080"
    })

if fmt in ("podcast-promo-clip",):
    assets.append({
        "type": "waveform_background",
        "description": "Audio waveform graphic or podcast cover art",
        "required": False,
        "recommended_resolution": "1080x1080"
    })

# Always need a branded background as fallback
assets.append({
    "type": "branded_gradient",
    "description": "Default branded gradient background",
    "required": False,
    "recommended_resolution": "1920x1080"
})

print(json.dumps(assets, indent=2))
ASSETSEOF
}

ASSETS_JSON="$(get_assets_needed "$VIDEO_FORMAT")"

# ── Build scene breakdown ────────────────────────────────────────────────────
build_scene_breakdown() {
    local format="$1"
    local scene_type="$2"

    export SCENE_FORMAT="$format"
    export SCENE_TYPE="$scene_type"
    export SCENE_HOOK="$HOOK"
    export SCENE_SUMMARY="$SUMMARY"
    export SCENE_CTA="$CTA"
    export SCENE_SCRIPT="$SCRIPT_TEXT"

    python3 << 'SCENEEOF'
import json, os

fmt = os.environ["SCENE_FORMAT"]
stype = os.environ["SCENE_TYPE"]
hook = os.environ.get("SCENE_HOOK", "")
summary = os.environ.get("SCENE_SUMMARY", "")
cta = os.environ.get("SCENE_CTA", "")
script = os.environ.get("SCENE_SCRIPT", "")

scenes = []

if stype == "single":
    scenes.append({
        "scene_number": 1,
        "description": "Full video — single scene",
        "script_segment": script.strip(),
        "layout_notes": f"Use {fmt} layout as documented in heygen-workflow.md",
        "background": "As specified in assets_needed"
    })
else:
    # Multi-scene: intro + content scenes + outro
    scenes.append({
        "scene_number": 1,
        "description": "Intro — Avatar full-screen greeting",
        "script_segment": hook if hook else "[Opening hook — write intro text]",
        "layout_notes": "Avatar centered, full-screen, branded background",
        "background": "Branded gradient"
    })

    # Split summary into content scenes (rough split by sentences)
    if summary:
        sentences = [s.strip() for s in summary.replace(". ", ".\n").split("\n") if s.strip()]
        for i, sentence in enumerate(sentences, start=2):
            scenes.append({
                "scene_number": i,
                "description": f"Content scene {i-1}",
                "script_segment": sentence,
                "layout_notes": "Avatar in corner (PIP), slide/screenshot as background",
                "background": f"Slide {i-1} or relevant screenshot"
            })
        next_num = len(sentences) + 2
    else:
        scenes.append({
            "scene_number": 2,
            "description": "Content scene — main message",
            "script_segment": "[Main content — split into multiple scenes as needed]",
            "layout_notes": "Avatar in corner (PIP), slide as background",
            "background": "Content slide"
        })
        next_num = 3

    scenes.append({
        "scene_number": next_num,
        "description": "Outro — CTA and closing",
        "script_segment": cta if cta else "[Closing CTA — write outro text]",
        "layout_notes": "Avatar centered, full-screen, branded background with CTA text",
        "background": "Branded gradient with CTA overlay"
    })

print(json.dumps(scenes, indent=2))
SCENEEOF
}

SCENES_JSON="$(build_scene_breakdown "$VIDEO_FORMAT" "$SCENE_TYPE")"

# ── Compose the production brief ────────────────────────────────────────────
DATE_STAMP="$(date '+%Y-%m-%d')"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
OUTPUT_FILENAME="heygen-${VIDEO_FORMAT}-${CONTENT_ID}-${DATE_STAMP}.mp4"
BRIEF_FILENAME="heygen-brief-${CONTENT_ID}-${TIMESTAMP}.json"

export BRIEF_CONTENT_ID="$CONTENT_ID"
export BRIEF_PRODUCT="$PRODUCT"
export BRIEF_BUCKET="$BUCKET"
export BRIEF_GOAL="$GOAL"
export BRIEF_VIDEO_FORMAT="$VIDEO_FORMAT"
export BRIEF_ASPECT_RATIO="$ASPECT_RATIO"
export BRIEF_DURATION_MIN="$DURATION_MIN"
export BRIEF_DURATION_MAX="$DURATION_MAX"
export BRIEF_LAYOUT="$LAYOUT"
export BRIEF_SCENE_TYPE="$SCENE_TYPE"
export BRIEF_SCRIPT_TEXT="$SCRIPT_TEXT"
export BRIEF_SCENES_JSON="$SCENES_JSON"
export BRIEF_ASSETS_JSON="$ASSETS_JSON"
export BRIEF_AVATAR_JSON="$AVATAR_JSON"
export BRIEF_OUTPUT_FILENAME="$OUTPUT_FILENAME"
export BRIEF_DATE_STAMP="$DATE_STAMP"
export BRIEF_TIMESTAMP="$TIMESTAMP"
export BRIEF_SOURCE_FILE="$INPUT_FILE"
export BRIEF_RESTRICTED_CLAIMS="$RESTRICTED_CLAIMS"
export BRIEF_CTA="$CTA"

BRIEF_JSON="$(python3 << 'BRIEFEOF'
import json, os

brief = {
    "brief_type": "heygen-production",
    "generated_at": os.environ["BRIEF_TIMESTAMP"],
    "source_content_package": os.environ["BRIEF_SOURCE_FILE"],
    "content_id": os.environ["BRIEF_CONTENT_ID"],
    "product": os.environ["BRIEF_PRODUCT"],
    "bucket": os.environ["BRIEF_BUCKET"],
    "goal": os.environ["BRIEF_GOAL"],
    "video_format": {
        "name": os.environ["BRIEF_VIDEO_FORMAT"],
        "aspect_ratio": os.environ["BRIEF_ASPECT_RATIO"],
        "duration_target": {
            "min_seconds": int(os.environ["BRIEF_DURATION_MIN"]),
            "max_seconds": int(os.environ["BRIEF_DURATION_MAX"])
        },
        "layout": os.environ["BRIEF_LAYOUT"],
        "scene_type": os.environ["BRIEF_SCENE_TYPE"]
    },
    "script_text": os.environ["BRIEF_SCRIPT_TEXT"],
    "scene_breakdown": json.loads(os.environ["BRIEF_SCENES_JSON"]),
    "assets_needed": json.loads(os.environ["BRIEF_ASSETS_JSON"]),
    "avatar_instructions": json.loads(os.environ["BRIEF_AVATAR_JSON"]),
    "output_filename": os.environ["BRIEF_OUTPUT_FILENAME"],
    "cta": os.environ["BRIEF_CTA"],
    "restricted_claims": [
        c for c in os.environ.get("BRIEF_RESTRICTED_CLAIMS", "").split("\n") if c.strip()
    ],
    "safety": {
        "script_reviewed": False,
        "review_note": "REVIEW REQUIRED: Read the script_text and restricted_claims before generating in HeyGen."
    },
    "status": "pending",
    "heygen_status": "brief-generated"
}

print(json.dumps(brief, indent=2, ensure_ascii=False))
BRIEFEOF
)"

# ── Output the brief ────────────────────────────────────────────────────────
if $DRY_RUN; then
    echo ""
    echo -e "${YELLOW}=== DRY RUN: HeyGen Production Brief ===${NC}"
    echo "$BRIEF_JSON" | python3 -m json.tool 2>/dev/null || echo "$BRIEF_JSON"
    echo ""
    echo -e "${YELLOW}Would save to:${NC} $HEYGEN_QUEUE_DIR/$BRIEF_FILENAME"
    echo -e "${YELLOW}Output video name:${NC} $OUTPUT_FILENAME"
    exit 0
fi

# Save the brief
mkdir -p "$HEYGEN_QUEUE_DIR"
BRIEF_PATH="$HEYGEN_QUEUE_DIR/$BRIEF_FILENAME"
echo "$BRIEF_JSON" > "$BRIEF_PATH"

if [[ ! -f "$BRIEF_PATH" ]]; then
    error "Failed to write brief to $BRIEF_PATH"
    exit 1
fi

log "Brief saved: $BRIEF_PATH"

# ── Update the content package with heygen_status ────────────────────────────
UPDATED_PACKAGE="$(jq \
    --arg status "brief-generated" \
    --arg brief_path "$BRIEF_PATH" \
    --arg video_format "$VIDEO_FORMAT" \
    '. + {heygen_status: $status, heygen_brief_path: $brief_path, heygen_video_format: $video_format}' \
    "$INPUT_FILE"
)"

if [[ -n "$UPDATED_PACKAGE" ]]; then
    echo "$UPDATED_PACKAGE" > "$INPUT_FILE"
    log "Updated content package with heygen_status: brief-generated"
else
    error "Failed to update content package — original file unchanged"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}HeyGen Production Brief Generated${NC}"
echo "──────────────────────────────────────────────"
echo -e "  Content ID:    ${BLUE}${CONTENT_ID}${NC}"
echo -e "  Product:       $PRODUCT"
echo -e "  Format:        $VIDEO_FORMAT ($ASPECT_RATIO)"
echo -e "  Duration:      ${DURATION_MIN}-${DURATION_MAX}s"
echo -e "  Layout:        $LAYOUT"
echo -e "  Scenes:        $SCENE_TYPE"
echo -e "  Brief:         $BRIEF_PATH"
echo -e "  Output name:   $OUTPUT_FILENAME"
echo ""
echo -e "  ${YELLOW}Next step:${NC} Review the brief, prepare assets, then follow heygen-workflow.md"
echo ""

success "HeyGen brief generated for $CONTENT_ID ($VIDEO_FORMAT)"
echo "$BRIEF_PATH"
exit 0
