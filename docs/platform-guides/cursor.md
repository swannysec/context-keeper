# ConKeeper for Cursor

Cursor supports native skills in the nightly channel, with rules fallback for stable.

## Status: ⚠️ Implemented Based on Documentation

This integration is based on [Cursor documentation](https://cursor.com/docs/context/skills). Community verification welcome.

## Installation

### Option 1: Skills (Nightly Channel)

```bash
# From context-keeper directory
cp -r platforms/cursor/.cursor /path/to/your/project/
```

This creates:
```
.cursor/
└── skills/
    ├── memory-init/
    │   └── SKILL.md
    ├── memory-sync/
    │   └── SKILL.md
    └── session-handoff/
        └── SKILL.md
```

### Option 2: Rules (Stable Channel)

Create `.cursor/rules/conkeeper.mdc`:

```markdown
---
description: ConKeeper memory system for persistent context
alwaysApply: false
---

# ConKeeper Memory Workflows

When working on non-trivial tasks, use the ConKeeper memory system:

## Memory Location
`.claude/memory/`

## Workflows
- memory-init: Create memory directory and initial files
- memory-sync: Update memory with session state
- session-handoff: Generate handoff prompt
```

### Option 3: AGENTS.md

Add the ConKeeper snippet to AGENTS.md:

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

### Option 4: All Methods (Recommended)

Use skills + rules + AGENTS.md for maximum compatibility.

## Usage

### With Skills (Nightly)
- Ask: "Initialize ConKeeper memory"
- Ask: "Sync my session"
- Ask: "Create a handoff"

### With Rules (Stable)
- "@conkeeper initialize memory"
- "Use @conkeeper to sync"

### With AGENTS.md
- "Follow the memory-init workflow"
- "Use memory-sync"

## Memory Location

`.claude/memory/` - Compatible with all platforms.

## Verification

1. Open project in Cursor
2. Open chat
3. Ask: "What memory workflows are available?"

## Troubleshooting

### Skills not appearing (Nightly)
- Verify you're on Cursor Nightly
- Check `.cursor/skills/` exists
- Restart Cursor

### Rules not loading (Stable)
- Verify `.cursor/rules/` exists
- Check `.mdc` extension
- Verify YAML frontmatter

### AGENTS.md not read
- Ensure file at project root
- Check filename

## Resources

- [Cursor Skills](https://cursor.com/docs/context/skills)
- [Cursor Rules](https://cursor.com/docs/context/rules)
- [ConKeeper Repository](https://github.com/swannysec/context-keeper)
