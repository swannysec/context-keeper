# ConKeeper for Cursor

Setup instructions for using ConKeeper memory system with Cursor IDE.

## Prerequisites

- Cursor IDE installed
- Cursor Nightly (for native skills support) or Stable (rules fallback)

## Installation

### Option 1: Copy Skills (Nightly Channel)

If using Cursor Nightly with skills support:

```bash
# From your project root
cp -r path/to/context-keeper/platforms/cursor/.cursor .
```

Or manually create the structure:
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

### Option 2: Add AGENTS.md Snippet (All Versions)

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

### Option 3: Cursor Rules (Stable Fallback)

For Cursor Stable without skills, create `.cursor/rules/conkeeper.mdc`:

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

### memory-init
Initialize memory: create `.claude/memory/` with product-context.md, active-context.md, progress.md, decisions/, sessions/

### memory-sync  
Sync session: update active-context.md, progress.md, create ADRs if needed

### session-handoff
Generate handoff prompt for new session continuation
```

### Option 4: Both Skills + AGENTS.md (Recommended)

Use skills AND AGENTS.md for the best experience across Cursor versions.

## Usage

### With Skills (Nightly)

Cursor will auto-discover skills. You can:
- Ask: "Initialize ConKeeper memory"
- Ask: "Sync my session to memory"
- Ask: "Create a session handoff"

### With AGENTS.md

Reference workflows naturally:
- "Follow the memory-init workflow"
- "Sync memory using ConKeeper"
- "Generate a handoff for continuation"

### With Rules (Stable)

Reference the rule:
- "@conkeeper initialize memory"
- "Use @conkeeper to sync"

## Memory Location

ConKeeper stores memory in `.claude/memory/` by default. This location:
- Works with Claude Code (primary platform)
- Is recognized by Cursor via AGENTS.md
- Can be changed to `.ai/memory/` for platform-neutral projects

## Verification

Test that Cursor sees ConKeeper:

**With Skills:**
1. Open Command Palette
2. Look for ConKeeper skills in context

**With AGENTS.md:**
1. Start a Cursor chat
2. Ask: "What memory workflows are available?"

## Troubleshooting

**Skills not appearing (Nightly):**
- Ensure `.cursor/skills/` exists at project root
- Verify you're on Cursor Nightly
- Restart Cursor

**AGENTS.md not being read:**
- Ensure AGENTS.md is at project root
- Cursor supports AGENTS.md in recent versions

**Rules not loading (Stable):**
- Ensure `.cursor/rules/` directory exists
- Check rule file has `.mdc` extension
- Verify YAML frontmatter is valid

## Validation Status

⚠️ This integration is implemented based on Cursor documentation. Skills support is in nightly channel and may change. Community feedback welcome.

## Resources

- [Cursor Agent Skills](https://cursor.com/docs/context/skills)
- [Cursor Rules](https://cursor.com/docs/context/rules)
- [ConKeeper Documentation](https://github.com/swannysec/context-keeper)
