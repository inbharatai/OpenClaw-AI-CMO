# Archived Approval Artifacts

These items were generated during testing BEFORE the approval-engine grep bug was fixed.

## The Bug
The approval-engine.sh used a grep pattern that matched the word "safe" inside 
BOTH safe=true AND safe=false LLM responses, causing content scored as safe to 
be incorrectly blocked.

## What happened
- 28 items from 2026-03-23: blocked by the bug (false positives)
- 8 items from 2026-03-25: empty test artifacts with no block reason
- 2 review items from 2026-03-23: pre-fix test data

## Fix applied
- Bug was fixed on 2026-03-25 in approval-engine.sh
- These files were archived on 2026-03-26 during honest audit cleanup
- They are preserved here for transparency, not deleted

## Current clean state
Only items from post-fix runs with real block reasons remain in the active 
blocked/approved/review folders.
