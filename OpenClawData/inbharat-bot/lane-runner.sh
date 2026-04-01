#!/bin/bash
# lane-runner.sh — Generic lane execution engine for InBharat Bot
# Runs any skill with optional web search context
# Usage: ./lane-runner.sh <skill-name> [--search "queries..."] [--context "text..."] [--output-dir dir] [--mode mode]
#
# This is the execution backbone for all InBharat Bot lanes.
# Each lane skill (india-problem-scanner, ai-gap-analyzer, etc.) is a prompt template.
# This script feeds real data + skill instructions to Ollama and saves structured output.

set -o pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"
DATE=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

# Source logger safely
if [ -f "$BOT_ROOT/logging/bot-logger.sh" ]; then
  source "$BOT_ROOT/logging/bot-logger.sh"
else
  bot_log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$2] [$1] $3"; }
fi

# Parse arguments
SKILL_NAME=""
SEARCH_QUERIES=""
CONTEXT=""
OUTPUT_DIR=""
MODE="default"
EXTRA_PROMPT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --search)
      [ $# -lt 2 ] && { echo "ERROR: --search requires a value"; exit 1; }
      SEARCH_QUERIES="$2"; shift ;;
    --context)
      [ $# -lt 2 ] && { echo "ERROR: --context requires a value"; exit 1; }
      CONTEXT="$2"; shift ;;
    --output-dir)
      [ $# -lt 2 ] && { echo "ERROR: --output-dir requires a value"; exit 1; }
      OUTPUT_DIR="$2"; shift ;;
    --mode)
      [ $# -lt 2 ] && { echo "ERROR: --mode requires a value"; exit 1; }
      MODE="$2"; shift ;;
    --extra)
      [ $# -lt 2 ] && { echo "ERROR: --extra requires a value"; exit 1; }
      EXTRA_PROMPT="$2"; shift ;;
    -*) echo "Unknown flag: $1"; exit 1 ;;
    *) [ -z "$SKILL_NAME" ] && SKILL_NAME="$1" ;;
  esac
  shift
done

if [ -z "$SKILL_NAME" ]; then
  echo "Usage: lane-runner.sh <skill-name> [--search \"queries\"] [--context \"text\"] [--output-dir dir]"
  echo ""
  echo "Available bot skills:"
  ls "$BOT_ROOT/skills" 2>/dev/null | sort
  exit 1
fi

# Resolve skill file — check bot skills first, then CMO skills
SKILL_FILE="$BOT_ROOT/skills/$SKILL_NAME/SKILL.md"
if [ ! -f "$SKILL_FILE" ]; then
  SKILL_FILE="$WORKSPACE_ROOT/OpenClawData/skills/$SKILL_NAME/SKILL.md"
fi
if [ ! -f "$SKILL_FILE" ]; then
  echo "ERROR: Skill '$SKILL_NAME' not found"
  exit 1
fi

# Default output directory
if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$BOT_ROOT/reports"
fi
mkdir -p "$OUTPUT_DIR"

bot_log "lane-runner" "info" "=== Lane: $SKILL_NAME | mode: $MODE ==="

# Check Ollama is running
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
  bot_log "lane-runner" "error" "Ollama not running"
  echo "ERROR: Ollama not running at $OLLAMA_URL"
  exit 1
fi

# Verify model is available
MODEL_CHECK=$(curl -s --max-time 5 "$OLLAMA_URL/api/tags" | python3 -c "
import sys, json
try:
    models = [m['name'] for m in json.load(sys.stdin).get('models', [])]
    print('available' if any('$MODEL' in m for m in models) else 'missing')
except: print('error')
" 2>/dev/null)

if [ "$MODEL_CHECK" = "missing" ]; then
  bot_log "lane-runner" "error" "Model $MODEL not available in Ollama"
  echo "ERROR: Model $MODEL not pulled. Run: ollama pull $MODEL"
  exit 1
fi

# ── Lock file to prevent concurrent runs of same skill ──
LOCK_FILE="/tmp/lane-runner-${SKILL_NAME}.lock"
if [ -f "$LOCK_FILE" ]; then
  LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
  if kill -0 "$LOCK_PID" 2>/dev/null; then
    echo "ERROR: $SKILL_NAME already running (PID $LOCK_PID)"
    exit 1
  else
    rm -f "$LOCK_FILE"
  fi
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# ── Web Search (if search queries provided) ──
SEARCH_RESULTS=""
if [ -n "$SEARCH_QUERIES" ]; then
  bot_log "lane-runner" "info" "Running web searches..."

  # Split queries by | delimiter
  IFS='|' read -ra QUERIES <<< "$SEARCH_QUERIES"

  for QUERY in "${QUERIES[@]}"; do
    QUERY=$(echo "$QUERY" | xargs) # trim whitespace
    [ -z "$QUERY" ] && continue

    bot_log "lane-runner" "info" "  Searching: $QUERY"

    # URL-encode safely via environment variable (no shell injection)
    ENCODED_QUERY=$(python3 -c "import urllib.parse, os; print(urllib.parse.quote(os.environ.get('SEARCH_QUERY','')))" 2>/dev/null <<< "" || echo "")
    export SEARCH_QUERY="$QUERY"
    ENCODED_QUERY=$(python3 -c "import urllib.parse, os; print(urllib.parse.quote(os.environ['SEARCH_QUERY']))" 2>/dev/null)

    if [ -z "$ENCODED_QUERY" ]; then
      bot_log "lane-runner" "warn" "  Failed to encode query, skipping"
      continue
    fi

    RESULT=$(curl -s --max-time 15 -w "\n%{http_code}" \
      -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" \
      "https://lite.duckduckgo.com/lite/?q=${ENCODED_QUERY}" \
      2>/dev/null)

    # Check HTTP status
    HTTP_CODE=$(echo "$RESULT" | tail -1)
    BODY=$(echo "$RESULT" | sed '$d')

    if [ "$HTTP_CODE" != "200" ] && [ -n "$HTTP_CODE" ]; then
      bot_log "lane-runner" "warn" "  Search returned HTTP $HTTP_CODE for: $QUERY"
      continue
    fi

    PARSED=$(echo "$BODY" | python3 -c "
import sys, re, html
content = sys.stdin.read()
text = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.DOTALL)
text = re.sub(r'<style[^>]*>.*?</style>', '', text, flags=re.DOTALL)
text = re.sub(r'<[^>]+>', ' ', text)
text = html.unescape(text)
lines = [l.strip() for l in text.split('\n') if l.strip() and len(l.strip()) > 30]
skip = ['DuckDuckGo', 'Privacy', 'Settings', 'About', 'Submit']
for line in lines[:12]:
    if not any(sw in line for sw in skip):
        print(line[:300])
" 2>/dev/null)

    if [ -n "$PARSED" ]; then
      SEARCH_RESULTS+="
--- Search: $QUERY ---
$PARSED
"
    fi
    sleep 1
  done

  # Save raw results
  mkdir -p "$OUTPUT_DIR/raw"
  echo "$SEARCH_RESULTS" > "$OUTPUT_DIR/raw/search-${SKILL_NAME}-${TIMESTAMP}.txt"
  bot_log "lane-runner" "info" "Collected ${#SEARCH_RESULTS} chars of search data"
fi

# ── Load Skill Instructions ──
SKILL_BODY=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$SKILL_FILE")
if [ -z "$SKILL_BODY" ]; then
  SKILL_BODY=$(cat "$SKILL_FILE")
fi

# ── Load Product Context (compact: one line per product) ──
PRODUCT_CONTEXT=""
STRATEGY_DIR="$WORKSPACE_ROOT/OpenClawData/strategy/product-truth"
if [ -d "$STRATEGY_DIR" ]; then
  PRODUCT_CONTEXT="
INBHARAT PRODUCTS (for relevance scoring):
"
  for TRUTH_FILE in "$STRATEGY_DIR"/*.md; do
    [ ! -f "$TRUTH_FILE" ] && continue
    [[ "$(basename "$TRUTH_FILE")" == ._* ]] && continue
    PRODUCT_NAME=$(basename "$TRUTH_FILE" .md)
    ONE_LINE=$(grep "^## One-Line Definition" -A 1 "$TRUTH_FILE" 2>/dev/null | tail -1)
    [ -n "$ONE_LINE" ] && PRODUCT_CONTEXT+="- $PRODUCT_NAME: $ONE_LINE
"
  done
fi

# ── Build Prompt (structured to survive truncation) ──
# CRITICAL: Task instruction goes FIRST so it survives any model-level context truncation.
# Data goes after instructions. If anything gets cut, it's data, not the task.

TASK_INSTRUCTION="
---
TASK: Execute the skill instructions above using the provided data. Be thorough, evidence-based, and actionable.
Do NOT invent data, statistics, or organizations. Only reference what appears in the search results or context provided.
Do NOT fabricate citations, surveys, or percentage claims.
Output in the structured format specified by the skill.
---"

PROMPT="$SKILL_BODY

$TASK_INSTRUCTION

TODAY'S DATE: $DATE
MODE: $MODE
$PRODUCT_CONTEXT"

if [ -n "$SEARCH_RESULTS" ]; then
  # Truncate search results to fit context window
  TRUNCATED="${SEARCH_RESULTS:0:3500}"
  PROMPT+="
WEB SEARCH RESULTS:
$TRUNCATED
"
fi

if [ -n "$CONTEXT" ]; then
  PROMPT+="
ADDITIONAL CONTEXT:
${CONTEXT:0:2000}
"
fi

if [ -n "$EXTRA_PROMPT" ]; then
  PROMPT+="
$EXTRA_PROMPT
"
fi

# ── Strip any leaked thinking tags from prompt ──
PROMPT=$(echo "$PROMPT" | sed 's/<\/?think>//g')

# ── Call Ollama ──
# qwen3:8b context window is ~8192 tokens (~24000 chars). Leave room for response.
# Max prompt: 16000 chars. If over, warn but don't hard-truncate instructions.
PROMPT_LEN=${#PROMPT}
if [ "$PROMPT_LEN" -gt 16000 ]; then
  bot_log "lane-runner" "warn" "Prompt is ${PROMPT_LEN} chars (over 16000). Trimming search data."
  # Re-truncate search data more aggressively
  SEARCH_TRUNC="${SEARCH_RESULTS:0:1500}"
  PROMPT="$SKILL_BODY

$TASK_INSTRUCTION

TODAY'S DATE: $DATE
MODE: $MODE
$PRODUCT_CONTEXT
WEB SEARCH RESULTS:
$SEARCH_TRUNC
"
  [ -n "$EXTRA_PROMPT" ] && PROMPT+="$EXTRA_PROMPT
"
  PROMPT_LEN=${#PROMPT}
fi

bot_log "lane-runner" "info" "Generating via $MODEL (prompt: ${PROMPT_LEN} chars)..."
echo "Analyzing with $SKILL_NAME..."

RESPONSE=$(curl -s --max-time 300 "$OLLAMA_URL/api/generate" \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.3, num_predict: 3000}}')" \
  | jq -r '(.response // empty) // "ERROR: No response from model"')

if [ "$RESPONSE" = "ERROR: No response from model" ] || [ -z "$RESPONSE" ]; then
  bot_log "lane-runner" "error" "Ollama did not respond"
  echo "ERROR: No response from $MODEL"
  exit 1
fi

# ── Strip thinking tags from response ──
RESPONSE=$(echo "$RESPONSE" | sed 's/<think>.*<\/think>//g; s/<\/?think>//g')

# ── Save Output ──
# Use TIMESTAMP in filename to prevent same-day overwrites
OUTPUT_FILE="$OUTPUT_DIR/${SKILL_NAME}-${DATE}-${MODE}.md"
if [ -f "$OUTPUT_FILE" ]; then
  # Don't overwrite — use timestamped name
  OUTPUT_FILE="$OUTPUT_DIR/${SKILL_NAME}-${TIMESTAMP}-${MODE}.md"
fi
echo "$RESPONSE" > "$OUTPUT_FILE"

# ── Log Activity ──
LOG_DIR="$BOT_ROOT/logging"
jq -cn \
  --arg date "$DATE" \
  --arg time "$(date '+%H:%M:%S')" \
  --arg skill "$SKILL_NAME" \
  --arg mode "$MODE" \
  --arg output "$OUTPUT_FILE" \
  --arg status "complete" \
  --arg search_chars "${#SEARCH_RESULTS}" \
  --arg prompt_len "$PROMPT_LEN" \
  '{date: $date, time: $time, type: "lane-run", skill: $skill, mode: $mode, output: $output, status: $status, search_chars: $search_chars, prompt_chars: $prompt_len}' \
  >> "$LOG_DIR/lane-runs-${DATE}.jsonl" 2>/dev/null

# ── Log Model Usage (cost tracking) ──
USAGE_LOG_DIR="$WORKSPACE_ROOT/OpenClawData/logs"
mkdir -p "$USAGE_LOG_DIR"
PROMPT_CHARS=${#PROMPT}
RESPONSE_CHARS=${#RESPONSE}
jq -cn \
  --arg date "$DATE" \
  --arg time "$(date '+%H:%M:%S')" \
  --arg model "$MODEL" \
  --arg endpoint "$OLLAMA_URL" \
  --arg tier "local-free" \
  --arg skill "$SKILL_NAME" \
  --arg prompt_chars "$PROMPT_CHARS" \
  --arg response_chars "$RESPONSE_CHARS" \
  '{date: $date, time: $time, model: $model, endpoint: $endpoint, tier: $tier, skill: $skill, prompt_chars: $prompt_chars, response_chars: $response_chars, cost_estimate: "$0.00"}' \
  >> "$USAGE_LOG_DIR/model-usage-${DATE}.jsonl" 2>/dev/null

bot_log "lane-runner" "info" "Output saved: $OUTPUT_FILE"

echo ""
echo "━━━ LANE COMPLETE: $SKILL_NAME ━━━"
echo "Output: $OUTPUT_FILE"
echo ""
echo "--- Preview ---"
head -30 "$OUTPUT_FILE"
