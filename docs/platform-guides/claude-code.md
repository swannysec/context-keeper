# ConKeeper for Claude Code

Claude Code is the primary and fully-tested platform for ConKeeper.

## Status: ✅ Fully Tested

## Installation

### As a Plugin (Recommended)

1. Clone or download ConKeeper:
   ```bash
   git clone https://github.com/swannysec/context-keeper.git ~/.claude-plugins/context-keeper
   ```

2. The plugin auto-registers when Claude Code detects the plugin.json

### Manual Installation

Copy to your project's `.claude/` directory:
```bash
mkdir -p .claude/plugins/context-keeper
cp -r /path/to/context-keeper/* .claude/plugins/context-keeper/
```

## Features

### SessionStart Hook
ConKeeper includes a SessionStart hook that automatically:
- Checks for existing memory
- Loads relevant context
- Sets the output style mode

### Slash Commands
- `/memory-init` - Initialize memory system
- `/memory-sync` - Sync session to memory
- `/session-handoff` - Generate session handoff

### Skills
Skills are automatically discovered and can be invoked contextually or explicitly.

## Usage

### Initialize Memory
```
/memory-init
```
Or ask: "Initialize ConKeeper memory for this project"

### Sync Session
```
/memory-sync
```
Or ask: "Sync my session to memory"

### Session Handoff
```
/session-handoff
```
Or ask: "Create a session handoff"

## Memory Location

`.claude/memory/` (configurable)

## Configuration

ConKeeper reads configuration from `.claude/memory/.memory-config.md`:

```yaml
---
suggest_memories: true
auto_load: true
output_style: explanatory
---
```

## Verification

Test installation:
1. Start Claude Code in your project
2. Ask: "What memory workflows are available?"
3. Claude should reference memory-init, memory-sync, session-handoff

## Troubleshooting

### Hook not firing
- Check hooks/hooks.json exists
- Verify hook script is executable
- Check Claude Code logs

### Skills not discovered
- Verify skills directory structure
- Check SKILL.md files have valid frontmatter
- Run `/help` to see registered skills

### Memory not loading
- Run `/memory-init` first
- Verify `.claude/memory/` exists
- Check file permissions

## Resources

- [Claude Code Documentation](https://docs.claude.ai/code)
- [ConKeeper Repository](https://github.com/swannysec/context-keeper)
