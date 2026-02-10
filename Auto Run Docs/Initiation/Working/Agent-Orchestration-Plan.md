---
type: plan
title: ConKeeper Agent Orchestration Plan — Phases 03–08
created: 2026-02-09
tags:
  - orchestration
  - agent-personas
  - review-workflow
  - implementation-plan
related:
  - "[[Implementation-Plan]]"
  - "[[Feature-Design-Decisions]]"
---

# ConKeeper Agent Orchestration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Define how Maestro, sub-agents, and agent personas orchestrate the implementation and review of ConKeeper Phases 03–08.

**Architecture:** Maestro dispatches each phase as a sequential Auto Run document. Within each phase, the implementing agent uses Claude Code sub-agents (Task tool) for parallelizable implementation work and for the mandatory review/validation stage. Specialized agent types are used for reviews; implementation uses `general-purpose` agents with prompt-based personas.

**Tech Stack:** Maestro (Electron desktop, Auto Run), Claude Code (sub-agents via Task tool), Bash shell scripts, Markdown.

---

## 1. Execution Model

### Why Sub-Agents (Not Agent Teams)

Phases 03–08 are **strictly sequential** — each phase depends on the prior. Within each phase, the work pattern is:

1. **Implement** — mostly sequential tasks, some parallelizable
2. **Test** — run test suite
3. **Review** — parallel code + architecture review
4. **Fix** — apply critical/high/medium findings
5. **Simplicity Review** — reduce unnecessary complexity
6. **Test** — verify simplicity changes
7. **Security Review** — parallel architecture-security + technical-security review (AFTER step 6)
8. **Security Fix** — apply critical/high/medium findings
9. **Final Test** — ensure nothing broke

**Agent teams** are designed for long-running concurrent workstreams with shared state. That's overkill here — the review stages need fresh, focused perspectives with no shared context contamination. **Sub-agents** (Task tool) are the right fit: lightweight, parallel, isolated context, and they report back to the orchestrating agent who synthesizes findings.

**Maestro's role:** Dispatch each phase's Auto Run document to a single agent. That agent orchestrates its own sub-agents for the review stages. Maestro doesn't need to manage multiple agents per phase — the phase agent handles that internally.

### Execution Flow Per Phase

```
Maestro dispatches Phase-NN Auto Run doc
  └─> Implementing Agent (general-purpose, persona: depends on phase)
       ├── Step 1: Implementation tasks (sequential, some parallel)
       ├── Step 2: Run tests
       ├── Step 3: Parallel review (2 sub-agents)
       │    ├── workflow-toolkit:code-reviewer
       │    └── compound-engineering:review:architecture-strategist
       ├── Step 4: Synthesize + deduplicate findings → write summary log
       ├── Step 5: Fix critical/high/medium findings (autonomous)
       ├── Step 6: Simplicity review (1 sub-agent)
       │    └── compound-engineering:review:code-simplicity-reviewer
       ├── Step 7: Fix simplicity findings (autonomous) + re-run tests
       ├── Step 8: Parallel security review (2 sub-agents) — BLOCKED until Step 7 complete
       │    ├── compound-engineering:review:security-sentinel (architecture prompt)
       │    └── compound-engineering:review:security-sentinel (technical prompt)
       ├── Step 9: Synthesize + deduplicate security findings → write summary log
       ├── Step 10: Fix critical/high/medium security findings (autonomous)
       └── Step 11: Final test run (if tests exist)
```

---

## 2. Agent Types & Personas

### Implementation Agents (One Per Phase)

All implementation agents use `subagent_type: "general-purpose"` with a prompt-based persona. No specialized implementation agent types exist in the environment — the persona guides the agent's mindset and priorities.

| Phase | Persona | Rationale |
|-------|---------|-----------|
| 03 (Categories) | **Schema Designer** | Focus on data format design, template consistency, cross-platform portability |
| 04 (Privacy) | **Privacy Engineer** | Focus on enforcement guarantees, edge cases, sed/grep compatibility, fail-safe defaults |
| 05 (Search) | **CLI Tools Developer** | Focus on cross-platform shell scripting, ripgrep/grep compatibility, output formatting |
| 06 (Observations) | **Hook Systems Developer** | Focus on JSON parsing, performance (<100ms), append-only safety, Bash 3.2 compat |
| 07 (Corrections) | **NLP/Pattern Detection Developer** | Focus on regex precision, false positive minimization, sensitivity tuning |
| 08 (Retrospection) | **Workflow Designer** | Focus on AAR methodology, skill instruction clarity, integration with all prior features |

### Review Agents (Reused Across All Phases)

These use **dedicated agent types** from the environment. Fresh context each time.

| Role | Agent Type (`subagent_type`) | Focus Areas |
|------|------------------------------|-------------|
| **Code Quality Reviewer** | `workflow-toolkit:code-reviewer` | Correctness, readability, DRY, test coverage, error handling, Bash 3.2 compat, no regressions. Has Read, Grep, Glob, WebSearch, WebFetch, Bash — read-only + verification. |
| **Architecture Reviewer** | `compound-engineering:review:architecture-strategist` | Schema consistency, cross-platform portability, dependency chain integrity, token budget impact, backwards compatibility. Full tool access. |
| **Simplicity Reviewer** | `compound-engineering:review:code-simplicity-reviewer` | Over-engineering, YAGNI violations, unnecessary abstractions, premature generalization. Ensures code is as simple and minimal as possible. Full tool access. |
| **Security Reviewer** (both passes) | `compound-engineering:review:security-sentinel` | Pass 1 (architecture prompt): Threat model, trust boundaries, data flow, privacy enforcement, fail-open safety. Pass 2 (technical prompt): Command injection, path traversal, sed/grep injection, YAML/JSON parsing safety, symlink attacks, race conditions. Full tool access. |

---

## 3. Review & Validation Phase Template

Every phase (03–08) concludes with this review/validation sequence. The implementing agent executes this after all implementation tasks are complete.

### Autonomy & Approval Policy

The implementing agent **fixes findings autonomously** without user approval UNLESS a fix would:
- Change the original design intent described in the Implementation Plan
- Remove or alter user-facing functionality
- Require modifying code from a prior phase

In those cases, the agent should document the conflict and ask the user before proceeding.

### Review Summary Logging

Every review stage writes a summary to a log file for post-hoc review:

```
Location: Auto Run Docs/Initiation/Working/review-logs/phase-NN-review-summary.md
```

Format:
```markdown
# Phase NN Review Summary

## Stage 2: Code + Architecture Review
### Code Quality (workflow-toolkit:code-reviewer)
- Critical: [count] | High: [count] | Medium: [count] | Low: [count]
- Key findings: [1-2 sentence summary per Critical/High finding]

### Architecture (compound-engineering:review:architecture-strategist)
- Critical: [count] | High: [count] | Medium: [count] | Low: [count]
- Key findings: [1-2 sentence summary per Critical/High finding]

### Consolidated (after dedup)
- Total unique findings: [count] (Critical: N, High: N, Medium: N)
- Fixes applied: [list of finding IDs fixed]

## Stage 5: Simplicity Review
### Simplicity (compound-engineering:review:code-simplicity-reviewer)
- Findings: [count]
- Key findings: [summary]
- Fixes applied: [list]

## Stage 7: Security Review
### Security Architecture (compound-engineering:review:security-sentinel — arch pass)
- Critical: [count] | High: [count] | Medium: [count] | Low: [count]
- Key findings: [summary]

### Security Technical (compound-engineering:review:security-sentinel — tech pass)
- Critical: [count] | High: [count] | Medium: [count] | Low: [count]
- Key findings: [summary]

### Consolidated (after dedup)
- Total unique findings: [count]
- Fixes applied: [list]

## Final Status
- All tests passing: [yes/no]
- Design intent preserved: [yes/no]
- Escalations to user: [none / list]
```

### Stage 1: Run Tests

```
If tests exist for this phase or prior phases:
  Run: bash tests/phase-NN-<name>/test-<name>.sh
  Run: all prior phase test suites (regression check)

  If ANY test fails:
    Fix the failure before proceeding to Stage 2.
    Re-run all tests to confirm the fix.
```

### Stage 2: Parallel Code + Architecture Review

Launch **two sub-agents in parallel** using the Task tool:

**Sub-Agent A: Code Quality Reviewer**

```
subagent_type: "workflow-toolkit:code-reviewer"

Persona: Senior developer reviewing a PR for merge readiness.

Review all files created or modified in this phase. For each file:
1. Correctness: Does the code do what the Implementation Plan says it should?
2. Bash 3.2 compatibility: Any mapfile, associative arrays, $EPOCHSECONDS, ${var,,}, \b?
3. Error handling: set -euo pipefail, trap on ERR, fail-open (exit 0)?
4. Edge cases: Empty input, missing files, malformed JSON, empty config?
5. Test coverage: Are all test expectations from the phase doc covered?
6. Code style: Consistent with existing hooks (session-start.sh, user-prompt-submit.sh)?
7. Regressions: Could this change break any existing functionality?

Output format:
## Code Review Findings

### Critical (must fix before merge)
- [C1] file:line — description

### High (should fix before merge)
- [H1] file:line — description

### Medium (fix if time permits)
- [M1] file:line — description

### Low (optional / nit)
- [L1] file:line — description

### Positive Observations
- [list of things done well]
```

**Sub-Agent B: Architecture Reviewer**

```
subagent_type: "compound-engineering:review:architecture-strategist"

Persona: Systems architect reviewing for long-term maintainability and design coherence.

Review all changes against the Implementation Plan and ConKeeper architecture:
1. Schema consistency: Do new tags/formats integrate cleanly with core/memory/schema.md?
2. Cross-platform portability: Will this work on all 6 supported platforms?
3. Dependency chain: Does this phase correctly build on prior phases without circular deps?
4. Token budget: Will the changes stay within documented token budget limits?
5. Configuration: Are new config options documented, defaulted, and backward-compatible?
6. Platform adapters: Are all 5 non-Claude-Code platform adapters updated consistently?
7. Naming conventions: Do new files, functions, and flags follow existing patterns?
8. Backwards compatibility: Can users upgrade from the prior version without migration?

Output format:
## Architecture Review Findings

### Critical (blocks release)
- [C1] area — description

### High (should address)
- [H1] area — description

### Medium (consider addressing)
- [M1] area — description

### Low (future consideration)
- [L1] area — description

### Architecture Observations
- [notes on design quality]
```

### Stage 3: Synthesize & Deduplicate

The implementing agent:

1. Reads both review outputs
2. Deduplicates findings that overlap (e.g., both reviewers flag the same Bash compat issue)
3. Creates a consolidated findings list with unique IDs
4. Groups by severity: Critical → High → Medium (ignoring Low for now)
5. **Writes summary to review log** (see Review Summary Logging above)

### Stage 4: Fix Findings

Fix all Critical, High, and Medium findings from the consolidated list. **Fix autonomously** unless a fix would change design intent or functionality.

```
For each finding (Critical first, then High, then Medium):
  1. Understand the finding
  2. If fix would change design intent/functionality → document and ask user
  3. Otherwise → implement the fix autonomously
  4. Mark the finding as resolved in the review log

After all fixes:
  Re-run tests to confirm no regressions from fixes.
```

### Stage 5: Simplicity Review

Launch **one sub-agent** using the Task tool:

**Sub-Agent E: Simplicity Reviewer**

```
subagent_type: "compound-engineering:review:code-simplicity-reviewer"

Review all files created or modified in this phase (post-fixes from Stage 4).
Identify opportunities to:
1. Remove unnecessary complexity or abstractions
2. Eliminate premature generalization (YAGNI violations)
3. Simplify conditional logic or data flow
4. Remove dead code or unused variables
5. Replace clever code with straightforward code

Do NOT suggest changes that would:
- Remove functionality specified in the Implementation Plan
- Add new features or capabilities
- Change the public interface or behavior

Output format:
## Simplicity Review Findings

### Simplifications (should apply)
- [S1] file:line — what to simplify — why it's simpler

### Optional (nice to have)
- [O1] file:line — suggestion

### Already Simple
- [list of things that are appropriately minimal]
```

### Stage 6: Fix Simplicity Findings + Test

Fix all "should apply" simplicity findings autonomously. Then re-run all tests to confirm simplicity changes don't break anything.

**Write simplicity summary to review log.**

### Stage 7: Parallel Security Review (BLOCKED until Stage 6 complete)

**CRITICAL: Do NOT start security reviews until ALL simplicity fixes from Stage 6 are complete and tests pass.** Security reviewers must review the final, simplified code.

Launch **two sub-agents in parallel** using the Task tool:

**Sub-Agent C: Security Reviewer (Architecture Pass)**

```
subagent_type: "compound-engineering:review:security-sentinel"

Focus: Application security architecture.

Review all files created or modified in this phase (post-all-fixes) for security posture:
1. Trust boundaries: Where does untrusted input enter the system? (hook JSON input,
   user-created memory files, .memory-config.md, .correction-ignore)
2. Privacy enforcement: Are <private> blocks respected in ALL code paths?
3. Data flow: Could sensitive content leak through observations, corrections, or search results?
4. Fail-open safety: Do all hooks exit 0 on error (never block the agent)?
5. Configuration safety: Can malicious config values cause unexpected behavior?
6. File system trust: Are paths validated? Symlink attacks prevented?
7. Information disclosure: Do error messages leak sensitive paths or content?

Output format:
## Security Architecture Review

### Critical (security vulnerability)
- [SC1] area — description — attack scenario

### High (security weakness)
- [SH1] area — description — risk

### Medium (defense-in-depth gap)
- [SM1] area — description — recommendation

### Low (hardening opportunity)
- [SL1] area — description

### Security Posture Assessment
- Overall risk: [Low/Medium/High]
- Trust boundary diagram: [if applicable]
```

**Sub-Agent D: Security Reviewer (Technical Pass)**

```
subagent_type: "compound-engineering:review:security-sentinel"

Focus: Shell script and code-level security vulnerabilities.

Review all shell scripts and skill files for technical security vulnerabilities:
1. Command injection: Any unquoted variables in command context?
   Any user content flowing into eval, $(), or backticks?
2. Path traversal: Are file paths from JSON input sanitized?
   Can session_id, file_path, or tool_input escape the expected directory?
3. sed/grep injection: Can user-controlled content in <private> tags,
   category values, or search queries inject sed/grep metacharacters?
4. YAML/JSON parsing: Can malformed .memory-config.md or hook input JSON
   cause unexpected behavior? Is jq absence handled gracefully?
5. Symlink attacks: Can symlinks in .claude/memory/ redirect writes to
   unexpected locations?
6. Race conditions: Can concurrent hook executions corrupt observation files
   or the corrections queue?
7. Denial of service: Can extremely large input JSON, memory files, or
   observation files cause excessive resource usage?
8. Temp file safety: Are temporary files created securely? (mktemp, not predictable names)

Output format:
## Technical Security Review

### Critical (exploitable vulnerability)
- [TC1] file:line — vulnerability — PoC/attack vector

### High (likely exploitable)
- [TH1] file:line — weakness — risk scenario

### Medium (requires specific conditions)
- [TM1] file:line — issue — conditions needed

### Low (theoretical / hardening)
- [TL1] file:line — note

### Security Testing Notes
- [specific tests that should be added]
```

### Stage 8: Synthesize & Deduplicate Security Findings

Same process as Stage 3, but for security findings:

1. Read both security review outputs
2. Deduplicate overlapping findings
3. Consolidated list with unique IDs
4. Group by severity: Critical → High → Medium
5. **Write security summary to review log**

### Stage 9: Fix Security Findings

Fix all Critical, High, and Medium security findings. **Fix autonomously** unless a fix would change design intent or functionality.

```
For each finding (Critical first, then High, then Medium):
  1. Understand the vulnerability/weakness
  2. If fix would change design intent/functionality → document and ask user
  3. Otherwise → implement the fix autonomously
     (prefer defense-in-depth: fix the root cause AND add a guard)
  4. Add a test for the security fix if applicable
  5. Mark the finding as resolved in the review log

After all fixes:
  Re-run ALL tests (this phase + all prior phases) to confirm no regressions.
```

### Stage 10: Final Verification

```
If tests exist:
  Run ALL test suites (this phase + all prior phases)
  ALL tests must pass before the phase is considered complete.

Verify:
  - Version bump is correct in plugin.json
  - hooks/hooks.json is valid JSON
  - session-start.sh produces valid JSON output
  - user-prompt-submit.sh produces valid JSON output (if modified)
  - Commit message follows conventional commit format

Write final status to review log.
```

---

## 4. Auto Run Document Format

Each phase Auto Run document (Phase-03 through Phase-08) should be structured as:

```markdown
# Phase NN: Feature Name

**Agent Persona:** [Persona Name] — [one-line description of focus]
**Version Bump:** vX.Y.Z → vA.B.C
**Dependency:** [which phases must be complete]

## Implementation Tasks

- [ ] Task 1: [description]
- [ ] Task 2: [description]
...

## Review & Validation

- [ ] Stage 1 — Run tests

- [ ] Stage 2 — Parallel code and architecture review:
  Sub-Agent A: subagent_type "workflow-toolkit:code-reviewer"
  Sub-Agent B: subagent_type "compound-engineering:review:architecture-strategist"

- [ ] Stage 3 — Synthesize review findings + write summary to review log

- [ ] Stage 4 — Fix code and architecture findings (autonomous unless design-changing)

- [ ] Stage 5 — Simplicity review:
  Sub-Agent E: subagent_type "compound-engineering:review:code-simplicity-reviewer"

- [ ] Stage 6 — Fix simplicity findings (autonomous) + re-run tests

- [ ] Stage 7 — Parallel security review (BLOCKED until Stage 6 complete):
  Sub-Agent C: subagent_type "compound-engineering:review:security-sentinel" (architecture)
  Sub-Agent D: subagent_type "compound-engineering:review:security-sentinel" (technical)

- [ ] Stage 8 — Synthesize security findings + write summary to review log

- [ ] Stage 9 — Fix security findings (autonomous unless design-changing)

- [ ] Stage 10 — Final verification: run all tests, verify artifacts, commit
```

---

## 5. Sub-Agent Dispatch Reference

When implementing the review stages, the orchestrating agent should dispatch sub-agents like this:

### Parallel Code + Architecture Review (Stage 2)

```
Launch TWO Task tool calls in a SINGLE message (parallel execution):

Task 1:
  subagent_type: "workflow-toolkit:code-reviewer"
  name: "code-quality-reviewer"
  description: "Code quality review"
  prompt: [Code Quality Reviewer prompt from Section 3, Stage 2, Sub-Agent A]
           Include: list of files changed, the phase number,
           reference to Implementation-Plan.md for spec

Task 2:
  subagent_type: "compound-engineering:review:architecture-strategist"
  name: "architecture-reviewer"
  description: "Architecture review"
  prompt: [Architecture Reviewer prompt from Section 3, Stage 2, Sub-Agent B]
           Include: list of files changed, the phase number,
           reference to Implementation-Plan.md and schema.md for spec
```

### Simplicity Review (Stage 5)

```
Launch ONE Task tool call:

Task 1:
  subagent_type: "compound-engineering:review:code-simplicity-reviewer"
  name: "simplicity-reviewer"
  description: "Code simplicity review"
  prompt: [Simplicity Reviewer prompt from Section 3, Stage 5, Sub-Agent E]
           Include: list of files changed (post-fix versions), the phase number
```

### Parallel Security Review (Stage 7)

```
Launch TWO Task tool calls in a SINGLE message (parallel execution):
ONLY after Stage 6 is complete and tests pass.

Task 1:
  subagent_type: "compound-engineering:review:security-sentinel"
  name: "security-architect"
  description: "Security architecture review"
  prompt: [Security Reviewer architecture prompt from Section 3, Stage 7, Sub-Agent C]
           Include: list of files changed (post-all-fix versions), the phase number

Task 2:
  subagent_type: "compound-engineering:review:security-sentinel"
  name: "security-engineer"
  description: "Technical security review"
  prompt: [Security Reviewer technical prompt from Section 3, Stage 7, Sub-Agent D]
           Include: list of files changed (post-all-fix versions), the phase number
```

---

## 6. Phase-Specific Parallelization Opportunities

Beyond the review stages, some implementation tasks within phases can be parallelized:

| Phase | Parallelizable Implementation Tasks |
|-------|--------------------------------------|
| 03 | Template updates (7 templates) can run in parallel with schema update |
| 04 | Template updates can run in parallel with schema update; hook modification is sequential |
| 05 | Skill file creation can run in parallel with shell script creation; but session-start.sh mod is sequential |
| 06 | Schema docs can run in parallel with config docs; hook script is sequential |
| 07 | Schema/config docs can run in parallel; hook modification is sequential and high-risk |
| 08 | Skill file, stop hook, and schema/config docs can all run in parallel; integration testing is sequential |

The implementing agent MAY use sub-agents for parallelizable implementation tasks, but this is optional — the review/validation parallelization is mandatory.

---

## 7. Maestro Dispatch Sequence

In Maestro, dispatch phases one at a time:

```
1. Dispatch Phase-03-Memory-Observation-Categories.md → Agent completes → verify
2. Dispatch Phase-04-Privacy-Tags.md → Agent completes → verify
3. Dispatch Phase-05-File-Based-Memory-Search.md → Agent completes → verify
4. Dispatch Phase-06-PostToolUse-Observation-Hook.md → Agent completes → verify
5. Dispatch Phase-07-Correction-Friction-Detection.md → Agent completes → verify
6. Dispatch Phase-08-Session-Retrospection.md → Agent completes → verify
```

Each phase's Auto Run document is self-contained. The agent reads the orchestration plan (this document) for review/validation instructions and persona prompts.

**Between phases:** Maestro user should verify the phase completed successfully (check the Auto Run checkboxes and review the summary log at `Working/review-logs/phase-NN-review-summary.md`) before dispatching the next phase.

---

## 8. Failure Handling

### Test Failures
- Fix immediately. Do not proceed to review stages with failing tests.
- If a fix requires changing the approach, update the phase doc's task description.

### Review Finding Disagreements
- If a review finding contradicts the Implementation Plan, the Implementation Plan wins.
- If a review finding reveals a genuine design flaw in the plan, note it and fix it.
  Document the deviation in the phase's commit message and review log.

### Fixes That Change Design Intent
- If a fix would change original design intent or remove/alter functionality, **stop and ask the user**.
- Document the conflict in the review log with: finding ID, proposed fix, why it changes intent.
- Wait for user direction before proceeding.

### Security Findings That Require Architecture Changes
- If a security finding requires changes to a prior phase's code, do NOT modify prior phase files.
- Instead, document the finding and create a follow-up task for the affected phase.
- The current phase should implement a defensive guard where possible.

### Sub-Agent Failures
- If a sub-agent fails to produce output, re-launch it once.
- If it fails again, perform that review manually (the orchestrating agent does it).

---

*Generated 2026-02-09. Source: Implementation-Plan.md, Feature-Design-Decisions.md, Maestro system context.*
