#!/bin/bash
# generate-video-local.sh — Generate basic videos locally via ffmpeg (FREE)
# Autonomous Tier 0 — OpenClaw calls this without approval
#
# Formats:
#   1. Image slideshow with transitions
#   2. Text animation (title card / stat reveal)
#   3. Ken Burns (zoom/pan on static image)
#   4. Quote card video (text on background)
#   5. Carousel-to-video (multiple images → video)
#
# Usage:
#   bash generate-video-local.sh slideshow img1.png img2.png img3.png --output out.mp4
#   bash generate-video-local.sh text "AI is transforming India" --output title.mp4
#   bash generate-video-local.sh kenburns image.png --output zoom.mp4
#   bash generate-video-local.sh quote "Building in public" --author "Reeturaj Goswami" --output quote.mp4

set -euo pipefail

WORKSPACE="/Volumes/Expansion/CMO-10million"
OUTPUT_DIR="$WORKSPACE/OpenClawData/openclaw-media/generated-videos"
mkdir -p "$OUTPUT_DIR"

# Find ffmpeg
if command -v ffmpeg &>/dev/null; then
    FFMPEG="ffmpeg"
elif [ -x "$HOME/local/bin/ffmpeg" ]; then
    FFMPEG="$HOME/local/bin/ffmpeg"
elif [ -x "/usr/local/bin/ffmpeg" ]; then
    FFMPEG="/usr/local/bin/ffmpeg"
elif [ -x "/opt/homebrew/bin/ffmpeg" ]; then
    FFMPEG="/opt/homebrew/bin/ffmpeg"
else
    echo "ERROR: ffmpeg not found"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FORMAT="${1:?Usage: generate-video-local.sh <format> [args] --output <file>}"
shift

# Parse --output from any position
OUTPUT=""
ARGS=()
while [ $# -gt 0 ]; do
    case "$1" in
        --output) OUTPUT="$2"; shift 2 ;;
        --author) AUTHOR="$2"; shift 2 ;;
        --duration) DURATION="$2"; shift 2 ;;
        --size) VSIZE="$2"; shift 2 ;;
        --bg) BG_COLOR="$2"; shift 2 ;;
        --font-color) FONT_COLOR="$2"; shift 2 ;;
        *) ARGS+=("$1"); shift ;;
    esac
done

DURATION="${DURATION:-5}"
VSIZE="${VSIZE:-1080x1920}"  # Default: vertical (Reels/Shorts)
BG_COLOR="${BG_COLOR:-black}"
FONT_COLOR="${FONT_COLOR:-white}"
AUTHOR="${AUTHOR:-}"

# Default output name
if [ -z "$OUTPUT" ]; then
    OUTPUT="$OUTPUT_DIR/${TIMESTAMP}-${FORMAT}.mp4"
fi

# Ensure absolute path for output
case "$OUTPUT" in
    /*) ;; # already absolute
    *) OUTPUT="$OUTPUT_DIR/$OUTPUT" ;;
esac

case "$FORMAT" in

slideshow)
    # Image slideshow with crossfade transitions
    # Args: image1.png image2.png image3.png ...
    if [ ${#ARGS[@]} -lt 2 ]; then
        echo "ERROR: Need at least 2 images for slideshow"
        exit 1
    fi

    # Build ffmpeg filter for crossfade
    N=${#ARGS[@]}
    SLIDE_DUR=3  # seconds per slide
    FADE_DUR=1   # crossfade duration

    # Build input array safely (handles spaces in filenames)
    INPUT_ARGS=()
    for i in "${!ARGS[@]}"; do
        INPUT_ARGS+=(-loop 1 -t "$SLIDE_DUR" -i "${ARGS[$i]}")
    done

    # Simple concat with fade
    FILTER_PARTS=""
    for i in "${!ARGS[@]}"; do
        FILTER_PARTS="${FILTER_PARTS}[$i:v]scale=${VSIZE}:force_original_aspect_ratio=decrease,pad=${VSIZE}:(ow-iw)/2:(oh-ih)/2:${BG_COLOR},setsar=1,fade=t=in:st=0:d=0.5,fade=t=out:st=$((SLIDE_DUR-1)):d=0.5[v$i];"
    done

    CONCAT=""
    for i in "${!ARGS[@]}"; do
        CONCAT="${CONCAT}[v$i]"
    done
    FILTER="${FILTER_PARTS}${CONCAT}concat=n=$N:v=1:a=0[outv]"

    "$FFMPEG" -y "${INPUT_ARGS[@]}" -filter_complex "$FILTER" -map '[outv]' -c:v libx264 -pix_fmt yuv420p -r 30 "$OUTPUT" 2>/dev/null
    echo "SAVED: $OUTPUT (slideshow, ${N} slides)"
    ;;

text)
    # Text animation — text fades in on colored background
    # Args: "Text to display"
    TEXT="${ARGS[0]:?Provide text as first argument}"

    # Escape special characters for ffmpeg drawtext
    TEXT=$(echo "$TEXT" | sed "s/'/'\\\\\\''/g; s/:/\\\\:/g; s/%/%%/g")

    # Calculate font size based on text length
    TEXT_LEN=${#TEXT}
    if [ "$TEXT_LEN" -lt 30 ]; then
        FONTSIZE=72
    elif [ "$TEXT_LEN" -lt 60 ]; then
        FONTSIZE=56
    elif [ "$TEXT_LEN" -lt 100 ]; then
        FONTSIZE=42
    else
        FONTSIZE=32
    fi

    W=$(echo "$VSIZE" | cut -dx -f1)
    H=$(echo "$VSIZE" | cut -dx -f2)

    $FFMPEG -y -f lavfi -i "color=c=${BG_COLOR}:s=${VSIZE}:d=${DURATION}:r=30" \
        -vf "drawtext=text='${TEXT}':fontsize=${FONTSIZE}:fontcolor=${FONT_COLOR}:x=(w-text_w)/2:y=(h-text_h)/2:alpha='if(lt(t,1),t,if(lt(t,${DURATION}-1),1,(${DURATION}-t)))'" \
        -c:v libx264 -pix_fmt yuv420p "$OUTPUT" 2>/dev/null

    echo "SAVED: $OUTPUT (text animation, ${DURATION}s)"
    ;;

kenburns)
    # Ken Burns effect — slow zoom on static image
    # Args: image.png
    IMAGE="${ARGS[0]:?Provide image path}"

    W=$(echo "$VSIZE" | cut -dx -f1)
    H=$(echo "$VSIZE" | cut -dx -f2)

    $FFMPEG -y -loop 1 -i "$IMAGE" -t "$DURATION" \
        -vf "scale=2*${W}:2*${H},zoompan=z='min(zoom+0.0015,1.5)':d=$((DURATION*30)):s=${VSIZE}:fps=30" \
        -c:v libx264 -pix_fmt yuv420p "$OUTPUT" 2>/dev/null

    echo "SAVED: $OUTPUT (Ken Burns, ${DURATION}s)"
    ;;

quote)
    # Quote card video — quote text with author attribution
    # Args: "Quote text" --author "Name"
    QUOTE="${ARGS[0]:?Provide quote text}"

    # Escape special characters for ffmpeg drawtext
    QUOTE=$(echo "$QUOTE" | sed "s/'/'\\\\\\''/g; s/:/\\\\:/g; s/%/%%/g")

    W=$(echo "$VSIZE" | cut -dx -f1)
    H=$(echo "$VSIZE" | cut -dx -f2)

    AUTHOR_TEXT=""
    if [ -n "$AUTHOR" ]; then
        AUTHOR_ESCAPED=$(echo "$AUTHOR" | sed "s/'/'\\\\\\''/g; s/:/\\\\:/g; s/%/%%/g")
        AUTHOR_TEXT="— $AUTHOR_ESCAPED"
    fi

    $FFMPEG -y -f lavfi -i "color=c=0x1a1a2e:s=${VSIZE}:d=${DURATION}:r=30" \
        -vf "drawtext=text='${QUOTE}':fontsize=48:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2-40:alpha='if(lt(t,1),t,1)',drawtext=text='${AUTHOR_TEXT}':fontsize=32:fontcolor=0xaaaaaa:x=(w-text_w)/2:y=(h/2)+60:alpha='if(lt(t,1.5),t/1.5,1)'" \
        -c:v libx264 -pix_fmt yuv420p "$OUTPUT" 2>/dev/null

    echo "SAVED: $OUTPUT (quote card, ${DURATION}s)"
    ;;

*)
    echo "Unknown format: $FORMAT"
    echo "Available: slideshow, text, kenburns, quote"
    exit 1
    ;;
esac

echo "PATH:$OUTPUT"
