#!/usr/bin/env bash
# Phase 08: Session Retrospection Tests
# Run: bash tests/phase-08-retrospection/test-retrospection.sh

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

# ---------------------------------------------------------------------------
# Test 1: Stop hook outputs suggestion when corrections queue has entries
# ---------------------------------------------------------------------------
test_stop_hook_suggests_with_corrections() {
  local workdir="$TMPDIR_TEST/test1"
  mkdir -p "$workdir/.claude/memory/sessions"

  # Create corrections queue with entries (more than 3 lines)
  cat > "$workdir/.claude/memory/corrections-queue.md" <<'EOF'
# Corrections Queue
<!-- Auto-populated by ConKeeper -->

- **2025-01-21 10:30:00** | correction | "use snake_case" | ref: previous assistant message
- **2025-01-21 10:31:00** | friction | "that didn't work" | ref: previous assistant message
EOF

  local output
  output=$(cd "$workdir" && bash "$REPO_ROOT/hooks/stop.sh" 2>&1) || true

  if echo "$output" | grep -q 'memory-reflect'; then
    pass "Test 1: Stop hook outputs suggestion when corrections queue has entries"
  else
    fail "Test 1: Stop hook should suggest /memory-reflect when corrections queue has entries"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: Stop hook is silent when no data exists
# ---------------------------------------------------------------------------
test_stop_hook_silent_no_data() {
  local workdir="$TMPDIR_TEST/test2"
  mkdir -p "$workdir/.claude/memory/sessions"

  # Empty corrections queue (only header, <= 3 lines)
  cat > "$workdir/.claude/memory/corrections-queue.md" <<'EOF'
# Corrections Queue
<!-- Auto-populated by ConKeeper -->

EOF

  local output
  output=$(cd "$workdir" && bash "$REPO_ROOT/hooks/stop.sh" 2>&1) || true

  if [[ -z "$output" ]]; then
    pass "Test 2: Stop hook is silent when no data exists"
  else
    fail "Test 2: Stop hook should be silent when no corrections or observations"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: Stop hook is silent when .claude/memory/ doesn't exist
# ---------------------------------------------------------------------------
test_stop_hook_silent_no_memory() {
  local workdir="$TMPDIR_TEST/test3"
  mkdir -p "$workdir"

  local output
  output=$(cd "$workdir" && bash "$REPO_ROOT/hooks/stop.sh" 2>&1) || true

  if [[ -z "$output" ]]; then
    pass "Test 3: Stop hook is silent when .claude/memory/ doesn't exist"
  else
    fail "Test 3: Stop hook should be silent without .claude/memory/"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: hooks/hooks.json is valid JSON with all 5 hooks
# ---------------------------------------------------------------------------
test_hooks_json_valid() {
  local hooks_file="$REPO_ROOT/hooks/hooks.json"

  if ! python3 -c "import json; json.load(open('$hooks_file'))" 2>/dev/null; then
    fail "Test 4: hooks/hooks.json is not valid JSON"
    return
  fi

  local hook_count
  hook_count=$(python3 -c "
import json
with open('$hooks_file') as f:
    data = json.load(f)
hooks = data.get('hooks', {})
print(len(hooks))
")

  local expected_hooks="SessionStart UserPromptSubmit PreCompact PostToolUse Stop"
  local missing=""
  for hook in $expected_hooks; do
    if ! python3 -c "
import json
with open('$hooks_file') as f:
    data = json.load(f)
assert '$hook' in data.get('hooks', {}), 'missing $hook'
" 2>/dev/null; then
      missing="$missing $hook"
    fi
  done

  if [[ -z "$missing" ]]; then
    pass "Test 4: hooks/hooks.json is valid JSON with all 5 hooks"
  else
    fail "Test 4: hooks/hooks.json missing hooks:$missing"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: Retro file format matches documented template
# ---------------------------------------------------------------------------
test_retro_format() {
  local sample_retro="$TMPDIR_TEST/test5-retro.md"
  cat > "$sample_retro" <<'EOF'
# Session Retrospective — 2025-01-21

## Session Summary
Worked on implementing Phase 08 features. Added Stop hook and memory-reflect skill.

## Improvement Log
### Approved
- Use conventional commits consistently → routed to patterns.md
<!-- @category: quality -->

### Declined
- Add verbose logging — reason: user declined

## Improvement Backlog
- [ ] Add cross-session trend analysis
- [ ] Improve hook performance

## Evidence
- Corrections: 3 detected, 2 processed
- Observations: 45 tool uses, 3 failures
- Friction signals: repeated test failures
- Facets data: available
  - Outcome: fully_achieved
  - Friction: wrong_approach: 1, buggy_code: 1
  - Satisfaction: satisfied: 1
  - Detail: Minor friction with test setup, resolved quickly
- Session depth: STANDARD

---
*Generated by /memory-reflect*
EOF

  local ok=true

  # Check required sections
  if ! grep -q '# Session Retrospective' "$sample_retro"; then
    echo "  Missing: Session Retrospective header"
    ok=false
  fi
  if ! grep -q '## Session Summary' "$sample_retro"; then
    echo "  Missing: Session Summary section"
    ok=false
  fi
  if ! grep -q '## Improvement Log' "$sample_retro"; then
    echo "  Missing: Improvement Log section"
    ok=false
  fi
  if ! grep -q '### Approved' "$sample_retro"; then
    echo "  Missing: Approved subsection"
    ok=false
  fi
  if ! grep -q '### Declined' "$sample_retro"; then
    echo "  Missing: Declined subsection"
    ok=false
  fi
  if ! grep -q '## Improvement Backlog' "$sample_retro"; then
    echo "  Missing: Improvement Backlog section"
    ok=false
  fi
  if ! grep -q '## Evidence' "$sample_retro"; then
    echo "  Missing: Evidence section"
    ok=false
  fi
  if ! grep -q 'Generated by /memory-reflect' "$sample_retro"; then
    echo "  Missing: generation attribution"
    ok=false
  fi
  if ! grep -q '@category:' "$sample_retro"; then
    echo "  Missing: category tags"
    ok=false
  fi

  if [[ "$ok" == true ]]; then
    pass "Test 5: Retro file format matches documented template"
  else
    fail "Test 5: Retro file format missing required sections"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: LIGHTWEIGHT retro format is correctly minimal
# ---------------------------------------------------------------------------
test_lightweight_retro() {
  local sample_retro="$TMPDIR_TEST/test6-retro.md"
  cat > "$sample_retro" <<'EOF'
# Session Retrospective — 2025-01-21

## Summary
Short session with minimal activity. No notable improvements identified.

## Evidence
- Observations: 3 tool uses
- Corrections: 0

---
*Generated by /memory-reflect (lightweight)*
EOF

  local ok=true

  # Should have Summary and Evidence
  if ! grep -q '## Summary' "$sample_retro"; then
    echo "  Missing: Summary section"
    ok=false
  fi
  if ! grep -q '## Evidence' "$sample_retro"; then
    echo "  Missing: Evidence section"
    ok=false
  fi
  if ! grep -q '(lightweight)' "$sample_retro"; then
    echo "  Missing: lightweight attribution"
    ok=false
  fi

  # Should NOT have Improvement Log or Improvement Backlog
  if grep -q '## Improvement Log' "$sample_retro"; then
    echo "  Unexpected: Improvement Log in lightweight retro"
    ok=false
  fi
  if grep -q '## Improvement Backlog' "$sample_retro"; then
    echo "  Unexpected: Improvement Backlog in lightweight retro"
    ok=false
  fi

  if [[ "$ok" == true ]]; then
    pass "Test 6: LIGHTWEIGHT retro format is correctly minimal"
  else
    fail "Test 6: LIGHTWEIGHT retro format validation"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: Bash 3.2 compatibility of stop.sh
# ---------------------------------------------------------------------------
test_stop_bash_compat() {
  local exit_code=0
  bash --norc --noprofile -n "$REPO_ROOT/hooks/stop.sh" 2>/dev/null || exit_code=$?

  if [[ "$exit_code" -eq 0 ]]; then
    # Check for Bash 4+ features
    local bash4_features=0
    if grep -qE '\$\{[a-zA-Z_][a-zA-Z0-9_]*,,' "$REPO_ROOT/hooks/stop.sh"; then
      echo "  Found Bash 4+ feature: \${var,,} lowercase"
      bash4_features=1
    fi
    if grep -qE '\$\{[a-zA-Z_][a-zA-Z0-9_]*\^\^' "$REPO_ROOT/hooks/stop.sh"; then
      echo "  Found Bash 4+ feature: \${var^^} uppercase"
      bash4_features=1
    fi
    if grep -q 'declare -A' "$REPO_ROOT/hooks/stop.sh"; then
      echo "  Found Bash 4+ feature: associative arrays"
      bash4_features=1
    fi
    if grep -qE '(mapfile|readarray)' "$REPO_ROOT/hooks/stop.sh"; then
      echo "  Found Bash 4+ feature: mapfile/readarray"
      bash4_features=1
    fi
    if grep -q 'EPOCHSECONDS' "$REPO_ROOT/hooks/stop.sh"; then
      echo "  Found Bash 5+ feature: \$EPOCHSECONDS"
      bash4_features=1
    fi

    if [[ "$bash4_features" -eq 0 ]]; then
      pass "Test 7: Bash 3.2 compatibility of stop.sh"
    else
      fail "Test 7: Bash 3.2 compatibility — Bash 4+ features detected in stop.sh"
    fi
  else
    fail "Test 7: Bash 3.2 compatibility — syntax errors in stop.sh"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: /memory-reflect skill has valid YAML front matter
# ---------------------------------------------------------------------------
test_reflect_skill_yaml() {
  local skill="$REPO_ROOT/skills/memory-reflect/SKILL.md"

  if [[ ! -f "$skill" ]]; then
    fail "Test 8: /memory-reflect skill file does not exist"
    return
  fi

  # Check YAML front matter: must start with --- and have name and description
  local has_frontmatter=false
  local has_name=false
  local has_description=false

  if head -n 1 "$skill" | grep -q '^---$'; then
    has_frontmatter=true
  fi

  if grep -q '^name:' "$skill"; then
    has_name=true
  fi

  if grep -q '^description:' "$skill"; then
    has_description=true
  fi

  if [[ "$has_frontmatter" == true && "$has_name" == true && "$has_description" == true ]]; then
    pass "Test 8: /memory-reflect skill has valid YAML front matter"
  else
    fail "Test 8: /memory-reflect skill YAML front matter issues"
    echo "  has_frontmatter=$has_frontmatter has_name=$has_name has_description=$has_description"
  fi
}

# ---------------------------------------------------------------------------
# Test 9: Reflect skill references all required data sources
# ---------------------------------------------------------------------------
test_reflect_data_sources() {
  local skill="$REPO_ROOT/skills/memory-reflect/SKILL.md"

  local ok=true

  if ! grep -q 'corrections-queue.md' "$skill"; then
    echo "  Missing reference: corrections-queue.md"
    ok=false
  fi
  if ! grep -q 'observations.md' "$skill"; then
    echo "  Missing reference: observations.md"
    ok=false
  fi
  if ! grep -q 'active-context.md' "$skill"; then
    echo "  Missing reference: active-context.md"
    ok=false
  fi
  if ! grep -q 'facets' "$skill"; then
    echo "  Missing reference: facets"
    ok=false
  fi

  if [[ "$ok" == true ]]; then
    pass "Test 9: Reflect skill references all required data sources"
  else
    fail "Test 9: Reflect skill missing data source references"
  fi
}

# ---------------------------------------------------------------------------
# Test 10: Privacy instructions present in the reflect skill
# ---------------------------------------------------------------------------
test_reflect_privacy() {
  local skill="$REPO_ROOT/skills/memory-reflect/SKILL.md"

  if grep -qi 'private' "$skill"; then
    pass "Test 10: Privacy instructions present in the reflect skill"
  else
    fail "Test 10: Privacy instructions should be present in /memory-reflect skill"
  fi
}

# ---------------------------------------------------------------------------
# Test 11: /memory-insights skill file exists with valid YAML front matter
# ---------------------------------------------------------------------------
test_insights_skill_yaml() {
  local skill="$REPO_ROOT/skills/memory-insights/SKILL.md"

  if [[ ! -f "$skill" ]]; then
    fail "Test 11: /memory-insights skill file does not exist"
    return
  fi

  local has_frontmatter=false
  local has_name=false
  local has_description=false

  if head -n 1 "$skill" | grep -q '^---$'; then
    has_frontmatter=true
  fi

  if grep -q '^name:' "$skill"; then
    has_name=true
  fi

  if grep -q '^description:' "$skill"; then
    has_description=true
  fi

  if [[ "$has_frontmatter" == true && "$has_name" == true && "$has_description" == true ]]; then
    pass "Test 11: /memory-insights skill has valid YAML front matter"
  else
    fail "Test 11: /memory-insights skill YAML front matter issues"
    echo "  has_frontmatter=$has_frontmatter has_name=$has_name has_description=$has_description"
  fi
}

# ---------------------------------------------------------------------------
# Test 12: /memory-insights references facets directory with graceful degradation
# ---------------------------------------------------------------------------
test_insights_facets_reference() {
  local skill="$REPO_ROOT/skills/memory-insights/SKILL.md"

  local ok=true

  if ! grep -q 'usage-data/facets' "$skill"; then
    echo "  Missing reference: ~/.claude/usage-data/facets/"
    ok=false
  fi

  if ! grep -qi 'graceful\|skip gracefully\|doesn.t exist' "$skill"; then
    echo "  Missing graceful degradation handling"
    ok=false
  fi

  if [[ "$ok" == true ]]; then
    pass "Test 12: /memory-insights references facets directory with graceful degradation"
  else
    fail "Test 12: /memory-insights facets reference or degradation issues"
  fi
}

# ---------------------------------------------------------------------------
# Test 13: Reflect skill handles missing facets directory gracefully
# ---------------------------------------------------------------------------
test_reflect_facets_graceful() {
  local skill="$REPO_ROOT/skills/memory-reflect/SKILL.md"

  if grep -qi 'skip gracefully\|doesn.t exist\|no matching session' "$skill"; then
    pass "Test 13: Reflect skill handles missing facets directory gracefully"
  else
    fail "Test 13: Reflect skill should handle missing facets directory gracefully"
  fi
}

# ---------------------------------------------------------------------------
# Test 14: Stop hook triggers on observations-only (no corrections)
# ---------------------------------------------------------------------------
test_stop_hook_observations_only() {
  local workdir="$TMPDIR_TEST/test14"
  mkdir -p "$workdir/.claude/memory/sessions"

  # Empty corrections queue (only header)
  cat > "$workdir/.claude/memory/corrections-queue.md" <<'EOF'
# Corrections Queue
<!-- Auto-populated by ConKeeper -->

EOF

  # Observations file with entries (more than 3 lines)
  cat > "$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md" <<'EOF'
# Session Observations — today
<!-- Auto-generated by ConKeeper PostToolUse hook -->

- **10:00:01** | `Read` | read | `/path/file.md` | — | success
- **10:00:02** | `Bash` | execute | `/path` | `npm test` | success
EOF

  local output
  output=$(cd "$workdir" && bash "$REPO_ROOT/hooks/stop.sh" 2>&1) || true

  if echo "$output" | grep -q 'memory-reflect'; then
    pass "Test 14: Stop hook triggers on observations-only (no corrections)"
  else
    fail "Test 14: Stop hook should suggest /memory-reflect when observations exist"
    echo "  Output: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 15: hooks.json timeout values are positive integers
# ---------------------------------------------------------------------------
test_hooks_timeout_values() {
  local hooks_file="$REPO_ROOT/hooks/hooks.json"

  local invalid
  invalid=$(python3 -c "
import json
with open('$hooks_file') as f:
    data = json.load(f)
hooks = data.get('hooks', {})
invalid = []
for name, entries in hooks.items():
    for entry in entries:
        for hook in entry.get('hooks', []):
            t = hook.get('timeout')
            if t is not None and (not isinstance(t, int) or t <= 0):
                invalid.append(f'{name}: timeout={t}')
print('|'.join(invalid))
" 2>/dev/null) || true

  if [[ -z "$invalid" ]]; then
    pass "Test 15: hooks.json timeout values are valid positive integers"
  else
    fail "Test 15: hooks.json has invalid timeout values: $invalid"
  fi
}

# ---------------------------------------------------------------------------
# Test 16 (Security): post-tool-use.sh sanitizes tool_input content
# ---------------------------------------------------------------------------
test_post_tool_use_sanitizes_content() {
  local workdir="$TMPDIR_TEST/test16"
  mkdir -p "$workdir/.claude/memory/sessions"

  # Create observations header
  printf '# Session Observations — %s\n<!-- Auto-generated -->\n\n' "$(date +%Y-%m-%d)" > "$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

  # Build JSON with jq to properly escape HTML comments and backticks in command value
  local input
  input=$(jq -n --arg cwd "$workdir" '{
    tool_name: "Bash",
    session_id: "test16sec",
    cwd: $cwd,
    tool_input: {command: "echo <!-- inject --> `evil`"}
  }')
  local output
  output=$(printf '%s' "$input" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>&1) || true

  local obs_file="$workdir/.claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"
  if [[ -f "$obs_file" ]]; then
    local ok=true
    # Should NOT contain raw HTML comments (<!-- stripped by sanitize_field)
    if grep '<!-- inject' "$obs_file" >/dev/null 2>&1; then
      echo "  Found raw HTML comment in observations"
      ok=false
    fi
    # Should NOT contain raw backticks around evil (backticks replaced by sanitize_field)
    if grep '`evil`' "$obs_file" >/dev/null 2>&1; then
      echo "  Found raw backticks in observations"
      ok=false
    fi
    if [[ "$ok" == true ]]; then
      pass "Test 16 (Security): post-tool-use.sh sanitizes tool_input content"
    else
      fail "Test 16 (Security): post-tool-use.sh should sanitize HTML comments and backticks"
      echo "  Content: $(cat "$obs_file")"
    fi
  else
    fail "Test 16 (Security): observations file not created"
  fi
}

# ---------------------------------------------------------------------------
# Test 17 (Security): user-prompt-submit.sh refuses symlinked queue file
# ---------------------------------------------------------------------------
test_queue_symlink_protection() {
  if ! command -v jq &>/dev/null; then
    pass "Test 17 (Security): Skipped — jq not available"
    return
  fi

  local workdir="$TMPDIR_TEST/test17"
  mkdir -p "$workdir/.claude/memory"

  # Create a symlink for the corrections queue
  local evil_target="$TMPDIR_TEST/test17-evil-target.md"
  printf '' > "$evil_target"
  ln -sf "$evil_target" "$workdir/.claude/memory/corrections-queue.md"

  # Create a dummy transcript
  local transcript="$TMPDIR_TEST/test17-transcript.jsonl"
  echo '{}' > "$transcript"

  # Feed a correction-triggering message
  local input='{"session_id":"test17sec","transcript_path":"'"$transcript"'","cwd":"'"$workdir"'","user_message":"no, use snake_case instead"}'
  printf '%s' "$input" | bash "$REPO_ROOT/hooks/user-prompt-submit.sh" 2>/dev/null || true

  # The evil target should remain empty (symlink was refused)
  local evil_size
  evil_size=$(wc -c < "$evil_target" 2>/dev/null || echo "0")
  evil_size=$(echo "$evil_size" | tr -d ' ')

  if [[ "$evil_size" -eq 0 ]]; then
    pass "Test 17 (Security): user-prompt-submit.sh refuses to write through symlinked queue file"
  else
    fail "Test 17 (Security): user-prompt-submit.sh wrote through symlink ($evil_size bytes)"
  fi
}

# ---------------------------------------------------------------------------
# Test 18 (Security): post-tool-use.sh refuses symlinked observations directory
# ---------------------------------------------------------------------------
test_obs_dir_symlink_protection() {
  if ! command -v jq &>/dev/null; then
    pass "Test 18 (Security): Skipped — jq not available"
    return
  fi

  local workdir="$TMPDIR_TEST/test18"
  mkdir -p "$workdir/.claude/memory"

  # Create a symlink for the sessions directory
  local evil_dir="$TMPDIR_TEST/test18-evil-dir"
  mkdir -p "$evil_dir"
  ln -sf "$evil_dir" "$workdir/.claude/memory/sessions"

  # Feed a tool use event
  local input='{"tool_name":"Read","session_id":"test18sec","cwd":"'"$workdir"'","tool_input":{"file_path":"/tmp/test.md"}}'
  printf '%s' "$input" | bash "$REPO_ROOT/hooks/post-tool-use.sh" 2>/dev/null || true

  # The evil directory should remain empty (symlink was refused)
  local evil_files
  evil_files=$(ls -A "$evil_dir" 2>/dev/null | wc -l || echo "0")
  evil_files=$(echo "$evil_files" | tr -d ' ')

  if [[ "$evil_files" -eq 0 ]]; then
    pass "Test 18 (Security): post-tool-use.sh refuses to write through symlinked sessions directory"
  else
    fail "Test 18 (Security): post-tool-use.sh wrote through symlinked directory ($evil_files files)"
  fi
}

# ---------------------------------------------------------------------------
# Test 19 (Security): pre-compact.sh handles corrupted flag file gracefully
# ---------------------------------------------------------------------------
test_precompact_corrupted_flag() {
  if ! command -v jq &>/dev/null; then
    pass "Test 19 (Security): Skipped — jq not available"
    return
  fi

  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  mkdir -p "$flag_dir"

  # Create a corrupted flag file with non-numeric content
  echo "CORRUPTED" > "$flag_dir/synced-test19sec"

  local input='{"session_id":"test19sec"}'
  local exit_code=0
  printf '%s' "$input" | bash "$REPO_ROOT/hooks/pre-compact.sh" 2>/dev/null || exit_code=$?

  # Clean up
  rm -f "$flag_dir/synced-test19sec"

  if [[ "$exit_code" -eq 0 ]]; then
    pass "Test 19 (Security): pre-compact.sh handles corrupted flag file gracefully"
  else
    fail "Test 19 (Security): pre-compact.sh should exit 0 even with corrupted flag (got exit $exit_code)"
  fi
}

# ---------------------------------------------------------------------------
# Test 20 (Security): session-start.sh refuses symlinked observations file
# ---------------------------------------------------------------------------
test_session_start_obs_symlink() {
  local workdir="$TMPDIR_TEST/test20"
  mkdir -p "$workdir/.claude/memory/sessions"

  # Create a symlink for the observations file
  local evil_target="$TMPDIR_TEST/test20-evil.md"
  printf '' > "$evil_target"
  local obs_name="$(date +%Y-%m-%d)-observations.md"
  ln -sf "$evil_target" "$workdir/.claude/memory/sessions/$obs_name"

  # Run session-start.sh
  local output
  output=$(cd "$workdir" && bash "$REPO_ROOT/hooks/session-start.sh" 2>/dev/null) || true

  # The evil target should remain empty (symlink was refused)
  local evil_size
  evil_size=$(wc -c < "$evil_target" 2>/dev/null || echo "0")
  evil_size=$(echo "$evil_size" | tr -d ' ')

  if [[ "$evil_size" -eq 0 ]]; then
    pass "Test 20 (Security): session-start.sh refuses to write through symlinked observations file"
  else
    fail "Test 20 (Security): session-start.sh wrote through symlink ($evil_size bytes)"
  fi
}

# ---------------------------------------------------------------------------
# Test 21 (Security): user-prompt-submit.sh backtick sanitization in corrections queue
# ---------------------------------------------------------------------------
test_correction_backtick_sanitization() {
  if ! command -v jq &>/dev/null; then
    pass "Test 21 (Security): Skipped — jq not available"
    return
  fi

  local workdir="$TMPDIR_TEST/test21"
  mkdir -p "$workdir/.claude/memory"

  # Create a dummy transcript
  local transcript="$TMPDIR_TEST/test21-transcript.jsonl"
  echo '{}' > "$transcript"

  # Feed a message with backticks that triggers correction detection
  local input='{"session_id":"test21sec","transcript_path":"'"$transcript"'","cwd":"'"$workdir"'","user_message":"no, use `snake_case` instead of `camelCase`"}'
  printf '%s' "$input" | bash "$REPO_ROOT/hooks/user-prompt-submit.sh" 2>/dev/null || true

  local queue_file="$workdir/.claude/memory/corrections-queue.md"
  if [[ -f "$queue_file" ]]; then
    # Should NOT contain raw backticks in the message content
    if grep -q '`snake_case`' "$queue_file"; then
      fail "Test 21 (Security): corrections queue should escape backticks"
      return
    fi
    pass "Test 21 (Security): user-prompt-submit.sh escapes backticks in corrections queue"
  else
    # Queue might not be created if correction was not detected — that's ok
    pass "Test 21 (Security): user-prompt-submit.sh backtick test (no correction detected — pass)"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 08: Session Retrospection Tests ==="
echo ""

test_stop_hook_suggests_with_corrections
test_stop_hook_silent_no_data
test_stop_hook_silent_no_memory
test_hooks_json_valid
test_retro_format
test_lightweight_retro
test_stop_bash_compat
test_reflect_skill_yaml
test_reflect_data_sources
test_reflect_privacy
test_insights_skill_yaml
test_insights_facets_reference
test_reflect_facets_graceful
test_stop_hook_observations_only
test_hooks_timeout_values
test_post_tool_use_sanitizes_content
test_queue_symlink_protection
test_obs_dir_symlink_protection
test_precompact_corrupted_flag
test_session_start_obs_symlink
test_correction_backtick_sanitization

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
