#!/bin/bash
# daily-pipeline.sh — Master daily orchestrator for the AI CMO pipeline
# Usage: ./daily-pipeline.sh [--dry-run] [--stage <stage>]
# Runs the full pipeline: intake → classify → produce → approve → distribute → report
# This is the ONE script you run daily to keep the AI CMO operating.

# Ignore SIGPIPE — prevents exit code 141 from pipe patterns on macOS
trap '' PIPE

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/daily-pipeline.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_TAG=$(date '+%Y-%m-%d')
OLLAMA_URL="http://127.0.0.1:11434"

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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  OpenClaw AI CMO — Daily Pipeline"
echo "  Date: $DATE_TAG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log "=== DAILY PIPELINE STARTED — $DATE_TAG ==="
[ -n "$DRY_RUN" ] && log "[DRY RUN MODE]"

# Pre-flight checks
echo "Running pre-flight checks..."

# Check 1: Workspace mounted
if [ ! -d "$WORKSPACE_ROOT" ]; then
    log "FATAL: Workspace not mounted at $WORKSPACE_ROOT"
    echo "ERROR: External drive not mounted. Connect the drive and try again."
    exit 1
fi

# Check 2: Ollama running
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    log "FATAL: Ollama is not running at $OLLAMA_URL"
    echo "ERROR: Ollama not running. Start Ollama and try again."
    echo "  Try: open -a Ollama"
    exit 1
fi

# Check 3: Scripts exist and are executable
for SCRIPT in intake-processor.sh content-agent.sh approval-engine.sh distribution-engine.sh; do
    if [ ! -x "$SCRIPTS_DIR/$SCRIPT" ]; then
        log "FATAL: $SCRIPT not found or not executable"
        echo "ERROR: Missing script: $SCRIPTS_DIR/$SCRIPT"
        exit 1
    fi
done

echo "Pre-flight: OK"
echo ""

run_stage() {
    local STAGE_NAME="$1"
    local STAGE_NUM="$2"
    local SCRIPT_CMD="$3"

    # If targeting a specific stage, skip others
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
        log "Stage $STAGE_NUM ($STAGE_NAME): FAILED (exit code $EXIT_CODE) after ${DURATION}s"
        echo "  FAILED (exit code $EXIT_CODE) after ${DURATION}s"
        echo "  Check log: $LOG_FILE"
        # Don't halt pipeline on non-fatal failures — continue to next stage
    fi
    echo ""
}

# ===== STAGE 1: INTAKE =====
# Scan source folders for new material and classify it
run_stage "intake" "1" "\"$SCRIPTS_DIR/intake-processor.sh\" $DRY_RUN"

# ===== STAGE 1.5: INTELLIGENCE TO CONTENT =====
# Convert InBharat Bot intelligence reports (AI gaps, opportunities) into social content
run_stage "intelligence" "1.5" "\"$SCRIPTS_DIR/intelligence-to-content.sh\" $DRY_RUN"

# ===== STAGE 2A: NEWSROOM =====
# Process AI news sources into summaries + multi-channel variants
run_stage "newsroom" "2a" "\"$SCRIPTS_DIR/newsroom-agent.sh\" $DRY_RUN"

# ===== STAGE 2B: PRODUCT UPDATES =====
# Process product notes into formatted updates + multi-channel variants
run_stage "product-updates" "2b" "\"$SCRIPTS_DIR/product-update-agent.sh\" $DRY_RUN"

# ===== STAGE 2C: CONTENT PRODUCTION =====
# Generate remaining content from classified source material
run_stage "produce" "2c" "\"$SCRIPTS_DIR/content-agent.sh\" $DRY_RUN"

# ===== STAGE 2D: CLAIM VALIDATION =====
# Pre-approval content quality check — catches fabricated stats and LLM artifacts
run_stage "validate" "2d" "\"$WORKSPACE_ROOT/OpenClawData/security/claim-validator.sh\" --scan-queues"

# ===== STAGE 3: APPROVAL =====
# Run all pending content through the approval engine
run_stage "approve" "3" "\"$SCRIPTS_DIR/approval-engine.sh\" $DRY_RUN"

# ===== STAGE 3.5: IMAGE GENERATION =====
# Generate DALL-E images for approved content with image_brief fields
# Must run AFTER approval (images cost money — only generate for approved content)
MEDIA_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media"
run_stage "images" "3.5" "\"$MEDIA_DIR/image-engine/process-briefs.sh\" $DRY_RUN"

# ===== STAGE 4: PUBLISH =====
# Autonomous publishing — post approved content to platforms via Playwright browser automation
# Runs FIRST so it posts linkedin/x/instagram before distribution-engine moves files
run_stage "publish" "4" "\"$WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine/publish.sh\" $DRY_RUN"

# ===== STAGE 4B: DISTRIBUTION =====
# Distribute remaining content to non-Playwright channels (website, discord webhook, email export, heygen)
# Skips linkedin/x/instagram — those were already posted by publish.sh above
run_stage "distribute" "4b" "\"$SCRIPTS_DIR/distribution-engine.sh\" $DRY_RUN"

# ===== STAGE 5: REPORT =====
# Generate daily report
run_stage "report" "5" "\"$SCRIPTS_DIR/reporting-engine-v2.sh\" $DRY_RUN"

# ===== STAGE 6: HEALTH + BUDGET =====
# Post-pipeline health check and budget status
run_stage "health" "6a" "\"$SCRIPTS_DIR/health-check.sh\" --quiet"
run_stage "budget" "6b" "\"$SCRIPTS_DIR/budget-governor.sh\" --status"

# ===== SUMMARY =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Daily Pipeline Complete"
echo "  Date: $DATE_TAG"
echo "  Log:  $LOG_FILE"
echo ""
echo "  Quick status:"

# Count queue states
PENDING_COUNT=$(find "$WORKSPACE_ROOT/OpenClawData/queues" -path "*/pending/*" -type f \( -name "*.md" -o -name "*.json" \) ! -name ".gitkeep" ! -name "._*" 2>/dev/null | wc -l | tr -d ' ')
APPROVED_COUNT=$(find "$WORKSPACE_ROOT/OpenClawData/queues" -path "*/approved/*" -type f \( -name "*.md" -o -name "*.json" \) ! -name ".gitkeep" ! -name "._*" 2>/dev/null | wc -l | tr -d ' ')
REVIEW_COUNT=$(find "$WORKSPACE_ROOT/OpenClawData/approvals/review" -type f \( -name "*.md" -o -name "*.json" \) ! -name ".gitkeep" ! -name "._*" 2>/dev/null | wc -l | tr -d ' ')
BLOCKED_COUNT=$(find "$WORKSPACE_ROOT/OpenClawData/approvals/blocked" -type f \( -name "*.md" -o -name "*.json" \) ! -name ".gitkeep" ! -name "._*" 2>/dev/null | wc -l | tr -d ' ')

echo "  Pending:   $PENDING_COUNT items"
echo "  Approved:  $APPROVED_COUNT items"
echo "  In Review: $REVIEW_COUNT items"
echo "  Blocked:   $BLOCKED_COUNT items"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log "=== DAILY PIPELINE COMPLETE — pending=$PENDING_COUNT approved=$APPROVED_COUNT review=$REVIEW_COUNT blocked=$BLOCKED_COUNT ==="
