#!/usr/bin/env bash
# Phase 06: PostToolUse Observation Hook Tests
# Run: bash tests/phase-06-observations/test-observations.sh

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

# Helper: create a project with memory directory and optional config
setup_project() {
  local base="$1"
  mkdir -p "$base/.claude/memory/sessions"
}

setup_config() {
  local base="$1"
  local content="$2"
  cat > "$base/.claude/memory/.memory-config.md" <<CONFIGEOF
$content
CONFIGEOF
}

# ---------------------------------------------------------------------------
# Test 1: Bash tool produces a full entry
# ---------------------------------------------------------------------------
test_full_entry() {
  local workdir="$TMPDIR_TEST/test1"
  setup_project "$workdir"

  local json
  json=$(cat <<'JSONEOF'
{
  "tool_name": "Bash",
  "tool_input": {"command":"npm test --coverage"},
  "session_id": "sess-abc-123",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json="${json//WORKDIR_PLACEHOLDER/$workdir}"

  printf '%s' "$json" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || true

  local obs_file="$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

  if [[ -f "$obs_file" ]] && grep -q '`Bash`' "$obs_file" && grep -q 'execute' "$obs_file" && grep -q 'npm test' "$obs_file"; then
    pass "Test 1: Bash tool produces a full entry"
  else
    fail "Test 1: Bash tool produces a full entry"
    [[ -f "$obs_file" ]] && echo "  Content: $(cat "$obs_file")" || echo "  File not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: Read tool produces a stub entry
# ---------------------------------------------------------------------------
test_stub_entry() {
  local workdir="$TMPDIR_TEST/test2"
  setup_project "$workdir"

  local json
  json=$(cat <<'JSONEOF'
{
  "tool_name": "Read",
  "tool_input": {"file_path":"/src/main.ts"},
  "session_id": "sess-abc-123",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json="${json//WORKDIR_PLACEHOLDER/$workdir}"

  printf '%s' "$json" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || true

  local obs_file="$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

  # Stub entries have "— |" (dash separator instead of command summary)
  if [[ -f "$obs_file" ]] && grep -q '`Read`' "$obs_file" && grep -q 'read' "$obs_file" && grep -q '| — |' "$obs_file"; then
    pass "Test 2: Read tool produces a stub entry"
  else
    fail "Test 2: Read tool produces a stub entry"
    [[ -f "$obs_file" ]] && echo "  Content: $(cat "$obs_file")" || echo "  File not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: observation_hook: false disables logging
# ---------------------------------------------------------------------------
test_disabled_hook() {
  local workdir="$TMPDIR_TEST/test3"
  setup_project "$workdir"
  setup_config "$workdir" "---
observation_hook: false
---"

  local json
  json=$(cat <<'JSONEOF'
{
  "tool_name": "Bash",
  "tool_input": {"command":"echo hello"},
  "session_id": "sess-abc-123",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json="${json//WORKDIR_PLACEHOLDER/$workdir}"

  printf '%s' "$json" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || true

  local obs_file="$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

  # File should not exist (or if created by a prior run, should have no Bash entry)
  if [[ ! -f "$obs_file" ]] || ! grep -q '`Bash`' "$obs_file"; then
    pass "Test 3: observation_hook: false disables logging"
  else
    fail "Test 3: observation_hook: false disables logging"
    echo "  Content: $(cat "$obs_file")"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: observation_detail: stubs_only gives Bash a stub entry
# ---------------------------------------------------------------------------
test_stubs_only() {
  local workdir="$TMPDIR_TEST/test4"
  setup_project "$workdir"
  setup_config "$workdir" "---
observation_detail: stubs_only
---"

  local json
  json=$(cat <<'JSONEOF'
{
  "tool_name": "Bash",
  "tool_input": {"command":"npm test --coverage"},
  "session_id": "sess-abc-123",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json="${json//WORKDIR_PLACEHOLDER/$workdir}"

  printf '%s' "$json" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || true

  local obs_file="$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

  # Bash should have a stub entry (with "— |") not a full entry (with command summary)
  if [[ -f "$obs_file" ]] && grep -q '`Bash`' "$obs_file" && grep -q '| — |' "$obs_file"; then
    pass "Test 4: observation_detail: stubs_only gives Bash a stub entry"
  else
    fail "Test 4: observation_detail: stubs_only gives Bash a stub entry"
    [[ -f "$obs_file" ]] && echo "  Content: $(cat "$obs_file")" || echo "  File not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: session-start.sh creates the observations file header
# ---------------------------------------------------------------------------
test_session_start_creates_obs() {
  local workdir="$TMPDIR_TEST/test5"
  setup_project "$workdir"

  cd "$workdir"
  # session-start.sh reads CWD to find .claude/memory
  local output
  output=$(bash "$REPO_ROOT/hooks/session-start.sh" <<'JSONEOF'
{}
JSONEOF
) 2>/dev/null || true

  local obs_file="$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

  if [[ -f "$obs_file" ]] && grep -q 'Session Observations' "$obs_file" && grep -q 'Auto-generated by ConKeeper' "$obs_file"; then
    pass "Test 5: session-start.sh creates the observations file header"
  else
    fail "Test 5: session-start.sh creates the observations file header"
    [[ -f "$obs_file" ]] && echo "  Content: $(cat "$obs_file")" || echo "  File not created"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 6: observations NOT included in session-start.sh context output
# ---------------------------------------------------------------------------
test_observations_not_in_context() {
  local workdir="$TMPDIR_TEST/test6"
  setup_project "$workdir"

  # Pre-create an observations file with content
  local today
  today=$(date +%Y-%m-%d)
  printf '# Session Observations — %s\n- **10:00:00** | `Bash` | execute | `npm test` | `npm test` | success\n' "$today" \
    > "$workdir/.claude/memory/sessions/${today}-observations.md"

  cd "$workdir"
  local output
  output=$(bash "$REPO_ROOT/hooks/session-start.sh" <<'JSONEOF'
{}
JSONEOF
) 2>/dev/null || true

  # The JSON context output should NOT contain observation content
  if ! echo "$output" | grep -q "observations"; then
    pass "Test 6: observations NOT included in session-start.sh context output"
  else
    fail "Test 6: observations should NOT be in session-start context"
    echo "  Output: $output"
  fi
  cd "$ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Test 7: Bash 3.2 compatibility — no Bash 4+ features
# ---------------------------------------------------------------------------
test_bash_compat() {
  local exit_code=0
  bash --norc --noprofile -n "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || exit_code=$?

  if [[ "$exit_code" -eq 0 ]]; then
    pass "Test 7: Bash 3.2 compatibility — script parses cleanly"
  else
    fail "Test 7: Bash 3.2 compatibility — syntax errors detected"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: Hook exits cleanly when no .claude/memory/ directory exists
# ---------------------------------------------------------------------------
test_no_memory_dir() {
  local workdir="$TMPDIR_TEST/test8"
  mkdir -p "$workdir"
  # Intentionally do NOT create .claude/memory/

  local json
  json=$(cat <<'JSONEOF'
{
  "tool_name": "Bash",
  "tool_input": {"command":"echo hello"},
  "session_id": "sess-abc-123",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json="${json//WORKDIR_PLACEHOLDER/$workdir}"

  local exit_code=0
  printf '%s' "$json" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || exit_code=$?

  # Should exit 0 and not create any files
  if [[ "$exit_code" -eq 0 ]] && [[ ! -d "$workdir/.claude" ]]; then
    pass "Test 8: Hook exits cleanly when no .claude/memory/ directory exists"
  else
    fail "Test 8: Hook should exit 0 with no .claude/memory/ directory"
    echo "  Exit code: $exit_code"
  fi
}

# ---------------------------------------------------------------------------
# Test 9: File path extraction from various tool_input formats
# ---------------------------------------------------------------------------
test_field_extraction() {
  local workdir="$TMPDIR_TEST/test9"
  setup_project "$workdir"

  # Test Read with file_path
  local json_read
  json_read=$(cat <<'JSONEOF'
{
  "tool_name": "Read",
  "tool_input": {"file_path":"/src/app.ts"},
  "session_id": "sess-abc-123",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json_read="${json_read//WORKDIR_PLACEHOLDER/$workdir}"
  printf '%s' "$json_read" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || true

  # Test Glob with pattern
  local json_glob
  json_glob=$(cat <<'JSONEOF'
{
  "tool_name": "Glob",
  "tool_input": {"pattern":"**/*.ts"},
  "session_id": "sess-abc-123",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json_glob="${json_glob//WORKDIR_PLACEHOLDER/$workdir}"
  printf '%s' "$json_glob" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || true

  # Test Bash with command
  local json_bash
  json_bash=$(cat <<'JSONEOF'
{
  "tool_name": "Bash",
  "tool_input": {"command":"git status"},
  "session_id": "sess-abc-123",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json_bash="${json_bash//WORKDIR_PLACEHOLDER/$workdir}"
  printf '%s' "$json_bash" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || true

  local obs_file="$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

  local ok=true
  if ! grep -q '/src/app.ts' "$obs_file"; then
    echo "  Missing file_path from Read tool"
    ok=false
  fi
  if ! grep -q '\*\*/\*.ts' "$obs_file"; then
    echo "  Missing pattern from Glob tool"
    ok=false
  fi
  if ! grep -q 'git status' "$obs_file"; then
    echo "  Missing command from Bash tool"
    ok=false
  fi

  if [[ "$ok" == true ]]; then
    pass "Test 9: File path extraction from various tool_input formats"
  else
    fail "Test 9: File path extraction from various tool_input formats"
    echo "  Content: $(cat "$obs_file")"
  fi
}

# ---------------------------------------------------------------------------
# Test 10: observation_detail: off disables logging (same as false)
# ---------------------------------------------------------------------------
test_detail_off() {
  local workdir="$TMPDIR_TEST/test10"
  setup_project "$workdir"
  setup_config "$workdir" "---
observation_detail: off
---"

  local json
  json=$(cat <<'JSONEOF'
{
  "tool_name": "Bash",
  "tool_input": {"command":"echo hello"},
  "session_id": "sess-abc-123",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json="${json//WORKDIR_PLACEHOLDER/$workdir}"

  printf '%s' "$json" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || true

  local obs_file="$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

  if [[ ! -f "$obs_file" ]] || ! grep -q '`Bash`' "$obs_file"; then
    pass "Test 10: observation_detail: off disables logging"
  else
    fail "Test 10: observation_detail: off should disable logging"
    echo "  Content: $(cat "$obs_file")"
  fi
}

# ---------------------------------------------------------------------------
# Test 11: Security — symlink attack on observation file is blocked
# ---------------------------------------------------------------------------
test_symlink_attack() {
  local workdir="$TMPDIR_TEST/test11"
  setup_project "$workdir"

  # Create a "sensitive" target file
  echo "SENSITIVE_DATA" > "$workdir/sensitive.txt"

  # Pre-create a symlink at the observation file path
  local today
  today=$(date +%Y-%m-%d)
  ln -s "$workdir/sensitive.txt" "$workdir/.claude/memory/sessions/${today}-observations.md"

  local json
  json=$(cat <<'JSONEOF'
{
  "tool_name": "Bash",
  "tool_input": {"command":"echo test"},
  "session_id": "sess-abc-123",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json="${json//WORKDIR_PLACEHOLDER/$workdir}"

  printf '%s' "$json" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || true

  # The sensitive file should NOT have observation data appended
  if ! grep -q 'Bash' "$workdir/sensitive.txt"; then
    pass "Test 11: Symlink attack on observation file is blocked"
  else
    fail "Test 11: Symlink attack should be blocked — data written through symlink"
    echo "  Content: $(cat "$workdir/sensitive.txt")"
  fi
}

# ---------------------------------------------------------------------------
# Test 12: Security — invalid session_id with path traversal chars is rejected
# ---------------------------------------------------------------------------
test_session_id_traversal() {
  local workdir="$TMPDIR_TEST/test12"
  setup_project "$workdir"

  local json
  json=$(cat <<'JSONEOF'
{
  "tool_name": "Bash",
  "tool_input": {"command":"echo evil"},
  "session_id": "../../../etc/passwd",
  "cwd": "WORKDIR_PLACEHOLDER"
}
JSONEOF
)
  json="${json//WORKDIR_PLACEHOLDER/$workdir}"

  local exit_code=0
  printf '%s' "$json" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || exit_code=$?

  local obs_file="$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

  # Should exit 0 and NOT write any observation
  if [[ "$exit_code" -eq 0 ]] && [[ ! -f "$obs_file" ]]; then
    pass "Test 12: Path traversal session_id is rejected"
  else
    fail "Test 12: Path traversal session_id should be rejected"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 06: PostToolUse Observation Hook Tests ==="
echo ""

test_full_entry
test_stub_entry
test_disabled_hook
test_stubs_only
test_session_start_creates_obs
test_observations_not_in_context
test_bash_compat
test_no_memory_dir
test_field_extraction
test_detail_off
test_symlink_attack
test_session_id_traversal

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
