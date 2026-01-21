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

## Platform-Specific Notes

> **Note:** Shell command examples use Unix/bash syntax for illustration. Adapt for your platform's shell or use your AI assistant's file manipulation capabilities.

- **Claude Code:** Available as `/memory-sync` command or skill
- **GitHub Copilot:** Available as contextual skill via custom instructions
- **Cursor:** Available as skill or via AGENTS.md guidance
- **Windsurf:** Available via `.windsurfrules` configuration
- **Cline/Roo Code:** Available via custom instructions or MCP configuration
- **Other platforms:** Follow manual workflow via AGENTS.md awareness
