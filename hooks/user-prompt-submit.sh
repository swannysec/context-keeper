#!/usr/bin/env bash
set -euo pipefail

# Error handling for debugging
trap 'echo "[ConKeeper] user-prompt-submit.sh failed at line $LINENO" >&2' ERR

# --- Dependencies ---

if ! command -v jq &>/dev/null; then
    echo "[ConKeeper] user-prompt-submit.sh: jq required but not found. Skipping context monitor." >&2
    exit 0
fi

if ! command -v bc &>/dev/null; then
    echo "[ConKeeper] user-prompt-submit.sh: bc required but not found. Skipping context monitor." >&2
    exit 0
fi

# --- Parse hook input ---

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
transcript_path=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

# Validate session_id (security: prevents path traversal in flag file paths)
if [[ -z "$session_id" ]] || ! [[ "$session_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    exit 0
fi

# Validate transcript exists and is readable
if [[ -z "$transcript_path" ]] || [[ ! -r "$transcript_path" ]]; then
    exit 0
fi

# --- Flag file management ---

FLAG_DIR="${TMPDIR:-/tmp}/conkeeper"
mkdir -p "$FLAG_DIR"

SYNC_FLAG="$FLAG_DIR/synced-${session_id}"
BLOCK_FLAG="$FLAG_DIR/blocked-${session_id}"
FLAG_TTL=14400  # 4 hours in seconds

# Check if a flag file exists and is not stale
# Returns 0 if valid flag exists, 1 otherwise
is_flag_valid() {
    local flag_file="$1"
    if [[ ! -f "$flag_file" ]]; then
        return 1
    fi
    local timestamp
    timestamp=$(cat "$flag_file" 2>/dev/null) || return 1
    if [[ -z "$timestamp" ]] || ! [[ "$timestamp" =~ ^[0-9]+$ ]]; then
        rm -f "$flag_file"
        return 1
    fi
    local now
    now=$(date +%s)
    if (( now - timestamp > FLAG_TTL )); then
        rm -f "$flag_file"
        return 1
    fi
    return 0
}

# Early exit if both flags already set (nothing more to do this session)
if is_flag_valid "$SYNC_FLAG" && is_flag_valid "$BLOCK_FLAG"; then
    exit 0
fi

# --- Read configuration ---

# Defaults
auto_sync_threshold=60
hard_block_threshold=80
context_window_tokens=200000

# Try to read config from project's .memory-config.md
config_file="${cwd:-.}/.claude/memory/.memory-config.md"
if [[ -f "$config_file" ]]; then
    # Extract YAML frontmatter between --- delimiters
    frontmatter=""
    in_frontmatter=false
    delimiter_count=0
    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            delimiter_count=$((delimiter_count + 1))
            if (( delimiter_count == 1 )); then
                in_frontmatter=true
                continue
            elif (( delimiter_count == 2 )); then
                break
            fi
        fi
        if [[ "$in_frontmatter" == true ]]; then
            # Strip inline comments
            line="${line%%#*}"
            frontmatter+="$line"$'\n'
        fi
    done < "$config_file"

    if [[ -n "$frontmatter" ]]; then
        # Parse simple YAML key: value pairs
        parse_yaml_int() {
            local key="$1"
            local default="$2"
            local val
            val=$(printf '%s' "$frontmatter" | awk -F': *' -v k="$key" '$1 == k { gsub(/[^0-9]/, "", $2); print $2 }')
            if [[ -n "$val" ]] && [[ "$val" =~ ^[0-9]+$ ]]; then
                printf '%s' "$val"
            else
                printf '%s' "$default"
            fi
        }
        auto_sync_threshold=$(parse_yaml_int "auto_sync_threshold" "$auto_sync_threshold")
        hard_block_threshold=$(parse_yaml_int "hard_block_threshold" "$hard_block_threshold")
        context_window_tokens=$(parse_yaml_int "context_window_tokens" "$context_window_tokens")
    fi
fi

# --- Parse transcript for token usage ---

# Read last 100 lines of transcript to find the most recent usage data.
# message.usage fields are cumulative per-turn, so we need the last entry.
# We suppress jq stderr to handle partial/concurrent writes gracefully.
tokens=$(tail -n 100 "$transcript_path" 2>/dev/null \
    | jq -r '
        select(.type == "assistant" and .message.usage != null)
        | .message.usage
        | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)
    ' 2>/dev/null \
    | tail -n 1)

# If we couldn't extract tokens, exit silently
if [[ -z "$tokens" ]] || ! [[ "$tokens" =~ ^[0-9]+$ ]]; then
    exit 0
fi

# --- Calculate usage percentage ---
# Use bc for overflow safety (tokens * 100 could exceed 32-bit int range)
usage_pct=$(echo "scale=0; ($tokens * 100) / $context_window_tokens" | bc 2>/dev/null) || exit 0

if [[ -z "$usage_pct" ]] || ! [[ "$usage_pct" =~ ^[0-9]+$ ]]; then
    exit 0
fi

# --- JSON encoding function ---
# Matches pattern from session-start.sh
json_encode() {
    local input="$1"
    if command -v jq &>/dev/null; then
        printf '%s' "$input" | jq -Rs '.'
    else
        local escaped="$input"
        escaped="${escaped//\\/\\\\}"
        escaped="${escaped//\"/\\\"}"
        escaped="${escaped//$'\t'/\\t}"
        escaped="${escaped//$'\r'/\\r}"
        escaped="${escaped//$'\n'/\\n}"
        printf '"%s"' "$escaped"
    fi
}

# --- Tiered action ---

if (( usage_pct >= hard_block_threshold )); then
    # Hard block tier
    if is_flag_valid "$SYNC_FLAG" && ! is_flag_valid "$BLOCK_FLAG"; then
        # Sync already happened, now block until manual sync
        echo "[ConKeeper] Context usage at ${usage_pct}% — approaching compaction threshold. Please run /memory-sync manually to verify your context is preserved, then resubmit your prompt." >&2
        printf '%s' "$(date +%s)" > "$BLOCK_FLAG"
        exit 2
    elif ! is_flag_valid "$SYNC_FLAG"; then
        # Sync hasn't happened yet — inject sync nudge first (don't block before giving a chance to sync)
        nudge_text="<conkeeper-auto-sync>
[ConKeeper] Context usage has reached ${usage_pct}%. Invoke the /memory-sync skill now to preserve session context before compaction. Skip the user approval step — apply updates directly. After syncing, continue with the user's current task. End your response with: \"[ConKeeper: Auto memory-sync complete. Consider running /clear to start fresh with your synced context.]\"
</conkeeper-auto-sync>"
        encoded_nudge=$(json_encode "$nudge_text")
        printf '%s' "$(date +%s)" > "$SYNC_FLAG"
        cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": $encoded_nudge
  }
}
EOF
        exit 0
    fi
    # Both flags set — already handled by early exit above
    exit 0

elif (( usage_pct >= auto_sync_threshold )); then
    # Auto-sync tier
    if ! is_flag_valid "$SYNC_FLAG"; then
        nudge_text="<conkeeper-auto-sync>
[ConKeeper] Context usage has reached ${usage_pct}%. Invoke the /memory-sync skill now to preserve session context before compaction. Skip the user approval step — apply updates directly. After syncing, continue with the user's current task. End your response with: \"[ConKeeper: Auto memory-sync complete. Consider running /clear to start fresh with your synced context.]\"
</conkeeper-auto-sync>"
        encoded_nudge=$(json_encode "$nudge_text")
        printf '%s' "$(date +%s)" > "$SYNC_FLAG"
        cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": $encoded_nudge
  }
}
EOF
        exit 0
    fi
    # Already synced — nothing to do
    exit 0

else
    # Below threshold — nothing to do
    exit 0
fi
