---
description: Sync current session to memory files
---

## Memory root selection

Resolve memory once per workflow, independently for project and global scopes: use existing `.ai/memory`, otherwise existing `.claude/memory`, otherwise select `.ai/memory` for authorized initialization. If both exist, use `.ai`, warn, and leave legacy memory untouched. Do not migrate or merge automatically.

When shell access is available, set `MEMORY_ROOT` with `bash "<conkeeper-path>/tools/memory-root.sh"` and `GLOBAL_MEMORY_ROOT` with the same command plus `--global`, checking for errors before continuing. Otherwise apply the same fixed rules with file tools. Run from the project root; global paths are relative to the user's home. All paths below use the selected root, including config, queues, observations, decisions, sync markers and handoffs. Read-only operations must not create directories. Preserve private content and refuse writes through symlinked memory subdirectories/files.



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
