# Agent Configurations

Each agent is a logical component that runs specific skills and scripts.

## Agent List

| Agent | Script | Skills Used | Memory |
|-------|--------|------------|--------|
| **HQ Coordinator** | `daily-pipeline.sh` | `hq-coordinator`, `task-planner` | `memory/hq/` |
| **Newsroom** | `newsroom-agent.sh` | `ai-news-summarizer`, `news-source-collector`, `trend-to-content` | `memory/newsroom/` |
| **Product Update** | `product-update-agent.sh` | `product-update-writer`, `build-log-writer` | `memory/product/` |
| **Content** | `content-agent.sh` | `social-repurposing`, `brand-voice`, `channel-adapter`, all writers | `memory/content/` |
| **Approval** | `approval-engine.sh` | `approval-policy`, `risk-scorer`, `duplicate-checker`, `factuality-check` | `memory/approval/` |
| **Distribution** | `distribution-engine.sh` | `channel-exporter`, `posting-queue-manager`, `discord-webhook-publisher` | `memory/distribution/` |
| **Reporting** | `generate-report.sh` | `reporting`, `content-performance-tracker` | `memory/reporting/` |
