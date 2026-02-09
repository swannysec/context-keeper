---
name: memory-search
description: Search memory files for keywords, patterns, or categories
---

Search across memory files for keywords, patterns, or past decisions.

**Usage:**
```
/memory-search <query>
/memory-search --global <query>
/memory-search --sessions <query>
/memory-search --category <name> <query>
```

**Flags:**
- `--global` — Include global memory (`~/.claude/memory/`)
- `--sessions` — Include session files (last 30 days)
- `--category <name>` — Filter to entries with matching category tag

Results are grouped by file with line numbers and category tags.
