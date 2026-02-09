# Phase 02: Feature Selection & Implementation Planning

This phase reviews the competitive feature matrix from Phase 1, selects the highest-impact improvements, and creates detailed implementation plans for each. The user will review the matrix and confirm which features to build. This phase bridges research to execution.

## Tasks

- [x] Present the feature matrix to the user for review and selection:
  - Read `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/Feature-Matrix.md`
  - Summarize the top 5 recommended improvements from Section 5 (the Impact/Lift ranked list)
  - Highlight the Session Retrospection opportunity from Section 6
  - Ask the user which features they want to implement, offering the recommended list as defaults
  - Confirm the final selection before proceeding
  - **Result:** User selected all 5 recommended features + Session Retrospection. Conducted detailed brainstorm/interview on all 6 features. User's existing `session-retrospective` skill (from robot-tools) will be folded into ConKeeper as `/memory-reflect`. Design decisions saved to `Working/Feature-Design-Decisions.md`. Key decisions: agent-first output design, ripgrep auto-detection, cross-platform shell script from day one, blended session-retro + claude-reflect approach, shared analysis core between correction detection and retrospection, sub-agent execution model for reflect.

- [x] For each selected feature, create a detailed implementation plan:
  - Read ConKeeper's existing architecture: `plugin.json`, `hooks/hooks.json`, skill files, hook scripts
  - For each feature, document:
    - **What it does** — user-facing behavior description
    - **Where it lives** — which files to create or modify (be specific: paths, filenames)
    - **How it works** — technical approach, data flow, integration points with existing code
    - **Dependencies** — any new tools, libraries, or shell commands needed (prefer zero-dependency approach)
    - **Platform impact** — does this affect only Claude Code, or also other platform adapters?
    - **Token budget impact** — will this increase memory file sizes? By how much?
    - **Risk assessment** — what could go wrong, backward compatibility concerns
  - Save the complete plan to `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/Working/Implementation-Plan.md`
  - Structure the plan so each feature maps cleanly to one Phase (3, 4, 5...) in the execution documents
  - **Result:** Complete implementation plan created covering all 6 features mapped to Phases 03–08. Reviewed entire architecture: 3 hook scripts, 4 skill files, 7 core templates, schema, snippet, plugin.json, hooks.json, and platform adapters across 6 platforms. Each feature section documents: user-facing behavior, specific file paths (create/modify), technical approach with data flow, zero-dependency design, platform impact, token budget impact, risk assessment with mitigations, and test expectations. Dependency order: Categories (03) → Privacy (04) → Search (05) → Observations (06) → Corrections (07) → Retrospection (08). Version bumps: v0.5.0 through v1.0.0.

- [x] Create execution phase documents (Phase 03, 04, etc.) for each selected feature:
  - Each feature gets its own Phase document in `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/`
  - Follow the standard Phase format with specific, actionable tasks
  - Include file paths, function signatures, and test expectations
  - Ensure each Phase is self-contained and can run autonomously
  - Order phases by dependency: foundational features first, features that build on others later
  - **Result:** Created 6 execution phase documents (Phase-03 through Phase-08), one per selected feature, ordered by dependency chain. Each document includes: version bump target, dependency declaration, specific file paths for creation/modification, code snippets with Bash 3.2-compatible implementations, test expectations with runnable test scripts, platform adapter updates, and commit message guidance. Phase mapping: 03-Categories (v0.5.0), 04-Privacy (v0.6.0), 05-Search (v0.7.0), 06-Observations (v0.8.0), 07-Corrections (v0.9.0), 08-Retrospection (v1.0.0). All documents reference actual file paths from the current architecture (hooks/hooks.json, hooks/session-start.sh, hooks/user-prompt-submit.sh, 4 skill directories, 7 templates, 6 platform adapters) and include concrete code patterns drawn from the existing codebase (json_encode, session_id validation, YAML front matter parsing, flag file management).
