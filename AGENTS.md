# Context Keeper engineering guidance

Context Keeper is a lightweight Markdown memory layer for multiple agents. The executable code defines current behavior; vNext specifications identify later-phase work separately.

Read [vNext overview](docs/vnext/overview.md), [current behavior](docs/vnext/current-behavior.md), [compatibility](docs/vnext/compatibility.md), and [implementation plan](docs/vnext/implementation-plan.md) before implementation. Read the focused specifications linked there for the phase at hand. [References](docs/vnext/references.md) distinguish upstream documentation from runtime verification.

## Invariants

- New default: `.ai/memory/` and `~/.ai/memory/`; existing legacy-only projects remain on `.claude/memory/` until explicit migration. Both roots means prefer `.ai`, warn, and never silently merge. Custom-root configuration is out of scope.
- Portable Context Keeper state must not appropriate vendor-native memory, skills, sessions, or compaction. Adapter instructions may live in native skill directories; memory does not move there.
- Base use requires no Obsidian, QMD, Hindsight, OpenShell, or Hermes. Optional Knowledge Workspaces are additive.
- Canonical explicit knowledge is portable Markdown. QMD is derived retrieval; Hindsight is derived cognition, including experiential memory. Hindsight inference cannot silently replace canonical state.
- Proactively queue durable-memory candidates, but authoritative promotion requires human review. Pending/deferred proposals are non-canonical and excluded from canonical ingestion.
- Reconcile through scope, status, authority, temporal validity, and provenance. Resolve once per task; reopen only on materially new evidence. Preserve meaningful history.
- Context Keeper integrates through files, instructions, and native skills. Do not introduce a memory-provider daemon, conflict database, or wrapper runtime dependency.

## Execution and verification

The compatibility-first plan must be reviewed before broad implementation. Start with Phase 1 characterization. Record baseline failures, then add behavior tests before changing root resolution. Cover every hook, tool, command, skill, platform copy, installer, config reader, and cross-project discovery path. Do not certify integrations from skill discovery alone; run the actual workflow in each claimed host.

Use Bash 3.2 and BSD-compatible commands on macOS. Preserve privacy and symlink protections. Do not write user/global memory as part of development without explicit authorization. `.claude/memory/` in this repo is ignored local state; canonical engineering specs belong in `docs/vnext/`. Keep local memory and credentials out of PRs.

Use bounded Luna High research agents when available for external verification. Capture links, date, revision, conclusions and limits, not copied upstream documentation. Do not claim source research is an empirical test.

Use a feature branch, conventional commits, and a PR. Preserve unrelated local changes. Update README/docs for changed behavior; avoid adjacent cleanup. Every phase ends with its required checks and an honest status update to the plan.

Do not introduce new requirements or configuration mechanisms without the user's review and approval. Keep tests proportional to the change; use focused behavior coverage and the existing regression suites rather than elaborate new verification infrastructure.
