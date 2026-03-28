#!/bin/bash
# InBharat Bot — Dashboard State Generator
# Produces a JSON state file that any dashboard (OpenClaw, SocialFlow, or web) can read.
# Also produces a human-readable status report.

set -uo pipefail  # removed -e: grep -c returns 1 when no matches, causing premature exit

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
  ERROR_COUNT=$(grep -c '\[error\]' "$TODAY_LOG" 2>/dev/null || true)
  [ -z "$ERROR_COUNT" ] && ERROR_COUNT=0
fi

# Ollama status
OLLAMA_STATUS="unknown"
if curl -s --max-time 3 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  OLLAMA_STATUS="running"
else
  OLLAMA_STATUS="not_responding"
fi

# Gateway status
GATEWAY_STATUS="not_running"
if pgrep -f openclaw-gateway >/dev/null 2>&1; then
  GATEWAY_STATUS="running"
fi

# Write JSON state using jq for guaranteed valid JSON
jq -n \
  --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --arg ollama "$OLLAMA_STATUS" \
  --arg gateway "$GATEWAY_STATUS" \
  --argjson scans "${SCAN_COUNT:-0}" \
  --argjson findings "${FINDINGS_COUNT:-0}" \
  --argjson proposals "${PROPOSALS_COUNT:-0}" \
  --argjson bridges "${BRIDGE_COUNT:-0}" \
  --argjson review "${REVIEW_COUNT:-0}" \
  --argjson blocked "${BLOCKED_COUNT:-0}" \
  --argjson approved "${APPROVED_COUNT:-0}" \
  --arg last_scan "$LAST_SCAN" \
  --arg last_findings "$LAST_FINDINGS" \
  --arg last_proposals "$LAST_PROPOSALS" \
  --argjson log_lines "${LOG_LINES:-0}" \
  --argjson errors "${ERROR_COUNT:-0}" \
  '{
    bot: "InBharat Bot",
    version: "1.0.0",
    timestamp: $ts,
    health: { ollama: $ollama, gateway: $gateway },
    counts: {
      scans: $scans, findings: $findings, proposals: $proposals,
      cmo_bridges: $bridges, review_pending: $review,
      blocked: $blocked, approved: $approved
    },
    last_activity: { scan: $last_scan, findings: $last_findings, proposals: $last_proposals },
    today_logs: { lines: $log_lines, errors: $errors }
  }' > "$STATE_JSON"

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
