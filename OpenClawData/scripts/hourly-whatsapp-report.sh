#!/bin/bash
# hourly-whatsapp-report.sh — Sends hourly activity summary to owner via WhatsApp
# Runs via cron every hour. Reports what happened in the last hour.

set -uo pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
LOGS_DIR="$WORKSPACE_ROOT/OpenClawData/logs"
ANALYTICS_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/analytics"
BOT_ROOT="$WORKSPACE_ROOT/OpenClawData/inbharat-bot"
DATE=$(date '+%Y-%m-%d')
HOUR=$(date '+%H')
NOW=$(date '+%Y-%m-%d %H:%M')

# ── Collect stats ──

# Content generated in last hour
CONTENT_GENERATED=0
for DIR in "$WORKSPACE_ROOT/OpenClawData/openclaw-media/native-pipeline/output" "$WORKSPACE_ROOT/OpenClawData/openclaw-media/amplify-pipeline/output"; do
  if [ -d "$DIR" ]; then
    COUNT=$(find "$DIR" -type f -name "*.json" -newer /tmp/.openclaw-hourly-marker 2>/dev/null | wc -l | tr -d ' ')
    CONTENT_GENERATED=$((CONTENT_GENERATED + COUNT))
  fi
done

# Items in queues
PENDING=0
APPROVED=0
POSTED_COUNT=0
for PLATFORM in discord linkedin x instagram; do
  P=$(find "$QUEUES_DIR/$PLATFORM/pending" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
  A=$(find "$QUEUES_DIR/$PLATFORM/approved" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
  D=$(find "$QUEUES_DIR/$PLATFORM/posted" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
  PENDING=$((PENDING + P))
  APPROVED=$((APPROVED + A))
  POSTED_COUNT=$((POSTED_COUNT + D))
done

# Posts made in last hour
POSTS_THIS_HOUR=0
POST_LOG="$ANALYTICS_DIR/post-actions-${DATE}.jsonl"
if [ -f "$POST_LOG" ]; then
  POSTS_THIS_HOUR=$(grep "\"action\":\"posted\"" "$POST_LOG" 2>/dev/null | grep "\"time\":\"${HOUR}:" 2>/dev/null | wc -l | tr -d ' ')
fi

# Lane runs in last hour
LANE_RUNS=0
LANE_LOG="$BOT_ROOT/logging/lane-runs-${DATE}.jsonl"
if [ -f "$LANE_LOG" ]; then
  LANE_RUNS=$(grep "\"hour\":\"${HOUR}\"" "$LANE_LOG" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$LANE_RUNS" -eq 0 ]; then
    # Try matching by time field
    LANE_RUNS=$(grep "\"${HOUR}:" "$LANE_LOG" 2>/dev/null | wc -l | tr -d ' ')
  fi
fi

# Scan reports generated today
SCANS_TODAY=0
for SCAN_DIR in "$BOT_ROOT/india-problems" "$BOT_ROOT/ai-gaps" "$BOT_ROOT/funding" "$BOT_ROOT/ecosystem-intelligence" "$BOT_ROOT/opportunities/reports"; do
  if [ -d "$SCAN_DIR" ]; then
    COUNT=$(find "$SCAN_DIR" -maxdepth 1 -type f -name "*${DATE}*" 2>/dev/null | wc -l | tr -d ' ')
    SCANS_TODAY=$((SCANS_TODAY + COUNT))
  fi
done

# Outreach drafts today
DRAFTS_TODAY=0
if [ -d "$BOT_ROOT/outreach/drafts" ]; then
  DRAFTS_TODAY=$(find "$BOT_ROOT/outreach/drafts" -type f -name "*${DATE}*" 2>/dev/null | wc -l | tr -d ' ')
fi

# Health check
HEALTH="unknown"
HEALTH_SCRIPT="$WORKSPACE_ROOT/OpenClawData/scripts/health-check.sh"
if [ -x "$HEALTH_SCRIPT" ]; then
  HEALTH_OUTPUT=$(bash "$HEALTH_SCRIPT" 2>&1 | tail -3)
  GREEN=$(echo "$HEALTH_OUTPUT" | grep -o '[0-9]* green' | head -1)
  YELLOW=$(echo "$HEALTH_OUTPUT" | grep -o '[0-9]* yellow' | head -1)
  RED=$(echo "$HEALTH_OUTPUT" | grep -o '[0-9]* red' | head -1)
  HEALTH="${GREEN:-?}, ${YELLOW:-?}, ${RED:-?}"
fi

# Blocked content
BLOCKED=0
BLOCKED_DIR="$WORKSPACE_ROOT/OpenClawData/approvals/blocked"
if [ -d "$BLOCKED_DIR" ]; then
  BLOCKED=$(find "$BLOCKED_DIR" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
fi

# ── Build message ──
MSG="🤖 *OpenClaw Hourly Report*
📅 ${NOW}

📊 *Queue Status*
• Pending review: ${PENDING}
• Approved: ${APPROVED}
• Total posted: ${POSTED_COUNT}
• Blocked: ${BLOCKED}

⚡ *Last Hour*
• Content generated: ${CONTENT_GENERATED}
• Posts published: ${POSTS_THIS_HOUR}
• Bot lane runs: ${LANE_RUNS}

📈 *Today's Activity*
• Intelligence scans: ${SCANS_TODAY}
• Outreach drafts: ${DRAFTS_TODAY}

🏥 *Health:* ${HEALTH}

💡 *Pending actions for you:*"

# Add pending actions
ACTIONS=""
if [ "$PENDING" -gt 0 ]; then
  ACTIONS="${ACTIONS}
• ${PENDING} items need your approval"
fi

# Check platform sessions
for PLATFORM in linkedin x instagram; do
  POSTER_SCRIPT="$WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine/post_${PLATFORM}.py"
  if [ -f "$POSTER_SCRIPT" ]; then
    SESSION_CHECK=$(python3 "$POSTER_SCRIPT" --check 2>&1)
    if echo "$SESSION_CHECK" | grep -qi "EXPIRED\|FAILED\|ERROR"; then
      ACTIONS="${ACTIONS}
• ${PLATFORM}: needs login"
    fi
  fi
done

# Check DALL-E
DALLE_KEY=$(security find-generic-password -s "openclaw" -a "openclaw-openai-api-key" -w 2>/dev/null)
if [ -z "$DALLE_KEY" ]; then
  ACTIONS="${ACTIONS}
• DALL-E 3: API key not set"
fi

if [ -z "$ACTIONS" ]; then
  ACTIONS="
• All good! No actions needed."
fi

MSG="${MSG}${ACTIONS}"

# ── Send via WhatsApp ──
OWNER_NUMBER="+919015823397"

# Send via OpenClaw CLI
SEND_RESULT=$(openclaw message send \
  --channel whatsapp \
  --target "$OWNER_NUMBER" \
  --message "$MSG" 2>&1)

SEND_EXIT=$?

if [ $SEND_EXIT -eq 0 ]; then
  echo "[$(date)] WhatsApp report sent successfully"
else
  # Fallback: try gateway API directly
  GATEWAY_URL="http://localhost:18789"
  SEND_RESULT=$(curl -s --max-time 10 "$GATEWAY_URL/api/whatsapp/send" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
msg = '''${MSG}'''
print(json.dumps({'to': '${OWNER_NUMBER}', 'message': msg}))
")" 2>&1)

  if echo "$SEND_RESULT" | grep -qi "ok\|sent\|success"; then
    echo "[$(date)] WhatsApp report sent via gateway fallback"
  else
    echo "[$(date)] WhatsApp send failed: $SEND_RESULT"
    echo "[$(date)] Report content:"
    echo "$MSG"
  fi
fi

# Update marker for next hour's "new files" check
touch /tmp/.openclaw-hourly-marker

# Log this report
mkdir -p "$LOGS_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hourly report sent" >> "$LOGS_DIR/hourly-reports.log"
