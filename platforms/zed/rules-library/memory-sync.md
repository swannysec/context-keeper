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

3. **Propose Updates**
   Show user what will change:
   ```
   Memory Sync Summary:
   
   active-context.md:
     - Current focus: [old] → [new]
     - Added question: [question]
   
   progress.md:
     - Completed: [task]
     - Added: [new task]
   
   decisions/:
     - New ADR: [title]
   
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
