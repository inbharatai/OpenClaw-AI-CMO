#!/usr/bin/env python3
"""
enrich_image_prompt.py — Transform generic image briefs into brand-aware DALL-E prompts.

Takes a raw image brief (e.g. "A multilingual AI chatbot interface") and enriches it
with product context, brand colors, visual style direction, platform sizing,
composition guidance, and negative prompt instructions.

This is the bridge between content planning (which says WHAT to show)
and image generation (which needs to know HOW to render it).

Usage:
    # Basic enrichment
    python3 enrich_image_prompt.py --brief "A multilingual chatbot interface" --product sahaayak

    # Full context
    python3 enrich_image_prompt.py \
        --brief "A multilingual chatbot interface" \
        --product sahaayak \
        --platform instagram \
        --image-type static_post \
        --output /tmp/enriched-prompt.txt

    # JSON output with all metadata
    python3 enrich_image_prompt.py --brief "..." --product inbharat --json

Exit codes:
    0 = success
    1 = brief too generic or missing product
    2 = usage error
"""

import argparse
import json
import sys
from pathlib import Path


# ── Load brand knowledge base ──
def load_brand_kb():
    """Load the canonical brand knowledge base."""
    kb_paths = [
        Path(__file__).parent.parent.parent / 'strategy' / 'brand-knowledge-base.json',
        Path('/Users/reeturajgoswami/Desktop/CMO-10million/OpenClawData/strategy/brand-knowledge-base.json'),
    ]
    for path in kb_paths:
        try:
            with open(path) as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            continue
    return None


def get_product_context(kb, product_id):
    """Extract product-specific visual context from brand KB."""
    if not kb:
        return None
    products = kb.get('products', {})
    # Try exact match first, then case-insensitive
    product = products.get(product_id)
    if not product:
        for key, val in products.items():
            if key.lower() == product_id.lower():
                product = val
                break
    return product


def get_image_type_rules(kb, image_type):
    """Get composition rules for a specific image type."""
    if not kb:
        return None
    return kb.get('image_types', {}).get(image_type)


def get_platform_dimensions(platform):
    """Get recommended image dimensions for a platform."""
    dims = {
        'instagram': {'size': '1080x1080', 'aspect': '1:1', 'dalle_size': '1024x1024'},
        'instagram_story': {'size': '1080x1920', 'aspect': '9:16', 'dalle_size': '1024x1792'},
        'linkedin': {'size': '1200x627', 'aspect': '1.91:1', 'dalle_size': '1792x1024'},
        'x': {'size': '1200x675', 'aspect': '16:9', 'dalle_size': '1792x1024'},
        'discord': {'size': '1200x675', 'aspect': '16:9', 'dalle_size': '1792x1024'},
        'youtube_thumbnail': {'size': '1280x720', 'aspect': '16:9', 'dalle_size': '1792x1024'},
    }
    return dims.get(platform, dims['instagram'])


# Platform-specific visual style direction
PLATFORM_STYLES = {
    'linkedin': 'Professional SaaS aesthetic. Clean, modern, minimal. Product mockups, data visualizations, clean typography. Business-appropriate. No casual or playful elements.',
    'instagram': 'Vibrant, eye-catching. Indian context where relevant — real scenarios, bright colors, educational visual. Strong visual hierarchy. Must work as a standalone square image.',
    'x': 'Minimal and clean. Simple graphic, text card, or single focal point. Brand accent colors. Must read well at small sizes in a feed.',
    'discord': 'Casual and community-friendly. Simpler visual, can be more playful. Clear and easy to understand at a glance.',
}


def enrich_prompt(brief, product_id=None, platform=None, image_type=None):
    """
    Enrich a raw image brief into a full DALL-E prompt.

    Returns:
        dict: {
            'original_brief': str,
            'enriched_prompt': str,
            'style_direction': str,
            'negative_prompt': str,
            'dimensions': dict,
            'product': str,
            'metadata': dict
        }
    """
    kb = load_brand_kb()
    product = get_product_context(kb, product_id) if product_id else None
    type_rules = get_image_type_rules(kb, image_type) if image_type else None
    dims = get_platform_dimensions(platform) if platform else get_platform_dimensions('instagram')
    global_rules = kb.get('global', {}) if kb else {}

    # ── Build enriched prompt ──
    prompt_parts = []

    # 1. Core visual concept from brief
    prompt_parts.append(brief.strip().rstrip('.'))

    # 2. Product context
    if product:
        product_name = product.get('product_name', '')
        visual_style = product.get('visual_style', {})
        mood = visual_style.get('mood', '') if isinstance(visual_style, dict) else str(visual_style)

        if mood:
            prompt_parts.append(f'Style: {mood}')

        # Product-specific image rules
        prompt_rules = product.get('image_prompt_rules', '')
        if prompt_rules:
            prompt_parts.append(prompt_rules)

        # Brand colors
        colors = product.get('preferred_colors', [])
        if colors:
            color_str = ', '.join(colors[:3])
            prompt_parts.append(f'Color palette: {color_str}')

    # 3. Image type composition
    if type_rules:
        comp = type_rules.get('composition', '')
        if comp:
            prompt_parts.append(f'Composition: {comp}')
        text_overlay = type_rules.get('text_overlay', '')
        if text_overlay:
            prompt_parts.append(f'Text overlay: {text_overlay}')

    # 4. Global visual principles
    if global_rules:
        principles = global_rules.get('visual_principles', [])
        if principles:
            # Add top 3 most relevant principles
            prompt_parts.append(f'Design: {", ".join(principles[:3])}')

    # 5. Platform-specific visual style
    if platform and platform in PLATFORM_STYLES:
        prompt_parts.append(f'Platform style: {PLATFORM_STYLES[platform]}')

    # 6. Platform sizing hint
    if dims:
        prompt_parts.append(f'Aspect ratio: {dims.get("aspect", "1:1")}')

    # ── Build negative prompt (what to avoid) ──
    negative_parts = []

    if product:
        visual_style = product.get('visual_style', {})
        if isinstance(visual_style, dict):
            avoid = visual_style.get('avoid', [])
            negative_parts.extend(avoid)

    if global_rules:
        prohibited = global_rules.get('prohibited_visual_styles', [])
        negative_parts.extend(prohibited[:5])  # Top 5 global prohibitions

    # Always avoid these
    negative_parts.extend([
        'no watermarks',
        'no text unless specified',
        'no blurry or low quality',
    ])

    # ── Compose final prompt ──
    enriched = '. '.join(prompt_parts) + '.'
    negative = 'Avoid: ' + '; '.join(list(set(negative_parts))[:8])

    # Build style direction summary
    style_parts = []
    if product:
        style_parts.append(product.get('product_name', 'unknown'))
    style_parts.append(image_type or 'general')
    style_parts.append(platform or 'multi-platform')
    style_direction = ' | '.join(style_parts)

    return {
        'original_brief': brief,
        'enriched_prompt': enriched,
        'style_direction': style_direction,
        'negative_prompt': negative,
        'dimensions': dims,
        'product': product_id or 'generic',
        'metadata': {
            'product_found': product is not None,
            'type_rules_found': type_rules is not None,
            'platform': platform,
            'image_type': image_type,
            'prompt_length': len(enriched),
        }
    }


def validate_brief(brief):
    """Check if a brief is too generic to produce a good image."""
    if not brief or len(brief.strip()) < 10:
        return False, 'Brief too short (< 10 chars)'

    # Check for overly generic briefs
    generic_phrases = [
        'an ai image',
        'a nice picture',
        'something about ai',
        'a technology image',
        'a cool graphic',
        'an abstract design',
    ]
    brief_lower = brief.lower().strip()
    for phrase in generic_phrases:
        if brief_lower == phrase or brief_lower.startswith(phrase):
            return False, f'Brief too generic: "{brief}"'

    return True, 'ok'


def main():
    parser = argparse.ArgumentParser(description='Enrich image briefs with brand context for DALL-E')
    parser.add_argument('--brief', type=str, required=True, help='Raw image brief text')
    parser.add_argument('--product', type=str, help='Product ID (e.g., sahaayak, testsprep, inbharat)')
    parser.add_argument('--platform', type=str,
                        choices=['instagram', 'instagram_story', 'linkedin', 'x', 'discord', 'youtube_thumbnail'],
                        help='Target platform')
    parser.add_argument('--image-type', type=str,
                        choices=['static_post', 'carousel_cover', 'infographic', 'ui_mockup',
                                 'conceptual_poster', 'product_explainer', 'workflow_diagram', 'founder_message'],
                        help='Type of image')
    parser.add_argument('--output', type=str, help='Write enriched prompt to file')
    parser.add_argument('--json', action='store_true', help='Output full JSON with metadata')
    args = parser.parse_args()

    # Validate brief
    is_valid, reason = validate_brief(args.brief)
    if not is_valid:
        print(f'ERROR: {reason}', file=sys.stderr)
        sys.exit(1)

    # Enrich
    result = enrich_prompt(
        brief=args.brief,
        product_id=args.product,
        platform=args.platform,
        image_type=args.image_type,
    )

    if args.json:
        print(json.dumps(result, indent=2))
    elif args.output:
        Path(args.output).write_text(result['enriched_prompt'])
        print(f'Enriched prompt ({len(result["enriched_prompt"])} chars) written to {args.output}',
              file=sys.stderr)
    else:
        print(result['enriched_prompt'])
        if result['negative_prompt']:
            print(f'\n--- Negative ---\n{result["negative_prompt"]}', file=sys.stderr)

    sys.exit(0)


if __name__ == '__main__':
    main()
