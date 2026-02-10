---
name: memory-search
description: Search memory files for keywords, patterns, or categories. Returns structured results grouped by file with context.
---

# Memory Search

Search across memory files for keywords, patterns, or past decisions. Returns structured results grouped by file with line numbers and category tags.

## Usage

Parse the user's invocation to extract the query and any flags:

```
/memory-search <query>
/memory-search --global <query>
/memory-search --sessions <query>
/memory-search --category <name> <query>
```

Flags can appear in any order relative to the query.

## Execution

Run the search script via Bash:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}/tools/memory-search.sh" <parsed-args>
```

Pass the query and any flags (`--global`, `--sessions`, `--category <name>`) directly to the script.

**Note:** The corrections queue (`.claude/memory/corrections-queue.md`) is included in default project memory search scope.

## Presenting Results

- Display the script output to the user as-is (it is already Markdown-formatted)
- If results are found, briefly note how many matches and files were returned
- If the query was filtered by `--category`, mention which category was used

## No Results

If the script returns "No results found", suggest broadening the search:

1. **Try `--global`** — include global memory (`~/.claude/memory/`)
2. **Try `--sessions`** — include session history files (last 30 days)
3. **Try alternate keywords** — suggest synonyms or related terms based on the query
4. **Remove `--category`** — if category filtering was used, try without it

## Examples

```
/memory-search "token budget"
/memory-search --global "naming convention"
/memory-search --sessions "authentication bug"
/memory-search --category decision "database"
/memory-search --category pattern --global "error handling"
```
