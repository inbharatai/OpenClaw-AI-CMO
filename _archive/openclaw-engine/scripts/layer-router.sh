#!/bin/bash
# ============================================================
# layer-router.sh — 3-Layer Architecture Router
# FAST LAYER:     mistral-small3.1:latest (or fallback qwen2.5-coder:7b)
# THINKING LAYER: qwen3:8b (deep reasoning only)
# RECORDER LAYER: always-on, non-blocking logging
#
# Usage: source this file, then call:
#   llm_fast "prompt"          → Fast layer (default, <5s)
#   llm_think "prompt"         → Thinking layer (complex tasks, 15-60s)
#   llm_route "task" "prompt"  → Auto-route based on task type
#   record_event "stage" "msg" → Recorder layer
# ============================================================

# --- CONFIG ---
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
FAST_MODEL="${FAST_MODEL:-mistral-small3.1:latest}"
FAST_FALLBACK="${FAST_FALLBACK:-qwen2.5-coder:7b}"
THINK_MODEL="${THINK_MODEL:-qwen3:8b}"

# Paths (set WORKSPACE_ROOT before sourcing, or use default)
LAYER_LOG="${WORKSPACE_ROOT:-.}/logs/layer-router.log"
TIMING_LOG="${WORKSPACE_ROOT:-.}/logs/timing-metrics.log"
RECORDER_LOG="${WORKSPACE_ROOT:-.}/logs/recorder.log"

# Ensure log directories exist
mkdir -p "$(dirname "$LAYER_LOG")" "$(dirname "$TIMING_LOG")" "$(dirname "$RECORDER_LOG")" 2>/dev/null

# --- DATE CONTEXT (Issue C fix) ---
get_date_context() {
    cat <<EOF
Today's date is: $(date '+%Y-%m-%d')
Current day: $(date '+%A')
Current month: $(date '+%B %Y')
Current year: $(date '+%Y')
Current timestamp: $(date '+%Y-%m-%dT%H:%M:%S%z')
Timezone: $(date '+%Z')
Use the current date above for ALL date-sensitive content. Do not use older dates.
EOF
}

DATE_CONTEXT="$(get_date_context)"

# --- TIMING ---
timer_start() {
    echo $(python3 -c "import time; print(time.time())")
}

timer_elapsed_ms() {
    local start="$1"
    python3 -c "import time; print(int((time.time() - $start) * 1000))"
}

# --- RECORDER LAYER (non-blocking) ---
record_event() {
    local stage="$1"
    local message="$2"
    local ts=$(date '+%Y-%m-%dT%H:%M:%S')
    echo "[$ts] [$stage] $message" >> "$RECORDER_LOG" 2>/dev/null &
}

record_timing() {
    local stage="$1"
    local layer="$2"
    local model="$3"
    local elapsed_ms="$4"
    local ts=$(date '+%Y-%m-%dT%H:%M:%S')
    echo "[$ts] stage=$stage layer=$layer model=$model elapsed_ms=$elapsed_ms" >> "$TIMING_LOG" 2>/dev/null &
}

# --- CHECK WHICH MODELS ARE AVAILABLE ---
_model_available=""
check_model_available() {
    local model="$1"
    if [ -z "$_model_available" ]; then
        _model_available=$(curl -s --max-time 3 "$OLLAMA_URL/api/tags" 2>/dev/null)
    fi
    echo "$_model_available" | grep -q "$model"
}

# Determine actual fast model at load time
resolve_fast_model() {
    if check_model_available "$FAST_MODEL"; then
        echo "$FAST_MODEL"
    elif check_model_available "$FAST_FALLBACK"; then
        echo "$FAST_FALLBACK"
    else
        echo "$THINK_MODEL"  # Last resort
    fi
}

RESOLVED_FAST_MODEL=$(resolve_fast_model)

# --- FAST LAYER ---
# For: routing, classification, formatting, summaries, short drafts, approvals pre-check
llm_fast() {
    local prompt="$1"
    local stage="${2:-fast}"
    local t_start=$(timer_start)

    record_event "$stage" "FAST LAYER → $RESOLVED_FAST_MODEL"

    local full_prompt="$DATE_CONTEXT

$prompt"

    local result=$(echo "$full_prompt" | python3 -c "
import json, sys
prompt_text = sys.stdin.read()
print(json.dumps({
    'model': '$RESOLVED_FAST_MODEL',
    'prompt': prompt_text,
    'stream': False,
    'options': {
        'temperature': 0.5,
        'num_predict': 1024
    }
}))
" 2>/dev/null | curl -s "$OLLAMA_URL/api/generate" -d @- 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('response', ''))
except:
    print('')
" 2>/dev/null)

    local elapsed=$(timer_elapsed_ms "$t_start")
    record_timing "$stage" "fast" "$RESOLVED_FAST_MODEL" "$elapsed"
    record_event "$stage" "FAST DONE in ${elapsed}ms"

    echo "$result"
}

# --- THINKING LAYER ---
# For: deep reasoning, complex planning, hard content, ambiguous tasks
llm_think() {
    local prompt="$1"
    local stage="${2:-think}"
    local t_start=$(timer_start)

    record_event "$stage" "THINKING LAYER → $THINK_MODEL"

    local full_prompt="$DATE_CONTEXT

$prompt"

    local result=$(echo "$full_prompt" | python3 -c "
import json, sys
prompt_text = sys.stdin.read()
print(json.dumps({
    'model': '$THINK_MODEL',
    'messages': [{'role': 'user', 'content': prompt_text}],
    'stream': False,
    'options': {
        'temperature': 0.7,
        'num_predict': 2048
    }
}))
" 2>/dev/null | curl -s "$OLLAMA_URL/api/chat" -d @- 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'message' in data:
        print(data['message'].get('content', ''))
    else:
        print(data.get('response', ''))
except:
    print('')
" 2>/dev/null)

    local elapsed=$(timer_elapsed_ms "$t_start")
    record_timing "$stage" "thinking" "$THINK_MODEL" "$elapsed"
    record_event "$stage" "THINK DONE in ${elapsed}ms"

    echo "$result"
}

# --- AUTO-ROUTER ---
# Decides fast vs thinking based on task classification
llm_route() {
    local task_type="$1"
    local prompt="$2"
    local stage="${3:-auto}"

    # FAST tasks — no deep reasoning needed
    local fast_tasks="routing|classify|format|summarize|summary|short-draft|discord|x-post|tweet|caption|status|metadata|pre-check|extract|translate|rewrite-short|approval-precheck|credential-check|risk-precheck|announcement|adapt-channel"

    # THINKING tasks — need deep reasoning
    local think_tasks="strategy|plan|architecture|research-synthesis|long-article|complex-analysis|campaign-design|comparison-deep|educational-deep|weekly-roundup|newsletter-full|monthly-review"

    task_lower=$(echo "$task_type" | tr '[:upper:]' '[:lower:]')

    if echo "$task_lower" | grep -qE "$fast_tasks"; then
        record_event "$stage" "ROUTED to FAST: task=$task_type"
        llm_fast "$prompt" "$stage"
    elif echo "$task_lower" | grep -qE "$think_tasks"; then
        record_event "$stage" "ROUTED to THINKING: task=$task_type"
        llm_think "$prompt" "$stage"
    else
        # Default: use FAST for anything not explicitly complex
        record_event "$stage" "ROUTED to FAST (default): task=$task_type"
        llm_fast "$prompt" "$stage"
    fi
}

# --- CONVENIENCE: Generate with skill context ---
llm_skill() {
    local skill_name="$1"
    local prompt="$2"
    local layer="${3:-auto}"  # fast|think|auto
    local stage="${4:-skill}"

    local skill_dir="${WORKSPACE_ROOT:-.}/openclaw-engine/skills"
    local skill_file="$skill_dir/$skill_name/SKILL.md"

    local skill_body=""
    if [ -f "$skill_file" ]; then
        skill_body=$(awk '/^---$/{c++;next}c>=2' "$skill_file")
        [ -z "$skill_body" ] && skill_body=$(cat "$skill_file")
    fi

    local full_prompt="You are operating with the following skill.
--- SKILL: $skill_name ---
$skill_body
--- END SKILL ---

USER REQUEST:
$prompt"

    case "$layer" in
        fast)  llm_fast "$full_prompt" "$stage" ;;
        think) llm_think "$full_prompt" "$stage" ;;
        auto)  llm_route "$skill_name" "$full_prompt" "$stage" ;;
    esac
}

# --- INIT LOG ---
record_event "init" "Layer router loaded. Fast=$RESOLVED_FAST_MODEL Think=$THINK_MODEL"
