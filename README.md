# ConKeeper (context-keeper)

A file-based agent memory system plugin for Claude Code that provides structured context management using plain Markdown files.

## Overview

ConKeeper replaces database-backed context management with simple, version-controllable Markdown files. It provides:

- **Global memory** (`~/.claude/memory/`) - Cross-project preferences and patterns
- **Project memory** (`<project>/.claude/memory/`) - Project-specific context, decisions, and progress
- **SessionStart hook** - Automatic memory awareness at session start
- **Skills + commands** - Easy memory initialization, sync, and session handoff

## Installation

1. Clone or symlink this repo to `~/.claude/plugins/context-keeper`:
   ```bash
   # Use absolute path for reliable symlink (not relative)
   ln -s /absolute/path/to/context-keeper ~/.claude/plugins/context-keeper
   ```

2. Enable the plugin in `~/.claude/settings.json`:
   ```json
   {
     "plugins": {
       "context-keeper": {
         "enabled": true
       }
     }
   }
   ```

3. Create global memory directory:
   ```bash
   mkdir -p ~/.claude/memory
   ```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `/memory-init` | Initialize memory for current project |
| `/memory-sync` | Sync current session state to memory files |
| `/session-handoff` | Generate handoff prompt for new session |

### Memory Structure

```
~/.claude/memory/                    # Global (cross-project)
├── preferences.md                   # Tool/workflow preferences
├── patterns.md                      # Reusable patterns
└── glossary.md                      # Personal terminology

<project>/.claude/memory/            # Project-specific
├── product-context.md               # Project overview, architecture
├── active-context.md                # Current focus, recent decisions
├── progress.md                      # Task tracking
├── patterns.md                      # Project conventions
├── glossary.md                      # Project terminology
├── decisions/                       # ADRs (ADR-001-title.md)
└── sessions/                        # Session history
```

### Workflow

1. **Start a new project:** Run `/memory-init` to create memory structure
2. **During work:** Memory updates happen naturally via suggestions or explicit `/memory-sync`
3. **End of session:** Run `/session-handoff` to generate a continuation prompt
4. **Next session:** Paste the handoff prompt to resume seamlessly

## Design Principles

- **Files are sufficient** - All memory in `.md` files; no database
- **Quiet by default** - Memory operations summarized to 1-2 lines
- **Graceful degradation** - Works without hooks via CLAUDE.md instructions
- **User control** - Memory suggestions can be disabled per-project
- **Simple over complex** - Standard filesystem; no special tooling

## Token Efficiency

Memory files use concise conventions:
- Bullet points over paragraphs (30-50% fewer tokens)
- Terse headers
- No redundant boilerplate
- Active voice, present tense
- Abbreviations when clear (DB, auth, etc.)

**Target sizes:**
- product-context.md: ~500-1000 tokens
- active-context.md: ~300-500 tokens
- progress.md: ~200-500 tokens
- ADRs: ~500 tokens each

## License

MIT License with Commercial Product Restriction - See [LICENSE](LICENSE) for details.

You may use this freely for personal, professional, educational, and internal business purposes. You may not incorporate it into commercial products or services sold to third parties.
