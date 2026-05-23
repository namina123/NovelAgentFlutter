#!/bin/bash

# Novel-OS Claude Code WSL Setup Script
# This script installs Novel-OS commands for Claude Code in WSL environments

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

# Function to detect Agent-OS installation
detect_agent_os() {
    local agent_os_path="$HOME/.agent-os"
    local agent_os_commands="$HOME/.agent-os/commands"
    local agent_os_instructions="$HOME/.agent-os/instructions/core"
    
    # Check if Agent-OS directories exist
    if [[ -d "$agent_os_path" ]] && [[ -d "$agent_os_commands" ]] && [[ -d "$agent_os_instructions" ]]; then
        # Check for key Agent-OS files
        local found_commands=0
        local agent_os_files=("plan-product.md" "create-spec.md" "execute-tasks.md" "analyze-product.md")
        
        for cmd in "${agent_os_files[@]}"; do
            if [[ -f "$agent_os_commands/$cmd" ]]; then
                found_commands=$((found_commands + 1))
            fi
        done
        
        # Consider Agent-OS installed if at least 2 core commands are found
        if [[ "$found_commands" -ge 2 ]]; then
            return 0  # Agent-OS detected
        fi
    fi
    
    return 1  # No Agent-OS found
}

# Function to configure CLAUDE.md for WSL
configure_claude_md_wsl() {
    echo ""
    echo "🔧 Configuring Claude Code for Novel-OS in WSL..."
    
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
            return 0
        fi
    fi
    
    # Detect if Agent-OS is installed
    if detect_agent_os; then
        echo "  ℹ️  Agent-OS detected - using combined Novel-OS + Agent-OS template"
        local template_url="${BASE_URL}claude-code/CLAUDE.md.template"
    else
        echo "  ℹ️  No Agent-OS found - using Novel-OS-only template"
        local template_url="${BASE_URL}claude-code/CLAUDE-novel-only.md.template"
    fi
    
    # Download the appropriate CLAUDE.md template
    if download_file_wsl "$template_url" "$claude_config" "CLAUDE.md configuration" "true"; then
        echo "  ✓ CLAUDE.md configured successfully for WSL"
        return 0
    else
        echo "  ❌ Failed to download CLAUDE.md template"
        return 1
    fi
}

# Function to verify WSL installation
verify_wsl_installation() {
    echo ""
    echo "🔍 Verifying WSL installation..."
    
    local missing_files=()
    local claude_config="$HOME/.claude/CLAUDE.md"
    
    # Check CLAUDE.md configuration
    if [[ ! -f "$claude_config" ]]; then
        missing_files+=("CLAUDE.md configuration")
    else
        # Verify it contains Novel-OS configuration
        if ! grep -q "Novel-OS.*Creative Writing" "$claude_config" || ! grep -q "/plan-novel.*novel" "$claude_config"; then
            missing_files+=("CLAUDE.md (missing Novel-OS configuration)")
        else
            # Check if Agent-OS is present and verify template type matches
            if detect_agent_os; then
                has_agent_os=true
            else
                has_agent_os=false
            fi
            
            if grep -q "Agent-OS.*Software Development" "$claude_config" && grep -q "/create-spec.*feature" "$claude_config"; then
                has_agent_os_config=true
            else
                has_agent_os_config=false
            fi
            
            if [[ "$has_agent_os" == "true" ]] && [[ "$has_agent_os_config" == "false" ]]; then
                echo "  ⚠️  Agent-OS detected but CLAUDE.md uses Novel-OS-only template"
                echo "      Consider re-running setup to upgrade to combined template"
            elif [[ "$has_agent_os" == "false" ]] && [[ "$has_agent_os_config" == "true" ]]; then
                echo "  ℹ️  CLAUDE.md includes Agent-OS configuration but Agent-OS not installed"
            fi
        fi
    fi
    
    # Check command files
    local commands=("plan-novel" "create-outline" "write-scenes" "analyze-manuscript")
    for cmd in "${commands[@]}"; do
        if [[ ! -f "$HOME/.claude/commands/${cmd}.md" ]]; then
            missing_files+=("commands/${cmd}.md")
        fi
    done
    
    # Check agent files
    local agents=("prose-reviewer" "context-researcher" "writing-workflow" "manuscript-creator" "date-checker" "continuity-checker")
    for agent in "${agents[@]}"; do
        if [[ ! -f "$HOME/.claude/agents/${agent}.md" ]]; then
            missing_files+=("agents/${agent}.md")
        fi
    done
    
    # Check output style files
    local output_styles=("novel-os-assistant")
    for style in "${output_styles[@]}"; do
        if [[ ! -f "$HOME/.claude/output-styles/${style}.md" ]]; then
            missing_files+=("output-styles/${style}.md")
        fi
    done
    
    # WSL-specific file access verification
    echo "  🔧 Testing WSL file access..."
    for test_file in "$HOME/.claude/commands/plan-novel.md" "$HOME/.claude/CLAUDE.md"; do
        if [[ -f "$test_file" ]] && [[ -r "$test_file" ]]; then
            echo "    ✓ $(basename "$test_file") accessible"
        else
            echo "    ❌ $(basename "$test_file") not accessible"
            missing_files+=("$(basename "$test_file") (access issue)")
        fi
    done
    
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        echo "  ✅ All Claude Code files verified successfully in WSL!"
        return 0
    else
        echo "  ❌ Missing or inaccessible files detected:"
        for file in "${missing_files[@]}"; do
            echo "     Missing: $file"
        done
        return 1
    fi
}

echo "📚 Novel-OS Claude Code WSL Setup"
echo "=================================="
echo ""

# Detect WSL environment
if ! detect_wsl; then
    echo "⚠️  WSL environment not detected!"
    echo ""
    echo "This script is specifically designed for WSL (Windows Subsystem for Linux)."
    echo "For other environments, please use:"
    echo "  - Linux/macOS: setup-claude-code.sh"
    echo "  - Windows: setup-claude-code.bat"
    echo ""
    exit 1
fi

echo "✅ WSL environment detected"
echo ""

# Setup WSL environment
setup_wsl_environment

# Check if Novel-OS base installation is present
if [[ ! -d "$HOME/.novel-os/instructions" ]] || [[ ! -d "$HOME/.novel-os/standards" ]]; then
    echo "⚠️  Novel-OS base installation not found!"
    echo ""
    echo "Please install the Novel-OS base installation first with the WSL installer:"
    echo ""
    echo "Option 1 - WSL-specific installation (recommended):"
    echo "  curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-wsl.sh | bash"
    echo ""
    echo "Option 2 - Manual installation:"
    echo "  Follow WSL-specific instructions in the Novel-OS README"
    echo ""
    exit 1
fi

# Base URL for raw GitHub content
BASE_URL="https://raw.githubusercontent.com/forsonny/book-os/main/"

# Create directories
echo "📁 Creating Claude Code directories..."
mkdir -p "$HOME/.claude/commands"
mkdir -p "$HOME/.claude/agents"
mkdir -p "$HOME/.claude/output-styles"

# Set proper permissions for WSL
chmod -R 755 "$HOME/.claude"

# Configure CLAUDE.md for Novel-OS
configure_claude_md_wsl

# Download command files for Claude Code
echo ""
echo "📥 Downloading Claude Code command files to ~/.claude/commands/"

# Commands
for cmd in plan-novel create-outline write-scenes analyze-manuscript; do
    download_file_wsl "${BASE_URL}commands/${cmd}.md" "$HOME/.claude/commands/${cmd}.md" "~/.claude/commands/${cmd}.md" "false"
done

# Download Claude Code agents
echo ""
echo "📥 Downloading Claude Code subagents to ~/.claude/agents/"

# List of agent files to download
agents=("prose-reviewer" "context-researcher" "writing-workflow" "manuscript-creator" "date-checker" "continuity-checker")

for agent in "${agents[@]}"; do
    download_file_wsl "${BASE_URL}claude-code/agents/${agent}.md" "$HOME/.claude/agents/${agent}.md" "~/.claude/agents/${agent}.md" "false"
done

# Install Novel-OS output style
echo ""
echo "📥 Installing Novel-OS output style to ~/.claude/output-styles/"

download_file_wsl "${BASE_URL}claude-code/output-styles/novel-os-assistant.md" "$HOME/.claude/output-styles/novel-os-assistant.md" "~/.claude/output-styles/novel-os-assistant.md" "false"

# Verify installation
verify_wsl_installation

echo ""
echo "✅ Novel-OS Claude Code WSL installation complete!"
echo ""
echo "📁 WSL-optimized files installed to:"
echo "   ~/.claude/CLAUDE.md        - Claude Code configuration (WSL-compatible)"
echo "   ~/.claude/commands/        - Claude Code novel writing commands"
echo "   ~/.claude/agents/          - Claude Code specialized writing subagents"
echo "   ~/.claude/output-styles/   - Claude Code Novel-OS output style"
echo ""
echo "🎯 WSL-specific next steps:"
echo ""
echo "1. Restart your WSL session or run: source ~/.bashrc"
echo ""
echo "2. Test the installation:"
echo "   /plan-novel"
echo ""
echo "3. Switch to the Novel-OS writing style:"
echo "   /output-style novel-os-assistant"
echo ""
echo "4. Create a story outline:"
echo "   /create-outline (or simply ask 'what's next?')"
echo ""
echo "5. Write scenes and chapters:"
echo "   /write-scenes"
echo ""
echo "🎉 Happy novel writing with AI assistance in WSL!"
echo ""