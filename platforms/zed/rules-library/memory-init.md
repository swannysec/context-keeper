# ConKeeper: Memory Init

## Memory root selection

Resolve memory once per workflow, independently for project and global scopes: use existing `.ai/memory`, otherwise existing `.claude/memory`, otherwise select `.ai/memory` for authorized initialization. If both exist, use `.ai`, warn, and leave legacy memory untouched. Do not migrate or merge automatically.

When shell access is available, set `MEMORY_ROOT` with `bash "<conkeeper-path>/tools/memory-root.sh"` and `GLOBAL_MEMORY_ROOT` with the same command plus `--global`, checking for errors before continuing. Otherwise apply the same fixed rules with file tools. Run from the project root; global paths are relative to the user's home. All paths below use the selected root, including config, queues, observations, decisions, sync markers and handoffs. Read-only operations must not create directories. Preserve private content and refuse writes through symlinked memory subdirectories/files.


Initialize the ConKeeper file-based memory system for this project.

## Steps

1. **Create Directory Structure**
   ```bash
   mkdir -p "$MEMORY_ROOT/decisions"
   mkdir -p "$MEMORY_ROOT/sessions"
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
   If no:
   ```bash
   memory_ignore="${MEMORY_ROOT#"$(pwd -P)/"}/"
   grep -qxF "$memory_ignore" .gitignore 2>/dev/null || echo "$memory_ignore" >> .gitignore
   ```

7. **Confirm completion**
   > Memory initialized. Use memory-sync to update as you work.
