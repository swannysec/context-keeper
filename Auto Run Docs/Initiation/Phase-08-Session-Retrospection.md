# Phase 08: Session Retrospection (`/memory-reflect`)

**Version Bump:** v0.9.0 → v1.0.0
**Dependency:** ALL previous phases. This is the capstone feature that builds on categories (Phase 03), privacy (Phase 04), search (Phase 05), observations (Phase 06), and corrections (Phase 07).

This phase adds a `/memory-reflect` skill implementing a 7-phase After Action Review (AAR) workflow. Produces a retrospective report with improvement log and backlog. Also adds a Stop hook to suggest reflection at session end.

## Tasks

- [ ] Create the `/memory-reflect` skill definition (`skills/memory-reflect/SKILL.md`):
  - Create directory: `mkdir -p skills/memory-reflect`
  - Create `skills/memory-reflect/SKILL.md` with YAML front matter:
    ```yaml
    ---
    name: memory-reflect
    description: Session retrospection using After Action Review methodology. Analyzes corrections, observations, and session activity to produce improvement recommendations. Use at end of sessions or after /memory-sync.
    ---
    ```
  - **Skill body — 7-Phase AAR Workflow:**

  - **Phase 1: Gather Evidence**
    ```
    Read the following data sources (skip any that don't exist):
    1. `.claude/memory/corrections-queue.md` — unprocessed correction/friction items
    2. Current session's observation file: `.claude/memory/sessions/YYYY-MM-DD-observations.md`
    3. Current session summary (if /memory-sync has run): most recent file in `.claude/memory/sessions/`
    4. `.claude/memory/active-context.md` — current project state

    Estimate session depth:
    - Count observation entries + correction entries + session file size
    - If < 5 observations AND 0 corrections → mark as LIGHTWEIGHT session
    - Otherwise → mark as STANDARD or THOROUGH based on reflect_depth config

    **Privacy:** Skip any content within <private>...</private> blocks.
    Skip files with `private: true` in YAML front matter.
    ```

  - **Phase 2: Classify Scope**
    ```
    Recommend scope classification:
    - PROCESS: Improvements to how the agent works (efficiency, tool usage, workflow)
    - PROJECT: Improvements to the codebase, architecture, documentation, or tests
    - BOTH: Improvements spanning both areas

    Present recommendation to user:
    "Scope recommendation: [PROCESS/PROJECT/BOTH] — [brief reason]"
    User can adjust. Proceed with confirmed scope.

    For LIGHTWEIGHT sessions: Auto-select PROCESS scope and produce minimal output.
    ```

  - **Phase 3: Analyze Patterns**
    ```
    1. Group corrections by type — repeated corrections get priority
    2. Analyze observation log for friction patterns:
       - Repeated failures (same file/command failing multiple times)
       - Many retries on the same file
       - Long sequences of read operations without progress
    3. Cross-reference with existing knowledge:
       - Read `.claude/memory/patterns.md` — don't re-discover known patterns
       - Read `.claude/memory/decisions/` — don't re-recommend existing decisions
       - Use `/memory-search` to check if similar issues were flagged in past session retros
    4. Identify net-new insights vs. reinforcements of existing knowledge
    ```

  - **Phase 4: Research (Conditional)**
    ```
    Only triggered when the agent needs external context to validate a recommendation.

    Examples:
    - User corrected AI to use a different testing pattern → research current best practices
    - Friction around a specific tool → research known issues or alternatives

    Never assume. Always back recommendations with evidence from the session or external sources.

    Skip this phase for LIGHTWEIGHT sessions.
    ```

  - **Phase 5: Generate Recommendations**
    ```
    For each recommendation, include:
    - **What:** Specific, actionable change (one sentence)
    - **Why:** Evidence from session — quote the correction text or observation pattern
    - **Where:** Target file or skill to update (exact path)
    - **Impact:** Expected improvement (one sentence)
    - **Category:** Retrospective category tag:
      - Agent efficiency → `<!-- @category: efficiency -->`
      - Code/output quality → `<!-- @category: quality -->`
      - User experience → `<!-- @category: ux -->`
      - Knowledge gap → `<!-- @category: knowledge -->`
      - Architectural improvement → `<!-- @category: architecture -->`

    For LIGHTWEIGHT sessions: Generate 0-2 recommendations max.
    For STANDARD sessions: Generate 2-5 recommendations.
    For THOROUGH sessions: Generate up to 10 recommendations with deeper analysis.
    ```

  - **Phase 6: Present for Approval**
    ```
    Display recommendations grouped by scope (PROCESS vs PROJECT):

    ## Recommendations

    ### Process Improvements
    1. [Recommendation] — Evidence: [quote] — Target: [file]

    ### Project Improvements
    1. [Recommendation] — Evidence: [quote] — Target: [file]

    For each recommendation, user can:
    - ✅ Approve → route to target memory file with category tag
    - ❌ Deny → note as "considered but declined" in retro file
    - 🔄 Iterate → modify the recommendation and re-approve

    Approved items routing:
    - Code conventions → patterns.md (Code Conventions section)
    - Architecture decisions → decisions/ADR-NNN-*.md (create new ADR)
    - Terminology → glossary.md
    - Workflow preferences → product-context.md or active-context.md
    - Backlog items → retro file's Improvement Backlog section
    ```

  - **Phase 7: Write Retrospective**
    ```
    Create retrospective file at: `.claude/memory/sessions/YYYY-MM-DD-retro.md`

    Format:
    ```markdown
    # Session Retrospective — YYYY-MM-DD

    ## Session Summary
    [Brief 2-3 sentence summary of what happened in this session]

    ## Improvement Log
    ### Approved
    - [Recommendation 1] → routed to patterns.md
    <!-- @category: quality -->
    - [Recommendation 2] → routed to decisions/ADR-NNN.md
    <!-- @category: architecture -->

    ### Declined
    - [Recommendation 3] — reason: [user's reason or "user declined"]

    ## Improvement Backlog
    - [ ] [Future improvement idea 1 — actionable, specific]
    - [ ] [Future improvement idea 2]

    ## Evidence
    - Corrections: [N] detected, [M] processed
    - Observations: [N] tool uses, [M] failures
    - Friction signals: [list of friction patterns detected]
    - Session depth: [LIGHTWEIGHT/STANDARD/THOROUGH]

    ---
    *Generated by /memory-reflect*
    ```

    For LIGHTWEIGHT sessions, produce a minimal retro:
    ```markdown
    # Session Retrospective — YYYY-MM-DD

    ## Summary
    [Short session with minimal activity. No notable improvements identified.]

    ## Evidence
    - Observations: [N] tool uses
    - Corrections: 0

    ---
    *Generated by /memory-reflect (lightweight)*
    ```
    ```

- [ ] Create the Stop hook script (`hooks/stop.sh`):
  - Create `hooks/stop.sh` with `#!/usr/bin/env bash` and `set -euo pipefail`
  - Add error trap: `trap 'exit 0' ERR`
  - Script body:
    ```bash
    #!/usr/bin/env bash
    set -euo pipefail
    trap 'exit 0' ERR

    # Only suggest reflect if project memory exists
    if [[ -d ".claude/memory" ]]; then
        # Check if there are unprocessed corrections or observations
        has_data=false
        queue=".claude/memory/corrections-queue.md"
        obs=".claude/memory/sessions/$(date +%Y-%m-%d)-observations.md"

        if [[ -f "$queue" ]] && [[ $(wc -l < "$queue") -gt 3 ]]; then
            has_data=true
        fi
        if [[ -f "$obs" ]] && [[ $(wc -l < "$obs") -gt 3 ]]; then
            has_data=true
        fi

        if [[ "$has_data" == true ]]; then
            echo "[ConKeeper] Session ending. Consider running /memory-reflect to capture learnings from this session." >&2
        fi
    fi

    exit 0
    ```
  - Make executable: `chmod +x hooks/stop.sh`
  - **Note:** The Stop hook is a newer Claude Code feature. If unavailable in the current Claude Code version, the hook registration will be silently ignored. The fallback is manual invocation of `/memory-reflect`.

- [ ] Register the Stop hook in `hooks/hooks.json`:
  - Add a new `"Stop"` entry to the `"hooks"` object:
    ```json
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/stop.sh",
            "timeout": 5
          }
        ]
      }
    ]
    ```
  - Verify the JSON is valid after editing

- [ ] Update `/memory-sync` skill to suggest reflection after sync:
  - Edit `skills/memory-sync/SKILL.md`
  - Modify Step 5 (Confirm) to conditionally suggest reflect:
    ```
    ### Step 5: Confirm

    > Memory synced. [N] files updated.

    If corrections were processed in Step 2.5, or if this was a substantial session
    (many decisions, significant progress), append:

    > Consider running /memory-reflect for deeper session analysis.

    Read `auto_reflect` from `.memory-config.md` (default: true).
    If `auto_reflect: true` and corrections were processed, automatically proceed to
    run /memory-reflect after sync completes (no additional user prompt needed).
    ```

- [ ] Update `/memory-config` skill with reflect configuration:
  - Edit `skills/memory-config/SKILL.md`
  - Add:
    ```
    ## Reflection Settings

    | Setting | Default | Options | Description |
    |---------|---------|---------|-------------|
    | `auto_reflect` | `true` | `true`, `false` | Auto-trigger /memory-reflect after /memory-sync |
    | `reflect_depth` | `standard` | `minimal`, `standard`, `thorough` | Depth of AAR analysis |

    - `minimal`: 0-2 recommendations, skip research phase, lightweight output
    - `standard`: 2-5 recommendations, conditional research, full retro file
    - `thorough`: Up to 10 recommendations, research phase enabled, deep analysis
    ```

- [ ] Update `core/memory/schema.md` to document the retro file:
  - In the Directory Structure, add the retro file:
    ```
    └── sessions/
        ├── YYYY-MM-DD-HHMM.md
        ├── YYYY-MM-DD-topic.md
        ├── YYYY-MM-DD-observations.md
        └── YYYY-MM-DD-retro.md          # Session retrospective (generated by /memory-reflect)
    ```
  - Add a new `### sessions/YYYY-MM-DD-retro.md` section documenting the format
  - Document the retrospective category set: `efficiency`, `quality`, `ux`, `knowledge`, `architecture`

- [ ] Update `.memory-config.md` schema in `core/memory/schema.md`:
  - Add the new config fields:
    ```yaml
    auto_reflect: true              # Auto-trigger /memory-reflect after /memory-sync
    reflect_depth: standard         # minimal | standard | thorough
    ```

- [ ] Update `core/snippet.md` to include `/memory-reflect` in available workflows:
  - Add to the **Available Workflows** list in all three snippet variants:
    ```
    - **memory-reflect** - Session retrospection and improvement analysis
    ```

- [ ] Update platform adapters for `/memory-reflect` awareness:
  - Platform adapters do not get a full reflect skill (it's too complex for non-Claude-Code platforms without hook support), but they should be aware of it:
  - `platforms/codex/`, `platforms/copilot/`, `platforms/cursor/`: Add a note in their existing sync skills mentioning: "After syncing, consider reviewing session observations and corrections for patterns. On Claude Code, use /memory-reflect for automated analysis."
  - `platforms/zed/rules-library/`: Add a `memory-reflect.md` with a simplified manual workflow: "Review corrections-queue.md and recent observations. Identify patterns. Write improvements to patterns.md or create ADRs."

- [ ] Write tests for session retrospection:
  - Create `tests/phase-08-retrospection/test-retrospection.sh`
  - **Setup:** Create temporary directory with full memory structure, sample corrections queue, sample observation file, sample patterns.md and decisions/
  - **Test 1:** Verify Stop hook outputs suggestion when corrections queue has entries
  - **Test 2:** Verify Stop hook is silent when no data exists (no corrections, no observations)
  - **Test 3:** Verify Stop hook is silent when `.claude/memory/` doesn't exist
  - **Test 4:** Verify `hooks/hooks.json` is valid JSON after adding both PostToolUse and Stop hooks
  - **Test 5:** Verify the retro file format matches the documented template (create a sample and validate structure)
  - **Test 6:** Verify the LIGHTWEIGHT retro format is correctly minimal
  - **Test 7:** Verify Bash 3.2 compatibility of stop.sh — parse with `bash -n hooks/stop.sh`
  - **Test 8:** Verify `/memory-reflect` skill file has valid YAML front matter (name and description fields present)
  - **Test 9:** Verify the reflect skill references all required data sources (corrections-queue.md, observations.md, active-context.md)
  - **Test 10:** Verify privacy instructions are present in the skill (grep for "private" in the skill file)
  - **Cleanup:** Remove temporary test directories
  - All tests runnable via `bash tests/phase-08-retrospection/test-retrospection.sh`

- [ ] Bump version to v1.0.0 and run the complete test suite:
  - Edit `plugin.json`: change version to `"1.0.0"`
  - Run ALL phase tests in sequence:
    - `bash tests/phase-03-categories/test-categories.sh`
    - `bash tests/phase-04-privacy/test-privacy.sh`
    - `bash tests/phase-05-search/test-search.sh`
    - `bash tests/phase-06-observations/test-observations.sh`
    - `bash tests/phase-07-corrections/test-corrections.sh`
    - `bash tests/phase-08-retrospection/test-retrospection.sh`
  - Verify `hooks/hooks.json` is valid JSON with all 5 hooks (SessionStart, UserPromptSubmit, PreCompact, PostToolUse, Stop)
  - Verify `session-start.sh` still produces valid JSON output
  - Verify `user-prompt-submit.sh` still produces valid JSON output for normal prompts
  - Verify `plugin.json` version is `"1.0.0"`
  - Update `README.md` to document all new features:
    - `/memory-search` command
    - `/memory-reflect` command
    - Category tags
    - Privacy tags
    - Observation hook
    - Correction detection
    - New configuration options
  - Commit all changes with message: `feat: add /memory-reflect session retrospection — v1.0.0 complete`
