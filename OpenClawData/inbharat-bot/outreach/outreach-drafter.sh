#!/bin/bash
# InBharat Bot — Outreach Email Drafter
# Usage: ./outreach-drafter.sh "<context>"
# Output: Draft email in outreach/drafts/ + log entry in outreach/log/

set -uo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
SKILLS_DIR="$BOT_ROOT/skills"
DRAFTS_DIR="$BOT_ROOT/outreach/drafts"
OUTREACH_LOG_DIR="$BOT_ROOT/outreach/log"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
DATE=$(date '+%Y-%m-%d')

source "$BOT_ROOT/logging/bot-logger.sh"

mkdir -p "$DRAFTS_DIR" "$OUTREACH_LOG_DIR"

CONTEXT="${1:-}"
if [ -z "$CONTEXT" ]; then
  echo "Usage: outreach-drafter.sh \"<context>\""
  echo "Example: outreach-drafter.sh \"introduce InBharat to ICDS department for Anganwadi AI\""
  exit 1
fi

bot_log "outreach" "info" "=== Outreach drafter started ==="
bot_log "outreach" "info" "Context: $CONTEXT"

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
  bot_log "outreach" "error" "Ollama not running"
  exit 1
fi

# Load skill instructions
SKILL_FILE="$SKILLS_DIR/professional-email-drafter/SKILL.md"
if [ ! -f "$SKILL_FILE" ]; then
  bot_log "outreach" "error" "Skill file not found: $SKILL_FILE"
  exit 1
fi

SKILL_BODY=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$SKILL_FILE")

PROMPT="$SKILL_BODY

---

TASK: Draft an outreach email based on this context:
$CONTEXT

Today's date is $DATE. Use this exact date in the frontmatter.

CRITICAL: Do not invent statistics, pilot results, or metrics that are not provided in the context. Do not claim partnerships or deployments that are not specified. Only state what is true based on the context above.

Output ONLY the email in the specified markdown format with frontmatter."

# Call Ollama
bot_log "outreach" "info" "Generating draft via $MODEL..."

RESPONSE=$(curl -s --max-time 120 "$OLLAMA_URL/api/generate" \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.4, num_predict: 2000}}')" \
  | jq -r '(.response // .thinking) // "ERROR: No response from model"')

if [ "$RESPONSE" = "ERROR: No response from model" ] || [ -z "$RESPONSE" ]; then
  bot_log "outreach" "error" "Ollama did not respond"
  exit 1
fi

# Save draft
SLUG=$(echo "$CONTEXT" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
SLUG="${SLUG:0:40}"
DRAFT_FILE="$DRAFTS_DIR/email-${DATE}-${SLUG}.md"

echo "$RESPONSE" > "$DRAFT_FILE"

# Log outreach activity
OUTREACH_LOG_FILE="$OUTREACH_LOG_DIR/outreach-${DATE}.jsonl"
CONTEXT_JSON=$(echo "$CONTEXT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))' 2>/dev/null || echo "\"$CONTEXT\"")
jq -cn \
  --arg date "$DATE" \
  --arg time "$(date '+%H:%M:%S')" \
  --arg type "email-draft" \
  --arg context "$CONTEXT" \
  --arg draft_file "$DRAFT_FILE" \
  --arg status "drafted" \
  '{date: $date, time: $time, type: $type, context: $context, draft_file: $draft_file, status: $status}' \
  >> "$OUTREACH_LOG_FILE" 2>/dev/null || echo "{\"date\":\"$DATE\",\"type\":\"email-draft\",\"context\":$CONTEXT_JSON,\"status\":\"drafted\"}" >> "$OUTREACH_LOG_FILE"

bot_log "outreach" "info" "Draft saved: $DRAFT_FILE"
bot_log_evidence "outreach" "email-draft" "$DRAFT_FILE" "success"

echo ""
echo "━━━ OUTREACH DRAFT COMPLETE ━━━"
echo "Draft: $DRAFT_FILE"
echo ""
echo "--- Preview ---"
head -20 "$DRAFT_FILE"
echo ""
echo "--- Actions ---"
echo "  Review: read $DRAFT_FILE"
echo "  Edit: edit $DRAFT_FILE"
echo "  Send: copy to Gmail or use Gmail MCP (when configured)"
