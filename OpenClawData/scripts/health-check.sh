#!/bin/bash
# health-check.sh — Control plane visibility layer for OpenClaw CMO pipeline
# Usage: ./health-check.sh [--quiet] [--json]
# Output: Color-coded status for every component, logged to logs/health-check-YYYY-MM-DD.log
# Non-destructive, read-only checks. Target: under 10 seconds.

set -o pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
DATA_DIR="$WORKSPACE_ROOT/OpenClawData"
SCRIPTS_DIR="$DATA_DIR/scripts"
QUEUES_DIR="$DATA_DIR/queues"
APPROVALS_DIR="$DATA_DIR/approvals"
LOGS_DIR="$DATA_DIR/logs"
HANDOFFS_DIR="$DATA_DIR/inbharat-bot/handoffs"
DATE_TAG=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="$LOGS_DIR/health-check-${DATE_TAG}.log"

# Counters
GREEN=0
YELLOW=0
RED=0

# Flags
QUIET=false
JSON_OUT=false
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=true ;;
    --json)  JSON_OUT=true ;;
  esac
done

# Emoji-free fallback for piped output
G="🟢"
Y="🟡"
R="🔴"

results=()

status_green() {
  results+=("$G $1: $2")
  GREEN=$((GREEN + 1))
}
status_yellow() {
  results+=("$Y $1: $2")
  YELLOW=$((YELLOW + 1))
}
status_red() {
  results+=("$R $1: $2")
  RED=$((RED + 1))
}

# ── 1. Ollama ──────────────────────────────────────────────────────────────────
check_ollama() {
  if ! pgrep -x ollama >/dev/null 2>&1 && ! curl -sf http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    status_red "Ollama" "not running"
    return
  fi
  local models_json
  models_json=$(curl -sf --max-time 3 http://127.0.0.1:11434/api/tags 2>/dev/null)
  if [ -z "$models_json" ]; then
    status_red "Ollama" "running but API not responding"
    return
  fi
  local has_qwen3 has_coder
  has_qwen3=$(echo "$models_json" | grep -c 'qwen3:8b\|qwen3.*8b')
  has_coder=$(echo "$models_json" | grep -c 'qwen2.5-coder:7b\|qwen2\.5-coder.*7b')
  if [ "$has_qwen3" -gt 0 ] && [ "$has_coder" -gt 0 ]; then
    status_green "Ollama" "running (qwen3:8b, qwen2.5-coder:7b)"
  elif [ "$has_qwen3" -gt 0 ]; then
    status_yellow "Ollama" "running but missing qwen2.5-coder:7b"
  elif [ "$has_coder" -gt 0 ]; then
    status_yellow "Ollama" "running but missing qwen3:8b"
  else
    status_yellow "Ollama" "running but neither model found"
  fi
}

# ── 2. OpenClaw Gateway ───────────────────────────────────────────────────────
check_gateway() {
  local resp
  resp=$(curl -sf --max-time 3 http://127.0.0.1:18789/ 2>/dev/null)
  if [ $? -eq 0 ]; then
    status_green "Gateway" "running (port 18789)"
  else
    # Check if port is listening at all
    if lsof -i :18789 >/dev/null 2>&1; then
      status_yellow "Gateway" "port 18789 open but not responding to HTTP"
    else
      status_red "Gateway" "not running (port 18789)"
    fi
  fi
}

# ── 3. External Drive ────────────────────────────────────────────────────────
check_drive() {
  if [ ! -d "/Volumes/Expansion" ]; then
    status_red "External Drive" "/Volumes/Expansion not mounted"
    return
  fi
  # Test writability with a temp file
  local test_file="/Volumes/Expansion/.health-check-test-$$"
  if touch "$test_file" 2>/dev/null; then
    rm -f "$test_file"
    status_green "External Drive" "/Volumes/Expansion mounted and writable"
  else
    status_yellow "External Drive" "/Volumes/Expansion mounted but read-only"
  fi
}

# ── 4. LaunchAgents ──────────────────────────────────────────────────────────
check_launchagents() {
  local expected_plists=(
    "ai.openclaw.gateway"
    "com.openclaw.cmo.daily"
    "com.openclaw.cmo.weekly"
    "com.openclaw.cmo.monthly"
  )
  local loaded=0
  local missing=()
  for label in "${expected_plists[@]}"; do
    if launchctl list "$label" >/dev/null 2>&1; then
      loaded=$((loaded + 1))
    else
      missing+=("$label")
    fi
  done
  if [ $loaded -eq 4 ]; then
    status_green "LaunchAgents" "all 4 plists loaded"
  elif [ $loaded -gt 0 ]; then
    status_yellow "LaunchAgents" "$loaded/4 loaded, missing: ${missing[*]}"
  else
    status_red "LaunchAgents" "none loaded (${missing[*]})"
  fi
}

# ── 5. Queue Health ──────────────────────────────────────────────────────────
count_queue_files() {
  # Count real files (not .gitkeep, not ._ macOS resource forks) in a directory
  local dir="$1"
  if [ -d "$dir" ]; then
    find "$dir" -maxdepth 1 -type f ! -name '.gitkeep' ! -name '._*' ! -name '.DS_Store' 2>/dev/null | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

check_queues() {
  local total_pending=0 total_approved=0 total_ready=0 total_posted=0
  local platforms=(discord email facebook heygen instagram linkedin medium reddit substack website x shorts)
  for platform in "${platforms[@]}"; do
    local p=$(count_queue_files "$QUEUES_DIR/$platform/pending")
    local a=$(count_queue_files "$QUEUES_DIR/$platform/approved")
    local r=$(count_queue_files "$QUEUES_DIR/$platform/publish-ready")
    local d=$(count_queue_files "$QUEUES_DIR/$platform/posted")
    total_pending=$((total_pending + p))
    total_approved=$((total_approved + a))
    total_ready=$((total_ready + r))
    total_posted=$((total_posted + d))
  done
  local detail="${total_pending} pending, ${total_approved} approved, ${total_ready} ready, ${total_posted} posted"
  if [ "$total_pending" -gt 50 ]; then
    status_red "Queues" "$detail (QUEUE BACKUP)"
  elif [ "$total_pending" -gt 20 ]; then
    status_yellow "Queues" "$detail (growing backlog)"
  else
    status_green "Queues" "$detail"
  fi
}

# ── 6. Approval Health ───────────────────────────────────────────────────────
check_approvals() {
  local review_count=$(count_queue_files "$APPROVALS_DIR/review")
  local blocked_count=$(count_queue_files "$APPROVALS_DIR/blocked")
  local detail="${review_count} in review, ${blocked_count} blocked"
  if [ "$review_count" -gt 20 ]; then
    status_red "Approvals" "$detail (review overload)"
  elif [ "$review_count" -gt 10 ] || [ "$blocked_count" -gt 5 ]; then
    status_yellow "Approvals" "$detail (attention needed)"
  else
    status_green "Approvals" "$detail"
  fi
}

# ── 7. Log Health ────────────────────────────────────────────────────────────
check_logs() {
  local today_logs=0
  local today_errors=0
  # Check all log files for today's entries
  for logfile in "$LOGS_DIR"/*.log; do
    [ -f "$logfile" ] || continue
    local lines=$(grep -c "$DATE_TAG" "$logfile" 2>/dev/null | head -1 | tr -d '[:space:]')
    lines=${lines:-0}
    local errors=$(grep -i "$DATE_TAG" "$logfile" 2>/dev/null | grep -ic 'error\|fatal\|exception\|traceback\|panic' | head -1 | tr -d '[:space:]')
    errors=${errors:-0}
    today_logs=$((today_logs + lines))
    today_errors=$((today_errors + errors))
  done
  if [ "$today_logs" -eq 0 ]; then
    status_yellow "Log Health" "no log entries for today"
  else
    local error_pct=$((today_errors * 100 / today_logs))
    if [ "$error_pct" -gt 10 ]; then
      status_red "Log Health" "${today_errors} errors in ${today_logs} entries (${error_pct}% error rate)"
    elif [ "$today_errors" -gt 0 ]; then
      status_yellow "Log Health" "${today_errors} errors in ${today_logs} entries (${error_pct}%)"
    else
      status_green "Log Health" "${today_logs} entries, 0 errors"
    fi
  fi
}

# ── 8. Disk Space ────────────────────────────────────────────────────────────
check_disk() {
  local avail_kb
  avail_kb=$(df -k /Volumes/Expansion 2>/dev/null | tail -1 | awk '{print $4}')
  if [ -z "$avail_kb" ]; then
    status_red "Disk Space" "cannot read /Volumes/Expansion"
    return
  fi
  local avail_gb=$((avail_kb / 1024 / 1024))
  local avail_mb=$((avail_kb / 1024))
  if [ "$avail_gb" -ge 50 ]; then
    status_green "Disk Space" "${avail_gb}GB free on /Volumes/Expansion"
  elif [ "$avail_gb" -ge 10 ]; then
    status_yellow "Disk Space" "${avail_gb}GB free (getting low)"
  else
    status_red "Disk Space" "${avail_mb}MB free (critically low)"
  fi
}

# ── 9. Stale Content ────────────────────────────────────────────────────────
check_stale() {
  local stale_count=0
  # Find queue items older than 7 days
  if [ -d "$QUEUES_DIR" ]; then
    stale_count=$(find "$QUEUES_DIR" -type f -name '*.json' -o -name '*.md' 2>/dev/null | while read f; do
      [ "$(basename "$f")" = ".gitkeep" ] && continue
      [[ "$(basename "$f")" == ._* ]] && continue
      if [ "$(find "$f" -mtime +7 2>/dev/null)" ]; then
        echo "stale"
      fi
    done | wc -l | tr -d ' ')
  fi
  if [ "$stale_count" -gt 10 ]; then
    status_red "Stale Content" "${stale_count} queue items older than 7 days"
  elif [ "$stale_count" -gt 0 ]; then
    status_yellow "Stale Content" "${stale_count} queue items older than 7 days"
  else
    status_green "Stale Content" "no stale items"
  fi
}

# ── 10. Secret Safety ───────────────────────────────────────────────────────
check_secrets() {
  local violations=()
  # Check all .sh files and .plist files for hardcoded secrets
  local search_dirs=("$DATA_DIR" "$WORKSPACE_ROOT")
  for dir in "${search_dirs[@]}"; do
    while IFS= read -r match; do
      [ -n "$match" ] && violations+=("$match")
    done < <(grep -rl --include='*.sh' --include='*.plist' --include='*.json' \
      -E '(gsk_[a-zA-Z0-9]{20,}|sk-[a-zA-Z0-9]{20,}|Bearer [a-zA-Z0-9]{20,}|api_key=[a-zA-Z0-9]{20,}|APIKEY=[a-zA-Z0-9]{10,}|password=[^\$\{][a-zA-Z0-9]{8,})' \
      "$dir" 2>/dev/null | head -10)
  done
  # Deduplicate
  local unique_violations=($(printf '%s\n' "${violations[@]}" | sort -u))
  if [ ${#unique_violations[@]} -gt 0 ]; then
    local files_list=""
    for v in "${unique_violations[@]}"; do
      local short="${v#$WORKSPACE_ROOT/}"
      files_list="${files_list}${short}, "
    done
    files_list="${files_list%, }"
    status_red "Secrets" "found plaintext key in: ${files_list}"
  else
    status_green "Secrets" "no hardcoded keys detected"
  fi
}

# ── 11. Script Integrity ────────────────────────────────────────────────────
check_scripts() {
  local critical_scripts=(
    "daily-pipeline.sh"
    "weekly-pipeline.sh"
    "monthly-pipeline.sh"
    "content-agent.sh"
    "distribution-engine.sh"
    "approval-engine.sh"
    "intake-processor.sh"
    "skill-runner.sh"
    "model-router.sh"
    "newsroom-agent.sh"
  )
  local missing=()
  local not_exec=()
  for script in "${critical_scripts[@]}"; do
    local path="$SCRIPTS_DIR/$script"
    if [ ! -f "$path" ]; then
      missing+=("$script")
    elif [ ! -x "$path" ]; then
      not_exec+=("$script")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    status_red "Scripts" "missing: ${missing[*]}"
  elif [ ${#not_exec[@]} -gt 0 ]; then
    status_yellow "Scripts" "not executable: ${not_exec[*]}"
  else
    status_green "Scripts" "all ${#critical_scripts[@]} critical scripts present and executable"
  fi
}

# ── 12. Model Usage ─────────────────────────────────────────────────────────
check_model_usage() {
  local usage_file="$LOGS_DIR/model-usage-${DATE_TAG}.jsonl"
  if [ ! -f "$usage_file" ]; then
    status_yellow "Model Usage" "no usage log for today"
    return
  fi
  local total_calls=$(wc -l < "$usage_file" | tr -d ' ')
  # Summarize by model
  local summary=""
  if command -v jq >/dev/null 2>&1; then
    summary=$(jq -r '.model' "$usage_file" 2>/dev/null | sort | uniq -c | sort -rn | head -5 | while read count model; do
      echo "${model}:${count}"
    done | tr '\n' ', ' | sed 's/, $//')
  else
    summary=$(grep -o '"model":"[^"]*"' "$usage_file" | sed 's/"model":"//;s/"//' | sort | uniq -c | sort -rn | head -5 | while read count model; do
      echo "${model}:${count}"
    done | tr '\n' ', ' | sed 's/, $//')
  fi
  if [ "$total_calls" -eq 0 ]; then
    status_yellow "Model Usage" "0 calls today"
  else
    status_green "Model Usage" "${total_calls} calls today (${summary})"
  fi
}

# ── 13. Pipeline Last Run ───────────────────────────────────────────────────
check_pipeline_runs() {
  local details=()
  for pipeline in daily weekly monthly; do
    local logfile="$LOGS_DIR/${pipeline}-pipeline.log"
    if [ -f "$logfile" ]; then
      local last_run=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$logfile" | tail -1)
      if [ -n "$last_run" ]; then
        details+=("${pipeline}:${last_run}")
      else
        details+=("${pipeline}:never")
      fi
    else
      details+=("${pipeline}:no-log")
    fi
  done
  local detail_str=$(printf '%s, ' "${details[@]}")
  detail_str="${detail_str%, }"
  # Check if daily ran today
  local daily_last=$(echo "$detail_str" | sed -n 's/.*daily:\([0-9-]*\).*/\1/p')
  if [ "$daily_last" = "$DATE_TAG" ]; then
    status_green "Pipeline Runs" "$detail_str"
  elif [ -n "$daily_last" ]; then
    status_yellow "Pipeline Runs" "$detail_str (daily not yet run today)"
  else
    status_red "Pipeline Runs" "$detail_str"
  fi
}

# ── 14. Dependencies ────────────────────────────────────────────────────────
check_dependencies() {
  local missing=()
  for cmd in python3 jq curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    status_red "Dependencies" "missing: ${missing[*]}"
  else
    local py_ver=$(python3 --version 2>&1 | head -1)
    local jq_ver=$(jq --version 2>&1 | head -1)
    status_green "Dependencies" "python3, jq, curl available ($py_ver, $jq_ver)"
  fi
}

# ── 15. Handoffs ─────────────────────────────────────────────────────────────
check_handoffs() {
  local unprocessed=0
  local old_handoffs=()
  if [ -d "$HANDOFFS_DIR" ]; then
    while IFS= read -r hfile; do
      [ -z "$hfile" ] && continue
      local basename=$(basename "$hfile")
      [[ "$basename" == ._* ]] && continue
      [[ "$basename" == .gitkeep ]] && continue
      [[ "$basename" == README* ]] && continue
      # Check if older than 2 days
      if [ -n "$(find "$hfile" -mtime +2 2>/dev/null)" ]; then
        old_handoffs+=("$basename")
      fi
      unprocessed=$((unprocessed + 1))
    done < <(find "$HANDOFFS_DIR" -maxdepth 1 -type f 2>/dev/null)
  fi
  if [ ${#old_handoffs[@]} -gt 0 ]; then
    status_yellow "Handoffs" "${#old_handoffs[@]} unprocessed handoffs older than 2 days"
  elif [ "$unprocessed" -gt 0 ]; then
    status_green "Handoffs" "${unprocessed} pending handoffs (none stale)"
  else
    status_green "Handoffs" "no unprocessed handoffs"
  fi
}

# ── Run all checks ──────────────────────────────────────────────────────────
check_ollama
check_gateway
check_drive
check_launchagents
check_queues
check_approvals
check_logs
check_disk
check_stale
check_secrets
check_scripts
check_model_usage
check_pipeline_runs
check_dependencies
check_handoffs

# ── Output ──────────────────────────────────────────────────────────────────
output() {
  echo ""
  echo "━━━ OPENCLAW HEALTH CHECK ━━━"
  echo "Date: $TIMESTAMP"
  echo ""
  for line in "${results[@]}"; do
    echo "$line"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Summary: $GREEN green, $YELLOW yellow, $RED red"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# Print to stdout unless --quiet
if [ "$QUIET" = false ]; then
  output
fi

# Always write to log file
mkdir -p "$LOGS_DIR"
output >> "$LOG_FILE"

# Exit code: 0=all green, 1=warnings, 2=critical
if [ "$RED" -gt 0 ]; then
  exit 2
elif [ "$YELLOW" -gt 0 ]; then
  exit 1
else
  exit 0
fi
