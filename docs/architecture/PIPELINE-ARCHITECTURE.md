# Content Pipeline Architecture

## End-to-End Pipeline Stages

```
STAGE 1: SOURCE INTAKE
    |
STAGE 2: NEWSROOM PROCESSING
    |
STAGE 3: PRODUCT UPDATE PROCESSING
    |
STAGE 4: CONTENT PRODUCTION
    |
STAGE 5: APPROVAL ENGINE
    |
STAGE 6: DISTRIBUTION
    |
STAGE 7: REPORTING
```

---

## Stage 1: Source Intake

**Script**: `intake-processor.sh`

**Inputs**:
- `data/source-notes/*.md` — Manual product/work notes
- `data/source-links/*.md` — AI news URLs and summaries
- `data/screenshots/` — Visual evidence

**Process**:
1. Scan for unprocessed files (no `.meta.json`)
2. Classify each: product-update, ai-news, founder-log, etc.
3. Tag with metadata (timestamp, type, source)
4. Write `.meta.json` sidecar file
5. Log to `logs/intake-processor.log`

**Output**: Tagged files ready for agent processing

---

## Stage 2: Newsroom Processing

**Script**: `newsroom-agent.sh`

**Inputs**: Tagged files in `data/source-links/`

**Process**:
1. Read unprocessed news items
2. Send to qwen3:8b for summarization
3. Generate channel variants (website, discord, linkedin, x)
4. Save formatted outputs to `data/ai-news/` and channel folders

**Output**: News summaries + multi-channel variants

---

## Stage 3: Product Update Processing

**Script**: `product-update-agent.sh`

**Inputs**: Tagged files in `data/source-notes/`

**Process**:
1. Read unprocessed product notes
2. Send to qwen3:8b for professional formatting
3. Generate channel variants (website, discord, linkedin, x)
4. Save to `data/product-updates/` and channel folders

**Output**: Product updates + multi-channel variants

---

## Stage 4: Content Production

**Script**: `content-agent.sh`

**Inputs**: All processed content from Stages 2-3

**Process**:
1. Collect all new content from agent outputs
2. For each item, generate platform-specific versions
3. Apply brand voice guidelines
4. Generate metadata (word count, channel, type)
5. Save to appropriate channel folders

**Content Types Produced**:
- Website updates / insights
- LinkedIn posts
- X/Twitter posts and threads
- Facebook posts
- Instagram captions
- Discord announcements
- Reddit post drafts
- Newsletter snippets
- Medium/Substack article drafts
- Video briefs (HeyGen)
- Image briefs

---

## Stage 5: Approval Engine

**Script**: `approval-engine.sh`

**Config**: `policies/approval-rules.json`

**Process**:
1. Scan all new content files
2. For each file, calculate risk scores across 6 dimensions
3. Compute weighted average
4. Route based on level:
   - L1 (auto): Move to `approvals/approved/`
   - L2 (score-gated): If passes threshold → approved, else → review
   - L3 (review): Move to `approvals/review/`
   - L4 (block): Move to `approvals/blocked/`
5. Log all decisions

---

## Stage 6: Distribution

**Script**: `distribution-engine.sh` + `socialflow-publisher.sh`

**Inputs**: Files in `approvals/approved/`

**Process**:
1. Read approved files
2. Determine target platform from filename/metadata
3. Route to appropriate output:
   - **SocialFlow API** → Direct posting via browser automation
   - **Website queue** → `queues/website/`
   - **Email export** → `exports/email/ready-to-send/`
   - **Manual review** → `exports/posted/`
4. Archive posted content to `exports/posted/`
5. Log all distribution actions

---

## Stage 7: Reporting

**Script**: `generate-report.sh` / `reporting-engine-v2.sh`

**Process**:
1. Count files processed at each stage
2. Count approved vs blocked vs review
3. Count items distributed per channel
4. Generate markdown report
5. Save to `reports/daily/`

**Report Includes**:
- Pipeline run timestamp and duration
- Files processed per stage
- Approval breakdown (approved/blocked/review)
- Distribution summary per channel
- Errors and warnings
- Next actions

---

## Pipeline Schedules

### Daily Pipeline
```
06:00 — Intake scan
06:05 — Newsroom agent
06:15 — Product update agent
06:30 — Content production
07:00 — Approval engine
07:05 — Distribution
07:10 — Daily report
```

### Weekly Pipeline (Mondays)
```
08:00 — Weekly roundup generation
08:30 — Editorial calendar update
09:00 — Video brief generation
09:30 — Newsletter draft
10:00 — Weekly report
```

### Monthly Pipeline (1st of month)
```
09:00 — Content pillar review
09:30 — Campaign theme refresh
10:00 — SEO topic update
10:30 — Performance summary
11:00 — Next month plan
```
