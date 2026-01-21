# ConKeeper for OpenAI Codex

OpenAI Codex CLI supports native skills via the `.codex/skills/` directory.

## Status: ⚠️ Implemented Based on Documentation

This integration is based on [OpenAI Codex documentation](https://developers.openai.com/codex/skills/). Community verification welcome.

## Installation

### Option 1: Copy Skills

```bash
# From context-keeper directory
cp -r platforms/codex/.codex /path/to/your/project/
```

This creates:
```
.codex/
└── skills/
    ├── memory-init/
    │   └── SKILL.md
    ├── memory-sync/
    │   └── SKILL.md
    └── session-handoff/
        └── SKILL.md
```

### Option 2: AGENTS.md Only

Codex reads AGENTS.md natively. Add the ConKeeper snippet:

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

For full documentation: https://github.com/swannysec/context-keeper
<!-- /ConKeeper -->
```

### Option 3: Both (Recommended)

Use skills AND AGENTS.md for best experience.

## Usage

### With Skills Installed

Codex discovers skills contextually. Invoke them by asking naturally:
- "Initialize memory for this project"
- "Sync my session to memory"
- "Create a handoff for the next session"

Or reference by name: "Run the memory-init skill"

### With AGENTS.md Only
- "Follow the memory-init workflow"
- "Use memory-sync"

## Memory Location

`.claude/memory/` - Compatible with all ConKeeper platforms.

## AGENTS.md Hierarchy

Codex reads AGENTS.md hierarchically:
- Root AGENTS.md applies globally
- Subdirectory AGENTS.md applies to that subtree

Place ConKeeper snippet in root AGENTS.md for project-wide access.

## Verification

1. Start Codex session
2. Ask: "What ConKeeper skills are available?"

## Troubleshooting

### Skills not found
- Verify `.codex/skills/` exists
- Check SKILL.md frontmatter
- Restart Codex

### AGENTS.md not read
- Ensure file at project root
- Check filename exactly matches

## Resources

- [OpenAI Codex Skills](https://developers.openai.com/codex/skills/)
- [AGENTS.md Standard](https://agents.md/)
- [ConKeeper Repository](https://github.com/swannysec/context-keeper)
