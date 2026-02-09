---
type: reference
title: ConKeeper Implementation Plan — 6 Features
created: 2026-02-09
tags:
  - implementation-plan
  - architecture
  - roadmap
related:
  - "[[Feature-Design-Decisions]]"
  - "[[Feature-Matrix]]"
---

# ConKeeper Implementation Plan

Detailed implementation plan for 6 selected features. Each feature maps to one execution Phase (Phase 03–08). Features are ordered by dependency: foundational capabilities first, features that build on them later.

---

## Phase 03: Memory Observation Categories

**Priority:** Foundation — category tags are consumed by search (Phase 05), sync (Phase 07), and reflect (Phase 08).

### What It Does

Adds inline category tags to memory file entries using HTML comment syntax: `<!-- @category: decision -->`. Tags are invisible in rendered Markdown but trivially parseable by grep/ripgrep. Two distinct category sets:

- **Memory categories** (for memory file entries): `decision`, `pattern`, `bugfix`, `convention`, `learning`
- **Retrospective categories** (for `/memory-reflect` output): `efficiency`, `quality`, `ux`, `knowledge`, `architecture`

Freeform tags also supported: `<!-- @tag: some-tag -->`.

### Where It Lives

| File | Action | Purpose |
|------|--------|---------|
| `core/memory/schema.md` | Modify | Add Category Tags section documenting format, allowed values, placement rules |
| `core/memory/templates/active-context.md` | Modify | Add example category tags in comments |
| `core/memory/templates/patterns.md` | Modify | Add example category tags |
| `core/memory/templates/session-template.md` | Modify | Add example retrospective category tags |
| `core/memory/templates/adr-template.md` | Modify | Add `<!-- @category: decision -->` to template |
| `skills/memory-sync/SKILL.md` | Modify | Add Step 2.5: Auto-categorize entries during sync |
| `skills/memory-init/SKILL.md` | Modify | Add opt-in retroactive tagging choice |
| `skills/memory-config/SKILL.md` | Modify | No new config — categories are always enabled |
| Platform adapter skills (`platforms/*/`) | Modify | Update memory-sync workflows with categorization step |

### How It Works

1. **Tag format:** `<!-- @category: <value> -->` placed on its own line immediately after a heading or bullet that it categorizes. One tag per entry. Multiple tags allowed on separate lines.
2. **Auto-categorization in `/memory-sync`:** During Step 2 (Analyze Session), the agent assigns a category to each new entry it writes. Uses keyword matching against entry content:
   - Contains "decided", "chose", "selected" → `decision`
   - Contains "pattern", "convention", "always" → `pattern`
   - Contains "fixed", "bug", "resolved" → `bugfix`
   - Contains "learned", "discovered", "TIL" → `learning`
   - Fallback: agent uses context to pick, or asks user when confidence is low
3. **Retroactive tagging (opt-in):** During `/memory-init`, ask: "Tag existing memory entries with categories? [y/n]". If yes, agent reads each memory file, classifies entries, and adds tags.
4. **No new dependencies.** Pure Markdown convention — no tools, no libraries.

### Dependencies

None. This is the first feature in the chain.

### Platform Impact

All platforms benefit. Category tags are standard Markdown comments — parseable everywhere. Platform adapter memory-sync workflows should be updated to include the categorization step.

### Token Budget Impact

Minimal. Each `<!-- @category: value -->` tag is ~5 tokens. A typical memory file might gain 10-20 tags = ~50-100 tokens total. Within all budget presets.

### Risk Assessment

- **Low risk.** Additive-only change. Existing memory files continue to work without tags.
- **Backward compatible.** Tags are HTML comments — invisible to any tool that doesn't explicitly parse them.
- **Migration path:** Retroactive tagging is opt-in and user-approved.

### Test Expectations

- Verify category tags survive Markdown rendering (invisible in rendered output)
- Verify `rg '@category: decision'` finds tagged entries
- Verify `grep '@category: decision'` finds tagged entries (no ripgrep fallback)
- Verify `/memory-sync` adds categories to new entries
- Verify `/memory-init` retroactive tagging works when accepted
- Verify no category tags are added when retroactive tagging is declined

---

## Phase 04: Privacy Tags

**Priority:** Must be in place before any new read/write paths (search, observations, reflect) to ensure enforcement from day one.

### What It Does

Adds `<private>...</private>` block wrappers for sensitive content in memory files. Content inside privacy tags is excluded from context injection, search results, sync analysis, and reflection. Also supports file-level privacy via `private: true` in YAML front matter.

### Where It Lives

| File | Action | Purpose |
|------|--------|---------|
| `core/memory/schema.md` | Modify | Add Privacy Tags section documenting format and enforcement rules |
| `core/memory/templates/*.md` | Modify | Add example `<private>` usage in comments |
| `hooks/session-start.sh` | Modify | Strip `<private>...</private>` blocks before injecting context |
| `skills/memory-sync/SKILL.md` | Modify | Skip `<private>` content during analysis; never move private content |
| `skills/memory-config/SKILL.md` | Modify | Document privacy tag feature (no config toggle — always enforced) |
| `.memory-config.md` schema | Modify | Add `private: true` front matter documentation |
| Platform adapter workflows | Modify | Add privacy tag awareness to sync workflows |

### How It Works

1. **Block-level tags:** `<private>` and `</private>` on their own lines. Content between them is excluded. Tags are visible to humans editing the file (intentional — privacy should be obvious).
2. **File-level privacy:** `private: true` in YAML front matter marks the entire file as private.
3. **Enforcement in `session-start.sh`:**
   - After reading memory files for context injection, strip content between `<private>` and `</private>` tags using sed/awk before encoding into JSON.
   - For files with `private: true` front matter, skip the entire file.
   - Implementation: `sed '/<private>/,/<\/private>/d'` applied to each memory file's content before injection.
4. **Enforcement in `/memory-sync`:**
   - Skill instructions state: "When analyzing memory files, skip any content within `<private>...</private>` blocks. Do not reference, move, or modify private content."
5. **Default private content:** Only obviously sensitive patterns auto-tagged. No auto-detection regex in v1 — users manually wrap sensitive content. Future: optional regex for API keys, credentials.

### Dependencies

None. Can be implemented independently, but should ship before Features 1, 2, 3, 6 to ensure all new paths respect privacy.

### Platform Impact

- **Claude Code:** session-start.sh hook modification is platform-specific
- **Other platforms:** Privacy tags are respected at the Markdown level. Platform workflows should include "skip `<private>` content" instructions. No hook equivalent on other platforms, but the workflow guidance covers the sync/search paths.

### Token Budget Impact

Zero net impact. Privacy tags exclude content that would otherwise be injected — they reduce token usage, not increase it.

### Risk Assessment

- **Low risk.** Additive-only. Existing files without privacy tags are unaffected.
- **sed compatibility:** Use POSIX `sed` patterns compatible with Bash 3.2 (macOS). Test with `sed '/<private>/,/<\/private>/d'` on both GNU and BSD sed.
- **Edge case:** Nested `<private>` tags. Policy: nesting not supported. Outer tag wins. Document this.
- **Edge case:** `<private>` tag inside a code fence. Policy: only match tags at the start of a line (no indentation prefix beyond whitespace). Code fences typically indent content.

### Test Expectations

- Verify `<private>` content is stripped from session-start.sh output
- Verify `private: true` front matter causes entire file to be skipped
- Verify `/memory-sync` instructions explicitly mention skipping private content
- Verify privacy stripping works with BSD sed (macOS) and GNU sed (Linux)
- Verify `<private>` tags inside code fences are NOT stripped (only line-start matches)
- Verify no existing functionality breaks with privacy tags absent (empty/no tags = no change)

---

## Phase 05: File-Based Memory Search (`/memory-search`)

**Priority:** Foundational tool used by correction detection, retrospection, and general agent workflow.

### What It Does

Adds a `/memory-search <query>` skill that performs keyword search across memory files. Returns agent-optimized structured results grouped by file, with context and category tags. Backed by a standalone shell script callable from any platform.

### Where It Lives

| File | Action | Purpose |
|------|--------|---------|
| `skills/memory-search/SKILL.md` | Create | Skill definition — invocation, options, output format |
| `tools/memory-search.sh` | Create | Standalone cross-platform search script |
| `hooks/session-start.sh` | Modify | Inject search reminder into context |
| `core/snippet.md` | Modify | Add `/memory-search` to available workflows |
| `core/memory/schema.md` | Modify | Reference search capability |
| `platforms/*/` | Modify | Add search script reference to platform adapters |

### How It Works

1. **Shell script (`tools/memory-search.sh`):**
   - Accepts: `<query>` (required), `--global` (include `~/.claude/memory/`), `--sessions` (include `sessions/`), `--category <name>` (filter by category tag)
   - Auto-detects `rg` (ripgrep) at runtime. Falls back to `grep -rn` if unavailable.
   - Searches `.claude/memory/` by default (project memory).
   - **Privacy enforcement:** Excludes matches within `<private>...</private>` blocks. Implementation: post-filter results — if a match's file+line falls within a private block range, omit it. For simplicity in v1, use a two-pass approach: first find private block ranges per file, then filter matches.
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

2. **Skill (`skills/memory-search/SKILL.md`):**
   - Parses user query from skill invocation
   - Calls `tools/memory-search.sh` via Bash
   - Presents results to user/agent
   - Supports flags: `/memory-search --global --category decision "token budget"`

3. **Session-start reminder:**
   - Add to context injection: "Search memory with `/memory-search <query>` before re-investigating known problems."

### Dependencies

- **Feature 4 (Categories):** Category filtering depends on categories existing in files. Script handles "no matches" gracefully.
- **Feature 5 (Privacy):** Privacy block exclusion must be implemented in the search script.

### Platform Impact

- **Claude Code:** Native skill + shell script
- **All platforms:** Shell script is directly callable. Platform adapters reference `tools/memory-search.sh` in their workflow docs. Copilot/Cursor/Codex can invoke via their shell execution capabilities.

### Token Budget Impact

- Script itself: 0 tokens (not injected into context)
- Search reminder in session-start: ~15 tokens
- Search results: Variable, but typically 100-500 tokens per query. Results are ephemeral (not persisted).

### Risk Assessment

- **Low risk.** Read-only operation. Cannot corrupt memory files.
- **grep compatibility:** Must work with BSD grep (macOS) and GNU grep. Use only POSIX-compatible flags.
- **Large sessions directory:** `--sessions` flag could be slow with many session files. Mitigate: limit to last 30 days by default, configurable.
- **Privacy filter complexity:** Two-pass filtering adds complexity. Keep v1 simple — if the private block detection proves too complex in pure bash, fall back to a simpler heuristic (skip entire files that contain `<private>` tags when `rg` isn't available).

### Test Expectations

- Verify search finds matches in project memory files
- Verify `--global` flag includes global memory
- Verify `--sessions` flag includes session files
- Verify `--category` filters results to matching category tags
- Verify `<private>` block content is excluded from results
- Verify `private: true` files are excluded from results
- Verify ripgrep auto-detection works (use `rg` when available, `grep` otherwise)
- Verify script works on macOS (Bash 3.2, BSD grep) and Linux (Bash 4+, GNU grep)
- Verify empty query or no matches returns clean "no results" output
- Verify output format is structured and agent-parseable

---

## Phase 06: PostToolUse Observation Hook

**Priority:** Produces the observation data consumed by correction detection and retrospection.

### What It Does

Adds a `PostToolUse` hook that logs tool usage to a per-session observations file. Two-tier logging: full entries for Bash/external tools, stub entries for native Read/Write/Edit tools. Creates a real-time activity log that the agent and `/memory-reflect` can analyze.

### Where It Lives

| File | Action | Purpose |
|------|--------|---------|
| `hooks/post-tool-use.sh` | Create | PostToolUse hook script |
| `hooks/hooks.json` | Modify | Register PostToolUse hook |
| `hooks/session-start.sh` | Modify | Create empty observations file at session start |
| `skills/memory-config/SKILL.md` | Modify | Add observation_hook config option |
| `core/memory/schema.md` | Modify | Document observations file format and location |

### How It Works

1. **Hook registration (`hooks.json`):**
   ```json
   "PostToolUse": [
     {
       "hooks": [
         {
           "type": "command",
           "command": "${CLAUDE_PLUGIN_ROOT}/hooks/post-tool-use.sh",
           "timeout": 5
         }
       ]
     }
   ]
   ```

2. **Hook script (`hooks/post-tool-use.sh`):**
   - Reads JSON input from stdin (tool_name, tool_input, tool_output, session_id, cwd)
   - Validates session_id (same sanitization as existing hooks)
   - Determines observation file path: `.claude/memory/sessions/YYYY-MM-DD-observations.md`
   - Creates file with header if it doesn't exist
   - **Full entries** (Bash, WebFetch, WebSearch, and any non-built-in tool):
     ```markdown
     - **HH:MM:SS** | `Bash` | execute | `/path/to/file` | `npm test` | success
     ```
   - **Stub entries** (Read, Write, Edit, Glob, Grep):
     ```markdown
     - **HH:MM:SS** | `Read` | read | `/path/to/file` | — | success
     ```
   - Extracts action type from tool name: Read→read, Write/Edit→write, Bash→execute, Glob/Grep→read
   - Extracts file path from tool_input (first path-like argument)
   - Extracts success/failure from exit code or tool_output error indicators
   - For Bash: extracts command summary (first 80 chars of command)
   - For failures: extracts error message (first 120 chars)

3. **Session-start.sh modification:**
   - At session start, create the observations file with a header:
     ```markdown
     # Session Observations — YYYY-MM-DD
     <!-- Auto-generated by ConKeeper PostToolUse hook -->
     ```
   - Only create if project memory exists (`.claude/memory/` directory present)

4. **Configuration:**
   - `observation_hook: true | false` in `.memory-config.md` (default: true)
   - Hook script checks config file at startup; exits immediately if disabled
   - `observation_detail: full | stubs_only | off` — controls stub vs full entries (default: full for Bash, stubs for native tools as described above)

### Dependencies

- **Feature 4 (Categories):** None directly, but observation entries could include retrospective categories later.
- **Feature 5 (Privacy):** Observations never include file content — only paths, tool names, and status. No privacy tag concern for the observation file itself, but the observation file should not be injected into session-start context (it grows rapidly).

### Platform Impact

- **Claude Code only.** PostToolUse hook is a Claude Code-specific feature. Other platforms do not have equivalent hook points.
- **Other platforms:** Not affected. Observation data benefits retrospection (Phase 08) which is skill-based and works everywhere.

### Token Budget Impact

- Observation file grows ~10-20 tokens per tool use. A typical session with 100 tool uses ≈ 1000-2000 tokens.
- Observation file is NOT auto-injected into context at session start (too large, too noisy).
- Only consumed on-demand by `/memory-reflect` and `/memory-search --sessions`.

### Risk Assessment

- **Low risk.** Append-only to a session-specific file. Cannot corrupt existing memory.
- **Performance:** 5-second timeout ensures hook cannot block the agent. Script should complete in <100ms (just a file append).
- **Bash 3.2 compatibility:** Avoid `mapfile`, associative arrays, `$EPOCHSECONDS`. Use `date +%H:%M:%S` for timestamps.
- **Disk space:** Observation files grow unbounded during a session. Mitigate: observations are per-session, old sessions can be archived/deleted. Add note to schema about cleanup.
- **Concurrency:** Multiple PostToolUse events could fire near-simultaneously. Append operations are atomic at the OS level for small writes, but add a brief note about this in the script comments.

### Test Expectations

- Verify hook script parses PostToolUse JSON input correctly
- Verify full entries are written for Bash tool uses
- Verify stub entries are written for Read/Write/Edit tool uses
- Verify session-start.sh creates the observations file header
- Verify observations are NOT injected into session-start context
- Verify hook exits cleanly when observation_hook is disabled
- Verify Bash 3.2 compatibility (no Bash 4+ features)
- Verify hook completes within 5-second timeout
- Verify file path extraction from tool_input JSON
- Verify error/failure entries include truncated error message

---

## Phase 07: Correction & Friction Detection

**Priority:** Builds the corrections queue and shared analysis core used by retrospection.

### What It Does

Extends `user-prompt-submit.sh` with regex patterns to detect user corrections ("no, use X instead") and friction signals ("that didn't work"). Detected items are queued in `corrections-queue.md` for processing during `/memory-sync`, which then triggers `/memory-reflect` for analysis.

### Where It Lives

| File | Action | Purpose |
|------|--------|---------|
| `hooks/user-prompt-submit.sh` | Modify | Add correction/friction regex detection before token checking |
| `skills/memory-sync/SKILL.md` | Modify | Add Step 2.5: Process corrections queue; trigger reflect |
| `skills/memory-search/SKILL.md` | Modify | Enable searching corrections queue |
| `core/memory/schema.md` | Modify | Document corrections-queue.md format |
| `skills/memory-config/SKILL.md` | Modify | Add correction_sensitivity setting |
| `.correction-ignore` (user-created) | Document | Suppression patterns file format |

### How It Works

1. **Correction detection in `user-prompt-submit.sh`:**
   - After parsing input JSON, extract `user_message` (the prompt text)
   - Apply regex patterns against user_message to detect corrections and friction:

   **Correction patterns (conservative/low sensitivity):**
   ```bash
   # "no, use X" / "no, do X" / "no, it should be"
   no[,.]?\s+(use|do|try|it\s+should)
   # "actually, X" / "actually it's"
   actually[,.]?\s+
   # "that's wrong" / "that's incorrect" / "that's not right"
   that'?s\s+(wrong|incorrect|not\s+right)
   # "I said X" / "I meant X" / "I asked for X"
   I\s+(said|meant|asked\s+for)
   # "not X, Y" / "don't X, Y"
   (not|don'?t)\s+\w+[,.]?\s+(instead|use|do|try)
   ```

   **Friction patterns (conservative/low sensitivity):**
   ```bash
   # "that didn't work" / "that doesn't work" / "still not working"
   (didn'?t|doesn'?t|not)\s+work
   # "try again" / "redo" / "start over"
   (try\s+again|redo|start\s+over)
   # "wrong approach" / "wrong file" / "wrong method"
   wrong\s+(approach|file|method|function|path|directory)
   # "let's revert" / "undo that" / "go back"
   (let'?s\s+revert|undo\s+that|go\s+back)
   # "still broken" / "still failing"
   still\s+(broken|failing|erroring|crashing)
   ```

   - **Sensitivity levels** (read from `.memory-config.md`):
     - `low` (default): Only the patterns above (high-precision, fewer false positives)
     - `medium`: Add looser patterns: "instead", "should be", "rather", "prefer"
     - `high`: Add even looser: "hmm", "wait", "oops", single-word negations

   - **Suppression:** Read `.correction-ignore` file (one pattern per line). Skip any match whose text matches a suppression pattern.

2. **Queue format (`corrections-queue.md`):**
   ```markdown
   # Corrections Queue
   <!-- Auto-populated by ConKeeper UserPromptSubmit hook -->

   - **2026-02-09 14:32:15** | correction | "no, use snake_case for method names" | ref: previous assistant message
   - **2026-02-09 14:35:02** | friction | "that didn't work, the test is still failing" | ref: previous assistant message
   ```

   - Queue file lives at `.claude/memory/corrections-queue.md`
   - Each entry: timestamp, type (correction|friction), raw user text (first 200 chars), reference marker

3. **Processing in `/memory-sync`:**
   - New Step 2.5 after "Analyze Session":
     - Check if `corrections-queue.md` exists and has entries
     - Present queued items to user with suggested routing:
       - Code conventions → `patterns.md`
       - Architecture choices → `decisions/ADR-NNN-*.md`
       - Terminology → `glossary.md`
       - General preferences → `product-context.md`
     - User approves, modifies, or rejects each item
     - Approved items are written to target files (with category tags from Feature 4)
     - Processed items are removed from the queue
   - After sync completes, if corrections were processed, suggest running `/memory-reflect`

4. **`.correction-ignore` file format:**
   ```
   # Patterns to never flag as corrections
   # One pattern per line, matched case-insensitively against user prompt text
   try again with.*verbose
   no worries
   ```

### Dependencies

- **Feature 4 (Categories):** Routed corrections get category tags (e.g., `<!-- @category: convention -->`)
- **Feature 5 (Privacy):** Corrections queue is NOT private by default (needs to flow through reflection pipeline)
- **Feature 6 (Observations):** Not directly dependent, but observations + corrections together give Feature 8 (Retrospection) full data

### Platform Impact

- **Claude Code:** Hook modification is platform-specific. Corrections queue file is platform-portable.
- **Other platforms:** Cannot auto-detect corrections (no hook). Users can manually flag corrections, or correction detection could be added to platform-specific rule files as a prompt instruction.

### Token Budget Impact

- Regex detection adds ~1-2ms to each UserPromptSubmit hook execution (negligible)
- `corrections-queue.md`: Typically 5-20 entries between syncs. ~200-800 tokens.
- Queue is ephemeral — cleared after processing. No permanent token growth.

### Risk Assessment

- **Medium risk.** Regex false positives could annoy users. Mitigated by:
  - Conservative default sensitivity (`low`)
  - All items require user approval before routing
  - `.correction-ignore` suppression file
  - Processing is visible and transparent
- **Hook latency:** Regex matching must complete within the existing 10-second timeout. Pure bash regex is fast (<50ms even with many patterns).
- **Bash 3.2 compatibility:** Use `[[ $text =~ pattern ]]` (supported in Bash 3.2). Avoid `\b` word boundaries (not supported in Bash regex — use `\s` or explicit alternatives).
- **User message extraction:** The `user_message` field in PostToolUse JSON may need to be extracted differently from the UserPromptSubmit input. Verify the exact JSON schema.

### Test Expectations

- Verify correction patterns match expected phrases
- Verify friction patterns match expected phrases
- Verify false positives are minimized at `low` sensitivity
- Verify `.correction-ignore` suppression works
- Verify queue entries have correct format (timestamp, type, text, ref)
- Verify `/memory-sync` presents queue items for approval
- Verify approved items route to correct target files with category tags
- Verify rejected items are removed from queue
- Verify queue file is cleaned after processing
- Verify sensitivity setting is read from `.memory-config.md`
- Verify Bash 3.2 regex compatibility

---

## Phase 08: Session Retrospection (`/memory-reflect`)

**Priority:** Capstone feature — builds on all previous features.

### What It Does

A new `/memory-reflect` skill that combines session-retrospective AAR (After Action Review) methodology with correction detection analysis. Produces a retrospective report with an improvement log and backlog. Runs as a sub-agent to avoid blocking active work.

### Where It Lives

| File | Action | Purpose |
|------|--------|---------|
| `skills/memory-reflect/SKILL.md` | Create | Full skill definition — 7-phase AAR workflow |
| `hooks/hooks.json` | Modify | Add Stop hook to auto-trigger reflect |
| `hooks/stop.sh` | Create | Stop hook that triggers reflect suggestion |
| `core/memory/schema.md` | Modify | Document retro file format and location |
| `skills/memory-sync/SKILL.md` | Modify | Add auto-trigger of reflect after sync |
| `skills/memory-config/SKILL.md` | Modify | Add reflect config options |

### How It Works

1. **Skill definition (`skills/memory-reflect/SKILL.md`):**

   **7-Phase AAR Workflow:**

   - **Phase 1: Gather Evidence**
     - Read `corrections-queue.md` (unprocessed items)
     - Read current session's `observations.md`
     - Read current session summary (if sync has run)
     - Read `active-context.md` for current state
     - Estimate session depth: count observations + corrections + session length

   - **Phase 2: Classify Scope**
     - Agent recommends PROCESS, PROJECT, or BOTH:
       - PROCESS: Improvements to how the agent works (efficiency, quality)
       - PROJECT: Improvements to the codebase, architecture, or documentation
       - BOTH: Improvements spanning both areas
     - Present recommendation to user. User can adjust.

   - **Phase 3: Analyze Patterns**
     - Group corrections by type (repeated patterns get priority)
     - Analyze observation log for friction (repeated failures, many retries on same file)
     - Cross-reference with existing `patterns.md` and `decisions/` to avoid re-discovering known patterns
     - Use `/memory-search` to check if similar issues were flagged in past sessions

   - **Phase 4: Research (Conditional)**
     - Only triggered when agent needs external context to validate a recommendation
     - Example: "User corrected AI to use a different testing pattern" → agent researches current best practices for that pattern
     - Never assumes — always backs recommendations with evidence

   - **Phase 5: Generate Recommendations**
     - Each recommendation includes:
       - **What:** Specific, actionable change
       - **Why:** Evidence from session (quote corrections/observations)
       - **Where:** Target file or skill to update
       - **Impact:** Expected improvement
       - **Category:** Retrospective category tag (`<!-- @category: efficiency -->` etc.)

   - **Phase 6: Present for Approval**
     - Display recommendations grouped by scope (PROCESS vs PROJECT)
     - User approves, denies, or iterates on each
     - Approved items are:
       - Routed to appropriate memory files (corrections → patterns/decisions/etc.)
       - Added to improvement log in retro file
     - Denied items are noted in retro file as "considered but declined"

   - **Phase 7: Write Retrospective**
     - Create `sessions/YYYY-MM-DD-retro.md`:
       ```markdown
       # Session Retrospective — YYYY-MM-DD

       ## Session Summary
       [Brief summary of what happened]

       ## Improvement Log
       ### Approved
       - [Recommendation 1] → routed to patterns.md
       <!-- @category: quality -->
       - [Recommendation 2] → routed to decisions/ADR-NNN.md
       <!-- @category: architecture -->

       ### Declined
       - [Recommendation 3] — reason: user declined

       ## Improvement Backlog
       - [ ] [Future improvement idea 1]
       - [ ] [Future improvement idea 2]

       ## Evidence
       - Corrections: [N] detected, [M] processed
       - Observations: [N] tool uses, [M] failures
       - Friction signals: [list]

       ---
       *Generated by /memory-reflect*
       ```

2. **Trigger model:**
   - **Auto after `/memory-sync`:** Sync skill suggests running reflect if corrections were found
   - **Auto at session end (Stop hook):** `stop.sh` outputs a suggestion: "Consider running `/memory-reflect` before ending."
   - **Manual:** User invokes `/memory-reflect` at any time
   - **Depth proportional to content:** If session has <5 observations and 0 corrections, produce a minimal "nothing notable" retro. Full AAR for substantial sessions.

3. **Stop hook (`hooks/stop.sh`):**
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   # Suggest reflect at session end
   echo "[ConKeeper] Session ending. Consider running /memory-reflect to capture learnings." >&2
   exit 0
   ```

4. **Shared analysis core with Feature 7:**
   - Both `/memory-sync` (correction processing) and `/memory-reflect` read the same data sources:
     - `corrections-queue.md`
     - Session observations
     - Session summaries
   - They share categorization logic (same category sets)
   - They share deduplication logic (check existing patterns/decisions before adding)
   - They differ in output: sync routes to memory files, reflect produces the retro report
   - **Implementation:** Shared logic is encoded in the skill instructions (not a separate library). Both skill files reference the same classification criteria and dedup rules.

5. **Configuration:**
   - `auto_reflect: true | false` — auto-trigger after sync (default: true)
   - `reflect_depth: minimal | standard | thorough` — controls AAR depth (default: standard)
   - Added to `.memory-config.md` schema

### Dependencies

- **Feature 4 (Categories):** Uses retrospective categories for improvement log entries
- **Feature 5 (Privacy):** Skips private content during evidence gathering
- **Feature 6 (Observations):** Reads observation log for friction analysis
- **Feature 7 (Corrections):** Reads corrections queue for learning analysis
- **Feature 5 (`/memory-search`):** Uses search to cross-reference past sessions

### Platform Impact

- **Claude Code:** Full experience — hook-triggered, skill-based analysis, sub-agent execution
- **Other platforms:** Skill-based workflow works everywhere. No auto-triggering (no hooks), but manual invocation works. Observation data won't exist on non-Claude-Code platforms, so reflect adapts to available data (session summaries + corrections only).

### Token Budget Impact

- Retro file: 300-800 tokens per session (varies by depth)
- Files are session-specific, not accumulated. Old retros don't grow token budget.
- Stop hook message: ~15 tokens (stderr only, not context injection)

### Risk Assessment

- **Medium risk.** AAR quality depends on skill instruction clarity. Mitigated by:
  - Proportional depth (small sessions get minimal retros)
  - Human approval gate for all recommendations
  - Conservative defaults
- **Sub-agent execution:** Designed to run as a sub-agent, but Claude Code doesn't natively support spawning sub-agents from hooks. The "sub-agent" concept is implemented as the skill running in the agent's current turn — the key is that reflect is invoked after sync completes, not during active coding work.
- **Stop hook availability:** The Stop hook is a newer Claude Code feature. If unavailable, the fallback is manual invocation and sync-triggered suggestion.
- **Large observation files:** Thorough retros on long sessions could hit token limits when reading the observations file. Mitigate: read only the last 200 entries, or summarize by category.

### Test Expectations

- Verify `/memory-reflect` reads corrections queue
- Verify `/memory-reflect` reads observation log
- Verify scope classification works (PROCESS/PROJECT/BOTH)
- Verify recommendations include evidence citations
- Verify approved recommendations route to correct memory files
- Verify retro file is created with correct format
- Verify improvement backlog items are actionable
- Verify minimal retro produced for short/quiet sessions
- Verify `/memory-search` cross-reference works during analysis
- Verify privacy tags are respected during evidence gathering
- Verify Stop hook outputs suggestion message

---

## Cross-Cutting Concerns

### Bash 3.2 Compatibility

All hook scripts MUST work on macOS system Bash (3.2). Avoid:
- `$EPOCHSECONDS` → use `$(date +%s)`
- `mapfile` / `readarray` → use `while read` loops
- Associative arrays (`declare -A`) → use separate variables or files
- `\b` in regex → use `\s` or explicit character classes
- `${var,,}` lowercase → use `tr '[:upper:]' '[:lower:]'`

### JSON Encoding

Reuse the `json_encode()` function pattern from existing hooks (jq when available, pure-bash fallback).

### Error Handling

All hooks use:
- `set -euo pipefail`
- `trap 'echo "script-name failed at line $LINENO" >&2' ERR`
- Fail-open: `exit 0` on any error (never block the agent)

### Configuration Schema Updates

`.memory-config.md` gains these new fields:

```yaml
---
# Existing fields...
token_budget: standard
suggest_memories: true
auto_load: true
output_style: normal
auto_sync_threshold: 60
hard_block_threshold: 80
context_window_tokens: 200000

# New fields (Phase 04+)
observation_hook: true          # Enable/disable PostToolUse observation logging
observation_detail: full        # full | stubs_only | off — level of detail in observations
correction_sensitivity: low     # low | medium | high — regex sensitivity for correction detection
auto_reflect: true              # Auto-trigger /memory-reflect after /memory-sync
reflect_depth: standard         # minimal | standard | thorough — AAR depth level
---
```

### File Creation Summary

| Phase | New Files | Modified Files |
|-------|-----------|----------------|
| 03 (Categories) | 0 | 9+ (schema, templates, skills, platform adapters) |
| 04 (Privacy) | 0 | 7+ (schema, templates, hooks, skills) |
| 05 (Search) | 2 (`skills/memory-search/SKILL.md`, `tools/memory-search.sh`) | 4+ (session-start, snippet, schema, platforms) |
| 06 (Observations) | 1 (`hooks/post-tool-use.sh`) + per-session files | 4 (hooks.json, session-start, config, schema) |
| 07 (Corrections) | 0 + per-project `corrections-queue.md` | 5 (user-prompt-submit, memory-sync, search, config, schema) |
| 08 (Retrospection) | 2 (`skills/memory-reflect/SKILL.md`, `hooks/stop.sh`) + per-session files | 4 (hooks.json, memory-sync, config, schema) |

### Version Bump Plan

Each phase bumps a minor version:
- Phase 03: → v0.5.0 (Categories)
- Phase 04: → v0.6.0 (Privacy)
- Phase 05: → v0.7.0 (Search)
- Phase 06: → v0.8.0 (Observations)
- Phase 07: → v0.9.0 (Corrections)
- Phase 08: → v1.0.0 (Retrospection — completes the v1 feature set)

---

*Generated 2026-02-09. Source: [[Feature-Design-Decisions]], [[Feature-Matrix]], ConKeeper architecture review.*
