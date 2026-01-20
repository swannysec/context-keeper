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
- Create new ADR files if needed (format: `ADR-NNN-title.md`)
- Update timestamps

**ADR Numbering:** Scan `decisions/` for highest ADR-NNN, increment from there.

> **Concurrency note:** If multiple sessions might create ADRs simultaneously (rare), use a timestamp suffix like `ADR-NNN-YYYYMMDD-HHMM-title.md` to avoid conflicts.

**ADR Format:** (max ~500 tokens)
```markdown
# ADR-NNN: [Title]

**Status:** Accepted | **Date:** [date] | **Tags:** [tags]

## Context
[Why this decision was needed - 1-2 sentences]

## Decision
[What was decided - 1 sentence]

## Rationale
- [Key reason 1]
- [Key reason 2]

## Consequences
- [Consequence 1]
- [Consequence 2]

## Alternatives Considered
- [Alt 1]: [Why rejected]
```

### Step 5: Confirm

> Memory synced. [N] files updated.
