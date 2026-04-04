#!/usr/bin/env python3
"""
test_enrich_image_prompt.py — Tests for image prompt enrichment.

Verifies that generic briefs are transformed into brand-aware, product-specific
DALL-E prompts with color palette, style direction, and negative guidance.

Run: python3 -m pytest OpenClawData/tests/test_enrich_image_prompt.py -v
  or: python3 OpenClawData/tests/test_enrich_image_prompt.py
"""

import sys
from pathlib import Path

# Add image-engine to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'openclaw-media' / 'image-engine'))
from enrich_image_prompt import enrich_prompt, validate_brief, load_brand_kb


# ── Test fixtures ──

GENERIC_BRIEF = "A multilingual AI chatbot interface"
PRODUCT_BRIEF = "A test preparation dashboard showing student progress"
VAGUE_BRIEF = "an ai image"
GOOD_BRIEF = "A rural Indian citizen using a phone-based AI assistant to check government scheme eligibility in Hindi"


# ── Tests ──

def test_brand_kb_loads():
    """Brand knowledge base should load successfully."""
    kb = load_brand_kb()
    assert kb is not None, "Brand KB should load from strategy/brand-knowledge-base.json"
    assert 'global' in kb, "KB should have global section"
    assert 'products' in kb, "KB should have products section"


def test_enrichment_adds_product_context():
    """Enriched prompt should contain product-specific information."""
    result = enrich_prompt(GENERIC_BRIEF, product_id='sahaayak')
    prompt = result['enriched_prompt']

    # Should be longer than original
    assert len(prompt) > len(GENERIC_BRIEF), \
        f"Enriched prompt ({len(prompt)} chars) should be longer than brief ({len(GENERIC_BRIEF)} chars)"

    # Should contain style or color information
    assert result['product'] == 'sahaayak'
    assert result['metadata']['product_found'] is True


def test_enrichment_adds_colors():
    """Enriched prompt should include brand color references."""
    result = enrich_prompt(PRODUCT_BRIEF, product_id='testsprep')
    prompt = result['enriched_prompt']

    # Should contain color hex codes or color references
    has_color = '#' in prompt or 'color' in prompt.lower() or 'palette' in prompt.lower()
    assert has_color, f"Enriched prompt should reference colors: {prompt}"


def test_enrichment_with_platform():
    """Platform-specific enrichment should include aspect ratio."""
    result = enrich_prompt(GENERIC_BRIEF, product_id='inbharat', platform='instagram')
    prompt = result['enriched_prompt']

    # Should contain aspect ratio for Instagram
    has_aspect = 'aspect' in prompt.lower() or '1:1' in prompt or '4:5' in prompt
    assert has_aspect or result['dimensions']['aspect'] == '1:1', \
        "Should include Instagram aspect ratio guidance"


def test_enrichment_with_image_type():
    """Image type should influence composition guidance."""
    result = enrich_prompt(
        "OpenClaw content pipeline architecture",
        product_id='openclaw',
        image_type='workflow_diagram'
    )
    assert result['metadata']['type_rules_found'] is True


def test_negative_prompt_generated():
    """Enrichment should generate a negative prompt (what to avoid)."""
    result = enrich_prompt(GENERIC_BRIEF, product_id='inbharat')
    negative = result['negative_prompt']

    assert 'Avoid' in negative, "Should have negative prompt guidance"
    assert len(negative) > 10, "Negative prompt should not be empty"


def test_generic_product_still_enriches():
    """Even without a product ID, global brand rules should apply."""
    result = enrich_prompt(GENERIC_BRIEF)
    prompt = result['enriched_prompt']

    assert len(prompt) > len(GENERIC_BRIEF), "Should still enrich with global rules"
    assert result['product'] == 'generic'


def test_brief_validation_rejects_vague():
    """Overly vague briefs should be rejected."""
    is_valid, reason = validate_brief(VAGUE_BRIEF)
    assert not is_valid, f"Vague brief should be rejected: {reason}"


def test_brief_validation_accepts_good():
    """Good, detailed briefs should pass validation."""
    is_valid, reason = validate_brief(GOOD_BRIEF)
    assert is_valid, f"Good brief should pass: {reason}"


def test_brief_validation_rejects_empty():
    """Empty briefs should be rejected."""
    is_valid, _ = validate_brief("")
    assert not is_valid
    is_valid, _ = validate_brief("short")
    assert not is_valid


def test_all_products_enrichable():
    """Every product in the brand KB should produce valid enrichment."""
    kb = load_brand_kb()
    if not kb:
        return  # Skip if KB not found

    for product_id in kb.get('products', {}).keys():
        result = enrich_prompt(
            f"A product visualization for {product_id}",
            product_id=product_id
        )
        assert result['metadata']['product_found'] is True, \
            f"Product {product_id} should be found in KB"
        assert len(result['enriched_prompt']) > 30, \
            f"Product {product_id} should produce meaningful enrichment"


def test_dimensions_per_platform():
    """Each platform should produce different dimension recommendations."""
    platforms = ['instagram', 'linkedin', 'x', 'discord']
    dims_set = set()
    for platform in platforms:
        result = enrich_prompt(GENERIC_BRIEF, platform=platform)
        dims_set.add(result['dimensions']['aspect'])

    # Should have at least 2 different aspect ratios across platforms
    assert len(dims_set) >= 2, \
        f"Different platforms should suggest different dimensions: {dims_set}"


# ── Run tests ──

if __name__ == '__main__':
    tests = [
        test_brand_kb_loads,
        test_enrichment_adds_product_context,
        test_enrichment_adds_colors,
        test_enrichment_with_platform,
        test_enrichment_with_image_type,
        test_negative_prompt_generated,
        test_generic_product_still_enriches,
        test_brief_validation_rejects_vague,
        test_brief_validation_accepts_good,
        test_brief_validation_rejects_empty,
        test_all_products_enrichable,
        test_dimensions_per_platform,
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
            print(f"  ERROR: {test.__name__} — {type(e).__name__}: {e}")
            failed += 1

    print(f"\n{'='*40}")
    print(f"Results: {passed} passed, {failed} failed (of {len(tests)})")
    print(f"{'='*40}")
    sys.exit(1 if failed > 0 else 0)
