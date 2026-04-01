#!/bin/bash
# sync-chrome-sessions.sh — Copy Chrome login cookies to Playwright sessions
# This lets you log in via Chrome and the bot reuses those sessions.
# Run this once after logging into platforms in Chrome, then the keepalive handles the rest.
#
# Usage:
#   ./sync-chrome-sessions.sh              Sync all platforms
#   ./sync-chrome-sessions.sh linkedin     Sync specific platform
#   ./sync-chrome-sessions.sh --check      Check which platforms are logged in

set -uo pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
ENGINE_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine"
SESSION_BASE="$HOME/.openclaw/browser-sessions"
CHROME_COOKIES="$HOME/Library/Application Support/Google/Chrome/Default/Cookies"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/session-sync.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
  echo "$1"
}

# Platform → domains mapping (bash 3 compatible)
get_domains() {
  case "$1" in
    linkedin) echo ".linkedin.com" ;;
    x) echo ".x.com,.twitter.com" ;;
    instagram) echo ".instagram.com" ;;
    *) echo "" ;;
  esac
}

TARGET="${1:-all}"

if [ "$TARGET" = "--check" ]; then
  echo "━━━ Platform Session Check ━━━"
  for PLATFORM in linkedin x instagram; do
    SCRIPT="$ENGINE_DIR/post_${PLATFORM}.py"
    if [ -f "$SCRIPT" ]; then
      CHECK=$(python3 "$SCRIPT" --check 2>&1)
      if echo "$CHECK" | grep -qi "VALID\|working\|logged"; then
        echo "  $PLATFORM: ✅ active"
      else
        echo "  $PLATFORM: ❌ needs sync"
      fi
    fi
  done
  # Discord
  DISCORD_CHECK=$(python3 "$ENGINE_DIR/post_discord.py" --check 2>&1)
  if echo "$DISCORD_CHECK" | grep -qi "POSTED\|success"; then
    echo "  discord: ✅ active"
  else
    echo "  discord: ❌ check failed"
  fi
  exit 0
fi

# Check Chrome cookie database exists
if [ ! -f "$CHROME_COOKIES" ]; then
  log "ERROR: Chrome cookies database not found at $CHROME_COOKIES"
  exit 1
fi

log "━━━ Syncing Chrome Sessions to Playwright ━━━"

# Sync function — copies cookies from Chrome to Playwright session via Python
sync_platform() {
  local PLATFORM="$1"
  local DOMAINS="$2"

  log "Syncing $PLATFORM (domains: $DOMAINS)..."

  local SESSION_DIR="$SESSION_BASE/$PLATFORM"
  mkdir -p "$SESSION_DIR/Default"

  python3 << PYEOF
import json
import os
import shutil
import sqlite3
import sys
import tempfile
from pathlib import Path

CHROME_COOKIES = "$CHROME_COOKIES"
SESSION_DIR = Path("$SESSION_DIR")
DOMAINS = "$DOMAINS".split(",")
PLATFORM = "$PLATFORM"

# Copy Chrome's cookie DB to temp file (can't read while Chrome has it locked)
tmp_db = tempfile.mktemp(suffix=".db")
try:
    shutil.copy2(CHROME_COOKIES, tmp_db)
except Exception as e:
    print(f"  ERROR: Cannot copy Chrome cookie DB: {e}", file=sys.stderr)
    sys.exit(1)

try:
    conn = sqlite3.connect(tmp_db)
    cursor = conn.cursor()

    # Get all cookies for the target domains
    cookies = []
    for domain in DOMAINS:
        domain = domain.strip()
        cursor.execute(
            "SELECT host_key, name, path, expires_utc, is_secure, is_httponly, samesite FROM cookies WHERE host_key LIKE ?",
            (f"%{domain}%",)
        )
        rows = cursor.fetchall()
        for row in rows:
            cookies.append({
                "host_key": row[0],
                "name": row[1],
                "path": row[2],
                "expires_utc": row[3],
                "is_secure": row[4],
                "is_httponly": row[5],
                "samesite": row[6],
            })

    conn.close()

    if not cookies:
        print(f"  WARNING: No cookies found for {PLATFORM} domains {DOMAINS}")
        print(f"  Make sure you're logged into {PLATFORM} in Chrome")
        sys.exit(1)

    print(f"  Found {len(cookies)} cookies for {PLATFORM}")

    # For Playwright persistent context: we need to ensure the session dir
    # has the Default profile. Copy the cookies DB there.
    dest_cookies = SESSION_DIR / "Default" / "Cookies"

    # Copy the full cookie DB (Playwright's Chromium will read it)
    shutil.copy2(tmp_db, str(dest_cookies))
    print(f"  Cookies synced to {dest_cookies}")

except Exception as e:
    print(f"  ERROR: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    os.unlink(tmp_db)
PYEOF

  if [ $? -eq 0 ]; then
    log "OK: $PLATFORM cookies synced"
  else
    log "FAIL: $PLATFORM cookie sync failed"
  fi
}

# Sync requested platforms
if [ "$TARGET" = "all" ]; then
  for PLATFORM in linkedin x instagram; do
    DOMAINS=$(get_domains "$PLATFORM")
    sync_platform "$PLATFORM" "$DOMAINS"
  done
else
  DOMAINS=$(get_domains "$TARGET")
  if [ -n "$DOMAINS" ]; then
    sync_platform "$TARGET" "$DOMAINS"
  else
    echo "ERROR: Unknown platform '$TARGET'. Use: linkedin, x, instagram, all"
    exit 1
  fi
fi

log "━━━ Sync Complete ━━━"
echo ""
echo "Now verifying sessions..."

# Verify
for PLATFORM in linkedin x instagram; do
  if [ "$TARGET" != "all" ] && [ "$TARGET" != "$PLATFORM" ]; then
    continue
  fi
  SCRIPT="$ENGINE_DIR/post_${PLATFORM}.py"
  if [ -f "$SCRIPT" ]; then
    CHECK=$(python3 "$SCRIPT" --check 2>&1)
    if echo "$CHECK" | grep -qi "VALID\|working\|logged"; then
      echo "  $PLATFORM: ✅ session active"
    else
      echo "  $PLATFORM: ⚠️ sync done but session check unclear — may need a page visit to activate"
    fi
  fi
done
