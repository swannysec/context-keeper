#!/usr/bin/env bash
# Configuration utility functions for ConKeeper memory system.
# Sourced by hooks (session-start.sh, user-prompt-submit.sh) and tools. Do not execute directly.

# Extracts YAML frontmatter from a file into CONKEEPER_FRONTMATTER variable.
# Usage: extract_frontmatter "/path/to/file"
# Returns 0 if frontmatter found, 1 otherwise.
# Security: refuses to read through symlinks.
extract_frontmatter() {
    local file="$1"
    CONKEEPER_FRONTMATTER=""

    # Security: refuse to read through symlinks
    if [ -L "$file" ]; then
        return 1
    fi

    if [ ! -f "$file" ]; then
        return 1
    fi

    local in_frontmatter=false
    local delimiter_count=0
    while IFS= read -r line; do
        if [ "$line" = "---" ]; then
            delimiter_count=$((delimiter_count + 1))
            if [ "$delimiter_count" -eq 1 ]; then
                in_frontmatter=true
                continue
            elif [ "$delimiter_count" -eq 2 ]; then
                break
            fi
        fi
        if [ "$in_frontmatter" = true ]; then
            # Strip inline YAML comments (# preceded by whitespace)
            line=$(printf '%s' "$line" | sed 's/[[:space:]]#.*$//')
            CONKEEPER_FRONTMATTER="${CONKEEPER_FRONTMATTER}${line}
"
        fi
    done < "$file"

    if [ -n "$CONKEEPER_FRONTMATTER" ]; then
        return 0
    fi
    return 1
}

# Parse an integer value from CONKEEPER_FRONTMATTER.
# Usage: val=$(parse_yaml_int "key" "default")
parse_yaml_int() {
    local key="$1"
    local default="$2"
    local val
    val=$(printf '%s' "$CONKEEPER_FRONTMATTER" | awk -F': *' -v k="$key" '$1 == k { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2 }')
    if [ -n "$val" ] && printf '%s' "$val" | grep -qE '^[0-9]+$'; then
        printf '%s' "$val"
    else
        printf '%s' "$default"
    fi
}

# Parse a string value from CONKEEPER_FRONTMATTER.
# Usage: val=$(parse_yaml_str "key" "default")
parse_yaml_str() {
    local key="$1"
    local default="$2"
    local val
    val=$(printf '%s' "$CONKEEPER_FRONTMATTER" | awk -F': *' -v k="$key" '$1 == k { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2 }')
    if [ -n "$val" ]; then
        printf '%s' "$val"
    else
        printf '%s' "$default"
    fi
}

