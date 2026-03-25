#!/bin/bash
# workspace-guard.sh — REAL enforcement: validates paths before file operations
# Usage: ./workspace-guard.sh <path-to-check>
# Exit codes: 0 = allowed, 1 = blocked
# This is ACTUAL enforcement, not prompt guidance.

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/workspace-guard.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ -z "$1" ]; then
    echo "ERROR: No path provided"
    echo "Usage: $0 <path-to-check>"
    exit 1
fi

TARGET_PATH="$1"

# Resolve to absolute path (handle relative paths)
if [[ "$TARGET_PATH" != /* ]]; then
    TARGET_PATH="$(cd "$(dirname "$TARGET_PATH")" 2>/dev/null && pwd)/$(basename "$TARGET_PATH")"
fi

# Check 1: Is the external drive mounted?
if [ ! -d "$WORKSPACE_ROOT" ]; then
    echo "BLOCKED: External drive not mounted at $WORKSPACE_ROOT"
    echo "[$TIMESTAMP] BLOCKED: Drive not mounted. Attempted: $TARGET_PATH" >> "$LOG_FILE" 2>/dev/null
    exit 1
fi

# Check 2: Is the target inside the workspace?
case "$TARGET_PATH" in
    "$WORKSPACE_ROOT"/*)
        # Inside workspace — check for read-only areas
        case "$TARGET_PATH" in
            "$WORKSPACE_ROOT"/OllamaModels/*)
                echo "BLOCKED: OllamaModels is read-only (managed by Ollama)"
                echo "[$TIMESTAMP] BLOCKED: Read-only area. Path: $TARGET_PATH" >> "$LOG_FILE"
                exit 1
                ;;
            *)
                echo "ALLOWED: $TARGET_PATH"
                echo "[$TIMESTAMP] ALLOWED: $TARGET_PATH" >> "$LOG_FILE"
                exit 0
                ;;
        esac
        ;;
    *)
        echo "BLOCKED: Path is outside workspace root ($WORKSPACE_ROOT)"
        echo "[$TIMESTAMP] BLOCKED: Outside workspace. Path: $TARGET_PATH" >> "$LOG_FILE"
        exit 1
        ;;
esac
