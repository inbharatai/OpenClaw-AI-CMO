# Product Update: OpenClaw Dashboard v2

We shipped a major upgrade to the OpenClaw dashboard this week.

What's new:
- Real-time pipeline status view showing intake, approval, and distribution stages
- Content preview before publishing
- One-click approval for review queue items
- Channel-specific formatting preview (how a post looks on LinkedIn vs Discord)
- Daily/weekly/monthly report viewer built in

This makes it much easier for solo builders to manage their AI CMO without leaving the browser.

Technical details:
- Built with React + FastAPI backend
- Connects to the same Ollama instance used for content generation
- SQLite for local state management
- No cloud dependency
