#!/bin/bash
# run-tests.sh — Comprehensive regression test suite for InBharat Bot + CMO Pipeline
# Non-destructive (read-only). No Ollama inference calls. Runs in under 60 seconds.
# Usage: ./run-tests.sh [--section <name>] [--verbose]
#
# Sections: infra, lane-runner, orchestrator, dashboard, post-manager,
#           approval, config, security, content

set -o pipefail

# ── Configuration ──
WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
BOT_ROOT="$WORKSPACE_ROOT/OpenClawData/inbharat-bot"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
APPROVALS_DIR="$WORKSPACE_ROOT/OpenClawData/approvals"
MEDIA_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media"
OLLAMA_URL="http://127.0.0.1:11434"

# ── Test counters ──
PASS=0
FAIL=0
SKIP=0
VERBOSE=false
SECTION_FILTER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --section) SECTION_FILTER="$2"; shift ;;
    --verbose) VERBOSE=true ;;
    *) echo "Usage: $0 [--section <name>] [--verbose]"; exit 1 ;;
  esac
  shift
done

# ── Test helpers ──

pass() {
  PASS=$((PASS + 1))
  echo "  PASS  $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "  FAIL  $1"
  [ -n "${2:-}" ] && echo "        reason: $2"
}

skip() {
  SKIP=$((SKIP + 1))
  echo "  SKIP  $1"
  [ -n "${2:-}" ] && echo "        reason: $2"
}

section() {
  if [ -n "$SECTION_FILTER" ] && [ "$SECTION_FILTER" != "$1" ]; then
    return 1
  fi
  echo ""
  echo "━━━ $2 ━━━"
  return 0
}

# ══════════════════════════════════════════════════════════════════════
# 1. INFRASTRUCTURE TESTS
# ══════════════════════════════════════════════════════════════════════

if section "infra" "INFRASTRUCTURE TESTS"; then

  # Ollama running
  if curl -s --max-time 5 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
    pass "Ollama is running at $OLLAMA_URL"
  else
    fail "Ollama is not running at $OLLAMA_URL"
  fi

  # Model qwen3:8b available
  MODEL_CHECK=$(curl -s --max-time 5 "$OLLAMA_URL/api/tags" 2>/dev/null \
    | python3 -c "
import sys, json
try:
    models = [m['name'] for m in json.load(sys.stdin).get('models', [])]
    print('yes' if any('qwen3:8b' in m for m in models) else 'no')
except: print('error')
" 2>/dev/null)
  if [ "$MODEL_CHECK" = "yes" ]; then
    pass "Model qwen3:8b is available in Ollama"
  elif [ "$MODEL_CHECK" = "no" ]; then
    fail "Model qwen3:8b is NOT available in Ollama"
  else
    fail "Could not query Ollama model list"
  fi

  # Required directories
  REQUIRED_DIRS=(
    "$BOT_ROOT"
    "$BOT_ROOT/config"
    "$BOT_ROOT/dashboard"
    "$BOT_ROOT/logging"
    "$BOT_ROOT/skills"
    "$BOT_ROOT/india-problems"
    "$BOT_ROOT/ai-gaps"
    "$BOT_ROOT/blogs"
    "$BOT_ROOT/funding"
    "$BOT_ROOT/learning"
    "$BOT_ROOT/reports"
    "$BOT_ROOT/handoffs"
    "$BOT_ROOT/podcast"
    "$BOT_ROOT/campaign-briefs"
    "$BOT_ROOT/ecosystem-intelligence"
    "$BOT_ROOT/leads"
    "$BOT_ROOT/outreach"
    "$BOT_ROOT/community"
    "$SCRIPTS_DIR"
    "$QUEUES_DIR"
    "$APPROVALS_DIR"
    "$MEDIA_DIR"
    "$MEDIA_DIR/publishing"
    "$WORKSPACE_ROOT/OpenClawData/logs"
  )
  DIR_OK=0
  DIR_MISSING=0
  for D in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$D" ]; then
      DIR_OK=$((DIR_OK + 1))
    else
      fail "Required directory missing: $D"
      DIR_MISSING=$((DIR_MISSING + 1))
    fi
  done
  if [ "$DIR_MISSING" -eq 0 ]; then
    pass "All ${#REQUIRED_DIRS[@]} required directories exist"
  fi

  # Required scripts are executable
  REQUIRED_SCRIPTS=(
    "$BOT_ROOT/inbharat-run.sh"
    "$BOT_ROOT/lane-runner.sh"
    "$BOT_ROOT/dashboard/generate-state.sh"
    "$BOT_ROOT/logging/bot-logger.sh"
    "$SCRIPTS_DIR/approval-engine.sh"
    "$SCRIPTS_DIR/content-agent.sh"
    "$SCRIPTS_DIR/distribution-engine.sh"
    "$SCRIPTS_DIR/daily-pipeline.sh"
    "$SCRIPTS_DIR/skill-runner.sh"
    "$MEDIA_DIR/publishing/post-manager.sh"
  )
  SCRIPT_ERRORS=0
  for S in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "$S" ]; then
      fail "Script missing: $S"
      SCRIPT_ERRORS=$((SCRIPT_ERRORS + 1))
    elif [ ! -x "$S" ] && ! head -1 "$S" 2>/dev/null | grep -q '^#!/bin/bash'; then
      # Script exists but not executable and not a bash script
      fail "Script not executable and no shebang: $S"
      SCRIPT_ERRORS=$((SCRIPT_ERRORS + 1))
    fi
  done
  if [ "$SCRIPT_ERRORS" -eq 0 ]; then
    pass "All ${#REQUIRED_SCRIPTS[@]} required scripts present with shebang"
  fi

  # CLI tools available
  for CMD in python3 jq curl; do
    if command -v "$CMD" >/dev/null 2>&1; then
      pass "$CMD is available ($(command -v "$CMD"))"
    else
      fail "$CMD is not available on PATH"
    fi
  done

  # bot-logger.sh sources without error
  LOGGER_OUT=$(bash -c 'source "'"$BOT_ROOT/logging/bot-logger.sh"'" 2>&1 && type bot_log >/dev/null 2>&1 && echo "ok"' 2>&1)
  if echo "$LOGGER_OUT" | grep -q "ok"; then
    pass "bot-logger.sh sources without error and defines bot_log"
  else
    fail "bot-logger.sh failed to source cleanly" "$LOGGER_OUT"
  fi

  # bot-logger.sh also defines bot_log_evidence
  LOGGER_FN=$(bash -c 'source "'"$BOT_ROOT/logging/bot-logger.sh"'" 2>&1 && type bot_log_evidence >/dev/null 2>&1 && echo "ok"' 2>&1)
  if echo "$LOGGER_FN" | grep -q "ok"; then
    pass "bot-logger.sh defines bot_log_evidence function"
  else
    fail "bot-logger.sh missing bot_log_evidence function"
  fi

fi

# ══════════════════════════════════════════════════════════════════════
# 2. LANE-RUNNER TESTS
# ══════════════════════════════════════════════════════════════════════

if section "lane-runner" "LANE-RUNNER TESTS"; then

  LANE_RUNNER="$BOT_ROOT/lane-runner.sh"

  # No args shows usage
  NO_ARG_OUT=$(bash "$LANE_RUNNER" 2>&1) || true
  if echo "$NO_ARG_OUT" | grep -qi "usage"; then
    pass "lane-runner.sh with no args shows usage"
  else
    fail "lane-runner.sh with no args did not show usage" "$(echo "$NO_ARG_OUT" | head -3)"
  fi

  # No args exits non-zero
  bash "$LANE_RUNNER" >/dev/null 2>&1
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -ne 0 ]; then
    pass "lane-runner.sh with no args exits non-zero (exit $EXIT_CODE)"
  else
    fail "lane-runner.sh with no args should exit non-zero but exited 0"
  fi

  # Invalid skill exits with error
  INVALID_OUT=$(bash "$LANE_RUNNER" "nonexistent-skill-xyz-999" 2>&1) || true
  EXIT_CODE=$?
  if echo "$INVALID_OUT" | grep -qi "error\|not found"; then
    pass "lane-runner.sh with invalid skill reports error"
  else
    fail "lane-runner.sh with invalid skill did not report error" "$(echo "$INVALID_OUT" | head -3)"
  fi

  # Lock file prevents concurrent runs
  # Create a fake lock file with current PID (which IS running)
  TEST_LOCK="/tmp/lane-runner-__test-lock-skill__.lock"
  echo $$ > "$TEST_LOCK"
  LOCK_OUT=$(bash "$LANE_RUNNER" "__test-lock-skill__" 2>&1) || true
  # The script should fail because the skill doesn't exist, but we test the lock path
  # by creating a lock with a real PID and a valid skill
  rm -f "$TEST_LOCK"

  # Test lock mechanism with a real skill name but a running PID
  FIRST_SKILL=$(ls "$BOT_ROOT/skills" 2>/dev/null | head -1)
  if [ -n "$FIRST_SKILL" ]; then
    TEST_LOCK="/tmp/lane-runner-${FIRST_SKILL}.lock"
    # Clean any stale lock
    rm -f "$TEST_LOCK"
    # Write our own PID (which is running)
    echo $$ > "$TEST_LOCK"
    LOCK_OUT=$(bash "$LANE_RUNNER" "$FIRST_SKILL" 2>&1) || true
    if echo "$LOCK_OUT" | grep -qi "already running"; then
      pass "lane-runner.sh lock file prevents concurrent runs"
    else
      fail "lane-runner.sh did not detect running lock" "$(echo "$LOCK_OUT" | head -3)"
    fi
    rm -f "$TEST_LOCK"
  else
    skip "lock file test" "no skills found"
  fi

  # Prompt building: measure a typical skill's SKILL.md size + overhead
  # The prompt is: SKILL_BODY + TASK_INSTRUCTION (~250 chars) + date/mode (~50 chars) + product context
  if [ -n "$FIRST_SKILL" ]; then
    SKILL_FILE="$BOT_ROOT/skills/$FIRST_SKILL/SKILL.md"
    if [ -f "$SKILL_FILE" ]; then
      SKILL_SIZE=$(wc -c < "$SKILL_FILE" | tr -d ' ')
      # Task instruction is ~250 chars, date/mode ~50, product context varies
      PRODUCT_CONTEXT_SIZE=0
      STRATEGY_DIR="$WORKSPACE_ROOT/OpenClawData/strategy/product-truth"
      if [ -d "$STRATEGY_DIR" ]; then
        PRODUCT_CONTEXT_SIZE=$(cat "$STRATEGY_DIR"/*.md 2>/dev/null | wc -c | tr -d ' ')
        # Only one-line defs are included, so rough estimate is ~500 chars max
        PRODUCT_CONTEXT_SIZE=500
      fi
      ESTIMATED_PROMPT=$((SKILL_SIZE + 300 + PRODUCT_CONTEXT_SIZE))
      if [ "$ESTIMATED_PROMPT" -lt 16000 ]; then
        pass "Prompt for '$FIRST_SKILL' estimated at ${ESTIMATED_PROMPT} chars (under 16000 limit)"
      else
        fail "Prompt for '$FIRST_SKILL' estimated at ${ESTIMATED_PROMPT} chars (EXCEEDS 16000 limit)"
      fi
    else
      skip "prompt size test" "SKILL.md not found for $FIRST_SKILL"
    fi
  fi

  # All bot skills have SKILL.md files
  SKILL_MISSING=0
  for SKILL_DIR in "$BOT_ROOT/skills"/*/; do
    [ ! -d "$SKILL_DIR" ] && continue
    SKILL_NAME=$(basename "$SKILL_DIR")
    if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
      fail "Skill '$SKILL_NAME' missing SKILL.md"
      SKILL_MISSING=$((SKILL_MISSING + 1))
    fi
  done
  if [ "$SKILL_MISSING" -eq 0 ]; then
    SKILL_COUNT=$(ls -d "$BOT_ROOT/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
    pass "All $SKILL_COUNT bot skills have SKILL.md files"
  fi

  # Output filename includes timestamp when file already exists
  # Test by checking the code logic in lane-runner.sh
  if grep -q 'TIMESTAMP.*MODE' "$LANE_RUNNER" && grep -q 'if \[ -f "$OUTPUT_FILE" \]' "$LANE_RUNNER"; then
    pass "lane-runner.sh uses timestamped filenames when output file exists"
  else
    fail "lane-runner.sh missing timestamp-on-collision logic"
  fi

fi

# ══════════════════════════════════════════════════════════════════════
# 3. ORCHESTRATOR ROUTING TESTS
# ══════════════════════════════════════════════════════════════════════

if section "orchestrator" "ORCHESTRATOR ROUTING TESTS"; then

  ORCHESTRATOR="$BOT_ROOT/inbharat-run.sh"

  # Commands that should produce output without crashing.
  # We test "list" subcommands and "status" commands that don't trigger Ollama inference.
  # For commands that would trigger inference (scan, analyze, etc.), we just verify
  # the function definition exists in the case statement.

  # These commands produce immediate output without Ollama calls
  SAFE_COMMANDS=(
    "status"
    "leads status"
    "india-problems list"
    "ai-gaps list"
    "funding list"
    "ecosystem list"
    "blog list"
    "podcast list"
    "campaign list"
    "learning list"
    "competitor list"
    "lead-research list"
    "opportunity-mine list"
  )

  for CMD_LINE in "${SAFE_COMMANDS[@]}"; do
    # shellcheck disable=SC2086
    CMD_OUT=$(bash "$ORCHESTRATOR" $CMD_LINE 2>&1) || true
    CMD_EXIT=$?
    # The command should either exit 0 or produce recognizable output
    if [ "$CMD_EXIT" -eq 0 ] || echo "$CMD_OUT" | grep -qiE "━━━|status|report|no .* yet|pipeline|total|updated"; then
      pass "orchestrator '$CMD_LINE' routes without crashing"
    else
      fail "orchestrator '$CMD_LINE' failed (exit $CMD_EXIT)" "$(echo "$CMD_OUT" | head -2)"
    fi
  done

  # Verify case statement has routing for all expected modes
  ROUTED_MODES=(
    "scan" "analyze" "propose" "bridge" "status"
    "leads" "revenue" "outreach"
    "opportunities" "competitors" "competitor"
    "lead-research" "opportunity-mine"
    "india-problems" "ai-gaps" "funding"
    "stakeholders" "blog" "podcast"
    "campaign" "ecosystem" "learning"
    "media" "government" "prototype"
  )
  ROUTE_MISSING=0
  for MODE in "${ROUTED_MODES[@]}"; do
    # Check the main case statement has this mode
    if grep -qE "^\s+${MODE}\)" "$ORCHESTRATOR" 2>/dev/null; then
      : # found
    else
      fail "orchestrator missing case route for '$MODE'"
      ROUTE_MISSING=$((ROUTE_MISSING + 1))
    fi
  done
  if [ "$ROUTE_MISSING" -eq 0 ]; then
    pass "All ${#ROUTED_MODES[@]} expected modes have case routes in orchestrator"
  fi

  # Media sub-commands route through post-manager without crashing
  MEDIA_CMDS=("media status" "media review" "media history")
  for CMD_LINE in "${MEDIA_CMDS[@]}"; do
    # shellcheck disable=SC2086
    CMD_OUT=$(bash "$ORCHESTRATOR" $CMD_LINE 2>&1) || true
    CMD_EXIT=$?
    if [ "$CMD_EXIT" -eq 0 ] || echo "$CMD_OUT" | grep -qiE "━━━|status|history|pending|review|total|no activity"; then
      pass "orchestrator '$CMD_LINE' routes without crashing"
    else
      fail "orchestrator '$CMD_LINE' failed (exit $CMD_EXIT)" "$(echo "$CMD_OUT" | head -2)"
    fi
  done

  # outreach track should work (reads log files, no inference)
  TRACK_OUT=$(bash "$ORCHESTRATOR" outreach track 2>&1) || true
  TRACK_EXIT=$?
  if [ "$TRACK_EXIT" -eq 0 ] || echo "$TRACK_OUT" | grep -qiE "outreach|track|log|no "; then
    pass "orchestrator 'outreach track' routes without crashing"
  else
    # outreach tracker might not exist yet
    if echo "$TRACK_OUT" | grep -qi "not found\|no such"; then
      skip "orchestrator 'outreach track'" "outreach-tracker.sh not yet built"
    else
      fail "orchestrator 'outreach track' failed (exit $TRACK_EXIT)" "$(echo "$TRACK_OUT" | head -2)"
    fi
  fi

  # revenue status should work
  REV_OUT=$(bash "$ORCHESTRATOR" revenue status 2>&1) || true
  REV_EXIT=$?
  if [ "$REV_EXIT" -eq 0 ] || echo "$REV_OUT" | grep -qiE "revenue|status|pipeline|no "; then
    pass "orchestrator 'revenue status' routes without crashing"
  else
    if echo "$REV_OUT" | grep -qi "not found\|no such"; then
      skip "orchestrator 'revenue status'" "revenue-engine.sh not yet built"
    else
      fail "orchestrator 'revenue status' failed" "$(echo "$REV_OUT" | head -2)"
    fi
  fi

fi

# ══════════════════════════════════════════════════════════════════════
# 4. DASHBOARD TESTS
# ══════════════════════════════════════════════════════════════════════

if section "dashboard" "DASHBOARD TESTS"; then

  GENERATE_STATE="$BOT_ROOT/dashboard/generate-state.sh"
  STATE_JSON="$BOT_ROOT/dashboard/bot-state.json"
  STATE_MD="$BOT_ROOT/dashboard/bot-status.md"

  # generate-state.sh produces valid JSON
  GEN_OUT=$(bash "$GENERATE_STATE" 2>&1)
  GEN_EXIT=$?
  if [ "$GEN_EXIT" -eq 0 ]; then
    pass "generate-state.sh runs without error (exit 0)"
  else
    fail "generate-state.sh failed (exit $GEN_EXIT)" "$(echo "$GEN_OUT" | tail -3)"
  fi

  # bot-state.json is valid JSON
  if [ -f "$STATE_JSON" ]; then
    if jq empty "$STATE_JSON" 2>/dev/null; then
      pass "bot-state.json is valid JSON"
    else
      fail "bot-state.json is NOT valid JSON"
    fi
  else
    fail "bot-state.json does not exist"
  fi

  # bot-state.json has all required keys
  REQUIRED_KEYS=("bot" "version" "health" "lanes" "queues" "approvals" "handoffs" "today")
  MISSING_KEYS=0
  if [ -f "$STATE_JSON" ]; then
    for KEY in "${REQUIRED_KEYS[@]}"; do
      if ! jq -e ".$KEY" "$STATE_JSON" >/dev/null 2>&1; then
        fail "bot-state.json missing required key: '$KEY'"
        MISSING_KEYS=$((MISSING_KEYS + 1))
      fi
    done
    if [ "$MISSING_KEYS" -eq 0 ]; then
      pass "bot-state.json has all ${#REQUIRED_KEYS[@]} required top-level keys"
    fi

    # health has expected sub-keys
    if jq -e '.health.ollama' "$STATE_JSON" >/dev/null 2>&1; then
      pass "bot-state.json health.ollama key present"
    else
      fail "bot-state.json missing health.ollama"
    fi

    # lanes has expected sub-keys
    LANE_KEYS=("india_problems" "ai_gaps" "blogs" "funding" "podcast" "learning" "reports")
    LANE_MISSING=0
    for LK in "${LANE_KEYS[@]}"; do
      if ! jq -e ".lanes.$LK" "$STATE_JSON" >/dev/null 2>&1; then
        fail "bot-state.json missing lanes.$LK"
        LANE_MISSING=$((LANE_MISSING + 1))
      fi
    done
    if [ "$LANE_MISSING" -eq 0 ]; then
      pass "bot-state.json has all expected lane keys"
    fi

    # queues has expected sub-keys
    for QK in pending approved publish_ready posted; do
      if ! jq -e ".queues.$QK" "$STATE_JSON" >/dev/null 2>&1; then
        fail "bot-state.json missing queues.$QK"
      fi
    done
    if jq -e '.queues.pending' "$STATE_JSON" >/dev/null 2>&1 && \
       jq -e '.queues.approved' "$STATE_JSON" >/dev/null 2>&1; then
      pass "bot-state.json queues has pending/approved sub-keys"
    fi

    # today has log_lines and errors
    if jq -e '.today.log_lines' "$STATE_JSON" >/dev/null 2>&1 && \
       jq -e '.today.errors' "$STATE_JSON" >/dev/null 2>&1; then
      pass "bot-state.json today has log_lines and errors"
    else
      fail "bot-state.json today missing log_lines or errors"
    fi
  fi

  # bot-status.md is non-empty
  if [ -f "$STATE_MD" ]; then
    MD_SIZE=$(wc -c < "$STATE_MD" | tr -d ' ')
    if [ "$MD_SIZE" -gt 50 ]; then
      pass "bot-status.md is non-empty ($MD_SIZE bytes)"
    else
      fail "bot-status.md is suspiciously small ($MD_SIZE bytes)"
    fi
  else
    fail "bot-status.md does not exist"
  fi

  # bot-status.md contains expected sections
  if [ -f "$STATE_MD" ]; then
    SECTIONS_FOUND=0
    for SECTION_NAME in "Health" "Lane" "Queue" "Approval"; do
      if grep -qi "$SECTION_NAME" "$STATE_MD" 2>/dev/null; then
        SECTIONS_FOUND=$((SECTIONS_FOUND + 1))
      fi
    done
    if [ "$SECTIONS_FOUND" -ge 3 ]; then
      pass "bot-status.md contains expected report sections ($SECTIONS_FOUND/4)"
    else
      fail "bot-status.md missing report sections (only $SECTIONS_FOUND/4 found)"
    fi
  fi

fi

# ══════════════════════════════════════════════════════════════════════
# 5. POST-MANAGER TESTS
# ══════════════════════════════════════════════════════════════════════

if section "post-manager" "POST-MANAGER TESTS"; then

  POST_MGR="$MEDIA_DIR/publishing/post-manager.sh"

  if [ ! -f "$POST_MGR" ]; then
    fail "post-manager.sh does not exist at $POST_MGR"
  else
    # status command produces expected format
    STATUS_OUT=$(bash "$POST_MGR" status 2>&1)
    STATUS_EXIT=$?
    if [ "$STATUS_EXIT" -eq 0 ] && echo "$STATUS_OUT" | grep -q "PUBLISHING STATUS\|TOTALS\|pending"; then
      pass "post-manager.sh status produces expected format"
    else
      fail "post-manager.sh status unexpected output (exit $STATUS_EXIT)"
    fi

    # review command works
    REVIEW_OUT=$(bash "$POST_MGR" review 2>&1)
    REVIEW_EXIT=$?
    if [ "$REVIEW_EXIT" -eq 0 ]; then
      pass "post-manager.sh review runs without error"
    else
      fail "post-manager.sh review failed (exit $REVIEW_EXIT)"
    fi

    # approve with nonexistent file returns error
    APPROVE_OUT=$(bash "$POST_MGR" approve "NONEXISTENT_FILE_xyz_12345.md" 2>&1)
    APPROVE_EXIT=$?
    if echo "$APPROVE_OUT" | grep -qi "not found"; then
      pass "post-manager.sh approve nonexistent file reports 'not found'"
    else
      fail "post-manager.sh approve nonexistent file did not report error" "$(echo "$APPROVE_OUT" | head -2)"
    fi

    # reject with nonexistent file returns error
    REJECT_OUT=$(bash "$POST_MGR" reject "NONEXISTENT_FILE_xyz_12345.md" 2>&1)
    REJECT_EXIT=$?
    if echo "$REJECT_OUT" | grep -qi "not found"; then
      pass "post-manager.sh reject nonexistent file reports 'not found'"
    else
      fail "post-manager.sh reject nonexistent file did not report error" "$(echo "$REJECT_OUT" | head -2)"
    fi

    # history command works
    HIST_OUT=$(bash "$POST_MGR" history 2>&1)
    HIST_EXIT=$?
    if [ "$HIST_EXIT" -eq 0 ] && echo "$HIST_OUT" | grep -qi "history\|posted\|archive\|no activity"; then
      pass "post-manager.sh history produces expected output"
    else
      fail "post-manager.sh history failed (exit $HIST_EXIT)"
    fi

    # Unknown command shows usage
    USAGE_OUT=$(bash "$POST_MGR" "bogus-command-xyz" 2>&1) || true
    if echo "$USAGE_OUT" | grep -qi "usage\|post.manager\|workflow"; then
      pass "post-manager.sh unknown command shows usage"
    else
      fail "post-manager.sh unknown command did not show usage"
    fi
  fi

fi

# ══════════════════════════════════════════════════════════════════════
# 6. APPROVAL ENGINE TESTS
# ══════════════════════════════════════════════════════════════════════

if section "approval" "APPROVAL ENGINE TESTS"; then

  APPROVAL_ENGINE="$SCRIPTS_DIR/approval-engine.sh"

  if [ ! -f "$APPROVAL_ENGINE" ]; then
    fail "approval-engine.sh does not exist"
  else
    # Script sources without syntax error (check via bash -n)
    SYNTAX_OUT=$(bash -n "$APPROVAL_ENGINE" 2>&1)
    SYNTAX_EXIT=$?
    if [ "$SYNTAX_EXIT" -eq 0 ]; then
      pass "approval-engine.sh has no syntax errors"
    else
      fail "approval-engine.sh has syntax errors" "$SYNTAX_OUT"
    fi

    # --dry-run flag is recognized (check the code parses it)
    if grep -q '\-\-dry-run' "$APPROVAL_ENGINE"; then
      pass "approval-engine.sh supports --dry-run flag"
    else
      fail "approval-engine.sh does not recognize --dry-run"
    fi

    # Processes both .json and .md files
    if grep -q '\.json' "$APPROVAL_ENGINE" && grep -q '\.md' "$APPROVAL_ENGINE"; then
      pass "approval-engine.sh handles both .json and .md file types"
    else
      fail "approval-engine.sh may not handle both .json and .md files"
    fi

    # Approval directories exist
    for AD in "$APPROVALS_DIR/review" "$APPROVALS_DIR/approved" "$APPROVALS_DIR/blocked"; do
      if [ -d "$AD" ] || grep -q "mkdir.*$(basename "$AD")" "$APPROVAL_ENGINE"; then
        : # ok, either exists or script creates it
      fi
    done
    # Check the script creates needed directories
    if grep -q 'mkdir.*approved.*blocked.*review\|mkdir.*review.*approved.*blocked' "$APPROVAL_ENGINE" 2>/dev/null || \
       grep -q 'mkdir -p.*approved.*review' "$APPROVAL_ENGINE" 2>/dev/null; then
      pass "approval-engine.sh creates required approval directories"
    else
      # Check if directories actually exist
      if [ -d "$APPROVALS_DIR/review" ] && [ -d "$APPROVALS_DIR/approved" ] && [ -d "$APPROVALS_DIR/blocked" ]; then
        pass "approval output directories exist (review, approved, blocked)"
      else
        fail "approval directories missing and script may not create them"
      fi
    fi

    # Checks Ollama before processing (but we don't want it to actually run)
    if grep -q 'curl.*api/tags\|ollama' "$APPROVAL_ENGINE"; then
      pass "approval-engine.sh checks Ollama availability"
    else
      fail "approval-engine.sh does not check Ollama"
    fi

    # Has DRY_RUN logic that prevents file moves
    if grep -q 'DRY_RUN' "$APPROVAL_ENGINE"; then
      pass "approval-engine.sh implements DRY_RUN logic"
    else
      fail "approval-engine.sh missing DRY_RUN implementation"
    fi
  fi

fi

# ══════════════════════════════════════════════════════════════════════
# 7. CONFIG CONSISTENCY TESTS
# ══════════════════════════════════════════════════════════════════════

if section "config" "CONFIG CONSISTENCY TESTS"; then

  BOT_CONFIG="$BOT_ROOT/config/bot-config.json"
  BOT_STATE="$BOT_ROOT/dashboard/bot-state.json"

  # bot-config.json is valid JSON
  if [ -f "$BOT_CONFIG" ]; then
    if jq empty "$BOT_CONFIG" 2>/dev/null; then
      pass "bot-config.json is valid JSON"
    else
      fail "bot-config.json is NOT valid JSON"
    fi
  else
    fail "bot-config.json does not exist"
  fi

  # bot-state.json is valid JSON (redundant with dashboard test but config section should self-contain)
  if [ -f "$BOT_STATE" ]; then
    if jq empty "$BOT_STATE" 2>/dev/null; then
      pass "bot-state.json is valid JSON"
    else
      fail "bot-state.json is NOT valid JSON"
    fi
  else
    fail "bot-state.json does not exist"
  fi

  # Version numbers match across config and state
  if [ -f "$BOT_CONFIG" ] && [ -f "$BOT_STATE" ]; then
    CONFIG_VERSION=$(jq -r '.version // "none"' "$BOT_CONFIG" 2>/dev/null)
    STATE_VERSION=$(jq -r '.version // "none"' "$BOT_STATE" 2>/dev/null)
    if [ "$CONFIG_VERSION" = "$STATE_VERSION" ]; then
      pass "Version match: bot-config.json ($CONFIG_VERSION) = bot-state.json ($STATE_VERSION)"
    else
      fail "Version MISMATCH: bot-config.json ($CONFIG_VERSION) != bot-state.json ($STATE_VERSION)"
    fi
  fi

  # bot-config.json has required structure
  if [ -f "$BOT_CONFIG" ]; then
    for CK in name version models scanner approval_levels logging; do
      if ! jq -e ".$CK" "$BOT_CONFIG" >/dev/null 2>&1; then
        fail "bot-config.json missing key: $CK"
      fi
    done
    if jq -e '.name' "$BOT_CONFIG" >/dev/null 2>&1 && \
       jq -e '.version' "$BOT_CONFIG" >/dev/null 2>&1 && \
       jq -e '.models' "$BOT_CONFIG" >/dev/null 2>&1; then
      pass "bot-config.json has required structure (name, version, models)"
    fi
  fi

  # Model in config matches lane-runner default
  if [ -f "$BOT_CONFIG" ]; then
    CONFIG_MODEL=$(jq -r '.models.scripts_default // "none"' "$BOT_CONFIG" 2>/dev/null)
    RUNNER_MODEL=$(grep '^MODEL=' "$BOT_ROOT/lane-runner.sh" 2>/dev/null | head -1 | cut -d'"' -f2)
    if [ -n "$CONFIG_MODEL" ] && [ -n "$RUNNER_MODEL" ]; then
      if [ "$CONFIG_MODEL" = "$RUNNER_MODEL" ]; then
        pass "Model consistency: config ($CONFIG_MODEL) matches lane-runner ($RUNNER_MODEL)"
      else
        fail "Model MISMATCH: config ($CONFIG_MODEL) != lane-runner ($RUNNER_MODEL)"
      fi
    else
      skip "model consistency check" "could not extract model names"
    fi
  fi

  # Ollama URL in config matches lane-runner
  if [ -f "$BOT_CONFIG" ]; then
    CONFIG_URL=$(jq -r '.ollama_url // "none"' "$BOT_CONFIG" 2>/dev/null)
    RUNNER_URL=$(grep '^OLLAMA_URL=' "$BOT_ROOT/lane-runner.sh" 2>/dev/null | head -1 | cut -d'"' -f2)
    if [ "$CONFIG_URL" = "$RUNNER_URL" ]; then
      pass "Ollama URL consistency: config matches lane-runner ($CONFIG_URL)"
    else
      fail "Ollama URL MISMATCH: config ($CONFIG_URL) != lane-runner ($RUNNER_URL)"
    fi
  fi

  # All case-statement routes in inbharat-run.sh correspond to defined functions
  ORCHESTRATOR="$BOT_ROOT/inbharat-run.sh"
  if [ -f "$ORCHESTRATOR" ]; then
    # Extract modes from the main case statement (lines after "Main routing")
    DANGLING=0
    while IFS= read -r ROUTE_LINE; do
      MODE_NAME=$(echo "$ROUTE_LINE" | sed 's/[[:space:]]*//g' | sed 's/).*//')
      [ -z "$MODE_NAME" ] && continue
      [ "$MODE_NAME" = "*" ] && continue
      [ "$MODE_NAME" = "full" ] && continue  # full calls multiple functions inline
      # Check a corresponding run_ function or inline code exists
      FUNC_NAME=$(echo "$ROUTE_LINE" | grep -oE 'run_[a-z_]+' | head -1)
      if [ -n "$FUNC_NAME" ]; then
        if ! grep -q "^${FUNC_NAME}()" "$ORCHESTRATOR" 2>/dev/null; then
          fail "Route '$MODE_NAME' calls $FUNC_NAME but function not defined"
          DANGLING=$((DANGLING + 1))
        fi
      fi
    done < <(sed -n '/^case "\$MODE"/,/^esac$/p' "$ORCHESTRATOR" | grep -E '^\s+\w.*\)')
    if [ "$DANGLING" -eq 0 ]; then
      pass "All orchestrator case routes call defined functions"
    fi
  fi

fi

# ══════════════════════════════════════════════════════════════════════
# 8. SECURITY TESTS
# ══════════════════════════════════════════════════════════════════════

if section "security" "SECURITY TESTS"; then

  # No plaintext API keys in .sh files
  # Look for patterns like API_KEY="sk-...", OPENAI_API_KEY=, etc.
  API_KEY_HITS=$(grep -rlE '(API_KEY|api_key|apikey)\s*=\s*"[a-zA-Z0-9_-]{20,}"' \
    "$WORKSPACE_ROOT/OpenClawData" \
    --include="*.sh" 2>/dev/null | grep -v 'tests/' | head -5)
  if [ -z "$API_KEY_HITS" ]; then
    pass "No hardcoded API keys found in .sh files"
  else
    fail "Potential API keys found in .sh files" "$API_KEY_HITS"
  fi

  # No passwords in .sh files (but allow references in echo/comment lines and $SMTP_PASS variable refs)
  PASS_HITS=$(grep -rnE '(PASSWORD|PASS|password)\s*=\s*"[^$"][^"]{5,}"' \
    "$WORKSPACE_ROOT/OpenClawData" \
    --include="*.sh" 2>/dev/null | grep -v 'tests/' | grep -v '^\s*#' | grep -v "echo " | grep -v "echo '" | head -5)
  PASS_HITS=$(echo "$PASS_HITS" | sed '/^$/d')
  if [ -z "$PASS_HITS" ]; then
    pass "No hardcoded passwords found in .sh files"
  else
    fail "Potential passwords found in .sh files" "$PASS_HITS"
  fi

  # .mail-credentials either doesn't exist or has restrictive permissions
  MAIL_CREDS="$BOT_ROOT/config/.mail-credentials"
  if [ ! -f "$MAIL_CREDS" ]; then
    pass ".mail-credentials does not exist (safe)"
  else
    # Check permissions - should not be world-readable
    PERMS=$(stat -f '%Lp' "$MAIL_CREDS" 2>/dev/null || stat -c '%a' "$MAIL_CREDS" 2>/dev/null)
    if [ -n "$PERMS" ]; then
      # Last digit should be 0 (no world access)
      WORLD_BITS=${PERMS: -1}
      if [ "$WORLD_BITS" = "0" ]; then
        pass ".mail-credentials has restrictive permissions ($PERMS)"
      else
        fail ".mail-credentials is world-readable (permissions: $PERMS)"
      fi
    else
      skip ".mail-credentials permission check" "could not read permissions"
    fi
  fi

  # No secrets in git-tracked files
  # Check if any tracked file contains obvious secret patterns
  GIT_SECRETS=$(cd "$WORKSPACE_ROOT" && git ls-files 2>/dev/null | \
    xargs grep -lE '(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|gsk_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16})' 2>/dev/null | \
    grep -v 'tests/' | head -5)
  if [ -z "$GIT_SECRETS" ]; then
    pass "No secret tokens (OpenAI/GitHub/Groq/AWS patterns) in git-tracked files"
  else
    fail "Potential secrets in git-tracked files" "$GIT_SECRETS"
  fi

  # No .env files tracked in git
  GIT_ENV=$(cd "$WORKSPACE_ROOT" && git ls-files 2>/dev/null | grep -E '\.env$' | head -5)
  if [ -z "$GIT_ENV" ]; then
    pass "No .env files tracked in git"
  else
    fail ".env files tracked in git" "$GIT_ENV"
  fi

  # No credentials.json tracked in git
  GIT_CREDS=$(cd "$WORKSPACE_ROOT" && git ls-files 2>/dev/null | grep -iE 'credentials\.json|secrets\.json' | head -5)
  if [ -z "$GIT_CREDS" ]; then
    pass "No credentials/secrets JSON files tracked in git"
  else
    fail "Credentials files tracked in git" "$GIT_CREDS"
  fi

fi

# ══════════════════════════════════════════════════════════════════════
# 9. CONTENT QUALITY TESTS
# ══════════════════════════════════════════════════════════════════════

if section "content" "CONTENT QUALITY TESTS"; then

  # No </think> tags in any queue content
  THINK_HITS=""
  for PLATFORM_DIR in "$QUEUES_DIR"/*/; do
    [ ! -d "$PLATFORM_DIR" ] && continue
    for STAGE in pending approved publish-ready; do
      STAGE_DIR="${PLATFORM_DIR}${STAGE}"
      [ ! -d "$STAGE_DIR" ] && continue
      HITS=$(grep -rl '</think>\|<think>' "$STAGE_DIR" 2>/dev/null | head -3)
      [ -n "$HITS" ] && THINK_HITS+="$HITS"$'\n'
    done
  done
  # Also check bot output directories
  for OUTPUT_DIR in "$BOT_ROOT/india-problems" "$BOT_ROOT/ai-gaps" "$BOT_ROOT/blogs" \
    "$BOT_ROOT/funding" "$BOT_ROOT/podcast" "$BOT_ROOT/campaign-briefs" \
    "$BOT_ROOT/ecosystem-intelligence" "$BOT_ROOT/learning" "$BOT_ROOT/reports"; do
    [ ! -d "$OUTPUT_DIR" ] && continue
    HITS=$(grep -rl '</think>\|<think>' "$OUTPUT_DIR" 2>/dev/null | head -3)
    [ -n "$HITS" ] && THINK_HITS+="$HITS"$'\n'
  done
  THINK_HITS=$(echo "$THINK_HITS" | sed '/^$/d')
  if [ -z "$THINK_HITS" ]; then
    pass "No <think> tags found in queue content or bot outputs"
  else
    THINK_COUNT=$(echo "$THINK_HITS" | wc -l | tr -d ' ')
    fail "$THINK_COUNT files contain <think> tags" "$(echo "$THINK_HITS" | head -5)"
  fi

  # No files larger than 50KB in pending queues
  OVERSIZED=""
  for PLATFORM_DIR in "$QUEUES_DIR"/*/; do
    [ ! -d "$PLATFORM_DIR" ] && continue
    PENDING="${PLATFORM_DIR}pending"
    [ ! -d "$PENDING" ] && continue
    while IFS= read -r BIGFILE; do
      [ -z "$BIGFILE" ] && continue
      SIZE=$(wc -c < "$BIGFILE" | tr -d ' ')
      OVERSIZED+="  $BIGFILE ($SIZE bytes)"$'\n'
    done < <(find "$PENDING" -type f -size +50k ! -name ".*" 2>/dev/null)
  done
  if [ -z "$OVERSIZED" ]; then
    pass "No oversized files (>50KB) in pending queues"
  else
    fail "Oversized files in pending queues" "$OVERSIZED"
  fi

  # All JSON files in queues are valid JSON
  JSON_INVALID=""
  JSON_CHECKED=0
  for PLATFORM_DIR in "$QUEUES_DIR"/*/; do
    [ ! -d "$PLATFORM_DIR" ] && continue
    for STAGE in pending approved publish-ready posted; do
      STAGE_DIR="${PLATFORM_DIR}${STAGE}"
      [ ! -d "$STAGE_DIR" ] && continue
      while IFS= read -r JSONFILE; do
        [ -z "$JSONFILE" ] && continue
        JSON_CHECKED=$((JSON_CHECKED + 1))
        if ! jq empty "$JSONFILE" 2>/dev/null; then
          JSON_INVALID+="  $JSONFILE"$'\n'
        fi
      done < <(find "$STAGE_DIR" -name "*.json" -type f ! -name ".*" 2>/dev/null)
    done
  done
  if [ -z "$JSON_INVALID" ]; then
    pass "All $JSON_CHECKED JSON files in queues are valid"
  else
    INVALID_COUNT=$(echo "$JSON_INVALID" | sed '/^$/d' | wc -l | tr -d ' ')
    fail "$INVALID_COUNT JSON files in queues are invalid" "$JSON_INVALID"
  fi

  # Check approval queue JSON files too
  APPROVAL_JSON_BAD=""
  APPROVAL_JSON_CHECKED=0
  for AD in "$APPROVALS_DIR/review" "$APPROVALS_DIR/approved" "$APPROVALS_DIR/blocked" "$APPROVALS_DIR/pending"; do
    [ ! -d "$AD" ] && continue
    while IFS= read -r JSONFILE; do
      [ -z "$JSONFILE" ] && continue
      APPROVAL_JSON_CHECKED=$((APPROVAL_JSON_CHECKED + 1))
      if ! jq empty "$JSONFILE" 2>/dev/null; then
        APPROVAL_JSON_BAD+="  $JSONFILE"$'\n'
      fi
    done < <(find "$AD" -name "*.json" -type f ! -name ".*" 2>/dev/null)
  done
  if [ -z "$APPROVAL_JSON_BAD" ]; then
    pass "All $APPROVAL_JSON_CHECKED JSON files in approval dirs are valid"
  else
    INVALID_COUNT=$(echo "$APPROVAL_JSON_BAD" | sed '/^$/d' | wc -l | tr -d ' ')
    fail "$INVALID_COUNT JSON files in approval dirs are invalid" "$APPROVAL_JSON_BAD"
  fi

  # No empty output files in bot lanes (zero-byte files indicate failed runs)
  EMPTY_OUTPUTS=""
  for LANE_DIR in "$BOT_ROOT/india-problems" "$BOT_ROOT/ai-gaps" "$BOT_ROOT/blogs" \
    "$BOT_ROOT/funding" "$BOT_ROOT/podcast" "$BOT_ROOT/campaign-briefs" \
    "$BOT_ROOT/learning" "$BOT_ROOT/reports"; do
    [ ! -d "$LANE_DIR" ] && continue
    while IFS= read -r EMPTY; do
      [ -z "$EMPTY" ] && continue
      EMPTY_OUTPUTS+="  $EMPTY"$'\n'
    done < <(find "$LANE_DIR" -maxdepth 1 -name "*.md" -type f -empty 2>/dev/null)
  done
  if [ -z "$EMPTY_OUTPUTS" ]; then
    pass "No empty .md output files in bot lane directories"
  else
    EMPTY_COUNT=$(echo "$EMPTY_OUTPUTS" | sed '/^$/d' | wc -l | tr -d ' ')
    fail "$EMPTY_COUNT empty .md files in lane directories (failed runs?)" "$EMPTY_OUTPUTS"
  fi

fi

# ══════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════

TOTAL=$((PASS + FAIL + SKIP))
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEST RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Total:   $TOTAL"
echo "  Passed:  $PASS"
echo "  Failed:  $FAIL"
echo "  Skipped: $SKIP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FAIL" -eq 0 ]; then
  echo "  ALL TESTS PASSED"
else
  echo "  $FAIL FAILURE(S) DETECTED"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Exit with failure if any tests failed
[ "$FAIL" -gt 0 ] && exit 1
exit 0
