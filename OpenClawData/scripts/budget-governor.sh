#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# budget-governor.sh — Track costs and enforce spending limits
# Usage: ./budget-governor.sh [--status | --log <service> <cost> | --check <amount>]
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

WS="/Volumes/Expansion/CMO-10million"
BUDGET_DIR="$WS/OpenClawData/budget"
LOG="$WS/OpenClawData/logs/budget.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')
MONTH=$(date '+%Y-%m')

mkdir -p "$BUDGET_DIR"
log() { echo "[$TS] $1" >> "$LOG"; echo "$1"; }

# Budget caps
DAILY_CAP=5.00
MONTHLY_CAP=50.00

SPEND_LOG="$BUDGET_DIR/spend-$MONTH.jsonl"
touch "$SPEND_LOG"

ACTION="${1:---status}"

get_total() {
  local PERIOD_FILE="$1"
  python3 -c "
total = 0
for line in open('$PERIOD_FILE'):
    import json
    try: total += json.loads(line.strip()).get('cost', 0)
    except: pass
print(f'{total:.2f}')
" 2>/dev/null || echo "0.00"
}

case "$ACTION" in
  --status)
    MONTHLY_TOTAL=$(get_total "$SPEND_LOG")
    # Today's spend
    TODAY_TOTAL=$(python3 -c "
import json
total = 0
for line in open('$SPEND_LOG'):
    try:
        e = json.loads(line.strip())
        if e.get('date','') == '$DATE': total += e.get('cost', 0)
    except: pass
print(f'{total:.2f}')
" 2>/dev/null || echo "0.00")
    
    log "=== Budget Status ==="
    log "  Today: \$$TODAY_TOTAL / \$$DAILY_CAP"
    log "  Month: \$$MONTHLY_TOTAL / \$$MONTHLY_CAP"
    log "  Local models: \$0 (Ollama)"
    
    # Alerts
    python3 -c "
today = float('$TODAY_TOTAL')
month = float('$MONTHLY_TOTAL')
dcap = float('$DAILY_CAP')
mcap = float('$MONTHLY_CAP')
if today >= dcap: print('  ⛔ DAILY CAP REACHED')
elif today >= dcap * 0.8: print('  ⚠️ DAILY 80% WARNING')
if month >= mcap: print('  ⛔ MONTHLY CAP REACHED')
elif month >= mcap * 0.8: print('  ⚠️ MONTHLY 80% WARNING')
if today == 0 and month == 0: print('  ✅ All local, zero cost')
" 2>/dev/null
    ;;

  --log)
    SERVICE="${2:?Missing service name}"
    COST="${3:?Missing cost amount}"
    echo "{\"date\":\"$DATE\",\"time\":\"$TS\",\"service\":\"$SERVICE\",\"cost\":$COST}" >> "$SPEND_LOG"
    log "Logged: $SERVICE \$$COST"
    ;;

  --check)
    AMOUNT="${2:?Missing amount to check}"
    TODAY_TOTAL=$(python3 -c "
import json
total = 0
for line in open('$SPEND_LOG'):
    try:
        e = json.loads(line.strip())
        if e.get('date','') == '$DATE': total += e.get('cost', 0)
    except: pass
print(f'{total:.2f}')
" 2>/dev/null || echo "0.00")
    
    WOULD_BE=$(python3 -c "print(f'{float(\"$TODAY_TOTAL\") + float(\"$AMOUNT\"):.2f}')" 2>/dev/null)
    if python3 -c "exit(0 if float('$WOULD_BE') <= float('$DAILY_CAP') else 1)" 2>/dev/null; then
      echo "APPROVED"
      log "Budget check: \$$AMOUNT approved (total would be \$$WOULD_BE)"
    else
      echo "DENIED"
      log "Budget check: \$$AMOUNT DENIED (would exceed daily cap \$$DAILY_CAP)"
    fi
    ;;
esac
