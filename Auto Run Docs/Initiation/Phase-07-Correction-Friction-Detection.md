# Phase 07: Correction & Friction Detection

**Agent Persona:** NLP/Pattern Detection Developer — Focus on regex precision, false positive minimization, sensitivity tuning.
**Version Bump:** v0.8.0 → v0.9.0
**Dependency:** Phase 03 (Categories) for category tags on routed corrections. Phase 04 (Privacy) for enforcement awareness. Phase 06 (Observations) produces data that complements corrections for Phase 08. All should be complete.
**Orchestration Reference:** See `Working/Agent-Orchestration-Plan.md` for review persona prompts and sub-agent dispatch instructions.

This phase extends `user-prompt-submit.sh` with regex patterns to detect user corrections ("no, use X instead") and friction signals ("that didn't work"). Detected items are queued in `corrections-queue.md` for processing during `/memory-sync`.

## Tasks

- [x] Extend `hooks/user-prompt-submit.sh` with correction and friction detection:
  - Add correction/friction detection **before** the existing token-checking logic (before the `# --- Parse transcript for token usage ---` section, around line 122)
  - **Extract user message from hook input:**
    - The UserPromptSubmit hook input JSON includes the user's prompt. Extract it:
      ```bash
      user_message=$(printf '%s' "$input" | jq -r '.user_message // empty')
      ```
    - If `user_message` is empty, skip detection (proceed to existing token logic)
  - **Read correction sensitivity from config:**
    - Reuse the existing config parsing logic (the `frontmatter` and `parse_yaml_int` code already in the script)
    - Add a new parser for string values:
      ```bash
      parse_yaml_str() {
          local key="$1"
          local default="$2"
          local val
          val=$(printf '%s' "$frontmatter" | awk -F': *' -v k="$key" '$1 == k { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2 }')
          if [[ -n "$val" ]]; then
              printf '%s' "$val"
          else
              printf '%s' "$default"
          fi
      }
      correction_sensitivity=$(parse_yaml_str "correction_sensitivity" "low")
      ```
  - **Define correction regex patterns (conservative/low sensitivity):**
    ```bash
    CORRECTION_PATTERNS=(
        'no[,. ]+\s*(use|do|try|it\s+should)'
        'actually[,. ]+\s*'
        "that'?s\s+(wrong|incorrect|not\s+right)"
        'I\s+(said|meant|asked\s+for)'
        "(not|don'?t)\s+\w+[,. ]+\s*(instead|use|do|try)"
    )
    ```
  - **Define friction regex patterns (conservative/low sensitivity):**
    ```bash
    FRICTION_PATTERNS=(
        "(didn'?t|doesn'?t|not)\s+work"
        '(try\s+again|redo|start\s+over)'
        'wrong\s+(approach|file|method|function|path|directory)'
        "(let'?s\s+revert|undo\s+that|go\s+back)"
        'still\s+(broken|failing|erroring|crashing)'
    )
    ```
  - **Medium sensitivity (add if `correction_sensitivity` is `medium`):**
    ```bash
    if [[ "$correction_sensitivity" == "medium" ]]; then
        CORRECTION_PATTERNS+=('instead' 'should\s+be' 'rather' 'prefer')
        FRICTION_PATTERNS+=('not\s+what' 'different\s+from')
    fi
    ```
  - **Note:** Only `low` and `medium` sensitivity levels are supported. The `high` level was dropped because Claude Code's facets data (`~/.claude/usage-data/facets/`) provides higher-accuracy retrospective friction classification via LLM analysis, making loose real-time regex patterns (e.g., "hmm", "wait") unnecessary. This hook provides fast first-pass detection; `/memory-reflect` consumes facets for the accurate second pass.
  - **Suppression — read `.correction-ignore` file:**
    ```bash
    IGNORE_FILE="${cwd:-.}/.correction-ignore"
    check_suppression() {
        local text="$1"
        if [[ -f "$IGNORE_FILE" ]]; then
            while IFS= read -r pattern || [[ -n "$pattern" ]]; do
                [[ "$pattern" =~ ^#.*$ ]] && continue  # skip comments
                [[ -z "$pattern" ]] && continue          # skip empty lines
                if [[ "${text,,}" == *"${pattern,,}"* ]]; then
                    return 0  # suppressed
                fi
            done < "$IGNORE_FILE"
        fi
        return 1  # not suppressed
    }
    ```
    - **Bash 3.2 note:** `${text,,}` (lowercase) is Bash 4+. Replace with: `text_lower=$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')` and `pattern_lower=$(printf '%s' "$pattern" | tr '[:upper:]' '[:lower:]')`
  - **Pattern matching loop:**
    ```bash
    detected_type=""
    for pattern in "${CORRECTION_PATTERNS[@]}"; do
        if [[ "$user_message" =~ $pattern ]]; then
            detected_type="correction"
            break
        fi
    done
    if [[ -z "$detected_type" ]]; then
        for pattern in "${FRICTION_PATTERNS[@]}"; do
            if [[ "$user_message" =~ $pattern ]]; then
                detected_type="friction"
                break
            fi
        done
    fi
    ```
  - **Queue entry (if detected and not suppressed):**
    ```bash
    if [[ -n "$detected_type" ]]; then
        if ! check_suppression "$user_message"; then
            queue_file="${cwd:-.}/.claude/memory/corrections-queue.md"
            if [[ -d "${cwd:-.}/.claude/memory" ]]; then
                # Create queue file with header if it doesn't exist
                if [[ ! -f "$queue_file" ]]; then
                    printf '# Corrections Queue\n<!-- Auto-populated by ConKeeper UserPromptSubmit hook -->\n\n' > "$queue_file"
                fi
                # Truncate user message to 200 chars for the queue entry
                truncated_msg=$(printf '%s' "$user_message" | head -c 200)
                timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                printf -- '- **%s** | %s | "%s" | ref: previous assistant message\n' \
                    "$timestamp" "$detected_type" "$truncated_msg" >> "$queue_file"
            fi
        fi
    fi
    ```
  - **Important:** This detection block runs BEFORE the existing token usage logic. It should NOT affect the hook's JSON output or exit code. The hook's existing behavior (context monitor) continues unchanged after detection.
  - **Performance:** Regex matching adds <50ms. Well within the 10-second timeout.

- [x] Update `/memory-sync` skill to process the corrections queue:
  - Edit `skills/memory-sync/SKILL.md`
  - Insert a new **Step 2.5: Process Corrections Queue** between Step 2 (Analyze Session) and Step 3 (Propose Updates):
    ```
    ### Step 2.5: Process Corrections Queue

    Check if `.claude/memory/corrections-queue.md` exists and has entries.

    If it has entries:
    1. Read the queue file
    2. For each queued item, suggest routing to the appropriate memory file:
       - Code conventions, naming, style → `patterns.md` (under Code Conventions)
       - Architecture choices, design decisions → `decisions/ADR-NNN-*.md` (create new ADR)
       - Terminology corrections → `glossary.md`
       - General preferences, project context → `product-context.md`
       - Workflow preferences → `active-context.md`
    3. Include the suggested routing in Step 3's proposed update output
    4. Add a category tag to each routed item (using Phase 03 categories):
       - Corrections about conventions → `<!-- @category: convention -->`
       - Corrections about decisions → `<!-- @category: decision -->`
       - Corrections about patterns → `<!-- @category: pattern -->`
       - Friction about bugs → `<!-- @category: bugfix -->`
       - Other → `<!-- @category: learning -->`
    5. User approves, modifies, or rejects each item
    6. Approved items are written to target files with category tags
    7. Rejected items are removed from queue
    8. After processing, clear the queue file (replace contents with just the header)
    9. If any corrections were processed, append to Step 5 output:
       "Corrections processed. Consider running /memory-reflect for deeper analysis."
    ```

- [x] Update `/memory-search` skill to enable searching the corrections queue:
  - Edit `skills/memory-search/SKILL.md`
  - Add a note in the skill body: "The corrections queue (`.claude/memory/corrections-queue.md`) is included in default project memory search scope."
  - No script changes needed — the queue file lives in `.claude/memory/` and is already in the default search path

- [x] Document the corrections queue format in `core/memory/schema.md`:
  - Add to the Directory Structure:
    ```
    .claude/memory/
    ├── ...existing files...
    └── corrections-queue.md  # Ephemeral correction/friction queue (auto-populated)
    ```
  - Add a new `### corrections-queue.md` section:
    ```
    **Purpose:** Ephemeral queue of user corrections and friction signals detected by the
    UserPromptSubmit hook. Processed during /memory-sync, then cleared.

    **Format:**
    - **YYYY-MM-DD HH:MM:SS** | correction | "user text" | ref: previous assistant message
    - **YYYY-MM-DD HH:MM:SS** | friction | "user text" | ref: previous assistant message

    **Lifecycle:** Auto-populated by hook → processed by /memory-sync → cleared after processing.
    Items are ephemeral and not meant for long-term storage.
    ```

- [x] Update `/memory-config` skill to document correction sensitivity:
  - Edit `skills/memory-config/SKILL.md`
  - Add:
    ```
    ## Correction Detection Settings

    | Setting | Default | Options | Description |
    |---------|---------|---------|-------------|
    | `correction_sensitivity` | `low` | `low`, `medium` | Regex sensitivity for detecting user corrections and friction |

    - `low`: Conservative patterns only (fewer false positives, higher precision)
    - `medium`: Adds looser patterns like "instead", "should be", "rather"

    Note: `high` sensitivity was intentionally omitted — Claude Code's facets data
    provides higher-accuracy retrospective friction classification. This hook is a
    fast first-pass; `/memory-reflect` uses facets for accurate second-pass analysis.

    Create `.correction-ignore` in project root to suppress specific patterns:
    ```
    # Patterns to never flag as corrections
    # One line per pattern, matched case-insensitively
    try again with.*verbose
    no worries
    ```
    ```

- [x] Update `.memory-config.md` schema in `core/memory/schema.md`:
  - Add the new field to the config example:
    ```yaml
    correction_sensitivity: low     # low | medium — regex sensitivity for real-time detection
    ```

- [x] Document the `.correction-ignore` file format:
  - Add to `core/memory/schema.md` a new section:
    ```
    ### .correction-ignore (Optional)

    **Location:** Project root (alongside `.claude/`)
    **Purpose:** Suppression patterns for correction detection. One pattern per line.
    Lines starting with `#` are comments. Empty lines are ignored.
    Patterns are matched case-insensitively against the full user prompt text.

    Example:
    ```
    # Patterns to never flag as corrections
    try again with.*verbose
    no worries
    that's fine
    ```
    ```

- [x] Write tests for correction and friction detection:
  - Create `tests/phase-07-corrections/test-corrections.sh`
  - **Setup:** Create temporary directory with `.claude/memory/` and a mock `.memory-config.md` with `correction_sensitivity: low`
  - **Test 1:** Feed UserPromptSubmit JSON with `user_message: "no, use snake_case for that"`. Verify a correction entry is appended to `corrections-queue.md`.
  - **Test 2:** Feed JSON with `user_message: "that didn't work, still failing"`. Verify a friction entry is appended.
  - **Test 3:** Feed JSON with `user_message: "looks good, thanks!"`. Verify NO entry is written (no match).
  - **Test 4:** Create `.correction-ignore` with pattern `no worries`. Feed JSON with `user_message: "no worries, try again"`. Verify `no worries` triggers suppression and no entry is written. Note: "try again" would normally match friction but the suppression check should prevent the entire message from being queued.
  - **Test 5:** Set `correction_sensitivity: medium` in config. Feed JSON with `user_message: "I'd prefer a different approach"`. Verify detection at medium (contains "prefer").
  - **Test 6:** Set `correction_sensitivity: low`. Same message. Verify NO detection at low sensitivity.
  - **Test 7:** Verify queue entry format includes timestamp, type, truncated text, and reference marker.
  - **Test 8:** Verify the existing token monitoring logic still works after the correction detection code is added (feed a normal prompt and verify the hook's JSON output is unchanged).
  - **Test 9:** Verify Bash 3.2 compatibility — no `${text,,}`, no associative arrays. Parse the script with `bash -n`.
  - **Test 10:** Verify queue file is created with header if it doesn't exist.
  - **Cleanup:** Remove temporary test directories
  - All tests runnable via `bash tests/phase-07-corrections/test-corrections.sh`

- [x] Bump version to v0.9.0 and verify all existing tests pass:
  - Edit `plugin.json`: change version to `"0.9.0"`
  - Run all previous phase tests (03 through 06)
  - Run Phase 07 tests
  - Verify `user-prompt-submit.sh` still produces valid JSON output for normal prompts
  - Verify the hook completes within the 10-second timeout
  - Commit all changes with message: `feat: add correction and friction detection to UserPromptSubmit hook (v0.9.0)`

## Review & Validation

Review stages use dedicated agent types. Agent fixes findings autonomously unless they would change design intent or functionality. All review summaries are written to `Auto Run Docs/Initiation/Working/review-logs/phase-07-review-summary.md`. See `Working/Agent-Orchestration-Plan.md` Section 3 for full review prompt templates.

- [x] Stage 1 — Run tests: Execute `bash tests/phase-07-corrections/test-corrections.sh` and all prior phase tests (03-06) for regression. All tests must pass. Fix any failures before proceeding.
  - ✅ Phase 07: 10/10 passed. Phase 06: 12/12 passed. Phase 05: 11/11 passed. Phase 04: 13/13 passed. Phase 03: 10/10 passed. **56 total, 0 failures.**

- [x] Stage 2 — Parallel code and architecture review: Launch two sub-agents in parallel. Sub-Agent A: `subagent_type: "workflow-toolkit:code-reviewer"` — review `user-prompt-submit.sh` modifications for correctness (regex patterns must match documented examples), Bash 3.2 compat (CRITICAL — `${text,,}` is Bash 4+, must use `tr`; `\s` and `\w` behavior in Bash regex), false positive analysis, error handling (detection must not break existing token monitoring), queue file format, config parsing for `correction_sensitivity`, `.correction-ignore` parsing robustness. Sub-Agent B: `subagent_type: "compound-engineering:review:architecture-strategist"` — review schema documentation of corrections-queue.md, config schema updates, `/memory-sync` Step 2.5 integration clarity, category tag routing correctness, cross-platform portability (hook is Claude Code only — are portable parts documented?), backward compat (existing hook behavior preserved). Both output findings as Critical/High/Medium/Low.
  - ✅ Code reviewer: 2 Critical, 3 High, 5 Medium, 3 Low. Architecture reviewer: 0 Critical, 3 High, 5 Medium, 4 Low.

- [x] Stage 3 — Synthesize review findings: Read both outputs. Deduplicate. Create consolidated list. Write summary to review log.
  - ✅ 18 unique findings (2 Critical, 5 High, 8 Medium). No duplicates between reviewers. Summary written to `review-logs/phase-07-review-summary.md`.

- [x] Stage 4 — Fix code and architecture findings: Fix all Critical, High, and Medium findings autonomously (escalate if design-changing). Re-run all test suites (03-07) after fixes. Especially verify the hook's JSON output is unchanged for normal prompts.
  - ✅ Fixed 11 findings (2 Critical, 5 High, 4 Medium). Accepted 4 as by-design. Deferred 1 (platform sync — out of scope). All 56 tests pass.

- [x] Stage 5 — Simplicity review: Launch one sub-agent: `subagent_type: "compound-engineering:review:code-simplicity-reviewer"` — review post-fix `user-prompt-submit.sh` correction detection code for over-engineering in the pattern arrays, sensitivity escalation, suppression logic, and queue entry formatting.
  - ✅ 2 actionable simplifications (S1: collapse sanitization pipeline, S2: pass pre-lowered text to check_suppression). 2 optional. Code assessed as "Low complexity, appropriately minimal".

- [x] Stage 6 — Fix simplicity findings + test: Fix all "should apply" findings autonomously. Re-run all tests. Write simplicity summary to review log.
  - ✅ Applied S1 (collapsed 3-subshell sanitization pipeline into 1) and S2 (pass pre-lowered text to check_suppression). All 56 tests pass.

- [x] Stage 7 — Parallel security review (BLOCKED until Stage 6 complete and tests pass): Launch two sub-agents in parallel. CRITICAL: Do NOT start until Stage 6 is fully complete. Sub-Agent C: `subagent_type: "compound-engineering:review:security-sentinel"` (architecture focus) — review trust model for user message content flowing into corrections-queue.md (untrusted — Markdown injection, HTML, control chars?), `.correction-ignore` as attacker-controlled input (crafted patterns causing ReDoS?), data flow from queue through `/memory-sync` to permanent memory files, side channel potential. Sub-Agent D: `subagent_type: "compound-engineering:review:security-sentinel"` (technical focus) — review for ReDoS in correction/friction patterns (`\s*` and `\w+` quantifiers in Bash regex), user message injection into queue file (quote/special char escaping in `printf`?), `.correction-ignore` pattern injection, path traversal via crafted `cwd`, `head -c` 200-char truncation safety (macOS vs Linux). ReDoS and injection findings are Critical by default.
  - ✅ Architecture: 0 Critical, 2 High, 5 Medium. Technical: 0 Critical, 1 High, 3 Medium. ReDoS confirmed safe (POSIX ERE, no backtracking). Glob injection in .correction-ignore confirmed safe (double-quoted).

- [x] Stage 8 — Synthesize security findings: Read both outputs. Deduplicate. Create consolidated list. Write security summary to review log.
  - ✅ 7 unique fixable findings (2 High, 5 Medium) after dedup. SH2/TH1 were the same cwd traversal finding. Written to review log.

- [x] Stage 9 — Fix security findings: Fix all Critical, High, and Medium findings autonomously (escalate if design-changing). Add security tests.
  - ✅ All 7 findings fixed. 4 security tests added (pipe escaping, HTML comment stripping, cwd traversal blocking, control char stripping). 60 total tests pass.

- [x] Stage 10 — Final verification: Run all test suites (phases 03-07). All must pass. Verify `user-prompt-submit.sh` produces valid JSON for normal prompts. Verify `plugin.json` version is `"0.9.0"`. Write final status to review log. Commit any remaining fixes.
  - ✅ All 60 tests pass (14+12+11+13+10). plugin.json v0.9.0 ✅. hooks.json valid ✅. JSON output verified ✅. Final status written to review log.
