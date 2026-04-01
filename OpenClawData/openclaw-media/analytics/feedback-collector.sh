#!/bin/bash
# feedback-collector.sh — Collects posting feedback for InBharat Bot's learning loop
# Called after content is marked as "posted" in post-manager.sh
# Writes structured JSONL to feedback-to-bot/ for the learning lane to consume
#
# Usage:
#   ./feedback-collector.sh record --file <filename> --platform <platform> [--content-file <path>]
#   ./feedback-collector.sh weekly-summary
#   ./feedback-collector.sh status
#
# Outputs:
#   feedback-to-bot/posted-YYYY-MM-DD.jsonl   — per-post records
#   feedback-to-bot/weekly-summary-YYYY-MM-DD.json — weekly aggregation

set -o pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
MEDIA_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media"
ANALYTICS_DIR="$MEDIA_DIR/analytics"
FEEDBACK_DIR="$ANALYTICS_DIR/feedback-to-bot"
ARCHIVE_DIR="$MEDIA_DIR/publishing/archive"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
DATE=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$FEEDBACK_DIR"

log_feedback() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [feedback-collector] $1"
}

# ── Record a single posted item ──
record_post() {
    local FILE=""
    local PLATFORM=""
    local CONTENT_FILE=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --file) FILE="$2"; shift ;;
            --platform) PLATFORM="$2"; shift ;;
            --content-file) CONTENT_FILE="$2"; shift ;;
            *) ;;
        esac
        shift
    done

    if [ -z "$FILE" ] || [ -z "$PLATFORM" ]; then
        echo "ERROR: --file and --platform are required"
        echo "Usage: feedback-collector.sh record --file <filename> --platform <platform>"
        return 1
    fi

    # Extract metadata from the content file if available
    local CONTENT_ID=""
    local PRODUCT=""
    local BUCKET=""
    local CONTENT_TYPE=""
    local HOOK=""

    # Try to find the content file in archive or posted directories
    if [ -z "$CONTENT_FILE" ]; then
        # Check archive first, then posted queue
        if [ -f "$ARCHIVE_DIR/$FILE" ]; then
            CONTENT_FILE="$ARCHIVE_DIR/$FILE"
        elif [ -f "$QUEUES_DIR/$PLATFORM/posted/$FILE" ]; then
            CONTENT_FILE="$QUEUES_DIR/$PLATFORM/posted/$FILE"
        fi
    fi

    if [ -n "$CONTENT_FILE" ] && [ -f "$CONTENT_FILE" ]; then
        # Extract fields from JSON content
        if [[ "$CONTENT_FILE" == *.json ]]; then
            EXTRACT_RESULT=$(PARSE_FILE="$CONTENT_FILE" python3 -c "
import json, os, sys
try:
    with open(os.environ['PARSE_FILE']) as f:
        data = json.load(f)
    result = {
        'content_id': data.get('content_id', data.get('id', '')),
        'product': data.get('product', data.get('product_name', '')),
        'bucket': data.get('bucket', data.get('content_bucket', data.get('category', ''))),
        'content_type': data.get('type', data.get('content_type', '')),
        'hook': data.get('hook', data.get('title', ''))[:120]
    }
    import json as j
    print(j.dumps(result))
except Exception as e:
    print('{}', file=sys.stderr)
    print('{}')
" 2>/dev/null)
            CONTENT_ID=$(echo "$EXTRACT_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('content_id',''))" 2>/dev/null)
            PRODUCT=$(echo "$EXTRACT_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('product',''))" 2>/dev/null)
            BUCKET=$(echo "$EXTRACT_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('bucket',''))" 2>/dev/null)
            CONTENT_TYPE=$(echo "$EXTRACT_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('content_type',''))" 2>/dev/null)
            HOOK=$(echo "$EXTRACT_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('hook',''))" 2>/dev/null)
        else
            # Extract from markdown frontmatter
            CONTENT_ID=$(grep "^content_id:" "$CONTENT_FILE" 2>/dev/null | head -1 | sed 's/content_id:\s*//' | tr -d '"' | tr -d ' ')
            PRODUCT=$(grep "^product:" "$CONTENT_FILE" 2>/dev/null | head -1 | sed 's/product:\s*//' | tr -d '"')
            BUCKET=$(grep "^bucket:" "$CONTENT_FILE" 2>/dev/null | head -1 | sed 's/bucket:\s*//' | tr -d '"')
            CONTENT_TYPE=$(grep "^type:" "$CONTENT_FILE" 2>/dev/null | head -1 | sed 's/type:\s*//' | tr -d '"' | tr -d ' ')
            HOOK=$(grep "^hook:\|^title:" "$CONTENT_FILE" 2>/dev/null | head -1 | sed 's/^[a-z_]*:\s*//' | tr -d '"' | head -c 120)
        fi
    fi

    # Generate content_id if not found
    if [ -z "$CONTENT_ID" ]; then
        CONTENT_ID="${PLATFORM}-$(echo "$FILE" | sed 's/\.[^.]*$//' | tr ' ' '-')-${DATE}"
    fi

    # Default product/bucket if not found
    [ -z "$PRODUCT" ] && PRODUCT="unknown"
    [ -z "$BUCKET" ] && BUCKET="unknown"
    [ -z "$CONTENT_TYPE" ] && CONTENT_TYPE="unknown"

    # Write structured JSONL entry
    local FEEDBACK_FILE="$FEEDBACK_DIR/posted-${DATE}.jsonl"
    jq -cn \
        --arg date "$DATE" \
        --arg timestamp "$TIMESTAMP" \
        --arg file "$FILE" \
        --arg platform "$PLATFORM" \
        --arg content_id "$CONTENT_ID" \
        --arg product "$PRODUCT" \
        --arg bucket "$BUCKET" \
        --arg content_type "$CONTENT_TYPE" \
        --arg hook "$HOOK" \
        --arg engagement_status "pending" \
        '{
            date: $date,
            timestamp: $timestamp,
            file: $file,
            platform: $platform,
            content_id: $content_id,
            product: $product,
            bucket: $bucket,
            content_type: $content_type,
            hook: $hook,
            posted: true,
            engagement_status: $engagement_status,
            engagement_data: null
        }' >> "$FEEDBACK_FILE" 2>/dev/null

    if [ $? -eq 0 ]; then
        log_feedback "Recorded: $PLATFORM/$FILE (product=$PRODUCT, bucket=$BUCKET, id=$CONTENT_ID)"
    else
        log_feedback "ERROR: Failed to write feedback for $FILE"
        return 1
    fi
}

# ── Generate weekly summary ──
generate_weekly_summary() {
    log_feedback "Generating weekly summary..."

    # Find all posted-*.jsonl files from the past 7 days
    local SUMMARY_FILE="$FEEDBACK_DIR/weekly-summary-${DATE}.json"
    local TEMP_ALL=$(mktemp)
    trap "rm -f '$TEMP_ALL'" RETURN

    # Collect all JSONL entries from last 7 days
    local FOUND_DATA=false
    for i in $(seq 0 6); do
        local CHECK_DATE
        CHECK_DATE=$(date -v-${i}d '+%Y-%m-%d' 2>/dev/null || date -d "-${i} days" '+%Y-%m-%d' 2>/dev/null)
        [ -z "$CHECK_DATE" ] && continue
        local DAY_FILE="$FEEDBACK_DIR/posted-${CHECK_DATE}.jsonl"
        if [ -f "$DAY_FILE" ]; then
            cat "$DAY_FILE" >> "$TEMP_ALL"
            FOUND_DATA=true
        fi
    done

    # Also include post-actions logs for richer data
    for i in $(seq 0 6); do
        local CHECK_DATE
        CHECK_DATE=$(date -v-${i}d '+%Y-%m-%d' 2>/dev/null || date -d "-${i} days" '+%Y-%m-%d' 2>/dev/null)
        [ -z "$CHECK_DATE" ] && continue
        local ACTION_FILE="$ANALYTICS_DIR/post-actions-${CHECK_DATE}.jsonl"
        if [ -f "$ACTION_FILE" ] && [ "$FOUND_DATA" = false ]; then
            # Use action logs as fallback if no feedback entries exist
            while IFS= read -r LINE; do
                local ACTION_TYPE
                ACTION_TYPE=$(echo "$LINE" | jq -r '.action // ""' 2>/dev/null)
                if [ "$ACTION_TYPE" = "posted" ]; then
                    echo "$LINE" >> "$TEMP_ALL"
                    FOUND_DATA=true
                fi
            done < "$ACTION_FILE"
        fi
    done

    if [ "$FOUND_DATA" = false ]; then
        log_feedback "No posting data found for the past 7 days"
        # Write empty summary
        jq -n \
            --arg week_ending "$DATE" \
            --arg generated_at "$TIMESTAMP" \
            '{
                week_ending: $week_ending,
                generated_at: $generated_at,
                total_posts: 0,
                posts_per_platform: {},
                posts_per_product: {},
                posts_per_bucket: {},
                content_ids: [],
                engagement_summary: "No data available",
                note: "No posts recorded in the past 7 days"
            }' > "$SUMMARY_FILE"
        echo "Weekly summary (empty): $SUMMARY_FILE"
        return 0
    fi

    # Generate summary using Python for proper JSON aggregation
    TEMP_FILE="$TEMP_ALL" SUMMARY_OUT="$SUMMARY_FILE" WEEK_DATE="$DATE" GEN_TIMESTAMP="$TIMESTAMP" python3 -c "
import json, os, sys
from collections import Counter

temp_file = os.environ['TEMP_FILE']
summary_out = os.environ['SUMMARY_OUT']
week_date = os.environ['WEEK_DATE']
gen_ts = os.environ['GEN_TIMESTAMP']

platform_counts = Counter()
product_counts = Counter()
bucket_counts = Counter()
content_ids = []
total = 0

with open(temp_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        total += 1
        platform = entry.get('platform', 'unknown')
        product = entry.get('product', 'unknown')
        bucket = entry.get('bucket', 'unknown')
        content_id = entry.get('content_id', entry.get('file', ''))

        platform_counts[platform] += 1
        if product and product != 'unknown':
            product_counts[product] += 1
        if bucket and bucket != 'unknown':
            bucket_counts[bucket] += 1
        if content_id and content_id not in content_ids:
            content_ids.append(content_id)

# Check for any engagement data
engagement_entries = []
with open(temp_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            eng = entry.get('engagement_data')
            if eng and eng != 'pending':
                engagement_entries.append(eng)
        except:
            pass

engagement_summary = 'No engagement data collected yet'
if engagement_entries:
    engagement_summary = f'{len(engagement_entries)} entries with engagement data'

summary = {
    'week_ending': week_date,
    'generated_at': gen_ts,
    'total_posts': total,
    'posts_per_platform': dict(platform_counts),
    'posts_per_product': dict(product_counts) if product_counts else {'note': 'No product tags found in posted content'},
    'posts_per_bucket': dict(bucket_counts) if bucket_counts else {'note': 'No bucket tags found in posted content'},
    'content_ids': content_ids[:50],
    'engagement_summary': engagement_summary
}

with open(summary_out, 'w') as f:
    json.dump(summary, f, indent=2)

print(f'Weekly summary: {total} posts across {len(platform_counts)} platforms')
print(f'Output: {summary_out}')
" 2>&1

    if [ $? -ne 0 ]; then
        log_feedback "ERROR: Failed to generate weekly summary"
        return 1
    fi

    log_feedback "Weekly summary generated: $SUMMARY_FILE"
}

# ── Show feedback status ──
show_status() {
    echo "--- FEEDBACK COLLECTOR STATUS ---"
    echo ""

    local TOTAL_ENTRIES=0
    local FILE_COUNT=0

    for F in "$FEEDBACK_DIR"/posted-*.jsonl; do
        [ -f "$F" ] || continue
        FILE_COUNT=$((FILE_COUNT + 1))
        local COUNT
        COUNT=$(wc -l < "$F" | tr -d ' ')
        TOTAL_ENTRIES=$((TOTAL_ENTRIES + COUNT))
        echo "  $(basename "$F"): $COUNT entries"
    done

    echo ""
    echo "  Total feedback files: $FILE_COUNT"
    echo "  Total entries: $TOTAL_ENTRIES"

    # Check for weekly summaries
    echo ""
    local SUMMARY_COUNT=0
    for S in "$FEEDBACK_DIR"/weekly-summary-*.json; do
        [ -f "$S" ] || continue
        SUMMARY_COUNT=$((SUMMARY_COUNT + 1))
        echo "  Summary: $(basename "$S")"
    done
    [ "$SUMMARY_COUNT" -eq 0 ] && echo "  No weekly summaries generated yet"
    echo ""
}

# ── Main dispatch ──
CMD="${1:-status}"
shift 2>/dev/null || true

case "$CMD" in
    record)
        record_post "$@"
        ;;
    weekly-summary)
        generate_weekly_summary
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: feedback-collector.sh <command>"
        echo ""
        echo "  record --file <name> --platform <platform>   Record a posted item"
        echo "  weekly-summary                                Generate weekly summary"
        echo "  status                                        Show feedback data status"
        ;;
esac
