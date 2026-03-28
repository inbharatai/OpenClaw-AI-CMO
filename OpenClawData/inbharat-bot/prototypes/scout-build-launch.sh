#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# scout-build-launch.sh — Full pipeline: Find problem → Build prototype → Launch
# Usage: ./scout-build-launch.sh [scan-mode]
# Modes: problems, projects, buildable, custom "query"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -uo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"
DATE=$(date '+%Y-%m-%d')

source "$BOT_ROOT/logging/bot-logger.sh"

SCAN_MODE="${1:-buildable}"
CUSTOM_QUERY="${2:-}"

bot_log "pipeline" "info" "=== Scout-Build-Launch Pipeline ==="
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SCOUT → BUILD → LAUNCH PIPELINE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── PHASE 1: SCOUT ──
echo "▶ PHASE 1: Scanning for buildable problems..."
echo ""

if [ "$SCAN_MODE" = "custom" ] && [ -n "$CUSTOM_QUERY" ]; then
  bash "$BOT_ROOT/opportunities/world-scanner.sh" custom "$CUSTOM_QUERY"
else
  bash "$BOT_ROOT/opportunities/world-scanner.sh" "$SCAN_MODE"
fi

# Find the latest report
LATEST_REPORT=$(ls -t "$BOT_ROOT/opportunities/reports"/world-scan-${DATE}-*.md 2>/dev/null | head -1)

if [ -z "$LATEST_REPORT" ] || [ ! -f "$LATEST_REPORT" ]; then
  bot_log "pipeline" "error" "No scan report generated"
  exit 1
fi

echo ""
echo "▶ PHASE 2: Picking best buildable opportunity..."
echo ""

# Ask Ollama to pick the single best buildable opportunity from the report
REPORT_CONTENT=$(cat "$LATEST_REPORT")

PICK_PROMPT="You are a startup product advisor. Read this opportunity scan report and pick the ONE opportunity that:
1. Can be built as a working prototype in under 300 lines of code
2. Solves a real, specific problem (not vague)
3. Could be useful to real users immediately
4. Aligns with InBharat AI's products (education AI, government AI, personal AI tools)

Report:
$REPORT_CONTENT

Respond with ONLY a JSON object (no markdown, no explanation):
{
  \"problem\": \"<1-2 sentence description of what to build>\",
  \"type\": \"web-app|cli-tool|api-tool|dashboard\",
  \"reason\": \"<why this is the best one to build>\",
  \"target_user\": \"<who will use this>\"
}"

PICK_RESPONSE=$(curl -s --max-time 60 "$OLLAMA_URL/api/generate" \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$PICK_PROMPT" '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.2, num_predict: 500}}')" \
  | jq -r '(.response // .thinking) // ""')

# Extract the problem description
PROBLEM=$(echo "$PICK_RESPONSE" | python3 -c "
import sys, json, re
text = sys.stdin.read()
# Try to find JSON in the response
match = re.search(r'\{[^}]+\}', text, re.DOTALL)
if match:
    try:
        data = json.loads(match.group())
        print(data.get('problem', ''))
    except:
        # Fall back to extracting problem field
        m = re.search(r'\"problem\":\s*\"([^\"]+)\"', text)
        print(m.group(1) if m else '')
else:
    print('')
" 2>/dev/null)

if [ -z "$PROBLEM" ]; then
  bot_log "pipeline" "warn" "Could not auto-pick a problem. Using first opportunity from report."
  # Fallback: extract first opportunity title from report
  PROBLEM=$(grep -m1 'Opportunity:' "$LATEST_REPORT" | sed 's/.*Opportunity: //' | head -c 100)
fi

if [ -z "$PROBLEM" ]; then
  echo "Could not identify a buildable problem from scan results."
  echo "Try: prototype-builder.sh \"<your problem description>\""
  exit 1
fi

echo "Selected problem: $PROBLEM"
echo "Picker analysis:"
echo "$PICK_RESPONSE" | head -10
echo ""

# ── PHASE 3: BUILD ──
echo "▶ PHASE 3: Building prototype..."
echo ""

bash "$BOT_ROOT/prototypes/prototype-builder.sh" "$PROBLEM"

# Find the latest build
LATEST_BUILD=$(ls -dt "$BOT_ROOT/prototypes/builds"/${DATE}-*/ 2>/dev/null | head -1)

if [ -z "$LATEST_BUILD" ] || [ ! -d "$LATEST_BUILD" ]; then
  bot_log "pipeline" "error" "Prototype build failed"
  exit 1
fi

# ── PHASE 4: LAUNCH ──
echo ""
echo "▶ PHASE 4: Launching prototype..."
echo ""

bash "$BOT_ROOT/prototypes/launcher.sh" "$LATEST_BUILD" --local

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PIPELINE COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Scanned: $SCAN_MODE"
echo "  Problem: $PROBLEM"
echo "  Built:   $LATEST_BUILD"
echo "  Status:  LIVE (local)"
echo ""
echo "  Package for deploy: bash inbharat-run.sh prototype package \"$LATEST_BUILD\""

bot_log "pipeline" "info" "=== Pipeline complete: $PROBLEM ==="
