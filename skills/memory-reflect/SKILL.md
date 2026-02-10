---
name: memory-reflect
description: Session retrospection using After Action Review methodology. Analyzes corrections, observations, and session activity to produce improvement recommendations. Use at end of sessions or after /memory-sync.
---

# Memory Reflect — Session Retrospection

7-phase After Action Review (AAR) workflow for extracting actionable improvements from the current session.

## Phase 1: Gather Evidence

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
- Otherwise → map `reflect_depth` config to session depth:
  - `minimal` → always use LIGHTWEIGHT depth regardless of activity level
  - `standard` → use STANDARD depth
  - `thorough` → use THOROUGH depth

**Privacy:** Skip any content within <private>...</private> blocks.
Skip files with `private: true` in YAML front matter.
Facets data does not contain file contents — no privacy filtering needed for facets.

## Phase 2: Classify Scope

Recommend scope classification:
- PROCESS: Improvements to how the agent works (efficiency, tool usage, workflow)
- PROJECT: Improvements to the codebase, architecture, documentation, or tests
- BOTH: Improvements spanning both areas

Present recommendation to user:
"Scope recommendation: [PROCESS/PROJECT/BOTH] — [brief reason]"
User can adjust. Proceed with confirmed scope.

For LIGHTWEIGHT sessions: Auto-select PROCESS scope, skip user confirmation, and produce minimal output.

## Phase 3: Analyze Patterns

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
     For any friction type not listed above, map to the closest ConKeeper category
     based on the friction_detail narrative, defaulting to `efficiency` if unclear.
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

## Phase 4: Research (Conditional)

Only triggered when the agent needs external context to validate a recommendation.

Examples:
- User corrected AI to use a different testing pattern → research current best practices
- Friction around a specific tool → research known issues or alternatives

Never assume. Always back recommendations with evidence from the session or external sources.

Skip this phase for LIGHTWEIGHT sessions.

## Phase 5: Generate Recommendations

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

## Phase 6: Present for Approval

Display recommendations grouped by scope (PROCESS vs PROJECT):

## Recommendations

### Process Improvements
1. [Recommendation] — Evidence: [quote] — Target: [file]

### Project Improvements
1. [Recommendation] — Evidence: [quote] — Target: [file]

Present each recommendation with a number. User can respond with:
- "approve N" or "approve all" → route to target memory file with category tag
- "deny N" → note as "considered but declined" in retro file
- "edit N" → user provides modified text, then approve the modified version

Approved items routing:
- Code conventions → patterns.md (Code Conventions section)
- Architecture decisions → decisions/ADR-NNN-*.md (create new ADR)
- Terminology → glossary.md
- Workflow preferences → product-context.md or active-context.md
- Backlog items → retro file's Improvement Backlog section

## Phase 7: Write Retrospective

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
