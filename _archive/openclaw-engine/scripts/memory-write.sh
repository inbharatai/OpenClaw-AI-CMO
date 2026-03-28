#!/bin/bash
# memory-write.sh — REAL enforcement: writes a memory entry to the correct category file
# Usage: ./memory-write.sh <category> "<title>" "<content>"
# Categories: brand-voice, campaign-preferences, prompt-templates, recurring-instructions,
#             lessons-learned, decisions-log, project-context
# This creates ACTUAL files, not prompt guidance.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MEMORY_DIR="$WORKSPACE_ROOT/openclaw-engine/memory"
TIMESTAMP=$(date '+%Y-%m-%d')

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <category> \"<title>\" \"<content>\""
    echo ""
    echo "Categories:"
    echo "  brand-voice"
    echo "  campaign-preferences"
    echo "  prompt-templates"
    echo "  recurring-instructions"
    echo "  lessons-learned"
    echo "  decisions-log"
    echo "  project-context"
    exit 1
fi

CATEGORY="$1"
TITLE="$2"
CONTENT="$3"

# Validate category
VALID_CATEGORIES="brand-voice campaign-preferences prompt-templates recurring-instructions lessons-learned decisions-log project-context"
if ! echo "$VALID_CATEGORIES" | grep -qw "$CATEGORY"; then
    echo "ERROR: Invalid category '$CATEGORY'"
    echo "Valid categories: $VALID_CATEGORIES"
    exit 1
fi

FILE="$MEMORY_DIR/$CATEGORY.md"

# Check workspace guard
GUARD_RESULT=$("$WORKSPACE_ROOT/openclaw-engine/scripts/workspace-guard.sh" "$FILE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "BLOCKED by workspace guard: $GUARD_RESULT"
    exit 1
fi

# Create file with header if it doesn't exist
if [ ! -f "$FILE" ]; then
    echo "# $(echo "$CATEGORY" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')" > "$FILE"
    echo "" >> "$FILE"
fi

# Append entry
cat >> "$FILE" << EOF

## [$TIMESTAMP] $TITLE

**Category:** $CATEGORY
**Source:** manual entry via memory-write.sh

$CONTENT

---
EOF

# Verify
if [ -f "$FILE" ]; then
    LINES=$(wc -l < "$FILE" | tr -d ' ')
    echo "SAVED: $FILE ($LINES lines)"
    echo "Entry: [$TIMESTAMP] $TITLE"
else
    echo "ERROR: Failed to write to $FILE"
    exit 1
fi
