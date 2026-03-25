#!/bin/bash
# verify-evidence.sh — REAL enforcement: checks if claimed output files actually exist
# Usage: ./verify-evidence.sh <file1> [file2] [file3] ...
# Exit codes: 0 = all verified, 1 = at least one missing
# This is ACTUAL verification, not prompt guidance.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$WORKSPACE_ROOT/logs/verification.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ -z "$1" ]; then
    echo "Usage: $0 <file1> [file2] [file3] ..."
    echo ""
    echo "Checks whether claimed output files actually exist."
    echo "Also verifies: Ollama status, drive mount, model availability."
    echo ""
    echo "Special checks:"
    echo "  $0 --system    Run full system health check"
    exit 1
fi

PASS=0
FAIL=0
TOTAL=0

# System health check mode
if [ "$1" = "--system" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  SYSTEM VERIFICATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Drive
    TOTAL=$((TOTAL+1))
    if [ -d "$WORKSPACE_ROOT" ]; then
        echo "✅ External drive mounted at $WORKSPACE_ROOT"
        PASS=$((PASS+1))
    else
        echo "❌ External drive NOT mounted"
        FAIL=$((FAIL+1))
    fi

    # Ollama
    TOTAL=$((TOTAL+1))
    if curl -s --max-time 3 http://127.0.0.1:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama running at http://127.0.0.1:11434"
        PASS=$((PASS+1))
    else
        echo "❌ Ollama NOT running"
        FAIL=$((FAIL+1))
    fi

    # Models
    for MODEL in "qwen3:8b" "qwen2.5-coder:7b"; do
        TOTAL=$((TOTAL+1))
        if curl -s --max-time 5 http://127.0.0.1:11434/api/tags 2>/dev/null | grep -q "$MODEL"; then
            echo "✅ Model available: $MODEL"
            PASS=$((PASS+1))
        else
            echo "❌ Model missing: $MODEL"
            FAIL=$((FAIL+1))
        fi
    done

    # Skills symlink
    TOTAL=$((TOTAL+1))
    if [ -L "$HOME/.openclaw/workspace/skills" ]; then
        SKILL_COUNT=$(ls "$HOME/.openclaw/workspace/skills/" 2>/dev/null | wc -l | tr -d ' ')
        echo "✅ Skills symlink active ($SKILL_COUNT skills)"
        PASS=$((PASS+1))
    else
        echo "❌ Skills symlink missing"
        FAIL=$((FAIL+1))
    fi

    # Scripts
    TOTAL=$((TOTAL+1))
    SCRIPT_COUNT=$(ls "$WORKSPACE_ROOT/openclaw-engine/scripts/"*.sh 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SCRIPT_COUNT" -gt 0 ]; then
        echo "✅ Enforcement scripts present ($SCRIPT_COUNT scripts)"
        PASS=$((PASS+1))
    else
        echo "❌ No enforcement scripts found"
        FAIL=$((FAIL+1))
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Result: $PASS/$TOTAL passed"
    echo "[$TIMESTAMP] SYSTEM CHECK: $PASS/$TOTAL passed" >> "$LOG_FILE" 2>/dev/null

    if [ "$FAIL" -gt 0 ]; then
        exit 1
    fi
    exit 0
fi

# File verification mode
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  FILE VERIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for FILE in "$@"; do
    TOTAL=$((TOTAL+1))
    if [ -f "$FILE" ]; then
        SIZE=$(wc -c < "$FILE" | tr -d ' ')
        LINES=$(wc -l < "$FILE" | tr -d ' ')
        echo "✅ EXISTS: $FILE ($LINES lines, $SIZE bytes)"
        PASS=$((PASS+1))
    elif [ -d "$FILE" ]; then
        COUNT=$(ls "$FILE" 2>/dev/null | wc -l | tr -d ' ')
        echo "✅ DIR EXISTS: $FILE ($COUNT items)"
        PASS=$((PASS+1))
    else
        echo "❌ MISSING: $FILE"
        FAIL=$((FAIL+1))
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Result: $PASS/$TOTAL verified"
echo "[$TIMESTAMP] FILE CHECK: $PASS/$TOTAL verified. Files: $*" >> "$LOG_FILE" 2>/dev/null

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
