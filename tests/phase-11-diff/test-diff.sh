#!/usr/bin/env bash
# Phase 11: Memory Diff Tests
# Run: bash tests/phase-11-diff/test-diff.sh

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

  # Initialize git repo with an initial commit
  cd "$base"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "# Test" > README.md
  git add -A && git commit -q -m "initial commit"

  # Create memory files
  echo "# Active Context" > .claude/memory/active-context.md
  echo "# Progress" > .claude/memory/progress.md
  git add -A && git commit -q -m "add memory files"
  cd "$ORIG_DIR"
}

# Helper: run session-start.sh in a project dir, capture output
run_session_start() {
  local workdir="$1"
  cd "$workdir"
  local output
  output=$(bash "$REPO_ROOT/hooks/session-start.sh" 2>/dev/null) || true
  cd "$ORIG_DIR"
  printf '%s' "$output"
}

# ---------------------------------------------------------------------------
# Test 1: .last-sync created on first run (valid epoch)
# ---------------------------------------------------------------------------
test_last_sync_created_first_run() {
  local base="$TMPDIR_TEST/test1"
  setup_project "$base"

  run_session_start "$base" > /dev/null

  if [ -f "$base/.claude/memory/.last-sync" ]; then
    local content
    content=$(cat "$base/.claude/memory/.last-sync")
    if printf '%s' "$content" | grep -qE '^[0-9]+$'; then
      pass "Test 1: .last-sync created on first run with valid epoch"
    else
      fail "Test 1: .last-sync content is not a valid epoch: $content"
    fi
  else
    fail "Test 1: .last-sync not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: No <conkeeper-diff> on first run
# ---------------------------------------------------------------------------
test_no_diff_first_run() {
  local base="$TMPDIR_TEST/test2"
  setup_project "$base"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-diff"; then
    fail "Test 2: <conkeeper-diff> should NOT appear on first run"
  else
    pass "Test 2: No <conkeeper-diff> on first run"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: Diff shows commit onelines when commits exist after epoch
# ---------------------------------------------------------------------------
test_diff_shows_commits() {
  local base="$TMPDIR_TEST/test3"
  setup_project "$base"

  # Set .last-sync to a past time
  printf '%s' "1000000000" > "$base/.claude/memory/.last-sync"

  # Add a commit after the epoch
  cd "$base"
  echo "change" >> README.md
  git add -A && git commit -q -m "feat: add feature"
  cd "$ORIG_DIR"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-diff"; then
    if printf '%s' "$output" | grep -q "feat: add feature"; then
      pass "Test 3: Diff shows commit onelines"
    else
      fail "Test 3: Diff block present but missing commit message"
    fi
  else
    fail "Test 3: <conkeeper-diff> missing when commits exist"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: Diff shows memory file changes (modified)
# ---------------------------------------------------------------------------
test_diff_shows_memory_changes() {
  local base="$TMPDIR_TEST/test4"
  setup_project "$base"

  # Set .last-sync to a past time
  printf '%s' "1000000000" > "$base/.claude/memory/.last-sync"

  # Touch a memory file to update mtime (after the past epoch)
  touch "$base/.claude/memory/active-context.md"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "active-context.md modified"; then
    pass "Test 4: Diff shows memory file changes"
  else
    fail "Test 4: Memory file change not detected in diff"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: Silent when no changes
# ---------------------------------------------------------------------------
test_silent_no_changes() {
  local base="$TMPDIR_TEST/test5"
  setup_project "$base"

  # Set .last-sync to a few seconds ago (recent past) — no commits after it
  # Sleep briefly to ensure the epoch is strictly in the past
  sleep 1
  local recent_epoch=$(date +%s)
  printf '%s' "$recent_epoch" > "$base/.claude/memory/.last-sync"

  # Touch memory files to have mtimes BEFORE the sync epoch
  touch -t 200001010000 "$base/.claude/memory/active-context.md"
  touch -t 200001010000 "$base/.claude/memory/progress.md"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-diff"; then
    fail "Test 5: <conkeeper-diff> should NOT appear when no changes"
    echo "  Output excerpt: $(printf '%s' "$output" | grep 'conkeeper-diff')"
  else
    pass "Test 5: Silent when no changes since last sync"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: Refuses symlink .last-sync
# ---------------------------------------------------------------------------
test_refuses_symlink_last_sync() {
  local base="$TMPDIR_TEST/test6"
  setup_project "$base"

  # Create a symlink .last-sync pointing to a real file
  local real_file="$TMPDIR_TEST/real_sync"
  printf '%s' "1000000000" > "$real_file"
  ln -s "$real_file" "$base/.claude/memory/.last-sync"

  local output
  output=$(run_session_start "$base")

  # Should not show diff (symlink refused) and should not crash
  if printf '%s' "$output" | grep -q "conkeeper-diff"; then
    fail "Test 6: Should refuse symlink .last-sync"
  else
    pass "Test 6: Refuses symlink .last-sync"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: Economy budget skips diff
# ---------------------------------------------------------------------------
test_economy_skips_diff() {
  local base="$TMPDIR_TEST/test7"
  setup_project "$base"

  # Set economy budget
  printf '%s\n' "---" > "$base/.claude/memory/.memory-config.md"
  printf '%s\n' "token_budget: economy" >> "$base/.claude/memory/.memory-config.md"
  printf '%s\n' "---" >> "$base/.claude/memory/.memory-config.md"

  # Set .last-sync to past with commits after it
  printf '%s' "1000000000" > "$base/.claude/memory/.last-sync"
  cd "$base"
  echo "change" >> README.md
  git add -A && git commit -q -m "feat: economy test"
  cd "$ORIG_DIR"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-diff"; then
    fail "Test 7: Economy budget should skip diff"
  else
    pass "Test 7: Economy budget skips diff"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: Light budget caps at 3 commits with (+N more)
# ---------------------------------------------------------------------------
test_light_budget_caps_commits() {
  local base="$TMPDIR_TEST/test8"
  setup_project "$base"

  # Set light budget
  printf '%s\n' "---" > "$base/.claude/memory/.memory-config.md"
  printf '%s\n' "token_budget: light" >> "$base/.claude/memory/.memory-config.md"
  printf '%s\n' "---" >> "$base/.claude/memory/.memory-config.md"

  # Set .last-sync to past
  printf '%s' "1000000000" > "$base/.claude/memory/.last-sync"

  # Create 5 commits
  cd "$base"
  for i in 1 2 3 4 5; do
    echo "change $i" >> README.md
    git add -A && git commit -q -m "commit-$i"
  done
  cd "$ORIG_DIR"

  local output
  output=$(run_session_start "$base")

  # setup_project creates 2 commits (initial + add memory files), plus 5 test commits = 7 total
  # Light budget max = 3, so 7-3 = 4 more
  if printf '%s' "$output" | grep -q "(+4 more)"; then
    pass "Test 8: Light budget caps at 3 commits with (+N more)"
  else
    fail "Test 8: Light budget should cap at 3 commits"
    echo "  Output: $(printf '%s' "$output" | grep -A5 'conkeeper-diff')"
  fi
}

# ---------------------------------------------------------------------------
# Test 9: Works without git repo (memory changes only)
# ---------------------------------------------------------------------------
test_works_without_git() {
  local base="$TMPDIR_TEST/test9"
  mkdir -p "$base/.claude/memory/sessions"
  mkdir -p "$base/.claude/memory/decisions"

  echo "# Active Context" > "$base/.claude/memory/active-context.md"
  echo "# Progress" > "$base/.claude/memory/progress.md"

  # Set .last-sync to past
  printf '%s' "1000000000" > "$base/.claude/memory/.last-sync"

  # Touch a memory file
  touch "$base/.claude/memory/active-context.md"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "active-context.md modified"; then
    pass "Test 9: Works without git repo (memory changes only)"
  else
    fail "Test 9: Should detect memory changes without git"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 11: Memory Diff Tests ==="
echo ""

test_last_sync_created_first_run
test_no_diff_first_run
test_diff_shows_commits
test_diff_shows_memory_changes
test_silent_no_changes
test_refuses_symlink_last_sync
test_economy_skips_diff
test_light_budget_caps_commits
test_works_without_git

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
