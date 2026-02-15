#!/usr/bin/env bash
# Phase 12: Decision Index Tests
# Run: bash tests/phase-12-decisions/test-decisions.sh

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
}

run_session_start() {
  local workdir="$1"
  cd "$workdir"
  bash "$REPO_ROOT/hooks/session-start.sh" 2>/dev/null || true
  cd "$ORIG_DIR"
}

# --- Test 1: Decision index directive present in session-start output ---
echo "--- Test 1: Decision index directive in session-start output ---"
TEST1_DIR="$TMPDIR_TEST/test1"
mkdir -p "$TEST1_DIR"
setup_project "$TEST1_DIR"
HOME="$TMPDIR_TEST"
mkdir -p "$HOME/.claude/memory"

output=$(cd "$TEST1_DIR" && bash "$REPO_ROOT/hooks/session-start.sh" 2>/dev/null) || true
HOME="$ORIG_HOME"

if echo "$output" | grep -q "decisions/INDEX.md"; then
  pass "Decision index directive present in session-start output"
else
  fail "Decision index directive NOT found in session-start output"
fi

# --- Test 2: Directive present even without decisions/ directory ---
echo "--- Test 2: Directive present without decisions/ directory ---"
TEST2_DIR="$TMPDIR_TEST/test2"
mkdir -p "$TEST2_DIR/.claude/memory/sessions"
# Deliberately NOT creating decisions/ directory
HOME="$TMPDIR_TEST"
mkdir -p "$HOME/.claude/memory"

output=$(cd "$TEST2_DIR" && bash "$REPO_ROOT/hooks/session-start.sh" 2>/dev/null) || true
HOME="$ORIG_HOME"

if echo "$output" | grep -q "decisions/INDEX.md"; then
  pass "Decision index directive present even without decisions/ directory"
else
  fail "Decision index directive NOT found without decisions/ directory"
fi

# --- Test 3: ADR template has YAML frontmatter ---
echo "--- Test 3: ADR template has YAML frontmatter ---"
TEMPLATE="$REPO_ROOT/core/memory/templates/adr-template.md"

first_line=$(head -n 1 "$TEMPLATE")
if [ "$first_line" = "---" ] && grep -q "private: false" "$TEMPLATE"; then
  pass "ADR template has YAML frontmatter with private: false"
else
  fail "ADR template missing YAML frontmatter or private: false"
fi

# --- Test 4: ADR template has Superseded By section ---
echo "--- Test 4: ADR template has Superseded By section ---"
if grep -q "## Superseded By" "$TEMPLATE"; then
  pass "ADR template has ## Superseded By section"
else
  fail "ADR template missing ## Superseded By section"
fi

# --- Results ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
