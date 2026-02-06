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

### Auto-Sync Mode (Hook-Triggered)

When ConKeeper's UserPromptSubmit hook detects high context usage (>= configured threshold), it injects a `<conkeeper-auto-sync>` tag into your context.

**When this tag is detected in the current context:**

1. **Skip Step 3** (Propose Updates / user approval) — apply updates directly
2. Run Steps 1, 2, and 4 as normal (review state, analyze session, apply updates)
3. Run Step 5 (confirm) but replace the confirmation with:

> [ConKeeper: Auto memory-sync complete. Consider running /clear to start fresh with your synced context.]

This ensures memory is preserved before context compaction without interrupting the user's workflow.
