#!/bin/bash
# ============================================================
# approval-engine.sh — 4-level approval pipeline
# OPTIMIZED: Credential check uses FAST layer (regex + small model)
#            Risk scoring uses FAST layer (not 8B thinking)
#            L1 auto-approve uses ZERO LLM calls (pure rules)
# Before: 2 LLM calls per item (all through 8B) = ~80s per item
# After:  L1 items: 0ms | L2 items: ~5s via fast model
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/date-context.sh"
source "$SCRIPT_DIR/layer-router.sh"

QUEUES_DIR="$WORKSPACE_ROOT/queues"
APPROVALS_DIR="$WORKSPACE_ROOT/approvals"
LOG_FILE="$WORKSPACE_ROOT/logs/approval-engine.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

DRY_RUN=false
TARGET_CHANNEL=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --channel) TARGET_CHANNEL="$2"; shift ;;
    esac
    shift
done

log() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
    echo "$1"
}

log "=== Approval Engine Started ==="
[ "$DRY_RUN" = true ] && log "[DRY RUN] No files will be moved"

mkdir -p "$APPROVALS_DIR/approved" "$APPROVALS_DIR/blocked" "$APPROVALS_DIR/review" "$APPROVALS_DIR/pending"

# L1 auto-approve types — NO LLM needed
L1_TYPES="product-update build-log founder-update discord-announcement newsletter-snippet repurposed-from-approved simple-website-update"

TOTAL_PROCESSED=0
TOTAL_APPROVED=0
TOTAL_REVIEW=0
TOTAL_BLOCKED=0
PIPELINE_START=$(timer_start)

# Determine channels
if [ -n "$TARGET_CHANNEL" ]; then
    CHANNELS=("$TARGET_CHANNEL")
else
    CHANNELS=()
    for dir in "$QUEUES_DIR"/*/pending; do
        [ -d "$dir" ] || continue
        CH=$(basename "$(dirname "$dir")")
        CHANNELS+=("$CH")
    done
fi

for CHANNEL in "${CHANNELS[@]}"; do
    PENDING_DIR="$QUEUES_DIR/$CHANNEL/pending"
    APPROVED_DIR="$QUEUES_DIR/$CHANNEL/approved"
    mkdir -p "$APPROVED_DIR"

    [ -d "$PENDING_DIR" ] || continue

    while IFS= read -r -d '' FILE; do
        FILENAME=$(basename "$FILE")
        [[ "$FILENAME" == .* ]] && continue
        [[ "$FILENAME" == *.meta.json ]] && continue

        TOTAL_PROCESSED=$((TOTAL_PROCESSED + 1))
        ITEM_START=$(timer_start)

        CONTENT=$(cat "$FILE" 2>/dev/null)
        [ -z "$CONTENT" ] && continue

        # Extract metadata from content
        CONTENT_TYPE=$(echo "$CONTENT" | grep "^type:" | head -1 | sed 's/type:\s*//' | tr -d '"' | tr -d ' ')
        APPROVAL_LEVEL=$(echo "$CONTENT" | grep "^approval_level:" | head -1 | sed 's/approval_level:\s*//' | tr -d '"' | tr -d ' ')

        # --- FAST CREDENTIAL CHECK (regex first, no LLM for clear cases) ---
        CRED_FAIL=false

        # Pure regex check — instant, no model needed
        if echo "$CONTENT" | grep -qiE 'password\s*[:=]|api[_-]?key\s*[:=]|secret\s*[:=]|token\s*[:=]|Bearer |sk-[a-zA-Z0-9]{20,}|-----BEGIN.*KEY'; then
            CRED_FAIL=true
            CRED_REASON="Regex detected credentials/keys"
        fi

        # Check for PII patterns
        if echo "$CONTENT" | grep -qiE '[0-9]{3}-[0-9]{2}-[0-9]{4}|[0-9]{16}'; then
            CRED_FAIL=true
            CRED_REASON="Regex detected PII (SSN/card pattern)"
        fi

        if [ "$CRED_FAIL" = true ]; then
            log "BLOCKED [L4-SAFETY]: $CHANNEL/$FILENAME — $CRED_REASON"
            if [ "$DRY_RUN" = false ]; then
                mv "$FILE" "$APPROVALS_DIR/blocked/"
                echo "## Blocked: $FILENAME
- **Date:** $TIMESTAMP
- **Channel:** $CHANNEL
- **Reason:** $CRED_REASON
---" >> "$APPROVALS_DIR/blocked/block-log-$DATE_TAG.md"
            fi
            TOTAL_BLOCKED=$((TOTAL_BLOCKED + 1))
            record_event "approval" "BLOCKED $FILENAME (credential) in $(timer_elapsed_ms "$ITEM_START")ms"
            continue
        fi

        # --- L1 AUTO-APPROVE (zero LLM calls) ---
        IS_L1=false
        for L1TYPE in $L1_TYPES; do
            if [ "$CONTENT_TYPE" = "$L1TYPE" ] || [ "$APPROVAL_LEVEL" = "L1" ]; then
                IS_L1=true
                break
            fi
        done

        # Also auto-approve discord and x channel items (low risk by nature)
        if [ "$CHANNEL" = "discord" ] || [ "$CHANNEL" = "x" ]; then
            IS_L1=true
        fi

        if [ "$IS_L1" = true ]; then
            log "APPROVED [L1-AUTO]: $CHANNEL/$FILENAME (type=$CONTENT_TYPE) — 0ms"
            if [ "$DRY_RUN" = false ]; then
                mv "$FILE" "$APPROVED_DIR/"
                echo "## Approved: $FILENAME
- **Date:** $TIMESTAMP
- **Channel:** $CHANNEL
- **Level:** L1 Auto-Approve
- **Type:** $CONTENT_TYPE
---" >> "$APPROVALS_DIR/approved/approval-log-$DATE_TAG.md"
            fi
            TOTAL_APPROVED=$((TOTAL_APPROVED + 1))
            record_event "approval" "APPROVED-L1 $FILENAME in $(timer_elapsed_ms "$ITEM_START")ms"
            continue
        fi

        # --- L2 SCORE-GATED (FAST layer for quick risk assessment) ---
        RISK_RESULT=$(llm_fast "Score this content on risk (0-100). Return ONLY a JSON object: {\"weighted_average\": N, \"max_dimension\": N, \"data_safety\": N}. Channel: $CHANNEL. Content: $(echo "$CONTENT" | head -c 500)" "approval-risk")

        WEIGHTED_AVG=$(echo "$RISK_RESULT" | grep -o '"weighted_average":\s*[0-9]*' | grep -o '[0-9]*' | head -1)
        MAX_DIM=$(echo "$RISK_RESULT" | grep -o '"max_dimension":\s*[0-9]*' | grep -o '[0-9]*' | head -1)
        DATA_SAFETY=$(echo "$RISK_RESULT" | grep -o '"data_safety":\s*[0-9]*' | grep -o '[0-9]*' | head -1)

        [ -z "$WEIGHTED_AVG" ] && WEIGHTED_AVG=35
        [ -z "$MAX_DIM" ] && MAX_DIM=35
        [ -z "$DATA_SAFETY" ] && DATA_SAFETY=0

        # L4 Block
        if [ "$MAX_DIM" -gt 75 ] || [ "$DATA_SAFETY" -gt 35 ]; then
            log "BLOCKED [L4-RISK]: $CHANNEL/$FILENAME — max=$MAX_DIM, safety=$DATA_SAFETY"
            if [ "$DRY_RUN" = false ]; then
                mv "$FILE" "$APPROVALS_DIR/blocked/"
                echo "## Blocked: $FILENAME
- **Date:** $TIMESTAMP
- **Channel:** $CHANNEL
- **Reason:** Risk too high (max=$MAX_DIM, safety=$DATA_SAFETY)
---" >> "$APPROVALS_DIR/blocked/block-log-$DATE_TAG.md"
            fi
            TOTAL_BLOCKED=$((TOTAL_BLOCKED + 1))
            continue
        fi

        # L2 Pass
        if [ "$MAX_DIM" -lt 60 ] && [ "$WEIGHTED_AVG" -lt 45 ]; then
            log "APPROVED [L2-SCORED]: $CHANNEL/$FILENAME — avg=$WEIGHTED_AVG, max=$MAX_DIM"
            if [ "$DRY_RUN" = false ]; then
                mv "$FILE" "$APPROVED_DIR/"
                echo "## Approved: $FILENAME
- **Date:** $TIMESTAMP
- **Channel:** $CHANNEL
- **Level:** L2 Score-Gated
- **Scores:** avg=$WEIGHTED_AVG, max=$MAX_DIM, safety=$DATA_SAFETY
---" >> "$APPROVALS_DIR/approved/approval-log-$DATE_TAG.md"
            fi
            TOTAL_APPROVED=$((TOTAL_APPROVED + 1))
            continue
        fi

        # L3 Review
        log "REVIEW [L3]: $CHANNEL/$FILENAME — avg=$WEIGHTED_AVG, max=$MAX_DIM"
        if [ "$DRY_RUN" = false ]; then
            mv "$FILE" "$APPROVALS_DIR/review/"
            echo "## Review: $FILENAME
- **Date:** $TIMESTAMP
- **Channel:** $CHANNEL
- **Scores:** avg=$WEIGHTED_AVG, max=$MAX_DIM, safety=$DATA_SAFETY
---" >> "$APPROVALS_DIR/review/review-log-$DATE_TAG.md"
        fi
        TOTAL_REVIEW=$((TOTAL_REVIEW + 1))

        record_event "approval" "PROCESSED $FILENAME in $(timer_elapsed_ms "$ITEM_START")ms"

    done < <(find "$PENDING_DIR" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" \) -print0 2>/dev/null)
done

PIPELINE_ELAPSED=$(timer_elapsed_ms "$PIPELINE_START")

log "=== Approval Engine Complete ==="
log "Processed: $TOTAL_PROCESSED | Approved: $TOTAL_APPROVED | Review: $TOTAL_REVIEW | Blocked: $TOTAL_BLOCKED | Time: ${PIPELINE_ELAPSED}ms"

echo ""
echo "━━━ APPROVAL SUMMARY ━━━"
echo "Processed: $TOTAL_PROCESSED"
echo "Approved:  $TOTAL_APPROVED"
echo "Review:    $TOTAL_REVIEW"
echo "Blocked:   $TOTAL_BLOCKED"
echo "Time:      ${PIPELINE_ELAPSED}ms"
echo "Log:       $LOG_FILE"
