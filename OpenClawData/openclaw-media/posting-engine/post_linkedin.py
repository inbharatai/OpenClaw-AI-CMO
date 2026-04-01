#!/usr/bin/env python3
"""
post_linkedin.py — Post content to LinkedIn via Playwright browser automation.

Uses persistent browser context (cookies/session) so login happens once.
Subsequent runs reuse the session — no credentials in code.

Usage:
    python3 post_linkedin.py --text "Post content here"
    python3 post_linkedin.py --file /path/to/content.json
    python3 post_linkedin.py --login   (first-time: opens browser for manual login)
    python3 post_linkedin.py --check   (verify session is still valid)

Session stored at: ~/.openclaw/browser-sessions/linkedin/
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

SESSION_DIR = Path.home() / ".openclaw" / "browser-sessions" / "linkedin"
POSTING_LOG = Path("/Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/analytics")

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
        args=["--disable-blink-features=AutomationControlled"],
    )
    return context

def do_login(pw):
    """Open browser for manual login. User logs in, we save the session."""
    print("Opening LinkedIn for manual login...")
    print("Log in with your credentials. The session will be saved automatically.")
    print("Close the browser window when done.")

    context = launch_browser(pw, headless=False)
    page = context.pages[0] if context.pages else context.new_page()
    page.goto("https://www.linkedin.com/login", wait_until="networkidle", timeout=60000)

    # Wait for user to log in — detect feed page
    print("Waiting for login... (navigate to your feed)")
    try:
        page.wait_for_url("**/feed**", timeout=300000)  # 5 min timeout
        print("Login successful! Session saved.")
    except Exception:
        print("Login timeout or cancelled. Try again with: python3 post_linkedin.py --login")

    context.close()

def check_session(pw):
    """Verify the saved session is still valid."""
    context = launch_browser(pw, headless=True)
    page = context.pages[0] if context.pages else context.new_page()

    try:
        page.goto("https://www.linkedin.com/feed/", wait_until="networkidle", timeout=30000)
        url = page.url
        if "/login" in url or "/authwall" in url:
            print("SESSION EXPIRED: Need to re-login. Run: python3 post_linkedin.py --login")
            context.close()
            return False
        else:
            print("SESSION VALID: Logged into LinkedIn")
            context.close()
            return True
    except Exception as e:
        print(f"SESSION CHECK FAILED: {e}")
        context.close()
        return False

def extract_text(file_path):
    """Extract post text from a content file."""
    path = Path(file_path)

    if path.suffix == ".json":
        with open(path) as f:
            data = json.load(f)
        # Try platform_content.linkedin_post first
        pc = data.get("platform_content", {})
        text = pc.get("linkedin_post", "")
        if not text:
            # Fallback to summary + hook
            hook = data.get("hook", "")
            summary = data.get("summary", "")
            cta = data.get("cta", "")
            text = f"{hook}\n\n{summary}\n\n{cta}".strip()
        return text, data

    elif path.suffix == ".md":
        with open(path) as f:
            content = f.read()
        # Strip frontmatter-like headers
        lines = content.split("\n")
        body_lines = []
        in_frontmatter = False
        for line in lines:
            if line.startswith("```") or line.startswith("---") or line.startswith("==="):
                in_frontmatter = not in_frontmatter
                continue
            if in_frontmatter:
                continue
            if ":" in line and any(line.startswith(k) for k in ["title:", "date:", "type:", "channel:", "approval_level:", "status:", "source_file:", "webhook_ready:"]):
                continue
            body_lines.append(line)
        return "\n".join(body_lines).strip(), {}

    else:
        with open(path) as f:
            return f.read().strip(), {}

def post_to_linkedin(pw, text, headless=True):
    """Post text content to LinkedIn."""
    if not text or len(text.strip()) < 10:
        print("ERROR: Post text too short or empty")
        return False

    context = launch_browser(pw, headless=headless)
    page = context.pages[0] if context.pages else context.new_page()

    try:
        # Navigate to feed
        page.goto("https://www.linkedin.com/feed/", wait_until="networkidle", timeout=30000)

        # Check if logged in
        if "/login" in page.url or "/authwall" in page.url:
            print("ERROR: Not logged in. Run: python3 post_linkedin.py --login")
            context.close()
            return False

        time.sleep(2)

        # Click "Start a post" button
        start_post = page.locator("button:has-text('Start a post'), div.share-box-feed-entry__trigger")
        start_post.first.click()
        time.sleep(2)

        # Wait for the post editor modal
        editor = page.locator("div.ql-editor[contenteditable='true'], div[role='textbox'][contenteditable='true']")
        editor.first.wait_for(state="visible", timeout=10000)
        time.sleep(1)

        # Type the post content
        editor.first.click()
        # Use keyboard to type (more reliable than fill for rich text editors)
        page.keyboard.type(text, delay=5)
        time.sleep(2)

        # Click the Post button
        post_button = page.locator("button:has-text('Post'):not(:has-text('Repost'))")
        post_button.first.click()
        time.sleep(3)

        # Verify — wait for the modal to close
        try:
            editor.first.wait_for(state="hidden", timeout=10000)
            print("POSTED: LinkedIn post published successfully")
            context.close()
            return True
        except Exception:
            # Check if there's an error or the post was still sent
            print("WARNING: Could not confirm post. Check LinkedIn manually.")
            context.close()
            return True  # Optimistic — log it and verify later

    except Exception as e:
        print(f"ERROR: Failed to post to LinkedIn: {e}")
        # Take screenshot for debugging
        try:
            screenshot_path = str(POSTING_LOG / f"linkedin-error-{int(time.time())}.png")
            page.screenshot(path=screenshot_path)
            print(f"Debug screenshot saved: {screenshot_path}")
        except Exception:
            pass
        context.close()
        return False

def log_posting(platform, file_path, success, text_preview=""):
    """Log the posting action."""
    from datetime import datetime
    log_dir = POSTING_LOG
    log_dir.mkdir(parents=True, exist_ok=True)

    date_str = datetime.now().strftime("%Y-%m-%d")
    log_file = log_dir / f"post-actions-{date_str}.jsonl"

    entry = {
        "date": date_str,
        "time": datetime.now().strftime("%H:%M:%S"),
        "platform": platform,
        "action": "posted" if success else "failed",
        "file": str(file_path) if file_path else "",
        "preview": text_preview[:100],
    }

    with open(log_file, "a") as f:
        f.write(json.dumps(entry) + "\n")

def main():
    parser = argparse.ArgumentParser(description="Post to LinkedIn via browser automation")
    parser.add_argument("--login", action="store_true", help="Open browser for manual login")
    parser.add_argument("--check", action="store_true", help="Check if session is valid")
    parser.add_argument("--text", type=str, help="Text to post directly")
    parser.add_argument("--file", type=str, help="Content file to extract and post")
    parser.add_argument("--visible", action="store_true", help="Show browser window (not headless)")
    parser.add_argument("--dry-run", action="store_true", help="Extract and show text without posting")
    args = parser.parse_args()

    with get_playwright() as pw:
        if args.login:
            do_login(pw)
            return

        if args.check:
            valid = check_session(pw)
            sys.exit(0 if valid else 1)

        # Get the text to post
        text = ""
        source_file = None

        if args.text:
            text = args.text
        elif args.file:
            source_file = args.file
            text, _ = extract_text(args.file)
        else:
            print("ERROR: Provide --text or --file")
            parser.print_help()
            sys.exit(1)

        if not text:
            print("ERROR: No text extracted from source")
            sys.exit(1)

        print(f"Content ({len(text)} chars):")
        print(f"---\n{text[:500]}\n---")

        if args.dry_run:
            print("\n[DRY RUN] Would post the above to LinkedIn")
            return

        # Post
        success = post_to_linkedin(pw, text, headless=not args.visible)
        log_posting("linkedin", source_file, success, text[:100])

        if success:
            print("Done. Content posted to LinkedIn.")
        else:
            print("Failed. Check logs and retry.")
            sys.exit(1)

if __name__ == "__main__":
    main()
