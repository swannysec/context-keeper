# Phase 05: File-Based Memory Search (`/memory-search`)

**Agent Persona:** CLI Tools Developer — Focus on cross-platform shell scripting, ripgrep/grep compatibility, output formatting.
**Version Bump:** v0.6.0 → v0.7.0
**Dependency:** Phase 03 (Categories) for `--category` filtering. Phase 04 (Privacy) for private content exclusion. Both must be complete.
**Orchestration Reference:** See `Working/Agent-Orchestration-Plan.md` for review persona prompts and sub-agent dispatch instructions.

This phase adds a `/memory-search <query>` skill backed by a standalone cross-platform shell script. The search returns agent-optimized structured results grouped by file, with context and category tags. The shell script is directly callable from any platform.

## Tasks

- [x] Create the standalone search shell script (`tools/memory-search.sh`):
  - Create directory: `mkdir -p tools`
  - Create `tools/memory-search.sh` with `#!/usr/bin/env bash` and `set -euo pipefail`
  - Add error trap: `trap 'echo "[ConKeeper] memory-search.sh failed at line $LINENO" >&2; exit 0' ERR`
  - **Arguments:**
    - `$1` (required): search query string
    - `--global`: include `~/.claude/memory/` in search scope
    - `--sessions`: include `sessions/` subdirectory (excluded by default — can be noisy)
    - `--category <name>`: filter results to entries with matching `<!-- @category: <name> -->` tag
  - **Search engine auto-detection:**
    ```bash
    if command -v rg &>/dev/null; then
        SEARCH_CMD="rg"
    else
        SEARCH_CMD="grep"
    fi
    ```
  - **Search paths:** Build an array of directories to search:
    - Default: `.claude/memory/` (project memory, excluding `sessions/`)
    - With `--global`: add `~/.claude/memory/`
    - With `--sessions`: add `.claude/memory/sessions/`
  - **Privacy enforcement (two-pass approach):**
    1. First pass: For each file in search scope, identify `<private>` block line ranges using `grep -n '<private>\|</private>'`
    2. Second pass: Run the actual search query. For each match, check if the match line falls within a private block range. Omit matches within private blocks.
    3. Skip files with `private: true` in YAML front matter entirely (check first 5 lines with `head -5 | grep -q '^private: *true'`)
    4. **Simplification fallback:** If the two-pass approach is too complex in pure bash, fall back to: skip entire files that contain any `<private>` tag when `rg` is not available. Document this limitation.
  - **Category filtering:** When `--category` is specified, post-filter results:
    - For each match file, check if the matching section/entry has a `<!-- @category: <name> -->` tag within 3 lines above or below the match
    - Only include matches where the category tag is found nearby
  - **Output format:** Structured for agent consumption:
    ```
    ## Results for: "<query>"

    ### .claude/memory/active-context.md
    <!-- @category: decision -->
    **Line 15:** ...matching line with context...
    **Line 16:** ...next line for context...

    ### .claude/memory/decisions/ADR-003-search.md
    **Line 8:** ...matching line...

    ---
    Found 3 matches across 2 files.
    ```
  - **No-results output:** `No results found for "<query>" in [scope description].`
  - **Session limiting:** When `--sessions` is used, limit to files modified in the last 30 days by default (use `find -mtime -30` or `stat` comparison)
  - Make the script executable: `chmod +x tools/memory-search.sh`
  - **Bash 3.2 compatibility:** No `mapfile`, no associative arrays, no `$EPOCHSECONDS`, no `\b` in regex. Use `while read` loops and POSIX grep flags only.

- [x] Create the `/memory-search` skill definition (`skills/memory-search/SKILL.md`):
  - Create directory: `mkdir -p skills/memory-search`
  - Create `skills/memory-search/SKILL.md` with YAML front matter:
    ```yaml
    ---
    name: memory-search
    description: Search memory files for keywords, patterns, or categories. Returns structured results grouped by file with context.
    ---
    ```
  - **Skill body:**
    - Parse user query from invocation: `/memory-search <query>` or `/memory-search --category decision "token budget"`
    - Call `tools/memory-search.sh` via Bash tool with the parsed arguments
    - Present results to user/agent
    - If no results, suggest broadening the search (try `--global`, try `--sessions`, try alternate keywords)
  - **Usage examples in the skill:**
    ```
    /memory-search "token budget"
    /memory-search --global "naming convention"
    /memory-search --sessions "authentication bug"
    /memory-search --category decision "database"
    ```

- [ ] Modify `hooks/session-start.sh` to inject search reminder into context:
  - In the context message block (around line 57-69), add a new line in the "For non-trivial tasks" guidance:
    ```
    - Search memory with /memory-search <query> before re-investigating known problems
    ```
  - Add it after the existing "Review decisions/ for architectural context" line
  - Keep it concise — this adds ~15 tokens to the session-start context

- [ ] Update `core/snippet.md` to include `/memory-search` in available workflows:
  - In all three snippet variants (append, create new, manual copy), add to the **Available Workflows** list:
    ```
    - **memory-search** - Search memory files by keyword or category
    ```
  - Add it after the existing `session-handoff` entry

- [ ] Update `core/memory/schema.md` to reference search capability:
  - In the main directory structure section, add a note: "Use `/memory-search <query>` to find entries across memory files"
  - In the Category Tags section (added in Phase 03), add: "Categories are searchable via `/memory-search --category <name>`"

- [ ] Update platform adapters to reference the search script:
  - `platforms/codex/.codex/skills/`: Create `memory-search/SKILL.md` mirroring the Claude Code skill but referencing the script path as `tools/memory-search.sh` relative to the ConKeeper install
  - `platforms/copilot/.github/skills/`: Create `memory-search/SKILL.md` with same approach
  - `platforms/cursor/.cursor/skills/`: Create `memory-search/SKILL.md` with same approach
  - `platforms/zed/rules-library/`: Create `memory-search.md` with search workflow guidance that references the shell script
  - Each platform adapter should note: "Run `bash <conkeeper-path>/tools/memory-search.sh <query>` to search memory"

- [ ] Write tests for memory search functionality:
  - Create `tests/phase-05-search/test-search.sh`
  - **Setup:** Create a temporary memory directory with sample files containing known content, category tags, and privacy tags
  - **Test 1:** Basic search finds matches in project memory files
  - **Test 2:** `--global` flag includes global memory directory
  - **Test 3:** `--sessions` flag includes session files
  - **Test 4:** `--category decision` filters results to only entries with `<!-- @category: decision -->`
  - **Test 5:** `<private>` block content is excluded from results
  - **Test 6:** Files with `private: true` front matter are excluded entirely
  - **Test 7:** Ripgrep auto-detection works — mock `rg` unavailable and verify grep fallback
  - **Test 8:** Script works on current platform (macOS Bash 3.2 or Linux Bash 4+)
  - **Test 9:** Empty query or no matches returns clean "No results" output
  - **Test 10:** Output format is structured with file headers, line numbers, and category tags
  - **Cleanup:** Remove temporary test directory after all tests
  - All tests runnable via `bash tests/phase-05-search/test-search.sh`

- [ ] Bump version to v0.7.0 and verify all existing tests pass:
  - Edit `plugin.json`: change version to `"0.7.0"`
  - Run Phase 03 tests (categories)
  - Run Phase 04 tests (privacy)
  - Run Phase 05 tests (search)
  - Verify session-start.sh still produces valid JSON output
  - Commit all changes with message: `feat: add /memory-search skill with cross-platform shell script (v0.7.0)`

## Review & Validation

Review stages use dedicated agent types. Agent fixes findings autonomously unless they would change design intent or functionality. All review summaries are written to `Auto Run Docs/Initiation/Working/review-logs/phase-05-review-summary.md`. See `Working/Agent-Orchestration-Plan.md` Section 3 for full review prompt templates.

- [ ] Stage 1 — Run tests: Execute `bash tests/phase-05-search/test-search.sh`, `bash tests/phase-04-privacy/test-privacy.sh`, and `bash tests/phase-03-categories/test-categories.sh` (regression). All tests must pass. Fix any failures before proceeding.

- [ ] Stage 2 — Parallel code and architecture review: Launch two sub-agents in parallel. Sub-Agent A: `subagent_type: "workflow-toolkit:code-reviewer"` — review `tools/memory-search.sh`, `skills/memory-search/SKILL.md`, and all modified files for correctness, Bash 3.2 compat (critical — new shell script), cross-platform grep/rg behavior, argument parsing edge cases, error handling, test coverage of privacy and category filtering, output format consistency. Sub-Agent B: `subagent_type: "compound-engineering:review:architecture-strategist"` — review schema consistency (search output format vs schema docs), cross-platform portability (all 6 platforms), privacy enforcement completeness (two-pass approach vs fallback), token budget impact of search reminder in session-start, platform adapter consistency, naming conventions. Both output findings as Critical/High/Medium/Low.

- [ ] Stage 3 — Synthesize review findings: Read both outputs. Deduplicate. Create consolidated list. Write summary to review log.

- [ ] Stage 4 — Fix code and architecture findings: Fix all Critical, High, and Medium findings autonomously (escalate if design-changing). Re-run all test suites after fixes.

- [ ] Stage 5 — Simplicity review: Launch one sub-agent: `subagent_type: "compound-engineering:review:code-simplicity-reviewer"` — review post-fix `tools/memory-search.sh` for over-engineering in the two-pass privacy filtering, argument parsing, and output formatting logic.

- [ ] Stage 6 — Fix simplicity findings + test: Fix all "should apply" findings autonomously. Re-run all tests. Write simplicity summary to review log.

- [ ] Stage 7 — Parallel security review (BLOCKED until Stage 6 complete and tests pass): Launch two sub-agents in parallel. CRITICAL: Do NOT start until Stage 6 is fully complete. Sub-Agent C: `subagent_type: "compound-engineering:review:security-sentinel"` (architecture focus) — review trust boundaries for user-supplied search queries, privacy enforcement in the two-pass approach (can crafted file content bypass private block detection?), data flow from search results (could results expose private content?), file system trust (path traversal via `--global` flag or symlinks). Sub-Agent D: `subagent_type: "compound-engineering:review:security-sentinel"` (technical focus) — review for command injection via search query (proper quoting when passed to grep/rg?), grep/rg regex injection, path traversal in directory construction, race conditions in privacy block detection, argument parsing bypass. Command injection and privacy bypass findings are Critical by default.

- [ ] Stage 8 — Synthesize security findings: Read both outputs. Deduplicate. Create consolidated list. Write security summary to review log.

- [ ] Stage 9 — Fix security findings: Fix all Critical, High, and Medium findings autonomously (escalate if design-changing). Add security tests where applicable.

- [ ] Stage 10 — Final verification: Run all test suites (phases 03-05). All must pass. Verify `plugin.json` version is `"0.7.0"`. Verify `session-start.sh` produces valid JSON. Verify `tools/memory-search.sh` is executable. Write final status to review log. Commit any remaining fixes.
