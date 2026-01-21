# ConKeeper Memory Schema

**Version:** 1.0.0
**Last Updated:** 2025-01-21

This document defines the standard format for ConKeeper memory files. Implementations across all platforms should follow this schema to ensure interoperability.

## Directory Structure

```
.claude/memory/          # or .ai/memory/ (future standard)
├── active-context.md    # Current session focus and state
├── product-context.md   # Project overview and architecture
├── progress.md          # Task tracking
├── patterns.md          # Code and architecture patterns
├── glossary.md          # Project-specific terminology
├── decisions/           # Architecture Decision Records
│   ├── ADR-001-*.md
│   └── ADR-NNN-*.md
└── sessions/            # Session summaries
    ├── YYYY-MM-DD-HHMM.md
    └── YYYY-MM-DD-topic.md
```

## Global Memory (Optional)

Global memory at `~/.claude/memory/` stores cross-project preferences. This is outside the scope of this schema but may include:
- `preferences.md` - Tool and workflow preferences
- `patterns.md` - Reusable patterns across projects
- `glossary.md` - Personal terminology

Global memory is platform-specific (Claude Code) and not portable.

## Memory Path Resolution

Implementations should check for memory in this order:
1. `.claude/memory/` (current standard)
2. `.ai/memory/` (future cross-platform standard)

## File Formats

### active-context.md

**Purpose:** Captures the current working state and focus. Updated frequently during sessions.

```markdown
# Active Context

## Current Focus
<!-- What are we working on right now? Single sentence or short paragraph. -->

## Recent Decisions
<!-- Decisions made in recent sessions that affect current work. Reference ADRs if applicable. -->

## Open Questions
<!-- Unresolved questions that need answers before proceeding. -->

## Blockers
<!-- What's preventing progress? Technical, organizational, or knowledge blockers. -->

---
*Session: YYYY-MM-DD*
```

### product-context.md

**Purpose:** Stable project overview. Updated infrequently as project understanding evolves.

```markdown
# Product Context

## Project Overview
<!-- What is this project? What problem does it solve? 2-3 sentences. -->

## Architecture
<!-- High-level architecture description. Tech stack, major components. -->

## Key Stakeholders
<!-- Who uses this? Who maintains it? -->

## Constraints
<!-- Technical, business, or regulatory constraints. -->

## Non-Goals
<!-- What this project explicitly doesn't do. Important for scope clarity. -->

---
*Last updated: YYYY-MM-DD by [author]*
```

### progress.md

**Purpose:** Task tracking across sessions. Provides continuity for ongoing work.

```markdown
# Progress Tracker

## In Progress
- [ ] Task description with context
- [ ] Another task

## Completed (Recent)
- [x] Completed task with date
- [x] Another completed task

## Backlog
- Future task
- Another future task

---
*Last updated: YYYY-MM-DD*
```

### patterns.md

**Purpose:** Documents recurring patterns discovered in the codebase.

```markdown
# Project Patterns

## Code Conventions
<!-- Coding standards: naming, formatting, style preferences -->

## Architecture Patterns
<!-- Recurring architectural patterns: error handling, data flow, etc. -->

## Testing Patterns
<!-- Testing conventions: frameworks, coverage expectations, fixtures -->

---
*Last updated: YYYY-MM-DD*
```

### glossary.md

**Purpose:** Project-specific terminology for consistent communication.

```markdown
# Project Glossary

## Terms
| Term | Definition |
|------|------------|
| Term | What it means in this project |

## Abbreviations
| Abbrev | Expansion |
|--------|-----------|
| ABC | Always Be Coding |

---
*Last updated: YYYY-MM-DD*
```

### decisions/ADR-NNN-title.md

**Purpose:** Architecture Decision Records for important decisions.

**Naming:** `ADR-NNN-kebab-case-title.md` where NNN is zero-padded sequence number.

**Numbering:** Scan existing ADRs, increment from highest number found.

**Concurrency:** If multiple sessions may create ADRs simultaneously, use timestamp suffix: `ADR-NNN-YYYYMMDD-HHMM-title.md`

```markdown
# ADR-NNN: Title

**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXX
**Date:** YYYY-MM-DD
**Tags:** tag1, tag2

## Context
Why this decision was needed. 1-3 sentences.

## Decision
What was decided. Clear, actionable statement.

## Rationale
- Key reason 1
- Key reason 2
- Key reason 3

## Consequences
- Positive: What this enables
- Negative: What tradeoffs were accepted
- Neutral: Other effects

## Alternatives Considered
- Alternative 1: Why rejected (brief)
- Alternative 2: Why rejected (brief)
```

### sessions/YYYY-MM-DD-topic.md

**Purpose:** Session summaries for continuity across context windows.

**Naming:** Prefer `YYYY-MM-DD-topic.md` when clear topic exists. Use `YYYY-MM-DD-HHMM.md` for multiple same-day sessions without clear topics.

```markdown
# Session: YYYY-MM-DD

## Summary
Brief 2-3 sentence summary of what was accomplished.

## Work Completed
- Item 1
- Item 2

## Decisions Made
- ADR-NNN: Title (if applicable)
- Informal decision without ADR

## Context for Next Session
- Key context point that future sessions need
- Another important detail

## Open Questions
- Question that remains unanswered

---
*Session duration: ~Xh Xm*
```

## Validation Rules

### Required Files
- `active-context.md` - Must exist after initialization
- `product-context.md` - Must exist after initialization

### Optional Files
- `progress.md` - Created when tasks are tracked
- `patterns.md` - Created when patterns are documented
- `glossary.md` - Created when terminology is documented

### Required Directories
- `decisions/` - Must exist, may be empty
- `sessions/` - Must exist, may be empty

## Configuration File (Optional)

### .memory-config.md

**Purpose:** Project-specific ConKeeper configuration. Placed in `.claude/memory/`.

```yaml
---
suggest_memories: true    # Whether to suggest memory additions
auto_load: true           # Whether to auto-load memory at session start
output_style: explanatory # Output verbosity (quiet, normal, explanatory)
---
```

This file is optional. If not present, defaults are used.

## Token Budget Guidelines

Memory files should be concise to fit within context windows:
- `active-context.md`: ~200-400 tokens
- `product-context.md`: ~300-600 tokens
- `progress.md`: ~200-400 tokens
- `patterns.md`: ~200-400 tokens
- `glossary.md`: ~100-300 tokens
- Individual ADR: ~300-500 tokens
- Session summary: ~200-400 tokens

Total memory load should target under 2000 tokens for full context injection.

## Security Considerations

Memory files are loaded into AI assistant context and may influence behavior. See the project's SECURITY.md for:
- Prompt injection awareness
- Recommendations for shared repositories
- High-security environment guidelines
