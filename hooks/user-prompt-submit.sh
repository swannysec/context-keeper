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

# Cap stdin at 1MB to prevent excessive memory use from large payloads
input=$(head -c 1048576)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
transcript_path=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

# Validate session_id (security: prevents path traversal in flag file paths)
if [[ -z "$session_id" ]] || ! [[ "$session_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    exit 0
fi

# Validate and resolve cwd (security: prevents path traversal and symlink escape)
if [[ -n "$cwd" ]]; then
    cwd=$(cd "$cwd" 2>/dev/null && pwd) || exit 0
fi

# Validate transcript exists and is readable
if [[ -z "$transcript_path" ]] || [[ ! -r "$transcript_path" ]]; then
    exit 0
fi

# --- Flag file management ---

FLAG_DIR="${TMPDIR:-/tmp}/conkeeper"
mkdir -p "$FLAG_DIR"
chmod 700 "$FLAG_DIR" 2>/dev/null || true

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

# Determine if threshold actions (sync/block) are still needed this session
need_threshold_actions=true
if is_flag_valid "$SYNC_FLAG" && is_flag_valid "$BLOCK_FLAG"; then
    need_threshold_actions=false
fi

# --- Read configuration ---

# Defaults
auto_sync_threshold=60
hard_block_threshold=80
context_window_tokens=200000  # Default; overridden by .memory-config.md or auto-detected from model
correction_sensitivity=low

config_had_explicit_window=false

# Source shared config library
SCRIPT_DIR_UPS="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR_UPS/lib-config.sh"

# Try to read config from project's .memory-config.md
config_file="${cwd:-.}/.claude/memory/.memory-config.md"
if extract_frontmatter "$config_file"; then
    auto_sync_threshold=$(parse_yaml_int "auto_sync_threshold" "$auto_sync_threshold")
    hard_block_threshold=$(parse_yaml_int "hard_block_threshold" "$hard_block_threshold")
    parsed_window=$(parse_yaml_int "context_window_tokens" "")
    if [[ -n "$parsed_window" ]]; then
        context_window_tokens=$parsed_window
        config_had_explicit_window=true
    fi
    correction_sensitivity=$(parse_yaml_str "correction_sensitivity" "low")
    # Context bracket settings
    context_brackets=$(parse_yaml_str "context_brackets" "true")
    bracket_fresh=$(parse_yaml_int "bracket_fresh" "40")
    bracket_moderate=$(parse_yaml_int "bracket_moderate" "60")
    bracket_depleted=$(parse_yaml_int "bracket_depleted" "80")
    # Lifecycle automation settings
    auto_clear=$(parse_yaml_str "auto_clear" "false")
    auto_clear_pct=$(parse_yaml_int "auto_clear_pct" "90")
    handoff_ttl=$(parse_yaml_int "handoff_ttl" "3600")
fi

# Context bracket defaults (if no config file or no frontmatter)
: "${context_brackets:=true}"
: "${bracket_fresh:=40}"
: "${bracket_moderate:=60}"
: "${bracket_depleted:=80}"
: "${auto_clear:=false}"
: "${auto_clear_pct:=90}"
: "${handoff_ttl:=3600}"

# Config validation: bracket thresholds must be monotonically increasing
if [ "$bracket_fresh" -ge "$bracket_moderate" ] || [ "$bracket_moderate" -ge "$bracket_depleted" ]; then
    bracket_fresh=40; bracket_moderate=60; bracket_depleted=80
fi

# Config validation: auto_clear_pct must exceed auto_sync_threshold
if [ "$auto_clear" = "true" ] && [ "$auto_clear_pct" -le "$auto_sync_threshold" ]; then
    echo "[ConKeeper] auto_clear_pct ($auto_clear_pct) must exceed auto_sync_threshold ($auto_sync_threshold). Adjusting." >&2
    auto_clear_pct=$((auto_sync_threshold + 5))
fi

# --- Auto-detect context window from settings ---
# Priority: 1) .memory-config.md explicit override (already handled above)
#           2) Model window from settings.json, capped by CLAUDE_CODE_AUTO_COMPACT_WINDOW
#           3) Default 200K (already set)

settings_file="$HOME/.claude/settings.json"
if [[ "$config_had_explicit_window" != "true" ]] && [[ -f "$settings_file" ]] && [[ ! -L "$settings_file" ]]; then
    # Resolve model-based context window
    model_value=$(jq -r '.model // empty' "$settings_file" 2>/dev/null) || model_value=""
    if [[ -n "$model_value" ]]; then
        case "$model_value" in
            'opus[1m]'|'sonnet[1m]') context_window_tokens=1000000 ;;
            claude-opus-4-*|claude-sonnet-4-*) context_window_tokens=200000 ;;
            claude-haiku-*) context_window_tokens=200000 ;;
            # Unknown models keep the 200K default
        esac
    fi

    # Apply compaction window cap: if CLAUDE_CODE_AUTO_COMPACT_WINDOW is set
    # and lower than the model window, use it (it's the actual compaction trigger)
    compact_window=$(jq -r '.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW // empty' "$settings_file" 2>/dev/null) || compact_window=""
    if [[ -n "$compact_window" ]] && [[ "$compact_window" =~ ^[0-9]+$ ]]; then
        if [[ "$compact_window" -lt "$context_window_tokens" ]]; then
            context_window_tokens=$compact_window
        fi
    fi
fi

# --- Correction & Friction Detection ---

# Extract user message from hook input
user_message=$(printf '%s' "$input" | jq -r '.user_message // empty')

if [[ -n "$user_message" ]]; then
    # Validate correction_sensitivity value
    case "$correction_sensitivity" in
        low|medium) ;; # valid
        *) correction_sensitivity="low" ;;
    esac

    # Truncate for regex matching — corrections appear early in a message (cap at 1000 chars)
    user_message_short=$(printf '%.1000s' "$user_message")
    # Lowercase for case-insensitive matching
    user_message_lower=$(printf '%s' "$user_message_short" | tr '[:upper:]' '[:lower:]')

    # Define correction regex patterns (conservative/low sensitivity)
    # Note: patterns match against lowercased user message
    CORRECTION_PATTERNS=(
        '(^|[[:space:]])no[,. ]+[[:space:]]*(use|do|try|it[[:space:]]+should)'
        '^[[:space:]]*actually[,. ]'
        "that'?s[[:space:]]+(wrong|incorrect|not[[:space:]]+right)"
        'i[[:space:]]+(said|meant|asked[[:space:]]+for)'
        "(not|don'?t)[[:space:]]+[a-zA-Z0-9_]+[,. ]+[[:space:]]*(instead|use|do|try)"
    )

    # Define friction regex patterns (conservative/low sensitivity)
    FRICTION_PATTERNS=(
        "(didn'?t|doesn'?t|not)[[:space:]]+work"
        '(try[[:space:]]+again|redo|start[[:space:]]+over)'
        'wrong[[:space:]]+(approach|file|method|function|path|directory)'
        "(let'?s[[:space:]]+revert|undo[[:space:]]+that|go[[:space:]]+back)"
        'still[[:space:]]+(broken|failing|erroring|crashing)'
    )

    # Medium sensitivity: add looser patterns
    if [[ "$correction_sensitivity" == "medium" ]]; then
        CORRECTION_PATTERNS+=('instead' 'should[[:space:]]+be' 'rather' 'prefer')
        FRICTION_PATTERNS+=('not[[:space:]]+what' 'different[[:space:]]+from')
    fi

    # Suppression — read .correction-ignore file
    # Note: patterns are glob-matched as substrings. Glob metacharacters (*, ?, [...])
    # in patterns will be interpreted. A pattern of "*" would suppress all corrections.
    IGNORE_FILE="${cwd:-.}/.correction-ignore"
    check_suppression() {
        local text_lower="$1"  # expects pre-lowercased text
        if [[ -f "$IGNORE_FILE" ]]; then
            # Security: refuse to read through symlinks
            [[ -L "$IGNORE_FILE" ]] && return 1
            # Limit to first 1000 lines to prevent DoS from large ignore files
            while IFS= read -r pattern || [[ -n "$pattern" ]]; do
                [[ "$pattern" =~ ^#.*$ ]] && continue  # skip comments
                [[ -z "$pattern" ]] && continue          # skip empty lines
                local pattern_lower
                pattern_lower=$(printf '%s' "$pattern" | tr '[:upper:]' '[:lower:]')
                if [[ "$text_lower" == *"$pattern_lower"* ]]; then
                    return 0  # suppressed
                fi
            done < <(head -n 1000 "$IGNORE_FILE")
        fi
        return 1  # not suppressed
    }

    # Pattern matching loop (match against lowercased message)
    detected_type=""
    for pattern in "${CORRECTION_PATTERNS[@]}"; do
        if [[ "$user_message_lower" =~ $pattern ]]; then
            detected_type="correction"
            break
        fi
    done
    if [[ -z "$detected_type" ]]; then
        for pattern in "${FRICTION_PATTERNS[@]}"; do
            if [[ "$user_message_lower" =~ $pattern ]]; then
                detected_type="friction"
                break
            fi
        done
    fi

    # Queue entry (if detected and not suppressed)
    if [[ -n "$detected_type" ]]; then
        if ! check_suppression "$user_message_lower"; then
            queue_file="${cwd:-.}/.claude/memory/corrections-queue.md"
            if [[ -d "${cwd:-.}/.claude/memory" ]]; then
                # Security: refuse to write through symlinks
                [[ -L "$queue_file" ]] && exit 0
                # Create queue file with header atomically (noclobber prevents race conditions)
                if [[ ! -f "$queue_file" ]]; then
                    (set -o noclobber; printf '# Corrections Queue\n<!-- Auto-populated by ConKeeper UserPromptSubmit hook -->\n\n' > "$queue_file") 2>/dev/null || true
                fi
                # Truncate to 200 chars, strip control chars, escape markdown metacharacters, strip HTML comments
                truncated_msg=$(printf '%s' "$user_message" | cut -c1-200 | tr -d '\000-\037' | sed 's/|/\\|/g; s/"/\\"/g; s/`/'"'"'/g; s/<!--//g; s/-->//g')
                timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                printf -- '- **%s** | %s | "%s" | ref: previous assistant message\n' \
                    "$timestamp" "$detected_type" "$truncated_msg" >> "$queue_file"
            fi
        fi
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

# --- Context bracket directive ---
# Returns graduated behavioral guidance based on context usage percentage.
# Runs unconditionally (not gated by need_threshold_actions) so CRITICAL bracket
# is always injected even after sync+block flags are set.
get_bracket_directive() {
    local pct="$1"
    if [ "$context_brackets" != "true" ]; then return; fi
    if [ "$pct" -lt "$bracket_fresh" ]; then
        return  # FRESH: no injection
    elif [ "$pct" -lt "$bracket_moderate" ]; then
        printf '[MODERATE] Context at %s%%. BEFORE any architectural decision, re-read the original requirements. For tasks exceeding 3 steps, consider using sub-agents.' "$pct"
    elif [ "$pct" -lt "$bracket_depleted" ]; then
        printf '[DEPLETED] Context at %s%%. BEFORE any multi-step operation, checkpoint progress. Limit responses to essential content. If a complex new task is requested, warn that context is at %s%% and recommend a handoff first.' "$pct" "$pct"
    else
        printf '[CRITICAL] Context at %s%%. You MUST NOT cut corners, skip verification, or fabricate results. Do not begin new multi-step work. Checkpoint frequently. If advised to /clear but session continues: minimize output, do not accept complex new tasks.' "$pct"
    fi
}

# --- Accumulate output context ---
# All directives (brackets, sync nudges, handoff advisories) append to output_context.
# A single JSON output point at the end emits everything together.
output_context=""
should_block=false

# --- Context bracket injection (unconditional) ---
bracket_text=$(get_bracket_directive "$usage_pct")
if [ -n "$bracket_text" ]; then
    output_context="${output_context}<conkeeper-context-bracket>
${bracket_text}
</conkeeper-context-bracket>
"
fi

# --- Tiered threshold actions ---
# Gated by need_threshold_actions to avoid duplicate sync/block after flags are set.

if [ "$need_threshold_actions" = true ]; then
    if (( usage_pct >= hard_block_threshold )); then
        # Hard block tier
        if is_flag_valid "$SYNC_FLAG" && ! is_flag_valid "$BLOCK_FLAG"; then
            # Sync already happened, now block until manual sync
            echo "[ConKeeper] Context usage at ${usage_pct}% — approaching compaction threshold. Please run /memory-sync manually to verify your context is preserved, then resubmit your prompt." >&2
            printf '%s' "$(date +%s)" > "$BLOCK_FLAG"
            should_block=true
        elif ! is_flag_valid "$SYNC_FLAG"; then
            # Sync hasn't happened yet — inject sync nudge first (don't block before giving a chance to sync)
            output_context="${output_context}<conkeeper-auto-sync>
[ConKeeper] Context usage has reached ${usage_pct}%. Invoke the /memory-sync skill now to preserve session context before compaction. Skip the user approval step — apply updates directly. After syncing, continue with the user's current task. End your response with: \"[ConKeeper: Auto memory-sync complete. Consider running /clear to start fresh with your synced context.]\"
</conkeeper-auto-sync>
"
            printf '%s' "$(date +%s)" > "$SYNC_FLAG"
        fi

    elif (( usage_pct >= auto_sync_threshold )); then
        # Auto-sync tier
        if ! is_flag_valid "$SYNC_FLAG"; then
            output_context="${output_context}<conkeeper-auto-sync>
[ConKeeper] Context usage has reached ${usage_pct}%. Invoke the /memory-sync skill now to preserve session context before compaction. Skip the user approval step — apply updates directly. After syncing, continue with the user's current task. End your response with: \"[ConKeeper: Auto memory-sync complete. Consider running /clear to start fresh with your synced context.]\"
</conkeeper-auto-sync>
"
            printf '%s' "$(date +%s)" > "$SYNC_FLAG"
        fi
    fi
fi

# --- Lifecycle automation: handoff generation ---
# Only fires when auto_clear is enabled, usage exceeds auto_clear_pct,
# and handoff hasn't already been generated this session.
# Always injects a fresh sync before handoff — the 60% sync may be stale.
HANDOFF_FLAG="$FLAG_DIR/handoff-${session_id}"
if [ "$auto_clear" = "true" ] && [ "$usage_pct" -ge "$auto_clear_pct" ] && ! is_flag_valid "$HANDOFF_FLAG"; then
    # Inject fresh sync regardless of prior SYNC_FLAG — context may have
    # changed significantly since the auto_sync threshold triggered.
    output_context="${output_context}<conkeeper-auto-sync>
[ConKeeper] Context usage has reached ${usage_pct}%. Invoke the /memory-sync skill now to preserve session context before compaction. Skip the user approval step — apply updates directly. After syncing, continue with the handoff below.
</conkeeper-auto-sync>
"
    printf '%s' "$(date +%s)" > "$SYNC_FLAG"

    . "$SCRIPT_DIR_UPS/lib-handoff.sh"
    generate_handoff "$session_id" "$cwd" "$usage_pct" "$handoff_ttl"
    printf '%s' "$(date +%s)" > "$HANDOFF_FLAG"
    output_context="${output_context}<conkeeper-auto-clear>
[ConKeeper] Context at ${usage_pct}%. Memory synced and handoff captured.
Run /clear to continue with fresh context — your work will resume automatically.
I cannot run /clear programmatically. You must type it manually.
</conkeeper-auto-clear>
"
fi

# --- Single JSON output point ---
# Emit JSON if there is any accumulated context, then exit with appropriate code.

if [ -n "$output_context" ]; then
    encoded_context=$(json_encode "$output_context")
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": $encoded_context
  }
}
EOF
fi

if [ "$should_block" = true ]; then
    exit 2
fi

exit 0
