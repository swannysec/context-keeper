#!/usr/bin/env bash
# Phase 15: Context Bracket Tests (two-tier: WARN >= 85%, CRITICAL >= 95%)
# Run: bash tests/phase-15-context-brackets/test-brackets.sh
#
# Two active tiers, keyed to bracket_warn (default 85) and bracket_critical (95):
#   pct < 85        → silent (no bracket)
#   85 <= pct < 95  → [WARN]     (agent warns the user; suggests handoff/sync)
#   pct >= 95       → [CRITICAL] (brevity; no new multi-step work)

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

# Explicit 200K window so bracket percentages are deterministic and
# independent of model auto-detection.
setup_project() {
  local base="$1"
  local tokens="$2"
  local config_extra="${3:-}"
  mkdir -p "$base/.claude/memory/sessions"

  local transcript="$base/transcript.jsonl"
  printf '{"type":"assistant","message":{"usage":{"input_tokens":%s,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}\n' "$tokens" > "$transcript"

  cat > "$base/.claude/memory/.memory-config.md" <<CONF
---
context_window_tokens: 200000
${config_extra}
---
CONF

  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  mkdir -p "$flag_dir"
  mkdir -p "$TMPDIR_TEST/fakehome/.claude"
  printf '{}' > "$TMPDIR_TEST/fakehome/.claude/settings.json"
}

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

run_hook_with_flags() {
  local workdir="$1"
  local session_id="$2"
  local set_sync="${3:-false}"
  local set_block="${4:-false}"

  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  rm -f "$flag_dir/synced-${session_id}" "$flag_dir/blocked-${session_id}" "$flag_dir/handoff-${session_id}"
  [ "$set_sync" = true ] && printf '%s' "$(date +%s)" > "$flag_dir/synced-${session_id}"
  [ "$set_block" = true ] && printf '%s' "$(date +%s)" > "$flag_dir/blocked-${session_id}"

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

# 1: 60% — silent (well below warn)
test_silent_below_warn() {
  local base="$TMPDIR_TEST/t1"
  setup_project "$base" 120000   # 60%
  local output; output=$(run_hook "$base" "sess-br-01")
  if printf '%s' "$output" | grep -q "conkeeper-context-bracket"; then
    fail "Test 1: 60% should be silent (no bracket)"
    echo "  Output: $output"
  else
    pass "Test 1: 60% — silent, no bracket"
  fi
}

# 2: 84% — still silent (just under warn boundary)
test_silent_just_below_warn() {
  local base="$TMPDIR_TEST/t2"
  setup_project "$base" 168000   # 84%
  local output; output=$(run_hook "$base" "sess-br-02")
  if printf '%s' "$output" | grep -q "conkeeper-context-bracket"; then
    fail "Test 2: 84% should still be silent (below 85% warn)"
    echo "  Output: $output"
  else
    pass "Test 2: 84% — silent (below warn boundary)"
  fi
}

# 3: 85% — WARN boundary (inclusive)
test_warn_boundary() {
  local base="$TMPDIR_TEST/t3"
  setup_project "$base" 170000   # 85%
  local output; output=$(run_hook "$base" "sess-br-03")
  if printf '%s' "$output" | grep -q '\[WARN\]'; then
    pass "Test 3: 85% — [WARN] fires at boundary"
  else
    fail "Test 3: 85% — expected [WARN]"
    echo "  Output: $output"
  fi
}

# 4: 90% — WARN, and memory-sync nudge co-emitted (auto_sync default 85)
test_warn_with_sync() {
  local base="$TMPDIR_TEST/t4"
  setup_project "$base" 180000   # 90%
  local output; output=$(run_hook "$base" "sess-br-04")
  if printf '%s' "$output" | grep -q '\[WARN\]'; then
    pass "Test 4a: 90% — [WARN] bracket injected"
  else
    fail "Test 4a: 90% — [WARN] missing"
    echo "  Output: $output"
  fi
  if printf '%s' "$output" | grep -q "conkeeper-auto-sync"; then
    pass "Test 4b: 90% — memory-sync nudge co-emitted at warn tier"
  else
    fail "Test 4b: 90% — sync nudge missing"
  fi
}

# 5: 98% — CRITICAL + sync nudge
test_critical_with_sync() {
  local base="$TMPDIR_TEST/t5"
  setup_project "$base" 196000   # 98%
  local output; output=$(run_hook "$base" "sess-br-05")
  if printf '%s' "$output" | grep -q '\[CRITICAL\]'; then
    pass "Test 5a: 98% — [CRITICAL] bracket injected"
  else
    fail "Test 5a: 98% — [CRITICAL] missing"
    echo "  Output: $output"
  fi
  if printf '%s' "$output" | grep -q "conkeeper-auto-sync"; then
    pass "Test 5b: 98% — sync nudge co-emitted"
  else
    fail "Test 5b: 98% — sync nudge missing"
  fi
}

# 6: 98% — CRITICAL still fires alongside a block (second run, sync flag set)
test_critical_with_block() {
  local base="$TMPDIR_TEST/t6"
  setup_project "$base" 196000   # 98%
  local output; output=$(run_hook_with_flags "$base" "sess-br-06" true false)
  if printf '%s' "$output" | grep -q '\[CRITICAL\]'; then
    pass "Test 6: 98% — [CRITICAL] fires alongside block"
  else
    fail "Test 6: 98% — [CRITICAL] missing alongside block"
    echo "  Output: $output"
  fi
}

# 7: 98% post-flags (both set) — CRITICAL STILL fires; no duplicate sync
test_critical_post_flags() {
  local base="$TMPDIR_TEST/t7"
  setup_project "$base" 196000   # 98%
  local output; output=$(run_hook_with_flags "$base" "sess-br-07" true true)
  if printf '%s' "$output" | grep -q '\[CRITICAL\]'; then
    pass "Test 7a: 98% post-flags — [CRITICAL] still fires (unconditional bracket)"
  else
    fail "Test 7a: 98% post-flags — [CRITICAL] should fire even with both flags"
    echo "  Output: $output"
  fi
  if printf '%s' "$output" | grep -q "conkeeper-auto-sync"; then
    fail "Test 7b: post-flags should not re-trigger sync"
  else
    pass "Test 7b: post-flags — no duplicate sync"
  fi
}

# 8: brackets disabled — no bracket even at CRITICAL tier
test_brackets_disabled() {
  local base="$TMPDIR_TEST/t8"
  setup_project "$base" 196000 "context_brackets: false"   # 98%
  local output; output=$(run_hook_with_flags "$base" "sess-br-08" true true)
  if printf '%s' "$output" | grep -q "conkeeper-context-bracket"; then
    fail "Test 8: brackets disabled — should inject no bracket"
    echo "  Output: $output"
  else
    pass "Test 8: brackets disabled — no bracket at any tier"
  fi
}

# 9: custom bracket_warn=50 shifts the WARN start down
test_custom_warn_threshold() {
  local base="$TMPDIR_TEST/t9"
  setup_project "$base" 120000 "bracket_warn: 50"   # 60% → WARN when warn=50
  local output; output=$(run_hook "$base" "sess-br-09")
  if printf '%s' "$output" | grep -q '\[WARN\]'; then
    pass "Test 9: custom bracket_warn=50 — [WARN] at 60%"
  else
    fail "Test 9: custom bracket_warn=50 — expected [WARN] at 60%"
    echo "  Output: $output"
  fi
}

# 10: bracket output is valid JSON
test_bracket_valid_json() {
  local base="$TMPDIR_TEST/t10"
  setup_project "$base" 180000   # 90% → WARN
  local output; output=$(run_hook "$base" "sess-br-10")
  if printf '%s' "$output" | jq . > /dev/null 2>&1; then
    pass "Test 10: bracket output is valid JSON"
  else
    fail "Test 10: bracket output is NOT valid JSON"
    echo "  Output: $output"
  fi
}

echo "=== Phase 15: Context Bracket Tests (two-tier) ==="
echo ""

test_silent_below_warn
test_silent_just_below_warn
test_warn_boundary
test_warn_with_sync
test_critical_with_sync
test_critical_with_block
test_critical_post_flags
test_brackets_disabled
test_custom_warn_threshold
test_bracket_valid_json

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
