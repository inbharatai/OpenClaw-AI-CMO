#!/bin/bash
# InBharat Bot — Logging Layer
# Usage: source bot-logger.sh; bot_log "scanner" "info" "Scan started"

LOG_DIR="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot/logging"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/bot-$(date +%Y-%m-%d).log"

bot_log() {
  local module="${1:-unknown}"
  local level="${2:-info}"
  local message="${3:-}"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local entry="[$timestamp] [$level] [$module] $message"
  echo "$entry" >> "$LOG_FILE" 2>/dev/null || true
  echo "$entry"
}

bot_log_evidence() {
  local module="${1:-unknown}"
  local action="${2:-unknown}"
  local evidence_file="${3:-}"
  local status="${4:-unknown}"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local entry="[$timestamp] [evidence] [$module] action=$action file=$evidence_file status=$status"
  echo "$entry" >> "$LOG_FILE" 2>/dev/null || true
  echo "$entry"
}
