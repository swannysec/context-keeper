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
