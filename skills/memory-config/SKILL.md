---
name: memory-config
description: View and modify ConKeeper memory configuration settings. Use to adjust token budget, output style, and other preferences after memory initialization.
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
| `auto_sync_threshold` | 0-100 (default: 60) | Context % to trigger auto memory-sync |
| `hard_block_threshold` | 0-100 (default: 80) | Context % to block prompts until sync |
| `context_window_tokens` | integer (default: 200000) | Context window size in tokens |
| `correction_sensitivity` | low/medium (default: low) | Regex sensitivity for correction detection |

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

### Step 3: Ask What to Change

> What would you like to change?
> 1. Token budget preset
> 2. Suggest memories setting
> 3. Auto load setting
> 4. Output style
> 5. Nothing (exit)
> 6. Auto-sync threshold
> 7. Hard-block threshold
> 8. Context window size
> 9. Observation hook (enable/disable)
> 10. Observation detail level
> 11. Correction sensitivity

### Step 4: Apply Changes

Update or create `.claude/memory/.memory-config.md`:

```yaml
---
token_budget: standard
suggest_memories: true
auto_load: true
output_style: normal
auto_sync_threshold: 60
hard_block_threshold: 80
context_window_tokens: 200000
observation_hook: true
observation_detail: full
correction_sensitivity: low
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
