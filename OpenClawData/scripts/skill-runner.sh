#!/bin/bash
# skill-runner.sh — Bridge script: feeds SKILL.md as system context to Ollama
# Usage: ./skill-runner.sh <skill-name> "<user prompt>" [model-override]
# This makes skills ACTUALLY work with local Ollama without ProClaw web app.

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SKILLS_DIR="$WORKSPACE_ROOT/OpenClawData/skills"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
OLLAMA_URL="http://127.0.0.1:11434"

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <skill-name> \"<your prompt>\" [model-override]"
    echo ""
    echo "Available skills:"
    ls "$SKILLS_DIR" 2>/dev/null | sort
    exit 1
fi

SKILL_NAME="$1"
USER_PROMPT="$2"
MODEL_OVERRIDE="$3"

SKILL_FILE="$SKILLS_DIR/$SKILL_NAME/SKILL.md"
BOT_SKILLS_DIR="$WORKSPACE_ROOT/OpenClawData/inbharat-bot/skills"

# Check skill exists — search CMO skills first, then bot skills
if [ ! -f "$SKILL_FILE" ]; then
    SKILL_FILE="$BOT_SKILLS_DIR/$SKILL_NAME/SKILL.md"
fi
if [ ! -f "$SKILL_FILE" ]; then
    echo "ERROR: Skill '$SKILL_NAME' not found"
    echo ""
    echo "Available CMO skills:"
    ls "$SKILLS_DIR" 2>/dev/null | sort
    echo ""
    echo "Available Bot skills:"
    ls "$BOT_SKILLS_DIR" 2>/dev/null | sort
    exit 1
fi

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "ERROR: Ollama is not running at $OLLAMA_URL"
    exit 1
fi

# Extract skill body (everything after the second ---)
SKILL_BODY=$(awk '/^---$/{c++;next}c>=2' "$SKILL_FILE")

if [ -z "$SKILL_BODY" ]; then
    echo "WARNING: Skill file has no body content, using full file"
    SKILL_BODY=$(cat "$SKILL_FILE")
fi

# Determine model
if [ -n "$MODEL_OVERRIDE" ]; then
    MODEL="$MODEL_OVERRIDE"
else
    # Use model-router to pick
    MODEL=$("$SCRIPTS_DIR/model-router.sh" "$USER_PROMPT" 2>/dev/null | head -1)
    if [ -z "$MODEL" ] || [[ "$MODEL" == ERROR* ]]; then
        MODEL="qwen3:8b"
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Skill:  $SKILL_NAME"
echo "Model:  $MODEL"
echo "Prompt: $(echo "$USER_PROMPT" | head -c 80)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Build the combined prompt with skill context
COMBINED_PROMPT="You are operating with the following skill instructions loaded. Follow them precisely.

--- SKILL: $SKILL_NAME ---
$SKILL_BODY
--- END SKILL ---

USER REQUEST:
$USER_PROMPT"

# Call Ollama native API (not /v1, using native /api/chat for direct CLI bridge)
curl -s "$OLLAMA_URL/api/chat" \
    -d "$(cat <<EOF
{
    "model": "$MODEL",
    "messages": [
        {"role": "user", "content": $(echo "$COMBINED_PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}
    ],
    "stream": false,
    "options": {
        "temperature": 0.7
    }
}
EOF
)" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'message' in data and 'content' in data['message']:
        print(data['message']['content'])
    elif 'error' in data:
        print('ERROR:', data['error'])
    else:
        print(json.dumps(data, indent=2))
except Exception as e:
    print('Parse error:', e)
"
