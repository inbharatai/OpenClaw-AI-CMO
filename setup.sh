#!/bin/bash
# ============================================================
# OpenClaw AI CMO — Setup Script
# One-command setup for the complete AI CMO system
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}       OpenClaw AI CMO — Setup                             ${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# ---- Check prerequisites ----
echo -e "${YELLOW}[1/7] Checking prerequisites...${NC}"

MISSING=0

if ! command -v ollama &>/dev/null; then
    echo -e "${RED}  ✗ Ollama not found. Install from https://ollama.com${NC}"
    MISSING=1
else
    echo -e "${GREEN}  ✓ Ollama found${NC}"
fi

if ! command -v python3 &>/dev/null; then
    echo -e "${RED}  ✗ Python 3 not found${NC}"
    MISSING=1
else
    PYVER=$(python3 --version 2>&1)
    echo -e "${GREEN}  ✓ $PYVER${NC}"
fi

if ! command -v pip3 &>/dev/null && ! command -v pip &>/dev/null; then
    echo -e "${YELLOW}  ! pip not found (will try python3 -m pip)${NC}"
else
    echo -e "${GREEN}  ✓ pip found${NC}"
fi

if [ "$MISSING" -eq 1 ]; then
    echo -e "${RED}Missing prerequisites. Install them and re-run setup.${NC}"
    exit 1
fi

# ---- Pull Ollama models ----
echo ""
echo -e "${YELLOW}[2/7] Pulling Ollama models...${NC}"

if ollama list 2>/dev/null | grep -q "qwen3:8b"; then
    echo -e "${GREEN}  ✓ qwen3:8b already available${NC}"
else
    echo -e "${BLUE}  Pulling qwen3:8b (this may take a few minutes)...${NC}"
    ollama pull qwen3:8b
    echo -e "${GREEN}  ✓ qwen3:8b pulled${NC}"
fi

if ollama list 2>/dev/null | grep -q "qwen2.5-coder:7b"; then
    echo -e "${GREEN}  ✓ qwen2.5-coder:7b already available${NC}"
else
    echo -e "${BLUE}  Pulling qwen2.5-coder:7b...${NC}"
    ollama pull qwen2.5-coder:7b
    echo -e "${GREEN}  ✓ qwen2.5-coder:7b pulled${NC}"
fi

# ---- Install SocialFlow dependencies ----
echo ""
echo -e "${YELLOW}[3/7] Installing SocialFlow dependencies...${NC}"

cd "$PROJECT_DIR/socialflow/backend"

if [ -d ".venv" ]; then
    echo -e "${GREEN}  ✓ Virtual environment exists${NC}"
else
    python3 -m venv .venv
    echo -e "${GREEN}  ✓ Created virtual environment${NC}"
fi

source .venv/bin/activate 2>/dev/null || . .venv/bin/activate

pip install -r requirements.txt -q 2>/dev/null
echo -e "${GREEN}  ✓ Python dependencies installed${NC}"

# ---- Install Playwright browsers ----
echo ""
echo -e "${YELLOW}[4/7] Installing Playwright browsers...${NC}"

python3 -m playwright install chromium 2>/dev/null && \
    echo -e "${GREEN}  ✓ Chromium browser installed${NC}" || \
    echo -e "${YELLOW}  ! Playwright browser install skipped (run manually: playwright install chromium)${NC}"

cd "$PROJECT_DIR"

# ---- Make scripts executable ----
echo ""
echo -e "${YELLOW}[5/7] Making scripts executable...${NC}"

chmod +x openclaw-engine/scripts/*.sh 2>/dev/null
chmod +x openclaw 2>/dev/null
chmod +x socialflow/start.sh 2>/dev/null
echo -e "${GREEN}  ✓ All scripts executable${NC}"

# ---- Create .env if not exists ----
echo ""
echo -e "${YELLOW}[6/7] Checking configuration...${NC}"

if [ ! -f "$PROJECT_DIR/configs/.env" ]; then
    cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/configs/.env" 2>/dev/null || \
    cat > "$PROJECT_DIR/configs/.env" << 'ENVEOF'
# OpenClaw AI CMO Configuration
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL_STRATEGY=qwen3:8b
OLLAMA_MODEL_CODE=qwen2.5-coder:7b
SOCIALFLOW_URL=http://localhost:8000
WORKSPACE_ROOT=.
ENVEOF
    echo -e "${GREEN}  ✓ Created configs/.env${NC}"
else
    echo -e "${GREEN}  ✓ configs/.env already exists${NC}"
fi

# ---- Verify Ollama is running ----
echo ""
echo -e "${YELLOW}[7/7] Verifying Ollama connectivity...${NC}"

if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Ollama is running and responsive${NC}"
else
    echo -e "${YELLOW}  ! Ollama is not running. Start it with: ollama serve${NC}"
fi

# ---- Done ----
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  Setup complete!                                           ${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "  Next steps:"
echo -e "  1. Drop a source note:  ${BLUE}echo 'My update' > data/source-notes/test.md${NC}"
echo -e "  2. Run daily pipeline:  ${BLUE}./openclaw-engine/scripts/daily-pipeline.sh${NC}"
echo -e "  3. Start SocialFlow:    ${BLUE}cd socialflow/backend && python main.py${NC}"
echo -e "  4. Read the docs:       ${BLUE}docs/guides/QUICKSTART.md${NC}"
echo ""
