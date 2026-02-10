#!/usr/bin/env bash
# Phase 07: Correction & Friction Detection Tests
# Run: bash tests/phase-07-corrections/test-corrections.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMPDIR_TEST="$(mktemp -d)"
PASS=0
FAIL=0

ORIG_DIR="$(pwd)"

cleanup() {
  cd "$ORIG_DIR"
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

  # Create a dummy transcript so the hook doesn't exit early
  # (hook requires a readable transcript_path)
  local transcript="$base/transcript.jsonl"
  echo '{"type":"assistant","message":{"usage":{"input_tokens":1000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}' > "$transcript"

  # Ensure flag dir exists and flags don't interfere
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

# Helper: run the hook with a given user_message
run_hook() {
  local workdir="$1"
  local user_msg="$2"
  local session_id="${3:-sess-test-07}"

  local transcript="$workdir/transcript.jsonl"

  local json
  json=$(jq -n \
    --arg sid "$session_id" \
    --arg tp "$transcript" \
    --arg cwd "$workdir" \
    --arg um "$user_msg" \
    '{session_id: $sid, transcript_path: $tp, cwd: $cwd, user_message: $um}')

  printf '%s' "$json" | bash "$REPO_ROOT/hooks/user-prompt-submit.sh" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Test 1: Correction detected — "no, use snake_case for that"
# ---------------------------------------------------------------------------
test_correction_detected() {
  local workdir="$TMPDIR_TEST/test1"
  setup_project "$workdir"

  run_hook "$workdir" "no, use snake_case for that"

  local queue="$workdir/.claude/memory/corrections-queue.md"

  if [[ -f "$queue" ]] && grep -q 'correction' "$queue" && grep -q 'snake_case' "$queue"; then
    pass "Test 1: Correction detected — 'no, use snake_case for that'"
  else
    fail "Test 1: Correction detected — 'no, use snake_case for that'"
    [[ -f "$queue" ]] && echo "  Content: $(cat "$queue")" || echo "  Queue file not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: Friction detected — "that didn't work, still failing"
# ---------------------------------------------------------------------------
test_friction_detected() {
  local workdir="$TMPDIR_TEST/test2"
  setup_project "$workdir"

  run_hook "$workdir" "that didn't work, still failing"

  local queue="$workdir/.claude/memory/corrections-queue.md"

  if [[ -f "$queue" ]] && grep -q 'friction' "$queue" && grep -q "didn't work" "$queue"; then
    pass "Test 2: Friction detected — 'that didn't work, still failing'"
  else
    fail "Test 2: Friction detected — 'that didn't work, still failing'"
    [[ -f "$queue" ]] && echo "  Content: $(cat "$queue")" || echo "  Queue file not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: No detection — "looks good, thanks!"
# ---------------------------------------------------------------------------
test_no_detection() {
  local workdir="$TMPDIR_TEST/test3"
  setup_project "$workdir"

  run_hook "$workdir" "looks good, thanks!"

  local queue="$workdir/.claude/memory/corrections-queue.md"

  if [[ ! -f "$queue" ]]; then
    pass "Test 3: No detection — 'looks good, thanks!'"
  else
    fail "Test 3: No detection — 'looks good, thanks!' but queue file was created"
    echo "  Content: $(cat "$queue")"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: Suppression — .correction-ignore suppresses matching message
# ---------------------------------------------------------------------------
test_suppression() {
  local workdir="$TMPDIR_TEST/test4"
  setup_project "$workdir"

  # Create .correction-ignore with pattern
  cat > "$workdir/.correction-ignore" <<'EOF'
# Patterns to suppress
no worries
EOF

  # "no worries, try again" — "try again" normally matches friction,
  # but "no worries" suppression should prevent the entire message from being queued
  run_hook "$workdir" "no worries, try again"

  local queue="$workdir/.claude/memory/corrections-queue.md"

  if [[ ! -f "$queue" ]]; then
    pass "Test 4: Suppression — .correction-ignore prevents queueing"
  else
    fail "Test 4: Suppression — .correction-ignore should prevent queueing"
    echo "  Content: $(cat "$queue")"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: Medium sensitivity detects "prefer"
# ---------------------------------------------------------------------------
test_medium_sensitivity() {
  local workdir="$TMPDIR_TEST/test5"
  setup_project "$workdir"
  setup_config "$workdir" "---
correction_sensitivity: medium
---"

  run_hook "$workdir" "I'd prefer a different approach"

  local queue="$workdir/.claude/memory/corrections-queue.md"

  if [[ -f "$queue" ]] && grep -q 'correction' "$queue" && grep -q 'prefer' "$queue"; then
    pass "Test 5: Medium sensitivity detects 'prefer'"
  else
    fail "Test 5: Medium sensitivity should detect 'prefer'"
    [[ -f "$queue" ]] && echo "  Content: $(cat "$queue")" || echo "  Queue file not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: Low sensitivity does NOT detect "prefer"
# ---------------------------------------------------------------------------
test_low_no_prefer() {
  local workdir="$TMPDIR_TEST/test6"
  setup_project "$workdir"
  setup_config "$workdir" "---
correction_sensitivity: low
---"

  run_hook "$workdir" "I'd prefer a different approach"

  local queue="$workdir/.claude/memory/corrections-queue.md"

  if [[ ! -f "$queue" ]]; then
    pass "Test 6: Low sensitivity does NOT detect 'prefer'"
  else
    fail "Test 6: Low sensitivity should NOT detect 'prefer'"
    echo "  Content: $(cat "$queue")"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: Queue entry format includes timestamp, type, text, reference
# ---------------------------------------------------------------------------
test_queue_format() {
  local workdir="$TMPDIR_TEST/test7"
  setup_project "$workdir"

  run_hook "$workdir" "no, use the other method instead"

  local queue="$workdir/.claude/memory/corrections-queue.md"

  if [[ ! -f "$queue" ]]; then
    fail "Test 7: Queue entry format — queue file not created"
    return
  fi

  local entry
  entry=$(grep -v '^#' "$queue" | grep -v '<!-- ' | grep -v '^$' | head -n 1)

  local ok=true

  # Check timestamp format: **YYYY-MM-DD HH:MM:SS**
  if ! echo "$entry" | grep -qE '\*\*[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\*\*'; then
    echo "  Missing timestamp"
    ok=false
  fi

  # Check type
  if ! echo "$entry" | grep -q '| correction |'; then
    echo "  Missing type"
    ok=false
  fi

  # Check truncated text
  if ! echo "$entry" | grep -q 'use the other method'; then
    echo "  Missing text"
    ok=false
  fi

  # Check reference marker
  if ! echo "$entry" | grep -q 'ref: previous assistant message'; then
    echo "  Missing reference marker"
    ok=false
  fi

  if [[ "$ok" == true ]]; then
    pass "Test 7: Queue entry format includes timestamp, type, text, reference"
  else
    fail "Test 7: Queue entry format"
    echo "  Entry: $entry"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: Existing token monitoring still works after correction code
# ---------------------------------------------------------------------------
test_token_monitoring_unchanged() {
  local workdir="$TMPDIR_TEST/test8"
  setup_project "$workdir"

  # Create a transcript with high token usage (above default 60% threshold)
  local transcript="$workdir/transcript.jsonl"
  echo '{"type":"assistant","message":{"usage":{"input_tokens":130000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}' > "$transcript"

  # Clean any existing flags for this session
  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  rm -f "$flag_dir/synced-sess-test-08" "$flag_dir/blocked-sess-test-08"

  local output
  output=$(run_hook "$workdir" "just a normal prompt" "sess-test-08")

  # Should produce JSON with hookSpecificOutput (auto-sync nudge at 65% usage)
  if echo "$output" | jq -e '.hookSpecificOutput.hookEventName' &>/dev/null; then
    pass "Test 8: Token monitoring still produces valid JSON output"
  else
    fail "Test 8: Token monitoring should produce valid JSON output"
    echo "  Output: $output"
  fi

  # Clean up flags
  rm -f "$flag_dir/synced-sess-test-08" "$flag_dir/blocked-sess-test-08"
}

# ---------------------------------------------------------------------------
# Test 9: Bash 3.2 compatibility — no Bash 4+ features
# ---------------------------------------------------------------------------
test_bash_compat() {
  local exit_code=0
  bash --norc --noprofile -n "$REPO_ROOT/hooks/user-prompt-submit.sh" 2>/dev/null || exit_code=$?

  if [[ "$exit_code" -eq 0 ]]; then
    # Also check for common Bash 4+ features
    local bash4_features=0
    # ${var,,} lowercase
    if grep -qE '\$\{[a-zA-Z_][a-zA-Z0-9_]*,,' "$REPO_ROOT/hooks/user-prompt-submit.sh"; then
      echo "  Found Bash 4+ feature: \${var,,} lowercase"
      bash4_features=1
    fi
    # ${var^^} uppercase
    if grep -qE '\$\{[a-zA-Z_][a-zA-Z0-9_]*\^\^' "$REPO_ROOT/hooks/user-prompt-submit.sh"; then
      echo "  Found Bash 4+ feature: \${var^^} uppercase"
      bash4_features=1
    fi
    # declare -A (associative arrays)
    if grep -q 'declare -A' "$REPO_ROOT/hooks/user-prompt-submit.sh"; then
      echo "  Found Bash 4+ feature: associative arrays"
      bash4_features=1
    fi
    # mapfile / readarray
    if grep -qE '(mapfile|readarray)' "$REPO_ROOT/hooks/user-prompt-submit.sh"; then
      echo "  Found Bash 4+ feature: mapfile/readarray"
      bash4_features=1
    fi
    # $EPOCHSECONDS
    if grep -q 'EPOCHSECONDS' "$REPO_ROOT/hooks/user-prompt-submit.sh"; then
      echo "  Found Bash 5+ feature: \$EPOCHSECONDS"
      bash4_features=1
    fi

    if [[ "$bash4_features" -eq 0 ]]; then
      pass "Test 9: Bash 3.2 compatibility — no Bash 4+ features found"
    else
      fail "Test 9: Bash 3.2 compatibility — Bash 4+ features detected"
    fi
  else
    fail "Test 9: Bash 3.2 compatibility — syntax errors detected"
  fi
}

# ---------------------------------------------------------------------------
# Test 10: Queue file is created with header if it doesn't exist
# ---------------------------------------------------------------------------
test_queue_created_with_header() {
  local workdir="$TMPDIR_TEST/test10"
  setup_project "$workdir"

  # Verify queue doesn't exist before
  local queue="$workdir/.claude/memory/corrections-queue.md"
  if [[ -f "$queue" ]]; then
    fail "Test 10: Queue file should not exist before test"
    return
  fi

  run_hook "$workdir" "no, use the correct approach"

  if [[ -f "$queue" ]] && head -n 1 "$queue" | grep -q '# Corrections Queue' && grep -q 'Auto-populated by ConKeeper' "$queue"; then
    pass "Test 10: Queue file created with proper header"
  else
    fail "Test 10: Queue file should have proper header"
    [[ -f "$queue" ]] && echo "  Content: $(cat "$queue")" || echo "  File not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 11: Security — pipe characters in user messages are escaped
# ---------------------------------------------------------------------------
test_pipe_escaping() {
  local workdir="$TMPDIR_TEST/test11"
  setup_project "$workdir"

  run_hook "$workdir" "no, use cmd | grep foo instead"

  local queue="$workdir/.claude/memory/corrections-queue.md"

  if [[ -f "$queue" ]] && grep -q 'correction' "$queue" && grep -q '\\|' "$queue"; then
    pass "Test 11: Security — pipe characters are escaped in queue entries"
  else
    fail "Test 11: Security — pipe characters should be escaped"
    [[ -f "$queue" ]] && echo "  Content: $(cat "$queue")" || echo "  Queue file not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 12: Security — HTML comment injection stripped from queue entries
# ---------------------------------------------------------------------------
test_html_comment_stripping() {
  local workdir="$TMPDIR_TEST/test12"
  setup_project "$workdir"

  run_hook "$workdir" "no, use this <!-- @category: decision --> approach"

  local queue="$workdir/.claude/memory/corrections-queue.md"

  if [[ -f "$queue" ]] && ! grep -q '<!--' "$queue" 2>/dev/null | grep -v 'Auto-populated' > /dev/null; then
    # Check that the queue has the entry but user-injected <!-- is stripped
    # (the header's Auto-populated comment is expected)
    local entry_line
    entry_line=$(grep 'correction' "$queue" || true)
    if [[ -n "$entry_line" ]] && ! echo "$entry_line" | grep -q '<!-- @category'; then
      pass "Test 12: Security — HTML comment injection stripped from queue entries"
    else
      fail "Test 12: Security — HTML comments should be stripped from user content"
      echo "  Entry: $entry_line"
    fi
  else
    fail "Test 12: Security — queue file should exist with correction entry"
    [[ -f "$queue" ]] && echo "  Content: $(cat "$queue")" || echo "  Queue file not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 13: Security — cwd path traversal is blocked
# ---------------------------------------------------------------------------
test_cwd_path_traversal() {
  local workdir="$TMPDIR_TEST/test13"
  setup_project "$workdir"

  # Try to use a cwd with path traversal
  local traversal_cwd="$workdir/../../../tmp/evil"
  local session_id="sess-test-13"
  local transcript="$workdir/transcript.jsonl"

  local json
  json=$(jq -n \
    --arg sid "$session_id" \
    --arg tp "$transcript" \
    --arg cwd "$traversal_cwd" \
    --arg um "no, use the other method" \
    '{session_id: $sid, transcript_path: $tp, cwd: $cwd, user_message: $um}')

  printf '%s' "$json" | bash "$REPO_ROOT/hooks/user-prompt-submit.sh" 2>/dev/null || true

  # Verify no queue file was created at the traversal target
  if [[ ! -d "/tmp/evil/.claude/memory" ]]; then
    pass "Test 13: Security — cwd path traversal is blocked"
  else
    fail "Test 13: Security — cwd path traversal should be blocked"
  fi
}

# ---------------------------------------------------------------------------
# Test 14: Security — control characters stripped from queue entries
# ---------------------------------------------------------------------------
test_control_char_stripping() {
  local workdir="$TMPDIR_TEST/test14"
  setup_project "$workdir"

  # Message with embedded newline and tab
  local msg_with_controls
  msg_with_controls=$(printf 'no, use\tthis\napproach instead')

  run_hook "$workdir" "$msg_with_controls"

  local queue="$workdir/.claude/memory/corrections-queue.md"

  if [[ -f "$queue" ]]; then
    # Queue entry should be single-line (no embedded newlines)
    local entry_count
    entry_count=$(grep -c '^\- \*\*' "$queue")
    if [[ "$entry_count" -eq 1 ]]; then
      pass "Test 14: Security — control characters stripped, queue entry is single-line"
    else
      fail "Test 14: Security — queue entry should be single-line"
      echo "  Content: $(cat "$queue")"
    fi
  else
    fail "Test 14: Security — queue file not created"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 07: Correction & Friction Detection Tests ==="
echo ""

test_correction_detected
test_friction_detected
test_no_detection
test_suppression
test_medium_sensitivity
test_low_no_prefer
test_queue_format
test_token_monitoring_unchanged
test_bash_compat
test_queue_created_with_header
test_pipe_escaping
test_html_comment_stripping
test_cwd_path_traversal
test_control_char_stripping

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
