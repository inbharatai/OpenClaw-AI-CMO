#!/bin/bash
# gateway-wrapper.sh — Launches OpenClaw gateway with secrets from macOS Keychain
# This replaces the direct plist launch that had plaintext API keys.
#
# Usage: This script is called by the LaunchAgent plist instead of npx directly.
# The plist's ProgramArguments should point here.

set -o pipefail

# Fetch secrets from Keychain
export GROQ_API_KEY=$(security find-generic-password -s "openclaw" -a "openclaw-groq-api-key" -w 2>/dev/null)

if [ -z "$GROQ_API_KEY" ]; then
  echo "[$(date)] ERROR: GROQ_API_KEY not found in Keychain. Run: credential-vault.sh store groq-api-key <key>" >&2
  # Fall back to env var if set externally
  if [ -z "$GROQ_API_KEY" ]; then
    echo "[$(date)] WARNING: No Groq API key available. Gateway will use local models only." >&2
  fi
fi

# Set required environment (match plist env vars)
export HOME="${HOME:-/Users/reeturajgoswami}"
export PATH="/Users/reeturajgoswami/local/node/bin:/Users/reeturajgoswami/.local/bin:/Users/reeturajgoswami/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export TMPDIR="${TMPDIR:-/var/folders/tb/sj1fd0dx5dn_8zwbpb4xj0380000gn/T/}"
export NODE_EXTRA_CA_CERTS="/etc/ssl/cert.pem"
export NODE_USE_SYSTEM_CA="1"
export OPENCLAW_GATEWAY_PORT="18789"
export OPENCLAW_LAUNCHD_LABEL="ai.openclaw.gateway"
export OPENCLAW_SERVICE_MARKER="openclaw"
export OPENCLAW_SERVICE_KIND="gateway"

# Launch gateway using the installed local binary (same as original plist)
cd "$HOME/.openclaw" 2>/dev/null || true
exec /Users/reeturajgoswami/local/node/bin/node \
  /Users/reeturajgoswami/local/node/lib/node_modules/openclaw/dist/index.js \
  gateway --port 18789 2>&1
