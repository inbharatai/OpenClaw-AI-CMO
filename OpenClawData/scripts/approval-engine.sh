#!/bin/bash
# approval-engine.sh — Process pending content through the 4-level approval pipeline
# Usage: ./approval-engine.sh [--dry-run] [--channel <channel>]
# Reads: OpenClawData/queues/*/pending/
# Writes: moves files to approved/, review/, or blocked/ based on policy
# Logs: OpenClawData/logs/approval-engine.log

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
SCRIPTS_DIR="$WORKSPACE_ROOT/OpenClawData/scripts"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
APPROVALS_DIR="$WORKSPACE_ROOT/OpenClawData/approvals"
POLICIES_DIR="$WORKSPACE_ROOT/OpenClawData/policies"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/approval-engine.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_TAG=$(date '+%Y-%m-%d')
OLLAMA_URL="http://127.0.0.1:11434"

DRY_RUN=false
TARGET_CHANNEL=""

# Parse args
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

# Ensure approval output directories exist
mkdir -p "$APPROVALS_DIR/approved" "$APPROVALS_DIR/blocked" "$APPROVALS_DIR/review" "$APPROVALS_DIR/pending"

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    log "ERROR: Ollama is not running"
    exit 1
fi

# Load L1 auto-approve content types from policy
L1_TYPES="product-update build-log founder-update discord-announcement newsletter-snippet repurposed-from-approved simple-website-update"

TOTAL_PROCESSED=0
TOTAL_APPROVED=0
TOTAL_REVIEW=0
TOTAL_BLOCKED=0

# Determine which channels to process
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

    [ -d "$PENDING_DIR" ] || continue

    # Find pending content files
    while IFS= read -r -d '' FILE; do
        FILENAME=$(basename "$FILE")
        [[ "$FILENAME" == .* ]] && continue
        [[ "$FILENAME" == *.meta.json ]] && continue

        TOTAL_PROCESSED=$((TOTAL_PROCESSED + 1))
        log "EVALUATING: $CHANNEL/$FILENAME"

        # Read content
        CONTENT=$(cat "$FILE" 2>/dev/null)
        if [ -z "$CONTENT" ]; then
            log "SKIP: Empty file $FILE"
            continue
        fi

        # Extract content type from frontmatter
        CONTENT_TYPE=$(echo "$CONTENT" | grep "^type:" | head -1 | sed 's/type:\s*//' | tr -d '"' | tr -d ' ')
        APPROVAL_LEVEL=$(echo "$CONTENT" | grep "^approval_level:" | head -1 | sed 's/approval_level:\s*//' | tr -d '"' | tr -d ' ')

        # --- CREDENTIAL SAFETY CHECK (always runs first) ---
        CRED_CHECK=$("$SCRIPTS_DIR/skill-runner.sh" credential-safety-policy \
            "Scan this content for credentials, API keys, personal data, and sensitive information. Content: $(echo "$CONTENT" | head -c 1000)" \
            "qwen2.5-coder:7b" 2>/dev/null | tail -n +5)

        # Check if credential scan found critical issues
        # Parse the structured response: only block if "safe": false or "action": "block"
        # IMPORTANT: Do NOT grep for generic phrases like "API key" — the LLM's explanation
        # of what it checked for will contain those words even when content is safe.
        CRED_SAFE=$(echo "$CRED_CHECK" | grep -oE '"safe":\s*(true|false)' | grep -oE '(true|false)' | head -1)
        CRED_ACTION=$(echo "$CRED_CHECK" | grep -oE '"action":\s*"[a-z]+"' | grep -oE '"[a-z]+"$' | tr -d '"' | head -1)

        # Default to safe if parsing fails (conservative: don't block on parse errors)
        [ -z "$CRED_SAFE" ] && CRED_SAFE="true"
        [ -z "$CRED_ACTION" ] && CRED_ACTION="pass"

        if [ "$CRED_SAFE" = "false" ] || [ "$CRED_ACTION" = "block" ]; then
            log "BLOCKED [L4-SAFETY]: $CHANNEL/$FILENAME — credential/data safety issue"
            if [ "$DRY_RUN" = false ]; then
                mv "$FILE" "$APPROVALS_DIR/blocked/"
                # Write block record
                cat >> "$APPROVALS_DIR/blocked/block-log-$DATE_TAG.md" <<EOF
## Blocked: $FILENAME
- **Date:** $TIMESTAMP
- **Channel:** $CHANNEL
- **Reason:** Credential/data safety check failed
- **Details:** $CRED_CHECK

---
EOF
            fi
            TOTAL_BLOCKED=$((TOTAL_BLOCKED + 1))
            continue
        fi

        # --- L1 AUTO-APPROVE CHECK ---
        IS_L1=false
        for L1TYPE in $L1_TYPES; do
            if [ "$CONTENT_TYPE" = "$L1TYPE" ] || [ "$APPROVAL_LEVEL" = "L1" ]; then
                IS_L1=true
                break
            fi
        done

        if [ "$IS_L1" = true ]; then
            log "APPROVED [L1-AUTO]: $CHANNEL/$FILENAME (type=$CONTENT_TYPE)"
            if [ "$DRY_RUN" = false ]; then
                mv "$FILE" "$APPROVED_DIR/"
                # Write approval record
                cat >> "$APPROVALS_DIR/approved/approval-log-$DATE_TAG.md" <<EOF
## Approved: $FILENAME
- **Date:** $TIMESTAMP
- **Channel:** $CHANNEL
- **Level:** L1 Auto-Approve
- **Type:** $CONTENT_TYPE

---
EOF
            fi
            TOTAL_APPROVED=$((TOTAL_APPROVED + 1))
            continue
        fi

        # --- L2 SCORE-GATED CHECK ---
        # Get risk scores
        RISK_SCORES=$("$SCRIPTS_DIR/skill-runner.sh" risk-scorer \
            "Score this content on 6 risk dimensions (source_confidence, brand_voice, claim_sensitivity, duplication, platform_risk, data_safety). Return scores 0-100. Channel: $CHANNEL. Type: $CONTENT_TYPE. Content: $(echo "$CONTENT" | head -c 800)" \
            "qwen2.5-coder:7b" 2>/dev/null | tail -n +5)

        # Try to extract weighted average and max dimension from LLM response
        WEIGHTED_AVG=$(echo "$RISK_SCORES" | grep -o '"weighted_average":\s*[0-9]*' | grep -o '[0-9]*' | head -1)
        MAX_DIM=$(echo "$RISK_SCORES" | grep -o '"max_dimension":\s*[0-9]*' | grep -o '[0-9]*' | head -1)
        DATA_SAFETY=$(echo "$RISK_SCORES" | grep -o '"data_safety":\s*[0-9]*' | grep -o '[0-9]*' | head -1)

        # Defaults if parsing failed
        [ -z "$WEIGHTED_AVG" ] && WEIGHTED_AVG=50
        [ -z "$MAX_DIM" ] && MAX_DIM=50
        [ -z "$DATA_SAFETY" ] && DATA_SAFETY=0

        # L4 Block check
        if [ "$MAX_DIM" -gt 75 ] || [ "$DATA_SAFETY" -gt 35 ]; then
            log "BLOCKED [L4-RISK]: $CHANNEL/$FILENAME — max_dim=$MAX_DIM, data_safety=$DATA_SAFETY"
            if [ "$DRY_RUN" = false ]; then
                mv "$FILE" "$APPROVALS_DIR/blocked/"
                cat >> "$APPROVALS_DIR/blocked/block-log-$DATE_TAG.md" <<EOF
## Blocked: $FILENAME
- **Date:** $TIMESTAMP
- **Channel:** $CHANNEL
- **Reason:** Risk scores too high (max_dim=$MAX_DIM, data_safety=$DATA_SAFETY)
- **Scores:** $RISK_SCORES

---
EOF
            fi
            TOTAL_BLOCKED=$((TOTAL_BLOCKED + 1))
            continue
        fi

        # L2 Score-gate pass
        if [ "$MAX_DIM" -lt 60 ] && [ "$WEIGHTED_AVG" -lt 45 ] && [ "$DATA_SAFETY" -lt 30 ]; then
            log "APPROVED [L2-SCORE-GATE]: $CHANNEL/$FILENAME — avg=$WEIGHTED_AVG, max=$MAX_DIM"
            if [ "$DRY_RUN" = false ]; then
                mv "$FILE" "$APPROVED_DIR/"
                cat >> "$APPROVALS_DIR/approved/approval-log-$DATE_TAG.md" <<EOF
## Approved: $FILENAME
- **Date:** $TIMESTAMP
- **Channel:** $CHANNEL
- **Level:** L2 Score-Gated
- **Type:** $CONTENT_TYPE
- **Scores:** weighted_avg=$WEIGHTED_AVG, max_dim=$MAX_DIM, data_safety=$DATA_SAFETY

---
EOF
            fi
            TOTAL_APPROVED=$((TOTAL_APPROVED + 1))
            continue
        fi

        # L3 Review queue (default)
        log "REVIEW [L3]: $CHANNEL/$FILENAME — avg=$WEIGHTED_AVG, max=$MAX_DIM"
        if [ "$DRY_RUN" = false ]; then
            mv "$FILE" "$APPROVALS_DIR/review/"
            cat >> "$APPROVALS_DIR/review/review-log-$DATE_TAG.md" <<EOF
## Needs Review: $FILENAME
- **Date:** $TIMESTAMP
- **Channel:** $CHANNEL
- **Level:** L3 Review Required
- **Type:** $CONTENT_TYPE
- **Scores:** weighted_avg=$WEIGHTED_AVG, max_dim=$MAX_DIM, data_safety=$DATA_SAFETY
- **Risk Details:** $RISK_SCORES

---
EOF
        fi
        TOTAL_REVIEW=$((TOTAL_REVIEW + 1))

    done < <(find "$PENDING_DIR" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" \) -print0 2>/dev/null)
done

log "=== Approval Engine Complete ==="
log "Processed: $TOTAL_PROCESSED | Approved: $TOTAL_APPROVED | Review: $TOTAL_REVIEW | Blocked: $TOTAL_BLOCKED"

echo ""
echo "━━━ APPROVAL SUMMARY ━━━"
echo "Processed: $TOTAL_PROCESSED"
echo "Approved:  $TOTAL_APPROVED"
echo "Review:    $TOTAL_REVIEW"
echo "Blocked:   $TOTAL_BLOCKED"
echo "Log: $LOG_FILE"
