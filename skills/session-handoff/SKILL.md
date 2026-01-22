---
name: session-handoff
description: Capture current session state and generate a handoff prompt for seamless continuation in a new session. Use when context window is filling up, before ending a long session, or when explicitly requested.
---

# Session Handoff

Generate a complete handoff package that allows a new session to resume work seamlessly.

## When to Use

- Context window approaching limit (agent or user notices slowdown/truncation)
- Before intentionally ending a productive session
- User requests handoff explicitly
- Complex task needs to span multiple sessions

## Handoff Process

### Step 0: Check Token Budget

Read `.claude/memory/.memory-config.md` for token budget (if exists):
- `economy`: Session summary ~200-400 tokens (brief, 2-3 sentences)
- `light`: Session summary ~400-700 tokens (concise, 3-5 sentences)
- `standard`: Session summary ~600-1000 tokens (default, 5-8 sentences)
- `detailed`: Session summary ~900-1500 tokens (comprehensive, 8-12 sentences)

If no config exists, use `standard` budget.

### Step 1: Sync Memory First

Before generating handoff, ensure memory is current:
- Update active-context.md with current state
- Add any new decisions to decisions/
- Update progress.md with completed/in-progress items
- Create session summary in sessions/

**Session file format:** `sessions/YYYY-MM-DD-HHMM.md` or `sessions/YYYY-MM-DD-topic.md`

> **Note:** Include timestamp (HHMM) to avoid overwriting previous same-day sessions. The topic suffix is preferred when a clear topic exists.

```markdown
# Session: [date]

## Summary
Brief summary of what was accomplished.
- economy: 2-3 sentences
- light: 3-5 sentences
- standard: 5-8 sentences (default)
- detailed: 8-12 sentences with comprehensive context

## Work Completed
- [Item 1]
- [Item 2]

## Decisions Made
- ADR-NNN: [title] (if applicable)

## Context for Next Session
- [Key context point]

## Open Questions
- [Question if any]

---
*Session duration: ~[time]*
```

### Step 2: Gather Handoff Context

Collect from conversation and memory:
- **Original goal:** What the user asked for
- **Current task:** What we're actively working on
- **Progress:** What's been completed this session
- **Remaining work:** What still needs to be done
- **Key decisions:** Decisions made this session (reference ADRs if created)
- **Blockers/questions:** Unresolved issues
- **Critical files:** Files being actively modified
- **Recent errors:** Any errors we're debugging

### Step 3: Generate Handoff Prompt

Output a fenced code block the user can copy/paste:

~~~markdown
## Handoff Prompt (copy everything below this line)

```
I'm continuing work on [project-name] from a previous session.

## Original Goal
[What the user originally asked for]

## Session Summary
[2-3 sentence summary of what was accomplished]

## Current State
- **Active task:** [What we were working on when session ended]
- **Files in progress:** [List of files being modified]
- **Last action:** [What the agent just did or was about to do]

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

### Step 4: Confirm Handoff Complete

After outputting the prompt:
> Session handoff complete. Memory has been synced.
>
> Copy the prompt above and paste it into a new session to continue.
>
> Key files updated:
> - active-context.md (current state)
> - progress.md (task status)
> - sessions/[date].md (session summary)
