#!/bin/bash
# model-router.sh — REAL enforcement: selects the correct Ollama model based on task type
# Usage: ./model-router.sh "<task description>"
# Outputs: model name to stdout, logs decision
# This is ACTUAL routing logic, not prompt guidance.

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/model-routing.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
OLLAMA_URL="http://127.0.0.1:11434"

CODING_MODEL="qwen3:8b"
GENERAL_MODEL="qwen3:8b"

if [ -z "$1" ]; then
    echo "ERROR: No task description provided"
    echo "Usage: $0 \"<task description>\""
    exit 1
fi

TASK="$1"
TASK_LOWER=$(echo "$TASK" | tr '[:upper:]' '[:lower:]')

# Check Ollama is running
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "ERROR: Ollama is not running at $OLLAMA_URL"
    echo "[$TIMESTAMP] ERROR: Ollama not running. Task: $TASK" >> "$LOG_FILE"
    exit 1
fi

# Routing logic — keyword-based, deterministic
SELECTED=""
REASON=""

# Code keywords
CODE_KEYWORDS="code|script|python|bash|javascript|function|debug|api|json|csv|regex|parse|automat|deploy|build|compile|syntax|variable|loop|import|class|def |git |npm|pip|curl|fetch|endpoint|database|sql|query|schema|migration"

# Marketing/strategy keywords
MARKETING_KEYWORDS="marketing|caption|campaign|brand|content|strategy|rewrite|rephrase|summarize|summary|plan|creative|social media|instagram|linkedin|email|newsletter|headline|copy|audience|engagement|tone|voice|brief|calendar|trend|competitor|research|lead|opportunity|report|briefing"

if echo "$TASK_LOWER" | grep -qE "$CODE_KEYWORDS"; then
    SELECTED="$CODING_MODEL"
    REASON="Task contains coding/technical keywords"
elif echo "$TASK_LOWER" | grep -qE "$MARKETING_KEYWORDS"; then
    SELECTED="$GENERAL_MODEL"
    REASON="Task contains marketing/strategy keywords"
else
    SELECTED="$GENERAL_MODEL"
    REASON="Default: no strong signal, routing to general model"
fi

# Verify selected model is available
if ! curl -s --max-time 5 "$OLLAMA_URL/api/tags" | grep -q "\"$SELECTED\""; then
    echo "WARNING: $SELECTED not found in Ollama, checking fallback..."
    if [ "$SELECTED" = "$CODING_MODEL" ]; then
        SELECTED="$GENERAL_MODEL"
    else
        SELECTED="$CODING_MODEL"
    fi
    REASON="$REASON (FALLBACK: primary model unavailable)"
fi

echo "$SELECTED"
echo "[$TIMESTAMP] Task: $(echo "$TASK" | head -c 80) → Model: $SELECTED | Reason: $REASON" >> "$LOG_FILE"
