#!/bin/bash
# campaign-memory.sh — Campaign memory and learning system
# Tracks what worked, what failed, and why across all content campaigns.
#
# Usage:
#   ./campaign-memory.sh record <campaign-id> <outcome> <notes>
#   ./campaign-memory.sh review [--period 7d|30d|all]
#   ./campaign-memory.sh winners [--top 5]
#   ./campaign-memory.sh losers [--top 5]
#   ./campaign-memory.sh insights
#   ./campaign-memory.sh bucket-scores

set -o pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
MEDIA_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media"
MEMORY_FILE="$MEDIA_DIR/analytics/campaign-memory.jsonl"
DATE=$(date '+%Y-%m-%d')

mkdir -p "$(dirname "$MEMORY_FILE")"

CMD="${1:-review}"
shift 2>/dev/null || true

record_outcome() {
  local CAMPAIGN_ID="${1:-}"
  local OUTCOME="${2:-}" # win|loss|neutral|partial
  local NOTES="${3:-}"

  if [ -z "$CAMPAIGN_ID" ] || [ -z "$OUTCOME" ]; then
    echo "Usage: campaign-memory.sh record <campaign-id> <win|loss|neutral|partial> \"notes\""
    return 1
  fi

  # Validate outcome
  case "$OUTCOME" in
    win|loss|neutral|partial) ;;
    *) echo "ERROR: outcome must be win|loss|neutral|partial"; return 1 ;;
  esac

  # Try to find the content package for this campaign
  local PRODUCT="" BUCKET="" PLATFORM=""
  for QUEUE_DIR in "$WORKSPACE_ROOT"/OpenClawData/queues/*/; do
    for STATE_DIR in pending approved publish-ready posted; do
      for F in "${QUEUE_DIR}${STATE_DIR}"/*"${CAMPAIGN_ID}"* 2>/dev/null; do
        [ ! -f "$F" ] && continue
        PRODUCT=$(jq -r '.product // ""' "$F" 2>/dev/null)
        BUCKET=$(jq -r '.bucket // ""' "$F" 2>/dev/null)
        PLATFORM=$(basename "$(dirname "$(dirname "$F")")")
        break 3
      done
    done
  done

  jq -cn \
    --arg date "$DATE" \
    --arg time "$(date '+%H:%M:%S')" \
    --arg campaign_id "$CAMPAIGN_ID" \
    --arg outcome "$OUTCOME" \
    --arg notes "$NOTES" \
    --arg product "$PRODUCT" \
    --arg bucket "$BUCKET" \
    --arg platform "$PLATFORM" \
    '{date: $date, time: $time, campaign_id: $campaign_id, outcome: $outcome, notes: $notes, product: $product, bucket: $bucket, platform: $platform}' \
    >> "$MEMORY_FILE"

  echo "✅ Recorded: $CAMPAIGN_ID → $OUTCOME"
  [ -n "$PRODUCT" ] && echo "   Product: $PRODUCT | Bucket: $BUCKET | Platform: $PLATFORM"
}

review_memory() {
  local PERIOD="${1:-all}"

  if [ ! -f "$MEMORY_FILE" ]; then
    echo "No campaign memory yet. Record outcomes with: campaign-memory.sh record <id> <outcome> \"notes\""
    return 0
  fi

  echo "━━━ CAMPAIGN MEMORY ━━━"
  echo ""

  local TOTAL=$(wc -l < "$MEMORY_FILE" | tr -d ' ')
  local WINS=$(grep -c '"outcome":"win"' "$MEMORY_FILE" 2>/dev/null || echo 0)
  local LOSSES=$(grep -c '"outcome":"loss"' "$MEMORY_FILE" 2>/dev/null || echo 0)
  local PARTIALS=$(grep -c '"outcome":"partial"' "$MEMORY_FILE" 2>/dev/null || echo 0)
  local NEUTRALS=$(grep -c '"outcome":"neutral"' "$MEMORY_FILE" 2>/dev/null || echo 0)

  echo "Total records: $TOTAL"
  echo "Wins: $WINS | Losses: $LOSSES | Partial: $PARTIALS | Neutral: $NEUTRALS"

  if [ "$TOTAL" -gt 0 ]; then
    local WIN_RATE=$(( (WINS * 100) / TOTAL ))
    echo "Win rate: ${WIN_RATE}%"
  fi

  echo ""
  echo "Recent entries:"
  tail -10 "$MEMORY_FILE" | jq -r '"  \(.date) | \(.campaign_id) | \(.outcome) | \(.notes[:50])"' 2>/dev/null
}

show_winners() {
  local TOP="${1:-5}"

  if [ ! -f "$MEMORY_FILE" ]; then
    echo "No campaign memory yet."
    return 0
  fi

  echo "━━━ TOP WINNERS ━━━"
  echo ""
  grep '"outcome":"win"' "$MEMORY_FILE" | tail -"$TOP" | jq -r '"  \(.date) | \(.campaign_id) | \(.product) | \(.notes[:60])"' 2>/dev/null
}

show_losers() {
  local TOP="${1:-5}"

  if [ ! -f "$MEMORY_FILE" ]; then
    echo "No campaign memory yet."
    return 0
  fi

  echo "━━━ LESSONS FROM LOSSES ━━━"
  echo ""
  grep '"outcome":"loss"' "$MEMORY_FILE" | tail -"$TOP" | jq -r '"  \(.date) | \(.campaign_id) | \(.product) | \(.notes[:60])"' 2>/dev/null
}

bucket_scores() {
  if [ ! -f "$MEMORY_FILE" ]; then
    echo "No campaign memory yet."
    return 0
  fi

  echo "━━━ BUCKET PERFORMANCE ━━━"
  echo ""

  # Group by bucket, show win/loss ratio
  python3 -c "
import json, sys
from collections import defaultdict

buckets = defaultdict(lambda: {'win': 0, 'loss': 0, 'partial': 0, 'neutral': 0, 'total': 0})
with open('$MEMORY_FILE') as f:
    for line in f:
        try:
            d = json.loads(line)
            b = d.get('bucket', 'unknown') or 'unknown'
            o = d.get('outcome', 'neutral')
            buckets[b][o] += 1
            buckets[b]['total'] += 1
        except: pass

for bucket, scores in sorted(buckets.items(), key=lambda x: -x[1]['win']):
    wr = (scores['win'] * 100 // scores['total']) if scores['total'] > 0 else 0
    print(f'  {bucket}: {scores[\"total\"]} campaigns | {wr}% win rate | W:{scores[\"win\"]} L:{scores[\"loss\"]} P:{scores[\"partial\"]}')
" 2>/dev/null
}

generate_insights() {
  if [ ! -f "$MEMORY_FILE" ]; then
    echo "No campaign memory yet."
    return 0
  fi

  echo "━━━ CAMPAIGN INSIGHTS ━━━"
  echo ""

  # Product performance
  echo "By Product:"
  python3 -c "
import json
from collections import defaultdict
products = defaultdict(lambda: {'win': 0, 'total': 0})
with open('$MEMORY_FILE') as f:
    for line in f:
        try:
            d = json.loads(line)
            p = d.get('product', 'unknown') or 'unknown'
            products[p]['total'] += 1
            if d.get('outcome') == 'win': products[p]['win'] += 1
        except: pass
for p, s in sorted(products.items(), key=lambda x: -x[1]['win']):
    wr = (s['win'] * 100 // s['total']) if s['total'] > 0 else 0
    print(f'  {p}: {s[\"total\"]} campaigns, {wr}% win rate')
" 2>/dev/null

  echo ""
  echo "By Platform:"
  python3 -c "
import json
from collections import defaultdict
platforms = defaultdict(lambda: {'win': 0, 'total': 0})
with open('$MEMORY_FILE') as f:
    for line in f:
        try:
            d = json.loads(line)
            p = d.get('platform', 'unknown') or 'unknown'
            platforms[p]['total'] += 1
            if d.get('outcome') == 'win': platforms[p]['win'] += 1
        except: pass
for p, s in sorted(platforms.items(), key=lambda x: -x[1]['win']):
    wr = (s['win'] * 100 // s['total']) if s['total'] > 0 else 0
    print(f'  {p}: {s[\"total\"]} campaigns, {wr}% win rate')
" 2>/dev/null

  echo ""
  echo "Top Failure Patterns:"
  grep '"outcome":"loss"' "$MEMORY_FILE" 2>/dev/null | jq -r '.notes' 2>/dev/null | sort | uniq -c | sort -rn | head -5 | sed 's/^/  /'
}

case "$CMD" in
  record)       record_outcome "${1:-}" "${2:-}" "${3:-}" ;;
  review)       review_memory "${1:-all}" ;;
  winners)      show_winners "${1:-5}" ;;
  losers)       show_losers "${1:-5}" ;;
  insights)     generate_insights ;;
  bucket-scores|buckets) bucket_scores ;;
  *)
    echo "━━━ Campaign Memory ━━━"
    echo ""
    echo "  record <id> <win|loss|neutral|partial> \"notes\"  Record outcome"
    echo "  review [period]                                   Review all records"
    echo "  winners [top-n]                                   Show top winners"
    echo "  losers [top-n]                                    Show failure lessons"
    echo "  insights                                          Product/platform analysis"
    echo "  bucket-scores                                     Content bucket performance"
    ;;
esac
