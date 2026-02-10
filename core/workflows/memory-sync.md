# Memory Sync Workflow

**Purpose:** Synchronize current session state to memory files.

## When to Use

- End of a productive session
- After significant progress or decisions
- Before context window fills up
- User explicitly requests sync

## Workflow Steps

### 1. Review Current Memory State

Read existing memory files:
- `active-context.md` - Current focus and state
- `progress.md` - Task status
- Recent entries in `decisions/` - Recent ADRs

### 2. Analyze Session

Review the conversation for:
- **Decisions made:** Architectural, implementation, tooling choices
- **Tasks completed:** What work finished this session
- **Tasks started:** What work began but isn't complete
- **Context changes:** New understanding, shifted priorities
- **Patterns discovered:** New code or architecture patterns
- **Questions resolved:** Previously open questions now answered
- **Questions raised:** New questions that emerged

### 2.5. Process Corrections Queue

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
4. Add a category tag to each routed item:
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

### 3. Propose Updates

Present changes to user before applying:
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

### 4. Apply Updates

On user confirmation:

**Update active-context.md:**
- Update "Current Focus" to reflect session end state
- Update "Recent Decisions" with session decisions
- Update "Open Questions" - remove resolved, add new
- Update "Blockers" as appropriate
- Update session timestamp

**Update progress.md:**
- Mark completed tasks as done
- Add new tasks discovered
- Move items between sections as appropriate
- Update timestamp

**Create ADRs (if needed):**
- Scan `decisions/` for highest ADR number
- Increment for new ADR
- Use format: `ADR-NNN-kebab-case-title.md`
- Keep ADRs concise (~500 tokens max)

**Update patterns.md (if needed):**
- Document newly discovered patterns
- Update timestamp

### 5. Confirm Completion

```
Memory synced. [N] files updated.
- active-context.md: Updated focus and questions
- progress.md: [X] tasks completed, [Y] tasks added
- decisions/ADR-003-title.md: Created
```

## ADR Guidelines

Create an ADR when:
- Choosing between significant alternatives
- Making decisions with long-term impact
- Decisions others might question later

ADR structure:
```markdown
# ADR-NNN: Title

**Status:** Accepted | **Date:** YYYY-MM-DD | **Tags:** tag1, tag2

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

## Error Handling

- **Memory not initialized:** Suggest running memory-init first
- **Conflicting updates:** Show diff, ask user to resolve
- **File permission issues:** Report and skip affected files

## Auto-Sync Mode (Context Preservation)

ConKeeper's UserPromptSubmit hook monitors context window usage. When usage exceeds the configured threshold (default: 60%), the hook injects instructions to trigger an automatic memory sync.

### Differences from Manual Sync

| Aspect | Manual Sync | Auto-Sync |
|--------|-------------|-----------|
| Trigger | User runs `/memory-sync` | Hook injects `<conkeeper-auto-sync>` tag |
| Approval | Step 3: User confirms changes | Skipped — changes applied directly |
| Scope | Full sync with review | Full sync without review |
| Completion message | "Memory synced. [N] files updated." | "[ConKeeper: Auto memory-sync complete. Consider running /clear to start fresh with your synced context.]" |

### Flow

1. UserPromptSubmit hook detects context usage >= threshold
2. Hook injects `additionalContext` with sync instructions
3. AI assistant detects `<conkeeper-auto-sync>` tag
4. Assistant runs Steps 1, 2, 2.5, 4 of the sync workflow (skipping Step 3 approval)
5. Assistant completes the user's original task
6. Response ends with the auto-sync completion marker

### Configuration

Thresholds are configured in `.claude/memory/.memory-config.md`:
- `auto_sync_threshold`: Percentage at which auto-sync triggers (default: 60)
- `hard_block_threshold`: Percentage at which the hook blocks prompts until manual sync (default: 80)
- `context_window_tokens`: Total context window size in tokens (default: 200000) (auto-detected from model if not explicitly configured)

See the schema documentation for details.

## Platform-Specific Notes

> **Note:** Shell command examples use Unix/bash syntax for illustration. Adapt for your platform's shell or use your AI assistant's file manipulation capabilities.

- **Claude Code:** Available as `/memory-sync` command or skill
- **GitHub Copilot:** Available as contextual skill via custom instructions
- **Cursor:** Available as skill or via AGENTS.md guidance
- **Windsurf:** Available via `.windsurfrules` configuration
- **Cline/Roo Code:** Available via custom instructions or MCP configuration
- **Other platforms:** Follow manual workflow via AGENTS.md awareness
