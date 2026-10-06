#!/usr/bin/env bash
# Phase 1 only: locks down observed v1.4 behavior, including known gaps.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/current_roots.py"
