#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# format-selector.sh — OpenClaw Video Format Selector
#
# Reads the video-format-library.json and selects the best matching format
# for the video generation pipeline based on platform, use-case, or direct ID.
#
# Usage:
#   ./format-selector.sh --platform linkedin --use-case "thought leadership"
#   ./format-selector.sh --platform x --random
#   ./format-selector.sh --format talking-presenter-product-ui
#   ./format-selector.sh --list
#   ./format-selector.sh --list --platform linkedin
#
# Environment:
#   OPENCLAW_ROOT         — override project root
#   FORMAT_LIBRARY_PATH   — override path to video-format-library.json
#   FORMAT_SELECTOR_SEED  — override random seed (for reproducible testing)
#
# Dependencies: jq (>= 1.6)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_ROOT="${OPENCLAW_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
FORMAT_LIBRARY_PATH="${FORMAT_LIBRARY_PATH:-${OPENCLAW_ROOT}/OpenClawData/strategy/video-format-library.json}"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Logging ──────────────────────────────────────────────────────────────────
log()     { echo -e "${BLUE}[format-selector]${NC} $1" >&2; }
warn()    { echo -e "${YELLOW}[format-selector] WARN:${NC} $1" >&2; }
error()   { echo -e "${RED}[format-selector] ERROR:${NC} $1" >&2; }
success() { echo -e "${GREEN}[format-selector]${NC} $1" >&2; }

# ── Dependency check ────────────────────────────────────────────────────────
check_dependencies() {
    if ! command -v jq &>/dev/null; then
        error "jq is required but not installed."
        echo "  Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
        exit 1
    fi

    local jq_version
    jq_version="$(jq --version 2>/dev/null | sed 's/jq-//')"
    log "jq version: ${jq_version}"
}

# ── Validate library file ───────────────────────────────────────────────────
validate_library() {
    if [[ ! -f "$FORMAT_LIBRARY_PATH" ]]; then
        error "Format library not found at: ${FORMAT_LIBRARY_PATH}"
        error "Set FORMAT_LIBRARY_PATH or ensure the file exists."
        exit 1
    fi

    if ! jq empty "$FORMAT_LIBRARY_PATH" 2>/dev/null; then
        error "Format library is not valid JSON: ${FORMAT_LIBRARY_PATH}"
        exit 1
    fi

    local count
    count="$(jq '.formats | length' "$FORMAT_LIBRARY_PATH")"
    if [[ "$count" -eq 0 ]]; then
        error "Format library contains no formats."
        exit 1
    fi

    log "Loaded ${count} formats from library."
}

# ── List formats ─────────────────────────────────────────────────────────────
list_formats() {
    local platform_filter="${1:-}"

    local filter_expr='.formats'
    if [[ -n "$platform_filter" ]]; then
        filter_expr=".formats | map(select(.platforms | index(\"${platform_filter}\")))"
        log "Filtering formats for platform: ${platform_filter}"
    fi

    local count
    count="$(jq "${filter_expr} | length" "$FORMAT_LIBRARY_PATH")"

    if [[ "$count" -eq 0 ]]; then
        warn "No formats found for platform: ${platform_filter}"
        exit 0
    fi

    echo -e "${BOLD}${CYAN}Available Video Formats (${count}):${NC}" >&2
    echo "" >&2

    jq -r "${filter_expr}[] | \"  \(.id)  —  \(.name)  [\(.ideal_duration_seconds.min)-\(.ideal_duration_seconds.max)s]  heygen:\(.heygen_usage)  platforms:\(.platforms | join(\",\"))\"" "$FORMAT_LIBRARY_PATH" >&2

    echo "" >&2

    # Also output machine-readable JSON to stdout
    jq "${filter_expr} | map({id, name, platforms, heygen_usage, ideal_duration_seconds})" "$FORMAT_LIBRARY_PATH"
}

# ── Select by format ID ─────────────────────────────────────────────────────
select_by_id() {
    local format_id="$1"

    local result
    result="$(jq --arg id "$format_id" '.formats[] | select(.id == $id)' "$FORMAT_LIBRARY_PATH")"

    if [[ -z "$result" ]]; then
        error "Format not found: ${format_id}"
        echo "" >&2
        echo "Available format IDs:" >&2
        jq -r '.formats[].id' "$FORMAT_LIBRARY_PATH" | sed 's/^/  /' >&2
        exit 1
    fi

    success "Selected format: ${format_id}"
    echo "$result"
}

# ── Score-based matching ─────────────────────────────────────────────────────
# Scores each format against the given platform and use-case keywords.
# Returns the best match or, with --random, a random pick from top scorers.
select_by_match() {
    local platform="${1:-}"
    local use_case="${2:-}"
    local random_pick="${3:-false}"

    if [[ -z "$platform" && -z "$use_case" ]]; then
        error "At least one of --platform or --use-case is required for matching."
        exit 1
    fi

    # Build a jq filter that scores each format.
    # Platform match = 10 points. Use-case keyword match = 5 points per keyword hit.
    local use_case_lower
    use_case_lower="$(echo "$use_case" | tr '[:upper:]' '[:lower:]')"

    # Split use-case into searchable keywords (remove common stop words)
    local keywords_json="[]"
    if [[ -n "$use_case_lower" ]]; then
        keywords_json="$(echo "$use_case_lower" | tr ' ' '\n' | \
            grep -vE '^(a|an|the|is|are|was|were|for|and|or|but|in|on|at|to|of|with|by|as|it|its|this|that)$' | \
            jq -R . | jq -s .)"
    fi

    local jq_filter
    jq_filter="$(cat <<'JQEOF'
        .formats | map(
            . as $fmt |
            {
                format: .,
                score: (
                    # Platform score: 10 points if platform matches
                    (if $platform != "" then
                        (if (.platforms | index($platform)) then 10 else 0 end)
                    else 0 end)
                    +
                    # Use-case keyword scoring: 5 points per keyword found
                    # in ideal_use_case (case-insensitive)
                    ([$keywords[] | . as $kw |
                        if ($fmt.ideal_use_case | ascii_downcase | test($kw)) then 5
                        elif ($fmt.name | ascii_downcase | test($kw)) then 3
                        elif ($fmt.variety_notes | ascii_downcase | test($kw)) then 1
                        else 0 end
                    ] | add // 0)
                )
            }
        )
        | sort_by(-.score)
        | if .[0].score == 0 then
            empty
          elif $random then
            # Collect all formats tied for the top score
            (.[0].score) as $top |
            [.[] | select(.score == $top)] |
            .[$seed % length].format
          else
            .[0].format
          end
JQEOF
    )"

    local seed="${FORMAT_SELECTOR_SEED:-$RANDOM}"

    local result
    result="$(jq \
        --arg platform "$platform" \
        --argjson keywords "$keywords_json" \
        --argjson random "$random_pick" \
        --argjson seed "$seed" \
        "$jq_filter" "$FORMAT_LIBRARY_PATH")"

    if [[ -z "$result" || "$result" == "null" ]]; then
        # Fallback: if no keyword match, return all platform-matching formats
        if [[ -n "$platform" ]]; then
            warn "No strong match found. Falling back to platform filter."

            local fallback_filter
            if [[ "$random_pick" == "true" ]]; then
                fallback_filter=".formats | map(select(.platforms | index(\"${platform}\"))) | if length == 0 then empty else .[$seed % length] end"
            else
                fallback_filter=".formats | map(select(.platforms | index(\"${platform}\"))) | first // empty"
            fi

            result="$(jq --argjson seed "$seed" "$fallback_filter" "$FORMAT_LIBRARY_PATH")"
        fi

        if [[ -z "$result" || "$result" == "null" ]]; then
            error "No matching format found for platform='${platform}' use-case='${use_case}'."
            echo "" >&2
            echo "Try --list to see available formats, or use --format to select by ID." >&2
            exit 1
        fi
    fi

    local selected_id
    selected_id="$(echo "$result" | jq -r '.id')"
    local selected_name
    selected_name="$(echo "$result" | jq -r '.name')"
    local heygen
    heygen="$(echo "$result" | jq -r '.heygen_usage')"

    if [[ "$random_pick" == "true" ]]; then
        success "Randomly selected: ${selected_id} — ${selected_name} [heygen: ${heygen}]"
    else
        success "Best match: ${selected_id} — ${selected_name} [heygen: ${heygen}]"
    fi

    echo "$result"
}

# ── Usage / Help ─────────────────────────────────────────────────────────────
usage() {
    cat >&2 <<USAGE
${BOLD}format-selector.sh${NC} — Select a video format from the OpenClaw format library.

${BOLD}USAGE:${NC}
  $(basename "$0") --platform <platform> [--use-case <text>] [--random]
  $(basename "$0") --format <format-id>
  $(basename "$0") --list [--platform <platform>]
  $(basename "$0") --help

${BOLD}OPTIONS:${NC}
  --platform <name>   Filter/match by platform (youtube-shorts, linkedin,
                       instagram-reels, x)
  --use-case <text>   Match by use-case keywords (e.g., "product demo",
                       "thought leadership", "community update")
  --format <id>       Select a specific format by its ID
  --random            Pick a random format from the top matches (for variety)
  --list              List all available formats (combine with --platform to filter)
  --help              Show this help message

${BOLD}ENVIRONMENT:${NC}
  OPENCLAW_ROOT         Override project root directory
  FORMAT_LIBRARY_PATH   Override path to video-format-library.json
  FORMAT_SELECTOR_SEED  Override random seed (for reproducible testing)

${BOLD}EXAMPLES:${NC}
  # Best format for a LinkedIn product demo
  $(basename "$0") --platform linkedin --use-case "product demo walkthrough"

  # Random format for YouTube Shorts
  $(basename "$0") --platform youtube-shorts --random

  # Specific format by ID
  $(basename "$0") --format discord-insider-update

  # List all formats for X (Twitter)
  $(basename "$0") --list --platform x

${BOLD}OUTPUT:${NC}
  Outputs the selected format configuration as JSON to stdout.
  Human-readable status messages go to stderr.
  Pipe stdout to the video generation pipeline.

USAGE
    exit 0
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    local platform=""
    local use_case=""
    local format_id=""
    local random_pick=false
    local do_list=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --platform)
                [[ $# -lt 2 ]] && { error "--platform requires a value"; exit 1; }
                platform="$2"
                shift 2
                ;;
            --use-case)
                [[ $# -lt 2 ]] && { error "--use-case requires a value"; exit 1; }
                use_case="$2"
                shift 2
                ;;
            --format)
                [[ $# -lt 2 ]] && { error "--format requires a value"; exit 1; }
                format_id="$2"
                shift 2
                ;;
            --random)
                random_pick=true
                shift
                ;;
            --list)
                do_list=true
                shift
                ;;
            --help|-h)
                usage
                ;;
            *)
                error "Unknown option: $1"
                echo "  Run with --help for usage information." >&2
                exit 1
                ;;
        esac
    done

    # Dependency and library validation
    check_dependencies
    validate_library

    # Dispatch
    if [[ "$do_list" == true ]]; then
        list_formats "$platform"
    elif [[ -n "$format_id" ]]; then
        select_by_id "$format_id"
    elif [[ -n "$platform" || -n "$use_case" ]]; then
        select_by_match "$platform" "$use_case" "$random_pick"
    else
        error "No action specified. Use --list, --format, --platform, or --use-case."
        echo "" >&2
        echo "  Run with --help for usage information." >&2
        exit 1
    fi
}

main "$@"
