#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# multilingual-adapter.sh — Adapt content to target language with tone
# Usage: ./multilingual-adapter.sh <content-file> <language> [tone]
# Languages: en, as (Assamese), hi (Hindi), bn (Bengali)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

WS="/Volumes/Expansion/CMO-10million"
MULTI_DIR="$WS/OpenClawData/multilingual"
LOG="$WS/OpenClawData/logs/multilingual.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')

log() { echo "[$TS] $1" >> "$LOG"; echo "$1"; }

CONTENT_FILE="${1:?Usage: multilingual-adapter.sh <content-file> <language> [tone]}"
LANG="${2:?Missing language code (en/as/hi/bn)}"
TONE="${3:-natural}"

[ ! -f "$CONTENT_FILE" ] && echo "ERROR: File not found: $CONTENT_FILE" && exit 1

CONTENT=$(cat "$CONTENT_FILE")

# Language names
case "$LANG" in
  en) LANG_NAME="English" ;;
  as) LANG_NAME="Assamese" ;;
  hi) LANG_NAME="Hindi" ;;
  bn) LANG_NAME="Bengali" ;;
  *) LANG_NAME="$LANG" ;;
esac

log "=== Multilingual Adapter: → $LANG_NAME ($TONE) ==="

# Check for language-specific tone template
TONE_FILE="$MULTI_DIR/templates/tone-$LANG.md"
TONE_GUIDE=""
if [ -f "$TONE_FILE" ]; then
  TONE_GUIDE="Use this tone guide: $(cat "$TONE_FILE")"
fi

PROMPT="You are a multilingual content adapter for InBharat.

Adapt the following content into $LANG_NAME.

IMPORTANT RULES:
- This is NOT a literal translation. Adapt the tone and cultural context.
- Keep technical terms in English where natural in $LANG_NAME.
- Make it sound like it was originally written in $LANG_NAME.
- Tone: $TONE
- Keep the same message and intent, but make it culturally appropriate.
$TONE_GUIDE

ORIGINAL CONTENT:
$CONTENT

Output the adapted $LANG_NAME content ONLY. No explanations."

RESPONSE=$(curl -s http://127.0.0.1:11434/api/generate \
  -d "{\"model\":\"qwen3:8b\",\"prompt\":$(echo "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))'),\"stream\":false,\"options\":{\"temperature\":0.5}}" 2>/dev/null)

TEXT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('response',''))" 2>/dev/null)

if [ -z "$TEXT" ]; then
  log "ERROR: Empty response"
  exit 1
fi

SRC_NAME=$(basename "$CONTENT_FILE" .md)
OUT_FILE="$MULTI_DIR/${SRC_NAME}-${LANG}.md"

cat > "$OUT_FILE" << ADAPTED
---
source: $(basename "$CONTENT_FILE")
language: $LANG_NAME
tone: $TONE
adapted: $TS
---

$TEXT
ADAPTED

log "Adapted content saved: $OUT_FILE"
