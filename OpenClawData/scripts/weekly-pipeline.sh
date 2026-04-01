#!/bin/bash
# weekly-pipeline.sh — Weekly orchestrator for the AI CMO pipeline
# Usage: ./weekly-pipeline.sh [--dry-run]
# Run once per week (e.g., Sunday evening) to produce weekly content
# Produces: weekly roundup, editorial calendar, newsletter draft, video/image briefs, performance review

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
MARKETING_DIR="$WORKSPACE_ROOT/MarketingToolData"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/weekly-pipeline.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_TAG=$(date '+%Y-%m-%d')
OLLAMA_URL="http://127.0.0.1:11434"

DRY_RUN=""
[ "$1" = "--dry-run" ] && DRY_RUN="--dry-run"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  OpenClaw AI CMO — Weekly Pipeline"
echo "  Week ending: $DATE_TAG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log "=== WEEKLY PIPELINE STARTED ==="

# Ensure output directories exist
mkdir -p "$MARKETING_DIR/calendars"
mkdir -p "$MARKETING_DIR/weekly-roundups"
mkdir -p "$MARKETING_DIR/build-logs"
mkdir -p "$MARKETING_DIR/newsletters"
mkdir -p "$MARKETING_DIR/video-briefs"
mkdir -p "$MARKETING_DIR/image-briefs"
mkdir -p "$MARKETING_DIR/research"
mkdir -p "$REPORTS_DIR/daily"
mkdir -p "$REPORTS_DIR/weekly"
mkdir -p "$QUEUES_DIR/website/pending"
mkdir -p "$QUEUES_DIR/email/pending"
mkdir -p "$QUEUES_DIR/heygen/pending"

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
        echo "  [DRY RUN] Would execute: $TASK_CMD"
        log "[DRY RUN] $TASK_NAME"
    else
        eval "$TASK_CMD" 2>&1
    fi

    local DURATION=$(( $(date +%s) - START ))
    log "$TASK_NAME: complete (${DURATION}s)"
    echo "  Done (${DURATION}s)"
    echo ""
}

# ===== TASK 1: Weekly Editorial Calendar =====
run_task "Build Next Week's Calendar" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" campaign-calendar-builder \
    'Build a weekly editorial calendar for the week starting $(date -v+1d '+%Y-%m-%d' 2>/dev/null || date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || echo 'next Monday'). Include website posts, social content, Discord updates, and newsletter. Keep realistic for a solo builder.' \
    'qwen3:8b' > '$MARKETING_DIR/calendars/calendar-$DATE_TAG-weekly.md' 2>/dev/null"

# ===== TASK 2: Weekly Roundup =====
# Gather this week's output files for context
WEEK_FILES=$(find "$MARKETING_DIR" -name "*.md" -newer "$WORKSPACE_ROOT/OpenClawData/reports/weekly/" -mtime -7 2>/dev/null | head -20 | while read f; do basename "$f"; done | tr '\n' ', ')

run_task "Write Weekly Roundup" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" weekly-roundup-builder \
    'Create a weekly roundup for the week ending $DATE_TAG. Content produced this week includes: $WEEK_FILES. Summarize what was built, what was published, key AI news, and what is planned next.' \
    'qwen3:8b' > '$MARKETING_DIR/weekly-roundups/weekly-roundup-$DATE_TAG.md' 2>/dev/null && \
    cp '$MARKETING_DIR/weekly-roundups/weekly-roundup-$DATE_TAG.md' '$QUEUES_DIR/website/pending/' 2>/dev/null"

# ===== TASK 3: Build Log =====
run_task "Write Weekly Build Log" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" build-log-writer \
    'Write a build-in-public log for the week ending $DATE_TAG. This week we worked on: AI CMO pipeline, content automation, multi-channel distribution system. Use first person, authentic tone.' \
    'qwen3:8b' > '$MARKETING_DIR/build-logs/build-log-$DATE_TAG.md' 2>/dev/null && \
    cp '$MARKETING_DIR/build-logs/build-log-$DATE_TAG.md' '$QUEUES_DIR/website/pending/' 2>/dev/null"

# ===== TASK 4: Newsletter Draft =====
run_task "Compile Weekly Newsletter" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" newsletter-draft-builder \
    'Compile the weekly newsletter for $DATE_TAG. Include: product updates, AI news summaries, one insight, and one actionable tip. Draw from this week produced content. Keep personal and subscriber-focused.' \
    'qwen3:8b' > '$MARKETING_DIR/newsletters/newsletter-$DATE_TAG.md' 2>/dev/null && \
    cp '$MARKETING_DIR/newsletters/newsletter-$DATE_TAG.md' '$QUEUES_DIR/email/pending/' 2>/dev/null"

# ===== TASK 5: Video Brief =====
run_task "Generate Video Brief" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" video-brief-generator \
    'Create a 60-second HeyGen video brief summarizing this week highlights. Focus on the most interesting thing we built or shipped. Professional but conversational tone. Include hook, body, and CTA.' \
    'qwen3:8b' > '$MARKETING_DIR/video-briefs/video-brief-$DATE_TAG.md' 2>/dev/null && \
    cp '$MARKETING_DIR/video-briefs/video-brief-$DATE_TAG.md' '$QUEUES_DIR/heygen/pending/' 2>/dev/null"

# ===== TASK 6: Image Briefs =====
run_task "Generate Image Briefs" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" image-brief-generator \
    'Create 2 image briefs: (1) A LinkedIn/website hero image for this week weekly roundup post. (2) An Instagram post graphic highlighting one key achievement this week. Include dimensions and style notes.' \
    'qwen3:8b' > '$MARKETING_DIR/image-briefs/image-briefs-$DATE_TAG.md' 2>/dev/null"

# ===== TASK 7: Performance Review =====
run_task "Weekly Performance Review" \
    "\"$SCRIPTS_DIR/skill-runner.sh\" content-performance-tracker \
    'Generate a weekly content performance summary. Count files in the posted folder, check approval logs, and summarize what was published, blocked, and queued this week.' \
    'qwen3:8b' > '$MARKETING_DIR/research/performance-$DATE_TAG-weekly.md' 2>/dev/null"

# ===== TASK 8: Run Approval on Weekly Content =====
run_task "Approve Weekly Content" \
    "\"$SCRIPTS_DIR/approval-engine.sh\" $DRY_RUN"

# ===== TASK 9: Weekly Report =====
run_task "Generate Weekly Report" \
    "\"$SCRIPTS_DIR/reporting-engine-v2.sh\" --type weekly"

# ===== SUMMARY =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Weekly Pipeline Complete"
echo "  Week ending: $DATE_TAG"
echo ""
echo "  Produced:"
echo "    - Editorial calendar"
echo "    - Weekly roundup"
echo "    - Build log"
echo "    - Newsletter draft"
echo "    - Video brief"
echo "    - Image briefs"
echo "    - Performance review"
echo "    - Weekly report"
echo ""
echo "  Review queue: $(find "$WORKSPACE_ROOT/OpenClawData/approvals/review" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ') items"
echo "  Log: $LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log "=== WEEKLY PIPELINE COMPLETE ==="
