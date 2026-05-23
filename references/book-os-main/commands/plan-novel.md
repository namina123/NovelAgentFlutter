# Plan Novel

Plan a new novel project and install Novel-OS in its workspace.

## IMPORTANT EXECUTION INSTRUCTIONS

1. **First, determine the user profile path**:
   - On Windows: Run `Bash(echo $USERPROFILE)` 
   - On macOS/Linux: Run `Bash(echo $HOME)`

2. **Then read the workflow file**:
   - Replace `~` with the actual user profile path obtained above
   - Read the file at: `[USER_PROFILE_PATH]/.novel-os/instructions/core/plan-novel.md`
   - Example: `C:\Users\Sonny\.novel-os\instructions\core\plan-novel.md` (Windows)
   - Example: `/home/username/.novel-os/instructions/core/plan-novel.md` (Unix)

3. **Execute the complete workflow** from the plan-novel.md file

## Setup Requirements

- **Global Novel-OS Required**: The global Novel-OS installation must exist at `[USER_PROFILE_PATH]/.novel-os/`
- **Project Setup Optional**: This command CREATES the project-specific `.novel-os/novel/` structure
- **Do NOT block execution** if `.novel-os/novel/` doesn't exist - creating it is this command's purpose

## Command Purpose

This command initializes a new Novel-OS project by:
- Gathering novel concept, themes, audience, and writing style
- Creating `.novel-os/novel/` directory structure in the current project
- Generating 5 essential planning files (premise.md, premise-lite.md, writing-style.md, writing-plan.md, decisions.md)
- Setting up the foundation for AI-assisted novel writing
