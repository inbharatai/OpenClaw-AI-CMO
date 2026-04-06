#!/bin/bash
# content-agent.sh — Produce content from classified source material
# Usage: ./content-agent.sh [--dry-run] [--type <content-type>]
# Reads: MarketingToolData source folders + .meta.json classification files
# Writes: Content drafts to MarketingToolData output folders + queues/*/pending/
# Logs: OpenClawData/logs/content-agent.log

WORKSPACE_ROOT="/Users/reeturajgoswami/Desktop/CMO-10million"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
MARKETING_DIR="$WORKSPACE_ROOT/MarketingToolData"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/content-agent.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_TAG=$(date '+%Y-%m-%d')
OLLAMA_URL="http://127.0.0.1:11434"

DRY_RUN=false
TARGET_TYPE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --type) TARGET_TYPE="$2"; shift ;;
    esac
    shift
done

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

log "=== Content Agent Started ==="
[ "$DRY_RUN" = true ] && log "[DRY RUN] No content will be written"

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    log "ERROR: Ollama is not running"
    exit 1
fi

TOTAL_PRODUCED=0
TOTAL_SKIPPED=0

# Find all classified but unprocessed source material
SOURCE_DIRS=(
    "$MARKETING_DIR/source-notes"
    "$MARKETING_DIR/source-links"
    "$MARKETING_DIR/product-updates"
)

PROCESSED_LOG="$WORKSPACE_ROOT/OpenClawData/logs/content-produced-files.log"
touch "$PROCESSED_LOG"

for DIR in "${SOURCE_DIRS[@]}"; do
    [ -d "$DIR" ] || continue

    # Find .meta.json files (classification metadata)
    while IFS= read -r -d '' META_FILE; do
        # Skip already processed
        if grep -qF "$META_FILE" "$PROCESSED_LOG" 2>/dev/null; then
            continue
        fi

        # Read classification metadata with error handling
        CONTENT_TYPE=$(python3 -c "
import json, sys
try:
    data = json.load(open('$META_FILE'))
    print(data.get('content_type','unknown'))
except (json.JSONDecodeError, FileNotFoundError) as e:
    print('unknown', file=sys.stderr)
    print('unknown')
" 2>/dev/null)
        STATUS=$(python3 -c "
import json, sys
try:
    data = json.load(open('$META_FILE'))
    print(data.get('status','unknown'))
except (json.JSONDecodeError, FileNotFoundError):
    print('unknown')
" 2>/dev/null)
        SOURCE_FILE=$(python3 -c "
import json, sys
try:
    data = json.load(open('$META_FILE'))
    print(data.get('source_file',''))
except (json.JSONDecodeError, FileNotFoundError):
    print('')
" 2>/dev/null)
        CHANNELS=$(python3 -c "
import json, sys
try:
    data = json.load(open('$META_FILE'))
    print(data.get('suggested_channels','website'))
except (json.JSONDecodeError, FileNotFoundError):
    print('website')
" 2>/dev/null)

        # Validate we got usable data
        [ -z "$CONTENT_TYPE" ] && CONTENT_TYPE="unknown"
        [ -z "$STATUS" ] && STATUS="unknown"

        # Skip if not classified
        [ "$STATUS" != "classified" ] && continue

        # Skip if targeting a specific type
        if [ -n "$TARGET_TYPE" ] && [ "$CONTENT_TYPE" != "$TARGET_TYPE" ]; then
            continue
        fi

        # Read source content
        if [ -f "$SOURCE_FILE" ]; then
            SOURCE_CONTENT=$(cat "$SOURCE_FILE" 2>/dev/null | head -c 2000)
        else
            # Try finding the .md file matching the .meta.json
            MD_FILE="${META_FILE%.meta.json}.md"
            if [ -f "$MD_FILE" ]; then
                SOURCE_FILE="$MD_FILE"
                SOURCE_CONTENT=$(cat "$MD_FILE" 2>/dev/null | head -c 2000)
            else
                log "SKIP: No source file found for $META_FILE"
                TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
                continue
            fi
        fi

        log "PRODUCING: type=$CONTENT_TYPE from $(basename "$SOURCE_FILE")"

        if [ "$DRY_RUN" = true ]; then
            log "[DRY RUN] Would produce $CONTENT_TYPE content"
            echo "$META_FILE" >> "$PROCESSED_LOG"
            continue
        fi

        # Route to appropriate skill based on content type
        case "$CONTENT_TYPE" in
            product-update|product_update)
                SKILL="website-update-writer"
                OUTPUT_DIR="$MARKETING_DIR/website-posts"
                QUEUE_CHANNEL="website"
                SLUG="update"
                ;;
            ai-news|ai_news|news)
                SKILL="ai-news-summarizer"
                OUTPUT_DIR="$MARKETING_DIR/ai-news"
                QUEUE_CHANNEL="website"
                SLUG="news"
                ;;
            founder-log|build-log|founder_log|build_log)
                SKILL="build-log-writer"
                OUTPUT_DIR="$MARKETING_DIR/build-logs"
                QUEUE_CHANNEL="website"
                SLUG="build-log"
                ;;
            educational|educational-post)
                SKILL="website-update-writer"
                OUTPUT_DIR="$MARKETING_DIR/insights"
                QUEUE_CHANNEL="website"
                SLUG="insight"
                ;;
            comparison|tool-comparison)
                SKILL="website-update-writer"
                OUTPUT_DIR="$MARKETING_DIR/insights"
                QUEUE_CHANNEL="website"
                SLUG="comparison"
                ;;
            social-post|social_post)
                SKILL="social-repurposing"
                OUTPUT_DIR="$MARKETING_DIR/linkedin"
                QUEUE_CHANNEL="linkedin"
                SLUG="social"
                ;;
            *)
                SKILL="website-update-writer"
                OUTPUT_DIR="$MARKETING_DIR/website-posts"
                QUEUE_CHANNEL="website"
                SLUG="content"
                ;;
        esac

        # Generate content via skill-runner
        GENERATED=$("$SCRIPTS_DIR/skill-runner.sh" "$SKILL" \
            "Create a $CONTENT_TYPE from this source material. Source: $SOURCE_CONTENT" \
            "qwen3:8b" 2>/dev/null | tail -n +5)

        if [ -z "$GENERATED" ]; then
            log "WARNING: Empty output from $SKILL for $SOURCE_FILE"
            TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
            continue
        fi

        # Write to output folder
        OUTPUT_FILE="$OUTPUT_DIR/$SLUG-$DATE_TAG-$(echo "$(basename "$SOURCE_FILE" .md)" | tr ' ' '-' | head -c 40).md"
        echo "$GENERATED" > "$OUTPUT_FILE"

        # Also place in queue for approval
        QUEUE_FILE="$QUEUES_DIR/$QUEUE_CHANNEL/pending/$(basename "$OUTPUT_FILE")"
        cp "$OUTPUT_FILE" "$QUEUE_FILE"

        # Mark as processed
        echo "$META_FILE" >> "$PROCESSED_LOG"

        # Update meta status
        python3 -c "
import json
meta = json.load(open('$META_FILE'))
meta['status'] = 'content_produced'
meta['output_file'] = '$OUTPUT_FILE'
meta['queue_file'] = '$QUEUE_FILE'
meta['produced_date'] = '$DATE_TAG'
json.dump(meta, open('$META_FILE','w'), indent=2)
" 2>/dev/null

        TOTAL_PRODUCED=$((TOTAL_PRODUCED + 1))
        log "PRODUCED: $OUTPUT_FILE → queued at $QUEUE_FILE"

        # Also generate channel-adapted versions if multiple channels suggested
        if echo "$CHANNELS" | grep -qE "linkedin|x$|x,|discord|instagram"; then
            # Generate Discord announcement if suggested
            if echo "$CHANNELS" | grep -qi "discord"; then
                DISCORD_OUT=$("$SCRIPTS_DIR/skill-runner.sh" discord-announcement-writer \
                    "Create a Discord announcement from this content: $(echo "$GENERATED" | head -c 500)" \
                    "qwen3:8b" 2>/dev/null | tail -n +5)
                if [ -n "$DISCORD_OUT" ]; then
                    DISCORD_FILE="$QUEUES_DIR/discord/pending/discord-$DATE_TAG-$(basename "$SOURCE_FILE" .md | head -c 30).md"
                    echo "$DISCORD_OUT" > "$DISCORD_FILE"
                    log "PRODUCED [discord variant]: $DISCORD_FILE"
                fi
            fi

            # Generate LinkedIn variant if suggested
            if echo "$CHANNELS" | grep -qi "linkedin"; then
                LINKEDIN_OUT=$("$SCRIPTS_DIR/skill-runner.sh" channel-adapter \
                    "Adapt this content for LinkedIn (max 3000 chars, professional tone). Content: $(echo "$GENERATED" | head -c 800)" \
                    "qwen3:8b" 2>/dev/null | tail -n +5)
                if [ -n "$LINKEDIN_OUT" ]; then
                    LI_FILE="$QUEUES_DIR/linkedin/pending/linkedin-$DATE_TAG-$(basename "$SOURCE_FILE" .md | head -c 30).md"
                    echo "$LINKEDIN_OUT" > "$LI_FILE"
                    log "PRODUCED [linkedin variant]: $LI_FILE"
                fi
            fi

            # Generate X/Twitter variant
            if echo "$CHANNELS" | grep -qiE "^x$|^x,|,x,|,x$| x "; then
                X_OUT=$("$SCRIPTS_DIR/skill-runner.sh" channel-adapter \
                    "Adapt this content for X/Twitter (max 280 chars, sharp direct tone, 0-2 hashtags). Content: $(echo "$GENERATED" | head -c 500)" \
                    "qwen3:8b" 2>/dev/null | tail -n +5)
                if [ -n "$X_OUT" ]; then
                    X_FILE="$QUEUES_DIR/x/pending/x-$DATE_TAG-$(basename "$SOURCE_FILE" .md | head -c 30).md"
                    echo "$X_OUT" > "$X_FILE"
                    log "PRODUCED [x variant]: $X_FILE"
                fi
            fi

            # Generate Instagram variant (JSON with image_brief — Instagram requires images)
            if echo "$CHANNELS" | grep -qi "instagram"; then
                INSTA_OUT=$("$SCRIPTS_DIR/skill-runner.sh" channel-adapter \
                    "Create an Instagram caption from this content (max 300 chars, engaging, 5-10 hashtags). Also provide a one-sentence image_brief describing a visual for this post. Format your response as: CAPTION: <caption text> IMAGE_BRIEF: <image description>. Content: $(echo "$GENERATED" | head -c 500)" \
                    "qwen3:8b" 2>/dev/null | tail -n +5)
                if [ -n "$INSTA_OUT" ]; then
                    # Parse caption and image_brief from output
                    INSTA_CAPTION=$(echo "$INSTA_OUT" | sed -n 's/.*CAPTION:\s*//p' | sed 's/IMAGE_BRIEF:.*//' | head -1)
                    INSTA_BRIEF=$(echo "$INSTA_OUT" | sed -n 's/.*IMAGE_BRIEF:\s*//p' | head -1)
                    [ -z "$INSTA_CAPTION" ] && INSTA_CAPTION="$INSTA_OUT"
                    [ -z "$INSTA_BRIEF" ] && INSTA_BRIEF="A clean, vibrant visual representing $CONTENT_TYPE content for InBharat AI"

                    INSTA_FILE="$QUEUES_DIR/instagram/pending/instagram-$DATE_TAG-$(basename "$SOURCE_FILE" .md | head -c 30).json"
                    export INSTA_ENV_CAPTION="$INSTA_CAPTION"
                    export INSTA_ENV_BRIEF="$INSTA_BRIEF"
                    export INSTA_ENV_DATE="$DATE_TAG"
                    export INSTA_ENV_SOURCE="$SOURCE_FILE"
                    python3 << 'INSTAJSON' > "$INSTA_FILE"
import json, os
data = {
    "content_id": f"IG-{os.environ['INSTA_ENV_DATE']}-{os.path.basename(os.environ['INSTA_ENV_SOURCE'])[:20]}",
    "platform_content": {
        "instagram_caption": os.environ['INSTA_ENV_CAPTION']
    },
    "image_brief": os.environ['INSTA_ENV_BRIEF'],
    "image_path": "",
    "product": "inbharat",
    "approval_level": "L2",
    "status": "pending"
}
print(json.dumps(data, indent=2))
INSTAJSON
                    log "PRODUCED [instagram variant]: $INSTA_FILE"
                fi
            fi
        fi

    done < <(find "$DIR" -maxdepth 2 -name "*.meta.json" -print0 2>/dev/null)
done

log "=== Content Agent Complete ==="
log "Produced: $TOTAL_PRODUCED | Skipped: $TOTAL_SKIPPED"

echo ""
echo "━━━ CONTENT AGENT SUMMARY ━━━"
echo "Produced: $TOTAL_PRODUCED"
echo "Skipped:  $TOTAL_SKIPPED"
echo "Log: $LOG_FILE"
