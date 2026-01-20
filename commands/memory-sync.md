---
description: Sync current session to memory files
---

Invoke the memory-sync skill to update memory files with the current session state.

## Usage

```
/memory-sync
```

## What it does

1. Reviews current memory files and conversation
2. Identifies decisions, completed tasks, context changes
3. Proposes updates to active-context.md, progress.md, and decisions/
4. Creates new ADR files if significant decisions were made
5. Applies updates after confirmation

## When to use

- After completing a significant task or feature
- When you've made architectural decisions worth recording
- Before ending a productive session
- Periodically during long sessions to checkpoint progress

## Files typically updated

- `active-context.md` - Current focus and recent decisions
- `progress.md` - Task completion status
- `decisions/ADR-NNN-*.md` - New architecture decision records
