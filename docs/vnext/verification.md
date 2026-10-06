# Bootstrap verification

Date: 2026-10-06. Scope: documentation-only bootstrap against Context Keeper v1.4.0, source revision `564d419f0a1f3f38782ebf4d4cb5c04dd269d2f7`. No resolver, schema parser, migration or knowledge capability was implemented.

All 15 existing `tests/*/test-*.sh` suites ran sequentially with macOS `/bin/bash` (3.2), BSD userland, system Python and available Homebrew jq/ripgrep. Test temporary files/flags were isolated under this chat's scratch directory. Every suite exited zero: 214 reported passes, zero failures. Output inspection found no dependency-skipped test reports. This is a baseline regression check, not proof of vNext or cross-agent compatibility.

| Suite | Reported passes | Failures |
|---|---:|---:|
| Functional integration | 36 | 0 |
| Phase 03 categories | 10 | 0 |
| Phase 04 privacy | 13 | 0 |
| Phase 05 search | 11 | 0 |
| Phase 06 observations | 12 | 0 |
| Phase 07 corrections | 14 | 0 |
| Phase 08 retrospection | 21 | 0 |
| Phase 09 context window | 18 | 0 |
| Phase 10 health | 9 | 0 |
| Phase 11 diff | 9 | 0 |
| Phase 12 decisions | 4 | 0 |
| Phase 13 cross-project | 9 | 0 |
| Phase 14 friction | 7 | 0 |
| Phase 15 context brackets | 13 | 0 |
| Phase 16 lifecycle | 18 | 0 |

The older local memory note about a phase-08 Python shim failure did not reproduce with the system Python selected for this run. It remains historical context, not a current baseline failure. Tests report PASS for some graceful fallback cases, so suite totals do not imply every integration was exercised. No live Hermes/OpenShell/Hindsight/QMD deployment was started.

At bootstrap, Phase 1 still needed targeted coverage review and characterization tests for the compatibility matrix before behavior changes. Subsequent Phase 1 results are recorded separately below.

## Phase 1 final verification — 2026-10-06

Characterized source revision: `4adf4535563d059216e0201ed06bddb11b7219a6` on `docs/vnext-bootstrap`. See [Phase 1 evidence](phase-1-characterization.md) for the component inventory, reproduction command, observed behaviors, known gaps and plugin QA results.

The original 15 suites were run before edits and again after adding coverage, sequentially on macOS `/bin/bash` 3.2.57 with BSD userland and isolated child-process HOME/TMPDIR. Both runs exited zero for every suite: 214 reported passes, zero failures; no dependency-skipped reports. The final run also included the new characterization suite: 13 unittest methods passed, including eight independently isolated project/global root-matrix subcases; zero failures. These method counts are separate from the existing shell suites' reported assertion counts.

New coverage exercises root detection/search, mixed scopes, read-only search, nested CWD, config bootstrap, symlink refusal and the known sessions-parent gap, privacy filtering, JSON-CWD observation/correction writers, native-state sentinels, cross-project mixed roots/depth, repeat instruction installation, CLAUDE-only installation, Codex skill selection and scratch package builds. Known-gap assertions record defects; they do not endorse them as intended behavior.

Shell syntax validation and `git diff --check` passed. A fresh SHA-256 inventory confirmed all nine files in the four excluded items were unchanged from before branch switching. Those items remain unstaged/untracked and excluded from the commit. No production files under hooks, tools, commands, skills, platforms, core, or manifests changed; no user/global memory was written.

Plugin QA validate mode found the repository marketplace, then rejected `source: "./"` under its monorepo source rule. Phases 3–8 were blocked by the unavailable valid toolkit inventory/layout; separate standalone checks are recorded in the evidence document. This is not a plugin QA PASS. No real Claude, Codex or other agent workflow was invoked or newly certified. Packaging, native adapter discovery, AGENTS-primary/CLAUDE-fallback behavior and write-symlink gaps remain compatibility gates.

Phase 1 characterization is complete. Phase 2 remains unstarted: `.ai` default selection and effective legacy fallback are acceptance requirements, not newly implemented behavior.

## Phase 2 verification — 2026-10-06

Base: merged main `fe03e82`, branch `feat/portable-memory-roots`. Scope was corrected by the user to fixed `.ai/memory` defaults and `.claude/memory` fallback only. No custom-root file, environment override, schema manifest, migration or later-phase knowledge feature was introduced. The existing project-root CWD and JSON hook `cwd` assumptions remain; global selection uses HOME.

`hooks/lib-memory-root.sh` is shared by SessionStart, UserPromptSubmit, PostToolUse, Stop, handoff generation, search and the read-only `tools/memory-root.sh` diagnostic. Feature settings, queues, observations, markers, decisions and handoffs follow the selected root. PreCompact still uses its existing temporary flags. Cross-project discovery checks both fixed roots at the existing depth limit, resolves each project independently, and deduplicates physical roots. Commands, skills, core workflows, copied rules, guides and schema path documentation were updated without changing the Markdown file format. Native facets/settings paths remain unchanged.

The installer supplies AGENTS.md primary instructions and a CLAUDE.md fallback with separate append/create prompts, preserves existing instructions, and includes the existing memory-search skill. Native skill placement is unchanged; modern discovery and live host certification remain Phase 8 work. Scratch distributions now include the root/search scripts and their shared libraries. The universal installer remains under `tools/` so its repository-relative source lookup works.

Verification used macOS Bash 3.2.57/BSD, Python 3.9.6, jq 1.7.1-apple, ripgrep 15.1.0 and isolated test HOME/TMPDIR. The initial new tests demonstrated the missing resolver and `.ai` hook behavior before implementation. Then all 15 original suites passed with 214 reported passes and zero failures; the updated characterization suite's 13 methods and the initial three root tests also passed in the same sequential full run.

A bounded read-only code review found native Claude-directory symlink selection, incorrect Git ignore paths under logical CWD, and copied rule examples that bypassed legacy selection. Each was corrected across its copies. A focused fixture reproduced the native-directory issue before its fix. Final targeted verification passed five root-test methods (including eight project/global matrix subcases, new-root hook/search/handoff flow, unsafe roots, unwritable roots without legacy writes, and symlinked sessions refusal), all 13 characterization methods, and the affected observation suite's 12 reported passes. No new test was skipped. Characterization includes actual packaged search execution in four distributions and repeated cross-project parents with one result per physical root. Direct checks of the Git ignore example through a symlinked CWD produced `.ai/memory/` and `.claude/memory/` correctly. Shell syntax and `git diff --check` passed. The original suites were not unnecessarily rerun after the small review fixes; affected behavior received targeted checks.

Existing legacy and native-state fixture contents remain intact. All nine files in the four excluded local items still match their pre-switch SHA-256 inventory and remain excluded from staging. No real user/global memory was written or migrated.

Plugin QA validate mode again found the marketplace (PASS), then rejected standalone `source: "./"` under its monorepo source rule (FAIL); phases 3–8 are blocked under that rule, not silently passed. Supplemental standalone checks safely parsed all 19 skill frontmatters and passed names/descriptions, root README/command references, root skill keywords and version `1.4.0` consistency. Twelve platform skill copies still lack trigger arrays (WARN under the skill convention); no reference directories are present. This is not a formal plugin QA PASS. No release/version bump was performed.

Phase 2 fixed-root implementation and verification are complete. Phase 3 and live cross-agent certification have not started. No blanket compatibility claim follows from fixture tests or source inspection.

## Release preparation — 2026-10-06

The user authorized version bumping and release preparation, with tagging and publication deferred until after merge. The feature commit warrants a minor bump from `1.4.0` to `1.5.0`; the root `plugin.json` is the sole executable version field. Historical baseline references above retain their original versions. CHANGELOG.md now has a pending 1.5.0 section; [draft release notes and post-merge steps](../releases/v1.5.0.md) are prepared. No tag or release has been created.

Plugin QA's formal phase 1 passed; phase 2 still rejects `source: "./"`, so formal phases 3–8 and the skill's release-prep validation gate cannot pass. Under the user's explicit preparation instruction, the applicable checks were performed against the standalone layout instead of changing the repository to fit the skill. No new layout or configuration requirement was introduced. Supplemental checks safely parsed all 19 skill frontmatters with Ruby Psych: names/descriptions passed; root README references and skill keywords passed; strict-semver `1.5.0` and version-free marketplace checks passed. Twelve existing platform copies still lack trigger arrays (WARN); no skill reference directories exist. Monorepo README-section checks are inapplicable. These supplemental results are not a formal plugin QA PASS.

All seven platform packages built in an isolated scratch copy; the shipped Claude plugin manifest contains `1.5.0`, and every package contains root/search tools and their shared libraries. All 13 characterization methods passed again, including packaged search execution. `git diff --check` passed. Existing Phase 2 regression evidence remains applicable because preparation changes only the version and release documentation. The unrelated local items remain excluded. Native adapter discovery and live host certification remain Phase 8 work.

## PR #25 Copilot feedback — 2026-10-06

All five comments were applicable: observation ignore patterns now use both literal fixed roots, the sync-marker redirect is quoted, README/SECURITY guidance covers selected and legacy roots, ADR-001 records Phase 2 implementation, and the universal package includes the existing platform assets required by its installer. No new installation option or configuration mechanism was added.

All 13 characterization methods passed with the existing package test extended to run the packaged universal installer's “all” option and check all four skill copies per native skill platform, Windsurf rules, AGENTS.md and CLAUDE.md. The first test attempt stopped at the installer's existing project-root prompt because the fixture lacked a project README; adding that fixture file allowed the actual installation check to run. Direct Bash 3.2 checks executed the documented sync-marker command under paths containing spaces for both roots; Git confirmed both documented observation patterns are ignored. Build syntax and `git diff --check` passed. Tests used isolated scratch directories; no native user memory was written.
