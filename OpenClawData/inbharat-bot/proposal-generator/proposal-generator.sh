#!/bin/bash
# InBharat Bot — Proposal Generator
# Reads the latest findings, generates structured build/fix/improve proposals.
# Each proposal has: title, problem, priority, effort, dependencies, criteria, docs/release needs, promotion angle.

set -euo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
FINDINGS_DIR="$BOT_ROOT/gap-finder"
PROPOSALS_DIR="$BOT_ROOT/proposal-generator"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
PROPOSALS_OUTPUT="$PROPOSALS_DIR/proposals-${TIMESTAMP}.md"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"

source "$BOT_ROOT/logging/bot-logger.sh"

bot_log "proposal-gen" "info" "=== Proposal generation started ==="

# Find latest findings
LATEST_FINDINGS=$(ls -t "$FINDINGS_DIR"/findings-*.md 2>/dev/null | head -1)
if [ -z "$LATEST_FINDINGS" ]; then
  bot_log "proposal-gen" "error" "No findings found. Run gap-finder first."
  exit 1
fi

bot_log "proposal-gen" "info" "Using findings: $LATEST_FINDINGS"

FINDINGS_CONTENT=$(cat "$LATEST_FINDINGS")

PROMPT="You are InBharat Bot, a builder operations planner.

Below are ecosystem findings showing gaps, weaknesses, and opportunities.

Your job is to convert the TOP 5 most important findings into structured proposals.

For EACH proposal, provide exactly this structure:

## Proposal N: [Title]
- **Problem:** What is wrong or missing
- **Why it matters:** Business/operational impact
- **Priority:** Critical / High / Medium / Low
- **Effort estimate:** Hours or days for a solo builder
- **Dependencies:** What must exist first
- **Acceptance criteria:** How to verify it is done
- **Docs/release needs:** What documentation or release steps are needed
- **Promotion angle:** How this could be communicated to users/community
- **Recommended model:** qwen3:8b or qwen3:8b and why
- **Status:** proposed

Be practical. These are for a solo founder building real AI products.
Do NOT propose massive infrastructure rewrites.
Do NOT propose vague aspirational goals.
Each proposal must be actionable within 1-3 days maximum.

=== FINDINGS ===
$FINDINGS_CONTENT"

bot_log "proposal-gen" "info" "Calling $MODEL for proposals..."

RESPONSE=$(curl -s --max-time 120 "$OLLAMA_URL/api/generate" \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.4, num_predict: 4000}}')" \
  | jq -r '(.response // .thinking) // "ERROR: No response from model"')

if [ "$RESPONSE" = "ERROR: No response from model" ]; then
  bot_log "proposal-gen" "error" "Ollama did not respond"
  exit 1
fi

# Write proposals
{
echo "# InBharat Bot — Build Proposals"
echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
echo "**Based on findings:** $(basename "$LATEST_FINDINGS")"
echo "**Model:** $MODEL"
echo "**Status:** All proposals are DRAFT — require founder approval before action"
echo ""
echo "$RESPONSE"
} > "$PROPOSALS_OUTPUT"

# Count proposals
PROPOSAL_COUNT=$(grep -c "^## Proposal" "$PROPOSALS_OUTPUT" 2>/dev/null || echo "0")

bot_log "proposal-gen" "info" "$PROPOSAL_COUNT proposals generated → $PROPOSALS_OUTPUT"
bot_log_evidence "proposal-gen" "proposal-generation" "$PROPOSALS_OUTPUT" "success"

echo ""
echo "=== $PROPOSAL_COUNT PROPOSALS SAVED TO: $PROPOSALS_OUTPUT ==="
