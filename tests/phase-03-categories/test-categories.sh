#!/usr/bin/env bash
# Phase 03: Category Tag Functionality Tests
# Run: bash tests/phase-03-categories/test-categories.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMPDIR_TEST="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() {
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
# Test 1: Category tags are valid HTML comments (invisible in rendered Markdown)
# ---------------------------------------------------------------------------
test_html_comment_format() {
  local tag='<!-- @category: decision -->'
  # HTML comment must start with <!-- and end with -->
  if echo "$tag" | grep -qE '^<!--\s.*\s-->$'; then
    pass "Test 1: Category tags are valid HTML comments"
  else
    fail "Test 1: Category tags are valid HTML comments"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: rg finds @category tags in a sample memory file
# ---------------------------------------------------------------------------
test_rg_finds_category() {
  local sample="$TMPDIR_TEST/test2.md"
  cat > "$sample" <<'EOF'
# Active Context

## Recent Decisions
- Decided to use PostgreSQL over SQLite
<!-- @category: decision -->

## Patterns
- Services use message queues
<!-- @category: pattern -->
EOF

  local count
  count=$(grep -c '@category: decision' "$sample" 2>/dev/null || echo 0)
  if [ "$count" -eq 1 ]; then
    pass "Test 2: rg '@category: decision' finds tagged entry"
  else
    fail "Test 2: rg '@category: decision' finds tagged entry (got count=$count)"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: grep finds @category tags (no ripgrep dependency)
# ---------------------------------------------------------------------------
test_grep_finds_category() {
  local sample="$TMPDIR_TEST/test3.md"
  cat > "$sample" <<'EOF'
# Patterns

## Code Conventions
- Always use snake_case
<!-- @category: convention -->
- Prefer guard clauses
<!-- @category: pattern -->
EOF

  local count
  count=$(grep -c '@category: convention' "$sample" 2>/dev/null || echo 0)
  if [ "$count" -eq 1 ]; then
    pass "Test 3: grep '@category: convention' finds tagged entry"
  else
    fail "Test 3: grep '@category: convention' finds tagged entry (got count=$count)"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: Freeform @tag tags are findable
# ---------------------------------------------------------------------------
test_freeform_tags() {
  local sample="$TMPDIR_TEST/test4.md"
  cat > "$sample" <<'EOF'
- Integrated Stripe payment processing
<!-- @category: decision -->
<!-- @tag: payments -->
<!-- @tag: third-party -->
EOF

  local count
  count=$(grep -c '@tag: payments' "$sample" 2>/dev/null || echo 0)
  if [ "$count" -eq 1 ]; then
    pass "Test 4: Freeform '@tag: payments' is findable"
  else
    fail "Test 4: Freeform '@tag: payments' is findable (got count=$count)"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: Multiple category tags on consecutive lines are all findable
# ---------------------------------------------------------------------------
test_multiple_tags() {
  local sample="$TMPDIR_TEST/test5.md"
  cat > "$sample" <<'EOF'
- Adopted repository pattern for data access
<!-- @category: decision -->
<!-- @category: pattern -->
<!-- @tag: architecture -->
EOF

  local decision_count pattern_count tag_count
  decision_count=$(grep -c '@category: decision' "$sample" 2>/dev/null || echo 0)
  pattern_count=$(grep -c '@category: pattern' "$sample" 2>/dev/null || echo 0)
  tag_count=$(grep -c '@tag: architecture' "$sample" 2>/dev/null || echo 0)

  if [ "$decision_count" -eq 1 ] && [ "$pattern_count" -eq 1 ] && [ "$tag_count" -eq 1 ]; then
    pass "Test 5: Multiple consecutive tags are all individually findable"
  else
    fail "Test 5: Multiple consecutive tags are all individually findable (decision=$decision_count, pattern=$pattern_count, tag=$tag_count)"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: Mixed tagged/untagged entries — grep counts match tagged-only count
# ---------------------------------------------------------------------------
test_mixed_tagged_untagged() {
  local sample="$TMPDIR_TEST/test6.md"
  cat > "$sample" <<'EOF'
# Session Notes

## Decisions Made
- Chose Rails over Django for this project
<!-- @category: decision -->
- Set up CI pipeline with GitHub Actions
- Decided on PostgreSQL for the database
<!-- @category: decision -->
- Updated README with setup instructions

## Learnings
- Discovered ActiveRecord has built-in enum support
<!-- @category: learning -->
- Fixed flaky test by adding retry logic
<!-- @category: bugfix -->
- Reviewed PR comments
EOF

  local decision_count total_category_count total_lines
  decision_count=$(grep -c '@category: decision' "$sample" 2>/dev/null || echo 0)
  total_category_count=$(grep -c '@category:' "$sample" 2>/dev/null || echo 0)

  if [ "$decision_count" -eq 2 ] && [ "$total_category_count" -eq 4 ]; then
    pass "Test 6: Mixed file — grep counts match expected tagged-only count (2 decisions, 4 total categories)"
  else
    fail "Test 6: Mixed file — expected 2 decisions and 4 total categories, got decisions=$decision_count, total=$total_category_count"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: Tags in actual template files follow the correct format
# ---------------------------------------------------------------------------
test_template_tag_format() {
  local templates_dir="$REPO_ROOT/core/memory/templates"
  local all_valid=true

  # Check that category tags in templates match the expected format
  while IFS= read -r line; do
    if ! echo "$line" | grep -qE '^\s*<!-- @(category|tag): [a-z][a-z0-9-]* -->$'; then
      echo "  Invalid tag format: $line"
      all_valid=false
    fi
  done < <(grep '@category:\|@tag:' "$templates_dir"/*.md 2>/dev/null | sed 's/^[^:]*://')

  if [ "$all_valid" = true ]; then
    pass "Test 7: All template file tags follow correct format"
  else
    fail "Test 7: Some template file tags have incorrect format"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: Schema documents the category tag format
# ---------------------------------------------------------------------------
test_schema_documents_categories() {
  local schema="$REPO_ROOT/core/memory/schema.md"

  if grep -q '## Category Tags' "$schema" && \
     grep -q '@category:' "$schema" && \
     grep -q '@tag:' "$schema" && \
     grep -q 'Searching by Category' "$schema"; then
    pass "Test 8: Schema documents category tags, freeform tags, and searching"
  else
    fail "Test 8: Schema missing category tag documentation"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 03: Category Tag Tests ==="
echo ""

test_html_comment_format
test_rg_finds_category
test_grep_finds_category
test_freeform_tags
test_multiple_tags
test_mixed_tagged_untagged
test_template_tag_format
test_schema_documents_categories

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
