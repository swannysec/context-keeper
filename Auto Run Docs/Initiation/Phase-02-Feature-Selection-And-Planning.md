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

- [ ] For each selected feature, create a detailed implementation plan:
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

- [ ] Create execution phase documents (Phase 03, 04, etc.) for each selected feature:
  - Each feature gets its own Phase document in `/Users/swanny/zed/context-keeper/Auto Run Docs/Initiation/`
  - Follow the standard Phase format with specific, actionable tasks
  - Include file paths, function signatures, and test expectations
  - Ensure each Phase is self-contained and can run autonomously
  - Order phases by dependency: foundational features first, features that build on others later
