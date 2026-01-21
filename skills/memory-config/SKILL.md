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

## Workflow

### Step 1: Read Current Config

Check for `.claude/memory/.memory-config.md`:
- If exists: Read and display current settings
- If not: Display defaults (standard preset)

### Step 2: Display Current Settings

> **Current ConKeeper Configuration**
> - Token budget: [compact/standard/detailed] (default: standard)
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

### Step 4: Apply Changes

Update or create `.claude/memory/.memory-config.md`:

```yaml
---
token_budget: standard
suggest_memories: true
auto_load: true
output_style: normal
---
```

### Step 5: Confirm

> Configuration updated.
> - [Setting]: [old value] → [new value]
>
> Changes take effect in the next session.
