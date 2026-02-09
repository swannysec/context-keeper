#!/usr/bin/env bash
# ConKeeper Memory Search Script
# Cross-platform search tool for memory files with privacy and category filtering.
# Usage: bash tools/memory-search.sh <query> [--global] [--sessions] [--category <name>]

set -euo pipefail

# ERR trap exits 0 so runtime failures degrade gracefully in hook contexts.
# Argument validation errors (below) still exit 1 for immediate feedback.
trap 'echo "[ConKeeper] memory-search.sh failed at line $LINENO" >&2; exit 0' ERR

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
QUERY=""
INCLUDE_GLOBAL=false
INCLUDE_SESSIONS=false
CATEGORY_FILTER=""

while [ $# -gt 0 ]; do
    case "$1" in
        --global)
            INCLUDE_GLOBAL=true
            shift
            ;;
        --sessions)
            INCLUDE_SESSIONS=true
            shift
            ;;
        --category)
            if [ $# -lt 2 ] || [ -z "$2" ]; then
                echo "Error: --category requires a non-empty value" >&2
                exit 1
            fi
            CATEGORY_FILTER="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
        *)
            if [ -z "$QUERY" ]; then
                QUERY="$1"
            else
                echo "Error: Unexpected argument: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Handle remaining positional args after --
if [ $# -gt 0 ] && [ -z "$QUERY" ]; then
    QUERY="$1"
    shift
fi

if [ -z "$QUERY" ]; then
    echo "Usage: memory-search.sh <query> [--global] [--sessions] [--category <name>]" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Search engine auto-detection
# ---------------------------------------------------------------------------
if command -v rg &>/dev/null; then
    SEARCH_CMD="rg"
else
    SEARCH_CMD="grep"
fi

# ---------------------------------------------------------------------------
# Build search paths (newline-delimited to support paths with spaces)
# ---------------------------------------------------------------------------
SEARCH_DIRS=""
SCOPE_DESC="project memory"

# Default: .claude/memory/ excluding sessions/
if [ -d ".claude/memory" ]; then
    SEARCH_DIRS=".claude/memory"
fi

if [ "$INCLUDE_GLOBAL" = true ]; then
    if [ -d "$HOME/.claude/memory" ]; then
        if [ -n "$SEARCH_DIRS" ]; then
            SEARCH_DIRS="$SEARCH_DIRS
$HOME/.claude/memory"
        else
            SEARCH_DIRS="$HOME/.claude/memory"
        fi
        SCOPE_DESC="$SCOPE_DESC + global memory"
    fi
fi

if [ "$INCLUDE_SESSIONS" = true ]; then
    SCOPE_DESC="$SCOPE_DESC + sessions"
fi

if [ -z "$SEARCH_DIRS" ]; then
    echo "No results found for \"$QUERY\" in $SCOPE_DESC."
    echo "(No memory directories found)"
    exit 0
fi

# ---------------------------------------------------------------------------
# Collect files to search
# ---------------------------------------------------------------------------
# Build list of files, respecting --sessions exclusion and 30-day limit
collect_files() {
    local dir="$1"
    local include_sessions="$2"

    # Find markdown files in the directory
    # On macOS, use find with -mtime for session limiting
    if [ "$include_sessions" = true ] && [ -d "$dir/sessions" ]; then
        # Include sessions but limit to last 30 days
        # First: non-session files
        find "$dir" -maxdepth 1 -name '*.md' -type f 2>/dev/null
        # Then: session files modified in last 30 days
        find "$dir/sessions" -name '*.md' -type f -mtime -30 2>/dev/null
        # Subdirectories that aren't sessions (e.g., decisions/)
        find "$dir" -mindepth 2 -name '*.md' -type f -not -path '*/sessions/*' 2>/dev/null
    else
        # Exclude sessions/ entirely
        find "$dir" -name '*.md' -type f -not -path '*/sessions/*' 2>/dev/null
    fi
}

FILES=""
while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    dir_files=$(collect_files "$dir" "$INCLUDE_SESSIONS")
    if [ -n "$dir_files" ]; then
        if [ -n "$FILES" ]; then
            FILES="$FILES
$dir_files"
        else
            FILES="$dir_files"
        fi
    fi
done <<EOF_DIRS
$SEARCH_DIRS
EOF_DIRS

if [ -z "$FILES" ]; then
    echo "No results found for \"$QUERY\" in $SCOPE_DESC."
    echo "(No memory files found)"
    exit 0
fi

# ---------------------------------------------------------------------------
# Privacy enforcement: source shared library for is_file_private()
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../hooks/lib-privacy.sh"

# ---------------------------------------------------------------------------
# Privacy enforcement: get private block line ranges for a file
# Returns pairs of start:end line numbers (inclusive) for <private> blocks.
# If a <private> has no closing tag, end is set to a very large number.
# ---------------------------------------------------------------------------
# Accept file content from stdin to avoid TOCTOU race (read file once, use for both
# privacy range detection and search matching).
get_private_ranges_from_stdin() {
    awk '/^[[:space:]]*<private>/ { if (!start) start=NR }
         /^[[:space:]]*<\/private>/ { if (start) { print start":"NR; start=0 } }
         END { if (start) print start":999999" }'
}

# Check if a line number falls within any private range
is_line_private() {
    local line_num="$1"
    local ranges="$2"

    if [ -z "$ranges" ]; then
        return 1
    fi

    local range
    for range in $ranges; do
        local range_start="${range%%:*}"
        local range_end="${range##*:}"
        if [ "$line_num" -ge "$range_start" ] && [ "$line_num" -le "$range_end" ]; then
            return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# Category filtering: check if a match has a nearby category tag
# ---------------------------------------------------------------------------
has_nearby_category() {
    local content="$1"
    local match_line="$2"
    local category="$3"

    local start=$((match_line - 3))
    local end=$((match_line + 3))
    if [ "$start" -lt 1 ]; then
        start=1
    fi

    # Extract nearby lines and check for category tag (use -F for literal match)
    printf '%s\n' "$content" | awk -v s="$start" -v e="$end" 'NR>=s && NR<=e' | grep -qF "<!-- @category: $category -->" && return 0
    return 1
}

# ---------------------------------------------------------------------------
# Main search loop
# ---------------------------------------------------------------------------
TOTAL_MATCHES=0
TOTAL_FILES=0
OUTPUT=""

while IFS= read -r filepath; do
    [ -z "$filepath" ] && continue

    # Skip files with private: true front matter
    if is_file_private "$filepath"; then
        continue
    fi

    # Read file once to avoid TOCTOU race (SEC-1: same snapshot for privacy + search)
    file_content=$(cat "$filepath" 2>/dev/null) || continue

    # Get private block ranges from the snapshot
    private_ranges=$(printf '%s\n' "$file_content" | get_private_ranges_from_stdin)

    # Run search on the snapshot (not the file, to prevent race)
    matches=""
    if [ "$SEARCH_CMD" = "rg" ]; then
        matches=$(printf '%s\n' "$file_content" | rg -n --no-heading -F -- "$QUERY" 2>/dev/null) || true
    else
        matches=$(printf '%s\n' "$file_content" | grep -n -F -- "$QUERY" 2>/dev/null) || true
    fi

    if [ -z "$matches" ]; then
        continue
    fi

    # Process matches: filter by privacy and category
    file_output=""
    file_match_count=0

    while IFS= read -r match_line; do
        [ -z "$match_line" ] && continue

        # Extract line number (format: "linenum:content" or "linenum-content")
        local_line_num=$(echo "$match_line" | cut -d: -f1)
        local_content=$(echo "$match_line" | cut -d: -f2-)

        # Validate line number is numeric
        case "$local_line_num" in
            *[!0-9]*) continue ;;
        esac

        # Privacy check: skip lines within <private> blocks
        if is_line_private "$local_line_num" "$private_ranges"; then
            continue
        fi

        # Category check: if --category specified, verify nearby tag
        if [ -n "$CATEGORY_FILTER" ]; then
            if ! has_nearby_category "$file_content" "$local_line_num" "$CATEGORY_FILTER"; then
                continue
            fi
        fi

        file_match_count=$((file_match_count + 1))

        # Find the nearest category tag near the match (within 3 lines above/below) for display
        local_cat_tag=""
        local_cat_start=$((local_line_num - 3))
        if [ "$local_cat_start" -lt 1 ]; then
            local_cat_start=1
        fi
        local_cat_end=$((local_line_num + 3))
        local_cat_tag=$(printf '%s\n' "$file_content" | awk -v s="$local_cat_start" -v e="$local_cat_end" 'NR>=s && NR<=e' | grep '<!-- @category:' | tail -1) || true

        if [ -n "$local_cat_tag" ]; then
            file_output="$file_output
$local_cat_tag"
        fi
        file_output="$file_output
**Line $local_line_num:** $local_content"

    done <<EOF_MATCHES
$matches
EOF_MATCHES

    if [ "$file_match_count" -gt 0 ]; then
        TOTAL_FILES=$((TOTAL_FILES + 1))
        TOTAL_MATCHES=$((TOTAL_MATCHES + file_match_count))
        OUTPUT="$OUTPUT

### $filepath
$file_output"
    fi

done <<EOF_FILES
$FILES
EOF_FILES

# ---------------------------------------------------------------------------
# Output results
# ---------------------------------------------------------------------------
if [ "$TOTAL_MATCHES" -eq 0 ]; then
    echo "No results found for \"$QUERY\" in $SCOPE_DESC."
    exit 0
fi

echo "## Results for: \"$QUERY\""
echo "$OUTPUT"
echo ""
echo "---"
echo "Found $TOTAL_MATCHES matches across $TOTAL_FILES files."
