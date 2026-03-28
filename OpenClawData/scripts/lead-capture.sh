#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# lead-capture.sh — Detect and classify inbound opportunities
# Usage: ./lead-capture.sh <source-type> <source-file-or-text>
# Sources: email, whatsapp, form, manual
# Output: Lead JSON in revenue/leads/
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

WS="/Volumes/Expansion/CMO-10million"
LEADS="$WS/OpenClawData/revenue/leads"
LOG="$WS/OpenClawData/logs/revenue.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')

log() { echo "[$TS] $1" >> "$LOG"; echo "$1"; }

SOURCE_TYPE="${1:-manual}"
SOURCE_INPUT="${2:-}"

if [ -f "$SOURCE_INPUT" ]; then
  CONTENT=$(cat "$SOURCE_INPUT")
elif [ -n "$SOURCE_INPUT" ]; then
  CONTENT="$SOURCE_INPUT"
else
  echo "Usage: lead-capture.sh <source-type> <source-file-or-text>"
  exit 1
fi

log "=== Lead Capture: source=$SOURCE_TYPE ==="

PROMPT="You are a lead qualification assistant for InBharat, an AI tools and services company.

Analyze this inbound message/inquiry and produce a structured lead assessment.

SOURCE TYPE: $SOURCE_TYPE
CONTENT:
$CONTENT

Produce ONLY valid JSON:
{
  \"lead_id\": \"lead-$DATE-<short-slug>\",
  \"date\": \"$DATE\",
  \"source\": \"$SOURCE_TYPE\",
  \"contact_name\": \"<extracted or unknown>\",
  \"contact_email\": \"<extracted or unknown>\",
  \"contact_org\": \"<extracted or unknown>\",
  \"inquiry_type\": \"<service-request/partnership/job/investment/general/spam>\",
  \"summary\": \"<1-2 sentence summary>\",
  \"urgency\": \"<high/medium/low>\",
  \"qualification\": \"<hot/warm/cold/spam>\",
  \"suggested_action\": \"<reply/schedule-call/send-info/defer/ignore>\",
  \"draft_reply\": \"<suggested reply text if action is reply>\",
  \"notes\": \"<any tactical notes>\"
}

Be conservative. If unsure, mark as 'cold' and 'defer'. Output ONLY JSON."

RESPONSE=$(curl -s http://127.0.0.1:11434/api/generate \
  -d "{\"model\":\"qwen3:8b\",\"prompt\":$(echo "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))'),\"stream\":false,\"options\":{\"temperature\":0.2}}" 2>/dev/null)

TEXT=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response','') or d.get('thinking',''))" 2>/dev/null)

JSON=$(echo "$TEXT" | python3 -c "
import sys, re, json
text = sys.stdin.read()
m = re.search(r'\{[\s\S]*\}', text)
if m:
    try:
        obj = json.loads(m.group())
        print(json.dumps(obj, indent=2))
    except: print('PARSE_ERROR')
else: print('NO_JSON')
" 2>/dev/null)

if [ "$JSON" = "PARSE_ERROR" ] || [ "$JSON" = "NO_JSON" ] || [ -z "$JSON" ]; then
  log "ERROR: Failed to classify lead"
  exit 1
fi

LEAD_ID=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('lead_id','lead-$DATE-unknown'))" 2>/dev/null)
OUT_FILE="$LEADS/${LEAD_ID}.json"
echo "$JSON" > "$OUT_FILE"

QUAL=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('qualification','?'))" 2>/dev/null)
ACTION=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('suggested_action','?'))" 2>/dev/null)

log "Lead saved: $OUT_FILE | qualification=$QUAL action=$ACTION"
log "=== Lead capture complete ==="
