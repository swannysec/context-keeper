---
name: memory-init
description: Initialize the ConKeeper memory system for the current project. Creates the directory structure and starter files for persistent AI context.
---

# Memory Initialization

## Memory root selection

Resolve memory once per workflow, independently for project and global scopes: use existing `.ai/memory`, otherwise existing `.claude/memory`, otherwise select `.ai/memory` for authorized initialization. If both exist, use `.ai`, warn, and leave legacy memory untouched. Do not migrate or merge automatically.

When shell access is available, set `MEMORY_ROOT` with `bash "<conkeeper-path>/tools/memory-root.sh"` and `GLOBAL_MEMORY_ROOT` with the same command plus `--global`, checking for errors before continuing. Otherwise apply the same fixed rules with file tools. Run from the project root; global paths are relative to the user's home. All paths below use the selected root, including config, queues, observations, decisions, sync markers and handoffs. Read-only operations must not create directories. Preserve private content and refuse writes through symlinked memory subdirectories/files.


Initialize ConKeeper's file-based memory system for this project.

## Pre-flight Checks

1. Confirm working directory is a project root (has package.json, Cargo.toml, pyproject.toml, go.mod, or similar)
2. Check if `$MEMORY_ROOT/` already exists
   - If yes: Ask user if they want to reset or review current memory
   - If no: Proceed with initialization

## Initialization Steps

### Step 1: Create Directory Structure

```bash
mkdir -p "$MEMORY_ROOT/decisions"
mkdir -p "$MEMORY_ROOT/sessions"
```

### Step 2: Gather Project Context

Ask user (or infer from codebase):
- What is this project? (1-2 sentences)
- What's the primary tech stack?
- Any key architectural decisions already made?
- What are you working on right now?

### Step 3: Create Initial Files

**product-context.md** - Populate with gathered info:
```markdown
# Product Context

## Project Overview
<!-- What is this project? What problem does it solve? -->

## Architecture
<!-- High-level architecture description -->

## Key Stakeholders
<!-- Who uses this? Who maintains it? -->

## Constraints
<!-- Technical, business, or regulatory constraints -->

## Non-Goals
<!-- What this project explicitly doesn't do -->

---
*Last updated: [date] by Copilot*
```

**active-context.md** - Set current focus:
```markdown
# Active Context

## Current Focus
<!-- What are we working on right now? -->

## Recent Decisions
<!-- Decisions made in recent sessions -->

## Open Questions
<!-- Unresolved questions that need answers -->

## Blockers
<!-- What's preventing progress? -->

---
*Session: [date]*
```

**progress.md** - Initialize with known tasks:
```markdown
# Progress Tracker

## In Progress
- [ ] [Initial task if known]

## Completed (Recent)
<!-- Recently completed items -->

## Backlog
<!-- Future tasks -->

---
*Last updated: [date]*
```

**patterns.md** - Document code patterns:
```markdown
# Project Patterns

## Code Conventions
<!-- Coding standards and conventions -->

## Architecture Patterns
<!-- Recurring architectural patterns -->

## Testing Patterns
<!-- Testing conventions -->

---
*Last updated: [date]*
```

**glossary.md** - Project terminology:
```markdown
# Project Glossary

## Terms
| Term | Definition |
|------|------------|
<!-- Add project-specific terminology -->

## Abbreviations
| Abbrev | Expansion |
|--------|-----------|
<!-- Add common abbreviations -->

---
*Last updated: [date]*
```

### Step 4: Configure Token Budget

Ask user:
> What token budget preset would you like?
> 1. **Economy** (~2000 tokens): Minimal context, fast loading
> 2. **Light** (~3000 tokens): Smaller projects, lighter footprint
> 3. **Standard** (~4000 tokens): Balanced for most projects (default)
> 4. **Detailed** (~6000 tokens): Comprehensive context, rich handoffs

Create `$MEMORY_ROOT/.memory-config.md` with their choice:
```yaml
---
token_budget: standard
---
```

If user accepts default (Standard), this file can be omitted.

### Step 5: Git Handling

Ask user:
> Should `$MEMORY_ROOT/` be tracked in git?
> - Yes: Memory persists with repo (recommended for solo projects)
> - No: Add to .gitignore (recommended for shared repos)

If no:
```bash
memory_ignore="${MEMORY_ROOT#"$(pwd -P)/"}/"
grep -qxF "$memory_ignore" .gitignore 2>/dev/null || echo "$memory_ignore" >> .gitignore
```

### Step 6: Confirm

Output summary:
> Memory initialized for [project-name]
> - Product context: [summary]
> - Current focus: [focus]
> - Token budget: [economy/light/standard/detailed]
> - Git tracking: [yes/no]
>
> Use memory-sync to update memory as you work.
