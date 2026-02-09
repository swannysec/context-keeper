# Phase 01: Competitive Research & Feature Matrix

This phase conducts deep competitive analysis of 7 memory/context projects to identify feature gaps and improvement opportunities for ConKeeper. The deliverable is a structured feature matrix document with impact scoring, saved to the Working folder for decision-making. This phase runs fully autonomously with no user input required.

## Tasks

- [x] Research claude-mem (primary competitor) by fetching its GitHub README and source:
  - Fetch https://github.com/thedotmack/claude-mem and extract: architecture, storage mechanism, features, installation method, platform support, and any unique capabilities
  - Clone or browse the repo structure to understand implementation depth
  - Note any features ConKeeper lacks (e.g., search, tagging, auto-categorization, memory types)
  - Save raw notes to `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/claude-mem-notes.md`
  - **Completed 2026-02-09:** Comprehensive analysis saved. Key findings: SQLite+Chroma storage, 5 MCP search tools, PostToolUse observation capture, web viewer UI, progressive disclosure pattern, fail-open hook architecture. 26K+ stars, v9.1.1, TypeScript. Primary gap for ConKeeper: search capability and observation granularity.

- [x] Research MemOS, OpenMemory, and mcp-memory-service by fetching their GitHub READMEs and source:
  - **MemOS** (https://github.com/MemTensor/MemOS): Focus on memory architecture patterns, API design, and any bot-focused features that could translate to coding assistants
  - **OpenMemory** (https://github.com/CaviraOSS/OpenMemory): Focus on memory storage, retrieval patterns, and multi-agent coordination
  - **mcp-memory-service** (https://github.com/doobidoo/mcp-memory-service): Focus on MCP integration patterns, tool definitions, and how memory is exposed via the Model Context Protocol
  - Save raw notes to `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/memos-openmemory-mcp-notes.md`
  - **Completed 2026-02-09:** Comprehensive analysis of all three saved. Key findings: MemOS (5K stars, Python, 17 MCP tools, 3-tier memory with LoRA+KV-cache, Neo4j+Qdrant required, Skill Memory feature); OpenMemory (3.2K stars, TypeScript, 5 MCP tools, 5-sector cognitive model with decay, SQLite default, waypoint graph, temporal facts); mcp-memory-service (1.3K stars, Python, 13+ MCP tools, dream-inspired consolidation, hybrid BM25+vector search, knowledge graph with typed relationships, SQLite-vec). Cross-cutting themes: search is table-stakes (ConKeeper has none), memory categorization is universal, decay/aging is standard, all use MCP tools while ConKeeper uses hooks/skills.

- [x] Research basic-memory, memU, and claude-reflect by fetching their GitHub READMEs and source:
  - **basic-memory** (https://github.com/basicmachines-co/basic-memory): Focus on simplicity patterns, what they chose to include/exclude, and any clever design decisions
  - **memU** (https://github.com/NevaMind-AI/memU): Focus on bot-oriented memory patterns that could adapt to coding assistant workflows
  - **claude-reflect** (https://github.com/BayramAnnakov/claude-reflect): Focus specifically on session retrospection, self-reflection patterns, and how this relates to ConKeeper's existing session-handoff skill. This is a net-new feature candidate.
  - Save raw notes to `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/basicmem-memu-reflect-notes.md`
  - **Completed 2026-02-09:** Comprehensive analysis of all three saved. Key findings: basic-memory (~2.5K stars, Python, AGPL-3.0, 17+ MCP tools, Entity-Observation-Relation knowledge graph, SQLite+Postgres, bi-directional Markdown editing, Obsidian-compatible, memory:// URI scheme, 3 search modes); memU (~8.6K stars, Python+Rust, Apache 2.0, proactive 24/7 memory with auto-categorization, PostgreSQL+pgvector, dual RAG/LLM retrieval, 92% Locomo benchmark, vision support, token cost reduction focus — but no Claude Code integration, heavy infra); claude-reflect (660 stars, Python 3.6+, MIT, hybrid regex+semantic correction capture, confidence scoring 0.60-0.95, human-in-the-loop approval gate, skill discovery from patterns, multi-target sync to CLAUDE.md/AGENTS.md/skill files, semantic dedup, historical scanning — closest to ConKeeper's philosophy). Cross-cutting: search confirmed as #1 gap (5/5 competitors have it), correction capture + skill discovery are the strongest net-new feature candidates for ConKeeper, and claude-reflect is the most natural integration partner (same storage format, same philosophy, complementary features).

- [x] Read ConKeeper's current capabilities to establish the baseline for comparison:
  - Read the full README.md at `/Users/swanny/zed/context-keeper/README.md`
  - Read the memory schema at `/Users/swanny/zed/context-keeper/core/memory/schema.md`
  - Read all 4 skill files: `skills/memory-init/SKILL.md`, `skills/memory-sync/SKILL.md`, `skills/memory-config/SKILL.md`, `skills/session-handoff/SKILL.md`
  - Read all 3 hook scripts: `hooks/session-start.sh`, `hooks/user-prompt-submit.sh`, `hooks/pre-compact.sh`
  - Read the hooks manifest: `hooks/hooks.json`
  - Compile a feature checklist of everything ConKeeper does today
  - Save to `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/conkeeper-baseline.md`
  - **Completed 2026-02-09:** Comprehensive baseline saved. Read 12 source files (README.md, schema.md, 4 SKILL.md files, 3 hook scripts, hooks.json, plugin.json, install.sh). ConKeeper v0.4.1: file-based Markdown storage with no database, 7-file memory schema (v1.0.0), 4 slash commands (init/sync/config/handoff), 3 hooks with tiered context escalation (60%→auto-sync, 80%→hard-block, 90%→compaction), 6-platform support (broadest in market), YAML config with 7 settings, 4 token budget presets, security features (symlink validation, session ID sanitization, path traversal prevention). Feature checklist compiled with 37 present capabilities and 22 identified gaps. Top gaps confirmed: no search (any kind), no auto observation capture, no MCP tools, no memory categorization, no decay/aging, no session retrospection.

- [x] Build the competitive feature matrix document:
  - Create `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/Feature-Matrix.md`
  - Use this structure:
    ```
    ---
    type: analysis
    title: ConKeeper Competitive Feature Matrix
    created: 2026-02-09
    tags:
      - competitive-analysis
      - feature-comparison
      - roadmap
    ---
    ```
  - **Section 1: Executive Summary** — 3-5 bullet overview of key findings
  - **Section 2: Feature Matrix Table** — Columns: Feature | ConKeeper | claude-mem | MemOS | OpenMemory | mcp-memory-service | basic-memory | memU | claude-reflect
    - Use checkmarks, partial indicators, and X marks
    - Group features by category: Storage, Retrieval, Context Management, Hooks/Automation, Multi-Platform, Search, Session Management, Reflection/Learning, Configuration, Security
  - **Section 3: Gap Analysis** — Features competitors have that ConKeeper lacks, sorted by estimated impact (High/Medium/Low) with a "Lift" column estimating implementation effort (Small/Medium/Large)
  - **Section 4: Unique Strengths** — Features where ConKeeper leads (multi-platform, pre-compaction hooks, etc.)
  - **Section 5: Recommended Improvements** — Top 5-10 features ranked by Impact/Lift ratio, with 1-2 sentence descriptions of what each would look like in ConKeeper
  - **Section 6: Net-New Feature Opportunity: Session Retrospection** — Dedicated analysis of claude-reflect patterns and how they'd integrate with ConKeeper's existing session-handoff skill
  - **Completed 2026-02-09:** Comprehensive feature matrix created with all 6 sections. Synthesized data from 4 research documents covering 7 competitors. Matrix contains 10 feature category tables (Storage, Search, Context Mgmt, Hooks, Multi-Platform, Session Mgmt, Reflection, Configuration, Security). Gap Analysis identifies 15 features sorted by impact. Recommended Improvements ranked by Impact/Lift ratio with top 10 actionable items. Section 6 details a 3-phase session retrospection integration plan with architecture fit analysis and effort estimates.

- [x] Review the completed Feature Matrix for quality and completeness:
  - Re-read `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/Feature-Matrix.md`
  - Verify all 7 competitors are represented in the matrix table
  - Verify the Gap Analysis is sorted by impact (High first)
  - Verify the Recommended Improvements section has concrete, actionable items
  - Verify the Lift estimates are realistic given ConKeeper's architecture (file-based, no database, shell hooks)
  - Fix any gaps, inconsistencies, or missing data
  - Ensure the document is immediately useful for decision-making without needing additional context
  - **Completed 2026-02-09:** Full review against 4 source research documents. All 9 matrix tables verified with all 7 competitors present. Gap Analysis confirmed sorted High→Medium→Low. All 10 Recommended Improvements verified as concrete and actionable. Lift estimates validated against ConKeeper's file-based/shell architecture. Three corrections applied: (1) Search gap count refined from "7/7" to "6/7" (claude-reflect has transcript scanning, not general memory search); (2) Executive summary updated to match; (3) Gap Analysis #1 Lift changed from "Medium" to "Small to Large" spectrum to match Recommended Improvement #1 and reflect the incremental implementation path.
