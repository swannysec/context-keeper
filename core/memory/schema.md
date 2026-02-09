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
token_budget: standard    # Token budget preset: compact, standard, or detailed
auto_sync_threshold: 60    # Context % to trigger auto memory-sync
hard_block_threshold: 80   # Context % to block prompts until sync
context_window_tokens: 200000  # Total context window size in tokens
---
```

This file is optional. If not present, defaults are used.

### Per-File Privacy

Any memory file can include `private: true` in its YAML front matter to mark the entire file as private:

```yaml
---
private: true
---
```

This is a per-file setting — add it to individual memory files that contain sensitive content. It is not a global configuration option in `.memory-config.md`. Files marked private are skipped entirely by context injection, search, sync, and reflection.

### Context Preservation Settings

These settings control ConKeeper's automatic context preservation hooks, which trigger memory syncs before context window compaction.

| Setting | Default | Description |
|---------|---------|-------------|
| `auto_sync_threshold` | 60 | Context usage percentage (0-100) at which auto memory-sync is triggered |
| `hard_block_threshold` | 80 | Context usage percentage at which prompts are blocked until manual sync |
| `context_window_tokens` | 200000 | Total context window size in tokens (used for percentage calculation) |

**Behavior at each threshold:**
- **Below `auto_sync_threshold`:** No action. Normal operation.
- **At/above `auto_sync_threshold`:** The UserPromptSubmit hook injects auto-sync instructions once per session. The AI assistant runs memory-sync without user approval.
- **At/above `hard_block_threshold`:** The UserPromptSubmit hook blocks the prompt (after auto-sync has had a chance to run). The user must run `/memory-sync` manually and resubmit.
- **At 90% (recommended `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`):** Claude Code's built-in auto-compaction fires. The PreCompact hook warns if memory-sync hasn't run.

**Note:** For the full escalation sequence, set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=90` in your shell profile. This gives ConKeeper's hooks room to preserve context before compaction occurs.

### Token Budget Presets

| Preset | Total Target | Best For |
|--------|--------------|----------|
| `economy` | ~2000 tokens | Quick tasks, minimal context |
| `light` | ~3000 tokens | Small projects, faster loading |
| `standard` | ~4000 tokens | Most projects (default) |
| `detailed` | ~6000 tokens | Complex projects, comprehensive handoffs |

**Per-file limits by preset:**

| File | economy | light | standard | detailed |
|------|---------|-------|----------|----------|
| active-context.md | 200-400 | 300-500 | 400-600 | 500-800 |
| product-context.md | 300-600 | 400-700 | 500-900 | 700-1200 |
| progress.md | 200-400 | 250-450 | 350-550 | 450-700 |
| patterns.md | 200-400 | 250-450 | 350-550 | 450-700 |
| glossary.md | 100-300 | 150-350 | 200-450 | 300-500 |
| Individual ADR | 300-500 | 400-600 | 500-800 | 700-1000 |
| Session summary | 200-400 | 400-700 | 600-1000 | 900-1500 |

## Category Tags

Category tags enable structured filtering and search across memory files. Tags use HTML comment syntax so they are invisible in rendered Markdown but trivially parseable by grep or ripgrep.

### Tag Format

Tags are placed on their own line immediately after the heading or bullet they categorize:

```markdown
- Decided to use PostgreSQL over SQLite for multi-user support
<!-- @category: decision -->
```

### Memory Categories

Use these categories for entries in memory files (`active-context.md`, `patterns.md`, `sessions/`, `decisions/`):

| Category | Use For |
|----------|---------|
| `decision` | Choices made: tool selection, architecture direction, tradeoffs |
| `pattern` | Recurring code or architecture patterns discovered |
| `bugfix` | Bugs found and their fixes or workarounds |
| `convention` | Naming standards, formatting rules, style preferences |
| `learning` | New knowledge gained: TILs, discoveries, realizations |

Example:

```markdown
## Code Conventions
- Always use snake_case for Ruby method names
<!-- @category: convention -->
- Error handlers return Result objects, never raise
<!-- @category: pattern -->
```

### Retrospective Categories

Use these categories for `/memory-reflect` output (session retrospection analysis):

| Category | Use For |
|----------|---------|
| `efficiency` | Process speed, automation, reduced friction |
| `quality` | Code quality, fewer bugs, better testing |
| `ux` | Developer experience, ergonomics, usability |
| `knowledge` | Understanding gained, context built |
| `architecture` | Structural decisions, system design insights |

### Freeform Tags

For user-defined tags beyond the standard categories, use the `@tag` prefix:

```markdown
- Integrated Stripe payment processing
<!-- @category: decision -->
<!-- @tag: payments -->
<!-- @tag: third-party -->
```

### Validation Rules

- Tag values must match: `[a-z][a-z0-9-]*` (lowercase, alphanumeric, hyphens only)
- `@category` values must be from the defined sets above (memory or retrospective)
- `@tag` values are freeform but should follow the same character pattern
- One tag per line, maximum 80 characters per tag line
- Category tags inside `<private>` blocks (Phase 04) are subject to the same privacy enforcement as the content they annotate

### Placement Rules

- Multiple tags are allowed on separate consecutive lines
- Tags are additive-only — files work normally without any tags

### Searching by Category

Tags are plain text inside HTML comments, so standard search tools find them:

```bash
# Find all decisions across memory files
rg '@category: decision' .claude/memory/

# Find freeform tags
rg '@tag: payments' .claude/memory/
```

## Privacy Tags

Privacy tags allow marking sensitive content in memory files so it is excluded from all automated processing (context injection, search, sync, reflection) while remaining visible to humans editing the file.

### Block-Level Privacy

Wrap sensitive content in `<private>` and `</private>` tags, each on its own line:

```markdown
## API Configuration
- Production endpoint: https://api.example.com/v2
<private>
- API key: sk-proj-abc123...
- Webhook secret: whsec_xyz789...
</private>
- Rate limit: 1000 req/min
```

Content between the tags is excluded from all automated processing. The tags themselves are **visible** to humans editing the file — privacy should be obvious, not hidden.

### File-Level Privacy

Add `private: true` to a memory file's YAML front matter to mark the entire file as private:

```yaml
---
private: true
---
# Sensitive Credentials

This entire file is excluded from automated processing.
```

This is a per-file setting added to individual memory files, not a global configuration option.

### Enforcement Points

Privacy tags are enforced at every automated code path:

| Code Path | Behavior |
|-----------|----------|
| **SessionStart hook** | Strips `<private>` blocks before context injection; skips files with `private: true` |
| **`/memory-search`** | Omits private block contents from search results; skips private files *(planned — Phase 05)* |
| **`/memory-sync`** | Skips private content during analysis; never moves or references private content |
| **`/memory-reflect`** | Skips private content during evidence gathering *(planned — Phase 08)* |

### Edge Cases

- **Nesting:** NOT supported. If `<private>` tags appear inside an already-open `<private>` block, the outer tag wins and inner tags are treated as plain content. Do not nest `<private>` blocks.
- **Code fences:** The `strip_private` function processes `<private>` tags regardless of code fence context. Callers that inject file content are responsible for excluding code-fenced blocks before piping through `strip_private`. In instruction-level enforcement (sync, reflect, search), the LLM is expected to recognize code fences and not treat documented examples as real privacy tags.
- **Empty blocks:** `<private></private>` (on separate lines) is valid and means nothing is hidden.
- **Unclosed blocks:** If a `<private>` tag has no matching `</private>`, all content from the opening tag to the end of the file is stripped. Always close your `<private>` blocks to avoid unintended data loss.
- **Category tags inside private blocks:** Category tags within `<private>` blocks are subject to the same privacy enforcement as the content they annotate — they will not appear in search results or be processed by automation.

### Example: Patterns File with Private Content

```markdown
# Project Patterns

## API Integration
- All external calls use retry with exponential backoff
<!-- @category: pattern -->
<private>
- Internal API key for staging: sk-test-abc123 (rotate quarterly)
<!-- @category: convention -->
</private>
- Timeout set to 30s for all HTTP clients
<!-- @category: convention -->
```

In this example, the staging API key and its category tag are excluded from all automated processing. The surrounding public patterns remain visible and searchable.

## Token Budget Guidelines

Memory files should be concise to fit within context windows. The default preset is `standard` (~4000 tokens total). See **Token Budget Presets** above for per-file limits.

Projects can customize via `.memory-config.md` or during `memory-init`.

## Security Considerations

Memory files are loaded into AI assistant context and may influence behavior. See the project's SECURITY.md for:
- Prompt injection awareness
- Recommendations for shared repositories
- High-security environment guidelines
