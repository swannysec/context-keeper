# ConKeeper for OpenAI Codex

Setup instructions for using ConKeeper memory system with OpenAI Codex CLI.

## Prerequisites

- OpenAI Codex CLI installed
- Project with AGENTS.md support

## Installation

### Option 1: Copy Skills (Recommended)

Copy the skills to your project:

```bash
# From your project root
cp -r path/to/context-keeper/platforms/codex/.codex .
```

Or manually create the structure:
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

### Option 2: Add AGENTS.md Snippet

Add the ConKeeper snippet to your project's AGENTS.md:

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
- **memory-search** - Search memory files by keyword or category
- **memory-reflect** - Session retrospection and improvement analysis
- **memory-insights** - Session friction trends and success pattern analysis

For full documentation: https://github.com/swannysec/context-keeper
<!-- /ConKeeper -->
EOF
```

### Option 3: Both (Recommended)

Use both skills AND the AGENTS.md snippet for best experience.

## Usage

### With Skills Installed

Codex will discover skills and make them available. You can invoke them with:

- `$memory-init` - Initialize memory
- `$memory-sync` - Sync session state
- `$session-handoff` - Generate handoff prompt

Or ask naturally:
- "Initialize memory for this project"
- "Sync my session to memory"
- "Create a handoff for the next session"

### With AGENTS.md Only

Reference workflows directly:
- "Follow the memory-init workflow"
- "Use memory-sync to save my progress"
- "Generate a session handoff"

## Memory Location

ConKeeper stores memory in `.claude/memory/` by default. This works across:
- Claude Code (primary platform)
- OpenAI Codex
- Other AGENTS.md-aware tools

## Verification

Test that Codex sees the skills:
1. Start a Codex session
2. Ask: "What ConKeeper skills are available?"

Codex should mention memory-init, memory-sync, and session-handoff.

## Troubleshooting

**Skills not appearing:**
- Ensure `.codex/skills/` exists at project root
- Check that each skill has a valid SKILL.md file
- Restart Codex session

**AGENTS.md not being read:**
- Ensure AGENTS.md is at project root
- Codex reads AGENTS.md hierarchically (root + subdirectories)

## Validation Status

⚠️ This integration is implemented based on OpenAI Codex documentation but has not been directly tested. Community feedback welcome.

## Resources

- [OpenAI Codex Skills](https://developers.openai.com/codex/skills/)
- [AGENTS.md Standard](https://agents.md/)
- [ConKeeper Documentation](https://github.com/swannysec/context-keeper)
