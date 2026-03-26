#!/bin/bash
# ============================================================
# visual-brief-generator.sh — Complete Visual Content System
#
# Generates production-ready visual content packs:
#   - carousel (slide-by-slide with design system)
#   - quote-card (shareable quote graphics)
#   - thumbnail (3 options with headline formulas)
#   - story-frames (Instagram/LinkedIn stories)
#   - image-prompt (AI image generation prompts)
#   - creative-pack (ALL of the above from one source)
#
# Does NOT generate pixels — generates the TEXT PACKS that
# a designer, Canva user, or AI image tool uses as input.
#
# Usage:
#   ./visual-brief-generator.sh "content or filepath" [type] [platform]
#   ./visual-brief-generator.sh --auto   (auto-generate from today's approved content)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/date-context.sh"

SCRIPTS_DIR="$SCRIPT_DIR"
OUTPUT_BASE="$WORKSPACE_ROOT/data/image-briefs"
LOG_FILE="$WORKSPACE_ROOT/logs/visual-brief.log"
OLLAMA_URL="http://127.0.0.1:11434"

# Create output subdirectories
for subdir in carousels quote-cards thumbnails story-frames image-prompts creative-packs; do
    mkdir -p "$OUTPUT_BASE/$subdir"
done

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# ── AUTO MODE: Generate visuals from today's approved content ──
if [ "$1" = "--auto" ]; then
    log "=== Visual Brief Auto Mode — $CURRENT_DATE ==="

    APPROVED_DIR="$WORKSPACE_ROOT/approvals/approved"
    QUEUES_APPROVED="$WORKSPACE_ROOT/queues/*/approved"
    TOTAL_GENERATED=0

    # Find today's approved content
    for FILE in "$APPROVED_DIR"/*"$DATE_TAG"*.md "$WORKSPACE_ROOT"/queues/*/approved/*"$DATE_TAG"*.md; do
        [ -f "$FILE" ] || continue

        CONTENT=$(cat "$FILE" | head -c 2000)
        BASENAME=$(basename "$FILE" .md | head -c 40)

        # Determine which visual type based on content
        if echo "$FILE" | grep -qi "linkedin\|x-\|twitter"; then
            BRIEF_TYPE="quote-card"
            SKILL="quote-card-generator"
            OUTDIR="$OUTPUT_BASE/quote-cards"
        elif echo "$FILE" | grep -qi "instagram\|facebook"; then
            BRIEF_TYPE="carousel"
            SKILL="carousel-builder"
            OUTDIR="$OUTPUT_BASE/carousels"
        elif echo "$FILE" | grep -qi "youtube\|video"; then
            BRIEF_TYPE="thumbnail"
            SKILL="thumbnail-generator"
            OUTDIR="$OUTPUT_BASE/thumbnails"
        else
            BRIEF_TYPE="creative-pack"
            SKILL="creative-pack-builder"
            OUTDIR="$OUTPUT_BASE/creative-packs"
        fi

        OUTPUT_FILE="$OUTDIR/$BRIEF_TYPE-$DATE_TAG-$BASENAME.md"

        # Skip if already generated
        if [ -f "$OUTPUT_FILE" ]; then
            log "SKIP: Already exists — $OUTPUT_FILE"
            continue
        fi

        log "GENERATING: $BRIEF_TYPE from $(basename "$FILE")"

        RESULT=$("$SCRIPTS_DIR/skill-runner.sh" "$SKILL" \
            "Create a $BRIEF_TYPE from this content. Use the full skill template.

$DATE_CONTEXT

Source content:
$CONTENT" \
            "qwen3:8b" 2>/dev/null | tail -n +5)

        if [ -n "$RESULT" ]; then
            cat > "$OUTPUT_FILE" <<EOF
---
title: "$BRIEF_TYPE — $(echo "$BASENAME" | tr '-' ' ')"
date: "$CURRENT_DATE"
type: "visual-brief"
format: "$BRIEF_TYPE"
source_file: "$FILE"
auto_generated: true
status: "ready-for-design"
---

$RESULT
EOF
            TOTAL_GENERATED=$((TOTAL_GENERATED + 1))
            log "CREATED: $OUTPUT_FILE"
        else
            log "WARNING: Empty output for $FILE"
        fi
    done

    log "=== Visual Auto Complete — $TOTAL_GENERATED briefs generated ==="
    echo "Generated $TOTAL_GENERATED visual briefs"
    exit 0
fi

# ── MANUAL MODE ──
SOURCE_CONTENT="$1"
BRIEF_TYPE="${2:-carousel}"
PLATFORM="${3:-instagram}"

if [ -z "$SOURCE_CONTENT" ]; then
    echo ""
    echo "Usage:"
    echo "  $0 \"<content or file path>\" [type] [platform]"
    echo "  $0 --auto    (auto-generate from today's approved content)"
    echo ""
    echo "Types:"
    echo "  carousel      — 5-7 slide Instagram/LinkedIn carousel"
    echo "  quote-card    — 3-5 shareable quote graphics"
    echo "  thumbnail     — 3 YouTube/article thumbnail options"
    echo "  story-frames  — 3 Instagram/LinkedIn story frames"
    echo "  image-prompt  — 3 AI image generation prompts"
    echo "  creative-pack — ALL of the above from one source"
    echo ""
    exit 1
fi

# Read file if path
if [ -f "$SOURCE_CONTENT" ]; then
    SOURCE_CONTENT=$(cat "$SOURCE_CONTENT" | head -c 2000)
fi

# Map type to skill and output directory
case "$BRIEF_TYPE" in
    carousel)
        SKILL="carousel-builder"
        OUTDIR="$OUTPUT_BASE/carousels"
        ;;
    quote-card|quote-cards)
        SKILL="quote-card-generator"
        OUTDIR="$OUTPUT_BASE/quote-cards"
        ;;
    thumbnail|thumbnails)
        SKILL="thumbnail-generator"
        OUTDIR="$OUTPUT_BASE/thumbnails"
        ;;
    story-frames|story|stories)
        SKILL="image-brief-generator"
        OUTDIR="$OUTPUT_BASE/story-frames"
        ;;
    image-prompt|image-prompts)
        SKILL="image-brief-generator"
        OUTDIR="$OUTPUT_BASE/image-prompts"
        ;;
    creative-pack|full|all)
        SKILL="creative-pack-builder"
        OUTDIR="$OUTPUT_BASE/creative-packs"
        ;;
    *)
        echo "Unknown type: $BRIEF_TYPE"
        echo "Valid: carousel, quote-card, thumbnail, story-frames, image-prompt, creative-pack"
        exit 1
        ;;
esac

SLUG=$(echo "$BRIEF_TYPE-$PLATFORM-$DATE_TAG" | tr ' ' '-' | head -c 50)
OUTPUT_FILE="$OUTDIR/$SLUG.md"

log "Generating $BRIEF_TYPE for $PLATFORM..."

RESULT=$("$SCRIPTS_DIR/skill-runner.sh" "$SKILL" \
    "Create a $BRIEF_TYPE for $PLATFORM from this content. Use the full skill template structure.

$DATE_CONTEXT

Source content:
$SOURCE_CONTENT" \
    "qwen3:8b" 2>/dev/null | tail -n +5)

if [ -n "$RESULT" ]; then
    cat > "$OUTPUT_FILE" <<EOF
---
title: "$BRIEF_TYPE — $PLATFORM"
date: "$CURRENT_DATE"
type: "visual-brief"
format: "$BRIEF_TYPE"
platform: "$PLATFORM"
status: "ready-for-design"
---

$RESULT
EOF
    log "Created: $OUTPUT_FILE"
    echo "$OUTPUT_FILE"
else
    log "ERROR: Empty result from $SKILL"
    exit 1
fi
