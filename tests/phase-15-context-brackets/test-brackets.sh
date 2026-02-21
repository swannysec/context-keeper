#!/usr/bin/env bash
# Phase 15: Context Bracket Tests
# Run: bash tests/phase-15-context-brackets/test-brackets.sh

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

# Helper: create a project with known token count for deterministic percentage
setup_project() {
  local base="$1"
  local tokens="$2"
  local config_extra="${3:-}"
  mkdir -p "$base/.claude/memory/sessions"

  # Transcript with specified token count
  local transcript="$base/transcript.jsonl"
  printf '{"type":"assistant","message":{"usage":{"input_tokens":%s,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}\n' "$tokens" > "$transcript"

  # Config with explicit 200K window so auto-detect doesn't interfere
  cat > "$base/.claude/memory/.memory-config.md" <<CONF
---
context_window_tokens: 200000
${config_extra}
---
CONF

  # Ensure flag dir and fake HOME
  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  mkdir -p "$flag_dir"
  mkdir -p "$TMPDIR_TEST/fakehome/.claude"
  printf '{}' > "$TMPDIR_TEST/fakehome/.claude/settings.json"
}

# Helper: run user-prompt-submit with given setup
run_hook() {
  local workdir="$1"
  local session_id="$2"

  local transcript="$workdir/transcript.jsonl"
  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  rm -f "$flag_dir/synced-${session_id}" "$flag_dir/blocked-${session_id}" "$flag_dir/handoff-${session_id}"

  local json
  json=$(jq -n \
    --arg sid "$session_id" \
    --arg tp "$transcript" \
    --arg cwd "$workdir" \
    --arg um "test prompt" \
    '{session_id: $sid, transcript_path: $tp, cwd: $cwd, user_message: $um}')

  (export HOME="$TMPDIR_TEST/fakehome"; printf '%s' "$json" | bash "$REPO_ROOT/hooks/user-prompt-submit.sh" 2>/dev/null) || true
}

# Helper: run hook with pre-set flags
run_hook_with_flags() {
  local workdir="$1"
  local session_id="$2"
  local set_sync="${3:-false}"
  local set_block="${4:-false}"

  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  rm -f "$flag_dir/synced-${session_id}" "$flag_dir/blocked-${session_id}" "$flag_dir/handoff-${session_id}"

  if [ "$set_sync" = true ]; then
    printf '%s' "$(date +%s)" > "$flag_dir/synced-${session_id}"
  fi
  if [ "$set_block" = true ]; then
    printf '%s' "$(date +%s)" > "$flag_dir/blocked-${session_id}"
  fi

  local transcript="$workdir/transcript.jsonl"
  local json
  json=$(jq -n \
    --arg sid "$session_id" \
    --arg tp "$transcript" \
    --arg cwd "$workdir" \
    --arg um "test prompt" \
    '{session_id: $sid, transcript_path: $tp, cwd: $cwd, user_message: $um}')

  (export HOME="$TMPDIR_TEST/fakehome"; printf '%s' "$json" | bash "$REPO_ROOT/hooks/user-prompt-submit.sh" 2>/dev/null) || true
}

# ---------------------------------------------------------------------------
# Test 1: FRESH (30%) — no bracket in output
# ---------------------------------------------------------------------------
test_fresh_no_bracket() {
  local base="$TMPDIR_TEST/t1"
  # 30% of 200K = 60000 tokens
  setup_project "$base" 60000
  local output
  output=$(run_hook "$base" "sess-br-01")

  if printf '%s' "$output" | grep -q "conkeeper-context-bracket"; then
    fail "Test 1: FRESH (30%) should have no bracket"
  else
    pass "Test 1: FRESH (30%) — no bracket injected"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: MODERATE (50%) — bracket injected, no sync
# ---------------------------------------------------------------------------
test_moderate_bracket() {
  local base="$TMPDIR_TEST/t2"
  # 50% of 200K = 100000 tokens
  setup_project "$base" 100000
  local output
  output=$(run_hook "$base" "sess-br-02")

  if printf '%s' "$output" | grep -q '\[MODERATE\]'; then
    pass "Test 2: MODERATE (50%) — bracket injected"
  else
    fail "Test 2: MODERATE (50%) — bracket missing"
    echo "  Output: $output"
  fi

  # Should NOT trigger sync (below 60%)
  if printf '%s' "$output" | grep -q "conkeeper-auto-sync"; then
    fail "Test 2b: MODERATE (50%) should not trigger sync"
  else
    pass "Test 2b: MODERATE (50%) — no sync trigger"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: DEPLETED (70%) — bracket + sync nudge co-emitted
# ---------------------------------------------------------------------------
test_depleted_with_sync() {
  local base="$TMPDIR_TEST/t3"
  # 70% of 200K = 140000 tokens
  setup_project "$base" 140000
  local output
  output=$(run_hook "$base" "sess-br-03")

  if printf '%s' "$output" | grep -q '\[DEPLETED\]'; then
    pass "Test 3a: DEPLETED (70%) — bracket injected"
  else
    fail "Test 3a: DEPLETED (70%) — bracket missing"
  fi

  if printf '%s' "$output" | grep -q "conkeeper-auto-sync"; then
    pass "Test 3b: DEPLETED (70%) — sync nudge co-emitted"
  else
    fail "Test 3b: DEPLETED (70%) — sync nudge missing"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: CRITICAL (85%) — bracket + block co-emitted
# ---------------------------------------------------------------------------
test_critical_with_block() {
  local base="$TMPDIR_TEST/t4"
  # 85% of 200K = 170000 tokens
  setup_project "$base" 170000

  # First run: sets sync flag, emits sync nudge + CRITICAL bracket
  local output1
  output1=$(run_hook "$base" "sess-br-04")

  if printf '%s' "$output1" | grep -q '\[CRITICAL\]'; then
    pass "Test 4a: CRITICAL (85%) — bracket injected on first run"
  else
    fail "Test 4a: CRITICAL (85%) — bracket missing on first run"
  fi

  # Second run: sync flag set, should block (exit 2) + still emit CRITICAL bracket
  local output2
  output2=$(run_hook_with_flags "$base" "sess-br-04b" true false)

  if printf '%s' "$output2" | grep -q '\[CRITICAL\]'; then
    pass "Test 4b: CRITICAL (85%) — bracket injected alongside block"
  else
    fail "Test 4b: CRITICAL (85%) — bracket missing alongside block"
    echo "  Output: $output2"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: CRITICAL post-flags (85%, both flags set) — bracket STILL fires
# ---------------------------------------------------------------------------
test_critical_post_flags() {
  local base="$TMPDIR_TEST/t5"
  # 85% of 200K = 170000 tokens
  setup_project "$base" 170000

  # Both flags pre-set: need_threshold_actions=false, but bracket is unconditional
  local output
  output=$(run_hook_with_flags "$base" "sess-br-05" true true)

  if printf '%s' "$output" | grep -q '\[CRITICAL\]'; then
    pass "Test 5: CRITICAL post-flags — bracket STILL fires (Phase 0 validation)"
  else
    fail "Test 5: CRITICAL post-flags — bracket should fire even with both flags set"
    echo "  Output: $output"
  fi

  # Should NOT have sync nudge (flags already set)
  if printf '%s' "$output" | grep -q "conkeeper-auto-sync"; then
    fail "Test 5b: Post-flags should not re-trigger sync"
  else
    pass "Test 5b: Post-flags — no duplicate sync"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: Brackets disabled — no bracket at any tier
# ---------------------------------------------------------------------------
test_brackets_disabled() {
  local base="$TMPDIR_TEST/t6"
  # 85% = CRITICAL tier normally
  setup_project "$base" 170000 "context_brackets: false"
  local output
  output=$(run_hook_with_flags "$base" "sess-br-06" true true)

  if printf '%s' "$output" | grep -q "conkeeper-context-bracket"; then
    fail "Test 6: Brackets disabled — should not inject any bracket"
  else
    pass "Test 6: Brackets disabled — no bracket at any tier"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: Custom thresholds — shifted bracket boundaries
# ---------------------------------------------------------------------------
test_custom_thresholds() {
  local base="$TMPDIR_TEST/t7"
  # 25% of 200K = 50000 tokens. With bracket_fresh=20, 25% should be MODERATE
  setup_project "$base" 50000 "bracket_fresh: 20"
  local output
  output=$(run_hook "$base" "sess-br-07")

  if printf '%s' "$output" | grep -q '\[MODERATE\]'; then
    pass "Test 7: Custom thresholds — bracket_fresh=20 shifts MODERATE start"
  else
    fail "Test 7: Custom thresholds — expected MODERATE at 25% with bracket_fresh=20"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: Valid JSON output when bracket is present
# ---------------------------------------------------------------------------
test_bracket_valid_json() {
  local base="$TMPDIR_TEST/t8"
  # 50% = MODERATE bracket
  setup_project "$base" 100000
  local output
  output=$(run_hook "$base" "sess-br-08")

  if printf '%s' "$output" | jq . > /dev/null 2>&1; then
    pass "Test 8: Bracket output is valid JSON"
  else
    fail "Test 8: Bracket output is NOT valid JSON"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 15: Context Bracket Tests ==="
echo ""

test_fresh_no_bracket
test_moderate_bracket
test_depleted_with_sync
test_critical_with_block
test_critical_post_flags
test_brackets_disabled
test_custom_thresholds
test_bracket_valid_json

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
