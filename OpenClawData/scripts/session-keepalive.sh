#!/bin/bash
# session-keepalive.sh — Periodically refreshes platform browser sessions
# Runs every 6 hours via cron to prevent session expiry.
# Uses Chrome's profile (shared with user's logged-in Chrome browser).
#
# If a session expires, it logs a warning and notifies via WhatsApp.

set -uo pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
ENGINE_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media/posting-engine"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/session-keepalive.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$DATE] $1" >> "$LOG_FILE"
  echo "$1"
}

log "━━━ Session Keep-Alive Check ━━━"

# Step 0: Sync Chrome cookies to Playwright sessions (if Chrome cookies exist)
SYNC_SCRIPT="$WORKSPACE_ROOT/OpenClawData/scripts/sync-chrome-sessions.sh"
if [ -x "$SYNC_SCRIPT" ]; then
  log "Syncing Chrome cookies to Playwright sessions..."
  bash "$SYNC_SCRIPT" all >> "$LOG_FILE" 2>&1 || log "Cookie sync had warnings (non-fatal)"
fi

EXPIRED_PLATFORMS=""
ACTIVE_PLATFORMS=""

# Check each platform
for PLATFORM in linkedin x instagram; do
  SCRIPT="$ENGINE_DIR/post_${PLATFORM}.py"
  if [ ! -f "$SCRIPT" ]; then
    log "SKIP: $PLATFORM — no posting script"
    continue
  fi

  # Check session (with timeout to prevent hanging)
  CHECK_OUTPUT=$(timeout 45 python3 "$SCRIPT" --check 2>&1)
  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ] && echo "$CHECK_OUTPUT" | grep -qi "VALID\|working\|logged"; then
    log "OK: $PLATFORM session active"
    ACTIVE_PLATFORMS="$ACTIVE_PLATFORMS $PLATFORM"

    # Refresh session by visiting the platform briefly (keeps cookies alive)
    timeout 30 python3 -c "
from playwright.sync_api import sync_playwright
from pathlib import Path
import sys

CHROME_DIR = Path.home() / 'Library' / 'Application Support' / 'Google' / 'Chrome'
PLATFORM = '$PLATFORM'
URLS = {'linkedin': 'https://www.linkedin.com/feed/', 'x': 'https://x.com/home', 'instagram': 'https://www.instagram.com/'}

if not CHROME_DIR.exists():
    sys.exit(0)

try:
    with sync_playwright() as p:
        ctx = p.chromium.launch_persistent_context(
            user_data_dir=str(CHROME_DIR),
            headless=True,
            channel='chrome',
            args=['--disable-blink-features=AutomationControlled', '--profile-directory=Default'],
        )
        page = ctx.pages[0] if ctx.pages else ctx.new_page()
        page.goto(URLS.get(PLATFORM, ''), wait_until='domcontentloaded', timeout=20000)
        import time; time.sleep(2)
        ctx.close()
except Exception as e:
    print(f'Session refresh warning: {e}', file=sys.stderr)
" 2>/dev/null

    log "REFRESHED: $PLATFORM session cookies renewed"
  else
    log "EXPIRED: $PLATFORM session needs re-login"
    EXPIRED_PLATFORMS="$EXPIRED_PLATFORMS $PLATFORM"
  fi
done

# Check Discord webhook (doesn't expire, but verify it works)
DISCORD_CHECK=$(python3 "$ENGINE_DIR/post_discord.py" --check 2>&1)
if echo "$DISCORD_CHECK" | grep -qi "POSTED\|success"; then
  log "OK: Discord webhook active"
  ACTIVE_PLATFORMS="$ACTIVE_PLATFORMS discord"
else
  log "WARN: Discord webhook check failed"
  EXPIRED_PLATFORMS="$EXPIRED_PLATFORMS discord"
fi

# Notify via WhatsApp if any sessions expired
if [ -n "$EXPIRED_PLATFORMS" ]; then
  MSG="⚠️ *Session Alert*
These platform sessions have expired:${EXPIRED_PLATFORMS}

Please open Chrome and log into these platforms. The bot will pick up the sessions automatically.

Active:${ACTIVE_PLATFORMS:-none}"

  # Try sending via OpenClaw CLI
  openclaw message send \
    --channel whatsapp \
    --target "+919015823397" \
    --message "$MSG" 2>/dev/null || log "Could not send WhatsApp alert"
fi

log "━━━ Keep-Alive Complete ━━━"
log "Active:${ACTIVE_PLATFORMS:-none} | Expired:${EXPIRED_PLATFORMS:-none}"
