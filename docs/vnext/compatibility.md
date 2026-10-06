# Compatibility contract

Status: intended vNext behavior. Current hardcoded legacy paths are described in [current behavior](current-behavior.md).

Project and global roots resolve independently in this order:

1. Explicit configured memory root.
2. Existing `.ai/memory/` (global: `~/.ai/memory/`).
3. Existing `.claude/memory/` (global: `~/.claude/memory/`).
4. Otherwise select `.ai/memory/`; create it only during an authorized initialization/write operation.

Read-only resolution/diagnostics must not create directories. Explicit configuration is authoritative even if the directory does not yet exist; invalid, inaccessible or unsafe configured roots produce a clear diagnostic rather than silently falling back. The exact configuration channel and relative-path anchoring need Phase 2 review: configuration cannot exist only inside the root it is needed to select. Retain existing per-root `.memory-config.md` for feature settings after resolution.

## Resolution acceptance matrix

| Explicit root | New exists | Legacy exists | Selected root | Required behavior |
|---|---|---|---|---|
| valid | any | any | explicit | Show configured choice; no implicit migration |
| absent | yes | no | new | No legacy directory creation |
| absent | no | yes | legacy | Existing projects require zero changes |
| absent | yes | yes | new | Surface ambiguity; never merge or delete legacy |
| absent | no | no | new target | Read-only: report absent; init: create |
| invalid/unsafe | any | any | none | Diagnose; do not hide error with fallback |

Apply the matrix independently to user and project scopes, including mixed legacy/new projects under configured cross-project search roots. Both directories must still be diagnosed if an explicit root selects one; report selection and ambiguity without changing either.

All readers/writers must use the same selected root: init, sync, search, config, reflection, insights, observations, correction queues, last-sync, ADR indexes and handoffs. Keep token budgets, privacy exclusions, category tags, graceful degradation and existing session semantics intact. No automatic content rewrite, filename rename or host-native memory migration.

Do not repurpose `.claude/`, `.codex/`, `.agents/`, `.pi/`, `.zed/`, `.hermes/`. Native skill placement is allowed in its documented namespace, but Context Keeper memory remains distinct. `.ai` is this project's chosen portable convention, not a globally reserved namespace. See [namespace verification](agent-namespaces.md).

Adding vNext must not require Obsidian/Hindsight/QMD/OpenShell/Hermes. Existing legacy installations remain supported until explicitly migrated. Changes to documented adapters must be tested through complete init/read/sync/search/handoff workflows rather than a host listing installed skills.
