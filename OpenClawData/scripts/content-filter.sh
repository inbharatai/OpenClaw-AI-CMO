#!/usr/bin/env bash
# Simple content‑filter for drafts in memory/approval/
# Scans markdown files for disallowed words/phrases and reports any matches.
# Add or remove patterns in the BAD_WORDS array as needed.

BAD_WORDS=("badword1" "badword2" "hate" "violence" "illegal")

for file in memory/approval/*.md; do
  if [[ -f "$file" ]]; then
    for bad in "${BAD_WORDS[@]}"; do
      if grep -iq "${bad}" "$file"; then
        echo "⚠️  Detected prohibited term '${bad}' in $file" >> memory/approval/content‑filter‑log.md
      fi
    done
  fi
done

echo "Content‑filter run complete. Check memory/approval/content‑filter‑log.md for any warnings."