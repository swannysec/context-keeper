# ConKeeper: Memory Reflect (Simplified)

## Memory root selection

Resolve memory once per workflow, independently for project and global scopes: use existing `.ai/memory`, otherwise existing `.claude/memory`, otherwise select `.ai/memory` for authorized initialization. If both exist, use `.ai`, warn, and leave legacy memory untouched. Do not migrate or merge automatically.

When shell access is available, set `MEMORY_ROOT` with `bash "<conkeeper-path>/tools/memory-root.sh"` and `GLOBAL_MEMORY_ROOT` with the same command plus `--global`, checking for errors before continuing. Otherwise apply the same fixed rules with file tools. Run from the project root; global paths are relative to the user's home. All paths below use the selected root, including config, queues, observations, decisions, sync markers and handoffs. Read-only operations must not create directories. Preserve private content and refuse writes through symlinked memory subdirectories/files.


Manual session retrospection workflow for platforms without hook support.

## Steps

1. **Review corrections queue**
   - Read `$MEMORY_ROOT/corrections-queue.md`
   - Group items by type (correction vs friction)
   - Note repeated corrections — these indicate patterns

2. **Review recent observations**
   - Read `$MEMORY_ROOT/sessions/YYYY-MM-DD-observations.md` (today's date)
   - Look for friction patterns: repeated failures, many retries on the same file
   - Count total tool uses and failure rate

3. **Cross-reference existing knowledge**
   - Read `$MEMORY_ROOT/patterns.md` — don't re-discover known patterns
   - Check `$MEMORY_ROOT/decisions/` — don't re-recommend existing decisions

4. **Identify improvements**
   For each improvement, note:
   - What to change (specific, actionable)
   - Evidence (which correction or observation)
   - Where to apply (target memory file)

5. **Route approved improvements**
   - Code conventions → patterns.md
   - Architecture decisions → decisions/ADR-NNN-*.md
   - Terminology → glossary.md
   - Workflow preferences → active-context.md

6. **Write retrospective**
   Create `$MEMORY_ROOT/sessions/YYYY-MM-DD-retro.md` with:
   - Session summary (2-3 sentences)
   - Approved improvements and their targets
   - Declined items with reasons
   - Evidence counts (corrections, observations)
