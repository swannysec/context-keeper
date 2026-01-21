# Memory Initialization Workflow

**Purpose:** Initialize the ConKeeper memory system for a project.

## Prerequisites

- Working directory must be a project root (has package.json, Cargo.toml, pyproject.toml, go.mod, or similar)
- Agent must have file write capabilities

## Workflow Steps

### 1. Pre-flight Checks

Check if memory already exists:
- Look for `.claude/memory/` directory
- Look for `.ai/memory/` directory (future standard)

If memory exists:
- Ask user: "Memory already exists. Would you like to reset it or review current state?"
- If reset: Backup existing and reinitialize
- If review: Read and summarize current memory files

### 2. Create Directory Structure

Create the following directories:
```
.claude/memory/
.claude/memory/decisions/
.claude/memory/sessions/
```

Alternative for cross-platform projects:
```
.ai/memory/
.ai/memory/decisions/
.ai/memory/sessions/
```

### 3. Gather Project Context

Collect information through conversation or codebase analysis:
- **Project purpose:** What is this project? (1-2 sentences)
- **Tech stack:** Primary languages, frameworks, tools
- **Architecture:** Key components and their relationships
- **Current focus:** What is the user working on now?

### 4. Create Initial Files

Create these files using templates from `core/memory/templates/`:

1. **product-context.md** - Populate with project overview, architecture, constraints
2. **active-context.md** - Set current focus based on user's immediate goals
3. **progress.md** - Initialize with any known tasks (can be empty)
4. **patterns.md** - Document any detected code patterns (can be empty)
5. **glossary.md** - Note any project-specific terms discovered (can be empty)

### 5. Configure Token Budget

Ask user about memory verbosity preference:
> "What token budget preset would you like?"
> - **Economy** (~2000 tokens): Minimal context, fast loading
> - **Light** (~3000 tokens): Smaller projects, lighter footprint
> - **Standard** (~4000 tokens): Balanced for most projects (default)
> - **Detailed** (~6000 tokens): Comprehensive context, rich handoffs

Create `.claude/memory/.memory-config.md` with their choice:
```yaml
---
token_budget: standard
---
```

If user accepts the default, this step can be skipped (standard is assumed).

### 6. Configure Git Tracking

Ask user about version control preference:
> "Should memory be tracked in git?"
> - **Yes** (recommended for solo projects): Memory persists with repo
> - **No** (recommended for shared repos): Add to .gitignore

If not tracking:
```bash
# Add to .gitignore (idempotent)
grep -qxF '.claude/memory/' .gitignore 2>/dev/null || echo '.claude/memory/' >> .gitignore
```

### 7. Confirm Completion

Output summary:
```
Memory initialized for [project-name]
- Product context: [brief summary]
- Current focus: [current focus]
- Token budget: [economy/light/standard/detailed]
- Git tracking: [yes/no]

Use memory-sync workflow to update memory as you work.
Use /memory-config to adjust settings later.
```

## Error Handling

- **No project markers found:** Warn user, offer to proceed anyway
- **Permission denied:** Inform user of permission issue
- **Existing memory conflict:** Always ask before overwriting

## Platform-Specific Notes

> **Note:** Shell command examples use Unix/bash syntax for illustration. Adapt for your platform's shell or use your AI assistant's file manipulation capabilities.

- **Claude Code:** Available as `/memory-init` command or skill
- **GitHub Copilot:** Available as contextual skill via custom instructions
- **Cursor:** Available as skill or via AGENTS.md guidance
- **Windsurf:** Available via `.windsurfrules` configuration
- **Cline/Roo Code:** Available via custom instructions or MCP configuration
- **Other platforms:** Follow manual workflow via AGENTS.md awareness
