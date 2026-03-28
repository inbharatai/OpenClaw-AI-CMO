#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# prototype-builder.sh — Build working prototypes from problems
# Usage: ./prototype-builder.sh "<problem description>"
# Output: Deployable prototype in prototypes/builds/<slug>/
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -uo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
SKILLS_DIR="$BOT_ROOT/skills"
BUILDS_DIR="$BOT_ROOT/prototypes/builds"
PROTO_LOG_DIR="$BOT_ROOT/prototypes/log"
OLLAMA_URL="http://127.0.0.1:11434"
MODEL="qwen3:8b"
DATE=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

source "$BOT_ROOT/logging/bot-logger.sh"

mkdir -p "$BUILDS_DIR" "$PROTO_LOG_DIR"

PROBLEM="${1:-}"
if [ -z "$PROBLEM" ]; then
  echo "Usage: prototype-builder.sh \"<problem description>\""
  echo "Example: prototype-builder.sh \"Anganwadi worker attendance tracker with offline support\""
  exit 1
fi

bot_log "prototype" "info" "=== Prototype Builder started ==="
bot_log "prototype" "info" "Problem: $PROBLEM"

# Check Ollama
if ! curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
  bot_log "prototype" "error" "Ollama not running"
  exit 1
fi

# Create build directory
SLUG=$(echo "$PROBLEM" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
SLUG="${SLUG:0:50}"
BUILD_DIR="$BUILDS_DIR/${DATE}-${SLUG}"
mkdir -p "$BUILD_DIR"

# Load skill
SKILL_FILE="$SKILLS_DIR/prototype-builder/SKILL.md"
if [ ! -f "$SKILL_FILE" ]; then
  bot_log "prototype" "error" "Skill file not found: $SKILL_FILE"
  exit 1
fi

SKILL_BODY=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$SKILL_FILE")

# Build prompt
PROMPT="$SKILL_BODY

---

TODAY'S DATE: $DATE

PROBLEM TO SOLVE:
$PROBLEM

TASK: Generate a complete, working prototype that solves this problem.

Requirements:
- Prefer a single-file web app (HTML+CSS+JS) unless the problem specifically needs Python/backend
- The code must work immediately when opened in a browser or run with python3
- Include realistic sample data if needed
- Keep it under 300 lines
- Make it look professional with clean UI
- Include InBharat AI branding subtly

Output each file using this exact format:
===FILE: filename.html===
<contents>
===END===

If multiple files needed, output each one. Start with the main file."

# Call Ollama
bot_log "prototype" "info" "Generating prototype via $MODEL..."
echo "Building prototype..."
echo ""

RESPONSE=$(curl -s --max-time 240 "$OLLAMA_URL/api/generate" \
  -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.3, num_predict: 4000}}')" \
  | jq -r '(.response // .thinking) // "ERROR: No response from model"')

if [ "$RESPONSE" = "ERROR: No response from model" ] || [ -z "$RESPONSE" ]; then
  bot_log "prototype" "error" "Ollama did not respond"
  exit 1
fi

# Parse response and extract files
# Format: ===FILE: name=== ... ===END===
FILE_COUNT=0

# Save raw response for debugging
echo "$RESPONSE" > "$BUILD_DIR/_raw-response.md"

# Extract files using Python for reliable parsing
python3 << 'PYEOF' - "$RESPONSE" "$BUILD_DIR"
import sys
import re

response = sys.argv[1]
build_dir = sys.argv[2]

# Try to find ===FILE: name=== ... ===END=== blocks
pattern = r'===FILE:\s*(.+?)===\s*\n(.*?)===END==='
matches = re.findall(pattern, response, re.DOTALL)

if matches:
    for filename, content in matches:
        filename = filename.strip()
        content = content.strip()
        # Remove markdown code fences if present
        content = re.sub(r'^```\w*\n', '', content)
        content = re.sub(r'\n```$', '', content)
        filepath = f"{build_dir}/{filename}"
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"EXTRACTED:{filename}")
else:
    # Fallback: look for code blocks and save as index.html or app.py
    code_blocks = re.findall(r'```(\w+)?\n(.*?)```', response, re.DOTALL)
    if code_blocks:
        for i, (lang, code) in enumerate(code_blocks):
            if lang in ('html', '') or '<html' in code.lower() or '<!doctype' in code.lower():
                fname = 'index.html'
            elif lang == 'python' or 'import ' in code:
                fname = 'app.py'
            elif lang in ('javascript', 'js'):
                fname = 'script.js'
            elif lang == 'css':
                fname = 'style.css'
            elif lang in ('json',):
                fname = 'config.json'
            else:
                fname = f'file_{i}.{lang}' if lang else f'file_{i}.txt'

            filepath = f"{build_dir}/{fname}"
            with open(filepath, 'w') as f:
                f.write(code.strip())
            print(f"EXTRACTED:{fname}")
    else:
        # Last resort: save entire response as index.html if it looks like HTML
        if '<html' in response.lower() or '<!doctype' in response.lower():
            with open(f"{build_dir}/index.html", 'w') as f:
                f.write(response)
            print("EXTRACTED:index.html")
        else:
            with open(f"{build_dir}/prototype.txt", 'w') as f:
                f.write(response)
            print("EXTRACTED:prototype.txt (raw — manual extraction needed)")
PYEOF

# Count extracted files
FILE_COUNT=$(ls "$BUILD_DIR" | grep -v '_raw-response.md' | wc -l | tr -d ' ')

# Generate a simple launcher script
cat > "$BUILD_DIR/launch.sh" << 'LAUNCHER'
#!/bin/bash
# Prototype Launcher
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$DIR/index.html" ]; then
  echo "Opening web app..."
  open "$DIR/index.html" 2>/dev/null || xdg-open "$DIR/index.html" 2>/dev/null || echo "Open $DIR/index.html in your browser"
elif [ -f "$DIR/app.py" ]; then
  echo "Starting Python app..."
  cd "$DIR"
  if [ -f requirements.txt ]; then
    pip3 install -r requirements.txt 2>/dev/null
  fi
  python3 app.py
elif [ -f "$DIR/tool.sh" ]; then
  echo "Running tool..."
  bash "$DIR/tool.sh"
else
  echo "Files in prototype:"
  ls -la "$DIR"
  echo ""
  echo "Open the appropriate file to run this prototype."
fi
LAUNCHER
chmod +x "$BUILD_DIR/launch.sh"

# Log build
jq -cn \
  --arg date "$DATE" \
  --arg time "$(date '+%H:%M:%S')" \
  --arg problem "$PROBLEM" \
  --arg build_dir "$BUILD_DIR" \
  --argjson file_count "$FILE_COUNT" \
  --arg status "built" \
  '{date: $date, time: $time, type: "prototype-build", problem: $problem, build_dir: $build_dir, files: $file_count, status: $status}' \
  >> "$PROTO_LOG_DIR/builds-${DATE}.jsonl"

bot_log "prototype" "info" "Prototype built: $BUILD_DIR ($FILE_COUNT files)"
bot_log_evidence "prototype" "prototype-build" "$BUILD_DIR" "success"

echo ""
echo "━━━ PROTOTYPE BUILT ━━━"
echo "Problem: $PROBLEM"
echo "Location: $BUILD_DIR"
echo "Files: $FILE_COUNT"
echo ""
echo "--- Contents ---"
ls -la "$BUILD_DIR" | grep -v '_raw-response.md'
echo ""
echo "--- Actions ---"
echo "  Launch:  bash $BUILD_DIR/launch.sh"
echo "  Review:  read $BUILD_DIR/index.html (or app.py)"
echo "  Deploy:  bash inbharat-run.sh prototype launch \"$BUILD_DIR\""
