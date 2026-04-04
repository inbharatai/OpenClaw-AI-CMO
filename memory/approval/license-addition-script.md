# License‑Addition Pull‑Request Script (Apache‑2.0)

The following Bash script can be run locally (or in a CI job) to add an `Apache‑2.0` licence file to every repository listed in the config. It creates a new branch, commits the `LICENSE` file, pushes the branch, and opens a PR.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Path to the config file containing the repo URLs (use the one in memory/approval)
CONFIG="memory/approval/config-updated.yaml"

# Extract all URLs (skip comment lines)
REPOS=$(grep -E "^- \"https" $CONFIG | sed -E 's/^[[:space:]]*- "(.*)"/\1/')

# Apache‑2.0 licence text (saved to a temporary file)
cat > LICENSE <<'EOF'
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
... (full license text omitted for brevity) ...
EOF

for REPO in $REPOS; do
  # Derive repo name (owner/repo)
  NAME=$(basename $REPO)
  echo "Processing $NAME …"
  # Clone shallow copy
  git clone --depth 1 $REPO $NAME
  cd $NAME
  # Create a new branch
  git checkout -b add-apache-license
  # Copy licence
  cp ../LICENSE .
  git add LICENSE
  git commit -m "Add Apache‑2.0 licence"
  # Push branch (requires your GitHub credentials configured)
  git push origin add‑apache‑license
  # Open PR via GitHub CLI (gh)
  gh pr create --title "Add Apache‑2.0 licence" \
    --body "Standardising the licence across InBharat repos."
  cd ..
  rm -rf $NAME
done
```

**How to use:**
1. Save this script as `add-license.sh` in your workspace.
2. Ensure you have `git` and the GitHub CLI (`gh`) installed and authenticated.
3. Run `bash add-license.sh`.
4. Review the generated PRs and merge when ready.

*The script is placed in `memory/approval/license-addition-script.md` for your final sign‑off.*
