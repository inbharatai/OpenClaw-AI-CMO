---
name: git-clone
description: Clone a git repository into the workspace. When user asks to clone a repo, output the exact shell command wrapped in a code block so the system can execute it.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Git Clone Skill

When the user asks to clone a git repository:

1. Extract the repo URL
2. Determine the clone destination: /Volumes/Expansion/CMO-10million/OpenClawData/repos/
3. Output the exact command:

```bash
cd /Volumes/Expansion/CMO-10million/OpenClawData/repos && git clone <URL>
```

4. After cloning, read the README.md and summarize the repo.

IMPORTANT: You must output the command inside a ```bash code block so the runtime can execute it.
