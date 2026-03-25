#!/bin/bash
# InBharat Bot — Dashboard State Generator
# Produces a JSON state file that any dashboard (OpenClaw, SocialFlow, or web) can read.
# Also produces a human-readable status report.

set -euo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
DASHBOARD_DIR="$BOT_ROOT/dashboard"
STATE_JSON="$DASHBOARD_DIR/bot-state.json"
STATE_REPORT="$DASHBOARD_DIR/bot-status.md"

source "$BOT_ROOT/logging/bot-logger.sh"

bot_log "dashboard" "info" "Generating dashboard state..."

# Count various items
SCAN_COUNT=$(find "$BOT_ROOT/registry" -name "ecosystem-scan-*.md" 2>/dev/null | wc -l | tr -d ' ')
FINDINGS_COUNT=$(find "$BOT_ROOT/gap-finder" -name "findings-*.md" 2>/dev/null | wc -l | tr -d ' ')
PROPOSALS_COUNT=$(find "$BOT_ROOT/proposal-generator" -name "proposals-*.md" 2>/dev/null | wc -l | tr -d ' ')
BRIDGE_COUNT=$(find "$BOT_ROOT/cmo-bridge" -name "bridge-output-*.md" 2>/dev/null | wc -l | tr -d ' ')
REVIEW_COUNT=$(find "$BOT_ROOT/approval" -name "review-*.md" 2>/dev/null | wc -l | tr -d ' ')
BLOCKED_COUNT=$(find "$BOT_ROOT/approval" -name "blocked-*.md" 2>/dev/null | wc -l | tr -d ' ')
APPROVED_COUNT=$(find "$BOT_ROOT/approval" -name "approved-*.md" 2>/dev/null | wc -l | tr -d ' ')

# Latest timestamps
LAST_SCAN=$(ls -t "$BOT_ROOT/registry"/ecosystem-scan-*.md 2>/dev/null | head -1 | xargs -I{} stat -f '%Sm' -t '%Y-%m-%d %H:%M' {} 2>/dev/null || echo "never")
LAST_FINDINGS=$(ls -t "$BOT_ROOT/gap-finder"/findings-*.md 2>/dev/null | head -1 | xargs -I{} stat -f '%Sm' -t '%Y-%m-%d %H:%M' {} 2>/dev/null || echo "never")
LAST_PROPOSALS=$(ls -t "$BOT_ROOT/proposal-generator"/proposals-*.md 2>/dev/null | head -1 | xargs -I{} stat -f '%Sm' -t '%Y-%m-%d %H:%M' {} 2>/dev/null || echo "never")

# Today's log line count
TODAY=$(date +%Y-%m-%d)
TODAY_LOG="$BOT_ROOT/logging/bot-${TODAY}.log"
LOG_LINES=0
ERROR_COUNT=0
if [ -f "$TODAY_LOG" ]; then
  LOG_LINES=$(wc -l < "$TODAY_LOG" | tr -d ' ')
  ERROR_COUNT=$(grep -c '\[error\]' "$TODAY_LOG" 2>/dev/null || echo "0")
fi

# Ollama status
OLLAMA_STATUS="unknown"
if curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  OLLAMA_STATUS="running"
else
  OLLAMA_STATUS="not_responding"
fi

# Gateway status
GATEWAY_STATUS="not_running"
if pgrep -f openclaw-gateway >/dev/null 2>&1; then
  GATEWAY_STATUS="running"
fi

# Write JSON state
cat > "$STATE_JSON" << ENDJSON
{
  "bot": "InBharat Bot",
  "version": "1.0.0",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "health": {
    "ollama": "$OLLAMA_STATUS",
    "gateway": "$GATEWAY_STATUS"
  },
  "counts": {
    "scans": $SCAN_COUNT,
    "findings": $FINDINGS_COUNT,
    "proposals": $PROPOSALS_COUNT,
    "cmo_bridges": $BRIDGE_COUNT,
    "review_pending": $REVIEW_COUNT,
    "blocked": $BLOCKED_COUNT,
    "approved": $APPROVED_COUNT
  },
  "last_activity": {
    "scan": "$LAST_SCAN",
    "findings": "$LAST_FINDINGS",
    "proposals": "$LAST_PROPOSALS"
  },
  "today_logs": {
    "lines": $LOG_LINES,
    "errors": $ERROR_COUNT
  }
}
ENDJSON

# Write human-readable report
{
echo "# InBharat Bot — Status"
echo "**Updated:** $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "## Health"
echo "- Ollama: $OLLAMA_STATUS"
echo "- Gateway: $GATEWAY_STATUS"
echo ""
echo "## Activity"
echo "- Scans completed: $SCAN_COUNT (last: $LAST_SCAN)"
echo "- Findings reports: $FINDINGS_COUNT (last: $LAST_FINDINGS)"
echo "- Proposals generated: $PROPOSALS_COUNT (last: $LAST_PROPOSALS)"
echo "- CMO bridge outputs: $BRIDGE_COUNT"
echo ""
echo "## Approval Queue"
echo "- Pending review: $REVIEW_COUNT"
echo "- Blocked: $BLOCKED_COUNT"
echo "- Approved: $APPROVED_COUNT"
echo ""
echo "## Today's Logs"
echo "- Lines: $LOG_LINES"
echo "- Errors: $ERROR_COUNT"
} > "$STATE_REPORT"

bot_log "dashboard" "info" "State generated → $STATE_JSON"
echo "=== Dashboard state updated ==="
cat "$STATE_REPORT"
