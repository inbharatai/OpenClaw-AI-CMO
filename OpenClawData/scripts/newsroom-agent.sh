#!/bin/bash
# newsroom-agent.sh — Process AI news sources into summarized, publishable content
# Usage: ./newsroom-agent.sh [--dry-run]
# Reads: MarketingToolData/source-links/ for news URLs and articles
# Writes: MarketingToolData/ai-news/ (formatted summaries)
#         OpenClawData/queues/website/pending/ (for approval)
#         OpenClawData/queues/discord/pending/ (news announcements)

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
MARKETING_DIR="$WORKSPACE_ROOT/MarketingToolData"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/newsroom-agent.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_TAG=$(date '+%Y-%m-%d')
OLLAMA_URL="http://127.0.0.1:11434"

DRY_RUN=false
[ "$1" = "--dry-run" ] && DRY_RUN=true

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

log "=== Newsroom Agent Started ==="

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    log "ERROR: Ollama is not running"
    exit 1
fi

PROCESSED_LOG="$WORKSPACE_ROOT/OpenClawData/logs/newsroom-processed.log"
touch "$PROCESSED_LOG"

TOTAL_PROCESSED=0
TOTAL_SKIPPED=0

SOURCE_DIR="$MARKETING_DIR/source-links"

# Process all unprocessed news source files
while IFS= read -r -d '' FILE; do
    FILENAME=$(basename "$FILE")
    [[ "$FILENAME" == .* ]] && continue
    [[ "$FILENAME" == *.meta.json ]] && continue

    # Skip already processed
    if grep -qF "$FILE" "$PROCESSED_LOG" 2>/dev/null; then
        continue
    fi

    CONTENT=$(cat "$FILE" 2>/dev/null)
    [ -z "$CONTENT" ] && continue

    log "PROCESSING NEWS: $FILENAME"

    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would process: $FILENAME"
        echo "$FILE" >> "$PROCESSED_LOG"
        continue
    fi

    # Generate AI news summary
    SLUG=$(echo "$FILENAME" | sed 's/\.md$//' | sed 's/\.txt$//' | tr ' ' '-' | head -c 40)

    NEWS_SUMMARY=$("$SCRIPTS_DIR/skill-runner.sh" ai-news-summarizer \
        "Summarize this AI industry news for our website /news section and add our builder perspective commentary. Source: $CONTENT" \
        "qwen3:8b" 2>/dev/null | tail -n +5)

    if [ -z "$NEWS_SUMMARY" ]; then
        log "WARNING: Empty summary for $FILENAME"
        TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
        continue
    fi

    # Write news summary
    OUTPUT_FILE="$MARKETING_DIR/ai-news/news-$DATE_TAG-$SLUG.md"
    echo "$NEWS_SUMMARY" > "$OUTPUT_FILE"

    # Queue for website
    cp "$OUTPUT_FILE" "$QUEUES_DIR/website/pending/"

    # Also generate a Discord variant
    DISCORD_OUT=$("$SCRIPTS_DIR/skill-runner.sh" discord-announcement-writer \
        "Create a brief Discord announcement about this AI news: $(echo "$NEWS_SUMMARY" | head -c 400)" \
        "qwen3:8b" 2>/dev/null | tail -n +5)

    if [ -n "$DISCORD_OUT" ]; then
        DISCORD_FILE="$QUEUES_DIR/discord/pending/discord-news-$DATE_TAG-$SLUG.md"
        echo "$DISCORD_OUT" > "$DISCORD_FILE"
        log "PRODUCED [discord news]: $DISCORD_FILE"
    fi

    # Generate LinkedIn variant for news
    LINKEDIN_NEWS=$("$SCRIPTS_DIR/skill-runner.sh" channel-adapter \
        "Adapt this AI news summary for LinkedIn (max 3000 chars, professional tone). Content: $(echo "$NEWS_SUMMARY" | head -c 800)" \
        "qwen3:8b" 2>/dev/null | tail -n +5)

    if [ -n "$LINKEDIN_NEWS" ]; then
        LI_FILE="$QUEUES_DIR/linkedin/pending/linkedin-news-$DATE_TAG-$SLUG.md"
        echo "$LINKEDIN_NEWS" > "$LI_FILE"
        log "PRODUCED [linkedin news]: $LI_FILE"
    fi

    echo "$FILE" >> "$PROCESSED_LOG"
    TOTAL_PROCESSED=$((TOTAL_PROCESSED + 1))
    log "SUMMARIZED: $OUTPUT_FILE"

done < <(find "$SOURCE_DIR" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" -o -name "*.url" \) -print0 2>/dev/null)

log "=== Newsroom Agent Complete ==="
log "Processed: $TOTAL_PROCESSED | Skipped: $TOTAL_SKIPPED"

echo ""
echo "━━━ NEWSROOM SUMMARY ━━━"
echo "News processed: $TOTAL_PROCESSED"
echo "Skipped:        $TOTAL_SKIPPED"
echo "Log: $LOG_FILE"
