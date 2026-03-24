#!/bin/bash
# ============================================================
# calendar-enforcer.sh — Operationally enforces the content calendar
#
# This is NOT a calendar generator. It CHECKS what content should
# be produced today based on the weekly plan, identifies gaps,
# and triggers production for missing items.
#
# Run: daily, after intake but before content-agent
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/date-context.sh"

CONFIG="$WORKSPACE_ROOT/configs/openclaw.yaml"
CALENDAR_DIR="$WORKSPACE_ROOT/data/calendars"
QUEUES_DIR="$WORKSPACE_ROOT/queues"
LOG_FILE="$WORKSPACE_ROOT/logs/calendar-enforcer.log"
CALENDAR_STATE="$WORKSPACE_ROOT/logs/calendar-state.json"

mkdir -p "$CALENDAR_DIR" "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

log "=== Calendar Enforcer Started — $CURRENT_DATE ($CURRENT_DAY) ==="

# ── Read weekly targets from config ──
read_yaml_value() {
    local key="$1"
    python3 -c "
import yaml
with open('$CONFIG') as f:
    cfg = yaml.safe_load(f)
keys = '$key'.split('.')
val = cfg
for k in keys:
    val = val.get(k, {})
if isinstance(val, dict):
    import json
    print(json.dumps(val))
else:
    print(val)
" 2>/dev/null
}

# ── Count what was already produced this week ──
WEEK_START=$(python3 -c "
from datetime import datetime, timedelta
today = datetime.now()
start = today - timedelta(days=today.weekday())
print(start.strftime('%Y-%m-%d'))
")

count_produced_this_week() {
    local platform="$1"
    local count=0

    # Check queues (pending + approved)
    for state in pending approved; do
        local dir="$QUEUES_DIR/$platform/$state"
        if [ -d "$dir" ]; then
            local c=$(find "$dir" -name "*.md" -newer "$WORKSPACE_ROOT/logs/.week-marker" 2>/dev/null | wc -l | tr -d ' ')
            count=$((count + c))
        fi
    done

    # Check posted
    local posted=$(find "$WORKSPACE_ROOT/exports/posted" -name "${platform}*" -newer "$WORKSPACE_ROOT/logs/.week-marker" 2>/dev/null | wc -l | tr -d ' ')
    count=$((count + posted))

    echo "$count"
}

# Create week marker if missing
WEEK_MARKER="$WORKSPACE_ROOT/logs/.week-marker"
if [ ! -f "$WEEK_MARKER" ] || [ "$(date -r "$WEEK_MARKER" '+%Y-%m-%d' 2>/dev/null)" \< "$WEEK_START" ]; then
    touch -t "$(echo "$WEEK_START" | tr -d '-')0000" "$WEEK_MARKER" 2>/dev/null || touch "$WEEK_MARKER"
fi

# ── Check each platform against weekly target ──
PLATFORMS="website linkedin x instagram discord reddit newsletter youtube"
GAPS_FOUND=0
GAPS_FILE="$WORKSPACE_ROOT/logs/content-gaps-$CURRENT_DATE.json"

echo "[" > "$GAPS_FILE"
FIRST=true

for PLATFORM in $PLATFORMS; do
    # Read target from config
    TARGET=$(python3 -c "
import yaml
with open('$CONFIG') as f:
    cfg = yaml.safe_load(f)
print(cfg.get('calendar',{}).get('weekly_targets',{}).get('$PLATFORM', 0))
" 2>/dev/null)
    [ -z "$TARGET" ] && TARGET=0

    PRODUCED=$(count_produced_this_week "$PLATFORM")

    # Calculate daily target (spread across 7 days)
    DAY_NUM=$(python3 -c "from datetime import datetime; print(datetime.now().weekday() + 1)")
    EXPECTED_BY_NOW=$(python3 -c "import math; print(math.ceil($TARGET * $DAY_NUM / 7))")

    GAP=$((EXPECTED_BY_NOW - PRODUCED))
    [ "$GAP" -lt 0 ] && GAP=0

    if [ "$GAP" -gt 0 ]; then
        GAPS_FOUND=$((GAPS_FOUND + GAP))
        log "GAP: $PLATFORM — produced $PRODUCED/$TARGET this week, need $GAP more by today"

        [ "$FIRST" = true ] && FIRST=false || echo "," >> "$GAPS_FILE"
        cat >> "$GAPS_FILE" <<EOF
{
    "platform": "$PLATFORM",
    "weekly_target": $TARGET,
    "produced_this_week": $PRODUCED,
    "expected_by_today": $EXPECTED_BY_NOW,
    "gap": $GAP,
    "date": "$CURRENT_DATE",
    "day": "$CURRENT_DAY"
}
EOF
    else
        log "OK: $PLATFORM — on track ($PRODUCED/$TARGET)"
    fi
done

echo "]" >> "$GAPS_FILE"

# ── Determine what content types to generate ──
if [ "$GAPS_FOUND" -gt 0 ]; then
    log "Total gaps: $GAPS_FOUND items needed"

    # Read pillar mix
    PILLARS=$(python3 -c "
import yaml, json
with open('$CONFIG') as f:
    cfg = yaml.safe_load(f)
print(json.dumps(cfg.get('calendar',{}).get('pillars',{})))
" 2>/dev/null)

    # Write gap-fill request for content-agent
    GAP_REQUEST="$WORKSPACE_ROOT/data/source-notes/calendar-gap-fill-$CURRENT_DATE.md"
    cat > "$GAP_REQUEST" <<EOF
---
title: "Calendar Gap Fill — $CURRENT_DATE"
date: "$CURRENT_DATE"
type: "calendar-gap-fill"
source: "calendar-enforcer"
auto_generated: true
---

# Content Gaps Detected — $CURRENT_DATE ($CURRENT_DAY)

The content calendar enforcer detected $GAPS_FOUND content gaps.

## Gaps Found

$(cat "$GAPS_FILE" | python3 -c "
import sys, json
gaps = json.load(sys.stdin)
for g in gaps:
    print(f'- **{g[\"platform\"]}**: need {g[\"gap\"]} more (have {g[\"produced_this_week\"]}/{g[\"weekly_target\"]})')
" 2>/dev/null)

## Pillar Mix Target
$(echo "$PILLARS" | python3 -c "
import sys, json
p = json.load(sys.stdin)
for k,v in p.items():
    print(f'- {k.replace(\"_\", \" \").title()}: {v}%')
" 2>/dev/null)

## Action Required
Generate content to fill these gaps. Prioritize platforms with the largest gaps.
Use the pillar mix above to choose content topics.
EOF

    # Create matching meta file
    python3 -c "
import json
meta = {
    'source_file': '$GAP_REQUEST',
    'content_type': 'calendar-gap-fill',
    'status': 'classified',
    'suggested_channels': '$(cat "$GAPS_FILE" | python3 -c "import sys,json; print(','.join(g['platform'] for g in json.load(sys.stdin)))" 2>/dev/null)',
    'auto_generated': True,
    'date': '$CURRENT_DATE'
}
json.dump(meta, open('${GAP_REQUEST%.md}.meta.json', 'w'), indent=2)
"

    log "Created gap-fill request: $GAP_REQUEST"
else
    log "All platforms on track. No gaps."
fi

# ── Save state for reporting ──
python3 -c "
import json
state = {
    'date': '$CURRENT_DATE',
    'day': '$CURRENT_DAY',
    'week_start': '$WEEK_START',
    'gaps_found': $GAPS_FOUND,
    'gaps_file': '$GAPS_FILE'
}
json.dump(state, open('$CALENDAR_STATE', 'w'), indent=2)
"

log "=== Calendar Enforcer Complete — $GAPS_FOUND gaps found ==="
