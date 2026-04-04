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

# Import sanitizer and policy gate
sys.path.insert(0, str(Path(__file__).parent))
from sanitize_post import sanitize, validate
from direct_post_gate import gate_direct_post

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
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        args=[
            "--disable-blink-features=AutomationControlled",
            "--disable-dev-shm-usage",
        ],
    )
    # Remove navigator.webdriver flag to avoid detection
    for page in context.pages:
        page.add_init_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
    context.on("page", lambda p: p.add_init_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"))
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

def _dismiss_x_overlays(page):
    """Dismiss common X overlays: Premium upsell, notifications, cookie banners."""
    for _ in range(2):
        try:
            # Premium upsell overlay — close button
            close_btns = page.locator("[aria-label='Close'], [data-testid='xMigrationBottomBar'] button, button[aria-label='Close']")
            if close_btns.count() > 0 and close_btns.first.is_visible(timeout=500):
                close_btns.first.click()
                time.sleep(0.5)
        except Exception:
            pass
        try:
            # "Not now" / "Maybe later" / "Dismiss" buttons
            dismiss = page.locator("button:has-text('Not now'), button:has-text('Maybe later'), button:has-text('Dismiss')")
            if dismiss.count() > 0 and dismiss.first.is_visible(timeout=500):
                dismiss.first.click()
                time.sleep(0.5)
        except Exception:
            pass
        try:
            # Any generic overlay backdrop
            backdrop = page.locator("[data-testid='sheetDialog'] [aria-label='Close']")
            if backdrop.count() > 0 and backdrop.first.is_visible(timeout=500):
                backdrop.first.click()
                time.sleep(0.5)
        except Exception:
            pass


def _wait_for_media_upload(page, timeout=30):
    """Wait for media upload to complete on X compose dialog."""
    start = time.time()
    while time.time() - start < timeout:
        try:
            # Check for upload progress indicators
            progress = page.locator("[role='progressbar'], [data-testid='progressBar']")
            if progress.count() == 0:
                # No progress bar — upload either done or not started
                time.sleep(1)
                # Double-check: wait a bit and verify still no progress
                if progress.count() == 0:
                    print("Media upload complete (no progress indicator)")
                    return True
            else:
                time.sleep(1)
        except Exception:
            time.sleep(1)
    print("WARNING: Media upload may not have completed within timeout")
    return False


def post_tweet(pw, text, headless=True, image_path=None):
    if not text or len(text.strip()) < 5:
        print("ERROR: Tweet text too short")
        return False

    if len(text) > MAX_TWEET_LEN:
        print(f"WARNING: Text is {len(text)} chars, truncating to {MAX_TWEET_LEN}")
        text = text[:MAX_TWEET_LEN - 3] + "..."

    if image_path and not Path(image_path).exists():
        print(f"WARNING: Image not found at {image_path}, posting without image")
        image_path = None

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
        time.sleep(0.5)

        # ── Dismiss any popups/overlays BEFORE typing ──
        _dismiss_x_overlays(page)

        # Use insertText for reliability (avoids hashtag autocomplete dropdown)
        page.evaluate("""(text) => {
            const editor = document.querySelector("div[role='textbox'][contenteditable='true']");
            if (editor) {
                editor.focus();
                document.execCommand('insertText', false, text);
            }
        }""", text)
        time.sleep(2)

        # ── Aggressively dismiss autocomplete dropdowns ──
        # The #1 failure cause: hashtag/emoji autocomplete blocking the Post button
        for _ in range(3):
            page.keyboard.press("Escape")
            time.sleep(0.3)
        # Click outside the editor to close any remaining dropdowns
        page.mouse.click(640, 100)
        time.sleep(0.5)
        # Re-focus shouldn't be needed since text is already entered

        # ── Dismiss overlays again (Premium upsell, notifications) ──
        _dismiss_x_overlays(page)

        # Attach image if provided
        if image_path:
            file_input = page.locator("input[type='file'][accept*='image']")
            if file_input.count() > 0:
                file_input.first.set_input_files(image_path)
                print(f"Attached image: {image_path}")
                # Wait for upload to complete — check for progress indicator
                _wait_for_media_upload(page)
            else:
                print("WARNING: Could not find image upload input, posting text only")

        time.sleep(2)

        # ── Final overlay dismissal before clicking Post ──
        _dismiss_x_overlays(page)

        # Click Post button
        post_btn = page.locator("button[data-testid='tweetButton']")
        post_btn.first.wait_for(state="visible", timeout=10000)
        time.sleep(1)

        # Dismiss any last-moment dropdowns
        page.keyboard.press("Escape")
        time.sleep(0.3)

        post_btn.first.click(force=True)
        time.sleep(4)

        # ── VERIFY: Did the tweet actually post? ──
        # Step 1: Check if compose dialog closed (basic signal)
        modal_closed = False
        try:
            editor.first.wait_for(state="hidden", timeout=15000)
            modal_closed = True
        except Exception:
            pass

        if not modal_closed:
            # Retry: dismiss overlays and click Post again
            try:
                _dismiss_x_overlays(page)
                page.keyboard.press("Escape")
                time.sleep(0.5)
                post_btn2 = page.locator("button[data-testid='tweetButton']")
                if post_btn2.count() > 0 and post_btn2.first.is_visible():
                    print("WARNING: First Post click failed, retrying...")
                    post_btn2.first.click(force=True)
                    time.sleep(5)
                    try:
                        editor.first.wait_for(state="hidden", timeout=10000)
                        modal_closed = True
                    except Exception:
                        pass
            except Exception:
                pass

        if not modal_closed:
            # Compose dialog still open — definitively failed
            print("ERROR: Tweet NOT posted — compose dialog still open after retry")
            try:
                screenshot_path = str(POSTING_LOG / f"x-error-{int(time.time())}.png")
                page.screenshot(path=screenshot_path)
                print(f"Debug screenshot: {screenshot_path}")
            except Exception:
                pass
            context.close()
            return False

        # Step 2: Verify on home feed — modal closed is necessary but not sufficient
        time.sleep(3)
        try:
            page.goto("https://x.com/home", wait_until="domcontentloaded", timeout=15000)
            time.sleep(4)
            # Check if our tweet text appears in the first few feed items
            feed_text = page.locator("article div[data-testid='tweetText']").all_text_contents()
            snippet = text[:50]
            for item in feed_text[:5]:
                if snippet[:30] in item:
                    print("POSTED: Tweet verified on home feed")
                    context.close()
                    return True
            # If not found, still return True since modal closed (X's feed loads async)
            print("POSTED: Tweet submitted (modal closed, feed verification inconclusive)")
            context.close()
            return True
        except Exception:
            # Feed check failed but modal DID close — cautious success
            print("POSTED: Tweet submitted (modal closed, feed check skipped)")
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
            time.sleep(0.5)
            # Use insertText to avoid hashtag autocomplete dropdown
            page.evaluate("""(text) => {
                const editors = document.querySelectorAll("div[role='textbox'][contenteditable='true']");
                const editor = editors[editors.length - 1];
                if (editor) {
                    editor.focus();
                    document.execCommand('insertText', false, text);
                }
            }""", tweet_text)
            time.sleep(1)
            page.keyboard.press("Escape")
            time.sleep(0.5)

            if i < len(tweets) - 1:
                # Click "Add another tweet" button
                add_btn = page.locator("button[data-testid='addButton'], button:has-text('Add')")
                if add_btn.count() > 0:
                    add_btn.first.click()
                    time.sleep(1)

        time.sleep(2)
        # Click Post all
        post_btn = page.locator("button[data-testid='tweetButton'], button:has-text('Post'), button:has-text('Tweet')")
        post_btn.first.click(force=True)
        time.sleep(5)

        # Verify thread was posted
        editor = page.locator("div[role='textbox'][contenteditable='true']")
        if editor.count() == 0 or "/compose" not in page.url:
            print(f"POSTED: Thread with {len(tweets)} tweets published (verified)")
            context.close()
            return True
        else:
            print(f"ERROR: Thread may not have posted — compose still open")
            screenshot_path = str(POSTING_LOG / f"x-error-{int(time.time())}.png")
            try:
                page.screenshot(path=screenshot_path)
                print(f"Debug screenshot: {screenshot_path}")
            except Exception:
                pass
            context.close()
            return False

    except Exception as e:
        print(f"ERROR: Failed to post thread: {e}")
        try:
            screenshot_path = str(POSTING_LOG / f"x-error-{int(time.time())}.png")
            page.screenshot(path=screenshot_path)
            print(f"Debug screenshot: {screenshot_path}")
        except Exception:
            pass
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
    parser.add_argument("--image", type=str, help="Image file to attach to tweet")
    parser.add_argument("--thread", action="store_true", help="Post as thread (from file)")
    parser.add_argument("--visible", action="store_true", help="Show browser window")
    parser.add_argument("--dry-run", action="store_true", help="Show text without posting")
    parser.add_argument("--allow-direct-post", action="store_true",
                        help="Required for direct invocation. Still enforces policy.")
    args = parser.parse_args()

    # ── Policy gate: enforce platform policy before any posting ──
    gate_direct_post(platform="x", args=args)

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

        # Sanitize content before posting — strip any leaked metadata/JSON
        text, sanitize_issues = sanitize(text)
        if sanitize_issues:
            print(f"SANITIZE: Fixed {len(sanitize_issues)} issues: {sanitize_issues}")
        # Also sanitize thread tweets if present
        if thread:
            clean_thread = []
            for tweet in thread:
                clean_tweet, _ = sanitize(str(tweet))
                clean_thread.append(clean_tweet)
            thread = clean_thread

        is_clean, problems = validate(text)
        if not is_clean and any('json_metadata_block' in p for p in problems):
            print(f"ERROR: JSON metadata detected in tweet — aborting: {problems}")
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
            success = post_tweet(pw, text, headless=not args.visible, image_path=args.image)
            log_posting("x", source_file, success, text[:100])

        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
