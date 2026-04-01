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
#   outreach research <company>              — Research a VC/company target
#   outreach campaign <template> <lead-file> — Draft campaign emails
#   outreach followup [--days 7]             — Follow up unreplied emails
#   outreach leads [name]                    — List lead databases
#   outreach status                          — Pipeline status
#   outreach draft <context>                 — Draft freeform email
#   outreach send <file> <email>             — Send approved draft
#   outreach track                           — Show outreach log
#
# Community modes:
#   community scan         — Run community intelligence scan
#   community engagement   — Check community engagement signals
#   community suggest      — Get content suggestions for community channels
#   community list         — Show recent community reports
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
  shift 2>/dev/null || true
  case "$SUBCMD" in
    status)
      bot_log "orchestrator" "info" "→ Lead pipeline status..."
      local COUNT=$(find "$BOT_ROOT/leads/data" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
      echo "━━━ LEAD PIPELINE ━━━"
      echo "Total leads: $COUNT"
      for f in "$BOT_ROOT/leads/data"/*.json; do
        [ ! -f "$f" ] && continue
        [[ "$(basename "$f")" == ._* ]] && continue
        # Safe JSON parsing via jq (no injection risk)
        local LID=$(jq -r '.lead_id // "?"' "$f" 2>/dev/null)
        local QUAL=$(jq -r '.qualification // "?"' "$f" 2>/dev/null)
        local ACT=$(jq -r '.suggested_action // "?"' "$f" 2>/dev/null)
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
  local SUBCMD="${1:-help}"
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
        echo "outreach-drafter.sh not found."
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
      bash "$BOT_ROOT/outreach/outreach-engine.sh" send "$DRAFT_FILE" "$RECIPIENT"
      ;;
    research)
      local TARGET="$*"
      if [ -z "$TARGET" ]; then
        echo "Usage: outreach research \"<company or VC name>\""
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Researching: $TARGET"
      bash "$BOT_ROOT/outreach/outreach-engine.sh" research "$TARGET"
      ;;
    campaign)
      local TEMPLATE="${1:-}"
      local LEAD_FILE="${2:-}"
      shift 2 2>/dev/null || true
      if [ -z "$TEMPLATE" ] || [ -z "$LEAD_FILE" ]; then
        echo "Usage: outreach campaign <template> <lead-file> [--dry-run] [--limit N]"
        echo ""
        echo "Templates:"
        for t in "$BOT_ROOT/outreach/templates"/*.md; do
          [ -f "$t" ] && echo "  $(basename "$t" .md)"
        done
        echo ""
        echo "Lead files:"
        for l in "$BOT_ROOT/outreach/leads"/*.json; do
          [ -f "$l" ] && echo "  $(basename "$l")"
        done
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Campaign: $TEMPLATE → $LEAD_FILE"
      bash "$BOT_ROOT/outreach/outreach-engine.sh" campaign "$TEMPLATE" "$LEAD_FILE" "$@"
      ;;
    followup)
      bot_log "orchestrator" "info" "→ Generating follow-ups..."
      bash "$BOT_ROOT/outreach/outreach-engine.sh" followup "$@"
      ;;
    leads)
      local FILTER="${1:-all}"
      bash "$BOT_ROOT/outreach/outreach-engine.sh" leads "$FILTER"
      ;;
    status)
      bash "$BOT_ROOT/outreach/outreach-engine.sh" status
      ;;
    track)
      local TRACK_MODE="${1:-today}"
      shift 2>/dev/null || true
      bash "$BOT_ROOT/outreach/outreach-tracker.sh" "$TRACK_MODE"
      ;;
    setup)
      echo "━━━ MAIL SETUP ━━━"
      echo ""
      # Check Keychain first
      local KC_USER
      KC_USER=$(security find-generic-password -s "openclaw" -a "openclaw-smtp-user" -w 2>/dev/null)
      if [ -n "$KC_USER" ]; then
        echo "Keychain: SMTP user configured ($KC_USER)"
      elif [ -f "$BOT_ROOT/config/.mail-credentials" ]; then
        echo "Credentials file exists"
        source "$BOT_ROOT/config/.mail-credentials"
        echo "   SMTP: ${SMTP_HOST:-not set}:${SMTP_PORT:-not set}"
        echo "   User: ${SMTP_USER:-not set}"
        echo "   From: ${FROM_NAME:-not set} <${FROM_EMAIL:-not set}>"
      else
        echo "No credentials configured"
        echo ""
        echo "Option 1 (recommended): Store in macOS Keychain:"
        echo "  security add-generic-password -s openclaw -a openclaw-smtp-user -w 'your@zoho.com'"
        echo "  security add-generic-password -s openclaw -a openclaw-smtp-pass -w 'your-app-password'"
        echo ""
        echo "Option 2: Create $BOT_ROOT/config/.mail-credentials"
      fi
      ;;
    *)
      echo "Usage: outreach [research|draft|campaign|send|followup|leads|status|track|setup]"
      echo ""
      echo "  Outreach Engine (investor/VC/partner pipeline):"
      echo "    research \"<company>\"                      Research a target"
      echo "    campaign <template> <lead-file> [--dry-run] [--limit N]"
      echo "                                               Draft campaign emails"
      echo "    followup [--days 7]                         Follow up on unreplied emails"
      echo "    leads [vc-india|vc-global|companies-ai|accelerators]"
      echo "                                               List lead databases"
      echo "    status                                     Pipeline status"
      echo ""
      echo "  Email Operations:"
      echo "    draft <context>                            Draft a freeform email"
      echo "    send <draft-file> <email>                  Send an approved draft"
      echo "    track [today|week|stats]                   View outreach activity"
      echo "    setup                                      Check mail credentials"
      exit 1
      ;;
  esac
}

# ── Intelligence lanes (new) ──

run_india_problems() {
  local SUBCMD="${1:-scan}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    scan)
      bot_log "orchestrator" "info" "→ India problem scan..."
      bash "$BOT_ROOT/lane-runner.sh" india-problem-scanner \
        --search "India problems AI can solve 2026|India healthcare rural challenges technology|India education gaps AI solutions|India agriculture technology problems|India government digital services problems|India financial inclusion challenges|India urban infrastructure AI opportunities" \
        --output-dir "$BOT_ROOT/india-problems" \
        --mode "scan"
      ;;
    deep)
      local TOPIC="$*"
      if [ -z "$TOPIC" ]; then
        echo "Usage: india-problems deep \"<topic>\""
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Deep dive: $TOPIC"
      bash "$BOT_ROOT/lane-runner.sh" india-problem-scanner \
        --search "India $TOPIC problems challenges 2026|India $TOPIC AI technology solutions|India $TOPIC government initiatives" \
        --output-dir "$BOT_ROOT/india-problems" \
        --mode "deep-$TOPIC"
      ;;
    list)
      echo "━━━ INDIA PROBLEM REPORTS ━━━"
      ls -lt "$BOT_ROOT/india-problems"/*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No reports yet"
      ;;
    *)
      echo "Usage: india-problems [scan|deep \"<topic>\"|list]"
      exit 1
      ;;
  esac
}

run_ai_gaps() {
  local SUBCMD="${1:-scan}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    scan)
      bot_log "orchestrator" "info" "→ AI gap analysis..."
      bash "$BOT_ROOT/lane-runner.sh" ai-gap-analyzer \
        --search "AI tools missing India market 2026|AI products not available Indian languages|affordable AI tools India gap|AI education tools India comparison|AI healthcare India underserved|India AI startup landscape gaps" \
        --output-dir "$BOT_ROOT/ai-gaps" \
        --mode "scan"
      ;;
    sector)
      local SECTOR="$*"
      if [ -z "$SECTOR" ]; then
        echo "Usage: ai-gaps sector \"<sector name>\""
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Sector AI gap: $SECTOR"
      bash "$BOT_ROOT/lane-runner.sh" ai-gap-analyzer \
        --search "AI tools $SECTOR India gap 2026|$SECTOR AI solutions available India|$SECTOR technology India underserved" \
        --output-dir "$BOT_ROOT/ai-gaps" \
        --mode "sector-$SECTOR"
      ;;
    list)
      echo "━━━ AI GAP REPORTS ━━━"
      ls -lt "$BOT_ROOT/ai-gaps"/*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No reports yet"
      ;;
    *)
      echo "Usage: ai-gaps [scan|sector \"<name>\"|list]"
      exit 1
      ;;
  esac
}

run_funding() {
  local SUBCMD="${1:-scan}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    scan)
      bot_log "orchestrator" "info" "→ Funding opportunity scan..."
      bash "$BOT_ROOT/lane-runner.sh" funding-scanner \
        --search "MeitY AI startup funding India 2026|Startup India scheme AI company benefits|NASSCOM AI startup program 2026|Google for Startups India AI 2026|Microsoft for Startups India AI|India government grant AI technology 2026|AI accelerator India application open 2026" \
        --output-dir "$BOT_ROOT/funding" \
        --mode "scan"
      ;;
    grants)
      bot_log "orchestrator" "info" "→ Grant-specific scan..."
      bash "$BOT_ROOT/lane-runner.sh" funding-scanner \
        --search "AI research grant India 2026|Gates Foundation AI India grant|USAID technology education grant India|World Bank AI project India 2026|social enterprise AI funding India" \
        --output-dir "$BOT_ROOT/funding" \
        --mode "grants"
      ;;
    tenders)
      bot_log "orchestrator" "info" "→ Tender scan..."
      bash "$BOT_ROOT/lane-runner.sh" funding-scanner \
        --search "GeM portal AI software tender India 2026|India government AI tender 2026|Smart Cities AI technology tender India|education technology tender India government" \
        --output-dir "$BOT_ROOT/funding" \
        --mode "tenders"
      ;;
    list)
      echo "━━━ FUNDING REPORTS ━━━"
      ls -lt "$BOT_ROOT/funding"/*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No reports yet"
      ;;
    *)
      echo "Usage: funding [scan|grants|tenders|list]"
      exit 1
      ;;
  esac
}

run_stakeholders() {
  local SUBCMD="${1:-map}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    map)
      bot_log "orchestrator" "info" "→ Stakeholder mapping..."
      bash "$BOT_ROOT/lane-runner.sh" stakeholder-mapper \
        --search "India AI policy makers MeitY NITI Aayog 2026|India edtech AI companies partnership|India AI investor VC funding 2026|India AI startup ecosystem founders|India AI research institutions|India AI community developer groups" \
        --output-dir "$BOT_ROOT/reports" \
        --mode "stakeholder-map"
      ;;
    sector)
      local SECTOR="$*"
      if [ -z "$SECTOR" ]; then
        echo "Usage: stakeholders sector \"<sector name>\""
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Sector stakeholders: $SECTOR"
      bash "$BOT_ROOT/lane-runner.sh" stakeholder-mapper \
        --search "$SECTOR India key players 2026|$SECTOR India companies AI adoption|$SECTOR India government department contact" \
        --output-dir "$BOT_ROOT/reports" \
        --mode "stakeholder-$SECTOR"
      ;;
    *)
      echo "Usage: stakeholders [map|sector \"<name>\"]"
      exit 1
      ;;
  esac
}

run_blog() {
  local SUBCMD="${1:-generate}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    generate)
      local TOPIC="$*"
      if [ -z "$TOPIC" ]; then
        # Auto-generate from latest reports
        LATEST_REPORT=$(ls -t "$BOT_ROOT/india-problems"/*.md "$BOT_ROOT/ai-gaps"/*.md "$BOT_ROOT/opportunities/reports"/*.md 2>/dev/null | head -1)
        if [ -n "$LATEST_REPORT" ]; then
          TOPIC=$(head -5 "$LATEST_REPORT")
          bot_log "orchestrator" "info" "→ Blog from latest report: $(basename "$LATEST_REPORT")"
        else
          echo "Usage: blog generate \"<topic or insight>\" OR run a scan first"
          exit 1
        fi
      fi
      bash "$BOT_ROOT/lane-runner.sh" blog-writer \
        --context "$TOPIC" \
        --output-dir "$BOT_ROOT/blogs" \
        --mode "blog"
      ;;
    list)
      echo "━━━ BLOG DRAFTS ━━━"
      ls -lt "$BOT_ROOT/blogs"/*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No blogs yet"
      ;;
    *)
      echo "Usage: blog [generate \"<topic>\"|list]"
      exit 1
      ;;
  esac
}

run_podcast() {
  local SUBCMD="${1:-plan}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    plan)
      local TOPIC="$*"
      if [ -z "$TOPIC" ]; then
        LATEST_REPORT=$(ls -t "$BOT_ROOT/india-problems"/*.md "$BOT_ROOT/ai-gaps"/*.md 2>/dev/null | head -1)
        if [ -n "$LATEST_REPORT" ]; then
          TOPIC=$(head -10 "$LATEST_REPORT")
          bot_log "orchestrator" "info" "→ Podcast from latest report"
        else
          echo "Usage: podcast plan \"<topic>\""
          exit 1
        fi
      fi
      bash "$BOT_ROOT/lane-runner.sh" podcast-planner \
        --context "$TOPIC" \
        --output-dir "$BOT_ROOT/podcast" \
        --mode "episode"
      ;;
    list)
      echo "━━━ PODCAST PLANS ━━━"
      ls -lt "$BOT_ROOT/podcast"/*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No episodes yet"
      ;;
    *)
      echo "Usage: podcast [plan \"<topic>\"|list]"
      exit 1
      ;;
  esac
}

run_campaign_brief() {
  local SUBCMD="${1:-generate}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    generate)
      local SOURCE="$*"
      if [ -z "$SOURCE" ]; then
        # Pull from latest report
        LATEST=$(ls -t "$BOT_ROOT/india-problems"/*.md "$BOT_ROOT/ai-gaps"/*.md "$BOT_ROOT/opportunities/reports"/*.md "$BOT_ROOT/blogs"/*.md 2>/dev/null | head -1)
        if [ -n "$LATEST" ]; then
          SOURCE=$(cat "$LATEST" | head -c 2000)
          bot_log "orchestrator" "info" "→ Campaign brief from: $(basename "$LATEST")"
        else
          echo "Usage: campaign generate \"<discovery or insight>\" OR run a scan first"
          exit 1
        fi
      fi
      bash "$BOT_ROOT/lane-runner.sh" campaign-brief-generator \
        --context "$SOURCE" \
        --output-dir "$BOT_ROOT/campaign-briefs" \
        --mode "campaign" \
        --extra "Generate a structured JSON campaign brief for OpenClaw amplification. Follow the exact JSON schema specified in the skill."
      # Also copy to handoffs directory
      LATEST_BRIEF=$(ls -t "$BOT_ROOT/campaign-briefs"/*.md 2>/dev/null | head -1)
      if [ -n "$LATEST_BRIEF" ]; then
        cp "$LATEST_BRIEF" "$BOT_ROOT/handoffs/" 2>/dev/null
        bot_log "orchestrator" "info" "Campaign brief copied to handoffs/"
      fi
      ;;
    list)
      echo "━━━ CAMPAIGN BRIEFS ━━━"
      ls -lt "$BOT_ROOT/campaign-briefs"/*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No briefs yet"
      echo ""
      echo "━━━ PENDING HANDOFFS ━━━"
      ls -lt "$BOT_ROOT/handoffs"/*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No handoffs yet"
      ;;
    *)
      echo "Usage: campaign [generate \"<context>\"|list]"
      exit 1
      ;;
  esac
}

run_ecosystem() {
  local SUBCMD="${1:-scan}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    scan)
      bot_log "orchestrator" "info" "→ Ecosystem intelligence scan..."
      # Read bot-config for tracked sites and repos
      CONFIG="$BOT_ROOT/config/bot-config.json"
      SITES=$(python3 -c "
import json, os
try:
    data = json.load(open(os.environ.get('BOT_CONFIG','')))
    for s in data.get('scanner',{}).get('websites',[]):
        url = s.get('url','') if isinstance(s, dict) else str(s)
        if url: print(url.replace('https://','').replace('http://','').rstrip('/'))
except: pass
" 2>/dev/null)
      export BOT_CONFIG="$CONFIG"
      SITES=$(BOT_CONFIG="$CONFIG" python3 -c "
import json, os
try:
    data = json.load(open(os.environ['BOT_CONFIG']))
    for s in data.get('scanner',{}).get('websites',[]):
        url = s.get('url','') if isinstance(s, dict) else str(s)
        if url: print(url.replace('https://','').replace('http://','').rstrip('/'))
except: pass
" 2>/dev/null | tr '\n' '|')
      REPOS=$(BOT_CONFIG="$CONFIG" python3 -c "
import json, os
try:
    data = json.load(open(os.environ['BOT_CONFIG']))
    for r in data.get('scanner',{}).get('repos',[]):
        url = r.get('url','') if isinstance(r, dict) else str(r)
        if url: print(url.split('/')[-1])
except: pass
" 2>/dev/null | head -5 | tr '\n' '|')

      SEARCH_Q="site:inbharat.ai InBharat AI products|site:github.com inbharat-ai repositories|InBharat AI company India products"
      if [ -n "$SITES" ]; then
        for SITE in $(echo "$SITES" | tr '|' ' '); do
          [ -n "$SITE" ] && SEARCH_Q+="|site:$SITE"
        done
      fi

      bash "$BOT_ROOT/lane-runner.sh" ecosystem-intelligence \
        --search "$SEARCH_Q" \
        --output-dir "$BOT_ROOT/ecosystem-intelligence" \
        --mode "scan" \
        --extra "Also analyze: Are InBharat products well-represented online? Is documentation current? Are GitHub repos active? Is social presence consistent with actual product state?"
      ;;
    repos)
      bot_log "orchestrator" "info" "→ Repo intelligence..."
      bash "$BOT_ROOT/lane-runner.sh" ecosystem-intelligence \
        --search "site:github.com inbharat-ai|site:github.com reeturaj|InBharat open source AI India" \
        --output-dir "$BOT_ROOT/ecosystem-intelligence" \
        --mode "repos"
      ;;
    social)
      bot_log "orchestrator" "info" "→ Social presence scan..."
      bash "$BOT_ROOT/lane-runner.sh" ecosystem-intelligence \
        --search "InBharat AI social media|InBharat AI LinkedIn|InBharat AI Twitter|Reeturaj Goswami AI India" \
        --output-dir "$BOT_ROOT/ecosystem-intelligence" \
        --mode "social"
      ;;
    list)
      echo "━━━ ECOSYSTEM REPORTS ━━━"
      ls -lt "$BOT_ROOT/ecosystem-intelligence"/*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No reports yet"
      ;;
    *)
      echo "Usage: ecosystem [scan|repos|social|list]"
      exit 1
      ;;
  esac
}

run_community() {
  local SUBCMD="${1:-scan}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    scan)
      bot_log "orchestrator" "info" "→ Community intelligence scan..."
      bash "$BOT_ROOT/lane-runner.sh" community-intelligence \
        --search "InBharat AI community mentions 2026|InBharat AI Discord engagement|India AI community building opportunities|India AI developer community trending topics|InBharat AI social media mentions|India AI startup community growth" \
        --output-dir "$BOT_ROOT/community" \
        --mode "scan"
      ;;
    engagement)
      bot_log "orchestrator" "info" "→ Community engagement signals..."
      bash "$BOT_ROOT/lane-runner.sh" community-intelligence \
        --search "InBharat AI Twitter mentions|InBharat AI LinkedIn posts|InBharat AI Reddit discussions|India AI Discord communities active|InBharat GitHub stars forks activity" \
        --output-dir "$BOT_ROOT/community" \
        --mode "engagement"
      ;;
    suggest)
      bot_log "orchestrator" "info" "→ Community content suggestions..."
      # Pull recent community reports for context
      RECENT_COMMUNITY=""
      for F in $(ls -t "$BOT_ROOT/community"/*.md 2>/dev/null | head -3); do
        [ -f "$F" ] && RECENT_COMMUNITY+="
--- $(basename "$F") ---
$(head -20 "$F")
"
      done
      bash "$BOT_ROOT/lane-runner.sh" community-intelligence \
        --search "India AI community content ideas 2026|developer community engagement content|behind the scenes startup content ideas|AI changelog community updates best practices" \
        --context "$RECENT_COMMUNITY" \
        --output-dir "$BOT_ROOT/community" \
        --mode "suggest" \
        --extra "Focus on suggesting specific community content ideas: devlog updates, behind-the-scenes posts, changelog entries, ask-the-community questions, and milestone celebrations. Recommend which platform to post each on and what tone to use."
      ;;
    list)
      echo "━━━ COMMUNITY REPORTS ━━━"
      ls -lt "$BOT_ROOT/community"/*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No community reports yet"
      ;;
    *)
      echo "Usage: community [scan|engagement|suggest|list]"
      exit 1
      ;;
  esac
}

run_learning() {
  local SUBCMD="${1:-review}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    review)
      bot_log "orchestrator" "info" "→ Weekly learning review..."
      # Collect recent outputs from all lanes
      RECENT_DATA=""
      for LANE_DIR in india-problems ai-gaps funding reports ecosystem-intelligence opportunities/reports blogs; do
        FULL_DIR="$BOT_ROOT/$LANE_DIR"
        [ ! -d "$FULL_DIR" ] && continue
        LATEST=$(ls -t "$FULL_DIR"/*.md 2>/dev/null | head -3)
        for F in $LATEST; do
          [ -f "$F" ] && RECENT_DATA+="
--- $(basename "$F") ---
$(head -20 "$F")
"
        done
      done
      # Also include outreach and lead data
      OUTREACH_LOG="$BOT_ROOT/outreach/log/outreach-$(date '+%Y-%m-%d').jsonl"
      [ -f "$OUTREACH_LOG" ] && RECENT_DATA+="
--- Outreach Activity ---
$(cat "$OUTREACH_LOG" | tail -5)
"
      # Include posted content feedback from OpenClaw media
      FEEDBACK_DIR="/Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/analytics/feedback-to-bot"
      FEEDBACK_COLLECTOR="/Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/analytics/feedback-collector.sh"

      # Generate a fresh weekly summary before learning review
      if [ -x "$FEEDBACK_COLLECTOR" ]; then
        bot_log "orchestrator" "info" "  Generating fresh weekly feedback summary..."
        "$FEEDBACK_COLLECTOR" weekly-summary 2>/dev/null || true
      fi

      if [ -d "$FEEDBACK_DIR" ]; then
        # Read individual posting records (last 7 days of JSONL)
        for FEEDBACK_FILE in "$FEEDBACK_DIR"/posted-*.jsonl; do
          [ -f "$FEEDBACK_FILE" ] || continue
          RECENT_DATA+="
--- Posted Content Feedback ($(basename "$FEEDBACK_FILE")) ---
$(tail -10 "$FEEDBACK_FILE")
"
        done
        # Read latest weekly summary — most actionable for learning review
        LATEST_SUMMARY=$(ls -t "$FEEDBACK_DIR"/weekly-summary-*.json 2>/dev/null | head -1)
        if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ]; then
          RECENT_DATA+="
--- Weekly Posting Summary ($(basename "$LATEST_SUMMARY")) ---
$(cat "$LATEST_SUMMARY")
"
        fi
      fi
      # Include post action logs for what was actually published
      POST_ACTIONS="/Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/analytics"
      for ACTION_LOG in "$POST_ACTIONS"/post-actions-*.jsonl; do
        [ -f "$ACTION_LOG" ] || continue
        RECENT_DATA+="
--- Post Actions ($(basename "$ACTION_LOG")) ---
$(tail -5 "$ACTION_LOG")
"
      done
      bash "$BOT_ROOT/lane-runner.sh" learning-review \
        --context "$RECENT_DATA" \
        --output-dir "$BOT_ROOT/learning" \
        --mode "weekly-learning"
      ;;
    list)
      echo "━━━ LEARNING LOGS ━━━"
      ls -lt "$BOT_ROOT/learning"/*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No learning logs yet"
      ;;
    *)
      echo "Usage: learning [review|list]"
      exit 1
      ;;
  esac
}

# ── Direct skill shortcuts (skills available via lane-runner) ──

run_competitor_scan() {
  local SUBCMD="${1:-scan}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    scan)
      bot_log "orchestrator" "info" "→ Competitor analysis..."
      bash "$BOT_ROOT/lane-runner.sh" competitor-monitor \
        --search "India AI startup competitors 2026|edtech AI companies India comparison|AI personal assistant India competition|Indian AI companies funding raised 2026" \
        --output-dir "$BOT_ROOT/reports" \
        --mode "competitor-scan"
      ;;
    track)
      local COMPANY="$*"
      if [ -z "$COMPANY" ]; then
        echo "Usage: competitor track \"<company name>\""
        exit 1
      fi
      bot_log "orchestrator" "info" "→ Tracking competitor: $COMPANY"
      bash "$BOT_ROOT/lane-runner.sh" competitor-monitor \
        --search "$COMPANY AI India 2026|$COMPANY funding latest|$COMPANY product updates" \
        --output-dir "$BOT_ROOT/reports" \
        --mode "track-$COMPANY"
      ;;
    list)
      echo "━━━ COMPETITOR REPORTS ━━━"
      ls -lt "$BOT_ROOT/reports"/competitor-*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No competitor reports yet"
      ;;
    *)
      echo "Usage: competitor [scan|track \"<company>\"|list]"
      exit 1
      ;;
  esac
}

run_lead_research() {
  local SUBCMD="${1:-}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    scan)
      bot_log "orchestrator" "info" "→ Lead research scan..."
      bash "$BOT_ROOT/lane-runner.sh" lead-research \
        --search "India AI decision makers 2026|India enterprise AI buyers|India government AI procurement contacts" \
        --output-dir "$BOT_ROOT/leads" \
        --mode "lead-scan"
      ;;
    deep)
      local LEAD="$*"
      if [ -z "$LEAD" ]; then
        echo "Usage: lead-research deep \"<company or person name>\""
        return 1
      fi
      bot_log "orchestrator" "info" "→ Deep lead research: $LEAD"
      bash "$BOT_ROOT/lane-runner.sh" lead-research \
        --search "$LEAD India AI|$LEAD company products|$LEAD LinkedIn profile|$LEAD news 2026" \
        --output-dir "$BOT_ROOT/leads" \
        --mode "lead-deep"
      ;;
    list)
      echo "━━━ LEAD RESEARCH REPORTS ━━━"
      ls -lt "$BOT_ROOT/leads"/lead-*.md "$BOT_ROOT/reports"/lead-*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No lead research reports yet"
      ;;
    "")
      echo "Usage: lead-research [scan|deep \"<name>\"|list]"
      return 1
      ;;
    *)
      # Treat as direct name lookup (backward compatible)
      local LEAD="$SUBCMD $*"
      bot_log "orchestrator" "info" "→ Lead research: $LEAD"
      bash "$BOT_ROOT/lane-runner.sh" lead-research \
        --search "$LEAD India AI|$LEAD company products|$LEAD LinkedIn profile|$LEAD news 2026" \
        --output-dir "$BOT_ROOT/leads" \
        --mode "lead-deep"
      ;;
  esac
}

run_opportunity_mine() {
  local SUBCMD="${1:-scan}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    scan)
      bot_log "orchestrator" "info" "→ Opportunity mining..."
      bash "$BOT_ROOT/lane-runner.sh" opportunity-miner \
        --search "AI business opportunity India 2026|AI partnership opportunity India|AI project collaboration India|technology business opportunity education healthcare India" \
        --output-dir "$BOT_ROOT/reports" \
        --mode "opportunity-mine"
      ;;
    list)
      echo "━━━ OPPORTUNITY REPORTS ━━━"
      ls -lt "$BOT_ROOT/reports"/opportunity-*.md 2>/dev/null | head -10 | awk '{print "  " $NF}' || echo "  No opportunity reports yet"
      ;;
    *)
      echo "Usage: opportunity-mine [scan|list]"
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
    problems)
      bot_log "orchestrator" "info" "→ Problem-opportunity scan..."
      bash "$BOT_ROOT/lane-runner.sh" india-problem-scanner \
        --search "India problems technology can solve 2026|India AI opportunity gaps" \
        --output-dir "$BOT_ROOT/reports" \
        --mode "opportunity-problems"
      ;;
    projects)
      bot_log "orchestrator" "info" "→ Buildable project scan..."
      bash "$BOT_ROOT/lane-runner.sh" opportunity-miner \
        --search "India AI projects buildable 2026|open source India AI projects needed" \
        --output-dir "$BOT_ROOT/reports" \
        --mode "projects"
      ;;
    buildable)
      bot_log "orchestrator" "info" "→ Buildable opportunity scan..."
      bash "$BOT_ROOT/lane-runner.sh" opportunity-miner \
        --search "India AI MVP buildable problems 2026|quick AI prototype India market" \
        --output-dir "$BOT_ROOT/reports" \
        --mode "buildable"
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
      echo "Usage: opportunities [all|government|corporate|global|grants|problems|projects|buildable|custom \"query\"]"
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

# ── OpenClaw Media modules ──

MEDIA_DIR="/Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media"

run_media() {
  local SUBCMD="${1:-status}"
  shift 2>/dev/null || true
  case "$SUBCMD" in
    native)
      bot_log "orchestrator" "info" "→ OpenClaw native content generation..."
      bash "$MEDIA_DIR/native-pipeline/generate-content.sh" "$@"
      ;;
    amplify)
      bot_log "orchestrator" "info" "→ OpenClaw amplification pipeline..."
      bash "$MEDIA_DIR/amplify-pipeline/amplify-handoff.sh" "$@"
      ;;
    status)
      bash "$MEDIA_DIR/publishing/post-manager.sh" status
      ;;
    review)
      bash "$MEDIA_DIR/publishing/post-manager.sh" review
      ;;
    approve)
      bash "$MEDIA_DIR/publishing/post-manager.sh" approve "$@"
      ;;
    reject)
      bash "$MEDIA_DIR/publishing/post-manager.sh" reject "$@"
      ;;
    ready)
      bash "$MEDIA_DIR/publishing/post-manager.sh" ready
      ;;
    posted)
      bash "$MEDIA_DIR/publishing/post-manager.sh" posted "$@"
      ;;
    history)
      bash "$MEDIA_DIR/publishing/post-manager.sh" history
      ;;
    clean)
      bash "$MEDIA_DIR/publishing/post-manager.sh" clean
      ;;
    validate)
      bot_log "orchestrator" "info" "→ Validating queue content..."
      bash "$WORKSPACE_ROOT/OpenClawData/security/claim-validator.sh" --scan-queues
      ;;
    memory)
      local MEM_CMD="${1:-review}"
      shift 2>/dev/null || true
      bash "$MEDIA_DIR/analytics/campaign-memory.sh" "$MEM_CMD" "$@"
      ;;
    full)
      bot_log "orchestrator" "info" "→ Full media cycle: native + amplify + status"
      echo "━━━ FULL MEDIA CYCLE ━━━"
      echo ""
      echo "Step 1: Native content generation..."
      bash "$MEDIA_DIR/native-pipeline/generate-content.sh" "$@"
      echo ""
      echo "Step 2: Amplifying handoffs..."
      bash "$MEDIA_DIR/amplify-pipeline/amplify-handoff.sh" --all
      echo ""
      echo "Step 3: Queue status..."
      bash "$MEDIA_DIR/publishing/post-manager.sh" status
      ;;
    publish|post)
      bot_log "orchestrator" "info" "→ Publishing approved content..."
      bash "$MEDIA_DIR/posting-engine/publish.sh" "$@"
      ;;
    image)
      bot_log "orchestrator" "info" "→ Image generation..."
      bash "$MEDIA_DIR/image-engine/generate-image.sh" "$@"
      ;;
    video)
      bot_log "orchestrator" "info" "→ Video generation..."
      bash "$MEDIA_DIR/video-engine/generate-video.sh" "$@"
      ;;
    *)
      echo "Usage: media [native|amplify|status|review|approve|reject|ready|posted|history|publish|image|video|full]"
      echo ""
      echo "  Content Generation:"
      echo "    native [--product X] [--bucket X] [--platform X]   Generate native social content"
      echo "    amplify [--all] [--file <handoff>]                  Amplify InBharat Bot handoffs"
      echo "    full [--product X]                                  Native + amplify + status"
      echo ""
      echo "  Queue Management:"
      echo "    status             Show all platform queue counts"
      echo "    review             Show items pending review"
      echo "    approve <file>     Approve a pending item"
      echo "    reject <file>      Reject a pending item"
      echo "    ready              Move approved → publish-ready"
      echo "    posted <file>      Mark as posted after browser posting"
      echo "    history            Show posting history"
      echo "    clean              Strip LLM thinking tags from queue items"
      echo "    validate           Check all queue items for fabricated claims"
      echo ""
      echo "  Generation Engines:"
      echo "    image --brief \"desc\" [--backend auto|dalle|placeholder]  Generate image"
      echo "    video --brief \"desc\" [--format shorts|landscape]         Generate video"
      echo "    video --check                                            Check video deps"
      echo ""
      echo "  Campaign Memory:"
      echo "    memory review      Show campaign outcomes"
      echo "    memory record <id> <win|loss> \"notes\""
      echo "    memory insights    Product/platform performance analysis"
      echo "    memory winners     Top performing campaigns"
      echo "    memory losers      Failure lessons"
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
  opportunities)    run_opportunities "$@" ;;
  competitors)      run_competitors ;;
  competitor)       run_competitor_scan "$@" ;;
  lead-research)    run_lead_research "$@" ;;
  opportunity-mine) run_opportunity_mine "$@" ;;
  government)       run_government "$@" ;;
  prototype)        run_prototype "$@" ;;
  india-problems)   run_india_problems "$@" ;;
  ai-gaps)          run_ai_gaps "$@" ;;
  funding)          run_funding "$@" ;;
  stakeholders)     run_stakeholders "$@" ;;
  blog)             run_blog "$@" ;;
  podcast)          run_podcast "$@" ;;
  campaign)         run_campaign_brief "$@" ;;
  ecosystem)        run_ecosystem "$@" ;;
  community)        run_community "$@" ;;
  learning)         run_learning "$@" ;;
  media)            run_media "$@" ;;
  publish)          bash "$MEDIA_DIR/posting-engine/publish.sh" "$@" ;;
  generate)
    GEN_TYPE="${1:-}"
    shift 2>/dev/null || true
    case "$GEN_TYPE" in
      image)  run_media image "$@" ;;
      video)  run_media video "$@" ;;
      *)      echo "Usage: generate [image|video] <options>"; exit 1 ;;
    esac
    ;;
  *)
    echo "━━━ InBharat Bot v3.0 ━━━"
    echo ""
    echo "Intelligence:"
    echo "  full        Complete cycle (scan→analyze→propose→bridge→status)"
    echo "  scan        Ecosystem scan"
    echo "  analyze     Gap analysis"
    echo "  propose     Build proposals"
    echo "  bridge      Feed to CMO pipeline"
    echo "  status      System dashboard"
    echo ""
    echo "India Intelligence:"
    echo "  india-problems [scan|deep \"<topic>\"|list]     India problem scanning"
    echo "  ai-gaps [scan|sector \"<name>\"|list]           AI market gap analysis"
    echo "  funding [scan|grants|tenders|list]             Funding/grants discovery"
    echo "  stakeholders [map|sector \"<name>\"]            Stakeholder mapping"
    echo "  ecosystem [scan|repos|social|list]             Internal ecosystem intel"
    echo "  community [scan|engagement|suggest|list]      Community intelligence"
    echo "  learning [review|list]                         Weekly learning review"
    echo ""
    echo "Content:"
    echo "  blog [generate \"<topic>\"|list]                Blog from discoveries"
    echo "  podcast [plan \"<topic>\"|list]                 Podcast episode planning"
    echo "  campaign [generate \"<context>\"|list]          Campaign brief → OpenClaw"
    echo ""
    echo "Revenue:"
    echo "  leads [status|capture <text>]"
    echo "  revenue [status|process|followups]"
    echo ""
    echo "Outreach Engine (investor/VC/partner pipeline):"
    echo "  outreach research \"<company>\"             Research a target"
    echo "  outreach campaign <template> <lead-file>  Draft campaign emails"
    echo "  outreach followup [--days 7]              Follow up unreplied emails"
    echo "  outreach leads [name]                     List lead databases"
    echo "  outreach status                           Pipeline status"
    echo "  outreach draft <context>                  Draft freeform email"
    echo "  outreach send <file> <email>              Send approved draft"
    echo "  outreach track [today|week|stats]         View activity log"
    echo "  outreach setup                            Check mail config"
    echo ""
    echo "World Scanner:"
    echo "  opportunities [all|government|corporate|global|grants|problems|projects|buildable]"
    echo "  opportunities custom \"<query>\"  Custom search"
    echo "  competitors                     AI competitor scan"
    echo "  competitor [scan|track \"<co>\"|list]  Deep competitor analysis"
    echo "  lead-research [scan|deep \"<co>\"|list] Lead intelligence research"
    echo "  opportunity-mine [scan|list]          Opportunity mining engine"
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
    echo "OpenClaw Media:"
    echo "  media native [--product X] [--bucket X]    Generate native social content"
    echo "  media amplify [--all]                      Amplify bot handoffs → social"
    echo "  media status                               Platform queue status"
    echo "  media review                               Items pending review"
    echo "  media approve <file>                       Approve → validate → auto-publish"
    echo "  media approve <file> --no-publish         Approve without auto-publishing"
    echo "  media reject <file>                        Reject content"
    echo "  media ready                                Move approved → publish-ready (manual)"
    echo "  media posted <file>                        Mark as posted (manual)"
    echo "  media full [--product X]                   Full cycle: native+amplify+status"
    echo "  media history                              Posting history"
    echo "  media publish [--platform X] [--dry-run]   Autonomous publishing"
    echo "  media image --brief \"desc\" [--backend X]   Generate image (DALL-E/placeholder)"
    echo "  media video --brief \"desc\" [--format X]    Generate video (slides+TTS+FFmpeg)"
    echo ""
    echo "Quick Generation:"
    echo "  generate image --brief \"desc\"              Direct image generation"
    echo "  generate video --brief \"desc\"              Direct video generation"
    echo ""
    exit 0
    ;;
esac

bot_log "orchestrator" "info" "=== InBharat Bot complete — $MODE ==="
