# ConKeeper: Memory Sync

Synchronize current session state to memory files.

## Steps

1. **Read Current Memory**
   - Read `.claude/memory/active-context.md`
   - Read `.claude/memory/progress.md`
   - Check `.claude/memory/decisions/` for recent ADRs

2. **Analyze This Session**
   Review conversation for:
   - Decisions made (architectural, tooling, implementation)
   - Tasks completed or started
   - Context changes (new understanding, priorities)
   - Questions resolved or raised

2.5. **Auto-Categorize Entries**
   For each new entry identified in Step 2, assign a memory category tag:
   - Contains "decided", "chose", "selected", "went with" → `decision`
   - Contains "pattern", "convention", "always", "never", "standard" → `pattern`
   - Contains "fixed", "bug", "resolved", "workaround" → `bugfix`
   - Contains "convention", "naming", "format", "style" → `convention`
   - Contains "learned", "discovered", "TIL", "realized" → `learning`
   - If unsure, use context to pick the best fit

   Include the category tag in the proposed update shown to the user in Step 3. Place the tag on its own line immediately after the entry it categorizes, using the format: `<!-- @category: <value> -->`

3. **Propose Updates**
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

4. **Apply Updates (on confirmation)**
   - Update active-context.md with current state
   - Update progress.md with task changes
   - Create ADR files for significant decisions

5. **ADR Format** (when needed)
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

6. **Confirm completion**
   > Memory synced. [N] files updated.
