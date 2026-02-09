# Phase 05 Review Summary: `/memory-search`

**Date:** 2026-02-09
**Reviewers:** Code Reviewer (Sub-Agent A), Architecture Strategist (Sub-Agent B)

## Consolidated Findings (Deduplicated)

### HIGH Severity

| ID | Finding | Source | Actionable? |
|----|---------|--------|-------------|
| H-1 | `SEARCH_DIRS` word-splitting breaks on paths with spaces (e.g., `$HOME="/Users/John Doe"` with `--global`) | Code Review | Yes — use newline-delimited list or indexed array |
| H-2 | Missing `commands/memory-search.md` — breaks skill/command pairing pattern | Architecture Review | Yes — create command file |

### MEDIUM Severity

| ID | Finding | Source | Actionable? |
|----|---------|--------|-------------|
| M-1 | No `--` (end-of-options) support in argument parser — can't search for strings starting with `-` | Code Review | Yes — add `--) shift; break ;;` case |
| M-2 | `has_nearby_category` uses grep without `-F` — regex injection via category name (e.g., `.` matches any char) | Code Review | Yes — add `-F` flag to grep on lines 253, 323 |
| M-3 | Category tag display asymmetry: filter checks +/-3 lines, display only checks above | Code Review | Yes — extend display range to also look below |
| M-4 | Test 7 doesn't actually test grep fallback (only tests rg when available) | Code Review | Yes — force grep codepath in test |
| M-5 | README AGENTS.md snippet outdated (missing `memory-search`) | Architecture Review | Yes — sync with core/snippet.md |
| M-6 | No `core/workflows/memory-search.md` — breaks layered architecture pattern | Architecture Review | Yes — create workflow spec |
| M-7 | Windsurf `.windsurfrules` missing `memory-search` workflow section | Architecture Review | Yes — add section |
| M-8 | `is_file_private()` duplicated between `lib-privacy.sh` and `memory-search.sh` (DRY violation) | Architecture Review | Yes — source shared library |
| M-9 | CHANGELOG not updated for v0.5.0-v0.7.0 | Architecture Review | Deferred — out of Phase 05 scope |

### LOW Severity

| ID | Finding | Source | Actionable? |
|----|---------|--------|-------------|
| L-1 | ERR trap exits 0 but argument errors exit 1 — undocumented dual behavior | Code Review | Improve with comment |
| L-2 | Private front matter scans 20 lines, spec says 5 (improvement over spec) | Code Review | No fix needed |
| L-3 | Output has extra leading blank line before first file section | Code Review | Cosmetic only |
| L-4 | No test for unclosed `<private>` blocks in search context | Code Review | Nice-to-have |
| L-5 | No test for nested `<private>` blocks in search context | Code Review | Nice-to-have |
| L-6 | Category tags inside `<private>` blocks could appear in output display | Architecture Review | Nice-to-have |
| L-7 | Code-fenced `<private>` tags could confuse privacy ranges (documented limitation) | Architecture Review | Accepted per schema |

### POSITIVE Findings (No Action Needed)

- Search output format is consistent with schema documentation
- Script path references correctly adapted per platform
- Zed adapter follows rules-library conventions
- Codex/Copilot/Cursor adapters are identical (correct)
- Two-pass privacy approach is architecturally sound
- Session-start search reminder: ~15 tokens, strong positive ROI
- Search output is token-efficient
- `/memory-search` naming follows established conventions

## Deduplication Notes

- Architecture M-8 (DRY violation for `is_file_private()`) and Code L-2 (20-line scan) both touch the same function but are distinct issues. M-8 is about duplication; L-2 is about behavior difference from spec.
- Architecture L-6 (category tags in private blocks) is related to Code M-3 (display asymmetry) but addresses a different edge case.

## Action Plan for Stage 4

Fix all Critical, High, and Medium findings (H-1, H-2, M-1 through M-8). M-9 (CHANGELOG) deferred as out of scope.

## Simplicity Review (Stage 5-6)

### "Should Apply" (Fixed)

| ID | Finding | Impact |
|----|---------|--------|
| S-1 | Replace 58-line `get_private_ranges` with 4-line awk | -54 lines, -3 subprocess calls per file |
| S-2 | Remove inline `is_file_private` fallback, source lib-privacy.sh directly | -15 lines, DRY violation eliminated |

### "Optional" (Not Applied)

| ID | Finding | Reason for Deferral |
|----|---------|---------------------|
| S-3 | `--` end-of-options handling (7 lines) | Low cost, protects against real edge case |
| S-4 | Category tag display runs on every match | Could guard behind `--category` but acceptable overhead |
| S-5 | SEARCH_DIRS could be inlined | Works correctly, consistent idiom |

**Post-fix result:** All 34 tests pass. ~69 lines of code removed net.

## Security Review (Stage 7-9)

### Consolidated Security Findings

| ID | Finding | Severity | Source | Fix? |
|----|---------|----------|--------|------|
| SEC-1 | TOCTOU race: file read twice (awk for ranges, grep for search) — content can change between reads | Critical | Technical | Yes — read file once into variable |
| SEC-2 | Nested `<private>` blocks: awk overwrites start, leaking content between inner `</private>` and outer `</private>` | Medium | Architecture | Yes — fix awk to track nesting |
| SEC-3 | `<private>` tag variants (uppercase, trailing space, attributes) not matched | Medium | Technical | Deferred — documented tag spec |
| SEC-4 | YAML `private: yes`/`on`/`1` not recognized | Medium | Technical | Deferred — ConKeeper generates `true` |
| SEC-5 | Empty `--category ""` silently disables filter | Low | Technical | Yes — validate non-empty |
| SEC-6 | ERR trap exits 0, masking failures | Low | Technical | Already documented (L-1) |

### Deduplication Notes

- SEC-2 (nested blocks in awk) overlaps with arch review's private block finding. Same root cause.
- SEC-6 was already documented as L-1 in the code review. No additional action.
- SEC-3 and SEC-4 are tag/YAML parsing strictness issues. The schema explicitly documents the exact tag format required. Treating as accepted behavior per schema.

### Fixes Applied

- **SEC-1 (Critical)**: Read file content once, pass to both awk and grep via variable
- **SEC-2 (Medium)**: Fixed awk to handle nested blocks by not overwriting start when already inside a block
- **SEC-5 (Low)**: Added validation for empty --category value

## Final Verification (Stage 10)

- All 34 tests pass: Phase 03 (10), Phase 04 (13), Phase 05 (11)
- `plugin.json` version: `0.7.0` ✅
- `session-start.sh` produces valid JSON ✅
- `tools/memory-search.sh` is executable ✅
- **Status: REVIEW COMPLETE — ALL STAGES PASSED**
