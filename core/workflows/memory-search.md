# Memory Search Workflow

## Memory root selection

Resolve memory once per workflow, independently for project and global scopes: use existing `.ai/memory`, otherwise existing `.claude/memory`, otherwise select `.ai/memory` for authorized initialization. If both exist, use `.ai`, warn, and leave legacy memory untouched. Do not migrate or merge automatically.

When shell access is available, set `MEMORY_ROOT` with `bash "<conkeeper-path>/tools/memory-root.sh"` and `GLOBAL_MEMORY_ROOT` with the same command plus `--global`, checking for errors before continuing. Otherwise apply the same fixed rules with file tools. Run from the project root; global paths are relative to the user's home. All paths below use the selected root, including config, queues, observations, decisions, sync markers and handoffs. Read-only operations must not create directories. Preserve private content and refuse writes through symlinked memory subdirectories/files.


**Purpose:** Search memory files for keywords, patterns, or past decisions. Returns structured results grouped by file with context and category tags.

## When to Use

- Before re-investigating a known problem
- Looking for past decisions or patterns
- Searching for specific content across memory files
- Finding entries by category (decision, convention, pattern)

## Workflow Steps

### 1. Parse Search Request

Extract from the user invocation:
- **Query string** (required): keywords or phrases to search
- **Flags** (optional):
  - `--global` — include `$GLOBAL_MEMORY_ROOT/` in search scope
  - `--sessions` — include `sessions/` subdirectory (last 30 days)
  - `--category <name>` — filter to entries with matching `<!-- @category: <name> -->` tag

### 2. Execute Search

Run the search script:
```bash
bash <conkeeper-path>/tools/memory-search.sh <query> [flags]
```

The script handles:
- Search engine auto-detection (ripgrep preferred, grep fallback)
- Privacy enforcement (skips `private: true` files and `<private>` block content)
- Category filtering when `--category` is specified
- Structured output formatting

### 3. Present Results

- Display script output as-is (already Markdown-formatted)
- Note match count and file count
- If category-filtered, mention which category was used

### 4. Handle No Results

If no results found, suggest broadening the search:
1. Try `--global` — include global memory
2. Try `--sessions` — include session history (last 30 days)
3. Try alternate keywords — suggest synonyms or related terms
4. Remove `--category` — if category filtering was used, try without it

## Examples

```
/memory-search "token budget"
/memory-search --global "naming convention"
/memory-search --sessions "authentication bug"
/memory-search --category decision "database"
```

## Output Format

```
## Results for: "<query>"

### $MEMORY_ROOT/active-context.md
<!-- @category: decision -->
**Line 15:** ...matching line with context...

### $MEMORY_ROOT/decisions/ADR-003-search.md
**Line 8:** ...matching line...

---
Found 3 matches across 2 files.
```

## Platform-Specific Notes

> **Note:** The search script requires bash and either ripgrep or grep. All platforms invoke the same `tools/memory-search.sh` script.

- **Claude Code:** Available as `/memory-search` command or skill
- **GitHub Copilot:** Available via skill with script path reference
- **Cursor:** Available via skill with script path reference
- **Windsurf:** Available via `.windsurfrules` workflow section
- **Zed:** Available via rules-library guidance
- **Codex:** Available via skill with script path reference
