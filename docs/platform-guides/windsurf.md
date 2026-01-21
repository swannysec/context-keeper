# ConKeeper for Windsurf

Windsurf uses `.windsurfrules` files for AI instructions since it doesn't support native skills.

## Status: ⚠️ Implemented Based on Documentation

This integration is based on [Windsurf documentation](https://docs.windsurf.com/windsurf/cascade/agents-md). Community verification welcome.

## Important Notes

- Windsurf does NOT support native skills
- ConKeeper provides inline workflows via `.windsurfrules`
- AGENTS.md is directory-scoped in Windsurf
- Root AGENTS.md snippet required for project-wide awareness

## Installation

### Step 1: Copy .windsurfrules

```bash
cp /path/to/context-keeper/platforms/windsurf/.windsurfrules /path/to/your/project/
```

Or append to existing file:
```bash
cat /path/to/context-keeper/platforms/windsurf/.windsurfrules >> .windsurfrules
```

### Step 2: Add AGENTS.md Snippet (Required)

Add to root AGENTS.md:

```markdown
<!-- ConKeeper Memory System -->
## Memory System

This project uses ConKeeper for persistent AI context management.

**Memory Location:** `.claude/memory/` (or `.ai/memory/`)

**Available Workflows:**
- **memory-init** - Initialize memory for this project
- **memory-sync** - Sync session state to memory files
- **session-handoff** - Generate handoff for new session

**Memory Files:**
- `active-context.md` - Current focus and state
- `product-context.md` - Project overview
- `progress.md` - Task tracking
- `decisions/` - Architecture Decision Records
- `sessions/` - Session summaries

**Usage:**
- Load memory at session start for non-trivial tasks
- Sync memory after significant progress
- Use handoff when context window fills

When asked to use these workflows, reference `.windsurfrules` for detailed instructions.

For full documentation: https://github.com/swannysec/context-keeper
<!-- /ConKeeper -->
```

## Usage

Ask Cascade to follow workflows:
- "Initialize ConKeeper memory for this project"
- "Sync my session using the memory-sync workflow"
- "Create a session handoff"

Cascade reads `.windsurfrules` for detailed instructions.

## Memory Location

`.claude/memory/` - Compatible with all platforms.

## Directory Scoping

Windsurf's AGENTS.md is directory-scoped:
- `.claude/AGENTS.md` only applies inside `.claude/`
- Root AGENTS.md applies project-wide

Always place ConKeeper snippet in **root** AGENTS.md.

## Verification

1. Open project in Windsurf
2. Start Cascade chat
3. Ask: "What memory workflows are available?"

## Troubleshooting

### Workflows not recognized
- Verify `.windsurfrules` at project root
- Check AGENTS.md snippet at root
- Restart Windsurf

### Directory scope issues
- Ensure snippet in root AGENTS.md, not subdirectory
- Check Windsurf's AGENTS.md scoping behavior

## Resources

- [Windsurf AGENTS.md](https://docs.windsurf.com/windsurf/cascade/agents-md)
- [ConKeeper Repository](https://github.com/swannysec/context-keeper)
