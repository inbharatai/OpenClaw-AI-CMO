#!/bin/bash
# generate-image.sh — Generate images via DALL-E 3 (OpenAI API)
# Autonomous Tier 0 — OpenClaw calls this without approval
#
# Usage:
#   bash generate-image.sh "A modern minimalist illustration of AI helping Indian students"
#   bash generate-image.sh "Quote card: Building AI for India" --size 1792x1024
#   bash generate-image.sh "Instagram carousel slide about Phoring" --size 1024x1792
#   bash generate-image.sh --budget   (show today's spend)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="/Volumes/Expansion/CMO-10million"
OUTPUT_DIR="$WORKSPACE/OpenClawData/openclaw-media/generated-images"
BUDGET_LOG="$OUTPUT_DIR/.budget-$(date +%Y-%m-%d).log"
DAILY_BUDGET_CAP=10  # max images per day ($0.40/day at standard quality)

# Get API key from Keychain
API_KEY=$(security find-generic-password -a "openclaw" -s "openai-api-key" -w 2>/dev/null || echo "")
if [ -z "$API_KEY" ]; then
    echo "ERROR: OpenAI API key not found in Keychain"
    echo "Store it: security add-generic-password -a openclaw -s openai-api-key -w YOUR_KEY"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Budget check
check_budget() {
    if [ -f "$BUDGET_LOG" ]; then
        COUNT=$(wc -l < "$BUDGET_LOG" | tr -d ' ')
    else
        COUNT=0
    fi
    echo "$COUNT"
}

show_budget() {
    COUNT=$(check_budget)
    echo "Today's image generation: $COUNT / $DAILY_BUDGET_CAP"
    echo "Estimated cost: \$$(echo "$COUNT * 0.04" | bc 2>/dev/null || echo "~$COUNT x \$0.04")"
    if [ -f "$BUDGET_LOG" ]; then
        echo ""
        echo "Generated today:"
        cat "$BUDGET_LOG"
    fi
}

if [ "${1:-}" = "--budget" ]; then
    show_budget
    exit 0
fi

# Check budget cap
COUNT=$(check_budget)
if [ "$COUNT" -ge "$DAILY_BUDGET_CAP" ]; then
    echo "BUDGET CAP: Already generated $COUNT images today (limit: $DAILY_BUDGET_CAP)"
    echo "Skipping to prevent overspend. Override with --force"
    if [ "${2:-}" != "--force" ] && [ "${3:-}" != "--force" ]; then
        exit 1
    fi
fi

# Parse arguments
PROMPT="${1:?Usage: generate-image.sh \"prompt\" [--size WxH] [--quality standard|hd]}"
SIZE="1024x1024"
QUALITY="standard"
MODEL="dall-e-3"

shift
while [ $# -gt 0 ]; do
    case "$1" in
        --size) SIZE="$2"; shift 2 ;;
        --quality) QUALITY="$2"; shift 2 ;;
        --hd) QUALITY="hd"; shift ;;
        --model) MODEL="$2"; shift 2 ;;
        --force) shift ;;
        *) shift ;;
    esac
done

# Map common size aliases
case "$SIZE" in
    square|1:1) SIZE="1024x1024" ;;
    landscape|16:9) SIZE="1792x1024" ;;
    portrait|9:16|story|reel) SIZE="1024x1792" ;;
esac

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SAFE_NAME=$(echo "$PROMPT" | tr -cd '[:alnum:] ' | tr ' ' '-' | head -c 50)
OUTPUT_FILE="$OUTPUT_DIR/${TIMESTAMP}-${SAFE_NAME}.png"

echo "Generating image..."
echo "  Prompt: $PROMPT"
echo "  Size: $SIZE | Quality: $QUALITY | Model: $MODEL"

# Call DALL-E 3 API
RESPONSE=$(curl -s "https://api.openai.com/v1/images/generations" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"$PROMPT\",
        \"n\": 1,
        \"size\": \"$SIZE\",
        \"quality\": \"$QUALITY\",
        \"response_format\": \"url\"
    }" 2>&1)

# Check for errors
ERROR=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',{}).get('message',''))" 2>/dev/null || echo "")
if [ -n "$ERROR" ]; then
    echo "ERROR: $ERROR"
    exit 1
fi

# Extract image URL and download
IMAGE_URL=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data'][0]['url'])" 2>/dev/null)
REVISED_PROMPT=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data'][0].get('revised_prompt',''))" 2>/dev/null || echo "")

if [ -z "$IMAGE_URL" ]; then
    echo "ERROR: No image URL in response"
    echo "$RESPONSE"
    exit 1
fi

# Download image
curl -s "$IMAGE_URL" -o "$OUTPUT_FILE"

if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo "SAVED: $OUTPUT_FILE ($FILE_SIZE)"

    # Log to budget tracker
    echo "$TIMESTAMP|$SIZE|$QUALITY|$SAFE_NAME" >> "$BUDGET_LOG"

    # Output the path (for piping to other scripts)
    echo "PATH:$OUTPUT_FILE"

    if [ -n "$REVISED_PROMPT" ]; then
        echo "Revised prompt: $REVISED_PROMPT"
    fi
else
    echo "ERROR: Failed to download image"
    exit 1
fi
