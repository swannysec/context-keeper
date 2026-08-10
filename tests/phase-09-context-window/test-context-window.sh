#!/usr/bin/env bash
# Phase 09: Context Window Auto-Detection Tests
# Run: bash tests/phase-09-context-window/test-context-window.sh
#
# Window resolution (post-1M-default):
#   - Default (no model anywhere) .............. 1,000,000
#   - opus / sonnet / *[1m] / unknown / future . 1,000,000
#   - *haiku* .................................. 200,000
#   - Model is read from the transcript's last assistant .message.model FIRST,
#     falling back to settings.json .model.
#   - Explicit .memory-config.md context_window_tokens overrides everything.
#   - CLAUDE_CODE_AUTO_COMPACT_WINDOW caps the window via min().

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
  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  mkdir -p "$flag_dir"
}

setup_config() {
  local base="$1"
  local content="$2"
  cat > "$base/.claude/memory/.memory-config.md" <<CONFIGEOF
$content
CONFIGEOF
}

setup_settings_json() {
  local home_dir="$1"
  local content="$2"
  mkdir -p "$home_dir/.claude"
  printf '%s' "$content" > "$home_dir/.claude/settings.json"
}

# Probe the resolved window by driving a fixed 900,000-token transcript through
# the hook and classifying which tier fires. With 900K tokens:
#   window 1,000,000 → 90%  → WARN tier   (85 <= pct < 95)   → "warn"
#   window   200,000 → 450% → CRITICAL    (pct >= 95)        → "critical"
#   window   400,000 → 225% → CRITICAL
# Both windows produce a positive, distinguishable signal (no silent-crash
# ambiguity). An optional transcript model lets us test transcript precedence.
probe() {
  local workdir="$1"
  local fake_home="$2"
  local session_id="${3:-sess-test-09}"
  local transcript_model="${4:-}"

  local transcript="$workdir/transcript.jsonl"
  if [[ -n "$transcript_model" ]]; then
    printf '{"type":"assistant","message":{"model":"%s","usage":{"input_tokens":900000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}\n' \
      "$transcript_model" > "$transcript"
  else
    echo '{"type":"assistant","message":{"usage":{"input_tokens":900000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}' > "$transcript"
  fi

  local flag_dir="${TMPDIR:-/tmp}/conkeeper"
  rm -f "$flag_dir/synced-${session_id}" "$flag_dir/blocked-${session_id}"

  local json
  json=$(jq -n \
    --arg sid "$session_id" \
    --arg tp "$transcript" \
    --arg cwd "$workdir" \
    --arg um "test prompt" \
    '{session_id: $sid, transcript_path: $tp, cwd: $cwd, user_message: $um}')

  local output
  HOME="$fake_home" output=$(printf '%s' "$json" | bash "$REPO_ROOT/hooks/user-prompt-submit.sh" 2>/dev/null) || true
  HOME="$ORIG_HOME"

  rm -f "$flag_dir/synced-${session_id}" "$flag_dir/blocked-${session_id}"

  if printf '%s' "$output" | grep -q '\[CRITICAL\]'; then
    echo "critical"
  elif printf '%s' "$output" | grep -q '\[WARN\]'; then
    echo "warn"
  else
    echo "silent"
  fi
}

expect() {
  local desc="$1" got="$2" want="$3"
  if [[ "$got" == "$want" ]]; then
    pass "$desc"
  else
    fail "$desc (got: $got, want: $want)"
  fi
}

# 1: Default (no settings, no config) → 1M window → 90% → warn
test_default_no_settings_no_config() {
  local w="$TMPDIR_TEST/t1" h="$TMPDIR_TEST/h1"
  setup_project "$w"; mkdir -p "$h/.claude"
  expect "Test 1: Default (no settings/config) → 1M window (warn at 90%)" \
    "$(probe "$w" "$h" sess-09-01)" warn
}

# 2: settings opus-4-6 → 1M
test_opus_1m() {
  local w="$TMPDIR_TEST/t2" h="$TMPDIR_TEST/h2"
  setup_project "$w"; setup_settings_json "$h" '{"model": "claude-opus-4-6"}'
  expect "Test 2: claude-opus-4-6 → 1M window (warn)" \
    "$(probe "$w" "$h" sess-09-02)" warn
}

# 3: settings sonnet-4-6 → 1M
test_sonnet_1m() {
  local w="$TMPDIR_TEST/t3" h="$TMPDIR_TEST/h3"
  setup_project "$w"; setup_settings_json "$h" '{"model": "claude-sonnet-4-6"}'
  expect "Test 3: claude-sonnet-4-6 → 1M window (warn)" \
    "$(probe "$w" "$h" sess-09-03)" warn
}

# 4: settings haiku → 200K → critical
test_haiku_200k() {
  local w="$TMPDIR_TEST/t4" h="$TMPDIR_TEST/h4"
  setup_project "$w"; setup_settings_json "$h" '{"model": "claude-haiku-4-5-20251001"}'
  expect "Test 4: claude-haiku → 200K window (critical at 450%)" \
    "$(probe "$w" "$h" sess-09-04)" critical
}

# 5: compact window caps 1M model to 400K → 225% → critical
test_compact_caps_model() {
  local w="$TMPDIR_TEST/t5" h="$TMPDIR_TEST/h5"
  setup_project "$w"; setup_settings_json "$h" '{"model": "opus[1m]", "env": {"CLAUDE_CODE_AUTO_COMPACT_WINDOW": "400000"}}'
  expect "Test 5: compact (400K) caps 1M model → critical" \
    "$(probe "$w" "$h" sess-09-05)" critical
}

# 6: compact (500K) higher than haiku (200K) → model wins (min) → critical
test_compact_higher_than_model() {
  local w="$TMPDIR_TEST/t6" h="$TMPDIR_TEST/h6"
  setup_project "$w"; setup_settings_json "$h" '{"model": "claude-haiku-4-5-20251001", "env": {"CLAUDE_CODE_AUTO_COMPACT_WINDOW": "500000"}}'
  expect "Test 6: compact (500K) > haiku (200K) → min 200K → critical" \
    "$(probe "$w" "$h" sess-09-06)" critical
}

# 7: explicit config override wins over model (1M)
test_explicit_config_override() {
  local w="$TMPDIR_TEST/t7" h="$TMPDIR_TEST/h7"
  setup_project "$w"; setup_settings_json "$h" '{"model": "opus[1m]"}'
  setup_config "$w" "---
context_window_tokens: 300000
---"
  # config 300K → 900K/300K = 300% → critical. If model (1M) won → warn.
  expect "Test 7: explicit config (300K) overrides model (1M) → critical" \
    "$(probe "$w" "$h" sess-09-07)" critical
}

# 8: non-numeric compact ignored → haiku model 200K → critical
test_non_numeric_compact() {
  local w="$TMPDIR_TEST/t8" h="$TMPDIR_TEST/h8"
  setup_project "$w"; setup_settings_json "$h" '{"model": "claude-haiku-4-5-20251001", "env": {"CLAUDE_CODE_AUTO_COMPACT_WINDOW": "not-a-number"}}'
  expect "Test 8: non-numeric compact ignored → haiku 200K → critical" \
    "$(probe "$w" "$h" sess-09-08)" critical
}

# 9: malformed settings.json → graceful default 1M → warn
test_malformed_settings() {
  local w="$TMPDIR_TEST/t9" h="$TMPDIR_TEST/h9"
  setup_project "$w"; mkdir -p "$h/.claude"
  printf '%s' 'not valid json {{{' > "$h/.claude/settings.json"
  expect "Test 9: malformed settings.json → graceful 1M default (warn)" \
    "$(probe "$w" "$h" sess-09-09)" warn
}

# 10: missing model field → default 1M → warn
test_missing_model() {
  local w="$TMPDIR_TEST/t10" h="$TMPDIR_TEST/h10"
  setup_project "$w"; setup_settings_json "$h" '{}'
  expect "Test 10: missing model field → 1M default (warn)" \
    "$(probe "$w" "$h" sess-09-10)" warn
}

# 11: symlink settings.json skipped → default 1M → warn
test_symlink_settings() {
  local w="$TMPDIR_TEST/t11" h="$TMPDIR_TEST/h11"
  setup_project "$w"
  local real="$TMPDIR_TEST/real_settings.json"
  printf '%s' '{"model": "claude-haiku-4-5-20251001"}' > "$real"
  mkdir -p "$h/.claude"; ln -s "$real" "$h/.claude/settings.json"
  # Symlink skipped → no model from settings → default 1M → warn (NOT haiku/critical)
  expect "Test 11: symlink settings.json skipped → 1M default (warn)" \
    "$(probe "$w" "$h" sess-09-11)" warn
}

# 12: unknown/future model → 1M default → warn
test_unknown_model() {
  local w="$TMPDIR_TEST/t12" h="$TMPDIR_TEST/h12"
  setup_project "$w"; setup_settings_json "$h" '{"model": "future-model-9-0"}'
  expect "Test 12: unknown/future model → 1M default (warn)" \
    "$(probe "$w" "$h" sess-09-12)" warn
}

# 13: compact (1M) with no model → default 1M, min stays 1M → warn
test_compact_only_1m() {
  local w="$TMPDIR_TEST/t13" h="$TMPDIR_TEST/h13"
  setup_project "$w"; setup_settings_json "$h" '{"env": {"CLAUDE_CODE_AUTO_COMPACT_WINDOW": "1000000"}}'
  expect "Test 13: compact (1M) no model → 1M stays (warn)" \
    "$(probe "$w" "$h" sess-09-13)" warn
}

# 14: compact (400K) below default → caps to 400K → critical
test_compact_below_default() {
  local w="$TMPDIR_TEST/t14" h="$TMPDIR_TEST/h14"
  setup_project "$w"; setup_settings_json "$h" '{"env": {"CLAUDE_CODE_AUTO_COMPACT_WINDOW": "400000"}}'
  expect "Test 14: compact (400K) below 1M default → caps → critical" \
    "$(probe "$w" "$h" sess-09-14)" critical
}

# 15: opus[1m] variant → 1M → warn
test_opus_1m_variant() {
  local w="$TMPDIR_TEST/t15" h="$TMPDIR_TEST/h15"
  setup_project "$w"; setup_settings_json "$h" '{"model": "opus[1m]"}'
  expect "Test 15: opus[1m] variant → 1M (warn)" \
    "$(probe "$w" "$h" sess-09-15)" warn
}

# 16: sonnet[1m] variant → 1M → warn
test_sonnet_1m_variant() {
  local w="$TMPDIR_TEST/t16" h="$TMPDIR_TEST/h16"
  setup_project "$w"; setup_settings_json "$h" '{"model": "sonnet[1m]"}'
  expect "Test 16: sonnet[1m] variant → 1M (warn)" \
    "$(probe "$w" "$h" sess-09-16)" warn
}

# 17: transcript model (haiku) overrides settings model (opus) → 200K → critical
test_transcript_model_overrides_settings() {
  local w="$TMPDIR_TEST/t17" h="$TMPDIR_TEST/h17"
  setup_project "$w"; setup_settings_json "$h" '{"model": "claude-opus-4-8"}'
  expect "Test 17: transcript model (haiku) overrides settings (opus) → 200K → critical" \
    "$(probe "$w" "$h" sess-09-17 claude-haiku-4-5-20251001)" critical
}

# 18: transcript model (opus) overrides settings model (haiku) → 1M → warn
test_transcript_model_opus_overrides_haiku() {
  local w="$TMPDIR_TEST/t18" h="$TMPDIR_TEST/h18"
  setup_project "$w"; setup_settings_json "$h" '{"model": "claude-haiku-4-5-20251001"}'
  expect "Test 18: transcript model (opus) overrides settings (haiku) → 1M → warn" \
    "$(probe "$w" "$h" sess-09-18 claude-opus-4-8)" warn
}

echo "=== Phase 09: Context Window Auto-Detection Tests ==="
echo ""

test_default_no_settings_no_config
test_opus_1m
test_sonnet_1m
test_haiku_200k
test_compact_caps_model
test_compact_higher_than_model
test_explicit_config_override
test_non_numeric_compact
test_malformed_settings
test_missing_model
test_symlink_settings
test_unknown_model
test_compact_only_1m
test_compact_below_default
test_opus_1m_variant
test_sonnet_1m_variant
test_transcript_model_overrides_settings
test_transcript_model_opus_overrides_haiku

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
