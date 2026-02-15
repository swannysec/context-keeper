#!/usr/bin/env bash
# Phase 14: Friction-Aware Session Start Tests
# Run: bash tests/phase-14-friction/test-friction.sh

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
  cd "$ORIG_DIR"
}

setup_config() {
  local base="$1"
  local content="$2"
  cat > "$base/.claude/memory/.memory-config.md" <<CONFIGEOF
$content
CONFIGEOF
}

run_session_start() {
  local workdir="$1"
  cd "$workdir"
  bash "$REPO_ROOT/hooks/session-start.sh" 2>/dev/null || true
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 1: Loaded at standard budget with <conkeeper-friction> tag
# ---------------------------------------------------------------------------
test_loaded_at_standard() {
  local base="$TMPDIR_TEST/test1"
  setup_project "$base"

  # Create .last-sync so we're not in first-run mode
  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  cat > "$base/.claude/memory/friction.md" <<'FRICTIONEOF'
# Friction Patterns
## Conventions
- When debugging, verify hypothesis before fix attempts
- Docker volume permissions cannot be fixed from inside the container
## Project-Specific
- This project uses bash 3.2 compatibility
FRICTIONEOF

  setup_config "$base" "---
token_budget: standard
---"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-friction"; then
    pass "Test 1: Friction loaded at standard budget with conkeeper-friction tag"
  else
    fail "Test 1: Should show <conkeeper-friction> at standard budget"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: Not loaded at economy budget
# ---------------------------------------------------------------------------
test_not_loaded_at_economy() {
  local base="$TMPDIR_TEST/test2"
  setup_project "$base"

  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  cat > "$base/.claude/memory/friction.md" <<'FRICTIONEOF'
# Friction Patterns
## Conventions
- When debugging, verify hypothesis before fix attempts
FRICTIONEOF

  setup_config "$base" "---
token_budget: economy
---"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-friction"; then
    fail "Test 2: Should NOT show conkeeper-friction at economy budget"
    echo "  Output: $output"
  else
    pass "Test 2: Friction not loaded at economy budget"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: Full content at detailed budget
# ---------------------------------------------------------------------------
test_full_content_at_detailed() {
  local base="$TMPDIR_TEST/test3"
  setup_project "$base"

  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  cat > "$base/.claude/memory/friction.md" <<'FRICTIONEOF'
# Friction Patterns
## Conventions
- When debugging, verify hypothesis before fix attempts
- Docker volume permissions cannot be fixed from inside the container
## Project-Specific
- This project uses bash 3.2 compatibility
- UNIQUE_MARKER_END_OF_FILE
FRICTIONEOF

  setup_config "$base" "---
token_budget: detailed
---"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-friction" && printf '%s' "$output" | grep -q "UNIQUE_MARKER_END_OF_FILE"; then
    pass "Test 3: Full content present at detailed budget"
  else
    fail "Test 3: Should show full friction content at detailed budget"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: Light budget caps content
# ---------------------------------------------------------------------------
test_light_budget_caps() {
  local base="$TMPDIR_TEST/test4"
  setup_project "$base"

  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  # Create friction.md with >1000 chars of content
  {
    echo "# Friction Patterns"
    echo "## Conventions"
    for i in $(seq 1 30); do
      echo "- Convention number $i: This is a fairly long convention entry that adds significant character count to the file to test truncation behavior at the light budget level"
    done
    echo "TAIL_MARKER_SHOULD_NOT_APPEAR"
  } > "$base/.claude/memory/friction.md"

  local original_size
  original_size=$(wc -c < "$base/.claude/memory/friction.md" | tr -d ' ')

  setup_config "$base" "---
token_budget: light
---"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-friction"; then
    if printf '%s' "$output" | grep -q "TAIL_MARKER_SHOULD_NOT_APPEAR"; then
      fail "Test 4: Light budget should truncate content but tail marker found"
    else
      pass "Test 4: Light budget caps content (truncated, tail marker absent)"
    fi
  else
    fail "Test 4: Should show conkeeper-friction at light budget"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: Missing file — no crash, no output
# ---------------------------------------------------------------------------
test_missing_file() {
  local base="$TMPDIR_TEST/test5"
  setup_project "$base"

  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  # No friction.md created

  setup_config "$base" "---
token_budget: standard
---"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-friction"; then
    fail "Test 5: Should NOT show conkeeper-friction when file missing"
  else
    pass "Test 5: Missing friction.md — no crash, no conkeeper-friction"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: Symlink refused
# ---------------------------------------------------------------------------
test_symlink_refused() {
  local base="$TMPDIR_TEST/test6"
  setup_project "$base"

  printf '%s' "$(date +%s)" > "$base/.claude/memory/.last-sync"

  # Create a real file and symlink to it
  echo "# Friction via symlink" > "$TMPDIR_TEST/real-friction.md"
  ln -s "$TMPDIR_TEST/real-friction.md" "$base/.claude/memory/friction.md"

  setup_config "$base" "---
token_budget: standard
---"

  local output
  output=$(run_session_start "$base")

  if printf '%s' "$output" | grep -q "conkeeper-friction"; then
    fail "Test 6: Should NOT load friction.md when it is a symlink"
  else
    pass "Test 6: Symlink friction.md refused — no conkeeper-friction"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: Template structure matches spec
# ---------------------------------------------------------------------------
test_template_structure() {
  # Verify the friction template in memory-init SKILL.md has expected headers
  local skill_file="$REPO_ROOT/skills/memory-init/SKILL.md"

  local has_header=false
  local has_conventions=false
  local has_project_specific=false

  if grep -q "# Friction Patterns" "$skill_file"; then
    has_header=true
  fi
  if grep -q "## Conventions" "$skill_file"; then
    has_conventions=true
  fi
  if grep -q "## Project-Specific" "$skill_file"; then
    has_project_specific=true
  fi

  if [ "$has_header" = true ] && [ "$has_conventions" = true ] && [ "$has_project_specific" = true ]; then
    pass "Test 7: Template structure matches spec (header, Conventions, Project-Specific)"
  else
    fail "Test 7: Template missing expected headers (header=$has_header, conventions=$has_conventions, project=$has_project_specific)"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 14: Friction-Aware Session Start Tests ==="
echo ""

test_loaded_at_standard
test_not_loaded_at_economy
test_full_content_at_detailed
test_light_budget_caps
test_missing_file
test_symlink_refused
test_template_structure

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
