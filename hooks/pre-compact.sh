#!/usr/bin/env bash
set -euo pipefail

# Error handling for debugging
trap 'echo "[ConKeeper] pre-compact.sh failed at line $LINENO" >&2' ERR

# Require jq for JSON parsing
if ! command -v jq &>/dev/null; then
    echo "[ConKeeper] pre-compact.sh: jq required but not found." >&2
    exit 0
fi

# Parse session_id from stdin JSON (cap at 1MB for safety)
input=$(head -c 1048576)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')

# Validate session_id format (alphanumeric, hyphens, underscores only)
if [[ -z "$session_id" || ! "$session_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    exit 0
fi

# Flag directory for cross-hook communication
flag_dir="${TMPDIR:-/tmp}/conkeeper"
mkdir -p "$flag_dir" 2>/dev/null; chmod 700 "$flag_dir" 2>/dev/null || true
flag_file="${flag_dir}/synced-${session_id}"

# Check if memory-sync ran this session (flag file exists and is not stale)
# TTL: 4 hours (14400 seconds)
TTL=14400

if [[ -f "$flag_file" ]]; then
    flag_epoch=$(cat "$flag_file" 2>/dev/null || echo "0")
    # Validate epoch is numeric (prevents arithmetic errors from corrupted flag files)
    if [[ -z "$flag_epoch" ]] || ! [[ "$flag_epoch" =~ ^[0-9]+$ ]]; then
        flag_epoch=0
    fi
    current_epoch=$(date +%s)
    age=$(( current_epoch - flag_epoch ))

    if (( age < TTL )); then
        echo "[ConKeeper] Compaction starting. Memory was synced this session." >&2
    else
        echo "[ConKeeper] Warning: Compaction starting and memory-sync has not run. Context may be lost. Run /memory-sync in your next prompt." >&2
    fi
else
    echo "[ConKeeper] Warning: Compaction starting and memory-sync has not run. Context may be lost. Run /memory-sync in your next prompt." >&2
fi

# Always exit 0 — never block compaction
exit 0
