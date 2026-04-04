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

# Import sanitizer and policy gate
sys.path.insert(0, str(Path(__file__).parent))
from sanitize_post import sanitize, validate
from direct_post_gate import gate_direct_post

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
    """Open browser for manual login. User logs in, we save the session."""
    print("Opening LinkedIn for manual login...")
    print("Log in with your credentials. The session will be saved automatically.")
    print("Close the browser window when done.")

    context = launch_browser(pw, headless=False)
    page = context.pages[0] if context.pages else context.new_page()
    page.goto("https://www.linkedin.com/login", wait_until="domcontentloaded", timeout=60000)

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
        page.goto("https://www.linkedin.com/feed/", wait_until="domcontentloaded", timeout=30000)
        page.wait_for_timeout(3000)
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

def post_to_linkedin(pw, text, headless=True, image_path=None):
    """Post text content to LinkedIn, optionally with an image."""
    if not text or len(text.strip()) < 10:
        print("ERROR: Post text too short or empty")
        return False

    if image_path and not Path(image_path).exists():
        print(f"WARNING: Image not found at {image_path}, posting without image")
        image_path = None

    context = launch_browser(pw, headless=headless)
    page = context.pages[0] if context.pages else context.new_page()

    try:
        # Navigate to feed
        page.goto("https://www.linkedin.com/feed/", wait_until="domcontentloaded", timeout=30000)

        # Check if logged in
        if "/login" in page.url or "/authwall" in page.url:
            print("ERROR: Not logged in. Run: python3 post_linkedin.py --login")
            context.close()
            return False

        time.sleep(2)

        # Click "Start a post" area — try multiple selectors for LinkedIn's changing UI
        start_selectors = [
            "div.share-box-feed-entry__trigger",
            "button:has-text('Start a post')",
            "text='Start a post'",
            ".share-box-feed-entry__closed-share-box",
            "[data-control-name='share.sharebox_feed']",
        ]
        clicked = False
        for sel in start_selectors:
            try:
                loc = page.locator(sel).first
                if loc.is_visible(timeout=2000):
                    loc.click()
                    clicked = True
                    break
            except Exception:
                continue

        if not clicked:
            # Fallback: click coordinates near "Start a post" text
            start_text = page.get_by_text("Start a post")
            if start_text.first.is_visible(timeout=3000):
                start_text.first.click()
                clicked = True

        if not clicked:
            print("ERROR: Could not find 'Start a post' button")
            context.close()
            return False

        time.sleep(3)

        # Wait for the post editor modal — try multiple selectors
        editor_selectors = [
            "div.ql-editor[contenteditable='true']",
            "div[role='textbox'][contenteditable='true']",
            "[contenteditable='true'][data-placeholder]",
            ".editor-content [contenteditable='true']",
        ]
        editor = None
        for sel in editor_selectors:
            try:
                loc = page.locator(sel).first
                loc.wait_for(state="visible", timeout=5000)
                editor = loc
                break
            except Exception:
                continue

        if not editor:
            print("ERROR: Post editor did not appear")
            context.close()
            return False

        time.sleep(1)

        # Type the post content
        editor.click()
        time.sleep(0.5)
        page.keyboard.type(text, delay=10)
        time.sleep(2)

        # Attach image if provided
        if image_path:
            try:
                file_input = page.locator("input[type='file'][accept*='image']")
                if file_input.count() > 0:
                    file_input.first.set_input_files(image_path)
                    print(f"Attached image: {image_path}")
                    time.sleep(3)
                else:
                    # Try clicking the image/media button first
                    media_btn = page.locator("button[aria-label*='media'], button[aria-label*='photo'], button[aria-label*='image']")
                    if media_btn.count() > 0:
                        media_btn.first.click()
                        time.sleep(1)
                        file_input = page.locator("input[type='file']")
                        if file_input.count() > 0:
                            file_input.first.set_input_files(image_path)
                            print(f"Attached image: {image_path}")
                            time.sleep(3)
            except Exception as e:
                print(f"WARNING: Could not attach image: {e}")

        # Click the Post button — find the submit button in the modal
        post_selectors = [
            "button.share-actions__primary-action",
            "button:has-text('Post'):not(:has-text('Repost'))",
            "button[data-control-name='share.post']",
        ]
        posted = False
        for sel in post_selectors:
            try:
                btn = page.locator(sel).first
                if btn.is_visible(timeout=3000):
                    btn.click()
                    posted = True
                    break
            except Exception:
                continue

        if not posted:
            # Last resort: find any enabled Post button in modal
            try:
                btn = page.get_by_role("button", name="Post").first
                btn.click()
                posted = True
            except Exception:
                print("ERROR: Could not find Post button")
                context.close()
                return False

        time.sleep(5)

        # Verify — check if modal closed
        try:
            editor.wait_for(state="hidden", timeout=15000)
            print("POSTED: LinkedIn post published successfully")
            context.close()
            return True
        except Exception:
            print("WARNING: Could not confirm modal closed. Post may have been sent — check LinkedIn.")
            context.close()
            return True

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
    parser.add_argument("--image", type=str, help="Image file to attach to post")
    parser.add_argument("--visible", action="store_true", help="Show browser window (not headless)")
    parser.add_argument("--dry-run", action="store_true", help="Extract and show text without posting")
    parser.add_argument("--allow-direct-post", action="store_true",
                        help="Required for direct invocation (bypass publish.sh). Still enforces policy.")
    args = parser.parse_args()

    # ── Policy gate: enforce platform policy before any posting ──
    gate_direct_post(platform="linkedin", args=args)

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

        # Sanitize content before posting — strip any leaked metadata/JSON
        text, sanitize_issues = sanitize(text)
        if sanitize_issues:
            print(f"SANITIZE: Fixed {len(sanitize_issues)} issues: {sanitize_issues}")
        is_clean, problems = validate(text)
        if not is_clean:
            print(f"WARNING: Post may contain internal artifacts: {problems}")
            if any('json_metadata_block' in p for p in problems):
                print("ERROR: JSON metadata detected in post — aborting")
                sys.exit(1)

        print(f"Content ({len(text)} chars):")
        print(f"---\n{text[:500]}\n---")

        if args.dry_run:
            print("\n[DRY RUN] Would post the above to LinkedIn")
            return

        # Post
        success = post_to_linkedin(pw, text, headless=not args.visible, image_path=args.image)
        log_posting("linkedin", source_file, success, text[:100])

        if success:
            print("Done. Content posted to LinkedIn.")
        else:
            print("Failed. Check logs and retry.")
            sys.exit(1)

if __name__ == "__main__":
    main()
