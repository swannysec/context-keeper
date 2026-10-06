---
description: Initialize project memory system
---

## Memory root selection

Resolve memory once per workflow, independently for project and global scopes: use existing `.ai/memory`, otherwise existing `.claude/memory`, otherwise select `.ai/memory` for authorized initialization. If both exist, use `.ai`, warn, and leave legacy memory untouched. Do not migrate or merge automatically.

When shell access is available, set `MEMORY_ROOT` with `bash "<conkeeper-path>/tools/memory-root.sh"` and `GLOBAL_MEMORY_ROOT` with the same command plus `--global`, checking for errors before continuing. Otherwise apply the same fixed rules with file tools. Run from the project root; global paths are relative to the user's home. All paths below use the selected root, including config, queues, observations, decisions, sync markers and handoffs. Read-only operations must not create directories. Preserve private content and refuse writes through symlinked memory subdirectories/files.



Invoke the memory-init skill to set up the file-based memory system for this project.

## Usage

```
/memory-init
```

## What it does

1. Creates `$MEMORY_ROOT/` directory structure
2. Gathers project context (prompts for overview, tech stack, current focus)
3. Creates starter files: product-context.md, active-context.md, progress.md, patterns.md, glossary.md
4. Optionally adds `$MEMORY_ROOT/` to .gitignore

## When to use

- Starting organized work on a new project
- Setting up memory for an existing project that doesn't have it
- After cloning a repo that should have project-specific memory

## Prerequisites

- Must be in a project root directory (has package.json, Cargo.toml, pyproject.toml, or similar)
