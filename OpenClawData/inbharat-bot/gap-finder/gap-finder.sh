#!/bin/bash
# InBharat Bot — Gap Finder / Opportunity Analyzer
# Reads the latest ecosystem scan, uses Ollama to identify gaps, weaknesses, opportunities.
# Produces a structured findings report.

set -euo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
REGISTRY_DIR="$BOT_ROOT/registry"
FINDINGS_DIR="$BOT_ROOT/gap-finder"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
FINDINGS_OUTPUT="$FINDINGS_DIR/findings-${TIMESTAMP}.md"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"

source "$BOT_ROOT/logging/bot-logger.sh"

bot_log "gap-finder" "info" "=== Gap analysis started ==="

# Find latest scan
LATEST_SCAN=$(ls -t "$REGISTRY_DIR"/ecosystem-scan-*.md 2>/dev/null | head -1)
if [ -z "$LATEST_SCAN" ]; then
  bot_log "gap-finder" "error" "No ecosystem scan found. Run scanner first."
  exit 1
fi

bot_log "gap-finder" "info" "Using scan: $LATEST_SCAN"

# Read scan content
SCAN_CONTENT=$(cat "$LATEST_SCAN")

# Build analysis prompt
PROMPT="You are InBharat Bot, an ecosystem intelligence analyzer.

Below is a complete scan of the InBharat AI ecosystem — tools, skills, scripts, queues, models, and current state.

Your job is to analyze this and produce a structured findings report identifying:

1. STRENGTHS — what is well-built and working
2. GAPS — what is missing, incomplete, or broken
3. WEAKNESSES — what exists but is fragile, duplicated, or poorly structured
4. OPPORTUNITIES — practical improvements, new tools, connectors, or workflows worth building
5. RISKS — things that could break, cause data loss, or produce wrong outputs
6. PRIORITIES — rank the top 5 most impactful things to fix or build next

Be specific. Reference actual files, scripts, counts, and states from the scan.
Do NOT be generic. Do NOT hallucinate features that don't exist.
If something is unclear from the scan, say so.

Format your output as a clean Markdown report with sections for each of the above.

=== ECOSYSTEM SCAN ===
$SCAN_CONTENT"

# Call Ollama
bot_log "gap-finder" "info" "Calling $MODEL for analysis..."

RESPONSE=$(curl -s "$OLLAMA_URL/api/generate" \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.3, num_predict: 4000}}')" \
  | jq -r '.response // "ERROR: No response from model"')

if [ "$RESPONSE" = "ERROR: No response from model" ]; then
  bot_log "gap-finder" "error" "Ollama did not respond"
  exit 1
fi

# Write findings
{
echo "# InBharat Bot — Gap Analysis & Findings"
echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
echo "**Based on scan:** $(basename "$LATEST_SCAN")"
echo "**Model:** $MODEL"
echo ""
echo "$RESPONSE"
} > "$FINDINGS_OUTPUT"

bot_log "gap-finder" "info" "Findings saved → $FINDINGS_OUTPUT"
bot_log_evidence "gap-finder" "gap-analysis" "$FINDINGS_OUTPUT" "success"

echo ""
echo "=== FINDINGS SAVED TO: $FINDINGS_OUTPUT ==="
