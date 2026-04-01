#!/bin/bash
# claim-validator.sh — Validates content packages against product truth
# Catches fabricated statistics, unverifiable claims, and restricted claims
# before content reaches publishing queues.
#
# Usage:
#   ./claim-validator.sh <file>           Validate a single content package
#   ./claim-validator.sh --scan-queues    Scan all pending queue items
#   ./claim-validator.sh --scan-dir <dir> Scan all files in a directory

set -o pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
STRATEGY_DIR="$WORKSPACE_ROOT/OpenClawData/strategy"
REGISTRY="$STRATEGY_DIR/product-registry.json"
DATE=$(date '+%Y-%m-%d')

CMD="${1:-}"
shift 2>/dev/null || true

# ── Validation rules ──
validate_file() {
  local FILE="$1"
  local FNAME=$(basename "$FILE")
  local ISSUES=0
  local WARNINGS=0

  if [ ! -f "$FILE" ]; then
    echo "ERROR: File not found: $FILE"
    return 1
  fi

  CONTENT=$(cat "$FILE" 2>/dev/null)

  echo "━━━ Validating: $FNAME ━━━"

  # Rule 1: Check for fabricated statistics (percentage claims without source)
  FAKE_STATS=$(echo "$CONTENT" | grep -oE '[0-9]+%' | wc -l | tr -d ' ')
  if [ "$FAKE_STATS" -gt 0 ]; then
    # Check if there are source citations near the stats
    HAS_SOURCES=$(echo "$CONTENT" | grep -ciE '(source:|citation:|according to|per |survey |report |study )' || echo 0)
    if [ "$HAS_SOURCES" -lt "$FAKE_STATS" ]; then
      echo "  🔴 FABRICATED STATS: Found $FAKE_STATS percentage claims but only $HAS_SOURCES source citations"
      echo "$CONTENT" | grep -oE '.{0,40}[0-9]+%.{0,40}' | head -5 | sed 's/^/     → /'
      ISSUES=$((ISSUES + 1))
    fi
  fi

  # Rule 2: Check for known fabrication patterns
  FABRICATION_PATTERNS=(
    "Economic Survey 202[0-9]"
    "according to.*202[0-9].*survey"
    "NASSCOM.*report.*202[0-9]"
    "[0-9]+ million users"
    "[0-9]+ thousand users"
    "deployed in [0-9]+ states"
    "serving [0-9]+ (users|customers|clients)"
    "proven to (reduce|increase|improve)"
    "guaranteed"
    "testimonial"
  )

  for PATTERN in "${FABRICATION_PATTERNS[@]}"; do
    MATCH=$(echo "$CONTENT" | grep -ciE "$PATTERN" 2>/dev/null || echo "0")
    MATCH=$(echo "$MATCH" | tr -d '[:space:]')
    if [ "${MATCH:-0}" -gt 0 ] 2>/dev/null; then
      echo "  🔴 SUSPICIOUS CLAIM: Pattern '$PATTERN' found"
      echo "$CONTENT" | grep -iE "$PATTERN" | head -2 | sed 's/^/     → /'
      ISSUES=$((ISSUES + 1))
    fi
  done

  # Rule 3: Check for thinking tags (LLM artifacts)
  if echo "$CONTENT" | grep -q '<think>' 2>/dev/null; then
    echo "  🔴 LLM ARTIFACT: <think> tags found in content"
    ISSUES=$((ISSUES + 1))
  fi

  # Rule 4: Check for restricted claims from product truth
  if [ -f "$REGISTRY" ]; then
    # Extract product name from content
    PRODUCT=$(echo "$CONTENT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('product', ''))
except:
    print('')
" 2>/dev/null)

    if [ -n "$PRODUCT" ]; then
      # Check restricted claims for this product
      RESTRICTED=$(jq -r ".products[] | select(.id == \"$(echo "$PRODUCT" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')\") | .restricted_claims[]?" "$REGISTRY" 2>/dev/null)
      while IFS= read -r CLAIM; do
        [ -z "$CLAIM" ] && continue
        # Simple keyword match
        KEYWORDS=$(echo "$CLAIM" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]')
        for WORD in $KEYWORDS; do
          if [ ${#WORD} -gt 4 ] && echo "$CONTENT" | grep -qiw "$WORD" 2>/dev/null; then
            echo "  🟡 RESTRICTED CLAIM WARNING: Content may violate: $CLAIM"
            WARNINGS=$((WARNINGS + 1))
            break
          fi
        done
      done <<< "$RESTRICTED"
    fi
  fi

  # Rule 5: Check file size (oversized = likely raw LLM dump)
  FILE_SIZE=$(wc -c < "$FILE" | tr -d ' ')
  if [ "$FILE_SIZE" -gt 50000 ]; then
    echo "  🔴 OVERSIZED: File is ${FILE_SIZE} bytes (max 50KB for queue items)"
    ISSUES=$((ISSUES + 1))
  fi

  # Rule 6: JSON validation for .json files
  if [[ "$FNAME" == *.json ]]; then
    if ! jq empty "$FILE" 2>/dev/null; then
      echo "  🔴 INVALID JSON: File is not valid JSON"
      ISSUES=$((ISSUES + 1))
    else
      # Check required fields
      for FIELD in content_id product hook summary; do
        VAL=$(jq -r ".$FIELD // empty" "$FILE" 2>/dev/null)
        if [ -z "$VAL" ]; then
          echo "  🟡 MISSING FIELD: $FIELD"
          WARNINGS=$((WARNINGS + 1))
        fi
      done
    fi
  fi

  # Rule 7: Check for empty or near-empty content
  WORD_COUNT=$(echo "$CONTENT" | wc -w | tr -d ' ')
  if [ "$WORD_COUNT" -lt 20 ]; then
    echo "  🔴 TOO SHORT: Only $WORD_COUNT words"
    ISSUES=$((ISSUES + 1))
  fi

  # Summary
  echo ""
  if [ "$ISSUES" -gt 0 ]; then
    echo "  VERDICT: ❌ BLOCKED ($ISSUES issue(s), $WARNINGS warning(s))"
    return 1
  elif [ "$WARNINGS" -gt 0 ]; then
    echo "  VERDICT: 🟡 REVIEW ($WARNINGS warning(s))"
    return 0
  else
    echo "  VERDICT: ✅ PASS"
    return 0
  fi
}

scan_queues() {
  echo "━━━ QUEUE CONTENT VALIDATION ━━━"
  echo ""

  local TOTAL=0
  local PASSED=0
  local BLOCKED=0
  local REVIEW=0

  for PLATFORM_DIR in "$WORKSPACE_ROOT"/OpenClawData/queues/*/; do
    [ ! -d "$PLATFORM_DIR" ] && continue
    PENDING_DIR="${PLATFORM_DIR}pending"
    [ ! -d "$PENDING_DIR" ] && continue

    for F in "$PENDING_DIR"/*; do
      [ ! -f "$F" ] && continue
      [[ "$(basename "$F")" == .* ]] && continue

      TOTAL=$((TOTAL + 1))
      if validate_file "$F" 2>&1; then
        if echo "$_LAST_OUTPUT" | grep -q "REVIEW"; then
          REVIEW=$((REVIEW + 1))
        else
          PASSED=$((PASSED + 1))
        fi
      else
        BLOCKED=$((BLOCKED + 1))
      fi
      echo ""
    done
  done

  echo "━━━ VALIDATION SUMMARY ━━━"
  echo "Total scanned: $TOTAL"
  echo "Passed: $PASSED"
  echo "Review needed: $REVIEW"
  echo "Blocked: $BLOCKED"
}

case "$CMD" in
  --scan-queues) scan_queues ;;
  --scan-dir)
    DIR="${1:-}"
    [ -z "$DIR" ] && { echo "Usage: claim-validator.sh --scan-dir <directory>"; exit 1; }
    for F in "$DIR"/*; do
      [ ! -f "$F" ] && continue
      [[ "$(basename "$F")" == .* ]] && continue
      validate_file "$F"
      echo ""
    done
    ;;
  ""|--help)
    echo "━━━ Content Claim Validator ━━━"
    echo ""
    echo "  <file>            Validate a single file"
    echo "  --scan-queues     Validate all pending queue items"
    echo "  --scan-dir <dir>  Validate all files in directory"
    echo ""
    echo "Checks: fabricated stats, restricted claims, LLM artifacts,"
    echo "        oversized content, invalid JSON, missing fields"
    ;;
  *)
    # Treat as file path
    validate_file "$CMD"
    ;;
esac
