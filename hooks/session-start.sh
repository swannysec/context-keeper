#!/usr/bin/env bash
set -euo pipefail

# Error handling for debugging (MEDIUM-1)
trap 'echo "session-start.sh failed at line $LINENO" >&2' ERR

# Check for memory directories
# NOTE: PROJECT_MEMORY uses relative path - this script assumes CWD is the project root.
# Claude Code invokes hooks from the project directory, so this is the expected behavior.
# (HIGH-3: Documented CWD assumption)
GLOBAL_MEMORY="$HOME/.claude/memory"
PROJECT_MEMORY=".claude/memory"

# Validate directory exists and resolve symlinks safely
# Returns 0 if valid directory, 1 otherwise
validate_memory_dir() {
    local dir="$1"
    local expected_parent="$2"

    # Check if path exists and is a directory (follows symlinks)
    if [ ! -d "$dir" ]; then
        return 1
    fi

    # If it's a symlink, resolve and validate the target
    if [ -L "$dir" ]; then
        local resolved
        # Use readlink -f if available, otherwise basic check
        if command -v readlink &>/dev/null; then
            resolved=$(readlink -f "$dir" 2>/dev/null) || return 1
            # Ensure resolved path is under expected parent (prevent symlink escape)
            case "$resolved" in
                "$expected_parent"*) return 0 ;;
                *) return 1 ;;  # Symlink points outside expected location
            esac
        fi
    fi

    return 0
}

# Privacy stripping — used by content injection (see Phase 05+ enhancements)
# Source shared privacy functions from lib-privacy.sh
HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-privacy.sh
. "$HOOKS_DIR/lib-privacy.sh"

has_global=false
has_project=false

validate_memory_dir "$GLOBAL_MEMORY" "$HOME" && has_global=true
validate_memory_dir "$PROJECT_MEMORY" "$PWD" && has_project=true

# Build context message
context=""

if [ "$has_global" = true ] || [ "$has_project" = true ]; then
    context="<memory-system-active>
Memory system detected.
- Global memory: $([ "$has_global" = true ] && echo "\$HOME/.claude/memory" || echo "not configured")
- Project memory: $([ "$has_project" = true ] && echo ".claude/memory" || echo "not configured")

For non-trivial tasks, load relevant memory before starting work:
- Read product-context.md and active-context.md for project context
- Check progress.md for task status
- Review decisions/ for architectural context

Update memory when:
- Making significant architectural decisions (add to decisions/)
- Completing or starting major tasks (update progress.md)
- Context changes significantly (update active-context.md)
- Session ends with important state to preserve

To initialize memory for a new project: /memory-init
To sync current session to memory: /memory-sync
</memory-system-active>"
else
    context="<memory-system-available>
No memory directories detected. For organized project work, initialize memory with /memory-init.
This provides structured context management across sessions.
</memory-system-available>"
fi

# JSON encoding function (CRITICAL-1, HIGH-1)
# Uses jq if available, otherwise falls back to pure-bash encoding
json_encode() {
    local input="$1"
    if command -v jq &>/dev/null; then
        # jq handles all JSON escaping correctly
        printf '%s' "$input" | jq -Rs '.'
    else
        # Pure-bash fallback: escape backslashes, quotes, and control characters
        # Preserves newlines as \n escape sequences for proper JSON
        local escaped="$input"
        escaped="${escaped//\\/\\\\}"      # Escape backslashes first
        escaped="${escaped//\"/\\\"}"      # Escape double quotes
        escaped="${escaped//$'\t'/\\t}"    # Escape tabs
        escaped="${escaped//$'\r'/\\r}"    # Escape carriage returns
        escaped="${escaped//$'\n'/\\n}"    # Escape newlines as \n
        printf '"%s"' "$escaped"
    fi
}

# Output JSON with properly encoded context
encoded_context=$(json_encode "$context")

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $encoded_context
  }
}
EOF
