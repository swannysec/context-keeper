# ConKeeper for Zed

Setup instructions for using ConKeeper memory system with Zed Editor.

## Prerequisites

- Zed Editor installed
- AI features enabled (Assistant Panel or Inline Assist)

## Important Notes

Zed does NOT support native skills. Instead, ConKeeper provides:
1. AGENTS.md awareness (Zed reads AGENTS.md as a rules source)
2. Rules Library prompts for manual workflow invocation

**Zed Rules Hierarchy:** Zed uses first-match from: AGENTS.md, CLAUDE.md, .rules, or custom rules paths. Place ConKeeper in whichever rules file Zed loads first.

## Installation

### Option 1: AGENTS.md (Recommended)

If you use AGENTS.md for AI rules, add the ConKeeper snippet:

```bash
cat >> AGENTS.md << 'EOF'

<!-- ConKeeper Memory System -->
## Memory System

This project uses ConKeeper for persistent AI context management.

**Memory Location:** `.claude/memory/`

**Available Workflows:**
- **memory-init** - Initialize memory (see full workflow below)
- **memory-sync** - Sync session state to memory files
- **session-handoff** - Generate handoff for new session
- **memory-search** - Search memory files by keyword or category
- **memory-reflect** - Session retrospection and improvement analysis
- **memory-insights** - Session friction trends and success pattern analysis

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

For full documentation: https://github.com/swannysec/context-keeper
<!-- /ConKeeper -->
EOF
```

### Option 2: .rules File

If you use `.rules` instead of AGENTS.md, add to `.rules`:

```
# ConKeeper Memory System
Memory location: .claude/memory/
Workflows: memory-init, memory-sync, session-handoff
When asked to use these workflows, create the appropriate memory files.
```

### Option 3: Rules Library

Import the ConKeeper prompts into Zed's Rules Library:

1. Open Zed Settings
2. Navigate to Assistant > Rules Library
3. Add new rule with ConKeeper workflow content
4. Mark as default if you want it always available

Copy content from `rules-library/` directory for each workflow.

## Usage

### In Assistant Panel

Ask the AI to follow workflows:
- "Initialize ConKeeper memory for this project"
- "Sync my session using memory-sync workflow"
- "Create a session handoff"

### With Inline Assist

Reference memory when needed:
- "Check .claude/memory/active-context.md for current focus"
- "Update progress.md with completed tasks"

## Memory Location

ConKeeper stores memory in `.claude/memory/` by default. This is cross-platform compatible with:
- Claude Code (primary platform)
- GitHub Copilot
- Cursor
- OpenAI Codex
- Windsurf

## Verification

Test that Zed sees ConKeeper:
1. Open Assistant Panel
2. Ask: "What memory workflows are available?"

The AI should reference ConKeeper workflows from your rules.

## Troubleshooting

**Workflows not recognized:**
- Verify AGENTS.md or .rules file exists at project root
- Check Zed's rules path settings
- Ensure rules file is first-match in hierarchy

**AI doesn't find memory:**
- Memory must be initialized first
- Check `.claude/memory/` directory exists
- Verify file permissions

## Validation Status

✅ AGENTS.md support has been verified in Zed.
⚠️ Rules Library integration is based on documentation.

## Resources

- [Zed AI Rules](https://zed.dev/docs/ai/rules)
- [ConKeeper Documentation](https://github.com/swannysec/context-keeper)
