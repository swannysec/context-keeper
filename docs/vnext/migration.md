# Explicit migration

Migration is a separate human-authorized operation, never a side effect of root discovery or agent startup. A legacy-only project remains legacy indefinitely without it.

## Required sequence

1. Resolve project/global roots and configuration; report both-path ambiguity. Inspect source/destination ownership, permissions, symlinks, active writers and privacy/tracking choices.
2. Preview the exact source, destination, file list, settings/adapter references to update, collisions and exclusions. With both directories present, do not propose an automatic merge; require a reviewed mapping or stop.
3. Make a coherent recoverable backup of the source. Preserve file contents, identity, applicable metadata and meaningful history. Stop or coordinate writers before moving operational queues/markers; do not invent state from stale hooks.
4. Stage the migration without overwriting unrelated destination files. Validate content hashes, config readability, links/IDs and privacy policy. Recheck source changes since preview; changed input invalidates the preview.
5. Explicitly apply the reviewed changes to root settings/instructions and adapters. Keep rollback material until restore has been exercised. Do not remove the source merely because the destination exists.
6. Verify init/read/sync/search/handoff and repeated invocation. Report what changed and how to roll back. Partial failure must leave a documented recoverable state.

Dry run is read-only. Preview cannot grant permission to publish/push backup data. Rerunning a completed migration must not duplicate content or reapply stale changes. Global migration requires explicit scope separate from project migration.

Rollback restores the previous root selection and coherent source snapshot without clobbering new edits made after migration. Concurrent divergent writes need human reconciliation, not last-writer-wins. Native `.claude`, `.codex`, `.agents`, `.pi`, `.zed`, `.hermes` state outside Context Keeper memory is out of migration scope.

Acceptance cases: legacy-only; both present; destination conflict; source changes after preview; interrupted apply; read-only destination; symlink escape; paths with spaces; rollback after a new edit; repeated migration; old adapter still running; no migration requested. Choose minimal mechanics in Phase 7; this specification does not authorize runtime implementation yet.
