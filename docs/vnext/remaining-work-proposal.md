# Integrated proposal for remaining vNext work

Date: 2026-10-06. Status: proposed for user review; implementation is not authorized by this document. Baseline: released v1.5.0. This proposal condenses original Phases 3–8 into two implementation chunks. It carries forward the existing specifications and identifies recommended choices below; approval would settle those choices without requiring a separate design round for each former phase.

## Outcome and scope

Keep ordinary project memory lightweight and backward compatible. Add an optional place for approved durable knowledge, a practical human review workflow, and deliberate migration. Agents use the same files and instructions through AGENTS.md primarily and CLAUDE.md where needed. Preserve each host's native memory, skills, sessions and lifecycle.

No custom project/global memory roots, automatic migration, graph database, conflict database, daemon, mandatory Obsidian/service, automatic external imports, or runtime wrapper dependency. The fixed `.ai/memory` / `.claude/memory` selection from v1.5.0 remains unchanged. Do not rewrite existing notes simply to adopt metadata.

The existing [workspace](knowledge-workspaces.md), [metadata](provenance-and-relations.md), [promotion](promotion-and-reconciliation.md), [migration](migration.md), and [compatibility](compatibility.md) requirements remain the source constraints. The old phase numbering remains useful for tracing coverage, rather than dictating six separate PRs.

## Decisions to approve together

These are recommendations, not previously approved implementation details. Approve this table as a whole or identify rows to change.

| Decision | Recommended choice | Reason and boundary |
|---|---|---|
| Manifest scope | One JSON manifest at `<workspace>/context-keeper/_system/manifest.json`, initially only `schema_version: 1`. No manifest requirement for project/global operating memory. | Avoid duplicating root selection, existing feature config, note contents, and adapter inventories. Missing manifests on ordinary memory remain normal. Creating or adopting a managed workspace is an explicit operation. |
| Workspace configuration | Add optional `knowledge_workspace` to existing `.memory-config.md`: an absolute directory path, or explicit `false` to disable it. Project setting overrides global; absent project setting inherits global; absent everywhere disables the feature. Always append `context-keeper/` to that directory. | Works with an Obsidian vault or ordinary directory. This configures the separately specified optional workspace, not a custom operating-memory root. No path guessing, shell expansion, environment override, or second config file. |
| Notes and identity | YAML frontmatter in newly managed knowledge/proposal Markdown files; UUIDs for stable identity; readable typed wikilinks in a Relations section. | Existing plain Markdown stays readable. UUIDs do not change on rename or approval. Keep sources and evidence readable in the note body; do not require a graph index. |
| Review storage | One Markdown file per proposal. Use the configured workspace's `proposals/` when reachable; otherwise the selected project root's `proposals/`. | No central queue database or new global writes. If a workspace is unreachable, pending material is retained locally; approval cannot silently write somewhere else. Moving a local proposal into a workspace preserves identity and requires the review workflow. |
| Canonical eligibility | Only a valid, explicitly approved, `current` managed note in `knowledge/` or `projects/` is eligible for ordinary workspace retrieval/export. | Directory location alone cannot confer approval. Pending, deferred, rejected, disputed, deprecated, superseded, missing-metadata and malformed records are excluded; historical retrieval is explicit. Existing project-memory search remains compatible. |
| Runtime dependencies | Existing base hooks/tools keep their dependencies. Optional structured workspace helpers use Python 3 and PyYAML for safe YAML parsing, with no other new library. | Avoid a bespoke YAML parser or expanding fragile shell parsing. Missing optional dependencies produce a clear diagnostic while ordinary memory continues working. No automatic system-wide installation. This dependency choice requires approval. |
| Migration strategy | Explicit project-scoped copy, validate, then switch by creating the new fixed root; retain the legacy source and a backup. Global migration is a separate explicit operation. | Preserve rollback and avoid moving native directories. Both-root cases require a reviewed mapping; no automatic merge. |

Exact helper function names, internal modules, CLI wording and fixture organization can be chosen during implementation. They must implement this contract without adding new user settings or dependencies. If implementation exposes a material change to these choices, stop that dependent work and return it for review.

## User workflow

Without a workspace, init/read/sync/search/handoff continue to work as they do in v1.5.0. A missing manifest is not an error. The existing tracking/privacy choices remain intact.

To opt in, the user explicitly supplies a workspace directory through memory-config and confirms initialization of its managed `context-keeper/` namespace. Only these directories are managed:

```text
context-keeper/
  knowledge/    approved durable knowledge; taxonomy is user-extensible
  projects/     deliberately promoted project facts or links
  proposals/    pending, deferred and rejected review records
  _system/      workspace manifest; rebuildable navigation if later useful
```

Initialization must not adopt or overwrite an unrelated existing namespace. Validate an existing supported manifest before writes. An unsupported manifest version disables workspace operations with a diagnostic; it must not disable ordinary project memory or trigger conversion. An existing workspace without a manifest requires explicit adoption after inspecting its contents. Do not scan or reorganize the rest of the vault.

During normal work, an agent identifies a useful durable candidate and distinguishes project state, global operating preferences and general knowledge. Routine general-knowledge candidates are queued and shown at sync/handoff or another natural task checkpoint. A significant decision or conflict affecting the current task is surfaced immediately. This is instruction-driven on all hosts; it adds no background watcher. Existing native hooks can supply reminders without becoming the only way the workflow functions.

The review presents the proposed claim, destination, evidence, uncertainty and effect. The human can approve, edit then approve, keep project-only, defer or reject. An explicit request to save a specific fact can authorize that fact; it does not approve unrelated candidates. Silence leaves the record pending. Keep-project-only may update project memory within the user's authorized scope but never authorizes global promotion.

Approval retains the proposal's identity and evidence in the resulting note, records the actual review action, and writes only to the reviewed destination. If that destination is unavailable, leave the proposal pending and explain why. Do not fill in an invented reviewer or approval event. Duplicate proposals are detected by identity and comparison of the claim/source; uncertain semantic matches are shown for review rather than automatically merged. A rejection is retained and blocks automatic re-proposal unless materially new evidence appears.

Workspace retrieval defaults to current approved notes and shows source/status. Explicit historical retrieval can include approved superseded/deprecated notes and validity intervals. Proposal review is a separate view, not a canonical search result. A read-only eligibility listing gives companion retrieval/import tooling the allowed files and exclusions; it does not call QMD or Hindsight, launch services, or claim a production import was tested. Private content must not be broadened in scope without separate authorization.

## Minimal note contract

New managed notes use these fields; optional fields are recorded only when known. This is the proposed serialization contract to approve, not a request to retrofit every existing note.

| Field | Meaning |
|---|---|
| `schema_version` | `1` for the managed note format; independent of the plugin release version. |
| `id`, `type`, `title` | Stable UUID, extensible note type, human-readable title. |
| `aliases`, `tags` | Lists, empty when unused; no imposed knowledge taxonomy. |
| `created`, `updated` | Actual capture/edit times; not evidence of when the underlying fact became true. |
| `status` | `current`, `superseded`, `disputed`, or `deprecated`. |
| `valid_from`, `valid_to` | Optional effective interval for the claim. |
| `review_state` | `pending`, `deferred`, `rejected`, `project_only`, or `approved`. |
| `proposed_by`, `reviewed_by`, `reviewed_at` | Actual agent/reviewer/action information when available. An approved record must contain a real review event; unknown identity must not be fabricated. |
| `destination` | Proposed or reviewed managed destination, required for proposals. |

Sources/Evidence in the body records source identifiers or links, capture time, and uncertainty. Relations contains readable entries such as `supersedes [[Previous Decision]]`; preserve identity and historical claims during changes. Rename within managed content keeps the UUID and preserves aliases or repairs affected managed links; never silently rewrite unrelated vault notes. Duplicate UUIDs and ambiguous titles are diagnosed. Validation is a focused command, not a permanent graph service.

Existing plain notes can be read normally. Deliberate promotion can enrich a reviewed note; absent metadata must never be interpreted as implicit approval for canonical import. Existing privacy/category conventions remain supported. Pending/deferred files remain ineligible even if renamed or moved into `knowledge/`.

Reconciliation follows the existing scope → status → authority → temporal validity → provenance guidance. Resolve the active interpretation for the task, preserve meaningful history, and proceed. A newer timestamp alone does not defeat an approved decision. An agent's inference can suggest review but cannot overwrite approved state. If human judgment is required, show the conflicting claims and consequence while continuing unrelated work. Reopen only on materially new evidence.

## Two implementation chunks

### A. Workspace, metadata and review workflow

Combines original Phases 3–6 and the relevant parts of Phase 8. Deliver the optional manifest/configuration, workspace initialization, note validation, proposal review actions, eligible retrieval/export listing and instruction updates. Reuse existing memory-init/config/sync/search/handoff entry points; avoid adding a command for every internal operation. Include templates, packages, guides and changelog updates with the behavior change.

Perform Claude and Codex workflow checks during this chunk: workspace opt-in, candidate creation, edited approval, search, sync/handoff and legacy ordinary-memory operation. File-based workflows must also be understandable to any agent reading AGENTS.md or the CLAUDE.md fallback. Native adapter discovery is verified separately from workflow execution. Use temporary projects/HOME and scratch workspaces; do not write real personal/global memory to test compatibility.

### B. Migration and remaining host verification

Combines original Phase 7 with remaining Phase 8 coverage. Deliver one migration workflow with preview, backup, staged copy, content/link/config validation, explicit apply and restore. Show exact source, destination, backup location, collisions, exclusions and adapter changes before asking for apply approval. Place default project backup/receipt material under `.ai/migration-backups/<operation-id>/`, outside the selected memory root; preview identifies its privacy/tracking implications. The receipt records file hashes and operation state rather than adding another memory schema manifest.

Coordinate known writers before apply, recheck source hashes after preview, and stop when source changes. Preserve source files; prevent stale legacy hooks from continuing to write after the switch. Rollback restores the pre-migration selection only after checking for subsequent edits; changed files require review rather than clobbering. Repeated execution reports completed work without duplicating content. The global operation requires its own reviewed scope. Both-root mappings, publication of backups and divergent-edit reconciliation remain explicit decisions per operation, not blanket consequences of implementation approval.

Exercise init/read/sync/search/handoff and native-state preservation across available supported hosts: Claude Code, Codex, Copilot, Cursor, Windsurf, Antigravity, Zed, Delta, Hermes and Pi. Refresh host-specific discovery/precedence documentation when implementing adapters. Record versions, actual executed workflows and unavailable capabilities. Add no mandatory host, service or model. Unavailable hosts remain unverified; do not claim universal certification. Companion wrapper/runtime integration stays outside this implementation scope.

## Verification proportional to the change

Extend existing fixture suites and use real workflow smoke checks where hosts are available. No elaborate new harness, benchmark project, duplicated assertion suite, or repeated full regression run without a new reason.

Chunk A needs focused cases for base/legacy memory without optional components, explicit workspace opt-in/disable/inheritance, unreachable workspace and local proposals, unsupported versions, plain notes, duplicate identity, privacy, renamed/misplaced pending records, all review actions including silence, rejected duplicates, edited approval and historical retrieval. Verify an actual Claude and Codex workflow where execution access permits it; otherwise describe the precise gap. Source/fixture checks alone do not certify a host.

Chunk B needs preview immutability, normal copy/apply, collisions, source changes after preview, an interrupted apply, unsafe/unwritable paths, restore with and without intervening edits, repeated operation and exclusion of native state. Check emitted eligibility manifests against positive and negative fixtures; live external-service ingestion is not part of this scope. Run existing regressions once for each material runtime chunk, then target subsequent review fixes. Record evidence and limits without claiming unavailable tests ran.

## Approval and autonomy

Approval of this proposal authorizes implementation of A then B on feature branches with reviewable PRs, including necessary shared helpers, adapters, documentation, proportionate tests and proposed release preparation. Routine internal choices need not return for permission. Keep each PR coherent; split A or B only if an independently reviewable boundary or real compatibility issue makes that useful.

It does not authorize automatic PR merging, tagging/publication, modifying a user's actual workspace or native memory, running a real migration, importing private material into external services, or changing the agreed dependency/configuration contract. Those actions require their own authorization. Material changes to behavior or scope return for review; ordinary bugs and review fixes remain within approved scope.

The implementation is complete when both chunks satisfy their specified behavior and available-host evidence is reported honestly. A release does not imply unavailable hosts were certified. No implementation starts solely because this document or its planning PR is merged; the user must approve its proposed choices and implementation scope.
