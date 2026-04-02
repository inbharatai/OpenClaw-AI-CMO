# Control Architecture Plan
## Browser Visibility + WhatsApp Control + Scheduling
### Date: 2026-03-25

---

## 1. EXECUTIVE SUMMARY

**Use SocialFlow as your browser dashboard now. Restore OpenClaw web app later for WhatsApp control.**

SocialFlow already exists with a 2172-line browser UI, FastAPI backend, SQLite database, OpenClaw bridge API, and a Python venv with all dependencies installed. It can show pipeline activity today. The old ProClaw web app is missing from the drive but may exist on GitHub — that's a separate recovery task that should not block pipeline proof.

**Target architecture:**
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   YOU (Browser)  │────▶│   SocialFlow     │────▶│  Shell Pipeline │
│   YOU (WhatsApp) │────▶│   (Dashboard)     │     │  (Execution)    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                              │      ▲
                              │      │
                         ┌────▼──────┴────┐
                         │   OpenClaw      │
                         │   (Scheduler +  │
                         │    WhatsApp)    │
                         └─────────────────┘
                              │
                              ▼
                         ┌─────────────────┐
                         │   Ollama         │
                         │   (Local LLMs)   │
                         └─────────────────┘
```

---

## 2. CURRENT REALITY ASSESSMENT

### What Already Exists for Scheduling
| Component | Status |
|---|---|
| `daily-pipeline.sh` orchestrator | Working — proven end-to-end |
| `weekly-pipeline.sh` orchestrator | Exists, not yet tested |
| `monthly-pipeline.sh` orchestrator | Exists, not yet tested |
| SocialFlow `APScheduler` | Built into main.py, supports timed posting |
| macOS cron/launchd | Available, not yet configured |
| OpenClaw agent config | `~/.openclaw/agents/main/` exists with model configs |

### What Already Exists for Browser Visibility
| Component | Status |
|---|---|
| SocialFlow frontend (index.html) | 2172 lines, full single-page app |
| SocialFlow FastAPI backend | 30+ API endpoints, working |
| SocialFlow SQLite database | 3 tables (accounts, posts, templates) |
| OpenClaw bridge API | 4 endpoints (publish, batch, status, history) |
| SocialFlow venv | Installed with all dependencies |

### What Already Exists for Bridge/Control
| Component | Status |
|---|---|
| `POST /api/openclaw/publish` | Pushes approved content to platform |
| `POST /api/openclaw/batch` | Batch publish |
| `GET /api/openclaw/status` | Check platform connection status |
| `GET /api/openclaw/history` | Recent publish history |
| `socialflow-publisher.sh` | Shell script that calls bridge API |

### What Is Missing
| Missing | Impact | Effort to Add |
|---|---|---|
| Pipeline status API endpoints in SocialFlow | Can't see queue/approval state in browser | Small — read queue folders via new API endpoints |
| Pipeline trigger endpoint | Can't trigger daily pipeline from browser | Small — one new endpoint calling daily-pipeline.sh |
| Report viewer endpoint | Can't read reports in browser | Small — serve report markdown files |
| Log viewer endpoint | Can't see logs in browser | Small — tail log files via API |
| Dashboard page for pipeline ops | No pipeline-specific UI | Medium — add a dashboard tab to frontend |
| OpenClaw web app (ProClaw) | No WhatsApp control, no native scheduling UI | Large — need to recover/reinstall |
| WhatsApp integration | No mobile control | Requires OpenClaw web app running |

---

## 3. BEST ARCHITECTURE DECISION

### Use SocialFlow as main dashboard NOW — Yes

SocialFlow is the right choice because:
- It's already built and installed
- It already has the OpenClaw bridge API
- It already has browser automation for social platforms
- It already has a scheduler (APScheduler)
- Adding 5-6 new API endpoints for pipeline visibility is a small task

### OpenClaw = scheduler/orchestrator ONLY until web app is restored — Yes

The OpenClaw agent config exists (`~/.openclaw/agents/main/`). The models are configured. But without the web app runtime, OpenClaw can only function as a config/agent definition layer, not as a live scheduler. Real scheduling should use cron (proven, simple) until the web app is back.

### Final Relationship

| Component | Role | Phase |
|---|---|---|
| **Shell pipeline** | Execution (content production, approval, distribution) | Now |
| **Cron** | Scheduling (daily/weekly/monthly triggers) | Now |
| **SocialFlow** | Browser dashboard + social posting + bridge API | Now |
| **OpenClaw web app** | Scheduler UI + WhatsApp control + agent orchestration | After restore |
| **Ollama** | LLM inference | Now |

---

## 4. STAGED IMPLEMENTATION PLAN

### Stage A: Immediate Browser Visibility (NOW)
**Purpose:** Get a working browser dashboard showing pipeline state today.

**Components:**
1. Start SocialFlow backend (already installed)
2. Add 5 new API endpoints to SocialFlow for pipeline visibility:
   - `GET /api/pipeline/status` — queue counts, approval counts, last run time
   - `GET /api/pipeline/queues` — list files in each queue by channel
   - `GET /api/pipeline/approvals` — list pending/approved/blocked/review items
   - `GET /api/pipeline/reports` — list and serve report files
   - `GET /api/pipeline/logs` — tail recent log files
   - `POST /api/pipeline/run` — trigger daily-pipeline.sh manually
3. Add a pipeline dashboard section to the frontend

**Dependencies:** SocialFlow venv working, pipeline folders accessible
**What NOT to touch:** The shell pipeline scripts, SKILL.md files, approval engine

### Stage B: Pipeline Proof + Dashboard Evidence (THIS WEEK)
**Purpose:** Run 3-day unattended proof while watching via dashboard.

**Components:**
1. Set up cron for daily-pipeline.sh at 8:07 AM
2. Drop 1-2 source notes per day
3. Monitor via SocialFlow dashboard in browser
4. Verify daily reports are generated automatically
5. Screenshot/save evidence from dashboard

**Dependencies:** Stage A complete, cron configured
**What NOT to touch:** No refactoring during proof period

### Stage C: Restore OpenClaw Web App (AFTER PROOF)
**Purpose:** Get the full OpenClaw runtime back for scheduling UI + WhatsApp.

**Components:**
1. Check GitHub for the ProClaw repo
2. Clone or reinstall
3. Configure Ollama connection (config already exists at `~/.openclaw/`)
4. Verify it launches on port 3002 or 18789
5. Connect its scheduling to daily-pipeline.sh

**Dependencies:** Phase 0 proof complete, repo found
**What NOT to touch:** SocialFlow continues working independently

### Stage D: Wire WhatsApp Control (AFTER RESTORE)
**Purpose:** Control pipeline from WhatsApp.

**Components:**
1. Enable WhatsApp channel in OpenClaw
2. Define command set (see Section 6)
3. Connect commands to pipeline actions via bridge API
4. Test each command
5. Set up confirmation flow for dangerous actions

**Dependencies:** Stage C complete, WhatsApp Business API or Twilio configured

### Stage E: Unify UX (LATER)
**Purpose:** Clean, single-pane experience.

**Components:**
1. SocialFlow dashboard embedded in or linked from OpenClaw UI
2. OpenClaw scheduling visible in SocialFlow
3. Unified notification system (WhatsApp + browser)
4. Single status view across both systems

**Dependencies:** Stages A-D stable for 2+ weeks

---

## 5. MINIMUM DASHBOARD REQUIREMENTS

### Must-Have Now (Stage A)
| Feature | API Endpoint | Display |
|---|---|---|
| Queue state by channel | `GET /api/pipeline/queues` | Table: channel, pending count, approved count |
| Approval status | `GET /api/pipeline/approvals` | Lists: pending, approved, review, blocked with filenames |
| Today's pipeline run status | `GET /api/pipeline/status` | Last run time, stage results, total counts |
| Recent logs (last 50 lines) | `GET /api/pipeline/logs?file=daily-pipeline` | Scrollable log viewer |
| Manual pipeline trigger | `POST /api/pipeline/run` | "Run Pipeline Now" button |
| Daily report view | `GET /api/pipeline/reports` | Rendered markdown of latest daily report |

### Should-Have Later (Stage B-C)
| Feature | Notes |
|---|---|
| Error highlighting in logs | Color-code BLOCKED, FAILED, WARNING lines |
| Content preview before approval | Click a review-queue item to see its content |
| Manual approve/block buttons | Move items between approval states from browser |
| Run history chart | Simple timeline of daily runs and their counts |
| Platform connection status | Which social accounts are connected |

### Nice-to-Have (Stage E)
| Feature | Notes |
|---|---|
| Real-time log streaming | WebSocket-based live log tail |
| Content calendar view | Visual calendar of scheduled/posted content |
| Analytics integration | Platform engagement metrics |
| Multi-user access | Share dashboard with team members |

---

## 6. WHATSAPP CONTROL DESIGN (For Stage D)

### Read-Only Commands (No confirmation needed)
| Command | Action | Response |
|---|---|---|
| `status` | Show pipeline status | Last run time + queue counts |
| `report` | Show today's report summary | Key numbers from daily report |
| `queues` | Show queue state | Per-channel pending/approved counts |
| `errors` | Show recent errors | Last 5 error lines from logs |
| `next` | What's scheduled next | Next cron run time |

### Action Commands (Require confirmation)
| Command | Action | Confirmation |
|---|---|---|
| `run now` | Trigger daily pipeline | "Run daily pipeline now? Reply YES to confirm" |
| `approve <id>` | Approve a review-queue item | "Approve [filename]? Reply YES to confirm" |
| `block <id>` | Block an item | "Block [filename]? Reply YES to confirm" |
| `pause` | Pause scheduled runs | "Pause all scheduled pipelines? Reply YES" |
| `resume` | Resume scheduled runs | "Resume scheduled pipelines? Reply YES" |

### Prohibited Commands (Never via WhatsApp)
| Action | Why |
|---|---|
| Delete files | Too dangerous for chat interface |
| Change credentials | Security risk |
| Modify scripts | Must be done in code, not chat |
| Mass publish | Requires browser review first |
| Access personal accounts | Only marketing accounts allowed |

### Safety Rules
- All action commands require explicit YES confirmation
- Rate limit: max 10 commands per hour
- Failed commands logged to `OpenClawData/logs/whatsapp-commands.log`
- No chained commands (each must be confirmed individually)
- "emergency stop" command immediately pauses all automation

---

## 7. REPO RECOVERY / REINSTALL STRATEGY

### Step 1: Check GitHub
```bash
# If gh CLI is available:
gh repo list --limit 100 | grep -i "proclaw\|openclaw"

# Or check browser:
# https://github.com/<your-username>?tab=repositories
# Search for "proclaw" or "openclaw"
```

### Step 2: Check Other Locations
```bash
# Check backup drives
find /Volumes -maxdepth 4 -name "proclaw*" -o -name "openclaw*" 2>/dev/null

# Check Downloads
find ~/Downloads -maxdepth 3 -name "proclaw*" -o -name "openclaw*" 2>/dev/null

# Check if it was in a zip/archive
find /Volumes/Expansion -name "*.zip" -o -name "*.tar.gz" 2>/dev/null | head -20
```

### Step 3: Decision Matrix
| Scenario | Action |
|---|---|
| Found on GitHub | Clone to `/Volumes/Expansion/Tools/proclaw.ai/`, run `npm install`, configure |
| Found in backup/zip | Extract, verify, install dependencies |
| Not found anywhere | SocialFlow is the dashboard. Build minimal WhatsApp bridge separately when needed |

### Is Restoration Necessary Now?
**No.** SocialFlow covers browser visibility. Cron covers scheduling. The shell pipeline covers execution. OpenClaw restoration is for WhatsApp control and native scheduling UI — both can wait until after proof.

---

## 8. EXACT RECOMMENDED ACTION ORDER

```
 1. Start SocialFlow backend (verify it runs on localhost:8000)
 2. Add 6 pipeline API endpoints to SocialFlow backend
 3. Add pipeline dashboard section to SocialFlow frontend
 4. Open browser, verify you can see queue state + approvals + logs
 5. Set up cron for daily-pipeline.sh at 8:07 AM
 6. Drop 1-2 source notes per day for 3 days
 7. Monitor via browser dashboard each day
 8. After 3 successful days: Phase 0 is PROVEN
 9. Search GitHub/backups for ProClaw repo
10. If found: clone and restore OpenClaw web app
11. If not found: continue with SocialFlow as primary dashboard
12. Wire WhatsApp control through OpenClaw (if restored) or separate bridge
13. Unify dashboard UX
```

---

## 9. FINAL RECOMMENDATION

**Start SocialFlow now.** Add 6 API endpoints for pipeline visibility. That gives you a working browser dashboard today without rebuilding anything. Set up cron in parallel. Run the 3-day proof while watching from the browser.

The OpenClaw web app restoration is a separate track. Search for it on GitHub. If it's there, restore it after proof. If it's not, SocialFlow becomes the permanent dashboard and you build a lightweight WhatsApp bridge later.

**Do not wait for the perfect setup. The pipeline is proven. Get visibility now, schedule now, restore later.**
