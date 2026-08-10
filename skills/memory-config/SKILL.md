---
name: memory-config
description: View and modify ConKeeper memory configuration settings. Use to adjust token budget, output style, and other preferences after memory initialization.
triggers:
  - /memory-config
---

# Memory Configuration

View and modify ConKeeper configuration for the current project.

## Pre-flight Check

1. Verify `.claude/memory/` exists
   - If not: Inform user to run `/memory-init` first

## Configuration Options

### Token Budget Presets

| Preset | Total Target | Session Summary | Best For |
|--------|--------------|-----------------|----------|
| `economy` | ~2000 tokens | 200-400 | Quick tasks, minimal context |
| `light` | ~3000 tokens | 400-700 | Small projects, faster loading |
| `standard` | ~4000 tokens | 600-1000 | Most projects (default) |
| `detailed` | ~6000 tokens | 900-1500 | Complex projects, comprehensive handoffs |

### Other Settings

| Setting | Values | Description |
|---------|--------|-------------|
| `suggest_memories` | true/false | Whether to suggest memory additions |
| `auto_load` | true/false | Auto-load memory at session start |
| `output_style` | quiet/normal/explanatory | Output verbosity |
| `auto_sync_threshold` | 0-100 (default: 85) | Context % to trigger auto memory-sync |
| `hard_block_threshold` | 0-100 (default: 95) | Context % to block prompts until sync |
| `context_window_tokens` | integer (default: 1000000, 200000 for Haiku) | Context window size in tokens. Auto-detected from the running model if not set. |
| `context_brackets` | true/false (default: true) | Enable/disable context behavioral brackets |
| `bracket_warn` | 0-100 (default: 85) | Context % where the WARN bracket starts |
| `bracket_critical` | 0-100 (default: 95) | Context % where the CRITICAL bracket starts |
| `correction_sensitivity` | low/medium (default: low) | Regex sensitivity for correction detection |
| `staleness_commits` | integer (default: 5, 0 = disable) | Commits since last file update before flagging memory as stale |
| `project_search_paths` | absent=off, disabled=permanently off, array=active | Parent directories to search for cross-project memory |

## Workflow

### Step 1: Read Current Config

Check for `.claude/memory/.memory-config.md`:
- If exists: Read and display current settings
- If not: Display defaults (standard preset)

### Step 2: Display Current Settings

> **Current ConKeeper Configuration**
> - Token budget: [economy/light/standard/detailed] (default: standard)
> - Suggest memories: [true/false] (default: true)
> - Auto load: [true/false] (default: true)
> - Output style: [quiet/normal/explanatory] (default: normal)
> - Auto-sync threshold: [0-100] (default: 85)
> - Hard-block threshold: [0-100] (default: 95)
> - Context window tokens: [integer] (default: auto-detected from running model, fallback: 1000000; 200000 for Haiku)
> - Observation hook: [true/false] (default: true)
> - Observation detail: [full/stubs_only/off] (default: full)
> - Correction sensitivity: [low/medium] (default: low)
> - Auto-reflect: [true/false] (default: true)
> - Staleness commits: [integer] (default: 5, 0 = disable)
> - Project search paths: [absent/disabled/paths] (default: absent)

### Step 3: Ask What to Change

Ask the user which setting they'd like to change, or whether they're done. Accept natural language responses (e.g., "change output style to quiet", "disable auto-reflect").

### Step 4: Apply Changes

Update or create `.claude/memory/.memory-config.md`:

```yaml
---
token_budget: standard
suggest_memories: true
auto_load: true
output_style: normal
auto_sync_threshold: 85
hard_block_threshold: 95
context_window_tokens: 1000000
observation_hook: true
observation_detail: full
correction_sensitivity: low
auto_reflect: true
staleness_commits: 5
# project_search_paths: ["~/zed", "~/work"]  # absent = off, disabled = permanently off
---
```

## Observation Hook Settings

| Setting | Default | Options | Description |
|---------|---------|---------|-------------|
| `observation_hook` | `true` | `true`, `false` | Enable/disable PostToolUse observation logging |
| `observation_detail` | `full` | `full`, `stubs_only`, `off` | Detail level for observation entries |

- `full`: Full entries for Bash/external tools, stub entries for native tools
- `stubs_only`: Stub entries for all tools (timestamp, tool, type, path, status only)
- `off`: No observation logging (same as `observation_hook: false`)

> **Auto-detection:** If `context_window_tokens` is not explicitly set, ConKeeper detects
> the running model — first from the transcript's most recent assistant message, then from
> `~/.claude/settings.json` — and sizes the window accordingly. Every current non-Haiku model
> (Opus, Sonnet, and their `[1m]` variants) uses a 1,000,000 token window; Haiku uses 200,000.
> Unknown or future models default to 1,000,000. `CLAUDE_CODE_AUTO_COMPACT_WINDOW`, if set,
> caps the window. Set `context_window_tokens` explicitly to override auto-detection.

## Correction Detection Settings

| Setting | Default | Options | Description |
|---------|---------|---------|-------------|
| `correction_sensitivity` | `low` | `low`, `medium` | Regex sensitivity for detecting user corrections and friction |

- `low`: Conservative patterns only (fewer false positives, higher precision)
- `medium`: Adds looser patterns like "instead", "should be", "rather"

Note: `high` sensitivity was intentionally omitted — Claude Code's facets data
provides higher-accuracy retrospective friction classification. This hook is a
fast first-pass; `/memory-reflect` uses facets for accurate second-pass analysis.

Create `.correction-ignore` in project root to suppress specific patterns:
```
# Patterns to never flag as corrections
# One line per literal substring, matched case-insensitively
no worries
try again with verbose
```

## Reflection Settings

| Setting | Default | Options | Description |
|---------|---------|---------|-------------|
| `auto_reflect` | `true` | `true`, `false` | Auto-trigger /memory-reflect after /memory-sync |

Session depth (LIGHTWEIGHT vs STANDARD) is auto-detected based on observation and correction counts.

## Privacy Tags

Privacy tags are always enforced — there is no configuration toggle.
- Wrap sensitive content in `<private>...</private>` tags
- Add `private: true` to YAML front matter for entire-file privacy
- Private content is excluded from context injection, search, sync, and reflection

### Step 5: Confirm

> Configuration updated.
> - [Setting]: [old value] → [new value]
>
> Changes take effect in the next session.
