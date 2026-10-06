# Phase 1 characterization evidence

Date: 2026-10-06. Source: `docs/vnext-bootstrap`, revision `4adf4535563d059216e0201ed06bddb11b7219a6` (v1.4.0 plus the documentation bootstrap). Scope: characterize current behavior and add tests; no production code, resolver, schema, migration, or adapter behavior changed. Phase 2 has not started.

## Reproduction and results

Run from the repository root on macOS, with `/bin/bash` 3.2.57 and BSD userland. Dependencies used: system Python 3, jq, bc, Git, and Homebrew ripgrep. Each baseline suite received an isolated child-process HOME and TMPDIR; no developer global or native memory was used. The new suite creates and cleans its own temporary fixtures, including paths with spaces, native-memory sentinels, and scratch build sources.

Observed versions: Python 3.9.6, jq 1.7.1-apple, ripgrep 15.1.0, Apple Git 2.50.1, and Ruby 2.6.10 for supplemental safe YAML parsing.

```bash
phase1_scratch=$(mktemp -d)
mkdir -p "$phase1_scratch/home" "$phase1_scratch/tmp"
for suite in tests/*/test-*.sh; do
    env HOME="$phase1_scratch/home" TMPDIR="$phase1_scratch/tmp" \
        /bin/bash "$suite" || exit 1
done
rm -rf "$phase1_scratch"
```

Before edits, all 15 existing suites exited zero with 214 reported passes and zero failures. Counts matched the [bootstrap baseline](verification.md). No dependency-skipped reports appeared. The existing tests include graceful fallback assertions, so these totals do not certify external integrations.

The added `tests/vnext-characterization/test-current-roots.sh` runs Python standard-library tests whose subprocesses invoke `/bin/bash`. It covers current behavior, including known gaps, rather than asserting the proposed resolver exists. Run it directly or through the loop above. Initial new-test failures came from two incorrect test assumptions: project fixtures leaked into global-only subcases, and the installer was incorrectly expected to stop at its first arithmetic increment. Isolating both scopes and asserting the observed successful install corrected the tests; production files were not changed.

## Observed root and configuration behavior

| Existing roots | SessionStart/search today | vNext difference |
|---|---|---|
| Neither | SessionStart reports available but inactive; search returns no directories; neither root is created | Future read-only resolver selects an absent `.ai` target without creating it |
| `.ai` only | Ignored; no legacy directory is created | Future resolver selects `.ai` |
| Legacy only | Uses `.claude/memory`; project SessionStart creates `.last-sync` and the daily observations file | Must preserve legacy projects without requiring migration |
| Both | Uses legacy silently; `.ai` files remain untouched | Future resolver selects `.ai`, diagnoses ambiguity, and never merges |

The suite exercises all four rows independently for project and global scopes, plus a mixed new-project/legacy-global case. Search is read-only. Global discovery does not create project markers. Explicit-root, invalid-configured-root and unwritable-configured-root acceptance cases remain Phase 2 work: there is no implemented configuration channel to exercise today. No speculative environment variable or config key was added.

SessionStart, Stop and search use the process working directory; they do not climb to the repository root. Running SessionStart/search under a nested `src/` misses the parent project's memory. PostToolUse and UserPromptSubmit instead use JSON `cwd`; the new suite calls them from outside the project and confirms that observations and corrections go to the supplied project's legacy root.

SessionStart reads feature settings inside the legacy root, strips inline comments, validates budget values, and refuses a symlinked config file. `.ai` feature settings cannot bootstrap root selection and are ignored today. UserPromptSubmit and cross-project search use `lib-config.sh`; PostToolUse has its own frontmatter parser and does not apply the same config-symlink guard. These readers need a common root contract before any change in selection.

## Privacy, symlinks and native memory

Search tests confirm file-level `private: true`, block-level `<private>` exclusion, and rejection of symlinked Markdown files. Existing suites also cover category filtering, session age limits, observation file symlinks, queue sanitization, handoff TTL/size limits, health, diff, friction, two-tier context warnings, and legacy multi-step lifecycle flows.

The new suite confirms that SessionStart rejects a memory-root symlink outside the expected project boundary. It also reproduces a pre-existing gap: if `.claude/memory/sessions` is a symlink to another directory, SessionStart creates its daily observations file in that directory. PostToolUse refuses to append through the same sessions symlink. Passing characterization of this gap does **not** mean the write is safe. Parent-directory symlink validation must be addressed before certifying resolver/write safety; no fix was attempted in Phase 1.

Fixture sentinels for Claude native auto-memory, Hermes native memory, Codex sessions, shared native skills and Pi sessions remain byte-identical after SessionStart, observation/correction hooks, PreCompact and Stop. These are file-preservation checks, not actual host invocations. Real user/global memory was neither migrated nor written.

Cross-project search finds only legacy directories within depth 3 under configured parents. Mixed new/legacy/both fixtures return the legacy notes; `.ai` and deeper projects are absent. Each included fixture appears once for a single configured parent. Existing suites cover tilde expansion and exclusion of the current project. Overlapping configured parents and the future independent per-project resolver still require Phase 2 duplication tests.

## Complete component inventory for follow-up

| Surface | Tracked components inspected | Evidence and Phase 2 responsibility |
|---|---|---|
| Hook entry points | `session-start.sh`, `user-prompt-submit.sh`, `post-tool-use.sh`, `pre-compact.sh`, `stop.sh`, `hooks.json` | Existing suites exercise all five hooks; new tests add root/CWD/config/native-preservation boundaries. PreCompact uses temporary session flags rather than a memory root. |
| Hook libraries | `lib-config.sh`, `lib-privacy.sh`, `lib-handoff.sh` | Frontmatter/privacy helpers and handoff generation are covered by existing suites; handoffs use legacy focus and `.handoffs` paths. |
| Tools | `memory-search.sh`, `install.sh`, `build.sh` | New tests exercise search, interactive instruction/Codex installation, repeat installation, and scratch builds. Build success alone does not establish usable packages. |
| Core | `core/memory/schema.md`, seven templates, `core/snippet.md`, four `core/workflows/*.md` files | Current schema/workflows favor legacy; initialization is an agent workflow, not an executable initializer. Config lives inside memory; sync includes correction queues and `.last-sync`; handoff includes session summaries. |
| Root commands | `memory-config`, `memory-init`, `memory-search`, `memory-sync`, `session-handoff` (5) | Instruction surfaces; `memory-config` command still describes older budget presets than current schema/skills. |
| Root skills | `memory-config`, `memory-init`, `memory-insights`, `memory-reflect`, `memory-search`, `memory-sync`, `session-handoff` (7) | Config, reflection, facets, queues, observations, sessions, markers and global/project paths all need inclusion in the resolver inventory. No live skill execution was claimed. |
| Native skill copies | Codex `.codex/skills`, Copilot `.github/skills`, Cursor `.cursor/skills`: init/search/sync/handoff in each (12) | All frontmatter parses. None is byte-identical to its root counterpart; this is a copy-drift signal, not proof every difference is wrong. Inventory all bodies before adapter changes. |
| Rule copies | Cursor `.cursor/rules/conkeeper.mdc`, Windsurf `.windsurfrules`, Zed `rules-library/{memory-init,memory-reflect,memory-search,memory-sync,session-handoff}.md` (7) | Legacy paths and embedded workflow copies remain distinct maintenance surfaces. |
| Guides | Five platform READMEs and seven `docs/platform-guides/*.md` files | Installation/discovery claims are documentation, not runtime proof. The namespace note records the Codex adapter discrepancy; Phase 8 must validate actual hosts. |

## Packaging and instruction compatibility gates

The scratch build exits zero and creates all seven packages: Claude Code, Codex, Copilot, Cursor, Windsurf, Zed and universal. It contains 7 Claude skills and 4 each for Codex/Copilot/Cursor. However, the four packages' search skills reference `tools/memory-search.sh`, which is absent from those packages. The search script also requires `hooks/lib-privacy.sh` and, for cross-project mode, `hooks/lib-config.sh`. A successful package build is therefore insufficient to certify search workflows.

Codex installation succeeds, copies init/sync/handoff byte-for-byte into `.codex/skills`, and omits the supplied search skill. It does not install `.agents/skills`. These are current implementation facts; modern host discovery and complete workflow execution remain unverified here.

The universal installer appends the AGENTS snippet with approval, preserves existing instructions, and does not duplicate the snippet on a second run. It leaves an existing `CLAUDE.md` untouched, including in a CLAUDE-only project where it creates `AGENTS.md`. No installer path supplies a CLAUDE fallback. The README mentions CLAUDE instructions, but this is not an implemented fallback contract. Future compatibility work must provide `AGENTS.md` as the primary instruction surface and `CLAUDE.md` as a backward-compatible fallback, preserve existing user instructions, and verify precedence in each supported host. No fallback file or adapter was added in this characterization phase.

## Plugin QA

Applied the explicitly requested [plugin-qa skill](/Users/swanny/.agents/skills/plugin-qa/SKILL.md) in validate mode. It is a robot-tools monorepo validator, whereas this is a standalone root plugin.

| Skill phase | Result | Evidence |
|---|---|---|
| 1. Locate root | PASS | Root `.claude-plugin/marketplace.json` found |
| 2. Validate sources/inventory | FAIL | `source: "./"` does not match the skill's required `./[a-zA-Z0-9_-]+` toolkit directory pattern |
| 3. Frontmatter | BLOCKED | No valid toolkit inventory can be derived under the skill's input-validation rule |
| 4. Toolkit README tables | BLOCKED | Standalone repository has no toolkit README layout |
| 5. Root toolkit cross-references | BLOCKED | Root README has no toolkit bullet-list layout |
| 6. Toolkit versions | BLOCKED | Version lives in root `plugin.json`, not a derived toolkit manifest |
| 7. Toolkit keywords | BLOCKED | Requires the validated toolkit inventory |
| 8. Reference coverage | BLOCKED | Requires the validated toolkit inventory |

Formal result: 1 pass, 0 warnings, 1 failure, 6 blocked phases. Phases 3–8 were not executed as monorepo checks because Step 2 rejected the input. The source field was not rewritten to make the validator pass.

Separate standalone checks inspected the actual root and platform inventory: 7 root skills, 12 platform skill copies, 5 commands, 0 agents. Ruby's safe YAML parser accepted all 19 skill frontmatters; names match parent directories and descriptions are nonempty. Root skills have trigger arrays; all 12 platform copies lack them (WARN under the skill convention). All root skill/command names occur in README, and all root skill names occur in plugin keywords. Root version `1.4.0` satisfies strict semver with components below 1000; marketplace metadata/entries have no version fields. No inventoried skill has a `references/` directory. These are supplemental results, not a formal plugin-qa PASS or proof of host compatibility.

## Stop boundary

Phase 1 completes after the final full-suite run and preservation check recorded in [verification](verification.md). Root selection, explicit-root configuration, schema, native placement, fallback instructions, packaging repairs and host certification remain unimplemented. Phase 2 must review the configuration channel and relative-path anchoring before coding. The symlink and packaging findings are explained pre-existing gaps, not unexplained baseline test failures. Cross-agent suitability cannot be certified until the actual init/read/sync/search/handoff workflows pass in the claimed hosts.
