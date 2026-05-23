#!/bin/bash

# Novel-OS Setup Script
# This script installs Novel-OS files to your system

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
    echo "For WSL users, we recommend using the WSL-optimized installer:"
    echo "  curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-wsl.sh | bash"
    echo ""
    echo "The WSL installer provides:"
    echo "  ✓ WSL-specific path handling and environment setup"
    echo "  ✓ Proper file permissions for WSL"
    echo "  ✓ Environment variables optimized for WSL"
    echo "  ✓ Enhanced error handling for WSL file systems"
    echo ""
    echo "You can also continue with this installer, but the WSL-specific version is recommended."
    echo ""
    read -p "Continue with standard installer? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please use the WSL installer for the best experience:"
        echo "  curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-wsl.sh | bash"
        exit 0
    fi
    echo "Continuing with standard installer..."
    echo ""
fi

# Check for Windows environment (not WSL)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OS" == "Windows_NT" ]]; then
    echo "⚠️  Windows detected!"
    echo ""
    echo "For Windows users, please use the Windows batch file instead:"
    echo "  setup.bat"
    echo ""
    echo "The batch file provides the same functionality but is optimized for Windows."
    echo "You can find setup.bat in the same directory as this script."
    echo ""
    exit 1
fi

set -e  # Exit on error

# Initialize flags
OVERWRITE_INSTRUCTIONS=false
OVERWRITE_STANDARDS=false

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
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --overwrite-instructions    Overwrite existing instruction files"
            echo "  --overwrite-standards       Overwrite existing standards files"
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

echo "📚 Novel-OS Setup Script"
echo "========================"
echo ""

# Base URL for raw GitHub content
BASE_URL="https://raw.githubusercontent.com/forsonny/book-os/main/"

# Create directories
echo "📁 Creating directories..."
mkdir -p "$HOME/.novel-os/standards"
mkdir -p "$HOME/.novel-os/standards/writing-style"
mkdir -p "$HOME/.novel-os/standards/genre-guides"
mkdir -p "$HOME/.novel-os/instructions"
mkdir -p "$HOME/.novel-os/instructions/core"
mkdir -p "$HOME/.novel-os/instructions/meta"

# Download standards files
echo ""
echo "📥 Downloading writing standards files to ~/.novel-os/standards/"

# writing-style.md
if [ -f "$HOME/.novel-os/standards/writing-style.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.novel-os/standards/writing-style.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/standards/writing-style.md" "${BASE_URL}/standards/writing-style.md"
    if [ -f "$HOME/.novel-os/standards/writing-style.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.novel-os/standards/writing-style.md (overwritten)"
    else
        echo "  ✓ ~/.novel-os/standards/writing-style.md"
    fi
fi

# narrative-techniques.md
if [ -f "$HOME/.novel-os/standards/narrative-techniques.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.novel-os/standards/narrative-techniques.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/standards/narrative-techniques.md" "${BASE_URL}/standards/narrative-techniques.md"
    if [ -f "$HOME/.novel-os/standards/narrative-techniques.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.novel-os/standards/narrative-techniques.md (overwritten)"
    else
        echo "  ✓ ~/.novel-os/standards/narrative-techniques.md"
    fi
fi

# Download writing-style subdirectory files
echo ""
echo "📥 Downloading writing style files to ~/.novel-os/standards/writing-style/"

# description-style.md
if [ -f "$HOME/.novel-os/standards/writing-style/description-style.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.novel-os/standards/writing-style/description-style.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/standards/writing-style/description-style.md" "${BASE_URL}/standards/writing-style/description-style.md"
    if [ -f "$HOME/.novel-os/standards/writing-style/description-style.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.novel-os/standards/writing-style/description-style.md (overwritten)"
    else
        echo "  ✓ ~/.novel-os/standards/writing-style/description-style.md"
    fi
fi

# Download genre-guides subdirectory files
echo ""
echo "📥 Downloading genre guide files to ~/.novel-os/standards/genre-guides/"

# literary-fiction.md
if [ -f "$HOME/.novel-os/standards/genre-guides/literary-fiction.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.novel-os/standards/genre-guides/literary-fiction.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/standards/genre-guides/literary-fiction.md" "${BASE_URL}/standards/genre-guides/literary-fiction.md"
    if [ -f "$HOME/.novel-os/standards/genre-guides/literary-fiction.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.novel-os/standards/genre-guides/literary-fiction.md (overwritten)"
    else
        echo "  ✓ ~/.novel-os/standards/genre-guides/literary-fiction.md"
    fi
fi

# mystery-thriller.md
if [ -f "$HOME/.novel-os/standards/genre-guides/mystery-thriller.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.novel-os/standards/genre-guides/mystery-thriller.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/standards/genre-guides/mystery-thriller.md" "${BASE_URL}/standards/genre-guides/mystery-thriller.md"
    if [ -f "$HOME/.novel-os/standards/genre-guides/mystery-thriller.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.novel-os/standards/genre-guides/mystery-thriller.md (overwritten)"
    else
        echo "  ✓ ~/.novel-os/standards/genre-guides/mystery-thriller.md"
    fi
fi

# fantasy-sci-fi.md
if [ -f "$HOME/.novel-os/standards/genre-guides/fantasy-sci-fi.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.novel-os/standards/genre-guides/fantasy-sci-fi.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/standards/genre-guides/fantasy-sci-fi.md" "${BASE_URL}/standards/genre-guides/fantasy-sci-fi.md"
    if [ -f "$HOME/.novel-os/standards/genre-guides/fantasy-sci-fi.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.novel-os/standards/genre-guides/fantasy-sci-fi.md (overwritten)"
    else
        echo "  ✓ ~/.novel-os/standards/genre-guides/fantasy-sci-fi.md"
    fi
fi

# Download instruction files
echo ""
echo "📥 Downloading instruction files to ~/.novel-os/instructions/"

# Core instruction files
echo "  📂 Core instructions:"

# plan-novel.md
if [ -f "$HOME/.novel-os/instructions/core/plan-novel.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.novel-os/instructions/core/plan-novel.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/instructions/core/plan-novel.md" "${BASE_URL}/instructions/core/plan-novel.md"
    if [ -f "$HOME/.novel-os/instructions/core/plan-novel.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.novel-os/instructions/core/plan-novel.md (overwritten)"
    else
        echo "    ✓ ~/.novel-os/instructions/core/plan-novel.md"
    fi
fi

# create-outline.md
if [ -f "$HOME/.novel-os/instructions/core/create-outline.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
  echo "    ⚠️  ~/.novel-os/instructions/core/create-outline.md already exists - skipping"
else
  curl -s -o "$HOME/.novel-os/instructions/core/create-outline.md" "${BASE_URL}/instructions/core/create-outline.md"
  if [ -f "$HOME/.novel-os/instructions/core/create-outline.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
    echo "    ✓ ~/.novel-os/instructions/core/create-outline.md (overwritten)"
  else
    echo "    ✓ ~/.novel-os/instructions/core/create-outline.md"
  fi
fi

# write-scenes.md
if [ -f "$HOME/.novel-os/instructions/core/write-scenes.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.novel-os/instructions/core/write-scenes.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/instructions/core/write-scenes.md" "${BASE_URL}/instructions/core/write-scenes.md"
    if [ -f "$HOME/.novel-os/instructions/core/write-scenes.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.novel-os/instructions/core/write-scenes.md (overwritten)"
    else
        echo "    ✓ ~/.novel-os/instructions/core/write-scenes.md"
    fi
fi

# write-scene.md
if [ -f "$HOME/.novel-os/instructions/core/write-scene.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.novel-os/instructions/core/write-scene.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/instructions/core/write-scene.md" "${BASE_URL}/instructions/core/write-scene.md"
    if [ -f "$HOME/.novel-os/instructions/core/write-scene.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.novel-os/instructions/core/write-scene.md (overwritten)"
    else
        echo "    ✓ ~/.novel-os/instructions/core/write-scene.md"
    fi
fi

# analyze-manuscript.md
if [ -f "$HOME/.novel-os/instructions/core/analyze-manuscript.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.novel-os/instructions/core/analyze-manuscript.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/instructions/core/analyze-manuscript.md" "${BASE_URL}/instructions/core/analyze-manuscript.md"
    if [ -f "$HOME/.novel-os/instructions/core/analyze-manuscript.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.novel-os/instructions/core/analyze-manuscript.md (overwritten)"
    else
        echo "    ✓ ~/.novel-os/instructions/core/analyze-manuscript.md"
    fi
fi

# Meta instruction files
echo ""
echo "  📂 Meta instructions:"

# pre-flight.md
if [ -f "$HOME/.novel-os/instructions/meta/pre-flight.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.novel-os/instructions/meta/pre-flight.md already exists - skipping"
else
    curl -s -o "$HOME/.novel-os/instructions/meta/pre-flight.md" "${BASE_URL}/instructions/meta/pre-flight.md"
    if [ -f "$HOME/.novel-os/instructions/meta/pre-flight.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.novel-os/instructions/meta/pre-flight.md (overwritten)"
    else
        echo "    ✓ ~/.novel-os/instructions/meta/pre-flight.md"
    fi
fi

echo ""
echo "✅ Novel-OS base installation complete!"
echo ""
echo "📍 Files installed to:"
echo "   ~/.novel-os/standards/     - Your writing standards"
echo "   ~/.novel-os/instructions/  - Novel-OS instructions"
echo ""
if [ "$OVERWRITE_INSTRUCTIONS" = false ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "💡 Note: Existing files were skipped to preserve your customizations"
    echo "   Use --overwrite-instructions or --overwrite-standards to update specific files"
else
    echo "💡 Note: Some files were overwritten based on your flags"
    if [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
        echo "   Existing instruction files were preserved"
    fi
    if [ "$OVERWRITE_STANDARDS" = false ]; then
        echo "   Existing standards files were preserved"
    fi
fi
echo ""
echo "Next steps:"
echo ""
echo "1. Customize your writing standards in ~/.novel-os/standards/"
echo ""
echo "2. Install commands for your AI writing assistant(s):"
echo ""
echo "   - Using Claude Code? Install the Claude Code commands with:"
echo "     curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-claude-code.sh | bash"
echo ""
echo "   - Using Cursor? Install the Cursor commands with:"
echo "     curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/setup-cursor.sh | bash"
echo ""
echo "   - Using something else? See instructions in the Novel-OS README"
echo ""
echo "Learn more about Novel-OS for AI-assisted novel writing!"
echo ""
