#!/bin/bash
# InBharat Bot — Outreach Tracker
# Usage: ./outreach-tracker.sh [today|week|all|stats]
# Reads JSONL logs from outreach/log/

set -uo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
OUTREACH_LOG_DIR="$BOT_ROOT/outreach/log"
DRAFTS_DIR="$BOT_ROOT/outreach/drafts"
DATE=$(date '+%Y-%m-%d')

MODE="${1:-today}"

case "$MODE" in
  today)
    LOG_FILE="$OUTREACH_LOG_DIR/outreach-${DATE}.jsonl"
    if [ ! -f "$LOG_FILE" ]; then
      echo "No outreach activity today."
      exit 0
    fi
    ENTRY_COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')
    echo "━━━ OUTREACH LOG — $DATE ━━━"
    echo "Entries: $ENTRY_COUNT"
    echo ""
    while IFS= read -r line; do
      TYPE=$(echo "$line" | jq -r '.type // "?"')
      CONTEXT=$(echo "$line" | jq -r '.context // "?"' | head -c 60)
      STATUS=$(echo "$line" | jq -r '.status // "?"')
      TIME=$(echo "$line" | jq -r '.time // "?"')
      echo "  [$TIME] $TYPE | $STATUS | $CONTEXT"
    done < "$LOG_FILE"
    ;;

  week)
    echo "━━━ OUTREACH LOG — Last 7 Days ━━━"
    TOTAL=0
    for i in $(seq 0 6); do
      D=$(date -v-${i}d '+%Y-%m-%d' 2>/dev/null || date -d "-${i} days" '+%Y-%m-%d' 2>/dev/null)
      [ -z "$D" ] && continue
      LOG_FILE="$OUTREACH_LOG_DIR/outreach-${D}.jsonl"
      if [ -f "$LOG_FILE" ]; then
        COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')
        TOTAL=$((TOTAL + COUNT))
        echo "  $D: $COUNT entries"
      fi
    done
    echo ""
    echo "Total: $TOTAL entries"
    ;;

  all)
    echo "━━━ ALL OUTREACH LOGS ━━━"
    TOTAL=0
    for LOG_FILE in "$OUTREACH_LOG_DIR"/outreach-*.jsonl; do
      [ ! -f "$LOG_FILE" ] && continue
      COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')
      TOTAL=$((TOTAL + COUNT))
      BASENAME=$(basename "$LOG_FILE" .jsonl | sed 's/outreach-//')
      echo "  $BASENAME: $COUNT entries"
    done
    echo ""
    echo "Total: $TOTAL entries"
    ;;

  stats)
    echo "━━━ OUTREACH STATS ━━━"
    DRAFT_COUNT=$(find "$DRAFTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    LOG_COUNT=$(find "$OUTREACH_LOG_DIR" -name "*.jsonl" -type f 2>/dev/null | wc -l | tr -d ' ')

    # Count by type from all logs
    COLD=0; PARTNERSHIP=0; GOVT=0; FOLLOWUP=0; THANKYOU=0
    for LOG_FILE in "$OUTREACH_LOG_DIR"/outreach-*.jsonl; do
      [ ! -f "$LOG_FILE" ] && continue
      while IFS= read -r line; do
        CONTEXT=$(echo "$line" | jq -r '.context // ""')
        case "$CONTEXT" in
          *cold*|*intro*) COLD=$((COLD + 1)) ;;
          *partner*) PARTNERSHIP=$((PARTNERSHIP + 1)) ;;
          *government*|*ICDS*|*NITI*|*ministry*) GOVT=$((GOVT + 1)) ;;
          *follow*) FOLLOWUP=$((FOLLOWUP + 1)) ;;
          *thank*) THANKYOU=$((THANKYOU + 1)) ;;
        esac
      done < "$LOG_FILE"
    done

    echo "Drafts on disk: $DRAFT_COUNT"
    echo "Log days: $LOG_COUNT"
    echo ""
    echo "By type (estimated from context):"
    echo "  Cold intro:    $COLD"
    echo "  Partnership:   $PARTNERSHIP"
    echo "  Government:    $GOVT"
    echo "  Follow-up:     $FOLLOWUP"
    echo "  Thank you:     $THANKYOU"
    ;;

  *)
    echo "Usage: outreach-tracker.sh [today|week|all|stats]"
    exit 1
    ;;
esac
