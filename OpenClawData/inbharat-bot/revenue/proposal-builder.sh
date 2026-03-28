#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# proposal-builder.sh — Generate proposal drafts from leads
# Usage: ./proposal-builder.sh <lead-json-file>
# Output: Proposal markdown in revenue/proposals/
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

WS="/Volumes/Expansion/CMO-10million"
BOT_ROOT="$WS/OpenClawData/inbharat-bot"
PROPOSALS="$BOT_ROOT/revenue/proposals"
LOG="$BOT_ROOT/logging/bot-$(date +%Y-%m-%d).log"
TS=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')

log() { echo "[$TS] $1" >> "$LOG"; echo "$1"; }

LEAD_FILE="${1:?Usage: proposal-builder.sh <lead-json-file>}"
[ ! -f "$LEAD_FILE" ] && echo "ERROR: Lead file not found" && exit 1

LEAD=$(cat "$LEAD_FILE")
LEAD_ID=$(echo "$LEAD" | python3 -c "import sys,json; print(json.load(sys.stdin).get('lead_id','unknown'))" 2>/dev/null)
CONTACT=$(echo "$LEAD" | python3 -c "import sys,json; print(json.load(sys.stdin).get('contact_name',''))" 2>/dev/null)
SUMMARY=$(echo "$LEAD" | python3 -c "import sys,json; print(json.load(sys.stdin).get('summary',''))" 2>/dev/null)
INQUIRY=$(echo "$LEAD" | python3 -c "import sys,json; print(json.load(sys.stdin).get('inquiry_type',''))" 2>/dev/null)

log "=== Proposal Builder: $LEAD_ID ==="

PROMPT="You are a business proposal writer for InBharat, an AI tools and services company founded by a solo builder.

Generate a professional but personal proposal draft based on this lead.

LEAD INFO:
- Contact: $CONTACT
- Inquiry type: $INQUIRY
- Summary: $SUMMARY
- Full lead data: $LEAD

Write a proposal in markdown with these sections:
1. Opening (personalized, reference their need)
2. Understanding (restate what they need in your words)
3. Proposed Solution (what InBharat can do, be specific but honest)
4. Approach (how you would do it, timeline)
5. Investment (leave placeholder for pricing: [PRICING TO BE CONFIRMED])
6. Why InBharat (brief, genuine, not salesy)
7. Next Steps (suggest a call or follow-up)

Keep it under 500 words. Be genuine, not corporate. Solo founder voice.
Output the markdown proposal ONLY."

RESPONSE=$(curl -s http://127.0.0.1:11434/api/generate \
  -d "{\"model\":\"qwen3:8b\",\"prompt\":$(echo "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))'),\"stream\":false,\"options\":{\"temperature\":0.4}}" 2>/dev/null)

TEXT=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response','') or d.get('thinking',''))" 2>/dev/null)

if [ -z "$TEXT" ]; then
  log "ERROR: Empty proposal response"
  exit 1
fi

OUT_FILE="$PROPOSALS/proposal-${LEAD_ID}-${DATE}.md"
cat > "$OUT_FILE" << PROP
---
lead_id: $LEAD_ID
contact: $CONTACT
inquiry: $INQUIRY
generated: $TS
status: draft
---

$TEXT
PROP

log "Proposal saved: $OUT_FILE"
log "=== Proposal complete ==="
