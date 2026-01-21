#!/usr/bin/env bash
# ConKeeper Multi-Platform Installer
# Interactive setup for ConKeeper memory system across AI coding platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Security: Check if path is a symlink
check_not_symlink() {
    local path="$1"
    local desc="$2"
    if [ -L "$path" ]; then
        echo -e "${RED}Security Error: $desc is a symlink. Refusing to modify.${NC}"
        echo "Target: $(readlink -f "$path" 2>/dev/null || readlink "$path")"
        return 1
    fi
    return 0
}

# Get script directory (where ConKeeper is installed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║       ConKeeper Multi-Platform Installer          ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if we're in a project directory
if [ ! -f "package.json" ] && [ ! -f "Cargo.toml" ] && [ ! -f "pyproject.toml" ] && [ ! -f "go.mod" ] && [ ! -f "Makefile" ] && [ ! -f "README.md" ]; then
    echo -e "${YELLOW}Warning: This doesn't appear to be a project root.${NC}"
    read -p "Continue anyway? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Security: Refuse to run in sensitive directories
case "$(pwd)" in
    /|/etc|/usr|/bin|/sbin|/var|/tmp|/root|"$HOME")
        echo -e "${RED}Security Error: Refusing to run in system directory: $(pwd)${NC}"
        echo "Please run from a project directory."
        exit 1
        ;;
esac

# Detect available platforms
detect_platforms() {
    local platforms=()
    
    # Claude Code (check for .claude directory or hooks)
    if [ -d ".claude" ] || [ -f "plugin.json" ]; then
        platforms+=("claude-code")
    fi
    
    # Cursor
    if [ -d ".cursor" ]; then
        platforms+=("cursor")
    fi
    
    # GitHub Copilot
    if [ -d ".github" ]; then
        platforms+=("copilot")
    fi
    
    # OpenAI Codex
    if [ -d ".codex" ]; then
        platforms+=("codex")
    fi
    
    # Windsurf (check for .windsurfrules)
    if [ -f ".windsurfrules" ]; then
        platforms+=("windsurf")
    fi
    
    # Zed (check for .rules or rules config)
    if [ -f ".rules" ] || [ -f "AGENTS.md" ]; then
        platforms+=("zed")
    fi
    
    echo "${platforms[@]}"
}

# Install skills for a platform
install_skills() {
    local platform=$1
    local source_dir=""
    local target_dir=""
    
    case $platform in
        copilot)
            source_dir="${SCRIPT_DIR}/platforms/copilot/.github/skills"
            target_dir=".github/skills"
            ;;
        codex)
            source_dir="${SCRIPT_DIR}/platforms/codex/.codex/skills"
            target_dir=".codex/skills"
            ;;
        cursor)
            source_dir="${SCRIPT_DIR}/platforms/cursor/.cursor/skills"
            target_dir=".cursor/skills"
            ;;
    esac

    if [ -n "$source_dir" ]; then
        if [ ! -d "$source_dir" ]; then
            echo -e "${YELLOW}Warning: Skills source not found at ${source_dir}${NC}"
            return 1
        fi

        # Check target isn't a symlink
        if [ -e "$target_dir" ] && ! check_not_symlink "$target_dir" "Target directory $target_dir"; then
            return 1
        fi

        echo -e "${BLUE}Installing skills to ${target_dir}...${NC}"
        mkdir -p "$target_dir"

        local installed=0
        for skill in memory-init memory-sync session-handoff; do
            if [ -d "${source_dir}/${skill}" ]; then
                cp -r "${source_dir}/${skill}" "$target_dir/"
                ((installed++))
            fi
        done

        if [ $installed -gt 0 ]; then
            echo -e "${GREEN}✓ ${installed} skills installed for ${platform}${NC}"
        else
            echo -e "${YELLOW}Warning: No skills found to install${NC}"
        fi
    fi
}

# Install Windsurf rules
# Note: Small TOCTOU window exists between check and write.
# Acceptable for interactive CLI; not suitable for concurrent execution.
install_windsurf() {
    local source_file="${SCRIPT_DIR}/platforms/windsurf/.windsurfrules"

    if [ -f "$source_file" ]; then
        if [ -f ".windsurfrules" ]; then
            if ! check_not_symlink ".windsurfrules" ".windsurfrules"; then
                return 1
            fi
            echo -e "${YELLOW}Existing .windsurfrules found.${NC}"
            read -p "Append ConKeeper rules? [Y/n] " response
            if [[ ! "$response" =~ ^[Nn]$ ]]; then
                echo "" >> .windsurfrules
                echo "# --- ConKeeper Memory System ---" >> .windsurfrules
                cat "$source_file" >> .windsurfrules
                echo -e "${GREEN}✓ ConKeeper rules appended to .windsurfrules${NC}"
            fi
        else
            # Check if path exists as symlink (but not regular file)
            if [ -L ".windsurfrules" ]; then
                echo -e "${RED}Security Error: .windsurfrules is a symlink. Refusing to modify.${NC}"
                echo "Target: $(readlink -f ".windsurfrules" 2>/dev/null || readlink ".windsurfrules")"
                return 1
            fi
            cp "$source_file" .windsurfrules
            echo -e "${GREEN}✓ Created .windsurfrules${NC}"
        fi
    fi
}

# Add AGENTS.md snippet
# Note: Small TOCTOU window exists between check and write.
# Acceptable for interactive CLI; not suitable for concurrent execution.
add_agents_snippet() {
    local snippet='
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
<!-- /ConKeeper -->'

    if [ -f "AGENTS.md" ]; then
        if ! check_not_symlink "AGENTS.md" "AGENTS.md"; then
            return 1
        fi
        if grep -q "ConKeeper Memory System" AGENTS.md 2>/dev/null; then
            echo -e "${GREEN}✓ ConKeeper already in AGENTS.md${NC}"
            return
        fi

        echo -e "${YELLOW}Existing AGENTS.md found.${NC}"
        read -p "Append ConKeeper snippet? [Y/n] " response
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            echo "$snippet" >> AGENTS.md
            echo -e "${GREEN}✓ ConKeeper snippet added to AGENTS.md${NC}"
        fi
    else
        # Check if path exists as symlink (but not regular file)
        if [ -L "AGENTS.md" ]; then
            echo -e "${RED}Security Error: AGENTS.md is a symlink. Refusing to modify.${NC}"
            echo "Target: $(readlink -f "AGENTS.md" 2>/dev/null || readlink "AGENTS.md")"
            return 1
        fi
        read -p "Create AGENTS.md with ConKeeper snippet? [Y/n] " response
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            echo "# AI Agent Instructions" > AGENTS.md
            echo "$snippet" >> AGENTS.md
            echo -e "${GREEN}✓ Created AGENTS.md with ConKeeper snippet${NC}"
        fi
    fi
}

# Main installation flow
main() {
    echo "Detecting platforms..."
    IFS=' ' read -ra detected <<< "$(detect_platforms)"
    
    if [ ${#detected[@]} -gt 0 ]; then
        echo -e "${GREEN}Detected platforms:${NC} ${detected[*]}"
    else
        echo -e "${YELLOW}No specific platform directories detected.${NC}"
    fi
    
    echo ""
    echo "Available installations:"
    echo "  1. AGENTS.md snippet (universal, all platforms)"
    echo "  2. GitHub Copilot skills (.github/skills/)"
    echo "  3. OpenAI Codex skills (.codex/skills/)"
    echo "  4. Cursor skills (.cursor/skills/)"
    echo "  5. Windsurf rules (.windsurfrules)"
    echo "  6. All of the above"
    echo ""
    
    while true; do
        read -p "What would you like to install? [1-6, or 'q' to quit]: " choice

        case $choice in
            1)
                add_agents_snippet
                break
                ;;
            2)
                mkdir -p .github
                install_skills copilot
                break
                ;;
            3)
                mkdir -p .codex
                install_skills codex
                break
                ;;
            4)
                mkdir -p .cursor
                install_skills cursor
                break
                ;;
            5)
                install_windsurf
                break
                ;;
            6)
                add_agents_snippet
                mkdir -p .github && install_skills copilot
                mkdir -p .codex && install_skills codex
                mkdir -p .cursor && install_skills cursor
                install_windsurf
                break
                ;;
            q|Q)
                echo "Installation cancelled."
                exit 0
                ;;
            *)
                echo -e "${YELLOW}Invalid choice. Please enter 1-6 or 'q'.${NC}"
                ;;
        esac
    done
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            Installation Complete!                 ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Initialize memory: Ask your AI to 'initialize ConKeeper memory'"
    echo "  2. Sync regularly: 'sync session to memory'"
    echo "  3. Handoff sessions: 'create session handoff'"
    echo ""
    echo "Documentation: https://github.com/swannysec/context-keeper"
}

main
