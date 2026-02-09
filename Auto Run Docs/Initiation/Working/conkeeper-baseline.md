---
type: analysis
title: ConKeeper Current Capabilities Baseline
created: 2026-02-09
tags:
  - baseline
  - competitive-analysis
  - conkeeper
related:
  - "[[claude-mem-notes]]"
  - "[[memos-openmemory-mcp-notes]]"
  - "[[basicmem-memu-reflect-notes]]"
  - "[[Feature-Matrix]]"
---

# ConKeeper Current Capabilities Baseline

**Version:** 0.4.1 | **License:** Apache-2.0 with Commons Clause | **Language:** Bash (hooks), Markdown (skills/schema)

## Project Summary

ConKeeper is a file-based agent memory system for AI coding assistants. It replaces database-backed context management with plain Markdown files that are human-readable, version-controllable, and platform-agnostic. Designed as a Claude Code plugin, it also supports 5 additional platforms via AGENTS.md snippets and native skill files.

## Architecture

### Storage Mechanism
- **Type:** File-based (plain Markdown, no database)
- **Global memory:** `~/.claude/memory/` (cross-project preferences, patterns, glossary)
- **Project memory:** `<project>/.claude/memory/` (project-specific context)
- **Configuration:** YAML frontmatter in `.memory-config.md`
- **No external dependencies** for storage (no SQLite, no vector DB, no graph DB)

### Memory Schema (v1.0.0)
| File | Purpose | Update Frequency |
|------|---------|-----------------|
| `active-context.md` | Current focus, recent decisions, blockers | Frequently (per-session) |
| `product-context.md` | Project overview, architecture, constraints | Infrequently |
| `progress.md` | Task tracking (in-progress, completed, backlog) | Per-task |
| `patterns.md` | Code conventions, architecture & testing patterns | As discovered |
| `glossary.md` | Project-specific terms and abbreviations | As needed |
| `decisions/ADR-NNN-title.md` | Architecture Decision Records | Per-decision |
| `sessions/YYYY-MM-DD-topic.md` | Session summaries for continuity | Per-session |

### Path Resolution
- Primary: `.claude/memory/`
- Future: `.ai/memory/` (cross-platform standard, documented but not yet active)

## Skills (4 total)

### 1. `/memory-init`
- **Purpose:** Initialize memory directory structure and starter files for a new project
- **Pre-flight checks:** Validates project root (looks for package.json, Cargo.toml, etc.); handles existing memory gracefully
- **Creates:** All 5 core files + `decisions/` and `sessions/` directories
- **Interactive steps:** Gathers project context, configures token budget (4 presets), handles git tracking choice
- **Token budget presets:** economy (~2K), light (~3K), standard (~4K), detailed (~6K)

### 2. `/memory-sync`
- **Purpose:** Synchronize current session state to memory files
- **Process:** Read state → Analyze session → Propose updates → Apply on confirmation → Confirm
- **Creates ADRs** for architectural decisions (auto-numbered, with concurrency-safe timestamp suffix option)
- **Auto-sync mode:** When triggered by `<conkeeper-auto-sync>` tag from hooks, skips user approval step and applies directly
- **Updates:** active-context.md, progress.md, decisions/, timestamps

### 3. `/memory-config`
- **Purpose:** View and modify configuration settings
- **Settings available:** token_budget, suggest_memories, auto_load, output_style, auto_sync_threshold, hard_block_threshold, context_window_tokens
- **Output styles:** quiet, normal, explanatory

### 4. `/session-handoff`
- **Purpose:** Generate a complete handoff prompt for seamless session continuation
- **Process:** Check token budget → Sync memory first → Gather handoff context → Generate copy-paste prompt → Confirm
- **Handoff prompt includes:** Original goal, session summary, current state, completed work, remaining tasks, key decisions, blockers, critical files, context loading instructions
- **Adapts to token budget:** Session summary length varies from 2-3 sentences (economy) to 8-12 sentences (detailed)

## Hooks (3 total)

### 1. `session-start.sh` (SessionStart)
- **Purpose:** Detect memory directories and inject awareness context at session start
- **Behavior:** Checks for global + project memory dirs; outputs `<memory-system-active>` or `<memory-system-available>` tag
- **Security:** Validates symlinks against expected parent directory (prevents symlink escape attacks)
- **JSON encoding:** jq with pure-bash fallback for environments without jq
- **Fail-safe:** Outputs guidance to initialize memory if no directories found

### 2. `user-prompt-submit.sh` (UserPromptSubmit)
- **Purpose:** Monitor context window usage and trigger memory preservation
- **Dependencies:** Requires jq and bc (exits gracefully if missing)
- **Tiered escalation system:**
  - **< 60%:** No action
  - **>= 60% (auto_sync_threshold):** Injects `<conkeeper-auto-sync>` context once per session; triggers auto memory-sync
  - **>= 80% (hard_block_threshold):** Blocks prompt (exit 2) requiring manual `/memory-sync`; only after auto-sync has had a chance to run
- **Flag file management:** Uses `$TMPDIR/conkeeper/synced-{session_id}` and `blocked-{session_id}` with 4-hour TTL
- **Configuration:** Reads thresholds from `.memory-config.md` YAML frontmatter
- **Token calculation:** Parses last 100 lines of transcript for `input_tokens + cache_read_input_tokens + cache_creation_input_tokens`
- **Security:** Validates session_id format (alphanumeric + hyphens/underscores only), prevents path traversal

### 3. `pre-compact.sh` (PreCompact)
- **Purpose:** Warn if memory hasn't been synced before context compaction
- **Behavior:** Checks for sync flag file; warns if absent or stale (>4h)
- **Never blocks compaction** (always exits 0) — advisory only
- **Depends on:** Flag file written by `user-prompt-submit.sh`

### Hook Manifest (`hooks.json`)
- **Events covered:** SessionStart, UserPromptSubmit, PreCompact
- **Timeout:** UserPromptSubmit has 10-second timeout; others use default
- **All hooks are `command` type** (shell scripts, not prompt-based)

## Platform Support

| Platform | Support Type | Status | Integration Method |
|----------|--------------|--------|--------------------|
| Claude Code | Native Plugin | Fully Tested | plugin.json + hooks + skills |
| GitHub Copilot (VSCode) | Native Skills | Verified | .github/skills/ files |
| OpenAI Codex | Native Skills | Documented | .codex/skills/ files |
| Cursor | Native Skills (Nightly) | Documented | .cursor/skills/ files |
| Windsurf | Rules File | Documented | .windsurfrules append |
| Zed | AGENTS.md + Rules | Verified | AGENTS.md snippet |

### Interactive Installer (`tools/install.sh`)
- Detects platforms by checking for platform-specific directories
- Offers 6 installation options (individual platforms or all)
- Security: Refuses to run in system directories; checks for symlink attacks
- Copies skill files from `platforms/` subdirectories

## Configuration System

### `.memory-config.md` (YAML frontmatter)
| Setting | Default | Type | Description |
|---------|---------|------|-------------|
| `token_budget` | standard | enum | economy/light/standard/detailed |
| `suggest_memories` | true | boolean | Whether to suggest memory additions |
| `auto_load` | true | boolean | Auto-load memory at session start |
| `output_style` | normal | enum | quiet/normal/explanatory |
| `auto_sync_threshold` | 60 | int (0-100) | Context % to trigger auto-sync |
| `hard_block_threshold` | 80 | int (0-100) | Context % to block until sync |
| `context_window_tokens` | 200000 | int | Context window size for % calculation |

## Token Efficiency Design

- Bullet points over paragraphs (30-50% fewer tokens)
- Terse headers, active voice, present tense
- Abbreviations when clear (DB, auth, etc.)
- Per-file token budgets vary by preset (economy: ~2K total, detailed: ~6K total)

## Security Features

- Symlink validation on memory directories (session-start.sh)
- Session ID format validation (alphanumeric + hyphens/underscores only)
- Path traversal prevention in flag file paths
- Installer refuses to run in system directories (/, /etc, /usr, $HOME, etc.)
- Installer checks symlink status before modifying any file
- SECURITY.md with prompt injection awareness guidance
- Recommendation to `.gitignore` memory files in shared repos

## Design Principles (Stated)
1. **Files are sufficient** — No database; all memory in `.md` files
2. **Quiet by default** — Memory operations summarized to 1-2 lines
3. **Graceful degradation** — Works without hooks via CLAUDE.md instructions
4. **User control** — Memory suggestions can be disabled per-project
5. **Simple over complex** — Standard filesystem; no special tooling

## Complete Feature Checklist

### Storage & Schema
- [x] File-based Markdown storage (no database)
- [x] Global + project memory separation
- [x] Defined memory schema (v1.0.0) with 7 file types
- [x] YAML frontmatter configuration
- [x] Token budget presets (4 tiers)
- [x] Per-file token limits by preset
- [ ] Search across memory files
- [ ] Memory tagging or categorization
- [ ] Memory linking/relationships between entries
- [ ] Memory aging/decay
- [ ] Memory deduplication

### Context Management
- [x] Session handoff prompt generation
- [x] Session summary storage
- [x] Active context tracking
- [x] Architecture Decision Records (ADRs)
- [x] Progress/task tracking
- [x] Pattern documentation
- [x] Glossary/terminology
- [ ] Automatic observation capture (from tool use)
- [ ] Automatic correction/learning capture
- [ ] Confidence scoring for memories
- [ ] Memory consolidation/merging

### Hooks & Automation
- [x] SessionStart — memory detection and context injection
- [x] UserPromptSubmit — context usage monitoring + tiered escalation
- [x] PreCompact — pre-compaction warning
- [x] Auto memory-sync at configurable threshold
- [x] Hard block at configurable threshold
- [x] Flag file management with TTL (prevents duplicate actions)
- [ ] PostToolUse observation capture
- [ ] Automated memory suggestions based on conversation
- [ ] Hook-driven memory categorization

### Multi-Platform Support
- [x] Claude Code (native plugin)
- [x] GitHub Copilot (native skills)
- [x] OpenAI Codex (native skills)
- [x] Cursor (native skills)
- [x] Windsurf (rules file)
- [x] Zed (AGENTS.md)
- [x] Interactive multi-platform installer
- [x] AGENTS.md snippet for universal integration

### Search & Retrieval
- [ ] Full-text search across memory files
- [ ] Semantic/vector search
- [ ] Keyword-based search
- [ ] Date-range filtering
- [ ] Tag-based filtering
- [ ] Memory query tools (MCP or skill-based)

### Session Management
- [x] Session handoff with copy-paste prompt
- [x] Session summary storage with timestamps
- [x] Budget-aware summary length
- [x] Context for next session section
- [ ] Session retrospection/reflection
- [ ] Skill discovery from session patterns
- [ ] Cross-session learning/correction capture

### Security
- [x] Symlink validation (escape prevention)
- [x] Session ID format validation
- [x] Path traversal prevention
- [x] System directory protection (installer)
- [x] Prompt injection awareness documentation
- [x] `.gitignore` guidance for shared repos
- [ ] Memory file integrity checking
- [ ] Access control/permissions

### Configuration
- [x] Per-project configuration via `.memory-config.md`
- [x] Token budget presets (4 levels)
- [x] Configurable context thresholds
- [x] Output style control (quiet/normal/explanatory)
- [x] Auto-load toggle
- [x] Memory suggestion toggle
- [x] Context window size override

### User Interface / Experience
- [x] 4 slash commands (init, sync, config, handoff)
- [x] Quiet operation by default (1-2 line summaries)
- [x] Graceful degradation without hooks
- [ ] Web-based memory viewer
- [ ] Memory visualization/graph
- [ ] CLI tool for memory operations outside AI sessions
- [ ] MCP tools for programmatic access

## Key Gaps vs. Competitors (Summary)

Based on research of 7 competitors (claude-mem, MemOS, OpenMemory, mcp-memory-service, basic-memory, memU, claude-reflect):

1. **No search capability** — Every competitor (7/7) offers some form of search; ConKeeper has none
2. **No automatic observation capture** — claude-mem captures via PostToolUse hooks; ConKeeper only does manual sync
3. **No memory categorization** — Competitors auto-categorize (facts, preferences, procedures, etc.); ConKeeper uses flat file types
4. **No MCP tools** — 5/7 competitors expose memory via MCP tools; ConKeeper uses only hooks + skills
5. **No decay/aging** — 3/7 competitors implement memory aging; ConKeeper memories are permanent
6. **No session retrospection** — claude-reflect captures corrections and discovers skills from patterns
7. **No knowledge graph** — basic-memory and mcp-memory-service build entity-relationship graphs; ConKeeper is flat files

## Key Strengths (Summary)

1. **Broadest platform support** (6 platforms vs. 1-2 for most competitors)
2. **Zero-dependency storage** (no database to install, configure, or maintain)
3. **Version-controllable** (plain Markdown works with git natively)
4. **Pre-compaction hooks** (tiered escalation system is unique)
5. **Human-readable** (all memory is directly editable Markdown)
6. **Configurable token budgets** (4 presets with per-file limits)
7. **Interactive cross-platform installer**
8. **Graceful degradation** (works without hooks, just via CLAUDE.md instructions)
