#!/bin/bash
# InBharat Bot — Master Orchestrator
# Founder's right-hand AI operator
# Usage: ./inbharat-run.sh <mode> [args...]
#
# Intelligence modes:
#   full      — Complete cycle: scan → analyze → propose → bridge → status
#   scan      — Ecosystem scanning
#   analyze   — Gap analysis
#   propose   — Build proposals
#   bridge    — Feed proposals to CMO pipeline
#   status    — System dashboard
#
# Revenue modes:
#   leads              — Show lead pipeline status
#   leads capture <text> — Capture and qualify a new lead
#   revenue            — Revenue pipeline status
#   revenue process    — Process hot leads → generate proposals
#   revenue followups  — Check follow-up queue
#
# Outreach modes:
#   outreach draft <context> — Draft outreach email
#   outreach track           — Show outreach log
#
# Opportunity modes:
#   opportunities      — Mine opportunities from ecosystem data
#   competitors        — Competitor analysis

set -euo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
SCRIPTS_DIR="/Volumes/Expansion/CMO-10million/OpenClawData/scripts"
source "$BOT_ROOT/logging/bot-logger.sh"

MODE="${1:-status}"
shift 2>/dev/null || true

# Dependency checks
for DEP in jq curl bash; do
  if ! command -v "$DEP" >/dev/null 2>&1; then
    echo "FATAL: Required command '$DEP' not found."
    exit 1
  fi
done

if [ ! -d "$BOT_ROOT" ]; then
  echo "FATAL: Bot root not found at $BOT_ROOT"
  exit 1
fi

bot_log "orchestrator" "info" "=== InBharat Bot — mode: $MODE ==="

# ── Intelligence modules ──

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
  bot_log "orchestrator" "info" "→ Generating dashboard..."
  bash "$BOT_ROOT/dashboard/generate-state.sh"
}

# ── Revenue modules ──

run_leads() {
  local SUBCMD="${1:-status}"
  case "$SUBCMD" in
    status)
      bot_log "orchestrator" "info" "→ Lead pipeline status..."
      local COUNT=$(find "$BOT_ROOT/leads/data" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
      echo "━━━ LEAD PIPELINE ━━━"
      echo "Total leads: $COUNT"
      for f in "$BOT_ROOT/leads/data"/*.json; do
        [ ! -f "$f" ] && continue
        local LID=$(python3 -c "import json; print(json.load(open('$f')).get('lead_id','?'))" 2>/dev/null)
        local QUAL=$(python3 -c "import json; print(json.load(open('$f')).get('qualification','?'))" 2>/dev/null)
        local ACT=$(python3 -c "import json; print(json.load(open('$f')).get('suggested_action','?'))" 2>/dev/null)
        echo "  $LID | $QUAL | $ACT"
      done
      ;;
    capture)
      local TEXT="$*"
      if [ -z "$TEXT" ]; then
        echo "Usage: inbharat-run.sh leads capture <description>"
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Capturing lead..."
      bash "$BOT_ROOT/leads/lead-capture.sh" "manual" "$TEXT"
      ;;
    *)
      echo "Usage: leads [status|capture <text>]"
      exit 1
      ;;
  esac
}

run_revenue() {
  local SUBCMD="${1:-status}"
  case "$SUBCMD" in
    status)
      bash "$BOT_ROOT/revenue/revenue-engine.sh" --status
      ;;
    process)
      bash "$BOT_ROOT/revenue/revenue-engine.sh" --process-leads
      ;;
    followups)
      bash "$BOT_ROOT/revenue/revenue-engine.sh" --follow-ups
      ;;
    *)
      echo "Usage: revenue [status|process|followups]"
      exit 1
      ;;
  esac
}

# ── Outreach modules ──

run_outreach() {
  local SUBCMD="${1:-track}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    draft)
      local CONTEXT="$*"
      if [ -z "$CONTEXT" ]; then
        echo "Usage: outreach draft <context>"
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Drafting outreach..."
      if [ -f "$BOT_ROOT/outreach/outreach-drafter.sh" ]; then
        bash "$BOT_ROOT/outreach/outreach-drafter.sh" "$CONTEXT"
      else
        echo "outreach-drafter.sh not yet built. Coming in Phase 2."
      fi
      ;;
    send)
      local DRAFT_FILE="${1:-}"
      local RECIPIENT="${2:-}"
      if [ -z "$DRAFT_FILE" ] || [ -z "$RECIPIENT" ]; then
        echo "Usage: outreach send <draft-file> <recipient-email>"
        echo ""
        bash "$BOT_ROOT/outreach/mail-sender.sh"
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Sending email: $DRAFT_FILE → $RECIPIENT"
      bash "$BOT_ROOT/outreach/mail-sender.sh" "$DRAFT_FILE" "$RECIPIENT"
      ;;
    track)
      local TRACK_MODE="${1:-today}"
      shift 2>/dev/null || true
      bash "$BOT_ROOT/outreach/outreach-tracker.sh" "$TRACK_MODE"
      ;;
    setup)
      echo "━━━ MAIL SETUP ━━━"
      echo ""
      if [ -f "$BOT_ROOT/config/.mail-credentials" ]; then
        echo "✅ Credentials file exists"
        source "$BOT_ROOT/config/.mail-credentials"
        echo "   SMTP: ${SMTP_HOST:-not set}:${SMTP_PORT:-not set}"
        echo "   User: ${SMTP_USER:-not set}"
        echo "   From: ${FROM_NAME:-not set} <${FROM_EMAIL:-not set}>"
      else
        echo "❌ No credentials configured"
        echo ""
        echo "Run this to set up:"
        echo "  cat > $BOT_ROOT/config/.mail-credentials << 'CREDS'"
        echo '  SMTP_HOST="smtp.zoho.in"'
        echo '  SMTP_PORT="587"'
        echo '  SMTP_USER="your@zoho.com"'
        echo '  SMTP_PASS="your-app-password"'
        echo '  FROM_NAME="Reeturaj Goswami"'
        echo '  FROM_EMAIL="your@zoho.com"'
        echo "  CREDS"
      fi
      ;;
    *)
      echo "Usage: outreach [draft|send|track|setup]"
      echo ""
      echo "  draft <context>              Draft an email"
      echo "  send <draft-file> <email>    Send a draft via SMTP"
      echo "  track [today|week|stats]     View outreach activity"
      echo "  setup                        Check mail credentials"
      exit 1
      ;;
  esac
}

# ── Opportunity modules ──

run_opportunities() {
  local SUBCMD="${1:-all}"
  shift 2>/dev/null || true
  bot_log "orchestrator" "info" "→ World scanner: $SUBCMD..."
  case "$SUBCMD" in
    all|government|corporate|global|grants)
      bash "$BOT_ROOT/opportunities/world-scanner.sh" "$SUBCMD"
      ;;
    custom)
      local QUERY="$*"
      if [ -z "$QUERY" ]; then
        echo "Usage: opportunities custom \"your search query\""
        exit 1
      fi
      bash "$BOT_ROOT/opportunities/world-scanner.sh" custom "$QUERY"
      ;;
    *)
      echo "Usage: opportunities [all|government|corporate|global|grants|custom \"query\"]"
      exit 1
      ;;
  esac
}

run_competitors() {
  bot_log "orchestrator" "info" "→ Competitor scan via world scanner..."
  bash "$BOT_ROOT/opportunities/world-scanner.sh" custom "AI competitors India education government personal assistant edtech 2026"
}

# ── Government modules ──

run_government() {
  local SUBCMD="${1:-scan}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    scan)
      bot_log "orchestrator" "info" "→ Government opportunity scan..."
      bash "$BOT_ROOT/opportunities/world-scanner.sh" government
      ;;
    propose)
      local SCHEME="$*"
      if [ -z "$SCHEME" ]; then
        echo "Usage: government propose <scheme-name>"
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Government proposal: $SCHEME..."
      bash "$BOT_ROOT/outreach/outreach-drafter.sh" "government proposal for $SCHEME — formal, credentials-led, reference InBharat AI products and alignment with scheme objectives"
      ;;
    *)
      echo "Usage: government [scan|propose <scheme>]"
      exit 1
      ;;
  esac
}

# ── Prototype modules ──

run_prototype() {
  local SUBCMD="${1:-list}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    build)
      local PROBLEM="$*"
      if [ -z "$PROBLEM" ]; then
        echo "Usage: prototype build \"<problem description>\""
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Building prototype: $PROBLEM"
      bash "$BOT_ROOT/prototypes/prototype-builder.sh" "$PROBLEM"
      ;;
    launch)
      local BUILD_DIR="$1"
      if [ -z "$BUILD_DIR" ]; then
        echo "Usage: prototype launch <build-directory>"
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Launching: $BUILD_DIR"
      bash "$BOT_ROOT/prototypes/launcher.sh" "$BUILD_DIR" --local
      ;;
    package)
      local BUILD_DIR="$1"
      if [ -z "$BUILD_DIR" ]; then
        echo "Usage: prototype package <build-directory>"
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Packaging: $BUILD_DIR"
      bash "$BOT_ROOT/prototypes/launcher.sh" "$BUILD_DIR" --package
      ;;
    pipeline)
      local SCAN_MODE="${1:-buildable}"
      shift 2>/dev/null || true
      local QUERY="$*"
      bot_log "orchestrator" "info" "→ Scout-Build-Launch pipeline: $SCAN_MODE"
      if [ "$SCAN_MODE" = "custom" ] && [ -n "$QUERY" ]; then
        bash "$BOT_ROOT/prototypes/scout-build-launch.sh" custom "$QUERY"
      else
        bash "$BOT_ROOT/prototypes/scout-build-launch.sh" "$SCAN_MODE"
      fi
      ;;
    list)
      echo "━━━ PROTOTYPES ━━━"
      echo ""
      echo "Builds:"
      for d in "$BOT_ROOT/prototypes/builds"/*/; do
        [ ! -d "$d" ] && continue
        FILES=$(ls "$d" | grep -v '_raw-response.md' | wc -l | tr -d ' ')
        echo "  $(basename "$d") ($FILES files)"
      done
      echo ""
      if [ -f "$BOT_ROOT/prototypes/log/builds-$(date +%Y-%m-%d).jsonl" ]; then
        echo "Today's builds:"
        cat "$BOT_ROOT/prototypes/log/builds-$(date +%Y-%m-%d).jsonl" | jq -r '"  \(.time) | \(.problem[:60]) | \(.status)"' 2>/dev/null
      fi
      ;;
    *)
      echo "Usage: prototype [build|launch|package|pipeline|list]"
      exit 1
      ;;
  esac
}

# ── Main routing ──

case "$MODE" in
  full)
    run_scan
    run_analyze
    run_propose
    run_bridge
    run_status
    ;;
  scan)       run_scan ;;
  analyze)    run_analyze ;;
  propose)    run_propose ;;
  bridge)     run_bridge ;;
  status)     run_status ;;
  leads)      run_leads "$@" ;;
  revenue)    run_revenue "$@" ;;
  outreach)   run_outreach "$@" ;;
  opportunities) run_opportunities "$@" ;;
  competitors)   run_competitors ;;
  government)    run_government "$@" ;;
  prototype)     run_prototype "$@" ;;
  *)
    echo "━━━ InBharat Bot ━━━"
    echo ""
    echo "Intelligence:"
    echo "  full        Complete cycle (scan→analyze→propose→bridge→status)"
    echo "  scan        Ecosystem scan"
    echo "  analyze     Gap analysis"
    echo "  propose     Build proposals"
    echo "  bridge      Feed to CMO pipeline"
    echo "  status      System dashboard"
    echo ""
    echo "Revenue:"
    echo "  leads [status|capture <text>]"
    echo "  revenue [status|process|followups]"
    echo ""
    echo "Outreach:"
    echo "  outreach draft <context>      Draft outreach email"
    echo "  outreach send <file> <email>  Send a draft via SMTP"
    echo "  outreach track [today|week|all|stats]"
    echo "  outreach setup                Check mail config"
    echo ""
    echo "World Scanner:"
    echo "  opportunities [all|government|corporate|global|grants|problems|projects|buildable]"
    echo "  opportunities custom \"<query>\"  Custom search"
    echo "  competitors                     AI competitor scan"
    echo "  government scan                 Government opportunity scan"
    echo "  government propose <scheme>     Draft government proposal"
    echo ""
    echo "Prototypes:"
    echo "  prototype build \"<problem>\"    Build a working prototype"
    echo "  prototype launch <dir>          Launch locally"
    echo "  prototype package <dir>         Package for deployment"
    echo "  prototype pipeline [mode]       Full: scan → pick → build → launch"
    echo "  prototype list                  Show all prototypes"
    echo ""
    exit 0
    ;;
esac

bot_log "orchestrator" "info" "=== InBharat Bot complete — $MODE ==="
