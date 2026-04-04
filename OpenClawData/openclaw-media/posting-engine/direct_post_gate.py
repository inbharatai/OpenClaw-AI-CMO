"""
direct_post_gate.py — Gate for direct posting script invocations.

Every posting script (post_linkedin.py, post_x.py, etc.) must call
gate_direct_post() before posting. This enforces:

1. --allow-direct-post flag is required (unless called from publish.sh)
2. Policy enforcement (blocked platforms, daily caps)
3. Logging of all direct post attempts

Usage in posting scripts:
    from direct_post_gate import gate_direct_post
    gate_direct_post(platform="linkedin", args=args)
"""

import os
import sys
from datetime import datetime
from pathlib import Path


def gate_direct_post(platform, args):
    """
    Enforce policy gate for direct posting script calls.

    Args:
        platform: Platform name (linkedin, x, instagram, discord)
        args: argparse namespace with --allow-direct-post flag

    Raises:
        SystemExit if posting is not allowed
    """
    # Skip gate for login/check/setup/dry-run actions
    if getattr(args, 'login', False) or getattr(args, 'check', False) or \
       getattr(args, 'setup', False) or getattr(args, 'dry_run', False):
        return

    # Skip if no content to post
    if not getattr(args, 'text', None) and not getattr(args, 'file', None):
        return

    allow_direct = getattr(args, 'allow_direct_post', False)

    # ── Log the attempt ──
    _log_attempt(platform, "direct" if not allow_direct else "authorized", args)

    # ── Check 1: --allow-direct-post flag ──
    if not allow_direct:
        print(f"ERROR: Direct posting to {platform} is not allowed.", file=sys.stderr)
        print(f"  Use publish.sh as the canonical publish path.", file=sys.stderr)
        print(f"  If you must post directly, add --allow-direct-post flag.", file=sys.stderr)
        print(f"  This attempt has been logged.", file=sys.stderr)
        sys.exit(1)

    # ── Check 2: Policy enforcement ──
    try:
        sys.path.insert(0, str(Path(__file__).parent))
        from policy_enforcer import check_platform, PolicyViolation, log_policy_event

        try:
            allowed, reason = check_platform(platform, is_direct_call=True)
            log_policy_event(platform, "DIRECT_POST_ALLOWED", reason)
        except PolicyViolation as e:
            log_policy_event(platform, "DIRECT_POST_BLOCKED", str(e))
            print(f"POLICY BLOCK: {e}", file=sys.stderr)
            sys.exit(1)

    except ImportError:
        # policy_enforcer not available — warn but allow
        print(f"WARNING: policy_enforcer.py not found — posting without policy check",
              file=sys.stderr)


def _log_attempt(platform, attempt_type, args):
    """Log direct post attempts for audit trail."""
    log_dir = Path("/Volumes/Expansion/CMO-10million/OpenClawData/logs")
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "direct-post-attempts.log"

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    source = getattr(args, 'file', getattr(args, 'text', 'inline')[:50] if getattr(args, 'text', None) else 'unknown')
    entry = f"[{timestamp}] [{attempt_type}] [{platform}] source={source}\n"

    try:
        with open(log_file, 'a') as f:
            f.write(entry)
    except Exception:
        pass
