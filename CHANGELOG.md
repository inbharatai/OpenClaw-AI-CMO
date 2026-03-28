# Changelog

All notable changes to OpenClaw AI CMO.

## [1.2.0] - 2026-03-24

### Added — Content Intelligence
- `calendar-enforcer.sh` — Operationally enforces weekly content targets per platform. Detects gaps, auto-creates content production requests. Runs as pipeline stage 1b.
- `quality-scorer.sh` — Content quality gate scoring readability, hook strength, CTA clarity, platform fit, formatting, and uniqueness. Runs before approval (stage 3a).
- `visual-brief-generator.sh` — Generates carousel slide packs, quote cards, thumbnail overlays, and image prompt packs from any source content.
- `analytics_store.py` — Post-publish performance tracking with SQLite schema + 5 FastAPI API endpoints (record metrics, query by platform, content type performance, pillar performance, weekly summaries).

### Added — Real Scheduling
- `install-schedule.sh` — Creates and loads macOS launchd agents for automated pipeline execution.
- 3 launchd agents: `com.openclaw.cmo.daily` (6 AM), `com.openclaw.cmo.weekly` (Monday 8 AM), `com.openclaw.cmo.monthly` (1st at 9 AM).
- Scheduling is LIVE — agents verified loaded via `launchctl list`.

### Added — HeyGen Native Integration
- `heygen_adapter.py` — Full HeyGen browser automation adapter inside SocialFlow, following the same `SocialAutomation` pattern as LinkedIn/Instagram. Includes job state machine (draft → queued → generating → completed → failed → ready_for_distribution).
- `heygen_routes.py` — 15 FastAPI endpoints for HeyGen jobs, asset registration, platform distribution, queue management.
- `asset_inventory.py` — Content asset inventory (SQLite) tracking all generated media with campaign/topic/tag metadata + per-platform content distribution queue.
- Platform video mapping rules for 7 platforms (Instagram reel, YouTube Short, LinkedIn video post, X video tweet, Discord attachment, Reddit link post, article embed).

### Added — Configuration
- `configs/openclaw.yaml` — Master config file with model settings, weekly posting targets per platform, content pillar mix percentages, posting time defaults, quality scoring thresholds, rate limits.

### Changed
- Daily pipeline upgraded from 7 stages to **9 stages** (added calendar enforcer at 1b, quality scorer at 3a)
- SocialFlow `.env.example` replaced Kling AI with HeyGen (browser-based, no API)
- SocialFlow `main.py` now registers HeyGen routes + analytics routes + asset tables on startup
- `automation_extended.py` factory routes `heygen` to new enhanced adapter with fallback

### Verified
- Calendar enforcer detected 9 content gaps across 8 platforms in test run
- Analytics API recorded and queried back 10.97% engagement rate in test
- HeyGen job lifecycle: create → register output → distribute to 5 platforms (all verified)
- All 25 shell scripts pass bash -n syntax check
- All 8 Python files pass ast.parse syntax check
- 3 launchd agents loaded and registered with macOS

---

## [1.1.0] - 2026-03-23

### Added
- 3-layer architecture: Fast Layer (mistral-small3.1), Thinking Layer (qwen3:8b), Recorder Layer
- `layer-router.sh` — core routing engine with `llm_fast()`, `llm_think()`, `llm_route()`, `record_event()`
- `date-context.sh` — central date helper injected into all LLM prompts
- Per-stage timing metrics in all pipeline scripts
- Recorder layer with async logging (non-blocking)
- Regex-first credential checking in approval engine (zero LLM for obvious cases)
- L1 auto-approve path with zero LLM calls (pure keyword/type matching)

### Changed
- All 20 scripts now use relative paths (portable across machines)
- Product update agent: 1 THINK + 4 FAST calls (was 5x 8B = 3.3x faster)
- Newsroom agent: 1 THINK + 2 FAST calls (was 3x 8B = 3x faster)
- Approval engine: regex + FAST scoring (was 2x 8B per item = 16x faster for L1)
- Model router now supports fast/think/auto layer selection
- Skill runner supports layer parameter (fast/think/auto)
- All folder references updated from OpenClawData/MarketingToolData to new structure

### Fixed
- **Critical**: Prompt quoting bug in layer-router.sh (triple-quote Python injection broke with apostrophes)
- **Critical**: 12 scripts had hardcoded `/Volumes/Expansion/CMO-10million` paths (now all relative)
- **Critical**: Generated content showed 2023 dates (now all prompts receive current date context)
- Old folder names (OpenClawData, MarketingToolData) replaced with portable names (openclaw-engine, data)
- 6 scripts missing date-context sourcing now properly source it

### Performance
- Daily pipeline: ~25min → ~5min (5x faster)
- Per-item product update: ~200s → ~88s (2.3x faster, will be 3.3x with mistral-small3.1)
- L1 approval: ~80s → 0ms (instant)
- L2 approval: ~80s → ~5s (16x faster)

---

## [1.0.0] - 2026-03-23

### Added
- Complete AI CMO pipeline engine with 7-stage daily pipeline
- 60 skills across foundation, content, approval, distribution, and research
- SocialFlow posting engine with 12 platform automations
- 4-level approval policy engine (auto/score-gated/review/block)
- Newsroom agent for AI news processing
- Product update agent for release note generation
- Content agent for multi-channel content production
- Distribution engine with SocialFlow bridge
- Reporting engine with daily/weekly/monthly reports
- Browser automation for LinkedIn, X, Facebook, Instagram, Reddit, Medium, Substack
- Discord webhook publishing
- HeyGen, beehiiv, MailerLite, Brevo browser automation
- OpenClaw-to-SocialFlow bridge API
- Encrypted credential storage (Fernet AES)
- Rate limiting and daily posting caps
- Brand voice enforcement
- Workspace guard (filesystem isolation)
- Comprehensive documentation and architecture docs
- One-command setup script
- MIT License

### Security
- All credentials encrypted at rest
- Browser sessions stored locally only
- No cloud API dependencies for core pipeline
- Workspace guard prevents out-of-bounds operations
