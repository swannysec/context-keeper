# v1.4 baseline behavior and design discrepancies

Inspected 2026-10-06 at bootstrap. At that time, tracked HEAD and fetched `origin/main` equaled `564d419f0a1f3f38782ebf4d4cb5c04dd269d2f7` (v1.4.0). The table below records that baseline, not Phase 2 behavior. Tests and subsequent changes are recorded in [verification](verification.md).

## Inspected code map

| Area | Current implementation | vNext implication |
|---|---|---|
| Root/config helpers | `hooks/lib-config.sh` parses frontmatter; it is not a common memory-root resolver | Introduce one consistent resolution contract without assuming it exists |
| Session start | `hooks/session-start.sh` sets global/project roots to `.claude/memory`, reads config and several derived paths literally; assumes project-root CWD | Cover root, config, markers, observations, friction, ADR index and handoff paths together |
| Runtime hooks | `user-prompt-submit.sh`, `post-tool-use.sh`, `stop.sh`, `lib-handoff.sh` reference legacy memory | Changing initialization alone would split reads/writes |
| Search | `tools/memory-search.sh` searches legacy project/global paths; configured cross-project paths discover only `*/.claude/memory` to depth 3 | Resolve each discovered project independently, avoid duplicate results and preserve configured scope/privacy |
| Workflows/schema | `core/memory/schema.md` lists legacy first, `.ai` second; initialization describes alternatives but creates legacy paths by default | vNext reverses intended order; these prose promises are not current executable support |
| Skills/adapters | `skills/`, `commands/`, `platforms/` carry workflow copies and native placement instructions | Inventory copies before changes; parity is a release gate |
| Installer | `tools/install.sh` installs native adapters and edits `AGENTS.md`; current Codex adapter uses `.codex/skills` | Revalidate current host discovery separately from portable memory roots |

Base files include active/product context, progress, patterns, glossary, friction, decisions and sessions. Privacy tags, category filtering, observation logging, correction queues, `.last-sync`, health/diff, handoffs and two-tier context warnings already exist. Preserve their tested semantics; do not import a historical plan's thresholds.

## Resolved discrepancies

The README mentions `.ai/memory`, but several executable paths remain legacy-only. Therefore the vNext resolution specification is **intended behavior**, not a claim of support today. `core/memory/schema.md` remains the current schema until the compatibility phase updates it; [compatibility](compatibility.md) owns intended changes.

The source working copy contains unrelated `.serena/project.yml` changes and untracked `.auto-claude/`, `context_portal/`, and `docs/plans/v1.3.0-final-plan.md`. None is imported into this PR. The local v1.3 plan describes historical four-tier brackets; tracked v1.4 code/docs use two tiers. Local active-context agrees with v1.4, while parts of local progress/config retain older values. Current tracked code wins for characterization; local historical notes do not redefine behavior.

These discrepancies are resolved for this bootstrap. Reopen only on new code or authoritative evidence. No native agent integration has been certified by this documentation pass.
