#!/usr/bin/env python3
"""
sanitize_post.py — Final sanitization layer for public-facing post content.

Strips internal metadata, JSON fragments, YAML frontmatter, template placeholders,
and raw schema artifacts from content before it reaches any posting script.

This is the last line of defense between OpenClaw's internal planning objects
and what the public sees. Every posting script must run content through this.

Usage:
    # As module (imported by posting scripts):
    from sanitize_post import sanitize, validate

    clean, issues = sanitize(raw_text)
    is_ok, problems = validate(raw_text)

    # As CLI (used by publish.sh validation gate):
    python3 sanitize_post.py --text "content to check"
    python3 sanitize_post.py --file /path/to/content.md
    python3 sanitize_post.py --validate-only --file /path/to/content.json

Exit codes:
    0 = clean (or cleaned successfully)
    1 = critical issues found (--validate-only mode)
    2 = file not found / usage error
"""

import argparse
import json
import re
import sys
from pathlib import Path


# ── Internal field names that must NEVER appear in public posts ──
# These patterns match field names only at the START of a line (as YAML keys
# or standalone references), NOT inside URLs, hashtags, or body text.
# The ^\s* anchor prevents false positives like https://api.com?content_id=123
INTERNAL_FIELD_PATTERNS = [
    r'^\s*proof_requirements\b',
    r'^\s*restricted_claims\b',
    r'^\s*content_id\b',
    r'^\s*platform_content\b',
    r'^\s*approval_level\b',
    r'^\s*source_confidence\b',
    r'^\s*claim_sensitivity\b',
    r'^\s*data_safety\b',
    r'^\s*brand_voice_score\b',
    r'^\s*duplication_score\b',
    r'^\s*platform_risk\b',
    r'^\s*risk_dimensions\b',
    r'^\s*weighted_avg\b',
    r'^\s*decision_level\b',
    r'^\s*image_brief\b',
    r'^\s*cover_brief\b',
    r'^\s*webhook_ready\b',
    r'^\s*source_file\b',
    r'^\s*adapted_from\b',
    r'^\s*char_count\b',
    r'^\s*content_type\s*:\s*["\']',  # content_type: "x_post" (internal)
    r'^\s*safe\s*:\s*(true|false)\b',
    r'^\s*status\s*:\s*["\']?(pending|approved|draft|blocked)["\']?\b',
]

# ── JSON/schema fragments ──
JSON_LEAK_PATTERNS = [
    r'^\s*\{[^}]{20,}\}\s*$',       # Standalone JSON objects
    r'^\s*\[[^\]]{20,}\]\s*$',       # Standalone JSON arrays
    r'"[a-z_]+"\s*:\s*["\[\{]',      # JSON key-value pairs: "key": "value"
    r"'[a-z_]+'\s*:\s*['\[\{]",      # Single-quote JSON-like: 'key': 'value'
]

# ── Template placeholders ──
PLACEHOLDER_PATTERNS = [
    r'\{\{[^}]+\}\}',               # {{placeholder}}
    r'\[PLACEHOLDER\]',             # [PLACEHOLDER]
    r'\[TODO\]',                    # [TODO]
    r'\[INSERT[_ ][A-Z_ ]+\]',     # [INSERT_LINK], [INSERT PRODUCT NAME]
    r'\[TBD\]',                     # [TBD]
    r'\[FILL[_ ]?IN\]',            # [FILL IN]
    r'<PLACEHOLDER>',              # <PLACEHOLDER>
]

# ── YAML frontmatter ──
FRONTMATTER_PATTERN = re.compile(r'^---\s*\n.*?\n---\s*\n', re.DOTALL)

# ── Escaped character artifacts ──
ESCAPE_PATTERNS = [
    (r'\\n(?=[A-Z])', '\n'),         # Literal \n before capital letter
    (r'\\n\\n', '\n\n'),             # Literal \n\n
    (r'\\"', '"'),                   # Escaped quotes
    (r'\\/', '/'),                   # Escaped slashes
]

# ── Null/undefined literals ──
NULL_PATTERNS = [
    r'\bnull\b(?!\s*\w)',            # bare "null" not part of a word
    r'\bundefined\b(?!\s*\w)',       # bare "undefined"
    r'\bNone\b(?!\s*\w)',            # Python None leaked
    r'\bTrue\b(?!\s*\w)',            # Python True leaked
    r'\bFalse\b(?!\s*\w)',           # Python False leaked
]


def strip_markdown(text):
    """
    Strip markdown formatting syntax from text, keeping the content.
    Social media platforms render plain text — markdown markers appear as raw characters.

    Key insight: In OpenClaw queue files, the ENTIRE post content is often wrapped
    in ```markdown ... ``` fences. We must KEEP the content inside, just remove
    the fence markers themselves.
    """
    lines = text.split('\n')
    clean = []

    for line in lines:
        stripped = line.strip()

        # Remove code fence lines (```markdown, ```, ```python, etc.)
        # But keep the content between them — it IS the post.
        if re.match(r'^```\w*\s*$', stripped):
            continue

        # Remove heading markers but keep text: ### Key Highlights → Key Highlights
        if re.match(r'^#{1,6}\s+', stripped):
            line = re.sub(r'^#{1,6}\s+', '', line.lstrip())

        # Remove horizontal rules (standalone ---, ===, ***)
        if re.match(r'^[-=*]{3,}\s*$', stripped):
            continue

        # Remove decorative lines (━━━, ═══, etc.)
        if re.match(r'^[━═─]{3,}\s*$', stripped):
            continue

        clean.append(line)

    text = '\n'.join(clean)

    # Strip bold: **text** → text
    text = re.sub(r'\*\*(.+?)\*\*', r'\1', text)
    # Strip italic: *text* → text (but not ** which is bold, already handled)
    text = re.sub(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)', r'\1', text)
    # Strip bold with underscores: __text__ → text
    text = re.sub(r'__(.+?)__', r'\1', text)
    # Strip inline code: `code` → code
    text = re.sub(r'`([^`]+)`', r'\1', text)
    # Strip link syntax: [text](url) → text (url)
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'\1 (\2)', text)

    return text


def sanitize(text):
    """
    Sanitize text for public posting.

    Returns:
        tuple: (clean_text, list_of_issues_found)
    """
    if not text or not text.strip():
        return "", ["empty_content"]

    issues = []
    original = text

    # 1. Strip YAML frontmatter
    if text.lstrip().startswith('---'):
        match = FRONTMATTER_PATTERN.match(text.lstrip())
        if match:
            text = text.lstrip()[match.end():]
            issues.append("stripped_yaml_frontmatter")

    # 2. Strip markdown formatting (code fences, headings, bold, italic)
    before_md = text
    text = strip_markdown(text)
    if text != before_md:
        issues.append("stripped_markdown_formatting")

    # 3. Strip lines that are pure internal field references
    clean_lines = []
    for line in text.split('\n'):
        stripped = line.strip()

        # Skip lines that are clearly internal metadata
        skip = False
        for pattern in INTERNAL_FIELD_PATTERNS:
            if re.search(pattern, stripped, re.IGNORECASE):
                issues.append(f"stripped_internal_field:{pattern}")
                skip = True
                break

        # Skip lines that look like YAML key-value metadata
        if not skip and re.match(r'^[a-z_]+:\s+\S', stripped) and ':' in stripped:
            key = stripped.split(':')[0].strip()
            if key in ('title', 'date', 'type', 'channel', 'approval_level',
                        'status', 'source_file', 'webhook_ready', 'category',
                        'adapted_from', 'char_count', 'content_id', 'product',
                        'audience', 'objective', 'platform', 'risk_score',
                        'decision_level', 'image_brief', 'cover_brief'):
                issues.append(f"stripped_metadata_line:{key}")
                skip = True

        if not skip:
            clean_lines.append(line)

    text = '\n'.join(clean_lines)

    # 4. Fix escaped character artifacts
    for pattern, replacement in ESCAPE_PATTERNS:
        if re.search(pattern, text):
            text = re.sub(pattern, replacement, text)
            issues.append("fixed_escape_artifacts")

    # 5. Remove template placeholders
    for pattern in PLACEHOLDER_PATTERNS:
        matches = re.findall(pattern, text, re.IGNORECASE)
        if matches:
            text = re.sub(pattern, '', text, flags=re.IGNORECASE)
            issues.append(f"stripped_placeholder:{matches[0]}")

    # 6. Remove null/undefined/None/True/False literals (only standalone ones)
    for pattern in NULL_PATTERNS:
        if re.search(pattern, text):
            text = re.sub(pattern, '', text)
            issues.append("stripped_null_literal")

    # 7. Clean up excessive whitespace from removals
    text = re.sub(r'\n{3,}', '\n\n', text)
    text = re.sub(r'  +', ' ', text)
    text = text.strip()

    return text, issues


def validate(text):
    """
    Validate text is safe for public posting WITHOUT modifying it.

    Returns:
        tuple: (is_clean, list_of_problems)
    """
    if not text or not text.strip():
        return False, ["empty_content"]

    problems = []

    # Check for JSON object/array fragments
    for pattern in JSON_LEAK_PATTERNS:
        if re.search(pattern, text, re.MULTILINE):
            problems.append(f"json_leak:{pattern}")

    # Check for internal field names (anchored to line start, so use MULTILINE)
    for pattern in INTERNAL_FIELD_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE | re.MULTILINE):
            problems.append(f"internal_field:{pattern}")

    # Check for template placeholders
    for pattern in PLACEHOLDER_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            problems.append(f"placeholder:{pattern}")

    # Check for YAML frontmatter
    if text.lstrip().startswith('---') and FRONTMATTER_PATTERN.match(text.lstrip()):
        problems.append("yaml_frontmatter")

    # Check for null/undefined literals
    for pattern in NULL_PATTERNS:
        if re.search(pattern, text):
            problems.append(f"null_literal:{pattern}")

    # Check for raw JSON-like structures (braces with internal field names)
    brace_content = re.findall(r'\{[^}]{10,}\}', text)
    for block in brace_content:
        if any(kw in block.lower() for kw in ['proof', 'claim', 'metadata', 'schema',
                                                  'content_id', 'platform_content',
                                                  'risk_', 'approval']):
            problems.append(f"json_metadata_block:{block[:50]}")

    # Check for markdown formatting artifacts (should never appear in social posts)
    if re.search(r'```', text):
        problems.append("markdown_code_fence")
    if re.search(r'^#{1,6}\s+', text, re.MULTILINE):
        problems.append("markdown_heading_marker")
    if re.search(r'\*\*[^*]+\*\*', text):
        problems.append("markdown_bold_marker")

    # Check for excessive hashtag dumps (more than 20 hashtags)
    hashtags = re.findall(r'#\w+', text)
    if len(hashtags) > 20:
        problems.append(f"hashtag_dump:{len(hashtags)}_hashtags")

    return len(problems) == 0, problems


def extract_and_sanitize_file(file_path, platform=None):
    """
    Extract text from a queue file (JSON or markdown) and sanitize it.

    Returns:
        tuple: (clean_text, issues, raw_data)
    """
    path = Path(file_path)
    raw_data = {}

    if path.suffix == '.json':
        with open(path) as f:
            raw_data = json.load(f)

        # Extract platform-specific content
        pc = raw_data.get('platform_content', {})
        text = ''

        if platform:
            platform_keys = {
                'linkedin': 'linkedin_post',
                'x': 'x_tweet',
                'instagram': 'instagram_caption',
                'discord': 'discord_message',
            }
            text = pc.get(platform_keys.get(platform, ''), '')

        if not text:
            # Try common fallback keys
            for key in ['linkedin_post', 'x_tweet', 'instagram_caption',
                        'discord_message', 'instagram_post']:
                text = pc.get(key, '')
                if text:
                    break

        if not text:
            # Last fallback: hook + summary + cta
            hook = raw_data.get('hook', '')
            summary = raw_data.get('summary', '')
            cta = raw_data.get('cta', '')
            parts = [p for p in [hook, summary, cta] if p and str(p).strip()]
            text = '\n\n'.join(parts)

    elif path.suffix == '.md':
        with open(path) as f:
            text = f.read()
    else:
        with open(path) as f:
            text = f.read()

    clean, issues = sanitize(text)
    return clean, issues, raw_data


def main():
    parser = argparse.ArgumentParser(description='Sanitize post content for public publishing')
    parser.add_argument('--text', type=str, help='Text to sanitize')
    parser.add_argument('--file', type=str, help='File to extract and sanitize')
    parser.add_argument('--platform', type=str, choices=['linkedin', 'x', 'instagram', 'discord'],
                        help='Target platform (for JSON extraction)')
    parser.add_argument('--validate-only', action='store_true',
                        help='Only validate, do not clean — exit 1 if issues found')
    parser.add_argument('--json-output', action='store_true',
                        help='Output results as JSON')
    args = parser.parse_args()

    if not args.text and not args.file:
        parser.print_help()
        sys.exit(2)

    if args.file:
        path = Path(args.file)
        if not path.exists():
            print(f"ERROR: File not found: {args.file}", file=sys.stderr)
            sys.exit(2)

    # Get text
    if args.text:
        text = args.text
    else:
        text_clean, issues, _ = extract_and_sanitize_file(args.file, args.platform)
        if args.validate_only:
            # Re-read raw text for validation
            with open(args.file) as f:
                raw = f.read()
            is_clean, problems = validate(raw)
            if args.json_output:
                print(json.dumps({'clean': is_clean, 'problems': problems}))
            else:
                if is_clean:
                    print('CLEAN: No issues found')
                else:
                    print(f'ISSUES ({len(problems)}):')
                    for p in problems:
                        print(f'  - {p}')
            sys.exit(0 if is_clean else 1)
        else:
            if args.json_output:
                print(json.dumps({'text': text_clean, 'issues': issues}))
            else:
                print(text_clean)
            sys.exit(0)

    # Direct text mode
    if args.validate_only:
        is_clean, problems = validate(text)
        if args.json_output:
            print(json.dumps({'clean': is_clean, 'problems': problems}))
        else:
            if is_clean:
                print('CLEAN: No issues found')
            else:
                print(f'ISSUES ({len(problems)}):')
                for p in problems:
                    print(f'  - {p}')
        sys.exit(0 if is_clean else 1)
    else:
        clean, issues = sanitize(text)
        if args.json_output:
            print(json.dumps({'text': clean, 'issues': issues}))
        else:
            print(clean)
        sys.exit(0)


if __name__ == '__main__':
    main()
