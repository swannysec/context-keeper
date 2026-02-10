# Phase 06 Review Summary — PostToolUse Observation Hook

**Date:** 2026-02-09
**Reviewers:** Sub-Agent A (code-reviewer), Sub-Agent B (architecture-strategist)
**Files reviewed:** hooks/post-tool-use.sh, hooks/hooks.json, hooks/session-start.sh, core/memory/schema.md, skills/memory-config/SKILL.md, plugin.json, tests/phase-06-observations/test-observations.sh

---

## Stage 2 — Code Review Findings (Sub-Agent A)

### Critical

| ID | Finding | File | Lines |
|----|---------|------|-------|
| CODE-C1 | Tests use wrong `tool_input` format (JSON string instead of JSON object). Tests pass by coincidence because jq -r serializes objects to strings which are then re-parsed. Real Claude Code sends `tool_input` as a native JSON object, not stringified. Tests don't match production format. | tests/phase-06-observations/test-observations.sh | 56, 87, 122, 155, 291, 306, 321, 365 |

### High

| ID | Finding | File | Lines |
|----|---------|------|-------|
| CODE-H1 | `tool_input` empty string causes jq failure suppressed by `2>/dev/null`; `\|\| file_path="—"` fallback is dead code because pipeline succeeds even when jq fails. Results in empty backtick path (`\`\``) instead of em-dash. | hooks/post-tool-use.sh | 116 |
| CODE-H2 | `set -u` combined with ERR trap is safe — verified all variables are assigned before use or protected by defaults. | hooks/post-tool-use.sh | All |

### Medium

| ID | Finding | File | Lines |
|----|---------|------|-------|
| CODE-M1 | Four separate jq invocations for initial parsing (lines 16-19). Each spawns a subshell + jq process (~5-10ms each on macOS). Total ~20-40ms of the 100ms budget. Could be consolidated into single jq call. | hooks/post-tool-use.sh | 16-19 |
| CODE-M2 | `tool_response` / success-failure detection not implemented; all entries hardcoded to `success`. Per Claude Code docs, PostToolUse only fires for successful calls (failures use PostToolUseFailure), so this is actually correct. Spec requirement partially unmet but by design. | hooks/post-tool-use.sh | 122-128 |
| CODE-M3 | YAML parser doesn't handle indented keys or quoted values. Works for defined config format but fragile. | hooks/post-tool-use.sh | 56-66 |

### Low

| ID | Finding | File | Lines |
|----|---------|------|-------|
| CODE-L1 | `tool_name` never validated for emptiness — could produce malformed entry with empty backticks | hooks/post-tool-use.sh | 16, 94 |
| CODE-L2 | Backtick characters in file paths or commands break Markdown rendering of entries | hooks/post-tool-use.sh | 116, 126-128 |
| CODE-L3 | `date` invoked twice (lines 80, 90); minor perf — could be combined | hooks/post-tool-use.sh | 80, 90 |
| CODE-L4 | tool_input containing non-object values (array, number, null) causes jq error suppressed by 2>/dev/null; same dead-code fallback issue as CODE-H1 | hooks/post-tool-use.sh | 116 |

### Pass (No Issues)

- Bash 3.2 compatibility: No Bash 4+ features detected
- ERR trap fail-open pattern correct and consistent
- Entry formats (full and stub) match spec
- Comment stripping in YAML parser works correctly
- Frontmatter delimiter detection is correct
- Missing config file handled correctly with defaults

---

## Stage 2 — Architecture Review Findings (Sub-Agent B)

### High

| ID | Finding | File | Lines |
|----|---------|------|-------|
| ARCH-H1 | Bash command summaries may contain secrets (API keys, passwords, connection strings). 80-char command summary written verbatim to project-local file that could be committed to version control. No sanitization or redaction. Schema docs don't warn about this risk. | hooks/post-tool-use.sh | 126-128 |

### Medium

| ID | Finding | File | Lines |
|----|---------|------|-------|
| ARCH-M1 | Observation logging defaults to opt-out (observation_hook: true). Existing users upgrading will silently start generating new files without explicit consent. Files are harmless but principle of least surprise. | hooks/post-tool-use.sh | 31 |
| ARCH-M2 | Config YAML parsing duplicated across two hooks (~30 lines). Acceptable at 2 instances but should be extracted to shared lib if a 3rd consumer emerges. | hooks/post-tool-use.sh, hooks/user-prompt-submit.sh | 36-69, 80-119 |

### Low

| ID | Finding | File | Lines |
|----|---------|------|-------|
| ARCH-L1 | No automated size cap or rotation on observation files. Manual cleanup documented; daily naming provides natural partitioning; sizes are reasonable (58-675 KB). | hooks/post-tool-use.sh | 120-129 |
| ARCH-L2 | "path" column overloaded with command string for Bash tools. Intentional per design doc. | hooks/post-tool-use.sh | 116 |
| ARCH-L3 | Error/failure detection deferred; Test 10 repurposed from error detection to testing observation_detail: off. | tests/phase-06-observations/test-observations.sh | 356-385 |
| ARCH-L4 | Unknown future tools default to full entries. Reasonable default. | hooks/post-tool-use.sh | 100 |
| ARCH-L5 | tool_input parsing handles both stringified and native JSON objects (works by accident via jq -r round-trip) | hooks/post-tool-use.sh | 16-17, 116 |

### Pass (No Issues)

- hooks.json: Valid JSON, no conflicts, PostToolUse entry properly configured with timeout: 5
- session-start.sh: Modification safe, isolated from context output (lines 49-57)
- Observations correctly excluded from session-start context JSON output
- Schema documentation complete and accurate (directory structure, entry formats, cleanup guidance)
- Config skill documentation complete (observation_hook and observation_detail)
- plugin.json version correctly at 0.8.0
- Backward compatibility: Users without jq or .claude/memory unaffected (graceful exit)
- Performance within budget (~20-50ms estimated)
- Fail-open error handling consistent with project patterns

---

## Consolidated Findings (Deduplicated)

### Critical (must fix)

| ID | Finding | Source |
|----|---------|--------|
| C1 | Tests use wrong `tool_input` format — should be JSON object, not stringified JSON string | CODE-C1 |

### High (should fix)

| ID | Finding | Source |
|----|---------|--------|
| H1 | Empty `tool_input` fallback is dead code — jq failure suppressed but pipeline succeeds; produces empty backtick path | CODE-H1 |
| H2 | Bash command summaries may contain secrets; no warning in schema docs; consider .gitignore guidance | ARCH-H1 |

### Medium (recommended fix)

| ID | Finding | Source |
|----|---------|--------|
| M1 | Four separate jq invocations could be consolidated for performance | CODE-M1 |
| M2 | success/failure detection deferred (acceptable — PostToolUse only fires for success) | CODE-M2 |
| M3 | YAML parser doesn't handle indented keys or quoted values | CODE-M3 |
| M4 | Observation logging opt-out by default for existing users | ARCH-M1 |
| M5 | Config parsing duplicated across two hooks | ARCH-M2 |

### Low (acceptable, document)

| ID | Finding | Source |
|----|---------|--------|
| L1 | tool_name not validated for emptiness | CODE-L1 |
| L2 | Backtick chars in paths/commands break Markdown | CODE-L2 |
| L3 | date invoked twice; minor perf | CODE-L3 |
| L4 | No automated size cap on observation files | ARCH-L1 |
| L5 | "path" column overloaded for Bash tools | ARCH-L2 |
| L6 | Error/failure detection deferred; Test 10 repurposed | ARCH-L3 |

---

## Stage 4 — Fixes Applied

- **C1 fixed:** Updated all test JSON to use native JSON objects for `tool_input`
- **H1 fixed:** Fixed dead-code fallback using `[[ -z ]]` check instead of `|| file_path="—"`
- **H2 fixed:** Added .gitignore guidance and secrets warning to `core/memory/schema.md`
- **M1 fixed:** Consolidated 4 jq calls into 2 (later reverted to 4 separate calls per security review)
- M2, M3, M4, M5: Accepted as-is (documented rationale)

## Stage 5-6 — Simplicity Review

**Findings:**
1. **Should simplify:** Merged two case statements into one (-8 lines)
2. **Should simplify:** Replaced while-loop + parse_yaml_val with awk one-liner (-21 lines)
3. Acceptable: Field extraction, overall structure, eval+jq pattern

**Result:** Script reduced from 137 to 108 lines (22% reduction). All tests pass.

## Stage 7-9 — Security Review

**Consolidated security findings:**

| ID | Finding | Severity | Status |
|----|---------|----------|--------|
| SEC-1 | eval + @sh shell injection risk (fragile pattern) | Critical→Low (tested safe, but replaced) | **Fixed** — reverted to separate jq calls |
| SEC-2 | Sensitive data leakage in command summaries | High | **Mitigated** — documented in schema.md with .gitignore guidance |
| SEC-3 | Symlink attack on observation file | Medium (confirmed via dynamic testing) | **Fixed** — added `[[ -L ]] && exit 0` check |
| SEC-4 | Unvalidated cwd enables arbitrary file write | Medium (confirmed via dynamic testing) | **Fixed** — added `cd && pwd` resolution |
| SEC-5 | Markdown/prompt injection via file_path | Medium | Accepted — truncation limits payload; observation file not auto-loaded |
| SEC-6 | printf format string safety | Low (not a vulnerability) | N/A — correctly uses `printf --` with `%s` args |
| SEC-7 | jq injection via malformed JSON | Low | N/A — jq is hardened; failures trigger ERR trap |
| SEC-8 | TOCTOU in header creation | Low | Accepted — benign race; worst case is duplicate header |
| SEC-9 | No security tests | Medium | **Fixed** — added Test 11 (symlink) and Test 12 (session_id traversal) |

**Security tests added:** Test 11 (symlink attack blocked), Test 12 (path traversal session_id rejected)

## Stage 10 — Final Verification

- All test suites pass:
  - Phase 03 (categories): 10/10
  - Phase 04 (privacy): 13/13
  - Phase 05 (search): 11/11
  - Phase 06 (observations): 12/12
- `hooks/hooks.json`: valid JSON
- `session-start.sh`: produces valid JSON output
- `plugin.json`: version 0.8.0
- **Total: 46 tests, 0 failures**
