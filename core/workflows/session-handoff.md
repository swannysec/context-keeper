# Session Handoff Workflow

**Purpose:** Generate a complete handoff package for seamless continuation in a new session.

## When to Use

- Context window approaching limit (slowdown, truncation)
- Before intentionally ending a productive session
- User explicitly requests handoff
- Complex task needs to span multiple sessions

## Workflow Steps

### 1. Sync Memory First

Before generating handoff, ensure memory is current:
- Update `active-context.md` with current state
- Add any new decisions to `decisions/`
- Update `progress.md` with completed/in-progress items
- Create session summary in `sessions/`

### 2. Create Session Summary

Create file: `sessions/YYYY-MM-DD-topic.md` or `sessions/YYYY-MM-DD-HHMM.md`

```markdown
# Session: YYYY-MM-DD

## Summary
Brief 2-3 sentence summary of what was accomplished.

## Work Completed
- Item 1
- Item 2

## Decisions Made
- ADR-NNN: Title (if applicable)
- Informal decision

## Context for Next Session
- Key context point
- Important detail

## Open Questions
- Unresolved question

---
*Session duration: ~Xh*
```

### 3. Gather Handoff Context

Collect from conversation and memory:
- **Original goal:** What the user initially asked for
- **Current task:** What was actively being worked on
- **Progress:** What was completed this session
- **Remaining work:** What still needs to be done
- **Key decisions:** Decisions made (reference ADRs if created)
- **Blockers/questions:** Unresolved issues
- **Critical files:** Files being actively modified
- **Recent errors:** Any errors being debugged

### 4. Generate Handoff Prompt

Output a fenced code block the user can copy:

~~~markdown
## Handoff Prompt (copy everything below this line)

```
I'm continuing work on [project-name] from a previous session.

## Original Goal
[What the user originally asked for]

## Session Summary
[2-3 sentence summary of what was accomplished]

## Current State
- **Active task:** [What was being worked on when session ended]
- **Files in progress:** [List of files being modified]
- **Last action:** [What agent just did or was about to do]

## Completed This Session
- [Item 1]
- [Item 2]

## Remaining Work
- [ ] [Task 1 - next priority]
- [ ] [Task 2]
- [ ] [Task 3]

## Key Decisions Made
- [Decision 1] (see ADR-NNN if applicable)
- [Decision 2]

## Open Questions/Blockers
- [Question or blocker if any]

## Context to Load
Project memory is at: .claude/memory/
Key files to review: [list critical files]

Please load the project memory and continue with [specific next task].
```
~~~

### 5. Confirm Handoff Complete

```
Session handoff complete. Memory has been synced.

Copy the prompt above and paste it into a new session to continue.

Key files updated:
- active-context.md (current state)
- progress.md (task status)
- sessions/YYYY-MM-DD-topic.md (session summary)
```

## Handoff Quality Checklist

A good handoff should:
- [ ] Clearly state what was being worked on
- [ ] List completed work
- [ ] Prioritize remaining tasks
- [ ] Reference any ADRs created
- [ ] Note blockers or open questions
- [ ] Specify which files are actively being modified
- [ ] Include enough context that a fresh session can continue

## Error Handling

- **Memory not initialized:** Create minimal handoff from conversation only
- **Cannot write session file:** Include session summary in handoff prompt itself
- **Long conversation:** Focus on recent context, reference memory for history

## Platform-Specific Notes

> **Note:** Shell command examples use Unix/bash syntax for illustration. Adapt for your platform's shell or use your AI assistant's file manipulation capabilities.

- **Claude Code:** Available as `/session-handoff` command or skill
- **GitHub Copilot:** Available as contextual skill via custom instructions
- **Cursor:** Available as skill or via AGENTS.md guidance
- **Windsurf:** Available via `.windsurfrules` configuration
- **Cline/Roo Code:** Available via custom instructions or MCP configuration
- **Other platforms:** Follow manual workflow via AGENTS.md awareness
