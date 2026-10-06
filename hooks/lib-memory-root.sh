#!/usr/bin/env bash
# Shared fixed-root selection. Resolution never creates directories.

resolve_memory_root() {
    local base="$1"
    local selected ancestor resolved
    base=$(cd "$base" 2>/dev/null && pwd -P) || {
        echo "[ConKeeper] Cannot access memory scope: $1" >&2
        return 1
    }
    selected="$base/.ai/memory"
    if [ -e "$selected" ] || [ -L "$selected" ]; then
        if [ -e "$base/.claude/memory" ] || [ -L "$base/.claude/memory" ]; then
            echo "[ConKeeper] Both memory roots exist; using $selected. Legacy memory is untouched." >&2
        fi
    elif [ -e "$base/.claude/memory" ] || [ -L "$base/.claude/memory" ]; then
        selected="$base/.claude/memory"
    fi

    # Resolve the nearest existing directory, including symlinked parents.
    # An unsafe selected root must not silently fall back to a different root.
    ancestor="$selected"
    while [ ! -e "$ancestor" ] && [ ! -L "$ancestor" ]; do
        ancestor=$(dirname "$ancestor")
    done
    resolved=$(cd "$ancestor" 2>/dev/null && pwd -P) || {
        echo "[ConKeeper] Invalid or inaccessible memory directory: $selected" >&2
        return 1
    }
    case "$resolved" in
        "$base"|"$base"/*) ;;
        *) echo "[ConKeeper] Memory directory escapes its scope: $selected" >&2; return 1 ;;
    esac
    case "$resolved" in
        "$base"/.claude/memory|"$base"/.claude/memory/*) ;;
        "$base"/.claude|"$base"/.claude/*|"$base"/.codex|"$base"/.codex/*|"$base"/.agents|"$base"/.agents/*|"$base"/.hermes|"$base"/.hermes/*|"$base"/.pi|"$base"/.pi/*|"$base"/.zed|"$base"/.zed/*)
            echo "[ConKeeper] Refusing agent-native memory directory: $selected" >&2
            return 1 ;;
    esac
    if [ ! -r "$ancestor" ] || [ ! -x "$ancestor" ]; then
        echo "[ConKeeper] Cannot read memory directory: $selected" >&2
        return 1
    fi
    printf '%s\n' "$selected"
}

# Reject symlinked subdirectories before reading, writing or cleaning children.
# The root itself has already been checked by resolve_memory_root.
memory_subdir_safe() {
    local root="$1"
    local path="$2"
    case "$path" in "$root"|"$root"/*) ;; *) return 1 ;; esac
    while [ "$path" != "$root" ]; do
        if [ -L "$path" ] || { [ -e "$path" ] && [ ! -d "$path" ]; }; then
            echo "[ConKeeper] Refusing unsafe memory subdirectory: $path" >&2
            return 1
        fi
        path=$(dirname "$path")
    done
    return 0
}
