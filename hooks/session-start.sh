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

has_global=false
has_project=false

[ -d "$GLOBAL_MEMORY" ] && has_global=true
[ -d "$PROJECT_MEMORY" ] && has_project=true

# Build context message
context=""

if [ "$has_global" = true ] || [ "$has_project" = true ]; then
    context="<memory-system-active>
Memory system detected.
- Global memory: $([ "$has_global" = true ] && echo "~/.claude/memory" || echo "not configured")
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
        # Then wrap in quotes and collapse whitespace
        local escaped="$input"
        escaped="${escaped//\\/\\\\}"      # Escape backslashes first
        escaped="${escaped//\"/\\\"}"      # Escape double quotes
        escaped="${escaped//$'\t'/\\t}"    # Escape tabs
        escaped="${escaped//$'\r'/\\r}"    # Escape carriage returns
        # Replace newlines with spaces and collapse multiple spaces
        escaped=$(printf '%s' "$escaped" | tr '\n' ' ' | sed 's/  */ /g')
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
