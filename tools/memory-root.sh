#!/usr/bin/env bash
# Print the selected project (default) or global root without creating it.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../hooks/lib-memory-root.sh"
case "${1:-}" in
    '') [ "$#" -eq 0 ] || exit 1; resolve_memory_root "$PWD" ;;
    --global) [ "$#" -eq 1 ] || exit 1; resolve_memory_root "$HOME" ;;
    *) echo 'Usage: memory-root.sh [--global]' >&2; exit 1 ;;
esac
