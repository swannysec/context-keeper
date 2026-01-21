# ConKeeper for Zed

Zed supports AI rules via AGENTS.md and the Rules Library.

## Status: ✅ Tested (AGENTS.md)

AGENTS.md support has been verified. Rules Library integration is based on documentation.

## Important Notes

- Zed does NOT support native skills
- ConKeeper works via AGENTS.md awareness
- Rules Library provides manual workflow imports
- Zed uses first-match from: AGENTS.md, CLAUDE.md, .rules

## Installation

### Option 1: AGENTS.md (Recommended)

Add inline workflows to AGENTS.md:

```markdown
<!-- ConKeeper Memory System -->
## Memory System

This project uses ConKeeper for persistent AI context management.

**Memory Location:** `.claude/memory/`

**Available Workflows:**
- **memory-init** - Initialize memory (see workflow below)
- **memory-sync** - Sync session state to memory files  
- **session-handoff** - Generate handoff for new session

### memory-init Workflow
1. Create `.claude/memory/decisions/` and `.claude/memory/sessions/`
2. Gather project context (purpose, tech stack, current focus)
3. Create product-context.md, active-context.md, progress.md
4. Ask about git tracking preference

### memory-sync Workflow
1. Review active-context.md and progress.md
2. Analyze session for decisions, completed tasks, context changes
3. Propose and apply updates (with user confirmation)
4. Create ADRs for significant decisions

### session-handoff Workflow
1. Sync memory first
2. Create session summary in sessions/YYYY-MM-DD-topic.md
3. Generate copyable handoff prompt for new session
<!-- /ConKeeper -->
```

### Option 2: .rules File

If using `.rules` instead:

```
# ConKeeper Memory System
Memory location: .claude/memory/
Workflows: memory-init, memory-sync, session-handoff
When asked to use these workflows, create the appropriate memory files.
```

### Option 3: Rules Library

Import prompts into Zed's Rules Library:

1. Open Zed Settings (Cmd/Ctrl + ,)
2. Navigate to Assistant > Rules Library
3. Add rules from `platforms/zed/rules-library/`:
   - `memory-init.md`
   - `memory-sync.md`
   - `session-handoff.md`
4. Mark as default if you want always-available

## Usage

### In Assistant Panel
- "Initialize ConKeeper memory for this project"
- "Sync my session using memory-sync workflow"
- "Create a session handoff"

### With Inline Assist
- "Check .claude/memory/active-context.md for current focus"
- "Update progress.md with completed tasks"

## Memory Location

`.claude/memory/` - Compatible with all platforms.

## Rules Hierarchy

Zed uses first-match from:
1. AGENTS.md
2. CLAUDE.md
3. .rules
4. Custom rules paths

Ensure ConKeeper is in whichever file Zed loads first.

## Verification

1. Open Assistant Panel
2. Ask: "What memory workflows are available?"

## Troubleshooting

### Workflows not recognized
- Check AGENTS.md or .rules exists at project root
- Verify Zed's rules path settings
- Ensure first-match file contains ConKeeper

### AI doesn't find memory
- Memory must be initialized first
- Check `.claude/memory/` exists
- Verify file permissions

## Resources

- [Zed AI Rules](https://zed.dev/docs/ai/rules)
- [ConKeeper Repository](https://github.com/swannysec/context-keeper)
