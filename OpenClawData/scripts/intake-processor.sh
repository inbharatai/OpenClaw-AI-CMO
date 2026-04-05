#!/bin/bash
# intake-processor.sh — Scans source folders for new/unprocessed files, classifies them, and stages for content production
# Usage: ./intake-processor.sh [--dry-run]
# Reads: MarketingToolData/source-notes/, source-links/, product-updates/, screenshots/
# Writes: Adds YAML frontmatter classification to files, copies to appropriate staging folders
# Logs: OpenClawData/logs/intake-processor.log

# Ignore SIGPIPE — prevents exit code 141 from head|grep patterns on macOS
trap '' PIPE

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/intake-processor.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_TAG=$(date '+%Y-%m-%d')
OLLAMA_URL="http://127.0.0.1:11434"
DRY_RUN=false

if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    echo "[DRY RUN] No files will be modified"
fi

# Source folders to scan
# Includes memory/approval/ — where gateway agent drafts and calendar content land
SOURCE_DIRS=(
    "$WORKSPACE_ROOT/MarketingToolData/source-notes"
    "$WORKSPACE_ROOT/MarketingToolData/source-links"
    "$WORKSPACE_ROOT/MarketingToolData/product-updates"
    "$WORKSPACE_ROOT/memory/approval"
)

PROCESSED_LOG="$WORKSPACE_ROOT/OpenClawData/logs/intake-processed-files.log"
touch "$PROCESSED_LOG"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

log "=== Intake Processor Started ==="

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    log "ERROR: Ollama is not running at $OLLAMA_URL"
    exit 1
fi

TOTAL_NEW=0
TOTAL_CLASSIFIED=0
TOTAL_SKIPPED=0

for DIR in "${SOURCE_DIRS[@]}"; do
    if [ ! -d "$DIR" ]; then
        log "SKIP: Directory not found: $DIR"
        continue
    fi

    # Find markdown and text files that haven't been processed
    while IFS= read -r -d '' FILE; do
        FILENAME=$(basename "$FILE")
        FILEPATH="$FILE"

        # Skip hidden files and backups
        [[ "$FILENAME" == .* ]] && continue
        [[ "$FILENAME" == *.backup-* ]] && continue

        # Skip already processed files (check if file path is in processed log)
        if grep -qF "$FILEPATH" "$PROCESSED_LOG" 2>/dev/null; then
            continue
        fi

        # Skip files that already have frontmatter classification
        if grep -q "^cmo-classified:" <(head -5 "$FILE") 2>/dev/null; then
            continue
        fi

        TOTAL_NEW=$((TOTAL_NEW + 1))

        # Determine source type from folder
        case "$DIR" in
            *source-notes*) SOURCE_TYPE="note" ;;
            *source-links*) SOURCE_TYPE="link" ;;
            *product-updates*) SOURCE_TYPE="product-update" ;;
            *) SOURCE_TYPE="unknown" ;;
        esac

        # Read file content (first 500 chars for classification)
        CONTENT_PREVIEW=$(head -c 500 "$FILE" 2>/dev/null)

        if [ -z "$CONTENT_PREVIEW" ]; then
            log "SKIP: Empty file: $FILEPATH"
            TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
            continue
        fi

        log "CLASSIFYING: $FILEPATH (source: $SOURCE_TYPE)"

        if [ "$DRY_RUN" = true ]; then
            log "[DRY RUN] Would classify: $FILEPATH"
            continue
        fi

        # Call content-classifier skill via skill-runner
        CLASSIFICATION=$("$SCRIPTS_DIR/skill-runner.sh" content-classifier \
            "Classify this content. Source type: $SOURCE_TYPE. Content: $CONTENT_PREVIEW" \
            "qwen3:8b" 2>/dev/null | tail -n +5)

        if [ -z "$CLASSIFICATION" ]; then
            log "WARNING: Classification returned empty for $FILEPATH, using defaults"
            CLASSIFICATION="type: $SOURCE_TYPE
priority: medium
channels: website
approval_level: L2"
        fi

        # Extract classification fields (parse LLM output for key fields)
        # We look for type, priority, channels in the response
        CONTENT_TYPE=$(echo "$CLASSIFICATION" | grep -i "type:" | head -1 | sed 's/.*type:\s*//i' | tr -d '[:space:]' | head -c 30)
        PRIORITY=$(echo "$CLASSIFICATION" | grep -i "priority:" | head -1 | sed 's/.*priority:\s*//i' | tr -d '[:space:]' | head -c 10)
        CHANNELS=$(echo "$CLASSIFICATION" | grep -i "channels:" | head -1 | sed 's/.*channels:\s*//i' | head -c 100)

        # Defaults if parsing failed
        [ -z "$CONTENT_TYPE" ] && CONTENT_TYPE="$SOURCE_TYPE"
        [ -z "$PRIORITY" ] && PRIORITY="medium"
        [ -z "$CHANNELS" ] && CHANNELS="website"

        # Write classification metadata file alongside the source
        META_FILE="${FILE%.md}.meta.json"
        cat > "$META_FILE" <<EOF
{
  "cmo_classified": true,
  "classified_date": "$DATE_TAG",
  "source_file": "$FILEPATH",
  "source_type": "$SOURCE_TYPE",
  "content_type": "$CONTENT_TYPE",
  "priority": "$PRIORITY",
  "suggested_channels": "$CHANNELS",
  "status": "classified",
  "approval_level": "pending_scoring"
}
EOF

        # Record as processed
        echo "$FILEPATH" >> "$PROCESSED_LOG"
        TOTAL_CLASSIFIED=$((TOTAL_CLASSIFIED + 1))
        log "CLASSIFIED: $FILEPATH → type=$CONTENT_TYPE, priority=$PRIORITY, channels=$CHANNELS"

    done < <(find "$DIR" -maxdepth 2 -type f \( -name "*.md" -o -name "*.txt" -o -name "*.url" \) -print0 2>/dev/null)
done

log "=== Intake Processor Complete ==="
log "New files found: $TOTAL_NEW | Classified: $TOTAL_CLASSIFIED | Skipped: $TOTAL_SKIPPED"

# Write summary to report
SUMMARY_FILE="$WORKSPACE_ROOT/OpenClawData/logs/intake-summary-$DATE_TAG.log"
cat >> "$SUMMARY_FILE" <<EOF
[$TIMESTAMP] Intake run: found=$TOTAL_NEW classified=$TOTAL_CLASSIFIED skipped=$TOTAL_SKIPPED
EOF

echo ""
echo "━━━ INTAKE SUMMARY ━━━"
echo "New files:  $TOTAL_NEW"
echo "Classified: $TOTAL_CLASSIFIED"
echo "Skipped:    $TOTAL_SKIPPED"
echo "Log: $LOG_FILE"
