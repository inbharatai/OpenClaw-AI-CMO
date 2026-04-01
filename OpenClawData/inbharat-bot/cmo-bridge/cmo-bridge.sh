#!/bin/bash
# InBharat Bot — CMO Bridge
# Converts approved proposals/findings into CMO pipeline source material.
# This bridges builder intelligence → marketing content.

set -euo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
WORKSPACE="/Volumes/Expansion/CMO-10million"
CMO_SOURCE="$WORKSPACE/MarketingToolData/source-notes"
PROPOSALS_DIR="$BOT_ROOT/proposal-generator"
BRIDGE_LOG="$BOT_ROOT/cmo-bridge"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"

source "$BOT_ROOT/logging/bot-logger.sh"

bot_log "cmo-bridge" "info" "=== CMO Bridge started ==="

# Find latest proposals
LATEST_PROPOSALS=$(ls -t "$PROPOSALS_DIR"/proposals-*.md 2>/dev/null | head -1)
if [ -z "$LATEST_PROPOSALS" ]; then
  bot_log "cmo-bridge" "error" "No proposals found. Run proposal-generator first."
  exit 1
fi

bot_log "cmo-bridge" "info" "Using proposals: $LATEST_PROPOSALS"

PROPOSALS_CONTENT=$(cat "$LATEST_PROPOSALS")

PROMPT="You are a founder communications writer for InBharat, an AI tools ecosystem.

Below are internal build proposals from our ecosystem intelligence bot.

Your job is to convert each approved proposal into a short, honest, founder-voice source note that can feed into our content pipeline.

For each proposal, write a 3-5 sentence source note that could become:
- a build-in-public update
- a product roadmap snippet
- a founder tweet/post
- a community update

Rules:
- Be honest — only reference what we plan to build, not what exists yet
- Use founder voice — direct, practical, no corporate fluff
- Keep each note under 100 words
- Label each note with a suggested content type: [build-log] [roadmap] [community-update] [product-note]

Output each as a separate section with a clear title.

=== PROPOSALS ===
$PROPOSALS_CONTENT"

bot_log "cmo-bridge" "info" "Generating CMO source material..."

RESPONSE=$(curl -s --max-time 120 "$OLLAMA_URL/api/generate" \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.5, num_predict: 2000}}')" \
  | jq -r '(.response // empty) // "ERROR: No response from model"')

if [ "$RESPONSE" = "ERROR: No response from model" ]; then
  bot_log "cmo-bridge" "error" "Ollama did not respond"
  exit 1
fi

# Save bridge output
BRIDGE_OUTPUT="$BRIDGE_LOG/bridge-output-${TIMESTAMP}.md"
{
echo "# InBharat Bot → CMO Bridge Output"
echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
echo "**Source:** $(basename "$LATEST_PROPOSALS")"
echo "**Status:** Draft source material — feeds into CMO pipeline"
echo ""
echo "$RESPONSE"
} > "$BRIDGE_OUTPUT"

# Also save as a CMO source note so the daily pipeline can pick it up
SOURCE_NOTE="$CMO_SOURCE/inbharat-bot-update-$(date +%Y-%m-%d).md"
{
echo "# InBharat Bot — Ecosystem Update"
echo "source: inbharat-bot"
echo "type: build-log"
echo "date: $(date +%Y-%m-%d)"
echo ""
echo "$RESPONSE"
} > "$SOURCE_NOTE"

bot_log "cmo-bridge" "info" "Bridge output → $BRIDGE_OUTPUT"
bot_log "cmo-bridge" "info" "CMO source note → $SOURCE_NOTE"
bot_log_evidence "cmo-bridge" "bridge-generation" "$BRIDGE_OUTPUT" "success"
bot_log_evidence "cmo-bridge" "source-note-creation" "$SOURCE_NOTE" "success"

echo ""
echo "=== CMO BRIDGE COMPLETE ==="
echo "Bridge output: $BRIDGE_OUTPUT"
echo "Source note for pipeline: $SOURCE_NOTE"
