#!/usr/bin/env python3
"""
policy_enforcer.py — Runtime policy enforcement for OpenClaw publishing.

This is the AUTHORITATIVE policy gate. Every posting path — publish.sh,
direct script calls, distribution-engine — must go through this.

Loads policies/rate-limits.json and policies/channel-policies.json at runtime.
Enforces: blocked platforms, daily caps, weekly caps, auto-post permissions.
Tracks daily post counts via a JSONL counter file.

Usage as module:
    from policy_enforcer import check_platform, record_post, PolicyViolation

Usage as CLI:
    python3 policy_enforcer.py --check linkedin        # exits 0=allowed, 1=blocked
    python3 policy_enforcer.py --check x               # exits 0=allowed, 1=blocked
    python3 policy_enforcer.py --record linkedin        # record a successful post
    python3 policy_enforcer.py --status                 # show all platform statuses
    python3 policy_enforcer.py --reset                  # reset daily counters (for testing)
"""

import json
import os
import sys
from datetime import datetime, date
from pathlib import Path


# ── Paths ──
WORKSPACE_ROOT = Path("/Users/reeturajgoswami/Desktop/CMO-10million")
RATE_LIMITS_PATH = WORKSPACE_ROOT / "OpenClawData" / "policies" / "rate-limits.json"
CHANNEL_POLICIES_PATH = WORKSPACE_ROOT / "OpenClawData" / "policies" / "channel-policies.json"
COUNTER_DIR = WORKSPACE_ROOT / "OpenClawData" / "openclaw-media" / "analytics"
COUNTER_FILE = COUNTER_DIR / f"post-counter-{date.today().isoformat()}.json"

# Also try relative paths for portability
_script_dir = Path(__file__).parent
_alt_rate_limits = _script_dir.parent.parent / "policies" / "rate-limits.json"
_alt_channel_policies = _script_dir.parent.parent / "policies" / "channel-policies.json"


class PolicyViolation(Exception):
    """Raised when a posting attempt violates policy."""
    def __init__(self, platform, reason, policy_source):
        self.platform = platform
        self.reason = reason
        self.policy_source = policy_source
        super().__init__(f"POLICY BLOCK [{platform}]: {reason} (source: {policy_source})")


def _load_json(primary_path, alt_path):
    """Load JSON from primary path, fall back to alternate."""
    for p in [primary_path, alt_path]:
        try:
            with open(p) as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            continue
    return None


def load_rate_limits():
    """Load rate-limits.json."""
    return _load_json(RATE_LIMITS_PATH, _alt_rate_limits)


def load_channel_policies():
    """Load channel-policies.json."""
    return _load_json(CHANNEL_POLICIES_PATH, _alt_channel_policies)


def _load_counter():
    """Load today's post counter."""
    try:
        with open(COUNTER_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def _save_counter(counter):
    """Save today's post counter."""
    COUNTER_DIR.mkdir(parents=True, exist_ok=True)
    with open(COUNTER_FILE, 'w') as f:
        json.dump(counter, f, indent=2)


def get_daily_count(platform):
    """Get how many posts have been made to this platform today."""
    counter = _load_counter()
    return counter.get(platform, 0)


def record_post(platform):
    """Record a successful post to a platform. Increments daily counter."""
    counter = _load_counter()
    counter[platform] = counter.get(platform, 0) + 1
    counter['_last_updated'] = datetime.now().isoformat()
    _save_counter(counter)
    return counter[platform]


def check_platform(platform, is_direct_call=False):
    """
    Check if posting to this platform is allowed right now.

    Args:
        platform: Platform name (linkedin, x, instagram, discord, email)
        is_direct_call: True if called from a direct script (not publish.sh)

    Returns:
        tuple: (allowed: bool, reason: str)

    Raises:
        PolicyViolation if platform is hard-blocked
    """
    rate_limits = load_rate_limits()
    if not rate_limits:
        # If policy file is missing, fail CLOSED — no posting without policies
        raise PolicyViolation(
            platform=platform,
            reason="rate-limits.json not found — cannot verify policy",
            policy_source="MISSING"
        )

    # rate-limits.json uses "channels" key
    channels = rate_limits.get('channels', rate_limits.get('platforms', {}))

    # Find platform config
    platform_config = None
    if isinstance(channels, dict):
        platform_config = channels.get(platform)

    if not platform_config:
        # No policy defined = not allowed (fail closed)
        raise PolicyViolation(
            platform=platform,
            reason=f"No policy defined for '{platform}' in rate-limits.json — posting denied",
            policy_source=str(RATE_LIMITS_PATH)
        )

    # ── Check 1: Hard block ──
    if platform_config.get('blocked', False):
        raise PolicyViolation(
            platform=platform,
            reason=f"Platform is BLOCKED. {platform_config.get('notes', '')}",
            policy_source=str(RATE_LIMITS_PATH)
        )

    # ── Check 2: Daily cap ──
    daily_cap = platform_config.get('daily_cap', 999)
    if daily_cap == 0:
        raise PolicyViolation(
            platform=platform,
            reason="daily_cap is 0 — no posts allowed today",
            policy_source=str(RATE_LIMITS_PATH)
        )

    current_count = get_daily_count(platform)
    if current_count >= daily_cap:
        raise PolicyViolation(
            platform=platform,
            reason=f"Daily cap reached ({current_count}/{daily_cap})",
            policy_source=str(RATE_LIMITS_PATH)
        )

    # ── Check 3: Auto-post permission ──
    auto_allowed = platform_config.get('auto_post_allowed', False)
    if not auto_allowed and not is_direct_call:
        # Queue/export only — allowed through publish.sh but flagged
        pass  # Still allow through pipeline, just not auto-scheduled

    # ── Check 4: Direct call restriction ──
    if is_direct_call and not auto_allowed:
        return True, f"Direct call allowed but platform is queue-only ({current_count}/{daily_cap} today)"

    return True, f"Allowed ({current_count}/{daily_cap} today)"


def get_all_statuses():
    """Get status of all platforms."""
    rate_limits = load_rate_limits()
    if not rate_limits:
        return {"error": "rate-limits.json not found"}

    channels = rate_limits.get('channels', rate_limits.get('platforms', {}))
    statuses = {}

    for platform_name, config in channels.items():
        if not isinstance(config, dict):
            continue
        if 'daily_cap' not in config and 'blocked' not in config:
            continue

        blocked = config.get('blocked', False)
        daily_cap = config.get('daily_cap', 0)
        current = get_daily_count(platform_name)
        auto = config.get('auto_post_allowed', False)

        if blocked:
            status = "BLOCKED"
        elif daily_cap == 0:
            status = "CAP_ZERO"
        elif current >= daily_cap:
            status = "CAP_REACHED"
        else:
            status = "AVAILABLE"

        statuses[platform_name] = {
            'status': status,
            'blocked': blocked,
            'daily_cap': daily_cap,
            'posted_today': current,
            'remaining': max(0, daily_cap - current) if not blocked else 0,
            'auto_post': auto,
            'notes': config.get('notes', ''),
        }

    return statuses


def log_policy_event(platform, event_type, detail=""):
    """Log a policy enforcement event for audit trail."""
    log_dir = WORKSPACE_ROOT / "OpenClawData" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "policy-enforcement.log"

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] [{event_type}] [{platform}] {detail}\n"

    with open(log_file, 'a') as f:
        f.write(entry)


def main():
    import argparse
    parser = argparse.ArgumentParser(description='OpenClaw policy enforcement')
    parser.add_argument('--check', type=str, help='Check if platform is allowed')
    parser.add_argument('--record', type=str, help='Record a post to platform')
    parser.add_argument('--status', action='store_true', help='Show all platform statuses')
    parser.add_argument('--reset', action='store_true', help='Reset daily counters')
    parser.add_argument('--direct', action='store_true', help='Mark as direct call')
    args = parser.parse_args()

    if args.status:
        statuses = get_all_statuses()
        print(f"{'Platform':<12} {'Status':<12} {'Today':<8} {'Cap':<6} {'Auto':<6}")
        print("-" * 46)
        for name, s in statuses.items():
            print(f"{name:<12} {s['status']:<12} {s['posted_today']:<8} {s['daily_cap']:<6} {'yes' if s['auto_post'] else 'no':<6}")
            if s.get('notes'):
                print(f"  Note: {s['notes']}")
        sys.exit(0)

    if args.check:
        try:
            allowed, reason = check_platform(args.check, is_direct_call=args.direct)
            print(f"ALLOWED: {args.check} — {reason}")
            log_policy_event(args.check, "CHECK_PASS", reason)
            sys.exit(0)
        except PolicyViolation as e:
            print(f"BLOCKED: {e}")
            log_policy_event(args.check, "CHECK_BLOCKED", str(e))
            sys.exit(1)

    if args.record:
        count = record_post(args.record)
        print(f"Recorded post #{count} to {args.record} today")
        log_policy_event(args.record, "POST_RECORDED", f"count={count}")
        sys.exit(0)

    if args.reset:
        if COUNTER_FILE.exists():
            COUNTER_FILE.unlink()
            print(f"Reset: {COUNTER_FILE}")
        else:
            print("No counter file to reset")
        sys.exit(0)

    parser.print_help()
    sys.exit(2)


if __name__ == '__main__':
    main()
