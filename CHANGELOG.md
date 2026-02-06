# Changelog

All notable changes to ConKeeper will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-02-06

### Added

- **Pre-compaction context preservation** — automatic memory-sync before context window compaction
  - `UserPromptSubmit` hook monitors context usage and triggers auto-sync at configurable threshold (default: 60%)
  - Hard-block at configurable threshold (default: 80%) requires manual `/memory-sync` before continuing
  - `PreCompact` hook warns if memory-sync hasn't run when compaction starts
  - Auto-sync mode in `/memory-sync` skill — skips user approval when hook-triggered
  - Session-scoped flag files prevent repeated nudges (4-hour TTL)
- **New configuration options** in `.memory-config.md`
  - `auto_sync_threshold` — context percentage to trigger auto-sync (default: 60)
  - `hard_block_threshold` — context percentage to block prompts (default: 80)
  - `context_window_tokens` — total context window size (default: 200000)

### Changed

- **License** changed from MIT with Commercial Product Restriction to Apache 2.0 with Commons Clause
- `hooks.json` now registers `UserPromptSubmit` and `PreCompact` hooks alongside `SessionStart`
- Memory-sync skill and workflow documentation updated with auto-sync mode
- Memory-config skill updated with context preservation settings

### Notes

- For the full escalation sequence (60% sync → 80% block → 90% compact), set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=90` in your shell profile
- Requires `jq` and `bc` — hooks exit gracefully if either is missing

## [0.2.0] - 2025-01-21

### Added

- **Multi-platform support** - ConKeeper now works across multiple AI coding platforms
  - GitHub Copilot via `.github/skills/`
  - OpenAI Codex via `.codex/skills/`
  - Cursor via `.cursor/skills/` (nightly) and rules (stable)
  - Windsurf via `.windsurfrules`
  - Zed via AGENTS.md and Rules Library
- **Core portable content** (`core/`)
  - `memory/schema.md` - Memory file format specification
  - `memory/templates/` - Template files for memory initialization
  - `workflows/` - Platform-agnostic workflow specifications
  - `snippet.md` - AGENTS.md snippet template
- **Platform adapters** (`platforms/`)
  - Platform-specific skill/rule packages for each supported platform
  - Per-platform README with setup instructions
- **Tools** (`tools/`)
  - `install.sh` - Interactive multi-platform installer
  - `build.sh` - Generate distributable platform packages
- **Documentation** (`docs/platform-guides/`)
  - Comprehensive setup guides for each platform
  - Platform support matrix and comparison

### Changed

- README.md updated with multi-platform overview and quick setup
- Architecture now uses layered approach: core workflows + platform adapters

### Notes

- Claude Code plugin functionality unchanged (backward compatible)
- Platforms marked "Documented" are implemented based on official documentation
- Community testing and feedback welcome for non-Claude Code platforms

## [0.1.0] - 2025-01-20

### Added

- Initial release of ConKeeper plugin
- **SessionStart hook** - Automatic memory detection and context injection
  - Detects global memory at `$HOME/.claude/memory`
  - Detects project memory at `.claude/memory`
  - Provides usage guidance in session context
- **Skills**
  - `memory-init` - Initialize project memory structure
  - `memory-sync` - Sync session state to memory files
  - `session-handoff` - Generate continuation prompts for new sessions
- **Commands**
  - `/memory-init` - Quick access to memory initialization
  - `/memory-sync` - Quick access to memory sync
  - `/session-handoff` - Quick access to session handoff
- **Security features**
  - Proper JSON encoding with jq (with bash fallback)
  - Symlink validation to prevent escape attacks
  - Error trapping for debugging
  - Idempotent gitignore handling
- **Documentation**
  - Comprehensive README with installation and usage
  - SECURITY.md with data handling guidelines
  - Expanded command documentation
  - ADR format templates

### Security

- JSON encoding handles backslashes, quotes, tabs, carriage returns, newlines
- Symlink resolution validates targets stay within expected directories
- No external dependencies (zero supply chain risk)
