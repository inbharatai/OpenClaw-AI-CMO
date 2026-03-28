# Quickstart Guide

Get OpenClaw AI CMO running in under 10 minutes.

---

## Prerequisites

| Requirement | Version | Purpose |
|------------|---------|---------|
| macOS or Linux | Any recent | Operating system |
| [Ollama](https://ollama.com) | Latest | Local LLM runtime |
| Python | 3.9+ | SocialFlow backend |
| pip | Latest | Python packages |

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/inbharatai/OpenClaw-AI-CMO.git
cd OpenClaw-AI-CMO
```

## Step 2: Run Setup

```bash
chmod +x setup.sh
./setup.sh
```

This will:
- Check all prerequisites
- Pull required Ollama models (qwen3:8b, qwen2.5-coder:7b)
- Install Python dependencies for SocialFlow
- Install Playwright browsers
- Create initial config files
- Verify everything works

## Step 3: Drop Your First Source Note

```bash
cat > data/source-notes/my-first-update.md << 'EOF'
# New Feature: User Dashboard

We launched a new user analytics dashboard today.
It shows real-time usage metrics, session tracking, and export capabilities.
Built with React and our custom charting library.
EOF
```

## Step 4: Run the Daily Pipeline

```bash
./openclaw-engine/scripts/daily-pipeline.sh
```

Watch as it:
1. Scans and classifies your source note
2. Processes it through the product update agent
3. Generates multi-channel content (website, LinkedIn, X, Discord)
4. Runs approval scoring
5. Routes approved content to distribution
6. Generates a daily report

## Step 5: Check Your Output

```bash
# See what was produced
ls data/product-updates/
ls data/linkedin/
ls data/x/
ls data/discord/

# See what was approved
ls approvals/approved/

# See the daily report
cat reports/daily/daily-report-*.md
```

## Step 6: Start SocialFlow (Optional — For Auto-Posting)

```bash
cd socialflow/backend
pip install -r requirements.txt
playwright install chromium
python main.py
```

Server starts at `http://localhost:8000`

## Step 7: Add Platform Credentials

```bash
# Add LinkedIn
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "linkedin", "username": "marketing@yourdomain.com", "password": "your-password"}'

# Add X/Twitter
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"platform": "x", "username": "marketing@yourdomain.com", "password": "your-password"}'

# Check status
curl http://localhost:8000/api/openclaw/status
```

## Step 8: Set Up Cron (Optional — For Automation)

```bash
# Run daily pipeline at 6 AM
echo "0 6 * * * cd /path/to/OpenClaw-AI-CMO && ./openclaw-engine/scripts/daily-pipeline.sh >> logs/cron.log 2>&1" | crontab -

# Run weekly pipeline on Mondays at 8 AM
echo "0 8 * * 1 cd /path/to/OpenClaw-AI-CMO && ./openclaw-engine/scripts/weekly-pipeline.sh >> logs/cron.log 2>&1" | crontab -
```

---

## What's Next?

- Read the [Platform Setup Guide](PLATFORM-SETUP.md) to connect all your accounts
- Read the [Architecture docs](../architecture/SYSTEM-ARCHITECTURE.md) to understand the system
- Customize `openclaw-engine/policies/` to tune approval thresholds
- Start dropping source notes daily and let the pipeline do its work
