#!/usr/bin/env python3
"""
render_post.py — Two-stage content renderer for OpenClaw publishing pipeline.

Stage 1 (internal): Raw queue file (JSON with platform_content, metadata, briefs, etc.)
Stage 2 (this script): Clean, human-readable, platform-ready text ONLY.

This script transforms internal content packages into final publishable text.
It is the ONLY bridge between queue files and posting scripts.

Usage:
    # Render for a specific platform
    python3 render_post.py --file /path/to/content.json --platform linkedin

    # Output to file instead of stdout
    python3 render_post.py --file /path/to/content.json --platform x --output /tmp/tweet.txt

    # Generate approval package (for review, NOT for posting)
    python3 render_post.py --file /path/to/content.json --platform linkedin --approval-package

Exit codes:
    0 = success
    1 = content failed validation after rendering
    2 = file not found / usage error
"""

import argparse
import json
import sys
from pathlib import Path

# Import sanitizer and shared constants from same directory
sys.path.insert(0, str(Path(__file__).parent))
from sanitize_post import sanitize, validate
from metadata_fields import METADATA_KEYS


def render_from_json(data, platform):
    """
    Extract and render platform-specific content from a JSON content package.

    Only returns the final public-facing text. All metadata, briefs, scores,
    and internal fields are stripped.
    """
    pc = data.get('platform_content', {})

    platform_keys = {
        'linkedin': ['linkedin_post'],
        'x': ['x_tweet'],
        'instagram': ['instagram_caption', 'instagram_post'],
        'discord': ['discord_message'],
        'email': ['email_body'],
        'reddit': ['reddit_post'],
        'website': ['website_article', 'article_body'],
    }

    text = ''
    for key in platform_keys.get(platform, []):
        text = pc.get(key, '')
        if text and str(text).strip():
            break

    if not text:
        # Fallback: construct from hook + summary + cta
        hook = data.get('hook', '')
        summary = data.get('summary', '')
        cta = data.get('cta', '')
        parts = [str(p).strip() for p in [hook, summary, cta] if p and str(p).strip()]
        text = '\n\n'.join(parts)

    return str(text).strip()


def render_from_markdown(content):
    """
    Extract body text from a markdown file, stripping frontmatter and metadata lines.
    """
    lines = content.split('\n')

    # Step 1: Strip YAML frontmatter if present at the very start.
    # Frontmatter is ONLY valid as paired --- delimiters at the top of file.
    # We look for explicit open/close pair — no toggle logic.
    start_idx = 0
    if lines and lines[0].strip() == '---':
        close_idx = None
        for i in range(1, len(lines)):
            if lines[i].strip() == '---':
                close_idx = i
                break
        if close_idx is not None:
            start_idx = close_idx + 1

    # Step 2: Process remaining lines, skipping metadata key:value lines
    body_lines = []
    for line in lines[start_idx:]:
        stripped = line.strip()
        if ':' in stripped:
            key = stripped.split(':')[0].strip().lower()
            if key in METADATA_KEYS:
                continue
        body_lines.append(line)

    return '\n'.join(body_lines).strip()


def render(file_path, platform):
    """
    Main render function. Takes a queue file path and target platform.

    Returns:
        tuple: (rendered_text, issues, raw_data)
    """
    path = Path(file_path)

    if not path.exists():
        return '', ['file_not_found'], {}

    raw_data = {}

    if path.suffix == '.json':
        with open(path) as f:
            raw_data = json.load(f)
        text = render_from_json(raw_data, platform)
    elif path.suffix == '.md':
        with open(path) as f:
            content = f.read()
        text = render_from_markdown(content)
    else:
        with open(path) as f:
            text = f.read().strip()

    # Run through sanitizer
    clean_text, issues = sanitize(text)

    # Final validation
    is_valid, problems = validate(clean_text)
    if not is_valid:
        issues.extend([f'post_validation:{p}' for p in problems])

    return clean_text, issues, raw_data


def build_approval_package(file_path, platform, rendered_text):
    """
    Build a review-only approval package. This is for human review —
    it includes metadata alongside the final text for context.
    NEVER send this to a posting script.
    """
    path = Path(file_path)
    raw_data = {}

    if path.suffix == '.json':
        with open(path) as f:
            raw_data = json.load(f)

    package = {
        'platform': platform,
        'product': raw_data.get('product', 'unknown'),
        'content_type': raw_data.get('content_type', 'unknown'),
        'final_caption': rendered_text,
        'char_count': len(rendered_text),
        'source_file': str(file_path),
        'cta': raw_data.get('cta', ''),
        'hashtags': raw_data.get('hashtags', ''),
        'image_brief': raw_data.get('image_brief', ''),
        'image_path': raw_data.get('image_path', ''),
        'sources_used': raw_data.get('source_urls', raw_data.get('source_links', [])),
        'restricted_claims': raw_data.get('restricted_claims', []),
        'confidence_note': 'Rendered via render_post.py — sanitized for public posting',
    }

    return package


def main():
    parser = argparse.ArgumentParser(description='Render queue files into clean publishable text')
    parser.add_argument('--file', type=str, required=True, help='Queue file (JSON or markdown)')
    parser.add_argument('--platform', type=str, required=True,
                        choices=['linkedin', 'x', 'instagram', 'discord', 'email',
                                 'reddit', 'website'],
                        help='Target platform')
    parser.add_argument('--output', type=str, help='Write rendered text to file instead of stdout')
    parser.add_argument('--approval-package', action='store_true',
                        help='Output approval package JSON (for review, NOT for posting)')
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        print(f'ERROR: File not found: {args.file}', file=sys.stderr)
        sys.exit(2)

    # Render
    rendered, issues, raw_data = render(args.file, args.platform)

    if not rendered:
        print(f'ERROR: No content rendered from {args.file}', file=sys.stderr)
        if issues:
            print(f'Issues: {issues}', file=sys.stderr)
        sys.exit(1)

    if issues:
        print(f'SANITIZE: {len(issues)} issues fixed: {issues}', file=sys.stderr)

    # Output
    if args.approval_package:
        package = build_approval_package(args.file, args.platform, rendered)
        print(json.dumps(package, indent=2))
    elif args.output:
        Path(args.output).write_text(rendered)
        print(f'Rendered {len(rendered)} chars to {args.output}', file=sys.stderr)
    else:
        print(rendered)

    sys.exit(0)


if __name__ == '__main__':
    main()
