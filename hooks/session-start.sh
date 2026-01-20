#!/usr/bin/env bash
set -euo pipefail

# Check for memory directories
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

# Output JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$(echo "$context" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/  */ /g')"
  }
}
EOF
