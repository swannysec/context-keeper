# ConKeeper for GitHub Copilot

## Memory roots

New projects use `.ai/memory/`; existing legacy-only projects keep `.claude/memory/`. Global memory resolves independently between `~/.ai/memory/` and `~/.claude/memory/`. Both roots means prefer `.ai`, warn, and never merge. Paths shown below are new-project examples; substitute the selected legacy root when applicable. Use `bash <conkeeper-path>/tools/memory-root.sh` (or `--global`) to resolve without creating directories. All workflows use that root for settings, sessions, queues, decisions and handoffs. `AGENTS.md` is primary; the installer can also add the same instructions to `CLAUDE.md` as a compatibility fallback, preserving existing instructions.


Setup instructions for using ConKeeper memory system with GitHub Copilot.

## Prerequisites

- GitHub Copilot enabled in your editor (VS Code, JetBrains, etc.)
- Agent mode enabled in Copilot settings

## Installation

### Option 1: Copy Skills (Recommended)

Copy the skills to your project:

```bash
# From your project root
cp -r path/to/context-keeper/platforms/copilot/.github .
```

Or manually create the structure:
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

### Option 2: Add AGENTS.md Snippet

Add the ConKeeper snippet to your project's AGENTS.md:

```bash
cat >> AGENTS.md << 'EOF'

<!-- ConKeeper Memory System -->
## Memory System

This project uses ConKeeper for persistent AI context management.

**Memory Location:** Use existing `.ai/memory/`, otherwise existing `.claude/memory/`, otherwise `.ai/memory/` for initialization. Apply the same rule independently under the home directory for global memory. If both roots exist, use `.ai`, warn, and leave legacy files untouched.

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

### Option 3: Both (Recommended for Best Experience)

Use both skills AND the AGENTS.md snippet for full functionality.

## Usage

### With Skills Installed

Copilot will automatically discover and surface relevant skills based on context. You can also:

- Ask: "Initialize memory for this project"
- Ask: "Sync my current session to memory"
- Ask: "Create a session handoff"

### With AGENTS.md Only

Reference the workflows directly:
- "Follow the memory-init workflow to set up memory"
- "Use the memory-sync workflow to save my progress"
- "Generate a session handoff following the ConKeeper workflow"

## Memory Location

ConKeeper defaults to `.ai/memory/` for new projects and retains `.claude/memory/` for legacy-only projects. This location:
- Works with Claude Code (primary platform)
- Is recognized by Copilot via AGENTS.md
- Uses `.ai/memory/` for new projects while retaining legacy-only roots

## Verification

Test that Copilot sees the skills:
1. Open a file in your project
2. Invoke Copilot chat
3. Ask: "What ConKeeper workflows are available?"

Copilot should mention memory-init, memory-sync, and session-handoff.

## Troubleshooting

**Skills not appearing:**
- Ensure `.github/skills/` exists at project root
- Check that each skill has a valid SKILL.md file
- Restart your editor to refresh Copilot context

**AGENTS.md not being read:**
- Ensure AGENTS.md is at project root
- File must be named exactly "AGENTS.md"

## Validation Status

⚠️ This integration is implemented based on GitHub Copilot documentation but has not been fully tested. Community feedback welcome.

## Resources

- [GitHub Copilot Agent Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [ConKeeper Documentation](https://github.com/swannysec/context-keeper)
