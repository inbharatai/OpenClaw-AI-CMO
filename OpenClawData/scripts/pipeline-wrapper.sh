#!/bin/bash
# pipeline-wrapper.sh — Safe launcher for CMO pipeline scripts
# Checks external drive availability before running pipeline.
# Usage: pipeline-wrapper.sh <daily|weekly|monthly>
#
# Called by LaunchAgent plists instead of running scripts directly.

set -o pipefail

DRIVE="/Volumes/Expansion"
WORKSPACE="$DRIVE/CMO-10million"
SCRIPTS_DIR="$WORKSPACE/OpenClawData/scripts"
LOGS_DIR="$WORKSPACE/OpenClawData/logs"
PIPELINE="${1:-}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check drive is mounted
if [ ! -d "$DRIVE" ]; then
  log "ERROR: External drive not mounted at $DRIVE. Pipeline '$PIPELINE' skipped." >&2
  # Try to log to a local fallback
  mkdir -p "$HOME/.openclaw/logs"
  log "ERROR: External drive not mounted. Pipeline '$PIPELINE' skipped." >> "$HOME/.openclaw/logs/pipeline-errors.log"
  exit 1
fi

# Check workspace exists
if [ ! -d "$WORKSPACE" ]; then
  log "ERROR: Workspace not found at $WORKSPACE. Pipeline '$PIPELINE' skipped." >&2
  exit 1
fi

# Check Ollama is running (pipelines need it)
if ! curl -sf --max-time 5 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  log "WARNING: Ollama not running. Pipeline may fail on inference tasks." >&2
fi

# Route to the correct pipeline
case "$PIPELINE" in
  daily)   SCRIPT="$SCRIPTS_DIR/daily-pipeline.sh" ;;
  weekly)  SCRIPT="$SCRIPTS_DIR/weekly-pipeline.sh" ;;
  monthly) SCRIPT="$SCRIPTS_DIR/monthly-pipeline.sh" ;;
  *)
    log "ERROR: Unknown pipeline '$PIPELINE'. Use: daily|weekly|monthly" >&2
    exit 1
    ;;
esac

if [ ! -f "$SCRIPT" ]; then
  log "ERROR: Script not found: $SCRIPT" >&2
  exit 1
fi

cd "$WORKSPACE" || exit 1
log "Starting $PIPELINE pipeline"
exec bash "$SCRIPT" 2>&1
