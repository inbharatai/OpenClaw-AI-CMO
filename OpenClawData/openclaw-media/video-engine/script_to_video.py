#!/usr/bin/env python3
"""
script_to_video.py — OpenClaw Video Engine
Generates branded slide-based videos from text scripts.

Pipeline: Text → Slide PNGs (Playwright) → TTS Audio (macOS say) → MP4 (FFmpeg)

Usage:
    python3 script_to_video.py --script "Your narration text" --title "Video Title" \
        --output /path/to/video.mp4 --format shorts --duration 15 --brand

Requires: Python 3.8+, FFmpeg, Playwright (pip install playwright && playwright install chromium)
Optional: macOS `say` command for TTS (falls back to silent video if unavailable)
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import textwrap
from pathlib import Path


# ── Brand constants ──────────────────────────────────────────────────────────
BRAND_ORANGE = "#FF6B35"
BRAND_DARK_BLUE = "#1A1A2E"
BRAND_WHITE = "#FFFFFF"
BRAND_LIGHT_GRAY = "#F0F0F5"
BRAND_ACCENT = "#E8E8EE"

# ── Format presets ───────────────────────────────────────────────────────────
FORMATS = {
    "shorts": {"width": 1080, "height": 1920, "label": "9:16 Shorts/Reels"},
    "landscape": {"width": 1920, "height": 1080, "label": "16:9 Landscape"},
}

DEFAULT_DURATION = 15  # seconds


def log(msg: str) -> None:
    print(f"[video-engine] {msg}", file=sys.stderr)


def check_dependencies() -> dict:
    """Check which tools are available and return a capabilities dict."""
    caps = {
        "ffmpeg": shutil.which("ffmpeg") is not None,
        "say": shutil.which("say") is not None,
        "playwright": False,
    }
    try:
        from playwright.sync_api import sync_playwright  # noqa: F401
        caps["playwright"] = True
    except ImportError:
        pass
    return caps


def split_script_to_points(script: str, max_points: int = 5) -> list:
    """Split a script into 3-5 key points for slides."""
    # Try splitting on sentence boundaries
    sentences = re.split(r'(?<=[.!?])\s+', script.strip())
    sentences = [s.strip() for s in sentences if s.strip()]

    if len(sentences) <= max_points:
        return sentences

    # Group sentences into max_points buckets
    points = []
    bucket_size = max(1, len(sentences) // max_points)
    for i in range(0, len(sentences), bucket_size):
        chunk = " ".join(sentences[i:i + bucket_size])
        if chunk:
            points.append(chunk)
        if len(points) >= max_points:
            # Append remaining sentences to the last point
            remaining = " ".join(sentences[i + bucket_size:])
            if remaining:
                points[-1] += " " + remaining
            break

    return points[:max_points]


def generate_slide_html(
    point: str,
    slide_index: int,
    total_slides: int,
    title: str,
    width: int,
    height: int,
    is_title_slide: bool = False,
    is_cta_slide: bool = False,
) -> str:
    """Generate branded HTML for a single slide."""
    # Escape HTML entities
    point_escaped = point.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    title_escaped = title.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    # Font sizes scale with resolution
    base_font = int(width * 0.035)
    title_font = int(width * 0.055)
    point_font = int(width * 0.032)
    small_font = int(width * 0.018)

    if is_title_slide:
        body_content = f"""
        <div class="title-slide">
            <div class="brand-bar"></div>
            <div class="logo">InBharat</div>
            <h1>{title_escaped}</h1>
            <div class="subtitle">OpenClaw Media</div>
            <div class="brand-bar bottom"></div>
        </div>
        """
    elif is_cta_slide:
        body_content = f"""
        <div class="cta-slide">
            <div class="brand-bar"></div>
            <div class="cta-icon">&#x1F680;</div>
            <h2>Learn More</h2>
            <p class="cta-text">{point_escaped}</p>
            <div class="brand-tag">InBharat &middot; OpenClaw</div>
            <div class="brand-bar bottom"></div>
        </div>
        """
    else:
        body_content = f"""
        <div class="content-slide">
            <div class="brand-bar"></div>
            <div class="slide-header">
                <span class="logo-small">InBharat</span>
                <span class="slide-counter">{slide_index}/{total_slides}</span>
            </div>
            <div class="point-container">
                <div class="point-number">{slide_index:02d}</div>
                <p class="point-text">{point_escaped}</p>
            </div>
            <div class="brand-bar bottom"></div>
        </div>
        """

    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{
        width: {width}px;
        height: {height}px;
        background: {BRAND_DARK_BLUE};
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        color: {BRAND_WHITE};
        display: flex;
        align-items: center;
        justify-content: center;
        overflow: hidden;
    }}
    .brand-bar {{
        position: absolute;
        top: 0; left: 0; right: 0;
        height: {int(height * 0.008)}px;
        background: linear-gradient(90deg, {BRAND_ORANGE}, {BRAND_ORANGE}cc);
    }}
    .brand-bar.bottom {{
        top: auto; bottom: 0;
    }}

    /* ── Title Slide ── */
    .title-slide {{
        text-align: center;
        padding: {int(width * 0.08)}px;
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
    }}
    .title-slide .logo {{
        font-size: {int(title_font * 0.7)}px;
        font-weight: 800;
        color: {BRAND_ORANGE};
        letter-spacing: 3px;
        text-transform: uppercase;
        margin-bottom: {int(height * 0.04)}px;
    }}
    .title-slide h1 {{
        font-size: {title_font}px;
        font-weight: 700;
        line-height: 1.2;
        margin-bottom: {int(height * 0.03)}px;
        max-width: 90%;
    }}
    .title-slide .subtitle {{
        font-size: {small_font}px;
        color: {BRAND_ACCENT};
        letter-spacing: 2px;
        text-transform: uppercase;
    }}

    /* ── Content Slide ── */
    .content-slide {{
        width: 100%;
        height: 100%;
        padding: {int(width * 0.06)}px;
        display: flex;
        flex-direction: column;
    }}
    .slide-header {{
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-top: {int(height * 0.03)}px;
        margin-bottom: auto;
    }}
    .logo-small {{
        font-size: {small_font}px;
        font-weight: 800;
        color: {BRAND_ORANGE};
        letter-spacing: 2px;
        text-transform: uppercase;
    }}
    .slide-counter {{
        font-size: {small_font}px;
        color: {BRAND_ACCENT};
    }}
    .point-container {{
        flex: 1;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: flex-start;
    }}
    .point-number {{
        font-size: {int(title_font * 1.5)}px;
        font-weight: 800;
        color: {BRAND_ORANGE};
        opacity: 0.3;
        margin-bottom: {int(height * 0.02)}px;
    }}
    .point-text {{
        font-size: {point_font}px;
        line-height: 1.5;
        font-weight: 400;
        max-width: 95%;
    }}

    /* ── CTA Slide ── */
    .cta-slide {{
        text-align: center;
        padding: {int(width * 0.08)}px;
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
    }}
    .cta-icon {{
        font-size: {int(title_font * 1.5)}px;
        margin-bottom: {int(height * 0.03)}px;
    }}
    .cta-slide h2 {{
        font-size: {title_font}px;
        font-weight: 700;
        color: {BRAND_ORANGE};
        margin-bottom: {int(height * 0.03)}px;
    }}
    .cta-text {{
        font-size: {point_font}px;
        line-height: 1.5;
        max-width: 85%;
        margin-bottom: {int(height * 0.04)}px;
    }}
    .brand-tag {{
        font-size: {small_font}px;
        color: {BRAND_ACCENT};
        letter-spacing: 2px;
    }}
</style>
</head>
<body>
{body_content}
</body>
</html>"""


def render_slides_playwright(
    slides_html: list, width: int, height: int, output_dir: str
) -> list:
    """Render HTML slides to PNG images using Playwright."""
    from playwright.sync_api import sync_playwright

    png_paths = []
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": width, "height": height})

        for i, html in enumerate(slides_html):
            html_path = os.path.join(output_dir, f"slide_{i:03d}.html")
            png_path = os.path.join(output_dir, f"slide_{i:03d}.png")

            with open(html_path, "w", encoding="utf-8") as f:
                f.write(html)

            page.goto(f"file://{html_path}")
            page.wait_for_timeout(300)  # let fonts load
            page.screenshot(path=png_path, full_page=False)
            png_paths.append(png_path)
            log(f"  Rendered slide {i + 1}/{len(slides_html)}")

        browser.close()

    return png_paths


def render_slides_fallback(
    points: list, title: str, width: int, height: int, output_dir: str
) -> list:
    """Fallback slide generation using FFmpeg lavfi (no Playwright needed)."""
    png_paths = []

    for i, point in enumerate(points):
        png_path = os.path.join(output_dir, f"slide_{i:03d}.png")
        # Wrap text for display
        wrapped = textwrap.fill(point, width=35 if width < height else 55)
        # Escape special chars for FFmpeg drawtext
        escaped = wrapped.replace("'", "\u2019").replace(":", "\\:").replace("%", "%%")
        title_escaped = title.replace("'", "\u2019").replace(":", "\\:").replace("%", "%%")

        fontsize_point = int(width * 0.03)
        fontsize_title = int(width * 0.02)

        # Use FFmpeg to generate a solid-color frame with text overlay
        cmd = [
            "ffmpeg", "-y",
            "-f", "lavfi",
            "-i", f"color=c=0x1A1A2E:s={width}x{height}:d=1",
            "-vf", (
                f"drawtext=text='{escaped}':fontcolor=white"
                f":fontsize={fontsize_point}:x=(w-text_w)/2:y=(h-text_h)/2"
                f":line_spacing=12,"
                f"drawtext=text='{title_escaped}':fontcolor=0xFF6B35"
                f":fontsize={fontsize_title}:x=(w-text_w)/2:y=h*0.08,"
                f"drawtext=text='InBharat':fontcolor=0xFF6B35"
                f":fontsize={int(fontsize_title * 0.8)}:x=(w-text_w)/2:y=h*0.92"
            ),
            "-frames:v", "1",
            png_path,
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            log(f"  WARNING: fallback slide {i} failed: {result.stderr[:200]}")
            # Generate a minimal blank slide
            subprocess.run([
                "ffmpeg", "-y", "-f", "lavfi",
                "-i", f"color=c=0x1A1A2E:s={width}x{height}:d=1",
                "-frames:v", "1", png_path,
            ], capture_output=True)
        else:
            log(f"  Generated fallback slide {i + 1}/{len(points)}")
        png_paths.append(png_path)

    return png_paths


def generate_tts_audio(text: str, output_path: str, caps: dict):
    """Generate TTS audio file. Returns path to WAV or None."""
    if not caps["say"]:
        log("  macOS `say` not available — generating silent video")
        return None

    aiff_path = output_path.replace(".wav", ".aiff")

    # Use macOS say to generate AIFF
    cmd_say = ["say", "-o", aiff_path, "--", text]
    result = subprocess.run(cmd_say, capture_output=True, text=True)
    if result.returncode != 0:
        log(f"  TTS failed: {result.stderr[:200]}")
        return None

    # Convert AIFF to WAV via FFmpeg
    cmd_convert = [
        "ffmpeg", "-y", "-i", aiff_path,
        "-acodec", "pcm_s16le", "-ar", "44100", "-ac", "1",
        output_path,
    ]
    result = subprocess.run(cmd_convert, capture_output=True, text=True)
    if result.returncode != 0:
        log(f"  AIFF→WAV conversion failed: {result.stderr[:200]}")
        return None

    log(f"  TTS audio generated: {output_path}")
    return output_path


def assemble_video(
    slide_pngs: list,
    audio_path,  # str or None
    output_path: str,
    duration: int,
    width: int,
    height: int,
) -> bool:
    """Combine slide PNGs + optional audio into a final MP4 via FFmpeg."""
    if not slide_pngs:
        log("ERROR: No slides to assemble")
        return False

    tmpdir = os.path.dirname(slide_pngs[0])
    num_slides = len(slide_pngs)

    # Determine per-slide duration
    if audio_path:
        # Probe audio length
        probe = subprocess.run(
            ["ffmpeg", "-i", audio_path, "-f", "null", "-"],
            capture_output=True, text=True,
        )
        # Parse duration from stderr
        dur_match = re.search(r"Duration:\s*(\d+):(\d+):(\d+\.\d+)", probe.stderr)
        if dur_match:
            h, m, s = dur_match.groups()
            audio_duration = int(h) * 3600 + int(m) * 60 + float(s)
            slide_duration = max(2.0, audio_duration / num_slides)
            total_duration = audio_duration
        else:
            slide_duration = max(2.0, duration / num_slides)
            total_duration = duration
    else:
        slide_duration = max(2.0, duration / num_slides)
        total_duration = duration

    # Build FFmpeg concat file
    concat_path = os.path.join(tmpdir, "concat.txt")
    with open(concat_path, "w") as f:
        for png in slide_pngs:
            f.write(f"file '{png}'\n")
            f.write(f"duration {slide_duration:.2f}\n")
        # FFmpeg concat demuxer needs the last file repeated
        f.write(f"file '{slide_pngs[-1]}'\n")

    # Build FFmpeg command
    cmd = [
        "ffmpeg", "-y",
        "-f", "concat", "-safe", "0", "-i", concat_path,
    ]

    if audio_path:
        cmd.extend(["-i", audio_path])

    cmd.extend([
        "-vf", (
            f"scale={width}:{height}:force_original_aspect_ratio=decrease,"
            f"pad={width}:{height}:(ow-iw)/2:(oh-ih)/2:color=0x1A1A2E,"
            f"format=yuv420p"
        ),
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "23",
        "-r", "30",
        "-pix_fmt", "yuv420p",
    ])

    if audio_path:
        cmd.extend([
            "-c:a", "aac",
            "-b:a", "128k",
            "-shortest",
        ])
    else:
        # Silent — generate silence track so players handle it well
        cmd.extend([
            "-f", "lavfi", "-i", f"anullsrc=r=44100:cl=mono",
            "-c:a", "aac",
            "-b:a", "32k",
            "-t", str(total_duration),
            "-shortest",
        ])

    cmd.extend([
        "-movflags", "+faststart",
        output_path,
    ])

    log(f"  Assembling video ({num_slides} slides, {total_duration:.1f}s)...")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        log(f"ERROR: FFmpeg assembly failed:\n{result.stderr[-500:]}")
        return False

    log(f"  Video saved: {output_path}")
    return True


def generate_video(
    script: str,
    title: str,
    output_path: str,
    fmt: str = "shorts",
    duration: int = DEFAULT_DURATION,
    brand: bool = True,
) -> bool:
    """
    Master function: text → slides → audio → video.

    Returns True on success, False on failure.
    """
    caps = check_dependencies()

    if not caps["ffmpeg"]:
        log("FATAL: FFmpeg is required but not found. Install with: brew install ffmpeg")
        return False

    preset = FORMATS.get(fmt, FORMATS["shorts"])
    width, height = preset["width"], preset["height"]
    log(f"Format: {preset['label']} ({width}x{height})")

    # Ensure output directory exists
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)

    # Split script into key points
    points = split_script_to_points(script)
    log(f"Script split into {len(points)} key points")

    with tempfile.TemporaryDirectory(prefix="openclaw_video_") as tmpdir:
        # ── Step 1: Generate slide HTML and render to PNG ────────────────
        slides_html = []

        # Title slide
        slides_html.append(
            generate_slide_html("", 0, len(points), title, width, height, is_title_slide=True)
        )

        # Content slides
        for i, point in enumerate(points, 1):
            slides_html.append(
                generate_slide_html(point, i, len(points), title, width, height)
            )

        # CTA slide (last point as CTA or generic)
        cta_text = "Follow InBharat for more insights on AI for Bharat."
        slides_html.append(
            generate_slide_html(cta_text, 0, 0, title, width, height, is_cta_slide=True)
        )

        # Render slides
        if caps["playwright"]:
            log("Rendering slides with Playwright...")
            slide_pngs = render_slides_playwright(slides_html, width, height, tmpdir)
        else:
            log("Playwright not available — using FFmpeg fallback renderer")
            all_points = [title] + points + [cta_text]
            slide_pngs = render_slides_fallback(all_points, title, width, height, tmpdir)

        if not slide_pngs:
            log("ERROR: No slides were generated")
            return False

        # ── Step 2: Generate TTS audio ──────────────────────────────────
        full_narration = f"{title}. " + " ".join(points) + f" {cta_text}"
        wav_path = os.path.join(tmpdir, "narration.wav")
        audio_path = generate_tts_audio(full_narration, wav_path, caps)

        # ── Step 3: Assemble final video ────────────────────────────────
        success = assemble_video(slide_pngs, audio_path, output_path, duration, width, height)

        if success:
            file_size = os.path.getsize(output_path)
            log(f"SUCCESS: {output_path} ({file_size / 1024:.0f} KB)")

        return success


def main():
    parser = argparse.ArgumentParser(
        description="OpenClaw Video Engine — generate branded videos from text scripts",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent("""\
            Examples:
              %(prog)s --script "AI is transforming India." --title "AI for Bharat" --output video.mp4
              %(prog)s --script "..." --format landscape --duration 30 --output promo.mp4
              %(prog)s --json /path/to/content-package.json --output video.mp4
        """),
    )

    # Input options (mutually exclusive)
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument("--script", type=str, help="Narration/content text")
    input_group.add_argument("--json", type=str, help="Path to content-package JSON (extracts video_brief)")

    parser.add_argument("--title", type=str, default="InBharat", help="Video title overlay")
    parser.add_argument("--output", type=str, required=True, help="Output MP4 path")
    parser.add_argument(
        "--format", type=str, choices=["shorts", "landscape"], default="shorts",
        help="Video format (default: shorts = 9:16 1080x1920)",
    )
    parser.add_argument("--duration", type=int, default=DEFAULT_DURATION, help="Target duration in seconds (default: 15)")
    parser.add_argument("--brand", action="store_true", default=True, help="Use InBharat brand colors (default: on)")
    parser.add_argument("--check", action="store_true", help="Check dependencies and exit")

    args = parser.parse_args()

    # Dependency check mode
    if args.check:
        caps = check_dependencies()
        print("OpenClaw Video Engine — Dependency Check")
        print("=" * 45)
        for tool, available in caps.items():
            status = "OK" if available else "MISSING"
            print(f"  {tool:15s} {status}")
        ok = caps["ffmpeg"]  # FFmpeg is the only hard requirement
        print(f"\nReady: {'YES' if ok else 'NO — install FFmpeg first'}")
        sys.exit(0 if ok else 1)

    # Extract script from JSON if needed
    script = args.script
    title = args.title
    fmt = args.format

    if args.json:
        json_path = args.json
        if not os.path.isfile(json_path):
            log(f"FATAL: JSON file not found: {json_path}")
            sys.exit(1)
        with open(json_path, "r", encoding="utf-8") as f:
            pkg = json.load(f)

        # Try video_brief first, then shorts_description, then summary
        script = (
            pkg.get("video_brief")
            or (pkg.get("platform_content", {}).get("shorts_description"))
            or pkg.get("shorts_description")
            or pkg.get("summary")
        )
        if not script:
            log("FATAL: No video_brief, shorts_description, or summary found in JSON")
            sys.exit(1)

        title = (
            pkg.get("platform_content", {}).get("shorts_title")
            or pkg.get("hook", "")[:60]
            or title
        )

        # Auto-detect format: if "shorts" is in platforms, use shorts
        platforms = pkg.get("platforms", [])
        if "shorts" in platforms or "instagram" in platforms:
            fmt = "shorts"

    success = generate_video(
        script=script,
        title=title,
        output_path=args.output,
        fmt=fmt,
        duration=args.duration,
        brand=args.brand,
    )
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
