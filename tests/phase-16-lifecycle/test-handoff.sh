#!/usr/bin/env bash
# Phase 16: Lifecycle Automation Tests (Handoff Generation + Resume Detection)
# Run: bash tests/phase-16-lifecycle/test-handoff.sh

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

# Helper: create a project with git, memory, and config
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

  cat > "$base/.claude/memory/active-context.md" <<'CTX'
# Active Context
## Current Focus
Building the authentication module with JWT tokens
## Recent Decisions
- Using bcrypt for password hashing
CTX

  mkdir -p "$TMPDIR_TEST/fakehome/.claude"
  printf '{}' > "$TMPDIR_TEST/fakehome/.claude/settings.json"

  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  mkdir -p "$flag_dir"
}

# Helper: set up git repo in project
setup_git() {
  local base="$1"
  cd "$base"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "# Project" > README.md
  git add -A && git commit -q -m "initial"
  cd "$ORIG_DIR"
}

# Helper: run user-prompt-submit
run_ups() {
  local workdir="$1"
  local session_id="$2"

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

# Helper: run with pre-set flags
run_ups_with_flags() {
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

  run_ups "$workdir" "$session_id"
}

# ---------------------------------------------------------------------------
# Test 1: Handoff generated at threshold with correct YAML frontmatter
# ---------------------------------------------------------------------------
test_handoff_generated() {
  local base="$TMPDIR_TEST/t1"
  # 92% of 200K = 184000. auto_clear_pct=90, need sync flag pre-set
  setup_project "$base" 184000 "auto_clear: true
auto_clear_pct: 90"
  setup_git "$base"

  local output
  output=$(run_ups_with_flags "$base" "sess-ho-01" true false)

  local handoff_file="$base/.claude/memory/.handoffs/.pending-handoff-sess-ho-01.md"
  if [ -f "$handoff_file" ]; then
    pass "Test 1a: Handoff file generated"
  else
    fail "Test 1a: Handoff file not generated"
    return
  fi

  # Check YAML frontmatter
  if grep -q "^generated:" "$handoff_file" && \
     grep -q "^previous_session: sess-ho-01" "$handoff_file" && \
     grep -q "^context_pct: 92" "$handoff_file" && \
     grep -q "^branch:" "$handoff_file" && \
     grep -q "^ttl:" "$handoff_file"; then
    pass "Test 1b: Handoff has correct YAML frontmatter"
  else
    fail "Test 1b: Handoff frontmatter incomplete"
    head -10 "$handoff_file"
  fi

  # Check advisory in output
  if printf '%s' "$output" | grep -q "conkeeper-auto-clear"; then
    pass "Test 1c: Auto-clear advisory in output"
  else
    fail "Test 1c: Auto-clear advisory missing"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: No handoff when auto_clear=false
# ---------------------------------------------------------------------------
test_no_handoff_disabled() {
  local base="$TMPDIR_TEST/t2"
  setup_project "$base" 184000 "auto_clear: false"

  local output
  output=$(run_ups_with_flags "$base" "sess-ho-02" true false)

  if [ -d "$base/.claude/memory/.handoffs" ]; then
    fail "Test 2: Handoff dir should not exist when auto_clear=false"
  else
    pass "Test 2: No handoff when auto_clear=false"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: No handoff when below threshold
# ---------------------------------------------------------------------------
test_no_handoff_below_threshold() {
  local base="$TMPDIR_TEST/t3"
  # 70% < 90% auto_clear_pct
  setup_project "$base" 140000 "auto_clear: true
auto_clear_pct: 90"

  local output
  output=$(run_ups_with_flags "$base" "sess-ho-03" true false)

  local handoff_file="$base/.claude/memory/.handoffs/.pending-handoff-sess-ho-03.md"
  if [ -f "$handoff_file" ]; then
    fail "Test 3: Should not generate handoff below threshold"
  else
    pass "Test 3: No handoff below auto_clear_pct"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: No re-generation (handoff flag prevents duplicate)
# ---------------------------------------------------------------------------
test_no_duplicate_handoff() {
  local base="$TMPDIR_TEST/t4"
  setup_project "$base" 184000 "auto_clear: true
auto_clear_pct: 90"
  setup_git "$base"

  # First run generates handoff
  run_ups_with_flags "$base" "sess-ho-04" true false > /dev/null

  # Set up flags for second run (sync + handoff already set by first run)
  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  # Handoff flag was set by first run. Run again with sync flag.
  printf '%s' "$(date +%s)" > "$flag_dir/synced-sess-ho-04"

  local output2
  output2=$(run_ups "$base" "sess-ho-04")

  # Should not emit a second auto-clear advisory
  if printf '%s' "$output2" | grep -q "conkeeper-auto-clear"; then
    fail "Test 4: Should not re-emit auto-clear advisory"
  else
    pass "Test 4: Handoff flag prevents duplicate generation"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: Handoff includes branch, dirty status, focus summary
# ---------------------------------------------------------------------------
test_handoff_content() {
  local base="$TMPDIR_TEST/t5"
  setup_project "$base" 184000 "auto_clear: true
auto_clear_pct: 90"
  setup_git "$base"

  # Make dirty changes
  cd "$base"
  echo "dirty change" >> README.md
  cd "$ORIG_DIR"

  run_ups_with_flags "$base" "sess-ho-05" true false > /dev/null

  local handoff_file="$base/.claude/memory/.handoffs/.pending-handoff-sess-ho-05.md"

  if grep -q "dirty: true" "$handoff_file"; then
    pass "Test 5a: Handoff records dirty status"
  else
    fail "Test 5a: Handoff missing dirty status"
  fi

  if grep -q "authentication module" "$handoff_file"; then
    pass "Test 5b: Handoff includes focus summary"
  else
    fail "Test 5b: Handoff missing focus summary"
  fi

  if grep -q "Uncommitted changes" "$handoff_file"; then
    pass "Test 5c: Handoff includes dirty warning"
  else
    fail "Test 5c: Handoff missing dirty warning"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: Session-scoped filenames (parallel session safety)
# ---------------------------------------------------------------------------
test_session_scoped_filenames() {
  local base="$TMPDIR_TEST/t6"
  setup_project "$base" 184000 "auto_clear: true
auto_clear_pct: 90"
  setup_git "$base"

  run_ups_with_flags "$base" "sess-ho-06a" true false > /dev/null
  run_ups_with_flags "$base" "sess-ho-06b" true false > /dev/null

  local file_a="$base/.claude/memory/.handoffs/.pending-handoff-sess-ho-06a.md"
  local file_b="$base/.claude/memory/.handoffs/.pending-handoff-sess-ho-06b.md"

  if [ -f "$file_a" ] && [ -f "$file_b" ]; then
    pass "Test 6: Session-scoped filenames — parallel sessions safe"
  else
    fail "Test 6: Missing session-scoped handoff files"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: Resume detection injects handoff content
# ---------------------------------------------------------------------------
test_resume_detection() {
  local base="$TMPDIR_TEST/t7"
  setup_project "$base" 184000 "auto_clear: true"
  setup_git "$base"

  # Create a pending handoff manually
  mkdir -p "$base/.claude/memory/.handoffs"
  local epoch
  epoch=$(date +%s)
  cat > "$base/.claude/memory/.handoffs/.pending-handoff-sess-prev.md" <<HANDOFF
---
generated: ${epoch}
previous_session: sess-prev
context_pct: 92
branch: main
dirty: false
ttl: 3600
---
# Pending Handoff

Building the authentication module with JWT tokens
HANDOFF

  cd "$base"
  git add -A && git commit -q -m "setup" 2>/dev/null || true

  local output
  output=$(bash "$REPO_ROOT/hooks/session-start.sh" 2>/dev/null)
  cd "$ORIG_DIR"

  if printf '%s' "$output" | grep -q "conkeeper-handoff"; then
    pass "Test 7a: Resume detection injects handoff content"
  else
    fail "Test 7a: Resume detection missing"
    echo "  Output snippet: $(printf '%s' "$output" | head -c 500)"
  fi

  if printf '%s' "$output" | grep -q "authentication module"; then
    pass "Test 7b: Handoff content present in injection"
  else
    fail "Test 7b: Handoff content missing"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: Consumed handoff renamed to .last-handoff-*
# ---------------------------------------------------------------------------
test_handoff_renamed_after_consumption() {
  local base="$TMPDIR_TEST/t8"
  setup_project "$base" 184000 "auto_clear: true"
  setup_git "$base"

  mkdir -p "$base/.claude/memory/.handoffs"
  local epoch
  epoch=$(date +%s)
  cat > "$base/.claude/memory/.handoffs/.pending-handoff-sess-consumed.md" <<HANDOFF
---
generated: ${epoch}
previous_session: sess-consumed
context_pct: 90
branch: main
dirty: false
ttl: 3600
---
# Pending Handoff

Test content
HANDOFF

  cd "$base"
  git add -A && git commit -q -m "setup" 2>/dev/null || true
  bash "$REPO_ROOT/hooks/session-start.sh" > /dev/null 2>&1
  cd "$ORIG_DIR"

  local pending="$base/.claude/memory/.handoffs/.pending-handoff-sess-consumed.md"
  local last="$base/.claude/memory/.handoffs/.last-handoff-sess-consumed.md"

  if [ ! -f "$pending" ] && [ -f "$last" ]; then
    pass "Test 8: Consumed handoff renamed to .last-handoff-*"
  else
    fail "Test 8: Handoff not properly renamed"
    ls -la "$base/.claude/memory/.handoffs/" 2>/dev/null || true
  fi
}

# ---------------------------------------------------------------------------
# Test 9: Stale handoff (expired TTL) deleted, not injected
# ---------------------------------------------------------------------------
test_stale_handoff_cleanup() {
  local base="$TMPDIR_TEST/t9"
  setup_project "$base" 184000 "auto_clear: true"
  setup_git "$base"

  mkdir -p "$base/.claude/memory/.handoffs"
  # Create a handoff with epoch far in the past (TTL expired)
  cat > "$base/.claude/memory/.handoffs/.pending-handoff-sess-stale.md" <<'HANDOFF'
---
generated: 1000000000
previous_session: sess-stale
context_pct: 90
branch: main
dirty: false
ttl: 3600
---
# Pending Handoff

Stale content
HANDOFF

  cd "$base"
  git add -A && git commit -q -m "setup" 2>/dev/null || true
  local output
  output=$(bash "$REPO_ROOT/hooks/session-start.sh" 2>/dev/null)
  local stderr_output
  stderr_output=$(bash "$REPO_ROOT/hooks/session-start.sh" 2>&1 1>/dev/null) || true
  cd "$ORIG_DIR"

  local stale_file="$base/.claude/memory/.handoffs/.pending-handoff-sess-stale.md"
  if [ ! -f "$stale_file" ]; then
    pass "Test 9a: Stale handoff deleted"
  else
    fail "Test 9a: Stale handoff should have been deleted"
  fi

  if printf '%s' "$output" | grep -q "conkeeper-handoff"; then
    fail "Test 9b: Stale handoff should NOT be injected"
  else
    pass "Test 9b: Stale handoff not injected"
  fi
}

# ---------------------------------------------------------------------------
# Test 10: Config validation: auto_clear_pct adjusted if <= auto_sync_threshold
# ---------------------------------------------------------------------------
test_config_validation() {
  local base="$TMPDIR_TEST/t10"
  # auto_clear_pct=50 <= auto_sync_threshold=60 → should be adjusted to 65
  setup_project "$base" 132000 "auto_clear: true
auto_clear_pct: 50
auto_sync_threshold: 60"
  setup_git "$base"

  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  rm -f "$flag_dir/synced-sess-ho-10" "$flag_dir/blocked-sess-ho-10" "$flag_dir/handoff-sess-ho-10"
  printf '%s' "$(date +%s)" > "$flag_dir/synced-sess-ho-10"

  local transcript="$base/transcript.jsonl"
  local json
  json=$(jq -n \
    --arg sid "sess-ho-10" \
    --arg tp "$transcript" \
    --arg cwd "$base" \
    --arg um "test prompt" \
    '{session_id: $sid, transcript_path: $tp, cwd: $cwd, user_message: $um}')

  local stderr_output
  stderr_output=$(export HOME="$TMPDIR_TEST/fakehome"; printf '%s' "$json" | bash "$REPO_ROOT/hooks/user-prompt-submit.sh" 2>&1 1>/dev/null) || true

  if printf '%s' "$stderr_output" | grep -q "must exceed"; then
    pass "Test 10: Config validation warns about invalid auto_clear_pct"
  else
    fail "Test 10: Config validation warning missing"
    echo "  Stderr: $stderr_output"
  fi
}

# ---------------------------------------------------------------------------
# Test 11: Handoff capped at 2000 chars in resume injection
# ---------------------------------------------------------------------------
test_handoff_cap() {
  local base="$TMPDIR_TEST/t11"
  setup_project "$base" 184000 "auto_clear: true"
  setup_git "$base"

  mkdir -p "$base/.claude/memory/.handoffs"
  local epoch
  epoch=$(date +%s)

  # Generate a handoff with >2000 chars of content
  {
    printf '%s\n' "---"
    printf 'generated: %s\n' "$epoch"
    printf 'previous_session: sess-big\n'
    printf 'context_pct: 92\n'
    printf 'branch: main\n'
    printf 'dirty: false\n'
    printf 'ttl: 3600\n'
    printf '%s\n' "---"
    printf '# Pending Handoff\n\n'
    # Generate 3000 chars of content
    for i in $(seq 1 100); do
      printf 'This is line %03d of the oversized handoff content padding.\n' "$i"
    done
  } > "$base/.claude/memory/.handoffs/.pending-handoff-sess-big.md"

  cd "$base"
  git add -A && git commit -q -m "setup" 2>/dev/null || true
  local output
  output=$(bash "$REPO_ROOT/hooks/session-start.sh" 2>/dev/null)
  cd "$ORIG_DIR"

  # The handoff content should be present but capped
  if printf '%s' "$output" | grep -q "conkeeper-handoff"; then
    pass "Test 11a: Oversized handoff still injected (capped)"
  else
    fail "Test 11a: Oversized handoff not injected"
  fi

  # Should NOT contain the very last lines (which would be beyond 2000 chars)
  if printf '%s' "$output" | grep -q "line 100"; then
    fail "Test 11b: Handoff content not capped at 2000 chars"
  else
    pass "Test 11b: Handoff content capped at 2000 chars"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 16: Lifecycle Automation Tests ==="
echo ""

test_handoff_generated
test_no_handoff_disabled
test_no_handoff_below_threshold
test_no_duplicate_handoff
test_handoff_content
test_session_scoped_filenames
test_resume_detection
test_handoff_renamed_after_consumption
test_stale_handoff_cleanup
test_config_validation
test_handoff_cap

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
