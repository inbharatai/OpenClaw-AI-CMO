#!/bin/bash
# product-update-agent.sh — Process product notes into structured updates and multi-channel content
# Usage: ./product-update-agent.sh [--dry-run]
# Reads: MarketingToolData/product-updates/, source-notes/
# Writes: Formatted updates + website/discord/social queue items

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
MARKETING_DIR="$WORKSPACE_ROOT/MarketingToolData"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/product-update-agent.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_TAG=$(date '+%Y-%m-%d')
OLLAMA_URL="http://127.0.0.1:11434"

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

PROCESSED_LOG="$WORKSPACE_ROOT/OpenClawData/logs/product-updates-processed.log"
touch "$PROCESSED_LOG"

TOTAL_PROCESSED=0

# Process product-updates folder
for SOURCE_DIR in "$MARKETING_DIR/product-updates" "$MARKETING_DIR/source-notes"; do
    [ -d "$SOURCE_DIR" ] || continue

    while IFS= read -r -d '' FILE; do
        FILENAME=$(basename "$FILE")
        [[ "$FILENAME" == .* ]] && continue
        [[ "$FILENAME" == *.meta.json ]] && continue
        [[ "$FILENAME" == *-formatted.md ]] && continue

        if grep -qF "$FILE" "$PROCESSED_LOG" 2>/dev/null; then
            continue
        fi

        CONTENT=$(cat "$FILE" 2>/dev/null)
        [ -z "$CONTENT" ] && continue

        # Check if this looks like a product update
        if ! echo "$CONTENT" | grep -qiE "release|ship|launch|feature|fix|update|version|improve|patch|build"; then
            continue
        fi

        log "PROCESSING PRODUCT UPDATE: $FILENAME"

        if [ "$DRY_RUN" = true ]; then
            log "[DRY RUN] Would process: $FILENAME"
            echo "$FILE" >> "$PROCESSED_LOG"
            continue
        fi

        SLUG=$(echo "$FILENAME" | sed 's/\.md$//' | sed 's/\.txt$//' | tr ' ' '-' | head -c 40)

        # Step 1: Format the product update
        FORMATTED=$("$SCRIPTS_DIR/skill-runner.sh" product-update-writer \
            "Format this raw product update into structured content: $CONTENT" \
            "qwen3:8b" 2>/dev/null | tail -n +5)

        if [ -z "$FORMATTED" ]; then
            log "WARNING: Empty formatted output for $FILENAME"
            continue
        fi

        # Save formatted version
        FORMATTED_FILE="$MARKETING_DIR/product-updates/$SLUG-formatted.md"
        echo "$FORMATTED" > "$FORMATTED_FILE"

        # Step 2: Create website update post
        WEBSITE_POST=$("$SCRIPTS_DIR/skill-runner.sh" website-update-writer \
            "Create a website /updates post from this product update: $FORMATTED" \
            "qwen3:8b" 2>/dev/null | tail -n +5)

        if [ -n "$WEBSITE_POST" ]; then
            WEBSITE_FILE="$MARKETING_DIR/website-posts/update-$DATE_TAG-$SLUG.md"
            echo "$WEBSITE_POST" > "$WEBSITE_FILE"
            cp "$WEBSITE_FILE" "$QUEUES_DIR/website/pending/"
            log "PRODUCED [website]: $WEBSITE_FILE"
        fi

        # Step 3: Create Discord announcement
        DISCORD_POST=$("$SCRIPTS_DIR/skill-runner.sh" discord-announcement-writer \
            "Create a Discord announcement for this product update: $(echo "$FORMATTED" | head -c 400)" \
            "qwen3:8b" 2>/dev/null | tail -n +5)

        if [ -n "$DISCORD_POST" ]; then
            DISCORD_FILE="$QUEUES_DIR/discord/pending/discord-update-$DATE_TAG-$SLUG.md"
            echo "$DISCORD_POST" > "$DISCORD_FILE"
            log "PRODUCED [discord]: $DISCORD_FILE"
        fi

        # Step 4: Create LinkedIn post (BLOCKED — linkedin disabled by policy)
        # LI_POST generation skipped
        log "SKIP [linkedin]: blocked by policy"

        # Step 5: Create X post
        X_POST=$("$SCRIPTS_DIR/skill-runner.sh" channel-adapter \
            "Adapt this product update for X/Twitter (max 280 chars, sharp and direct): $(echo "$FORMATTED" | head -c 400)" \
            "qwen3:8b" 2>/dev/null | tail -n +5)

        if [ -n "$X_POST" ]; then
            X_FILE="$QUEUES_DIR/x/pending/x-update-$DATE_TAG-$SLUG.md"
            echo "$X_POST" > "$X_FILE"
            log "PRODUCED [x]: $X_FILE"
        fi

        echo "$FILE" >> "$PROCESSED_LOG"
        TOTAL_PROCESSED=$((TOTAL_PROCESSED + 1))
        log "COMPLETE: $FILENAME → website + discord + linkedin + x"

    done < <(find "$SOURCE_DIR" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" \) -print0 2>/dev/null)
done

log "=== Product Update Agent Complete ==="
log "Product updates processed: $TOTAL_PROCESSED"

echo ""
echo "━━━ PRODUCT UPDATE AGENT SUMMARY ━━━"
echo "Processed: $TOTAL_PROCESSED"
echo "Log: $LOG_FILE"
