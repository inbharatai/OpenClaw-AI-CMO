#!/bin/bash
# InBharat Bot — Ecosystem Scanner
# Scans local projects, repos, websites, docs and produces a structured registry.
# Does NOT modify anything. Read-only inspection.

set -euo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
REGISTRY_DIR="$BOT_ROOT/registry"
CONFIG="$BOT_ROOT/config/bot-config.json"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
SCAN_OUTPUT="$REGISTRY_DIR/ecosystem-scan-${TIMESTAMP}.md"

source "$BOT_ROOT/logging/bot-logger.sh"

bot_log "scanner" "info" "=== Ecosystem scan started ==="

# --- 1. Scan workspace structure ---
bot_log "scanner" "info" "Scanning workspace structure..."

WORKSPACE="/Volumes/Expansion/CMO-10million"

{
echo "# InBharat Ecosystem Scan"
echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
echo "**Scanner:** ecosystem-scanner v1.0"
echo ""

echo "## 1. Workspace Structure"
echo '```'
ls -1 "$WORKSPACE"
echo '```'
echo ""

# --- 2. OpenClawData inventory ---
echo "## 2. OpenClawData Inventory"
echo ""
echo "### Skills ($(ls "$WORKSPACE/OpenClawData/skills" | wc -l | tr -d ' ') total)"
echo '```'
ls -1 "$WORKSPACE/OpenClawData/skills"
echo '```'
echo ""

echo "### Pipeline Scripts ($(ls "$WORKSPACE/OpenClawData/scripts/"*.sh 2>/dev/null | grep -v '._' | wc -l | tr -d ' ') total)"
echo '```'
ls -1 "$WORKSPACE/OpenClawData/scripts/"*.sh 2>/dev/null | grep -v '._' | xargs -I{} basename {}
echo '```'
echo ""

echo "### Policies"
echo '```'
ls -1 "$WORKSPACE/OpenClawData/policies/" 2>/dev/null || echo "none"
echo '```'
echo ""

# --- 3. Queue state ---
echo "## 3. Queue State"
TOTAL_QUEUED=0
for channel_dir in "$WORKSPACE/OpenClawData/queues/"*/; do
  if [ -d "$channel_dir" ]; then
    channel=$(basename "$channel_dir")
    pending=$(ls "$channel_dir/pending/" 2>/dev/null | wc -l | tr -d ' ')
    approved=$(ls "$channel_dir/approved/" 2>/dev/null | wc -l | tr -d ' ')
    echo "- **$channel**: $pending pending, $approved approved"
    TOTAL_QUEUED=$((TOTAL_QUEUED + pending + approved))
  fi
done
echo "- **Total items in queues:** $TOTAL_QUEUED"
echo ""

# --- 4. Approval state ---
echo "## 4. Approval State"
for state_dir in pending approved blocked review; do
  count=$(ls "$WORKSPACE/OpenClawData/approvals/$state_dir/" 2>/dev/null | wc -l | tr -d ' ')
  echo "- **$state_dir**: $count items"
done
echo ""

# --- 5. Reports inventory ---
echo "## 5. Reports"
for period in daily weekly monthly; do
  count=$(ls "$WORKSPACE/OpenClawData/reports/$period/" 2>/dev/null | wc -l | tr -d ' ')
  echo "- **$period**: $count reports"
done
echo ""

# --- 6. Memory state ---
echo "## 6. Memory"
echo '```'
find "$WORKSPACE/OpenClawData/memory" -type f 2>/dev/null | head -20 || echo "empty"
echo '```'
echo ""

# --- 7. Marketing data ---
echo "## 7. MarketingToolData"
echo '```'
ls -1 "$WORKSPACE/MarketingToolData/" 2>/dev/null || echo "empty"
echo '```'
echo ""

# --- 8. Source material ---
echo "## 8. Source Material Available"
for src_dir in source-notes source-links ai-news product-updates; do
  count=$(ls "$WORKSPACE/MarketingToolData/$src_dir/" 2>/dev/null | wc -l | tr -d ' ')
  echo "- **$src_dir**: $count items"
done
echo ""

# --- 9. Ollama models ---
echo "## 9. Ollama Models"
echo '```'
ollama list 2>/dev/null || echo "Ollama not responding"
echo '```'
echo ""

# --- 10. OpenClaw install ---
echo "## 10. OpenClaw Installation"
if [ -d "$WORKSPACE/OpenClaw" ]; then
  echo "- Installed at: $WORKSPACE/OpenClaw"
  echo "- Key dirs: $(ls "$WORKSPACE/OpenClaw/packages/" 2>/dev/null | tr '\n' ', ')"
  echo "- Gateway PID: $(pgrep -f openclaw-gateway 2>/dev/null || echo 'not running')"
else
  echo "- Not installed locally"
fi
echo ""

# --- 11. InBharat Bot state ---
echo "## 11. InBharat Bot"
echo "- Modules: $(ls "$BOT_ROOT" | tr '\n' ', ')"
echo "- Previous scans: $(ls "$REGISTRY_DIR"/ecosystem-scan-*.md 2>/dev/null | wc -l | tr -d ' ')"
echo "- Previous proposals: $(ls "$BOT_ROOT/proposal-generator/"*.md 2>/dev/null | wc -l | tr -d ' ')"
echo ""

# --- 12. Cron state ---
echo "## 12. Cron State"
echo '```'
crontab -l 2>/dev/null | head -20 || echo "no crontab"
echo '```'
echo ""

# --- Summary ---
echo "## Summary"
echo "- Skills: $(ls "$WORKSPACE/OpenClawData/skills" | wc -l | tr -d ' ')"
echo "- Scripts: $(ls "$WORKSPACE/OpenClawData/scripts/"*.sh 2>/dev/null | grep -v '._' | wc -l | tr -d ' ')"
echo "- Queue items: $TOTAL_QUEUED"
echo "- Ollama: $(ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ') models"
echo "- Gateway: $(pgrep -f openclaw-gateway >/dev/null 2>&1 && echo 'running' || echo 'not running')"

} > "$SCAN_OUTPUT"

bot_log "scanner" "info" "Scan complete → $SCAN_OUTPUT"
bot_log_evidence "scanner" "ecosystem-scan" "$SCAN_OUTPUT" "success"

echo ""
echo "=== SCAN SAVED TO: $SCAN_OUTPUT ==="
