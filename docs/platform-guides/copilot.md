# ConKeeper for GitHub Copilot

## Memory roots

New projects use `.ai/memory/`; existing legacy-only projects keep `.claude/memory/`. Global memory resolves independently between `~/.ai/memory/` and `~/.claude/memory/`. Both roots means prefer `.ai`, warn, and never merge. Paths shown below are new-project examples; substitute the selected legacy root when applicable. Use `bash <conkeeper-path>/tools/memory-root.sh` (or `--global`) to resolve without creating directories. All workflows use that root for settings, sessions, queues, decisions and handoffs. `AGENTS.md` is primary; the installer can also add the same instructions to `CLAUDE.md` as a compatibility fallback, preserving existing instructions.


GitHub Copilot supports native skills via the `.github/skills/` directory.

## Status: ⚠️ Implemented Based on Documentation

This integration is based on [GitHub Copilot documentation](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills). Community verification welcome.

## Installation

### Option 1: Copy Skills

```bash
# From context-keeper directory
cp -r platforms/copilot/.github /path/to/your/project/
```

This creates:
```
.github/
└── skills/
    ├── memory-init/
    │   └── SKILL.md
    ├── memory-sync/
    │   └── SKILL.md
    └── session-handoff/
        └── SKILL.md
```

### Option 2: AGENTS.md Only

Add to your project's AGENTS.md:

```markdown
<!-- ConKeeper Memory System -->
## Memory System

This project uses ConKeeper for persistent AI context management.

**Memory Location:** Use existing `.ai/memory/`, otherwise existing `.claude/memory/`, otherwise `.ai/memory/` for initialization. Apply the same rule independently under the home directory for global memory. If both roots exist, use `.ai`, warn, and leave legacy files untouched.

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

### With Skills
Copilot auto-discovers skills. You can:
- Ask: "Initialize memory for this project"
- Ask: "Sync my session"
- Ask: "Create a handoff"

### With AGENTS.md Only
Reference workflows directly:
- "Follow the memory-init workflow"
- "Use memory-sync to save progress"

## Memory Location

`.ai/memory/` - Compatible with Claude Code and other platforms.

## Verification

1. Open project in VS Code with Copilot
2. Open Copilot chat
3. Ask: "What ConKeeper skills are available?"

## Troubleshooting

### Skills not appearing
- Verify `.github/skills/` exists
- Check each skill has SKILL.md
- Restart VS Code

### AGENTS.md not read
- Ensure file is at project root
- Check exact filename

## Resources

- [GitHub Copilot Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [ConKeeper Repository](https://github.com/swannysec/context-keeper)
