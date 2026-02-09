---
type: analysis
title: ConKeeper Competitive Feature Matrix
created: 2026-02-09
tags:
  - competitive-analysis
  - feature-comparison
  - roadmap
related:
  - "[[claude-mem-notes]]"
  - "[[memos-openmemory-mcp-notes]]"
  - "[[basicmem-memu-reflect-notes]]"
  - "[[conkeeper-baseline]]"
---

# ConKeeper Competitive Feature Matrix

## Section 1: Executive Summary

- **Search is the #1 gap:** All 7 competitors offer some form of search (full-text, semantic, hybrid, or pattern-based). ConKeeper has none. This is the single most impactful missing capability.
- **ConKeeper leads on platform breadth and simplicity:** 6-platform support (vs. 1-3 for most competitors) and zero-dependency file-based storage are genuine differentiators, especially for individual developers and enterprise users wary of heavy infrastructure.
- **Session retrospection is the strongest net-new opportunity:** claude-reflect's correction capture and skill discovery patterns complement ConKeeper's existing session-handoff/memory-sync perfectly — ConKeeper captures *what happened*, but not *what was learned*.
- **MCP tools are becoming table-stakes:** 5 of 7 competitors expose memory via MCP tools. ConKeeper's hook+skill approach is Claude Code-native but limits interoperability with non-Claude tooling.
- **ConKeeper's pre-compaction hooks are unique:** No competitor implements tiered context-window escalation (60% auto-sync → 80% hard-block → 90% compaction warning). This is a genuine innovation.

---

## Section 2: Feature Matrix Table

### Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Full support |
| 🟡 | Partial or limited support |
| ❌ | Not supported |
| — | Not applicable to this tool's architecture |

### Storage & Data Model

| Feature | ConKeeper | claude-mem | MemOS | OpenMemory | mcp-memory-service | basic-memory | memU | claude-reflect |
|---------|-----------|-----------|-------|------------|-------------------|-------------|------|----------------|
| Persistent memory across sessions | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| File-based (Markdown) storage | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Database-backed storage | ❌ | ✅ SQLite+Chroma | ✅ Neo4j+Qdrant | ✅ SQLite/Postgres | ✅ SQLite-vec | ✅ SQLite/Postgres | ✅ Postgres+pgvector | ❌ |
| Knowledge graph / entity relations | ❌ | ❌ | ✅ Neo4j | 🟡 Waypoint graph | ✅ Typed edges | ✅ Entity-Obs-Relation | 🟡 Cross-refs | ❌ |
| Memory categorization / typing | 🟡 By file type only | ✅ 5 obs. types | ✅ 3 tiers | ✅ 5 cognitive sectors | ✅ 5 base / 21 subtypes | ✅ 8 obs. categories | ✅ Auto-categories | ❌ |
| Memory schema / versioned format | ✅ v1.0.0, 7 files | ✅ 21+ migrations | ✅ Multi-layer | ✅ HMD v2 | ✅ Versioned SQLite | ✅ Entity-Obs-Relation | ✅ Resource-Item-Cat | ❌ |
| Token budget presets | ✅ 4 tiers | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| YAML config file | ✅ | 🟡 JSON settings | ❌ | ❌ | 🟡 100+ env vars | ❌ | ❌ | ❌ |
| Git-friendly (version-controllable) | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |

### Search & Retrieval

| Feature | ConKeeper | claude-mem | MemOS | OpenMemory | mcp-memory-service | basic-memory | memU | claude-reflect |
|---------|-----------|-----------|-------|------------|-------------------|-------------|------|----------------|
| Full-text keyword search | ❌ | ✅ FTS5 | ✅ | ✅ | ✅ BM25 | ✅ | ❌ | ❌ |
| Semantic / vector search | ❌ | ✅ Chroma | ✅ Qdrant | ✅ Cosine similarity | ✅ sqlite-vec | ❌ | ✅ RAG | ❌ |
| Hybrid search (keyword + semantic) | ❌ | ✅ | ❌ | 🟡 Composite scoring | ✅ BM25+vector | ❌ | ✅ RAG+LLM | ❌ |
| Tag/metadata filtering | ❌ | ✅ | ✅ | ✅ Sector filtering | ✅ Tag search | ✅ Metadata search | ✅ Category nav | ❌ |
| Date-range filtering | ❌ | ✅ | ❌ | ✅ | ✅ Natural language | ✅ | ❌ | ❌ |
| Progressive disclosure (tiered results) | ❌ | ✅ 3-layer | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Token cost per search result | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Historical session scanning | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ --scan-history |

### Context Management

| Feature | ConKeeper | claude-mem | MemOS | OpenMemory | mcp-memory-service | basic-memory | memU | claude-reflect |
|---------|-----------|-----------|-------|------------|-------------------|-------------|------|----------------|
| Auto context injection at session start | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ Proactive | ❌ |
| Pre-compaction hooks (tiered escalation) | ✅ Unique | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Pre-compact backup |
| Token-aware context building | ✅ Budget presets | ✅ TokenCalculator | ❌ | ❌ | ❌ | ❌ | ✅ Cost reduction | ❌ |
| AI-powered summarization | ❌ | ✅ Stop hook | ✅ | ❌ | ✅ Consolidation | ❌ | ✅ | ❌ |
| CLAUDE.md generation/management | ❌ | ✅ Folder-level | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Target file |
| Session handoff prompts | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Architecture Decision Records | ✅ Auto-numbered | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Active context tracking | ✅ | 🟡 Session-scoped | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Pattern / convention documentation | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Glossary / terminology tracking | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

### Hooks & Automation

| Feature | ConKeeper | claude-mem | MemOS | OpenMemory | mcp-memory-service | basic-memory | memU | claude-reflect |
|---------|-----------|-----------|-------|------------|-------------------|-------------|------|----------------|
| SessionStart hook | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | — | ✅ Reminder |
| UserPromptSubmit hook | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | — | ✅ Capture |
| PostToolUse observation capture | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ Proactive | ❌ |
| Stop / SessionEnd hook | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | — | ❌ |
| PreCompact hook | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Backup |
| Post-commit hook | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | — | ✅ Reflect prompt |
| Fail-open architecture | ✅ | ✅ | — | — | — | — | — | ✅ |
| Flag file dedup (TTL-based) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Auto-sync at threshold | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

### Multi-Platform Support

| Feature | ConKeeper | claude-mem | MemOS | OpenMemory | mcp-memory-service | basic-memory | memU | claude-reflect |
|---------|-----------|-----------|-------|------------|-------------------|-------------|------|----------------|
| Claude Code | ✅ Native plugin | ✅ Plugin | ❌ | ❌ | ✅ MCP config | ❌ | ❌ | ✅ Plugin |
| Claude Desktop | ❌ | ✅ | ✅ MCP | ✅ MCP | ✅ MCP | ✅ MCP | ❌ | ❌ |
| GitHub Copilot (VS Code) | ✅ Native skills | ❌ | ❌ | ✅ MCP | ✅ MCP | ✅ MCP | ❌ | ❌ |
| Cursor | ✅ Native skills | ✅ Hooks installer | ❌ | ✅ MCP | ✅ MCP | ❌ | ❌ | 🟡 AGENTS.md |
| Windsurf | ✅ Rules file | ❌ | ❌ | ✅ MCP | ✅ MCP | ❌ | ❌ | ❌ |
| Zed | ✅ AGENTS.md | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 AGENTS.md |
| OpenAI Codex | ✅ Native skills | ❌ | ❌ | ✅ MCP | ✅ MCP | ❌ | ❌ | 🟡 AGENTS.md |
| Web viewer / dashboard | ❌ | ✅ localhost:37777 | ✅ Dashboard | ✅ Dashboard | ✅ D3.js dashboard | ❌ | ✅ Cloud | ❌ |
| Interactive installer | ✅ | 🟡 Smart install | ❌ | ✅ One-click deploy | ✅ pip install | ❌ | ❌ | ✅ Marketplace |
| **Platform count** | **6** | **3** | **1-2** | **5-6** | **6+** | **2-3** | **1-2** | **3-4** |

### Session Management

| Feature | ConKeeper | claude-mem | MemOS | OpenMemory | mcp-memory-service | basic-memory | memU | claude-reflect |
|---------|-----------|-----------|-------|------------|-------------------|-------------|------|----------------|
| Session tracking | ✅ Sessions/ dir | ✅ Session model | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Queue tracking |
| Session handoff | ✅ Copy-paste prompt | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Session retrospection / reflection | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ /reflect |
| Correction/learning capture | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Hybrid regex+AI |
| Skill discovery from patterns | ❌ | ❌ | 🟡 Skill Memory | ❌ | ❌ | ❌ | ❌ | ✅ /reflect-skills |
| Cross-session learning | ❌ | ✅ Observation history | ❌ | ❌ | ❌ | ❌ | ✅ Continuous | ✅ --scan-history |

### Reflection & Learning

| Feature | ConKeeper | claude-mem | MemOS | OpenMemory | mcp-memory-service | basic-memory | memU | claude-reflect |
|---------|-----------|-----------|-------|------------|-------------------|-------------|------|----------------|
| Correction detection | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Regex + semantic |
| Confidence scoring | ❌ | ❌ | ❌ | ❌ | ✅ Quality scoring | ❌ | ❌ | ✅ 0.60-0.95 |
| Human approval gate | ✅ Manual sync | ❌ Automatic | ❌ | ❌ | ❌ | ✅ Bi-directional | ❌ | ✅ /reflect approval |
| Memory decay / aging | ❌ | ❌ | ✅ Archival | ✅ Exponential per-sector | ✅ Dream consolidation | ❌ | ❌ | 🟡 Queue decay |
| Semantic deduplication | ❌ | ❌ | ✅ NLI-based | ❌ | ✅ 0.85 threshold | ❌ | ❌ | ✅ /reflect --dedupe |
| Auto-categorization | ❌ | ✅ 5 obs. types | ✅ Multi-modal | ✅ 5 sectors | ✅ 21 subtypes | ✅ 8 categories | ✅ Auto-categories | ❌ |
| Privacy controls | 🟡 .gitignore guidance | ✅ `<private>` tags | ❌ | ✅ User partitioning | ❌ | ❌ | ❌ | ✅ Local-only |

### Configuration

| Feature | ConKeeper | claude-mem | MemOS | OpenMemory | mcp-memory-service | basic-memory | memU | claude-reflect |
|---------|-----------|-----------|-------|------------|-------------------|-------------|------|----------------|
| Per-project config | ✅ .memory-config.md | 🟡 Per-directory CLAUDE.md | ❌ | ❌ | ❌ | ✅ Multi-project | ❌ | ✅ Per-project targets |
| Token budget control | ✅ 4 presets | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Configurable thresholds | ✅ 2 thresholds | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Output style options | ✅ 3 modes | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Config CLI / command | ✅ /memory-config | ❌ | ✅ CLI | ✅ opm CLI | ✅ CLI | ❌ | ❌ | ❌ |
| Environment variable overrides | ❌ | ✅ | ✅ | ✅ | ✅ 100+ vars | ✅ | ✅ | ❌ |

### Security

| Feature | ConKeeper | claude-mem | MemOS | OpenMemory | mcp-memory-service | basic-memory | memU | claude-reflect |
|---------|-----------|-----------|-------|------------|-------------------|-------------|------|----------------|
| Symlink validation | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Path traversal prevention | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Session ID sanitization | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| System directory protection | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| CORS / XSS protection | — | ✅ | ❌ | ❌ | ✅ OAuth 2.1 | ❌ | ❌ | — |
| Prompt injection guidance | ✅ SECURITY.md | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Privacy tags / content exclusion | ❌ | ✅ `<private>` | ❌ | ✅ User partitions | ❌ | ❌ | ❌ | ❌ |
| Local-only (no external calls) | ✅ | ❌ Chroma worker | ❌ Server | ❌ Server | ❌ Server | ❌ SQLite process | ❌ API calls | ✅ |

---

## Section 3: Gap Analysis

Features competitors have that ConKeeper lacks, sorted by estimated impact.

| # | Feature Gap | Impact | Lift | Competitors With It | Notes |
|---|------------|--------|------|-------------------|-------|
| 1 | **Any form of search** (full-text, keyword, or semantic) | **High** | **Medium** | 7/7 (all competitors) | #1 gap. Even a simple `grep`-based skill would be transformative. Semantic search requires embedding infrastructure ConKeeper doesn't have. |
| 2 | **Correction/learning capture** from user feedback | **High** | **Medium** | 1/7 (claude-reflect) | Only claude-reflect does this, but it's the highest-value net-new feature. ConKeeper's hooks could detect corrections via regex in UserPromptSubmit. |
| 3 | **MCP tool exposure** for cross-tool interoperability | **High** | **Medium** | 5/7 (claude-mem, MemOS, OpenMemory, mcp-memory-service, basic-memory) | Would let non-Claude tools access ConKeeper memories. Requires building an MCP server (TypeScript or Python). |
| 4 | **Automatic observation capture** (PostToolUse) | **High** | **Small** | 2/7 (claude-mem, memU) | claude-mem captures every tool use. ConKeeper could add a lightweight PostToolUse hook that logs tool names + file paths to session files. |
| 5 | **Memory categorization** beyond file types | **Medium** | **Small** | 6/7 (all except claude-reflect) | Add observation categories (decision, pattern, bugfix, convention) to memory entries. Could be tag-based within existing Markdown files. |
| 6 | **Skill discovery** from repeating session patterns | **Medium** | **Medium** | 2/7 (MemOS Skill Memory, claude-reflect) | Analyze sessions/ directory for recurring themes. Suggest new skills when patterns appear 3+ times. |
| 7 | **Memory decay / aging** for stale content | **Medium** | **Medium** | 3/7 (MemOS, OpenMemory, mcp-memory-service) | File timestamps enable basic staleness detection. Active-context entries not referenced in N sessions could be flagged. |
| 8 | **Semantic deduplication** for growing memory | **Medium** | **Medium** | 3/7 (MemOS, mcp-memory-service, claude-reflect) | As memory files grow, duplicate entries waste tokens. Could add `--dedupe` to `/memory-sync`. |
| 9 | **Privacy tags** for content exclusion | **Medium** | **Small** | 2/7 (claude-mem, OpenMemory) | `<private>` tags to exclude sensitive content from memory sync. Simple regex check in memory-sync skill. |
| 10 | **AI-powered summarization** at session end | **Medium** | **Small** | 3/7 (claude-mem, mcp-memory-service, memU) | ConKeeper's `/memory-sync` already summarizes, but a Stop hook could auto-trigger it. |
| 11 | **Web viewer / dashboard** | **Low** | **Large** | 5/7 (claude-mem, MemOS, OpenMemory, mcp-memory-service, memU) | Nice-to-have but conflicts with ConKeeper's zero-dependency philosophy. Markdown files already viewable in any editor. |
| 12 | **Knowledge graph traversal** | **Low** | **Large** | 4/7 (MemOS, OpenMemory, mcp-memory-service, basic-memory) | ConKeeper uses `[[wiki-links]]` but has no traversal engine. Would require indexing infrastructure. |
| 13 | **Memory quality / confidence scoring** | **Low** | **Medium** | 2/7 (mcp-memory-service, claude-reflect) | Interesting for prioritization but premature for ConKeeper's current maturity. |
| 14 | **Document ingestion** (PDF, DOCX, etc.) | **Low** | **Large** | 3/7 (MemOS, OpenMemory, mcp-memory-service) | Outside ConKeeper's scope as a coding assistant memory system. |
| 15 | **Vision / image support** | **Low** | **Large** | 1/7 (memU) | Niche; not relevant to ConKeeper's core use case. |

---

## Section 4: Unique Strengths

Features where ConKeeper leads or is unique among all 8 tools analyzed.

### 1. Broadest Platform Support (6 platforms)
ConKeeper supports Claude Code, GitHub Copilot, OpenAI Codex, Cursor, Windsurf, and Zed — with platform-native integration for each (skills, rules files, AGENTS.md). Most competitors support 1-3 platforms. Only mcp-memory-service approaches similar breadth, and only via generic MCP config.

### 2. Pre-Compaction Tiered Escalation (Unique)
No competitor implements context-window-aware hooks with tiered escalation:
- 60%: auto-sync memory (invisible to user)
- 80%: hard-block until manual sync
- Pre-compact: advisory warning

This prevents context loss during compaction — a problem every other tool ignores.

### 3. Zero-Dependency Storage
Plain Markdown files with no database, no daemon, no vector store. This means:
- No install complexity beyond the plugin itself
- No background processes consuming resources
- Full git compatibility (diff, merge, blame)
- Works offline and in air-gapped environments
- Human-readable and editable with any text editor

### 4. Token Budget System (Unique)
Four configurable presets (economy ~2K, light ~3K, standard ~4K, detailed ~6K) with per-file token limits. No competitor offers this granularity of token management.

### 5. Session Handoff Prompts (Unique)
The `/session-handoff` command generates a complete, copy-paste-ready prompt for continuing work in a new session. No competitor provides explicit session continuation support.

### 6. Architecture Decision Records (Unique)
Auto-numbered ADRs with concurrency-safe timestamps. No other memory tool captures architectural decisions in a structured, retrievable format.

### 7. Security Posture
ConKeeper is the only tool with:
- Symlink validation (prevents escape attacks)
- Session ID sanitization
- Path traversal prevention
- System directory protection in the installer
- Documented prompt injection guidance (SECURITY.md)

### 8. Graceful Degradation
ConKeeper works without hooks (via CLAUDE.md instructions alone). No competitor degrades as gracefully when its automation layer is unavailable.

### 9. Human-in-the-Loop by Design
Memory sync requires explicit user action (or auto-sync with human review). This is a conscious design choice shared only with claude-reflect. Most competitors operate autonomously, which can lead to noisy or inaccurate memory accumulation.

---

## Section 5: Recommended Improvements

Ranked by Impact/Lift ratio (High impact + Small lift = top priority).

### 1. File-Based Memory Search Skill ⭐ Impact: High | Lift: Small
**What:** Add a `/memory-search` skill that performs `grep`-based keyword search across all memory files (global + project). Return matching lines with file context.
**Why:** Closes the #1 competitive gap with minimal infrastructure. Every competitor has search; even basic keyword matching would be a massive UX improvement. No database required — just recursive `grep` over `.claude/memory/`.

### 2. PostToolUse Observation Hook ⭐ Impact: High | Lift: Small
**What:** Add a lightweight `PostToolUse` hook that appends a one-line log entry (timestamp, tool name, file path) to the current session file in `sessions/`. No AI processing — just structured logging.
**Why:** Gives ConKeeper automatic session activity capture (currently only manual via `/memory-sync`). claude-mem's biggest advantage is its granular observation capture; even a minimal version closes this gap significantly.

### 3. Correction Detection in UserPromptSubmit Impact: High | Lift: Medium
**What:** Extend `user-prompt-submit.sh` with regex patterns to detect correction phrases ("no, use X instead", "actually...", "that's wrong") and append flagged items to a `corrections-queue.md` file for review during next `/memory-sync`.
**Why:** Brings claude-reflect's core innovation into ConKeeper without a separate plugin. Corrections are the highest-value learning signal. The hybrid regex approach has been validated by claude-reflect (160 tests, v2.5.1).

### 4. Memory Observation Categories Impact: Medium | Lift: Small
**What:** Add optional `[category]` tags to memory entries: `[decision]`, `[pattern]`, `[bugfix]`, `[convention]`, `[learning]`. The `/memory-sync` skill would suggest categories during sync. The `/memory-search` skill could filter by category.
**Why:** Enables structured retrieval without a database. Categories are inline Markdown tags — no schema change needed. 6/7 competitors have categorization.

### 5. Privacy Tags Impact: Medium | Lift: Small
**What:** Support `<private>` or `<!-- private -->` tags in memory files. The session-start hook and memory-sync skill would skip content wrapped in privacy tags when injecting context.
**Why:** Simple to implement (regex exclusion) and addresses a legitimate enterprise concern. claude-mem has this; it's a quick win.

### 6. Skill Discovery from Session Patterns Impact: Medium | Lift: Medium
**What:** Add a `/memory-discover` skill that analyzes `sessions/` files for recurring themes (e.g., "ran tests 5 times this week", "always checked linting before commit"). Suggest new skills or patterns when themes repeat 3+ times.
**Why:** Turns ConKeeper into a self-improving system. claude-reflect's `/reflect-skills` validates this concept. Would use ConKeeper's existing session data — no new capture needed.

### 7. Stop Hook for Auto-Summary Impact: Medium | Lift: Small
**What:** Add a `Stop` hook that auto-triggers a lightweight session summary append to `sessions/YYYY-MM-DD-*.md`. Uses the existing memory-sync logic in auto-sync mode.
**Why:** Currently users must remember to run `/memory-sync` or rely on threshold-based auto-sync. A Stop hook ensures every session gets at least a minimal summary. claude-mem does this.

### 8. Memory Staleness Detection Impact: Medium | Lift: Medium
**What:** During `/memory-sync`, check file modification timestamps on memory files. Flag entries in `active-context.md` that haven't been updated in N sessions (configurable). Suggest archival or removal.
**Why:** Memory grows without bound today. Basic staleness detection prevents token waste on outdated context. 3/7 competitors have decay/aging.

### 9. MCP Tool Exposure Impact: High | Lift: Large
**What:** Build a lightweight MCP server (TypeScript, stdio transport) that exposes ConKeeper's memory as 3-5 tools: `memory_search`, `memory_read`, `memory_list`, `memory_status`. Reads from the same `.claude/memory/` files.
**Why:** Would make ConKeeper interoperable with Claude Desktop, VS Code, and any MCP client. 5/7 competitors have this. Large lift because it's a new TypeScript service, but high strategic value.

### 10. Semantic Deduplication in Memory Sync Impact: Medium | Lift: Medium
**What:** During `/memory-sync`, compare new entries against existing content using simple string similarity (Levenshtein or token overlap). Flag duplicates for user review before writing.
**Why:** As memory files grow across sessions, duplication is inevitable. claude-reflect's `--dedupe` validates the need. Can start with simple string matching, upgrade to semantic later.

---

## Section 6: Net-New Feature Opportunity — Session Retrospection

### The Opportunity

claude-reflect (660 stars, MIT license, Python 3.6+) is the only competitor focused on **learning from sessions** rather than just storing session state. Its core innovation — detecting user corrections and discovering reusable patterns — directly complements ConKeeper's existing capabilities:

| Capability | ConKeeper Today | claude-reflect | Combined |
|-----------|----------------|----------------|----------|
| What happened this session | ✅ memory-sync captures context, decisions, progress | ❌ No session state | ✅ Full picture |
| What was learned | ❌ No correction detection | ✅ Regex + AI detection | ✅ Corrections → decisions/ |
| Reusable patterns | 🟡 Manual patterns.md | ✅ /reflect-skills auto-discovery | ✅ Auto-discovered → patterns.md |
| Cross-session continuity | ✅ session-handoff | ❌ No handoff | ✅ Handoff + accumulated learnings |
| Human approval | ✅ Manual sync | ✅ /reflect approval gate | ✅ Consistent philosophy |

### How It Would Work in ConKeeper

**Phase A: Correction Detection (UserPromptSubmit hook enhancement)**
1. Extend `user-prompt-submit.sh` with regex patterns for correction phrases
2. Detected corrections are appended to `.claude/memory/corrections-queue.md` with timestamp and raw text
3. No AI processing during the hook — just fast regex matching to avoid latency
4. Queue file is ephemeral; processed during next `/memory-sync`

**Phase B: Learning Integration (memory-sync skill enhancement)**
1. During `/memory-sync`, check for `corrections-queue.md`
2. Present queued corrections to user with suggested categorization
3. Approved corrections route to appropriate memory files:
   - Code conventions → `patterns.md`
   - Architecture choices → `decisions/ADR-NNN-*.md`
   - Terminology → `glossary.md`
   - General preferences → `product-context.md`
4. Rejected corrections are discarded (with optional "never flag this again" list)

**Phase C: Pattern Discovery (new `/memory-discover` skill)**
1. Analyze `sessions/` directory for recurring themes across multiple sessions
2. Cross-reference with `corrections-queue.md` history
3. When a pattern appears 3+ times, suggest adding it to `patterns.md` or creating a project-specific skill
4. Optional: suggest updates to `.memory-config.md` based on observed behavior

### Architecture Fit

This approach aligns with ConKeeper's design principles:
- **Files are sufficient:** Corrections queue is a Markdown file, not a database
- **Quiet by default:** Hook regex matching is silent; only surfaces during sync
- **Graceful degradation:** Works without the hook (user can manually note corrections)
- **User control:** All corrections require approval before persisting
- **Simple over complex:** Regex matching in bash, no AI in the hook path

### Implementation Estimate

| Phase | Effort | Dependencies | Risk |
|-------|--------|-------------|------|
| A: Correction Detection | ~2-3 days | Extend existing hook | Low — regex in bash is proven |
| B: Learning Integration | ~3-5 days | Extend existing skill | Low — follows sync pattern |
| C: Pattern Discovery | ~5-8 days | New skill + session analysis | Medium — pattern matching quality |

### Key Design Decisions

1. **Regex-first, not AI-first:** claude-reflect proves regex catches 70%+ of corrections. AI can be added later for semantic validation (Phase B already uses Claude's context for categorization).
2. **Queue, don't auto-apply:** Matches ConKeeper's human-in-the-loop philosophy. Prevents false positives from accumulating.
3. **Route to existing files:** No new schema changes. Corrections flow into the existing 7-file memory schema.
4. **No new dependencies:** Regex in bash (Phase A) and skill-based AI processing (Phase B) — no Python, no database.

### Differentiation vs. claude-reflect

If ConKeeper absorbs this capability, it would offer a **superset** of claude-reflect's value:
- claude-reflect captures corrections but not session context, progress, or architectural decisions
- ConKeeper with retrospection captures everything: context + corrections + patterns + decisions
- ConKeeper's multi-platform support means corrections captured in Claude Code would be available in Cursor, Copilot, etc.
- claude-reflect requires a separate plugin install; ConKeeper would have it built-in

---

*Generated 2026-02-09 from analysis of 7 competitors: claude-mem (26K stars), MemOS (5K), OpenMemory (3.2K), mcp-memory-service (1.3K), basic-memory (~2.5K), memU (~8.6K), claude-reflect (660). Source documents: [[claude-mem-notes]], [[memos-openmemory-mcp-notes]], [[basicmem-memu-reflect-notes]], [[conkeeper-baseline]].*
