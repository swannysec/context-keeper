# Context Keeper vNext

Status: intended design, not implemented. Requirements approved in the bootstrap handoff on 2026-10-06; implementation plan awaits review. Baseline: v1.4.0, commit `564d419f0a1f3f38782ebf4d4cb5c04dd269d2f7`.

Context Keeper keeps project state and operating memory in portable Markdown, independent of the host agent. vNext first makes memory-root resolution consistent, preserving existing projects, then adds optional general knowledge and human-reviewed promotion.

## Specification map

- [Current behavior](current-behavior.md): inspected implementation and discrepancies.
- [Compatibility](compatibility.md) and [memory layout](memory-layout.md): deterministic roots, base files, configuration bootstrap and proposed manifest.
- [Knowledge Workspaces](knowledge-workspaces.md): optional durable general knowledge and Obsidian namespace.
- [Provenance and relations](provenance-and-relations.md): stable identity, evidence, approval, status and temporal context.
- [Promotion and reconciliation](promotion-and-reconciliation.md): candidate review and current-task conflict handling.
- [Migration](migration.md): explicit preview, backup, validation and rollback.
- [Implementation plan](implementation-plan.md): compatibility-first phases and acceptance gates.
- [References](references.md) and [agent namespaces](agent-namespaces.md): dated external checks and limits.
- [ADRs](decisions/ADR-001-portable-roots.md): architectural decisions and consequences.

## Component ownership

Context Keeper owns explicit project state and approved durable general knowledge. Obsidian exposes canonical Markdown to humans. Hermes owns native hot memory, sessions, compaction and its external-memory-provider lifecycle. QMD indexes source material and is rebuildable. Hindsight owns derived cognition and experiential retention; it may flag stale knowledge but does not approve changes.

The sibling Agent Memory Stack repository owns the [cross-component contract](../../../agent-memory-stack/docs/contract.md). Its setup/doctor/maintenance tooling exits after use. Context Keeper remains usable without that wrapper. The sibling [runtime architecture](../../../hermes-openshell/docs/architecture.md) owns Mac/OpenShell responsibilities. These sibling links are optional companion references; this repository's base requirements stand alone.

No new canonical database, runtime broker, mandatory graph service, or rewrite of host-native lifecycle is in scope. Language/package choice and exact configuration/manifest encoding are deferred until characterization; this documentation does not commit to a new implementation framework.
