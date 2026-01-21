# ConKeeper: Session Handoff

Generate a complete handoff prompt for seamless continuation in a new session.

## Steps

1. **Sync Memory First**
   Run memory-sync workflow to ensure memory is current.

2. **Create Session Summary**
   File: `.claude/memory/sessions/[YYYY-MM-DD]-[topic].md`
   ```markdown
   # Session: [date]
   
   ## Summary
   [2-3 sentence summary of what was accomplished]
   
   ## Work Completed
   - [Item 1]
   - [Item 2]
   
   ## Decisions Made
   - [Decision] (ADR-NNN if applicable)
   
   ## Context for Next Session
   - [Important context point]
   
   ## Open Questions
   - [Unresolved question]
   
   ---
   *Session duration: ~[estimate]*
   ```

3. **Generate Handoff Prompt**
   Output this for user to copy into new session:

   ~~~
   I'm continuing work on [project-name] from a previous session.
   
   ## Original Goal
   [What the user originally requested]
   
   ## Session Summary
   [2-3 sentences of what was accomplished]
   
   ## Current State
   - **Active task:** [What we were working on]
   - **Files in progress:** [List files being modified]
   - **Last action:** [What was just done or about to be done]
   
   ## Completed This Session
   - [Item 1]
   - [Item 2]
   
   ## Remaining Work
   - [ ] [Next priority task]
   - [ ] [Following task]
   
   ## Key Decisions Made
   - [Decision] (see ADR-NNN if applicable)
   
   ## Open Questions/Blockers
   - [Any unresolved issues]
   
   ## Context to Load
   Project memory is at: .claude/memory/
   Key files to review: [list critical files]
   
   Please load the project memory and continue with [specific next task].
   ~~~

4. **Confirm handoff complete**
   > Session handoff generated. Copy the prompt above into a new session.
   > 
   > Files updated:
   > - active-context.md
   > - progress.md  
   > - sessions/[date]-[topic].md
