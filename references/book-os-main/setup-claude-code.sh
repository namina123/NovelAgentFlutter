#!/bin/bash

# Novel-OS Claude Code Setup Script
# This script installs Novel-OS commands for Claude Code

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

# Check for WSL environment first
if detect_wsl; then
    echo "🐧 WSL (Windows Subsystem for Linux) detected!"
    echo ""
    echo "For WSL users, we recommend using the WSL-optimized Claude Code installer:"
    echo "  curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-claude-code-wsl.sh | bash"
    echo ""
    echo "The WSL installer provides:"
    echo "  ✓ WSL-specific Claude Code configuration"
    echo "  ✓ Enhanced file access verification for WSL"
    echo "  ✓ Environment variables optimized for WSL"
    echo "  ✓ WSL-compatible CLAUDE.md template"
    echo ""
    echo "You can also continue with this installer, but the WSL-specific version is recommended."
    echo ""
    read -p "Continue with standard installer? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please use the WSL Claude Code installer for the best experience:"
        echo "  curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-claude-code-wsl.sh | bash"
        exit 0
    fi
    echo "Continuing with standard installer..."
    echo ""
fi

# Check for Windows environment (not WSL)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OS" == "Windows_NT" ]]; then
    echo "[WARN] Windows detected!"
    echo ""
    echo "For Windows users, please use the Windows batch file instead:"
    echo "  setup-claude-code.bat"
    echo ""
    echo "The batch file provides the same functionality but is optimized for Windows."
    echo "You can find setup-claude-code.bat in the same directory as this script."
    echo ""
    exit 1
fi

set -e  # Exit on error

echo "[INFO] Novel-OS Claude Code Setup"
echo "=================================="
echo ""

# Check if Novel-OS base installation is present
if [ ! -d "$HOME/.novel-os/instructions" ] || [ ! -d "$HOME/.novel-os/standards" ]; then
    echo "[WARN] Novel-OS base installation not found!"
    echo ""
    echo "Please install the Novel-OS base installation first:"
    echo ""
    echo "Option 1 - Automatic installation:"
    echo "  curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup.sh | bash"
    echo ""
    echo "Option 2 - Manual installation:"
    echo "  Follow instructions in the Novel-OS README"
    echo ""
    exit 1
fi

# Base URL for raw GitHub content
BASE_URL="https://raw.githubusercontent.com/forsonny/book-os/main/"

# Function to detect Agent-OS installation
detect_agent_os() {
    local agent_os_path="$HOME/.agent-os"
    local agent_os_commands="$HOME/.agent-os/commands"
    local agent_os_instructions="$HOME/.agent-os/instructions/core"
    
    # Check if Agent-OS directories exist
    if [ -d "$agent_os_path" ] && [ -d "$agent_os_commands" ] && [ -d "$agent_os_instructions" ]; then
        # Check for key Agent-OS files
        local found_commands=0
        local agent_os_files=("plan-product.md" "create-spec.md" "execute-tasks.md" "analyze-product.md")
        
        for cmd in "${agent_os_files[@]}"; do
            if [ -f "$agent_os_commands/$cmd" ]; then
                found_commands=$((found_commands + 1))
            fi
        done
        
        # Consider Agent-OS installed if at least 2 core commands are found
        if [ "$found_commands" -ge 2 ]; then
            return 0  # Agent-OS detected
        fi
    fi
    
    return 1  # No Agent-OS found
}

# Function to configure CLAUDE.md
configure_claude_md() {
    echo ""
    echo "[INFO] Configuring Claude Code for Novel-OS..."
    
    local claude_config="$HOME/.claude/CLAUDE.md"
    
    # Check if CLAUDE.md already exists
    if [ -f "$claude_config" ]; then
        # Backup existing file
        local backup_file="$claude_config.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$claude_config" "$backup_file"
        echo "  [WARN] Backed up existing CLAUDE.md to $(basename "$backup_file")"
        
        # Check if it already contains Novel-OS configuration
        if grep -q "Novel-OS.*Creative Writing" "$claude_config" && grep -q "/plan-novel.*novel planning" "$claude_config"; then
            echo "  [OK] CLAUDE.md already contains Novel-OS configuration - skipping"
            return 0
        fi
    fi
    
    # Detect if Agent-OS is installed
    if detect_agent_os; then
        echo "  [INFO] Agent-OS detected - using combined Novel-OS + Agent-OS template"
        local template_url="${BASE_URL}claude-code/CLAUDE.md.template"
    else
        echo "  [INFO] No Agent-OS found - using Novel-OS-only template"
        local template_url="${BASE_URL}claude-code/CLAUDE-novel-only.md.template"
    fi
    
    # Download the appropriate CLAUDE.md template
    if curl -s -o "$claude_config" "$template_url"; then
        echo "  [OK] CLAUDE.md configured successfully"
        return 0
    else
        echo "  [ERROR] Failed to download CLAUDE.md template"
        return 1
    fi
}

# Create directories
echo "[INFO] Creating directories..."
mkdir -p "$HOME/.claude/commands"
mkdir -p "$HOME/.claude/agents"
mkdir -p "$HOME/.claude/output-styles"

# Configure CLAUDE.md for Novel-OS
configure_claude_md

# Download command files for Claude Code
echo ""
echo "[INFO] Downloading Claude Code command files to ~/.claude/commands/"

# Commands
for cmd in plan-novel create-outline write-scenes analyze-manuscript; do
    if [ -f "$HOME/.claude/commands/${cmd}.md" ]; then
        echo "  [WARN] ~/.claude/commands/${cmd}.md already exists - skipping"
    else
        curl -s -o "$HOME/.claude/commands/${cmd}.md" "${BASE_URL}/commands/${cmd}.md"
        echo "  [OK] ~/.claude/commands/${cmd}.md"
    fi
done

# Download Claude Code agents
echo ""
echo "[INFO] Downloading Claude Code subagents to ~/.claude/agents/"

# List of agent files to download
agents=("prose-reviewer" "context-researcher" "writing-workflow" "manuscript-creator" "date-checker" "continuity-checker")

for agent in "${agents[@]}"; do
    if [ -f "$HOME/.claude/agents/${agent}.md" ]; then
        echo "  [WARN] ~/.claude/agents/${agent}.md already exists - skipping"
    else
        curl -s -o "$HOME/.claude/agents/${agent}.md" "${BASE_URL}/claude-code/agents/${agent}.md"
        echo "  [OK] ~/.claude/agents/${agent}.md"
    fi
done

# Install Novel-OS output style
echo ""
echo "[INFO] Installing Novel-OS output style to ~/.claude/output-styles/"

if [ -f "$HOME/.claude/output-styles/novel-os-assistant.md" ]; then
    echo "  [WARN] ~/.claude/output-styles/novel-os-assistant.md already exists - skipping"
else
    curl -s -o "$HOME/.claude/output-styles/novel-os-assistant.md" "${BASE_URL}/claude-code/output-styles/novel-os-assistant.md"
    echo "  [OK] ~/.claude/output-styles/novel-os-assistant.md"
fi

# Function to verify installation
verify_installation() {
    echo ""
    echo "[INFO] Verifying installation..."
    
    local missing_files=()
    local claude_config="$HOME/.claude/CLAUDE.md"
    
    # Check CLAUDE.md configuration
    if [ ! -f "$claude_config" ]; then
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
            
            if [ "$has_agent_os" = true ] && [ "$has_agent_os_config" = false ]; then
                echo "  [WARN] Agent-OS detected but CLAUDE.md uses Novel-OS-only template"
                echo "  [INFO] Consider re-running setup to upgrade to combined template"
            elif [ "$has_agent_os" = false ] && [ "$has_agent_os_config" = true ]; then
                echo "  [INFO] CLAUDE.md includes Agent-OS configuration but Agent-OS not installed"
            fi
        fi
    fi
    
    # Check command files
    local commands=("plan-novel" "create-outline" "write-scenes" "analyze-manuscript")
    for cmd in "${commands[@]}"; do
        if [ ! -f "$HOME/.claude/commands/${cmd}.md" ]; then
            missing_files+=("commands/${cmd}.md")
        fi
    done
    
    # Check agent files
    local agents=("prose-reviewer" "context-researcher" "writing-workflow" "manuscript-creator" "date-checker" "continuity-checker")
    for agent in "${agents[@]}"; do
        if [ ! -f "$HOME/.claude/agents/${agent}.md" ]; then
            missing_files+=("agents/${agent}.md")
        fi
    done
    
    # Check output style files
    local output_styles=("novel-os-assistant")
    for style in "${output_styles[@]}"; do
        if [ ! -f "$HOME/.claude/output-styles/${style}.md" ]; then
            missing_files+=("output-styles/${style}.md")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        echo "  [OK] All Claude Code files verified successfully!"
        return 0
    else
        echo "  [ERROR] Missing files detected:"
        for file in "${missing_files[@]}"; do
            echo "     Missing: $file"
        done
        return 1
    fi
}

# Verify installation
verify_installation

echo ""
echo "[OK] Novel-OS Claude Code installation complete!"
echo ""
echo "[INFO] Files installed to:"
echo "   ~/.claude/CLAUDE.md        - Claude Code configuration (Novel-OS + Agent-OS)"
echo "   ~/.claude/commands/        - Claude Code novel writing commands"
echo "   ~/.claude/agents/          - Claude Code specialized writing subagents"
echo "   ~/.claude/output-styles/   - Claude Code Novel-OS output style"
echo ""
echo "Next steps:"
echo ""
echo "For the best Novel-OS experience, switch to the writing-optimized output style:"
echo "  /output-style novel-os-assistant"
echo ""
echo "Start a new novel project with:"
echo "  /plan-novel"
echo ""
echo "Add Novel-OS to an existing manuscript with:"
echo "  /analyze-manuscript"
echo ""
echo "Create a story outline with:"
echo "  /create-outline (or simply ask 'what's next?')"
echo ""
echo "Write scenes and chapters with:"
echo "  /write-scenes"
echo ""
echo "Happy novel writing with AI assistance!"
echo ""
