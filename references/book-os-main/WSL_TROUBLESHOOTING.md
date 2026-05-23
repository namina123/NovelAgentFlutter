# Novel-OS WSL Troubleshooting Guide

This guide helps resolve common issues when using Novel-OS with Claude Code in WSL (Windows Subsystem for Linux) environments.

## Common Issues and Solutions

### 1. "Novel-OS files aren't accessible from this environment"

This error typically occurs when there are path resolution or file permission issues in WSL.

**Solutions:**

#### Option A: Use WSL-Specific Installers (Recommended)
```bash
# Install Novel-OS with WSL optimizations
curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-wsl.sh | bash

# Install Claude Code integration with WSL optimizations  
curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-claude-code-wsl.sh | bash
```

#### Option B: Manual File Access Verification
```bash
# Verify environment variables
echo "HOME: $HOME"
echo "USERPROFILE: $USERPROFILE"

# Check Novel-OS installation
ls -la ~/.novel-os/instructions/core/
ls -la ~/.claude/commands/

# Test file access
cat ~/.novel-os/instructions/core/plan-novel.md | head -5
cat ~/.claude/commands/plan-novel.md
```

#### Option C: Fix Environment Variables
```bash
# Add to ~/.bashrc
echo 'export NOVEL_OS_HOME="$HOME/.novel-os"' >> ~/.bashrc
source ~/.bashrc

# Verify
echo $NOVEL_OS_HOME
ls $NOVEL_OS_HOME
```

### 2. File Permission Issues

WSL can have different file permission requirements compared to native Linux.

**Solutions:**

```bash
# Fix permissions for Novel-OS
chmod -R 755 ~/.novel-os
chmod -R 755 ~/.claude

# Verify permissions
ls -la ~/.novel-os/
ls -la ~/.claude/
```

### 3. Path Resolution Issues

WSL uses different path formats that can cause issues with file references.

**Solutions:**

```bash
# Verify your home directory path
echo "Home directory: $HOME"
pwd

# Check if paths resolve correctly
ls ~/.novel-os 2>/dev/null && echo "Novel-OS accessible" || echo "Novel-OS not accessible"
ls ~/.claude 2>/dev/null && echo "Claude accessible" || echo "Claude not accessible"
```

### 4. Windows/Linux Path Confusion

WSL can sometimes get confused between Windows and Linux paths.

**Solutions:**

```bash
# Ensure you're using Linux-style paths
echo "Current PATH format:"
echo $HOME  # Should be /c/Users/YourName or /home/YourName

# If showing Windows paths (C:\Users\...), restart WSL:
# In Windows cmd/PowerShell: wsl --shutdown
# Then restart WSL
```

### 5. Claude Code Command Not Working

If `/plan-novel` or other commands don't work after installation.

**Solutions:**

```bash
# Verify command files exist
ls ~/.claude/commands/
cat ~/.claude/commands/plan-novel.md

# Check CLAUDE.md configuration
grep -i "novel-os" ~/.claude/CLAUDE.md
grep -i "plan-novel" ~/.claude/CLAUDE.md

# If missing, reinstall Claude Code integration:
curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-claude-code-wsl.sh | bash
```

### 6. Environment Variables Not Persistent

Environment variables disappear after closing WSL session.

**Solutions:**

```bash
# Add to ~/.bashrc for persistence
cat >> ~/.bashrc << 'EOF'

# Novel-OS environment variables
export NOVEL_OS_HOME="$HOME/.novel-os"
EOF

# Reload configuration
source ~/.bashrc

# Verify persistence (restart WSL and check)
echo $NOVEL_OS_HOME
```

## WSL-Specific Installation Verification

Run this complete verification script to diagnose issues:

```bash
#!/bin/bash
echo "=== Novel-OS WSL Installation Verification ==="
echo ""

# Check WSL environment
echo "1. WSL Environment:"
if [[ -f /proc/version ]] && grep -q -i microsoft /proc/version; then
    echo "   ✓ WSL detected: $(grep -o -i 'microsoft.*' /proc/version)"
else
    echo "   ❌ WSL not detected"
fi
echo ""

# Check environment variables
echo "2. Environment Variables:"
echo "   HOME: $HOME"
echo "   USERPROFILE: $USERPROFILE"
echo "   NOVEL_OS_HOME: $NOVEL_OS_HOME"
echo ""

# Check Novel-OS installation
echo "3. Novel-OS Installation:"
if [[ -d "$HOME/.novel-os" ]]; then
    echo "   ✓ ~/.novel-os directory exists"
    if [[ -f "$HOME/.novel-os/instructions/core/plan-novel.md" ]]; then
        echo "   ✓ plan-novel.md accessible"
    else
        echo "   ❌ plan-novel.md missing"
    fi
    if [[ -f "$HOME/.novel-os/standards/writing-style.md" ]]; then
        echo "   ✓ writing-style.md accessible"
    else
        echo "   ❌ writing-style.md missing"
    fi
else
    echo "   ❌ ~/.novel-os directory missing"
fi
echo ""

# Check Claude Code integration
echo "4. Claude Code Integration:"
if [[ -d "$HOME/.claude" ]]; then
    echo "   ✓ ~/.claude directory exists"
    if [[ -f "$HOME/.claude/commands/plan-novel.md" ]]; then
        echo "   ✓ plan-novel command accessible"
    else
        echo "   ❌ plan-novel command missing"
    fi
    if [[ -f "$HOME/.claude/CLAUDE.md" ]]; then
        echo "   ✓ CLAUDE.md exists"
        if grep -q -i "novel-os" "$HOME/.claude/CLAUDE.md"; then
            echo "   ✓ CLAUDE.md contains Novel-OS configuration"
        else
            echo "   ❌ CLAUDE.md missing Novel-OS configuration"
        fi
    else
        echo "   ❌ CLAUDE.md missing"
    fi
else
    echo "   ❌ ~/.claude directory missing"
fi
echo ""

# Check file permissions
echo "5. File Permissions:"
if [[ -r "$HOME/.novel-os/instructions/core/plan-novel.md" ]]; then
    echo "   ✓ Novel-OS files readable"
else
    echo "   ❌ Novel-OS files not readable"
fi
if [[ -r "$HOME/.claude/commands/plan-novel.md" ]]; then
    echo "   ✓ Claude commands readable"
else
    echo "   ❌ Claude commands not readable"
fi
echo ""

echo "=== End Verification ==="
```

## Reinstallation from Scratch

If you're experiencing persistent issues, try a complete reinstallation:

```bash
# Remove existing installations
rm -rf ~/.novel-os
rm -rf ~/.claude/commands/plan-novel.md ~/.claude/commands/create-outline.md ~/.claude/commands/write-scenes.md ~/.claude/commands/analyze-manuscript.md
rm -rf ~/.claude/agents/prose-reviewer.md ~/.claude/agents/context-researcher.md ~/.claude/agents/writing-workflow.md ~/.claude/agents/manuscript-creator.md ~/.claude/agents/date-checker.md ~/.claude/agents/continuity-checker.md
rm -rf ~/.claude/output-styles/novel-os-assistant.md

# Backup and remove CLAUDE.md (if you want to start fresh)
mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.backup-$(date +%Y%m%d) 2>/dev/null || true

# Reinstall with WSL-specific installers
curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-wsl.sh | bash
curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-claude-code-wsl.sh | bash

# Restart WSL session
# In Windows cmd/PowerShell: wsl --shutdown
# Then restart your WSL session
```

## Getting Help

If you continue to experience issues:

1. **Run the verification script above** and share the output
2. **Check your WSL version**: `wsl --version` (in Windows cmd/PowerShell)
3. **Share your environment**:
   ```bash
   echo "WSL Version: $(cat /proc/version)"
   echo "Distribution: $(cat /etc/os-release | grep PRETTY_NAME)"
   echo "Home: $HOME"
   echo "Working Directory: $(pwd)"
   ```

4. **Create an issue** at https://github.com/forsonny/book-os/issues with:
   - Your WSL distribution and version
   - Output from the verification script
   - Specific error messages you're seeing
   - Steps you've already tried

## WSL Best Practices for Novel-OS

1. **Always use the WSL-specific installers** when available
2. **Keep your WSL distribution updated**: `sudo apt update && sudo apt upgrade`
3. **Use Linux-style paths** (`~/.novel-os`) instead of Windows paths
4. **Set environment variables in ~/.bashrc** for persistence
5. **Restart WSL completely** (`wsl --shutdown`) if you encounter persistent issues
6. **Avoid mixing Windows and WSL file operations** on the same files