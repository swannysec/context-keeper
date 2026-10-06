---
name: memory-search
description: Search memory files for keywords, patterns, or categories
---

## Memory root selection

Resolve memory once per workflow, independently for project and global scopes: use existing `.ai/memory`, otherwise existing `.claude/memory`, otherwise select `.ai/memory` for authorized initialization. If both exist, use `.ai`, warn, and leave legacy memory untouched. Do not migrate or merge automatically.

When shell access is available, set `MEMORY_ROOT` with `bash "<conkeeper-path>/tools/memory-root.sh"` and `GLOBAL_MEMORY_ROOT` with the same command plus `--global`, checking for errors before continuing. Otherwise apply the same fixed rules with file tools. Run from the project root; global paths are relative to the user's home. All paths below use the selected root, including config, queues, observations, decisions, sync markers and handoffs. Read-only operations must not create directories. Preserve private content and refuse writes through symlinked memory subdirectories/files.



Search across memory files for keywords, patterns, or past decisions.

**Usage:**
```
/memory-search <query>
/memory-search --global <query>
/memory-search --sessions <query>
/memory-search --category <name> <query>
```

**Flags:**
- `--global` — Include global memory (`$GLOBAL_MEMORY_ROOT/`)
- `--sessions` — Include session files (last 30 days)
- `--category <name>` — Filter to entries with matching category tag

Results are grouped by file with line numbers and category tags.
