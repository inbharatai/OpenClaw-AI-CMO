# OpenClaw AI CMO — System Architecture

## Overview

OpenClaw AI CMO is a **local-first, multi-agent content pipeline** that transforms raw inputs (product updates, AI news, daily work) into platform-ready content, approves it through a policy engine, and distributes it to 17+ channels.

---

## Core Architecture Diagram

```
+------------------------------------------------------------------+
|                        OPENCLAW AI CMO                           |
+------------------------------------------------------------------+
|                                                                  |
|  +------------------+    +------------------+                    |
|  |   SOURCE INTAKE  |    |   SCHEDULED      |                    |
|  |   (Manual Input) |    |   PIPELINES      |                    |
|  |                  |    |   (Cron/Manual)   |                    |
|  | - source-notes/  |    | - daily-pipeline  |                    |
|  | - source-links/  |    | - weekly-pipeline |                    |
|  | - screenshots/   |    | - monthly-pipeline|                    |
|  +--------+---------+    +--------+---------+                    |
|           |                       |                              |
|           +-----------+-----------+                              |
|                       |                                          |
|              +--------v---------+                                |
|              |  INTAKE ENGINE   |                                |
|              |  (intake-        |                                |
|              |   processor.sh)  |                                |
|              |                  |                                |
|              | - Classify type  |                                |
|              | - Tag metadata   |                                |
|              | - Route to agent |                                |
|              +--------+---------+                                |
|                       |                                          |
|        +--------------+--------------+                           |
|        |              |              |                            |
|  +-----v------+ +----v-------+ +----v--------+                  |
|  | NEWSROOM   | | PRODUCT    | | CONTENT     |                  |
|  | AGENT      | | UPDATE     | | AGENT       |                  |
|  |            | | AGENT      | |             |                  |
|  | newsroom-  | | product-   | | content-    |                  |
|  | agent.sh   | | update-    | | agent.sh    |                  |
|  |            | | agent.sh   | |             |                  |
|  | Processes: | | Processes: | | Produces:   |                  |
|  | - AI news  | | - Releases | | - Website   |                  |
|  | - Trends   | | - Features | | - Social    |                  |
|  | - Market   | | - Logs     | | - Newsletter|                  |
|  +-----+------+ +----+-------+ | - Articles  |                  |
|        |              |         | - Briefs    |                  |
|        +--------------+         +----+--------+                  |
|                       |              |                           |
|                       +--------------+                           |
|                              |                                   |
|                    +---------v----------+                        |
|                    |  APPROVAL ENGINE   |                        |
|                    |  (approval-        |                        |
|                    |   engine.sh)       |                        |
|                    |                    |                        |
|                    | L1: Auto-Approve   |                        |
|                    | L2: Score-Gated    |                        |
|                    | L3: Review Queue   |                        |
|                    | L4: Block          |                        |
|                    +---------+----------+                        |
|                              |                                   |
|                    +---------v----------+                        |
|                    | DISTRIBUTION       |                        |
|                    | ENGINE             |                        |
|                    | (distribution-     |                        |
|                    |  engine.sh)        |                        |
|                    |                    |                        |
|                    | Routes to:         |                        |
|                    | - Website queue    |                        |
|                    | - SocialFlow API   |                        |
|                    | - Email exports    |                        |
|                    | - Manual review    |                        |
|                    +---------+----------+                        |
|                              |                                   |
|            +-----------------+------------------+                |
|            |                 |                  |                |
|    +-------v------+  +------v-------+  +-------v------+        |
|    | WEBSITE      |  | SOCIALFLOW   |  | EMAIL        |        |
|    | QUEUE        |  | ENGINE       |  | EXPORT       |        |
|    | (files)      |  | (FastAPI +   |  | (files)      |        |
|    |              |  |  Playwright) |  |              |        |
|    +--------------+  +------+-------+  +--------------+        |
|                             |                                   |
+------------------------------------------------------------------+
                              |
            +-----------------+------------------+
            |        |        |        |         |
         LinkedIn  X/Twitter Facebook Instagram Discord
         Medium    Substack  Reddit   HeyGen    ...
```

---

## Agent Architecture

### 1. HQ Coordinator
- **Role**: Orchestrates all other agents
- **Script**: `daily-pipeline.sh`, `weekly-pipeline.sh`, `monthly-pipeline.sh`
- **Decides**: What to run, in what order, with what priority
- **Memory**: `memory/hq/`

### 2. Newsroom Agent
- **Role**: Processes AI/tool news into content
- **Script**: `newsroom-agent.sh`
- **Input**: `data/source-links/`
- **Output**: `data/ai-news/`, channel variants in `data/discord/`, `data/linkedin/`, etc.
- **LLM**: qwen3:8b

### 3. Product Update Agent
- **Role**: Processes product changes into content
- **Script**: `product-update-agent.sh`
- **Input**: `data/source-notes/`
- **Output**: `data/product-updates/`, channel variants
- **LLM**: qwen3:8b

### 4. Content Agent
- **Role**: Produces all content types from processed material
- **Script**: `content-agent.sh`
- **Produces**: Website posts, social variants, newsletters, briefs, articles
- **LLM**: qwen3:8b

### 5. Approval Policy Agent
- **Role**: Scores and routes content through 4-level approval
- **Script**: `approval-engine.sh`
- **Config**: `policies/approval-rules.json`
- **Output**: `approvals/approved/`, `approvals/blocked/`, `approvals/review/`

### 6. Distribution Agent
- **Role**: Routes approved content to platforms
- **Script**: `distribution-engine.sh`, `socialflow-publisher.sh`
- **Targets**: SocialFlow API, file queues, email exports

### 7. Reporting Agent
- **Role**: Generates pipeline reports
- **Script**: `generate-report.sh`, `reporting-engine-v2.sh`
- **Output**: `reports/daily/`, `reports/weekly/`, `reports/monthly/`

---

## Data Flow

```
Source Note → Intake → Product Agent → Content Agent → Approval → Distribution → Posted
Source Link → Intake → Newsroom Agent → Content Agent → Approval → Distribution → Posted
```

Each step creates auditable files with timestamps and metadata.

---

## LLM Routing

| Task Type | Model | Why |
|-----------|-------|-----|
| Strategy, writing, summaries, planning | `qwen3:8b` | Best at creative and analytical text |
| Scripts, automation, code generation | `qwen2.5-coder:7b` | Optimized for code tasks |

The `model-router.sh` script selects the appropriate model based on task type.

---

## Security Model

1. **Workspace Guard**: All operations confined to project folder
2. **Credential Encryption**: Fernet (AES) encryption for all stored credentials
3. **Session Isolation**: Browser sessions per-platform, stored locally
4. **Rate Limiting**: Configurable per-platform daily caps
5. **Approval Gate**: No content reaches platforms without passing approval
6. **Audit Logging**: Every action logged with timestamp and evidence
7. **No Cloud Dependencies**: Core pipeline runs 100% locally
