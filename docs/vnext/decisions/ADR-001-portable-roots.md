# ADR-001: Portable roots with legacy continuity

Status: accepted intended design; implementation pending. Date: 2026-10-06.

Current code embeds legacy Claude paths across many consumers. Rebranding a folder in initialization alone would split state. Select explicit configured root first, then existing `.ai/memory`, existing `.claude/memory`, otherwise new `.ai/memory`. Apply independently globally and per project. Both directories means prefer new, diagnose ambiguity and never silently merge.

Existing legacy-only projects continue unchanged until explicit migration. This intentionally differs from the current schema's legacy-first prose; preserve current tests before changing code. `.ai` is a convention, not proof of universal namespace reservation. Native agent memory/lifecycle stays native. See [compatibility](../compatibility.md).

Rejected: automatic migration on startup, dual writes, and repurposing each vendor's native memory directory. Consequence: coordinated adapter changes and migration preview tests are required.
