#!/bin/bash
# InBharat Bot — Master Orchestrator
# Runs the full intelligence cycle: scan → analyze → propose → bridge → report
# Usage: ./inbharat-run.sh [full|scan|analyze|propose|bridge|status]

set -euo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
source "$BOT_ROOT/logging/bot-logger.sh"

MODE="${1:-full}"

bot_log "orchestrator" "info" "=== InBharat Bot started — mode: $MODE ==="

run_scan() {
  bot_log "orchestrator" "info" "→ Running ecosystem scanner..."
  bash "$BOT_ROOT/scanner/ecosystem-scanner.sh"
}

run_analyze() {
  bot_log "orchestrator" "info" "→ Running gap finder..."
  bash "$BOT_ROOT/gap-finder/gap-finder.sh"
}

run_propose() {
  bot_log "orchestrator" "info" "→ Running proposal generator..."
  bash "$BOT_ROOT/proposal-generator/proposal-generator.sh"
}

run_bridge() {
  bot_log "orchestrator" "info" "→ Running CMO bridge..."
  bash "$BOT_ROOT/cmo-bridge/cmo-bridge.sh"
}

run_status() {
  bot_log "orchestrator" "info" "→ Generating dashboard state..."
  bash "$BOT_ROOT/dashboard/generate-state.sh"
}

case "$MODE" in
  full)
    run_scan
    run_analyze
    run_propose
    run_bridge
    run_status
    ;;
  scan)
    run_scan
    ;;
  analyze)
    run_analyze
    ;;
  propose)
    run_propose
    ;;
  bridge)
    run_bridge
    ;;
  status)
    run_status
    ;;
  *)
    echo "Usage: $0 [full|scan|analyze|propose|bridge|status]"
    exit 1
    ;;
esac

bot_log "orchestrator" "info" "=== InBharat Bot completed — mode: $MODE ==="
echo ""
echo "=== InBharat Bot run complete ($MODE) ==="
