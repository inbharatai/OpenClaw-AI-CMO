"""
metadata_fields.py — Shared constants for internal metadata field names.

Used by sanitize_post.py, render_post.py, and all posting scripts to ensure
consistent metadata stripping across the entire publishing pipeline.

When a new internal field is added to content packages, add it HERE
and all files will automatically detect/strip it.
"""

# Internal metadata keys that appear as YAML-style key:value lines in queue files.
# These must be stripped before public posting.
METADATA_KEYS = frozenset([
    'title',
    'date',
    'type',
    'channel',
    'approval_level',
    'status',
    'source_file',
    'webhook_ready',
    'category',
    'adapted_from',
    'char_count',
    'content_id',
    'product',
    'audience',
    'objective',
    'platform',
    'risk_score',
    'decision_level',
    'image_brief',
    'cover_brief',
    'content_type',
    'source_confidence',
    'claim_sensitivity',
    'data_safety',
    'brand_voice_score',
    'duplication_score',
    'platform_risk',
    'risk_dimensions',
    'weighted_avg',
    'proof_requirements',
    'restricted_claims',
    'platform_content',
])
