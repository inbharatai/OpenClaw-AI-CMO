#!/bin/bash
# post-manager.sh — OpenClaw Publishing Queue Manager
# Manages the posting lifecycle: draft → review → approved → publish-ready → posted
# Usage: ./post-manager.sh [status|review|approve <file>|reject <file>|ready|posted <file>|history]
#
# Browser automation handles actual posting. This manages the queue state.

set -o pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
APPROVALS_DIR="$WORKSPACE_ROOT/OpenClawData/approvals"
MEDIA_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media"
ARCHIVE_DIR="$MEDIA_DIR/publishing/archive"
LOG_DIR="$MEDIA_DIR/analytics"
FEEDBACK_COLLECTOR="$MEDIA_DIR/analytics/feedback-collector.sh"
DATE=$(date '+%Y-%m-%d')

mkdir -p "$ARCHIVE_DIR" "$LOG_DIR" "$APPROVALS_DIR/review" "$APPROVALS_DIR/approved" "$APPROVALS_DIR/blocked"

# All platforms we manage (matches actual queue directories)
PLATFORMS=(instagram shorts linkedin x discord website email)

CMD="${1:-status}"
shift 2>/dev/null || true

show_status() {
  echo "━━━ OPENCLAW PUBLISHING STATUS — $DATE ━━━"
  echo ""

  TOTAL_PENDING=0
  TOTAL_APPROVED=0
  TOTAL_READY=0
  TOTAL_POSTED=0

  for PLATFORM in "${PLATFORMS[@]}"; do
    PENDING=$(find "$QUEUES_DIR/$PLATFORM/pending" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
    APPROVED=$(find "$QUEUES_DIR/$PLATFORM/approved" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
    READY=$(find "$QUEUES_DIR/$PLATFORM/publish-ready" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
    POSTED=$(find "$QUEUES_DIR/$PLATFORM/posted" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')

    TOTAL_PENDING=$((TOTAL_PENDING + PENDING))
    TOTAL_APPROVED=$((TOTAL_APPROVED + APPROVED))
    TOTAL_READY=$((TOTAL_READY + READY))
    TOTAL_POSTED=$((TOTAL_POSTED + POSTED))

    if [ $((PENDING + APPROVED + READY + POSTED)) -gt 0 ]; then
      echo "  $PLATFORM:"
      [ "$PENDING" -gt 0 ] && echo "    pending:  $PENDING"
      [ "$APPROVED" -gt 0 ] && echo "    approved: $APPROVED"
      [ "$READY" -gt 0 ] && echo "    ready:    $READY"
      [ "$POSTED" -gt 0 ] && echo "    posted:   $POSTED"
    fi
  done

  echo ""
  echo "  TOTALS: pending=$TOTAL_PENDING  approved=$TOTAL_APPROVED  ready=$TOTAL_READY  posted=$TOTAL_POSTED"

  # Show review queue
  REVIEW_COUNT=$(find "$APPROVALS_DIR/review" -type f ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
  BLOCKED_COUNT=$(find "$APPROVALS_DIR/blocked" -type f ! -name ".*" -not -name "block-log-*" 2>/dev/null | wc -l | tr -d ' ')
  [ "$REVIEW_COUNT" -gt 0 ] && echo "  In review: $REVIEW_COUNT"
  [ "$BLOCKED_COUNT" -gt 0 ] && echo "  Blocked: $BLOCKED_COUNT"
  echo ""
}

show_review() {
  echo "━━━ ITEMS PENDING REVIEW ━━━"
  echo ""

  for PLATFORM in "${PLATFORMS[@]}"; do
    PENDING_DIR="$QUEUES_DIR/$PLATFORM/pending"
    [ ! -d "$PENDING_DIR" ] && continue

    FILES=$(find "$PENDING_DIR" -type f \( -name "*.md" -o -name "*.json" \) ! -name ".*" 2>/dev/null)
    [ -z "$FILES" ] && continue

    echo "[$PLATFORM]"
    while IFS= read -r F; do
      [ -z "$F" ] && continue
      FNAME=$(basename "$F")
      # Try to extract hook/title from JSON (use env var to avoid injection)
      HOOK=$(REVIEW_FILE="$F" python3 -c "
import json, os
try:
    with open(os.environ['REVIEW_FILE']) as f:
        data = json.load(f)
    print(data.get('hook','')[:80])
except: pass
" 2>/dev/null)
      if [ -n "$HOOK" ]; then
        echo "  $FNAME — $HOOK"
      else
        # For markdown, show first non-empty line
        FIRST_LINE=$(grep -m1 '.' "$F" 2>/dev/null | head -c 80)
        echo "  $FNAME${FIRST_LINE:+ — $FIRST_LINE}"
      fi
    done <<< "$FILES"
    echo ""
  done

  # Show centralized review queue
  REVIEW_DIR="$APPROVALS_DIR/review"
  if [ -d "$REVIEW_DIR" ]; then
    REVIEW_FILES=$(find "$REVIEW_DIR" -type f \( -name "*.md" -o -name "*.json" \) ! -name ".*" 2>/dev/null)
    if [ -n "$REVIEW_FILES" ]; then
      echo "[REVIEW QUEUE]"
      while IFS= read -r F; do
        echo "  $(basename "$F")"
      done <<< "$REVIEW_FILES"
      echo ""
    fi
  fi
}

approve_file() {
  local FILE="$1"
  if [ -z "$FILE" ]; then
    echo "Usage: post-manager.sh approve <filename>"
    echo "       post-manager.sh approve <filename> --no-publish  (approve without auto-publishing)"
    exit 1
  fi

  local NO_PUBLISH=false
  if [ "${2:-}" = "--no-publish" ]; then
    NO_PUBLISH=true
  fi

  local FOUND=0
  local APPROVED_PLATFORMS=()

  # Approve across ALL platform queues (not just first match)
  for PLATFORM in "${PLATFORMS[@]}"; do
    PENDING_PATH="$QUEUES_DIR/$PLATFORM/pending/$FILE"
    if [ -f "$PENDING_PATH" ]; then
      APPROVED_DIR="$QUEUES_DIR/$PLATFORM/approved"
      mkdir -p "$APPROVED_DIR"
      mv "$PENDING_PATH" "$APPROVED_DIR/"
      echo "  ✅ $PLATFORM/approved/"
      FOUND=$((FOUND + 1))
      APPROVED_PLATFORMS+=("$PLATFORM")

      # Log
      jq -cn --arg date "$DATE" --arg time "$(date '+%H:%M:%S')" \
        --arg file "$FILE" --arg platform "$PLATFORM" --arg action "approved" \
        '{date: $date, time: $time, file: $file, platform: $platform, action: $action}' \
        >> "$LOG_DIR/post-actions-${DATE}.jsonl" 2>/dev/null
    fi
  done

  # Check centralized review queue
  REVIEW_PATH="$APPROVALS_DIR/review/$FILE"
  if [ -f "$REVIEW_PATH" ]; then
    mkdir -p "$APPROVALS_DIR/approved"
    mv "$REVIEW_PATH" "$APPROVALS_DIR/approved/"
    echo "  ✅ Approved from review queue"
    FOUND=$((FOUND + 1))
  fi

  if [ "$FOUND" -gt 0 ]; then
    echo "Approved '$FILE' across $FOUND location(s)"

    # ── AUTO-PUBLISH: validate then publish immediately ──
    if [ "$NO_PUBLISH" = true ]; then
      echo "  ⏸  Auto-publish skipped (--no-publish flag)"
      return 0
    fi

    echo ""
    echo "━━━ AUTO-PUBLISH: Validate → Publish ━━━"

    local PUBLISH_SCRIPT="$WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine/publish.sh"
    local VALIDATOR="$WORKSPACE_ROOT/OpenClawData/security/claim-validator.sh"
    local PUBLISH_OK=0
    local PUBLISH_BLOCKED=0
    local PUBLISH_SKIPPED=0

    for PLATFORM in "${APPROVED_PLATFORMS[@]}"; do
      local APPROVED_FILE="$QUEUES_DIR/$PLATFORM/approved/$FILE"
      [ ! -f "$APPROVED_FILE" ] && continue

      # Step 1: Claim validation
      if [ -x "$VALIDATOR" ]; then
        local VALIDATION
        VALIDATION=$("$VALIDATOR" "$APPROVED_FILE" 2>&1)
        local VAL_EXIT=$?
        if [ "$VAL_EXIT" -ne 0 ]; then
          echo "  ❌ $PLATFORM: BLOCKED by claim validator"
          echo "     $VALIDATION" | head -3 | sed 's/^/     /'
          # Move back to blocked
          mkdir -p "$APPROVALS_DIR/blocked"
          mv "$APPROVED_FILE" "$APPROVALS_DIR/blocked/"
          PUBLISH_BLOCKED=$((PUBLISH_BLOCKED + 1))

          jq -cn --arg date "$DATE" --arg time "$(date '+%H:%M:%S')" \
            --arg file "$FILE" --arg platform "$PLATFORM" --arg action "blocked-post-validation" \
            '{date: $date, time: $time, file: $file, platform: $platform, action: $action}' \
            >> "$LOG_DIR/post-actions-${DATE}.jsonl" 2>/dev/null
          continue
        fi
        echo "  ✓ $PLATFORM: Claim validation passed"
      fi

      # Step 2: Check if platform has a posting script
      local POSTER
      case "$PLATFORM" in
        linkedin)  POSTER="python3 $WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine/post_linkedin.py" ;;
        x)         POSTER="python3 $WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine/post_x.py" ;;
        discord)   POSTER="python3 $WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine/post_discord.py" ;;
        instagram) POSTER="python3 $WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine/post_instagram.py --confirm" ;;
        *)         POSTER="" ;;
      esac

      if [ -z "$POSTER" ]; then
        echo "  ⏭  $PLATFORM: No posting script — staying in approved/"
        PUBLISH_SKIPPED=$((PUBLISH_SKIPPED + 1))
        continue
      fi

      # Step 3: Check platform session is active (skip if not logged in)
      local SESSION_CHECK
      case "$PLATFORM" in
        discord)
          # Discord uses webhook, always available
          SESSION_CHECK="ok"
          ;;
        *)
          SESSION_CHECK=$($POSTER --check 2>&1 || true)
          if echo "$SESSION_CHECK" | grep -qi "error\|not configured\|expired\|no.*session\|not found"; then
            echo "  ⏭  $PLATFORM: No active session — staying in approved/ (run: publish.sh --login $PLATFORM)"
            PUBLISH_SKIPPED=$((PUBLISH_SKIPPED + 1))
            continue
          fi
          ;;
      esac

      # Step 4: Publish
      echo "  → $PLATFORM: Publishing..."
      local POST_OUTPUT
      POST_OUTPUT=$($POSTER --file "$APPROVED_FILE" 2>&1)
      local POST_EXIT=$?

      if [ "$POST_EXIT" -eq 0 ]; then
        echo "  ✅ $PLATFORM: POSTED successfully"
        PUBLISH_OK=$((PUBLISH_OK + 1))

        # Move to posted/
        local POSTED_DIR="$QUEUES_DIR/$PLATFORM/posted"
        mkdir -p "$POSTED_DIR"
        mv "$APPROVED_FILE" "$POSTED_DIR/"

        # Archive
        mkdir -p "$MEDIA_DIR/publishing/archive"
        cp "$POSTED_DIR/$FILE" "$MEDIA_DIR/publishing/archive/" 2>/dev/null

        # Log
        jq -cn --arg date "$DATE" --arg time "$(date '+%H:%M:%S')" \
          --arg file "$FILE" --arg platform "$PLATFORM" --arg action "auto-posted" \
          '{date: $date, time: $time, file: $file, platform: $platform, action: $action}' \
          >> "$LOG_DIR/post-actions-${DATE}.jsonl" 2>/dev/null

        # Feedback loop
        if [ -x "$FEEDBACK_COLLECTOR" ]; then
          "$FEEDBACK_COLLECTOR" record \
            --file "$FILE" \
            --platform "$PLATFORM" \
            --content-file "$POSTED_DIR/$FILE" 2>/dev/null || true
        fi
      else
        echo "  ⚠️  $PLATFORM: Post FAILED — staying in approved/"
        echo "     $(echo "$POST_OUTPUT" | head -1)"
        PUBLISH_SKIPPED=$((PUBLISH_SKIPPED + 1))

        jq -cn --arg date "$DATE" --arg time "$(date '+%H:%M:%S')" \
          --arg file "$FILE" --arg platform "$PLATFORM" --arg action "auto-post-failed" \
          --arg error "$(echo "$POST_OUTPUT" | head -1)" \
          '{date: $date, time: $time, file: $file, platform: $platform, action: $action, error: $error}' \
          >> "$LOG_DIR/post-actions-${DATE}.jsonl" 2>/dev/null
      fi
    done

    echo ""
    echo "Auto-publish: $PUBLISH_OK posted, $PUBLISH_BLOCKED blocked, $PUBLISH_SKIPPED skipped"
  else
    echo "❌ File not found in any pending queue: $FILE"
    return 1
  fi
}

reject_file() {
  local FILE="$1"
  if [ -z "$FILE" ]; then
    echo "Usage: post-manager.sh reject <filename>"
    exit 1
  fi

  local FOUND=0

  # Reject across ALL platform queues
  for PLATFORM in "${PLATFORMS[@]}"; do
    PENDING_PATH="$QUEUES_DIR/$PLATFORM/pending/$FILE"
    if [ -f "$PENDING_PATH" ]; then
      mkdir -p "$APPROVALS_DIR/blocked"
      mv "$PENDING_PATH" "$APPROVALS_DIR/blocked/"
      echo "  ❌ Rejected from $PLATFORM"
      FOUND=$((FOUND + 1))

      jq -cn --arg date "$DATE" --arg time "$(date '+%H:%M:%S')" \
        --arg file "$FILE" --arg platform "$PLATFORM" --arg action "rejected" \
        '{date: $date, time: $time, file: $file, platform: $platform, action: $action}' \
        >> "$LOG_DIR/post-actions-${DATE}.jsonl" 2>/dev/null
    fi
  done

  if [ "$FOUND" -gt 0 ]; then
    echo "Rejected '$FILE' from $FOUND queue(s)"
  else
    echo "File not found in any pending queue: $FILE"
    return 1
  fi
}

mark_ready() {
  echo "━━━ MARKING APPROVED → PUBLISH-READY ━━━"
  MOVED=0

  for PLATFORM in "${PLATFORMS[@]}"; do
    APPROVED_DIR="$QUEUES_DIR/$PLATFORM/approved"
    READY_DIR="$QUEUES_DIR/$PLATFORM/publish-ready"
    [ ! -d "$APPROVED_DIR" ] && continue
    mkdir -p "$READY_DIR"

    for F in "$APPROVED_DIR"/*; do
      [ ! -f "$F" ] && continue
      [[ "$(basename "$F")" == .* ]] && continue
      mv "$F" "$READY_DIR/"
      echo "  → $PLATFORM: $(basename "$F") → publish-ready"
      MOVED=$((MOVED + 1))
    done
  done

  echo ""
  echo "Moved $MOVED items to publish-ready"
  [ "$MOVED" -gt 0 ] && echo "Next: Use browser automation to post, then run: post-manager.sh posted <filename>"
}

mark_posted() {
  local FILE="$1"
  if [ -z "$FILE" ]; then
    echo "Usage: post-manager.sh posted <filename>"
    exit 1
  fi

  local FOUND=0

  for PLATFORM in "${PLATFORMS[@]}"; do
    READY_PATH="$QUEUES_DIR/$PLATFORM/publish-ready/$FILE"
    if [ -f "$READY_PATH" ]; then
      POSTED_DIR="$QUEUES_DIR/$PLATFORM/posted"
      mkdir -p "$POSTED_DIR"
      mv "$READY_PATH" "$POSTED_DIR/"

      # Archive
      cp "$POSTED_DIR/$FILE" "$ARCHIVE_DIR/" 2>/dev/null

      echo "  ✅ Posted: $FILE ($PLATFORM)"
      FOUND=$((FOUND + 1))

      # Log posting event
      jq -cn --arg date "$DATE" --arg time "$(date '+%H:%M:%S')" --arg file "$FILE" \
        --arg platform "$PLATFORM" --arg action "posted" \
        '{date: $date, time: $time, file: $file, platform: $platform, action: $action}' \
        >> "$LOG_DIR/post-actions-${DATE}.jsonl" 2>/dev/null

      # Feed structured posting data to InBharat Bot's learning loop
      if [ -x "$FEEDBACK_COLLECTOR" ]; then
        "$FEEDBACK_COLLECTOR" record \
          --file "$FILE" \
          --platform "$PLATFORM" \
          --content-file "$POSTED_DIR/$FILE" 2>/dev/null || true
      else
        # Fallback: write minimal feedback directly if collector not available
        local FB_DIR="$MEDIA_DIR/analytics/feedback-to-bot"
        mkdir -p "$FB_DIR"
        jq -cn --arg date "$DATE" --arg platform "$PLATFORM" --arg file "$FILE" \
          '{date: $date, platform: $platform, file: $file, posted: true, engagement_status: "pending"}' \
          >> "$FB_DIR/posted-${DATE}.jsonl" 2>/dev/null
      fi
    fi
  done

  if [ "$FOUND" -eq 0 ]; then
    echo "File not found in any publish-ready queue: $FILE"
    return 1
  fi
}

show_history() {
  echo "━━━ POSTING HISTORY ━━━"
  echo ""

  if [ -f "$LOG_DIR/post-actions-${DATE}.jsonl" ]; then
    echo "Today ($DATE):"
    jq -r '"  \(.time // .date) | \(.platform) | \(.action) | \(.file)"' "$LOG_DIR/post-actions-${DATE}.jsonl" 2>/dev/null
  else
    echo "No activity today."
  fi

  echo ""

  # Show recent archives
  ARCHIVE_COUNT=$(find "$ARCHIVE_DIR" -type f ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
  echo "Total archived posts: $ARCHIVE_COUNT"

  for PLATFORM in "${PLATFORMS[@]}"; do
    POSTED_COUNT=$(find "$QUEUES_DIR/$PLATFORM/posted" -type f ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
    [ "$POSTED_COUNT" -gt 0 ] && echo "  $PLATFORM: $POSTED_COUNT posted"
  done
  return 0
}

# ── Clean queue items: strip LLM thinking tags ──
clean_queue_item() {
  local FILE="$1"
  if [ -f "$FILE" ]; then
    # Remove <think>...</think> blocks and bare tags
    if grep -q '<think>' "$FILE" 2>/dev/null; then
      python3 -c "
import re, sys, os
with open(os.environ['CLEAN_FILE'], 'r') as f:
    content = f.read()
cleaned = re.sub(r'<think>.*?</think>', '', content, flags=re.DOTALL)
cleaned = re.sub(r'</?think>', '', cleaned)
with open(os.environ['CLEAN_FILE'], 'w') as f:
    f.write(cleaned.strip() + '\n')
" 2>/dev/null
      return $?
    fi
  fi
}

case "$CMD" in
  status)    show_status ;;
  review)    show_review ;;
  approve)   approve_file "${1:-}" "${2:-}" ;;
  reject)    reject_file "${1:-}" ;;
  ready)     mark_ready ;;
  posted)    mark_posted "${1:-}" ;;
  history)   show_history ;;
  clean)
    # Clean all pending queue items of thinking tags
    echo "Cleaning queue items..."
    CLEANED=0
    for PLATFORM in "${PLATFORMS[@]}"; do
      for F in "$QUEUES_DIR/$PLATFORM/pending"/*; do
        [ ! -f "$F" ] && continue
        [[ "$(basename "$F")" == .* ]] && continue
        export CLEAN_FILE="$F"
        if clean_queue_item "$F"; then
          CLEANED=$((CLEANED + 1))
        fi
      done
    done
    echo "Cleaned $CLEANED items"
    ;;
  *)
    echo "━━━ OpenClaw Post Manager ━━━"
    echo ""
    echo "Usage: post-manager.sh <command>"
    echo ""
    echo "  status              Show publishing queue status"
    echo "  review              Show items pending review"
    echo "  approve <file>                 Approve → validate → auto-publish"
    echo "  approve <file> --no-publish   Approve without auto-publishing"
    echo "  reject <file>                 Reject across ALL platform queues"
    echo "  ready                         Move all approved → publish-ready (manual flow)"
    echo "  posted <file>                 Mark item as posted (manual flow)"
    echo "  history                       Show posting history"
    echo "  clean                         Strip LLM thinking tags from queue items"
    echo ""
    echo "Workflow: pending → approve → [auto-validate → auto-publish] → posted"
    echo "  Auto-publish runs claim validation, checks platform sessions,"
    echo "  posts to all platforms with active sessions, archives + logs."
    echo "  Use --no-publish to approve without publishing."
    ;;
esac
