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

### Step 2.5: Process Corrections Queue

Check if `.claude/memory/corrections-queue.md` exists and has entries.

If it has entries:
1. Read the queue file
2. For each queued item, suggest routing to the appropriate memory file:
   - Code conventions, naming, style → `patterns.md` (under Code Conventions)
   - Architecture choices, design decisions → `decisions/ADR-NNN-*.md` (create new ADR)
   - Terminology corrections → `glossary.md`
   - General preferences, project context → `product-context.md`
   - Workflow preferences → `active-context.md`
3. Include the suggested routing in Step 3's proposed update output
4. Add a category tag to each routed item (using Phase 03 categories):
   - Corrections about conventions → `<!-- @category: convention -->`
   - Corrections about decisions → `<!-- @category: decision -->`
   - Corrections about patterns → `<!-- @category: pattern -->`
   - Friction about bugs → `<!-- @category: bugfix -->`
   - Other → `<!-- @category: learning -->`
5. User approves, modifies, or rejects each item
6. Approved items are written to target files with category tags
7. Rejected items are removed from queue
8. After processing, clear the queue file (replace contents with just the header)
9. If any corrections were processed, append to Step 5 output:
   "Corrections processed. Consider running /memory-reflect for deeper analysis."

### Step 2.6: Auto-Categorize Entries

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

If corrections were processed in Step 2.5, or if this was a substantial session
(many decisions, significant progress), append:

> Consider running /memory-reflect for deeper session analysis.

Read `auto_reflect` from `.memory-config.md` (default: true).
If `auto_reflect: true` and corrections were processed, automatically proceed to
run /memory-reflect after sync completes (no additional user prompt needed).

**Note:** Auto-reflect only triggers on corrections (not merely "substantial sessions") because
corrections are the strongest signal that retrospection will yield actionable improvements.
Auto-reflect is not triggered during auto-sync mode (hook-triggered) since auto-sync skips
Step 2.5 (corrections processing).

### Auto-Sync Mode (Hook-Triggered)

When ConKeeper's UserPromptSubmit hook detects high context usage (>= configured threshold), it injects a `<conkeeper-auto-sync>` tag into your context.

**When this tag is detected in the current context:**

1. **Skip Step 2.5** (Process Corrections Queue) — defer queue processing to next manual sync for security (queue entries need human review)
2. **Skip Step 3** (Propose Updates / user approval) — apply updates directly
3. Run Steps 1, 2, 2.6, and 4 as normal (review state, analyze session, auto-categorize, apply updates)
4. Run Step 5 (confirm) but replace the confirmation with:

> [ConKeeper: Auto memory-sync complete. Consider running /clear to start fresh with your synced context.]

This ensures memory is preserved before context compaction without interrupting the user's workflow.
