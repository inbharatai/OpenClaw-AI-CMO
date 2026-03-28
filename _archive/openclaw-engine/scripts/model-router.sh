#!/bin/bash
# ============================================================
# model-router.sh — 3-Layer Model Router
# Now supports: fast | thinking | recorder layers
# Usage: ./model-router.sh "<task description>" [fast|think|auto]
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$WORKSPACE_ROOT/logs/model-routing.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"

FAST_MODEL="${FAST_MODEL:-mistral-small3.1:latest}"
FAST_FALLBACK="${FAST_FALLBACK:-qwen2.5-coder:7b}"
THINK_MODEL="${THINK_MODEL:-qwen3:8b}"

if [ -z "$1" ]; then
    echo "Usage: $0 \"<task description>\" [fast|think|auto]"
    exit 1
fi

TASK="$1"
FORCE_LAYER="${2:-auto}"
TASK_LOWER=$(echo "$TASK" | tr '[:upper:]' '[:lower:]')

if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "ERROR: Ollama not running"
    exit 1
fi

# Resolve fast model availability
AVAILABLE=$(curl -s --max-time 3 "$OLLAMA_URL/api/tags" 2>/dev/null)
RESOLVED_FAST="$FAST_MODEL"
if ! echo "$AVAILABLE" | grep -q "$FAST_MODEL"; then
    RESOLVED_FAST="$FAST_FALLBACK"
fi

# Forced layer
if [ "$FORCE_LAYER" = "fast" ]; then
    echo "$RESOLVED_FAST"
    echo "[$TIMESTAMP] FAST (forced): $(echo "$TASK" | head -c 60) → $RESOLVED_FAST" >> "$LOG_FILE"
    exit 0
fi
if [ "$FORCE_LAYER" = "think" ]; then
    echo "$THINK_MODEL"
    echo "[$TIMESTAMP] THINK (forced): $(echo "$TASK" | head -c 60) → $THINK_MODEL" >> "$LOG_FILE"
    exit 0
fi

# Auto-routing
SELECTED=""
REASON=""

# FAST tasks
FAST_KW="format|summarize|summary|classify|route|adapt|caption|tweet|announce|discord|short|extract|translate|rewrite|metadata|status|pre-check|credential|risk-score|duplicate"

# THINKING tasks
THINK_KW="strategy|plan|architect|research|synthesis|long.*article|complex|campaign.*design|comparison.*deep|educational|weekly.*roundup|newsletter.*full|monthly.*review|analysis|reasoning"

# CODE tasks (use fast/coder)
CODE_KW="code|script|python|bash|javascript|json|csv|regex|parse|api|endpoint|function|debug|sql|query"

if echo "$TASK_LOWER" | grep -qE "$THINK_KW"; then
    SELECTED="$THINK_MODEL"
    REASON="Thinking keywords detected"
elif echo "$TASK_LOWER" | grep -qE "$CODE_KW"; then
    SELECTED="$RESOLVED_FAST"
    REASON="Code task → fast/coder model"
elif echo "$TASK_LOWER" | grep -qE "$FAST_KW"; then
    SELECTED="$RESOLVED_FAST"
    REASON="Fast-eligible task"
else
    SELECTED="$RESOLVED_FAST"
    REASON="Default → fast layer (no deep reasoning needed)"
fi

echo "$SELECTED"
echo "[$TIMESTAMP] $REASON: $(echo "$TASK" | head -c 60) → $SELECTED" >> "$LOG_FILE"
