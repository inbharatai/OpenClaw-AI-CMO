---
name: source-sync
description: Crawls official websites and GitHub repos to update product knowledge from approved sources
version: 1.0.0
category: research
triggers:
  - sync sources
  - update product knowledge
  - refresh brand memory
inputs:
  - product (optional): Specific product to sync, or "all" for everything
outputs:
  - updated product truth files
  - updated brand knowledge base
  - sync report
honest_classification: research-tool
---

# Source Sync

## Purpose
OpenClaw must generate content grounded in real product information — not improvisation.
This skill crawls approved source URLs and updates product knowledge files.

## Approved Source Classes
Only these sources are trusted:
1. **Official websites** listed in `product-registry.json` → `website` field
2. **Official GitHub repos** listed in `product-registry.json` → `repo` field
3. **README files** in official repos
4. **Approved markdown docs** in `OpenClawData/strategy/product-truth/`
5. **Brand knowledge base** at `OpenClawData/strategy/brand-knowledge-base.json`

## Sync Process

### Step 1: Load Source URLs
Read `OpenClawData/strategy/product-registry.json` to get all product website URLs and GitHub repo URLs.

### Step 2: Fetch Each Source
For each product with a website_url:
- Fetch the homepage
- Extract: tagline, key features, product description, pricing info, CTA text
- Note what's actually live vs placeholder/coming-soon

For each product with a github_url:
- Fetch the README.md
- Extract: project description, features list, installation/usage info, tech stack
- Note last commit date and activity level

### Step 3: Compare with Product Truth
For each product, compare fetched data against `strategy/product-truth/{product}.md`:
- Are the descriptions still accurate?
- Are any new features listed that aren't in the truth file?
- Are any claims in the truth file that aren't supported by the source?
- Has the product status changed (development → live, or vice versa)?

### Step 4: Generate Sync Report
Output a structured report:
```
SOURCE SYNC REPORT — {date}
───────────────────────────

Product: {name}
  Website: {url} — {status: live | down | placeholder | updated}
  Repo: {url} — {status: active | stale | private}
  Changes detected:
    - {description of change}
  Recommended updates:
    - Update product-truth/{product}.md field X
    - Add new feature Y to safe claims
  Warnings:
    - Claim Z in truth file not supported by current source

... (repeat per product)
```

### Step 5: Update Files (with review)
- Update `strategy/product-truth/{product}.md` with new verified information
- Update `strategy/brand-knowledge-base.json` product entries
- Mark `last_verified` date in product-registry.json

## Safety Rules
- NEVER add unverified claims to Safe Claims
- NEVER remove Restricted Claims without founder approval
- NEVER change product status without verifying the actual website
- If a website is down, note it but don't assume the product is dead
- If a GitHub repo is archived, flag it but don't remove the product

## Frequency
- Full sync: Weekly (or on demand)
- Quick check (just status): Daily
- Deep crawl (including sub-pages): Monthly
