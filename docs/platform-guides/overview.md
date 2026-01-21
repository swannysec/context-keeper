# ConKeeper Multi-Platform Guide

ConKeeper provides persistent AI context management across multiple coding platforms. This guide covers installation and usage for each supported platform.

## Platform Support Matrix

| Platform | Skills Support | Method | Status |
|----------|----------------|--------|--------|
| **Claude Code** | Native | Plugin + Hooks | ✅ Fully Tested |
| **GitHub Copilot** | Native | `.github/skills/` | ⚠️ Documented |
| **OpenAI Codex** | Native | `.codex/skills/` | ⚠️ Documented |
| **Cursor** | Native (Nightly) | `.cursor/skills/` | ⚠️ Documented |
| **Windsurf** | Inline Rules | `.windsurfrules` | ⚠️ Documented |
| **Zed** | Rules Library | AGENTS.md | ✅ Verified |

**Legend:**
- ✅ Fully Tested: Verified through hands-on testing
- ⚠️ Documented: Implemented based on platform documentation

## Quick Start

### Option 1: Interactive Installer

```bash
# From your project directory
/path/to/context-keeper/tools/install.sh
```

### Option 2: Manual Setup

1. Add AGENTS.md snippet (works on all platforms)
2. Copy platform-specific skills if supported
3. Initialize memory with your AI assistant

## Architecture

ConKeeper uses a layered approach:

```
┌─────────────────────────────────────────────────┐
│              Your AI Assistant                   │
├─────────────────────────────────────────────────┤
│  Platform Layer (Skills/Rules/AGENTS.md)        │
├─────────────────────────────────────────────────┤
│  Core Workflows (memory-init, sync, handoff)    │
├─────────────────────────────────────────────────┤
│  Memory Files (.claude/memory/)                 │
└─────────────────────────────────────────────────┘
```

### Memory Location

ConKeeper stores memory in `.claude/memory/` by default:

```
.claude/memory/
├── active-context.md    # Current session focus
├── product-context.md   # Project overview
├── progress.md          # Task tracking
├── patterns.md          # Code patterns
├── glossary.md          # Project terms
├── decisions/           # Architecture Decision Records
│   └── ADR-NNN-*.md
└── sessions/            # Session summaries
    └── YYYY-MM-DD-*.md
```

## Platform Guides

- [Claude Code](claude-code.md) - Full plugin with hooks
- [GitHub Copilot](copilot.md) - Native skills
- [OpenAI Codex](codex.md) - Native skills
- [Cursor](cursor.md) - Skills + rules fallback
- [Windsurf](windsurf.md) - Inline rules
- [Zed](zed.md) - AGENTS.md + Rules Library

## AGENTS.md Snippet

For universal compatibility, add this snippet to your project's AGENTS.md:

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

## Workflows

### memory-init
Initialize the memory system for a new project:
- Creates directory structure
- Gathers project context
- Creates initial memory files
- Configures git tracking

### memory-sync
Synchronize session state to memory:
- Reviews conversation for decisions and progress
- Proposes updates to memory files
- Creates ADRs for significant decisions
- Updates timestamps

### session-handoff
Generate handoff for new session:
- Syncs current memory state
- Creates session summary
- Generates copyable handoff prompt
- Ensures continuity across sessions

## Troubleshooting

### Memory not loading
- Verify `.claude/memory/` directory exists
- Check that memory was initialized
- Ensure AI has file read access

### Skills not discovered
- Verify skills are in correct directory for platform
- Check SKILL.md files have valid YAML frontmatter
- Restart editor/IDE

### AGENTS.md not read
- Ensure file is at project root
- Verify exact filename "AGENTS.md"
- Check platform supports AGENTS.md

> **Note:** External documentation links were current as of January 2025. If links are broken, search for "[Platform] AI skills documentation" or "[Platform] agent mode".

## Contributing

Community testing and feedback for platforms marked as "Documented" is welcome. Please open issues at:
https://github.com/swannysec/context-keeper/issues
