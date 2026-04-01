#!/bin/bash
# process-briefs.sh -- Batch Image Generation from Content Package Briefs
# Scans all content packages in queues for non-null image_brief fields
# and generates images for each.
#
# Usage:
#   ./process-briefs.sh                   # Process all queues
#   ./process-briefs.sh --queue linkedin   # Process specific queue
#   ./process-briefs.sh --dry-run          # Show what would be generated
#   ./process-briefs.sh --force            # Regenerate even if image exists

set -uo pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
ENGINE_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/image-engine"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
ASSETS_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/assets/images"
NATIVE_OUTPUT="$WORKSPACE_ROOT/OpenClawData/openclaw-media/native-pipeline/output"
AMPLIFY_OUTPUT="$WORKSPACE_ROOT/OpenClawData/openclaw-media/amplify-pipeline/output"
BOT_ROOT="$WORKSPACE_ROOT/OpenClawData/inbharat-bot"
DATE=$(date '+%Y-%m-%d')

# Source logger
if [ -f "$BOT_ROOT/logging/bot-logger.sh" ]; then
  source "$BOT_ROOT/logging/bot-logger.sh"
else
  bot_log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$2] [image-batch] $3"; }
fi

# Parse arguments
TARGET_QUEUE=""
DRY_RUN=false
FORCE=false
BACKEND=""

while [ $# -gt 0 ]; do
  case "$1" in
    --queue)    TARGET_QUEUE="$2"; shift ;;
    --dry-run)  DRY_RUN=true ;;
    --force)    FORCE=true ;;
    --backend)  BACKEND="$2"; shift ;;
    -h|--help)
      echo "Usage: process-briefs.sh [--queue <name>] [--dry-run] [--force] [--backend dalle|placeholder]"
      exit 0
      ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
  shift
done

mkdir -p "$ASSETS_DIR"

bot_log "image-batch" "info" "=== Batch Image Generation Started ==="

# Counters
TOTAL=0
GENERATED=0
SKIPPED=0
FAILED=0

# ── Collect all content package JSON files ──
PACKAGE_FILES=()

# From queues (pending + approved)
if [ -n "$TARGET_QUEUE" ]; then
  QUEUE_DIRS=("$QUEUES_DIR/$TARGET_QUEUE")
else
  QUEUE_DIRS=("$QUEUES_DIR"/*)
fi

for QDIR in "${QUEUE_DIRS[@]}"; do
  [ ! -d "$QDIR" ] && continue
  for SUBDIR in pending approved; do
    SCAN_DIR="$QDIR/$SUBDIR"
    [ ! -d "$SCAN_DIR" ] && continue
    for F in "$SCAN_DIR"/*.json; do
      [ ! -f "$F" ] && continue
      PACKAGE_FILES+=("$F")
    done
  done
done

# Also scan pipeline output directories
for OUTPUT_DIR in "$NATIVE_OUTPUT" "$AMPLIFY_OUTPUT"; do
  [ ! -d "$OUTPUT_DIR" ] && continue
  for F in "$OUTPUT_DIR"/*.json; do
    [ ! -f "$F" ] && continue
    PACKAGE_FILES+=("$F")
  done
done

if [ ${#PACKAGE_FILES[@]} -eq 0 ]; then
  bot_log "image-batch" "info" "No content packages found in queues or pipeline output"
  echo "No content packages found to process."
  exit 0
fi

bot_log "image-batch" "info" "Found ${#PACKAGE_FILES[@]} content packages to scan"

# ── Process each package ──
for PACKAGE_FILE in "${PACKAGE_FILES[@]}"; do
  # Extract image_brief and content_id from JSON
  export IMG_PKG_FILE="$PACKAGE_FILE"
  BRIEF=$(python3 << 'BEXTEOF' 2>/dev/null
import json, os
try:
    with open(os.environ['IMG_PKG_FILE']) as f:
        data = json.load(f)
    briefs = []
    ib = data.get('image_brief')
    if ib and ib != 'null' and str(ib).strip():
        briefs.append(('image', str(ib)))
    cb = data.get('cover_brief')
    if cb and cb != 'null' and str(cb).strip():
        briefs.append(('cover', str(cb)))
    cid = data.get('content_id', 'unknown')
    for btype, btext in briefs:
        print(f'{cid}|{btype}|{btext}')
except Exception:
    pass
BEXTEOF
)

  [ -z "$BRIEF" ] && continue

  while IFS='|' read -r CONTENT_ID BRIEF_TYPE BRIEF_TEXT; do
    [ -z "$BRIEF_TEXT" ] && continue
    TOTAL=$((TOTAL + 1))

    # Determine output filename
    SLUG=$(echo "$CONTENT_ID" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    OUTPUT_FILE="$ASSETS_DIR/${SLUG}-${BRIEF_TYPE}.png"

    # Skip if already exists (unless --force)
    if [ -f "$OUTPUT_FILE" ] && [ "$FORCE" = false ]; then
      bot_log "image-batch" "info" "SKIP (exists): $OUTPUT_FILE"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi

    echo ""
    echo "--- Processing: $CONTENT_ID ($BRIEF_TYPE) ---"
    echo "  Brief: ${BRIEF_TEXT:0:100}"
    echo "  Source: $(basename "$PACKAGE_FILE")"
    echo "  Output: $OUTPUT_FILE"

    if [ "$DRY_RUN" = true ]; then
      echo "  [DRY RUN] Would generate image"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi

    # Generate image
    BACKEND_ARG=""
    [ -n "$BACKEND" ] && BACKEND_ARG="--backend $BACKEND"

    GEN_RESULT=$("$ENGINE_DIR/generate-image.sh" \
      --brief "$BRIEF_TEXT" \
      --output "$OUTPUT_FILE" \
      --content-id "$CONTENT_ID" \
      $BACKEND_ARG 2>&1)
    GEN_EXIT=$?

    if [ $GEN_EXIT -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
      GENERATED=$((GENERATED + 1))
      bot_log "image-batch" "info" "Generated: $OUTPUT_FILE"

      # Update the content package with the image path (add image_path field)
      export IMG_PACKAGE_FILE="$PACKAGE_FILE"
      export IMG_BRIEF_TYPE="$BRIEF_TYPE"
      export IMG_OUTPUT_FILE="$OUTPUT_FILE"
      python3 << 'IMGEOF' 2>/dev/null
import json, os, sys
try:
    pkg = os.environ['IMG_PACKAGE_FILE']
    brief_type = os.environ['IMG_BRIEF_TYPE']
    output = os.environ['IMG_OUTPUT_FILE']
    with open(pkg, 'r') as f:
        data = json.load(f)
    key = 'image_path' if brief_type == 'image' else 'cover_path'
    data[key] = output
    with open(pkg, 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print(f'Warning: Could not update package with image path: {e}', file=sys.stderr)
IMGEOF

    else
      FAILED=$((FAILED + 1))
      bot_log "image-batch" "warn" "Failed to generate: $OUTPUT_FILE"
      echo "  FAILED: $GEN_RESULT" >&2
    fi

  done <<< "$BRIEF"
done

# ── Summary ──
echo ""
echo "=========================================="
echo "  Batch Image Generation Summary"
echo "=========================================="
echo "  Total briefs found: $TOTAL"
echo "  Generated:          $GENERATED"
echo "  Skipped (exists):   $SKIPPED"
echo "  Failed:             $FAILED"
echo "  Output directory:   $ASSETS_DIR"
echo "=========================================="

bot_log "image-batch" "info" "Batch complete: $GENERATED generated, $SKIPPED skipped, $FAILED failed (of $TOTAL)"

# Log results
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/openclaw-media/analytics/image-gen-${DATE}.jsonl"
mkdir -p "$(dirname "$LOG_FILE")"
export IMG_BATCH_DATE="$DATE"
export IMG_BATCH_TOTAL="$TOTAL"
export IMG_BATCH_GENERATED="$GENERATED"
export IMG_BATCH_SKIPPED="$SKIPPED"
export IMG_BATCH_FAILED="$FAILED"
python3 << 'BLOGEOF' >> "$LOG_FILE" 2>/dev/null
import json, os
from datetime import datetime
entry = {
    'date': os.environ['IMG_BATCH_DATE'],
    'time': datetime.now().strftime('%H:%M:%S'),
    'type': 'batch-image-gen',
    'total': int(os.environ['IMG_BATCH_TOTAL']),
    'generated': int(os.environ['IMG_BATCH_GENERATED']),
    'skipped': int(os.environ['IMG_BATCH_SKIPPED']),
    'failed': int(os.environ['IMG_BATCH_FAILED']),
}
print(json.dumps(entry))
BLOGEOF

[ $FAILED -gt 0 ] && exit 1
exit 0
