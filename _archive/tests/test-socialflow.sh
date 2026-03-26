#!/bin/bash
# ============================================================
# SocialFlow — Health and API Test
# Requires SocialFlow to be running on localhost:8000
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    if [ "$1" -eq 0 ]; then
        echo -e "${GREEN}  ✓ $2${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}  ✗ $2${NC}"
        FAIL=$((FAIL + 1))
    fi
}

echo -e "${YELLOW}=== SocialFlow API Tests ===${NC}"
echo ""

# Health check
echo -e "${YELLOW}[1] Health check...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health 2>/dev/null)
[ "$HTTP_CODE" = "200" ]
check $? "Health endpoint returns 200"

# Platform status
echo -e "${YELLOW}[2] Platform status...${NC}"
STATUS=$(curl -s http://localhost:8000/api/openclaw/status 2>/dev/null)
echo "$STATUS" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'platforms' in d" 2>/dev/null
check $? "Platform status endpoint works"

# Dry run publish
echo -e "${YELLOW}[3] Dry run publish...${NC}"
RESULT=$(curl -s -X POST http://localhost:8000/api/openclaw/publish \
    -H "Content-Type: application/json" \
    -d '{"platform":"linkedin","content":"Test post from OpenClaw pipeline test","content_type":"test","dry_run":true}' 2>/dev/null)
echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d.get('success')==True" 2>/dev/null
check $? "Dry run publish validates successfully"

# History endpoint
echo -e "${YELLOW}[4] History endpoint...${NC}"
HISTORY=$(curl -s http://localhost:8000/api/openclaw/history 2>/dev/null)
echo "$HISTORY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'events' in d" 2>/dev/null
check $? "History endpoint works"

# Summary
echo ""
echo -e "${YELLOW}=== Results ===${NC}"
echo -e "  ${GREEN}Passed: $PASS${NC}"
[ "$FAIL" -gt 0 ] && echo -e "  ${RED}Failed: $FAIL${NC}" || echo "  Failed: 0"
echo ""
