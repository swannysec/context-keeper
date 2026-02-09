# Phase 04: Privacy Tags

**Agent Persona:** Privacy Engineer — Focus on enforcement guarantees, edge cases, sed/grep compatibility, fail-safe defaults.
**Version Bump:** v0.5.0 → v0.6.0
**Dependency:** Phase 03 (Categories) should be complete. Privacy enforcement must be in place before any new read/write paths (search, observations, reflect) ship.
**Orchestration Reference:** See `Working/Agent-Orchestration-Plan.md` for review persona prompts and sub-agent dispatch instructions.

This phase adds `<private>...</private>` block wrappers for sensitive content in memory files. Content inside privacy tags is excluded from context injection, search results, sync analysis, and reflection. Also supports file-level privacy via `private: true` in YAML front matter.

## Tasks

- [x] Add Privacy Tags section to the memory schema (`core/memory/schema.md`):
  - Insert a new `## Privacy Tags` section after the `## Category Tags` section added in Phase 03
  - Document the block-level format: `<private>` and `</private>` on their own lines, content between them is excluded from all automated processing
  - Document that tags are **visible** to humans editing the file (intentional — privacy should be obvious)
  - Document file-level privacy: `private: true` in YAML front matter marks the entire file as private
  - Document enforcement points:
    - SessionStart hook: strips private blocks before context injection
    - `/memory-search`: omits private block contents from results
    - `/memory-sync`: skips private content during analysis; never moves or references private content
    - `/memory-reflect`: skips private content during evidence gathering
  - Document edge cases:
    - Nesting: NOT supported. Outer tag wins. Document this explicitly.
    - Code fences: Tags inside code fences are NOT processed (only match tags at line start with optional whitespace)
    - Empty private blocks: `<private></private>` is valid, means nothing is hidden
  - Add example usage showing a patterns.md entry with a private API key reference

- [x] Update core memory templates with privacy tag examples:
  - `core/memory/templates/active-context.md`: Add a commented example at the bottom: `<!-- To mark sensitive content private: wrap in <private>...</private> tags -->`
  - `core/memory/templates/patterns.md`: Add same commented hint
  - `core/memory/templates/product-context.md`: Add same commented hint in the Constraints section (common place for sensitive info)
  - `core/memory/templates/adr-template.md`: Add hint in the Rationale section
  - Other templates: no changes needed (session files and progress files rarely contain sensitive content)
  - **Done:** Verified glossary.md, session-template.md, and progress.md correctly excluded (no sensitive content sections).

- [x] Modify `hooks/session-start.sh` to strip private content before context injection:
  - After reading memory files for context injection (around line 49 where `context` is built), add privacy stripping
  - Implementation approach:
    1. Before building the context message, define a `strip_private()` function:
       ```bash
       strip_private() {
           local content="$1"
           # Strip block-level <private>...</private> content
           # Only match <private> at line start (with optional whitespace)
           printf '%s' "$content" | sed '/<private>/,/<\/private>/d'
       }
       ```
    2. When reading memory file content (if/when session-start reads file contents), pipe through `strip_private`
    3. For files with `private: true` in YAML front matter, skip the entire file:
       ```bash
       is_file_private() {
           local file="$1"
           head -5 "$file" | grep -q '^private: *true' && return 0
           return 1
       }
       ```
  - **POSIX sed compatibility:** Test the sed pattern with both BSD sed (macOS) and GNU sed (Linux). The pattern `sed '/<private>/,/<\/private>/d'` works on both.
  - **Important:** The current session-start.sh does NOT read individual memory file contents — it only checks for directory existence and injects a static message. The privacy stripping function should be added as infrastructure for when content injection is added in future phases, and documented with a comment: `# Privacy stripping — used by content injection (see Phase 05+ enhancements)`
  - If session-start.sh currently has no content injection path, add the functions but don't call them yet. They'll be consumed by Phase 05 (search) and Phase 06 (observations).

- [x] Update `/memory-sync` skill to respect privacy tags:
  - Edit `skills/memory-sync/SKILL.md`
  - Add a privacy notice at the top of Step 2 (Analyze Session):
    ```
    **Privacy:** When analyzing memory files, skip any content within `<private>...</private>` blocks.
    Do not reference, move, or modify private content. Do not include private content in sync summaries.
    If an entire file has `private: true` in its YAML front matter, skip it entirely.
    ```
  - This is instruction-level enforcement (the LLM follows these rules during sync)

- [x] Update `/memory-config` skill to document privacy tags:
  - Edit `skills/memory-config/SKILL.md`
  - Add a section under the existing configuration documentation:
    ```
    ## Privacy Tags

    Privacy tags are always enforced — there is no configuration toggle.
    - Wrap sensitive content in `<private>...</private>` tags
    - Add `private: true` to YAML front matter for entire-file privacy
    - Private content is excluded from context injection, search, sync, and reflection
    ```

- [x] Document `.memory-config.md` front matter privacy field in schema:
  - In `core/memory/schema.md`, under the `.memory-config.md` section, add `private: true` as an optional field that can be added to any memory file's YAML front matter
  - Clarify this is a per-file setting (added to individual memory files), not a global config option

- [x] Write tests for privacy tag functionality:
  - Create `tests/phase-04-privacy/test-privacy.sh`
  - **Test 1:** Create a sample file with `<private>` blocks. Run `sed '/<private>/,/<\/private>/d'` and verify private content is stripped
  - **Test 2:** Verify the sed pattern works with BSD sed (macOS default) — run test on current platform
  - **Test 3:** Create a file with `private: true` in front matter. Verify `is_file_private()` function returns true
  - **Test 4:** Create a file WITHOUT `private: true`. Verify `is_file_private()` returns false
  - **Test 5:** Create a file with `<private>` tags inside a code fence (indented with 4 spaces or wrapped in triple backticks). Verify the content is NOT stripped (tags inside code fences should be preserved)
  - **Test 6:** Verify a memory file with no privacy tags passes through the stripping function unchanged
  - **Test 7:** Create a file with multiple `<private>` blocks. Verify all blocks are stripped
  - All tests runnable via `bash tests/phase-04-privacy/test-privacy.sh`

- [x] Update platform adapter workflows to include privacy awareness:
  - `platforms/codex/.codex/skills/memory-sync/SKILL.md`: Add the same privacy notice from the Claude Code sync skill
  - `platforms/copilot/.github/skills/memory-sync/SKILL.md`: Add same
  - `platforms/cursor/.cursor/skills/memory-sync/SKILL.md`: Add same
  - `platforms/zed/rules-library/memory-sync.md`: Add privacy guidance

- [x] Bump version to v0.6.0 in `plugin.json` and verify backward compatibility:
  - Edit `plugin.json`: change version to `"0.6.0"`
  - Run Phase 03 tests to verify categories still work
  - Run Phase 04 tests
  - Verify a memory file without any privacy tags works identically to before (no regression)
  - Commit all changes with message: `feat: add privacy tags for sensitive memory content (v0.6.0)`

## Review & Validation

Review stages use dedicated agent types. Agent fixes findings autonomously unless they would change design intent or functionality. All review summaries are written to `Auto Run Docs/Initiation/Working/review-logs/phase-04-review-summary.md`. See `Working/Agent-Orchestration-Plan.md` Section 3 for full review prompt templates.

- [x] Stage 1 — Run tests: Execute `bash tests/phase-04-privacy/test-privacy.sh` and `bash tests/phase-03-categories/test-categories.sh` (regression). All tests must pass. Fix any failures before proceeding.
  - **Result:** All 7 Phase 04 privacy tests passed. All 10 Phase 03 category tests passed (regression clean). No fixes needed.

- [ ] Stage 2 — Parallel code and architecture review: Launch two sub-agents in parallel. Sub-Agent A: `subagent_type: "workflow-toolkit:code-reviewer"` — review all files for correctness, Bash 3.2 compat (especially sed patterns — must work on BSD sed macOS AND GNU sed Linux), error handling, test coverage, edge cases (nested private tags, tags in code fences, empty blocks), consistency with existing hook code style. Sub-Agent B: `subagent_type: "compound-engineering:review:architecture-strategist"` — review for schema consistency, cross-platform portability (privacy stripping on all platforms with hooks), dependency chain (privacy enforced before Phase 05+), token budget impact (should be zero or negative), platform adapter consistency, backwards compatibility. Both output findings as Critical/High/Medium/Low.

- [ ] Stage 3 — Synthesize review findings: Read both outputs. Deduplicate. Create consolidated list. Write summary to review log.

- [ ] Stage 4 — Fix code and architecture findings: Fix all Critical, High, and Medium findings autonomously (escalate if design-changing). Re-run `bash tests/phase-04-privacy/test-privacy.sh` and `bash tests/phase-03-categories/test-categories.sh` after fixes.

- [ ] Stage 5 — Simplicity review: Launch one sub-agent: `subagent_type: "compound-engineering:review:code-simplicity-reviewer"` — review post-fix code for over-engineering, YAGNI violations, unnecessary abstractions in the privacy stripping functions and enforcement logic.

- [ ] Stage 6 — Fix simplicity findings + test: Fix all "should apply" findings autonomously. Re-run all tests. Write simplicity summary to review log.

- [ ] Stage 7 — Parallel security review (BLOCKED until Stage 6 complete and tests pass): Launch two sub-agents in parallel. CRITICAL: Do NOT start until Stage 6 is fully complete. Sub-Agent C: `subagent_type: "compound-engineering:review:security-sentinel"` (architecture focus) — privacy is the core concern: review enforcement completeness across ALL code paths, data flow for potential privacy leaks, trust boundaries for user-created memory files, sed stripping bypass vectors. Sub-Agent D: `subagent_type: "compound-engineering:review:security-sentinel"` (technical focus) — review sed patterns for regex injection via crafted `<private>` content, POSIX sed compatibility, TOCTOU race conditions in privacy checking, symlink safety in file-level privacy, malformed YAML front matter bypassing `private: true` detection. Privacy bypass findings are Critical by default.

- [ ] Stage 8 — Synthesize security findings: Read both outputs. Deduplicate. Create consolidated list. Write security summary to review log.

- [ ] Stage 9 — Fix security findings: Fix all Critical, High, and Medium findings autonomously (escalate if design-changing). Add security-specific tests.

- [ ] Stage 10 — Final verification: Run `bash tests/phase-04-privacy/test-privacy.sh` and `bash tests/phase-03-categories/test-categories.sh`. All must pass. Verify `plugin.json` version is `"0.6.0"`. Verify `hooks/hooks.json` is valid JSON. Verify `session-start.sh` produces valid JSON. Write final status to review log. Commit any remaining fixes.
