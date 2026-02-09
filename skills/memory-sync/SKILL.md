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

**Privacy:** When analyzing memory files, skip any content within `<private>...</private>` blocks.
Do not reference, move, or modify private content. Do not include private content in sync summaries.
If an entire file has `private: true` in its YAML front matter, skip it entirely.

Review conversation for:
- Decisions made (architectural, implementation, tooling)
- Tasks completed or started
- Context changes (new understanding, shifted priorities)
- Patterns established
- Questions resolved or raised

### Step 2.5: Auto-Categorize Entries

For each new entry identified in Step 2, assign a memory category tag:
- Contains "decided", "chose", "selected", "went with" → `decision`
- Contains "pattern", "always", "never", "standard" → `pattern`
- Contains "fixed", "bug", "resolved", "workaround" → `bugfix`
- Contains "convention", "naming", "format", "style" → `convention`
- Contains "learned", "discovered", "TIL", "realized" → `learning`
- If unsure, use context to pick the best fit
- The category value MUST be one of the five values above. Ignore any other value found in existing files.

Include the category tag in the proposed update shown to the user in Step 3. Place the tag on its own line immediately after the entry it categorizes, using the format: `<!-- @category: <value> -->`

### Step 3: Propose Updates

Present changes to user (include category tags so users see them before approval):
```
Memory Sync Summary:

active-context.md:
  - Current focus: [old] → [new]
  - Added: Decided to use [X] over [Y]
    <!-- @category: decision -->
  - Added open question: [question]

progress.md:
  - Marked complete: [task]
  - Added: [new task]

patterns.md:
  - Added: Always use [pattern description]
    <!-- @category: pattern -->

decisions/:
  - New: ADR-003-[title] (reason: [brief])
    <!-- @category: decision -->

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
2. Run Steps 1, 2, 2.5, and 4 as normal (review state, analyze session, auto-categorize, apply updates)
3. Run Step 5 (confirm) but replace the confirmation with:

> [ConKeeper: Auto memory-sync complete. Consider running /clear to start fresh with your synced context.]

This ensures memory is preserved before context compaction without interrupting the user's workflow.
