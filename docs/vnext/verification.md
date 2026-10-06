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
