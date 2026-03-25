#!/bin/bash
# InBharat Bot — Logging Layer
# Every action logs here with timestamp, module, level, and message.
# Usage: source bot-logger.sh; bot_log "scanner" "info" "Scan started"

LOG_DIR="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot/logging"
LOG_FILE="$LOG_DIR/bot-$(date +%Y-%m-%d).log"

bot_log() {
  local module="$1"
  local level="$2"
  local message="$3"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local entry="[$timestamp] [$level] [$module] $message"
  echo "$entry" >> "$LOG_FILE"
  # Also print to stdout for pipeline visibility
  echo "$entry"
}

bot_log_evidence() {
  local module="$1"
  local action="$2"
  local evidence_file="$3"
  local status="$4"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local entry="[$timestamp] [evidence] [$module] action=$action file=$evidence_file status=$status"
  echo "$entry" >> "$LOG_FILE"
  echo "$entry"
}
