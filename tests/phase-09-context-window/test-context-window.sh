#!/usr/bin/env bash
# Phase 09: Context Window Auto-Detection Tests
# Run: bash tests/phase-09-context-window/test-context-window.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMPDIR_TEST="$(mktemp -d)"
PASS=0
FAIL=0

ORIG_DIR="$(pwd)"
ORIG_HOME="$HOME"

cleanup() {
  cd "$ORIG_DIR"
  HOME="$ORIG_HOME"
  rm -rf "$TMPDIR_TEST"
}
trap cleanup EXIT

pass() {
  PASS=$((PASS + 1))
  echo "PASS: $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "FAIL: $1"
}

# Helper: create a project with memory directory, transcript, and flag dir
setup_project() {
  local base="$1"
  mkdir -p "$base/.claude/memory/sessions"

  # Create a transcript with known token count for deterministic percentage calc
  local transcript="$base/transcript.jsonl"
  echo '{"type":"assistant","message":{"usage":{"input_tokens":1000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}' > "$transcript"

  # Ensure flag dir exists
  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  mkdir -p "$flag_dir"
}

setup_config() {
  local base="$1"
  local content="$2"
  cat > "$base/.claude/memory/.memory-config.md" <<CONFIGEOF
$content
CONFIGEOF
}

setup_settings_json() {
  local home_dir="$1"
  local content="$2"
  mkdir -p "$home_dir/.claude"
  printf '%s' "$content" > "$home_dir/.claude/settings.json"
}

# Helper: run the hook and capture the resolved context_window_tokens value
# We use a high token count so that the usage percentage output reveals the window size.
# With 500000 input_tokens: pct = (500000*100)/window
#   window=200000 → 250  (above any threshold)
#   window=1000000 → 50  (below default 60% threshold)
#   window=500000 → 100
get_context_window() {
  local workdir="$1"
  local fake_home="$2"
  local session_id="${3:-sess-test-09}"

  local transcript="$workdir/transcript.jsonl"
  # Write a transcript with 500000 tokens for percentage calculation
  echo '{"type":"assistant","message":{"usage":{"input_tokens":500000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}' > "$transcript"

  # Clean any existing flags
  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  rm -f "$flag_dir/synced-${session_id}" "$flag_dir/blocked-${session_id}"

  local json
  json=$(jq -n \
    --arg sid "$session_id" \
    --arg tp "$transcript" \
    --arg cwd "$workdir" \
    --arg um "test prompt" \
    '{session_id: $sid, transcript_path: $tp, cwd: $cwd, user_message: $um}')

  local output exit_code
  HOME="$fake_home" output=$(printf '%s' "$json" | bash "$REPO_ROOT/hooks/user-prompt-submit.sh" 2>/dev/null) || true
  HOME="$ORIG_HOME"

  # If window=200000 → 500000/200000 = 250% → above hard_block (80%)
  #   After sync flag set, next run would block (exit 2)
  #   First run sets sync flag and outputs JSON
  # If window=1000000 → 500000/1000000 = 50% → below auto_sync (60%)
  #   No output, exit 0
  # If window=500000 → 500000/500000 = 100% → above hard_block
  #   First run sets sync flag and outputs JSON

  # Detect by output behavior:
  # - JSON output with hookSpecificOutput → triggered auto-sync (window caused >= 60%)
  # - No output → below threshold (window is large enough that 500K tokens < 60%)
  if echo "$output" | jq -e '.hookSpecificOutput' &>/dev/null 2>&1; then
    echo "triggered"
  else
    echo "below_threshold"
  fi

  # Clean up flags
  rm -f "$flag_dir/synced-${session_id}" "$flag_dir/blocked-${session_id}"
}

# ---------------------------------------------------------------------------
# Test 1: Default (no settings, no config) → 200000
# ---------------------------------------------------------------------------
test_default_no_settings_no_config() {
  local workdir="$TMPDIR_TEST/test1"
  local fake_home="$TMPDIR_TEST/home1"
  setup_project "$workdir"
  mkdir -p "$fake_home/.claude"
  # No settings.json, no .memory-config.md

  local result
  result=$(get_context_window "$workdir" "$fake_home" "sess-09-01")

  # With 200K window: 500000/200000 = 250% → should trigger
  if [[ "$result" == "triggered" ]]; then
    pass "Test 1: Default (no settings, no config) — 200K window triggers at 250%"
  else
    fail "Test 1: Default (no settings, no config) — expected trigger at 250%"
    echo "  Result: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: Auto-detect opus 1M → 1000000
# ---------------------------------------------------------------------------
test_auto_detect_opus_1m() {
  local workdir="$TMPDIR_TEST/test2"
  local fake_home="$TMPDIR_TEST/home2"
  setup_project "$workdir"
  setup_settings_json "$fake_home" '{"model": "opus[1m]"}'

  local result
  result=$(get_context_window "$workdir" "$fake_home" "sess-09-02")

  # With 1M window: 500000/1000000 = 50% → below 60% threshold
  if [[ "$result" == "below_threshold" ]]; then
    pass "Test 2: Auto-detect opus[1m] — 1M window, 50% below threshold"
  else
    fail "Test 2: Auto-detect opus[1m] — expected below_threshold (50%)"
    echo "  Result: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: Auto-detect sonnet 1M → 1000000
# ---------------------------------------------------------------------------
test_auto_detect_sonnet_1m() {
  local workdir="$TMPDIR_TEST/test3"
  local fake_home="$TMPDIR_TEST/home3"
  setup_project "$workdir"
  setup_settings_json "$fake_home" '{"model": "sonnet[1m]"}'

  local result
  result=$(get_context_window "$workdir" "$fake_home" "sess-09-03")

  # With 1M window: 500000/1000000 = 50% → below 60% threshold
  if [[ "$result" == "below_threshold" ]]; then
    pass "Test 3: Auto-detect sonnet[1m] — 1M window, 50% below threshold"
  else
    fail "Test 3: Auto-detect sonnet[1m] — expected below_threshold (50%)"
    echo "  Result: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: Auto-detect standard opus → 200000
# ---------------------------------------------------------------------------
test_auto_detect_standard_opus() {
  local workdir="$TMPDIR_TEST/test4"
  local fake_home="$TMPDIR_TEST/home4"
  setup_project "$workdir"
  setup_settings_json "$fake_home" '{"model": "opus"}'

  local result
  result=$(get_context_window "$workdir" "$fake_home" "sess-09-04")

  # With 200K window: 500000/200000 = 250% → should trigger
  if [[ "$result" == "triggered" ]]; then
    pass "Test 4: Auto-detect standard opus — 200K window triggers"
  else
    fail "Test 4: Auto-detect standard opus — expected trigger at 250%"
    echo "  Result: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: Auto-detect haiku → 200000
# ---------------------------------------------------------------------------
test_auto_detect_haiku() {
  local workdir="$TMPDIR_TEST/test5"
  local fake_home="$TMPDIR_TEST/home5"
  setup_project "$workdir"
  setup_settings_json "$fake_home" '{"model": "haiku"}'

  local result
  result=$(get_context_window "$workdir" "$fake_home" "sess-09-05")

  # With 200K window: 500000/200000 = 250% → should trigger
  if [[ "$result" == "triggered" ]]; then
    pass "Test 5: Auto-detect haiku — 200K window triggers"
  else
    fail "Test 5: Auto-detect haiku — expected trigger at 250%"
    echo "  Result: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: Explicit config override wins over auto-detect
# ---------------------------------------------------------------------------
test_explicit_config_override() {
  local workdir="$TMPDIR_TEST/test6"
  local fake_home="$TMPDIR_TEST/home6"
  setup_project "$workdir"
  setup_settings_json "$fake_home" '{"model": "opus[1m]"}'
  setup_config "$workdir" "---
context_window_tokens: 500000
---"

  local result
  result=$(get_context_window "$workdir" "$fake_home" "sess-09-06")

  # With 500K window: 500000/500000 = 100% → should trigger (above 80%)
  # If auto-detect won, it would be 1M → 50% → below threshold
  if [[ "$result" == "triggered" ]]; then
    pass "Test 6: Explicit config override (500K) wins over auto-detect (1M)"
  else
    fail "Test 6: Explicit config override should win — expected trigger at 100%"
    echo "  Result: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: Malformed settings.json → fallback to 200000
# ---------------------------------------------------------------------------
test_malformed_settings_json() {
  local workdir="$TMPDIR_TEST/test7"
  local fake_home="$TMPDIR_TEST/home7"
  setup_project "$workdir"
  mkdir -p "$fake_home/.claude"
  printf '%s' 'not valid json {{{' > "$fake_home/.claude/settings.json"

  local result
  result=$(get_context_window "$workdir" "$fake_home" "sess-09-07")

  # Malformed JSON → jq fails → fallback to 200K → 250% → triggers
  if [[ "$result" == "triggered" ]]; then
    pass "Test 7: Malformed settings.json — graceful fallback to 200K"
  else
    fail "Test 7: Malformed settings.json — expected fallback trigger at 250%"
    echo "  Result: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: Missing model field → fallback to 200000
# ---------------------------------------------------------------------------
test_missing_model_field() {
  local workdir="$TMPDIR_TEST/test8"
  local fake_home="$TMPDIR_TEST/home8"
  setup_project "$workdir"
  setup_settings_json "$fake_home" '{}'

  local result
  result=$(get_context_window "$workdir" "$fake_home" "sess-09-08")

  # Empty object → model is empty → fallback to 200K → 250% → triggers
  if [[ "$result" == "triggered" ]]; then
    pass "Test 8: Missing model field — graceful fallback to 200K"
  else
    fail "Test 8: Missing model field — expected fallback trigger at 250%"
    echo "  Result: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 9: Symlink settings.json is skipped (security)
# ---------------------------------------------------------------------------
test_symlink_settings_json() {
  local workdir="$TMPDIR_TEST/test9"
  local fake_home="$TMPDIR_TEST/home9"
  setup_project "$workdir"

  # Create a real settings file in a separate location
  local real_settings="$TMPDIR_TEST/real_settings.json"
  printf '%s' '{"model": "opus[1m]"}' > "$real_settings"

  # Create a symlink to it
  mkdir -p "$fake_home/.claude"
  ln -s "$real_settings" "$fake_home/.claude/settings.json"

  local result
  result=$(get_context_window "$workdir" "$fake_home" "sess-09-09")

  # Symlink should be skipped → fallback to 200K → 250% → triggers
  if [[ "$result" == "triggered" ]]; then
    pass "Test 9: Symlink settings.json is skipped — fallback to 200K"
  else
    fail "Test 9: Symlink settings.json should be skipped — expected fallback trigger"
    echo "  Result: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 10: Unknown model value → fallback to 200000
# ---------------------------------------------------------------------------
test_unknown_model_value() {
  local workdir="$TMPDIR_TEST/test10"
  local fake_home="$TMPDIR_TEST/home10"
  setup_project "$workdir"
  setup_settings_json "$fake_home" '{"model": "future-model[2m]"}'

  local result
  result=$(get_context_window "$workdir" "$fake_home" "sess-09-10")

  # Unknown model [2m] → not matched by [1m] case → fallback to 200K → 250% → triggers
  if [[ "$result" == "triggered" ]]; then
    pass "Test 10: Unknown model value (future-model[2m]) — fallback to 200K"
  else
    fail "Test 10: Unknown model value — expected fallback trigger at 250%"
    echo "  Result: $result"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 09: Context Window Auto-Detection Tests ==="
echo ""

test_default_no_settings_no_config
test_auto_detect_opus_1m
test_auto_detect_sonnet_1m
test_auto_detect_standard_opus
test_auto_detect_haiku
test_explicit_config_override
test_malformed_settings_json
test_missing_model_field
test_symlink_settings_json
test_unknown_model_value

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
