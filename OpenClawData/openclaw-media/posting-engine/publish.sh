#!/bin/bash
# publish.sh — Autonomous publishing engine for OpenClaw
#
# Reads approved queue → posts to platforms → marks posted → logs
# Runs independently of Claude. No human-in-the-loop required.
#
# Usage:
#   ./publish.sh                    Post all approved content
#   ./publish.sh --platform x       Post only X/Twitter content
#   ./publish.sh --platform linkedin Post only LinkedIn content
#   ./publish.sh --dry-run          Show what would be posted
#   ./publish.sh --status           Check session status for all platforms
#   ./publish.sh --login <platform> Open browser for manual login
#
# Prerequisites:
#   - Playwright installed: pip3 install playwright
#   - Browser sessions initialized: ./publish.sh --login linkedin
#   - Discord webhook configured: credential-vault.sh store discord-webhook <url>

set -o pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
ENGINE_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine"
ANALYTICS_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/analytics"
VALIDATOR="$WORKSPACE_ROOT/OpenClawData/security/claim-validator.sh"
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
    linkedin)  echo "python3 $ENGINE_DIR/post_linkedin.py" ;;
    x)         echo "python3 $ENGINE_DIR/post_x.py" ;;
    discord)   echo "python3 $ENGINE_DIR/post_discord.py" ;;
    instagram) echo "python3 $ENGINE_DIR/post_instagram.py --confirm" ;;
    # shorts requires video upload — manual for now
    # website/email handled differently
    *)         echo "" ;;
  esac
}

# Platforms with posting scripts
POSTABLE_PLATFORMS=(linkedin x discord instagram)

# ── Help ──
if [ "$ACTION" = "help" ]; then
  echo "━━━ OpenClaw Publishing Engine ━━━"
  echo ""
  echo "  ./publish.sh                     Post all approved content"
  echo "  ./publish.sh --platform <name>   Post to specific platform"
  echo "  ./publish.sh --dry-run           Preview without posting"
  echo "  ./publish.sh --status            Check login sessions"
  echo "  ./publish.sh --login <platform>  Log in to a platform"
  echo ""
  echo "Supported platforms: ${POSTABLE_PLATFORMS[*]}"
  echo ""
  echo "Setup:"
  echo "  1. python3 $ENGINE_DIR/post_linkedin.py --login"
  echo "  2. python3 $ENGINE_DIR/post_x.py --login"
  echo "  3. python3 $ENGINE_DIR/post_discord.py --setup"
  exit 0
fi

# ── Login ──
if [ "$ACTION" = "login" ]; then
  if [ -z "$PLATFORM_FILTER" ]; then
    echo "Usage: ./publish.sh --login <linkedin|x|discord>"
    exit 1
  fi
  POSTER=$(get_poster "$PLATFORM_FILTER")
  if [ -z "$POSTER" ]; then
    echo "ERROR: No poster script for platform '$PLATFORM_FILTER'"
    exit 1
  fi
  if [ "$PLATFORM_FILTER" = "discord" ]; then
    $POSTER --setup
  else
    $POSTER --login
  fi
  exit $?
fi

# ── Status ──
if [ "$ACTION" = "status" ]; then
  echo "━━━ Publishing Engine Status ━━━"
  echo ""
  for PLATFORM in "${POSTABLE_PLATFORMS[@]}"; do
    POSTER=$(get_poster "$PLATFORM")
    if [ -z "$POSTER" ]; then
      echo "  $PLATFORM: no poster script"
      continue
    fi

    STATUS=$($POSTER --check 2>&1)
    if echo "$STATUS" | grep -q "VALID\|POSTED\|working"; then
      echo "  $PLATFORM: 🟢 session active"
    elif echo "$STATUS" | grep -q "EXPIRED\|ERROR\|not configured"; then
      echo "  $PLATFORM: 🔴 needs login"
    else
      echo "  $PLATFORM: 🟡 unknown ($STATUS)"
    fi
  done

  echo ""
  echo "Approved queue:"
  for PLATFORM in "${POSTABLE_PLATFORMS[@]}"; do
    COUNT=$(find "$QUEUES_DIR/$PLATFORM/approved" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
    echo "  $PLATFORM: $COUNT items"
  done
  exit 0
fi

# ── Publish ──
log "━━━ Publishing Engine Started ━━━"
[ "$DRY_RUN" = true ] && log "[DRY RUN MODE]"

TOTAL=0
POSTED=0
FAILED=0
SKIPPED=0

for PLATFORM in "${POSTABLE_PLATFORMS[@]}"; do
  # Filter to specific platform if requested
  if [ -n "$PLATFORM_FILTER" ] && [ "$PLATFORM_FILTER" != "$PLATFORM" ]; then
    continue
  fi

  APPROVED_DIR="$QUEUES_DIR/$PLATFORM/approved"
  POSTED_DIR="$QUEUES_DIR/$PLATFORM/posted"
  mkdir -p "$POSTED_DIR"

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
    log "PUBLISHING: $PLATFORM/$FNAME"

    # Pre-publish claim validation
    if [ -x "$VALIDATOR" ]; then
      VALIDATION=$("$VALIDATOR" "$FILE" 2>&1)
      if [ $? -ne 0 ]; then
        log "BLOCKED: $PLATFORM/$FNAME — failed claim validation"
        log "  $VALIDATION"
        SKIPPED=$((SKIPPED + 1))
        continue
      fi
    fi

    if [ "$DRY_RUN" = true ]; then
      log "[DRY RUN] Would post: $PLATFORM/$FNAME"
      # Show preview
      $POSTER --file "$FILE" --dry-run 2>&1 | sed 's/^/  /'
      continue
    fi

    # Execute posting
    OUTPUT=$($POSTER --file "$FILE" 2>&1)
    EXIT_CODE=$?

    if [ "$EXIT_CODE" -eq 0 ]; then
      log "POSTED: $PLATFORM/$FNAME"
      # Move to posted/
      mv "$FILE" "$POSTED_DIR/"
      POSTED=$((POSTED + 1))

      # Archive a copy
      mkdir -p "$WORKSPACE_ROOT/OpenClawData/openclaw-media/publishing/archive"
      cp "$POSTED_DIR/$FNAME" "$WORKSPACE_ROOT/OpenClawData/openclaw-media/publishing/archive/" 2>/dev/null

      # Log to analytics
      echo "{\"date\":\"$DATE\",\"time\":\"$(date '+%H:%M:%S')\",\"platform\":\"$PLATFORM\",\"action\":\"posted\",\"file\":\"$FNAME\"}" \
        >> "$ANALYTICS_DIR/post-actions-${DATE}.jsonl"

      # Feed to learning loop
      FEEDBACK_COLLECTOR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/analytics/feedback-collector.sh"
      if [ -x "$FEEDBACK_COLLECTOR" ]; then
        "$FEEDBACK_COLLECTOR" record \
          --file "$FNAME" \
          --platform "$PLATFORM" \
          --content-file "$POSTED_DIR/$FNAME" 2>/dev/null || true
      fi
    else
      log "FAILED: $PLATFORM/$FNAME — $OUTPUT"
      FAILED=$((FAILED + 1))

      # Log failure
      echo "{\"date\":\"$DATE\",\"time\":\"$(date '+%H:%M:%S')\",\"platform\":\"$PLATFORM\",\"action\":\"failed\",\"file\":\"$FNAME\",\"error\":\"$(echo "$OUTPUT" | head -1)\"}" \
        >> "$ANALYTICS_DIR/post-actions-${DATE}.jsonl"
    fi
  done
done

log "━━━ Publishing Complete ━━━"
log "Total: $TOTAL | Posted: $POSTED | Failed: $FAILED | Skipped: $SKIPPED"

echo ""
echo "━━━ PUBLISHING SUMMARY ━━━"
echo "Total:   $TOTAL"
echo "Posted:  $POSTED"
echo "Failed:  $FAILED"
echo "Skipped: $SKIPPED"
