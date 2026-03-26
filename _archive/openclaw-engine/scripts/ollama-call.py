#!/usr/bin/env python3
"""
ollama-call.py — Safe Ollama API caller for skill-runner
Reads prompt from a temp file, calls Ollama, prints content to stdout.
Handles control characters, long prompts, and JSON safely.

Usage: python3 ollama-call.py <prompt-file> <model> [ollama-url]
"""

import json
import re
import subprocess
import sys

if len(sys.argv) < 3:
    print("Usage: ollama-call.py <prompt-file> <model> [ollama-url]", file=sys.stderr)
    sys.exit(1)

prompt_file = sys.argv[1]
model = sys.argv[2]
ollama_url = sys.argv[3] if len(sys.argv) > 3 else "http://127.0.0.1:11434"

try:
    with open(prompt_file, 'r') as f:
        prompt = f.read()
except Exception as e:
    print(f"Error reading prompt file: {e}", file=sys.stderr)
    sys.exit(1)

payload = json.dumps({
    "model": model,
    "messages": [{"role": "user", "content": prompt}],
    "stream": False,
    "options": {"temperature": 0.7, "num_predict": 2048}
})

try:
    result = subprocess.run(
        ["curl", "-s", f"{ollama_url}/api/chat", "-d", payload],
        capture_output=True, text=True, timeout=180
    )

    if result.returncode != 0:
        print(f"curl error: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    # Clean control characters for safe JSON parsing
    raw = re.sub(r'[\x00-\x1f]', ' ', result.stdout)
    data = json.loads(raw)

    content = data.get("message", {}).get("content", "")
    if not content:
        content = data.get("response", "")

    if content:
        print(content)
    else:
        print("", file=sys.stderr)

except subprocess.TimeoutExpired:
    print("Timeout: LLM call exceeded 180s", file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"JSON parse error: {e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
