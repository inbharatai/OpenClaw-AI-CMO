#!/bin/bash
# distribution-engine.sh — Distribute approved content to channels
# Usage: ./distribution-engine.sh [--dry-run] [--channel <channel>]
# Reads: OpenClawData/queues/*/approved/
# Actions: Discord webhook post, website staging, social packaging, newsletter export
# Logs: OpenClawData/logs/distribution-engine.log

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
MARKETING_DIR="$WORKSPACE_ROOT/MarketingToolData"
EXPORTS_DIR="$WORKSPACE_ROOT/ExportsLogs"
POLICIES_DIR="$WORKSPACE_ROOT/OpenClawData/policies"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/distribution-engine.log"
POSTING_LOG="$WORKSPACE_ROOT/OpenClawData/logs/posting-log.json"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_TAG=$(date '+%Y-%m-%d')

DRY_RUN=false
TARGET_CHANNEL=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --channel) TARGET_CHANNEL="$2"; shift ;;
    esac
    shift
done

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

log "=== Distribution Engine Started ==="
[ "$DRY_RUN" = true ] && log "[DRY RUN] No distribution will occur"

# Initialize posting log if it doesn't exist
if [ ! -f "$POSTING_LOG" ]; then
    echo '{"posts":[]}' > "$POSTING_LOG"
fi

TOTAL_DISTRIBUTED=0
TOTAL_SKIPPED=0

# Count today's posts for rate limiting
TODAYS_POSTS=$(grep -c "\"date\":\"$DATE_TAG\"" "$POSTING_LOG" 2>/dev/null || echo "0")
TODAYS_POSTS=$(echo "$TODAYS_POSTS" | tr -d '[:space:]')
GLOBAL_CAP=15

if [ "$TODAYS_POSTS" -ge "$GLOBAL_CAP" ] 2>/dev/null; then
    log "GLOBAL RATE LIMIT: $TODAYS_POSTS posts today (cap: $GLOBAL_CAP). Stopping."
    exit 0
fi

distribute_website() {
    local FILE="$1"
    local FILENAME=$(basename "$FILE")
    local SECTION=$(grep "^section:" "$FILE" | head -1 | sed 's/section:\s*//' | tr -d '"' | tr -d ' ')

    case "$SECTION" in
        updates|update) DEST="$MARKETING_DIR/website-posts/" ;;
        insights|insight) DEST="$MARKETING_DIR/insights/" ;;
        build-log|build_log) DEST="$MARKETING_DIR/build-logs/" ;;
        news) DEST="$MARKETING_DIR/ai-news/" ;;
        *) DEST="$MARKETING_DIR/website-posts/" ;;
    esac

    if [ "$DRY_RUN" = false ]; then
        cp "$FILE" "$DEST"
        mv "$FILE" "$EXPORTS_DIR/posted/"
        log "DISTRIBUTED [website/$SECTION]: $FILENAME → $DEST"
    else
        log "[DRY RUN] Would distribute website/$SECTION: $FILENAME → $DEST"
    fi
}

distribute_discord() {
    local FILE="$1"
    local FILENAME=$(basename "$FILE")
    local WEBHOOK_CONFIG="$POLICIES_DIR/discord-webhook.json"

    # Check if webhook is configured
    if [ ! -f "$WEBHOOK_CONFIG" ]; then
        log "SKIP [discord]: No webhook configured at $WEBHOOK_CONFIG"
        cp "$FILE" "$MARKETING_DIR/discord/"
        mv "$FILE" "$EXPORTS_DIR/posted/"
        TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
        return
    fi

    local WEBHOOK_URL=$(python3 -c "import json; print(json.load(open('$WEBHOOK_CONFIG'))['webhook_url'])" 2>/dev/null)
    local ENABLED=$(python3 -c "import json; print(json.load(open('$WEBHOOK_CONFIG')).get('enabled', False))" 2>/dev/null)

    if [ "$ENABLED" != "True" ] || [ -z "$WEBHOOK_URL" ]; then
        log "SKIP [discord]: Webhook disabled or URL missing"
        cp "$FILE" "$MARKETING_DIR/discord/"
        mv "$FILE" "$EXPORTS_DIR/posted/"
        return
    fi

    # Extract content (everything after frontmatter)
    local CONTENT=$(awk '/^---$/{c++;next}c>=2' "$FILE" | head -c 2000)
    [ -z "$CONTENT" ] && CONTENT=$(cat "$FILE")

    if [ "$DRY_RUN" = false ]; then
        # Build payload safely — pipe content via stdin to avoid injection
        local PAYLOAD=$(echo "$CONTENT" | python3 -c "
import json, sys
content = sys.stdin.read()[:1900]
payload = {'username': 'OpenClaw CMO', 'content': content}
print(json.dumps(payload))
" 2>/dev/null)

        # Post to Discord
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD" \
            "$WEBHOOK_URL" 2>/dev/null)

        if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
            log "POSTED [discord]: $FILENAME (HTTP $HTTP_CODE)"
            mv "$FILE" "$EXPORTS_DIR/posted/"
            # Log to posting log
            python3 -c "
import json
log = json.load(open('$POSTING_LOG'))
log['posts'].append({'channel':'discord','file':'$FILENAME','date':'$DATE_TAG','time':'$TIMESTAMP','status':'posted','http_code':'$HTTP_CODE'})
json.dump(log, open('$POSTING_LOG','w'), indent=2)
" 2>/dev/null
        else
            log "FAILED [discord]: $FILENAME (HTTP $HTTP_CODE) — left in approved queue"
        fi
    else
        log "[DRY RUN] Would post to Discord: $FILENAME"
    fi
}

distribute_social() {
    local CHANNEL="$1"
    local FILE="$2"
    local FILENAME=$(basename "$FILE")
    local SOCIALFLOW_URL="http://127.0.0.1:8000"
    local PUBLISHER="$SCRIPTS_DIR/socialflow-publisher.sh"

    if [ "$DRY_RUN" = false ]; then
        # Try SocialFlow live posting first
        SOCIALFLOW_RUNNING=false
        if curl -s --max-time 2 "$SOCIALFLOW_URL/api/health" > /dev/null 2>&1; then
            SOCIALFLOW_RUNNING=true
        fi

        if [ "$SOCIALFLOW_RUNNING" = true ] && [ -x "$PUBLISHER" ]; then
            log "POSTING [$CHANNEL]: $FILENAME via SocialFlow..."
            if "$PUBLISHER" "$CHANNEL" "$FILE" 2>/dev/null; then
                cp "$FILE" "$MARKETING_DIR/$CHANNEL/"
                mv "$FILE" "$EXPORTS_DIR/posted/"
                log "POSTED [$CHANNEL]: $FILENAME via SocialFlow"
                # Log to posting log
                python3 -c "
import json
log = json.load(open('$POSTING_LOG'))
log['posts'].append({'channel':'$CHANNEL','file':'$FILENAME','date':'$DATE_TAG','time':'$TIMESTAMP','status':'posted','via':'socialflow'})
json.dump(log, open('$POSTING_LOG','w'), indent=2)
" 2>/dev/null
                return
            else
                log "SOCIALFLOW FAILED [$CHANNEL]: $FILENAME — falling back to export"
            fi
        fi

        # Fallback: export to folder
        cp "$FILE" "$MARKETING_DIR/$CHANNEL/"
        mv "$FILE" "$EXPORTS_DIR/posted/"
        log "EXPORTED [$CHANNEL]: $FILENAME → $MARKETING_DIR/$CHANNEL/"
    else
        log "[DRY RUN] Would post/export $CHANNEL: $FILENAME"
    fi
}

distribute_email() {
    local FILE="$1"
    local FILENAME=$(basename "$FILE")
    local SOCIALFLOW_URL="http://127.0.0.1:8000"
    local PUBLISHER="$SCRIPTS_DIR/socialflow-publisher.sh"

    if [ "$DRY_RUN" = false ]; then
        # Try SocialFlow for newsletter platforms
        if curl -s --max-time 2 "$SOCIALFLOW_URL/api/health" > /dev/null 2>&1 && [ -x "$PUBLISHER" ]; then
            # Detect email platform from content
            EMAIL_PLATFORM=$(grep "^email_platform:" "$FILE" | head -1 | sed 's/email_platform:\s*//' | tr -d '"' | tr -d ' ')
            [ -z "$EMAIL_PLATFORM" ] && EMAIL_PLATFORM="beehiiv"

            if "$PUBLISHER" "$EMAIL_PLATFORM" "$FILE" 2>/dev/null; then
                cp "$FILE" "$EXPORTS_DIR/email/ready-to-send/"
                mv "$FILE" "$EXPORTS_DIR/posted/"
                log "POSTED [email/$EMAIL_PLATFORM]: $FILENAME via SocialFlow"
                return
            fi
        fi

        # Fallback: export
        cp "$FILE" "$EXPORTS_DIR/email/ready-to-send/"
        mv "$FILE" "$EXPORTS_DIR/posted/"
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
        log "EXPORTED [heygen]: $FILENAME → video-briefs/"
    else
        log "[DRY RUN] Would export heygen: $FILENAME"
    fi
}

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

# Blocked channels — skip entirely
# LinkedIn unblocked for posting (2026-03-31). Re-add "linkedin" to block again.
BLOCKED_CHANNELS=""

for CHANNEL in "${CHANNELS[@]}"; do
    if echo "$BLOCKED_CHANNELS" | grep -qw "$CHANNEL"; then
        log "BLOCKED CHANNEL: $CHANNEL — skipping (blocked by policy)"
        continue
    fi
    APPROVED_DIR="$QUEUES_DIR/$CHANNEL/approved"
    [ -d "$APPROVED_DIR" ] || continue

    while IFS= read -r -d '' FILE; do
        FILENAME=$(basename "$FILE")
        [[ "$FILENAME" == .* ]] && continue

        # Check global rate limit
        TODAYS_POSTS=$(grep -c "\"date\":\"$DATE_TAG\"" "$POSTING_LOG" 2>/dev/null || echo "0")
        TODAYS_POSTS=$(echo "$TODAYS_POSTS" | tr -d '[:space:]')
        if [ "$TODAYS_POSTS" -ge "$GLOBAL_CAP" ] 2>/dev/null; then
            log "GLOBAL RATE LIMIT reached ($TODAYS_POSTS/$GLOBAL_CAP). Stopping distribution."
            break 2
        fi

        case "$CHANNEL" in
            website) distribute_website "$FILE" ;;
            discord) distribute_discord "$FILE" ;;
            linkedin|x|facebook|instagram|shorts) distribute_social "$CHANNEL" "$FILE" ;;
            email|substack) distribute_email "$FILE" ;;
            heygen) distribute_heygen "$FILE" ;;
            medium|reddit) distribute_social "$CHANNEL" "$FILE" ;;
            *) log "UNKNOWN CHANNEL: $CHANNEL — skipping $FILENAME"; TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1)) ;;
        esac

        TOTAL_DISTRIBUTED=$((TOTAL_DISTRIBUTED + 1))

    done < <(find "$APPROVED_DIR" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" -o -name "*.json" \) ! -name "._*" -print0 2>/dev/null)
done

log "=== Distribution Engine Complete ==="
log "Distributed: $TOTAL_DISTRIBUTED | Skipped: $TOTAL_SKIPPED"

echo ""
echo "━━━ DISTRIBUTION SUMMARY ━━━"
echo "Distributed: $TOTAL_DISTRIBUTED"
echo "Skipped:     $TOTAL_SKIPPED"
echo "Log: $LOG_FILE"
