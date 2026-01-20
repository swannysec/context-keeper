# ConKeeper (context-keeper) Implementation Plan

**Status:** Ready for implementation
**Date:** 2025-01-20
**Replaces:** Serena memories, ConPort MCP server
**Repo:** https://github.com/swannysec/context-keeper.git
**Dev path:** /Users/swanny/zed/context-keeper/

---

## Executive Summary

This plan describes a **ConPort-inspired, file-based memory system** that provides structured context management using plain Markdown files instead of a database. The system supports both global and project-specific memory with intelligent enforcement that works even when hooks are unavailable.

---

## 1. Architecture Overview

### 1.1 Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Files are sufficient** | All memory stored in `.md` files; no database |
| **Quiet by default** | Memory operations summarized to 1-2 lines unless verbose requested |
| **Graceful degradation** | Works without hooks via CLAUDE.md instructions |
| **User control** | Memory suggestions can be disabled per-project or globally |
| **Simple over complex** | Standard filesystem operations; no special tooling required |

### 1.2 Directory Structure

```
~/.claude/memory/                           # Global memory (cross-project preferences)
├── preferences.md                          # Tool preferences, style choices, workflow preferences
├── patterns.md                             # Reusable patterns you want applied everywhere
└── glossary.md                             # Personal terminology, abbreviations

<project>/.claude/memory/                   # Project memory (project-specific context)
├── product-context.md                      # Project goals, architecture, constraints, stakeholders
├── active-context.md                       # Current focus, immediate priorities, recent decisions
├── decisions/                              # Architectural Decision Records
│   ├── ADR-001-<title>.md
│   └── ADR-002-<title>.md
├── progress.md                             # Task tracking with checkbox format
├── patterns.md                             # Project-specific patterns and conventions
├── glossary.md                             # Project-specific terminology
├── sessions/                               # Session history
│   ├── 2025-01-19.md
│   └── 2025-01-20-feature-auth.md
└── .memory-config.md                       # Optional: per-project memory settings
```

### 1.3 Token-Efficient Markdown Conventions

All memory files follow these conventions to minimize token usage while preserving clarity:

| Convention | Example | Why |
|------------|---------|-----|
| **Bullet points over paragraphs** | `- Use PostgreSQL for DB` | 30-50% fewer tokens than prose |
| **Inline metadata** | `**Status:** Active \| **Date:** 2025-01-20` | Single line vs multiple |
| **Terse headers** | `## Rationale` not `## Rationale for This Decision` | Every word costs tokens |
| **No redundant boilerplate** | Skip "This document describes..." intros | Zero-value tokens |
| **Active voice, present tense** | "Uses JWT" not "It has been decided that we will use JWT" | Fewer words, same meaning |
| **Abbreviate when clear** | "DB" not "database", "auth" not "authentication" | Context makes it clear |

**File-specific limits:**

| File | Target Size | Rationale |
|------|-------------|-----------|
| `product-context.md` | ~500-1000 tokens | Loaded every session |
| `active-context.md` | ~300-500 tokens | Loaded every session, changes often |
| `progress.md` | ~200-500 tokens | Keep recent items, archive old |
| `decisions/*.md` | ~500 tokens each | All loaded; conciseness critical |
| `sessions/*.md` | ~300-500 tokens | Only recent loaded; older summarized |
| `preferences.md` | ~200-400 tokens | Loaded globally |

**Loading strategy:** All decisions and current context files are loaded by default. This ensures no critical context is missed. If total memory exceeds ~5000 tokens, older sessions are summarized rather than decisions being skipped.

### 1.4 Memory Precedence (Global + Project Coexistence)

**Resolution Strategy: Additive with Override**

```
┌─────────────────────────────────────────────────────────────┐
│  Effective Memory = Global Memory + Project Memory          │
│                                                             │
│  Where:                                                     │
│  - Global preferences APPLY unless project contradicts      │
│  - Project-specific items ADD to global                     │
│  - Explicit project overrides WIN over global               │
│                                                             │
│  Example:                                                   │
│  Global: "Prefer gh over GitHub MCP tools"                  │
│  Project: (no override) → gh preferred                      │
│  Project: "Use GitHub MCP for this project" → MCP used      │
└─────────────────────────────────────────────────────────────┘
```

**Implementation:**
- Global `preferences.md` loaded first (always)
- Project memory loaded second (when project detected)
- Explicit `## Overrides` section in project files takes precedence
- No merging of conflicting items—last loaded wins for same key

---

## 2. File Formats

### 2.1 preferences.md (Global)

```markdown
# Global Preferences

## Tool Preferences
- Prefer `gh` CLI over GitHub MCP tools for GitHub operations
- Use `rg` (ripgrep) over grep when available
- Prefer conventional commits format

## Workflow Preferences
- Always run tests before committing
- Create feature branches for non-trivial changes

## Style Preferences
- Concise responses unless detail requested
- No emojis unless explicitly requested

## Overrides
<!-- Project-level preferences.md can override items here by key -->
```

### 2.2 product-context.md (Project)

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
*Last updated: 2025-01-20 by Claude*
```

### 2.3 active-context.md (Project)

```markdown
# Active Context

## Current Focus
<!-- What are we working on right now? -->

## Recent Decisions
<!-- Decisions made in recent sessions that affect current work -->

## Open Questions
<!-- Unresolved questions that need answers -->

## Blockers
<!-- What's preventing progress? -->

---
*Session: 2025-01-20*
```

### 2.4 progress.md (Project)

```markdown
# Progress Tracker

## In Progress
- [ ] Implement user authentication (#123)
- [ ] Add rate limiting to API endpoints

## Completed (Recent)
- [x] Set up project structure (2025-01-19)
- [x] Configure CI/CD pipeline (2025-01-18)

## Backlog
- [ ] Add admin dashboard
- [ ] Implement export functionality

---
*Last updated: 2025-01-20*
```

### 2.5 decisions/ADR-NNN-title.md (Project)

**Convention: Max ~500 tokens per ADR.** All decisions are loaded by default, so conciseness matters.

```markdown
# ADR-001: Use PostgreSQL for Primary Database

**Status:** Accepted | **Date:** 2025-01-15 | **Tags:** database, infrastructure

## Context
We need a persistent data store for user data and application state.

## Decision
Use PostgreSQL 15+ as the primary database.

## Rationale
- ACID compliance for financial data
- JSON support for flexible schemas
- Team familiarity
- Excellent tooling ecosystem

## Consequences
- Need to manage database migrations
- Requires connection pooling for scale
- Adds operational complexity vs SQLite

## Alternatives Considered
- SQLite: Too limited for concurrent access
- MongoDB: Team lacks experience, ACID concerns
```

### 2.6 .memory-config.md (Project, Optional)

```markdown
---
suggest_memories: true          # Offer to save things to memory (default: true)
auto_load_on_init: true         # Load memory at session start (default: true)
include_global: true            # Include global preferences (default: true)
verbose_sync: false             # Show detailed sync output (default: false)
---

# Project Memory Configuration

Additional project-specific configuration notes can go here.
```

---

## 3. Enforcement Mechanisms

### 3.1 Multi-Layer Enforcement

The system uses **three layers** to ensure memory is used even when any single layer fails:

```
┌────────────────────────────────────────────────────────────────┐
│ Layer 1: SessionStart Hook                                     │
│ - Checks for memory directories                                │
│ - Injects memory-awareness context                             │
│ - Offers initialization if memory not found                    │
├────────────────────────────────────────────────────────────────┤
│ Layer 2: Global CLAUDE.md Instructions                         │
│ - Contains memory system instructions                          │
│ - Works even if hooks unavailable                              │
│ - Defines when memory should be engaged                        │
├────────────────────────────────────────────────────────────────┤
│ Layer 3: Memory Skills (invokable workflows)                   │
│ - /memory-init: Initialize memory for a project                │
│ - /memory-sync: Update memory with current session state       │
│ - Explicitly invokable when needed                             │
└────────────────────────────────────────────────────────────────┘
```

### 3.2 Task Complexity Detection

**Engage memory when:**
- Working in a directory with `.claude/memory/` present
- Task appears non-trivial (code changes, multi-step work, feature implementation)
- User explicitly requests it
- Previous session context would be helpful

**Skip memory for:**
- Quick questions ("what does X mean?")
- One-off terminal commands
- Web searches or research without implementation
- Explicit user request to skip

**Detection heuristic (for hook/CLAUDE.md):**
```
SHOULD_LOAD_MEMORY = (
    project_has_memory_dir() OR
    task_involves_code_changes() OR
    task_is_multi_step() OR
    user_explicitly_requested()
) AND NOT (
    task_is_simple_question() OR
    task_is_one_off_command() OR
    user_explicitly_skipped()
)
```

### 3.3 SessionStart Hook Implementation

**File:** `~/.claude/plugins/memory-system/hooks/hooks.json`

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

**File:** `~/.claude/plugins/memory-system/hooks/session-start.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Check for memory directories
GLOBAL_MEMORY="$HOME/.claude/memory"
PROJECT_MEMORY=".claude/memory"

has_global=false
has_project=false

[ -d "$GLOBAL_MEMORY" ] && has_global=true
[ -d "$PROJECT_MEMORY" ] && has_project=true

# Build context message
context=""

if [ "$has_global" = true ] || [ "$has_project" = true ]; then
    context="<memory-system-active>
Memory system detected.
- Global memory: $([ "$has_global" = true ] && echo "~/.claude/memory" || echo "not configured")
- Project memory: $([ "$has_project" = true ] && echo ".claude/memory" || echo "not configured")

For non-trivial tasks, load relevant memory before starting work:
- Read product-context.md and active-context.md for project context
- Check progress.md for task status
- Review decisions/ for architectural context

Update memory when:
- Making significant architectural decisions (add to decisions/)
- Completing or starting major tasks (update progress.md)
- Context changes significantly (update active-context.md)
- Session ends with important state to preserve

To initialize memory for a new project: /memory-init
To sync current session to memory: /memory-sync
</memory-system-active>"
else
    context="<memory-system-available>
No memory directories detected. For organized project work, initialize memory with /memory-init.
This provides structured context management across sessions.
</memory-system-available>"
fi

# Output JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$(echo "$context" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/  */ /g')"
  }
}
EOF
```

### 3.4 Global CLAUDE.md Instructions

**File:** `~/.claude/CLAUDE.md`

```markdown
# Global Instructions

## Memory System

This environment uses a file-based memory system for context persistence.

### Memory Locations
- **Global:** `~/.claude/memory/` - Cross-project preferences and patterns
- **Project:** `.claude/memory/` - Project-specific context

### When to Use Memory

**Load memory at session start when:**
- Project has `.claude/memory/` directory
- Task is non-trivial (feature work, debugging complex issues, multi-step tasks)
- You need context from previous sessions

**Skip memory for:**
- Quick questions or explanations
- One-off terminal commands
- Simple web searches
- User explicitly says "quick question" or similar

### Memory Operations

**Loading (quiet by default):**
When loading memory, summarize in 1-2 lines:
> Memory loaded: [project-name] - [current focus from active-context]

**Suggesting additions:**
When you notice something worth remembering (decisions, patterns, preferences):
> Would you like me to save this to memory? [brief description]

Only suggest if `suggest_memories` is not disabled in `.memory-config.md`.

**Syncing:**
User can trigger full sync with `/memory-sync`. Otherwise, update files incrementally as work progresses.

### Skills
- `/memory-init` - Initialize memory for current project
- `/memory-sync` - Sync current session state to memory files
```

---

## 4. Memory Skills

### 4.1 memory-init Skill

**File:** `~/.claude/skills/memory-init/SKILL.md`

```markdown
---
name: memory-init
description: Initialize the file-based memory system for the current project. Creates the directory structure and starter files. Use when starting organized work on a new project.
---

# Memory Initialization

## Pre-flight Checks

1. Confirm working directory is a project root (has package.json, Cargo.toml, pyproject.toml, go.mod, or similar)
2. Check if `.claude/memory/` already exists
   - If yes: Ask user if they want to reset or just review current memory
   - If no: Proceed with initialization

## Initialization Steps

### Step 1: Create Directory Structure

```bash
mkdir -p .claude/memory/decisions
```

### Step 2: Gather Project Context

Ask user (or infer from codebase):
- What is this project? (1-2 sentences)
- What's the primary tech stack?
- Any key architectural decisions already made?
- What are you working on right now?

### Step 3: Create Initial Files

**product-context.md** - Populate with gathered info
**active-context.md** - Set current focus
**progress.md** - Empty or with known tasks
**patterns.md** - Any detected patterns
**glossary.md** - Any project-specific terms

### Step 4: Git Handling

Ask user:
> Should `.claude/memory/` be tracked in git?
> - Yes: Memory persists with repo (recommended for solo projects)
> - No: Add to .gitignore (recommended for shared repos)

### Step 5: Confirm

Output summary:
> Memory initialized for [project-name]
> - Product context: [summary]
> - Current focus: [focus]
> - Git tracking: [yes/no]
>
> Use `/memory-sync` to update memory as you work.
```

### 4.2 memory-sync Skill

**File:** `~/.claude/skills/memory-sync/SKILL.md`

```markdown
---
name: memory-sync
description: Synchronize current session state to memory files. Reviews conversation, updates relevant files, and confirms changes. Use at end of sessions or when significant progress has been made.
---

# Memory Sync

## Sync Process

### Step 1: Review Current State

Read current memory files:
- active-context.md
- progress.md
- Recent entries in decisions/

### Step 2: Analyze Session

Review conversation for:
- Decisions made (architectural, implementation, tooling)
- Tasks completed or started
- Context changes (new understanding, shifted priorities)
- Patterns established
- Questions resolved or raised

### Step 3: Propose Updates

Present changes to user:
```
Memory Sync Summary:

active-context.md:
  - Current focus: [old] → [new]
  - Added open question: [question]

progress.md:
  - Marked complete: [task]
  - Added: [new task]

decisions/:
  - New: ADR-003-[title] (reason: [brief])

Proceed with sync? [y/n]
```

### Step 4: Apply Updates

On confirmation:
- Update files using Edit tool
- Create new ADR files if needed
- Update timestamps

### Step 5: Confirm

> Memory synced. [N] files updated.
```

### 4.3 session-handoff Skill

**File:** `~/.claude/plugins/context-keeper/skills/session-handoff/SKILL.md`

```markdown
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

### Step 1: Sync Memory First

Before generating handoff, ensure memory is current:
- Update active-context.md with current state
- Add any new decisions to decisions/
- Update progress.md with completed/in-progress items
- Create session summary in sessions/

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
```

### 4.4 Command Shortcuts

**File:** `~/.claude/plugins/context-keeper/commands/memory-init.md`

```markdown
---
description: Initialize project memory system
---

Invoke the memory-init skill to set up the file-based memory system for this project.
```

**File:** `~/.claude/plugins/context-keeper/commands/memory-sync.md`

```markdown
---
description: Sync current session to memory files
---

Invoke the memory-sync skill to update memory files with the current session state.
```

**File:** `~/.claude/plugins/context-keeper/commands/session-handoff.md`

```markdown
---
description: Generate handoff prompt for continuing in a new session
---

Invoke the session-handoff skill to sync memory and generate a copy/paste prompt for seamless session continuation.
```

### 4.4 Session Summary Format

**File:** `<project>/.claude/memory/sessions/2025-01-20.md`

```markdown
# Session: 2025-01-20

## Summary
Brief 2-3 sentence summary of what was accomplished.

## Work Completed
- Implemented user authentication flow
- Added JWT token validation
- Fixed bug in session refresh logic

## Decisions Made
- ADR-003: Use Redis for session storage (see decisions/ADR-003-redis-sessions.md)

## Context for Next Session
- Authentication is working but needs rate limiting
- User requested OAuth integration as next priority
- Test coverage is at 78%, targeting 85%

## Open Questions
- Should we support multiple auth providers simultaneously?

---
*Session duration: ~2 hours*
```

### 4.5 Global Memory Management

**For global preferences, use direct file operations:**

When user expresses a preference that should apply everywhere:
1. Read `~/.claude/memory/preferences.md`
2. Add new preference under appropriate section
3. Confirm: "Added to global preferences: [preference]"

---

## 5. Implementation Phases

### Phase 1: Core Infrastructure (Do First)
- [ ] Create plugin directory structure at `/Users/swanny/zed/context-keeper/`
- [ ] Initialize git repo and connect to remote
- [ ] Create plugin.json manifest
- [ ] Implement SessionStart hook
- [ ] Create memory-init skill + command
- [ ] Create memory-sync skill + command
- [ ] Create session-handoff skill + command
- [ ] Symlink plugin to `~/.claude/plugins/context-keeper`
- [ ] Create global CLAUDE.md with memory instructions
- [ ] Create global memory directory with starter files

### Phase 2: Testing & Refinement
- [ ] Test with new project initialization
- [ ] Test with existing project (no memory → add memory)
- [ ] Test hook failure graceful degradation
- [ ] Test global + project memory coexistence
- [ ] Refine detection heuristics based on usage

### Phase 3: Polish
- [ ] Add memory-status command (show current memory state)
- [ ] Add memory-suggest toggle command
- [ ] Documentation and examples
- [ ] Consider memory search/query capability (grep-based)

---

## 6. File Locations Summary

| Component | Location |
|-----------|----------|
| Plugin root | `~/.claude/plugins/context-keeper/` (symlink to dev repo) |
| Dev repo | `/Users/swanny/zed/context-keeper/` |
| Plugin manifest | `context-keeper/plugin.json` |
| Hook config | `context-keeper/hooks/hooks.json` |
| Hook script | `context-keeper/hooks/session-start.sh` |
| memory-init skill | `context-keeper/skills/memory-init/SKILL.md` |
| memory-sync skill | `context-keeper/skills/memory-sync/SKILL.md` |
| session-handoff skill | `context-keeper/skills/session-handoff/SKILL.md` |
| memory-init command | `context-keeper/commands/memory-init.md` |
| memory-sync command | `context-keeper/commands/memory-sync.md` |
| session-handoff command | `context-keeper/commands/session-handoff.md` |
| Global CLAUDE.md | `~/.claude/CLAUDE.md` |
| Global memory | `~/.claude/memory/` |
| Project memory | `<project>/.claude/memory/` |

---

## 7. Design Decisions (Resolved)

1. **Plugin packaging:** Standalone local plugin at `~/.claude/plugins/memory-system/`
   - Start local, consider repo for iteration later

2. **Skill invocation:** Skills as primary + command shortcuts
   - Skills enable agent proactivity and sub-agent access
   - Commands (`/memory-init`, `/memory-sync`) provide explicit user control
   - Commands simply invoke the underlying skills

3. **ADR numbering:** Auto-increment within each project
   - Scan `decisions/` for highest ADR-NNN, increment from there
   - Format: `ADR-001-title.md`, `ADR-002-title.md`, etc.

4. **Session history:** Include `sessions/` directory
   - Store session summaries with date-based naming
   - Format: `sessions/2025-01-20.md` or `sessions/2025-01-20-topic.md`
   - Complements active-context.md (current state vs historical record)

5. **Sub-agent access:** Full read/write access
   - Sub-agents can record their work independently
   - Enables parallel agents to coordinate via shared memory files

---

## 8. Comparison: Before vs After

| Aspect | ConPort | This System |
|--------|---------|-------------|
| Storage | SQLite database | Markdown files |
| Initialization | MCP server startup | Directory creation |
| Reliability | MCP server can fail | Native filesystem |
| Debugging | Query database | `cat file.md` |
| Version control | Separate exports | Native git |
| Semantic search | Database queries | grep/ripgrep |
| Structure | Schema-enforced | Convention-enforced |
| Token efficiency | Same (no vector DB) | Same |
| Portability | Requires ConPort | Works anywhere |

---

*Plan ready for review. Approve to proceed with Phase 1 implementation.*
