#!/bin/bash
# ============================================================
# quality-scorer.sh — Content quality gate (separate from risk scoring)
#
# Scores content on: readability, hook strength, CTA clarity,
# platform fit, formatting, uniqueness.
#
# Runs BEFORE approval engine. Low-quality content gets flagged
# for revision, not just blocked for risk.
#
# Uses FAST model (not thinking model) for speed.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/date-context.sh"
source "$SCRIPT_DIR/layer-router.sh"

QUEUES_DIR="$WORKSPACE_ROOT/queues"
LOG_FILE="$WORKSPACE_ROOT/logs/quality-scorer.log"
SCORES_DIR="$WORKSPACE_ROOT/logs/quality-scores"
MIN_SCORE=60

mkdir -p "$SCORES_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

log "=== Quality Scorer Started — $CURRENT_DATE ==="

# Read min score from config if available
CONFIG="$WORKSPACE_ROOT/configs/openclaw.yaml"
if [ -f "$CONFIG" ]; then
    MIN_SCORE=$(python3 -c "
import yaml
with open('$CONFIG') as f:
    cfg = yaml.safe_load(f)
print(cfg.get('quality',{}).get('min_score_to_approve', 60))
" 2>/dev/null)
fi

TOTAL=0
PASSED=0
FLAGGED=0

# Score all pending queue items
for CHANNEL_DIR in "$QUEUES_DIR"/*/pending; do
    [ -d "$CHANNEL_DIR" ] || continue
    CHANNEL=$(basename "$(dirname "$CHANNEL_DIR")")

    while IFS= read -r -d '' FILE; do
        FILENAME=$(basename "$FILE")
        [[ "$FILENAME" == .* ]] && continue
        [[ "$FILENAME" == *.json ]] && continue

        CONTENT=$(cat "$FILE" 2>/dev/null | head -c 1500)
        [ -z "$CONTENT" ] && continue

        TOTAL=$((TOTAL + 1))

        # Use fast model for quality scoring
        SCORE_PROMPT="Score this content for quality on a scale of 0-100.

Evaluate these 6 dimensions (each 0-100):
1. READABILITY: Is it clear, scannable, well-structured?
2. HOOK_STRENGTH: Does the first sentence/line grab attention?
3. CTA_CLARITY: Is there a clear call-to-action or next step?
4. PLATFORM_FIT: Does the format match the target platform ($CHANNEL)?
5. FORMATTING: Headers, bullets, spacing, emoji usage appropriate?
6. UNIQUENESS: Does it feel fresh, not generic/templated?

$DATE_CONTEXT

Content to score:
---
$CONTENT
---

Respond ONLY in this exact JSON format, nothing else:
{\"readability\": <0-100>, \"hook_strength\": <0-100>, \"cta_clarity\": <0-100>, \"platform_fit\": <0-100>, \"formatting\": <0-100>, \"uniqueness\": <0-100>, \"overall\": <0-100>, \"suggestion\": \"<one-line improvement suggestion>\"}
"

        SCORE_RAW=$(llm_fast "$SCORE_PROMPT" 2>/dev/null)

        # Parse JSON from response
        SCORE_JSON=$(echo "$SCORE_RAW" | python3 -c "
import sys, json, re
text = sys.stdin.read()
# Find JSON in response
match = re.search(r'\{[^}]+\}', text, re.DOTALL)
if match:
    try:
        data = json.loads(match.group())
        print(json.dumps(data))
    except:
        print(json.dumps({'overall': 50, 'suggestion': 'Score parse failed', 'parse_error': True}))
else:
    print(json.dumps({'overall': 50, 'suggestion': 'No JSON in response', 'parse_error': True}))
" 2>/dev/null)

        OVERALL=$(echo "$SCORE_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('overall', 50))" 2>/dev/null)
        SUGGESTION=$(echo "$SCORE_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('suggestion', 'none')[:80])" 2>/dev/null)

        # Save score
        SCORE_FILE="$SCORES_DIR/score-$CURRENT_DATE-$CHANNEL-$(echo "$FILENAME" | head -c 40).json"
        python3 -c "
import json
score = json.loads('$(echo "$SCORE_JSON" | sed "s/'/\\\\'/g")')
score['file'] = '$FILE'
score['channel'] = '$CHANNEL'
score['date'] = '$CURRENT_DATE'
score['passed'] = $OVERALL >= $MIN_SCORE
json.dump(score, open('$SCORE_FILE', 'w'), indent=2)
" 2>/dev/null

        if [ "$OVERALL" -ge "$MIN_SCORE" ]; then
            PASSED=$((PASSED + 1))
            log "PASS [$OVERALL/100]: $CHANNEL/$FILENAME"
        else
            FLAGGED=$((FLAGGED + 1))
            log "FLAGGED [$OVERALL/100]: $CHANNEL/$FILENAME — $SUGGESTION"

            # Add quality flag to the file frontmatter
            python3 -c "
content = open('$FILE').read()
if '---' in content:
    parts = content.split('---', 2)
    if len(parts) >= 3:
        parts[1] = parts[1].rstrip() + '\nquality_score: $OVERALL\nquality_flag: needs_improvement\nquality_suggestion: \"$SUGGESTION\"\n'
        open('$FILE', 'w').write('---'.join(parts))
" 2>/dev/null
        fi

    done < <(find "$CHANNEL_DIR" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
done

log "=== Quality Scorer Complete — $TOTAL scored, $PASSED passed, $FLAGGED flagged ==="
echo ""
echo "━━━ QUALITY SCORER SUMMARY ━━━"
echo "Total:   $TOTAL"
echo "Passed:  $PASSED (≥$MIN_SCORE)"
echo "Flagged: $FLAGGED (<$MIN_SCORE)"
