#!/bin/bash
# ============================================================
# newsroom-agent.sh — Process AI news into multi-channel content
# OPTIMIZED: THINK for summary, FAST for channel variants
# Before: 3 × 8B calls = ~120s per item
# After:  1 THINK + 2 FAST = ~40s per item (3x faster)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/date-context.sh"
source "$SCRIPT_DIR/layer-router.sh"

DATA_DIR="$WORKSPACE_ROOT/data"
QUEUES_DIR="$WORKSPACE_ROOT/queues"
LOG_FILE="$WORKSPACE_ROOT/logs/newsroom-agent.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

DRY_RUN=false
[ "$1" = "--dry-run" ] && DRY_RUN=true

log() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
    echo "$1"
}

log "=== Newsroom Agent Started ==="

if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    log "ERROR: Ollama is not running"
    exit 1
fi

PROCESSED_LOG="$WORKSPACE_ROOT/logs/newsroom-processed.log"
touch "$PROCESSED_LOG"

TOTAL_PROCESSED=0
TOTAL_SKIPPED=0
PIPELINE_START=$(timer_start)

SOURCE_DIR="$DATA_DIR/source-links"
[ -d "$SOURCE_DIR" ] || { log "No source-links directory"; exit 0; }

while IFS= read -r -d '' FILE; do
    FILENAME=$(basename "$FILE")
    [[ "$FILENAME" == .* ]] && continue
    [[ "$FILENAME" == *.meta.json ]] && continue

    grep -qF "$FILE" "$PROCESSED_LOG" 2>/dev/null && continue

    CONTENT=$(cat "$FILE" 2>/dev/null)
    [ -z "$CONTENT" ] && continue

    log "PROCESSING NEWS: $FILENAME"

    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would process: $FILENAME"
        echo "$FILE" >> "$PROCESSED_LOG"
        continue
    fi

    SLUG=$(echo "$FILENAME" | sed 's/\.md$//' | sed 's/\.txt$//' | tr ' ' '-' | head -c 40)
    ITEM_START=$(timer_start)

    # Step 1: THINKING LAYER — Deep news summary with analysis
    NEWS_SUMMARY=$(llm_think "Summarize this AI industry news for our website /news section. Include: key facts, why it matters, and our builder perspective commentary. Source: $CONTENT" "newsroom-summary")

    if [ -z "$NEWS_SUMMARY" ]; then
        log "WARNING: Empty summary for $FILENAME"
        TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
        continue
    fi

    OUTPUT_FILE="$DATA_DIR/ai-news/news-$DATE_TAG-$SLUG.md"
    echo "$NEWS_SUMMARY" > "$OUTPUT_FILE"
    mkdir -p "$QUEUES_DIR/website/pending"
    cp "$OUTPUT_FILE" "$QUEUES_DIR/website/pending/"

    # Step 2: FAST LAYER — Discord variant
    DISCORD_OUT=$(llm_fast "Write a short Discord announcement (under 400 chars) about this AI news: $(echo "$NEWS_SUMMARY" | head -c 400)" "newsroom-discord")

    if [ -n "$DISCORD_OUT" ]; then
        mkdir -p "$QUEUES_DIR/discord/pending"
        echo "$DISCORD_OUT" > "$QUEUES_DIR/discord/pending/discord-news-$DATE_TAG-$SLUG.md"
        log "PRODUCED [discord news]"
    fi

    # Step 3: FAST LAYER — LinkedIn variant
    LI_OUT=$(llm_fast "Adapt this AI news for LinkedIn (professional tone, 1500 chars max, end with engagement question): $(echo "$NEWS_SUMMARY" | head -c 600)" "newsroom-linkedin")

    if [ -n "$LI_OUT" ]; then
        mkdir -p "$QUEUES_DIR/linkedin/pending"
        echo "$LI_OUT" > "$QUEUES_DIR/linkedin/pending/linkedin-news-$DATE_TAG-$SLUG.md"
        log "PRODUCED [linkedin news]"
    fi

    ITEM_ELAPSED=$(timer_elapsed_ms "$ITEM_START")
    echo "$FILE" >> "$PROCESSED_LOG"
    TOTAL_PROCESSED=$((TOTAL_PROCESSED + 1))
    log "SUMMARIZED: $OUTPUT_FILE in ${ITEM_ELAPSED}ms"

done < <(find "$SOURCE_DIR" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" -o -name "*.url" \) -print0 2>/dev/null)

PIPELINE_ELAPSED=$(timer_elapsed_ms "$PIPELINE_START")

log "=== Newsroom Agent Complete ==="
log "Processed: $TOTAL_PROCESSED | Skipped: $TOTAL_SKIPPED | Time: ${PIPELINE_ELAPSED}ms"

echo ""
echo "━━━ NEWSROOM SUMMARY ━━━"
echo "Processed: $TOTAL_PROCESSED"
echo "Skipped:   $TOTAL_SKIPPED"
echo "Time:      ${PIPELINE_ELAPSED}ms"
echo "Log:       $LOG_FILE"
