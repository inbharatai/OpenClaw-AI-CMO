#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# mail-sender.sh — Send email drafts via SMTP
# Usage: ./mail-sender.sh <draft-file.md> <recipient-email>
# Reads draft from outreach/drafts/, sends via Zoho SMTP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -uo pipefail

BOT_ROOT="/Volumes/Expansion/CMO-10million/OpenClawData/inbharat-bot"
CREDS_FILE="$BOT_ROOT/config/.mail-credentials"
OUTREACH_LOG_DIR="$BOT_ROOT/outreach/log"
DATE=$(date '+%Y-%m-%d')

source "$BOT_ROOT/logging/bot-logger.sh"

DRAFT_FILE="${1:-}"
RECIPIENT="${2:-}"

if [ -z "$DRAFT_FILE" ] || [ -z "$RECIPIENT" ]; then
  echo "Usage: mail-sender.sh <draft-file.md> <recipient-email>"
  echo ""
  echo "Available drafts:"
  ls "$BOT_ROOT/outreach/drafts/"*.md 2>/dev/null | while read f; do
    SUBJ=$(grep "^subject:" "$f" | head -1 | sed 's/subject: *//')
    echo "  $(basename "$f") — $SUBJ"
  done
  exit 1
fi

# Resolve draft file path
if [ ! -f "$DRAFT_FILE" ]; then
  # Try relative to drafts dir
  DRAFT_FILE="$BOT_ROOT/outreach/drafts/$DRAFT_FILE"
fi

if [ ! -f "$DRAFT_FILE" ]; then
  bot_log "mail-sender" "error" "Draft not found: $DRAFT_FILE"
  exit 1
fi

# Load credentials — try Keychain first, fall back to file
SMTP_HOST="smtp.zoho.in"
SMTP_PORT="587"
FROM_NAME="Reeturaj Goswami"

# Try macOS Keychain
SMTP_USER=$(security find-generic-password -s "openclaw" -a "openclaw-smtp-user" -w 2>/dev/null)
SMTP_PASS=$(security find-generic-password -s "openclaw" -a "openclaw-smtp-pass" -w 2>/dev/null)
FROM_EMAIL="${SMTP_USER:-}"

# Fall back to credentials file
if [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ]; then
  if [ -f "$CREDS_FILE" ]; then
    source "$CREDS_FILE"
  fi
fi

if [ -z "${SMTP_USER:-}" ] || [ -z "${SMTP_PASS:-}" ]; then
  echo "━━━ MAIL CREDENTIALS NOT CONFIGURED ━━━"
  echo ""
  echo "Option 1 (recommended): Store in macOS Keychain:"
  echo "  bash OpenClawData/security/credential-vault.sh store smtp-user your-email@zoho.com"
  echo "  bash OpenClawData/security/credential-vault.sh store smtp-pass your-app-password"
  echo ""
  echo "Option 2: Create credentials file at $CREDS_FILE"
  echo ""
  echo "Get app password from: accounts.zoho.com → Security → App Passwords"
  exit 1
fi

FROM_EMAIL="${FROM_EMAIL:-$SMTP_USER}"

# Parse draft frontmatter
SUBJECT=$(grep "^subject:" "$DRAFT_FILE" | head -1 | sed 's/subject: *//')
DRAFT_TYPE=$(grep "^type:" "$DRAFT_FILE" | head -1 | sed 's/type: *//')

if [ -z "$SUBJECT" ]; then
  SUBJECT="Message from InBharat AI"
fi

# Extract email body (everything after the frontmatter closing ---)
BODY=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$DRAFT_FILE")

if [ -z "$BODY" ]; then
  # Fallback: skip first --- block
  BODY=$(sed '1,/^---$/d' "$DRAFT_FILE" | sed '1,/^---$/d')
fi

if [ -z "$BODY" ]; then
  bot_log "mail-sender" "error" "Could not extract email body from draft"
  exit 1
fi

bot_log "mail-sender" "info" "Sending email: $SUBJECT → $RECIPIENT"

# Send via Python smtplib (all values passed via environment variables — no shell injection)
export MAIL_SMTP_HOST="$SMTP_HOST"
export MAIL_SMTP_PORT="$SMTP_PORT"
export MAIL_SMTP_USER="$SMTP_USER"
export MAIL_SMTP_PASS="$SMTP_PASS"
export MAIL_FROM_NAME="$FROM_NAME"
export MAIL_FROM_EMAIL="$FROM_EMAIL"
export MAIL_TO="$RECIPIENT"
export MAIL_SUBJECT="$SUBJECT"
export MAIL_BODY="$BODY"

python3 << 'PYEOF'
import smtplib
import ssl
import os
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

smtp_host = os.environ.get("MAIL_SMTP_HOST", "smtp.zoho.in")
smtp_port = int(os.environ.get("MAIL_SMTP_PORT", "587"))
smtp_user = os.environ["MAIL_SMTP_USER"]
smtp_pass = os.environ["MAIL_SMTP_PASS"]
from_name = os.environ.get("MAIL_FROM_NAME", "Reeturaj Goswami")
from_email = os.environ.get("MAIL_FROM_EMAIL", smtp_user)
to_email = os.environ["MAIL_TO"]
subject = os.environ.get("MAIL_SUBJECT", "Message from InBharat AI")
body = os.environ.get("MAIL_BODY", "")

msg = MIMEMultipart("alternative")
msg["Subject"] = subject
msg["From"] = f"{from_name} <{from_email}>"
msg["To"] = to_email

msg.attach(MIMEText(body, "plain"))

try:
    context = ssl.create_default_context()
    with smtplib.SMTP(smtp_host, smtp_port) as server:
        server.starttls(context=context)
        server.login(smtp_user, smtp_pass)
        server.sendmail(from_email, to_email, msg.as_string())
    print("SENT_OK")
except Exception as e:
    print(f"SEND_FAILED: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF

SEND_RESULT=$?

if [ $SEND_RESULT -eq 0 ]; then
  bot_log "mail-sender" "info" "Email sent successfully: $SUBJECT → $RECIPIENT"

  # Update draft status
  sed -i '' 's/^status: draft/status: sent/' "$DRAFT_FILE" 2>/dev/null

  # Log send
  jq -cn \
    --arg date "$DATE" \
    --arg time "$(date '+%H:%M:%S')" \
    --arg type "email-send" \
    --arg subject "$SUBJECT" \
    --arg recipient "$RECIPIENT" \
    --arg draft "$(basename "$DRAFT_FILE")" \
    --arg status "sent" \
    '{date: $date, time: $time, type: $type, subject: $subject, recipient: $recipient, draft: $draft, status: $status}' \
    >> "$OUTREACH_LOG_DIR/outreach-${DATE}.jsonl"

  echo ""
  echo "━━━ EMAIL SENT ━━━"
  echo "To: $RECIPIENT"
  echo "Subject: $SUBJECT"
  echo "Type: $DRAFT_TYPE"
  echo "Draft: $(basename "$DRAFT_FILE") → status updated to 'sent'"
else
  bot_log "mail-sender" "error" "Failed to send email: $SUBJECT → $RECIPIENT"
  echo ""
  echo "━━━ SEND FAILED ━━━"
  echo "Check credentials in: $CREDS_FILE"
  echo "Check SMTP settings: ${SMTP_HOST:-smtp.zoho.in}:${SMTP_PORT:-587}"
  exit 1
fi
