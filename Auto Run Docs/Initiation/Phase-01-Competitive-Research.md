# Phase 01: Competitive Research & Feature Matrix

This phase conducts deep competitive analysis of 7 memory/context projects to identify feature gaps and improvement opportunities for ConKeeper. The deliverable is a structured feature matrix document with impact scoring, saved to the Working folder for decision-making. This phase runs fully autonomously with no user input required.

## Tasks

- [x] Research claude-mem (primary competitor) by fetching its GitHub README and source:
  - Fetch https://github.com/thedotmack/claude-mem and extract: architecture, storage mechanism, features, installation method, platform support, and any unique capabilities
  - Clone or browse the repo structure to understand implementation depth
  - Note any features ConKeeper lacks (e.g., search, tagging, auto-categorization, memory types)
  - Save raw notes to `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/claude-mem-notes.md`
  - **Completed 2026-02-09:** Comprehensive analysis saved. Key findings: SQLite+Chroma storage, 5 MCP search tools, PostToolUse observation capture, web viewer UI, progressive disclosure pattern, fail-open hook architecture. 26K+ stars, v9.1.1, TypeScript. Primary gap for ConKeeper: search capability and observation granularity.

- [ ] Research MemOS, OpenMemory, and mcp-memory-service by fetching their GitHub READMEs and source:
  - **MemOS** (https://github.com/MemTensor/MemOS): Focus on memory architecture patterns, API design, and any bot-focused features that could translate to coding assistants
  - **OpenMemory** (https://github.com/CaviraOSS/OpenMemory): Focus on memory storage, retrieval patterns, and multi-agent coordination
  - **mcp-memory-service** (https://github.com/doobidoo/mcp-memory-service): Focus on MCP integration patterns, tool definitions, and how memory is exposed via the Model Context Protocol
  - Save raw notes to `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/memos-openmemory-mcp-notes.md`

- [ ] Research basic-memory, memU, and claude-reflect by fetching their GitHub READMEs and source:
  - **basic-memory** (https://github.com/basicmachines-co/basic-memory): Focus on simplicity patterns, what they chose to include/exclude, and any clever design decisions
  - **memU** (https://github.com/NevaMind-AI/memU): Focus on bot-oriented memory patterns that could adapt to coding assistant workflows
  - **claude-reflect** (https://github.com/BayramAnnakov/claude-reflect): Focus specifically on session retrospection, self-reflection patterns, and how this relates to ConKeeper's existing session-handoff skill. This is a net-new feature candidate.
  - Save raw notes to `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/basicmem-memu-reflect-notes.md`

- [ ] Read ConKeeper's current capabilities to establish the baseline for comparison:
  - Read the full README.md at `/Users/swanny/zed/context-keeper/README.md`
  - Read the memory schema at `/Users/swanny/zed/context-keeper/core/memory/schema.md`
  - Read all 4 skill files: `skills/memory-init/SKILL.md`, `skills/memory-sync/SKILL.md`, `skills/memory-config/SKILL.md`, `skills/session-handoff/SKILL.md`
  - Read all 3 hook scripts: `hooks/session-start.sh`, `hooks/user-prompt-submit.sh`, `hooks/pre-compact.sh`
  - Read the hooks manifest: `hooks/hooks.json`
  - Compile a feature checklist of everything ConKeeper does today
  - Save to `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/conkeeper-baseline.md`

- [ ] Build the competitive feature matrix document:
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

- [ ] Review the completed Feature Matrix for quality and completeness:
  - Re-read `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/Feature-Matrix.md`
  - Verify all 7 competitors are represented in the matrix table
  - Verify the Gap Analysis is sorted by impact (High first)
  - Verify the Recommended Improvements section has concrete, actionable items
  - Verify the Lift estimates are realistic given ConKeeper's architecture (file-based, no database, shell hooks)
  - Fix any gaps, inconsistencies, or missing data
  - Ensure the document is immediately useful for decision-making without needing additional context
