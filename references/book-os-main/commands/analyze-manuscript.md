# Analyze Manuscript

Analyze your existing manuscript and install Novel-OS

## IMPORTANT EXECUTION INSTRUCTIONS

1. **First, determine the user profile path**:
   - On Windows: Run `Bash(echo $USERPROFILE)` 
   - On macOS/Linux: Run `Bash(echo $HOME)`

2. **Then read the workflow file**:
   - Replace `~` with the actual user profile path obtained above
   - Read the file at: `[USER_PROFILE_PATH]/.novel-os/instructions/core/analyze-manuscript.md`
   - Example: `C:\Users\Sonny\.novel-os\instructions\core\analyze-manuscript.md` (Windows)
   - Example: `/home/username/.novel-os/instructions/core/analyze-manuscript.md` (Unix)

3. **Execute the complete workflow** from the analyze-manuscript.md file

## Command Purpose

This command analyzes an existing manuscript and sets up Novel-OS by:
- Scanning for manuscript files in the current directory
- Analyzing writing style, themes, and structure
- Creating `.novel-os/novel/` directory structure
- Generating planning files based on the existing work
- Setting up for continued AI-assisted writing
