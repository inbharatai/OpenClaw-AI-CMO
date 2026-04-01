#!/usr/bin/env python3
"""
dalle_generate.py -- DALL-E 3 Image Generation for OpenClaw
Reads OPENAI_API_KEY from macOS Keychain, generates images via DALL-E 3.

Usage:
    python3 dalle_generate.py --prompt "description" --output /path/to/file.png
    python3 dalle_generate.py --prompt "description" --size 1024x1792 --style vivid --output /path/to/file.png

Exit codes:
    0 = success
    1 = general error
    2 = API key not found
    3 = openai package not installed
    4 = API call failed
"""

import argparse
import os
import subprocess
import sys


def get_api_key():
    """Retrieve OPENAI_API_KEY from environment or macOS Keychain."""
    key = os.environ.get("OPENAI_API_KEY")
    if key:
        return key

    try:
        result = subprocess.run(
            [
                "security", "find-generic-password",
                "-s", "openclaw",
                "-a", "openclaw-openai-api-key",
                "-w",
            ],
            capture_output=True, text=True, timeout=10,
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return None


def main():
    parser = argparse.ArgumentParser(description="Generate images via DALL-E 3")
    parser.add_argument("--prompt", required=True, help="Image description / brief")
    parser.add_argument("--size", default="1024x1024",
                        choices=["1024x1024", "1024x1792", "1792x1024"],
                        help="Image dimensions (default: 1024x1024)")
    parser.add_argument("--style", default="natural",
                        choices=["natural", "vivid"],
                        help="DALL-E style (default: natural)")
    parser.add_argument("--output", required=True, help="Output file path (.png)")
    parser.add_argument("--quality", default="standard",
                        choices=["standard", "hd"],
                        help="Image quality (default: standard)")
    args = parser.parse_args()

    # --- Check for openai package ---
    try:
        import openai  # noqa: E402
    except ImportError:
        print("ERROR: 'openai' Python package is not installed.", file=sys.stderr)
        print("Install it with: pip3 install openai", file=sys.stderr)
        sys.exit(3)

    # --- Get API key ---
    api_key = get_api_key()
    if not api_key:
        print("ERROR: OPENAI_API_KEY not found.", file=sys.stderr)
        print("Set it via:", file=sys.stderr)
        print("  1. Environment variable: export OPENAI_API_KEY=sk-...", file=sys.stderr)
        print("  2. macOS Keychain:", file=sys.stderr)
        print('     security add-generic-password -s "openclaw" -a "openclaw-openai-api-key" -w "sk-..."',
              file=sys.stderr)
        sys.exit(2)

    # --- Ensure output directory exists ---
    output_dir = os.path.dirname(args.output)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    # --- Call DALL-E 3 ---
    client = openai.OpenAI(api_key=api_key)

    print(f"Generating image with DALL-E 3...")
    print(f"  Prompt: {args.prompt[:100]}{'...' if len(args.prompt) > 100 else ''}")
    print(f"  Size: {args.size}")
    print(f"  Style: {args.style}")

    try:
        response = client.images.generate(
            model="dall-e-3",
            prompt=args.prompt,
            size=args.size,
            style=args.style,
            quality=args.quality,
            n=1,
            response_format="url",
        )
    except openai.AuthenticationError:
        print("ERROR: Invalid API key. Check your OPENAI_API_KEY.", file=sys.stderr)
        sys.exit(2)
    except openai.RateLimitError:
        print("ERROR: Rate limit exceeded. Try again later.", file=sys.stderr)
        sys.exit(4)
    except openai.BadRequestError as e:
        print(f"ERROR: Bad request -- {e}", file=sys.stderr)
        sys.exit(4)
    except Exception as e:
        print(f"ERROR: DALL-E API call failed -- {e}", file=sys.stderr)
        sys.exit(4)

    image_url = response.data[0].url
    revised_prompt = getattr(response.data[0], "revised_prompt", None)

    if revised_prompt:
        print(f"  Revised prompt: {revised_prompt[:120]}...")

    # --- Download image ---
    try:
        import urllib.request
        urllib.request.urlretrieve(image_url, args.output)
    except Exception as e:
        print(f"ERROR: Failed to download generated image -- {e}", file=sys.stderr)
        sys.exit(4)

    file_size = os.path.getsize(args.output)
    print(f"  Saved: {args.output} ({file_size:,} bytes)")
    print(args.output)


if __name__ == "__main__":
    main()
