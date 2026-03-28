#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# launcher.sh — Deploy prototypes
# Usage: ./launcher.sh <build-dir> [--local|--package]
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -uo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
LAUNCHED_DIR="$BOT_ROOT/prototypes/launched"
LAUNCH_LOG_DIR="$BOT_ROOT/prototypes/log"
DATE=$(date '+%Y-%m-%d')

source "$BOT_ROOT/logging/bot-logger.sh"

mkdir -p "$LAUNCHED_DIR" "$LAUNCH_LOG_DIR"

BUILD_DIR="${1:-}"
DEPLOY_MODE="${2:---local}"

if [ -z "$BUILD_DIR" ] || [ ! -d "$BUILD_DIR" ]; then
  echo "Usage: launcher.sh <build-directory> [--local|--package]"
  echo ""
  echo "Available builds:"
  ls -d "$BOT_ROOT/prototypes/builds"/*/ 2>/dev/null | while read d; do
    echo "  $(basename "$d")"
  done
  exit 1
fi

BUILD_NAME=$(basename "$BUILD_DIR")
bot_log "launcher" "info" "=== Launcher: $BUILD_NAME ==="

case "$DEPLOY_MODE" in
  --local)
    # Launch locally — open in browser or run
    bot_log "launcher" "info" "Local launch: $BUILD_DIR"

    # Find HTML file — prefer index.html, fallback to any .html
    HTML_FILE=""
    if [ -f "$BUILD_DIR/index.html" ]; then
      HTML_FILE="index.html"
    else
      HTML_FILE=$(ls "$BUILD_DIR"/*.html 2>/dev/null | head -1 | xargs basename 2>/dev/null)
    fi

    if [ -n "$HTML_FILE" ]; then
      echo "━━━ LAUNCHING WEB APP ━━━"
      echo "Opening: $BUILD_DIR/$HTML_FILE"

      # Start a simple HTTP server for proper loading
      PORT=8090
      while lsof -i :$PORT >/dev/null 2>&1; do
        PORT=$((PORT + 1))
      done

      echo "Starting server on port $PORT..."
      cd "$BUILD_DIR"
      python3 -m http.server "$PORT" &
      SERVER_PID=$!
      sleep 1

      # Open in browser
      open "http://localhost:$PORT/$HTML_FILE" 2>/dev/null || echo "Open http://localhost:$PORT/$HTML_FILE in your browser"

      echo ""
      echo "Server running at: http://localhost:$PORT"
      echo "Server PID: $SERVER_PID"
      echo "Stop: kill $SERVER_PID"

      # Log launch
      jq -cn \
        --arg date "$DATE" \
        --arg time "$(date '+%H:%M:%S')" \
        --arg build "$BUILD_NAME" \
        --arg mode "local" \
        --arg url "http://localhost:$PORT" \
        --argjson pid "$SERVER_PID" \
        --arg status "running" \
        '{date: $date, time: $time, type: "launch", build: $build, mode: $mode, url: $url, pid: $pid, status: $status}' \
        >> "$LAUNCH_LOG_DIR/launches-${DATE}.jsonl"

    elif [ -f "$BUILD_DIR/app.py" ]; then
      echo "━━━ LAUNCHING PYTHON APP ━━━"
      cd "$BUILD_DIR"
      if [ -f requirements.txt ]; then
        echo "Installing dependencies..."
        pip3 install -r requirements.txt 2>/dev/null
      fi
      echo "Running: python3 app.py"
      python3 app.py &
      APP_PID=$!
      echo "PID: $APP_PID"

      jq -cn \
        --arg date "$DATE" \
        --arg time "$(date '+%H:%M:%S')" \
        --arg build "$BUILD_NAME" \
        --arg mode "local-python" \
        --argjson pid "$APP_PID" \
        --arg status "running" \
        '{date: $date, time: $time, type: "launch", build: $build, mode: $mode, pid: $pid, status: $status}' \
        >> "$LAUNCH_LOG_DIR/launches-${DATE}.jsonl"

    elif [ -f "$BUILD_DIR/launch.sh" ]; then
      bash "$BUILD_DIR/launch.sh"
    else
      echo "No launchable file found in $BUILD_DIR"
      ls "$BUILD_DIR"
      exit 1
    fi
    ;;

  --package)
    # Package for deployment — create a deployable zip
    PACKAGE_FILE="$LAUNCHED_DIR/${BUILD_NAME}.zip"
    bot_log "launcher" "info" "Packaging: $BUILD_DIR → $PACKAGE_FILE"

    # Create package excluding raw response
    cd "$BUILD_DIR"
    zip -r "$PACKAGE_FILE" . -x '_raw-response.md' 2>/dev/null

    echo "━━━ PROTOTYPE PACKAGED ━━━"
    echo "Package: $PACKAGE_FILE"
    echo "Size: $(du -h "$PACKAGE_FILE" | cut -f1)"
    echo ""
    echo "Deploy options:"
    echo "  Vercel:  Upload to Vercel dashboard or use Vercel MCP"
    echo "  Netlify: Drag & drop $PACKAGE_FILE to netlify.com/drop"
    echo "  GitHub:  Push $BUILD_DIR to a new repo"
    echo ""
    echo "For Vercel deployment via MCP (if configured):"
    echo "  Use: deploy_to_vercel tool with project files from $BUILD_DIR"

    jq -cn \
      --arg date "$DATE" \
      --arg time "$(date '+%H:%M:%S')" \
      --arg build "$BUILD_NAME" \
      --arg mode "packaged" \
      --arg package "$PACKAGE_FILE" \
      --arg status "ready" \
      '{date: $date, time: $time, type: "launch", build: $build, mode: $mode, package: $package, status: $status}' \
      >> "$LAUNCH_LOG_DIR/launches-${DATE}.jsonl"
    ;;

  *)
    echo "Usage: launcher.sh <build-dir> [--local|--package]"
    exit 1
    ;;
esac

bot_log "launcher" "info" "Launch complete: $BUILD_NAME ($DEPLOY_MODE)"
