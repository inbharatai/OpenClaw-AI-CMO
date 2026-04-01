#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# outreach-engine.sh — Investor/VC Outreach Orchestrator
# Master script for the InBharat Bot outreach pipeline
#
# Usage:
#   ./outreach-engine.sh research <company>
#   ./outreach-engine.sh draft <template> <lead-file> [--limit N]
#   ./outreach-engine.sh send <draft-file> <email>
#   ./outreach-engine.sh campaign <template> <lead-file> [--dry-run]
#   ./outreach-engine.sh status
#   ./outreach-engine.sh followup [--days 7]
#   ./outreach-engine.sh leads [vc-india|vc-global|companies-ai|accelerators]
#
# All drafts go to outreach/queue/ for approval before sending.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -uo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
OUTREACH_DIR="$BOT_ROOT/outreach"
LEADS_DIR="$OUTREACH_DIR/leads"
TEMPLATES_DIR="$OUTREACH_DIR/templates"
DRAFTS_DIR="$OUTREACH_DIR/drafts"
QUEUE_DIR="$OUTREACH_DIR/queue"
RESEARCH_DIR="$OUTREACH_DIR/research"
LOG_DIR="$OUTREACH_DIR/log"
PRODUCT_REGISTRY="/Volumes/Expansion/CMO-10million/OpenClawData/strategy/product-registry.json"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"
DATE=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

source "$BOT_ROOT/logging/bot-logger.sh"

mkdir -p "$DRAFTS_DIR" "$QUEUE_DIR" "$RESEARCH_DIR" "$LOG_DIR"

COMMAND="${1:-help}"
shift 2>/dev/null || true

# ── Utility functions ──

log_activity() {
  local TYPE="$1"
  local TARGET="$2"
  local STATUS="$3"
  local DETAIL="${4:-}"
  jq -cn \
    --arg date "$DATE" \
    --arg time "$(date '+%H:%M:%S')" \
    --arg type "$TYPE" \
    --arg target "$TARGET" \
    --arg status "$STATUS" \
    --arg detail "$DETAIL" \
    '{date: $date, time: $time, type: $type, target: $target, status: $status, detail: $detail}' \
    >> "$LOG_DIR/outreach-${DATE}.jsonl"
}

check_ollama() {
  if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
    echo "ERROR: Ollama not running at $OLLAMA_URL"
    echo "Start it with: ollama serve"
    return 1
  fi
  return 0
}

ollama_generate() {
  local PROMPT="$1"
  local MAX_TOKENS="${2:-2500}"
  curl -s --max-time 180 "$OLLAMA_URL/api/generate" \
    -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --argjson num "$MAX_TOKENS" \
    '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.4, num_predict: $num}}')" \
    | jq -r '(.response // "") | gsub("^<think>[\\s\\S]*?</think>\\s*"; "")' 2>/dev/null
}

get_founder_name() {
  jq -r '.meta.founder // "Reeturaj Goswami"' "$PRODUCT_REGISTRY" 2>/dev/null || echo "Reeturaj Goswami"
}

get_restricted_claims() {
  jq -r '[.products[].restricted_claims[]] | unique | .[]' "$PRODUCT_REGISTRY" 2>/dev/null | head -10
}

# ── Command: research ──

cmd_research() {
  local TARGET="${1:-}"
  if [ -z "$TARGET" ]; then
    echo "Usage: outreach-engine.sh research \"<company or VC name>\""
    exit 1
  fi
  bot_log "outreach-engine" "info" "Research target: $TARGET"
  bash "$OUTREACH_DIR/lead-researcher.sh" "$TARGET"
}

# ── Command: draft ──

cmd_draft() {
  local TEMPLATE="${1:-}"
  local LEAD_FILE="${2:-}"
  shift 2 2>/dev/null || true
  local LIMIT=999

  # Parse optional args
  while [ $# -gt 0 ]; do
    case "$1" in
      --limit) LIMIT="${2:-5}"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ -z "$TEMPLATE" ] || [ -z "$LEAD_FILE" ]; then
    echo "Usage: outreach-engine.sh draft <template-name> <lead-file> [--limit N]"
    echo ""
    echo "Templates:"
    for t in "$TEMPLATES_DIR"/*.md; do
      [ -f "$t" ] && echo "  $(basename "$t" .md)"
    done
    echo ""
    echo "Lead files:"
    for l in "$LEADS_DIR"/*.json; do
      [ -f "$l" ] && echo "  $(basename "$l")"
    done
    exit 1
  fi

  # Resolve template path
  local TEMPLATE_FILE="$TEMPLATES_DIR/${TEMPLATE}.md"
  [ ! -f "$TEMPLATE_FILE" ] && TEMPLATE_FILE="$TEMPLATES_DIR/${TEMPLATE}"
  if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: Template not found: $TEMPLATE"
    echo "Available: $(ls "$TEMPLATES_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ', ')"
    exit 1
  fi

  # Resolve lead file path
  local LEAD_PATH="$LEADS_DIR/$LEAD_FILE"
  [ ! -f "$LEAD_PATH" ] && LEAD_PATH="$LEADS_DIR/${LEAD_FILE}.json"
  [ ! -f "$LEAD_PATH" ] && LEAD_PATH="$LEAD_FILE"
  if [ ! -f "$LEAD_PATH" ]; then
    echo "ERROR: Lead file not found: $LEAD_FILE"
    exit 1
  fi

  check_ollama || exit 1

  local TEMPLATE_BODY
  TEMPLATE_BODY=$(cat "$TEMPLATE_FILE")
  local FOUNDER_NAME
  FOUNDER_NAME=$(get_founder_name)
  local RESTRICTED
  RESTRICTED=$(get_restricted_claims)
  local LEAD_TYPE
  LEAD_TYPE=$(jq -r '.type // "unknown"' "$LEAD_PATH")

  # Determine the field name for the lead entry name
  local NAME_FIELD="firm"
  case "$LEAD_TYPE" in
    companies-ai) NAME_FIELD="company" ;;
    accelerators) NAME_FIELD="name" ;;
  esac

  local LEAD_COUNT
  LEAD_COUNT=$(jq '.leads | length' "$LEAD_PATH")
  local ACTUAL_LIMIT=$((LEAD_COUNT < LIMIT ? LEAD_COUNT : LIMIT))

  echo "━━━ DRAFTING EMAILS ━━━"
  echo "Template: $(basename "$TEMPLATE_FILE" .md)"
  echo "Leads:    $(basename "$LEAD_PATH") ($LEAD_COUNT total, processing $ACTUAL_LIMIT)"
  echo "Founder:  $FOUNDER_NAME"
  echo ""

  local DRAFTED=0
  for i in $(seq 0 $((ACTUAL_LIMIT - 1))); do
    local LEAD_JSON
    LEAD_JSON=$(jq -c ".leads[$i]" "$LEAD_PATH")
    local LEAD_NAME
    LEAD_NAME=$(echo "$LEAD_JSON" | jq -r ".${NAME_FIELD} // .firm // .company // .name // \"Unknown\"")

    echo "  [$((i+1))/$ACTUAL_LIMIT] Drafting for: $LEAD_NAME..."

    # Check for existing research
    local LEAD_SLUG
    LEAD_SLUG=$(echo "$LEAD_NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    local RESEARCH_CONTEXT=""
    if [ -f "$RESEARCH_DIR/${LEAD_SLUG}.md" ]; then
      RESEARCH_CONTEXT=$(head -40 "$RESEARCH_DIR/${LEAD_SLUG}.md")
    fi

    # Load website context for accurate product details
    local WEBSITE_CTX=""
    local WEB_CTX_FILE="$BOT_ROOT/../strategy/website-context.md"
    if [ -f "$WEB_CTX_FILE" ]; then
      WEBSITE_CTX=$(head -c 2000 "$WEB_CTX_FILE")
    fi

    local PERSONALIZATION_PROMPT="You are a professional email writer for a startup founder. Generate a personalized outreach email.

COMPANY CONTEXT (use this for accurate product descriptions):
$WEBSITE_CTX

TEMPLATE TO FOLLOW (use this as the structure and tone guide):
$TEMPLATE_BODY

LEAD INFORMATION:
$LEAD_JSON

ADDITIONAL RESEARCH (if available):
${RESEARCH_CONTEXT:-No additional research available}

FOUNDER NAME: $FOUNDER_NAME

RESTRICTED CLAIMS (DO NOT violate these):
$RESTRICTED

INSTRUCTIONS:
1. Fill in ALL placeholders ({{...}}) with appropriate values from the lead data
2. Personalize the email based on the lead's focus areas and any research available
3. Choose the most appropriate subject line from the template options
4. Add a brief personalized paragraph about why this specific firm/company is relevant
5. Keep the honest classification disclaimer at the bottom
6. Do NOT fabricate statistics, user numbers, revenue, or partnership claims
7. Do NOT claim government partnerships or deployments that don't exist
8. Output the complete email in markdown format with frontmatter

Format the output as:
---
to_name: [contact name or 'Team']
to_firm: [firm/company name]
to_email: [contact email from lead data]
subject: [chosen subject line]
template: $(basename "$TEMPLATE_FILE" .md)
type: $LEAD_TYPE
status: queued
date: $DATE
---

[Email body here]"

    local DRAFT_RESPONSE
    DRAFT_RESPONSE=$(ollama_generate "$PERSONALIZATION_PROMPT" 2500)

    if [ -z "$DRAFT_RESPONSE" ] || [ "$DRAFT_RESPONSE" = "null" ]; then
      echo "    WARN: Failed to generate draft for $LEAD_NAME — skipping"
      log_activity "draft-failed" "$LEAD_NAME" "error" "Ollama returned empty"
      continue
    fi

    # Save to queue (not drafts — requires approval)
    local DRAFT_SLUG
    DRAFT_SLUG=$(echo "$LEAD_NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    DRAFT_SLUG="${DRAFT_SLUG:0:40}"
    local QUEUE_FILE="$QUEUE_DIR/email-${DATE}-${DRAFT_SLUG}.md"

    echo "$DRAFT_RESPONSE" > "$QUEUE_FILE"

    echo "    Queued: $(basename "$QUEUE_FILE")"
    log_activity "email-draft" "$LEAD_NAME" "queued" "$QUEUE_FILE"
    DRAFTED=$((DRAFTED + 1))
  done

  echo ""
  echo "━━━ DRAFTING COMPLETE ━━━"
  echo "Drafted: $DRAFTED / $ACTUAL_LIMIT"
  echo "Queue:   $QUEUE_DIR/"
  echo ""
  echo "--- Next Steps ---"
  echo "  Review queue: ls $QUEUE_DIR/"
  echo "  Read a draft: cat $QUEUE_DIR/<filename>"
  echo "  Approve & send: ./outreach-engine.sh send <draft-file> <email>"
  echo "  Campaign mode: ./outreach-engine.sh campaign <template> <lead-file>"
}

# ── Command: send ──

cmd_send() {
  local DRAFT_FILE="${1:-}"
  local RECIPIENT="${2:-}"

  if [ -z "$DRAFT_FILE" ] || [ -z "$RECIPIENT" ]; then
    echo "Usage: outreach-engine.sh send <draft-file> <recipient-email>"
    echo ""
    echo "Queued drafts:"
    for f in "$QUEUE_DIR"/*.md; do
      [ ! -f "$f" ] && continue
      local SUBJ
      SUBJ=$(grep "^subject:" "$f" 2>/dev/null | head -1 | sed 's/subject: *//')
      local TO_FIRM
      TO_FIRM=$(grep "^to_firm:" "$f" 2>/dev/null | head -1 | sed 's/to_firm: *//')
      echo "  $(basename "$f") — $TO_FIRM — $SUBJ"
    done
    exit 1
  fi

  # Resolve draft path
  [ ! -f "$DRAFT_FILE" ] && DRAFT_FILE="$QUEUE_DIR/$DRAFT_FILE"
  [ ! -f "$DRAFT_FILE" ] && DRAFT_FILE="$DRAFTS_DIR/$DRAFT_FILE"

  if [ ! -f "$DRAFT_FILE" ]; then
    echo "ERROR: Draft not found: $DRAFT_FILE"
    exit 1
  fi

  echo "━━━ SENDING EMAIL ━━━"
  echo "Draft: $(basename "$DRAFT_FILE")"
  echo "To:    $RECIPIENT"
  echo ""

  # Move from queue to drafts first (mark as approved)
  if [[ "$DRAFT_FILE" == *"/queue/"* ]]; then
    local APPROVED_FILE="$DRAFTS_DIR/$(basename "$DRAFT_FILE")"
    cp "$DRAFT_FILE" "$APPROVED_FILE"
    # Update status in the approved copy
    sed -i '' 's/^status: queued/status: approved/' "$APPROVED_FILE" 2>/dev/null
    DRAFT_FILE="$APPROVED_FILE"
  fi

  # Send via mail-sender.sh
  bash "$OUTREACH_DIR/mail-sender.sh" "$DRAFT_FILE" "$RECIPIENT"
  local SEND_RESULT=$?

  if [ $SEND_RESULT -eq 0 ]; then
    # Remove from queue if it was there
    local QUEUE_COPY="$QUEUE_DIR/$(basename "$DRAFT_FILE")"
    [ -f "$QUEUE_COPY" ] && rm "$QUEUE_COPY"
    log_activity "email-send" "$RECIPIENT" "sent" "$(basename "$DRAFT_FILE")"
  else
    log_activity "email-send" "$RECIPIENT" "failed" "$(basename "$DRAFT_FILE")"
  fi
}

# ── Command: campaign ──

cmd_campaign() {
  local TEMPLATE="${1:-}"
  local LEAD_FILE="${2:-}"
  shift 2 2>/dev/null || true
  local DRY_RUN=false
  local LIMIT=999

  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=true; shift ;;
      --limit) LIMIT="${2:-5}"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ -z "$TEMPLATE" ] || [ -z "$LEAD_FILE" ]; then
    echo "Usage: outreach-engine.sh campaign <template> <lead-file> [--dry-run] [--limit N]"
    echo ""
    echo "This will:"
    echo "  1. Generate personalized drafts for all leads"
    echo "  2. Queue them for review (NOT auto-send)"
    echo "  3. With --dry-run: only show what would be generated"
    exit 1
  fi

  echo "━━━ CAMPAIGN MODE ━━━"
  echo "Template:  $TEMPLATE"
  echo "Leads:     $LEAD_FILE"
  echo "Dry Run:   $DRY_RUN"
  echo "Limit:     $LIMIT"
  echo ""

  if [ "$DRY_RUN" = true ]; then
    echo "--- DRY RUN: Showing what would be generated ---"
    echo ""

    local LEAD_PATH="$LEADS_DIR/$LEAD_FILE"
    [ ! -f "$LEAD_PATH" ] && LEAD_PATH="$LEADS_DIR/${LEAD_FILE}.json"
    if [ ! -f "$LEAD_PATH" ]; then
      echo "ERROR: Lead file not found: $LEAD_FILE"
      exit 1
    fi

    local LEAD_TYPE
    LEAD_TYPE=$(jq -r '.type // "unknown"' "$LEAD_PATH")
    local NAME_FIELD="firm"
    case "$LEAD_TYPE" in
      companies-ai) NAME_FIELD="company" ;;
      accelerators) NAME_FIELD="name" ;;
    esac

    local COUNT
    COUNT=$(jq '.leads | length' "$LEAD_PATH")
    local SHOW=$((COUNT < LIMIT ? COUNT : LIMIT))

    for i in $(seq 0 $((SHOW - 1))); do
      local NAME
      NAME=$(jq -r ".leads[$i].${NAME_FIELD} // .leads[$i].firm // .leads[$i].company // .leads[$i].name // \"?\"" "$LEAD_PATH")
      local EMAIL
      EMAIL=$(jq -r ".leads[$i].contact_email // .leads[$i].apply_url // \"no-email\"" "$LEAD_PATH")
      echo "  [$((i+1))] $NAME → $EMAIL"
    done

    echo ""
    echo "Would generate $SHOW draft emails using template: $TEMPLATE"
    echo "Run without --dry-run to generate drafts."
    return 0
  fi

  # Generate drafts
  cmd_draft "$TEMPLATE" "$LEAD_FILE" --limit "$LIMIT"

  log_activity "campaign" "$TEMPLATE/$LEAD_FILE" "completed" "Limit: $LIMIT"

  echo ""
  echo "━━━ CAMPAIGN QUEUED ━━━"
  echo ""
  echo "All drafts are in the review queue."
  echo "IMPORTANT: Emails will NOT be sent until you approve each one."
  echo ""
  echo "Review process:"
  echo "  1. Review: cat $QUEUE_DIR/<file>.md"
  echo "  2. Edit if needed"
  echo "  3. Send: ./outreach-engine.sh send <file>.md <email>"
}

# ── Command: status ──

cmd_status() {
  echo "━━━ OUTREACH ENGINE STATUS ━━━"
  echo ""

  # Lead databases
  echo "Lead Databases:"
  for f in "$LEADS_DIR"/*.json; do
    [ ! -f "$f" ] && continue
    [[ "$(basename "$f")" == ._* ]] && continue
    local COUNT
    COUNT=$(jq '.leads | length' "$f" 2>/dev/null || echo 0)
    local TYPE
    TYPE=$(jq -r '.type // "?"' "$f" 2>/dev/null)
    echo "  $(basename "$f"): $COUNT leads ($TYPE)"
  done

  echo ""

  # Queue status
  local QUEUED=0
  local APPROVED=0
  local SENT=0
  local BOUNCED=0

  for f in "$QUEUE_DIR"/*.md; do
    [ ! -f "$f" ] && continue
    [[ "$(basename "$f")" == ._* ]] && continue
    QUEUED=$((QUEUED + 1))
  done

  for f in "$DRAFTS_DIR"/*.md; do
    [ ! -f "$f" ] && continue
    [[ "$(basename "$f")" == ._* ]] && continue
    local STATUS
    STATUS=$(grep "^status:" "$f" 2>/dev/null | head -1 | sed 's/status: *//')
    case "$STATUS" in
      sent) SENT=$((SENT + 1)) ;;
      approved) APPROVED=$((APPROVED + 1)) ;;
      bounced|failed) BOUNCED=$((BOUNCED + 1)) ;;
    esac
  done

  echo "Pipeline:"
  echo "  Queued (awaiting review): $QUEUED"
  echo "  Approved (ready to send): $APPROVED"
  echo "  Sent:                     $SENT"
  echo "  Bounced/Failed:           $BOUNCED"

  echo ""

  # Research files
  local RESEARCH_COUNT=0
  for f in "$RESEARCH_DIR"/*.md; do
    [ ! -f "$f" ] && continue
    [[ "$(basename "$f")" == ._* ]] && continue
    RESEARCH_COUNT=$((RESEARCH_COUNT + 1))
  done
  echo "Research briefs: $RESEARCH_COUNT"

  echo ""

  # Recent log activity
  local TODAY_LOG="$LOG_DIR/outreach-${DATE}.jsonl"
  if [ -f "$TODAY_LOG" ]; then
    local TODAY_COUNT
    TODAY_COUNT=$(wc -l < "$TODAY_LOG" | tr -d ' ')
    echo "Today's activity: $TODAY_COUNT entries"
    echo ""
    echo "Recent:"
    tail -5 "$TODAY_LOG" | while IFS= read -r line; do
      local T
      T=$(echo "$line" | jq -r '.time // "?"')
      local TY
      TY=$(echo "$line" | jq -r '.type // "?"')
      local TA
      TA=$(echo "$line" | jq -r '.target // "?"' | head -c 30)
      local ST
      ST=$(echo "$line" | jq -r '.status // "?"')
      echo "  [$T] $TY | $ST | $TA"
    done
  else
    echo "No activity logged today."
  fi

  echo ""

  # Templates
  echo "Available templates:"
  for t in "$TEMPLATES_DIR"/*.md; do
    [ ! -f "$t" ] && continue
    echo "  $(basename "$t" .md)"
  done
}

# ── Command: followup ──

cmd_followup() {
  local DAYS=7

  while [ $# -gt 0 ]; do
    case "$1" in
      --days) DAYS="${2:-7}"; shift 2 ;;
      *) shift ;;
    esac
  done

  echo "━━━ FOLLOW-UP GENERATOR ━━━"
  echo "Looking for sent emails older than $DAYS days without reply..."
  echo ""

  check_ollama || exit 1

  local TEMPLATE_FILE="$TEMPLATES_DIR/investor-followup.md"
  if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: Follow-up template not found"
    exit 1
  fi

  local TEMPLATE_BODY
  TEMPLATE_BODY=$(cat "$TEMPLATE_FILE")
  local FOUNDER_NAME
  FOUNDER_NAME=$(get_founder_name)
  local FOLLOWUP_COUNT=0

  # Find sent emails older than N days
  for f in "$DRAFTS_DIR"/*.md; do
    [ ! -f "$f" ] && continue
    [[ "$(basename "$f")" == ._* ]] && continue

    local STATUS
    STATUS=$(grep "^status:" "$f" 2>/dev/null | head -1 | sed 's/status: *//')
    [ "$STATUS" != "sent" ] && continue

    # Check if already followed up
    local HAS_FOLLOWUP
    HAS_FOLLOWUP=$(grep "^followup_of:" "$QUEUE_DIR"/*.md 2>/dev/null | grep "$(basename "$f")" | head -1)
    [ -n "$HAS_FOLLOWUP" ] && continue

    local SEND_DATE
    SEND_DATE=$(grep "^date:" "$f" 2>/dev/null | head -1 | sed 's/date: *//')
    [ -z "$SEND_DATE" ] && continue

    # Calculate days since sent
    local SEND_EPOCH
    SEND_EPOCH=$(date -j -f "%Y-%m-%d" "$SEND_DATE" "+%s" 2>/dev/null || date -d "$SEND_DATE" "+%s" 2>/dev/null)
    [ -z "$SEND_EPOCH" ] && continue
    local NOW_EPOCH
    NOW_EPOCH=$(date "+%s")
    local DAYS_SINCE=$(( (NOW_EPOCH - SEND_EPOCH) / 86400 ))

    [ "$DAYS_SINCE" -lt "$DAYS" ] && continue

    # Check if reply was received (status: replied)
    [ "$STATUS" = "replied" ] && continue

    local TO_FIRM
    TO_FIRM=$(grep "^to_firm:" "$f" 2>/dev/null | head -1 | sed 's/to_firm: *//')
    local TO_NAME
    TO_NAME=$(grep "^to_name:" "$f" 2>/dev/null | head -1 | sed 's/to_name: *//')
    local TO_EMAIL
    TO_EMAIL=$(grep "^to_email:" "$f" 2>/dev/null | head -1 | sed 's/to_email: *//')
    local ORIG_SUBJECT
    ORIG_SUBJECT=$(grep "^subject:" "$f" 2>/dev/null | head -1 | sed 's/subject: *//')

    echo "  Generating follow-up for: ${TO_FIRM:-Unknown} ($DAYS_SINCE days since sent)..."

    local FOLLOWUP_PROMPT="Generate a follow-up email based on this template and context.

FOLLOW-UP TEMPLATE:
$TEMPLATE_BODY

ORIGINAL EMAIL CONTEXT:
- Sent to: ${TO_NAME:-Team} at ${TO_FIRM:-Unknown}
- Original subject: ${ORIG_SUBJECT:-InBharat AI introduction}
- Days since sent: $DAYS_SINCE
- Founder: $FOUNDER_NAME

INSTRUCTIONS:
1. Fill all placeholders
2. Keep it SHORT (under 100 words for the body)
3. Include one new update or data point (e.g., a new product milestone, repo update, or relevant news)
4. Do NOT fabricate any metrics or claims
5. Be professional and non-pushy
6. Output in markdown with frontmatter

Frontmatter must include:
---
to_name: ${TO_NAME:-Team}
to_firm: ${TO_FIRM:-Unknown}
to_email: ${TO_EMAIL:-unknown}
subject: Re: Follow-up — InBharat AI
template: investor-followup
type: followup
status: queued
date: $DATE
followup_of: $(basename "$f")
original_date: $SEND_DATE
days_since: $DAYS_SINCE
---"

    local FOLLOWUP_RESPONSE
    FOLLOWUP_RESPONSE=$(ollama_generate "$FOLLOWUP_PROMPT" 1500)

    if [ -n "$FOLLOWUP_RESPONSE" ] && [ "$FOLLOWUP_RESPONSE" != "null" ]; then
      local FU_SLUG
      FU_SLUG=$(echo "${TO_FIRM:-unknown}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
      FU_SLUG="${FU_SLUG:0:30}"
      local FU_FILE="$QUEUE_DIR/followup-${DATE}-${FU_SLUG}.md"
      echo "$FOLLOWUP_RESPONSE" > "$FU_FILE"
      echo "    Queued: $(basename "$FU_FILE")"
      log_activity "followup-draft" "${TO_FIRM:-unknown}" "queued" "$FU_FILE"
      FOLLOWUP_COUNT=$((FOLLOWUP_COUNT + 1))
    fi
  done

  echo ""
  if [ "$FOLLOWUP_COUNT" -gt 0 ]; then
    echo "Generated $FOLLOWUP_COUNT follow-up drafts."
    echo "Review in: $QUEUE_DIR/"
  else
    echo "No follow-ups needed — no sent emails older than $DAYS days without reply."
  fi
}

# ── Command: leads ──

cmd_leads() {
  local FILTER="${1:-all}"

  echo "━━━ LEAD DATABASES ━━━"
  echo ""

  for f in "$LEADS_DIR"/*.json; do
    [ ! -f "$f" ] && continue
    [[ "$(basename "$f")" == ._* ]] && continue

    local BASENAME
    BASENAME=$(basename "$f" .json)
    local TYPE
    TYPE=$(jq -r '.type // "?"' "$f" 2>/dev/null)
    local DESC
    DESC=$(jq -r '.description // "?"' "$f" 2>/dev/null)
    local COUNT
    COUNT=$(jq '.leads | length' "$f" 2>/dev/null || echo 0)
    local UPDATED
    UPDATED=$(jq -r '.last_updated // "?"' "$f" 2>/dev/null)

    if [ "$FILTER" != "all" ] && [ "$BASENAME" != "$FILTER" ]; then
      continue
    fi

    echo "[$BASENAME] $DESC"
    echo "  File: $f"
    echo "  Type: $TYPE | Leads: $COUNT | Updated: $UPDATED"
    echo ""

    if [ "$FILTER" != "all" ]; then
      # Show individual leads
      local NAME_FIELD="firm"
      case "$TYPE" in
        companies-ai) NAME_FIELD="company" ;;
        accelerators) NAME_FIELD="name" ;;
      esac

      jq -r --arg nf "$NAME_FIELD" '.leads[] | "  \(.[$nf] // .firm // .company // .name) — \(.focus // .focus_areas // [] | if type == "array" then join(", ") else . end)"' "$f" 2>/dev/null
    fi
  done
}

# ── Main routing ──

case "$COMMAND" in
  research)
    cmd_research "$@"
    ;;
  draft)
    cmd_draft "$@"
    ;;
  send)
    cmd_send "$@"
    ;;
  campaign)
    cmd_campaign "$@"
    ;;
  status)
    cmd_status
    ;;
  followup)
    cmd_followup "$@"
    ;;
  leads)
    cmd_leads "$@"
    ;;
  help|*)
    echo "━━━ OUTREACH ENGINE — InBharat Bot ━━━"
    echo ""
    echo "Investor/VC/Partnership outreach pipeline"
    echo ""
    echo "Commands:"
    echo "  research <company>                    Research a target (web search + AI summary)"
    echo "  draft <template> <lead-file> [--limit N]  Generate personalized email drafts"
    echo "  send <draft-file> <email>             Send an approved draft via SMTP"
    echo "  campaign <template> <lead-file> [--dry-run] [--limit N]"
    echo "                                        Generate all drafts for a campaign"
    echo "  status                                Show pipeline status"
    echo "  followup [--days 7]                   Generate follow-ups for unreplied emails"
    echo "  leads [name]                          List available lead databases"
    echo ""
    echo "Templates: $(ls "$TEMPLATES_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ', ' | sed 's/,$//')"
    echo "Lead files: $(ls "$LEADS_DIR"/*.json 2>/dev/null | xargs -I{} basename {} .json | tr '\n' ', ' | sed 's/,$//')"
    echo ""
    echo "Workflow:"
    echo "  1. Research targets:     ./outreach-engine.sh research \"Blume Ventures\""
    echo "  2. Draft campaign:       ./outreach-engine.sh campaign vc-cold-intro vc-india.json --limit 5"
    echo "  3. Review queue:         ls outreach/queue/"
    echo "  4. Approve & send:       ./outreach-engine.sh send <draft>.md recipient@email.com"
    echo "  5. Check status:         ./outreach-engine.sh status"
    echo "  6. Follow up (7 days):   ./outreach-engine.sh followup --days 7"
    echo ""
    echo "SAFETY: All drafts go to queue/ for manual review. Nothing auto-sends."
    ;;
esac
