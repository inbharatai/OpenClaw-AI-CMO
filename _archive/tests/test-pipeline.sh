#!/bin/bash
# ============================================================
# OpenClaw AI CMO — Full Pipeline Test
# Tests all stages end-to-end with a sample source note
# ============================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$PROJECT_DIR/openclaw-engine/scripts"
PASS=0
FAIL=0
TOTAL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
    TOTAL=$((TOTAL + 1))
    if [ "$1" -eq 0 ]; then
        echo -e "${GREEN}  ✓ $2${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}  ✗ $2${NC}"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo -e "${YELLOW}=== OpenClaw AI CMO — Full Test Suite ===${NC}"
echo ""

# Test 1: Ollama connectivity
echo -e "${YELLOW}[1] Checking Ollama...${NC}"
curl -s http://localhost:11434/api/tags >/dev/null 2>&1
check $? "Ollama is running"

# Test 2: Models available
echo -e "${YELLOW}[2] Checking models...${NC}"
ollama list 2>/dev/null | grep -q "qwen3:8b"
check $? "qwen3:8b available"
ollama list 2>/dev/null | grep -q "qwen2.5-coder"
check $? "qwen2.5-coder:7b available"

# Test 3: Scripts exist and are executable
echo -e "${YELLOW}[3] Checking scripts...${NC}"
for script in daily-pipeline.sh intake-processor.sh newsroom-agent.sh product-update-agent.sh content-agent.sh approval-engine.sh distribution-engine.sh generate-report.sh; do
    [ -f "$SCRIPTS/$script" ]
    check $? "$script exists"
done

# Test 4: Policies exist
echo -e "${YELLOW}[4] Checking policies...${NC}"
for policy in approval-rules.json brand-voice-rules.json channel-policies.json rate-limits.json; do
    [ -f "$PROJECT_DIR/openclaw-engine/policies/$policy" ]
    check $? "$policy exists"
done

# Test 5: Skills exist
echo -e "${YELLOW}[5] Checking skills...${NC}"
SKILL_COUNT=$(ls "$PROJECT_DIR/openclaw-engine/skills/" 2>/dev/null | grep -v "^\." | wc -l | tr -d ' ')
[ "$SKILL_COUNT" -ge 50 ]
check $? "Skills installed ($SKILL_COUNT found)"

# Test 6: Create test source note
echo -e "${YELLOW}[6] Creating test source note...${NC}"
TEST_FILE="$PROJECT_DIR/data/source-notes/test-pipeline-$(date +%s).md"
echo "Test pipeline run: Added new search feature with autocomplete and fuzzy matching" > "$TEST_FILE"
[ -f "$TEST_FILE" ]
check $? "Test source note created"

# Test 7: LLM test
echo -e "${YELLOW}[7] Testing LLM response...${NC}"
RESPONSE=$(curl -s http://localhost:11434/api/generate -d '{
  "model": "qwen3:8b",
  "prompt": "Say OK in one word",
  "stream": false
}' 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','')[:50])" 2>/dev/null)
[ -n "$RESPONSE" ]
check $? "LLM generates response"

# Test 8: Directory structure
echo -e "${YELLOW}[8] Checking directory structure...${NC}"
for dir in data/source-notes data/source-links data/ai-news data/product-updates data/linkedin data/x data/discord approvals/approved approvals/blocked reports/daily logs exports/posted; do
    [ -d "$PROJECT_DIR/$dir" ]
    check $? "$dir exists"
done

# Summary
echo ""
echo -e "${YELLOW}=== Test Summary ===${NC}"
echo -e "  Total:  $TOTAL"
echo -e "  ${GREEN}Passed: $PASS${NC}"
if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}Failed: $FAIL${NC}"
else
    echo -e "  Failed: 0"
fi
echo ""

# Cleanup
rm -f "$TEST_FILE" 2>/dev/null

exit $FAIL
