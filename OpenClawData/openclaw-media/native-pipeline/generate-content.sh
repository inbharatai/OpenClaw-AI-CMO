#!/bin/bash
# generate-content.sh — OpenClaw Native Social Content Generator
# Takes product truth + platform rules + content buckets → platform-native content packages
# Usage: ./generate-content.sh [--product <name>] [--bucket <name>] [--platform <name>] [--dry-run]
#
# This is Pipeline A: OpenClaw creates its own social content from product context.

set -uo pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
STRATEGY_DIR="$WORKSPACE_ROOT/OpenClawData/strategy"
MEDIA_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media"
SCHEMAS_DIR="$MEDIA_DIR/schemas"
TEMPLATES_DIR="$MEDIA_DIR/templates"
OUTPUT_DIR="$MEDIA_DIR/native-pipeline/output"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
BOT_ROOT="$WORKSPACE_ROOT/OpenClawData/inbharat-bot"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"
DATE=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

source "$BOT_ROOT/logging/bot-logger.sh"

# Parse arguments
TARGET_PRODUCT=""
TARGET_BUCKET=""
TARGET_PLATFORM=""
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    --product) TARGET_PRODUCT="$2"; shift ;;
    --bucket) TARGET_BUCKET="$2"; shift ;;
    --platform) TARGET_PLATFORM="$2"; shift ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
  shift
done

mkdir -p "$OUTPUT_DIR"

bot_log "native-pipeline" "info" "=== OpenClaw Native Content Generator ==="

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
  echo "ERROR: Ollama not running"
  exit 1
fi

# ── Load Product Truth ──
PRODUCT_CONTEXT=""
if [ -n "$TARGET_PRODUCT" ]; then
  TRUTH_FILE="$STRATEGY_DIR/product-truth/${TARGET_PRODUCT}.md"
  if [ -f "$TRUTH_FILE" ]; then
    PRODUCT_CONTEXT=$(cat "$TRUTH_FILE" | head -c 2000)
  else
    echo "ERROR: Product truth file not found: $TRUTH_FILE"
    echo "Available: $(ls "$STRATEGY_DIR/product-truth/" 2>/dev/null | sed 's/.md//g' | tr '\n' ', ')"
    exit 1
  fi
else
  # Load all product summaries for broader content
  for F in "$STRATEGY_DIR/product-truth"/*.md; do
    [ ! -f "$F" ] && continue
    PNAME=$(basename "$F" .md)
    ONE_LINE=$(grep "^## One-Line Definition" -A 1 "$F" 2>/dev/null | tail -1)
    DIFF=$(grep "^## Strongest Differentiators" -A 5 "$F" 2>/dev/null | tail -4)
    PRODUCT_CONTEXT+="
--- $PNAME ---
$ONE_LINE
$DIFF
"
  done
fi

# ── Load Platform Rules ──
PLATFORM_RULES=""
if [ -n "$TARGET_PLATFORM" ]; then
  RULE_FILE="$STRATEGY_DIR/platform-rules/${TARGET_PLATFORM}.md"
  [ -f "$RULE_FILE" ] && PLATFORM_RULES=$(cat "$RULE_FILE" | head -c 1500)
else
  # Load all platform rules (summarized)
  for F in "$STRATEGY_DIR/platform-rules"/*.md; do
    [ ! -f "$F" ] && continue
    PNAME=$(basename "$F" .md)
    SUMMARY=$(head -20 "$F")
    PLATFORM_RULES+="
--- $PNAME ---
$SUMMARY
"
  done
fi

# ── Load Content Buckets ──
BUCKETS=$(cat "$STRATEGY_DIR/content-buckets.md" 2>/dev/null | head -c 1500)

# ── Load Approval Policy ──
APPROVAL_POLICY=$(cat "$STRATEGY_DIR/approval-policy.md" 2>/dev/null | head -c 500)

# ── Load Website & Company Context ──
WEBSITE_CONTEXT=""
if [ -f "$STRATEGY_DIR/website-context.md" ]; then
  WEBSITE_CONTEXT=$(cat "$STRATEGY_DIR/website-context.md" | head -c 2500)
fi

# ── Load Content Package Schema ──
PACKAGE_SCHEMA=$(cat "$SCHEMAS_DIR/content-package-schema.json" 2>/dev/null)

# ── Determine what to generate ──
BUCKET_INSTRUCTION=""
if [ -n "$TARGET_BUCKET" ]; then
  BUCKET_INSTRUCTION="Generate content for the '$TARGET_BUCKET' bucket specifically."
else
  BUCKET_INSTRUCTION="Choose the most timely and impactful bucket from the approved list. Consider what would perform best right now."
fi

PLATFORM_INSTRUCTION=""
if [ -n "$TARGET_PLATFORM" ]; then
  PLATFORM_INSTRUCTION="Generate content optimized for $TARGET_PLATFORM specifically."
else
  PLATFORM_INSTRUCTION="Generate content for the platforms most appropriate for the chosen bucket."
fi

# ── Build Prompt ──
PROMPT="You are OpenClaw's native social content generation engine for InBharat AI.

COMPANY & WEBSITE CONTEXT:
$WEBSITE_CONTEXT

PRODUCT TRUTH:
$PRODUCT_CONTEXT

CONTENT BUCKETS:
$BUCKETS

PLATFORM RULES:
$PLATFORM_RULES

CONTENT PACKAGE SCHEMA:
$PACKAGE_SCHEMA

---

TODAY'S DATE: $DATE
$BUCKET_INSTRUCTION
$PLATFORM_INSTRUCTION

TASK: Generate a complete content package that is ready to post.

You must output a valid JSON content package following the schema above.

Include all of these in your JSON:
- content_id: CP-$DATE-001
- source_pipeline: \"native\"
- source_campaign_id: null
- product: the product this content is about
- bucket: the content bucket
- goal: what this post aims to achieve
- platforms: array of target platforms
- hook: the attention-grabbing opening line
- summary: 1-2 sentence summary
- platform_content: object with platform-specific versions:
  - instagram_caption (if targeting instagram)
  - shorts_title + shorts_description (if targeting shorts)
  - linkedin_post (if targeting linkedin)
  - x_tweet (if targeting x)
  - discord_message (if targeting discord)
- image_brief: description for image generation (or null)
- video_brief: description for short video (or null)
- cover_brief: thumbnail/cover description (or null)
- proof_requirements: what proof is needed
- cta: call to action
- restricted_claims: claims NOT to make
- status: \"draft\"
- approval_level: L1/L2/L3
- created_date: $DATE

RULES:
- Content must be real, grounded, and based on actual product truth
- Do NOT invent features, users, statistics, or testimonials
- Do NOT make claims not supported by the product truth files
- Match the tone and format to each platform's rules
- Instagram captions: engaging, visual-first, max 2200 chars, 5-10 hashtags
- LinkedIn posts: professional, insight-led, max 3000 chars
- X tweets: punchy, max 280 chars
- Shorts titles: curiosity-driven, max 100 chars
- Discord: community-friendly, informative

Output ONLY the JSON content package. No markdown wrapping."

bot_log "native-pipeline" "info" "Generating native content..."

if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Would generate content package"
  echo "  Product: ${TARGET_PRODUCT:-auto}"
  echo "  Bucket: ${TARGET_BUCKET:-auto}"
  echo "  Platform: ${TARGET_PLATFORM:-all}"
  exit 0
fi

# ── Call Ollama ──
# Smart prompt truncation: cut data, not instructions
PROMPT_LEN=${#PROMPT}
if [ "$PROMPT_LEN" -gt 16000 ]; then
  bot_log "native-pipeline" "warn" "Prompt is ${PROMPT_LEN} chars, trimming data sections"
  PROMPT="${PROMPT:0:16000}"
fi

RESPONSE=$(curl -s --max-time 300 "$OLLAMA_URL/api/generate" \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.5, num_predict: 2500}}')" \
  | jq -r '(.response // empty) // "ERROR: No response"')

if [ "$RESPONSE" = "ERROR: No response" ] || [ -z "$RESPONSE" ]; then
  bot_log "native-pipeline" "error" "Ollama did not respond"
  exit 1
fi

# Strip thinking tags from response
RESPONSE=$(echo "$RESPONSE" | sed 's/<think>.*<\/think>//g; s/<\/?think>//g')

# ── Save output ──
SLUG="${TARGET_PRODUCT:-mixed}"
[ -n "$TARGET_BUCKET" ] && SLUG="${SLUG}-${TARGET_BUCKET}"
OUTPUT_FILE="$OUTPUT_DIR/content-package-${DATE}-${SLUG}.json"
echo "$RESPONSE" > "$OUTPUT_FILE"

# ── Try to validate JSON and extract key info ──
IS_VALID=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    # Try to extract JSON from response (may have markdown wrapping)
    text = sys.stdin.read()
    # Strip markdown code fences if present
    if '\`\`\`json' in text:
        text = text.split('\`\`\`json')[1].split('\`\`\`')[0]
    elif '\`\`\`' in text:
        text = text.split('\`\`\`')[1].split('\`\`\`')[0]
    data = json.loads(text.strip())
    print('VALID')
    print(json.dumps(data, indent=2))
except:
    print('INVALID')
    print(text[:200] if 'text' in dir() else 'parse error')
" 2>/dev/null)

VALID_STATUS=$(echo "$IS_VALID" | head -1)

if [ "$VALID_STATUS" = "VALID" ]; then
  # Extract clean JSON
  CLEAN_JSON=$(echo "$IS_VALID" | tail -n +2)
  echo "$CLEAN_JSON" > "$OUTPUT_FILE"

  # Extract platforms and route to queues
  PLATFORMS=$(echo "$CLEAN_JSON" | python3 -c "import sys,json; [print(p) for p in json.load(sys.stdin).get('platforms',[])]" 2>/dev/null)
  APPROVAL=$(echo "$CLEAN_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('approval_level','L2'))" 2>/dev/null)

  for PLATFORM in $PLATFORMS; do
    QUEUE_DIR="$QUEUES_DIR/$PLATFORM/pending"
    mkdir -p "$QUEUE_DIR"
    cp "$OUTPUT_FILE" "$QUEUE_DIR/native-${DATE}-${SLUG}.json"
    bot_log "native-pipeline" "info" "Queued for $PLATFORM (approval: $APPROVAL)"
  done

  echo ""
  echo "━━━ NATIVE CONTENT PACKAGE GENERATED ━━━"
  echo "Package: $OUTPUT_FILE"
  echo "Status: Valid JSON ✅"
  echo "Platforms: $PLATFORMS"
  echo "Approval: $APPROVAL"
  echo ""
  echo "--- Preview ---"
  echo "$CLEAN_JSON" | python3 -c "
import sys,json
d = json.load(sys.stdin)
print(f\"Product: {d.get('product','?')}\")
print(f\"Bucket: {d.get('bucket','?')}\")
print(f\"Hook: {d.get('hook','?')[:100]}\")
print(f\"CTA: {d.get('cta','?')[:80]}\")
pc = d.get('platform_content',{})
for k,v in pc.items():
    if isinstance(v, str):
        print(f\"{k}: {v[:80]}...\")
" 2>/dev/null
else
  echo ""
  echo "━━━ CONTENT GENERATED (raw — JSON validation failed) ━━━"
  echo "Output: $OUTPUT_FILE"
  echo "Note: Content was generated but could not be parsed as clean JSON."
  echo "Manual review recommended."
  echo ""
  head -20 "$OUTPUT_FILE"
fi

# ── Post-generation claim validation (warn only, does not block) ──
CLAIM_VALIDATOR="$WORKSPACE_ROOT/OpenClawData/security/claim-validator.sh"
if [ -x "$CLAIM_VALIDATOR" ] && [ -f "$OUTPUT_FILE" ]; then
  bot_log "native-pipeline" "info" "Running claim validator on generated content..."
  CLAIM_OUTPUT=$("$CLAIM_VALIDATOR" "$OUTPUT_FILE" 2>&1)
  CLAIM_EXIT=$?
  if [ "$CLAIM_EXIT" -ne 0 ]; then
    bot_log "native-pipeline" "warn" "CLAIM VALIDATION WARNING: $OUTPUT_FILE has potential issues"
    echo ""
    echo "⚠️  CLAIM VALIDATION WARNING ⚠️"
    echo "The generated content has potential claim issues that should be reviewed before approval:"
    echo "$CLAIM_OUTPUT" | grep -E '(FABRICATED|SUSPICIOUS|LLM ARTIFACT|OVERSIZED|INVALID|TOO SHORT|BLOCKED)' | head -10
    echo ""
    echo "This content has been queued but may be blocked by the approval engine."
    echo "Edit the content package at: $OUTPUT_FILE"
  else
    bot_log "native-pipeline" "info" "Claim validation passed for $OUTPUT_FILE"
  fi
fi

# ── Post-generation image generation (optional — warn but don't block) ──
IMAGE_ENGINE="$WORKSPACE_ROOT/OpenClawData/openclaw-media/image-engine/generate-image.sh"
if [ -x "$IMAGE_ENGINE" ] && [ "$VALID_STATUS" = "VALID" ] && [ -f "$OUTPUT_FILE" ]; then
  IMAGE_BRIEF=$(echo "$CLEAN_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ib = data.get('image_brief')
    if ib and str(ib).strip() and str(ib) != 'null':
        print(str(ib))
except:
    pass
" 2>/dev/null)

  if [ -n "$IMAGE_BRIEF" ]; then
    bot_log "native-pipeline" "info" "Generating image for content package..."
    CONTENT_ID=$(echo "$CLEAN_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('content_id','unknown'))" 2>/dev/null)
    IMAGE_RESULT=$("$IMAGE_ENGINE" --brief "$IMAGE_BRIEF" --content-id "$CONTENT_ID" 2>&1)
    IMAGE_EXIT=$?
    if [ $IMAGE_EXIT -eq 0 ]; then
      IMAGE_PATH=$(echo "$IMAGE_RESULT" | tail -1)
      bot_log "native-pipeline" "info" "Image generated: $IMAGE_PATH"
      echo "Image: $IMAGE_PATH"

      # Update content package with image path
      python3 -c "
import json, sys
try:
    with open('$OUTPUT_FILE', 'r') as f:
        data = json.load(f)
    data['image_path'] = '$IMAGE_PATH'
    with open('$OUTPUT_FILE', 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print(f'Warning: Could not update package with image path: {e}', file=sys.stderr)
" 2>/dev/null
    else
      bot_log "native-pipeline" "warn" "Image generation failed (non-blocking): $IMAGE_RESULT"
      echo ""
      echo "WARNING: Image generation failed (content pipeline continues)"
      echo "  Brief: ${IMAGE_BRIEF:0:80}"
      echo "  Run manually: $IMAGE_ENGINE --brief \"$IMAGE_BRIEF\""
    fi
  fi
fi

# ── Log ──
jq -cn \
  --arg date "$DATE" \
  --arg time "$(date '+%H:%M:%S')" \
  --arg type "native-content" \
  --arg product "${TARGET_PRODUCT:-auto}" \
  --arg bucket "${TARGET_BUCKET:-auto}" \
  --arg output "$OUTPUT_FILE" \
  --arg valid "$VALID_STATUS" \
  '{date: $date, time: $time, type: $type, product: $product, bucket: $bucket, output: $output, json_valid: $valid}' \
  >> "$MEDIA_DIR/analytics/native-gen-${DATE}.jsonl" 2>/dev/null

bot_log "native-pipeline" "info" "Native content generation complete: $OUTPUT_FILE"
