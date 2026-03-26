#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# community-rewriter.sh — Rewrite content for community-native tone
# Usage: ./community-rewriter.sh <content-file> <community-profile>
# Output: Rewritten file in community/drafts/
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

WS="/Volumes/Expansion/CMO-10million"
DRAFTS="$WS/OpenClawData/community/drafts"
LOG="$WS/OpenClawData/logs/community-rewriter.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')

log() { echo "[$TS] $1" >> "$LOG"; echo "$1"; }

CONTENT_FILE="${1:?Usage: community-rewriter.sh <content-file> <community-profile>}"
PROFILE_FILE="${2:?Missing community profile JSON}"

[ ! -f "$CONTENT_FILE" ] && echo "ERROR: Content file not found: $CONTENT_FILE" && exit 1
[ ! -f "$PROFILE_FILE" ] && echo "ERROR: Profile not found: $PROFILE_FILE" && exit 1

CONTENT=$(cat "$CONTENT_FILE")
PROFILE=$(cat "$PROFILE_FILE")

# Extract key info from profile
COMMUNITY_NAME=$(echo "$PROFILE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('name','unknown'))" 2>/dev/null)
PLATFORM=$(echo "$PROFILE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('platform','unknown'))" 2>/dev/null)
TONE=$(echo "$PROFILE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tone','neutral'))" 2>/dev/null)
MODE=$(echo "$PROFILE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('recommended_posting_mode','observe'))" 2>/dev/null)
AVOID=$(echo "$PROFILE" | python3 -c "import sys,json; print(', '.join(json.load(sys.stdin).get('avoid',[])))" 2>/dev/null)
PROMO=$(echo "$PROFILE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('rules',{}).get('self_promotion','limited'))" 2>/dev/null)

log "=== Rewriting for $COMMUNITY_NAME ($PLATFORM) mode=$MODE ==="

if [ "$MODE" = "observe" ]; then
  log "SKIP: Community is in observe-only mode. No rewrite."
  exit 0
fi

PROMPT="You are an expert community content adapter. Rewrite this content for a specific online community.

ORIGINAL CONTENT:
$CONTENT

TARGET COMMUNITY: $COMMUNITY_NAME ($PLATFORM)
TONE: $TONE
POSTING MODE: $MODE
SELF-PROMOTION POLICY: $PROMO
THINGS TO AVOID: $AVOID

REWRITE RULES:
- If mode is 'value': Lead with genuine insight. Subtle mention only. No hard sell.
- If mode is 'discussion': Frame as a question or discussion starter. No promotion.
- If mode is 'comment': Write as a helpful reply to someone's question. No links.
- If mode is 'broadcast': Direct but respectful. Can include links.
- Match the community's tone exactly ($TONE).
- Remove any marketing language if self-promotion is limited or banned.
- For Reddit: No links in body text. Put links in a follow-up comment note.
- For Discord: Can be more casual, use emoji if appropriate.
- For HN: Ultra-minimal. Show don't tell. Technical only.
- For LinkedIn: Professional, founder-story angle.

Output the rewritten content ONLY. No explanations."

RESPONSE=$(curl -s http://127.0.0.1:11434/api/generate \
  -d "{\"model\":\"qwen3:8b\",\"prompt\":$(echo "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))'),\"stream\":false,\"options\":{\"temperature\":0.5}}" 2>/dev/null)

TEXT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('response',''))" 2>/dev/null)

if [ -z "$TEXT" ]; then
  log "ERROR: Empty response from Ollama"
  exit 1
fi

SAFE_COMMUNITY=$(echo "$COMMUNITY_NAME" | tr '/' '-' | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
OUT_FILE="$DRAFTS/${PLATFORM}-${SAFE_COMMUNITY}-$(date +%Y-%m-%d-%H%M%S).md"

cat > "$OUT_FILE" << DRAFT
---
source: $(basename "$CONTENT_FILE")
community: $COMMUNITY_NAME
platform: $PLATFORM
mode: $MODE
tone: $TONE
rewritten: $TS
---

$TEXT
DRAFT

log "Draft saved: $OUT_FILE"
log "=== Rewrite complete ==="
