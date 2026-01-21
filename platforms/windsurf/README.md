# ConKeeper for Windsurf

Setup instructions for using ConKeeper memory system with Windsurf IDE.

## Prerequisites

- Windsurf IDE installed
- Cascade AI enabled

## Important Notes

Windsurf does NOT support native skills like Claude Code, Copilot, or Cursor. Instead, ConKeeper provides:
1. `.windsurfrules` file with inline workflow instructions
2. AGENTS.md snippet for global awareness

**Directory Scoping:** Windsurf's AGENTS.md support is directory-scoped. An AGENTS.md in `.claude/` only applies when editing files inside `.claude/`. For project-wide awareness, use the root AGENTS.md snippet.

## Installation

### Step 1: Copy .windsurfrules

Copy the rules file to your project root:

```bash
cp path/to/context-keeper/platforms/windsurf/.windsurfrules .
```

Or create it manually (see content below).

### Step 2: Add AGENTS.md Snippet (Required)

Add the ConKeeper snippet to your project's root AGENTS.md:

```bash
cat >> AGENTS.md << 'EOF'

<!-- ConKeeper Memory System -->
## Memory System

This project uses ConKeeper for persistent AI context management.

**Memory Location:** `.claude/memory/`

**Available Workflows:**
- **memory-init** - Initialize memory for this project
- **memory-sync** - Sync session state to memory files  
- **session-handoff** - Generate handoff for new session

When asked to use these workflows, reference `.windsurfrules` for detailed instructions.

For full documentation: https://github.com/swannysec/context-keeper
<!-- /ConKeeper -->
EOF
```

## Usage

### Invoking Workflows

Ask Cascade to follow the workflows:
- "Initialize ConKeeper memory for this project"
- "Sync my session using the memory-sync workflow"
- "Create a session handoff for continuation"

Cascade will read the `.windsurfrules` file and follow the inline instructions.

### Memory Location

ConKeeper stores memory in `.claude/memory/` by default. This is cross-platform compatible with:
- Claude Code (primary platform)
- GitHub Copilot
- Cursor
- OpenAI Codex

## .windsurfrules Content

The `.windsurfrules` file contains full inline workflow instructions since Windsurf doesn't support skills. This includes:
- Memory directory structure
- Initialization workflow
- Sync workflow
- Handoff workflow

## Verification

Test that Windsurf sees ConKeeper:
1. Open your project in Windsurf
2. Start a Cascade chat
3. Ask: "What memory workflows are available?"

Cascade should reference ConKeeper and the available workflows.

## Troubleshooting

**Workflows not recognized:**
- Ensure `.windsurfrules` is at project root
- Ensure AGENTS.md snippet is at project root
- Restart Windsurf

**Memory directory scoping:**
- Windsurf's AGENTS.md is directory-scoped
- Root AGENTS.md provides project-wide awareness
- `.claude/AGENTS.md` only applies inside `.claude/`

## Validation Status

⚠️ This integration is implemented based on Windsurf documentation but has not been directly tested. Community feedback welcome.

## Resources

- [Windsurf AGENTS.md](https://docs.windsurf.com/windsurf/cascade/agents-md)
- [ConKeeper Documentation](https://github.com/swannysec/context-keeper)
