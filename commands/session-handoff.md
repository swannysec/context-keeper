---
description: Generate handoff prompt for continuing in a new session
---

Invoke the session-handoff skill to sync memory and generate a copy/paste prompt for seamless session continuation.

## Usage

```
/session-handoff
```

## What it does

1. Syncs current session state to memory (like /memory-sync)
2. Creates a session summary in `sessions/YYYY-MM-DD-HHMM.md`
3. Generates a formatted handoff prompt you can copy/paste into a new session

## When to use

- Context window approaching limits (slowdown, truncation)
- Before intentionally ending a long productive session
- Complex task needs to span multiple sessions
- You want to continue work later with full context

## Output

Produces a markdown code block containing:
- Original goal
- Session summary
- Current state (active task, files in progress)
- Completed work
- Remaining tasks
- Key decisions made
- Instructions for the next session
