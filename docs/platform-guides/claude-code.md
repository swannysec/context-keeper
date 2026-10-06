# ConKeeper for Claude Code

## Memory roots

New projects use `.ai/memory/`; existing legacy-only projects keep `.claude/memory/`. Global memory resolves independently between `~/.ai/memory/` and `~/.claude/memory/`. Both roots means prefer `.ai`, warn, and never merge. Paths shown below are new-project examples; substitute the selected legacy root when applicable. Use `bash <conkeeper-path>/tools/memory-root.sh` (or `--global`) to resolve without creating directories. All workflows use that root for settings, sessions, queues, decisions and handoffs. `AGENTS.md` is primary; the installer can also add the same instructions to `CLAUDE.md` as a compatibility fallback, preserving existing instructions.


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

`.ai/memory/` (new-project default; legacy-only projects retain `.claude/memory/`)

## Configuration

ConKeeper reads configuration from `.ai/memory/.memory-config.md`:

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
- Verify `.ai/memory/` exists
- Check file permissions

## Resources

- [Claude Code Documentation](https://docs.claude.ai/code)
- [ConKeeper Repository](https://github.com/swannysec/context-keeper)

## Optional durable knowledge

Set `knowledge_workspace` in the selected project/global `.memory-config.md` to an absolute containing vault/directory; absent project keys inherit global settings, a project path overrides, and false disables it. Existing memory workflows use relevant notes under `context-keeper/` with file tools. Candidate additions/changes always carry citation/provenance and a verbatim source excerpt for human review; auto-sync never approves promotion. See the packaged `core/workflows/durable-knowledge.md` and knowledge note/proposal templates. No new runtime dependency, manifest, migration or external service is required.
