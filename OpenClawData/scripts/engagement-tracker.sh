#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# engagement-tracker.sh — Track content performance and outcomes
# Usage: ./engagement-tracker.sh <action> [args]
# Actions: --log, --report, --best
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

WS="/Volumes/Expansion/CMO-10million"
ENGAGEMENT="$WS/OpenClawData/engagement"
LOG="$WS/OpenClawData/logs/engagement.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')

mkdir -p "$ENGAGEMENT"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; echo "$1"; }

ACTION="${1:---report}"

case "$ACTION" in
  --log)
    # Log an engagement event
    PLATFORM="${2:?Missing platform}"
    CONTENT_ID="${3:?Missing content ID}"
    METRIC="${4:?Missing metric (views/likes/comments/shares/clicks)}"
    VALUE="${5:?Missing value}"
    
    echo "{\"date\":\"$DATE\",\"time\":\"$TS\",\"platform\":\"$PLATFORM\",\"content_id\":\"$CONTENT_ID\",\"metric\":\"$METRIC\",\"value\":$VALUE}" >> "$ENGAGEMENT/events-$DATE.jsonl"
    log "Logged: $PLATFORM/$CONTENT_ID $METRIC=$VALUE"
    ;;

  --report)
    log "=== Engagement Report ==="
    TOTAL_EVENTS=$(find "$ENGAGEMENT" -name "events-*.jsonl" -type f 2>/dev/null | xargs cat 2>/dev/null | wc -l | tr -d ' ')
    log "Total events tracked: $TOTAL_EVENTS"
    
    if [ "$TOTAL_EVENTS" -gt 0 ]; then
      ENGAGEMENT_DIR="$ENGAGEMENT" python3 -c "
import json, glob, collections, os
events = []
for f in glob.glob(os.path.join(os.environ['ENGAGEMENT_DIR'], 'events-*.jsonl')):
    for line in open(f):
        try: events.append(json.loads(line.strip()))
        except: pass

by_platform = collections.Counter(e['platform'] for e in events)
by_metric = collections.Counter(e['metric'] for e in events)

print('By platform:')
for p, c in by_platform.most_common(): print(f'  {p}: {c} events')
print('By metric:')
for m, c in by_metric.most_common(): print(f'  {m}: {c} events')
" 2>/dev/null
    else
      log "No engagement data yet. Use --log to add events."
    fi
    ;;

  --best)
    log "=== Best Performing Content ==="
    ENGAGEMENT_DIR="$ENGAGEMENT" python3 -c "
import json, glob, collections, os
events = []
for f in glob.glob(os.path.join(os.environ['ENGAGEMENT_DIR'], 'events-*.jsonl')):
    for line in open(f):
        try: events.append(json.loads(line.strip()))
        except: pass

if not events:
    print('No data yet.')
else:
    scores = collections.defaultdict(int)
    for e in events:
        scores[e['content_id']] += e.get('value', 0)
    top = sorted(scores.items(), key=lambda x: -x[1])[:5]
    for cid, score in top:
        print(f'  {cid}: total={score}')
" 2>/dev/null
    ;;
esac
