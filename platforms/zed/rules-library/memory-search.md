# ConKeeper: Memory Search

Search across memory files for keywords, patterns, or past decisions. Returns structured results grouped by file with line numbers and category tags.

## Usage

```
/memory-search <query>
/memory-search --global <query>
/memory-search --sessions <query>
/memory-search --category <name> <query>
/memory-search --cross-project <query>
```

Flags can appear in any order relative to the query.

## Steps

1. **Parse the Query**
   Extract the search query and any flags from the user's invocation:
   - `--global` — include global memory (`~/.claude/memory/`)
   - `--sessions` — include session history files (last 30 days)
   - `--category <name>` — filter results to entries with matching category tag
   - `--cross-project` — search across other projects (requires config)

2. **Run the Search Script**
   ```bash
   bash "<conkeeper-path>/tools/memory-search.sh" <parsed-args>
   ```
   Where `<conkeeper-path>` is the ConKeeper installation directory (typically found via `git rev-parse --show-toplevel` or the directory containing the `tools/` folder).

   Pass the query and any flags directly to the script.

3. **Present Results**
   - Display the script output as-is (it is already Markdown-formatted)
   - If results are found, briefly note how many matches and files were returned
   - If the query was filtered by `--category`, mention which category was used

4. **No Results**
   If the script returns "No results found", suggest broadening the search:
   - Try `--global` to include global memory
   - Try `--sessions` to include session history
   - Try alternate keywords or synonyms
   - Remove `--category` if category filtering was used

## Examples

```
/memory-search "token budget"
/memory-search --global "naming convention"
/memory-search --sessions "authentication bug"
/memory-search --category decision "database"
/memory-search --category pattern --global "error handling"
/memory-search --cross-project "authentication"
```
