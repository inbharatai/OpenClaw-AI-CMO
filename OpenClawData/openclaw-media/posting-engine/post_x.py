#!/usr/bin/env python3
"""
post_x.py — Post content to X (Twitter) via Playwright browser automation.

Uses persistent browser context (cookies/session) so login happens once.

Usage:
    python3 post_x.py --text "Tweet content here"
    python3 post_x.py --file /path/to/content.json
    python3 post_x.py --login   (first-time: opens browser for manual login)
    python3 post_x.py --check   (verify session is still valid)
    python3 post_x.py --thread --file /path/to/thread-content.json

Session stored at: ~/.openclaw/browser-sessions/x/
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

SESSION_DIR = Path.home() / ".openclaw" / "browser-sessions" / "x"
POSTING_LOG = Path("/Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/analytics")
MAX_TWEET_LEN = 280

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
    ensure_session_dir()
    context = pw.chromium.launch_persistent_context(
        user_data_dir=str(SESSION_DIR),
        headless=headless,
        viewport={"width": 1280, "height": 900},
        args=["--disable-blink-features=AutomationControlled"],
    )
    return context

def do_login(pw):
    print("Opening X (Twitter) for manual login...")
    print("Log in with your credentials. Close the browser when done.")

    context = launch_browser(pw, headless=False)
    page = context.pages[0] if context.pages else context.new_page()
    page.goto("https://x.com/login", wait_until="domcontentloaded", timeout=60000)

    print("Waiting for login... (navigate to your home feed)")
    try:
        page.wait_for_url("**/home**", timeout=300000)
        print("Login successful! Session saved.")
    except Exception:
        print("Login timeout. Try again.")

    context.close()

def check_session(pw):
    context = launch_browser(pw, headless=True)
    page = context.pages[0] if context.pages else context.new_page()

    try:
        page.goto("https://x.com/home", wait_until="domcontentloaded", timeout=30000)
        url = page.url
        if "/login" in url or "/i/flow" in url:
            print("SESSION EXPIRED: Run: python3 post_x.py --login")
            context.close()
            return False
        else:
            print("SESSION VALID: Logged into X")
            context.close()
            return True
    except Exception as e:
        print(f"SESSION CHECK FAILED: {e}")
        context.close()
        return False

def extract_text(file_path):
    path = Path(file_path)

    if path.suffix == ".json":
        with open(path) as f:
            data = json.load(f)
        pc = data.get("platform_content", {})
        tweet = pc.get("x_tweet", "")
        thread = pc.get("x_thread", [])
        if not tweet:
            hook = data.get("hook", "")
            tweet = hook[:MAX_TWEET_LEN] if hook else data.get("summary", "")[:MAX_TWEET_LEN]
        return tweet, thread, data

    elif path.suffix == ".md":
        with open(path) as f:
            content = f.read()
        lines = content.split("\n")
        body_lines = []
        for line in lines:
            if line.startswith("```") or line.startswith("---") or line.startswith("==="):
                continue
            if ":" in line and any(line.startswith(k) for k in ["title:", "date:", "type:", "channel:", "approval_level:", "status:", "source_file:", "char_count:", "adapted_from:", "webhook_ready:"]):
                continue
            body_lines.append(line)
        text = "\n".join(body_lines).strip()
        if len(text) > MAX_TWEET_LEN:
            text = text[:MAX_TWEET_LEN - 3] + "..."
        return text, [], {}

    else:
        with open(path) as f:
            text = f.read().strip()
        return text[:MAX_TWEET_LEN], [], {}

def post_tweet(pw, text, headless=True):
    if not text or len(text.strip()) < 5:
        print("ERROR: Tweet text too short")
        return False

    if len(text) > MAX_TWEET_LEN:
        print(f"WARNING: Text is {len(text)} chars, truncating to {MAX_TWEET_LEN}")
        text = text[:MAX_TWEET_LEN - 3] + "..."

    context = launch_browser(pw, headless=headless)
    page = context.pages[0] if context.pages else context.new_page()

    try:
        page.goto("https://x.com/compose/post", wait_until="domcontentloaded", timeout=30000)
        time.sleep(2)

        if "/login" in page.url or "/i/flow" in page.url:
            print("ERROR: Not logged in. Run: python3 post_x.py --login")
            context.close()
            return False

        # Find the tweet compose box
        editor = page.locator("div[role='textbox'][contenteditable='true']")
        editor.first.wait_for(state="visible", timeout=10000)
        time.sleep(1)

        editor.first.click()
        page.keyboard.type(text, delay=5)
        time.sleep(2)

        # Click Post button
        post_btn = page.locator("button[data-testid='tweetButton'], button:has-text('Post')")
        post_btn.first.click()
        time.sleep(3)

        print("POSTED: Tweet published successfully")
        context.close()
        return True

    except Exception as e:
        print(f"ERROR: Failed to post tweet: {e}")
        try:
            screenshot_path = str(POSTING_LOG / f"x-error-{int(time.time())}.png")
            page.screenshot(path=screenshot_path)
            print(f"Debug screenshot: {screenshot_path}")
        except Exception:
            pass
        context.close()
        return False

def post_thread(pw, tweets, headless=True):
    """Post a thread of multiple tweets."""
    if not tweets or len(tweets) < 2:
        print("ERROR: Thread needs at least 2 tweets")
        return False

    context = launch_browser(pw, headless=headless)
    page = context.pages[0] if context.pages else context.new_page()

    try:
        page.goto("https://x.com/compose/post", wait_until="domcontentloaded", timeout=30000)
        time.sleep(2)

        if "/login" in page.url:
            print("ERROR: Not logged in. Run: python3 post_x.py --login")
            context.close()
            return False

        for i, tweet_text in enumerate(tweets):
            if len(tweet_text) > MAX_TWEET_LEN:
                tweet_text = tweet_text[:MAX_TWEET_LEN - 3] + "..."

            editor = page.locator("div[role='textbox'][contenteditable='true']")
            editor.last.wait_for(state="visible", timeout=10000)
            editor.last.click()
            page.keyboard.type(tweet_text, delay=5)
            time.sleep(1)

            if i < len(tweets) - 1:
                # Click "Add another tweet" button
                add_btn = page.locator("button[data-testid='addButton'], button:has-text('Add')")
                if add_btn.count() > 0:
                    add_btn.first.click()
                    time.sleep(1)

        time.sleep(1)
        # Click Post all
        post_btn = page.locator("button[data-testid='tweetButton'], button:has-text('Post')")
        post_btn.first.click()
        time.sleep(3)

        print(f"POSTED: Thread with {len(tweets)} tweets published")
        context.close()
        return True

    except Exception as e:
        print(f"ERROR: Failed to post thread: {e}")
        context.close()
        return False

def log_posting(platform, file_path, success, text_preview=""):
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
    parser = argparse.ArgumentParser(description="Post to X (Twitter) via browser automation")
    parser.add_argument("--login", action="store_true", help="Open browser for manual login")
    parser.add_argument("--check", action="store_true", help="Check if session is valid")
    parser.add_argument("--text", type=str, help="Tweet text to post")
    parser.add_argument("--file", type=str, help="Content file to extract and post")
    parser.add_argument("--thread", action="store_true", help="Post as thread (from file)")
    parser.add_argument("--visible", action="store_true", help="Show browser window")
    parser.add_argument("--dry-run", action="store_true", help="Show text without posting")
    args = parser.parse_args()

    with get_playwright() as pw:
        if args.login:
            do_login(pw)
            return

        if args.check:
            valid = check_session(pw)
            sys.exit(0 if valid else 1)

        text = ""
        thread = []
        source_file = None

        if args.text:
            text = args.text
        elif args.file:
            source_file = args.file
            text, thread, _ = extract_text(args.file)
        else:
            print("ERROR: Provide --text or --file")
            sys.exit(1)

        if args.dry_run:
            if args.thread and thread:
                print(f"[DRY RUN] Would post thread ({len(thread)} tweets):")
                for i, t in enumerate(thread):
                    print(f"  [{i+1}] {t}")
            else:
                print(f"[DRY RUN] Would post tweet ({len(text)} chars):")
                print(f"  {text}")
            return

        if args.thread and thread:
            success = post_thread(pw, thread, headless=not args.visible)
            log_posting("x", source_file, success, thread[0][:100] if thread else "")
        else:
            success = post_tweet(pw, text, headless=not args.visible)
            log_posting("x", source_file, success, text[:100])

        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
