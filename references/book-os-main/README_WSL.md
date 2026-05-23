# Novel-OS for WSL (Windows Subsystem for Linux)

Special installation instructions and optimizations for WSL users.

## WSL Quick Install

### Option 1: Complete WSL Installation (Recommended)
Install both Novel-OS and Claude Code integration with WSL optimizations:

```bash
# Install Novel-OS base with WSL optimizations
curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-wsl.sh | bash

# Install Claude Code integration with WSL optimizations
curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-claude-code-wsl.sh | bash
```

### Option 2: Novel-OS Only
If you only want Novel-OS without Claude Code integration:

```bash
curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-wsl.sh | bash --skip-claude-setup
```

## WSL-Specific Features

The WSL installers provide several optimizations not available in the standard installers:

### 🔧 Environment Setup
- **Automatic WSL detection** and environment configuration
- **Environment variables** added to `~/.bashrc` for persistence
- **Path resolution testing** to ensure file accessibility
- **WSL-compatible file permissions** (755) applied automatically

### 📁 Enhanced File Handling
- **WSL-specific path handling** for reliable file access
- **File system access verification** during installation
- **Enhanced error handling** for WSL file system quirks
- **Symbolic link support** for consistent path resolution

### ⚡ Installation Verification
- **Real-time file access testing** during installation
- **WSL-specific verification scripts** included
- **Automatic detection of installation issues**
- **Comprehensive troubleshooting guidance**

## Verification

After installation, verify everything is working:

```bash
# Run the WSL verification script
curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/verify-wsl-installation.sh | bash

# Or download and run locally
curl -s -o verify-wsl.sh https://raw.githubusercontent.com/forsonny/book-os/main/verify-wsl-installation.sh
chmod +x verify-wsl.sh
./verify-wsl.sh
```

## Testing Your Installation

### Test Novel-OS Commands
```bash
# Test environment variables
echo $NOVEL_OS_HOME  # Should show /c/Users/YourName/.novel-os

# Test file access
ls ~/.novel-os/instructions/core/
cat ~/.novel-os/instructions/core/plan-novel.md | head -5

# Test Claude Code commands (if installed)
ls ~/.claude/commands/
cat ~/.claude/commands/plan-novel.md
```

### Test Claude Code Integration
If you installed Claude Code integration, test these commands:

```bash
/plan-novel         # Start a new novel project
/create-outline     # Create chapter outlines
/write-scenes       # Begin scene writing
/analyze-manuscript # Analyze existing manuscript
```

## WSL-Specific Environment Variables

The WSL installer automatically sets up these environment variables:

```bash
# Novel-OS home directory
export NOVEL_OS_HOME="$HOME/.novel-os"

# These are automatically added to ~/.bashrc for persistence
echo 'export NOVEL_OS_HOME="$HOME/.novel-os"' >> ~/.bashrc
```

## Troubleshooting

### Common WSL Issues

#### "Novel-OS files aren't accessible"
This is the most common issue. Try these solutions in order:

```bash
# 1. Verify environment and file access
echo "HOME: $HOME"
ls ~/.novel-os/instructions/core/

# 2. Reload environment variables
source ~/.bashrc
echo $NOVEL_OS_HOME

# 3. Fix file permissions
chmod -R 755 ~/.novel-os ~/.claude

# 4. Restart WSL completely
# In Windows cmd/PowerShell: wsl --shutdown
# Then restart your WSL session

# 5. Reinstall with WSL-specific installer
curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-wsl.sh | bash
```

#### Path Resolution Issues
```bash
# Test path resolution
ls ~/.novel-os 2>/dev/null && echo "✅ Accessible" || echo "❌ Not accessible"
ls $HOME/.novel-os 2>/dev/null && echo "✅ Accessible" || echo "❌ Not accessible"

# If issues persist, ensure you're using Linux-style paths
echo $HOME  # Should be /c/Users/YourName or /home/YourName (not C:\Users\...)
```

#### Environment Variables Not Persistent
```bash
# Check if variables are in bashrc
grep NOVEL_OS_HOME ~/.bashrc

# If missing, add manually
echo 'export NOVEL_OS_HOME="$HOME/.novel-os"' >> ~/.bashrc
source ~/.bashrc
```

### Complete Diagnostic Script

Run this comprehensive diagnostic:

```bash
#!/bin/bash
echo "=== WSL Novel-OS Diagnostic ==="

# WSL detection
if [[ -f /proc/version ]] && grep -q -i microsoft /proc/version; then
    echo "✅ WSL detected"
else
    echo "❌ WSL not detected"
fi

# Environment variables
echo "📋 Environment:"
echo "  HOME: $HOME"
echo "  NOVEL_OS_HOME: $NOVEL_OS_HOME"

# File access
echo "📁 File Access:"
echo "  Novel-OS: $(ls ~/.novel-os >/dev/null 2>&1 && echo "✅" || echo "❌")"
echo "  Claude: $(ls ~/.claude >/dev/null 2>&1 && echo "✅" || echo "❌")"

# Key files
echo "🔑 Key Files:"
echo "  plan-novel: $(ls ~/.novel-os/instructions/core/plan-novel.md >/dev/null 2>&1 && echo "✅" || echo "❌")"
echo "  commands: $(ls ~/.claude/commands/plan-novel.md >/dev/null 2>&1 && echo "✅" || echo "❌")"

echo "=== End Diagnostic ==="
```

### Getting Help

1. **Run the verification script** and share the output:
   ```bash
   curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/verify-wsl-installation.sh | bash
   ```

2. **Share your WSL environment**:
   ```bash
   echo "WSL Version: $(cat /proc/version)"
   echo "Distribution: $(cat /etc/os-release | grep PRETTY_NAME)"
   echo "Home Directory: $HOME"
   ```

3. **Check detailed troubleshooting**: [WSL_TROUBLESHOOTING.md](WSL_TROUBLESHOOTING.md)

4. **Create an issue**: https://github.com/forsonny/book-os/issues

## WSL vs Standard Installation

| Feature | Standard Install | WSL Install |
|---------|-----------------|-------------|
| Environment Detection | Basic | Advanced WSL detection |
| Path Handling | Standard Linux | WSL-optimized paths |
| File Permissions | Standard | WSL-compatible (755) |
| Environment Variables | Manual setup | Automatic with persistence |
| Error Handling | Basic | Enhanced for WSL quirks |
| Verification | Basic checks | Comprehensive WSL testing |
| Troubleshooting | General guides | WSL-specific solutions |

## Advanced WSL Configuration

### Custom Installation Paths
```bash
# Install to custom location
export CUSTOM_NOVEL_OS_HOME="/mnt/c/MyDocuments/novel-os"
mkdir -p "$CUSTOM_NOVEL_OS_HOME"
# Then run installer with custom paths
```

### Multiple WSL Distributions
```bash
# Check which WSL distribution you're using
echo $WSL_DISTRO_NAME
cat /etc/os-release

# Novel-OS works across all WSL distributions:
# - Ubuntu
# - Debian  
# - Alpine
# - openSUSE
# - Fedora
# - And more...
```

### Performance Optimization
```bash
# For better performance, consider installing to WSL file system
# instead of Windows file system (/mnt/c/)

# Check current location
pwd
df -h .

# If you're in /mnt/c/, consider moving to ~/
cd ~
# Re-run installer
```

---

**Happy novel writing with AI assistance in WSL! 🐧📚**