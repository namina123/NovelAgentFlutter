---
description: Common Pre-Flight Steps for Novel-OS Instructions
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Pre-Flight Rules

## Path Resolution for @ References

**CRITICAL**: Throughout these workflows, you'll see references like `@~/.novel-os/...`

Before using any @ reference:
1. Remove the `@` prefix
2. Replace `~` with the actual user profile path:
   - Windows: `C:\Users\[Username]` (get with `Bash(echo $USERPROFILE)`)
   - Unix: `/home/[username]` (get with `Bash(echo $HOME)`)
3. Use the resulting absolute path for file operations

Example transformations:
- `@~/.novel-os/standards/writing-style.md` becomes:
  - Windows: `C:\Users\Sonny\.novel-os\standards\writing-style.md`
  - Unix: `/home/username/.novel-os/standards/writing-style.md`

## Workflow Execution Rules

- IMPORTANT: For any step that specifies a subagent in the subagent="" XML attribute you MUST use the specified subagent to perform the instructions for that step.

- Process XML blocks sequentially

- Use exact templates as provided

- Focus on creative writing workflows and novel development
