#!/usr/bin/env bash
# Phase 13: Cross-Project Search Tests
# Run: bash tests/phase-13-cross-project/test-cross-project.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMPDIR_TEST="$(mktemp -d)"
PASS=0
FAIL=0

# Save original directory so we can restore it
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

# Helper: set up cross-project directory structure
setup_cross_project() {
  local parent="$1"
  # Current project
  mkdir -p "$parent/project-a/.claude/memory/sessions"
  echo "# Active Context" > "$parent/project-a/.claude/memory/active-context.md"

  # Other project with searchable content
  mkdir -p "$parent/project-b/.claude/memory/sessions"
  cat > "$parent/project-b/.claude/memory/patterns.md" <<'EOF'
# Patterns

authentication pattern here
<!-- @category: decision -->

database migration strategy
EOF
}

# ---------------------------------------------------------------------------
# Test 1: Flag parsing — no config → error message
# ---------------------------------------------------------------------------
test_no_config_error() {
  local workdir="$TMPDIR_TEST/test1"
  mkdir -p "$workdir/.claude/memory"
  echo "# Active Context" > "$workdir/.claude/memory/active-context.md"

  cd "$workdir"
  local output
  output=$(bash "$REPO_ROOT/tools/memory-search.sh" "anything" --cross-project 2>&1) || true

  if echo "$output" | grep -q "Cross-project search not configured"; then
    pass "Test 1: No config → error message"
  else
    fail "Test 1: No config → error message"
    echo "  Got: $output"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 2: disabled config → same error
# ---------------------------------------------------------------------------
test_disabled_config() {
  local workdir="$TMPDIR_TEST/test2"
  mkdir -p "$workdir/.claude/memory"
  echo "# Active Context" > "$workdir/.claude/memory/active-context.md"
  cat > "$workdir/.claude/memory/.memory-config.md" <<'EOF'
---
project_search_paths: disabled
---
EOF

  cd "$workdir"
  local output
  output=$(bash "$REPO_ROOT/tools/memory-search.sh" "anything" --cross-project 2>&1) || true

  if echo "$output" | grep -q "Cross-project search not configured"; then
    pass "Test 2: disabled config → error message"
  else
    fail "Test 2: disabled config → error message"
    echo "  Got: $output"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 3: Finds other projects under configured parent
# ---------------------------------------------------------------------------
test_finds_other_projects() {
  local parent="$TMPDIR_TEST/test3/parent"
  setup_cross_project "$parent"

  # Configure project-a to search parent directory
  cat > "$parent/project-a/.claude/memory/.memory-config.md" <<EOF
---
project_search_paths: ["$parent"]
---
EOF

  cd "$parent/project-a"
  local output
  output=$(bash "$REPO_ROOT/tools/memory-search.sh" "authentication" --cross-project 2>&1) || true

  if echo "$output" | grep -q "authentication pattern here"; then
    pass "Test 3: Finds other projects under configured parent"
  else
    fail "Test 3: Finds other projects under configured parent"
    echo "  Got: $output"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 4: Excludes current project from results
# ---------------------------------------------------------------------------
test_excludes_current_project() {
  local parent="$TMPDIR_TEST/test4/parent"
  setup_cross_project "$parent"

  # Add unique content only in project-a (current project)
  echo "unique_current_project_marker" >> "$parent/project-a/.claude/memory/active-context.md"

  # Configure project-a
  cat > "$parent/project-a/.claude/memory/.memory-config.md" <<EOF
---
project_search_paths: ["$parent"]
---
EOF

  cd "$parent/project-a"
  local output
  output=$(bash "$REPO_ROOT/tools/memory-search.sh" "unique_current_project_marker" --cross-project 2>&1) || true

  # The marker is only in project-a (current project). Cross-project search should
  # still find it in the local project memory (SEARCH_DIRS starts with local), but
  # the cross-project discovery should NOT add project-a again.
  # We verify by checking the output doesn't list the project-a memory dir twice.
  local count
  count=$(echo "$output" | grep -c "project-a/.claude/memory" || true)

  if [ "$count" -le 1 ]; then
    pass "Test 4: Excludes current project from cross-project results"
  else
    fail "Test 4: Current project should not be duplicated in cross-project results"
    echo "  Got: $output"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 5: Respects private: true files in cross-project dirs
# ---------------------------------------------------------------------------
test_private_file_cross_project() {
  local parent="$TMPDIR_TEST/test5/parent"
  setup_cross_project "$parent"

  # Add a private file in project-b with searchable content
  cat > "$parent/project-b/.claude/memory/secrets.md" <<'EOF'
---
private: true
---
# Secrets
cross_project_secret_value here
EOF

  cat > "$parent/project-a/.claude/memory/.memory-config.md" <<EOF
---
project_search_paths: ["$parent"]
---
EOF

  cd "$parent/project-a"
  local output
  output=$(bash "$REPO_ROOT/tools/memory-search.sh" "cross_project_secret_value" --cross-project 2>&1) || true

  if echo "$output" | grep -q "No results" || ! echo "$output" | grep -q "cross_project_secret_value"; then
    pass "Test 5: Respects private: true files in cross-project dirs"
  else
    fail "Test 5: Private files in cross-project dirs should be excluded"
    echo "  Got: $output"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 6: Respects <private> blocks in cross-project files
# ---------------------------------------------------------------------------
test_private_blocks_cross_project() {
  local parent="$TMPDIR_TEST/test6/parent"
  setup_cross_project "$parent"

  # Add a file with private block in project-b
  cat > "$parent/project-b/.claude/memory/credentials.md" <<'EOF'
# Credentials
Public info here
<private>
cross_project_private_block_content
</private>
More public info
EOF

  cat > "$parent/project-a/.claude/memory/.memory-config.md" <<EOF
---
project_search_paths: ["$parent"]
---
EOF

  cd "$parent/project-a"
  local output
  output=$(bash "$REPO_ROOT/tools/memory-search.sh" "cross_project_private_block_content" --cross-project 2>&1) || true

  if echo "$output" | grep -q "No results" || ! echo "$output" | grep -q "cross_project_private_block_content"; then
    pass "Test 6: Respects <private> blocks in cross-project files"
  else
    fail "Test 6: Private blocks in cross-project files should be excluded"
    echo "  Got: $output"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 7: Symlink escape refused
# ---------------------------------------------------------------------------
test_symlink_escape() {
  local parent="$TMPDIR_TEST/test7/parent"
  setup_cross_project "$parent"

  # Create an outside directory with memory content
  local outside="$TMPDIR_TEST/test7/outside"
  mkdir -p "$outside/.claude/memory"
  echo "symlink_escaped_content" > "$outside/.claude/memory/patterns.md"

  # Create a symlink inside the parent that points outside
  ln -s "$outside" "$parent/symlinked-project"

  cat > "$parent/project-a/.claude/memory/.memory-config.md" <<EOF
---
project_search_paths: ["$parent"]
---
EOF

  cd "$parent/project-a"
  local output
  output=$(bash "$REPO_ROOT/tools/memory-search.sh" "symlink_escaped_content" --cross-project 2>&1) || true

  if echo "$output" | grep -q "No results" || ! echo "$output" | grep -q "symlink_escaped_content"; then
    pass "Test 7: Symlink escape refused"
  else
    fail "Test 7: Symlink escape should be refused"
    echo "  Got: $output"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 8: Flag stacking (--cross-project --category decision)
# ---------------------------------------------------------------------------
test_flag_stacking() {
  local parent="$TMPDIR_TEST/test8/parent"
  setup_cross_project "$parent"

  cat > "$parent/project-a/.claude/memory/.memory-config.md" <<EOF
---
project_search_paths: ["$parent"]
---
EOF

  cd "$parent/project-a"

  # Search with both --cross-project and --category decision
  local output
  output=$(bash "$REPO_ROOT/tools/memory-search.sh" "authentication" --cross-project --category decision 2>&1) || true

  # "authentication pattern here" in project-b has a decision category tag nearby
  if echo "$output" | grep -q "authentication pattern here"; then
    pass "Test 8: Flag stacking (--cross-project --category decision)"
  else
    fail "Test 8: Flag stacking should combine cross-project with category filter"
    echo "  Got: $output"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 9: Tilde expansion in config paths
# ---------------------------------------------------------------------------
test_tilde_expansion() {
  local fake_home="$TMPDIR_TEST/test9/fakehome"
  local parent="$fake_home/projects"
  mkdir -p "$parent"
  setup_cross_project "$parent"

  # Configure with tilde path
  cat > "$parent/project-a/.claude/memory/.memory-config.md" <<'EOF'
---
project_search_paths: ["~/projects"]
---
EOF

  cd "$parent/project-a"
  local output
  output=$(HOME="$fake_home" bash "$REPO_ROOT/tools/memory-search.sh" "authentication" --cross-project 2>&1) || true

  if echo "$output" | grep -q "authentication pattern here"; then
    pass "Test 9: Tilde expansion in config paths"
  else
    fail "Test 9: Tilde expansion should resolve ~ to HOME"
    echo "  Got: $output"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 13: Cross-Project Search Tests ==="
echo ""

test_no_config_error
test_disabled_config
test_finds_other_projects
test_excludes_current_project
test_private_file_cross_project
test_private_blocks_cross_project
test_symlink_escape
test_flag_stacking
test_tilde_expansion

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
