# Phase 03: Memory Observation Categories

**Version Bump:** v0.4.1 → v0.5.0
**Dependency:** None — this is the foundation feature. Category tags are consumed by search (Phase 05), sync routing (Phase 07), and reflect categorization (Phase 08).

This phase adds inline category tags to memory file entries using HTML comment syntax. Tags are invisible in rendered Markdown but trivially parseable by grep/ripgrep, enabling structured filtering across all downstream features.

## Tasks

- [ ] Add Category Tags section to the memory schema (`core/memory/schema.md`):
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

- [ ] Update all 7 core memory templates with category tag examples:
  - `core/memory/templates/active-context.md`: Add `<!-- @category: decision -->` example after the "Recent Decisions" bullet format
  - `core/memory/templates/patterns.md`: Add `<!-- @category: pattern -->` and `<!-- @category: convention -->` examples in the Code Conventions and Architecture Patterns sections
  - `core/memory/templates/adr-template.md`: Add `<!-- @category: decision -->` on its own line after the `# ADR-NNN: Title` heading
  - `core/memory/templates/session-template.md`: Add `<!-- @category: learning -->` example in the "Decisions Made" section, and a comment showing retrospective category usage: `<!-- @category: efficiency -->`
  - `core/memory/templates/product-context.md`: No changes needed (rarely categorized)
  - `core/memory/templates/progress.md`: No changes needed (task tracking, not categorized)
  - `core/memory/templates/glossary.md`: No changes needed (table format doesn't suit inline tags)
  - For each modified template, add a brief HTML comment explaining the tag: `<!-- ConKeeper: category tags are invisible in rendered Markdown -->`

- [ ] Update `/memory-sync` skill to auto-categorize new entries during sync:
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

- [ ] Update `/memory-init` skill to offer retroactive tagging of existing memory:
  - Edit `skills/memory-init/SKILL.md`
  - Add a new optional step after all initialization is complete (after the "Confirm initialization" step)
  - New step: "If memory files already contain entries (reset scenario or migration), ask: 'Tag existing memory entries with categories? [y/n]'"
  - If yes: Read each memory file, classify each entry/section using the keyword matching rules from Step 2.5 above, and add `<!-- @category: <value> -->` tags
  - If no: Skip — no tags added. Files continue to work normally.
  - This step is opt-in only. Never auto-tag without asking.

- [ ] Update platform adapter memory-sync workflows to include categorization:
  - `platforms/codex/.codex/skills/memory-sync/SKILL.md`: Add the same Step 2.5 auto-categorization instructions
  - `platforms/copilot/.github/skills/memory-sync/SKILL.md`: Add the same Step 2.5 auto-categorization instructions
  - `platforms/cursor/.cursor/skills/memory-sync/SKILL.md`: Add the same Step 2.5 auto-categorization instructions
  - `platforms/zed/rules-library/memory-sync.md`: Add categorization guidance in the sync workflow section
  - Verify each platform adapter's sync workflow matches the Claude Code skill's categorization logic

- [ ] Write tests for category tag functionality:
  - Create a test script or test cases document at `tests/phase-03-categories/` (create directory)
  - **Test 1:** Verify `<!-- @category: decision -->` is invisible in rendered Markdown output (use a Markdown renderer or verify the tag is a valid HTML comment)
  - **Test 2:** Verify `rg '@category: decision'` finds tagged entries in a sample memory file
  - **Test 3:** Verify `grep '@category: decision'` finds tagged entries (no ripgrep fallback)
  - **Test 4:** Verify `rg '@tag: custom-tag'` finds freeform tags
  - **Test 5:** Verify multiple category tags on consecutive lines are all findable
  - **Test 6:** Create a sample memory file with mixed tagged and untagged entries; verify grep counts match expected tagged-only count
  - All tests should be runnable via `bash tests/phase-03-categories/test-categories.sh` and output PASS/FAIL per test

- [ ] Bump version to v0.5.0 in `plugin.json` and verify no existing tests break:
  - Edit `plugin.json`: change `"version": "0.4.1"` to `"version": "0.5.0"`
  - Run any existing test suites to verify backward compatibility
  - Verify a memory file without any category tags still loads and functions correctly (no regression)
  - Commit all changes with message: `feat: add memory observation categories (v0.5.0)`
