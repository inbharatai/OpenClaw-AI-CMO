#!/bin/bash
# qa-guardrail.sh — Pre-publish quality assurance gate for OpenClaw
#
# Runs all validation checks on approved content before publishing.
# This is the final gate between the approval queue and the posting engine.
#
# Usage:
#   ./qa-guardrail.sh                          Check all approved queues
#   ./qa-guardrail.sh --platform linkedin       Check specific platform
#   ./qa-guardrail.sh --file /path/to/content   Check specific file
#   ./qa-guardrail.sh --fix                     Auto-fix what can be fixed
#
# Exit codes:
#   0 = all checks pass
#   1 = some checks failed (content needs review)

set -o pipefail

WORKSPACE_ROOT="/Users/reeturajgoswami/Desktop/CMO-10million"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
ENGINE_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine"
SANITIZER="$ENGINE_DIR/sanitize_post.py"
RENDERER="$ENGINE_DIR/render_post.py"
BRAND_VOICE="$WORKSPACE_ROOT/OpenClawData/policies/brand-voice-rules.json"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/qa-guardrail.log"
DATE=$(date '+%Y-%m-%d')

PLATFORM_FILTER=""
FILE_FILTER=""
FIX_MODE=false

while [ $# -gt 0 ]; do
  case "$1" in
    --platform) PLATFORM_FILTER="$2"; shift ;;
    --file)     FILE_FILTER="$2"; shift ;;
    --fix)      FIX_MODE=true ;;
    -h|--help)
      echo "Usage: qa-guardrail.sh [--platform <name>] [--file <path>] [--fix]"
      exit 0
      ;;
  esac
  shift
done

mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
  echo "$1"
}

TOTAL=0
PASSED=0
FAILED=0
FIXED=0

check_file() {
  local FILE="$1"
  local PLATFORM="$2"
  local FNAME=$(basename "$FILE")

  TOTAL=$((TOTAL + 1))
  local ISSUES=()

  # ── Check 1: Content sanitization ──
  if [ -f "$SANITIZER" ]; then
    SANITIZE_RESULT=$(python3 "$SANITIZER" --validate-only --file "$FILE" --json-output 2>&1)
    SANITIZE_EXIT=$?
    if [ $SANITIZE_EXIT -ne 0 ]; then
      ISSUES+=("SANITIZE: Content contains internal metadata/JSON artifacts")
    fi
  fi

  # ── Check 2: Render succeeds ──
  if [ -f "$RENDERER" ]; then
    RENDERED=$(python3 "$RENDERER" --file "$FILE" --platform "$PLATFORM" 2>/dev/null)
    RENDER_EXIT=$?
    if [ $RENDER_EXIT -ne 0 ] || [ -z "$RENDERED" ]; then
      ISSUES+=("RENDER: Could not extract clean content for $PLATFORM")
    else
      CHAR_COUNT=${#RENDERED}

      # ── Check 3: Platform length limits ──
      case "$PLATFORM" in
        x)
          if [ $CHAR_COUNT -gt 280 ]; then
            ISSUES+=("LENGTH: X post is $CHAR_COUNT chars (max 280)")
          fi
          ;;
        discord)
          if [ $CHAR_COUNT -gt 2000 ]; then
            ISSUES+=("LENGTH: Discord message is $CHAR_COUNT chars (max 2000)")
          fi
          ;;
        instagram)
          if [ $CHAR_COUNT -gt 2200 ]; then
            ISSUES+=("LENGTH: Instagram caption is $CHAR_COUNT chars (max 2200)")
          fi
          ;;
        linkedin)
          if [ $CHAR_COUNT -gt 3000 ]; then
            ISSUES+=("LENGTH: LinkedIn post is $CHAR_COUNT chars (max 3000)")
          fi
          ;;
      esac

      # ── Check 4: Content is not empty/trivial ──
      if [ $CHAR_COUNT -lt 20 ]; then
        ISSUES+=("CONTENT: Rendered content too short ($CHAR_COUNT chars)")
      fi

      # ── Check 5: No banned phrases ──
      if [ -f "$BRAND_VOICE" ]; then
        BANNED_CHECK=$(echo "$RENDERED" | python3 -c "
import sys, json
try:
    with open('$BRAND_VOICE') as f:
        rules = json.load(f)
    banned = rules.get('banned_phrases', [])
    text = sys.stdin.read().lower()
    found = [b for b in banned if b.lower() in text]
    if found:
        print('BANNED: ' + ', '.join(found))
except Exception as e:
    pass
" 2>/dev/null)
        if [ -n "$BANNED_CHECK" ]; then
          ISSUES+=("$BANNED_CHECK")
        fi
      fi

      # ── Check 6: Raw markdown syntax ──
      if echo "$RENDERED" | grep -q '```'; then
        ISSUES+=("MARKDOWN: Raw code fence (\`\`\`) found in rendered content")
      fi
      if echo "$RENDERED" | grep -qE '^#{1,6} '; then
        ISSUES+=("MARKDOWN: Raw heading marker (###) found in rendered content")
      fi
      if echo "$RENDERED" | grep -qE '\*\*[^*]+\*\*'; then
        ISSUES+=("MARKDOWN: Raw bold markers (**text**) found in rendered content")
      fi

      # ── Check 7: Excessive hashtags ──
      HASHTAG_COUNT=$(echo "$RENDERED" | grep -oE '#[A-Za-z][A-Za-z0-9_]*' | wc -l | tr -d ' ')
      case "$PLATFORM" in
        x)
          if [ "$HASHTAG_COUNT" -gt 2 ]; then
            ISSUES+=("HASHTAGS: $HASHTAG_COUNT hashtags on X (max 2)")
          fi
          ;;
        linkedin)
          if [ "$HASHTAG_COUNT" -gt 5 ]; then
            ISSUES+=("HASHTAGS: $HASHTAG_COUNT hashtags on LinkedIn (max 5)")
          fi
          ;;
        instagram)
          if [ "$HASHTAG_COUNT" -gt 15 ]; then
            ISSUES+=("HASHTAGS: $HASHTAG_COUNT hashtags on Instagram (max 15)")
          fi
          ;;
      esac
    fi
  fi

  # ── Report ──
  if [ ${#ISSUES[@]} -eq 0 ]; then
    log "  PASS: $PLATFORM/$FNAME"
    PASSED=$((PASSED + 1))
  else
    log "  FAIL: $PLATFORM/$FNAME"
    for issue in "${ISSUES[@]}"; do
      log "    - $issue"
    done
    FAILED=$((FAILED + 1))
  fi
}

# ── Main ──
log "━━━ QA Guardrail Check ━━━"

if [ -n "$FILE_FILTER" ]; then
  # Check single file
  PLATFORM=${PLATFORM_FILTER:-"linkedin"}
  check_file "$FILE_FILTER" "$PLATFORM"
else
  # Check all approved queues
  PLATFORMS=(linkedin x discord instagram email)
  for PLATFORM in "${PLATFORMS[@]}"; do
    if [ -n "$PLATFORM_FILTER" ] && [ "$PLATFORM_FILTER" != "$PLATFORM" ]; then
      continue
    fi

    APPROVED_DIR="$QUEUES_DIR/$PLATFORM/approved"
    [ -d "$APPROVED_DIR" ] || continue

    for FILE in "$APPROVED_DIR"/*; do
      [ -f "$FILE" ] || continue
      FNAME=$(basename "$FILE")
      [[ "$FNAME" == .* ]] && continue
      [[ "$FNAME" == *.gitkeep ]] && continue
      check_file "$FILE" "$PLATFORM"
    done
  done
fi

log "━━━ QA Summary ━━━"
log "Total: $TOTAL | Passed: $PASSED | Failed: $FAILED"

echo ""
echo "━━━ QA GUARDRAIL RESULTS ━━━"
echo "Total:  $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

[ $FAILED -gt 0 ] && exit 1
exit 0
