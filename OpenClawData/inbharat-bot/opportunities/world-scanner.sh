#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# world-scanner.sh — Global Opportunity Scanner
# Searches government, corporate, and global opportunities
# Usage: ./world-scanner.sh [all|government|corporate|global|grants|custom "query"]
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -uo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
SKILLS_DIR="$BOT_ROOT/skills"
REPORTS_DIR="$BOT_ROOT/opportunities/reports"
SCAN_LOG_DIR="$BOT_ROOT/opportunities/log"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"
DATE=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

source "$BOT_ROOT/logging/bot-logger.sh"

mkdir -p "$REPORTS_DIR" "$SCAN_LOG_DIR"

SCAN_MODE="${1:-all}"
CUSTOM_QUERY="${2:-}"

bot_log "world-scanner" "info" "=== World Scanner started — mode: $SCAN_MODE ==="

# ── Check Ollama ──
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
  bot_log "world-scanner" "error" "Ollama not running"
  exit 1
fi

# ── DuckDuckGo HTML Search ──
# Returns text snippets from search results
ddg_search() {
  local QUERY="$1"
  local RESULT=""

  # Use DuckDuckGo lite (text-only endpoint)
  RESULT=$(curl -s --max-time 15 \
    -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" \
    "https://lite.duckduckgo.com/lite/?q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$QUERY'))")" \
    2>/dev/null \
    | python3 -c "
import sys, re, html

content = sys.stdin.read()

# Extract text snippets from DuckDuckGo lite results
# Remove HTML tags but keep text content
text = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.DOTALL)
text = re.sub(r'<style[^>]*>.*?</style>', '', content, flags=re.DOTALL)
text = re.sub(r'<[^>]+>', ' ', text)
text = html.unescape(text)

# Clean whitespace
lines = [l.strip() for l in text.split('\n') if l.strip() and len(l.strip()) > 20]

# Skip navigation/header lines, take result snippets
results = []
skip_words = ['DuckDuckGo', 'Privacy', 'Settings', 'About', 'Submit']
for line in lines:
    if any(sw in line for sw in skip_words):
        continue
    if len(line) > 30:
        results.append(line[:300])

# Return up to 15 result snippets
for r in results[:15]:
    print(r)
" 2>/dev/null)

  echo "$RESULT"
}

# ── Define search queries by category ──
declare -a GOV_INDIA_QUERIES=(
  "India government AI tender 2026 education technology"
  "GeM portal AI software procurement India 2026"
  "ICDS Anganwadi digital technology tender RFP"
  "Digital India AI projects education health 2026"
  "Smart Cities Mission AI technology requirements India"
  "India government startup scheme AI technology 2026"
  "MeitY AI project funding India"
  "National Education Policy NEP AI technology implementation"
)

declare -a GOV_GLOBAL_QUERIES=(
  "UN UNICEF AI education developing countries 2026"
  "World Bank technology education healthcare project 2026"
  "USAID digital development AI education grant"
  "Asian Development Bank AI technology project India"
  "Bill Gates Foundation AI education India 2026"
  "international development AI tools rural areas"
)

declare -a CORPORATE_QUERIES=(
  "Indian edtech company AI partnership 2026"
  "India healthcare AI startup partnership opportunity"
  "enterprise AI tools India company looking partner"
  "Indian government contractor AI technology partner"
  "education technology company India hiring AI"
  "CSR AI education India rural development corporate"
)

declare -a GLOBAL_QUERIES=(
  "open source AI education tools project 2026"
  "AI agent platform open source community contribution"
  "Google AI for Social Good grants 2026"
  "Microsoft AI for Good education grant application"
  "AI startup accelerator India application 2026"
  "open source AI grants funding 2026"
)

declare -a GRANT_QUERIES=(
  "startup India scheme AI company registration benefits"
  "NASSCOM AI startup funding program 2026"
  "Indian government grant AI startup 2026"
  "Gates Foundation Grand Challenges AI health India"
  "AI research grant developing countries 2026"
  "social enterprise AI funding India"
)

declare -a PROBLEMS_QUERIES=(
  "site:github.com issues label:help-wanted AI education tools"
  "site:github.com issues label:good-first-issue machine learning education"
  "site:github.com issues AI agent platform bug open"
  "education technology broken problem needs fixing 2026"
  "AI chatbot problems users complaining bad experience"
  "rural healthcare app issues bugs India technology"
  "government portal usability problems India digital services"
  "open source AI tools missing features requests"
)

declare -a PROJECTS_QUERIES=(
  "small company looking for AI developer partner India"
  "startup needs AI integration education platform"
  "indie developer building education app looking for help"
  "small business AI automation need freelance India"
  "site:producthunt.com AI education tool India 2026"
  "site:indiehackers.com AI education startup building"
  "nonprofit needs technology help education India rural"
  "small edtech company hiring AI engineer India remote"
)

# ── Run search queries for a category ──
run_category_search() {
  local CATEGORY="$1"
  shift
  local -a QUERIES=("$@")
  local ALL_RESULTS=""

  bot_log "world-scanner" "info" "Scanning category: $CATEGORY (${#QUERIES[@]} queries)"

  for QUERY in "${QUERIES[@]}"; do
    bot_log "world-scanner" "info" "  Searching: $QUERY"
    RESULT=$(ddg_search "$QUERY")
    if [ -n "$RESULT" ]; then
      ALL_RESULTS+="
--- Search: $QUERY ---
$RESULT
"
    fi
    # Brief pause to avoid rate limiting
    sleep 1
  done

  echo "$ALL_RESULTS"
}

# ── Collect search results based on mode ──
SEARCH_RESULTS=""

case "$SCAN_MODE" in
  all)
    echo "━━━ WORLD SCANNER — Full Scan ━━━"
    echo "Scanning all categories... (this takes 3-6 minutes)"
    echo ""
    SEARCH_RESULTS+=$(run_category_search "GOVERNMENT-INDIA" "${GOV_INDIA_QUERIES[@]}")
    SEARCH_RESULTS+=$(run_category_search "GOVERNMENT-GLOBAL" "${GOV_GLOBAL_QUERIES[@]}")
    SEARCH_RESULTS+=$(run_category_search "CORPORATE" "${CORPORATE_QUERIES[@]}")
    SEARCH_RESULTS+=$(run_category_search "GLOBAL-OPPORTUNITIES" "${GLOBAL_QUERIES[@]}")
    SEARCH_RESULTS+=$(run_category_search "GRANTS-FUNDING" "${GRANT_QUERIES[@]}")
    SEARCH_RESULTS+=$(run_category_search "PROBLEMS-TO-SOLVE" "${PROBLEMS_QUERIES[@]}")
    SEARCH_RESULTS+=$(run_category_search "SMALL-COMPANY-PROJECTS" "${PROJECTS_QUERIES[@]}")
    ;;
  government)
    echo "━━━ WORLD SCANNER — Government ━━━"
    SEARCH_RESULTS+=$(run_category_search "GOVERNMENT-INDIA" "${GOV_INDIA_QUERIES[@]}")
    SEARCH_RESULTS+=$(run_category_search "GOVERNMENT-GLOBAL" "${GOV_GLOBAL_QUERIES[@]}")
    ;;
  corporate)
    echo "━━━ WORLD SCANNER — Corporate ━━━"
    SEARCH_RESULTS+=$(run_category_search "CORPORATE" "${CORPORATE_QUERIES[@]}")
    ;;
  global)
    echo "━━━ WORLD SCANNER — Global Opportunities ━━━"
    SEARCH_RESULTS+=$(run_category_search "GLOBAL-OPPORTUNITIES" "${GLOBAL_QUERIES[@]}")
    SEARCH_RESULTS+=$(run_category_search "GRANTS-FUNDING" "${GRANT_QUERIES[@]}")
    ;;
  grants)
    echo "━━━ WORLD SCANNER — Grants & Funding ━━━"
    SEARCH_RESULTS+=$(run_category_search "GRANTS-FUNDING" "${GRANT_QUERIES[@]}")
    ;;
  problems)
    echo "━━━ WORLD SCANNER — Problems to Solve ━━━"
    SEARCH_RESULTS+=$(run_category_search "PROBLEMS-TO-SOLVE" "${PROBLEMS_QUERIES[@]}")
    ;;
  projects)
    echo "━━━ WORLD SCANNER — Small Company Projects ━━━"
    SEARCH_RESULTS+=$(run_category_search "SMALL-COMPANY-PROJECTS" "${PROJECTS_QUERIES[@]}")
    ;;
  buildable)
    echo "━━━ WORLD SCANNER — Buildable Opportunities ━━━"
    echo "Scanning problems + projects + open source..."
    SEARCH_RESULTS+=$(run_category_search "PROBLEMS-TO-SOLVE" "${PROBLEMS_QUERIES[@]}")
    SEARCH_RESULTS+=$(run_category_search "SMALL-COMPANY-PROJECTS" "${PROJECTS_QUERIES[@]}")
    SEARCH_RESULTS+=$(run_category_search "GLOBAL-OPPORTUNITIES" "${GLOBAL_QUERIES[@]}")
    ;;
  custom)
    if [ -z "$CUSTOM_QUERY" ]; then
      echo "Usage: world-scanner.sh custom \"your search query\""
      exit 1
    fi
    echo "━━━ WORLD SCANNER — Custom: $CUSTOM_QUERY ━━━"
    SEARCH_RESULTS+=$(run_category_search "CUSTOM" "$CUSTOM_QUERY")
    ;;
  *)
    echo "Usage: world-scanner.sh [all|government|corporate|global|grants|problems|projects|buildable|custom \"query\"]"
    exit 1
    ;;
esac

# ── Check if we got any results ──
RESULT_LENGTH=${#SEARCH_RESULTS}
if [ "$RESULT_LENGTH" -lt 100 ]; then
  bot_log "world-scanner" "warn" "Very few search results returned ($RESULT_LENGTH chars). Internet may be down."
  echo ""
  echo "⚠ Limited search results. Check internet connection."
  echo "Raw results saved for debugging."
  echo "$SEARCH_RESULTS" > "$SCAN_LOG_DIR/raw-results-${TIMESTAMP}.txt"
  exit 1
fi

# Save raw results for audit trail
echo "$SEARCH_RESULTS" > "$SCAN_LOG_DIR/raw-results-${TIMESTAMP}.txt"
bot_log "world-scanner" "info" "Collected $RESULT_LENGTH chars of search results"

# ── Load skill instructions ──
SKILL_FILE="$SKILLS_DIR/world-scanner/SKILL.md"
SKILL_BODY=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$SKILL_FILE")

# ── Truncate results if too long for context window ──
# qwen3:8b has ~8k effective context; keep search results under 4000 chars
if [ "$RESULT_LENGTH" -gt 4000 ]; then
  SEARCH_RESULTS="${SEARCH_RESULTS:0:4000}

[... truncated for context window — ${RESULT_LENGTH} total chars collected]"
fi

# ── Build prompt ──
PROMPT="$SKILL_BODY

---

TODAY'S DATE: $DATE
SCAN MODE: $SCAN_MODE

SEARCH RESULTS FROM WEB:
$SEARCH_RESULTS

---

TASK: Analyze these search results and produce a World Scan Report in the format specified above.

Rules:
- ONLY report opportunities that appear in the search results above. Do NOT invent opportunities.
- If a search result mentions a specific scheme, tender, company, or program — include it with the source text.
- If results are thin, say so honestly. Do not pad with generic advice.
- Evaluate each opportunity against InBharat AI's actual products and stage.
- Maximum 10 opportunities. Quality over quantity.
- Include the Recommendations section with exactly 3 specific next actions.

Output the complete report in markdown."

# ── Call Ollama ──
bot_log "world-scanner" "info" "Analyzing results via $MODEL..."
echo "Analyzing opportunities..."

RESPONSE=$(curl -s --max-time 180 "$OLLAMA_URL/api/generate" \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.3, num_predict: 3000}}')" \
  | jq -r '(.response // .thinking) // "ERROR: No response from model"')

if [ "$RESPONSE" = "ERROR: No response from model" ] || [ -z "$RESPONSE" ]; then
  bot_log "world-scanner" "error" "Ollama did not respond"
  exit 1
fi

# ── Save report ──
REPORT_FILE="$REPORTS_DIR/world-scan-${DATE}-${SCAN_MODE}.md"
echo "$RESPONSE" > "$REPORT_FILE"

# ── Log scan activity ──
jq -cn \
  --arg date "$DATE" \
  --arg time "$(date '+%H:%M:%S')" \
  --arg mode "$SCAN_MODE" \
  --arg result_chars "$RESULT_LENGTH" \
  --arg report "$REPORT_FILE" \
  --arg status "complete" \
  '{date: $date, time: $time, type: "world-scan", mode: $mode, search_result_chars: $result_chars, report: $report, status: $status}' \
  >> "$SCAN_LOG_DIR/scans-${DATE}.jsonl"

bot_log "world-scanner" "info" "Report saved: $REPORT_FILE"
bot_log_evidence "world-scanner" "opportunity-scan" "$REPORT_FILE" "success"

echo ""
echo "━━━ WORLD SCAN COMPLETE ━━━"
echo "Mode: $SCAN_MODE"
echo "Report: $REPORT_FILE"
echo "Raw data: $SCAN_LOG_DIR/raw-results-${TIMESTAMP}.txt"
echo ""
echo "--- Preview ---"
head -30 "$REPORT_FILE"
echo ""
echo "--- Actions ---"
echo "  Full report: read $REPORT_FILE"
echo "  Draft outreach: bash inbharat-run.sh outreach draft \"<context from report>\""
echo "  Capture lead: bash inbharat-run.sh leads capture \"<lead from report>\""
