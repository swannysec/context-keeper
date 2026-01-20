---
description: Initialize project memory system
---

Invoke the memory-init skill to set up the file-based memory system for this project.

## Usage

```
/memory-init
```

## What it does

1. Creates `.claude/memory/` directory structure
2. Gathers project context (prompts for overview, tech stack, current focus)
3. Creates starter files: product-context.md, active-context.md, progress.md, patterns.md, glossary.md
4. Optionally adds `.claude/memory/` to .gitignore

## When to use

- Starting organized work on a new project
- Setting up memory for an existing project that doesn't have it
- After cloning a repo that should have project-specific memory

## Prerequisites

- Must be in a project root directory (has package.json, Cargo.toml, pyproject.toml, or similar)
