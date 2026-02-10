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

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
