# Compatibility contract

Status: Phase 2 fixed-root contract. The v1.4 baseline is described in [current behavior](current-behavior.md).

Project and global roots resolve independently in this order:

1. Existing `.ai/memory/` (global: `~/.ai/memory/`).
2. Existing `.claude/memory/` (global: `~/.claude/memory/`).
3. Otherwise select `.ai/memory/`; create it only during an authorized initialization/write operation.

Read-only resolution/diagnostics must not create directories. Invalid, inaccessible or unsafe selected roots produce a clear diagnostic rather than silently falling back. Retain existing per-root `.memory-config.md` for feature settings after resolution. Custom roots and new root-configuration channels are out of scope, per the user's scope correction on 2026-10-06; any future addition requires review and approval.

## Resolution acceptance matrix

| New exists | Legacy exists | Selected root | Required behavior |
|---|---|---|---|
| yes | no | new | No legacy directory creation |
| no | yes | legacy | Existing projects require zero changes |
| yes | yes | new | Surface ambiguity; never merge or delete legacy |
| no | no | new target | Read-only: report absent; init: create |
| selected path invalid/unsafe | any | none | Diagnose; do not hide error with fallback |

Apply the matrix independently to user and project scopes, including mixed legacy/new projects under configured cross-project search parents. Run from the project root, as in the existing workflows; JSON hook `cwd` supplies that scope when present. Global selection is anchored to the user's home directory. Selection does not change either root.

All readers/writers must use the same selected root: init, sync, search, config, reflection, insights, observations, correction queues, last-sync, ADR indexes and handoffs. Keep token budgets, privacy exclusions, category tags, graceful degradation and existing session semantics intact. No automatic content rewrite, filename rename or host-native memory migration.

Do not repurpose `.claude/`, `.codex/`, `.agents/`, `.pi/`, `.zed/`, `.hermes/`. Native skill placement is allowed in its documented namespace, but Context Keeper memory remains distinct. `.ai` is this project's chosen portable convention, not a globally reserved namespace. See [namespace verification](agent-namespaces.md).

Adding vNext must not require Obsidian/Hindsight/QMD/OpenShell/Hermes. Existing legacy installations remain supported until explicitly migrated. Changes to documented adapters must be tested through complete init/read/sync/search/handoff workflows rather than a host listing installed skills.

Portable instructions use `AGENTS.md` as the primary entry point and `CLAUDE.md` as a backward-compatible fallback for hosts that need it. Adapter work must preserve existing user instructions and native memory, keep both instruction surfaces consistent, and verify host-specific precedence rather than assuming every loader behaves identically. This is an acceptance requirement; Phase 1 does not implement or certify the fallback.
