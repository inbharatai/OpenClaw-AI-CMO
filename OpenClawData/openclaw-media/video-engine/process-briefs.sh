#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# process-briefs.sh — OpenClaw Video Engine Batch Processor
#
# Scans content queues and pipeline outputs for items with video_brief or
# shorts_description, generates videos for each, and saves them to the
# assets/videos/ directory.
#
# Usage:
#   ./process-briefs.sh                   # process all pending briefs
#   ./process-briefs.sh --dry-run         # show what would be processed
#   ./process-briefs.sh --limit 5         # process at most 5 items
#   ./process-briefs.sh --source queues   # only scan queues/
#   ./process-briefs.sh --source pipeline # only scan pipeline output/
#
# Environment:
#   OPENCLAW_ROOT — override project root
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_ROOT="${OPENCLAW_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
GENERATE_SCRIPT="$SCRIPT_DIR/generate-video.sh"
ASSETS_DIR="$OPENCLAW_ROOT/OpenClawData/openclaw-media/assets/videos"
LOG_DIR="$OPENCLAW_ROOT/OpenClawData/logs"
LOG_FILE="$LOG_DIR/video-engine.log"

# Directories to scan for content packages
QUEUE_DIRS=(
    "$OPENCLAW_ROOT/OpenClawData/queues/shorts/pending"
    "$OPENCLAW_ROOT/OpenClawData/queues/instagram/pending"
    "$OPENCLAW_ROOT/OpenClawData/queues/linkedin/pending"
    "$OPENCLAW_ROOT/OpenClawData/queues/x/pending"
    "$OPENCLAW_ROOT/OpenClawData/queues/discord/pending"
    "$OPENCLAW_ROOT/OpenClawData/queues/facebook/pending"
)

PIPELINE_DIRS=(
    "$OPENCLAW_ROOT/OpenClawData/openclaw-media/native-pipeline/output"
    "$OPENCLAW_ROOT/OpenClawData/openclaw-media/amplify-pipeline/output"
)

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [batch-processor] $1"
    echo -e "${BLUE}${msg}${NC}" >&2
    mkdir -p "$LOG_DIR"
    echo "$msg" >> "$LOG_FILE"
}

# ── Parse Arguments ──────────────────────────────────────────────────────────
DRY_RUN=false
LIMIT=0          # 0 = unlimited
SOURCE="all"     # all | queues | pipeline

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)   DRY_RUN=true; shift ;;
        --limit)     LIMIT="$2"; shift 2 ;;
        --source)    SOURCE="$2"; shift 2 ;;
        --help)
            echo "Usage: process-briefs.sh [--dry-run] [--limit N] [--source queues|pipeline|all]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# ── Validate ─────────────────────────────────────────────────────────────────
if [[ ! -x "$GENERATE_SCRIPT" ]]; then
    echo -e "${RED}ERROR: generate-video.sh not found or not executable at $GENERATE_SCRIPT${NC}" >&2
    exit 1
fi

mkdir -p "$ASSETS_DIR"

# ── Collect candidate JSON files ─────────────────────────────────────────────
CANDIDATES=()

collect_from_dirs() {
    local -n dirs=$1
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' f; do
                CANDIDATES+=("$f")
            done < <(find "$dir" -maxdepth 1 -name '*.json' -print0 2>/dev/null)
        fi
    done
}

case "$SOURCE" in
    queues)   collect_from_dirs QUEUE_DIRS ;;
    pipeline) collect_from_dirs PIPELINE_DIRS ;;
    all)
        collect_from_dirs QUEUE_DIRS
        collect_from_dirs PIPELINE_DIRS
        ;;
    *)
        echo "Invalid --source value: $SOURCE (expected: queues, pipeline, all)" >&2
        exit 1
        ;;
esac

log "Found ${#CANDIDATES[@]} JSON files to scan"

# ── Filter: only files with video_brief or shorts_description ────────────────
has_video_content() {
    local file="$1"
    export VID_CHECK_FILE="$file"
    python3 << 'VCHKEOF' 2>/dev/null
import json, sys, os
with open(os.environ['VID_CHECK_FILE'], 'r') as f:
    d = json.load(f)
vb = d.get('video_brief')
sd = d.get('platform_content', {}).get('shorts_description') or d.get('shorts_description')
if vb or sd:
    sys.exit(0)
sys.exit(1)
VCHKEOF
}

get_content_id() {
    local file="$1"
    export VID_ID_FILE="$file"
    python3 << 'VIDEOF' 2>/dev/null || echo "unknown"
import json, os
with open(os.environ['VID_ID_FILE'], 'r') as f:
    d = json.load(f)
print(d.get('content_id', 'unknown'))
VIDEOF
}

# ── Process candidates ───────────────────────────────────────────────────────
PROCESSED=0
SUCCEEDED=0
FAILED=0
SKIPPED=0

# Track already-processed content IDs to avoid duplicates across queues
declare -A SEEN_IDS

echo ""
echo -e "${CYAN}OpenClaw Video Engine — Batch Processor${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

for json_file in "${CANDIDATES[@]}"; do
    # Check limit
    if [[ $LIMIT -gt 0 && $PROCESSED -ge $LIMIT ]]; then
        log "Reached processing limit ($LIMIT)"
        break
    fi

    # Check if file has video content
    if ! has_video_content "$json_file"; then
        continue
    fi

    # Deduplicate by content_id
    CONTENT_ID="$(get_content_id "$json_file")"
    if [[ -n "${SEEN_IDS[$CONTENT_ID]+x}" ]]; then
        continue
    fi
    SEEN_IDS["$CONTENT_ID"]=1

    BASENAME="$(basename "$json_file" .json)"
    OUTPUT_FILE="$ASSETS_DIR/${BASENAME}.mp4"

    # Skip if video already exists
    if [[ -f "$OUTPUT_FILE" ]]; then
        echo -e "  ${YELLOW}SKIP${NC}  $BASENAME (video already exists)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    PROCESSED=$((PROCESSED + 1))

    if $DRY_RUN; then
        echo -e "  ${CYAN}WOULD${NC} process: $BASENAME"
        echo -e "         Source: $json_file"
        echo -e "         Output: $OUTPUT_FILE"
        continue
    fi

    echo -e "  ${BLUE}[${PROCESSED}]${NC} Processing: $BASENAME"
    log "Processing: $json_file → $OUTPUT_FILE"

    if "$GENERATE_SCRIPT" --file "$json_file" --output "$OUTPUT_FILE" 2>&1 | while IFS= read -r line; do
        echo "      $line"
    done; then
        echo -e "  ${GREEN}DONE${NC}  $OUTPUT_FILE"
        SUCCEEDED=$((SUCCEEDED + 1))
    else
        echo -e "  ${RED}FAIL${NC}  $BASENAME"
        FAILED=$((FAILED + 1))
    fi

    echo ""
done

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Summary${NC}"
echo "───────────────────────────────"
if $DRY_RUN; then
    echo -e "  Would process: ${PROCESSED}"
else
    echo -e "  Processed:  ${PROCESSED}"
    echo -e "  Succeeded:  ${GREEN}${SUCCEEDED}${NC}"
    echo -e "  Failed:     ${RED}${FAILED}${NC}"
fi
echo -e "  Skipped:    ${YELLOW}${SKIPPED}${NC} (already exist)"
echo -e "  Output dir: $ASSETS_DIR"
echo ""

log "Batch complete: $SUCCEEDED succeeded, $FAILED failed, $SKIPPED skipped"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
exit 0
