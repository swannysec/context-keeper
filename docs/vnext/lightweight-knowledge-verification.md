# Lightweight durable knowledge: implementation evidence

Date: 2026-10-06. Base: released v1.5.0 (`963be12`). Scope: the user-approved [revised remaining-work proposal](remaining-work-proposal.md), including citation/provenance and a verbatim source sample for every candidate. Implementation is delivered for review; host verification is partial, not a blanket compatibility certification.

## Delivered behavior

The existing skills, workflows, commands and copied platform instructions describe optional `knowledge_workspace` inheritance, project override/disable, authorized setup, relevant reading, human review and handoff. No project enable flag is required. Operating-memory resolution remains unchanged: `.ai/memory` by default, indefinite `.claude/memory` fallback for legacy-only projects. No manifest, migration, exporter, new parser dependency or wrapper runtime was added.

The [shared workflow](../../core/workflows/durable-knowledge.md) and [proposal template](../../core/memory/templates/knowledge-proposal.md) require the claim, destination/effect, uncertainty, citation/provenance and verbatim source text in a quotation or code block. Approved notes retain that evidence. Flat Obsidian-compatible properties keep lifecycle and review state separate; existing human notes need no conversion. Approval, edited approval, project-only, defer and reject remain human actions; silence and automatic project sync do not approve durable promotion. These are agent instructions, not a new machine-enforced ingestion system.

Standalone copies include privacy filtering, source-text-as-evidence handling and native-directory boundaries. A bounded code review identified omissions of those safeguards in initial standalone copies; both findings were corrected and the reviewer confirmed the fixes. No real personal memory or durable store was edited.

Codex's current native skills are supplied in `.agents/skills`. Packages retain identical legacy `.codex/skills` copies for older consumers. The native Codex, Copilot and Cursor adapters now include memory-config alongside init/search/sync/handoff. All seven packages include the shared workflow and templates. Codex uses AGENTS.md by default; CLAUDE-only fallback requires its documented native configuration. The installer does not change that native configuration automatically.

## Regression and packaging checks

All 17 existing shell-suite entry points ran sequentially with isolated child HOME/TMPDIR on macOS Bash 3.2/BSD. Sixteen exited zero. Phase 03 initially stopped because its category test referenced the former Codex source location; correcting that one path and rerunning the affected suite produced ten passes and zero failures. The resulting 15 original suites report 214 passes, while fixed-root coverage reports five unittest methods and characterization reports 13 methods separately. No dependency-skipped reports were observed. The full collection was not unnecessarily rerun after that focused correction.

Characterization exercises actual scratch builds and universal installation, five native skills per adapter, modern and legacy Codex package copies, preservation of pre-existing native sentinels, and shared workflow/template inclusion in all seven distributions. Existing root/privacy/search/hook coverage remains applicable. Build/installer shell syntax and `git diff --check` passed.

Local evidence: `/tmp/conkeeper-approved-regression-dmb4t72r/` contains the original run logs and results, including the initial Phase 03 failure. These temporary paths are diagnostic evidence, not repository prerequisites or durable release artifacts.

## Live Codex exercise

Codex CLI 0.144.5 completed two isolated runs in a project with spaces, a synthetic source document, scratch HOME/global memory, and an explicitly approved narrowed claim. Direct artifact checks confirmed:

- Init preserved legacy memory contents and a native skill sentinel without creating project `.ai/memory`.
- Absent project configuration inherited a global store path containing spaces. Explicit project `false` disabled it; removing the key resumed inheritance without changing global configuration or unrelated project settings.
- One approved note retained the narrowed synthetic claim, UUID, source citation and verbatim sample. An unrelated backoff suggestion remained pending in a proposal and handoff.
- Relevant reading distinguished an ordinary human note and the approved note from pending suggestions, including a pending proposal moved into `knowledge/`. Private source text did not appear in agent messages.
- A project override to a nonexistent store did not create that destination or switch elsewhere. The pending claim, citation and exact source quotation survived in the existing project handoff.
- Stored knowledge files retained their SHA-256 hashes during the follow-up. Global config, legacy fixtures and the native sentinel remained intact.

The first run exposed missing native memory-config discovery, although the agent used the shared workflow successfully. The adapter was added before the second run, which exercised native memory-config and memory-search. Evidence is in `/tmp/conkeeper-live-hosts-zk88shss/codex/`. Scratch authentication state was removed after testing. These runs verify the exercised behavior, not every possible model response; reject/defer/rename/conflict semantics are documented instructions rather than independently exercised host scenarios.

## Host limits and source research

Claude Code 2.1.292 was located, but its isolated configuration reported no login. Automatic approval review rejected reading its existing OAuth credential from macOS Keychain because credential extraction was not explicitly authorized. That action did not execute. No alternate credential route was attempted. Claude live verification remains pending user authorization or another explicitly authorized isolated login.

Antigravity, Delta, Hermes and Zed GUI applications were found locally. Their complete isolated workflows were not exercised. No runnable Copilot, Cursor, Windsurf or Pi CLI was discovered in the inspected PATH. Installed applications, source documentation and package fixtures do not establish successful host workflows.

Bounded primary-source research checked [Codex skills](https://developers.openai.com/codex/skills), [Codex AGENTS.md](https://developers.openai.com/codex/guides/agents-md), [Claude skills](https://code.claude.com/docs/en/skills), and [Obsidian Properties](https://obsidian.md/help/properties) on 2026-10-06. Current Codex discovery and flat Obsidian formatting informed the delivered changes; no live Obsidian claim follows. Further source checks covered [Zed instructions](https://zed.dev/docs/ai/instructions), [Antigravity rules](https://antigravity.google/docs/rules/), [Copilot CLI skills](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills), [Cursor rules](https://docs.cursor.com/context/rules), and [Pi skills](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md). Hermes context-file sources contained differing discovery descriptions; Delta's private-source contract was not independently refreshed, and Windsurf documentation remained a bounded research gap. No adapter change or runtime certification was inferred from those incomplete checks.

## Plugin QA and preservation

The invoked plugin-qa validate workflow found the marketplace (phase 1 PASS), then rejected standalone `source: "./"` under its monorepo source rule (phase 2 FAIL). Its dependent phases 3–8 remain blocked, not silently passed. Supplemental standalone checks safely parsed all 22 skill frontmatters and both new flat templates: names/descriptions, root README component references, root skill keywords and strict-semver version 1.5.0 consistency passed. Twelve existing native copies lack trigger arrays (WARN); no skill reference directories exist. This is not a formal plugin QA PASS. No repository layout or new requirement was introduced to satisfy a monorepo-only rule.

All nine files under the four excluded local items match the pre-switch SHA-256 inventory: `.serena/project.yml`, `.auto-claude/`, `context_portal/` and `docs/plans/v1.3.0-final-plan.md`. They remain outside this change. No real project/global memory migration, native settings change, external ingestion, merge, tag or release is included. Version remains 1.5.0 with changes recorded under Unreleased.
