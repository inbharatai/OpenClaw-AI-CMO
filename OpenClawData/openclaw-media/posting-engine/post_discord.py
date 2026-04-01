#!/usr/bin/env python3
"""
post_discord.py — Post content to Discord via webhook.

No browser needed — Discord webhooks are simple HTTP POST.

Usage:
    python3 post_discord.py --text "Message content"
    python3 post_discord.py --file /path/to/content.md
    python3 post_discord.py --setup   (configure webhook URL)
    python3 post_discord.py --check   (verify webhook works)

Webhook URL stored in macOS Keychain (service: openclaw, account: openclaw-discord-webhook)
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

POSTING_LOG = Path("/Volumes/Expansion/CMO-10million/OpenClawData/openclaw-media/analytics")

def get_webhook_url():
    """Read Discord webhook URL from macOS Keychain."""
    try:
        result = subprocess.run(
            ["security", "find-generic-password", "-s", "openclaw", "-a", "openclaw-discord-webhook", "-w"],
            capture_output=True, text=True, timeout=5
        )
        url = result.stdout.strip()
        if url and url.startswith("https://discord.com/api/webhooks/"):
            return url
        return None
    except Exception:
        return None

def store_webhook_url(url):
    """Store Discord webhook URL in macOS Keychain."""
    if not url.startswith("https://discord.com/api/webhooks/"):
        print("ERROR: Invalid webhook URL. Must start with https://discord.com/api/webhooks/")
        return False

    subprocess.run([
        "security", "add-generic-password",
        "-s", "openclaw", "-a", "openclaw-discord-webhook",
        "-w", url,
        "-U"  # Update if exists
    ], timeout=5)
    print("Webhook URL stored in Keychain.")
    return True

def extract_text(file_path):
    path = Path(file_path)

    if path.suffix == ".json":
        with open(path) as f:
            data = json.load(f)
        pc = data.get("platform_content", {})
        text = pc.get("discord_message", "")
        if not text:
            text = data.get("summary", data.get("hook", ""))
        # Ensure product links are present
        product = data.get("product", "").lower()
        text = ensure_links(text, product)
        return text

    elif path.suffix == ".md":
        with open(path) as f:
            content = f.read()
        lines = content.split("\n")
        body_lines = []
        for line in lines:
            if line.startswith("---") or line.startswith("==="):
                continue
            if ":" in line and any(line.startswith(k) for k in ["title:", "date:", "type:", "category:", "approval_level:", "status:", "source_file:", "webhook_ready:"]):
                continue
            body_lines.append(line)
        text = "\n".join(body_lines).strip()
        # Fix dangling CTAs like "Check it out →" with no link
        text = ensure_links(text)
        return text

    else:
        with open(path) as f:
            return f.read().strip()


# Product URL mapping
PRODUCT_LINKS = {
    "inbharat": "https://inbharat.ai",
    "phoring": "https://phoring.in",
    "testsprep": "https://testsprep.in",
    "uniassist": "https://uniassist.ai",
    "openclaw": "https://github.com/inbharatai/OpenClaw-AI-CMO",
    "sahaayak": "https://inbharat.ai",
    "sahaayak-seva": "https://inbharat.ai",
    "codein": "https://github.com/inbharatai",
    "agent-arcade": "https://github.com/inbharatai",
    "sahayak-os": "https://github.com/inbharatai",
}


def ensure_links(text, product=""):
    """Fix content that has dangling CTAs without links."""
    # If text already contains a URL, leave it alone
    if "https://" in text or "http://" in text:
        return text

    # Get product link
    link = PRODUCT_LINKS.get(product, "https://github.com/inbharatai/OpenClaw-AI-CMO")

    # Fix "Check it out →" or similar with no link
    import re
    text = re.sub(r'Check it out\s*→?\s*$', f'Check it out → {link}', text, flags=re.MULTILINE)
    text = re.sub(r'Learn more\s*→?\s*$', f'Learn more → {link}', text, flags=re.MULTILINE)

    # If no link anywhere, append GitHub
    if "https://" not in text:
        text += f"\n\n🔗 {link}"

    return text

def post_to_discord(webhook_url, text, username="InBharat Bot"):
    """Send message via Discord webhook using curl (avoids Cloudflare blocks on urllib)."""
    if not text:
        print("ERROR: No text to post")
        return False

    # Discord message limit is 2000 chars
    if len(text) > 2000:
        text = text[:1997] + "..."

    payload = json.dumps({
        "content": text,
        "username": username,
    })

    try:
        result = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}",
             "-X", "POST", webhook_url,
             "-H", "Content-Type: application/json",
             "-d", payload],
            capture_output=True, text=True, timeout=15
        )
        status_code = result.stdout.strip()
        if status_code in ("200", "204"):
            print("POSTED: Discord message sent successfully")
            return True
        else:
            print(f"ERROR: Discord returned status {status_code}")
            if result.stderr:
                print(f"  {result.stderr[:200]}")
            return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False

def log_posting(file_path, success, text_preview=""):
    from datetime import datetime
    log_dir = POSTING_LOG
    log_dir.mkdir(parents=True, exist_ok=True)

    date_str = datetime.now().strftime("%Y-%m-%d")
    log_file = log_dir / f"post-actions-{date_str}.jsonl"

    entry = {
        "date": date_str,
        "time": datetime.now().strftime("%H:%M:%S"),
        "platform": "discord",
        "action": "posted" if success else "failed",
        "file": str(file_path) if file_path else "",
        "preview": text_preview[:100],
    }

    with open(log_file, "a") as f:
        f.write(json.dumps(entry) + "\n")

def main():
    parser = argparse.ArgumentParser(description="Post to Discord via webhook")
    parser.add_argument("--setup", action="store_true", help="Configure webhook URL")
    parser.add_argument("--check", action="store_true", help="Test webhook connection")
    parser.add_argument("--text", type=str, help="Message to send")
    parser.add_argument("--file", type=str, help="Content file to extract and send")
    parser.add_argument("--dry-run", action="store_true", help="Show text without sending")
    args = parser.parse_args()

    if args.setup:
        url = input("Paste Discord webhook URL: ").strip()
        store_webhook_url(url)
        return

    webhook_url = get_webhook_url()
    if not webhook_url and not args.setup:
        print("ERROR: No Discord webhook configured.")
        print("Run: python3 post_discord.py --setup")
        print("Or:  bash credential-vault.sh store discord-webhook <url>")
        sys.exit(1)

    if args.check:
        success = post_to_discord(webhook_url, "OpenClaw health check - Discord webhook is working.")
        sys.exit(0 if success else 1)

    text = ""
    source_file = None

    if args.text:
        text = args.text
    elif args.file:
        source_file = args.file
        text = extract_text(args.file)
    else:
        print("ERROR: Provide --text or --file")
        sys.exit(1)

    if args.dry_run:
        print(f"[DRY RUN] Would send to Discord ({len(text)} chars):")
        print(f"---\n{text[:500]}\n---")
        return

    success = post_to_discord(webhook_url, text)
    log_posting(source_file, success, text[:100])
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
