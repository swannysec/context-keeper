# Changelog

All notable changes to ConKeeper will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
