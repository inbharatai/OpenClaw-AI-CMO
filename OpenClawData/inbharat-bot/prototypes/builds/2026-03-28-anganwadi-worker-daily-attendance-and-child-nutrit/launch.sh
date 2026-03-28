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
