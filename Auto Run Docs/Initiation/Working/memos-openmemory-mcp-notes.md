---
type: research
title: Competitive Research — MemOS, OpenMemory, mcp-memory-service
created: 2026-02-09
tags:
  - competitive-analysis
  - phase-01
  - memory-systems
related:
  - "[[claude-mem-notes]]"
  - "[[Feature-Matrix]]"
---

# Competitive Research: MemOS, OpenMemory, mcp-memory-service

## 1. MemOS (MemTensor/MemOS)

**Repository:** https://github.com/MemTensor/MemOS
**Stars:** 5,006 | **Forks:** 462 | **License:** Apache 2.0
**Language:** Python | **Version:** 2.0.4 (2026-01-30, "Stardust")
**Last Activity:** 2026-02-09 (today) | **Commits:** 965

### Architecture

MemOS is a full **memory operating system** for LLMs and AI agents — not a lightweight library. Python-based, FastAPI server, with 23 subdirectories in the source. Uses factory patterns throughout for swappable backends.

### Memory Model (Three-Tier)

MemOS implements a unique **three-layer memory hierarchy** inspired by neuroscience:

| Layer | Storage | Description |
|-------|---------|-------------|
| **Textual Memory** | Graph DB (Neo4j) + Vector DB (Qdrant) | Conversational/factual knowledge. Sub-types: tree-structured, preference, simple, general |
| **Parametric Memory** | LoRA adapters | Model-level memory encoded as weight modifications |
| **Activation Memory** | KV-cache (vLLM) | Working memory for active inference sessions |

### Memory Cube System

Core organizational unit:
- **Single Cube**: Isolated memory container per user/project/agent
- **Multi-Cube**: Composable cubes for controlled cross-boundary knowledge sharing
- CRUD operations through unified API
- Graph-structured internally (not just embeddings) — "inspectable and editable by design, not a black-box embedding store"

### Storage Requirements (Heavy)

| Required | Purpose |
|----------|---------|
| **Neo4j 5.26.4** | Graph database for relationships |
| **Qdrant 1.15.3** | Vector database for semantic search |

Optional: Milvus, Nebula Graph, PolarDB, Redis/RabbitMQ, MySQL, Alibaba OSS

### MCP Server (17 Tools)

Full MCP implementation via `api/mcp_serve.py`:

**Memory Operations:** search_memories, add_memory, get_memory, update_memory, delete_memory, delete_all_memories
**Cube Management:** create_cube, register_cube, unregister_cube, dump_cube, share_cube
**User & System:** chat, create_user, get_user_info, clear_chat_history, control_memory_scheduler

Transport: stdio (default), HTTP, SSE

### API Design

- REST API (FastAPI on port 8000)
- MCP Server (17 tools, 3 transports)
- CLI via `memos` command
- Python client library

### Key Features

- Three-tier memory (textual/parametric/activation)
- Graph-structured memory (Neo4j)
- Memory Cube isolation + composition
- Multi-modal memory (text, images, tool traces, personas)
- Memory-augmented chat
- Async scheduling (Redis Streams / RabbitMQ)
- Memory feedback/quality scoring
- NLI-based deduplication + MMR deduplication
- Memory archival (prevent redundancy)
- **Skill Memory** (new in v2.0.4) — persistent coding patterns, project conventions, cross-task reuse
- Deep search agent
- Document ingestion + parsing
- Reranking pipeline

### LLM Provider Support

OpenAI, DeepSeek, Qwen, Ollama, Hugging Face Transformers, vLLM

### Installation

- Docker Compose (recommended): Neo4j + Qdrant + MemOS API
- Manual via Poetry (Python >=3.10)
- Cloud hosted dashboard at memos-dashboard.openmem.net

### Unique Capabilities

1. **Three-tier memory** — only project with parametric (LoRA) + activation (KV-cache) layers
2. **Graph-structured, inspectable memory** — not a black-box embedding store
3. **Memory Cube composition** — isolation + controlled sharing
4. **Skill Memory** — persistent cross-task skill knowledge (directly relevant to coding assistants)
5. **NLI-based deduplication** — uses Natural Language Inference for conflict detection
6. **Memory Scheduler** — async background processing for production concurrency
7. **vLLM activation memory** — direct KV cache integration

### Relevance to ConKeeper

| Feature | Relevance |
|---------|-----------|
| Skill Memory | Store learned coding patterns, project conventions |
| Memory Cubes | Isolate per-project while sharing developer prefs |
| Graph structure | Inspectable memory aligns with ConKeeper's file-based philosophy |
| Deduplication | Prevent redundant context entries |
| Archival | Age out stale context |

### Limitations for ConKeeper Context

- **Heavy infrastructure** (Neo4j + Qdrant minimum) — overkill for individual devs
- No file-based or SQLite mode
- Server-oriented, not local-first
- Chinese ecosystem orientation (Alibaba OSS, PolarDB, Qwen, DingDing)

---

## 2. OpenMemory (CaviraOSS/OpenMemory)

**Repository:** https://github.com/CaviraOSS/OpenMemory
**Stars:** 3,246 | **Forks:** 372 | **License:** Apache 2.0
**Language:** TypeScript | **Version:** 1.2.3 stable / 1.3.0 beta
**Last Push:** 2026-01-27 | **Commits:** ~254
**Tagline:** "Local persistent memory store for LLM applications including Claude Desktop, GitHub Copilot, Codex, Antigravity, etc."

### Architecture

Implements **Hierarchical Memory Decomposition (HMD) v2** with:
- REST API Server (port 8080)
- HSG Memory Engine (Hierarchical Storage Graph)
- Pluggable embedding processor (OpenAI, Gemini, AWS Bedrock, Ollama, synthetic/free)
- SQLite (default) or PostgreSQL
- Web Dashboard (port 3000)
- MCP Server

### Five-Sector Cognitive Memory Model

Inspired by cognitive science, each sector has its own decay rate:

| Sector | Decay Lambda | Purpose |
|--------|-------------|---------|
| **Episodic** | 0.015 | Events and experiences |
| **Semantic** | 0.005 | Facts and knowledge |
| **Procedural** | 0.008 | How-to and processes |
| **Emotional** | 0.020 | Feelings and sentiments |
| **Reflective** | 0.001 | Meta-cognition and insights |

### Storage

- **SQLite** (default, zero-config) or **PostgreSQL**
- Tables: `memories`, `vectors`, `waypoints`, `embed_logs`
- Optional: Valkey (vector storage), Weaviate
- Chunking: 512-token chunks with 50-token overlap, mean pooling aggregation

### Retrieval — Multi-Signal Composite Scoring

```
Score = 0.6 × similarity + 0.2 × salience + 0.1 × recency + 0.1 × waypoint
```

- Cosine similarity search
- **Waypoint graph expansion** — traverses associative links between memories
- Reinforcement: salience boost + waypoint weight increase on retrieval
- Exponential decay: `salience × e^(-decay_lambda × days)`, runs every 24h
- Waypoint pruning: removes weights < 0.05 weekly

### Temporal Facts System

Subject-predicate-object triples with `valid_from`/`valid_to` windows:
- Point-in-time historical queries
- Automatic invalidation of outdated facts

### MCP Server (5 Tools)

| Tool | Purpose |
|------|---------|
| `openmemory_store` | Persist content to memory and/or temporal facts |
| `openmemory_query` | Semantic search or structured fact patterns |
| `openmemory_list` | Browse recent memories with sector filtering |
| `openmemory_get` | Fetch individual memory by ID |
| `openmemory_reinforce` | Boost memory salience scores |

### REST API

`/memory/add`, `/memory/search`, `/memory/query`, `/memory/delete`, `/memory/ingest`, `/memory/ingest/url`, `/health`, `/sectors`, LangGraph endpoints (`/lgm/store`, `/lgm/retrieve`, `/lgm/context`)

### Key Features

- Five-sector cognitive memory model with decay
- Waypoint graph (associative linking that evolves with usage)
- Composite scoring (4 signals)
- Temporal knowledge graph with validity windows
- Document ingestion (text, PDF, DOCX, HTML, audio via Whisper, video via FFmpeg)
- Multiple embedding providers (OpenAI, Gemini, Bedrock, Ollama, **free synthetic/hash-based**)
- User-partitioned memory isolation
- LangGraph integration (node-to-sector mapping)
- Python SDK + OpenAI wrapper + LangChain integration
- Node.js/TypeScript SDK
- VS Code extension
- Web dashboard
- CLI tool (`opm`)
- Data connectors (GitHub, Notion, Google Drive/Sheets/Slides, OneDrive, Web Crawler)
- Migration tools (import from Mem0, Zep, Supermemory)
- One-click cloud deploy (Railway, Render, Vercel)

### Platform Support

Claude Desktop, Cursor, Windsurf, GitHub Copilot, OpenAI Codex, Antigravity (via MCP)

### Unique Capabilities

1. **Five-sector cognitive model** — biologically-inspired memory classification
2. **Waypoint graph** — emergent association network that strengthens/decays with use
3. **Composite scoring (4 signals)** — beyond simple cosine similarity
4. **Adaptive exponential decay** — sector-specific rates
5. **Temporal facts with validity windows** — point-in-time queries
6. **Free synthetic embeddings** — hash-based, no API key needed
7. **LangGraph native integration** — maps cognitive nodes to memory sectors
8. **Competitor migration tools** — import from Mem0, Zep, Supermemory

### Relevance to ConKeeper

| Feature | Relevance |
|---------|-----------|
| Cognitive sectors | Could inform memory categorization beyond flat files |
| Decay model | Context aging is relevant — stale context degrades usefulness |
| Waypoint graph | Associative linking could improve memory retrieval |
| Temporal facts | Useful for tracking evolving project decisions |
| Free embeddings | Low-barrier search without API costs |
| Migration tools | Shows maturity in ecosystem thinking |

### Limitations for ConKeeper Context

- Requires server process (not pure file-based)
- More complex than ConKeeper's philosophy warrants for v1
- Decay model requires background process
- Primary maintainer accounts for 55% of commits (bus factor risk)

---

## 3. mcp-memory-service (doobidoo/mcp-memory-service)

**Repository:** https://github.com/doobidoo/mcp-memory-service
**Stars:** 1,290 | **Forks:** 189 | **License:** Apache 2.0
**Language:** Python | **Version:** 10.10.0 (2026-02-08)
**Last Activity:** 2026-02-09 | **Commits:** 2,007
**Author:** Heinrich Krupp

### Architecture

Python-based MCP server built on **FastMCP** framework. Layered design:
- `server/` — Server runtime and lifecycle
- `storage/` — Pluggable backends (SQLite-vec, Cloudflare, Hybrid, Graph)
- `embeddings/` — ONNX local + external API embedding
- `consolidation/` — Dream-inspired memory consolidation engine
- `ingestion/` — Document pipelines (PDF, TXT, MD, JSON)
- `web/` — Dashboard with D3.js knowledge graph visualization
- `quality/` — Memory quality scoring and feedback
- `graph/` — Knowledge graph operations
- `sync/` — Cloud synchronization
- `backup/` — Automated backup
- `discovery/` — mDNS service discovery

### Storage (Three Backends)

**a) SQLite-vec (local)**
- `sqlite-vec` extension with `vec0` virtual tables
- FLOAT[384] vectors, cosine distance
- FTS5 full-text index (trigram tokenization, BM25)
- ~5ms read latency
- Semantic dedup (0.85 threshold within 24h)
- Soft deletion with 30-day tombstone purge

**b) Cloudflare (cloud)**
- D1 (database) + Vectorize (vectors) + R2 (large content)
- Network-dependent latency

**c) Hybrid (default, recommended)**
- SQLite-vec primary (~5ms local reads)
- Cloudflare secondary (background sync, 300s interval)
- Drift detection (hourly)
- Fallback on secondary failure

**d) Graph Layer**
- SQLite-based directed edges
- Relationship types: causes, fixes, supports, related, contradicts, follows
- BFS traversal via recursive CTEs
- Modes: memories_only, dual_write (default), graph_only

### MCP Tools (13+ Tools)

| Tool | Purpose |
|------|---------|
| **store_memory / memory_store** | Store with tags, type, metadata |
| **retrieve_memory / memory_search** | Semantic/exact/hybrid search |
| **search_by_tag** | Tag-based filtering |
| **delete_memory / memory_delete** | Remove by hash, tags, or time (supports dry_run) |
| **memory_update** | Modify metadata without re-embedding |
| **list_memories / memory_list** | Paginated browsing |
| **check_database_health / memory_health** | Database stats and status |
| **get_cache_stats / memory_stats** | Performance metrics |
| **memory_consolidate** | Dream-inspired optimization (daily/weekly/monthly/quarterly/yearly) |
| **memory_cleanup** | Deduplication |
| **memory_ingest** | Batch document import |
| **memory_quality** | Rate and analyze memory quality |
| **memory_graph** | Knowledge graph traversal |

Memory types: observation, decision, learning, error, pattern (5 base types, 21 subtypes)

### Search Modes

1. **Vector Similarity**: ONNX/SentenceTransformers → 384-dim embeddings → KNN cosine distance
2. **BM25 Keyword**: FTS5 trigram tokenization, rank normalization
3. **Hybrid (default since v10.8.0)**: Parallel execution, weighted fusion `(keyword × 0.3) + (semantic × 0.7)`, optional quality boost

### Dream-Inspired Consolidation

Novel feature mimicking human sleep-cycle memory processing:
- Exponential decay scoring
- Semantic clustering (DBSCAN, hierarchical, simple)
- Semantic compression
- Controlled forgetting with archival
- Creative association discovery
- Scheduled horizons: daily, weekly, monthly, quarterly, yearly

### Key Features

- Hybrid BM25 + vector search
- Knowledge graph with typed relationships
- Dream-inspired memory consolidation
- AI-powered quality scoring (ONNX, Groq, Gemini)
- Quality-boosted search
- Document ingestion (PDF, TXT, MD, JSON + LlamaParse OCR)
- Web dashboard with D3.js graph visualization (8 tabs)
- OAuth 2.1 + API key auth + HTTPS
- Automated backups (hourly/daily/weekly)
- mDNS service discovery
- Natural language time queries
- Semantic deduplication
- Soft deletion + tombstone management
- 100+ environment variables for configuration
- Interoperable with SHODH Unified Memory API spec

### Platform Support

**AI Clients (13+):** Claude Desktop, Claude Code, VS Code, Cursor, Windsurf, ChatGPT, LM Studio, plus additional MCP-compatible clients
**OS:** macOS, Windows, Linux
**Python:** 3.10-3.14
**Embedding Backends:** External API (vLLM/Ollama/OpenAI), ONNX Runtime, SentenceTransformers, SHA-256 hash fallback

### Installation

```bash
pip install mcp-memory-service
python -m mcp_memory_service.scripts.installation.install --quick
```

Extras: `[ml]`, `[sqlite]`, `[full]`

### Unique Capabilities

1. **Dream-inspired consolidation** — decay, clustering, compression, controlled forgetting, creative associations
2. **Knowledge graph with typed relationships** — causes, fixes, supports, contradicts, follows
3. **Hybrid BM25 + vector search** — combined keyword + semantic
4. **Quality scoring system** — AI-powered with retention policies
5. **Multi-backend hybrid storage** — local SQLite + cloud Cloudflare sync
6. **Massive configuration surface** — 100+ env vars
7. **Web dashboard with D3.js graph** — 8-tab management interface
8. **Document ingestion pipeline** — PDF/TXT/MD/JSON with LlamaParse

### Relevance to ConKeeper

| Feature | Relevance |
|---------|-----------|
| Hybrid search | Semantic + keyword search for memory files |
| Quality scoring | Could inform memory pruning/prioritization |
| Consolidation | "Dream" pattern for aging/merging memories |
| Knowledge graph | Relationships between memory entries |
| Typed memory categories | 21 subtypes inform structured note-taking |
| Natural language time queries | User-friendly temporal access |
| Backup automation | Important for file-based systems |

### Limitations for ConKeeper Context

- Heavy dependencies (24 core deps including PyTorch, sentence-transformers)
- Requires running server process
- Configuration complexity (100+ env vars) vs ConKeeper's simplicity
- Over-engineered for file-based, shell-hook architecture
- Extremely rapid versioning (v10.10.0 in 13 months) suggests instability risk

---

## Cross-Cutting Comparison

| Dimension | MemOS | OpenMemory | mcp-memory-service |
|-----------|-------|------------|-------------------|
| **Stars** | 5,006 | 3,246 | 1,290 |
| **Language** | Python | TypeScript | Python |
| **Storage** | Neo4j + Qdrant | SQLite/PostgreSQL | SQLite-vec + Cloudflare |
| **MCP Tools** | 17 | 5 | 13+ |
| **Search** | Semantic + reranking | Composite (4 signals) | Hybrid BM25 + vector |
| **Memory Types** | 3 tiers (textual/parametric/activation) | 5 cognitive sectors | 5 base / 21 subtypes |
| **Decay/Aging** | Archival mechanism | Exponential decay per sector | Dream-inspired consolidation |
| **Graph** | Neo4j native | Waypoint associative graph | SQLite-based typed edges |
| **Infrastructure** | Heavy (Neo4j+Qdrant) | Light (SQLite default) | Medium (SQLite-vec + optional cloud) |
| **Local-first** | No (server required) | Partial (SQLite but needs server) | Partial (local SQLite, server process) |
| **Quality/Feedback** | Memory feedback module | Salience reinforcement | AI-powered quality scoring |
| **Unique Hook** | Skill Memory, LoRA | Cognitive sectors, temporal facts | Dream consolidation, typed relationships |

### Key Themes for ConKeeper

1. **Search is table-stakes** — All three provide semantic search. ConKeeper has none.
2. **Memory categorization** — All classify memories by type. ConKeeper uses flat files.
3. **Decay/aging** — All address stale memory. ConKeeper's pre-compaction hooks are adjacent but different.
4. **Graph relationships** — All support some form of memory linking. ConKeeper has wiki-links but no traversal.
5. **Quality/feedback** — Emerging pattern for memory curation. ConKeeper lacks this.
6. **MCP integration** — All expose tools via MCP. ConKeeper uses hooks/skills (Claude Code-specific).
