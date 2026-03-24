#!/bin/bash
# ============================================================
# date-context.sh — Central Date Helper (Issue C fix)
# Source this to get DATE_CONTEXT for all prompt builders
# ============================================================

export CURRENT_DATE=$(date '+%Y-%m-%d')
export CURRENT_DAY=$(date '+%A')
export CURRENT_MONTH=$(date '+%B')
export CURRENT_YEAR=$(date '+%Y')
export CURRENT_TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S%z')
export CURRENT_TIMEZONE=$(date '+%Z')
export DATE_TAG=$(date '+%Y-%m-%d')

# Inject this into every LLM prompt that generates date-sensitive content
export DATE_CONTEXT="Today's date is: $CURRENT_DATE
Current day: $CURRENT_DAY
Current month: $CURRENT_MONTH $CURRENT_YEAR
Current year: $CURRENT_YEAR
Current timestamp: $CURRENT_TIMESTAMP
Timezone: $CURRENT_TIMEZONE
IMPORTANT: Use the date $CURRENT_DATE for all date references. Never use 2023 or any other year unless explicitly asked."
