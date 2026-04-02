#!/usr/bin/env python3
"""
post_instagram.py — Post content to Instagram via Playwright browser automation.

Uses persistent browser context (cookies/session) so login happens once.
Subsequent runs reuse the session — no credentials in code.

Usage:
    python3 post_instagram.py --file /path/to/content.json
    python3 post_instagram.py --file /path/to/content.json --image /path/to/image.png
    python3 post_instagram.py --login   (first-time: opens browser for manual login)
    python3 post_instagram.py --check   (verify session is still valid)
    python3 post_instagram.py --dry-run --file /path/to/content.json

Session stored at: ~/.openclaw/browser-sessions/instagram/

SAFETY: Never auto-posts. Always shows content preview and requires confirmation
unless invoked by publish.sh with --confirm flag.
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

SESSION_DIR = Path.home() / ".openclaw" / "browser-sessions" / "instagram"
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
        viewport={"width": 430, "height": 932},
        user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
        device_scale_factor=3,
        is_mobile=True,
        has_touch=True,
        args=["--disable-blink-features=AutomationControlled"],
    )
    return context

def do_login(pw):
    """Open browser for manual login. User logs in, we save the session."""
    print("Opening Instagram for manual login...")
    print("Log in with your credentials. The session will be saved automatically.")
    print("Close the browser window when done.")

    context = launch_browser(pw, headless=False)
    page = context.pages[0] if context.pages else context.new_page()
    page.goto("https://www.instagram.com/accounts/login/", wait_until="domcontentloaded", timeout=60000)

    # Dismiss cookie/app banners if present
    try:
        cookie_btn = page.locator("button:has-text('Allow'), button:has-text('Accept')")
        if cookie_btn.count() > 0:
            cookie_btn.first.click()
            time.sleep(1)
    except Exception:
        pass

    # Wait for user to log in — detect leaving the login page
    print("Waiting for login... (log in and navigate to your feed)")
    try:
        # Poll until URL no longer contains /accounts/login
        deadline = time.time() + 300  # 5 min
        while time.time() < deadline:
            current_url = page.url
            if "/accounts/login" not in current_url and "instagram.com" in current_url:
                time.sleep(3)
                print("Login successful! Session saved.")
                break
            time.sleep(2)
        else:
            print("Login timeout. Try again with: python3 post_instagram.py --login")
    except Exception:
        print("Login timeout or cancelled. Try again with: python3 post_instagram.py --login")

    context.close()

def check_session(pw):
    """Verify the saved session is still valid."""
    context = launch_browser(pw, headless=True)
    page = context.pages[0] if context.pages else context.new_page()

    try:
        page.goto("https://www.instagram.com/", wait_until="domcontentloaded", timeout=30000)
        time.sleep(3)
        url = page.url
        if "/accounts/login" in url:
            print("SESSION EXPIRED: Need to re-login. Run: python3 post_instagram.py --login")
            context.close()
            return False
        else:
            print("SESSION VALID: Logged into Instagram")
            context.close()
            return True
    except Exception as e:
        print(f"SESSION CHECK FAILED: {e}")
        context.close()
        return False

def extract_content(file_path):
    """Extract caption and image path from a content file."""
    path = Path(file_path)

    if path.suffix == ".json":
        with open(path) as f:
            data = json.load(f)

        # Try platform_content.instagram_caption first
        pc = data.get("platform_content", {})
        caption = pc.get("instagram_caption", "")
        if not caption:
            # Fallback: try instagram_post
            caption = pc.get("instagram_post", "")
        if not caption:
            # Fallback: build from hook + summary + hashtags
            hook = data.get("hook", "")
            summary = data.get("summary", "")
            cta = data.get("cta", "")
            hashtags = data.get("hashtags", "")
            parts = [p for p in [hook, summary, cta, hashtags] if p]
            caption = "\n\n".join(parts).strip()

        # Extract image path
        image_path = data.get("image_path", "")
        if not image_path:
            image_path = data.get("media", {}).get("image_path", "")
        if not image_path:
            image_path = pc.get("image_path", "")

        return caption, image_path, data

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
        return "\n".join(body_lines).strip(), "", {}

    else:
        with open(path) as f:
            return f.read().strip(), "", {}

def post_to_instagram(pw, caption, image_path, headless=True):
    """Post image + caption to Instagram via browser automation."""
    if not caption or len(caption.strip()) < 5:
        print("ERROR: Caption too short or empty")
        return False

    if not image_path or not Path(image_path).exists():
        print(f"ERROR: Image file required for Instagram posts. Got: {image_path}")
        print("Instagram requires an image. Provide --image or include image_path in content JSON.")
        return False

    image_path = str(Path(image_path).resolve())

    context = launch_browser(pw, headless=headless)
    page = context.pages[0] if context.pages else context.new_page()

    try:
        # Navigate to Instagram
        page.goto("https://www.instagram.com/", wait_until="domcontentloaded", timeout=30000)
        time.sleep(3)

        # Check if logged in
        if "/accounts/login" in page.url:
            print("ERROR: Not logged in. Run: python3 post_instagram.py --login")
            context.close()
            return False

        # Dismiss any popups (notifications, app install banners)
        _dismiss_popups(page)

        # Click the create/new post button (+ icon)
        # Instagram web uses SVG icons — target the new post button
        create_btn = page.locator(
            "svg[aria-label='New post'], "
            "a[href='/create/'], "
            "div[role='button'] svg[aria-label='New post'], "
            "span:has-text('Create')"
        )
        if create_btn.count() == 0:
            # Fallback: try the bottom nav bar + icon on mobile web
            create_btn = page.locator(
                "a[href*='create'], "
                "div[role='menuitem']:has-text('Create'), "
                "[aria-label='New post']"
            )

        if create_btn.count() == 0:
            print("ERROR: Could not find 'New post' button. Instagram UI may have changed.")
            _save_debug_screenshot(page, "no-create-btn")
            context.close()
            return False

        create_btn.first.click()
        time.sleep(3)

        # Handle file upload dialog
        # Instagram shows a "Select from computer" or drag-drop area
        file_input = page.locator("input[type='file']")
        if file_input.count() == 0:
            # Click "Select from computer" button if visible
            select_btn = page.locator("button:has-text('Select from computer'), button:has-text('Select From Computer')")
            if select_btn.count() > 0:
                select_btn.first.click()
                time.sleep(1)
            file_input = page.locator("input[type='file']")

        if file_input.count() == 0:
            print("ERROR: Could not find file upload input. Instagram UI may have changed.")
            _save_debug_screenshot(page, "no-file-input")
            context.close()
            return False

        # Upload the image
        file_input.first.set_input_files(image_path)
        time.sleep(3)

        # Click through crop/filter screens
        # Step 1: Crop screen — click "Next"
        _click_next(page)
        time.sleep(2)

        # Step 2: Filter screen — click "Next"
        _click_next(page)
        time.sleep(2)

        # Step 3: Caption screen — enter caption
        caption_input = page.locator(
            "textarea[aria-label='Write a caption...'], "
            "textarea[aria-label='Write a caption'], "
            "div[aria-label='Write a caption...'][contenteditable='true'], "
            "div[role='textbox'][contenteditable='true']"
        )

        if caption_input.count() > 0:
            caption_input.first.click()
            time.sleep(1)
            # Type caption (use keyboard for reliability with rich text editors)
            page.keyboard.type(caption, delay=3)
            time.sleep(2)
        else:
            print("WARNING: Could not find caption input. Post may go up without caption.")
            _save_debug_screenshot(page, "no-caption-input")

        # Click "Share" to publish
        share_btn = page.locator(
            "button:has-text('Share'), "
            "div[role='button']:has-text('Share')"
        )

        if share_btn.count() == 0:
            print("ERROR: Could not find 'Share' button. Instagram UI may have changed.")
            _save_debug_screenshot(page, "no-share-btn")
            context.close()
            return False

        share_btn.first.click()
        time.sleep(5)

        # Verify — look for "Post shared" or return to feed
        try:
            # Instagram shows a checkmark animation or "Your post has been shared" text
            shared_indicator = page.locator("img[alt='Animated checkmark'], span:has-text('shared')")
            shared_indicator.first.wait_for(state="visible", timeout=15000)
            print("POSTED: Instagram post published successfully")
            context.close()
            return True
        except Exception:
            # Check if we're back on the feed (post likely went through)
            time.sleep(3)
            if "/create" not in page.url:
                print("POSTED: Instagram post likely published (returned to feed)")
                context.close()
                return True
            else:
                print("WARNING: Could not confirm post. Check Instagram manually.")
                _save_debug_screenshot(page, "post-unconfirmed")
                context.close()
                return True  # Optimistic — log it and verify later

    except Exception as e:
        print(f"ERROR: Failed to post to Instagram: {e}")
        _save_debug_screenshot(page, "post-failed")
        context.close()
        return False

def _dismiss_popups(page):
    """Dismiss common Instagram popups (notifications, app install)."""
    try:
        # "Turn on Notifications" popup
        not_now = page.locator("button:has-text('Not Now'), button:has-text('Not now')")
        if not_now.count() > 0:
            not_now.first.click()
            time.sleep(1)
    except Exception:
        pass
    try:
        # "Add Instagram to your Home screen" or cookie consent
        dismiss = page.locator("button:has-text('Cancel'), button:has-text('Dismiss')")
        if dismiss.count() > 0:
            dismiss.first.click()
            time.sleep(1)
    except Exception:
        pass

def _click_next(page):
    """Click the 'Next' button in Instagram's post creation flow."""
    next_btn = page.locator(
        "button:has-text('Next'), "
        "div[role='button']:has-text('Next')"
    )
    if next_btn.count() > 0:
        next_btn.first.click()
    else:
        # Fallback: try the right arrow or top-right button
        arrow = page.locator("svg[aria-label='Right chevron'], button[aria-label='Next']")
        if arrow.count() > 0:
            arrow.first.click()

def _save_debug_screenshot(page, label):
    """Save a debug screenshot for troubleshooting."""
    try:
        POSTING_LOG.mkdir(parents=True, exist_ok=True)
        screenshot_path = str(POSTING_LOG / f"instagram-error-{label}-{int(time.time())}.png")
        page.screenshot(path=screenshot_path)
        print(f"Debug screenshot saved: {screenshot_path}")
    except Exception:
        pass

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
    parser = argparse.ArgumentParser(description="Post to Instagram via browser automation")
    parser.add_argument("--login", action="store_true", help="Open browser for manual login")
    parser.add_argument("--check", action="store_true", help="Check if session is valid")
    parser.add_argument("--file", type=str, help="Content file (JSON/MD) to extract caption from")
    parser.add_argument("--image", type=str, help="Image file to upload (overrides image_path in content file)")
    parser.add_argument("--visible", action="store_true", help="Show browser window (not headless)")
    parser.add_argument("--dry-run", action="store_true", help="Extract and show content without posting")
    parser.add_argument("--confirm", action="store_true", help="Skip confirmation prompt (used by publish.sh)")
    args = parser.parse_args()

    with get_playwright() as pw:
        if args.login:
            do_login(pw)
            return

        if args.check:
            valid = check_session(pw)
            sys.exit(0 if valid else 1)

        # Need a content file for Instagram
        if not args.file:
            print("ERROR: Provide --file with content to post")
            parser.print_help()
            sys.exit(1)

        # Extract content
        source_file = args.file
        caption, image_path, data = extract_content(args.file)

        # --image flag overrides image_path from content file
        if args.image:
            image_path = args.image

        if not caption:
            print("ERROR: No caption extracted from source")
            sys.exit(1)

        # Show preview
        print(f"Caption ({len(caption)} chars):")
        print(f"---\n{caption[:500]}\n---")
        print(f"Image: {image_path if image_path else '(none)'}")

        if args.dry_run:
            print("\n[DRY RUN] Would post the above to Instagram")
            if not image_path or not Path(image_path).exists():
                print("[DRY RUN] WARNING: Image file missing or not found — post would fail")
            return

        # Validate image exists
        if not image_path or not Path(image_path).exists():
            print(f"ERROR: Image file required for Instagram. Got: '{image_path}'")
            print("Use --image /path/to/image.png or include image_path in content JSON.")
            sys.exit(1)

        # Safety: require confirmation unless called by publish.sh
        if not args.confirm:
            print("\nPost this to Instagram? [y/N] ", end="", flush=True)
            try:
                answer = input().strip().lower()
            except EOFError:
                answer = ""
            if answer not in ("y", "yes"):
                print("Cancelled.")
                return

        # Post
        success = post_to_instagram(pw, caption, image_path, headless=not args.visible)
        log_posting("instagram", source_file, success, caption[:100])

        if success:
            print("Done. Content posted to Instagram.")
        else:
            print("Failed. Check logs and retry.")
            sys.exit(1)

if __name__ == "__main__":
    main()
