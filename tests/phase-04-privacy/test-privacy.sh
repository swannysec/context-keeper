#!/usr/bin/env bash
# Phase 04: Privacy Tag Functionality Tests
# Run: bash tests/phase-04-privacy/test-privacy.sh

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

# Source shared privacy functions from the canonical location
. "$REPO_ROOT/hooks/lib-privacy.sh"

# ---------------------------------------------------------------------------
# Test 1: strip_private removes <private> blocks from content
# ---------------------------------------------------------------------------
test_strip_private_basic() {
  local input
  input="$(cat <<'EOF'
## API Configuration
- Production endpoint: https://api.example.com/v2
<private>
- API key: sk-proj-abc123
- Webhook secret: whsec_xyz789
</private>
- Rate limit: 1000 req/min
EOF
)"

  local result
  result=$(printf '%s' "$input" | strip_private)

  if echo "$result" | grep -q "Production endpoint" && \
     echo "$result" | grep -q "Rate limit" && \
     ! echo "$result" | grep -q "API key" && \
     ! echo "$result" | grep -q "Webhook secret"; then
    pass "Test 1: strip_private removes <private> block content"
  else
    fail "Test 1: strip_private removes <private> block content"
    echo "  Got: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: sed pattern works with BSD sed (macOS) — validates on current platform
# ---------------------------------------------------------------------------
test_sed_bsd_compat() {
  local sample="$TMPDIR_TEST/test2.md"
  cat > "$sample" <<'EOF'
Line before
<private>
Secret stuff here
</private>
Line after
EOF

  local result
  result=$(sed '/^[[:space:]]*<private>/,/^[[:space:]]*<\/private>/d' "$sample")

  if echo "$result" | grep -q "Line before" && \
     echo "$result" | grep -q "Line after" && \
     ! echo "$result" | grep -q "Secret"; then
    pass "Test 2: sed pattern works on current platform (BSD/GNU compat)"
  else
    fail "Test 2: sed pattern failed on current platform"
    echo "  Got: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: is_file_private returns true for private: true in front matter
# ---------------------------------------------------------------------------
test_is_file_private_true() {
  local sample="$TMPDIR_TEST/test3.md"
  cat > "$sample" <<'EOF'
---
private: true
---
# Sensitive Credentials
Some secret content
EOF

  if is_file_private "$sample"; then
    pass "Test 3: is_file_private returns true for private: true"
  else
    fail "Test 3: is_file_private should return true for private: true"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: is_file_private returns false for non-private files
# ---------------------------------------------------------------------------
test_is_file_private_false() {
  local sample="$TMPDIR_TEST/test4.md"
  cat > "$sample" <<'EOF'
---
title: Regular File
---
# Normal Content
Nothing private here
EOF

  if ! is_file_private "$sample"; then
    pass "Test 4: is_file_private returns false for non-private file"
  else
    fail "Test 4: is_file_private should return false for non-private file"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: strip_private processes tags regardless of code fence context
# (caller is responsible for excluding code-fenced content)
# ---------------------------------------------------------------------------
test_code_fence_caller_responsibility() {
  local input
  input="$(cat <<'TESTEOF'
# Documentation

Here is an example of privacy tags:

```markdown
<private>
This is just documentation, not a real private block
</private>
```

Real content here
TESTEOF
)"

  local result
  result=$(printf '%s' "$input" | strip_private)

  # strip_private processes line-by-line and will strip <private> tags
  # even inside code fences. This is documented behavior: the caller is
  # responsible for handling code fences before invoking strip_private.
  if echo "$result" | grep -q "Documentation" && \
     echo "$result" | grep -q "Real content here"; then
    pass "Test 5: Content outside private blocks preserved (code fence handling is caller responsibility)"
  else
    fail "Test 5: Content outside private blocks should be preserved"
    echo "  Got: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: File with no privacy tags passes through unchanged
# ---------------------------------------------------------------------------
test_no_tags_passthrough() {
  local input
  input="$(cat <<'EOF'
# Project Patterns

## Code Conventions
- Always use snake_case for Ruby method names
<!-- @category: convention -->
- Error handlers return Result objects, never raise
<!-- @category: pattern -->
EOF
)"

  local result
  result=$(printf '%s' "$input" | strip_private)

  if [ "$result" = "$input" ]; then
    pass "Test 6: File with no privacy tags passes through unchanged"
  else
    fail "Test 6: File with no privacy tags should pass through unchanged"
    echo "  Input length: ${#input}"
    echo "  Result length: ${#result}"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: Multiple <private> blocks are all stripped
# ---------------------------------------------------------------------------
test_multiple_private_blocks() {
  local input
  input="$(cat <<'EOF'
## API Keys
- Service A endpoint: https://a.example.com
<private>
- Service A key: sk-aaa111
</private>
- Service B endpoint: https://b.example.com
<private>
- Service B key: sk-bbb222
- Service B secret: sec-bbb333
</private>
- Rate limits apply to both services
EOF
)"

  local result
  result=$(printf '%s' "$input" | strip_private)

  if echo "$result" | grep -q "Service A endpoint" && \
     echo "$result" | grep -q "Service B endpoint" && \
     echo "$result" | grep -q "Rate limits" && \
     ! echo "$result" | grep -q "sk-aaa111" && \
     ! echo "$result" | grep -q "sk-bbb222" && \
     ! echo "$result" | grep -q "sec-bbb333"; then
    pass "Test 7: Multiple <private> blocks are all stripped"
  else
    fail "Test 7: Multiple <private> blocks should all be stripped"
    echo "  Got: $result"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: is_file_private rejects private: true in body text (no front matter)
# ---------------------------------------------------------------------------
test_is_file_private_body_false_positive() {
  local sample="$TMPDIR_TEST/test8_no_frontmatter.md"
  cat > "$sample" <<'EOF'
# Regular Document

This file has no YAML front matter.
private: true
This should NOT be detected as private.
EOF

  if ! is_file_private "$sample"; then
    pass "Test 8: is_file_private rejects private: true in body (no front matter)"
  else
    fail "Test 8: is_file_private should reject private: true without front matter delimiters"
  fi

  # Also test: private: true in body AFTER valid front matter
  local sample2="$TMPDIR_TEST/test8_body_text.md"
  cat > "$sample2" <<'EOF'
---
title: Normal File
---
# Content
private: true
This is just body text, not a front matter field.
EOF

  if ! is_file_private "$sample2"; then
    pass "Test 8b: is_file_private rejects private: true in body after front matter"
  else
    fail "Test 8b: is_file_private should reject private: true in body text"
  fi
}

# ---------------------------------------------------------------------------
# Test 9: is_file_private rejects partial match (private: trueish)
# ---------------------------------------------------------------------------
test_is_file_private_partial_match() {
  local sample="$TMPDIR_TEST/test9.md"
  cat > "$sample" <<'EOF'
---
private: trueish
---
# Content
EOF

  if ! is_file_private "$sample"; then
    pass "Test 9: is_file_private rejects partial match (private: trueish)"
  else
    fail "Test 9: is_file_private should reject private: trueish"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "=== Phase 04: Privacy Tag Tests ==="
echo ""

test_strip_private_basic
test_sed_bsd_compat
test_is_file_private_true
test_is_file_private_false
test_code_fence_caller_responsibility
test_no_tags_passthrough
test_multiple_private_blocks
test_is_file_private_body_false_positive
test_is_file_private_partial_match

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
