#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# revenue-engine.sh — Orchestrate revenue pipeline
# Usage: ./revenue-engine.sh [--scan-inbox] [--process-leads] [--follow-ups]
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -uo pipefail

WS="/Volumes/Expansion/CMO-10million"
BOT_ROOT="$WS/OpenClawData/inbharat-bot"
LEADS="$BOT_ROOT/leads/data"
PROPOSALS="$BOT_ROOT/revenue/proposals"
FOLLOWUPS="$BOT_ROOT/revenue/followups"
PIPELINE="$BOT_ROOT/revenue/pipeline-state"
SCRIPTS="$BOT_ROOT/revenue"
LOG="$BOT_ROOT/logging/bot-$(date +%Y-%m-%d).log"
TS=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')

log() { echo "[$TS] $1" >> "$LOG"; echo "$1"; }

ACTION="${1:---status}"

log "=== Revenue Engine: $ACTION ==="

case "$ACTION" in
  --status)
    LEAD_COUNT=$(find "$LEADS" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
    PROPOSAL_COUNT=$(find "$PROPOSALS" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    HOT=$(grep -rl '"hot"' "$LEADS"/ 2>/dev/null | wc -l | tr -d ' ')
    WARM=$(grep -rl '"warm"' "$LEADS"/ 2>/dev/null | wc -l | tr -d ' ')
    log "Leads: $LEAD_COUNT (hot=$HOT warm=$WARM) | Proposals: $PROPOSAL_COUNT"
    
    # Generate pipeline state
    cat > "$PIPELINE/state-$DATE.json" << STATE
{
  "date": "$DATE",
  "total_leads": $LEAD_COUNT,
  "hot_leads": $HOT,
  "warm_leads": $WARM,
  "proposals_drafted": $PROPOSAL_COUNT,
  "status": "active"
}
STATE
    ;;

  --process-leads)
    log "Processing unhandled leads..."
    for LEAD_FILE in "$LEADS"/*.json; do
      [ ! -f "$LEAD_FILE" ] && continue
      QUAL=$(python3 -c "import json; print(json.load(open('$LEAD_FILE')).get('qualification','?'))" 2>/dev/null)
      ACTION_NEEDED=$(python3 -c "import json; print(json.load(open('$LEAD_FILE')).get('suggested_action','?'))" 2>/dev/null)
      
      if [ "$QUAL" = "hot" ] && [ "$ACTION_NEEDED" = "reply" ]; then
        # Auto-generate proposal for hot leads
        EXISTING_PROPOSAL=$(find "$PROPOSALS" -name "*$(basename "$LEAD_FILE" .json)*" 2>/dev/null | head -1)
        if [ -z "$EXISTING_PROPOSAL" ]; then
          log "  Hot lead needs proposal: $(basename "$LEAD_FILE")"
          bash "$SCRIPTS/proposal-builder.sh" "$LEAD_FILE" 2>/dev/null
        fi
      fi
    done
    ;;

  --follow-ups)
    log "Checking follow-ups..."
    # List leads older than 3 days without proposals
    find "$LEADS" -name "*.json" -mtime +3 -type f 2>/dev/null | while read LEAD_FILE; do
      LID=$(python3 -c "import json; print(json.load(open('$LEAD_FILE')).get('lead_id','?'))" 2>/dev/null)
      EXISTING=$(find "$PROPOSALS" -name "*$LID*" 2>/dev/null | head -1)
      if [ -z "$EXISTING" ]; then
        log "  FOLLOW-UP NEEDED: $LID (no proposal after 3 days)"
      fi
    done
    ;;
esac

log "=== Revenue Engine complete ==="
