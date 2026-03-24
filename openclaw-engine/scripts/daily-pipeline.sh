#!/bin/bash
# ============================================================
# daily-pipeline.sh — Master daily orchestrator
# OPTIMIZED: Uses 3-layer architecture, timing metrics, date context
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/date-context.sh"

SCRIPTS_DIR="$SCRIPT_DIR"
LOG_FILE="$WORKSPACE_ROOT/logs/daily-pipeline.log"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"

DRY_RUN=""
TARGET_STAGE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN="--dry-run" ;;
        --stage) TARGET_STAGE="$2"; shift ;;
    esac
    shift
done

log() {
    local ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $1" >> "$LOG_FILE"
    echo "$1"
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  OpenClaw AI CMO — Daily Pipeline"
echo "  Date: $CURRENT_DATE ($CURRENT_DAY)"
echo "  Fast Model: ${FAST_MODEL:-mistral-small3.1:latest}"
echo "  Think Model: ${THINK_MODEL:-qwen3:8b}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PIPELINE_START=$(python3 -c "import time; print(time.time())")

log "=== DAILY PIPELINE STARTED — $CURRENT_DATE ==="
[ -n "$DRY_RUN" ] && log "[DRY RUN MODE]"

# Pre-flight
echo "Pre-flight checks..."
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    log "FATAL: Ollama is not running"
    exit 1
fi
echo "Pre-flight: OK"
echo ""

STAGE_TIMES=""

run_stage() {
    local STAGE_NAME="$1"
    local STAGE_NUM="$2"
    local SCRIPT_CMD="$3"

    if [ -n "$TARGET_STAGE" ] && [ "$TARGET_STAGE" != "$STAGE_NAME" ]; then
        return 0
    fi

    echo "━━━ Stage $STAGE_NUM: $STAGE_NAME ━━━"
    log "--- Stage $STAGE_NUM: $STAGE_NAME ---"

    local START_TIME=$(date +%s)
    eval "$SCRIPT_CMD"
    local EXIT_CODE=$?
    local END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))

    if [ $EXIT_CODE -eq 0 ]; then
        log "Stage $STAGE_NUM ($STAGE_NAME): COMPLETE in ${DURATION}s"
        echo "  Completed in ${DURATION}s"
    else
        log "Stage $STAGE_NUM ($STAGE_NAME): FAILED (exit $EXIT_CODE) after ${DURATION}s"
        echo "  FAILED after ${DURATION}s"
    fi

    STAGE_TIMES="${STAGE_TIMES}${STAGE_NAME}=${DURATION}s "
    echo ""
}

# ===== PIPELINE STAGES (9-stage) =====
run_stage "intake"           "1"  "\"$SCRIPTS_DIR/intake-processor.sh\" $DRY_RUN"
run_stage "calendar-enforce" "1b" "\"$SCRIPTS_DIR/calendar-enforcer.sh\""
run_stage "newsroom"         "2a" "\"$SCRIPTS_DIR/newsroom-agent.sh\" $DRY_RUN"
run_stage "product-updates"  "2b" "\"$SCRIPTS_DIR/product-update-agent.sh\" $DRY_RUN"
run_stage "content"          "2c" "\"$SCRIPTS_DIR/content-agent.sh\" $DRY_RUN"
run_stage "quality-score"    "3a" "\"$SCRIPTS_DIR/quality-scorer.sh\""
run_stage "approval"         "3b" "\"$SCRIPTS_DIR/approval-engine.sh\" $DRY_RUN"
run_stage "visual-briefs"    "3c" "\"$SCRIPTS_DIR/visual-brief-generator.sh\" --auto"
run_stage "distribution"     "4"  "\"$SCRIPTS_DIR/distribution-engine.sh\" $DRY_RUN"
run_stage "report"           "5"  "\"$SCRIPTS_DIR/reporting-engine-v2.sh\" $DRY_RUN"

# ===== SUMMARY =====
PIPELINE_END=$(python3 -c "import time; print(time.time())")
TOTAL_SECONDS=$(python3 -c "print(int($PIPELINE_END - $PIPELINE_START))")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Daily Pipeline Complete"
echo "  Date:  $CURRENT_DATE"
echo "  Total: ${TOTAL_SECONDS}s"
echo ""
echo "  Stage times: $STAGE_TIMES"
echo ""

# Count queue states
PENDING=$(find "$WORKSPACE_ROOT/queues" -path "*/pending/*" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
APPROVED=$(find "$WORKSPACE_ROOT/queues" -path "*/approved/*" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
REVIEW=$(find "$WORKSPACE_ROOT/approvals/review" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
BLOCKED=$(find "$WORKSPACE_ROOT/approvals/blocked" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

echo "  Pending:   $PENDING"
echo "  Approved:  $APPROVED"
echo "  In Review: $REVIEW"
echo "  Blocked:   $BLOCKED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log "=== DAILY PIPELINE COMPLETE in ${TOTAL_SECONDS}s — pending=$PENDING approved=$APPROVED review=$REVIEW blocked=$BLOCKED ==="

# Write timing report
TIMING_REPORT="$WORKSPACE_ROOT/logs/timing-daily-$DATE_TAG.log"
echo "Pipeline: $CURRENT_DATE | Total: ${TOTAL_SECONDS}s | Stages: $STAGE_TIMES" >> "$TIMING_REPORT"
