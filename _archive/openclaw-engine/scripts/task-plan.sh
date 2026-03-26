#!/bin/bash
# task-plan.sh — REAL enforcement: creates a structured plan file from a goal
# Usage: ./task-plan.sh "<goal description>"
# Uses Ollama to decompose the goal, then saves a real plan file.
# This creates ACTUAL plan files, not prompt guidance.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SESSIONS_DIR="$WORKSPACE_ROOT/logs/sessions"
SCRIPTS_DIR="$WORKSPACE_ROOT/openclaw-engine/scripts"
OLLAMA_URL="http://127.0.0.1:11434"
TIMESTAMP=$(date '+%Y-%m-%d')
MODEL="qwen3:8b"

if [ -z "$1" ]; then
    echo "Usage: $0 \"<goal description>\""
    echo ""
    echo "Creates a structured task plan using Ollama ($MODEL)."
    echo "Plans are saved to: $SESSIONS_DIR/"
    exit 1
fi

GOAL="$1"
SLUG=$(echo "$GOAL" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | head -c 40)
PLAN_FILE="$SESSIONS_DIR/plan-$TIMESTAMP-$SLUG.md"

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "ERROR: Ollama is not running"
    exit 1
fi

echo "Creating plan for: $GOAL"
echo "Using model: $MODEL"
echo "Output: $PLAN_FILE"
echo ""

PLAN_PROMPT="Break down this goal into a practical step-by-step plan. Be specific and actionable.

Goal: $GOAL

Output the plan in EXACTLY this Markdown format:

# Plan: <Goal Title>

**Created:** $TIMESTAMP
**Status:** active

## Goal
<one sentence>

## Subtasks

### 1. <Task name>
- **Depends on:** none
- **Model:** qwen3:8b or qwen2.5-coder:7b (pick the right one)
- **Output:** <what this produces>
- **Done when:** <specific criteria>
- **Status:** pending

(continue for each subtask, max 8 subtasks)

## Notes
<any important constraints>

Keep it practical. Max 8 subtasks. Each must have clear completion criteria."

# Call Ollama
RESPONSE=$(curl -s "$OLLAMA_URL/api/chat" \
    -d "$(cat <<EOF
{
    "model": "$MODEL",
    "messages": [{"role": "user", "content": $(echo "$PLAN_PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}],
    "stream": false,
    "options": {"temperature": 0.5}
}
EOF
)" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('message', {}).get('content', 'ERROR: No content in response'))
except Exception as e:
    print(f'ERROR: {e}')
")

if [[ "$RESPONSE" == ERROR* ]]; then
    echo "$RESPONSE"
    exit 1
fi

# Save plan
echo "$RESPONSE" > "$PLAN_FILE"

# Verify
if [ -f "$PLAN_FILE" ]; then
    LINES=$(wc -l < "$PLAN_FILE" | tr -d ' ')
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Plan saved: $PLAN_FILE ($LINES lines)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "❌ Failed to save plan"
    exit 1
fi
