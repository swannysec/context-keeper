---
type: research
title: "claude-mem Competitive Research Notes"
created: 2026-02-09
tags:
  - competitive-analysis
  - claude-mem
  - memory-systems
related:
  - "[[Feature-Matrix]]"
  - "[[conkeeper-baseline]]"
---

# claude-mem — Competitive Research Notes

**Repository:** https://github.com/thedotmack/claude-mem
**Stars:** 26,075
**Version:** v9.1.1 (as of 2026-02-07) / package.json says 6.5.0
**Primary Language:** TypeScript (3.6MB), JavaScript (525KB), Python (10KB), Shell (8KB)
**License:** AGPL-3.0 (ragtime/ subdirectory is PolyForm Noncommercial 1.0.0)
**Author:** Alex Newman (@thedotmack)
**Installation:** Claude Code plugin marketplace (`/plugin marketplace add thedotmack/claude-mem`)

---

## Architecture Overview

### Storage Mechanism
- **SQLite database** for persistent storage (sessions, observations, summaries, prompts)
- **Chroma vector database** for hybrid semantic + keyword search
- **FTS5** (SQLite full-text search) for keyword indexing
- Data stored in `~/.claude-mem/` directory
- Settings managed in `~/.claude-mem/settings.json`

### Core Components
1. **Worker Service** — HTTP API server on port 37777, managed by Bun runtime
   - Web viewer UI at `http://localhost:37777`
   - 10+ search endpoints
   - In-process worker architecture (hooks become the worker when port available)
2. **5 Lifecycle Hooks** — SessionStart, UserPromptSubmit, PostToolUse, Stop, SessionEnd (6 hook scripts total)
3. **Smart Install** — Cached dependency checker (pre-hook script)
4. **MCP Server** — Exposes 5 search/memory tools via Model Context Protocol (stdio transport)
5. **Context Builder** — Token-aware context injection with formatters, sections, and observation compilation

### Hook Implementation
- Hooks defined in `plugin/hooks/hooks.json`
- **SessionStart:** Smart install check, worker service start, context injection
- **UserPromptSubmit:** Worker service start, session initialization
- **PostToolUse:** Worker service start, observation recording (captures every tool use)
- **Stop:** Worker service start, summarization, session completion
- Uses `bun-runner.js` wrapper for cross-platform Bun path resolution
- **Fail-open architecture** — hooks exit 0 with empty responses if worker unavailable

### Data Model
- **Sessions** — Track individual coding sessions with project association
- **Observations** — Granular records of tool usage (types: bugfix, feature, decision, discovery, change)
- **Summaries** — AI-compressed summaries of session activity
- **Prompts** — User prompt history for context

---

## Features

### Memory & Storage
- [x] Persistent memory across sessions
- [x] SQLite-backed structured storage with migrations
- [x] AI-powered compression of session observations
- [x] Session-scoped data (observations belong to sessions)
- [x] Project-scoped data (sessions belong to projects)
- [x] Manual memory saving via `save_memory` MCP tool
- [x] Import/export scripts for memories
- [x] Privacy controls via `<private>` tags to exclude content

### Search & Retrieval
- [x] Full-text search (FTS5)
- [x] Vector/semantic search via Chroma
- [x] Hybrid search combining keyword + semantic
- [x] 3-layer progressive disclosure: search index → timeline → full details
- [x] Timeline navigation around observations
- [x] MCP tools for search: `search`, `timeline`, `get_observations`, `save_memory`, `__IMPORTANT`
- [x] `mem-search` skill for natural language queries
- [x] Token cost visibility per search result (~50-100 tokens for index, ~500-1000 for full)
- [x] Filtering by: type, observation type, date range, project, relevance/date ordering

### Context Management
- [x] Automatic context injection on SessionStart
- [x] Progressive disclosure (layered memory retrieval)
- [x] Token-aware context building (TokenCalculator, ContextBuilder)
- [x] Configurable context injection (`CLAUDE_MEM_FOLDER_CLAUDEMD_ENABLED`, context config)
- [x] CLAUDE.md generation for project directories
- [x] Folder-level CLAUDE.md with exclusion patterns

### Hooks & Automation
- [x] 5 lifecycle hook events (SessionStart, UserPromptSubmit, PostToolUse, Stop, SessionEnd)
- [x] Fully automatic — no manual intervention required
- [x] PostToolUse observation capture (records every tool Claude uses)
- [x] Stop hook triggers AI summarization
- [x] Fail-open architecture (hooks don't block on errors)

### Platform & Integration
- [x] Claude Code plugin (marketplace install)
- [x] Claude Desktop support via skill
- [x] Cursor support via hooks installer
- [x] Web viewer UI at localhost:37777 (real-time memory stream)
- [x] MCP server integration (5 tools)
- [x] Beta channel for experimental features (Endless Mode)
- [x] i18n — README available in 30+ languages

### Configuration
- [x] Settings file (`~/.claude-mem/settings.json`)
- [x] Environment variable overrides (env > file > defaults)
- [x] AI model configuration
- [x] Worker port configuration
- [x] Data directory configuration
- [x] Log level configuration
- [x] Project exclusion patterns
- [x] Folder exclude patterns for CLAUDE.md generation
- [x] Custom config directory support (`CLAUDE_CONFIG_DIR`)

### Session Management
- [x] Automatic session tracking
- [x] Session-complete hooks for cleanup
- [x] Orphan process/session cleanup
- [x] Prompt-too-long termination
- [x] Infinite restart prevention (max 3 retries with exponential backoff)
- [x] Provider-aware recovery (SDKAgent, Gemini, OpenRouter)

### Security
- [x] CORS restricted to localhost
- [x] XSS defense-in-depth (DOMPurify)
- [x] Isolated credential handling (only from `~/.claude-mem/.env`)
- [x] Privacy tags to exclude sensitive content

---

## Unique Capabilities (vs ConKeeper)

### Features ConKeeper Lacks
1. **Structured database storage** — SQLite with schema migrations vs ConKeeper's flat markdown files
2. **Full-text search** — FTS5 + Chroma vector search vs ConKeeper's no built-in search
3. **Semantic/vector search** — Chroma integration for meaning-based retrieval
4. **PostToolUse observation capture** — Records every tool Claude uses automatically
5. **AI-powered summarization** — Compresses observations with AI at session end
6. **MCP server integration** — 5 search tools exposed via Model Context Protocol
7. **Web viewer UI** — Real-time memory dashboard at localhost:37777
8. **Progressive disclosure** — 3-layer search workflow with token cost visibility
9. **Timeline navigation** — Browse context around specific observations
10. **Manual memory saving** — Explicit `save_memory` tool for user-initiated storage
11. **Privacy tags** — `<private>` exclusion for sensitive content
12. **Multi-provider support** — Gemini, OpenRouter fallbacks beyond Claude
13. **Import/export** — Scripts for memory portability
14. **Beta channel** — Experimental features like Endless Mode
15. **Cursor integration** — Cross-editor support
16. **i18n** — 30+ language translations

### Shared Capabilities
- Session tracking and context injection on session start
- Hook-based architecture (lifecycle hooks)
- Project-scoped memory
- Configuration system
- Pre-compaction context preservation (ConKeeper) vs. continuous observation (claude-mem)

---

## Architecture Depth Analysis

### Strengths
- **Mature codebase** — v9.1.1 with extensive CHANGELOG, 35+ contributors, 26K stars
- **Layered architecture** — Clean separation: hooks → worker → services → SQLite/Chroma
- **Resilience** — Fail-open hooks, in-process worker fallback, spawn guards, zombie cleanup
- **Token efficiency** — Progressive disclosure pattern saves ~10x tokens vs naive fetching
- **Cross-platform** — Bun runner handles PATH resolution across macOS/Linux/Windows

### Weaknesses / Complexity Concerns
- **Heavy dependencies** — Requires Bun runtime, Chroma (Python/uv), Node.js 18+
- **Always-on daemon** — Worker service on port 37777 runs continuously
- **Complex hook chain** — Every hook starts worker service, then sends command
- **Database migrations** — 21+ schema versions with FK constraint issues in recent patches
- **Crypto token** — Has a Solana token ($CMEM) prominently featured, which may concern enterprise users
- **AGPL license** — More restrictive than permissive licenses for commercial use

---

## Implementation Patterns Worth Noting

### Progressive Disclosure Pattern
```
Search (50-100 tokens/result) → Timeline (context) → Full Details (500-1000 tokens/result)
```
This is the standout architectural pattern — saves tokens by not loading full observation data upfront.

### Context Builder Pattern
- `ContextBuilder.ts` — Assembles context from multiple sections
- `TokenCalculator.ts` — Estimates token costs before injection
- `ObservationCompiler.ts` — Transforms raw observations into injectable context
- Section-based formatters allow configurable context shape

### Observation Type System
- Typed observations: bugfix, feature, decision, discovery, change
- Custom types supported via mode system (v8.0.0+)
- Enables filtered retrieval by observation category

---

## Key Takeaways for ConKeeper

1. **Search is the #1 gap** — claude-mem's primary differentiator. ConKeeper has no search capability today.
2. **Observation granularity** — PostToolUse capture gives claude-mem fine-grained session history that ConKeeper doesn't collect.
3. **Token awareness** — Progressive disclosure with token cost estimates is a UX pattern worth adopting.
4. **MCP integration** — Exposing memory via MCP tools is a powerful pattern for cross-tool interoperability.
5. **ConKeeper's simplicity is a strength** — No daemon, no database, no Bun dependency. File-based approach is more portable and less fragile.
6. **Privacy controls** — `<private>` tags are a simple, effective pattern ConKeeper could adopt cheaply.
