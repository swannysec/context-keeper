#!/usr/bin/env bash
# Handoff generation library for ConKeeper lifecycle automation.
# Sourced conditionally by user-prompt-submit.sh when handoff trigger fires.
# Do not execute directly.

# Run a command with a timeout (bash-native, no GNU timeout).
# Usage: run_with_timeout <seconds> <command> [args...]
# Returns the command's exit code on success; non-zero on timeout or failure.
# All callers should use `|| true` since timeout exit codes vary.
run_with_timeout() {
    local timeout_secs="$1"
    shift
    local output=""
    output=$("$@" &
        local cmd_pid=$!
        (sleep "$timeout_secs" && kill "$cmd_pid" 2>/dev/null) &
        local killer_pid=$!
        wait "$cmd_pid" 2>/dev/null
        local exit_code=$?
        kill "$killer_pid" 2>/dev/null 2>&1
        wait "$killer_pid" 2>/dev/null 2>&1
        exit $exit_code
    ) 2>/dev/null
    local rc=$?
    printf '%s' "$output"
    return $rc
}

# Generate a handoff file capturing current session state.
# Usage: generate_handoff <session_id> <cwd> <usage_pct> <handoff_ttl>
generate_handoff() {
    local session_id="$1"
    local cwd="$2"
    local usage_pct="$3"
    local handoff_ttl="$4"
    local epoch
    epoch=$(date +%s)

    # Extract Current Focus from active-context.md
    local focus_summary="No active context available."
    local active_ctx="${cwd:-.}/.claude/memory/active-context.md"
    if [ -f "$active_ctx" ] && [ ! -L "$active_ctx" ]; then
        local extracted
        extracted=$(awk '/^## Current Focus/{found=1; next} found && /^## /{exit} found{print}' "$active_ctx" 2>/dev/null | head -5)
        if [ -z "$extracted" ]; then
            extracted=$(head -5 "$active_ctx" 2>/dev/null)
        fi
        if [ -n "$extracted" ]; then
            focus_summary="$extracted"
        fi
    fi

    # Git state (with timeouts to stay within hook budget)
    local branch="unknown"
    local dirty=false
    local git_detail=""

    if command -v git &>/dev/null; then
        local branch_result
        branch_result=$(run_with_timeout 2 git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null) || true
        if [ -n "$branch_result" ]; then
            branch="$branch_result"
        fi

        local porcelain
        porcelain=$(run_with_timeout 2 git -C "$cwd" status --porcelain 2>/dev/null) || true
        if [ -n "$porcelain" ]; then
            dirty=true
            # Try full diff; if too long, fall back to --stat
            local diff_output
            diff_output=$(run_with_timeout 2 git -C "$cwd" diff 2>/dev/null) || true
            if [ -n "$diff_output" ]; then
                local line_count
                line_count=$(printf '%s\n' "$diff_output" | wc -l | tr -d ' ')
                if [ "$line_count" -gt 50 ]; then
                    diff_output=$(run_with_timeout 2 git -C "$cwd" diff --stat 2>/dev/null) || true
                fi
            fi
            if [ -n "$diff_output" ]; then
                git_detail="$diff_output"
            fi
        fi
    fi

    # Write handoff file
    local handoff_dir="${cwd:-.}/.claude/memory/.handoffs"
    mkdir -p "$handoff_dir"
    chmod 700 "$handoff_dir" 2>/dev/null || true
    local handoff_file="$handoff_dir/.pending-handoff-${session_id}.md"

    # Security: refuse to write through symlinks
    if [ -L "$handoff_file" ]; then
        echo "[ConKeeper] Refusing to write handoff through symlink" >&2
        return 1
    fi

    {
        printf '%s\n' "---"
        printf 'generated: %s\n' "$epoch"
        printf 'previous_session: %s\n' "$session_id"
        printf 'context_pct: %s\n' "$usage_pct"
        printf 'branch: %s\n' "$branch"
        printf 'dirty: %s\n' "$dirty"
        printf 'ttl: %s\n' "$handoff_ttl"
        printf '%s\n' "---"
        printf '# Pending Handoff\n\n'
        printf '%s\n' "$focus_summary"
        if [ "$dirty" = true ]; then
            printf '\nUncommitted changes on branch %s.\n' "$branch"
            if [ -n "$git_detail" ]; then
                printf '```\n%s\n```\n' "$git_detail"
            fi
        fi
    } > "$handoff_file"
}
