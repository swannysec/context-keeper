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

Phase 1 still needs targeted coverage review and characterization tests for the compatibility matrix before behavior changes. Preserve this baseline, add new behavior tests, and record actual phase results separately.
