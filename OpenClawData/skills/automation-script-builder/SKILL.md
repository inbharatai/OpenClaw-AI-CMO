> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.

---
name: automation-script-builder
description: Build automation scripts for repetitive tasks like file processing, data transformation, scheduling, API calls, and workflow automation. Use when the user needs a script to automate something, process files in batch, schedule tasks, or connect tools. Triggers on "automate this", "write a script for", "batch process", "schedule this", "connect these tools", or any automation request.
---

# Automation Script Builder

Build practical automation scripts for repetitive tasks. Keep scripts simple, readable, and reliable.

## Default Model

`qwen2.5-coder:7b` — purpose-built for scripting, file handling, and automation logic.

## Storage

- Scripts → `MarketingToolData/scripts/`
- Logs → `OpenClawData/logs/`

## Supported Script Types

| Type | Language | Use Case |
|---|---|---|
| File processing | Python / Bash | Rename, move, convert, clean files |
| Data transformation | Python | CSV/JSON processing, data cleanup |
| API integration | Python | Connect to external services |
| Scheduling | Bash + cron | Run tasks on a schedule |
| Text processing | Python / Bash | Search, replace, extract, format |
| Report generation | Python | Compile data into reports |

## Script Template

Every script must include:

```python
#!/usr/bin/env python3
"""
Script: <name>
Purpose: <one line description>
Created: YYYY-MM-DD
Usage: python3 <script-name>.py [arguments]

Dependencies: <list any pip packages needed>
"""

import sys
import os
from datetime import datetime

# Configuration
WORKSPACE_ROOT = "/Volumes/Expansion/CMO-10million"

def main():
    """Main execution logic."""
    # 1. Validate inputs
    # 2. Execute task
    # 3. Report results
    pass

if __name__ == "__main__":
    main()
```

## Script Rules

1. **Workspace guard applies** — scripts must only operate within the approved workspace
2. **Always include error handling** — try/except with clear error messages
3. **Log important actions** — print what the script is doing as it runs
4. **Test before deploying** — run with a small test case first
5. **No destructive defaults** — scripts should default to safe mode (preview/dry-run)
6. **Include a --dry-run flag** for any script that creates, moves, or deletes files
7. **Document dependencies** — list any pip packages in the script header

## Saving Scripts

```
MarketingToolData/scripts/auto-<YYYY-MM-DD>-<purpose>.py
```

Or for Bash:
```
MarketingToolData/scripts/auto-<YYYY-MM-DD>-<purpose>.sh
```

## After Creating a Script

1. Test it with a small input
2. Show the output
3. Confirm it works before declaring done
4. Save to the scripts folder
5. Add to prompt library if it's reusable
