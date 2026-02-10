# Phase 08 Review Summary — Session Retrospection

**Date:** 2026-02-09
**Reviewers:** Sub-Agent A (Code Reviewer), Sub-Agent B (Architecture Strategist)
**Stage:** Stage 2–3 (Parallel review + synthesis)
**Status:** Consolidated findings ready for Stage 4

---

## Summary

| Source | Critical | High | Medium | Low |
|--------|----------|------|--------|-----|
| Code Review (Sub-Agent A) | 0 | 2 | 5 | 5 |
| Architecture Review (Sub-Agent B) | 0 | 2 | 5 | 3 |
| **Consolidated (deduplicated)** | **0** | **3** | **8** | **6** |

Both reviewers confirmed the overall implementation is well-structured, with full cross-phase integration (all 6 phases correctly consumed by `/memory-reflect`), proper graceful degradation, and good Bash 3.2 compatibility. The Stop hook, `/memory-insights`, and facets integration are clean.

---

## Consolidated Findings

### High Severity (Must Fix for v1.0.0)

**H-1: README configuration and feature documentation incomplete**
- *Sources:* Code Review #12, Architecture Review #6
- *Files:* `README.md` (lines 83-111, 194-204)
- *Issue:* The AGENTS.md snippet embedded in README only lists 4 workflows (missing `memory-reflect` and `memory-insights`). The Configuration YAML block omits `observation_hook`, `observation_detail`, `suggest_memories`, `auto_load`, and `output_style`. No dedicated sections explain the observation hook or correction detection features.
- *Fix:* Update README's embedded snippet to match `core/snippet.md`. Expand config block to include all settings. At minimum, add missing lines to config YAML example.

**H-2: Unmapped facets friction types in `/memory-reflect` Phase 3**
- *Source:* Code Review #8
- *File:* `skills/memory-reflect/SKILL.md` (lines 63-65)
- *Issue:* The facets-to-ConKeeper category mapping covers 6 friction types but Claude Code may produce additional/future friction types. No fallback instruction exists.
- *Fix:* Add: "For any friction type not listed above, map to the closest ConKeeper category based on the friction_detail narrative, defaulting to `efficiency` if unclear."

**H-3: Stale privacy enforcement table in schema**
- *Source:* Architecture Review #1
- *File:* `core/memory/schema.md` (line 541, lines 535-539)
- *Issue:* Line 541 says "Future code paths (`/memory-reflect`) will enforce privacy tags when implemented." — this is stale. `/memory-reflect` IS implemented. Also, the enforcement table only lists 3 code paths but should include `/memory-reflect` and `/memory-insights`.
- *Fix:* Remove stale line. Add `/memory-reflect` and `/memory-insights` rows to enforcement table.

### Medium Severity (Should Fix)

**M-1: CHANGELOG.md not updated for v1.0.0**
- *Source:* Architecture Review #5
- *File:* `CHANGELOG.md`
- *Issue:* Latest entry is `[0.4.0]`. All Phase 03-08 features missing. v1.0.0 release needs a comprehensive changelog entry.
- *Fix:* Add `[1.0.0]` entry covering all features since `0.4.0`.

**M-2: `reflect_depth` config vs skill naming inconsistency**
- *Source:* Architecture Review #2
- *Issue:* Config uses `minimal | standard | thorough` but skill uses `LIGHTWEIGHT | STANDARD | THOROUGH`. The mapping of config `minimal` → skill `LIGHTWEIGHT` is never documented. If user sets `reflect_depth: minimal` but session has 50 observations, the behavior is ambiguous.
- *Fix:* Add explicit mapping in the skill: "If reflect_depth is `minimal`, use LIGHTWEIGHT depth regardless of activity level."

**M-3: `/memory-config` Step 2 display missing new settings**
- *Source:* Code Review #11
- *File:* `skills/memory-config/SKILL.md` (lines 48-53)
- *Issue:* Step 2 display only shows 4 original settings. All settings added in Phases 04-08 are missing from the display (though they appear in Step 3 menu).
- *Fix:* Add all settings to Step 2 display block.

**M-4: Platform adapter READMEs missing Phase 05-08 workflows**
- *Source:* Architecture Review #3
- *Files:* `platforms/{codex,copilot,cursor,windsurf,zed}/README.md`
- *Issue:* AGENTS.md snippets in platform READMEs only list 3 workflows. Missing: `memory-search`, `memory-reflect`, `memory-insights`.
- *Fix:* Update all five platform README snippets to match `core/snippet.md`.

**M-5: Phase 2 LIGHTWEIGHT auto-selection ambiguous on user skip**
- *Source:* Code Review #6
- *File:* `skills/memory-reflect/SKILL.md` (line 49)
- *Issue:* For LIGHTWEIGHT sessions, "Auto-select PROCESS scope" doesn't explicitly say user confirmation is skipped.
- *Fix:* Change to: "Auto-select PROCESS scope, skip user confirmation, and produce minimal output."

**M-6: `/memory-sync` auto_reflect trigger condition asymmetry**
- *Sources:* Code Review #10, Architecture Review #7
- *File:* `skills/memory-sync/SKILL.md` (lines 135-142)
- *Issue:* Suggestion text triggers on "corrections OR substantial session" but auto_reflect only triggers on corrections. This asymmetry is likely intentional but should be explicit. Also, auto-sync mode implicitly prevents auto-reflect (because it skips Step 2.5) but this isn't documented.
- *Fix:* Add clarifying notes for both: (1) auto-reflect only triggers on corrections because they're the strongest retrospection signal, and (2) auto-reflect is not triggered during auto-sync mode since Step 2.5 is skipped.

**M-7: Phase 6 approval parsing unspecified**
- *Source:* Code Review #9
- *File:* `skills/memory-reflect/SKILL.md` (lines 122-124)
- *Issue:* Emoji labels for approve/deny/iterate are clear to humans but the skill doesn't specify how the LLM should present and parse user responses.
- *Fix:* Add explicit guidance: present numbered, accept "approve N", "deny N", "edit N", "approve all".

**M-8: `auto_reflect: true` default may surprise upgrading users**
- *Source:* Architecture Review #8
- *Issue:* Users upgrading from v0.4.1 get auto-reflect after `/memory-sync` when corrections exist. No opt-in required.
- *Fix:* Document in CHANGELOG note that existing users should be aware of auto-reflect behavior and can disable via `auto_reflect: false` in `.memory-config.md`.

### Low Severity (Nice to Have)

**L-1: `stop.sh` ERR trap doesn't log diagnostic info**
- *Source:* Code Review #1
- *File:* `hooks/stop.sh` (line 3)
- *Issue:* All other hooks log `"[ConKeeper] <name>.sh failed at line $LINENO"` to stderr on ERR. `stop.sh` exits silently.
- *Fix:* Change trap to: `trap 'echo "[ConKeeper] stop.sh failed at line $LINENO" >&2; exit 0' ERR`

**L-2: Stop hook stderr-only visibility concern**
- *Source:* Architecture Review #9
- *Issue:* Stop hook writes to stderr only; if Claude Code doesn't display Stop hook stderr, the message is invisible.
- *Fix:* Verify Claude Code runtime behavior. Consider adding `hookSpecificOutput` JSON on stdout as fallback.

**L-3: SessionStart context injection doesn't mention `/memory-reflect`**
- *Source:* Architecture Review #10
- *File:* `hooks/session-start.sh`
- *Issue:* Injected context mentions `/memory-init`, `/memory-sync` but not `/memory-reflect` or `/memory-insights`.
- *Fix:* Add "To run session retrospection: /memory-reflect" to injected context.

**L-4: `corrections-queue.md` lifecycle in schema doesn't mention `/memory-reflect`**
- *Source:* Architecture Review #11
- *File:* `core/memory/schema.md` (line 304)
- *Issue:* Lifecycle says "processed by /memory-sync" but doesn't mention `/memory-reflect` also consumes it.
- *Fix:* Update to include `/memory-reflect` consumption.

**L-5: Test names could be clearer (format contract tests)**
- *Source:* Code Review #13
- *File:* `tests/phase-08-retrospection/test-retrospection.sh` (Tests 5-6)
- *Issue:* Tests create sample retro files then verify them — these are format contract tests, not output validation tests. Names could be clearer.
- *Fix:* Consider renaming to "Retro format template has all required sections".

**L-6: Missing test edge cases**
- *Source:* Code Review #14
- *File:* `tests/phase-08-retrospection/test-retrospection.sh`
- *Issue:* Missing: (a) Stop hook with observations-only trigger (no corrections), (b) hooks.json timeout value validation.
- *Fix:* Add test for observations-only trigger. Add test verifying timeout values.

---

## Positive Confirmations (Both Reviewers)

- All 13 Phase 08 tests pass
- `/memory-reflect` correctly consumes ALL prior phase data (Phases 03-07)
- Stop hook degrades gracefully on unsupporting runtimes
- New config fields have proper defaults
- Bash 3.2 compatibility maintained
- Facets integration well-specified with graceful degradation
- Privacy instructions present and consistent
- All hooks.json commands use `${CLAUDE_PLUGIN_ROOT}`
- Snippet token impact within acceptable range
- Zed rules library has correctly simplified memory-reflect.md

---

## Stage 4 — Fix Results

All 3 High and 8 Medium findings fixed. Also fixed L-1, L-3, L-4, L-6 (4 Low findings). Skipped L-2 (speculative) and L-5 (cosmetic). All 75 tests pass across 6 phases.

---

## Stage 5 — Simplicity Review

**Date:** 2026-02-09
**Reviewer:** Code Simplicity Reviewer
**Status:** Complete — findings ready for Stage 6

### Summary

| Classification | Count |
|----------------|-------|
| Should simplify | 7 |
| Worth discussing | 3 |
| Acceptable complexity | 3 |

Overall complexity score: **Medium** — core design is sound but has accumulated speculative features. Estimated ~100 LOC removable (~10% across reviewed files).

### Should Simplify (Prioritized by Impact)

**S-1: Remove THOROUGH tier and cross-session analysis from /memory-reflect** *(highest impact)*
- *File:* `skills/memory-reflect/SKILL.md` (Phase 3, lines 71-76; all THOROUGH references in Phases 3-5)
- *Issue:* THOROUGH depth's cross-session trend analysis duplicates `/memory-insights`. Having the same analysis in two skills violates DRY and inflates skill complexity.
- *Fix:* Remove lines 71-76 from Phase 3. Remove all THOROUGH-specific instructions. Keep LIGHTWEIGHT (auto-detected) and STANDARD (default) tiers only. The THOROUGH tier can return in a future version if users request it.
- *Estimated reduction:* ~15 lines

**S-2: Collapse Phase 4 (Research) into a note in Phase 3**
- *File:* `skills/memory-reflect/SKILL.md` (lines 84-94)
- *Issue:* Phase 4 is a full phase for "look things up if needed." In practice, LLMs naturally research when generating recommendations. A separate phase adds ceremony without behavior.
- *Fix:* Replace Phase 4 with a 2-line note at end of Phase 3: "If a recommendation would benefit from external validation, briefly verify with external sources before recommending." Renumber subsequent phases.
- *Estimated reduction:* ~8 lines, workflow goes from 7 phases to 6

**S-3: Remove numbered menu from /memory-config Step 3**
- *File:* `skills/memory-config/SKILL.md` (lines 62-78)
- *Issue:* A 13-item numbered menu is a CLI pattern forced onto an LLM conversation. The LLM handles "change output style to quiet" natively. The menu numbering is inconsistent (item 5 = "Nothing (exit)") and hard to maintain.
- *Fix:* Replace with: "Ask the user which setting they'd like to change, or whether they're done."
- *Estimated reduction:* ~16 lines

**S-4: Deduplicate retro template between schema.md and SKILL.md**
- *File:* `core/memory/schema.md` (lines 255-292)
- *Issue:* Full retro template exists in both schema.md and SKILL.md Phase 7. Two copies will drift over time.
- *Fix:* Reduce schema.md entry to a brief description (like the observations entry) with "See /memory-reflect skill for full format." Keep SKILL.md as the authoritative template.
- *Estimated reduction:* ~25 lines from schema.md

**S-5: Simplify Phase 6 approval protocol**
- *File:* `skills/memory-reflect/SKILL.md` (lines 126-136)
- *Issue:* Over-specified approval protocol ("approve N", "deny N", "edit N", "approve all") constrains natural LLM conversation. The 5-target routing table duplicates knowledge from schema.md.
- *Fix:* Simplify to: present numbered recommendations, user can approve all or selectively approve/deny in natural language. Route to the most appropriate memory file. Remove "edit N" — users can edit in the target file after approval.
- *Estimated reduction:* ~8 lines

**S-6: Trim retro Evidence section template (Phase 7)**
- *File:* `skills/memory-reflect/SKILL.md` (lines 164-172)
- *Issue:* "truncated to 200 chars" is micro-management. Eight specific evidence line items with exact formatting is over-specified for an LLM output template.
- *Fix:* Specify required sections (Summary, Improvement Log, Backlog, Evidence) and key evidence items. Remove "truncated to 200 chars" instruction.
- *Estimated reduction:* ~5 lines

**S-7: Remove `reflect_depth` config knob (conditional on S-1)**
- *File:* `skills/memory-config/SKILL.md`
- *Issue:* `reflect_depth` (minimal/standard/thorough) only exists to support the THOROUGH tier. If S-1 removes THOROUGH, this becomes unnecessary — LIGHTWEIGHT is auto-detected, STANDARD is the default.
- *Fix:* If S-1 is applied, replace `reflect_depth` with nothing. Auto-detection handles lightweight sessions. One less config knob (12→11).

### Worth Discussing

**D-1: Phase 2 (Classify Scope) adds a conversational round-trip for cosmetic grouping**
- The scope classification (PROCESS/PROJECT/BOTH) doesn't gate different behavior in later phases. Recommendations are already naturally grouped in Phase 6 output. The user can approve/deny individually regardless of scope.
- Counter-argument: sets user expectations for what kind of output to expect.
- *Recommendation:* Keep for v1.0.0 but flag for potential removal if user testing shows it adds friction.

**D-2: /memory-insights sub-commands (friction, sessions --worst/--best, patterns)**
- No user has requested these. The default dashboard covers 80% of the value. The LLM can answer drill-down questions conversationally.
- Counter-argument: sub-commands serve as structured prompts guiding the LLM toward useful analysis.
- *Recommendation:* Keep for v1.0.0. They're instruction-only (no code cost) and provide useful structure. Revisit if skill proves too complex.

**D-3: External Data Sources section in schema.md**
- Already fairly concise at 8 lines. All information is relevant. No simplification needed.

### Acceptable Complexity (No Changes)

- **stop.sh** — 24 lines, already minimal. The `wc -l > 3` threshold correctly handles header lines.
- **Phase 1 facets integration** — Six specific field names are necessary for reliable extraction. Graceful degradation is required.
- **Phase 3 friction type mapping** — Explicit mapping table ensures deterministic categorization across sessions. Fallback rule handles unknown types.

### YAGNI Violations Summary

| Violation | File | Action |
|-----------|------|--------|
| THOROUGH tier | memory-reflect/SKILL.md | Remove (S-1) |
| `reflect_depth` config | memory-config/SKILL.md | Remove if S-1 applied (S-7) |
| `edit N` in approval | memory-reflect/SKILL.md | Remove (part of S-5) |
| Phase 4 as standalone phase | memory-reflect/SKILL.md | Collapse (S-2) |

---

## Stage 6 — Simplicity Fix Results

**Date:** 2026-02-09
**Status:** Complete — all 7 "Should simplify" findings fixed, all 75 tests pass.

### Changes Applied

| Finding | Action | Files Changed |
|---------|--------|---------------|
| S-1: Remove THOROUGH tier | Removed cross-session analysis from Phase 3, removed all THOROUGH depth references. `/memory-insights` remains the dedicated cross-session tool. | `skills/memory-reflect/SKILL.md` |
| S-2: Collapse Phase 4 (Research) | Replaced standalone Research phase with a 2-line note at end of Phase 3. Workflow reduced from 7 phases to 6. Renumbered subsequent phases. | `skills/memory-reflect/SKILL.md` |
| S-3: Remove numbered menu | Replaced 13-item numbered menu in Step 3 with natural language instruction. | `skills/memory-config/SKILL.md` |
| S-4: Deduplicate retro template | Replaced full retro template in schema.md with brief description and pointer to `/memory-reflect` skill. | `core/memory/schema.md` |
| S-5: Simplify approval protocol | Replaced over-specified "approve N/deny N/edit N" protocol with natural language approval. Simplified routing table to single sentence. | `skills/memory-reflect/SKILL.md` |
| S-6: Trim evidence template | Removed per-field facets sub-items and "truncated to 200 chars" instruction. Replaced with single line: "include outcome, friction counts, and satisfaction summary if available". | `skills/memory-reflect/SKILL.md` |
| S-7: Remove `reflect_depth` config | Removed `reflect_depth` from config YAML, Step 2 display, Reflection Settings table, schema.md, README.md, and CHANGELOG.md. Session depth is now purely auto-detected (LIGHTWEIGHT vs STANDARD). Config knobs reduced from 12 to 11. | `skills/memory-config/SKILL.md`, `core/memory/schema.md`, `README.md`, `CHANGELOG.md` |

### "Worth Discussing" Items (D-1, D-2, D-3)

All three kept as-is per reviewer recommendation:
- **D-1** (Phase 2 Classify Scope): Kept — sets user expectations. Flagged for potential removal based on user testing.
- **D-2** (/memory-insights sub-commands): Kept — instruction-only cost, provides useful structure for LLM analysis.
- **D-3** (External Data Sources in schema.md): Kept — already concise at 8 lines.

### Estimated Reduction

- ~70 lines removed across skill files and schema
- Workflow phases: 7 → 6
- Config knobs: 12 → 11
- YAGNI violations resolved: 4/4 (THOROUGH tier, reflect_depth config, "edit N" approval, Phase 4 standalone)

### Test Results

All 75 tests pass across 6 phases:
- Phase 03 (Categories): 10/10
- Phase 04 (Privacy): 13/13
- Phase 05 (Search): 11/11
- Phase 06 (Observations): 12/12
- Phase 07 (Corrections): 14/14
- Phase 08 (Retrospection): 15/15

---

## Stage 7 — Security Review

**Date:** 2026-02-09
**Reviewers:** Sub-Agent C (Security Architecture), Sub-Agent D (Technical Security)
**Status:** Complete — findings consolidated

### Summary

| Source | Critical | High | Medium | Low |
|--------|----------|------|--------|-----|
| Security Architecture (Sub-Agent C) | 0 | 3 | 7 | 7 |
| Technical Security (Sub-Agent D) | 0 | 1* | 7 | 10 |
| **Consolidated (deduplicated)** | **0** | **3** | **9** | **10** |

*TH2 (bc division by zero) self-assessed as Low by reviewer; TH3 merged with SM5.

Both reviewers confirmed overall risk is **LOW**. No critical vulnerabilities found. The attack surface is local-only (no network exposure). Strong input validation on session_id across all hooks. Fail-open design verified. Primary risk area is indirect prompt injection via unsanitized content in memory files.

---

### Consolidated Security Findings

#### High Severity (Must Fix for v1.0.0)

**SEC-H1: Unsanitized tool_input content written to observation file (LLM prompt injection vector)**
- *Sources:* Architecture SH1, Technical TH1
- *Files:* `hooks/post-tool-use.sh` (lines 90, 97-98, 103-104)
- *Issue:* `file_path` and `cmd_summary` extracted from `tool_input` JSON are truncated but never sanitized for markdown metacharacters, HTML comments, pipe chars, or backticks before appending to observations file. Contrast with `user-prompt-submit.sh` line 229 which sanitizes corrections queue entries with `tr -d '\000-\037' | sed 's/|/\\|/g; s/"/\\"/g; s/<!--//g; s/-->//g'`.
- *Risk:* When `/memory-reflect` reads observations, attacker-influenced content (e.g., from crafted filenames or shell commands in repo Makefiles) becomes part of the LLM prompt.
- *Fix:* Add same sanitization pipeline as corrections queue (strip control chars, escape pipes/quotes, strip HTML comments).

**SEC-H2: Auto-sync skips user approval — memory file content propagated without review**
- *Sources:* Architecture SH2, SH3; Technical TL7
- *Files:* `skills/memory-sync/SKILL.md` (auto-sync mode), all memory files
- *Issue:* When context threshold triggers auto-sync, `/memory-sync` skips user approval (Step 3). Crafted content in memory files (patterns.md, corrections-queue.md) could be propagated to other memory files without human review. This is an inherent design tradeoff of file-based memory systems.
- *Risk:* If a shared repo contains malicious memory files, auto-sync amplifies their reach.
- *Existing mitigations:* Auto-sync skips Step 2.5 (corrections processing). Claude Code has built-in prompt injection defenses. SECURITY.md documents this risk.
- *Fix:* Add a note in `/memory-sync` auto-sync mode: "During auto-sync, only update active-context.md and progress.md. Do NOT process corrections queue or route items to patterns.md/decisions/." This limits the blast radius of auto-sync.

**SEC-H3: Shared temp directory created without restrictive permissions**
- *Sources:* Architecture SM5, Technical TH3
- *Files:* `hooks/user-prompt-submit.sh` (lines 43-44), `hooks/pre-compact.sh` (lines 23-24)
- *Issue:* `mkdir -p "$FLAG_DIR"` creates `${TMPDIR}/conkeeper/` with default umask permissions. On shared systems, another user could pre-create the directory or plant flag files to suppress auto-sync/correction detection.
- *Fix:* Add `chmod 700 "$FLAG_DIR" 2>/dev/null` after mkdir in both scripts.

#### Medium Severity (Should Fix)

**SEC-M1: Incomplete cwd path traversal validation in user-prompt-submit.sh**
- *Sources:* Architecture SM2, Technical TM4
- *File:* `hooks/user-prompt-submit.sh` (lines 32-34)
- *Issue:* Only checks for literal `..` — doesn't resolve symlinks. `post-tool-use.sh` uses the stronger `cwd=$(cd "$cwd" && pwd)` pattern.
- *Fix:* Apply same `cd && pwd` resolution pattern from post-tool-use.sh.

**SEC-M2: TOCTOU race between symlink check and file write in post-tool-use.sh**
- *Sources:* Architecture SL3, Technical TM1, TL1
- *File:* `hooks/post-tool-use.sh` (lines 59-62, 97-104)
- *Issue:* Symlink check on obs_file is separate from the write. Also no symlink check on `obs_dir` (parent directory). Window is tiny but is a textbook TOCTOU.
- *Fix:* Use `O_NOFOLLOW` semantics where possible. For Bash 3.2, check symlinks on both dir and file immediately before write, and use `>>` append which on most filesystems is atomic for small writes.

**SEC-M3: No symlink check on corrections queue file**
- *Sources:* Technical TL3
- *File:* `hooks/user-prompt-submit.sh` (line 222)
- *Issue:* Unlike observations file which has `[[ -L "$obs_file" ]] && exit 0`, the corrections queue file has no symlink check before writing.
- *Fix:* Add `[[ -L "$queue_file" ]] && exit 0` before the noclobber creation block.

**SEC-M4: No symlink check on observation file in session-start.sh**
- *Sources:* Technical TL2
- *File:* `hooks/session-start.sh` (lines 52-56)
- *Issue:* Creates/writes observations file header without checking if path is a symlink.
- *Fix:* Add `[[ -L "$obs_file" ]] && : # skip symlink` before writing.

**SEC-M5: Incomplete sanitization of user message in corrections queue**
- *Sources:* Architecture SM4, Technical TM5
- *File:* `hooks/user-prompt-submit.sh` (line 229)
- *Issue:* Strips `<!--`/`-->` but doesn't handle backtick injection or other markdown metacharacters. Primary concern is LLM prompt injection when `/memory-reflect` reads the queue.
- *Fix:* Add backtick escaping: `s/\`/\\'/g` to the sed pipeline.

**SEC-M6: pre-compact.sh flag file content not validated before arithmetic**
- *Sources:* Architecture SL4 (mapped), Technical TL4
- *File:* `hooks/pre-compact.sh` (line 31)
- *Issue:* `flag_epoch=$(cat "$flag_file")` used directly in arithmetic. Non-numeric content triggers ERR trap. Unlike `user-prompt-submit.sh` which validates `^[0-9]+$`.
- *Fix:* Add validation: `if [[ -z "$flag_epoch" ]] || ! [[ "$flag_epoch" =~ ^[0-9]+$ ]]; then flag_epoch=0; fi`

**SEC-M7: Unbounded stdin read into bash variable**
- *Sources:* Technical TM6
- *Files:* `hooks/user-prompt-submit.sh` (line 21), `hooks/post-tool-use.sh` (line 15)
- *Issue:* `input=$(cat)` reads all stdin into memory. Extremely large JSON payloads could cause excessive memory consumption.
- *Fix:* Add `head -c 1048576` (1MB cap) before storing: `input=$(head -c 1048576)`. Hook timeouts (10s/5s) provide secondary mitigation.

**SEC-M8: Glob metacharacters in .correction-ignore can suppress all detection**
- *Sources:* Architecture SM6, Technical TM7
- *File:* `hooks/user-prompt-submit.sh` (line 194)
- *Issue:* Patterns from `.correction-ignore` used in `[[ "$text" == *"$pattern"* ]]` glob match. A pattern of `*` suppresses all corrections. Patterns with `?` or `[` have glob interpretation.
- *Fix:* Document this as intended behavior (`.correction-ignore` is a user-controlled suppression file). Add a comment in the code: `# Note: patterns are glob-matched, not literal substring`

**SEC-M9: Auto-sync mode should limit scope of memory writes**
- *Sources:* Architecture SH2 (expanded fix)
- *File:* `skills/memory-sync/SKILL.md`
- *Issue:* Auto-sync mode processes the same steps as manual sync, minus Step 2.5 (corrections) and Step 3 (approval). It could still write to patterns.md, decisions/, glossary.md if the LLM decides to during Steps 2 and 4.
- *Fix:* Add explicit instruction: "During auto-sync mode, only update active-context.md and progress.md. Do not create new decision files or modify patterns.md."

#### Low Severity (Informational / Hardening)

**SEC-L1:** `readlink -f` unavailable on stock macOS < 12.3 — fails closed (rejects symlink), which is correct security behavior. No fix needed.

**SEC-L2:** Pure-bash JSON encode fallback doesn't escape all control characters (0x00-0x1F beyond \t, \r, \n). jq is tried first. Very low practical risk.

**SEC-L3:** `stop.sh` uses relative paths without cwd validation. Read-only (no writes), output is only stderr suggestion. Low risk.

**SEC-L4:** `post-tool-use.sh` config values `observation_hook`/`observation_detail` not validated against allowlist. Unexpected values fall through to default behavior (safe).

**SEC-L5:** `sed` range pattern in `strip_private` could delete to EOF if no closing `</private>` tag. Documented behavior. Linear time.

**SEC-L6:** Observations and corrections queue files grow unboundedly within a session. No automatic cleanup. Disk space concern for very long sessions only.

**SEC-L7:** Search query echoed without sanitization in memory-search output. Self-injection only (query comes from user's own prompt).

**SEC-L8:** `cd "$cwd"` in post-tool-use.sh follows symlinks — resolved path could be outside expected tree. Mitigated by requiring `.claude/memory` under resolved path.

**SEC-L9:** TOCTOU in corrections queue creation (`noclobber` + separate `>>` append). Writes are under PIPE_BUF, kernel guarantees atomicity for small appends. Practical risk near zero.

**SEC-L10:** Config file path from unresolved cwd in user-prompt-submit.sh. Related to SEC-M1 — fixed by same cwd resolution.

### Security Posture Assessment

**Overall risk: LOW**

The ConKeeper plugin demonstrates strong security awareness:
- Fail-open design in all hooks (verified)
- Session ID validation with `^[a-zA-Z0-9_-]+$` in all hooks (verified)
- Symlink protection for observation files (partial — needs expansion)
- Input sanitization for corrections queue (partial — needs expansion to observations)
- Timeout enforcement in hooks.json
- Privacy enforcement documented and implemented

**Primary risk area:** Indirect prompt injection via memory files (SEC-H2). This is an inherent design tradeoff of file-based memory systems and is appropriately documented. The fix limits auto-sync blast radius.

**Security tests recommended:** 10 new tests (see Technical Security Review output for full list).

---
