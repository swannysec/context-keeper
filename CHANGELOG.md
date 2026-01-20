# Changelog

All notable changes to ConKeeper will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
