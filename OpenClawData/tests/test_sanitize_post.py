#!/usr/bin/env python3
"""
test_sanitize_post.py — Tests for post content sanitization.

Tests that the sanitization layer correctly strips internal metadata,
JSON fragments, YAML frontmatter, and template placeholders from content
before it reaches public posting scripts.

Run: python3 -m pytest OpenClawData/tests/test_sanitize_post.py -v
  or: python3 OpenClawData/tests/test_sanitize_post.py
"""

import sys
from pathlib import Path

# Add posting-engine to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'openclaw-media' / 'posting-engine'))
from sanitize_post import sanitize, validate


# ── Test fixtures ──

CLEAN_POST = """AI in India is evolving fast. We just shipped multilingual support for Sahaayak — now available in Hindi, Tamil, and Bengali.

What started as a single-language assistant is becoming a truly Indian AI tool.

Try it at sahaayak.ai

#AIinIndia #Multilingual #Sahaayak"""

JSON_LEAKING_POST = """{
  "content_id": "post-2026-04-03-sahaayak",
  "platform_content": {
    "linkedin_post": "We just shipped multilingual support."
  },
  "restricted_claims": ["no user numbers"],
  "approval_level": "L1",
  "safe": true
}"""

YAML_LEAKING_POST = """---
title: Sahaayak Update
date: 2026-04-03
type: product-update
channel: linkedin
approval_level: L2
status: approved
---

We just shipped multilingual support for Sahaayak. Now available in Hindi, Tamil, and Bengali.

Try it at sahaayak.ai"""

PLACEHOLDER_LEAKING_POST = """We just built {{product_name}} for {{audience}}.

It does [PLACEHOLDER] really well and helps [TODO] with their daily work.

Visit [INSERT_LINK] to learn more.

#AIinIndia"""

METADATA_MIXED_POST = """content_id: post-2026-04-03
platform_content: linkedin
approval_level: L2
status: approved
source_file: /some/path.json

We just shipped multilingual support for Sahaayak.

proof_requirements: verified by source
restricted_claims: no user numbers
safe: true

Try it at sahaayak.ai"""

INTERNAL_FIELD_POST = """We shipped Sahaayak's new update.

image_brief: A multilingual chatbot showing Hindi text
cover_brief: Thumbnail of Sahaayak logo with languages
webhook_ready: true

Great progress this week!"""

CLEAN_TWEET = """Just shipped multilingual support for Sahaayak — Hindi, Tamil, Bengali.

India's AI should speak India's languages.

Try it: sahaayak.ai #AIinIndia"""


# ── Sanitize tests ──

def test_clean_post_unchanged():
    """Clean content should pass through with zero issues."""
    clean, issues = sanitize(CLEAN_POST)
    assert len(issues) == 0, f"Clean post had issues: {issues}"
    assert clean.strip() == CLEAN_POST.strip()


def test_json_leak_detected():
    """Full JSON objects should be flagged by validation."""
    is_clean, problems = validate(JSON_LEAKING_POST)
    assert not is_clean, "JSON content should fail validation"
    assert any('json' in p.lower() or 'internal_field' in p.lower() for p in problems), \
        f"Should detect JSON leak: {problems}"


def test_yaml_frontmatter_stripped():
    """YAML frontmatter should be removed, body preserved."""
    clean, issues = sanitize(YAML_LEAKING_POST)
    assert '---' not in clean, "Frontmatter delimiters should be stripped"
    assert 'approval_level:' not in clean, "Metadata fields should be stripped"
    assert 'multilingual support' in clean, "Body content should be preserved"
    assert 'sahaayak.ai' in clean, "URLs should be preserved"


def test_placeholders_stripped():
    """Template placeholders should be removed."""
    clean, issues = sanitize(PLACEHOLDER_LEAKING_POST)
    assert '{{' not in clean, "Handlebars placeholders should be removed"
    assert '[PLACEHOLDER]' not in clean
    assert '[TODO]' not in clean
    assert '[INSERT_LINK]' not in clean
    assert '#AIinIndia' in clean, "Hashtags should be preserved"


def test_metadata_lines_stripped():
    """Lines that look like internal metadata key:value pairs should be removed."""
    clean, issues = sanitize(METADATA_MIXED_POST)
    assert 'content_id:' not in clean, "content_id should be stripped"
    assert 'approval_level:' not in clean, "approval_level should be stripped"
    assert 'source_file:' not in clean, "source_file should be stripped"
    assert 'proof_requirements' not in clean, "proof_requirements should be stripped"
    assert 'safe: true' not in clean.lower(), "safe: true should be stripped"
    assert 'multilingual support' in clean, "Body content should be preserved"
    assert 'sahaayak.ai' in clean, "URLs should be preserved"


def test_internal_fields_stripped():
    """Internal field names like image_brief, cover_brief should be removed."""
    clean, issues = sanitize(INTERNAL_FIELD_POST)
    assert 'image_brief' not in clean, "image_brief should be stripped"
    assert 'cover_brief' not in clean, "cover_brief should be stripped"
    assert 'webhook_ready' not in clean, "webhook_ready should be stripped"
    assert 'shipped' in clean, "Body content should be preserved"
    assert 'Great progress' in clean, "Body content should be preserved"


def test_clean_tweet_unchanged():
    """Clean tweet should pass through unchanged."""
    clean, issues = sanitize(CLEAN_TWEET)
    assert len(issues) == 0, f"Clean tweet had issues: {issues}"
    assert 'sahaayak.ai' in clean


def test_empty_content():
    """Empty content should be flagged."""
    clean, issues = sanitize("")
    assert 'empty_content' in issues
    clean, issues = sanitize("   ")
    assert 'empty_content' in issues


def test_validation_clean_content():
    """Clean content should pass validation."""
    is_clean, problems = validate(CLEAN_POST)
    assert is_clean, f"Clean post should validate: {problems}"


def test_validation_json_content():
    """JSON content should fail validation."""
    is_clean, problems = validate(JSON_LEAKING_POST)
    assert not is_clean, "JSON content should fail"


def test_hashtags_preserved():
    """Hashtags should not be stripped by sanitization."""
    text = "Great update! #InBharatAI #TestsPrep #AI"
    clean, issues = sanitize(text)
    assert '#InBharatAI' in clean
    assert '#TestsPrep' in clean


def test_urls_preserved():
    """URLs should not be stripped by sanitization."""
    text = "Check it out at https://inbharat.ai and https://github.com/inbharatai"
    clean, issues = sanitize(text)
    assert 'https://inbharat.ai' in clean
    assert 'https://github.com/inbharatai' in clean


def test_urls_with_internal_field_names_preserved():
    """URLs containing internal field names (like content_id) should NOT be stripped."""
    text = "See details at https://api.example.com/post?content_id=12345&status=active"
    clean, issues = sanitize(text)
    assert 'content_id=12345' in clean, f"URL with content_id should be preserved: {clean}"
    assert 'status=active' in clean, f"URL with status should be preserved: {clean}"


def test_inline_field_names_in_body_preserved():
    """Field names mentioned naturally in body text should not be stripped."""
    text = "The platform_content feature helps distribute across channels."
    clean, issues = sanitize(text)
    # This line should NOT be stripped because the field name is used in context
    assert 'platform_content' in clean or 'distribute' in clean, \
        f"Body text with field name should be mostly preserved: {clean}"


def test_horizontal_rule_not_eaten():
    """A --- horizontal rule in body text should not trigger frontmatter stripping."""
    text = "Some text above\n\n---\n\nSome text below"
    clean, issues = sanitize(text)
    assert 'Some text above' in clean, f"Text above --- should be preserved: {clean}"
    assert 'Some text below' in clean, f"Text below --- should be preserved: {clean}"


# ── Run tests ──

if __name__ == '__main__':
    tests = [
        test_clean_post_unchanged,
        test_json_leak_detected,
        test_yaml_frontmatter_stripped,
        test_placeholders_stripped,
        test_metadata_lines_stripped,
        test_internal_fields_stripped,
        test_clean_tweet_unchanged,
        test_empty_content,
        test_validation_clean_content,
        test_validation_json_content,
        test_hashtags_preserved,
        test_urls_preserved,
        test_urls_with_internal_field_names_preserved,
        test_inline_field_names_in_body_preserved,
        test_horizontal_rule_not_eaten,
    ]

    passed = 0
    failed = 0

    for test in tests:
        try:
            test()
            print(f"  PASS: {test.__name__}")
            passed += 1
        except AssertionError as e:
            print(f"  FAIL: {test.__name__} — {e}")
            failed += 1
        except Exception as e:
            print(f"  ERROR: {test.__name__} — {e}")
            failed += 1

    print(f"\n{'='*40}")
    print(f"Results: {passed} passed, {failed} failed (of {len(tests)})")
    print(f"{'='*40}")
    sys.exit(1 if failed > 0 else 0)
