#!/usr/bin/env bash
# ConKeeper Build Script
# Generates distributable packages for each platform

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/dist"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║         ConKeeper Build Script                    ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# Clean and create build directory
# Sanity check before rm -rf
if [[ ! "$BUILD_DIR" =~ /dist$ ]] || [ -z "$SCRIPT_DIR" ]; then
    echo -e "${RED}ERROR: BUILD_DIR doesn't look safe: $BUILD_DIR${NC}"
    exit 1
fi
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build Claude Code package (original plugin)
build_claude_code() {
    echo "Building Claude Code package..."
    local pkg_dir="${BUILD_DIR}/claude-code"
    mkdir -p "$pkg_dir"
    
    cp "${SCRIPT_DIR}/plugin.json" "$pkg_dir/"
    cp -r "${SCRIPT_DIR}/skills" "$pkg_dir/"
    cp -r "${SCRIPT_DIR}/commands" "$pkg_dir/"
    cp -r "${SCRIPT_DIR}/hooks" "$pkg_dir/"
    cp "${SCRIPT_DIR}/README.md" "$pkg_dir/"
    cp "${SCRIPT_DIR}/LICENSE" "$pkg_dir/"
    
    echo -e "${GREEN}✓ Claude Code package built${NC}"
}

# Build Copilot package
build_copilot() {
    echo "Building GitHub Copilot package..."
    local pkg_dir="${BUILD_DIR}/copilot"
    mkdir -p "$pkg_dir"
    
    cp -r "${SCRIPT_DIR}/platforms/copilot/.github" "$pkg_dir/"
    cp "${SCRIPT_DIR}/platforms/copilot/README.md" "$pkg_dir/"
    cp "${SCRIPT_DIR}/core/snippet.md" "$pkg_dir/AGENTS-SNIPPET.md"
    
    echo -e "${GREEN}✓ GitHub Copilot package built${NC}"
}

# Build Codex package
build_codex() {
    echo "Building OpenAI Codex package..."
    local pkg_dir="${BUILD_DIR}/codex"
    mkdir -p "$pkg_dir"
    
    cp -r "${SCRIPT_DIR}/platforms/codex/.codex" "$pkg_dir/"
    cp "${SCRIPT_DIR}/platforms/codex/README.md" "$pkg_dir/"
    cp "${SCRIPT_DIR}/core/snippet.md" "$pkg_dir/AGENTS-SNIPPET.md"
    
    echo -e "${GREEN}✓ OpenAI Codex package built${NC}"
}

# Build Cursor package
build_cursor() {
    echo "Building Cursor package..."
    local pkg_dir="${BUILD_DIR}/cursor"
    mkdir -p "$pkg_dir"
    
    cp -r "${SCRIPT_DIR}/platforms/cursor/.cursor" "$pkg_dir/"
    cp "${SCRIPT_DIR}/platforms/cursor/README.md" "$pkg_dir/"
    cp "${SCRIPT_DIR}/core/snippet.md" "$pkg_dir/AGENTS-SNIPPET.md"
    
    echo -e "${GREEN}✓ Cursor package built${NC}"
}

# Build Windsurf package
build_windsurf() {
    echo "Building Windsurf package..."
    local pkg_dir="${BUILD_DIR}/windsurf"
    mkdir -p "$pkg_dir"
    
    cp "${SCRIPT_DIR}/platforms/windsurf/.windsurfrules" "$pkg_dir/"
    cp "${SCRIPT_DIR}/platforms/windsurf/README.md" "$pkg_dir/"
    cp "${SCRIPT_DIR}/core/snippet.md" "$pkg_dir/AGENTS-SNIPPET.md"
    
    echo -e "${GREEN}✓ Windsurf package built${NC}"
}

# Build Zed package
build_zed() {
    echo "Building Zed package..."
    local pkg_dir="${BUILD_DIR}/zed"
    mkdir -p "$pkg_dir"
    
    cp -r "${SCRIPT_DIR}/platforms/zed/rules-library" "$pkg_dir/"
    cp "${SCRIPT_DIR}/platforms/zed/README.md" "$pkg_dir/"
    cp "${SCRIPT_DIR}/core/snippet.md" "$pkg_dir/AGENTS-SNIPPET.md"
    
    echo -e "${GREEN}✓ Zed package built${NC}"
}

# Build universal package (just AGENTS.md snippet + core)
build_universal() {
    echo "Building universal package..."
    local pkg_dir="${BUILD_DIR}/universal"
    mkdir -p "$pkg_dir"
    
    cp -r "${SCRIPT_DIR}/core" "$pkg_dir/"
    cp "${SCRIPT_DIR}/tools/install.sh" "$pkg_dir/"
    
    # Create simple README
    cat > "${pkg_dir}/README.md" << 'EOF'
# ConKeeper Universal Package

This package contains the core ConKeeper memory system for use with any AI coding assistant.

## Contents

- `core/snippet.md` - AGENTS.md snippet to add to your project
- `core/memory/schema.md` - Memory file format specification
- `core/memory/templates/` - Template files for memory initialization
- `core/workflows/` - Platform-agnostic workflow specifications
- `install.sh` - Interactive installer script

## Quick Start

1. Add the snippet from `core/snippet.md` to your project's AGENTS.md
2. Ask your AI assistant to "initialize ConKeeper memory"
3. Use memory-sync and session-handoff as needed

## Platform-Specific Packages

For native skill support, download the platform-specific package:
- Claude Code: Full plugin support
- GitHub Copilot: Native skills
- OpenAI Codex: Native skills  
- Cursor: Native skills (nightly)
- Windsurf: .windsurfrules
- Zed: Rules Library

See https://github.com/swannysec/context-keeper for details.
EOF
    
    echo -e "${GREEN}✓ Universal package built${NC}"
}

# Main
main() {
    build_claude_code
    build_copilot
    build_codex
    build_cursor
    build_windsurf
    build_zed
    build_universal
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              Build Complete!                      ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Packages built in: ${BUILD_DIR}"
    echo ""
    ls -la "$BUILD_DIR"
}

main
