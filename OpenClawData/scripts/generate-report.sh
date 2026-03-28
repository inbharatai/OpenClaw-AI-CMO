#!/bin/bash
# generate-report.sh — REAL enforcement: generates an evidence-based execution report
# Usage: ./generate-report.sh "<what was done>" [files-changed...]
# This creates ACTUAL report files with real evidence, not prompt guidance.

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
REPORTS_DIR="$WORKSPACE_ROOT/OpenClawData/reports"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
TIMESTAMP_FULL=$(date '+%Y-%m-%d %H:%M:%S')
TIMESTAMP_DATE=$(date '+%Y-%m-%d')

if [ -z "$1" ]; then
    echo "Usage: $0 \"<what was done>\" [file1] [file2] ..."
    echo ""
    echo "Generates an execution report with real file evidence."
    echo "Reports saved to: $REPORTS_DIR/"
    exit 1
fi

DESCRIPTION="$1"
shift
FILES_TO_CHECK=("$@")

SLUG=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | head -c 40)
REPORT_FILE="$REPORTS_DIR/report-$TIMESTAMP_DATE-$SLUG.md"

# Build evidence section
EVIDENCE=""
FILES_SECTION=""
PASS=0
FAIL=0

if [ ${#FILES_TO_CHECK[@]} -gt 0 ]; then
    for FILE in "${FILES_TO_CHECK[@]}"; do
        if [ -f "$FILE" ]; then
            SIZE=$(wc -c < "$FILE" | tr -d ' ')
            LINES=$(wc -l < "$FILE" | tr -d ' ')
            EVIDENCE="$EVIDENCE\n| File verified | \`$FILE\` ($LINES lines, $SIZE bytes) |"
            FILES_SECTION="$FILES_SECTION\n- \`$FILE\` — verified exists ($LINES lines)"
            PASS=$((PASS+1))
        elif [ -d "$FILE" ]; then
            COUNT=$(ls "$FILE" 2>/dev/null | wc -l | tr -d ' ')
            EVIDENCE="$EVIDENCE\n| Directory verified | \`$FILE\` ($COUNT items) |"
            FILES_SECTION="$FILES_SECTION\n- \`$FILE\` — directory verified ($COUNT items)"
            PASS=$((PASS+1))
        else
            EVIDENCE="$EVIDENCE\n| FILE MISSING | \`$FILE\` — NOT FOUND |"
            FILES_SECTION="$FILES_SECTION\n- \`$FILE\` — ❌ NOT FOUND"
            FAIL=$((FAIL+1))
        fi
    done
fi

# System status
OLLAMA_STATUS="❌ Not running"
if curl -s --max-time 3 http://127.0.0.1:11434/api/tags > /dev/null 2>&1; then
    OLLAMA_STATUS="✅ Running"
fi

DRIVE_STATUS="❌ Not mounted"
if [ -d "$WORKSPACE_ROOT" ]; then
    DRIVE_STATUS="✅ Mounted"
fi

# Determine overall status
if [ "$FAIL" -gt 0 ]; then
    STATUS="partial"
elif [ "$PASS" -gt 0 ]; then
    STATUS="completed"
else
    STATUS="completed (no files to verify)"
fi

# Write report
cat > "$REPORT_FILE" << EOF
# Execution Report: $DESCRIPTION

**Date:** $TIMESTAMP_FULL
**Status:** $STATUS

## What Was Done
$DESCRIPTION

## System Status
- Drive: $DRIVE_STATUS
- Ollama: $OLLAMA_STATUS

## Evidence
| Type | Detail |
|---|---|$(echo -e "$EVIDENCE")

## Files
$(echo -e "$FILES_SECTION")

## Verification
- Files checked: $((PASS + FAIL))
- Verified: $PASS
- Missing: $FAIL
EOF

# Verify report was written
if [ -f "$REPORT_FILE" ]; then
    REPORT_LINES=$(wc -l < "$REPORT_FILE" | tr -d ' ')
    echo "✅ Report saved: $REPORT_FILE ($REPORT_LINES lines)"
    echo "   Status: $STATUS | Evidence: $PASS verified, $FAIL missing"
else
    echo "❌ Failed to save report"
    exit 1
fi
