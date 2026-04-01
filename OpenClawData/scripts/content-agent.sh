#!/bin/bash
# content-agent.sh — Produce content from classified source material
# Usage: ./content-agent.sh [--dry-run] [--type <content-type>]
# Reads: MarketingToolData source folders + .meta.json classification files
# Writes: Content drafts to MarketingToolData output folders + queues/*/pending/
# Logs: OpenClawData/logs/content-agent.log

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
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
