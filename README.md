# ConKeeper (context-keeper)

A file-based agent memory system for AI coding assistants that provides structured context management using plain Markdown files.

**Multi-Platform Support:** ConKeeper works with Claude Code, GitHub Copilot, OpenAI Codex, Cursor, Windsurf, and Zed.

## Overview

ConKeeper replaces database-backed context management with simple, version-controllable Markdown files. It provides:

- **Global memory** (`~/.claude/memory/`) - Cross-project preferences and patterns
- **Project memory** (`<project>/.claude/memory/`) - Project-specific context, decisions, and progress
- **SessionStart hook** - Automatic memory awareness at session start
- **Context preservation hooks** - Automatic memory-sync before context compaction
- **Skills + commands** - Easy memory initialization, sync, and session handoff
- **Category tags** - Structured `<!-- @category: ... -->` tags for filtering and search
- **Privacy tags** - `<private>` blocks and file-level privacy for sensitive content
- **Observation hook** - Automatic tool usage logging via PostToolUse hook
- **Correction detection** - Real-time detection of user corrections and friction signals
- **Session retrospection** - After Action Review workflow via `/memory-reflect`
- **Facets integration** - Claude Code session analytics for friction and satisfaction trends

## Installation

### Option 1: Marketplace (Recommended)

Add the marketplace and install the plugin:

```bash
# Add the marketplace (use full HTTPS URL to avoid SSH auth issues)
/plugin marketplace add https://github.com/swannysec/context-keeper.git

# Install the plugin
/plugin install context-keeper@swannysec-plugins

# Create global memory directory
mkdir -p ~/.claude/memory
```

> **Note:** Using the full HTTPS URL avoids [SSH authentication issues](https://github.com/anthropics/claude-code/issues/14485) with the `github` source type.

### Option 2: Manual Installation

1. Clone or symlink this repo to `~/.claude/plugins/context-keeper`:
   ```bash
   # Use absolute path for reliable symlink (not relative)
   ln -s /absolute/path/to/context-keeper ~/.claude/plugins/context-keeper
   ```

2. Enable the plugin in `~/.claude/settings.json`:
   ```json
   {
     "enabledPlugins": {
       "context-keeper": true
     }
   }
   ```

3. Create global memory directory:
   ```bash
   mkdir -p ~/.claude/memory
   ```

## Multi-Platform Support

ConKeeper supports multiple AI coding platforms through native skills and AGENTS.md awareness.

### Platform Support Matrix

| Platform | Support Type | Status |
|----------|--------------|--------|
| **Claude Code** | Native Plugin | ✅ Fully Tested |
| **GitHub Copilot in VSCode** | Native Skills | ✅ Verified |
| **OpenAI Codex** | Native Skills | ⚠️ Documented |
| **Cursor** | Native Skills (Nightly) | ⚠️ Documented |
| **Windsurf** | .windsurfrules | ⚠️ Documented |
| **Zed** | AGENTS.md + Rules | ✅ Verified |

### Quick Setup (Any Platform)

Add this snippet to your project's AGENTS.md:

```text
<!-- ConKeeper Memory System -->
## Memory System

This project uses ConKeeper for persistent AI context management.

**Memory Location:** `.claude/memory/` (or `.ai/memory/`)

**Available Workflows:**
- **memory-init** - Initialize memory for this project
- **memory-sync** - Sync session state to memory files
- **session-handoff** - Generate handoff for new session
- **memory-search** - Search memory files by keyword or category

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

### Interactive Installer

```bash
# Run from your project directory
/path/to/context-keeper/tools/install.sh
```

### Platform-Specific Setup

See [docs/platform-guides/](docs/platform-guides/) for detailed platform instructions:
- [Claude Code](docs/platform-guides/claude-code.md)
- [GitHub Copilot](docs/platform-guides/copilot.md)
- [OpenAI Codex](docs/platform-guides/codex.md)
- [Cursor](docs/platform-guides/cursor.md)
- [Windsurf](docs/platform-guides/windsurf.md)
- [Zed](docs/platform-guides/zed.md)

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `/memory-init` | Initialize memory for current project |
| `/memory-sync` | Sync current session state to memory files |
| `/session-handoff` | Generate handoff prompt for new session |
| `/memory-search` | Search memory files by keyword or category |
| `/memory-config` | View and modify ConKeeper configuration |
| `/memory-reflect` | Session retrospection using After Action Review methodology |
| `/memory-insights` | Analyze session friction trends and success patterns (Claude Code) |

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

## Context Preservation (Claude Code)

ConKeeper automatically preserves your memory before context window compaction. Two hooks monitor usage and escalate:

| Context % | Action |
|-----------|--------|
| < 60% | Normal operation |
| >= 60% | Auto memory-sync (no approval needed, fires once) |
| >= 80% | Hard block — requires manual `/memory-sync` before continuing |
| >= 90% | Claude's auto-compaction fires; PreCompact hook warns if unsaved |

### Recommended Setup

For the full escalation sequence, add to your shell profile (`.zshrc`, `.bashrc`, etc.):

```bash
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=90
```

This pushes Claude's built-in compaction to 90%, giving ConKeeper's hooks room at 60% and 80%.

### Configuration

Thresholds are configurable per-project in `.claude/memory/.memory-config.md`:

```yaml
---
auto_sync_threshold: 60       # When to auto-sync (default: 60)
hard_block_threshold: 80      # When to block until manual sync (default: 80)
context_window_tokens: 200000 # Context window size (default: 200000)
correction_sensitivity: low   # low | medium — correction detection sensitivity
auto_reflect: true            # Auto-trigger /memory-reflect after /memory-sync
reflect_depth: standard       # minimal | standard | thorough
---
```

Adjust via `/memory-config` or edit the file directly.

### Requirements

The context preservation hooks require `jq` and `bc`. Install via your package manager if not already present. Hooks exit gracefully if either is missing.

## Design Principles

- **Files are sufficient** - All memory in `.md` files; no database
- **Quiet by default** - Memory operations summarized to 1-2 lines
- **Graceful degradation** - Works without hooks via CLAUDE.md instructions
- **User control** - Memory suggestions can be disabled per-project
- **Simple over complex** - Standard filesystem; no special tooling

## Security Considerations

Memory files may contain project context that influences AI assistant behavior. For security guidance, see [SECURITY.md](SECURITY.md).

Key recommendations:
- Add `.claude/memory/` to `.gitignore` for shared repositories
- Review memory files when working on untrusted codebases
- See SECURITY.md for prompt injection awareness

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

## Acknowledgments

ConKeeper was inspired by [ContextPortal](https://github.com/GreatScottyMac/context-portal) by [GreatScottyMac](https://github.com/GreatScottyMac). ContextPortal pioneered the concept of structured memory bank files for AI context persistence, and ConKeeper builds on those ideas with a Claude Code plugin implementation.

## License

Apache License 2.0 with Commons Clause - See [LICENSE](LICENSE) for details.

You may freely use, modify, and distribute this software. The Commons Clause restricts selling the software itself as a commercial product or service.
