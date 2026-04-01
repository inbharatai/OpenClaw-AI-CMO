#!/usr/bin/env python3
"""
placeholder_generate.py -- Branded Placeholder Image Generator for OpenClaw
Creates professional-looking branded card images from text briefs.
Works fully offline -- no API keys needed.

Backends (in priority order):
  1. Playwright (headless browser screenshot of styled HTML)
  2. Pillow/PIL (direct image rendering)
  3. Pure HTML file output (last resort)

Usage:
    python3 placeholder_generate.py --text "A multilingual AI chatbot interface" --output /path/to/file.png
    python3 placeholder_generate.py --text "brief" --size 1080x1080 --output /path/to/file.png
"""

import argparse
import html
import os
import sys
import textwrap
import tempfile
from datetime import date


# InBharat brand colors
BRAND_ORANGE = "#FF6B35"
BRAND_DARK_BLUE = "#1A1A2E"
BRAND_WHITE = "#FFFFFF"
BRAND_LIGHT_BG = "#F5F5F7"
BRAND_ACCENT = "#E94560"


def build_html(brief_text, width, height):
    """Build a branded HTML card for the given brief text."""
    safe_text = html.escape(brief_text)
    today = date.today().strftime("%Y-%m-%d")

    # Determine font size based on text length and card size
    base_size = min(width, height)
    if len(brief_text) < 50:
        font_size = int(base_size * 0.055)
    elif len(brief_text) < 120:
        font_size = int(base_size * 0.04)
    else:
        font_size = int(base_size * 0.032)

    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{
    width: {width}px;
    height: {height}px;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    background: {BRAND_DARK_BLUE};
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
  }}
  .card {{
    width: {int(width * 0.88)}px;
    height: {int(height * 0.88)}px;
    background: linear-gradient(145deg, {BRAND_DARK_BLUE} 0%, #16213E 50%, #0F3460 100%);
    border-radius: {int(base_size * 0.025)}px;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    padding: {int(base_size * 0.06)}px;
    position: relative;
    overflow: hidden;
  }}
  .card::before {{
    content: '';
    position: absolute;
    top: -{int(height * 0.15)}px;
    right: -{int(width * 0.1)}px;
    width: {int(base_size * 0.5)}px;
    height: {int(base_size * 0.5)}px;
    background: {BRAND_ORANGE};
    opacity: 0.08;
    border-radius: 50%;
  }}
  .card::after {{
    content: '';
    position: absolute;
    bottom: -{int(height * 0.1)}px;
    left: -{int(width * 0.05)}px;
    width: {int(base_size * 0.35)}px;
    height: {int(base_size * 0.35)}px;
    background: {BRAND_ACCENT};
    opacity: 0.06;
    border-radius: 50%;
  }}
  .header {{
    display: flex;
    align-items: center;
    gap: {int(base_size * 0.02)}px;
    z-index: 1;
  }}
  .logo-mark {{
    width: {int(base_size * 0.06)}px;
    height: {int(base_size * 0.06)}px;
    background: {BRAND_ORANGE};
    border-radius: {int(base_size * 0.012)}px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 800;
    color: white;
    font-size: {int(base_size * 0.03)}px;
  }}
  .brand-name {{
    font-size: {int(base_size * 0.028)}px;
    font-weight: 700;
    color: {BRAND_WHITE};
    letter-spacing: 0.5px;
  }}
  .brand-sub {{
    font-size: {int(base_size * 0.018)}px;
    color: {BRAND_ORANGE};
    font-weight: 500;
    margin-left: auto;
    text-transform: uppercase;
    letter-spacing: 1.5px;
  }}
  .content {{
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1;
    padding: {int(base_size * 0.03)}px 0;
  }}
  .brief-text {{
    font-size: {font_size}px;
    color: {BRAND_WHITE};
    line-height: 1.5;
    text-align: center;
    font-weight: 400;
    max-width: 90%;
    opacity: 0.92;
  }}
  .divider {{
    width: {int(base_size * 0.1)}px;
    height: 3px;
    background: {BRAND_ORANGE};
    margin: {int(base_size * 0.025)}px auto;
    border-radius: 2px;
  }}
  .footer {{
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    z-index: 1;
  }}
  .footer-label {{
    font-size: {int(base_size * 0.018)}px;
    color: rgba(255,255,255,0.35);
    text-transform: uppercase;
    letter-spacing: 1px;
  }}
  .footer-date {{
    font-size: {int(base_size * 0.016)}px;
    color: rgba(255,255,255,0.25);
  }}
  .accent-bar {{
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: {int(base_size * 0.006)}px;
    background: linear-gradient(90deg, {BRAND_ORANGE}, {BRAND_ACCENT}, {BRAND_ORANGE});
    border-radius: 0 0 {int(base_size * 0.025)}px {int(base_size * 0.025)}px;
  }}
</style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div class="logo-mark">iB</div>
      <span class="brand-name">InBharat AI</span>
      <span class="brand-sub">OpenClaw</span>
    </div>
    <div class="content">
      <div>
        <div class="divider"></div>
        <div class="brief-text">{safe_text}</div>
        <div class="divider"></div>
      </div>
    </div>
    <div class="footer">
      <span class="footer-label">Image Brief</span>
      <span class="footer-date">{today}</span>
    </div>
    <div class="accent-bar"></div>
  </div>
</body>
</html>"""


def generate_with_playwright(html_content, output_path, width, height):
    """Render HTML to PNG using Playwright."""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        return False

    tmp_html = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html_content)
            tmp_html = f.name

        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page(viewport={"width": width, "height": height})
            page.goto(f"file://{tmp_html}")
            page.wait_for_load_state("networkidle")
            page.screenshot(path=output_path, type="png")
            browser.close()

        return True
    except Exception as e:
        print(f"  Playwright rendering failed: {e}", file=sys.stderr)
        return False
    finally:
        if tmp_html and os.path.exists(tmp_html):
            os.unlink(tmp_html)


def generate_with_pillow(brief_text, output_path, width, height):
    """Render a branded card using Pillow."""
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        return False

    try:
        img = Image.new("RGB", (width, height), BRAND_DARK_BLUE)
        draw = ImageDraw.Draw(img)

        # Try to load a good font, fall back to default
        base_size = min(width, height)
        title_size = int(base_size * 0.035)
        brief_size = int(base_size * 0.04) if len(brief_text) < 80 else int(base_size * 0.032)

        try:
            # macOS system fonts
            title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", title_size)
            brief_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", brief_size)
            small_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(base_size * 0.02))
        except (OSError, IOError):
            try:
                title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", title_size)
                brief_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", brief_size)
                small_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", int(base_size * 0.02))
            except (OSError, IOError):
                title_font = ImageFont.load_default()
                brief_font = ImageFont.load_default()
                small_font = ImageFont.load_default()

        # Background gradient effect (approximate with rectangles)
        for i in range(height):
            ratio = i / height
            r = int(26 * (1 - ratio * 0.3))
            g = int(26 * (1 - ratio * 0.2))
            b = int(46 + ratio * 20)
            draw.line([(0, i), (width, i)], fill=(r, g, b))

        # Orange accent circle (top right)
        circle_r = int(base_size * 0.2)
        cx, cy = int(width * 0.85), int(height * 0.1)
        for dx in range(-circle_r, circle_r):
            for dy in range(-circle_r, circle_r):
                if dx * dx + dy * dy <= circle_r * circle_r:
                    px, py = cx + dx, cy + dy
                    if 0 <= px < width and 0 <= py < height:
                        bg = img.getpixel((px, py))
                        alpha = 0.06
                        new_color = (
                            int(bg[0] * (1 - alpha) + 255 * alpha),
                            int(bg[1] * (1 - alpha) + 107 * alpha),
                            int(bg[2] * (1 - alpha) + 53 * alpha),
                        )
                        img.putpixel((px, py), new_color)

        padding = int(base_size * 0.08)

        # Logo mark
        logo_size = int(base_size * 0.06)
        logo_x, logo_y = padding, padding
        draw.rounded_rectangle(
            [logo_x, logo_y, logo_x + logo_size, logo_y + logo_size],
            radius=int(base_size * 0.01),
            fill=BRAND_ORANGE,
        )
        draw.text(
            (logo_x + logo_size // 2, logo_y + logo_size // 2),
            "iB", fill=BRAND_WHITE, font=small_font, anchor="mm",
        )

        # Brand name
        draw.text(
            (logo_x + logo_size + int(base_size * 0.02), logo_y + logo_size // 2),
            "InBharat AI", fill=BRAND_WHITE, font=title_font, anchor="lm",
        )

        # OpenClaw label (right side)
        draw.text(
            (width - padding, logo_y + logo_size // 2),
            "OPENCLAW", fill=BRAND_ORANGE, font=small_font, anchor="rm",
        )

        # Brief text (centered, word-wrapped)
        max_chars = max(20, int((width - 2 * padding) / (brief_size * 0.55)))
        wrapped = textwrap.fill(brief_text, width=max_chars)
        lines = wrapped.split("\n")
        total_text_height = len(lines) * int(brief_size * 1.6)
        text_y = (height - total_text_height) // 2

        # Divider above text
        div_w = int(base_size * 0.1)
        div_y = text_y - int(base_size * 0.04)
        draw.rounded_rectangle(
            [(width - div_w) // 2, div_y, (width + div_w) // 2, div_y + 3],
            radius=1, fill=BRAND_ORANGE,
        )

        for line in lines:
            draw.text(
                (width // 2, text_y),
                line, fill=(255, 255, 255, 235), font=brief_font, anchor="mt",
            )
            text_y += int(brief_size * 1.6)

        # Divider below text
        div_y2 = text_y + int(base_size * 0.02)
        draw.rounded_rectangle(
            [(width - div_w) // 2, div_y2, (width + div_w) // 2, div_y2 + 3],
            radius=1, fill=BRAND_ORANGE,
        )

        # Footer
        footer_y = height - padding
        draw.text((padding, footer_y), "IMAGE BRIEF", fill=(255, 255, 255, 90), font=small_font, anchor="lb")
        draw.text(
            (width - padding, footer_y),
            date.today().strftime("%Y-%m-%d"),
            fill=(255, 255, 255, 64), font=small_font, anchor="rb",
        )

        # Bottom accent bar
        bar_h = int(base_size * 0.006)
        draw.rectangle(
            [0, height - bar_h, width, height],
            fill=BRAND_ORANGE,
        )

        img.save(output_path, "PNG")
        return True
    except Exception as e:
        print(f"  Pillow rendering failed: {e}", file=sys.stderr)
        return False


def generate_html_fallback(html_content, output_path):
    """Save the HTML file as a last resort (with .html extension alongside)."""
    html_path = output_path.rsplit(".", 1)[0] + ".html"
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"  Saved HTML fallback: {html_path}", file=sys.stderr)
    return html_path


def main():
    parser = argparse.ArgumentParser(description="Generate branded placeholder images")
    parser.add_argument("--text", required=True, help="Brief text to display on the card")
    parser.add_argument("--output", required=True, help="Output file path (.png)")
    parser.add_argument("--size", default="1080x1080", help="Image dimensions WxH (default: 1080x1080)")
    args = parser.parse_args()

    # Parse size
    try:
        parts = args.size.lower().split("x")
        width, height = int(parts[0]), int(parts[1])
    except (ValueError, IndexError):
        print(f"ERROR: Invalid size format '{args.size}'. Use WxH, e.g., 1080x1080", file=sys.stderr)
        sys.exit(1)

    if width < 100 or height < 100 or width > 4096 or height > 4096:
        print("ERROR: Size must be between 100x100 and 4096x4096", file=sys.stderr)
        sys.exit(1)

    # Ensure output directory exists
    output_dir = os.path.dirname(args.output)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    brief_text = args.text.strip()
    if not brief_text:
        print("ERROR: --text cannot be empty", file=sys.stderr)
        sys.exit(1)

    html_content = build_html(brief_text, width, height)

    print(f"Generating placeholder image...")
    print(f"  Text: {brief_text[:80]}{'...' if len(brief_text) > 80 else ''}")
    print(f"  Size: {width}x{height}")

    # Try backends in priority order
    # 1. Playwright
    if generate_with_playwright(html_content, args.output, width, height):
        file_size = os.path.getsize(args.output)
        print(f"  Backend: Playwright")
        print(f"  Saved: {args.output} ({file_size:,} bytes)")
        print(args.output)
        return

    # 2. Pillow
    if generate_with_pillow(brief_text, args.output, width, height):
        file_size = os.path.getsize(args.output)
        print(f"  Backend: Pillow")
        print(f"  Saved: {args.output} ({file_size:,} bytes)")
        print(args.output)
        return

    # 3. HTML fallback
    result_path = generate_html_fallback(html_content, args.output)
    print(f"  Backend: HTML fallback (no PNG renderer available)")
    print(f"  Install Playwright or Pillow for PNG output:")
    print(f"    pip3 install playwright && python3 -m playwright install chromium")
    print(f"    pip3 install Pillow")
    print(result_path)


if __name__ == "__main__":
    main()
