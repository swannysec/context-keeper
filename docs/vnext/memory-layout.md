# Memory layout and manifest requirements

Status: intended design; no manifest implementation in this bootstrap.

The resolved project root retains familiar Markdown files: `product-context.md`, `active-context.md`, `progress.md`, `patterns.md`, `glossary.md`, `friction.md`, `decisions/`, and `sessions/`. Existing category and privacy conventions remain readable. Operational queues, `.last-sync`, and `.handoffs/` stay associated with that root; they are not automatically general knowledge. Global operating memory retains lightweight preferences, patterns and glossary. Do not mirror agent-native USER.md/MEMORY.md or session databases into these namespaces as competing authorities.

## Proposed manifest contract

A manifest, if introduced in Phase 3, records schema version, selected root/scope, optional Knowledge Workspace path, managed files/adapters and migration provenance. It contains configuration references, never credentials or a second copy of canonical knowledge. Exact filename, encoding and field names remain an implementation decision. Old roots without a manifest must remain readable; future unsupported schema versions produce a bounded diagnostic rather than destructive conversion.

Phase 2 uses only the fixed `.ai/memory` default and legacy `.claude/memory` fallback. Feature settings remain in the selected root. Custom roots and new configuration channels are out of scope unless reviewed and approved. Existing CWD/home anchoring, paths with spaces, absent/unwritable roots and symlink boundaries must retain clear semantics.

Local project/global memory retains the user's tracking/privacy choice. This repository's local memory is ignored. Engineering specifications are tracked here; personal memory is not automatically added to Git. Export tooling must use a reviewed allowlist and privacy checks rather than relying only on `.gitignore`.

Knowledge Workspace layout is separate and optional; see [workspaces](knowledge-workspaces.md). QMD collections and Hindsight bank/configuration are derived-service configuration references. Removing those services or the setup wrapper must leave all base Markdown usable.
