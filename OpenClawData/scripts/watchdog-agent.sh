#!/bin/bash
# watchdog-agent.sh — OpenClaw Self-Healing Watchdog
#
# Runs every 15 minutes via cron. Detects failures, applies known fixes,
# escalates only what it can't solve. Not a daemon — runs, fixes, exits.
#
# Usage:
#   ./watchdog-agent.sh              Full check + fix cycle
#   ./watchdog-agent.sh --check-only Report problems without fixing
#   ./watchdog-agent.sh --status     Show current health summary
#
# Cron: */15 * * * * /Users/reeturajgoswami/Desktop/CMO-10million/OpenClawData/scripts/watchdog-agent.sh

set -o pipefail

WORKSPACE="/Users/reeturajgoswami/Desktop/CMO-10million"
OCD="$WORKSPACE/OpenClawData"
SCRIPTS="$OCD/scripts"
ENGINE="$OCD/openclaw-media/posting-engine"
ANALYTICS="$OCD/openclaw-media/analytics"
QUEUES="$OCD/queues"
LOG_FILE="$OCD/logs/watchdog.log"
STATE_FILE="$OCD/logs/watchdog-state.json"
ESCALATION_LOG="$OCD/logs/watchdog-escalations.log"
DATE=$(date '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M:%S')
NOW_EPOCH=$(date +%s)

CHECK_ONLY=false
STATUS_ONLY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --check-only) CHECK_ONLY=true ;;
    --status)     STATUS_ONLY=true ;;
    -h|--help)
      echo "Usage: watchdog-agent.sh [--check-only] [--status]"
      exit 0 ;;
  esac
  shift
done

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$STATE_FILE")"

# ── Logging ──
wlog() {
  echo "[$NOW] [$1] $2" >> "$LOG_FILE"
  echo "[$1] $2"
}

# ── State management ──
load_state() {
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo '{}'
  fi
}

save_state() {
  echo "$1" > "$STATE_FILE"
}

get_state_val() {
  local KEY="$1"
  load_state | /usr/bin/python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('$KEY', '0'))
" 2>/dev/null || echo "0"
}

set_state_val() {
  local KEY="$1"
  local VAL="$2"
  /usr/bin/python3 -c "
import json
try:
    with open('$STATE_FILE') as f:
        d = json.load(f)
except:
    d = {}
d['$KEY'] = '$VAL'
d['last_run'] = '$NOW'
with open('$STATE_FILE', 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null
}

# Check cooldown: returns 0 if action is allowed, 1 if on cooldown
check_cooldown() {
  local KEY="$1"
  local COOLDOWN_SECS="$2"
  local LAST=$(get_state_val "last_fix_${KEY}")
  if [ "$LAST" = "0" ] || [ -z "$LAST" ]; then
    return 0
  fi
  local ELAPSED=$((NOW_EPOCH - LAST))
  if [ "$ELAPSED" -lt "$COOLDOWN_SECS" ]; then
    return 1  # On cooldown
  fi
  return 0
}

record_fix() {
  local KEY="$1"
  set_state_val "last_fix_${KEY}" "$NOW_EPOCH"
  local COUNT=$(get_state_val "fix_count_${KEY}")
  COUNT=$((COUNT + 1))
  set_state_val "fix_count_${KEY}" "$COUNT"
}

# ── Escalation ──
escalate() {
  local SEVERITY="$1"
  local MSG="$2"
  wlog "ESCALATE" "[$SEVERITY] $MSG"
  echo "[$NOW] [$SEVERITY] $MSG" >> "$ESCALATION_LOG"

  # Try to send WhatsApp alert via gateway if available
  if curl -sf --max-time 3 http://127.0.0.1:18789/ >/dev/null 2>&1; then
    # Gateway is up — could send via webhook, but we don't auto-message
    # Just log it. The gateway agent can read escalation log on request.
    :
  fi
}

# ══════════════════════════════════════════
# CHECK FUNCTIONS
# ══════════════════════════════════════════

PROBLEMS=()
FIXES_APPLIED=()

check_ollama() {
  if curl -sf --max-time 5 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    wlog "OK" "Ollama: running"
  else
    wlog "FAIL" "Ollama: NOT running"
    PROBLEMS+=("ollama_down")
  fi
}

check_gateway() {
  # Gateway uninstalled — Claude Code is the primary executor now.
  wlog "OK" "Gateway: not needed (Claude Code is primary executor)"
  return
  if curl -sf --max-time 5 http://127.0.0.1:18789/ >/dev/null 2>&1; then
    wlog "OK" "Gateway: running on :18789"
  else
    wlog "FAIL" "Gateway: NOT responding on :18789"
    PROBLEMS+=("gateway_down")
  fi
}

check_sessions() {
  local EXPIRED=()
  for platform in linkedin x instagram discord; do
    local RESULT=$(/usr/bin/python3 "$ENGINE/post_${platform}.py" --check 2>&1)
    local EXIT=$?
    if [ $EXIT -ne 0 ] || echo "$RESULT" | grep -qi "EXPIRED\|ERROR\|not configured"; then
      EXPIRED+=("$platform")
    fi
  done

  if [ ${#EXPIRED[@]} -eq 0 ]; then
    wlog "OK" "Sessions: all valid"
  elif [ ${#EXPIRED[@]} -lt 4 ]; then
    wlog "WARN" "Sessions expired: ${EXPIRED[*]}"
    PROBLEMS+=("sessions_expired:${EXPIRED[*]}")
  else
    wlog "FAIL" "Sessions: ALL expired"
    PROBLEMS+=("all_sessions_expired")
  fi
}

check_queues() {
  local TOTAL_PENDING=0
  local TOTAL_APPROVED=0
  for platform in linkedin x discord instagram website email heygen; do
    local P=$(find "$QUEUES/$platform/pending" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
    local A=$(find "$QUEUES/$platform/approved" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
    TOTAL_PENDING=$((TOTAL_PENDING + P))
    TOTAL_APPROVED=$((TOTAL_APPROVED + A))
  done

  if [ "$TOTAL_PENDING" -gt 20 ]; then
    wlog "WARN" "Queue backlog: $TOTAL_PENDING pending items"
    PROBLEMS+=("queue_backlog:$TOTAL_PENDING")
  else
    wlog "OK" "Queues: $TOTAL_PENDING pending, $TOTAL_APPROVED approved"
  fi
}

check_pipeline() {
  local PIPELINE_LOG="$OCD/logs/daily-pipeline.log"
  if [ ! -f "$PIPELINE_LOG" ]; then
    wlog "WARN" "Pipeline: no log file found"
    PROBLEMS+=("pipeline_no_log")
    return
  fi

  # Check when pipeline last ran
  local LAST_RUN=$(grep "Publishing Engine Started\|Pipeline Started\|Distribution Engine Started" "$PIPELINE_LOG" 2>/dev/null | tail -1 | grep -oE '\[20[0-9]{2}-[0-9]{2}-[0-9]{2}' | tr -d '[')
  if [ -z "$LAST_RUN" ]; then
    LAST_RUN=$(stat -f "%Sm" -t "%Y-%m-%d" "$PIPELINE_LOG" 2>/dev/null)
  fi

  if [ -n "$LAST_RUN" ]; then
    local LAST_EPOCH=$(date -j -f "%Y-%m-%d" "$LAST_RUN" +%s 2>/dev/null || echo "0")
    local AGE_HOURS=$(( (NOW_EPOCH - LAST_EPOCH) / 3600 ))
    if [ "$AGE_HOURS" -gt 26 ]; then
      wlog "WARN" "Pipeline: last ran $AGE_HOURS hours ago (stale)"
      PROBLEMS+=("pipeline_stale:${AGE_HOURS}h")
    else
      wlog "OK" "Pipeline: last ran $AGE_HOURS hours ago"
    fi
  fi

  # Check for stage failures in last run
  local FAILURES=$(grep -c "FAILED\|exit code [1-9]" "$PIPELINE_LOG" 2>/dev/null | tail -1)
  if [ "$FAILURES" -gt 3 ]; then
    wlog "WARN" "Pipeline: $FAILURES failure entries in log"
  fi
}

check_posting_failures() {
  local LOG_FILE="$ANALYTICS/post-actions-${DATE}.jsonl"
  if [ ! -f "$LOG_FILE" ]; then
    wlog "OK" "Posting: no activity today"
    return
  fi

  local TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
  local FAILED=$(grep -c '"failed"' "$LOG_FILE" 2>/dev/null)
  local POSTED=$(grep -c '"posted"' "$LOG_FILE" 2>/dev/null)

  if [ "$FAILED" -gt 0 ] && [ "$POSTED" -eq 0 ]; then
    wlog "FAIL" "Posting: $FAILED failures, 0 successes today"
    PROBLEMS+=("posting_all_failing:$FAILED")
  elif [ "$FAILED" -gt "$POSTED" ]; then
    wlog "WARN" "Posting: $FAILED failures vs $POSTED successes"
    PROBLEMS+=("posting_high_failure:${FAILED}/${TOTAL}")
  else
    wlog "OK" "Posting: $POSTED posted, $FAILED failed today"
  fi
}

check_disk() {
  local AVAIL_KB=$(df -k "$WORKSPACE" 2>/dev/null | tail -1 | awk '{print $4}')
  local AVAIL_GB=$((AVAIL_KB / 1048576))
  if [ "$AVAIL_GB" -lt 5 ]; then
    wlog "FAIL" "Disk: only ${AVAIL_GB}GB free"
    PROBLEMS+=("disk_low:${AVAIL_GB}GB")
  else
    wlog "OK" "Disk: ${AVAIL_GB}GB free"
  fi
}

check_stale_content() {
  local STALE=0
  for platform in linkedin x discord instagram; do
    local COUNT=$(find "$QUEUES/$platform/approved" -type f -mtime +3 ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
    STALE=$((STALE + COUNT))
  done
  if [ "$STALE" -gt 0 ]; then
    wlog "WARN" "Stale content: $STALE items in approved/ older than 3 days"
    PROBLEMS+=("stale_content:$STALE")
  else
    wlog "OK" "Stale content: none"
  fi
}

check_zombie_playwright() {
  local ZOMBIES=$(pgrep -f "chromium.*--headless\|chrome.*--headless\|playwright" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$ZOMBIES" -gt 5 ]; then
    wlog "WARN" "Zombie Playwright: $ZOMBIES headless browser processes"
    PROBLEMS+=("zombie_playwright:$ZOMBIES")
  fi
}

# ══════════════════════════════════════════
# FIX FUNCTIONS
# ══════════════════════════════════════════

fix_ollama() {
  if ! check_cooldown "ollama" 300; then  # 5 min cooldown
    wlog "COOLDOWN" "Ollama restart skipped (cooldown active)"
    return 1
  fi
  wlog "FIX" "Restarting Ollama..."
  ollama serve &>/dev/null &
  sleep 10
  if curl -sf --max-time 5 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    wlog "FIXED" "Ollama restarted successfully"
    record_fix "ollama"
    FIXES_APPLIED+=("ollama_restarted")
    return 0
  else
    wlog "FAIL" "Ollama restart failed"
    return 1
  fi
}

fix_gateway() {
  if ! check_cooldown "gateway" 600; then  # 10 min cooldown
    wlog "COOLDOWN" "Gateway restart skipped (cooldown active)"
    return 1
  fi
  wlog "FIX" "Restarting Gateway..."
  pkill -f "openclaw.*gateway" 2>/dev/null
  sleep 3

  export PATH="/Users/reeturajgoswami/local/node/bin:$PATH"
  export HOME="/Users/reeturajgoswami"
  export GROQ_API_KEY=$(security find-generic-password -s "openclaw" -a "openclaw-groq-api-key" -w 2>/dev/null)
  export OPENCLAW_GATEWAY_PORT="18789"

  cd ~/.openclaw 2>/dev/null
  nohup /Users/reeturajgoswami/local/node/bin/node \
    /Users/reeturajgoswami/local/node/lib/node_modules/openclaw/dist/index.js \
    gateway --port 18789 > /tmp/openclaw-gateway.log 2>&1 &

  sleep 8
  if curl -sf --max-time 5 http://127.0.0.1:18789/ >/dev/null 2>&1; then
    wlog "FIXED" "Gateway restarted on :18789"
    record_fix "gateway"
    FIXES_APPLIED+=("gateway_restarted")
    cd "$WORKSPACE"
    return 0
  else
    wlog "FAIL" "Gateway restart failed"
    cd "$WORKSPACE"
    return 1
  fi
}

fix_sessions() {
  if ! check_cooldown "sessions" 21600; then  # 6 hour cooldown
    wlog "COOLDOWN" "Session refresh skipped (cooldown active)"
    return 1
  fi
  wlog "FIX" "Refreshing sessions via session-keepalive.sh..."
  if [ -x "$SCRIPTS/session-keepalive.sh" ]; then
    bash "$SCRIPTS/session-keepalive.sh" >> "$LOG_FILE" 2>&1
    record_fix "sessions"
    FIXES_APPLIED+=("sessions_refreshed")
    return 0
  else
    wlog "FAIL" "session-keepalive.sh not found"
    return 1
  fi
}

fix_zombie_playwright() {
  if ! check_cooldown "zombie" 120; then  # 2 min cooldown
    return 1
  fi
  wlog "FIX" "Killing zombie Playwright processes..."
  pkill -f "chromium.*--headless" 2>/dev/null
  pkill -f "chrome.*--remote-debugging.*--headless" 2>/dev/null
  # Don't kill the gateway's browser (port 18800)
  sleep 2
  record_fix "zombie"
  FIXES_APPLIED+=("zombies_killed")
}

fix_stale_content() {
  if ! check_cooldown "stale" 86400; then  # 24 hour cooldown
    return 1
  fi
  wlog "FIX" "Archiving stale approved content (>7 days)..."
  local MOVED=0
  for platform in linkedin x discord instagram; do
    local ARCHIVE="$QUEUES/$platform/archived"
    mkdir -p "$ARCHIVE"
    find "$QUEUES/$platform/approved" -type f -mtime +7 ! -name ".*" ! -name ".gitkeep" -print0 2>/dev/null | \
      while IFS= read -r -d '' f; do
        mv "$f" "$ARCHIVE/"
        MOVED=$((MOVED + 1))
      done
  done
  wlog "FIXED" "Archived stale items"
  record_fix "stale"
  FIXES_APPLIED+=("stale_archived")
}

fix_pipeline_retry() {
  if ! check_cooldown "pipeline" 86400; then  # 24 hour cooldown
    wlog "COOLDOWN" "Pipeline retry skipped (cooldown active)"
    return 1
  fi
  local HOUR=$(date '+%H')
  if [ "$HOUR" -lt 8 ]; then
    wlog "SKIP" "Pipeline retry skipped (before 8 AM)"
    return 1
  fi
  wlog "FIX" "Re-running daily pipeline..."
  bash "$SCRIPTS/daily-pipeline.sh" >> "$OCD/logs/watchdog-pipeline-retry.log" 2>&1 &
  record_fix "pipeline"
  FIXES_APPLIED+=("pipeline_retried")
}

# ══════════════════════════════════════════
# MAIN: CHECK → DIAGNOSE → FIX → REPORT
# ══════════════════════════════════════════

wlog "START" "━━━ Watchdog Agent Run ━━━"

# ── CHECK ──
check_ollama
check_gateway
check_sessions
check_queues
check_pipeline
check_posting_failures
check_disk
check_stale_content
check_zombie_playwright

# ── STATUS ONLY ──
if [ "$STATUS_ONLY" = true ]; then
  echo ""
  echo "━━━ WATCHDOG STATUS ━━━"
  echo "Problems: ${#PROBLEMS[@]}"
  for p in "${PROBLEMS[@]}"; do echo "  - $p"; done
  echo "Last run: $(get_state_val 'last_run')"
  exit 0
fi

# ── CHECK ONLY ──
if [ "$CHECK_ONLY" = true ]; then
  wlog "END" "Check-only mode. ${#PROBLEMS[@]} problems found."
  exit "${#PROBLEMS[@]}"
fi

# ── DIAGNOSE + FIX ──
if [ ${#PROBLEMS[@]} -eq 0 ]; then
  wlog "HEALTHY" "All checks passed. No action needed."
else
  wlog "DIAGNOSE" "${#PROBLEMS[@]} problems detected: ${PROBLEMS[*]}"

  for PROBLEM in "${PROBLEMS[@]}"; do
    case "$PROBLEM" in
      ollama_down)
        fix_ollama || escalate "HIGH" "Ollama won't restart after watchdog fix attempt"
        ;;
      gateway_down)
        fix_gateway || escalate "HIGH" "Gateway won't restart after watchdog fix attempt"
        ;;
      sessions_expired:*)
        fix_sessions || escalate "MEDIUM" "Session refresh failed: $PROBLEM"
        ;;
      all_sessions_expired)
        escalate "CRITICAL" "ALL platform sessions expired — manual re-login required for each platform"
        ;;
      queue_backlog:*)
        wlog "NOTE" "Queue backlog detected — will clear on next pipeline run"
        ;;
      pipeline_stale:*)
        fix_pipeline_retry || escalate "MEDIUM" "Pipeline hasn't run in >26h and retry failed"
        ;;
      posting_all_failing:*)
        escalate "HIGH" "All posting attempts failing today — check browser sessions and Playwright"
        ;;
      posting_high_failure:*)
        wlog "WARN" "High posting failure rate — monitoring"
        ;;
      disk_low:*)
        escalate "CRITICAL" "Disk space critically low: $PROBLEM"
        ;;
      stale_content:*)
        fix_stale_content
        ;;
      zombie_playwright:*)
        fix_zombie_playwright
        ;;
      pipeline_no_log)
        wlog "WARN" "No pipeline log — system may not have run yet"
        ;;
      *)
        wlog "UNKNOWN" "Unhandled problem: $PROBLEM"
        ;;
    esac
  done
fi

# ── REPORT ──
set_state_val "last_run" "$NOW"
set_state_val "last_problems" "${#PROBLEMS[@]}"
set_state_val "last_fixes" "${#FIXES_APPLIED[@]}"

wlog "END" "━━━ Watchdog Complete: ${#PROBLEMS[@]} problems, ${#FIXES_APPLIED[@]} fixes applied ━━━"

echo ""
echo "━━━ WATCHDOG SUMMARY ━━━"
echo "Problems:  ${#PROBLEMS[@]}"
echo "Fixes:     ${#FIXES_APPLIED[@]}"
for f in "${FIXES_APPLIED[@]}"; do echo "  Applied: $f"; done
echo ""

# Exit code: 0=healthy, 1=problems found (some fixed), 2=escalations needed
[ -s "$ESCALATION_LOG" ] && grep -q "$DATE" "$ESCALATION_LOG" 2>/dev/null && exit 2
[ ${#PROBLEMS[@]} -gt 0 ] && exit 1
exit 0
