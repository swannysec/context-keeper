---
description: Generate handoff prompt for continuing in a new session
---

## Memory root selection

Resolve memory once per workflow, independently for project and global scopes: use existing `.ai/memory`, otherwise existing `.claude/memory`, otherwise select `.ai/memory` for authorized initialization. If both exist, use `.ai`, warn, and leave legacy memory untouched. Do not migrate or merge automatically.

When shell access is available, set `MEMORY_ROOT` with `bash "<conkeeper-path>/tools/memory-root.sh"` and `GLOBAL_MEMORY_ROOT` with the same command plus `--global`, checking for errors before continuing. Otherwise apply the same fixed rules with file tools. Run from the project root; global paths are relative to the user's home. All paths below use the selected root, including config, queues, observations, decisions, sync markers and handoffs. Read-only operations must not create directories. Preserve private content and refuse writes through symlinked memory subdirectories/files.



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

For optional durable knowledge, follow the corresponding skill: inherit global `knowledge_workspace` unless the project overrides/disables it. Every proposed addition/change includes citation/provenance and a verbatim source excerpt in a quote/code block. Human review is still required during auto-sync; preserve pending items in the existing project session/handoff record when the store is unavailable.
