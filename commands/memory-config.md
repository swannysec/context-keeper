---
name: memory-config
description: View and modify ConKeeper memory configuration
---

## Memory root selection

Resolve memory once per workflow, independently for project and global scopes: use existing `.ai/memory`, otherwise existing `.claude/memory`, otherwise select `.ai/memory` for authorized initialization. If both exist, use `.ai`, warn, and leave legacy memory untouched. Do not migrate or merge automatically.

When shell access is available, set `MEMORY_ROOT` with `bash "<conkeeper-path>/tools/memory-root.sh"` and `GLOBAL_MEMORY_ROOT` with the same command plus `--global`, checking for errors before continuing. Otherwise apply the same fixed rules with file tools. Run from the project root; global paths are relative to the user's home. All paths below use the selected root, including config, queues, observations, decisions, sync markers and handoffs. Read-only operations must not create directories. Preserve private content and refuse writes through symlinked memory subdirectories/files.



View and modify memory settings for this project.

**Available settings:**
- **Token budget**: compact (~2000), standard (~3000), or detailed (~4000)
- **Suggest memories**: Whether to suggest memory additions
- **Auto load**: Auto-load memory at session start
- **Output style**: quiet, normal, or explanatory

Run this command to see current settings and make changes.

For optional durable knowledge, follow the corresponding skill: inherit global `knowledge_workspace` unless the project overrides/disables it. Every proposed addition/change includes citation/provenance and a verbatim source excerpt in a quote/code block. Human review is still required during auto-sync; preserve pending items in the existing project session/handoff record when the store is unavailable.
