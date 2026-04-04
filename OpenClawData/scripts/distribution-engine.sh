#!/bin/bash
# distribution-engine.sh — Distribute approved content to NON-PLAYWRIGHT channels
#
# This script handles channels that DON'T use browser automation:
#   - website (file copy to staging directory)
#   - email/substack (export to ready-to-send folder)
#   - heygen (export video briefs)
#   - medium (export drafts)
#
# Channels handled by publish.sh (Playwright browser automation):
#   - linkedin, x, instagram, discord
#   These are SKIPPED here. publish.sh is the canonical path for live posts.
#
# All channels go through:
#   1. Policy enforcement (rate-limits.json)
#   2. Content sanitization (sanitize_post.py)
#   3. Distribution to target
#   4. Post count recording (policy_enforcer.py)
#
# Usage:
#   ./distribution-engine.sh                    Distribute all approved content
#   ./distribution-engine.sh --channel website  Distribute specific channel
#   ./distribution-engine.sh --dry-run          Preview without distributing

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
ENGINE_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine"
MARKETING_DIR="$WORKSPACE_ROOT/MarketingToolData"
EXPORTS_DIR="$WORKSPACE_ROOT/ExportsLogs"
POLICIES_DIR="$WORKSPACE_ROOT/OpenClawData/policies"
POLICY="$ENGINE_DIR/policy_enforcer.py"
SANITIZER="$ENGINE_DIR/sanitize_post.py"
RENDERER="$ENGINE_DIR/render_post.py"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/distribution-engine.log"
ANALYTICS_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/analytics"
DATE_TAG=$(date '+%Y-%m-%d')

DRY_RUN=false
TARGET_CHANNEL=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --channel) TARGET_CHANNEL="$2"; shift ;;
        -h|--help)
            echo "Usage: distribution-engine.sh [--dry-run] [--channel <channel>]"
            echo "Handles: website, email, substack, heygen, medium"
            echo "Skips: linkedin, x, instagram, discord (use publish.sh)"
            exit 0
            ;;
    esac
    shift
done

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

mkdir -p "$(dirname "$LOG_FILE")" "$ANALYTICS_DIR"

log "=== Distribution Engine Started ==="
[ "$DRY_RUN" = true ] && log "[DRY RUN] No distribution will occur"

TOTAL_DISTRIBUTED=0
TOTAL_SKIPPED=0
POLICY_BLOCKED=0

# ── Channels that publish.sh handles — NEVER touch these ──
PLAYWRIGHT_CHANNELS="linkedin x instagram discord"

# ── Channels this script handles ──
DISTRIBUTION_CHANNELS="website email substack heygen medium"

# ── Ensure target directories exist ──
mkdir -p "$MARKETING_DIR/website-posts" "$MARKETING_DIR/insights" "$MARKETING_DIR/build-logs" \
         "$MARKETING_DIR/ai-news" "$MARKETING_DIR/video-briefs" \
         "$EXPORTS_DIR/email/ready-to-send" "$EXPORTS_DIR/posted" 2>/dev/null

# ── Policy check helper ──
check_policy() {
    local CHANNEL="$1"
    if [ -f "$POLICY" ]; then
        RESULT=$(python3 "$POLICY" --check "$CHANNEL" 2>&1)
        EXIT=$?
        if [ $EXIT -ne 0 ]; then
            log "POLICY BLOCK [$CHANNEL]: $RESULT"
            return 1
        fi
    fi
    return 0
}

# ── Sanitize content helper ──
sanitize_content() {
    local FILE="$1"
    local CHANNEL="$2"
    if [ -f "$SANITIZER" ]; then
        RESULT=$(python3 "$SANITIZER" --validate-only --file "$FILE" 2>&1)
        if [ $? -ne 0 ]; then
            log "SANITIZE WARNING [$CHANNEL]: $(basename "$FILE") — $RESULT"
        fi
    fi
}

# ── Record post to policy counter ──
record_post() {
    local CHANNEL="$1"
    if [ -f "$POLICY" ]; then
        python3 "$POLICY" --record "$CHANNEL" 2>/dev/null
    fi
}

# ── Distribution functions ──

distribute_website() {
    local FILE="$1"
    local FILENAME=$(basename "$FILE")
    local SECTION=$(grep "^section:" "$FILE" 2>/dev/null | head -1 | sed 's/section:\s*//' | tr -d '"' | tr -d ' ')

    case "$SECTION" in
        updates|update) DEST="$MARKETING_DIR/website-posts/" ;;
        insights|insight) DEST="$MARKETING_DIR/insights/" ;;
        build-log|build_log) DEST="$MARKETING_DIR/build-logs/" ;;
        news) DEST="$MARKETING_DIR/ai-news/" ;;
        *) DEST="$MARKETING_DIR/website-posts/" ;;
    esac

    mkdir -p "$DEST"

    if [ "$DRY_RUN" = false ]; then
        cp "$FILE" "$DEST"
        mv "$FILE" "$EXPORTS_DIR/posted/"
        record_post "website"
        log "DISTRIBUTED [website/$SECTION]: $FILENAME → $DEST"
    else
        log "[DRY RUN] Would distribute website/$SECTION: $FILENAME → $DEST"
    fi
}

distribute_email() {
    local FILE="$1"
    local FILENAME=$(basename "$FILE")

    if [ "$DRY_RUN" = false ]; then
        cp "$FILE" "$EXPORTS_DIR/email/ready-to-send/"
        mv "$FILE" "$EXPORTS_DIR/posted/"
        record_post "email"
        log "EXPORTED [email]: $FILENAME → ready-to-send/"
    else
        log "[DRY RUN] Would export email: $FILENAME"
    fi
}

distribute_heygen() {
    local FILE="$1"
    local FILENAME=$(basename "$FILE")

    if [ "$DRY_RUN" = false ]; then
        cp "$FILE" "$MARKETING_DIR/video-briefs/"
        mv "$FILE" "$EXPORTS_DIR/posted/"
        record_post "heygen"
        log "EXPORTED [heygen]: $FILENAME → video-briefs/"
    else
        log "[DRY RUN] Would export heygen: $FILENAME"
    fi
}

distribute_medium() {
    local FILE="$1"
    local FILENAME=$(basename "$FILE")

    mkdir -p "$MARKETING_DIR/medium/"
    if [ "$DRY_RUN" = false ]; then
        cp "$FILE" "$MARKETING_DIR/medium/"
        mv "$FILE" "$EXPORTS_DIR/posted/"
        record_post "medium"
        log "EXPORTED [medium]: $FILENAME → medium/"
    else
        log "[DRY RUN] Would export medium: $FILENAME"
    fi
}

# ── Main distribution loop ──

# Determine channels to process
if [ -n "$TARGET_CHANNEL" ]; then
    CHANNELS=("$TARGET_CHANNEL")
else
    CHANNELS=()
    for dir in "$QUEUES_DIR"/*/approved; do
        [ -d "$dir" ] || continue
        CH=$(basename "$(dirname "$dir")")
        CHANNELS+=("$CH")
    done
fi

for CHANNEL in "${CHANNELS[@]}"; do
    # ── Hard skip: Playwright-handled platforms ──
    if echo "$PLAYWRIGHT_CHANNELS" | grep -qw "$CHANNEL"; then
        log "SKIP [$CHANNEL]: Handled by publish.sh (canonical Playwright path)"
        continue
    fi

    # ── Policy enforcement ──
    if ! check_policy "$CHANNEL"; then
        POLICY_BLOCKED=$((POLICY_BLOCKED + 1))
        continue
    fi

    APPROVED_DIR="$QUEUES_DIR/$CHANNEL/approved"
    [ -d "$APPROVED_DIR" ] || continue

    while IFS= read -r -d '' FILE; do
        FILENAME=$(basename "$FILE")
        [[ "$FILENAME" == .* ]] && continue
        [[ "$FILENAME" == *.gitkeep ]] && continue

        # ── Per-item policy cap check ──
        if ! check_policy "$CHANNEL"; then
            log "CAP REACHED [$CHANNEL]: Stopping distribution for this channel"
            TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
            break
        fi

        # ── Sanitize content ──
        sanitize_content "$FILE" "$CHANNEL"

        # ── Distribute by channel type ──
        case "$CHANNEL" in
            website)  distribute_website "$FILE" ;;
            email)    distribute_email "$FILE" ;;
            substack) distribute_email "$FILE" ;;  # Same export path
            heygen)   distribute_heygen "$FILE" ;;
            medium)   distribute_medium "$FILE" ;;
            reddit)
                # Reddit is NEVER auto-distributed — export only
                log "SKIP [reddit]: Manual-only. File stays in approved queue."
                TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
                continue
                ;;
            *)
                log "UNKNOWN [$CHANNEL]: Skipping $FILENAME"
                TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
                continue
                ;;
        esac

        TOTAL_DISTRIBUTED=$((TOTAL_DISTRIBUTED + 1))

        # Analytics log
        echo "{\"date\":\"$DATE_TAG\",\"time\":\"$(date '+%H:%M:%S')\",\"platform\":\"$CHANNEL\",\"action\":\"distributed\",\"file\":\"$FILENAME\",\"path\":\"distribution-engine\"}" \
            >> "$ANALYTICS_DIR/post-actions-${DATE_TAG}.jsonl"

    done < <(find "$APPROVED_DIR" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" -o -name "*.json" \) ! -name "._*" -print0 2>/dev/null)
done

log "=== Distribution Engine Complete ==="
log "Distributed: $TOTAL_DISTRIBUTED | Skipped: $TOTAL_SKIPPED | Policy-blocked: $POLICY_BLOCKED"

echo ""
echo "━━━ DISTRIBUTION SUMMARY ━━━"
echo "Distributed:    $TOTAL_DISTRIBUTED"
echo "Skipped:        $TOTAL_SKIPPED"
echo "Policy blocked: $POLICY_BLOCKED"
echo "Log: $LOG_FILE"
