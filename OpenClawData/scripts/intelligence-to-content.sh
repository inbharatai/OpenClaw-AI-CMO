#!/bin/bash
# intelligence-to-content.sh — Convert InBharat Bot intelligence reports into social content
#
# Scans bot output directories for new discoveries:
#   - ai-gaps/*.md        → "Market Gap Insight" posts
#   - opportunities/*.md  → "Opportunity Insight" posts
#
# For each new report, generates platform-specific posts with image_brief
# and queues them for approval. Tracks processed files to avoid duplicates.
#
# Usage:
#   ./intelligence-to-content.sh              Process all new intelligence
#   ./intelligence-to-content.sh --dry-run    Show what would be created
#
# Called from: daily-pipeline.sh Stage 1.5

set -o pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
BOT_DIR="$WORKSPACE_ROOT/OpenClawData/inbharat-bot"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
BRAND_KB="$WORKSPACE_ROOT/OpenClawData/strategy/brand-knowledge-base.json"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/intelligence-to-content.log"
STATE_FILE="$WORKSPACE_ROOT/OpenClawData/logs/intel-processed.log"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"
DATE_TAG=$(date '+%Y-%m-%d')

DRY_RUN=false
[ "$1" = "--dry-run" ] && DRY_RUN=true

mkdir -p "$(dirname "$LOG_FILE")"
touch "$STATE_FILE"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
  echo "$1"
}

log "=== Intelligence-to-Content Started ==="
[ "$DRY_RUN" = true ] && log "[DRY RUN]"

TOTAL=0
PRODUCED=0
SKIPPED=0

# Check Ollama is running
if ! curl -sf --max-time 5 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
  log "ERROR: Ollama not running. Skipping intelligence processing."
  exit 1
fi

# ── Process AI Gap Reports ──
process_intel_file() {
  local FILE="$1"
  local TYPE="$2"    # "gap" or "opportunity"
  local FILENAME=$(basename "$FILE")

  # Skip if already processed
  if grep -qF "$FILENAME" "$STATE_FILE" 2>/dev/null; then
    return
  fi

  TOTAL=$((TOTAL + 1))

  # Read the report content (first 1000 chars for context)
  local CONTENT
  CONTENT=$(head -c 1000 "$FILE")
  [ -z "$CONTENT" ] && return

  if [ "$DRY_RUN" = true ]; then
    log "[DRY RUN] Would process $TYPE: $FILENAME"
    return
  fi

  log "PROCESSING [$TYPE]: $FILENAME"

  # Determine which InBharat product is relevant
  local PRODUCT="inbharat"
  echo "$CONTENT" | grep -qi "healthcare\|anganwadi\|ICDS\|welfare" && PRODUCT="sahaayak-seva"
  echo "$CONTENT" | grep -qi "education\|exam\|test\|student" && PRODUCT="testsprep"
  echo "$CONTENT" | grep -qi "university\|college\|admission" && PRODUCT="uniassist"
  echo "$CONTENT" | grep -qi "communication\|calling\|phone\|forecast\|signal" && PRODUCT="phoring"
  echo "$CONTENT" | grep -qi "coding\|developer\|programming" && PRODUCT="codein"

  # Generate LinkedIn post
  local LI_PROMPT="You are an expert content writer for InBharat AI. Write a LinkedIn post (max 1500 chars, professional tone, thought leadership) about this ${TYPE} discovery. Connect it to how InBharat is addressing this. End with a CTA. No markdown formatting - plain text only. 0-3 hashtags at end.

Discovery: $CONTENT"

  local LI_OUT
  LI_OUT=$(curl -sf --max-time 120 "$OLLAMA_URL/api/generate" \
    -d "$(printf '%s' "$LI_PROMPT" | python3 -c "import json,sys; print(json.dumps({'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,'options':{'temperature':0.5,'num_predict':2000}}))")" 2>/dev/null \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('response',''))" 2>/dev/null)

  if [ -n "$LI_OUT" ] && [ ${#LI_OUT} -gt 50 ]; then
    local LI_FILE="$QUEUES_DIR/linkedin/pending/linkedin-${TYPE}-$DATE_TAG-$(echo "$FILENAME" | head -c 30 | tr ' ' '-').md"
    echo "$LI_OUT" > "$LI_FILE"
    log "  PRODUCED [linkedin]: $LI_FILE"
  fi

  # Generate X tweet
  local X_PROMPT="Write a single tweet (max 270 chars) about this AI ${TYPE} in India. Sharp, insightful, no fluff. 0-2 hashtags. No markdown. Plain text only.

Discovery: $(echo "$CONTENT" | head -c 300)"

  local X_OUT
  X_OUT=$(curl -sf --max-time 60 "$OLLAMA_URL/api/generate" \
    -d "$(printf '%s' "$X_PROMPT" | python3 -c "import json,sys; print(json.dumps({'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,'options':{'temperature':0.6,'num_predict':500}}))")" 2>/dev/null \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('response',''))" 2>/dev/null)

  if [ -n "$X_OUT" ] && [ ${#X_OUT} -gt 20 ]; then
    local X_FILE="$QUEUES_DIR/x/pending/x-${TYPE}-$DATE_TAG-$(echo "$FILENAME" | head -c 30 | tr ' ' '-').md"
    echo "$X_OUT" > "$X_FILE"
    log "  PRODUCED [x]: $X_FILE"
  fi

  # Generate Discord message
  local DISC_PROMPT="Write a short Discord community message (max 500 chars) sharing this AI ${TYPE} discovery with the InBharat community. Casual, friendly, informative. No markdown formatting.

Discovery: $(echo "$CONTENT" | head -c 300)"

  local DISC_OUT
  DISC_OUT=$(curl -sf --max-time 60 "$OLLAMA_URL/api/generate" \
    -d "$(printf '%s' "$DISC_PROMPT" | python3 -c "import json,sys; print(json.dumps({'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,'options':{'temperature':0.5,'num_predict':800}}))")" 2>/dev/null \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('response',''))" 2>/dev/null)

  if [ -n "$DISC_OUT" ] && [ ${#DISC_OUT} -gt 30 ]; then
    local DISC_FILE="$QUEUES_DIR/discord/pending/discord-${TYPE}-$DATE_TAG-$(echo "$FILENAME" | head -c 30 | tr ' ' '-').md"
    echo "$DISC_OUT" > "$DISC_FILE"
    log "  PRODUCED [discord]: $DISC_FILE"
  fi

  # Generate Instagram JSON with image_brief
  local INSTA_PROMPT="Write an Instagram caption (max 250 chars, engaging) about this AI ${TYPE}. Include 5-8 hashtags. Also provide IMAGE_BRIEF: <one sentence describing a visual>.

Discovery: $(echo "$CONTENT" | head -c 300)"

  local INSTA_OUT
  INSTA_OUT=$(curl -sf --max-time 60 "$OLLAMA_URL/api/generate" \
    -d "$(printf '%s' "$INSTA_PROMPT" | python3 -c "import json,sys; print(json.dumps({'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,'options':{'temperature':0.5,'num_predict':500}}))")" 2>/dev/null \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('response',''))" 2>/dev/null)

  if [ -n "$INSTA_OUT" ] && [ ${#INSTA_OUT} -gt 20 ]; then
    local INSTA_CAPTION
    INSTA_CAPTION=$(echo "$INSTA_OUT" | sed -n 's/.*CAPTION:\s*//p' | sed 's/IMAGE_BRIEF:.*//' | head -1)
    [ -z "$INSTA_CAPTION" ] && INSTA_CAPTION=$(echo "$INSTA_OUT" | head -c 250)
    local INSTA_BRIEF
    INSTA_BRIEF=$(echo "$INSTA_OUT" | sed -n 's/.*IMAGE_BRIEF:\s*//p' | head -1)
    [ -z "$INSTA_BRIEF" ] && INSTA_BRIEF="A clean visual about AI ${TYPE} discovery in India, modern design with InBharat brand colors"

    local INSTA_FILE="$QUEUES_DIR/instagram/pending/instagram-${TYPE}-$DATE_TAG-$(echo "$FILENAME" | head -c 25 | tr ' ' '-').json"
    export IC="$INSTA_CAPTION" IB="$INSTA_BRIEF" ID="$DATE_TAG" IP="$PRODUCT" IT="$TYPE" IF="$FILENAME"
    python3 << 'IGJSON' > "$INSTA_FILE"
import json, os
data = {
    "content_id": f"IG-{os.environ['IT'].upper()}-{os.environ['ID']}-{os.environ['IF'][:15]}",
    "platform_content": {"instagram_caption": os.environ['IC']},
    "image_brief": os.environ['IB'],
    "image_path": "",
    "product": os.environ['IP'],
    "approval_level": "L2",
    "status": "pending"
}
print(json.dumps(data, indent=2))
IGJSON
    log "  PRODUCED [instagram]: $INSTA_FILE"
  fi

  # Mark as processed
  echo "$FILENAME" >> "$STATE_FILE"
  PRODUCED=$((PRODUCED + 1))
}

# ── Scan intelligence directories ──

# AI Gaps
if [ -d "$BOT_DIR/ai-gaps" ]; then
  for f in "$BOT_DIR/ai-gaps"/*.md; do
    [ -f "$f" ] || continue
    process_intel_file "$f" "gap"
  done
fi

# Opportunities
if [ -d "$BOT_DIR/opportunities/reports" ]; then
  for f in "$BOT_DIR/opportunities/reports"/*.md; do
    [ -f "$f" ] || continue
    process_intel_file "$f" "opportunity"
  done
fi

log "=== Intelligence-to-Content Complete ==="
log "Total: $TOTAL | Produced: $PRODUCED | Skipped: $SKIPPED"

echo ""
echo "━━━ INTELLIGENCE-TO-CONTENT SUMMARY ━━━"
echo "Total new reports:  $TOTAL"
echo "Content produced:   $PRODUCED"
echo "Skipped:           $SKIPPED"
