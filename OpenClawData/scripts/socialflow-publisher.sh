# DEPRECATED — SocialFlow bypassed. Use distribution-engine.sh instead.
#!/bin/bash
# socialflow-publisher.sh — Bridge from OpenClaw distribution to SocialFlow API
# Usage: ./socialflow-publisher.sh <platform> <content-file> [--dry-run]
# Sends approved content from OpenClaw to SocialFlow for browser-based posting
# SocialFlow must be running at http://127.0.0.1:8000

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SOCIALFLOW_URL="http://127.0.0.1:8000"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/socialflow-publisher.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

PLATFORM="$1"
CONTENT_FILE="$2"
DRY_RUN=false

[ "$3" = "--dry-run" ] && DRY_RUN=true

log() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
    echo "$1"
}

if [ -z "$PLATFORM" ] || [ -z "$CONTENT_FILE" ]; then
    echo "Usage: $0 <platform> <content-file> [--dry-run]"
    echo "Platforms: linkedin, x, facebook, instagram, discord, reddit, medium, substack, heygen, beehiiv"
    exit 1
fi

if [ ! -f "$CONTENT_FILE" ]; then
    log "ERROR: Content file not found: $CONTENT_FILE"
    exit 1
fi

# Check SocialFlow is running
if ! curl -s --max-time 3 "$SOCIALFLOW_URL/api/health" > /dev/null 2>&1; then
    log "ERROR: SocialFlow not running at $SOCIALFLOW_URL"
    echo "Start SocialFlow first: cd SocialFlow/backend && uvicorn main:app --host 127.0.0.1 --port 8000"
    exit 1
fi

# Extract metadata from frontmatter
CONTENT=$(cat "$CONTENT_FILE")
TITLE=$(echo "$CONTENT" | grep "^title:" | head -1 | sed 's/^title:\s*//' | tr -d '"')
CONTENT_TYPE=$(echo "$CONTENT" | grep "^type:" | head -1 | sed 's/^type:\s*//' | tr -d '"' | tr -d ' ')
APPROVAL_LEVEL=$(echo "$CONTENT" | grep "^approval_level:" | head -1 | sed 's/^approval_level:\s*//' | tr -d '"' | tr -d ' ')
SUBREDDIT=$(echo "$CONTENT" | grep "^subreddit:" | head -1 | sed 's/^subreddit:\s*//' | tr -d '"' | tr -d ' ')

# Extract body (everything after second --- frontmatter marker)
BODY=$(awk '/^---$/{c++;next}c>=2' "$CONTENT_FILE")
[ -z "$BODY" ] && BODY="$CONTENT"

# Truncate body for the platform
case "$PLATFORM" in
    x|twitter) BODY=$(echo "$BODY" | head -c 280) ;;
    discord) BODY=$(echo "$BODY" | head -c 2000) ;;
    linkedin) BODY=$(echo "$BODY" | head -c 3000) ;;
    facebook) BODY=$(echo "$BODY" | head -c 2000) ;;
    instagram) BODY=$(echo "$BODY" | head -c 2200) ;;
esac

# Build JSON payload safely via Python to prevent injection
DRY_RUN_PY=$( [ "$DRY_RUN" = true ] && echo "True" || echo "False" )

PAYLOAD=$(python3 << PYEOF
import json, sys, os

content = """$BODY"""
platform = "$PLATFORM"
content_type = "${CONTENT_TYPE:-social-post}"
title_val = "${TITLE}"
approval = "${APPROVAL_LEVEL:-L2}"
source = "${CONTENT_FILE}"
dry = $DRY_RUN_PY
subreddit = "${SUBREDDIT}"

payload = {
    "platform": platform,
    "content": content.strip(),
    "content_type": content_type,
    "approval_level": approval,
    "source_file": source,
    "dry_run": dry
}

if title_val:
    payload["title"] = title_val
if platform == "reddit" and subreddit:
    payload["subreddit"] = subreddit

print(json.dumps(payload))
PYEOF
)

if [ -z "$PAYLOAD" ]; then
    log "ERROR: Failed to build JSON payload for $PLATFORM"
    exit 1
fi

log "PUBLISHING to $PLATFORM via SocialFlow..."
[ "$DRY_RUN" = true ] && log "[DRY RUN]"

# Call SocialFlow bridge API
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$SOCIALFLOW_URL/api/openclaw/publish" 2>/dev/null)

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY_RESPONSE=$(echo "$RESPONSE" | sed '$d')

SUCCESS=$(echo "$BODY_RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('success', False))" 2>/dev/null || echo "False")
MESSAGE=$(echo "$BODY_RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('message', 'Unknown'))" 2>/dev/null || echo "Parse error")

if [ "$SUCCESS" = "True" ]; then
    log "SUCCESS [$PLATFORM]: $MESSAGE (HTTP $HTTP_CODE)"
    echo "Published successfully to $PLATFORM"
else
    log "FAILED [$PLATFORM]: $MESSAGE (HTTP $HTTP_CODE)"
    echo "Failed: $MESSAGE"
    exit 1
fi
