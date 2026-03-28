#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# community-operator.sh — Decide and execute community actions
# Usage: ./community-operator.sh [--dry-run]
# Reads community maps, checks warmup status, routes content
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

WS="/Volumes/Expansion/CMO-10million"
MAPS="$WS/OpenClawData/community/maps"
HISTORY="$WS/OpenClawData/community/history"
DRAFTS="$WS/OpenClawData/community/drafts"
APPROVED="$WS/OpenClawData/approvals/approved"
SCRIPTS="$WS/OpenClawData/scripts"
LOG="$WS/OpenClawData/logs/community-operator.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')
DRY_RUN=false

[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

log() { echo "[$TS] $1" >> "$LOG"; echo "$1"; }

log "=== Community Operator $([ "$DRY_RUN" = true ] && echo '[DRY RUN]') ==="

# Count available community maps
MAP_COUNT=$(find "$MAPS" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$MAP_COUNT" -eq 0 ]; then
  log "No community maps found. Run community-scout.sh first."
  exit 0
fi

# Count available approved content
CONTENT_COUNT=$(find "$APPROVED" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
log "Maps: $MAP_COUNT | Approved content: $CONTENT_COUNT"

# Process each community
ACTIONS=0
SKIPPED=0
REWRITES=0

for MAP_FILE in "$MAPS"/*.json; do
  [ ! -f "$MAP_FILE" ] && continue

  COMMUNITY=$(python3 -c "import json; d=json.load(open('$MAP_FILE')); print(d.get('name','?'))" 2>/dev/null)
  PLATFORM=$(python3 -c "import json; d=json.load(open('$MAP_FILE')); print(d.get('platform','?'))" 2>/dev/null)
  MODE=$(python3 -c "import json; d=json.load(open('$MAP_FILE')); print(d.get('recommended_posting_mode','observe'))" 2>/dev/null)
  WARMUP=$(python3 -c "import json; d=json.load(open('$MAP_FILE')); print(d.get('warmup_status','observe'))" 2>/dev/null)
  RISK=$(python3 -c "import json; d=json.load(open('$MAP_FILE')); print(d.get('scores',{}).get('risk_of_removal',5))" 2>/dev/null)

  log "  Community: $COMMUNITY ($PLATFORM) | mode=$MODE warmup=$WARMUP risk=$RISK"

  # Decision logic
  if [ "$WARMUP" = "observe" ]; then
    log "    → OBSERVE ONLY. No action taken."
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ "$RISK" -ge 8 ]; then
    log "    → HIGH RISK ($RISK/10). Skipping."
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ "$CONTENT_COUNT" -eq 0 ]; then
    log "    → No approved content available."
    continue
  fi

  # Pick best content for this community
  BEST_CONTENT=$(find "$APPROVED" -name "*.md" -type f 2>/dev/null | head -1)
  if [ -z "$BEST_CONTENT" ]; then
    continue
  fi

  # Rewrite for community
  if [ "$DRY_RUN" = true ]; then
    log "    → [DRY RUN] Would rewrite $(basename "$BEST_CONTENT") for $COMMUNITY"
  else
    bash "$SCRIPTS/community-rewriter.sh" "$BEST_CONTENT" "$MAP_FILE" 2>/dev/null && REWRITES=$((REWRITES + 1))
    log "    → Rewrite created for $COMMUNITY"
  fi

  ACTIONS=$((ACTIONS + 1))

  # Log to history
  echo "{\"date\":\"$DATE\",\"community\":\"$COMMUNITY\",\"platform\":\"$PLATFORM\",\"action\":\"rewrite\",\"mode\":\"$MODE\",\"content\":\"$(basename "$BEST_CONTENT")\"}" >> "$HISTORY/actions-$DATE.jsonl"

done

log "=== Summary: $ACTIONS actions, $REWRITES rewrites, $SKIPPED skipped ==="
