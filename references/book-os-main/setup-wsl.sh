#!/bin/bash

# Novel-OS WSL Setup Script
# This script installs Novel-OS files specifically for WSL environments

set -e  # Exit on error

# Function to detect WSL environment
detect_wsl() {
    if [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
        return 0  # WSL detected
    elif [[ -f /proc/version ]] && grep -q microsoft /proc/version; then
        return 0  # WSL2 detected
    elif [[ -n "$WSL_DISTRO_NAME" ]]; then
        return 0  # WSL environment variable detected
    elif [[ "$OSTYPE" == "linux-gnu"* ]] && [[ "$(uname -r)" == *Microsoft* ]]; then
        return 0  # WSL kernel detected
    fi
    return 1  # Not WSL
}

# Function to setup WSL environment variables
setup_wsl_environment() {
    echo "🔧 Setting up WSL environment variables..."
    
    # Ensure HOME is properly set for WSL
    if [[ -z "$HOME" ]] || [[ "$HOME" == "/root" ]] && [[ "$(whoami)" != "root" ]]; then
        export HOME="/home/$(whoami)"
        echo "  ✓ HOME set to: $HOME"
    fi
    
    # Set Novel-OS environment variable for consistent access
    export NOVEL_OS_HOME="$HOME/.novel-os"
    echo "  ✓ NOVEL_OS_HOME set to: $NOVEL_OS_HOME"
    
    # Add to bashrc if not already present
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "NOVEL_OS_HOME" "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# Novel-OS environment variables" >> "$bashrc"
        echo "export NOVEL_OS_HOME=\"\$HOME/.novel-os\"" >> "$bashrc"
        echo "  ✓ Added NOVEL_OS_HOME to ~/.bashrc for future sessions"
    fi
}

# Function to verify WSL file system access
verify_wsl_file_access() {
    echo "🔍 Verifying WSL file system access..."
    
    # Test creating and accessing a temporary file
    local test_file="$HOME/.novel-os-wsl-test"
    if touch "$test_file" 2>/dev/null && [[ -f "$test_file" ]]; then
        rm -f "$test_file"
        echo "  ✓ File system access verified"
        return 0
    else
        echo "  ❌ File system access issue detected"
        echo "  Please ensure you have write permissions to $HOME"
        return 1
    fi
}

# Function to create WSL-compatible directories
create_wsl_directories() {
    echo "📁 Creating WSL-compatible directories..."
    
    # Use explicit home path to avoid any path resolution issues
    local novel_os_path="$HOME/.novel-os"
    local claude_path="$HOME/.claude"
    
    # Create Novel-OS directories with proper permissions
    mkdir -p "$novel_os_path/standards"
    mkdir -p "$novel_os_path/standards/writing-style"
    mkdir -p "$novel_os_path/standards/genre-guides"
    mkdir -p "$novel_os_path/instructions/core"
    mkdir -p "$novel_os_path/instructions/meta"
    
    # Create Claude Code directories
    mkdir -p "$claude_path/commands"
    mkdir -p "$claude_path/agents"
    mkdir -p "$claude_path/output-styles"
    
    # Set proper permissions for WSL
    chmod -R 755 "$novel_os_path" "$claude_path"
    
    echo "  ✓ All directories created with proper WSL permissions"
}

# Initialize flags
OVERWRITE_INSTRUCTIONS=false
OVERWRITE_STANDARDS=false
SKIP_CLAUDE_SETUP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --overwrite-instructions)
            OVERWRITE_INSTRUCTIONS=true
            shift
            ;;
        --overwrite-standards)
            OVERWRITE_STANDARDS=true
            shift
            ;;
        --skip-claude-setup)
            SKIP_CLAUDE_SETUP=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "WSL-specific Novel-OS installation script"
            echo ""
            echo "Options:"
            echo "  --overwrite-instructions    Overwrite existing instruction files"
            echo "  --overwrite-standards       Overwrite existing standards files"
            echo "  --skip-claude-setup         Skip Claude Code setup (Novel-OS only)"
            echo "  -h, --help                  Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "📚 Novel-OS WSL Setup Script"
echo "============================"
echo ""

# Detect WSL environment
if ! detect_wsl; then
    echo "⚠️  WSL environment not detected!"
    echo ""
    echo "This script is specifically designed for WSL (Windows Subsystem for Linux)."
    echo "For other environments, please use:"
    echo "  - Linux/macOS: setup.sh"
    echo "  - Windows: setup.bat"
    echo ""
    exit 1
fi

echo "✅ WSL environment detected"
echo ""

# Setup WSL environment
setup_wsl_environment

# Verify file access
if ! verify_wsl_file_access; then
    exit 1
fi

# Create directories
create_wsl_directories

# Base URL for raw GitHub content
BASE_URL="https://raw.githubusercontent.com/forsonny/book-os/main/"

# Download standards files
echo ""
echo "📥 Downloading writing standards files to ~/.novel-os/standards/"

# Function to download file with WSL-specific error handling
download_file_wsl() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    local overwrite_flag="$4"
    
    if [[ -f "$output_path" ]] && [[ "$overwrite_flag" == "false" ]]; then
        echo "  ⚠️  $description already exists - skipping"
        return 0
    fi
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$output_path")"
    
    # Download with curl, using WSL-compatible options
    if curl -s -L --fail --max-time 30 -o "$output_path" "$url"; then
        # Verify file was downloaded and has content
        if [[ -f "$output_path" ]] && [[ -s "$output_path" ]]; then
            if [[ "$overwrite_flag" == "true" ]] && [[ -f "$output_path" ]]; then
                echo "  ✓ $description (overwritten)"
            else
                echo "  ✓ $description"
            fi
            return 0
        else
            echo "  ❌ $description (downloaded but empty/invalid)"
            return 1
        fi
    else
        echo "  ❌ $description (download failed)"
        return 1
    fi
}

# Download all Novel-OS files with WSL-specific handling
files_to_download=(
    "${BASE_URL}standards/writing-style.md|$HOME/.novel-os/standards/writing-style.md|~/.novel-os/standards/writing-style.md|$OVERWRITE_STANDARDS"
    "${BASE_URL}standards/narrative-techniques.md|$HOME/.novel-os/standards/narrative-techniques.md|~/.novel-os/standards/narrative-techniques.md|$OVERWRITE_STANDARDS"
    "${BASE_URL}standards/writing-style/description-style.md|$HOME/.novel-os/standards/writing-style/description-style.md|~/.novel-os/standards/writing-style/description-style.md|$OVERWRITE_STANDARDS"
    "${BASE_URL}standards/genre-guides/literary-fiction.md|$HOME/.novel-os/standards/genre-guides/literary-fiction.md|~/.novel-os/standards/genre-guides/literary-fiction.md|$OVERWRITE_STANDARDS"
    "${BASE_URL}standards/genre-guides/mystery-thriller.md|$HOME/.novel-os/standards/genre-guides/mystery-thriller.md|~/.novel-os/standards/genre-guides/mystery-thriller.md|$OVERWRITE_STANDARDS"
    "${BASE_URL}standards/genre-guides/fantasy-sci-fi.md|$HOME/.novel-os/standards/genre-guides/fantasy-sci-fi.md|~/.novel-os/standards/genre-guides/fantasy-sci-fi.md|$OVERWRITE_STANDARDS"
    "${BASE_URL}instructions/core/plan-novel.md|$HOME/.novel-os/instructions/core/plan-novel.md|~/.novel-os/instructions/core/plan-novel.md|$OVERWRITE_INSTRUCTIONS"
    "${BASE_URL}instructions/core/create-outline.md|$HOME/.novel-os/instructions/core/create-outline.md|~/.novel-os/instructions/core/create-outline.md|$OVERWRITE_INSTRUCTIONS"
    "${BASE_URL}instructions/core/write-scenes.md|$HOME/.novel-os/instructions/core/write-scenes.md|~/.novel-os/instructions/core/write-scenes.md|$OVERWRITE_INSTRUCTIONS"
    "${BASE_URL}instructions/core/write-scene.md|$HOME/.novel-os/instructions/core/write-scene.md|~/.novel-os/instructions/core/write-scene.md|$OVERWRITE_INSTRUCTIONS"
    "${BASE_URL}instructions/core/analyze-manuscript.md|$HOME/.novel-os/instructions/core/analyze-manuscript.md|~/.novel-os/instructions/core/analyze-manuscript.md|$OVERWRITE_INSTRUCTIONS"
    "${BASE_URL}instructions/meta/pre-flight.md|$HOME/.novel-os/instructions/meta/pre-flight.md|~/.novel-os/instructions/meta/pre-flight.md|$OVERWRITE_INSTRUCTIONS"
)

# Download Novel-OS files
for file_info in "${files_to_download[@]}"; do
    IFS='|' read -r url output_path description overwrite_flag <<< "$file_info"
    download_file_wsl "$url" "$output_path" "$description" "$overwrite_flag"
done

# Claude Code setup
if [[ "$SKIP_CLAUDE_SETUP" == "false" ]]; then
    echo ""
    echo "📥 Setting up Claude Code integration..."
    
    # Download Claude Code files
    claude_files_to_download=(
        "${BASE_URL}commands/plan-novel.md|$HOME/.claude/commands/plan-novel.md|~/.claude/commands/plan-novel.md|false"
        "${BASE_URL}commands/create-outline.md|$HOME/.claude/commands/create-outline.md|~/.claude/commands/create-outline.md|false"
        "${BASE_URL}commands/write-scenes.md|$HOME/.claude/commands/write-scenes.md|~/.claude/commands/write-scenes.md|false"
        "${BASE_URL}commands/analyze-manuscript.md|$HOME/.claude/commands/analyze-manuscript.md|~/.claude/commands/analyze-manuscript.md|false"
        "${BASE_URL}claude-code/agents/prose-reviewer.md|$HOME/.claude/agents/prose-reviewer.md|~/.claude/agents/prose-reviewer.md|false"
        "${BASE_URL}claude-code/agents/context-researcher.md|$HOME/.claude/agents/context-researcher.md|~/.claude/agents/context-researcher.md|false"
        "${BASE_URL}claude-code/agents/writing-workflow.md|$HOME/.claude/agents/writing-workflow.md|~/.claude/agents/writing-workflow.md|false"
        "${BASE_URL}claude-code/agents/manuscript-creator.md|$HOME/.claude/agents/manuscript-creator.md|~/.claude/agents/manuscript-creator.md|false"
        "${BASE_URL}claude-code/agents/date-checker.md|$HOME/.claude/agents/date-checker.md|~/.claude/agents/date-checker.md|false"
        "${BASE_URL}claude-code/agents/continuity-checker.md|$HOME/.claude/agents/continuity-checker.md|~/.claude/agents/continuity-checker.md|false"
        "${BASE_URL}claude-code/output-styles/novel-os-assistant.md|$HOME/.claude/output-styles/novel-os-assistant.md|~/.claude/output-styles/novel-os-assistant.md|false"
    )
    
    for file_info in "${claude_files_to_download[@]}"; do
        IFS='|' read -r url output_path description overwrite_flag <<< "$file_info"
        download_file_wsl "$url" "$output_path" "$description" "$overwrite_flag"
    done
    
    # Configure CLAUDE.md for WSL
    echo ""
    echo "🔧 Configuring CLAUDE.md for WSL environment..."
    
    local claude_config="$HOME/.claude/CLAUDE.md"
    
    # Check if CLAUDE.md already exists
    if [[ -f "$claude_config" ]]; then
        # Backup existing file
        local backup_file="$claude_config.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$claude_config" "$backup_file"
        echo "  ⚠️  Backed up existing CLAUDE.md to $(basename "$backup_file")"
        
        # Check if it already contains Novel-OS configuration
        if grep -q "Novel-OS.*Creative Writing" "$claude_config" && grep -q "/plan-novel.*novel planning" "$claude_config"; then
            echo "  ✓ CLAUDE.md already contains Novel-OS configuration - skipping"
        else
            # Download Novel-OS-only template for WSL
            if download_file_wsl "${BASE_URL}claude-code/CLAUDE-novel-only.md.template" "$claude_config" "CLAUDE.md configuration" "true"; then
                echo "  ✓ CLAUDE.md configured for Novel-OS in WSL"
            fi
        fi
    else
        # Download Novel-OS-only template for WSL
        if download_file_wsl "${BASE_URL}claude-code/CLAUDE-novel-only.md.template" "$claude_config" "CLAUDE.md configuration" "false"; then
            echo "  ✓ CLAUDE.md configured for Novel-OS in WSL"
        fi
    fi
fi

# WSL-specific verification
echo ""
echo "🔍 WSL-specific verification..."

# Test file access with full paths
test_files=(
    "$HOME/.novel-os/instructions/core/plan-novel.md"
    "$HOME/.novel-os/standards/writing-style.md"
)

if [[ "$SKIP_CLAUDE_SETUP" == "false" ]]; then
    test_files+=(
        "$HOME/.claude/commands/plan-novel.md"
        "$HOME/.claude/CLAUDE.md"
    )
fi

all_files_accessible=true
for test_file in "${test_files[@]}"; do
    if [[ -f "$test_file" ]] && [[ -r "$test_file" ]]; then
        echo "  ✓ $(basename "$test_file") accessible"
    else
        echo "  ❌ $(basename "$test_file") not accessible"
        all_files_accessible=false
    fi
done

if [[ "$all_files_accessible" == "true" ]]; then
    echo "  ✅ All files verified and accessible in WSL"
else
    echo "  ❌ Some files are not accessible - installation may be incomplete"
    exit 1
fi

echo ""
echo "✅ Novel-OS WSL installation complete!"
echo ""
echo "📍 WSL-specific configuration:"
echo "   Environment variables added to ~/.bashrc"
echo "   File permissions optimized for WSL"
echo "   Path resolution tested and verified"
echo ""
echo "📁 Files installed to:"
echo "   ~/.novel-os/standards/     - Your writing standards"
echo "   ~/.novel-os/instructions/  - Novel-OS instructions"
if [[ "$SKIP_CLAUDE_SETUP" == "false" ]]; then
    echo "   ~/.claude/commands/        - Claude Code commands"
    echo "   ~/.claude/agents/          - Claude Code subagents"
    echo "   ~/.claude/CLAUDE.md        - Claude Code configuration"
fi
echo ""
echo "🎯 Next steps for WSL users:"
echo ""
echo "1. Restart your WSL session or run: source ~/.bashrc"
echo ""
if [[ "$SKIP_CLAUDE_SETUP" == "false" ]]; then
    echo "2. Test Novel-OS with Claude Code:"
    echo "   /plan-novel"
    echo ""
    echo "3. Switch to the Novel-OS writing style:"
    echo "   /output-style novel-os-assistant"
    echo ""
fi
echo "🎉 Happy novel writing with AI assistance in WSL!"
echo ""