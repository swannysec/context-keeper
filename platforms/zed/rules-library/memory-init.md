# ConKeeper: Memory Init

Initialize the ConKeeper file-based memory system for this project.

## Steps

1. **Create Directory Structure**
   ```bash
   mkdir -p .claude/memory/decisions
   mkdir -p .claude/memory/sessions
   ```

2. **Gather Project Context**
   Ask user:
   - What is this project? (1-2 sentences)
   - What's the primary tech stack?
   - What are you working on right now?

3. **Create product-context.md**
   ```markdown
   # Product Context
   
   ## Project Overview
   [Project description from user]
   
   ## Architecture
   [Tech stack and key components]
   
   ## Constraints
   [Any constraints mentioned]
   
   ---
   *Last updated: [today's date]*
   ```

4. **Create active-context.md**
   ```markdown
   # Active Context
   
   ## Current Focus
   [What user is working on]
   
   ## Open Questions
   [Any questions raised]
   
   ---
   *Session: [today's date]*
   ```

5. **Create progress.md**
   ```markdown
   # Progress Tracker
   
   ## In Progress
   - [ ] [Current task]
   
   ## Completed (Recent)
   
   ## Backlog
   
   ---
   *Last updated: [today's date]*
   ```

6. **Git Handling**
   Ask: "Should memory be tracked in git?"
   - If no: `grep -qxF '.claude/memory/' .gitignore 2>/dev/null || echo '.claude/memory/' >> .gitignore`

7. **Confirm completion**
   > Memory initialized. Use memory-sync to update as you work.
