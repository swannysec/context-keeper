#!/usr/bin/env bash
# Privacy utility functions for ConKeeper memory system.
# Sourced by session-start.sh and tests. Do not execute directly.

# Strips block-level <private>...</private> content from stdin.
# Only matches <private>/<\/private> at line start (with optional whitespace).
# Tags inside code fences are not affected by this function because
# code-fenced content should not be piped through strip_private.
strip_private() {
    sed '/^[[:space:]]*<private>/,/^[[:space:]]*<\/private>/d'
}

# Checks if a file has private: true in its YAML front matter.
# Returns 0 (true) if private, 1 (false) otherwise.
# Validates that the file starts with --- (YAML front matter delimiter)
# and only searches within the front matter block (up to 20 lines).
is_file_private() {
    local file="$1"
    # File must start with --- to have valid YAML front matter
    local first_line
    first_line=$(head -1 "$file")
    if [ "$first_line" != "---" ]; then
        return 1
    fi
    # Extract front matter (between first --- and next ---), search up to 20 lines
    # Use awk for BSD/GNU portability: print lines 2..20 until next --- delimiter
    awk 'NR>1 && NR<=20 { if (/^---$/) exit; print }' "$file" | grep -q '^private: *true[[:space:]]*$' && return 0
    return 1
}
