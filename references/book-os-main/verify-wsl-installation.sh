#!/bin/bash

# Novel-OS WSL Installation Verification Script
# This script verifies that Novel-OS is properly installed and accessible in WSL

set -e

echo "📋 Novel-OS WSL Installation Verification"
echo "=========================================="
echo ""

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

# Function to check file accessibility
check_file_access() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]] && [[ -r "$file" ]] && [[ -s "$file" ]]; then
        echo "    ✅ $description"
        return 0
    elif [[ -f "$file" ]] && [[ ! -r "$file" ]]; then
        echo "    ❌ $description (exists but not readable)"
        return 1
    elif [[ -f "$file" ]] && [[ ! -s "$file" ]]; then
        echo "    ❌ $description (exists but empty)"
        return 1
    else
        echo "    ❌ $description (missing)"
        return 1
    fi
}

# Check WSL environment
echo "1️⃣ WSL Environment Detection"
if detect_wsl; then
    wsl_info=$(grep -o -i 'microsoft.*' /proc/version 2>/dev/null || echo "WSL detected")
    echo "   ✅ WSL detected: $wsl_info"
    
    # Additional WSL info
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        echo "   📋 Distribution: $WSL_DISTRO_NAME"
    fi
    if [[ -f /etc/os-release ]]; then
        distro_name=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
        echo "   📋 OS: $distro_name"
    fi
else
    echo "   ⚠️  WSL not detected - this script is designed for WSL environments"
    echo ""
    echo "If you're running in WSL, this might indicate a detection issue."
    echo "You can still continue with the verification."
    echo ""
fi
echo ""

# Check environment variables
echo "2️⃣ Environment Variables"
echo "   🏠 HOME: $HOME"
if [[ -n "$USERPROFILE" ]]; then
    echo "   🪟 USERPROFILE: $USERPROFILE"
fi
if [[ -n "$NOVEL_OS_HOME" ]]; then
    echo "   📚 NOVEL_OS_HOME: $NOVEL_OS_HOME"
else
    echo "   ⚠️  NOVEL_OS_HOME not set"
fi
echo "   📂 Current directory: $(pwd)"
echo ""

# Check Novel-OS base installation
echo "3️⃣ Novel-OS Base Installation"
novel_os_issues=0

if [[ -d "$HOME/.novel-os" ]]; then
    echo "   ✅ ~/.novel-os directory exists"
    
    # Check subdirectories
    if [[ -d "$HOME/.novel-os/standards" ]]; then
        echo "   ✅ standards directory exists"
    else
        echo "   ❌ standards directory missing"
        novel_os_issues=$((novel_os_issues + 1))
    fi
    
    if [[ -d "$HOME/.novel-os/instructions" ]]; then
        echo "   ✅ instructions directory exists"
    else
        echo "   ❌ instructions directory missing"
        novel_os_issues=$((novel_os_issues + 1))
    fi
    
    # Check core files
    echo "   📁 Core instruction files:"
    core_files=(
        "$HOME/.novel-os/instructions/core/plan-novel.md|plan-novel.md"
        "$HOME/.novel-os/instructions/core/create-outline.md|create-outline.md"
        "$HOME/.novel-os/instructions/core/write-scenes.md|write-scenes.md"
        "$HOME/.novel-os/instructions/core/write-scene.md|write-scene.md"
        "$HOME/.novel-os/instructions/core/analyze-manuscript.md|analyze-manuscript.md"
    )
    
    for file_info in "${core_files[@]}"; do
        IFS='|' read -r file_path file_name <<< "$file_info"
        if ! check_file_access "$file_path" "$file_name"; then
            novel_os_issues=$((novel_os_issues + 1))
        fi
    done
    
    echo "   📁 Standards files:"
    standards_files=(
        "$HOME/.novel-os/standards/writing-style.md|writing-style.md"
        "$HOME/.novel-os/standards/narrative-techniques.md|narrative-techniques.md"
    )
    
    for file_info in "${standards_files[@]}"; do
        IFS='|' read -r file_path file_name <<< "$file_info"
        if ! check_file_access "$file_path" "$file_name"; then
            novel_os_issues=$((novel_os_issues + 1))
        fi
    done
    
    echo "   📁 Meta files:"
    if ! check_file_access "$HOME/.novel-os/instructions/meta/pre-flight.md" "pre-flight.md"; then
        novel_os_issues=$((novel_os_issues + 1))
    fi
    
else
    echo "   ❌ ~/.novel-os directory missing"
    novel_os_issues=$((novel_os_issues + 1))
fi
echo ""

# Check Claude Code integration
echo "4️⃣ Claude Code Integration"
claude_issues=0

if [[ -d "$HOME/.claude" ]]; then
    echo "   ✅ ~/.claude directory exists"
    
    # Check CLAUDE.md
    echo "   📄 Configuration file:"
    if [[ -f "$HOME/.claude/CLAUDE.md" ]]; then
        if [[ -r "$HOME/.claude/CLAUDE.md" ]] && [[ -s "$HOME/.claude/CLAUDE.md" ]]; then
            echo "    ✅ CLAUDE.md (accessible)"
            
            # Check if it contains Novel-OS configuration
            if grep -q -i "novel-os" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
                echo "    ✅ Contains Novel-OS configuration"
            else
                echo "    ⚠️  May be missing Novel-OS configuration"
                claude_issues=$((claude_issues + 1))
            fi
        else
            echo "    ❌ CLAUDE.md (exists but not accessible or empty)"
            claude_issues=$((claude_issues + 1))
        fi
    else
        echo "    ❌ CLAUDE.md missing"
        claude_issues=$((claude_issues + 1))
    fi
    
    # Check command files
    echo "   📁 Command files:"
    command_files=(
        "$HOME/.claude/commands/plan-novel.md|plan-novel.md"
        "$HOME/.claude/commands/create-outline.md|create-outline.md"
        "$HOME/.claude/commands/write-scenes.md|write-scenes.md"
        "$HOME/.claude/commands/analyze-manuscript.md|analyze-manuscript.md"
    )
    
    for file_info in "${command_files[@]}"; do
        IFS='|' read -r file_path file_name <<< "$file_info"
        if ! check_file_access "$file_path" "$file_name"; then
            claude_issues=$((claude_issues + 1))
        fi
    done
    
    # Check agent files
    echo "   📁 Agent files:"
    agent_files=(
        "$HOME/.claude/agents/prose-reviewer.md|prose-reviewer.md"
        "$HOME/.claude/agents/context-researcher.md|context-researcher.md"
        "$HOME/.claude/agents/writing-workflow.md|writing-workflow.md"
        "$HOME/.claude/agents/manuscript-creator.md|manuscript-creator.md"
    )
    
    for file_info in "${agent_files[@]}"; do
        IFS='|' read -r file_path file_name <<< "$file_info"
        if ! check_file_access "$file_path" "$file_name"; then
            claude_issues=$((claude_issues + 1))
        fi
    done
    
    # Check output style
    echo "   📁 Output styles:"
    if ! check_file_access "$HOME/.claude/output-styles/novel-os-assistant.md" "novel-os-assistant.md"; then
        claude_issues=$((claude_issues + 1))
    fi
    
else
    echo "   ❌ ~/.claude directory missing"
    claude_issues=$((claude_issues + 1))
fi
echo ""

# Check file permissions
echo "5️⃣ File Permissions & Access"
permission_issues=0

echo "   🔒 Novel-OS file permissions:"
if [[ -d "$HOME/.novel-os" ]]; then
    novel_os_perms=$(ls -ld "$HOME/.novel-os" | cut -d' ' -f1)
    echo "    📋 ~/.novel-os permissions: $novel_os_perms"
    
    # Test write access
    if touch "$HOME/.novel-os/.test-write" 2>/dev/null; then
        rm -f "$HOME/.novel-os/.test-write"
        echo "    ✅ Write access confirmed"
    else
        echo "    ❌ No write access to ~/.novel-os"
        permission_issues=$((permission_issues + 1))
    fi
fi

echo "   🔒 Claude Code file permissions:"
if [[ -d "$HOME/.claude" ]]; then
    claude_perms=$(ls -ld "$HOME/.claude" | cut -d' ' -f1)
    echo "    📋 ~/.claude permissions: $claude_perms"
    
    # Test write access
    if touch "$HOME/.claude/.test-write" 2>/dev/null; then
        rm -f "$HOME/.claude/.test-write"
        echo "    ✅ Write access confirmed"
    else
        echo "    ❌ No write access to ~/.claude"
        permission_issues=$((permission_issues + 1))
    fi
fi
echo ""

# Test functional access
echo "6️⃣ Functional Testing"
functional_issues=0

echo "   🧪 Testing file content access:"
# Test reading a few key files
if [[ -f "$HOME/.novel-os/instructions/core/plan-novel.md" ]]; then
    if head -5 "$HOME/.novel-os/instructions/core/plan-novel.md" >/dev/null 2>&1; then
        echo "    ✅ Can read plan-novel.md content"
    else
        echo "    ❌ Cannot read plan-novel.md content"
        functional_issues=$((functional_issues + 1))
    fi
fi

if [[ -f "$HOME/.claude/commands/plan-novel.md" ]]; then
    if head -5 "$HOME/.claude/commands/plan-novel.md" >/dev/null 2>&1; then
        echo "    ✅ Can read Claude command content"
    else
        echo "    ❌ Cannot read Claude command content"
        functional_issues=$((functional_issues + 1))
    fi
fi

echo "   🧪 Testing path resolution:"
# Test path resolution with tilde
if [[ -f ~/.novel-os/instructions/core/plan-novel.md ]]; then
    echo "    ✅ Tilde path resolution works"
else
    echo "    ❌ Tilde path resolution fails"
    functional_issues=$((functional_issues + 1))
fi

# Test environment variable path resolution
if [[ -n "$NOVEL_OS_HOME" ]] && [[ -d "$NOVEL_OS_HOME" ]]; then
    echo "    ✅ Environment variable path resolution works"
else
    echo "    ⚠️  Environment variable path resolution not available"
fi
echo ""

# Summary
echo "📊 VERIFICATION SUMMARY"
echo "======================="
total_issues=$((novel_os_issues + claude_issues + permission_issues + functional_issues))

if [[ $total_issues -eq 0 ]]; then
    echo "🎉 SUCCESS: Novel-OS is properly installed and accessible in WSL!"
    echo ""
    echo "✅ Novel-OS base installation: Complete"
    echo "✅ Claude Code integration: Complete"
    echo "✅ File permissions: Correct"
    echo "✅ Functional testing: Passed"
    echo ""
    echo "🚀 You're ready to use Novel-OS commands like:"
    echo "   /plan-novel"
    echo "   /create-outline"
    echo "   /write-scenes"
    echo "   /analyze-manuscript"
else
    echo "⚠️  ISSUES FOUND: $total_issues total issues detected"
    echo ""
    if [[ $novel_os_issues -gt 0 ]]; then
        echo "❌ Novel-OS base installation: $novel_os_issues issues"
    else
        echo "✅ Novel-OS base installation: Complete"
    fi
    
    if [[ $claude_issues -gt 0 ]]; then
        echo "❌ Claude Code integration: $claude_issues issues"
    else
        echo "✅ Claude Code integration: Complete"
    fi
    
    if [[ $permission_issues -gt 0 ]]; then
        echo "❌ File permissions: $permission_issues issues"
    else
        echo "✅ File permissions: Correct"
    fi
    
    if [[ $functional_issues -gt 0 ]]; then
        echo "❌ Functional testing: $functional_issues issues"
    else
        echo "✅ Functional testing: Passed"
    fi
    
    echo ""
    echo "🔧 RECOMMENDED ACTIONS:"
    
    if [[ $novel_os_issues -gt 0 ]]; then
        echo "   • Reinstall Novel-OS base: curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-wsl.sh | bash"
    fi
    
    if [[ $claude_issues -gt 0 ]]; then
        echo "   • Reinstall Claude Code integration: curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-claude-code-wsl.sh | bash"
    fi
    
    if [[ $permission_issues -gt 0 ]]; then
        echo "   • Fix permissions: chmod -R 755 ~/.novel-os ~/.claude"
    fi
    
    echo "   • See troubleshooting guide: https://github.com/forsonny/book-os/blob/main/WSL_TROUBLESHOOTING.md"
fi
echo ""