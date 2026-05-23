#!/bin/bash

# Novel-OS Cursor Setup Script
# This script installs Novel-OS commands for Cursor in the current project

# Check for Windows environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OS" == "Windows_NT" ]]; then
    echo "⚠️  Windows detected!"
    echo ""
    echo "For Windows users, please use the Windows batch file instead:"
    echo "  setup-cursor.bat"
    echo ""
    echo "The batch file provides the same functionality but is optimized for Windows."
    echo "You can find setup-cursor.bat in the same directory as this script."
    echo ""
    exit 1
fi

set -e  # Exit on error

echo "📚 Novel-OS Cursor Setup"
echo "========================"
echo ""

# Check if Novel-OS base installation is present
if [ ! -d "$HOME/.novel-os/instructions" ] || [ ! -d "$HOME/.novel-os/standards" ]; then
    echo "⚠️  Novel-OS base installation not found!"
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

echo ""
echo "📁 Creating .cursor/rules directory..."
mkdir -p .cursor/rules

# Base URL for raw GitHub content
BASE_URL="https://raw.githubusercontent.com/forsonny/book-os/main/"

echo ""
echo "📥 Downloading and setting up Cursor command files..."

# Function to process a command file
process_command_file() {
    local cmd="$1"
    local temp_file="/tmp/${cmd}.md"
    local target_file=".cursor/rules/${cmd}.mdc"

    # Download the file
    if curl -s -o "$temp_file" "${BASE_URL}/commands/${cmd}.md"; then
        # Create the front-matter and append original content
        cat > "$target_file" << EOF
---
alwaysApply: false
---

EOF

        # Append the original content
        cat "$temp_file" >> "$target_file"

        # Clean up temp file
        rm "$temp_file"

        echo "  ✓ .cursor/rules/${cmd}.mdc"
    else
        echo "  ❌ Failed to download ${cmd}.md"
        return 1
    fi
}

# Process each command file
for cmd in plan-novel create-outline write-scenes analyze-manuscript; do
    process_command_file "$cmd"
done

echo ""
echo "✅ Novel-OS Cursor setup complete!"
echo ""
echo "📍 Files installed to:"
echo "   .cursor/rules/             - Cursor novel writing command rules"
echo ""
echo "Next steps:"
echo ""
echo "Use Novel-OS commands in Cursor with @ prefix:"
echo "  @plan-novel        - Start a new novel project with Novel-OS"
echo "  @analyze-manuscript - Add Novel-OS to an existing manuscript"
echo "  @create-outline    - Create a story outline (or simply ask 'what's next?')"
echo "  @write-scenes      - Write scenes and chapters"
echo ""
echo "Happy novel writing with AI assistance! 📚✨"
echo ""
