# Memory Search Workflow

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
  - `--global` — include `~/.claude/memory/` in search scope
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

### .claude/memory/active-context.md
<!-- @category: decision -->
**Line 15:** ...matching line with context...

### .claude/memory/decisions/ADR-003-search.md
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
