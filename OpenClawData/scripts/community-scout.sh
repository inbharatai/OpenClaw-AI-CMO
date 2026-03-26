#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# community-scout.sh — Discover and profile communities
# Usage: ./community-scout.sh <platform> <community-name> <url>
# Output: JSON profile in community/maps/
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

WS="/Volumes/Expansion/CMO-10million"
MAPS="$WS/OpenClawData/community/maps"
SCORES="$WS/OpenClawData/community/scores"
LOG="$WS/OpenClawData/logs/community-scout.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')

log() { echo "[$TS] $1" >> "$LOG"; echo "$1"; }

PLATFORM="${1:-reddit}"
NAME="${2:-unknown}"
URL="${3:-}"
SAFE_NAME=$(echo "$NAME" | tr '/' '-' | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
OUT_FILE="$MAPS/${PLATFORM}-${SAFE_NAME}.json"

log "=== Community Scout: $PLATFORM / $NAME ==="

# Use Ollama to analyze the community
PROMPT="You are a community intelligence analyst. Analyze this online community and produce a JSON profile.

Community: $NAME
Platform: $PLATFORM
URL: $URL

Produce ONLY valid JSON with these exact fields:
{
  \"id\": \"${PLATFORM}-${SAFE_NAME}\",
  \"platform\": \"$PLATFORM\",
  \"name\": \"$NAME\",
  \"url\": \"$URL\",
  \"topic\": \"<main topic focus>\",
  \"audience\": \"<who participates>\",
  \"estimated_size\": \"<small/medium/large/very-large>\",
  \"rules\": {
    \"self_promotion\": \"<allowed/limited/banned>\",
    \"links_allowed\": <true/false>,
    \"flair_required\": <true/false>,
    \"min_account_age\": \"<requirement or none>\"
  },
  \"tone\": \"<technical/casual/professional/mixed>\",
  \"scores\": {
    \"relevance\": <1-10>,
    \"education_openness\": <1-10>,
    \"founder_openness\": <1-10>,
    \"tool_openness\": <1-10>,
    \"risk_of_removal\": <1-10>,
    \"effort_required\": <1-10>
  },
  \"recommended_posting_mode\": \"<broadcast/value/discussion/comment/observe>\",
  \"warmup_status\": \"observe\",
  \"best_content_types\": [\"<type1>\", \"<type2>\"],
  \"avoid\": [\"<thing to avoid 1>\", \"<thing to avoid 2>\"],
  \"notes\": \"<tactical notes for posting here>\"
}

Be realistic and conservative with scores. If unsure, score lower. Output ONLY JSON, no other text."

RESPONSE=$(curl -s http://127.0.0.1:11434/api/generate \
  -d "{\"model\":\"qwen3:8b\",\"prompt\":$(echo "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))'),\"stream\":false,\"options\":{\"temperature\":0.3}}" 2>/dev/null)

# Extract the response text
TEXT=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response','') or d.get('thinking',''))" 2>/dev/null)

# Extract JSON from response (handle markdown code blocks)
JSON=$(echo "$TEXT" | python3 -c "
import sys, re, json
text = sys.stdin.read()
# Try to find JSON block
m = re.search(r'\{[\s\S]*\}', text)
if m:
    try:
        obj = json.loads(m.group())
        print(json.dumps(obj, indent=2))
    except:
        print('PARSE_ERROR')
else:
    print('NO_JSON')
" 2>/dev/null)

if [ "$JSON" = "PARSE_ERROR" ] || [ "$JSON" = "NO_JSON" ] || [ -z "$JSON" ]; then
  log "ERROR: Failed to generate valid profile for $NAME"
  exit 1
fi

echo "$JSON" > "$OUT_FILE"
log "Profile saved: $OUT_FILE"

# Also generate a score summary
echo "$JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
s = d.get('scores', {})
print(f\"Relevance: {s.get('relevance',0)}/10\")
print(f\"Education: {s.get('education_openness',0)}/10\")
print(f\"Founder: {s.get('founder_openness',0)}/10\")
print(f\"Tool: {s.get('tool_openness',0)}/10\")
print(f\"Risk: {s.get('risk_of_removal',0)}/10\")
print(f\"Mode: {d.get('recommended_posting_mode','observe')}\")
" 2>/dev/null

log "=== Scout complete for $NAME ==="
