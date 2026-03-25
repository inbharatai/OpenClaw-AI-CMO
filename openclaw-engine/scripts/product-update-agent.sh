#!/bin/bash
# ============================================================
# product-update-agent.sh — Process product notes into multi-channel content
# OPTIMIZED: Uses FAST layer for channel variants, THINKING only for main format
# Before: 5 LLM calls × 8B model = ~200s per item
# After:  1 THINK + 4 FAST = ~60s per item (3x faster)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/date-context.sh"
source "$SCRIPT_DIR/layer-router.sh"

DATA_DIR="$WORKSPACE_ROOT/data"
QUEUES_DIR="$WORKSPACE_ROOT/queues"
LOG_FILE="$WORKSPACE_ROOT/logs/product-update-agent.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

DRY_RUN=false
[ "$1" = "--dry-run" ] && DRY_RUN=true

log() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
    echo "$1"
}

log "=== Product Update Agent Started ==="

if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    log "ERROR: Ollama is not running"
    exit 1
fi

PROCESSED_LOG="$WORKSPACE_ROOT/logs/product-updates-processed.log"
touch "$PROCESSED_LOG"

TOTAL_PROCESSED=0
PIPELINE_START=$(timer_start)

for SOURCE_DIR in "$DATA_DIR/product-updates" "$DATA_DIR/source-notes"; do
    [ -d "$SOURCE_DIR" ] || continue

    while IFS= read -r -d '' FILE; do
        FILENAME=$(basename "$FILE")
        [[ "$FILENAME" == .* ]] && continue
        [[ "$FILENAME" == *.meta.json ]] && continue
        [[ "$FILENAME" == *-formatted.md ]] && continue

        grep -qF "$FILE" "$PROCESSED_LOG" 2>/dev/null && continue

        CONTENT=$(cat "$FILE" 2>/dev/null)
        [ -z "$CONTENT" ] && continue

        # Quick keyword check — no LLM needed
        if ! echo "$CONTENT" | grep -qiE "release|ship|launch|feature|fix|update|version|improve|patch|build"; then
            continue
        fi

        log "PROCESSING: $FILENAME"

        if [ "$DRY_RUN" = true ]; then
            log "[DRY RUN] Would process: $FILENAME"
            echo "$FILE" >> "$PROCESSED_LOG"
            continue
        fi

        SLUG=$(echo "$FILENAME" | sed 's/\.md$//' | sed 's/\.txt$//' | tr ' ' '-' | head -c 40)
        ITEM_START=$(timer_start)

        # Step 1: THINKING LAYER — Format the product update (the only deep task)
        FORMATTED=$(llm_think "Format this raw product update into professional, structured content with clear sections (What Changed, Why It Matters, Technical Details). Source: $CONTENT" "product-format")

        if [ -z "$FORMATTED" ]; then
            log "WARNING: Empty output for $FILENAME"
            continue
        fi

        FORMATTED_FILE="$DATA_DIR/product-updates/$SLUG-formatted.md"
        echo "$FORMATTED" > "$FORMATTED_FILE"

        # Write meta
        python3 -c "
import json
json.dump({
    'source_file': '$FILE',
    'formatted_file': '$FORMATTED_FILE',
    'content_type': 'product-update',
    'status': 'classified',
    'date': '$DATE_TAG',
    'suggested_channels': 'website,discord,linkedin,x'
}, open('$DATA_DIR/product-updates/$SLUG-formatted.meta.json', 'w'), indent=2)
" 2>/dev/null

        # Step 2: FAST LAYER — Website update (quick reformat, not deep reasoning)
        WEBSITE_POST=$(llm_fast "Reformat this product update as a website /updates post. Keep it concise. Content: $(echo "$FORMATTED" | head -c 800)" "product-website")

        if [ -n "$WEBSITE_POST" ]; then
            WEBSITE_FILE="$DATA_DIR/website-posts/update-$DATE_TAG-$SLUG.md"
            echo "$WEBSITE_POST" > "$WEBSITE_FILE"
            mkdir -p "$QUEUES_DIR/website/pending"
            cp "$WEBSITE_FILE" "$QUEUES_DIR/website/pending/"
            log "PRODUCED [website]: $WEBSITE_FILE"
        fi

        # Step 3: FAST LAYER — Discord (short announcement)
        DISCORD_POST=$(llm_fast "Write a short Discord announcement (under 500 chars) for this update: $(echo "$FORMATTED" | head -c 400)" "product-discord")

        if [ -n "$DISCORD_POST" ]; then
            mkdir -p "$QUEUES_DIR/discord/pending"
            DISCORD_FILE="$QUEUES_DIR/discord/pending/discord-update-$DATE_TAG-$SLUG.md"
            echo "$DISCORD_POST" > "$DISCORD_FILE"
            log "PRODUCED [discord]: $DISCORD_FILE"
        fi

        # Step 4: FAST LAYER — LinkedIn (professional adapt)
        LI_POST=$(llm_fast "Adapt this product update for LinkedIn (professional tone, under 2000 chars, end with engagement question): $(echo "$FORMATTED" | head -c 600)" "product-linkedin")

        if [ -n "$LI_POST" ]; then
            mkdir -p "$QUEUES_DIR/linkedin/pending"
            LI_FILE="$QUEUES_DIR/linkedin/pending/linkedin-update-$DATE_TAG-$SLUG.md"
            echo "$LI_POST" > "$LI_FILE"
            log "PRODUCED [linkedin]: $LI_FILE"
        fi

        # Step 5: FAST LAYER — X/Twitter (280 chars)
        X_POST=$(llm_fast "Write a tweet (max 280 chars) about this product update: $(echo "$FORMATTED" | head -c 300)" "product-x")

        if [ -n "$X_POST" ]; then
            mkdir -p "$QUEUES_DIR/x/pending"
            X_FILE="$QUEUES_DIR/x/pending/x-update-$DATE_TAG-$SLUG.md"
            echo "$X_POST" > "$X_FILE"
            log "PRODUCED [x]: $X_FILE"
        fi

        ITEM_ELAPSED=$(timer_elapsed_ms "$ITEM_START")
        echo "$FILE" >> "$PROCESSED_LOG"
        TOTAL_PROCESSED=$((TOTAL_PROCESSED + 1))
        log "COMPLETE: $FILENAME → 5 outputs in ${ITEM_ELAPSED}ms"

    done < <(find "$SOURCE_DIR" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" \) -print0 2>/dev/null)
done

PIPELINE_ELAPSED=$(timer_elapsed_ms "$PIPELINE_START")

log "=== Product Update Agent Complete ==="
log "Processed: $TOTAL_PROCESSED in ${PIPELINE_ELAPSED}ms"

echo ""
echo "━━━ PRODUCT UPDATE AGENT SUMMARY ━━━"
echo "Processed: $TOTAL_PROCESSED"
echo "Time:      ${PIPELINE_ELAPSED}ms"
echo "Log:       $LOG_FILE"
