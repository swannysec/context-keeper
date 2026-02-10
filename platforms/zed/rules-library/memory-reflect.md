# ConKeeper: Memory Reflect (Simplified)

Manual session retrospection workflow for platforms without hook support.

## Steps

1. **Review corrections queue**
   - Read `.claude/memory/corrections-queue.md`
   - Group items by type (correction vs friction)
   - Note repeated corrections — these indicate patterns

2. **Review recent observations**
   - Read `.claude/memory/sessions/YYYY-MM-DD-observations.md` (today's date)
   - Look for friction patterns: repeated failures, many retries on the same file
   - Count total tool uses and failure rate

3. **Cross-reference existing knowledge**
   - Read `.claude/memory/patterns.md` — don't re-discover known patterns
   - Check `.claude/memory/decisions/` — don't re-recommend existing decisions

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
   Create `.claude/memory/sessions/YYYY-MM-DD-retro.md` with:
   - Session summary (2-3 sentences)
   - Approved improvements and their targets
   - Declined items with reasons
   - Evidence counts (corrections, observations)
