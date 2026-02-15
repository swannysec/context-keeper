#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[ConKeeper] stop.sh failed at line $LINENO" >&2; exit 0' ERR

# Only act if project memory exists
if [ -d ".claude/memory" ]; then
    FLAG_DIR="${TMPDIR:-/tmp}/conkeeper"
    health_cache="$FLAG_DIR/health-$(date +%Y%m%d)"
    LAST_SYNC_FILE=".claude/memory/.last-sync"

    # Check if cached health results show stale files
    has_stale=false
    if [ -f "$health_cache" ] && [ -s "$health_cache" ]; then
        has_stale=true
    fi

    # Check if a sync happened this session (.last-sync mtime > health cache mtime)
    sync_happened=false
    if [ "$has_stale" = true ] && [ -f "$LAST_SYNC_FILE" ] && [ ! -L "$LAST_SYNC_FILE" ] && [ -f "$health_cache" ]; then
        sync_mtime=$(stat -f %m "$LAST_SYNC_FILE" 2>/dev/null) || sync_mtime=0
        cache_mtime=$(stat -f %m "$health_cache" 2>/dev/null) || cache_mtime=0
        if [ "$sync_mtime" -gt "$cache_mtime" ]; then
            sync_happened=true
        fi
    fi

    if [ "$has_stale" = true ] && [ "$sync_happened" = false ]; then
        # Stale memory and no sync — single consolidated message
        echo "[ConKeeper] Session ending with stale memory. Run /memory-sync to preserve context (this will also trigger /memory-reflect if corrections were processed)." >&2
    else
        # No stale files or sync already happened — fall back to existing reflect suggestion
        has_data=false
        queue=".claude/memory/corrections-queue.md"
        obs=".claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

        if [ -f "$queue" ] && [ "$(wc -l < "$queue")" -gt 3 ]; then
            has_data=true
        fi
        if [ -f "$obs" ] && [ "$(wc -l < "$obs")" -gt 3 ]; then
            has_data=true
        fi

        if [ "$has_data" = true ]; then
            echo "[ConKeeper] Session ending. Consider running /memory-reflect to capture learnings from this session." >&2
        fi
    fi
fi

exit 0
