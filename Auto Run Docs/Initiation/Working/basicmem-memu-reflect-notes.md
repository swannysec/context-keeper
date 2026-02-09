---
type: research
title: "basic-memory, memU, and claude-reflect Competitive Research Notes"
created: 2026-02-09
tags:
  - competitive-analysis
  - basic-memory
  - memU
  - claude-reflect
  - memory-systems
related:
  - "[[Feature-Matrix]]"
  - "[[conkeeper-baseline]]"
  - "[[claude-mem-notes]]"
  - "[[memos-openmemory-mcp-notes]]"
---

# basic-memory, memU, and claude-reflect — Competitive Research Notes

---

## 1. basic-memory

**Repository:** https://github.com/basicmachines-co/basic-memory
**Stars:** ~2,500
**Primary Language:** Python 3.12+
**License:** AGPL-3.0
**Installation:** `uv tool install basic-memory` or `uvx basic-memory`
**MCP Status:** Certified MCP server

---

### Architecture Overview

#### Storage Mechanism
- **Markdown files** as the canonical storage format (human-readable, editable by both humans and AI)
- **SQLite database** for indexing, full-text search, and relationship tracking
- **Optional PostgreSQL** backend for enterprise deployments
- Files organized in a knowledge graph structure with semantic relationships
- All data stored locally by default; optional cloud sync via Basic Memory Cloud (subscription)

#### Core Data Model: Entity-Observation-Relation
1. **Entities** — Topics represented as Markdown files with YAML frontmatter (title, type, permalink)
2. **Observations** — Categorized facts using format: `[category] content #tag (context)`
   - Categories: method, tip, preference, fact, experiment, resource, question, note
3. **Relations** — Semantic links between entities using wiki-link syntax: `relation_type [[WikiLink]] (optional context)`
   - Relation types: pairs_well_with, grown_in, contrasts_with, requires, improves_with, relates_to, inspired_by, documented_in

#### Unique Architecture Pattern: Bi-directional Editing
Both humans and AI read/write to the same Markdown files. This is a fundamentally different approach from most competitors — the knowledge base isn't a black box; it's a shared workspace.

### MCP Tools (17+ tools)

**Content Management:**
- `write_note` — Create new knowledge entries
- `read_note` — Read specific notes
- `read_content` — Read raw file content
- `view_note` — Formatted note display
- `edit_note` — Modify existing notes
- `move_note` — Relocate notes in hierarchy
- `delete_note` — Remove notes

**Knowledge Graph Navigation:**
- `build_context` — Assemble context from `memory://` URIs
- `recent_activity` — Surface recently modified knowledge
- `list_directory` — Browse knowledge hierarchy

**Search & Discovery:**
- `search` — Full-text search with pagination
- `search_notes` — Filtered search (entity types, date ranges, metadata, tags, status)
- `search_by_metadata` — Structured frontmatter-based search

**Project Management:**
- `list_memory_projects` — Multi-project support
- `create_memory_project` — Initialize new project contexts
- `get_current_project` — Active project identifier
- `sync_status` — Sync state visibility

**Visualization:**
- `canvas` — Generate knowledge graph visualizations

### Key Features

| Feature | Details |
|---------|---------|
| **Persistent memory** | Markdown files on local disk |
| **Knowledge graph** | Entity-Observation-Relation model with typed relationships |
| **Bi-directional editing** | Humans and AI share the same files |
| **Full-text search** | SQLite-backed with pagination and filters |
| **Metadata search** | YAML frontmatter-based querying |
| **Wiki-link syntax** | `[[Entity]]` cross-references |
| **memory:// URIs** | Semantic navigation protocol |
| **Multi-project** | Separate knowledge bases per project |
| **Cloud sync** | Optional subscription-based cross-device sync |
| **Obsidian compatible** | Files work directly in Obsidian |
| **Docker support** | Dockerfile + docker-compose for self-hosting |
| **Dual DB backends** | SQLite (default) + PostgreSQL (enterprise) |
| **MCP certified** | Official MCP server certification |

### Platform Support
- Claude Desktop (via claude_desktop_config.json)
- VS Code (via .vscode/mcp.json)
- Any MCP-compatible client
- Web/mobile via Basic Memory Cloud

### Configuration
- MCP server config in Claude Desktop or VS Code settings
- Environment variables for customization
- Docker configuration for containerized deployments
- Cloud sync requires subscription

### Strengths (vs ConKeeper)
1. **Rich knowledge graph** — Entity-Observation-Relation model enables structured knowledge navigation far beyond ConKeeper's flat file approach
2. **17+ MCP tools** — Extensive programmatic access to memory
3. **Bi-directional editing** — Users and AI share the same knowledge base seamlessly
4. **Obsidian compatibility** — Markdown + wiki-links work in existing knowledge management tools
5. **Multi-project support** — Built-in project isolation
6. **Search depth** — Three search modes (full-text, notes, metadata) with filtering and pagination
7. **Visualization** — Canvas generation for knowledge graph views

### Weaknesses / Concerns
1. **AGPL license** — Restrictive for commercial integrations
2. **Python 3.12+ requirement** — Narrows platform compatibility (macOS ships Python 3.x but often older)
3. **Heavy infrastructure** — SQLite + optional Postgres + Docker + Cloud sync adds complexity
4. **No hook-based automation** — Requires explicit MCP tool calls; no automatic capture
5. **Cloud sync is paid** — Cross-device feature requires subscription
6. **Single-platform focus** — Primarily Claude Desktop / VS Code; no multi-editor hook story

### Key Takeaways for ConKeeper
1. **Entity-Observation-Relation model** — The structured data model is more queryable than ConKeeper's freeform Markdown, but at the cost of requiring specific formatting
2. **Wiki-link cross-references** — ConKeeper already uses `[[wiki-links]]` in its structured output artifacts, but doesn't have graph traversal
3. **memory:// URI scheme** — Interesting protocol for referencing knowledge across tools; could inspire a ConKeeper addressing scheme
4. **Obsidian compatibility** — ConKeeper's Markdown-first approach could also be made Obsidian-compatible with minimal effort
5. **Search is table-stakes** — Another competitor with robust search; ConKeeper's lack of search is increasingly a differentiator... in the wrong direction
6. **ConKeeper's hooks advantage** — basic-memory requires explicit MCP calls; ConKeeper's automatic hooks are more seamless

---

## 2. memU

**Repository:** https://github.com/NevaMind-AI/memU
**Stars:** ~8,600
**Primary Language:** Python 3.13+ (with Rust components via Cargo.toml)
**License:** Apache 2.0
**Installation:** `pip install -e .` (self-hosted) or Cloud API at api.memu.so
**Benchmark:** 92.09% average accuracy on Locomo benchmark

---

### Architecture Overview

#### Storage Mechanism
- **In-memory** — For testing/development
- **PostgreSQL 16+ with pgvector** — Production persistent storage with vector embeddings
- **Cloud backend** — Hosted service at memu.so with 24/7 continuous learning

#### Core Data Model: Three-Layer Hierarchy
1. **Resources** — Original data sources (conversations, documents, images, files)
2. **Items** — Extracted facts, preferences, and skills (the "memory units")
3. **Categories** — Auto-organized topics for hierarchical navigation

The metaphor is "memory like a file system" — categories are folders, items are files, and cross-references are symlinks.

#### Unique Architecture Pattern: Proactive Memory
Unlike all other competitors (which are reactive — search/retrieve on demand), memU actively monitors interactions and pre-loads context before the user asks. This is the 24/7 "always-on" differentiator.

### API / Tools

**Core Operations:**
- `memorize()` — Continuous learning pipeline; processes inputs in real-time with immediate memory updates
- `retrieve()` — Dual-mode: RAG-based (fast, embedding-only, low cost) or LLM-based (deep reasoning, higher cost)

**Cloud API v3 Endpoints:**
- `POST /api/v3/memory/memorize` — Submit content for memorization
- `GET /api/v3/memory/memorize/status/{task_id}` — Check memorization status
- `GET /api/v3/memory/categories` — Browse category hierarchy
- `POST /api/v3/memory/retrieve` — Query memories

### Key Features

| Feature | Details |
|---------|---------|
| **Proactive memory** | 24/7 background monitoring, pattern detection, intent prediction |
| **Auto-categorization** | Hierarchical topic organization without manual tagging |
| **Dual retrieval modes** | RAG-based (fast/cheap) and LLM-based (deep/expensive) |
| **Vision support** | Can memorize images via vision-enabled models |
| **Token cost reduction** | Caches insights, avoids redundant LLM calls |
| **Multi-provider LLM** | OpenAI, Anthropic (via OpenRouter), DashScope, Voyage AI, custom |
| **Cross-references** | Symlink-like relationships between related memories |
| **Continuous extraction** | Real-time fact extraction from ongoing interactions |
| **Benchmark validated** | 92.09% accuracy on Locomo benchmark |

### Platform Support
- Self-hosted Python application
- Cloud API (memu.so)
- No direct Claude Code / IDE integration mentioned
- Framework-level integration (embed into your own agents)

### Configuration
- LLM profile configuration (provider, model, API key)
- Environment variables (OPENAI_API_KEY, OPENROUTER_API_KEY)
- Custom HTTP/SDK client backends
- Embedding model configuration (separate from chat model)

### Strengths (vs ConKeeper)
1. **Proactive intelligence** — Anticipates needs before explicit requests; no other competitor does this
2. **Auto-categorization** — No manual tagging required; memories self-organize
3. **Token cost optimization** — Explicit focus on reducing LLM costs through caching
4. **Vision support** — Can process and remember images (unique among competitors)
5. **Benchmark validation** — Published accuracy metrics (92.09% Locomo)
6. **Dual retrieval** — Choose between fast/cheap (RAG) and deep/expensive (LLM) retrieval

### Weaknesses / Concerns
1. **Heavy infrastructure** — Requires PostgreSQL 16+ with pgvector for production use
2. **Python 3.13+ requirement** — Very bleeding-edge; many systems don't have 3.13 yet
3. **No Claude Code integration** — No plugin, hooks, or skills; it's a framework, not a product
4. **Cloud-first design** — Self-hosting requires significant setup
5. **No MCP tools** — Uses REST API, not Model Context Protocol
6. **No session management** — No concept of coding sessions, projects, or session handoff
7. **Requires external LLM** — Needs OpenAI/OpenRouter for extraction; additional API costs
8. **Not coding-specific** — Designed for general AI agents (recommendations, email, finance); no IDE awareness

### Key Takeaways for ConKeeper
1. **Proactive context is a frontier feature** — memU's anticipatory pre-loading is genuinely novel but extremely complex to implement in a file-based system
2. **Auto-categorization** — ConKeeper could add lightweight auto-tagging to memory files without the full infrastructure
3. **Token cost visibility** — Explicit token budget awareness (ConKeeper's pre-compact hook already has token parsing, but could surface this more)
4. **Vision support is unique** — No other competitor processes images; niche but interesting
5. **Different market segment** — memU targets autonomous agent builders, not individual coding assistants; limited direct competitive threat
6. **REST API pattern** — If ConKeeper ever needs a remote/API mode, memU's REST approach is simpler than MCP for basic use cases

---

## 3. claude-reflect

**Repository:** https://github.com/BayramAnnakov/claude-reflect
**Stars:** ~660
**Version:** v2.5.1
**Primary Language:** Python 3.6+
**License:** MIT
**Installation:** Claude Code plugin marketplace (`claude plugin marketplace add bayramannakov/claude-reflect`)
**Tests:** 160 passing

---

### Architecture Overview

#### Storage Mechanism
- **CLAUDE.md files** — Markdown files as persistent storage (same files ConKeeper uses!)
- **AGENTS.md** — Cross-platform compatibility file (Codex, Cursor, Aider, Jules, Zed, Factory)
- **Skill files** — `.claude/commands/*.md` for learned workflow patterns
- **Queue file** — Temporary storage for pending learnings before human approval
- No database, no vector store, no external services

#### Core Pipeline: Two-Stage Hybrid Detection
**Stage 1 — Automatic Capture (hooks, real-time):**
- Regex pattern matching for correction phrases ("no, use X", "don't use Y", "actually...", "that's wrong")
- Positive feedback detection ("Perfect!", "Exactly right", "Great approach")
- Explicit markers ("remember:" — highest confidence)
- Queues learnings without blocking workflow

**Stage 2 — Manual Processing (`/reflect` command):**
- AI-powered semantic validation of queued items
- Multi-language support (understands corrections in any language)
- False positive filtering
- Produces concise, actionable statements
- Human approval gate before writing to CLAUDE.md

#### Unique Architecture Pattern: Human-in-the-Loop Learning
Automation captures candidate learnings, but humans retain approval authority. This prevents training on false corrections while ensuring legitimate learnings are integrated. This is the closest competitor to ConKeeper's philosophy of human control.

### Commands

| Command | Function |
|---------|---------|
| `/reflect` | Process queued learnings with human review |
| `/reflect --scan-history` | Scan past sessions for missed corrections |
| `/reflect --dry-run` | Preview changes without applying |
| `/reflect --targets` | Show target files (CLAUDE.md, AGENTS.md) |
| `/reflect --review` | Display queue with confidence scores and decay |
| `/reflect --dedupe` | Find and consolidate similar entries |
| `/reflect --include-tool-errors` | Add tool errors to scan scope |
| `/reflect-skills` | Discover skill candidates from repeating patterns |
| `/reflect-skills --days N` | Analyze N days of history (default: 14) |
| `/reflect-skills --project <path>` | Scan specific project |
| `/reflect-skills --all-projects` | Cross-project pattern scan |
| `/reflect-skills --dry-run` | Preview patterns without generating |
| `/skip-reflect` | Discard all queued learnings |
| `/view-queue` | View pending learnings without processing |

### Hooks (4 hooks)

1. **session_start_reminder.py** — Notifies user of pending learnings at session start
2. **capture_learning.py** — Per-prompt: regex detection of corrections, queues them
3. **check_learnings.py** — Pre-compaction: backs up queue, notifies user
4. **post_commit_reminder.py** — Post git-commit: prompts user to run `/reflect`

### Key Features

| Feature | Details |
|---------|---------|
| **Correction capture** | Automatic detection of user corrections via regex + AI semantic analysis |
| **Confidence scoring** | 0.60-0.95 scores; higher of regex and semantic confidence |
| **Human approval gate** | All learnings require explicit user approval before persistence |
| **Multi-target sync** | Global CLAUDE.md, project CLAUDE.md, subdirectory CLAUDE.md, skill files, AGENTS.md |
| **Semantic deduplication** | `/reflect --dedupe` consolidates similar entries |
| **Historical scanning** | `/reflect --scan-history` recovers corrections from past sessions |
| **Skill discovery** | `/reflect-skills` identifies repeating patterns and generates skill files |
| **Skill self-improvement** | Corrections during skill execution route back to the skill file |
| **Multi-language** | Correction patterns detected regardless of language |
| **Cross-platform targets** | Writes to AGENTS.md for Codex, Cursor, Aider, Jules, Zed, Factory |
| **Smart filtering** | Excludes one-time instructions, questions, context-specific requests |
| **Decay tracking** | Queue items decay over time if not processed |
| **Privacy** | No external services; all processing local |

### Platform Support
- Claude Code (plugin marketplace)
- macOS, Linux, Windows (native Python, no WSL required)
- Cross-platform target files: CLAUDE.md + AGENTS.md (Codex, Cursor, Aider, Jules, Zed, Factory)

### Configuration
- Plugin auto-registers hooks on install
- Target files auto-discovered (CLAUDE.md hierarchy, AGENTS.md, skill files)
- Python 3.6+ (very low barrier — even old systems qualify)
- No external API keys required for basic operation (semantic analysis uses Claude itself)

### Strengths (vs ConKeeper)
1. **Correction capture** — Learns from mistakes automatically; ConKeeper has no learning-from-corrections mechanism
2. **Skill discovery** — Auto-generates reusable commands from repeating patterns; ConKeeper doesn't detect patterns
3. **Human-in-the-loop** — Same philosophy as ConKeeper but applied to learning, not just memory sync
4. **Confidence scoring** — Quantified trust in each learning; ConKeeper has no confidence model
5. **Semantic deduplication** — Prevents knowledge base bloat; ConKeeper has no dedup
6. **Historical scanning** — Recovers past learnings retroactively; ConKeeper only captures current session
7. **Multi-target sync** — Writes to CLAUDE.md, AGENTS.md, skill files simultaneously; ConKeeper writes only to its own memory files
8. **Same storage format** — Uses CLAUDE.md, which ConKeeper also relies on; potential for integration
9. **Low dependencies** — Python 3.6+, no database, no daemon; similar simplicity to ConKeeper
10. **Skill self-improvement** — Corrections made during skill use update the skill itself; genuinely novel

### Weaknesses / Concerns
1. **Narrow focus** — Only captures corrections and patterns; doesn't manage general project context
2. **No search** — No way to search across learned content
3. **No structured data model** — Learnings are appended to CLAUDE.md as bullet points; no graph, no relations
4. **Small community** — 660 stars; less battle-tested than claude-mem (26K) or memU (8.6K)
5. **Regex fragility** — Stage 1 relies on pattern matching that may miss nuanced corrections
6. **Queue management overhead** — Users must periodically run `/reflect` or learnings accumulate
7. **No session context** — Doesn't capture project state, architecture, or active work context
8. **Potential conflict with ConKeeper** — Both write to CLAUDE.md files; could create merge issues if used simultaneously

### Key Takeaways for ConKeeper

1. **Session retrospection is the #1 integration opportunity** — claude-reflect's correction capture + skill discovery could complement ConKeeper's session-handoff and memory-sync:
   - ConKeeper captures *what happened* (context, state, decisions)
   - claude-reflect captures *what was learned* (corrections, patterns)
   - Together they'd provide full session retrospection

2. **Correction detection is a net-new feature for ConKeeper** — The hybrid regex + semantic pipeline is well-proven (160 tests, 2.5.1 version). Could be adapted as a new ConKeeper hook or skill:
   - Add a `UserPromptSubmit` hook that detects corrections
   - Queue learnings for review during `/memory-sync`
   - Write approved learnings to ConKeeper's decisions/ directory

3. **Skill discovery from patterns** — ConKeeper could detect repeated session patterns:
   - Analyze memory-sync content across sessions for recurring themes
   - Suggest new skills when patterns repeat 3+ times
   - This turns ConKeeper into a self-improving system

4. **Semantic deduplication** — As ConKeeper's memory files grow, dedup becomes important:
   - Add a `--dedupe` flag to `/memory-sync`
   - Consolidate similar entries in progress.md and decisions/

5. **AGENTS.md cross-platform sync** — claude-reflect writes to AGENTS.md for multi-editor support:
   - ConKeeper already has multi-platform adapters but doesn't generate AGENTS.md
   - Adding AGENTS.md output would cover Codex, Cursor, Aider, Jules, Zed, Factory

6. **Confidence scoring** — ConKeeper could adopt confidence for decisions:
   - High-confidence decisions go directly to decisions/
   - Low-confidence items stay in active-context.md for review

7. **Decay tracking** — Time-based relevance decay for memory items:
   - Old decisions could be auto-archived or flagged for review
   - Active-context.md items could fade if not referenced in recent sessions

8. **Complementary, not competitive** — claude-reflect and ConKeeper serve different needs. The strongest path is integration, not competition:
   - ConKeeper provides the *memory infrastructure* (context, state, sync)
   - claude-reflect provides the *learning pipeline* (corrections, patterns)
   - ConKeeper could absorb claude-reflect's core ideas as a "learning" feature

---

## Cross-Cutting Analysis: All Three Projects

### Common Themes

| Theme | basic-memory | memU | claude-reflect | ConKeeper |
|-------|-------------|------|----------------|-----------|
| **Storage** | Markdown + SQLite | PostgreSQL + pgvector | CLAUDE.md files | Markdown files |
| **Search** | Full-text + metadata + filtered | RAG + LLM dual-mode | None | None |
| **Automation** | Manual (MCP tools) | Proactive (24/7) | Hybrid (auto-capture + manual review) | Automatic (hooks) |
| **Data model** | Entity-Observation-Relation | Resource-Item-Category | Flat bullet points | Freeform Markdown |
| **Human control** | Full (bi-directional editing) | Low (autonomous) | High (approval gate) | High (manual sync) |
| **Infrastructure** | Python + SQLite/Postgres | Python + Postgres + pgvector | Python 3.6 only | Shell + Markdown |
| **Platform** | Claude Desktop, VS Code | Framework (embed in agents) | Claude Code plugin | Claude Code plugin + 5 platforms |

### Patterns Reinforced by This Batch

1. **Search is non-negotiable** — basic-memory has 3 search modes; memU has dual RAG/LLM retrieval; even claude-reflect's `/reflect --scan-history` is a search operation. ConKeeper's zero search capability is now confirmed as the #1 gap across all 5 analyzed competitors.

2. **Structured data models enable richer features** — basic-memory's Entity-Observation-Relation and memU's Resource-Item-Category both enable features (graph traversal, auto-categorization) that flat Markdown can't support. ConKeeper may need at minimum a lightweight indexing layer.

3. **Human-in-the-loop is a design choice, not a limitation** — Both ConKeeper and claude-reflect prioritize human approval. This is a feature, especially for enterprise/security-conscious users. ConKeeper should market this explicitly.

4. **The learning gap is real** — claude-reflect captures *what was learned*; ConKeeper captures *what happened*. Neither alone provides full session retrospection. This is the strongest integration or feature opportunity.

5. **Dependency weight matters** — basic-memory (Python 3.12, SQLite/Postgres, Docker) and memU (Python 3.13, PostgreSQL, pgvector) require significant infrastructure. ConKeeper and claude-reflect (shell/Python 3.6) are radically simpler. Simplicity is a genuine competitive advantage for individual developers.
