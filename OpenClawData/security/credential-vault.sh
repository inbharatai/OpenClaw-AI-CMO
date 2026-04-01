#!/bin/bash
# credential-vault.sh — Secure credential management for OpenClaw/InBharat
# Uses macOS Keychain for secret storage instead of plaintext files
#
# Usage:
#   ./credential-vault.sh store <key-name> <value>     Store a secret
#   ./credential-vault.sh get <key-name>               Retrieve a secret
#   ./credential-vault.sh delete <key-name>             Remove a secret
#   ./credential-vault.sh list                          List stored keys
#   ./credential-vault.sh migrate                       Migrate plaintext secrets to Keychain
#   ./credential-vault.sh audit                         Check for plaintext secrets in codebase
#
# All secrets are stored in macOS Keychain under service "openclaw"

set -o pipefail

SERVICE="openclaw"
ACCOUNT_PREFIX="openclaw-"
WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"

CMD="${1:-help}"
shift 2>/dev/null || true

store_secret() {
  local KEY="$1"
  local VALUE="$2"
  if [ -z "$KEY" ] || [ -z "$VALUE" ]; then
    echo "Usage: credential-vault.sh store <key-name> <value>"
    return 1
  fi

  # Delete existing entry if present (security update avoids duplicates)
  security delete-generic-password -s "$SERVICE" -a "${ACCOUNT_PREFIX}${KEY}" 2>/dev/null

  security add-generic-password \
    -s "$SERVICE" \
    -a "${ACCOUNT_PREFIX}${KEY}" \
    -w "$VALUE" \
    -T "" \
    -U 2>/dev/null

  if [ $? -eq 0 ]; then
    echo "✅ Stored: $KEY (in macOS Keychain, service: $SERVICE)"
  else
    echo "❌ Failed to store: $KEY"
    return 1
  fi
}

get_secret() {
  local KEY="$1"
  if [ -z "$KEY" ]; then
    echo "Usage: credential-vault.sh get <key-name>"
    return 1
  fi

  local VALUE
  VALUE=$(security find-generic-password \
    -s "$SERVICE" \
    -a "${ACCOUNT_PREFIX}${KEY}" \
    -w 2>/dev/null)

  if [ $? -eq 0 ] && [ -n "$VALUE" ]; then
    echo "$VALUE"
  else
    echo "ERROR: Secret '$KEY' not found in Keychain" >&2
    return 1
  fi
}

delete_secret() {
  local KEY="$1"
  if [ -z "$KEY" ]; then
    echo "Usage: credential-vault.sh delete <key-name>"
    return 1
  fi

  security delete-generic-password \
    -s "$SERVICE" \
    -a "${ACCOUNT_PREFIX}${KEY}" 2>/dev/null

  if [ $? -eq 0 ]; then
    echo "✅ Deleted: $KEY"
  else
    echo "❌ Not found: $KEY"
    return 1
  fi
}

list_secrets() {
  echo "━━━ OpenClaw Credential Vault ━━━"
  echo "Service: $SERVICE"
  echo ""

  # List all openclaw keys in keychain
  security dump-keychain 2>/dev/null | grep -A 4 "svce.*\"$SERVICE\"" | grep "acct" | sed 's/.*"openclaw-/  /; s/".*//' | sort

  echo ""
  echo "Use 'credential-vault.sh get <key>' to retrieve a value"
}

migrate_secrets() {
  echo "━━━ MIGRATING PLAINTEXT SECRETS TO KEYCHAIN ━━━"
  echo ""

  local MIGRATED=0
  local SKIPPED=0

  # 1. Groq API key from gateway plist
  PLIST="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
  if [ -f "$PLIST" ]; then
    GROQ_KEY=$(grep -A 1 "GROQ_API_KEY" "$PLIST" 2>/dev/null | grep "<string>" | sed 's/.*<string>//;s/<\/string>.*//')
    if [ -n "$GROQ_KEY" ] && [ "$GROQ_KEY" != '$(credential-vault.sh get groq-api-key)' ]; then
      echo "Found: Groq API key in gateway plist"
      store_secret "groq-api-key" "$GROQ_KEY"

      # Replace plaintext key with keychain lookup in plist
      # NOTE: LaunchAgent plists cannot run shell commands in env vars.
      # The proper fix is a wrapper script that fetches from keychain.
      echo "  ⚠ Plist cannot use Keychain directly. Create a wrapper script."
      echo "  See: $WORKSPACE_ROOT/OpenClawData/security/gateway-wrapper.sh"
      MIGRATED=$((MIGRATED + 1))
    else
      echo "Skip: Groq API key (already migrated or not found)"
      SKIPPED=$((SKIPPED + 1))
    fi
  fi

  # 2. Gateway auth token from openclaw.json
  OPENCLAW_JSON="$HOME/.openclaw/openclaw.json"
  if [ -f "$OPENCLAW_JSON" ]; then
    GW_TOKEN=$(python3 -c "
import json, os
try:
    with open(os.path.expanduser('~/.openclaw/openclaw.json')) as f:
        data = json.load(f)
    token = data.get('gateway',{}).get('auth',{}).get('token','')
    if token: print(token)
except: pass
" 2>/dev/null)

    if [ -n "$GW_TOKEN" ]; then
      echo "Found: Gateway auth token in openclaw.json"
      store_secret "gateway-token" "$GW_TOKEN"
      echo "  ⚠ Token remains in openclaw.json (gateway reads it directly)"
      echo "  Future: gateway should read from Keychain via env var"
      MIGRATED=$((MIGRATED + 1))
    fi
  fi

  # 3. Mail credentials
  MAIL_CREDS="$WORKSPACE_ROOT/OpenClawData/inbharat-bot/config/.mail-credentials"
  if [ -f "$MAIL_CREDS" ]; then
    echo "Found: Plaintext mail credentials at $MAIL_CREDS"
    echo "  ⚠ Manual action needed: store SMTP password in Keychain"
    echo "  Run: credential-vault.sh store smtp-password '<your-app-password>'"
    echo "  Then delete: $MAIL_CREDS"
    MIGRATED=$((MIGRATED + 1))
  fi

  echo ""
  echo "━━━ MIGRATION SUMMARY ━━━"
  echo "Migrated: $MIGRATED"
  echo "Skipped: $SKIPPED"

  if [ "$MIGRATED" -gt 0 ]; then
    echo ""
    echo "NEXT STEPS:"
    echo "  1. Verify secrets are in Keychain: credential-vault.sh list"
    echo "  2. Update gateway to use wrapper: security/gateway-wrapper.sh"
    echo "  3. Remove plaintext keys from plist after testing wrapper"
    echo "  4. Store any additional secrets: credential-vault.sh store <name> <value>"
  fi
}

audit_secrets() {
  echo "━━━ SECRET AUDIT ━━━"
  echo ""

  local FOUND=0

  # Check for API key patterns in shell scripts
  echo "Scanning for plaintext secrets in scripts..."
  while IFS= read -r FILE; do
    [ -z "$FILE" ] && continue
    # Skip binary files and this script
    [[ "$FILE" == *"credential-vault.sh" ]] && continue
    [[ "$FILE" == *".output" ]] && continue

    MATCHES=$(grep -nE '(gsk_[a-zA-Z0-9]{20,}|sk-[a-zA-Z0-9]{20,}|api_key\s*=\s*"[^"]{10,}"|password\s*=\s*"[^"]{5,}"|Bearer [a-zA-Z0-9]{20,})' "$FILE" 2>/dev/null | head -3)
    if [ -n "$MATCHES" ]; then
      echo "🔴 FOUND in $(basename "$FILE"):"
      echo "$MATCHES" | head -2 | sed 's/^/    /'
      FOUND=$((FOUND + 1))
    fi
  done < <(find "$WORKSPACE_ROOT/OpenClawData" -name "*.sh" -o -name "*.json" -o -name "*.env" 2>/dev/null | grep -v node_modules | grep -v "._")

  # Check plist files
  for PLIST in "$HOME/Library/LaunchAgents"/ai.openclaw.*.plist "$HOME/Library/LaunchAgents"/com.openclaw.*.plist; do
    [ ! -f "$PLIST" ] && continue
    MATCHES=$(grep -nE '(gsk_|sk-|api_key|password|secret|token)' "$PLIST" 2>/dev/null | grep -v "MARKER\|VERSION\|KIND\|SERVICE" | head -3)
    if [ -n "$MATCHES" ]; then
      echo "🔴 FOUND in $(basename "$PLIST"):"
      echo "$MATCHES" | head -2 | sed 's/^/    /'
      FOUND=$((FOUND + 1))
    fi
  done

  # Check openclaw.json
  if [ -f "$HOME/.openclaw/openclaw.json" ]; then
    MATCHES=$(grep -nE '"token":|"apiKey":|"password":' "$HOME/.openclaw/openclaw.json" 2>/dev/null | head -3)
    if [ -n "$MATCHES" ]; then
      echo "🔴 FOUND in openclaw.json:"
      echo "$MATCHES" | head -2 | sed 's/^/    /'
      FOUND=$((FOUND + 1))
    fi
  fi

  echo ""
  if [ "$FOUND" -eq 0 ]; then
    echo "🟢 No plaintext secrets found in scanned files"
  else
    echo "🔴 Found secrets in $FOUND file(s)"
    echo ""
    echo "Fix: Run 'credential-vault.sh migrate' to move secrets to Keychain"
  fi
}

case "$CMD" in
  store)   store_secret "${1:-}" "${2:-}" ;;
  get)     get_secret "${1:-}" ;;
  delete)  delete_secret "${1:-}" ;;
  list)    list_secrets ;;
  migrate) migrate_secrets ;;
  audit)   audit_secrets ;;
  *)
    echo "━━━ OpenClaw Credential Vault ━━━"
    echo ""
    echo "Usage: credential-vault.sh <command>"
    echo ""
    echo "  store <key> <value>   Store secret in macOS Keychain"
    echo "  get <key>             Retrieve secret from Keychain"
    echo "  delete <key>          Remove secret from Keychain"
    echo "  list                  List all stored keys"
    echo "  migrate               Migrate plaintext secrets to Keychain"
    echo "  audit                 Scan codebase for plaintext secrets"
    echo ""
    echo "Secrets are stored in macOS Keychain under service: $SERVICE"
    ;;
esac
