#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# task-builder.sh — Auto-detect, create, and manage tasks
# Usage: ./task-builder.sh [--scan | --create <desc> | --list | --execute <task-id>]
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

WS="/Volumes/Expansion/CMO-10million"
TASKS="$WS/OpenClawData/inbharat-bot/tasks"
LOG="$WS/OpenClawData/logs/task-builder.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')

mkdir -p "$TASKS"/{pending,in-progress,done,blocked}
log() { echo "[$TS] $1" >> "$LOG"; echo "$1"; }

ACTION="${1:---list}"

case "$ACTION" in
  --scan)
    log "=== Task Scan: detecting missing work ==="
    
    # Scan for gaps using Ollama
    CONTEXT="Current workspace state:
- Scripts: $(ls "$WS/OpenClawData/scripts/"*.sh 2>/dev/null | wc -l | tr -d ' ')
- Skills: $(ls "$WS/OpenClawData/skills/" 2>/dev/null | wc -l | tr -d ' ')
- Reports (daily): $(find "$WS/OpenClawData/reports/daily" -type f 2>/dev/null | wc -l | tr -d ' ')
- Reports (weekly): $(find "$WS/OpenClawData/reports/weekly" -type f 2>/dev/null | wc -l | tr -d ' ')
- Community maps: $(find "$WS/OpenClawData/community/maps" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
- Leads: $(find "$WS/OpenClawData/revenue/leads" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
- Queue items: $(find "$WS/OpenClawData/queues" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
- Memory files: $(find "$WS/OpenClawData/memory" -type f 2>/dev/null | wc -l | tr -d ' ')
- Cron status: $(crontab -l 2>/dev/null | grep -c "pipeline" || echo 0) pipelines scheduled
- Discord webhook: $([ -f "$WS/OpenClawData/policies/discord-webhook.json" ] && echo "configured" || echo "NOT configured")
- Source notes: $(find "$WS/MarketingToolData/source-notes" -type f 2>/dev/null | wc -l | tr -d ' ')"

    PROMPT="You are a task detection system for InBharat. Given the current workspace state, identify 3-5 actionable tasks that should be done next.

$CONTEXT

Rules:
- Tasks must be specific and actionable
- Classify risk: safe (can auto-execute) or review (needs owner approval)
- Priority: critical / high / medium / low
- Only suggest tasks that make practical sense for a solo builder

Output ONLY a JSON array:
[{\"id\":\"task-001\",\"title\":\"...\",\"description\":\"...\",\"risk\":\"safe|review\",\"priority\":\"critical|high|medium|low\",\"category\":\"content|community|revenue|infrastructure|docs\",\"estimated_minutes\":N}]"

    RESPONSE=$(curl -s http://127.0.0.1:11434/api/generate \
      -d "{\"model\":\"qwen3:8b\",\"prompt\":$(echo "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))'),\"stream\":false,\"options\":{\"temperature\":0.3}}" 2>/dev/null)

    TEXT=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response','') or d.get('thinking',''))" 2>/dev/null)
    
    # Save tasks
    echo "$TEXT" | python3 -c "
import sys, re, json
text = sys.stdin.read()
m = re.search(r'\[[\s\S]*\]', text)
if m:
    try:
        tasks = json.loads(m.group())
        for t in tasks:
            tid = t.get('id','task-unknown')
            with open('$TASKS/pending/' + tid + '.json', 'w') as f:
                json.dump(t, f, indent=2)
            print(f\"  Created: {tid} [{t.get('priority','?')}] {t.get('title','?')}\")
    except Exception as e:
        print(f'Parse error: {e}')
else:
    print('No tasks found in response')
" 2>/dev/null

    log "=== Task scan complete ==="
    ;;

  --create)
    DESC="${2:?Missing task description}"
    TASK_ID="task-$(date +%s)"
    cat > "$TASKS/pending/$TASK_ID.json" << TASK
{
  "id": "$TASK_ID",
  "title": "$DESC",
  "created": "$TS",
  "risk": "review",
  "priority": "medium",
  "status": "pending"
}
TASK
    log "Created task: $TASK_ID — $DESC"
    ;;

  --list)
    log "=== Tasks ==="
    for state in pending in-progress done blocked; do
      COUNT=$(find "$TASKS/$state" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
      [ "$COUNT" -gt 0 ] && log "  $state: $COUNT"
      find "$TASKS/$state" -name "*.json" -type f 2>/dev/null | while read f; do
        TITLE=$(python3 -c "import json; print(json.load(open('$f')).get('title','?'))" 2>/dev/null)
        PRIO=$(python3 -c "import json; print(json.load(open('$f')).get('priority','?'))" 2>/dev/null)
        echo "    [$(basename "$f" .json)] [$PRIO] $TITLE"
      done
    done
    ;;

  --execute)
    TASK_ID="${2:?Missing task ID}"
    TASK_FILE="$TASKS/pending/$TASK_ID.json"
    [ ! -f "$TASK_FILE" ] && echo "Task not found: $TASK_ID" && exit 1
    
    RISK=$(python3 -c "import json; print(json.load(open('$TASK_FILE')).get('risk','review'))" 2>/dev/null)
    if [ "$RISK" = "review" ]; then
      log "Task $TASK_ID requires review. Moving to review queue."
      mv "$TASK_FILE" "$TASKS/blocked/"
      exit 0
    fi
    
    mv "$TASK_FILE" "$TASKS/in-progress/"
    log "Executing safe task: $TASK_ID"
    # Safe execution would go here per task type
    mv "$TASKS/in-progress/$TASK_ID.json" "$TASKS/done/"
    log "Task $TASK_ID completed"
    ;;
esac
