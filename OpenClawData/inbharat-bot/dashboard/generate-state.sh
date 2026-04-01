#!/bin/bash
# InBharat Bot — Dashboard State Generator v3.0
# Produces a JSON state file and human-readable status report.
# Counts ACTUAL lane outputs, queue states, and system health.

set -o pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
APPROVALS_DIR="$WORKSPACE_ROOT/OpenClawData/approvals"
MEDIA_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media"
DASHBOARD_DIR="$BOT_ROOT/dashboard"
STATE_JSON="$DASHBOARD_DIR/bot-state.json"
STATE_REPORT="$DASHBOARD_DIR/bot-status.md"

# Source logger safely
if [ -f "$BOT_ROOT/logging/bot-logger.sh" ]; then
  source "$BOT_ROOT/logging/bot-logger.sh"
else
  bot_log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$2] [$1] $3"; }
fi

bot_log "dashboard" "info" "Generating dashboard state..."

# Helper: count real files (exclude ._ macOS metadata and .gitkeep)
count_files() {
  find "$1" -maxdepth 1 -type f ! -name ".*" ! -name ".gitkeep" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' '
}

# Helper: latest file date
latest_file_date() {
  local LATEST=$(ls -t "$1"/*.md "$1"/*.json 2>/dev/null | head -1)
  if [ -n "$LATEST" ]; then
    stat -f '%Sm' -t '%Y-%m-%d' "$LATEST" 2>/dev/null || echo "unknown"
  else
    echo "never"
  fi
}

# ── Count Lane Outputs (v3.0 architecture) ──
INDIA_PROBLEMS=$(count_files "$BOT_ROOT/india-problems")
AI_GAPS=$(count_files "$BOT_ROOT/ai-gaps")
BLOGS=$(count_files "$BOT_ROOT/blogs")
CAMPAIGNS=$(count_files "$BOT_ROOT/campaigns")
ECOSYSTEM=$(count_files "$BOT_ROOT/ecosystem")
OUTREACH=$(count_files "$BOT_ROOT/outreach")
LEADS=$(count_files "$BOT_ROOT/leads")
FUNDING=$(count_files "$BOT_ROOT/funding")
PODCAST=$(count_files "$BOT_ROOT/podcast")
LEARNING=$(count_files "$BOT_ROOT/learning")
REPORTS=$(count_files "$BOT_ROOT/reports")

# ── Count Queue States ──
QUEUE_PENDING=0
QUEUE_APPROVED=0
QUEUE_READY=0
QUEUE_POSTED=0
for PLATFORM_DIR in "$QUEUES_DIR"/*/; do
  [ ! -d "$PLATFORM_DIR" ] && continue
  P_COUNT=$(count_files "${PLATFORM_DIR}pending" 2>/dev/null); P_COUNT=${P_COUNT:-0}
  A_COUNT=$(count_files "${PLATFORM_DIR}approved" 2>/dev/null); A_COUNT=${A_COUNT:-0}
  R_COUNT=$(count_files "${PLATFORM_DIR}publish-ready" 2>/dev/null); R_COUNT=${R_COUNT:-0}
  T_COUNT=$(count_files "${PLATFORM_DIR}posted" 2>/dev/null); T_COUNT=${T_COUNT:-0}
  QUEUE_PENDING=$((QUEUE_PENDING + P_COUNT))
  QUEUE_APPROVED=$((QUEUE_APPROVED + A_COUNT))
  QUEUE_READY=$((QUEUE_READY + R_COUNT))
  QUEUE_POSTED=$((QUEUE_POSTED + T_COUNT))
done

# ── Count Approval States ──
REVIEW_COUNT=$(count_files "$APPROVALS_DIR/review" 2>/dev/null || echo 0)
BLOCKED_COUNT=$(find "$APPROVALS_DIR/blocked" -type f ! -name ".*" ! -name "block-log-*" 2>/dev/null | wc -l | tr -d ' ')

# ── Count Handoffs ──
HANDOFFS_PENDING=$(count_files "$BOT_ROOT/handoffs" 2>/dev/null || echo 0)
HANDOFFS_PROCESSED=$(count_files "$BOT_ROOT/handoffs/processed" 2>/dev/null || echo 0)

# ── System Health ──
TODAY=$(date +%Y-%m-%d)
OLLAMA_STATUS="not_responding"
if curl -s --max-time 3 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  OLLAMA_STATUS="running"
fi

GATEWAY_STATUS="not_running"
if pgrep -f openclaw >/dev/null 2>&1 || curl -s --max-time 3 http://127.0.0.1:18789/ >/dev/null 2>&1; then
  GATEWAY_STATUS="running"
fi

# ── Today's Activity ──
TODAY_LOG="$BOT_ROOT/logging/bot-${TODAY}.log"
LOG_LINES=0
ERROR_COUNT=0
if [ -f "$TODAY_LOG" ]; then
  LOG_LINES=$(wc -l < "$TODAY_LOG" | tr -d ' ')
  ERROR_COUNT=$(grep -c '\[error\]' "$TODAY_LOG" 2>/dev/null || echo 0)
  [ -z "$ERROR_COUNT" ] && ERROR_COUNT=0
fi

# ── Write JSON state ──
jq -n \
  --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --arg ollama "$OLLAMA_STATUS" \
  --arg gateway "$GATEWAY_STATUS" \
  --argjson india_problems "${INDIA_PROBLEMS:-0}" \
  --argjson ai_gaps "${AI_GAPS:-0}" \
  --argjson blogs "${BLOGS:-0}" \
  --argjson campaigns "${CAMPAIGNS:-0}" \
  --argjson ecosystem "${ECOSYSTEM:-0}" \
  --argjson outreach "${OUTREACH:-0}" \
  --argjson leads "${LEADS:-0}" \
  --argjson funding "${FUNDING:-0}" \
  --argjson podcast "${PODCAST:-0}" \
  --argjson learning "${LEARNING:-0}" \
  --argjson reports "${REPORTS:-0}" \
  --argjson q_pending "${QUEUE_PENDING:-0}" \
  --argjson q_approved "${QUEUE_APPROVED:-0}" \
  --argjson q_ready "${QUEUE_READY:-0}" \
  --argjson q_posted "${QUEUE_POSTED:-0}" \
  --argjson review "${REVIEW_COUNT:-0}" \
  --argjson blocked "${BLOCKED_COUNT:-0}" \
  --argjson h_pending "${HANDOFFS_PENDING:-0}" \
  --argjson h_processed "${HANDOFFS_PROCESSED:-0}" \
  --argjson log_lines "${LOG_LINES:-0}" \
  --argjson errors "${ERROR_COUNT:-0}" \
  '{
    bot: "InBharat Bot",
    version: "3.1.0",
    timestamp: $ts,
    health: { ollama: $ollama, gateway: $gateway },
    lanes: {
      india_problems: $india_problems,
      ai_gaps: $ai_gaps,
      blogs: $blogs,
      campaigns: $campaigns,
      ecosystem: $ecosystem,
      outreach: $outreach,
      leads: $leads,
      funding: $funding,
      podcast: $podcast,
      learning: $learning,
      reports: $reports
    },
    queues: {
      pending: $q_pending,
      approved: $q_approved,
      publish_ready: $q_ready,
      posted: $q_posted
    },
    approvals: {
      review: $review,
      blocked: $blocked
    },
    handoffs: {
      pending: $h_pending,
      processed: $h_processed
    },
    today: {
      log_lines: $log_lines,
      errors: $errors
    }
  }' > "$STATE_JSON"

# ── Write human-readable report ──
{
echo "# InBharat Bot — Status v3.1"
echo "**Updated:** $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "## Health"
echo "- Ollama: $OLLAMA_STATUS"
echo "- Gateway: $GATEWAY_STATUS"
echo ""
echo "## Lane Outputs"
echo "- India Problems: $INDIA_PROBLEMS"
echo "- AI Gaps: $AI_GAPS"
echo "- Blogs: $BLOGS"
echo "- Campaigns: $CAMPAIGNS"
echo "- Ecosystem: $ECOSYSTEM"
echo "- Outreach: $OUTREACH"
echo "- Leads: $LEADS"
echo "- Funding: $FUNDING"
echo "- Podcast: $PODCAST"
echo "- Learning: $LEARNING"
echo "- Reports: $REPORTS"
echo ""
echo "## Publishing Queues"
echo "- Pending: $QUEUE_PENDING"
echo "- Approved: $QUEUE_APPROVED"
echo "- Publish-Ready: $QUEUE_READY"
echo "- Posted: $QUEUE_POSTED"
echo ""
echo "## Approvals"
echo "- In review: $REVIEW_COUNT"
echo "- Blocked: $BLOCKED_COUNT"
echo ""
echo "## Handoffs (Bot → OpenClaw)"
echo "- Pending: $HANDOFFS_PENDING"
echo "- Processed: $HANDOFFS_PROCESSED"
echo ""
echo "## Today's Activity"
echo "- Log lines: $LOG_LINES"
echo "- Errors: $ERROR_COUNT"
} > "$STATE_REPORT"

bot_log "dashboard" "info" "State generated → $STATE_JSON"
echo "=== Dashboard state updated ==="
cat "$STATE_REPORT"
