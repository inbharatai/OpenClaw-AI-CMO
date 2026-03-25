#!/bin/bash
# ============================================================
# skill-runner.sh — Runs a skill through the 3-layer router
# Usage: ./skill-runner.sh <skill-name> "<prompt>" [fast|think|auto] [model-override]
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$WORKSPACE_ROOT/openclaw-engine/skills"

# Source the layer router and date context
source "$SCRIPT_DIR/date-context.sh"
source "$SCRIPT_DIR/layer-router.sh"

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <skill-name> \"<your prompt>\" [fast|think|auto] [model-override]"
    echo ""
    echo "Layers: fast (default, <5s) | think (deep, 15-60s) | auto (router decides)"
    echo ""
    echo "Available skills:"
    ls "$SKILLS_DIR" 2>/dev/null | sort
    exit 1
fi

SKILL_NAME="$1"
USER_PROMPT="$2"

# $3 can be a layer name (fast/think/auto) or a model name (qwen3:8b)
# Detect which it is
ARG3="${3:-auto}"
if echo "$ARG3" | grep -qE "^(fast|think|auto)$"; then
    LAYER="$ARG3"
    MODEL_OVERRIDE="$4"
else
    # $3 is a model name, not a layer
    LAYER="think"
    MODEL_OVERRIDE="$ARG3"
fi

SKILL_FILE="$SKILLS_DIR/$SKILL_NAME/SKILL.md"

if [ ! -f "$SKILL_FILE" ]; then
    echo "ERROR: Skill '$SKILL_NAME' not found at $SKILL_FILE"
    exit 1
fi

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "ERROR: Ollama is not running"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Skill:  $SKILL_NAME"
echo "Layer:  $LAYER"
echo "Model:  $([ "$LAYER" = "fast" ] && echo "$RESOLVED_FAST_MODEL" || echo "$THINK_MODEL")"
echo "Prompt: $(echo "$USER_PROMPT" | head -c 80)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

T_START=$(timer_start)

# Use model override if provided, otherwise use layer router
if [ -n "$MODEL_OVERRIDE" ]; then
    # Direct model call with date context
    SKILL_BODY=$(awk '/^---$/{c++;next}c>=2' "$SKILL_FILE")
    [ -z "$SKILL_BODY" ] && SKILL_BODY=$(cat "$SKILL_FILE")

    # Truncate skill body to prevent oversized prompts
    SKILL_EXCERPT=$(echo "$SKILL_BODY" | head -c 2000)

    # Write prompt to temp file — avoids shell escaping issues with long skill content
    PROMPT_TMP=$(mktemp /tmp/openclaw-prompt-XXXXXX.txt)
    printf '%s\n\n' "$DATE_CONTEXT" > "$PROMPT_TMP"
    printf 'You are a content creation expert. Follow the skill instructions below.\n--- SKILL: %s ---\n' "$SKILL_NAME" >> "$PROMPT_TMP"
    echo "$SKILL_EXCERPT" >> "$PROMPT_TMP"
    printf '\n--- END SKILL ---\n\nUSER REQUEST:\n%s\n' "$USER_PROMPT" >> "$PROMPT_TMP"

    # Call Ollama safely via Python helper
    python3 "$SCRIPT_DIR/ollama-call.py" "$PROMPT_TMP" "$MODEL_OVERRIDE" "$OLLAMA_URL"

    rm -f "$PROMPT_TMP"
else
    # Use the layer router
    llm_skill "$SKILL_NAME" "$USER_PROMPT" "$LAYER" "skill-$SKILL_NAME"
fi

ELAPSED=$(timer_elapsed_ms "$T_START")
record_event "skill-runner" "Skill=$SKILL_NAME Layer=$LAYER Elapsed=${ELAPSED}ms"
echo ""
echo "[${ELAPSED}ms]"
