# Phase 03: Memory Observation Categories

**Agent Persona:** Schema Designer — Focus on data format design, template consistency, cross-platform portability.
**Version Bump:** v0.4.1 → v0.5.0
**Dependency:** None — this is the foundation feature. Category tags are consumed by search (Phase 05), sync routing (Phase 07), and reflect categorization (Phase 08).
**Orchestration Reference:** See `Working/Agent-Orchestration-Plan.md` for review persona prompts and sub-agent dispatch instructions.

This phase adds inline category tags to memory file entries using HTML comment syntax. Tags are invisible in rendered Markdown but trivially parseable by grep/ripgrep, enabling structured filtering across all downstream features.

## Tasks

- [x] Add Category Tags section to the memory schema (`core/memory/schema.md`):
  - Insert a new `## Category Tags` section after the existing `## Configuration File (Optional)` section and before `## Token Budget Guidelines`
  - Document the tag format: `<!-- @category: <value> -->` placed on its own line immediately after the heading or bullet it categorizes
  - Document the two distinct category sets:
    - **Memory categories** (for memory file entries): `decision`, `pattern`, `bugfix`, `convention`, `learning`
    - **Retrospective categories** (for `/memory-reflect` output): `efficiency`, `quality`, `ux`, `knowledge`, `architecture`
  - Document freeform tag support: `<!-- @tag: some-tag -->` for user-defined tags
  - Document placement rules: one tag per line, multiple tags allowed on separate lines, tag goes immediately after the entry it categorizes
  - Document that tags are additive-only — files work normally without them
  - Add a `### Searching by Category` subsection noting: `rg '@category: decision'` or `grep '@category: decision'` finds tagged entries
  - Verify the section renders correctly (tags invisible in Markdown preview)

- [x] Update all 7 core memory templates with category tag examples:
  - `core/memory/templates/active-context.md`: Add `<!-- @category: decision -->` example after the "Recent Decisions" bullet format
  - `core/memory/templates/patterns.md`: Add `<!-- @category: pattern -->` and `<!-- @category: convention -->` examples in the Code Conventions and Architecture Patterns sections
  - `core/memory/templates/adr-template.md`: Add `<!-- @category: decision -->` on its own line after the `# ADR-NNN: Title` heading
  - `core/memory/templates/session-template.md`: Add `<!-- @category: learning -->` example in the "Decisions Made" section, and a comment showing retrospective category usage: `<!-- @category: efficiency -->`
  - `core/memory/templates/product-context.md`: No changes needed (rarely categorized)
  - `core/memory/templates/progress.md`: No changes needed (task tracking, not categorized)
  - `core/memory/templates/glossary.md`: No changes needed (table format doesn't suit inline tags)
  - For each modified template, add a brief HTML comment explaining the tag: `<!-- ConKeeper: category tags are invisible in rendered Markdown -->`

- [x] Update `/memory-sync` skill to auto-categorize new entries during sync:
  - Edit `skills/memory-sync/SKILL.md`
  - Insert a new **Step 2.5: Auto-Categorize Entries** between existing Step 2 (Analyze Session) and Step 3 (Propose Updates)
  - Step 2.5 instructions:
    ```
    For each new entry identified in Step 2, assign a memory category tag:
    - Contains "decided", "chose", "selected", "went with" → `decision`
    - Contains "pattern", "convention", "always", "never", "standard" → `pattern`
    - Contains "fixed", "bug", "resolved", "workaround" → `bugfix`
    - Contains "convention", "naming", "format", "style" → `convention`
    - Contains "learned", "discovered", "TIL", "realized" → `learning`
    - If unsure, use context to pick the best fit
    - Include the category tag in the proposed update shown to the user in Step 3
    ```
  - The tag should appear in Step 3's proposed output format so users see it before approval
  - Do NOT add any new dependencies or configuration — categories are always enabled

- [x] Update `/memory-init` skill to offer retroactive tagging of existing memory:
  - Edit `skills/memory-init/SKILL.md`
  - Add a new optional step after all initialization is complete (after the "Confirm initialization" step)
  - New step: "If memory files already contain entries (reset scenario or migration), ask: 'Tag existing memory entries with categories? [y/n]'"
  - If yes: Read each memory file, classify each entry/section using the keyword matching rules from Step 2.5 above, and add `<!-- @category: <value> -->` tags
  - If no: Skip — no tags added. Files continue to work normally.
  - This step is opt-in only. Never auto-tag without asking.

- [x] Update platform adapter memory-sync workflows to include categorization:
  - `platforms/codex/.codex/skills/memory-sync/SKILL.md`: Add the same Step 2.5 auto-categorization instructions
  - `platforms/copilot/.github/skills/memory-sync/SKILL.md`: Add the same Step 2.5 auto-categorization instructions
  - `platforms/cursor/.cursor/skills/memory-sync/SKILL.md`: Add the same Step 2.5 auto-categorization instructions
  - `platforms/zed/rules-library/memory-sync.md`: Add categorization guidance in the sync workflow section
  - Verify each platform adapter's sync workflow matches the Claude Code skill's categorization logic

- [x] Write tests for category tag functionality:
  - Create a test script or test cases document at `tests/phase-03-categories/` (create directory)
  - **Test 1:** Verify `<!-- @category: decision -->` is invisible in rendered Markdown output (use a Markdown renderer or verify the tag is a valid HTML comment)
  - **Test 2:** Verify `rg '@category: decision'` finds tagged entries in a sample memory file
  - **Test 3:** Verify `grep '@category: decision'` finds tagged entries (no ripgrep fallback)
  - **Test 4:** Verify `rg '@tag: custom-tag'` finds freeform tags
  - **Test 5:** Verify multiple category tags on consecutive lines are all findable
  - **Test 6:** Create a sample memory file with mixed tagged and untagged entries; verify grep counts match expected tagged-only count
  - All tests should be runnable via `bash tests/phase-03-categories/test-categories.sh` and output PASS/FAIL per test

- [x] Bump version to v0.5.0 in `plugin.json` and verify no existing tests break:
  - Edit `plugin.json`: change `"version": "0.4.1"` to `"version": "0.5.0"`
  - Run any existing test suites to verify backward compatibility
  - Verify a memory file without any category tags still loads and functions correctly (no regression)
  - Commit all changes with message: `feat: add memory observation categories (v0.5.0)`

## Review & Validation

Review stages use dedicated agent types. Agent fixes findings autonomously unless they would change design intent or functionality. All review summaries are written to `Auto Run Docs/Initiation/Working/review-logs/phase-03-review-summary.md`. See `Working/Agent-Orchestration-Plan.md` Section 3 for full review prompt templates.

- [ ] Stage 1 — Run tests: Execute `bash tests/phase-03-categories/test-categories.sh`. All tests must pass. Fix any failures before proceeding.

- [ ] Stage 2 — Parallel code and architecture review: Launch two sub-agents in parallel using the Task tool. Sub-Agent A: `subagent_type: "workflow-toolkit:code-reviewer"` — review all files for correctness, Bash 3.2 compat, readability, DRY, test coverage, error handling, regressions, code style consistency. Sub-Agent B: `subagent_type: "compound-engineering:review:architecture-strategist"` — review for schema consistency with `core/memory/schema.md`, cross-platform portability, dependency chain integrity, token budget impact, configuration backward compatibility, platform adapter consistency, naming conventions. Both output findings as Critical/High/Medium/Low.

- [ ] Stage 3 — Synthesize review findings: Read both sub-agent outputs. Deduplicate. Create consolidated list with unique IDs grouped by severity. Write summary to review log.

- [ ] Stage 4 — Fix code and architecture findings: Fix all Critical, High, and Medium findings autonomously (escalate to user only if fix changes design intent). Re-run `bash tests/phase-03-categories/test-categories.sh` after fixes.

- [ ] Stage 5 — Simplicity review: Launch one sub-agent: `subagent_type: "compound-engineering:review:code-simplicity-reviewer"` — review post-fix code for over-engineering, YAGNI violations, unnecessary abstractions. Do not suggest removing planned functionality.

- [ ] Stage 6 — Fix simplicity findings + test: Fix all "should apply" simplicity findings autonomously. Re-run `bash tests/phase-03-categories/test-categories.sh`. Write simplicity summary to review log.

- [ ] Stage 7 — Parallel security review (BLOCKED until Stage 6 complete and tests pass): Launch two sub-agents in parallel. CRITICAL: Do NOT start until Stage 6 is fully complete. Sub-Agent C: `subagent_type: "compound-engineering:review:security-sentinel"` (architecture focus) — review trust boundaries, privacy enforcement readiness (ensure no patterns preclude Phase 04 privacy tags), data flow safety, fail-open guarantees, configuration safety, file system trust, information disclosure. Sub-Agent D: `subagent_type: "compound-engineering:review:security-sentinel"` (technical focus) — review for command injection, path traversal, sed/grep injection via category values, YAML/JSON parsing safety, symlink attacks, race conditions, DoS vectors. Both output findings as Critical/High/Medium/Low.

- [ ] Stage 8 — Synthesize security findings: Read both outputs. Deduplicate. Create consolidated list. Write security summary to review log.

- [ ] Stage 9 — Fix security findings: Fix all Critical, High, and Medium security findings autonomously (escalate if design-changing). Add security-specific tests where applicable.

- [ ] Stage 10 — Final verification: Run `bash tests/phase-03-categories/test-categories.sh`. All tests must pass. Verify `plugin.json` version is `"0.5.0"`. Write final status to review log. Commit any remaining fixes with message: `fix: address review findings for Phase 03`
