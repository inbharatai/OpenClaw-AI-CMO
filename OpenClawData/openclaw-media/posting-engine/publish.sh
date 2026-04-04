#!/bin/bash
# publish.sh — THE SINGLE CANONICAL PUBLISH PATH for OpenClaw
#
# Every live post MUST go through this script. No exceptions.
#
# Pipeline order:
#   1. Policy enforcement (rate-limits.json: blocked? daily cap?)
#   2. Claim validation (claim-validator.sh)
#   3. Content sanitization (sanitize_post.py)
#   4. QA guardrail (qa-guardrail.sh: length, hashtags, banned phrases)
#   5. Two-stage render (render_post.py: queue file → clean text)
#   6. Post (platform script)
#   7. Record (policy_enforcer.py: increment daily counter)
#
# Usage:
#   ./publish.sh                    Post all approved content
#   ./publish.sh --platform x       Post only X/Twitter content
#   ./publish.sh --dry-run          Show what would be posted (safe)
#   ./publish.sh --status           Check sessions + policy status
#   ./publish.sh --login <platform> Open browser for manual login
#
# Direct posting scripts (post_linkedin.py etc.) are GATED.
# They require --allow-direct-post and still enforce policy.

set -o pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
ENGINE_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
ANALYTICS_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/analytics"
VALIDATOR="$WORKSPACE_ROOT/OpenClawData/security/claim-validator.sh"
SANITIZER="$ENGINE_DIR/sanitize_post.py"
RENDERER="$ENGINE_DIR/render_post.py"
POLICY="$ENGINE_DIR/policy_enforcer.py"
QA_GUARD="$SCRIPTS_DIR/qa-guardrail.sh"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/publishing-engine.log"
DATE=$(date '+%Y-%m-%d')

PLATFORM_FILTER=""
DRY_RUN=false
ACTION="publish"

while [ $# -gt 0 ]; do
  case "$1" in
    --platform) PLATFORM_FILTER="$2"; shift ;;
    --dry-run)  DRY_RUN=true ;;
    --status)   ACTION="status" ;;
    --login)    ACTION="login"; PLATFORM_FILTER="$2"; shift ;;
    --help)     ACTION="help" ;;
  esac
  shift
done

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
  echo "$1"
}

mkdir -p "$(dirname "$LOG_FILE")" "$ANALYTICS_DIR"

# ── Platform → script mapping ──
get_poster() {
  local PLATFORM="$1"
  case "$PLATFORM" in
    linkedin)  echo "python3 $ENGINE_DIR/post_linkedin.py --allow-direct-post" ;;
    x)         echo "python3 $ENGINE_DIR/post_x.py --allow-direct-post" ;;
    discord)   echo "python3 $ENGINE_DIR/post_discord.py --allow-direct-post" ;;
    instagram) echo "python3 $ENGINE_DIR/post_instagram.py --confirm --allow-direct-post" ;;
    email)     echo "python3 $ENGINE_DIR/email_zoho.py --visible" ;;
    *)         echo "" ;;
  esac
}

POSTABLE_PLATFORMS=(linkedin x discord instagram email)

# ── Help ──
if [ "$ACTION" = "help" ]; then
  echo "━━━ OpenClaw Publishing Engine (Canonical Path) ━━━"
  echo ""
  echo "  ./publish.sh                     Post all approved content"
  echo "  ./publish.sh --platform <name>   Post to specific platform"
  echo "  ./publish.sh --dry-run           Preview without posting"
  echo "  ./publish.sh --status            Check sessions + policy status"
  echo "  ./publish.sh --login <platform>  Log in to a platform"
  echo ""
  echo "Pipeline: policy → claim-check → sanitize → QA → render → post → record"
  echo "Supported: ${POSTABLE_PLATFORMS[*]}"
  exit 0
fi

# ── Login ──
if [ "$ACTION" = "login" ]; then
  if [ -z "$PLATFORM_FILTER" ]; then
    echo "Usage: ./publish.sh --login <linkedin|x|discord|instagram>"
    exit 1
  fi
  POSTER=$(get_poster "$PLATFORM_FILTER")
  if [ -z "$POSTER" ]; then
    echo "ERROR: No poster script for platform '$PLATFORM_FILTER'"
    exit 1
  fi
  if [ "$PLATFORM_FILTER" = "discord" ]; then
    python3 "$ENGINE_DIR/post_discord.py" --setup
  else
    # Strip --allow-direct-post for login action
    python3 "$ENGINE_DIR/post_${PLATFORM_FILTER}.py" --login
  fi
  exit $?
fi

# ── Status (sessions + policy) ──
if [ "$ACTION" = "status" ]; then
  echo "━━━ Publishing Engine Status ━━━"
  echo ""

  # Policy status
  echo "── Policy Status ──"
  if [ -f "$POLICY" ]; then
    python3 "$POLICY" --status 2>&1 | sed 's/^/  /'
  else
    echo "  WARNING: policy_enforcer.py not found"
  fi

  echo ""
  echo "── Session Status ──"
  for PLATFORM in "${POSTABLE_PLATFORMS[@]}"; do
    POSTER=$(get_poster "$PLATFORM")
    [ -z "$POSTER" ] && continue
    # Use base script for session check
    STATUS=$(python3 "$ENGINE_DIR/post_${PLATFORM}.py" --check 2>&1 || python3 "$ENGINE_DIR/post_discord.py" --check 2>&1)
    if echo "$STATUS" | grep -q "VALID\|POSTED\|working"; then
      echo "  $PLATFORM: session active"
    elif echo "$STATUS" | grep -q "EXPIRED\|ERROR\|not configured"; then
      echo "  $PLATFORM: needs login"
    else
      echo "  $PLATFORM: unknown"
    fi
  done

  echo ""
  echo "── Queue Status ──"
  for PLATFORM in "${POSTABLE_PLATFORMS[@]}"; do
    COUNT=$(find "$QUEUES_DIR/$PLATFORM/approved" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
    echo "  $PLATFORM: $COUNT approved items"
  done
  exit 0
fi

# ═══════════════════════════════════════════════════
# ── PUBLISH: The canonical path ──
# ═══════════════════════════════════════════════════
log "━━━ Publishing Engine Started ━━━"
[ "$DRY_RUN" = true ] && log "[DRY RUN MODE]"

TOTAL=0
POSTED=0
FAILED=0
SKIPPED=0
POLICY_BLOCKED=0

for PLATFORM in "${POSTABLE_PLATFORMS[@]}"; do
  if [ -n "$PLATFORM_FILTER" ] && [ "$PLATFORM_FILTER" != "$PLATFORM" ]; then
    continue
  fi

  # ════════════════════════════════════════════
  # GATE 0: POLICY ENFORCEMENT (platform-level)
  # ════════════════════════════════════════════
  if [ -f "$POLICY" ]; then
    POLICY_CHECK=$(python3 "$POLICY" --check "$PLATFORM" 2>&1)
    POLICY_EXIT=$?
    if [ $POLICY_EXIT -ne 0 ]; then
      log "POLICY BLOCK: $PLATFORM — $POLICY_CHECK"
      POLICY_BLOCKED=$((POLICY_BLOCKED + 1))
      continue
    fi
    log "POLICY OK: $PLATFORM — $POLICY_CHECK"
  fi

  # ════════════════════════════════════════════
  # GATE 0.5: SESSION HEALTH CHECK
  # ════════════════════════════════════════════
  # Verify platform session is valid BEFORE attempting any posts.
  # Skip platform entirely if session is expired — don't waste time on silent failures.
  if [ "$PLATFORM" != "email" ]; then  # email_zoho has different check mechanism
    SESSION_CHECK=$(python3 "$ENGINE_DIR/post_${PLATFORM}.py" --check 2>&1)
    SESSION_EXIT=$?
    if [ $SESSION_EXIT -ne 0 ] || echo "$SESSION_CHECK" | grep -qi "EXPIRED\|ERROR\|not configured\|not logged"; then
      log "SESSION EXPIRED: $PLATFORM — $SESSION_CHECK"
      log "  Run: python3 $ENGINE_DIR/post_${PLATFORM}.py --login"
      POLICY_BLOCKED=$((POLICY_BLOCKED + 1))
      continue
    fi
  fi

  APPROVED_DIR="$QUEUES_DIR/$PLATFORM/approved"
  POSTED_DIR="$QUEUES_DIR/$PLATFORM/posted"
  REJECTED_DIR="$QUEUES_DIR/$PLATFORM/rejected"
  mkdir -p "$POSTED_DIR" "$REJECTED_DIR"

  [ -d "$APPROVED_DIR" ] || continue

  POSTER=$(get_poster "$PLATFORM")
  if [ -z "$POSTER" ]; then
    log "SKIP: No posting script for $PLATFORM"
    continue
  fi

  for FILE in "$APPROVED_DIR"/*; do
    [ -f "$FILE" ] || continue
    FNAME=$(basename "$FILE")
    [[ "$FNAME" == .* ]] && continue
    [[ "$FNAME" == *.gitkeep ]] && continue

    TOTAL=$((TOTAL + 1))
    log "PROCESSING: $PLATFORM/$FNAME"

    # ════════════════════════════════════════════
    # GATE 1: POLICY ENFORCEMENT (per-post cap check)
    # ════════════════════════════════════════════
    if [ -f "$POLICY" ]; then
      CAP_CHECK=$(python3 "$POLICY" --check "$PLATFORM" 2>&1)
      CAP_EXIT=$?
      if [ $CAP_EXIT -ne 0 ]; then
        log "CAP REACHED: $PLATFORM/$FNAME — $CAP_CHECK"
        SKIPPED=$((SKIPPED + 1))
        continue
      fi
    fi

    # ════════════════════════════════════════════
    # GATE 2: CLAIM VALIDATION
    # ════════════════════════════════════════════
    if [ -x "$VALIDATOR" ]; then
      VALIDATION=$("$VALIDATOR" "$FILE" 2>&1)
      if [ $? -ne 0 ]; then
        log "CLAIM BLOCK: $PLATFORM/$FNAME — $VALIDATION"
        SKIPPED=$((SKIPPED + 1))
        continue
      fi
    fi

    # ════════════════════════════════════════════
    # GATE 3: CONTENT SANITIZATION CHECK
    # ════════════════════════════════════════════
    if [ -f "$SANITIZER" ]; then
      SANITIZE_RESULT=$(python3 "$SANITIZER" --validate-only --file "$FILE" 2>&1)
      SANITIZE_EXIT=$?
      if [ $SANITIZE_EXIT -ne 0 ]; then
        log "SANITIZE WARNING: $PLATFORM/$FNAME — issues will be cleaned during render"
      fi
    fi

    # ════════════════════════════════════════════
    # GATE 4: TWO-STAGE RENDER
    # ════════════════════════════════════════════
    RENDERED_FILE=""
    if [ -f "$RENDERER" ]; then
      RENDERED_FILE=$(mktemp /tmp/openclaw-render-XXXXXX.txt)
      RENDER_OUTPUT=$(python3 "$RENDERER" --file "$FILE" --platform "$PLATFORM" --output "$RENDERED_FILE" 2>&1)
      RENDER_EXIT=$?
      if [ $RENDER_EXIT -ne 0 ] || [ ! -s "$RENDERED_FILE" ]; then
        log "RENDER BLOCK: $PLATFORM/$FNAME — render failed ($RENDER_OUTPUT)"
        rm -f "$RENDERED_FILE"
        SKIPPED=$((SKIPPED + 1))
        continue
      fi
    fi

    # ════════════════════════════════════════════
    # GATE 5: QA GUARDRAIL (length, hashtags, banned phrases)
    # ════════════════════════════════════════════
    QA_INPUT="${RENDERED_FILE:-$FILE}"
    if [ -x "$QA_GUARD" ]; then
      QA_RESULT=$(bash "$QA_GUARD" --file "$QA_INPUT" --platform "$PLATFORM" 2>&1)
      QA_EXIT=$?
      if [ $QA_EXIT -ne 0 ]; then
        log "QA BLOCK: $PLATFORM/$FNAME — $QA_RESULT"
        rm -f "$RENDERED_FILE" 2>/dev/null
        # Move to rejected instead of leaving in approved
        mv "$FILE" "$REJECTED_DIR/" 2>/dev/null
        SKIPPED=$((SKIPPED + 1))
        continue
      fi
    fi

    # ════════════════════════════════════════════
    # DRY RUN — show what would be posted, then skip
    # ════════════════════════════════════════════
    if [ "$DRY_RUN" = true ]; then
      log "[DRY RUN] Would post: $PLATFORM/$FNAME"
      if [ -n "$RENDERED_FILE" ] && [ -f "$RENDERED_FILE" ]; then
        echo "  --- Rendered content ($(wc -c < "$RENDERED_FILE" | tr -d ' ') chars) ---"
        head -20 "$RENDERED_FILE" | sed 's/^/  /'
        rm -f "$RENDERED_FILE"
      fi
      continue
    fi

    # ════════════════════════════════════════════
    # EXECUTE POST
    # ════════════════════════════════════════════
    # Instagram needs original file for image_path. Others use rendered file.
    if [ "$PLATFORM" = "instagram" ]; then
      OUTPUT=$($POSTER --file "$FILE" 2>&1)
      EXIT_CODE=$?
      rm -f "$RENDERED_FILE" 2>/dev/null
    elif [ -n "$RENDERED_FILE" ] && [ -f "$RENDERED_FILE" ]; then
      OUTPUT=$($POSTER --file "$RENDERED_FILE" 2>&1)
      EXIT_CODE=$?
      rm -f "$RENDERED_FILE"
    else
      OUTPUT=$($POSTER --file "$FILE" 2>&1)
      EXIT_CODE=$?
    fi

    # ── Check for hidden failures: exit code 0 but ERROR in output ──
    if [ "$EXIT_CODE" -eq 0 ] && echo "$OUTPUT" | grep -qi "^ERROR:"; then
      log "FALSE POSITIVE CAUGHT: $PLATFORM/$FNAME — exit 0 but ERROR in output"
      log "  Output: $(echo "$OUTPUT" | grep -i "ERROR:" | head -3)"
      EXIT_CODE=1  # Override to failure
    fi

    if [ "$EXIT_CODE" -eq 0 ]; then
      log "POSTED: $PLATFORM/$FNAME"
      log "  Verification: $(echo "$OUTPUT" | grep -i "POSTED:\|verified\|confirmed" | head -1)"
      mv "$FILE" "$POSTED_DIR/"
      POSTED=$((POSTED + 1))

      # ── Record post in policy counter ──
      if [ -f "$POLICY" ]; then
        python3 "$POLICY" --record "$PLATFORM" 2>/dev/null
      fi

      # Archive
      mkdir -p "$WORKSPACE_ROOT/OpenClawData/openclaw-media/publishing/archive"
      cp "$POSTED_DIR/$FNAME" "$WORKSPACE_ROOT/OpenClawData/openclaw-media/publishing/archive/" 2>/dev/null

      # Analytics log
      echo "{\"date\":\"$DATE\",\"time\":\"$(date '+%H:%M:%S')\",\"platform\":\"$PLATFORM\",\"action\":\"posted\",\"file\":\"$FNAME\",\"path\":\"canonical\"}" \
        >> "$ANALYTICS_DIR/post-actions-${DATE}.jsonl"
    else
      log "FAILED: $PLATFORM/$FNAME — $(echo "$OUTPUT" | head -1)"
      FAILED=$((FAILED + 1))

      echo "{\"date\":\"$DATE\",\"time\":\"$(date '+%H:%M:%S')\",\"platform\":\"$PLATFORM\",\"action\":\"failed\",\"file\":\"$FNAME\",\"error\":\"$(echo "$OUTPUT" | head -1)\",\"path\":\"canonical\"}" \
        >> "$ANALYTICS_DIR/post-actions-${DATE}.jsonl"
    fi
  done
done

log "━━━ Publishing Complete ━━━"
log "Total: $TOTAL | Posted: $POSTED | Failed: $FAILED | Skipped: $SKIPPED | Policy-blocked: $POLICY_BLOCKED"

echo ""
echo "━━━ PUBLISHING SUMMARY ━━━"
echo "Total:          $TOTAL"
echo "Posted:         $POSTED"
echo "Failed:         $FAILED"
echo "Skipped (QA):   $SKIPPED"
echo "Policy blocked: $POLICY_BLOCKED"
