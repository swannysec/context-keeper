# Changelog

All notable changes to ConKeeper will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.2] — 2026-04-09

### Fixed
- **Model ID detection for 1M context variants** — standard models (`claude-opus-4-6`, `claude-sonnet-4-6`) now correctly map to 200K; new 1M context model IDs (`opus[1m]`, `sonnet[1m]`) map to 1M
- **Fresh sync before auto-clear** — auto-clear now always injects a sync before handoff generation, regardless of whether the 60% auto-sync already fired (the earlier sync may be stale by the time auto-clear triggers)

## [1.3.1] — 2026-04-07

### Fixed
- **Dynamic context window detection** — replaced broken `*[1m]*` model pattern with real model ID matching (`claude-opus-4-*`, `claude-sonnet-4-*` → 1M; `claude-haiku-*` → 200K)
- **Compaction window cap** — reads `CLAUDE_CODE_AUTO_COMPACT_WINDOW` from `settings.json` env and applies `min(model_window, compact_window)` so thresholds align with the actual compaction trigger point
- Auto-sync and hard-block tiers no longer fire too early when effective window exceeds 200K

## [1.3.0] — 2026-02-21

### Added
- **Context brackets** — graduated behavioral directives injected based on context window usage
  - Four tiers: FRESH (no injection), MODERATE, DEPLETED, CRITICAL
  - Fires unconditionally on every prompt — even after sync/block flags are set
  - Configurable thresholds (`bracket_fresh`, `bracket_moderate`, `bracket_depleted`)
  - Disable with `context_brackets: false`
- **Lifecycle automation (auto-clear)** — handoff generation and resume detection
  - Generates handoff file at configurable threshold (default: 90%) after sync completes
  - Advisory-only `/clear` recommendation (hooks cannot trigger CLI commands)
  - Resume detection in session-start: auto-injects handoff content on next session
  - Session-scoped filenames prevent parallel session collisions
  - Handoff TTL with automatic stale cleanup (default: 1 hour)
  - Disabled by default — opt-in via `auto_clear: true`
- New configuration options: `context_brackets`, `bracket_fresh`, `bracket_moderate`, `bracket_depleted`, `auto_clear`, `auto_clear_pct`, `handoff_ttl`

### Changed
- **Refactored `user-prompt-submit.sh` output architecture** — replaced early-exit pattern with accumulate-then-emit, enabling co-emission of brackets alongside sync/block directives
- Config validation: `auto_clear_pct` auto-adjusted if <= `auto_sync_threshold`
- Phase-09 context window tests updated to check for `conkeeper-auto-sync` specifically (accommodates bracket output)

### Notes
- 195 tests pass (129 unit + 12 bracket + 18 lifecycle + 36 functional integration)
- `lib-handoff.sh` sourced conditionally to keep the hot path lean
- Handoff files stored in `.claude/memory/.handoffs/` (isolated from memory files)
- All git operations in handoff use 2-second bash-native timeout (no GNU `timeout`)

## [1.2.0] — 2026-02-14

### Added
- **Session intelligence features** — memory diff, health scoring, decision index, cross-project search, friction-aware loading
  - Shared config library (`hooks/lib-config.sh`) for consistent YAML parsing
  - Memory diff shows commits and file changes since last sync
  - Health scoring detects stale memory files
  - Decision index directive for ADR lookup
  - Cross-project search with privacy enforcement
  - Friction-aware session start with budget gating

### Changed
- Version bumped from 1.1.0 to 1.2.0

## [1.1.0] — 2026-02-10

### Added
- **Context window auto-detection:** Reads `~/.claude/settings.json` to detect
  the active model's context window size (200K vs 1M). Eliminates premature
  sync/block warnings when using 1M context models.

### Changed
- `context_window_tokens` config setting is now optional — auto-detected if not set

## [1.0.0] - 2026-02-09

### Added

- **Category tags** (Phase 03) — structured `<!-- @category: ... -->` tags for filtering and search
  - Memory categories: `decision`, `pattern`, `bugfix`, `convention`, `learning`
  - Retrospective categories: `efficiency`, `quality`, `ux`, `knowledge`, `architecture`
  - Freeform `<!-- @tag: ... -->` tags for custom classification
  - Auto-categorization during `/memory-sync`
- **Privacy tags** (Phase 04) — `<private>` blocks and file-level `private: true` for sensitive content
  - Enforced across all code paths: SessionStart, sync, search, reflect
  - `.correction-ignore` file for suppressing false-positive correction detections
- **`/memory-search`** (Phase 05) — search memory files by keyword, category, or tag
  - `--global`, `--sessions`, `--category` flags for targeted search
- **Observation hook** (Phase 06) — PostToolUse hook logs tool usage to daily observation file
  - Full entries for external tools (Bash, WebFetch, etc.), stub entries for native tools
  - Configurable via `observation_hook` and `observation_detail` settings
- **Correction detection** (Phase 07) — UserPromptSubmit hook detects user corrections and friction
  - Real-time regex-based detection with configurable sensitivity (`low`/`medium`)
  - Corrections queue processed during `/memory-sync`
- **`/memory-reflect`** (Phase 08) — session retrospection using 7-phase After Action Review methodology
  - Consumes corrections, observations, session data, and Claude Code facets
  - Generates improvement recommendations with approval routing
  - Produces session retrospective files with evidence summary
- **`/memory-insights`** (Phase 08) — session friction trends and success pattern analysis
  - Dashboard, friction deep-dive, best/worst sessions, cross-session pattern analysis
  - Powered by Claude Code facets data (graceful degradation when unavailable)
- **Stop hook** — suggests `/memory-reflect` at session end when corrections or observations exist
- **New configuration options:** `observation_hook`, `observation_detail`, `correction_sensitivity`, `auto_reflect`

### Changed

- Version bumped from 0.4.0 to 1.0.0 (all planned features complete)
- `/memory-sync` now processes corrections queue (Step 2.5) and auto-categorizes entries (Step 2.6)
- `/memory-sync` conditionally triggers `/memory-reflect` after sync when `auto_reflect: true` and corrections were processed
- `/memory-config` expanded with observation, correction, and reflection settings
- Schema documentation updated with retro file format, external data sources, and privacy enforcement table
- Platform adapter snippets updated with all 6 available workflows
- `hooks/hooks.json` now registers 5 hooks: SessionStart, UserPromptSubmit, PreCompact, PostToolUse, Stop

### Notes

- **Upgrading from v0.4.x:** The `auto_reflect` setting defaults to `true`, meaning `/memory-reflect` will automatically run after `/memory-sync` when corrections are detected. Set `auto_reflect: false` in `.memory-config.md` to disable this behavior.
- Facets data integration is Claude Code-specific and degrades gracefully on other platforms
- All 73 tests pass across 6 test suites (Phases 03-08)

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
