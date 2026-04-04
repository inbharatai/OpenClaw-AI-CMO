#!/usr/bin/env python3
"""
email_zoho.py — Send emails via Zoho Mail using Playwright browser automation.

Uses persistent browser context (cookies/session) so login happens once.
Subsequent runs reuse the session — no SMTP credentials needed.

Usage:
    python3 email_zoho.py --login                          (first-time: opens browser for manual login)
    python3 email_zoho.py --check                          (verify session is still valid)
    python3 email_zoho.py --to "name@example.com" --subject "Subject" --body "Email body"
    python3 email_zoho.py --draft --to "name@example.com" --subject "Subject" --body "Email body"
    python3 email_zoho.py --dry-run --to "name@example.com" --subject "Subject" --body "Email body"

Session stored at: ~/.openclaw/browser-sessions/zoho/
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

SESSION_DIR = Path.home() / ".openclaw" / "browser-sessions" / "zoho"
LOG_DIR = Path("/Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/analytics")

ZOHO_MAIL_URL = "https://mail.zoho.in"
ZOHO_COMPOSE_URL = "https://mail.zoho.in/zm/#compose"


def get_playwright():
    try:
        from playwright.sync_api import sync_playwright
        return sync_playwright()
    except ImportError:
        print("ERROR: playwright not installed. Run: pip3 install playwright")
        sys.exit(1)


def ensure_session_dir():
    SESSION_DIR.mkdir(parents=True, exist_ok=True)


def launch_browser(pw, headless=False):
    """Launch browser with persistent context (reuses login session)."""
    ensure_session_dir()
    context = pw.chromium.launch_persistent_context(
        user_data_dir=str(SESSION_DIR),
        headless=headless,
        viewport={"width": 1280, "height": 900},
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
        args=[
            "--disable-blink-features=AutomationControlled",
            "--disable-features=AutomationControlled",
        ],
    )
    return context


def do_login(pw):
    """Open browser for manual login. User logs in, we save the session."""
    print("Opening Zoho Mail for manual login...")
    print("Log in with your credentials. The session will be saved automatically.")
    print("Close the browser window when done.")

    context = launch_browser(pw, headless=False)
    page = context.pages[0] if context.pages else context.new_page()
    page.goto(ZOHO_MAIL_URL, wait_until="domcontentloaded", timeout=60000)

    # Wait for user to log in — poll until we leave login/accounts page
    print("Waiting for login... (log in and reach your inbox)")
    print("(Will wait up to 5 minutes)")
    try:
        deadline = time.time() + 300  # 5 min
        while time.time() < deadline:
            url = page.url
            # Zoho mail can be .in, .com, .eu etc — check broadly
            if ("mail.zoho" in url or "zohomail" in url) and ("/zm/" in url or "mail/inbox" in url.lower() or "#" in url):
                time.sleep(3)
                print(f"Login successful! Session saved. (URL: {url[:60]})")
                break
            # Also detect if user closed the login page and is in the mail app
            if "zoho" in url and "login" not in url and "accounts" not in url and "signin" not in url:
                time.sleep(5)
                print(f"Login successful! Session saved. (URL: {url[:60]})")
                break
            time.sleep(2)
        else:
            print("Login timeout. Try again with: python3 email_zoho.py --login")
    except Exception:
        print("Login cancelled. Try again with: python3 email_zoho.py --login")

    context.close()


def check_session(pw):
    """Verify the saved session is still valid. Zoho blocks headless — must use visible."""
    context = launch_browser(pw, headless=False)
    page = context.pages[0] if context.pages else context.new_page()

    try:
        page.goto(ZOHO_MAIL_URL, wait_until="domcontentloaded", timeout=30000)
        page.wait_for_timeout(5000)
        url = page.url
        if "zoho" in url and ("login" not in url and "accounts" not in url and "signin" not in url):
            print(f"SESSION VALID: Logged into Zoho Mail ({url[:60]})")
            context.close()
            return True
        else:
            print(f"SESSION EXPIRED: Need to re-login. Run: python3 email_zoho.py --login (got: {url[:60]})")
            context.close()
            return False
    except Exception as e:
        print(f"SESSION CHECK FAILED: {e}")
        context.close()
        return False


def send_email(pw, to, subject, body, draft_only=False, headless=False):
    """Compose and send (or save as draft) an email via Zoho Mail.
    Note: Zoho blocks headless browsers, so this always runs visible."""
    if not to or not subject:
        print("ERROR: --to and --subject are required")
        return False

    context = launch_browser(pw, headless=headless)
    page = context.pages[0] if context.pages else context.new_page()

    try:
        # Navigate to Zoho Mail
        page.goto(ZOHO_MAIL_URL, wait_until="domcontentloaded", timeout=30000)
        page.wait_for_timeout(5000)

        # Check if logged in
        if "/zm/" not in page.url:
            print("ERROR: Not logged in. Run: python3 email_zoho.py --login")
            context.close()
            return False

        # Click Compose / New Mail button
        compose_selectors = [
            "button:has-text('New Mail')",
            "button:has-text('Compose')",
            "[data-action='compose']",
            "a:has-text('New Mail')",
            ".zmCnew",
            "text='New Mail'",
        ]
        clicked = False
        for sel in compose_selectors:
            try:
                loc = page.locator(sel).first
                if loc.is_visible(timeout=3000):
                    loc.click()
                    clicked = True
                    break
            except Exception:
                continue

        if not clicked:
            # Try keyboard shortcut
            page.keyboard.press("n")
            time.sleep(2)
            clicked = True

        time.sleep(3)

        # Fill TO field
        to_selectors = [
            "input[placeholder*='To']",
            "input[aria-label*='To']",
            "textarea[placeholder*='To']",
            ".zmdrop input",
            "[data-type='to'] input",
            "input.zmCTo",
        ]
        to_filled = False
        for sel in to_selectors:
            try:
                loc = page.locator(sel).first
                if loc.is_visible(timeout=3000):
                    loc.click()
                    loc.fill(to)
                    page.keyboard.press("Tab")
                    to_filled = True
                    break
            except Exception:
                continue

        if not to_filled:
            # Fallback: tab into To field and type
            page.keyboard.press("Tab")
            time.sleep(0.5)
            page.keyboard.type(to, delay=10)
            page.keyboard.press("Tab")

        time.sleep(1)

        # Fill Subject
        subject_selectors = [
            "input[placeholder*='Subject']",
            "input[aria-label*='Subject']",
            "input.zmCSub",
            "[data-type='subject'] input",
        ]
        subj_filled = False
        for sel in subject_selectors:
            try:
                loc = page.locator(sel).first
                if loc.is_visible(timeout=3000):
                    loc.click()
                    loc.fill(subject)
                    subj_filled = True
                    break
            except Exception:
                continue

        if not subj_filled:
            page.keyboard.type(subject, delay=10)

        time.sleep(1)

        # Fill Body — rich text editor
        body_selectors = [
            "[contenteditable='true'].ze_area",
            "iframe.ze_body",
            "[contenteditable='true'][role='textbox']",
            ".ze_area",
            "[contenteditable='true']",
        ]
        body_filled = False
        for sel in body_selectors:
            try:
                loc = page.locator(sel).first
                if loc.is_visible(timeout=3000):
                    loc.click()
                    time.sleep(0.5)
                    page.keyboard.type(body, delay=3)
                    body_filled = True
                    break
            except Exception:
                continue

        # Try iframe approach if contenteditable didn't work
        if not body_filled:
            try:
                frames = page.frames
                for frame in frames:
                    try:
                        editor = frame.locator("[contenteditable='true']").first
                        if editor.is_visible(timeout=2000):
                            editor.click()
                            frame.locator("[contenteditable='true']").first.type(body, delay=3)
                            body_filled = True
                            break
                    except Exception:
                        continue
            except Exception:
                pass

        if not body_filled:
            print("WARNING: Could not fill email body. Email may be incomplete.")

        time.sleep(2)

        if draft_only:
            # Save as draft — Ctrl+S or click Save
            page.keyboard.press("Control+s" if sys.platform != "darwin" else "Meta+s")
            time.sleep(2)
            print("DRAFT SAVED: Email saved as draft in Zoho Mail")
            context.close()
            return True

        # Click Send
        send_selectors = [
            "button:has-text('Send')",
            "[data-action='send']",
            "button.zmCSend",
            "text='Send'",
        ]
        sent = False
        for sel in send_selectors:
            try:
                btn = page.locator(sel).first
                if btn.is_visible(timeout=3000):
                    btn.click()
                    sent = True
                    break
            except Exception:
                continue

        if not sent:
            print("ERROR: Could not find Send button")
            context.close()
            return False

        # ── VERIFY: Check for Zoho's "Message sent" confirmation ──
        time.sleep(3)
        confirmed = False
        try:
            # Zoho Mail shows a confirmation toast/banner after successful send
            confirm_selectors = [
                "text='Message sent'",
                "text='Sent successfully'",
                "div.zmNotifMsg:has-text('sent')",
                "span:has-text('Message sent')",
                "div.ztag-notif:has-text('sent')",
            ]
            for sel in confirm_selectors:
                try:
                    loc = page.locator(sel)
                    if loc.count() > 0 and loc.first.is_visible(timeout=5000):
                        confirmed = True
                        break
                except Exception:
                    continue

            # Also check if compose window closed (Zoho closes it on success)
            if not confirmed:
                time.sleep(3)
                compose_area = page.locator("div.zmComposeBox, div.zmeditarea, div[role='textbox']")
                if compose_area.count() == 0 or not compose_area.first.is_visible(timeout=3000):
                    confirmed = True  # Compose area gone = email was sent
        except Exception:
            pass

        if confirmed:
            print(f"SENT: Email to {to} — Subject: {subject} (confirmed)")
            context.close()
            return True
        else:
            print(f"ERROR: Email to {to} — Send clicked but no confirmation received")
            try:
                screenshot_path = str(LOG_DIR / f"zoho-error-unconfirmed-{int(time.time())}.png")
                page.screenshot(path=screenshot_path)
                print(f"Debug screenshot: {screenshot_path}")
            except Exception:
                pass
            context.close()
            return False

    except Exception as e:
        print(f"ERROR: Failed to send email: {e}")
        try:
            screenshot_path = str(LOG_DIR / f"zoho-error-{int(time.time())}.png")
            page.screenshot(path=screenshot_path)
            print(f"Debug screenshot saved: {screenshot_path}")
        except Exception:
            pass
        context.close()
        return False


def log_action(action, to, subject, success):
    """Log email action."""
    from datetime import datetime
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    date_str = datetime.now().strftime("%Y-%m-%d")
    log_file = LOG_DIR / f"email-actions-{date_str}.jsonl"
    entry = {
        "date": date_str,
        "time": datetime.now().strftime("%H:%M:%S"),
        "platform": "zoho",
        "action": action,
        "to": to,
        "subject": subject,
        "success": success,
    }
    with open(log_file, "a") as f:
        f.write(json.dumps(entry) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Send email via Zoho Mail browser automation")
    parser.add_argument("--login", action="store_true", help="Open browser for manual login")
    parser.add_argument("--check", action="store_true", help="Check if session is valid")
    parser.add_argument("--to", type=str, help="Recipient email address")
    parser.add_argument("--subject", type=str, help="Email subject")
    parser.add_argument("--body", type=str, default="", help="Email body text")
    parser.add_argument("--draft", action="store_true", help="Save as draft instead of sending")
    parser.add_argument("--visible", action="store_true", help="Show browser window")
    parser.add_argument("--dry-run", action="store_true", help="Show email details without sending")
    args = parser.parse_args()

    with get_playwright() as pw:
        if args.login:
            do_login(pw)
            return

        if args.check:
            valid = check_session(pw)
            sys.exit(0 if valid else 1)

        if not args.to or not args.subject:
            print("ERROR: Provide --to and --subject")
            parser.print_help()
            sys.exit(1)

        print(f"To: {args.to}")
        print(f"Subject: {args.subject}")
        print(f"Body: {args.body[:200]}...")
        print(f"Mode: {'DRAFT' if args.draft else 'SEND'}")

        if args.dry_run:
            print("\n[DRY RUN] Would send the above email")
            return

        action = "draft" if args.draft else "sent"
        success = send_email(pw, args.to, args.subject, args.body,
                           draft_only=args.draft, headless=not args.visible)
        log_action(action if success else "failed", args.to, args.subject, success)

        if not success:
            sys.exit(1)


if __name__ == "__main__":
    main()
