# Phase 08: Session Retrospection (`/memory-reflect`)

**Agent Persona:** Workflow Designer — Focus on AAR methodology, skill instruction clarity, integration with all prior features.
**Version Bump:** v0.9.0 → v1.0.0
**Dependency:** ALL previous phases. This is the capstone feature that builds on categories (Phase 03), privacy (Phase 04), search (Phase 05), observations (Phase 06), and corrections (Phase 07).
**Orchestration Reference:** See `Working/Agent-Orchestration-Plan.md` for review persona prompts and sub-agent dispatch instructions.

This phase adds a `/memory-reflect` skill implementing a 7-phase After Action Review (AAR) workflow. Produces a retrospective report with improvement log and backlog. Also adds a Stop hook to suggest reflection at session end.

## Tasks

- [x] Create the `/memory-reflect` skill definition (`skills/memory-reflect/SKILL.md`):
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
    5. **Claude Code facets data** (if available): Find the facet JSON file matching the
       current session ID in `~/.claude/usage-data/facets/`. Extract:
       - `friction_counts` — pre-classified friction events by type
       - `friction_detail` — plain-English description of what went wrong
       - `user_satisfaction_counts` — inferred satisfaction signals
       - `outcome` — session outcome (fully_achieved, mostly_achieved, etc.)
       - `goal_categories` — categorized sub-goals
       - `primary_success` — what went right
       If the facets directory doesn't exist or no matching session is found, skip gracefully.
       Facets data is Claude Code-specific and may not exist on all installations.

    Estimate session depth:
    - Count observation entries + correction entries + session file size
    - If facets data exists, also consider: friction count, satisfaction signals
    - If < 5 observations AND 0 corrections AND no facets friction → mark as LIGHTWEIGHT
    - Otherwise → mark as STANDARD or THOROUGH based on reflect_depth config

    **Privacy:** Skip any content within <private>...</private> blocks.
    Skip files with `private: true` in YAML front matter.
    Facets data does not contain file contents — no privacy filtering needed for facets.
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
    3. **Facets-enhanced analysis** (if facets data was gathered in Phase 1):
       - Use `friction_counts` as pre-classified friction signals (more accurate than
         manual observation log scanning — these are LLM-classified, not regex-matched)
       - Use `friction_detail` for narrative context on what went wrong
       - Map facets friction types to ConKeeper categories:
         wrong_approach → efficiency, buggy_code → quality,
         misunderstood_request → ux, excessive_changes → quality,
         got_stuck → efficiency, premature_stop → efficiency
       - For THOROUGH depth: cross-session trend analysis:
         Read ALL facet files in ~/.claude/usage-data/facets/
         Aggregate friction_counts across sessions
         Identify recurring friction patterns (e.g., "wrong_approach" correlating
         with specific goal_categories like "debugging" or "configuration_change")
         Compare current session's friction profile to historical baseline
         Flag if this session's dominant friction type has occurred in 3+ past sessions
    4. Cross-reference with existing knowledge:
       - Read `.claude/memory/patterns.md` — don't re-discover known patterns
       - Read `.claude/memory/decisions/` — don't re-recommend existing decisions
       - Use `/memory-search` to check if similar issues were flagged in past session retros
    5. Identify net-new insights vs. reinforcements of existing knowledge
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
    - Facets data: [available/unavailable]
      - Outcome: [fully_achieved/mostly_achieved/etc.]
      - Friction: [friction_counts summary, e.g., "wrong_approach: 2, buggy_code: 1"]
      - Satisfaction: [user_satisfaction_counts summary]
      - Detail: [friction_detail narrative, truncated to 200 chars]
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

- [x] Create the `/memory-insights` skill definition (`skills/memory-insights/SKILL.md`):
  - Create directory: `mkdir -p skills/memory-insights`
  - Create `skills/memory-insights/SKILL.md` with YAML front matter:
    ```yaml
    ---
    name: memory-insights
    description: Analyze session friction trends, success rates, and satisfaction patterns across sessions using Claude Code facets data. Read-only query tool for on-demand trend analysis.
    ---
    ```
  - **Skill body:**
    ```
    Read all JSON files in ~/.claude/usage-data/facets/ (skip gracefully if directory doesn't exist).
    Each file is a per-session analysis with fields: session_id, underlying_goal, goal_categories,
    outcome, session_type, claude_helpfulness, primary_success, friction_counts, friction_detail,
    user_satisfaction_counts, brief_summary.

    Default (no arguments): Show a summary dashboard:
    - Total sessions analyzed: [N]
    - Outcome breakdown: fully_achieved [N], mostly_achieved [N], etc.
    - Helpfulness: essential [N], very_helpful [N], etc.
    - Top 5 friction types with counts
    - Sessions with friction: [N]/[total] ([%])
    - Satisfaction: [satisfied+likely_satisfied] positive, [dissatisfied+frustrated] negative

    /memory-insights friction — Friction deep dive:
    - All friction types ranked by count
    - Top 5 highest-friction sessions with brief_summary and friction_detail
    - Correlation: which goal_categories have the most friction?
    - Trend: is friction increasing or decreasing over recent sessions?

    /memory-insights sessions --worst — Show highest-friction sessions:
    - Sort all sessions by total friction count (descending)
    - Show top 10 with: session_id, brief_summary, friction_counts, outcome
    - Include friction_detail for each

    /memory-insights sessions --best — Show most successful sessions:
    - Filter: outcome=fully_achieved AND friction_counts is empty
    - Show with: session_id, brief_summary, primary_success, session_type

    /memory-insights patterns — Cross-session pattern analysis:
    - Correlate friction types with goal_categories
      (e.g., "wrong_approach clusters around debugging and configuration_change tasks")
    - Correlate session_type with outcome
      (e.g., "iterative_refinement has 80% fully_achieved vs multi_task at 50%")
    - Identify which primary_success factors appear in friction-free sessions

    **Privacy:** Facets data contains session summaries and goals but no file contents.
    No privacy tag filtering is needed. However, do not expose full underlying_goal text
    if it might contain sensitive project details — summarize instead.

    **Graceful degradation:** If ~/.claude/usage-data/facets/ doesn't exist, output:
    "No facets data available. Facets are generated by Claude Code and may not be present
    on all installations. Session insights require at least one completed Claude Code session."
    ```

- [x] Create the Stop hook script (`hooks/stop.sh`):
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

- [x] Register the Stop hook in `hooks/hooks.json`:
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

- [x] Update `/memory-sync` skill to suggest reflection after sync:
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

- [x] Update `/memory-config` skill with reflect configuration:
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

- [x] Update `core/memory/schema.md` to document the retro file and facets data source:
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
  - Add a new `## External Data Sources` section documenting:
    ```
    ### Claude Code Facets (~/.claude/usage-data/facets/)

    **Availability:** Claude Code only. Not present on other platforms.
    **Format:** Per-session JSON files named by session UUID.
    **Purpose:** Pre-classified session analysis including friction types, satisfaction signals,
    goal categories, and outcome assessment. Generated by Claude Code after sessions complete.
    **Used by:** /memory-reflect (evidence gathering and pattern analysis),
    /memory-insights (trend analysis and dashboards).
    **Privacy:** Contains session summaries and goals but no file contents.
    Not managed by ConKeeper — read-only access.
    ```

- [x] Update `.memory-config.md` schema in `core/memory/schema.md`:
  - Add the new config fields:
    ```yaml
    auto_reflect: true              # Auto-trigger /memory-reflect after /memory-sync
    reflect_depth: standard         # minimal | standard | thorough
    ```

- [x] Update `core/snippet.md` to include `/memory-reflect` and `/memory-insights` in available workflows:
  - Add to the **Available Workflows** list in all three snippet variants:
    ```
    - **memory-reflect** - Session retrospection and improvement analysis
    - **memory-insights** - Session friction trends and success pattern analysis
    ```

- [x] Update platform adapters for `/memory-reflect` awareness:
  - Platform adapters do not get a full reflect skill (it's too complex for non-Claude-Code platforms without hook support), but they should be aware of it:
  - `platforms/codex/`, `platforms/copilot/`, `platforms/cursor/`: Add a note in their existing sync skills mentioning: "After syncing, consider reviewing session observations and corrections for patterns. On Claude Code, use /memory-reflect for automated analysis."
  - `platforms/zed/rules-library/`: Add a `memory-reflect.md` with a simplified manual workflow: "Review corrections-queue.md and recent observations. Identify patterns. Write improvements to patterns.md or create ADRs."

- [x] Write tests for session retrospection:
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
  - **Test 9:** Verify the reflect skill references all required data sources (corrections-queue.md, observations.md, active-context.md, facets)
  - **Test 10:** Verify privacy instructions are present in the skill (grep for "private" in the skill file)
  - **Test 11:** Verify `/memory-insights` skill file exists with valid YAML front matter
  - **Test 12:** Verify `/memory-insights` skill references `~/.claude/usage-data/facets/` and handles missing directory gracefully
  - **Test 13:** Verify the reflect skill's facets integration handles missing `~/.claude/usage-data/facets/` gracefully (grep for "skip gracefully" or equivalent)
  - **Cleanup:** Remove temporary test directories
  - All tests runnable via `bash tests/phase-08-retrospection/test-retrospection.sh`

- [x] Bump version to v1.0.0 and run the complete test suite:
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
    - `/memory-insights` command
    - Category tags
    - Privacy tags
    - Observation hook
    - Correction detection
    - Facets data integration (Claude Code only)
    - New configuration options
  - Commit all changes with message: `feat: add /memory-reflect session retrospection — v1.0.0 complete`

## Review & Validation

Review stages use dedicated agent types. Agent fixes findings autonomously unless they would change design intent or functionality. All review summaries are written to `Auto Run Docs/Initiation/Working/review-logs/phase-08-review-summary.md`. See `Working/Agent-Orchestration-Plan.md` Section 3 for full review prompt templates. **This is the v1.0.0 release — all findings must be addressed.**

- [x] Stage 1 — Run tests: Execute `bash tests/phase-08-retrospection/test-retrospection.sh` and ALL prior phase tests (03-07) for full regression. All tests must pass. Fix any failures before proceeding.
  - **Result:** All 73 tests pass across 6 phases: Phase 03 (10/10), Phase 04 (13/13), Phase 05 (11/11), Phase 06 (12/12), Phase 07 (14/14), Phase 08 (13/13).

- [x] Stage 2 — Parallel code and architecture review: Launch two sub-agents in parallel. Sub-Agent A: `subagent_type: "workflow-toolkit:code-reviewer"` — review `skills/memory-reflect/SKILL.md` for instruction clarity and completeness (all 7 AAR phases), `hooks/stop.sh` for Bash 3.2 compat, `hooks/hooks.json` validity (now 5 hooks), `/memory-sync` Step 5 modification correctness, config documentation, README accuracy (all 6 new features), test coverage of hook and skill. Sub-Agent B: `subagent_type: "compound-engineering:review:architecture-strategist"` — review integration coherence across ALL 6 phases (does capstone correctly consume all prior phase data?), schema documentation completeness, snippet updates, platform adapter awareness, configuration schema completeness (all new fields), version bump to v1.0.0, overall backwards compat (v0.4.1 → v1.0.0 upgrade path). Both output findings as Critical/High/Medium/Low.
  - **Result:** Code Review: 0 Critical, 2 High, 5 Medium, 5 Low. Architecture Review: 0 Critical, 2 High, 5 Medium, 3 Low. Both confirmed full cross-phase integration is sound.

- [x] Stage 3 — Synthesize review findings: Read both outputs. Deduplicate. Create consolidated list. Write summary to review log.
  - **Result:** Consolidated to 0 Critical, 3 High, 8 Medium, 6 Low findings. Written to `Working/review-logs/phase-08-review-summary.md`.

- [x] Stage 4 — Fix code and architecture findings: Fix all Critical, High, and Medium findings autonomously (escalate if design-changing). Re-run ALL test suites (03-08) after fixes.
  - **Result:** Fixed all 3 High and 8 Medium findings. Also fixed L-1 (stop.sh ERR diagnostic), L-3 (session-start mentions /memory-reflect), L-4 (corrections lifecycle mentions /memory-reflect), L-6 (2 new tests added). Skipped L-2 (speculative JSON fallback) and L-5 (cosmetic test rename). All 75 tests pass across 6 phases: Phase 03 (10/10), Phase 04 (13/13), Phase 05 (11/11), Phase 06 (12/12), Phase 07 (14/14), Phase 08 (15/15).

- [x] Stage 5 — Simplicity review: Launch one sub-agent: `subagent_type: "compound-engineering:review:code-simplicity-reviewer"` — review post-fix `skills/memory-reflect/SKILL.md` for AAR workflow over-engineering, `hooks/stop.sh` for unnecessary complexity, and all config/schema additions for unnecessary abstraction.
  - **Result:** 7 "Should simplify", 3 "Worth discussing", 3 "Acceptable complexity". Key findings: S-1 (remove THOROUGH tier — duplicates /memory-insights), S-2 (collapse Research phase into Phase 3 note), S-3 (remove numbered config menu), S-4 (deduplicate retro template), S-5 (simplify approval protocol), S-6 (trim evidence template), S-7 (remove reflect_depth config if S-1 applied). Written to `Working/review-logs/phase-08-review-summary.md`.

- [x] Stage 6 — Fix simplicity findings + test: Fix all "should apply" findings autonomously. Re-run all tests. Write simplicity summary to review log.
  - **Result:** All 7 "Should simplify" findings (S-1 through S-7) applied. Key changes: removed THOROUGH tier (S-1), collapsed Research into Phase 3 note reducing workflow to 6 phases (S-2), replaced numbered config menu with natural language (S-3), deduplicated retro template in schema.md (S-4), simplified approval protocol (S-5), trimmed evidence template (S-6), removed `reflect_depth` config knob (S-7). ~70 lines removed, config knobs 12→11. All 75 tests pass across 6 phases.

- [ ] Stage 7 — Parallel security review (BLOCKED until Stage 6 complete and tests pass): Launch two sub-agents in parallel. CRITICAL: Do NOT start until Stage 6 is fully complete. Sub-Agent C: `subagent_type: "compound-engineering:review:security-sentinel"` (architecture focus) — perform **holistic** security review of the ENTIRE feature set (Phases 03-08 together): end-to-end data flow from user input through hooks to memory files to reflection output, privacy enforcement consistency across all code paths, trust model for all new inputs (hook JSON, user messages, config files, memory files), cross-phase security gaps. Sub-Agent D: `subagent_type: "compound-engineering:review:security-sentinel"` (technical focus) — review `hooks/stop.sh` for injection and compat, `/memory-reflect` skill for instruction injection (crafted memory file content causing unexpected LLM behavior?), `wc -l` and file existence checks for race conditions, **final pass across all hook scripts** (session-start.sh, user-prompt-submit.sh, pre-compact.sh, post-tool-use.sh, stop.sh) for any remaining command injection, path traversal, or symlink vulnerabilities. All findings must be addressed for v1.0.0.

- [ ] Stage 8 — Synthesize security findings: Read both outputs. Deduplicate. Create consolidated list. Write security summary to review log.

- [ ] Stage 9 — Fix security findings: Fix ALL Critical, High, and Medium findings autonomously (escalate if design-changing). Add security tests. This is v1.0.0 — no security findings left unaddressed.

- [ ] Stage 10 — Final verification: Run ALL test suites (phases 03-08). ALL must pass. Verify `hooks/hooks.json` is valid JSON with 5 hooks. Verify `session-start.sh` produces valid JSON. Verify `user-prompt-submit.sh` produces valid JSON. Verify `plugin.json` version is `"1.0.0"`. Verify README documents all new features. Write final status to review log. Commit final changes with message: `feat: v1.0.0 release — all 6 features complete with security review`
