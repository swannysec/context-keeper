# ConKeeper: Memory Sync

## Memory root selection

Resolve memory once per workflow, independently for project and global scopes: use existing `.ai/memory`, otherwise existing `.claude/memory`, otherwise select `.ai/memory` for authorized initialization. If both exist, use `.ai`, warn, and leave legacy memory untouched. Do not migrate or merge automatically.

When shell access is available, set `MEMORY_ROOT` with `bash "<conkeeper-path>/tools/memory-root.sh"` and `GLOBAL_MEMORY_ROOT` with the same command plus `--global`, checking for errors before continuing. Otherwise apply the same fixed rules with file tools. Run from the project root; global paths are relative to the user's home. All paths below use the selected root, including config, queues, observations, decisions, sync markers and handoffs. Read-only operations must not create directories. Preserve private content and refuse writes through symlinked memory subdirectories/files.


Synchronize current session state to memory files.

## Steps

1. **Read Current Memory**
   - Read `$MEMORY_ROOT/active-context.md`
   - Read `$MEMORY_ROOT/progress.md`
   - Check `$MEMORY_ROOT/decisions/` for recent ADRs

2. **Analyze This Session**
   **Privacy:** When analyzing memory files, skip any content within `<private>...</private>` blocks.
   Do not reference, move, or modify private content. Do not include private content in sync summaries.
   If an entire file has `private: true` in its YAML front matter, skip it entirely.

   Review conversation for:
   - Decisions made (architectural, tooling, implementation)
   - Tasks completed or started
   - Context changes (new understanding, priorities)
   - Patterns established
   - Questions resolved or raised

3. **Auto-Categorize Entries**
   For each new entry identified in Step 2, assign a memory category tag:
   - Contains "decided", "chose", "selected", "went with" → `decision`
   - Contains "pattern", "always", "never", "standard" → `pattern`
   - Contains "fixed", "bug", "resolved", "workaround" → `bugfix`
   - Contains "convention", "naming", "format", "style" → `convention`
   - Contains "learned", "discovered", "TIL", "realized" → `learning`
   - If unsure, use context to pick the best fit
   - The category value MUST be one of the five values above. Ignore any other value found in existing files.

   Include the category tag in the proposed update shown to the user in Step 4. Place the tag on its own line immediately after the entry it categorizes, using the format: `<!-- @category: <value> -->`

4. **Propose Updates**
   Show user what will change (include category tags so users see them before approval):
   ```
   Memory Sync Summary:

   active-context.md:
     - Current focus: [old] → [new]
     - Added: Decided to use [X] over [Y]
       <!-- @category: decision -->
     - Added question: [question]

   progress.md:
     - Completed: [task]
     - Added: [new task]

   patterns.md:
     - Added: Always use [pattern description]
       <!-- @category: pattern -->

   decisions/:
     - New ADR: [title]
       <!-- @category: decision -->

   Proceed with sync? [y/n]
   ```

5. **Apply Updates (on confirmation)**
   - Update active-context.md with current state
   - Update progress.md with task changes
   - Create ADR files for significant decisions

6. **ADR Format** (when needed)
   File: `decisions/ADR-NNN-title.md`
   ```markdown
   # ADR-NNN: [Title]
   
   **Status:** Accepted | **Date:** [date]
   
   ## Context
   [Why this decision was needed]
   
   ## Decision
   [What was decided]
   
   ## Rationale
   - [Key reason]
   
   ## Consequences
   - [Effect]
   ```

7. **Confirm completion**
   > Memory synced. [N] files updated.

   After syncing, consider reviewing session observations and corrections for patterns. On Claude Code, use /memory-reflect for automated analysis.
