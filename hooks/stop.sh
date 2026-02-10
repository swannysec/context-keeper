#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[ConKeeper] stop.sh failed at line $LINENO" >&2; exit 0' ERR

# Only suggest reflect if project memory exists
if [[ -d ".claude/memory" ]]; then
    # Check if there are unprocessed corrections or observations
    has_data=false
    queue=".claude/memory/corrections-queue.md"
    obs=".claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

    if [[ -f "$queue" ]] && [[ $(wc -l < "$queue") -gt 3 ]]; then
        has_data=true
    fi
    if [[ -f "$obs" ]] && [[ $(wc -l < "$obs") -gt 3 ]]; then
        has_data=true
    fi

    if [[ "$has_data" == true ]]; then
        echo "[ConKeeper] Session ending. Consider running /memory-reflect to capture learnings from this session." >&2
    fi
fi

exit 0
