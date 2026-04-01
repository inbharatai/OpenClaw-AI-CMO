#!/bin/bash
# amplify-handoff.sh — OpenClaw Amplification Pipeline
# Takes campaign briefs from InBharat Bot handoffs/ → generates platform-native content packages
# Usage: ./amplify-handoff.sh [--file <handoff-file>] [--all] [--dry-run]
#
# This is Pipeline B: OpenClaw converts InBharat Bot discoveries into social content.

set -uo pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
STRATEGY_DIR="$WORKSPACE_ROOT/OpenClawData/strategy"
MEDIA_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media"
BOT_ROOT="$WORKSPACE_ROOT/OpenClawData/inbharat-bot"
HANDOFFS_DIR="$BOT_ROOT/handoffs"
OUTPUT_DIR="$MEDIA_DIR/amplify-pipeline/output"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"
DATE=$(date '+%Y-%m-%d')

source "$BOT_ROOT/logging/bot-logger.sh"

TARGET_FILE=""
PROCESS_ALL=false
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    --file) TARGET_FILE="$2"; shift ;;
    --all) PROCESS_ALL=true ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
  shift
done

mkdir -p "$OUTPUT_DIR" "$HANDOFFS_DIR/processed"

bot_log "amplify-pipeline" "info" "=== OpenClaw Amplification Pipeline ==="

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
  echo "ERROR: Ollama not running"
  exit 1
fi

# ── Load platform rules (summarized) ──
PLATFORM_RULES=""
for F in "$STRATEGY_DIR/platform-rules"/*.md; do
  [ ! -f "$F" ] && continue
  PNAME=$(basename "$F" .md)
  PLATFORM_RULES+="
--- $PNAME ---
$(head -15 "$F")
"
done

# ── Load Website & Company Context ──
WEBSITE_CONTEXT=""
if [ -f "$STRATEGY_DIR/website-context.md" ]; then
  WEBSITE_CONTEXT=$(cat "$STRATEGY_DIR/website-context.md" | head -c 2500)
fi

# ── Find handoff files to process ──
HANDOFF_FILES=()
if [ -n "$TARGET_FILE" ]; then
  if [ -f "$TARGET_FILE" ]; then
    HANDOFF_FILES+=("$TARGET_FILE")
  else
    echo "ERROR: File not found: $TARGET_FILE"
    exit 1
  fi
elif [ "$PROCESS_ALL" = true ]; then
  for F in "$HANDOFFS_DIR"/*.md; do
    [ -f "$F" ] && HANDOFF_FILES+=("$F")
  done
else
  # Default: process latest unprocessed handoff
  LATEST=$(ls -t "$HANDOFFS_DIR"/*.md 2>/dev/null | head -1)
  if [ -n "$LATEST" ]; then
    HANDOFF_FILES+=("$LATEST")
  else
    echo "No handoffs to process."
    echo "Generate one first: bash inbharat-run.sh campaign generate"
    exit 0
  fi
fi

if [ ${#HANDOFF_FILES[@]} -eq 0 ]; then
  echo "No handoff files found in $HANDOFFS_DIR/"
  exit 0
fi

TOTAL_PROCESSED=0
TOTAL_PACKAGES=0

for HANDOFF_FILE in "${HANDOFF_FILES[@]}"; do
  FILENAME=$(basename "$HANDOFF_FILE")
  echo ""
  echo "━━━ Processing: $FILENAME ━━━"

  # Read handoff content
  HANDOFF_CONTENT=$(cat "$HANDOFF_FILE" | head -c 3000)

  # Try to extract JSON campaign brief from the handoff
  CAMPAIGN_JSON=$(echo "$HANDOFF_CONTENT" | python3 -c "
import sys, json, re
text = sys.stdin.read()
# Try to extract JSON block
match = re.search(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', text, re.DOTALL)
if match:
    try:
        data = json.loads(match.group())
        print(json.dumps(data))
    except:
        print('RAW')
else:
    print('RAW')
" 2>/dev/null)

  if [ "$CAMPAIGN_JSON" = "RAW" ] || [ -z "$CAMPAIGN_JSON" ]; then
    # Treat as free-form text brief
    BRIEF_TEXT="$HANDOFF_CONTENT"
    CAMPAIGN_ID="CAMP-${DATE}-manual"
  else
    BRIEF_TEXT="$CAMPAIGN_JSON"
    CAMPAIGN_ID=$(echo "$CAMPAIGN_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('campaign_id','CAMP-${DATE}-000'))" 2>/dev/null)
  fi

  bot_log "amplify-pipeline" "info" "Processing handoff: $FILENAME (ID: $CAMPAIGN_ID)"

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would generate content package from: $FILENAME"
    TOTAL_PROCESSED=$((TOTAL_PROCESSED + 1))
    continue
  fi

  # ── Build Prompt ──
  PROMPT="You are OpenClaw's amplification engine. Your job is to convert a campaign brief from InBharat Bot into platform-ready social content.

COMPANY & WEBSITE CONTEXT:
$WEBSITE_CONTEXT

CAMPAIGN BRIEF:
$BRIEF_TEXT

PLATFORM RULES:
$PLATFORM_RULES

TODAY'S DATE: $DATE

TASK: Generate a complete content package for social media amplification.

Output a valid JSON content package with these fields:
{
  \"content_id\": \"CP-$DATE-AMP-001\",
  \"source_pipeline\": \"amplify\",
  \"source_campaign_id\": \"$CAMPAIGN_ID\",
  \"product\": \"[product from brief]\",
  \"bucket\": \"[matching content bucket]\",
  \"goal\": \"[campaign goal]\",
  \"platforms\": [\"linkedin\", \"x\", \"instagram\", \"shorts\", \"discord\"],
  \"hook\": \"[attention-grabbing opening]\",
  \"summary\": \"[1-2 sentence summary]\",
  \"platform_content\": {
    \"linkedin_post\": \"[full LinkedIn post, professional, insight-led, max 3000 chars]\",
    \"x_tweet\": \"[punchy tweet, max 280 chars]\",
    \"x_thread\": [\"tweet 1\", \"tweet 2\", \"tweet 3\"],
    \"instagram_caption\": \"[engaging caption with hashtags]\",
    \"shorts_title\": \"[curiosity-driven title, max 100 chars]\",
    \"shorts_description\": \"[short description]\",
    \"discord_message\": \"[community-friendly message]\"
  },
  \"image_brief\": \"[description for image generation or null]\",
  \"video_brief\": \"[description for short video or null]\",
  \"cover_brief\": \"[thumbnail description or null]\",
  \"proof_requirements\": \"[what proof is needed]\",
  \"cta\": \"[call to action]\",
  \"restricted_claims\": [\"list of claims NOT to make\"],
  \"status\": \"draft\",
  \"approval_level\": \"L2\",
  \"created_date\": \"$DATE\"
}

RULES:
- Every piece of platform content must be native to that platform's style
- LinkedIn: professional, data-driven, insight-led
- X: punchy, conversational, thread-worthy
- Instagram: visual-first, story-driven, hashtag-rich
- Shorts: curiosity hook in first 3 seconds
- Discord: community-friendly, informative, discussion-starter
- Do NOT invent statistics, users, or testimonials
- Do NOT make claims not supported by the brief
- Match the priority and approval level from the brief
- restricted_claims must never be empty

Output ONLY the JSON. No markdown wrapping."

  # ── Call Ollama ──
  # Truncate prompt if over context window limit
  AMP_PROMPT_LEN=${#PROMPT}
  if [ "$AMP_PROMPT_LEN" -gt 16000 ]; then
    bot_log "amplify-pipeline" "warn" "Prompt is ${AMP_PROMPT_LEN} chars, trimming"
    PROMPT="${PROMPT:0:16000}"
  fi

  RESPONSE=$(curl -s --max-time 300 "$OLLAMA_URL/api/generate" \
    -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.5, num_predict: 3000}}')" \
    | jq -r '(.response // empty) // "ERROR: No response"')

  if [ "$RESPONSE" = "ERROR: No response" ] || [ -z "$RESPONSE" ]; then
    bot_log "amplify-pipeline" "error" "Ollama did not respond for $FILENAME"
    continue
  fi

  # Strip thinking tags from response
  RESPONSE=$(echo "$RESPONSE" | sed 's/<think>.*<\/think>//g; s/<\/?think>//g')

  # ── Save and validate ──
  SLUG=$(echo "$FILENAME" | sed 's/.md//' | tr ' ' '-')
  PACKAGE_FILE="$OUTPUT_DIR/amplified-${DATE}-${SLUG}.json"
  echo "$RESPONSE" > "$PACKAGE_FILE"

  # Try to extract and validate JSON
  CLEAN_JSON=$(echo "$RESPONSE" | python3 -c "
import sys, json
text = sys.stdin.read()
if '\`\`\`json' in text:
    text = text.split('\`\`\`json')[1].split('\`\`\`')[0]
elif '\`\`\`' in text:
    text = text.split('\`\`\`')[1].split('\`\`\`')[0]
try:
    data = json.loads(text.strip())
    print(json.dumps(data, indent=2))
except:
    print('INVALID')
" 2>/dev/null)

  if [ "$CLEAN_JSON" != "INVALID" ] && [ -n "$CLEAN_JSON" ]; then
    echo "$CLEAN_JSON" > "$PACKAGE_FILE"

    # Route to platform queues
    PLATFORMS=$(echo "$CLEAN_JSON" | python3 -c "import sys,json; [print(p) for p in json.load(sys.stdin).get('platforms',[])]" 2>/dev/null)
    for PLATFORM in $PLATFORMS; do
      QUEUE_DIR="$QUEUES_DIR/$PLATFORM/pending"
      mkdir -p "$QUEUE_DIR"
      cp "$PACKAGE_FILE" "$QUEUE_DIR/"
      bot_log "amplify-pipeline" "info" "Queued amplified content for $PLATFORM"
    done

    echo "  ✅ Valid JSON content package"
    echo "  Package: $PACKAGE_FILE"
    echo "  Platforms: $PLATFORMS"
    TOTAL_PACKAGES=$((TOTAL_PACKAGES + 1))
  else
    echo "  ⚠ Generated but JSON validation failed — manual review needed"
    echo "  Output: $PACKAGE_FILE"
  fi

  # Move handoff to processed
  mv "$HANDOFF_FILE" "$HANDOFFS_DIR/processed/" 2>/dev/null
  TOTAL_PROCESSED=$((TOTAL_PROCESSED + 1))

  # Log
  jq -cn \
    --arg date "$DATE" \
    --arg time "$(date '+%H:%M:%S')" \
    --arg handoff "$FILENAME" \
    --arg campaign_id "$CAMPAIGN_ID" \
    --arg output "$PACKAGE_FILE" \
    --arg valid "$([ "$CLEAN_JSON" != "INVALID" ] && echo 'true' || echo 'false')" \
    '{date: $date, time: $time, type: "amplification", handoff: $handoff, campaign_id: $campaign_id, output: $output, json_valid: $valid}' \
    >> "$MEDIA_DIR/analytics/amplify-gen-${DATE}.jsonl" 2>/dev/null

done

echo ""
echo "━━━ AMPLIFICATION COMPLETE ━━━"
echo "Handoffs processed: $TOTAL_PROCESSED"
echo "Packages created: $TOTAL_PACKAGES"
echo "Output: $OUTPUT_DIR/"
bot_log "amplify-pipeline" "info" "Amplification complete: $TOTAL_PROCESSED processed, $TOTAL_PACKAGES packages"
