#!/bin/bash
# ============================================================
# install-schedule.sh — Install launchd agents for macOS scheduling
#
# Creates LaunchAgents plist files for:
#   - Daily pipeline (6 AM)
#   - Weekly pipeline (Monday 8 AM)
#   - Monthly pipeline (1st of month 9 AM)
#
# Usage: ./install-schedule.sh [--uninstall]
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAUNCH_DIR="$HOME/Library/LaunchAgents"
PREFIX="com.openclaw.cmo"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$LAUNCH_DIR"

# ── UNINSTALL ──
if [ "$1" = "--uninstall" ]; then
    echo -e "${YELLOW}Uninstalling OpenClaw schedules...${NC}"
    for label in daily weekly monthly; do
        PLIST="$LAUNCH_DIR/${PREFIX}.${label}.plist"
        if [ -f "$PLIST" ]; then
            launchctl unload "$PLIST" 2>/dev/null
            rm "$PLIST"
            echo -e "  ${GREEN}✓${NC} Removed $label"
        fi
    done
    echo -e "${GREEN}Done.${NC}"
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  OpenClaw AI CMO — Schedule Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Project: $PROJECT_DIR"
echo "Target:  $LAUNCH_DIR"
echo ""

# ── DAILY (6:00 AM every day) ──
cat > "$LAUNCH_DIR/${PREFIX}.daily.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PREFIX}.daily</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${PROJECT_DIR}/openclaw-engine/scripts/daily-pipeline.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>6</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>${PROJECT_DIR}/logs/launchd-daily.log</string>
    <key>StandardErrorPath</key>
    <string>${PROJECT_DIR}/logs/launchd-daily-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF
echo -e "  ${GREEN}✓${NC} Daily pipeline — 6:00 AM every day"

# ── WEEKLY (Monday 8:00 AM) ──
cat > "$LAUNCH_DIR/${PREFIX}.weekly.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PREFIX}.weekly</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${PROJECT_DIR}/openclaw-engine/scripts/weekly-pipeline.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>1</integer>
        <key>Hour</key>
        <integer>8</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>${PROJECT_DIR}/logs/launchd-weekly.log</string>
    <key>StandardErrorPath</key>
    <string>${PROJECT_DIR}/logs/launchd-weekly-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF
echo -e "  ${GREEN}✓${NC} Weekly pipeline — Monday 8:00 AM"

# ── MONTHLY (1st of month, 9:00 AM) ──
cat > "$LAUNCH_DIR/${PREFIX}.monthly.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PREFIX}.monthly</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${PROJECT_DIR}/openclaw-engine/scripts/monthly-pipeline.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Day</key>
        <integer>1</integer>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>${PROJECT_DIR}/logs/launchd-monthly.log</string>
    <key>StandardErrorPath</key>
    <string>${PROJECT_DIR}/logs/launchd-monthly-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF
echo -e "  ${GREEN}✓${NC} Monthly pipeline — 1st at 9:00 AM"

# ── LOAD ALL ──
echo ""
echo "Loading agents..."
for label in daily weekly monthly; do
    PLIST="$LAUNCH_DIR/${PREFIX}.${label}.plist"
    launchctl unload "$PLIST" 2>/dev/null
    launchctl load "$PLIST"
    echo -e "  ${GREEN}✓${NC} Loaded ${PREFIX}.${label}"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Scheduling installed!${NC}"
echo ""
echo "  Verify:  launchctl list | grep openclaw"
echo "  Logs:    $PROJECT_DIR/logs/launchd-*.log"
echo "  Remove:  $SCRIPT_DIR/install-schedule.sh --uninstall"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
