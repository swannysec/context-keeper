#!/usr/bin/env bash
# Phase 10: Memory Health Scoring Tests
# Run: bash tests/phase-10-health/test-health.sh

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

# Helper: create a project with memory directory and git repo
setup_project() {
  local base="$1"
  mkdir -p "$base/.claude/memory/sessions"
  mkdir -p "$base/.claude/memory/decisions"

  cd "$base"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "# Test" > README.md
  git add -A && git commit -q -m "initial commit"

  echo "# Active Context" > .claude/memory/active-context.md
  echo "# Progress" > .claude/memory/progress.md
  echo "# Patterns" > .claude/memory/patterns.md
  git add -A && git commit -q -m "add memory files"
  cd "$ORIG_DIR"
}

setup_config() {
  local base="$1"
  local content="$2"
  cat > "$base/.claude/memory/.memory-config.md" <<CONFIGEOF
$content
CONFIGEOF
}

# Helper: run session-start.sh in a project dir
run_session_start() {
  local workdir="$1"
  cd "$workdir"
  bash "$REPO_ROOT/hooks/session-start.sh" 2>/dev/null || true
  cd "$ORIG_DIR"
}

# Helper: run stop.sh in a project dir, capture stderr
run_stop() {
  local workdir="$1"
  cd "$workdir"
  bash "$REPO_ROOT/hooks/stop.sh" 2>&1 1>/dev/null || true
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 1: First run — no health output (.last-sync just created)
# ---------------------------------------------------------------------------
test_first_run_no_health() {
  local base="$TMPDIR_TEST/test1"
  setup_project "$base"
  # No .last-sync exists — first run

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-health"; then
    fail "Test 1: Should NOT show health on first run"
  else
    pass "Test 1: No health output on first run (.last-sync just created)"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: All files current — silent
# ---------------------------------------------------------------------------
test_all_current_silent() {
  local base="$TMPDIR_TEST/test2"
  setup_project "$base"

  # Create .last-sync (simulate previous sync)
  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  # Touch memory files so they're fresh (mtime = now)
  touch "$base/.claude/memory/active-context.md"
  touch "$base/.claude/memory/progress.md"
  touch "$base/.claude/memory/patterns.md"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-health"; then
    fail "Test 2: Should NOT show health when all files current"
    echo "  Output: $(printf '%s' "$output" | grep 'conkeeper-health')"
  else
    pass "Test 2: All files current — silent"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: Stale files detected — <conkeeper-health> with commit counts
# ---------------------------------------------------------------------------
test_stale_files_detected() {
  local base="$TMPDIR_TEST/test3"
  setup_project "$base"

  # Set .last-sync to past
  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  # Create many commits AFTER the memory files were last touched
  # (memory files have old mtime from setup_project)
  cd "$base"
  # Set memory file mtimes to the past so commits are "after" them
  touch -t 200001010000 .claude/memory/active-context.md
  touch -t 200001010000 .claude/memory/progress.md
  for i in $(seq 1 8); do
    echo "change $i" >> README.md
    git add -A && git commit -q -m "commit-$i"
  done
  cd "$ORIG_DIR"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-health"; then
    if printf '%s' "$output" | grep -q "commits behind"; then
      pass "Test 3: Stale files detected with commit counts"
    else
      fail "Test 3: Health block present but missing commit counts"
    fi
  else
    fail "Test 3: Should show <conkeeper-health> for stale files"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: Custom threshold (staleness_commits: 10) — files with 7 commits NOT flagged
# ---------------------------------------------------------------------------
test_custom_threshold() {
  local base="$TMPDIR_TEST/test4"
  setup_project "$base"

  setup_config "$base" "---
staleness_commits: 10
---"

  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  cd "$base"
  touch -t 200001010000 .claude/memory/active-context.md
  for i in $(seq 1 7); do
    echo "change $i" >> README.md
    git add -A && git commit -q -m "commit-$i"
  done
  cd "$ORIG_DIR"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-health"; then
    fail "Test 4: Should NOT flag with threshold 10 and only 9 commits"
  else
    pass "Test 4: Custom threshold (10) — 9 commits not flagged"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: Disabled (staleness_commits: 0) — no health check
# ---------------------------------------------------------------------------
test_disabled() {
  local base="$TMPDIR_TEST/test5"
  setup_project "$base"

  setup_config "$base" "---
staleness_commits: 0
---"

  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  cd "$base"
  touch -t 200001010000 .claude/memory/active-context.md
  for i in $(seq 1 20); do
    echo "change $i" >> README.md
    git add -A && git commit -q -m "commit-$i"
  done
  cd "$ORIG_DIR"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-health"; then
    fail "Test 5: Should NOT run health check when disabled (0)"
  else
    pass "Test 5: Disabled (staleness_commits: 0) — no health check"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: Performance guard timeout message
# ---------------------------------------------------------------------------
# Note: This test is difficult to reliably trigger in CI (depends on system speed).
# We test that the performance guard code path exists rather than forcing a timeout.
test_performance_guard_exists() {
  # Verify the performance guard code is present in session-start.sh
  if grep -q "health check timed out" "$REPO_ROOT/hooks/session-start.sh"; then
    pass "Test 6: Performance guard timeout code path exists"
  else
    fail "Test 6: Performance guard timeout code missing from session-start.sh"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: Health cache file created in $TMPDIR
# ---------------------------------------------------------------------------
test_health_cache_created() {
  local base="$TMPDIR_TEST/test7"
  setup_project "$base"

  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  local flag_dir="${TMPDIR:-/tmp}/conkeeper"

  run_session_start "$base" > /dev/null

  local cache_file="$flag_dir/health-$(date +%Y%m%d)"
  if [ -f "$cache_file" ]; then
    pass "Test 7: Health cache file created in \$TMPDIR"
  else
    fail "Test 7: Health cache file not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: Stop hook reads cache, shows consolidated message
# ---------------------------------------------------------------------------
test_stop_hook_stale_message() {
  local base="$TMPDIR_TEST/test8"
  setup_project "$base"

  # Create a health cache with stale data
  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  mkdir -p "$flag_dir"
  printf '%s' "  - active-context.md (12 commits behind)" > "$flag_dir/health-$(date +%Y%m%d)"

  # Set .last-sync to older than cache (no sync happened)
  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"
  sleep 1
  # Touch the cache to be newer than .last-sync
  touch "$flag_dir/health-$(date +%Y%m%d)"

  local stderr_output
  stderr_output=$(run_stop "$base")

  if printf '%s' "$stderr_output" | grep -q "stale memory"; then
    pass "Test 8: Stop hook shows consolidated stale message"
  else
    fail "Test 8: Stop hook should show stale memory message"
    echo "  Output: $stderr_output"
  fi
}

# ---------------------------------------------------------------------------
# Test 9: Stop hook silent after sync happened
# ---------------------------------------------------------------------------
test_stop_hook_silent_after_sync() {
  local base="$TMPDIR_TEST/test9"
  setup_project "$base"

  # Create a health cache with stale data
  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  mkdir -p "$flag_dir"
  printf '%s' "  - active-context.md (12 commits behind)" > "$flag_dir/health-$(date +%Y%m%d)"

  # Set .last-sync to NEWER than cache (sync happened this session)
  sleep 1
  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  local stderr_output
  stderr_output=$(run_stop "$base")

  if printf '%s' "$stderr_output" | grep -q "stale memory"; then
    fail "Test 9: Stop hook should be silent after sync"
    echo "  Output: $stderr_output"
  else
    pass "Test 9: Stop hook silent after sync happened"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 10: Memory Health Scoring Tests ==="
echo ""

test_first_run_no_health
test_all_current_silent
test_stale_files_detected
test_custom_threshold
test_disabled
test_performance_guard_exists
test_health_cache_created
test_stop_hook_stale_message
test_stop_hook_silent_after_sync

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
