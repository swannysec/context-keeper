#!/usr/bin/env bash
# ConKeeper Memory Search Script
# Cross-platform search tool for memory files with privacy and category filtering.
# Usage: bash tools/memory-search.sh <query> [--global] [--sessions] [--category <name>]

set -euo pipefail

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
            if [ $# -lt 2 ]; then
                echo "Error: --category requires a value" >&2
                exit 1
            fi
            CATEGORY_FILTER="$2"
            shift 2
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
# Build search paths
# ---------------------------------------------------------------------------
SEARCH_DIRS=""
SCOPE_DESC="project memory"

# Default: .claude/memory/ excluding sessions/
if [ -d ".claude/memory" ]; then
    SEARCH_DIRS=".claude/memory"
fi

if [ "$INCLUDE_GLOBAL" = true ]; then
    if [ -d "$HOME/.claude/memory" ]; then
        SEARCH_DIRS="$SEARCH_DIRS $HOME/.claude/memory"
        SCOPE_DESC="$SCOPE_DESC + global memory"
    fi
fi

if [ "$INCLUDE_SESSIONS" = true ]; then
    SCOPE_DESC="$SCOPE_DESC + sessions"
fi

# Trim leading space
SEARCH_DIRS="$(echo "$SEARCH_DIRS" | sed 's/^ //')"

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
for dir in $SEARCH_DIRS; do
    dir_files=$(collect_files "$dir" "$INCLUDE_SESSIONS")
    if [ -n "$dir_files" ]; then
        if [ -n "$FILES" ]; then
            FILES="$FILES
$dir_files"
        else
            FILES="$dir_files"
        fi
    fi
done

if [ -z "$FILES" ]; then
    echo "No results found for \"$QUERY\" in $SCOPE_DESC."
    echo "(No memory files found)"
    exit 0
fi

# ---------------------------------------------------------------------------
# Privacy enforcement: is_file_private (check YAML front matter)
# ---------------------------------------------------------------------------
is_file_private() {
    local file="$1"
    local first_line
    first_line=$(head -1 "$file" | sed 's/^\xef\xbb\xbf//' | tr -d '\r')
    if [ "$first_line" != "---" ]; then
        return 1
    fi
    awk 'NR>1 && NR<=20 { if (/^---/) exit; print }' "$file" | tr -d '\r' | grep -qi '^private: *["'"'"']\{0,1\}true["'"'"']\{0,1\}[[:space:]]*$' && return 0
    return 1
}

# ---------------------------------------------------------------------------
# Privacy enforcement: get private block line ranges for a file
# Returns pairs of start:end line numbers (inclusive) for <private> blocks.
# If a <private> has no closing tag, end is set to a very large number.
# ---------------------------------------------------------------------------
get_private_ranges() {
    local file="$1"
    local start_lines end_lines
    start_lines=$(grep -n '^[[:space:]]*<private>' "$file" 2>/dev/null | cut -d: -f1)
    end_lines=$(grep -n '^[[:space:]]*</private>' "$file" 2>/dev/null | cut -d: -f1)

    if [ -z "$start_lines" ]; then
        return
    fi

    # Pair up start/end lines. Use while-read for Bash 3.2 compat.
    local starts_arr=""
    local ends_arr=""
    local i=0
    while IFS= read -r line; do
        starts_arr="$starts_arr $line"
        i=$((i + 1))
    done <<EOF_STARTS
$start_lines
EOF_STARTS

    i=0
    while IFS= read -r line; do
        ends_arr="$ends_arr $line"
        i=$((i + 1))
    done <<EOF_ENDS
$end_lines
EOF_ENDS

    # Trim leading space
    starts_arr="$(echo "$starts_arr" | sed 's/^ //')"
    ends_arr="$(echo "$ends_arr" | sed 's/^ //')"

    # Match starts with ends sequentially
    local remaining_ends="$ends_arr"
    for s in $starts_arr; do
        local matched_end=""
        local new_remaining=""
        local found=false
        for e in $remaining_ends; do
            if [ "$found" = false ] && [ "$e" -ge "$s" ]; then
                matched_end="$e"
                found=true
            else
                if [ -n "$new_remaining" ]; then
                    new_remaining="$new_remaining $e"
                else
                    new_remaining="$e"
                fi
            fi
        done
        if [ -z "$matched_end" ]; then
            matched_end=999999
        fi
        echo "$s:$matched_end"
        remaining_ends="$new_remaining"
    done
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
    local file="$1"
    local match_line="$2"
    local category="$3"

    local start=$((match_line - 3))
    local end=$((match_line + 3))
    if [ "$start" -lt 1 ]; then
        start=1
    fi

    # Extract nearby lines and check for category tag
    awk -v s="$start" -v e="$end" 'NR>=s && NR<=e' "$file" | grep -q "<!-- @category: $category -->" && return 0
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

    # Get private block ranges for this file
    private_ranges=$(get_private_ranges "$filepath")

    # Run search on this file
    matches=""
    if [ "$SEARCH_CMD" = "rg" ]; then
        matches=$(rg -n --no-heading -F -- "$QUERY" "$filepath" 2>/dev/null) || true
    else
        matches=$(grep -n -F -- "$QUERY" "$filepath" 2>/dev/null) || true
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
            if ! has_nearby_category "$filepath" "$local_line_num" "$CATEGORY_FILTER"; then
                continue
            fi
        fi

        file_match_count=$((file_match_count + 1))

        # Find the nearest category tag above the match (within 3 lines) for display
        local_cat_tag=""
        local_cat_start=$((local_line_num - 3))
        if [ "$local_cat_start" -lt 1 ]; then
            local_cat_start=1
        fi
        local_cat_tag=$(awk -v s="$local_cat_start" -v e="$local_line_num" 'NR>=s && NR<=e' "$filepath" 2>/dev/null | grep '<!-- @category:' | tail -1) || true

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
