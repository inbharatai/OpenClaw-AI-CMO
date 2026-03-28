#!/bin/bash
# InBharat Bot — Approval Gate
# Classifies bot actions into: observe/infer/propose/act/publish
# Only observe/infer/propose are auto-allowed. Act/publish require approval.

set -euo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
APPROVAL_DIR="$BOT_ROOT/approval"
CONFIG="$BOT_ROOT/config/bot-config.json"

source "$BOT_ROOT/logging/bot-logger.sh"

# Action classification
classify_action() {
  local action_type="$1"  # observe, infer, propose, act, publish
  local module="$2"
  local description="$3"

  case "$action_type" in
    observe|infer|propose)
      bot_log "approval" "info" "AUTO-APPROVED: [$action_type] $module — $description"
      echo "approved"
      ;;
    act)
      bot_log "approval" "warn" "REVIEW-REQUIRED: [$action_type] $module — $description"
      # Write to review queue
      local review_file="$APPROVAL_DIR/review-$(date +%Y%m%d-%H%M%S)-${module}.md"
      {
        echo "# Approval Request"
        echo "**Module:** $module"
        echo "**Action Type:** $action_type"
        echo "**Description:** $description"
        echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
        echo "**Status:** PENDING REVIEW"
        echo ""
        echo "To approve: rename this file to approved-*.md"
        echo "To reject: rename this file to rejected-*.md"
      } > "$review_file"
      echo "review_required"
      ;;
    publish)
      bot_log "approval" "warn" "BLOCKED-PENDING-APPROVAL: [$action_type] $module — $description"
      local block_file="$APPROVAL_DIR/blocked-$(date +%Y%m%d-%H%M%S)-${module}.md"
      {
        echo "# Publish Request — Requires Explicit Approval"
        echo "**Module:** $module"
        echo "**Action Type:** $action_type"
        echo "**Description:** $description"
        echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
        echo "**Status:** BLOCKED — requires founder approval"
      } > "$block_file"
      echo "blocked"
      ;;
    *)
      bot_log "approval" "error" "UNKNOWN action type: $action_type"
      echo "blocked"
      ;;
  esac
}

# Check if an action was approved (for act/publish types)
check_approval() {
  local module="$1"
  local approved_count
  approved_count=$(ls "$APPROVAL_DIR"/approved-*-"${module}".md 2>/dev/null | wc -l | tr -d ' ')
  if [ "$approved_count" -gt 0 ]; then
    echo "approved"
  else
    echo "not_approved"
  fi
}

# Export functions for use by other scripts
export -f classify_action 2>/dev/null || true
export -f check_approval 2>/dev/null || true
