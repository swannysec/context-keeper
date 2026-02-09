---
type: reference
title: ConKeeper Feature Design Decisions
created: 2026-02-09
tags:
  - design-decisions
  - feature-spec
  - brainstorm
related:
  - "[[Feature-Matrix]]"
  - "[[Implementation-Plan]]"
---

# ConKeeper Feature Design Decisions

Design decisions captured from brainstorm/interview session with the user. These decisions inform the Implementation Plan and Phase execution documents.

## Selected Features

All 5 recommended features from the competitive analysis **plus** the 3-phase Session Retrospection system:

1. File-Based Memory Search (`/memory-search`)
2. PostToolUse Observation Hook
3. Correction & Friction Detection (UserPromptSubmit enhancement)
4. Memory Observation Categories
5. Privacy Tags
6. Session Retrospection (`/memory-reflect`) — merged from session-retrospective skill + claude-reflect approaches

---

## Feature 1: File-Based Memory Search (`/memory-search`)

### Design Decisions

- **Scope:** Project memory (`.claude/memory/`) by default. `--global` flag adds `~/.claude/memory/`. Configurable.
- **Output format:** Agent-optimized structured output — results grouped by file with filename, matching section/entry, surrounding context, and category tags. Not raw grep-style line output.
- **Sessions:** Opt-in via `--sessions` flag, excluded by default (sessions can be large/noisy).
- **Category filtering:** `--category <name>` filtering supported from day one (functional once Feature 4 ships).
- **Search engine:** Auto-detect ripgrep (`rg`) at runtime, use silently when available. Fall back to `grep` otherwise.
- **Cross-platform:** Core search logic implemented as a standalone shell script. Claude Code skill invokes the script. Other platforms (Copilot, Cursor, Zed) can call the same script from their rules/AGENTS.md. Built cross-platform from day one — lift is small when architected this way.
- **Retrospective integration:** Same tool serves both quick lookups and pattern analysis across sessions via the `--sessions` flag.
- **Agent adoption:** Two mechanisms to encourage agent usage:
  - SessionStart hook injects: "Search memory with `/memory-search` before assuming context or re-investigating known problems"
  - CLAUDE.md guidance references search as first step for non-trivial tasks

---

## Feature 2: PostToolUse Observation Hook

### Design Decisions

- **What to capture per entry:**
  - Tool name
  - File path
  - Input summary (truncated — enough to capture bash commands, not full context text)
  - Action type (read/write/execute)
  - Success/failure status
  - Failure message (truncated to reasonable length)
- **Where to write:** Separate `session-observations.md` file alongside the session summary (not inline in the session file).
- **Noise control — two tiers:**
  - **Full entries** for Bash and external tools (the high-value observations)
  - **Stub entries** (timestamp, tool, type, path, status only) for native Read/Write/Edit tools
  - Configurable in `.memory-config.md`
- **Default behavior:** On by default. Opt-out via `.memory-config.md` setting.
- **Session file creation:** `SessionStart` hook creates the observations file at session start. Each PostToolUse hook append keeps it current in real-time. The curated session summary remains a `/memory-sync` product.
- **Retrospective integration:** Log format designed for machine consumption — structured enough that `/memory-reflect` and `/memory-discover` can parse, categorize, and find friction patterns directly.

---

## Feature 3: Correction & Friction Detection

### Design Decisions

- **Detection scope:** Both corrections ("no, use X instead", "actually, it should be...") AND friction signals ("that didn't work", "try again", "wrong approach", "let's revert"). Friction captures include surrounding context (reference to preceding assistant message) so the agent understands what went wrong.
- **Approach:** Blended synthesis of:
  - **session-retrospective skill** — structured AAR with evidence gathering, categorization, prioritization
  - **claude-reflect** — regex-first detection, confidence scoring, correction routing
  - The session-retrospective skill is folded fully into ConKeeper as `/memory-reflect` — no separate skill needed.
- **Queue format:** Each entry includes: timestamp, raw user text, detected category (correction vs friction), reference to preceding context. Designed for agent consumption, not human review.
- **Processing pipeline:** `/memory-sync` completes → silently triggers `/memory-reflect` → agent analyzes queued items with full retrospective rigor (evidence, patterns, prioritization) → proposes solutions to user for approval/denial/iteration.
- **Manual trigger:** User can invoke `/memory-reflect` independently at any time.
- **Sensitivity control:** Conservative default regex. Configurable aggressiveness in `.memory-config.md`:
  - `correction_sensitivity: low | medium | high`
  - Defaults to `low` (fewer false positives, higher precision)
- **Suppression:** `.correction-ignore` file for patterns the user never wants flagged. One pattern per line.
- **Agentic self-improvement loop:** The agent should identify repeated corrections/friction, understand the surrounding context, and propose actionable solutions — not just log them. The user approves, denies, or requests iteration on each recommendation.

---

## Feature 4: Memory Observation Categories

### Design Decisions

- **Tag format:** HTML comment inline tags: `<!-- @category: decision -->`. Rationale:
  - Invisible in rendered Markdown (doesn't clutter human-readable files)
  - Trivially parseable by both `rg` and `grep` (`rg '@category: decision'`)
  - Won't clash with `<private>` privacy tags (Feature 5)
  - `@` prefix provides namespace that won't collide with prose content
  - Also supports `<!-- @tag: some-tag -->` for freeform tags, differentiated from categories by prefix
- **Category sets — kept separate:**
  - **Memory categories** (for memory file entries): `decision`, `pattern`, `bugfix`, `convention`, `learning`
  - **Retrospective categories** (for `/memory-reflect` output): `efficiency`, `quality`, `ux`, `knowledge`, `architecture`
  - Both searchable via `/memory-search --category`
- **Auto-categorization:** Agent categorizes automatically during `/memory-sync`. Falls back to asking the user when confidence is low. No manual tagging required.
- **Retroactive tagging:** Offered as opt-in choice during `/memory-init`: "Tag existing memory entries? [y/n]"
- **Platform portability:** HTML comment format is universally parseable across all platforms and editors.

---

## Feature 5: Privacy Tags

### Design Decisions

- **Tag format:** `<private>...</private>` block wrapper. Visible to humans (intentionally — privacy should be obvious to the person editing the file). Easily parseable by agents.
- **Scope:** Block-level wrapping. Granular — only the specific sensitive content gets wrapped, not entire surrounding paragraphs or code sections. If only part of a section is sensitive, wrap just that part.
- **Enforcement points — privacy tags respected by:**
  - SessionStart hook (excludes private blocks from context injection)
  - `/memory-search` (omits private block contents from results)
  - `/memory-sync` (skips private content when analyzing/routing)
  - `/memory-reflect` (skips private content during retrospective analysis)
- **Default private content:** Only obviously sensitive patterns (API keys, credentials, tokens detected by regex). Corrections queue and observation logs are NOT private by default — they need to flow through the reflection pipeline.
- **File-level privacy:** Support `private: true` in YAML front matter to mark entire files. Expected to be rarely used but available.

---

## Feature 6: Session Retrospection (`/memory-reflect`)

### Design Decisions

- **What it is:** Merged capability combining the session-retrospective skill's 7-phase AAR workflow with claude-reflect's correction detection and routing. Folded into ConKeeper as a native feature — no separate plugin needed.
- **Trigger model:**
  - Auto-triggered silently after `/memory-sync` completes
  - Auto-triggered at session end (Stop hook)
  - Manually invokable via `/memory-reflect` at any time
  - Depth is proportional to session content — short sessions get lightweight analysis
- **Scope selection:** Agent recommends PROCESS vs PROJECT vs BOTH classification. Presents recommendation to user alongside other findings. User can adjust.
- **Research phase:** Retained from session-retrospective skill. Agent uses external web research only when it needs more context to validate a recommendation. Never guesses or assumes — always backs recommendations with real data/experiences.
- **Execution model:** Runs as a **sub-agent** so active work continues uninterrupted. Proposes changes for user approval rather than writing directly. Human-in-the-loop preserved.
- **Output destination:**
  - Dedicated retrospective file: `sessions/YYYY-MM-DD-retro.md`
  - Contains improvement log and improvement backlog as sections within the file
  - If Obsidian is configured as a sync target in `.memory-config.md`, retro file (including log/backlog) syncs there too
- **Shared core with Feature 3:** Both correction detection processing and session retrospection use a common analysis engine that reads observation logs, corrections queue, and session files. They share categorization, deduplication, and prioritization logic. They differ only in output:
  - Feature 3 path: Routes corrections/friction to memory files (`patterns.md`, `decisions/`, etc.)
  - Feature 6 path: Produces retrospective report with improvement log/backlog
  - Common methods prevent overlap; distinct output paths prevent duplication

---

## Architecture Notes

### Shared Analysis Core

Features 3 and 6 share a common analysis engine:

```
┌─────────────────────────────────────────┐
│           Shared Analysis Core           │
│  (reads observations, corrections,       │
│   session files; categorizes,            │
│   deduplicates, prioritizes)             │
└──────────┬───────────────┬──────────────┘
           │               │
    ┌──────▼──────┐ ┌──────▼──────┐
    │  Feature 3  │ │  Feature 6  │
    │  Output:    │ │  Output:    │
    │  Route to   │ │  Retro file │
    │  memory     │ │  + backlog  │
    │  files      │ │  + log      │
    └─────────────┘ └─────────────┘
```

### Dependency Order

Features should be implemented in this order (foundational first):

1. **Feature 4: Categories** — needed by search filtering and categorization throughout
2. **Feature 5: Privacy Tags** — enforcement needed before any new read/write paths
3. **Feature 1: Memory Search** — foundational tool used by subsequent features
4. **Feature 2: PostToolUse Hook** — produces data consumed by Features 3 and 6
5. **Feature 3: Correction Detection** — queue + shared analysis core
6. **Feature 6: Session Retrospection** — builds on everything above

### New Files Created

| File | Feature | Purpose |
|------|---------|---------|
| `skills/memory-search/` | 1 | Search skill + standalone shell script |
| `hooks/post-tool-use.sh` | 2 | Observation logging hook |
| `sessions/YYYY-MM-DD-observations.md` | 2 | Per-session observation log (auto-created) |
| `.claude/memory/corrections-queue.md` | 3 | Ephemeral correction/friction queue |
| `.correction-ignore` | 3 | Suppression patterns |
| `skills/memory-reflect/` | 6 | Retrospection skill |
| `sessions/YYYY-MM-DD-retro.md` | 6 | Per-session retrospective report |

### Modified Files

| File | Features | Changes |
|------|----------|---------|
| `hooks/hooks.json` | 2, 3, 6 | Add PostToolUse hook, Stop hook |
| `hooks/user-prompt-submit.sh` | 3 | Add correction/friction regex detection |
| `hooks/session-start.sh` | 1, 2 | Create observations file; inject search reminder |
| `skills/memory-sync/` | 3, 4, 6 | Auto-categorization, trigger reflect, privacy enforcement |
| `.memory-config.md` | 1-6 | New config options (correction_sensitivity, observation_hook, obsidian_sync_target, etc.) |
| `core/templates/` | 4, 5 | Updated templates with category/privacy tag examples |
| Platform adapters | 1 | Reference standalone search script |

---

*Captured 2026-02-09 from brainstorm session. Source: [[Feature-Matrix]] Section 5 and Section 6.*
