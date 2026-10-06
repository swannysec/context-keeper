# Integrated proposal for remaining vNext work

Date: 2026-10-06. Status: revised recommendations approved by the user on 2026-10-06; lightweight implementation delivered for review; remaining host verification recorded in [implementation evidence](lightweight-knowledge-verification.md). Baseline: released v1.5.0. The remaining work is a lightweight skill/workflow extension, followed by host verification. This revision removes unnecessary manifest, helper-library, export and migration deliverables from the earlier proposal.

## Outcome and scope

Keep ordinary project memory backward compatible. Let an agent use a separately configured durable knowledge store, suggest useful additions, and save reviewed knowledge as readable Markdown. Use existing memory-init/config/sync/search/handoff skills and instructions, with AGENTS.md primary and CLAUDE.md fallback. Preserve native agent memory and lifecycle.

The existing `.ai/memory` default and indefinite `.claude/memory` fallback remain unchanged. No project or global memory needs to migrate. There is no standalone manifest, new Python/PyYAML dependency, required note conversion, database, daemon, export pipeline, or external-service adapter in this scope. Obsidian remains optional.

The older specifications describe additional possible mechanisms. This proposal retains their durable-knowledge, human-review, provenance, privacy and native-state boundaries, but recommends deferring their manifest, automated ingestion and migration tooling. Those are not necessary to deliver this workflow. The user approved this narrower implementation scope; the original phase table remains historical traceability rather than six required implementation projects.

## Recommended decisions

| Decision | Proposed behavior |
|---|---|
| Manifest | None. Paths and ordinary Markdown files are enough for this release; add version machinery only if a demonstrated incompatible format later needs it. |
| Global knowledge configuration | One optional `knowledge_workspace` setting in existing `.memory-config.md`, pointing to a vault or ordinary directory. An absent project setting inherits the global setting. An explicit project path overrides it; explicit `false` disables it for that project. No setting anywhere means ordinary memory only. |
| Store boundary | Context Keeper writes its new durable notes under `<configured directory>/context-keeper/`. It neither guesses the directory nor reorganizes the user's other notes. Workspace means this configured store, not a new application or runtime. |
| Note format | Ordinary Markdown with flat, Obsidian-compatible YAML properties for newly created durable notes/proposals. Stable UUID identity survives renames. Existing notes remain readable and are not retrofitted automatically. |
| Pending suggestions | A proposal is a suggested durable fact awaiting review. When a store is configured and available, deferred proposals can be Markdown files in its `context-keeper/proposals/`. Without an available store, record the pending suggestion in the existing project session/handoff record; do not create a new queue subsystem or global store. |
| Reading and approval | Read existing knowledge as context while respecting its source, status and privacy. Treat agent-generated pending suggestions as suggestions, never approved facts. Explicit human review governs additions or changes to durable knowledge. No export or machine-enforced eligibility tool is proposed. |
| Dependencies and migration | Keep the current lightweight skills and setup scripting. No new runtime dependency or migration tool. If implementation cannot deliver an agreed behavior without a materially different mechanism, return that issue for review. |

The configuration setting names the separate durable knowledge store; it does not change project/global operating-memory roots. It can be configured globally once and used by projects automatically. Do not write a global setting merely because a project opts in: the user chooses configuration scope. Existing private/tracking choices remain intact.

## Everyday workflow

1. The agent reads project memory and, when configured, relevant durable knowledge. It does not load an entire vault or confuse global operating preferences with general knowledge.
2. During work, it identifies a potentially reusable fact, relationship or decision. Routine candidates are presented at sync/handoff or a natural checkpoint; consequential conflicts are surfaced when they affect the task. This is skill behavior, with no background watcher.
3. It presents the proposed claim, source/evidence, uncertainty, destination and effect. Every candidate also carries a citation/provenance and a verbatim relevant source sample in a quote or code block, as required by the approval. The human can approve, edit then approve, keep project-only, defer or reject. Silence leaves it pending. An explicit request to save a specified fact authorizes that fact, not unrelated additions.
4. The agent writes the reviewed note to the agreed destination and records actual provenance/review information. An unavailable destination is reported, with the pending work preserved in the project record; never silently choose another canonical store.
5. Later reading distinguishes current knowledge, historical or disputed claims, and pending suggestions. A recently edited timestamp does not make a claim authoritative. Preserve meaningful history and reopen a resolved conflict only on materially new evidence.

An existing human-maintained note does not become unreadable because it lacks Context Keeper properties or an approval stamp. Unknown provenance remains unknown. Approval metadata is primarily the record of the agent's proposed changes and their review; it is not a demand that the user certify every existing note. Moving an agent-generated pending proposal into `knowledge/` does not approve it.

The proposed namespace remains small:

```text
context-keeper/
  knowledge/    reviewed durable notes, using the user's taxonomy
  projects/     deliberately saved project facts or links, not shadow copies
  proposals/    deferred suggestions awaiting human review
```

Do not create `_system/` unless a later, reviewed need exists. Do not overwrite an existing file or adopt unrelated content during setup. Ordinary memory workflows continue when no durable store is configured. If the user explicitly requests a proposal without a configured store, keep it in the current project's record rather than creating infrastructure.

## Obsidian-compatible properties

Use YAML at the very start of a note, between `---` delimiters. Use unique, flat property names with simple scalar or list values. Keep `tags` and `aliases` as lists. Use `YYYY-MM-DD` for dates; use the documented ISO-style date/time form when a time is actually needed. Never invent a capture time, source, reviewer or approval.

Use prefixed workflow fields such as `ck_id`, `ck_status` and `ck_review_state` so new workflow metadata is less likely to collide with a user's existing properties. Preserve other properties and their types. Lifecycle status (`current`, `superseded`, `disputed`, `deprecated`) is separate from review state (`pending`, `deferred`, `rejected`, `project_only`, `approved`). UUID generation is an ordinary file/tool operation, not a new identity service.

Optional fields can record a proposing agent, actual reviewer, review date and effective interval. Add only information that is useful and known; do not require a fixed set of empty properties on every note. Sources, uncertainty, review explanations and typed relationships belong in readable body sections. Existing metadata and human-edited content are preserved during changes.

Relations remain ordinary text such as `works_at [[Company]]` or `supersedes [[Previous Decision]]`. If a wikilink is placed in a YAML property, quote it; do not put Markdown prose or nested source/review objects into properties. Rename deliberately, retain the UUID, and preserve aliases or update affected links within the managed notes. Ambiguous identities are brought to the user's attention rather than silently merged. No graph index is required.

These conventions follow [Obsidian's official Properties documentation](https://obsidian.md/help/properties), checked 2026-10-06. Obsidian supports flat text/list/date properties, while nested properties are not supported in its normal property editor. This is a design-format check, not a claim that a live Obsidian workflow was tested.

## Two implementation chunks

### A. Lightweight durable-knowledge workflow

Update existing skills, core instructions, templates, platform copies and setup/config guidance for the agreed configuration inheritance, readable metadata and proposal/review behavior. Reuse existing scripting only where needed for setup or locating configured files; no general YAML parser, new dependency, metadata engine, queue service or exporter. Configuration values are treated as data, never evaluated as shell code.

Check actual Claude and Codex init/read/sync/search/handoff behavior during this chunk where available, including an inherited global knowledge setting, project disable, unreachable store, pending suggestions, edited approval and ordinary legacy memory. Keep the workflow understandable to any agent that can read AGENTS.md or CLAUDE.md. Use scratch projects/workspaces, not real personal or native memory.

### B. Remaining host compatibility and packaging

Verify file-based instructions, native discovery where applicable, packaging and complete workflows across available supported hosts: Claude Code, Codex, Copilot, Cursor, Windsurf, Antigravity, Zed, Delta, Hermes and Pi. Update an adapter only when a demonstrated compatibility issue requires it. Record versions and actual exercised behavior; unavailable hosts remain unverified. Reading a skill menu or passing a fixture does not certify a workflow.

No migration is included. Legacy projects can remain on `.claude/memory` indefinitely. The older [migration specification](migration.md) describes optional future tooling if separately requested, not a prerequisite for this work. Neither a real migration nor implementation of that tooling is authorized by this proposal.

QMD/Hindsight ingestion, export controls, wrapper integration and transport/synchronization are also deferred. A future integration must preserve review state, exclude proposals and private material from broader canonical imports, and receive its own scoped approval. This proposal does not implement or certify those integrations.

## Verification and autonomy

Use existing tests and focused smoke checks for changed behavior. Verify configuration inheritance/disable, literal paths with spaces, unavailable stores, instruction preservation, metadata formatting, pending versus approved notes, review actions including silence, privacy, legacy memory and native-state preservation. No new broad verification framework. Run existing regressions for material scripting changes, then target review fixes; documentation-only edits do not require a full runtime rerun.

Approval of this revised proposal permits implementation of A then B on feature branches with reviewable PRs. Routine internal choices, proportionate tests, documentation and review fixes can proceed without repeated permission requests. Material scope changes, new dependencies/settings or automation beyond this contract return for review.

Approval does not authorize automatic merging/releases, edits to real personal workspaces/native memory, migrations, or external imports. It authorizes development and scratch verification of the agreed behavior. A merged planning document alone is not implementation approval. Completion reports distinguish delivered workflow behavior from unavailable host verification.
