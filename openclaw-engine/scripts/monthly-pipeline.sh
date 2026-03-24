#!/bin/bash
# monthly-pipeline.sh — Monthly orchestrator for the AI CMO pipeline
# Usage: ./monthly-pipeline.sh [--dry-run]
# Run on the 1st of each month for strategic review and planning
# Produces: content pillar review, SEO update, campaign theme, monthly plan, performance summary

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/date-context.sh"
SCRIPTS_DIR="$WORKSPACE_ROOT/openclaw-engine/scripts"
MARKETING_DIR="$WORKSPACE_ROOT/data"
QUEUES_DIR="$WORKSPACE_ROOT/queues"
EXPORTS_DIR="$WORKSPACE_ROOT/ExportsLogs"
APPROVALS_DIR="$WORKSPACE_ROOT/approvals"
LOG_FILE="$WORKSPACE_ROOT/logs/monthly-pipeline.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_TAG=$(date '+%Y-%m-%d')
MONTH_TAG=$(date '+%Y-%m')
OLLAMA_URL="http://127.0.0.1:11434"

DRY_RUN=""
[ "$1" = "--dry-run" ] && DRY_RUN="--dry-run"

log() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
    echo "$1"
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  OpenClaw AI CMO — Monthly Pipeline"
echo "  Month: $MONTH_TAG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log "=== MONTHLY PIPELINE STARTED ==="

# Pre-flight
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    log "FATAL: Ollama is not running"
    exit 1
fi

run_task() {
    local TASK_NAME="$1"
    local TASK_CMD="$2"

    echo "━━━ $TASK_NAME ━━━"
    log "--- $TASK_NAME ---"
    local START=$(date +%s)

    if [ -n "$DRY_RUN" ]; then
        echo "  [DRY RUN] Would execute"
        log "[DRY RUN] $TASK_NAME"
    else
        eval "$TASK_CMD" 2>&1
    fi

    local DURATION=$(( $(date +%s) - START ))
    log "$TASK_NAME: complete (${DURATION}s)"
    echo "  Done (${DURATION}s)"
    echo ""
}

# ===== TASK 1: Content Pillar Review =====
run_task "Content Pillar Review" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" content-strategy \
    'Review our content pillars for the new month. Our current pillars are: (1) Product updates and build-in-public, (2) AI industry news and commentary, (3) Educational/how-to content, (4) Tool comparisons and reviews. Based on last month performance, recommend whether to keep, adjust, or replace any pillar. Also suggest the content mix ratio.' \
    'qwen3:8b' > '$MARKETING_DIR/campaigns/pillar-review-$MONTH_TAG.md' 2>/dev/null"

# ===== TASK 2: SEO Topic Update =====
run_task "SEO Topic Opportunity Update" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" seo-topic-mapper \
    'Generate a fresh SEO topic map for $MONTH_TAG. Focus on AI tools, automation, local LLM usage, and builder-focused topics. Identify 5-10 high-value content topics with search intent, estimated difficulty, and recommended content format.' \
    'qwen3:8b' > '$MARKETING_DIR/research/seo-map-$MONTH_TAG.md' 2>/dev/null"

# ===== TASK 3: Campaign Theme =====
run_task "Monthly Campaign Theme" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" campaign-calendar-builder \
    'Build a monthly content calendar for $MONTH_TAG. Include a monthly theme, 4 weekly focuses, content targets per channel, and any key dates or launches. Be realistic for a solo builder.' \
    'qwen3:8b' > '$MARKETING_DIR/calendars/calendar-$MONTH_TAG-monthly.md' 2>/dev/null"

# ===== TASK 4: Offer/Positioning Review =====
run_task "Offer Positioning Review" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" offer-funnel-copy \
    'Review our current product positioning and offer messaging. Suggest any updates to value proposition, key benefits, or call-to-action language for the new month. Keep it practical and honest.' \
    'qwen3:8b' > '$MARKETING_DIR/campaigns/positioning-review-$MONTH_TAG.md' 2>/dev/null"

# ===== TASK 5: Archive Cleanup =====
run_task "Archive Cleanup" \
    "echo 'Archiving old queue items...' && \
    ARCHIVED=0 && \
    for CH_DIR in '$QUEUES_DIR'/*/approved; do
        [ -d \"\$CH_DIR\" ] || continue
        while IFS= read -r -d '' f; do
            mv \"\$f\" '$EXPORTS_DIR/archive/' 2>/dev/null && ARCHIVED=\$((ARCHIVED + 1))
        done < <(find \"\$CH_DIR\" -type f -name '*.md' -mtime +14 -print0 2>/dev/null)
    done && \
    echo \"Archived \$ARCHIVED old items\""

# ===== TASK 6: Monthly Performance Summary =====
MONTH_PRODUCED=$(find "$MARKETING_DIR" -type f -name "*.md" -mtime -30 2>/dev/null | wc -l | tr -d ' ')
MONTH_POSTED=$(find "$EXPORTS_DIR/posted" -type f -mtime -30 2>/dev/null | wc -l | tr -d ' ')
MONTH_BLOCKED=$(find "$APPROVALS_DIR/blocked" -type f -mtime -30 2>/dev/null | wc -l | tr -d ' ')

run_task "Monthly Performance Summary" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" content-performance-tracker \
    'Generate a monthly performance summary for $MONTH_TAG. This month: $MONTH_PRODUCED content pieces produced, $MONTH_POSTED posted/distributed, $MONTH_BLOCKED blocked. Analyze the numbers and recommend improvements for next month.' \
    'qwen2.5-coder:7b' > '$MARKETING_DIR/research/performance-$MONTH_TAG-monthly.md' 2>/dev/null"

# ===== TASK 7: Next Month Plan =====
run_task "Next Month Planning" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" task-planner \
    'Create a high-level plan for next month AI CMO operations. Based on this month ($MONTH_PRODUCED produced, $MONTH_POSTED posted), plan realistic content targets, any new channels to activate, and key milestones.' \
    'qwen3:8b' > '$WORKSPACE_ROOT/logs/sessions/plan-next-month-$MONTH_TAG.md' 2>/dev/null"

# ===== TASK 8: Monthly Report =====
run_task "Generate Monthly Report" \
    "\"$SCRIPTS_DIR/reporting-engine-v2.sh\" --type monthly"

# ===== SUMMARY =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Monthly Pipeline Complete"
echo "  Month: $MONTH_TAG"
echo ""
echo "  Produced:"
echo "    - Content pillar review"
echo "    - SEO topic map"
echo "    - Monthly campaign calendar"
echo "    - Positioning review"
echo "    - Archive cleanup"
echo "    - Performance summary"
echo "    - Next month plan"
echo "    - Monthly report"
echo ""
echo "  This month totals:"
echo "    - Content produced: $MONTH_PRODUCED"
echo "    - Items posted: $MONTH_POSTED"
echo "    - Items blocked: $MONTH_BLOCKED"
echo ""
echo "  Log: $LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log "=== MONTHLY PIPELINE COMPLETE ==="
