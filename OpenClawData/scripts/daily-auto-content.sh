#!/bin/bash
# daily-auto-content.sh — Automated daily content generation and publishing
# Generates at least 1 post/article per day across all platforms.
# Runs via cron at 9 AM daily. Content goes to approval queue.
#
# Platform-specific content:
#   LinkedIn  → Professional post (text + image)
#   X/Twitter → Punchy tweet (280 chars)
#   Discord   → Community update
#   Instagram → Reel caption + image (vertical 9:16)
#   Shorts    → Video brief (vertical 9:16, 15-60s) via HeyGen avatar
#   Reddit    → Value-first draft (manual post)
#   Blog      → Long-form article
#
# Usage:
#   ./daily-auto-content.sh                Run full daily cycle
#   ./daily-auto-content.sh --dry-run      Preview without generating
#   ./daily-auto-content.sh --platform x   Generate for specific platform only

set -uo pipefail

WORKSPACE_ROOT="/Volumes/Expansion/CMO-10million"
BOT_ROOT="$WORKSPACE_ROOT/OpenClawData/inbharat-bot"
MEDIA_DIR="$WORKSPACE_ROOT/OpenClawData/openclaw-media"
STRATEGY_DIR="$WORKSPACE_ROOT/OpenClawData/strategy"
QUEUES_DIR="$WORKSPACE_ROOT/OpenClawData/queues"
LOG_FILE="$WORKSPACE_ROOT/OpenClawData/logs/daily-auto-content.log"
DATE=$(date '+%Y-%m-%d')
DAY_OF_WEEK=$(date '+%u')  # 1=Monday, 7=Sunday

source "$BOT_ROOT/logging/bot-logger.sh"

DRY_RUN=false
PLATFORM_FILTER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)    DRY_RUN=true ;;
    --platform)   PLATFORM_FILTER="$2"; shift ;;
  esac
  shift
done

mkdir -p "$(dirname "$LOG_FILE")"
bot_log "daily-content" "info" "━━━ Daily Auto-Content Engine Started ━━━"
[ "$DRY_RUN" = true ] && bot_log "daily-content" "info" "[DRY RUN MODE]"

# ── Product rotation — different product each day ──
PRODUCTS=("phoring" "sahaayak" "testsprep" "inbharat" "uniassist" "openclaw" "codein")
DAY_INDEX=$(( ($(date '+%j') - 1) % ${#PRODUCTS[@]} ))
TODAYS_PRODUCT="${PRODUCTS[$DAY_INDEX]}"
bot_log "daily-content" "info" "Today's focus product: $TODAYS_PRODUCT"

# ── Content bucket rotation ──
BUCKETS=("product-proof" "founder-journey" "india-problems" "ai-education" "behind-the-scenes" "user-stories" "industry-insight")
BUCKET_INDEX=$(( ($(date '+%j') - 1) % ${#BUCKETS[@]} ))
TODAYS_BUCKET="${BUCKETS[$BUCKET_INDEX]}"
bot_log "daily-content" "info" "Today's content bucket: $TODAYS_BUCKET"

GENERATED=0
FAILED=0

# ── Helper: run command or dry-run ──
run_or_preview() {
  local DESC="$1"
  shift
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would: $DESC"
    echo "  Command: $*"
    return 0
  fi
  echo "→ $DESC"
  "$@" 2>&1
  return $?
}

# ══════════════════════════════════════════════════════════════
# DAILY CONTENT SCHEDULE
# ══════════════════════════════════════════════════════════════

# ── 1. LinkedIn Post (daily) ──
if [ -z "$PLATFORM_FILTER" ] || [ "$PLATFORM_FILTER" = "linkedin" ]; then
  bot_log "daily-content" "info" "Generating LinkedIn post..."
  if run_or_preview "Generate LinkedIn post about $TODAYS_PRODUCT" \
    bash "$MEDIA_DIR/native-pipeline/generate-content.sh" \
      --product "$TODAYS_PRODUCT" \
      --platform linkedin \
      --bucket "$TODAYS_BUCKET"; then
    GENERATED=$((GENERATED + 1))
    bot_log "daily-content" "info" "LinkedIn content generated ✅"
  else
    FAILED=$((FAILED + 1))
    bot_log "daily-content" "warn" "LinkedIn generation failed"
  fi
fi

# ── 2. X/Twitter Tweet (daily) ──
if [ -z "$PLATFORM_FILTER" ] || [ "$PLATFORM_FILTER" = "x" ]; then
  bot_log "daily-content" "info" "Generating X tweet..."
  if run_or_preview "Generate X tweet about $TODAYS_PRODUCT" \
    bash "$MEDIA_DIR/native-pipeline/generate-content.sh" \
      --product "$TODAYS_PRODUCT" \
      --platform x \
      --bucket "$TODAYS_BUCKET"; then
    GENERATED=$((GENERATED + 1))
    bot_log "daily-content" "info" "X tweet generated ✅"
  else
    FAILED=$((FAILED + 1))
    bot_log "daily-content" "warn" "X tweet generation failed"
  fi
fi

# ── 3. Discord Update (daily) ──
if [ -z "$PLATFORM_FILTER" ] || [ "$PLATFORM_FILTER" = "discord" ]; then
  bot_log "daily-content" "info" "Generating Discord update..."
  if run_or_preview "Generate Discord update about $TODAYS_PRODUCT" \
    bash "$MEDIA_DIR/native-pipeline/generate-content.sh" \
      --product "$TODAYS_PRODUCT" \
      --platform discord \
      --bucket "$TODAYS_BUCKET"; then
    GENERATED=$((GENERATED + 1))
    bot_log "daily-content" "info" "Discord update generated ✅"
  else
    FAILED=$((FAILED + 1))
    bot_log "daily-content" "warn" "Discord generation failed"
  fi
fi

# ── 4. Instagram Reel (daily — caption + image brief + video brief) ──
if [ -z "$PLATFORM_FILTER" ] || [ "$PLATFORM_FILTER" = "instagram" ]; then
  bot_log "daily-content" "info" "Generating Instagram Reel content..."
  if run_or_preview "Generate Instagram Reel about $TODAYS_PRODUCT" \
    bash "$MEDIA_DIR/native-pipeline/generate-content.sh" \
      --product "$TODAYS_PRODUCT" \
      --platform instagram \
      --bucket "$TODAYS_BUCKET"; then
    GENERATED=$((GENERATED + 1))
    bot_log "daily-content" "info" "Instagram content generated ✅"
  else
    FAILED=$((FAILED + 1))
    bot_log "daily-content" "warn" "Instagram generation failed"
  fi
fi

# ── 5. YouTube Shorts / HeyGen Video Brief (daily) ──
if [ -z "$PLATFORM_FILTER" ] || [ "$PLATFORM_FILTER" = "shorts" ]; then
  bot_log "daily-content" "info" "Generating Shorts video brief..."

  # First generate content package for shorts
  if run_or_preview "Generate Shorts content about $TODAYS_PRODUCT" \
    bash "$MEDIA_DIR/native-pipeline/generate-content.sh" \
      --product "$TODAYS_PRODUCT" \
      --platform shorts \
      --bucket "$TODAYS_BUCKET"; then

    # Then generate HeyGen avatar video brief from the content package
    LATEST_SHORTS=$(ls -t "$QUEUES_DIR/shorts/pending/"*.json 2>/dev/null | head -1)
    if [ -n "$LATEST_SHORTS" ] && [ -f "$LATEST_SHORTS" ]; then
      if run_or_preview "Generate HeyGen avatar brief for Shorts" \
        bash "$MEDIA_DIR/video-engine/generate-video.sh" \
          --heygen --file "$LATEST_SHORTS" --format shorts; then
        bot_log "daily-content" "info" "Shorts + HeyGen brief generated ✅"
      else
        bot_log "daily-content" "warn" "HeyGen brief generation failed (content still queued)"
      fi
    fi
    GENERATED=$((GENERATED + 1))
  else
    FAILED=$((FAILED + 1))
    bot_log "daily-content" "warn" "Shorts generation failed"
  fi
fi

# ── 6. Blog Article (every 3 days) ──
if [ -z "$PLATFORM_FILTER" ] || [ "$PLATFORM_FILTER" = "blog" ]; then
  if [ $(($(date '+%j') % 3)) -eq 0 ]; then
    bot_log "daily-content" "info" "Generating blog article (every 3 days)..."
    BLOG_TOPICS=(
      "How AI is solving real problems in rural India"
      "Building local-first AI tools — why it matters"
      "The future of AI-powered communication in India"
      "Why Indian startups need their own AI infrastructure"
      "Lessons from building AI products for Bharat"
      "Open source AI tools for Indian developers"
      "How AI can transform Indian education"
    )
    BLOG_INDEX=$(( ($(date '+%j') / 3) % ${#BLOG_TOPICS[@]} ))
    BLOG_TOPIC="${BLOG_TOPICS[$BLOG_INDEX]}"

    if run_or_preview "Generate blog: $BLOG_TOPIC" \
      bash "$BOT_ROOT/inbharat-run.sh" blog generate "$BLOG_TOPIC"; then
      GENERATED=$((GENERATED + 1))
      bot_log "daily-content" "info" "Blog generated ✅"
    else
      FAILED=$((FAILED + 1))
      bot_log "daily-content" "warn" "Blog generation failed"
    fi
  else
    bot_log "daily-content" "info" "Blog: skipping today (runs every 3 days)"
  fi
fi

# ── 7. Reddit Draft (every 5 days) ──
if [ -z "$PLATFORM_FILTER" ] || [ "$PLATFORM_FILTER" = "reddit" ]; then
  if [ $(($(date '+%j') % 5)) -eq 0 ]; then
    bot_log "daily-content" "info" "Generating Reddit draft (every 5 days)..."

    SUBREDDITS=("r/SaaS" "r/artificial" "r/IndiaHacks" "r/LocalLLaMA" "r/startups")
    SUB_INDEX=$(( ($(date '+%j') / 5) % ${#SUBREDDITS[@]} ))
    TARGET_SUB="${SUBREDDITS[$SUB_INDEX]}"

    REDDIT_TOPICS=(
      "building AI tools for India-specific problems"
      "running local LLMs for production content pipelines"
      "open source AI marketing automation"
      "solving rural education with AI in India"
      "why local-first AI matters for developing countries"
    )
    REDDIT_INDEX=$(( ($(date '+%j') / 5) % ${#REDDIT_TOPICS[@]} ))
    REDDIT_TOPIC="${REDDIT_TOPICS[$REDDIT_INDEX]}"

    if run_or_preview "Draft Reddit post: $REDDIT_TOPIC for $TARGET_SUB" \
      bash "$BOT_ROOT/inbharat-run.sh" reddit draft "$REDDIT_TOPIC" --subreddit "$TARGET_SUB" --product "$TODAYS_PRODUCT"; then
      GENERATED=$((GENERATED + 1))
      bot_log "daily-content" "info" "Reddit draft generated ✅"
    else
      FAILED=$((FAILED + 1))
      bot_log "daily-content" "warn" "Reddit draft failed"
    fi
  else
    bot_log "daily-content" "info" "Reddit: skipping today (runs every 5 days)"
  fi
fi

# ── 8. Intelligence Scan (daily — rotates between scan types) ──
if [ -z "$PLATFORM_FILTER" ]; then
  SCAN_TYPES=("india-problems" "ai-gaps" "funding" "competitor" "ecosystem")
  SCAN_INDEX=$(( ($(date '+%j') - 1) % ${#SCAN_TYPES[@]} ))
  TODAYS_SCAN="${SCAN_TYPES[$SCAN_INDEX]}"

  bot_log "daily-content" "info" "Running daily intelligence scan: $TODAYS_SCAN"
  if run_or_preview "Intelligence scan: $TODAYS_SCAN" \
    bash "$BOT_ROOT/inbharat-run.sh" "$TODAYS_SCAN" scan; then
    bot_log "daily-content" "info" "Intelligence scan complete ✅"
  else
    bot_log "daily-content" "warn" "Intelligence scan failed (non-critical)"
  fi
fi

# ══════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════

bot_log "daily-content" "info" "━━━ Daily Content Complete ━━━"
bot_log "daily-content" "info" "Generated: $GENERATED | Failed: $FAILED"
bot_log "daily-content" "info" "Product: $TODAYS_PRODUCT | Bucket: $TODAYS_BUCKET"

# Show queue status
echo ""
echo "━━━ DAILY AUTO-CONTENT SUMMARY ━━━"
echo "Date: $DATE"
echo "Product: $TODAYS_PRODUCT"
echo "Bucket: $TODAYS_BUCKET"
echo "Generated: $GENERATED | Failed: $FAILED"
echo ""
echo "Queue Status:"
for PLATFORM in discord linkedin x instagram shorts reddit; do
  COUNT=$(find "$QUEUES_DIR/$PLATFORM/pending" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
  echo "  $PLATFORM: $COUNT pending"
done
echo ""
echo "HeyGen Briefs:"
COUNT=$(find "$QUEUES_DIR/heygen/pending" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
echo "  $COUNT briefs waiting for video production"
echo ""

# Send WhatsApp notification
MSG="📝 *Daily Content Generated*
📅 $DATE

🎯 Focus: $TODAYS_PRODUCT ($TODAYS_BUCKET)
✅ Generated: $GENERATED pieces
❌ Failed: $FAILED

📋 *What's waiting for you:*"

for PLATFORM in linkedin x discord instagram shorts; do
  COUNT=$(find "$QUEUES_DIR/$PLATFORM/pending" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$COUNT" -gt 0 ]; then
    MSG="$MSG
• $PLATFORM: $COUNT pending"
  fi
done

HEYGEN_COUNT=$(find "$QUEUES_DIR/heygen/pending" -type f ! -name ".*" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
if [ "$HEYGEN_COUNT" -gt 0 ]; then
  MSG="$MSG
• HeyGen: $HEYGEN_COUNT video briefs ready

🎬 To create avatar videos: review HeyGen briefs and produce in HeyGen studio"
fi

MSG="$MSG

Reply 'what's pending' to see details
Reply 'approve <filename>' to publish"

# Send via OpenClaw
openclaw message send \
  --channel whatsapp \
  --target "+919015823397" \
  --message "$MSG" 2>/dev/null || echo "WhatsApp notification skipped"

echo "Daily content cycle complete."
