#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# lead-researcher.sh — Research a VC/company/investor target
# Usage: ./lead-researcher.sh "<company or VC name>"
# Output: Research file in outreach/research/<company-slug>.md
# Uses DuckDuckGo for web search + Ollama qwen3:8b for summarization
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -uo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
RESEARCH_DIR="$BOT_ROOT/outreach/research"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"
DATE=$(date '+%Y-%m-%d')
OUTREACH_LOG_DIR="$BOT_ROOT/outreach/log"

source "$BOT_ROOT/logging/bot-logger.sh"

mkdir -p "$RESEARCH_DIR" "$OUTREACH_LOG_DIR"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: lead-researcher.sh \"<company or VC name>\""
  echo ""
  echo "Example:"
  echo "  ./lead-researcher.sh \"Blume Ventures\""
  echo "  ./lead-researcher.sh \"a16z\""
  echo "  ./lead-researcher.sh \"Sarvam AI\""
  exit 1
fi

# Generate slug for filename
SLUG=$(echo "$TARGET" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
SLUG="${SLUG:0:50}"
RESEARCH_FILE="$RESEARCH_DIR/${SLUG}.md"

bot_log "lead-researcher" "info" "=== Researching: $TARGET ==="

# ── Step 1: Web search via DuckDuckGo HTML API ──

echo "Searching for information on: $TARGET..."

# DuckDuckGo search function (HTML scraping - no API key needed)
ddg_search() {
  local QUERY="$1"
  local ENCODED_QUERY
  export DDG_QUERY="$QUERY"
  ENCODED_QUERY=$(python3 -c "import urllib.parse, os; print(urllib.parse.quote(os.environ['DDG_QUERY']))" 2>/dev/null || echo "$QUERY")
  curl -s --max-time 15 \
    -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
    "https://html.duckduckgo.com/html/?q=${ENCODED_QUERY}" 2>/dev/null \
    | python3 -c "
import sys, re, html as h
text = sys.stdin.read()
# Extract result snippets
results = re.findall(r'class=\"result__snippet\"[^>]*>(.*?)</a>', text, re.DOTALL)
for i, r in enumerate(results[:8]):
    clean = re.sub(r'<[^>]+>', '', r)
    clean = h.unescape(clean).strip()
    if clean:
        print(f'- {clean}')
" 2>/dev/null || echo "- Search returned no results"
}

# Run multiple searches in parallel to gather information
SEARCH_RESULTS=""

# Search 1: Recent funding and news
echo "  [1/4] Searching funding activity..."
RESULT1=$(ddg_search "$TARGET AI funding investment 2025 2026")
SEARCH_RESULTS+="
## Recent Funding & News
$RESULT1
"

# Search 2: AI portfolio and investments
echo "  [2/4] Searching portfolio/products..."
RESULT2=$(ddg_search "$TARGET AI portfolio companies investments startups")
SEARCH_RESULTS+="
## Portfolio / Products
$RESULT2
"

# Search 3: Key people and decision makers
echo "  [3/4] Searching key people..."
RESULT3=$(ddg_search "$TARGET partners founders team leadership AI")
SEARCH_RESULTS+="
## Key People
$RESULT3
"

# Search 4: Application or pitch process
echo "  [4/4] Searching pitch/application process..."
RESULT4=$(ddg_search "$TARGET pitch startup application apply how to reach")
SEARCH_RESULTS+="
## Application / Pitch Process
$RESULT4
"

if [ -z "$SEARCH_RESULTS" ] || [ "$SEARCH_RESULTS" = "$(printf '\n## Recent Funding & News\n\n## Portfolio / Products\n\n## Key People\n\n## Application / Pitch Process\n')" ]; then
  bot_log "lead-researcher" "warn" "Web search returned minimal results for $TARGET"
  SEARCH_RESULTS="Note: Web search returned limited results. Manual research recommended."
fi

# ── Step 2: Check if target exists in our lead databases ──

EXISTING_DATA=""
for LEAD_FILE in "$BOT_ROOT/outreach/leads"/*.json; do
  [ ! -f "$LEAD_FILE" ] && continue
  MATCH=$(jq -r --arg name "$TARGET" '
    .leads[] | select(
      (.firm // .company // .name) | ascii_downcase | contains($name | ascii_downcase)
    ) | tostring' "$LEAD_FILE" 2>/dev/null)
  if [ -n "$MATCH" ]; then
    EXISTING_DATA="$MATCH"
    break
  fi
done

# ── Step 3: Summarize with Ollama ──

echo "  Generating AI summary..."

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
  bot_log "lead-researcher" "warn" "Ollama not running — saving raw research only"

  # Save raw research without AI summary
  cat > "$RESEARCH_FILE" << RAWEOF
# Research: $TARGET
**Date:** $DATE
**Status:** Raw (Ollama unavailable for summary)

## Existing Lead Data
\`\`\`
${EXISTING_DATA:-No existing data in lead databases}
\`\`\`

$SEARCH_RESULTS

---
*Raw research — AI summary pending. Run again when Ollama is available.*
RAWEOF

  echo ""
  echo "Research saved (raw): $RESEARCH_FILE"
  exit 0
fi

SUMMARY_PROMPT="You are a startup research analyst. Analyze the following web search results about \"$TARGET\" and produce a structured research brief.

EXISTING DATA FROM OUR DATABASE:
${EXISTING_DATA:-None}

WEB SEARCH RESULTS:
$SEARCH_RESULTS

---

Produce a research brief in this exact markdown format:

# Research Brief: $TARGET
**Date:** $DATE
**Researcher:** InBharat Bot (Automated)

## Overview
[1-2 sentence summary of who they are and what they do]

## Investment/Business Focus
[Key focus areas, sectors, check sizes if VC]

## Recent Activity
[Notable recent investments, news, or activities from the search results]

## Key Decision Makers
[Names and roles found in search results — only include if actually found]

## How to Reach Them
[Application process, pitch guidelines, contact methods found]

## Relevance to InBharat AI
[Why they might be interested in InBharat AI, which of our products align with their interests]

## Recommended Approach
[Suggested outreach strategy: which template, what angle, timing]

## Raw Search Data
[Include a condensed version of search results for reference]

---
IMPORTANT: Only state facts found in the search results. If information is not available, say 'Not found in search results' rather than making assumptions."

RESPONSE=$(curl -s --max-time 180 "$OLLAMA_URL/api/generate" \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$SUMMARY_PROMPT" \
  '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.3, num_predict: 3000}}')" \
  | jq -r '(.response // "") | gsub("^<think>[\\s\\S]*?</think>\\s*"; "")' 2>/dev/null)

if [ -z "$RESPONSE" ] || [ "$RESPONSE" = "null" ]; then
  bot_log "lead-researcher" "warn" "Ollama returned empty response — saving raw research"
  cat > "$RESEARCH_FILE" << RAWEOF2
# Research: $TARGET
**Date:** $DATE
**Status:** Raw (AI summary failed)

## Existing Lead Data
\`\`\`
${EXISTING_DATA:-No existing data in lead databases}
\`\`\`

$SEARCH_RESULTS
RAWEOF2
else
  echo "$RESPONSE" > "$RESEARCH_FILE"
fi

# ── Step 4: Log the research activity ──

jq -cn \
  --arg date "$DATE" \
  --arg time "$(date '+%H:%M:%S')" \
  --arg type "lead-research" \
  --arg target "$TARGET" \
  --arg file "$RESEARCH_FILE" \
  --arg status "completed" \
  '{date: $date, time: $time, type: $type, target: $target, research_file: $file, status: $status}' \
  >> "$OUTREACH_LOG_DIR/outreach-${DATE}.jsonl"

bot_log "lead-researcher" "info" "Research saved: $RESEARCH_FILE"

echo ""
echo "━━━ RESEARCH COMPLETE ━━━"
echo "Target: $TARGET"
echo "File:   $RESEARCH_FILE"
echo ""
echo "--- Preview ---"
head -25 "$RESEARCH_FILE"
echo ""
echo "--- Next Steps ---"
echo "  Full report: cat $RESEARCH_FILE"
echo "  Draft email: ./outreach-engine.sh draft vc-cold-intro vc-india.json --limit 1"
echo "  Research another: ./lead-researcher.sh \"<company name>\""
