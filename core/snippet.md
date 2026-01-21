# ConKeeper AGENTS.md Snippet

Add this snippet to your project's root `AGENTS.md` file to enable ConKeeper awareness across all AI coding assistants.

## Installation

### Option 1: Append to existing AGENTS.md

If you already have an AGENTS.md file:

```bash
cat >> AGENTS.md << 'EOF'

<!-- ConKeeper Memory System -->
## Memory System

This project uses ConKeeper for persistent AI context management.

**Memory Location:** `.claude/memory/` (or `.ai/memory/`)

**Available Workflows:**
- **memory-init** - Initialize memory for this project
- **memory-sync** - Sync session state to memory files  
- **session-handoff** - Generate handoff for new session

**Memory Files:**
- `active-context.md` - Current focus and state
- `product-context.md` - Project overview
- `progress.md` - Task tracking
- `decisions/` - Architecture Decision Records
- `sessions/` - Session summaries

**Usage:**
- Load memory at session start for non-trivial tasks
- Sync memory after significant progress
- Use handoff when context window fills

For full documentation: https://github.com/swannysec/context-keeper
<!-- /ConKeeper -->
EOF
```

### Option 2: Create new AGENTS.md

If you don't have an AGENTS.md file:

```bash
cat > AGENTS.md << 'EOF'
# AI Agent Instructions

<!-- ConKeeper Memory System -->
## Memory System

This project uses ConKeeper for persistent AI context management.

**Memory Location:** `.claude/memory/` (or `.ai/memory/`)

**Available Workflows:**
- **memory-init** - Initialize memory for this project
- **memory-sync** - Sync session state to memory files  
- **session-handoff** - Generate handoff for new session

**Memory Files:**
- `active-context.md` - Current focus and state
- `product-context.md` - Project overview
- `progress.md` - Task tracking
- `decisions/` - Architecture Decision Records
- `sessions/` - Session summaries

**Usage:**
- Load memory at session start for non-trivial tasks
- Sync memory after significant progress
- Use handoff when context window fills

For full documentation: https://github.com/swannysec/context-keeper
<!-- /ConKeeper -->
EOF
```

## Snippet Content (for manual copy/paste)

```markdown
<!-- ConKeeper Memory System -->
## Memory System

This project uses ConKeeper for persistent AI context management.

**Memory Location:** `.claude/memory/` (or `.ai/memory/`)

**Available Workflows:**
- **memory-init** - Initialize memory for this project
- **memory-sync** - Sync session state to memory files  
- **session-handoff** - Generate handoff for new session

**Memory Files:**
- `active-context.md` - Current focus and state
- `product-context.md` - Project overview
- `progress.md` - Task tracking
- `decisions/` - Architecture Decision Records
- `sessions/` - Session summaries

**Usage:**
- Load memory at session start for non-trivial tasks
- Sync memory after significant progress
- Use handoff when context window fills

For full documentation: https://github.com/swannysec/context-keeper
<!-- /ConKeeper -->
```

## Platform Compatibility

This snippet is read by:
- ✅ Claude Code (AGENTS.md support)
- ✅ GitHub Copilot (AGENTS.md support)
- ✅ OpenAI Codex (AGENTS.md native)
- ✅ Cursor (AGENTS.md support)
- ✅ Windsurf (AGENTS.md support, directory-scoped)
- ✅ Zed (AGENTS.md as rules source)

## Token Impact

The snippet is approximately 50-60 tokens, minimal impact on context window.

## Updating the Snippet

The HTML comments (`<!-- ConKeeper -->` and `<!-- /ConKeeper -->`) make it easy to find and update the snippet:

```bash
# Remove old snippet
sed -i '' '/<!-- ConKeeper Memory System -->/,/<!-- \/ConKeeper -->/d' AGENTS.md

# Add new snippet
cat >> AGENTS.md << 'EOF'
[new snippet content]
EOF
```

## Notes

- The snippet provides awareness only; detailed workflow instructions come from platform-native skills
- Users on platforms without native skill support get guidance from the snippet itself
- The snippet doesn't override any existing user instructions
