# Novel-OS Usage Guide

## Quick Start

### For New Novel Projects

1. **Install Novel-OS**:
   
   **Unix/Linux/macOS**:
   ```bash
   curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/Novel-OS/setup.sh | bash
   ```
   
   **Windows**:
   
   *PowerShell (Recommended):*
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forsonny/book-os/main/setup.ps1" -OutFile "setup.ps1"
   .\setup.ps1
   ```
   
   *Command Prompt:*
   ```cmd
   curl -o setup.bat https://raw.githubusercontent.com/forsonny/book-os/main/setup.bat
   setup.bat
   ```

2. **Install for your AI tool**:
   
   **Claude Code**:
   
   *Unix/Linux/macOS*:
   ```bash
   curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/Novel-OS/setup-claude-code.sh | bash
   ```
   
   *Windows*:
   
   *PowerShell (Recommended):*
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forsonny/book-os/main/setup-claude-code.ps1" -OutFile "setup-claude-code.ps1"
   .\setup-claude-code.ps1
   ```
   
   *Command Prompt:*
   ```cmd
   curl -o setup-claude-code.bat https://raw.githubusercontent.com/forsonny/book-os/main/setup-claude-code.bat
   setup-claude-code.bat
   ```
   
   **Cursor** (run from your novel project folder):
   
   *Unix/Linux/macOS*:
   ```bash
   curl -sSL https://raw.githubusercontent.com/forsonny/book-os/main/Novel-OS/setup-cursor.sh | bash
   ```
   
   *Windows*:
   
   *PowerShell (Recommended):*
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forsonny/book-os/main/setup-cursor.ps1" -OutFile "setup-cursor.ps1"
   .\setup-cursor.ps1
   ```
   
   *Command Prompt:*
   ```cmd
   curl -o setup-cursor.bat https://raw.githubusercontent.com/forsonny/book-os/main/setup-cursor.bat
   setup-cursor.bat
   ```

3. **Start your novel**:
   ```
   /plan-novel (Claude Code) or @plan-novel (Cursor)
   
   I want to write a mystery novel about a detective investigating art forgeries in Paris
   Target audience: Adult mystery readers
   Writing style: Third person limited, atmospheric prose
   ```

### For Existing Manuscripts

1. **Install Novel-OS** (same as above)

2. **Analyze your manuscript**:
   ```
   /analyze-manuscript (Claude Code) or @analyze-manuscript (Cursor)
   
   I want to install Novel-OS in my existing novel project
   ```

## Command Reference

### `/plan-novel` or `@plan-novel`
**Purpose**: Initialize a new novel project with Novel-OS structure

**Usage**:
```
/plan-novel

I want to write a [GENRE] novel about [PREMISE]
Key themes: [THEME1], [THEME2]
Target audience: [READER_DESCRIPTION]
Writing style: [POV], [TONE], [TENSE]
```

**Creates**:
- `.novel-os/novel/premise.md` - Story vision and themes
- `.novel-os/novel/writing-plan.md` - Writing phases and milestones
- `.novel-os/novel/writing-style.md` - Novel-specific style guide
- `.novel-os/novel/decisions.md` - Creative decision log

### `/create-outline` or `@create-outline`
**Purpose**: Create detailed story outline with character development

**Usage**:
```
/create-outline

Let's outline my [STORY_ELEMENT] with [SPECIFIC_REQUIREMENTS]
```

**Creates**:
- `.novel-os/manuscripts/YYYY-MM-DD-story-name/story-outline.md` - Complete story structure
- `.novel-os/manuscripts/YYYY-MM-DD-story-name/sub-specs/character-profiles.md` - Character development
- `.novel-os/manuscripts/YYYY-MM-DD-story-name/sub-specs/world-building.md` - Setting details (if needed)
- `.novel-os/manuscripts/YYYY-MM-DD-story-name/tasks.md` - Scene-by-scene writing plan

### `/write-scenes` or `@write-scenes`
**Purpose**: Write scenes and chapters according to your outline

**Usage**:
```
/write-scenes

Write [SPECIFIC_SCENE] or continue with next scene
```

**Features**:
- Maintains character voice consistency
- Follows established writing style
- Tracks word count progress
- Updates writing plan automatically

### `/analyze-manuscript` or `@analyze-manuscript`
**Purpose**: Install Novel-OS in existing novel projects

**Usage**:
```
/analyze-manuscript

I want to install Novel-OS in my existing novel project
```

**Analyzes**:
- Current manuscript structure and progress
- Writing style and genre
- Character development patterns
- Story themes and elements

## Workflow Examples

### Daily Writing Session

1. **Check what's next**:
   ```
   What's next on my writing plan?
   ```

2. **Write the scene**:
   ```
   /write-scenes
   
   Write the scene where Sarah confronts her sister about the family secret
   ```

3. **Review and continue**:
   Novel-OS automatically reviews prose quality and updates progress.

### Story Development Session

1. **Develop characters**:
   ```
   /create-outline
   
   I need to develop the relationship dynamics between my protagonist and antagonist
   ```

2. **Plan story arc**:
   ```
   /create-outline
   
   Create the three-act structure for my mystery novel with proper clue placement
   ```

### Revision Session

1. **Review existing scenes**:
   ```
   Review Chapter 3 for character voice consistency and pacing issues
   ```

2. **Check story continuity**:
   ```
   Check the timeline and character development from Chapters 1-5 for any inconsistencies
   ```

## File Organization

### Global Standards 
**Unix/Linux/macOS**: `~/.novel-os/standards/`  
**Windows**: `%USERPROFILE%\.novel-os\standards\`
- `writing-style.md` - Your default narrative voice and prose style
- `narrative-techniques.md` - Story structure and character development approaches
- `genre-guides/` - Genre-specific writing conventions and techniques

### Novel Documentation (`.novel-os/novel/`)
- `premise.md` - Complete story vision, themes, and market positioning
- `premise-lite.md` - Condensed premise for efficient AI context
- `writing-style.md` - Novel-specific style and voice guidelines
- `writing-plan.md` - Writing phases, milestones, and completion targets
- `decisions.md` - Creative decision log with rationale

### Manuscript Files (`.novel-os/manuscripts/YYYY-MM-DD-story-name/`)
- `story-outline.md` - Complete story structure with character arcs
- `story-outline-lite.md` - Condensed outline for AI context
- `sub-specs/character-profiles.md` - Detailed character development
- `sub-specs/world-building.md` - Setting and world details (genre-dependent)
- `tasks.md` - Scene-by-scene writing task breakdown

## Tips for Success

### Writing Standards
- **Be Specific**: "Third person limited with introspective voice" vs. "good writing"
- **Include Examples**: Show your preferred dialogue style and description approach
- **Define Character Voice**: How characters speak and think differently

### Story Planning
- **Start with Strong Premise**: Clear story concept drives everything else
- **Develop Characters First**: Compelling characters create compelling plots
- **Plan but Stay Flexible**: Outline thoroughly but allow for creative discoveries

### Writing Sessions
- **Focus on Single Scenes**: Complete one scene fully before moving on
- **Maintain Consistency**: Let AI track character details and story continuity
- **Review Regularly**: Use prose review for quality maintenance

### Creative Process
- **Trust the Structure**: Follow your outline but embrace unexpected insights
- **Document Decisions**: Record why you made creative choices
- **Iterate and Improve**: Refine your standards as you learn what works

## Troubleshooting

### Common Issues

**AI not matching your writing style?**
- Check your writing style standards file has specific examples:
  - **Unix/Linux/macOS**: `~/.novel-os/standards/writing-style.md`
  - **Windows**: `%USERPROFILE%\.novel-os\standards\writing-style.md`
- Add dialogue samples and prose examples to your style guide
- Update narrative voice guidelines with clear preferences

**Character voices becoming inconsistent?**
- Review character profiles for voice and speech pattern details
- Add specific dialogue examples for each character
- Use continuity-checker agent to identify voice drift

**Story getting off track?**
- Return to story outline and verify scene purposes
- Check if outline needs updating based on story discoveries
- Document major plot changes in decisions.md

**Scenes too long or unfocused?**
- Review scene structure guidelines in writing standards
- Break complex scenes into smaller, focused scenes
- Clarify scene goals and conflict in your outline

### Advanced Troubleshooting

**Performance Issues**:
- Novel-OS uses conditional loading to minimize context
- Large manuscripts may need more specific scene targeting
- Use lite versions of documents when possible

**Integration Issues**:
- Verify all setup scripts completed successfully
- Check that subagent files are properly installed
- Ensure command files point to correct instruction paths

## Advanced Features

### Custom Subagents
Create specialized agents for your specific writing needs:
- Research agents for historical accuracy
- Style agents for specific genre requirements
- Character agents for complex character development

### Genre Customization
Add new genre guides in your standards directory:
- **Unix/Linux/macOS**: `~/.novel-os/standards/genre-guides/`
- **Windows**: `%USERPROFILE%\.novel-os\standards\genre-guides\`

Examples:
- Romance writing conventions
- Horror atmosphere techniques
- Young adult voice guidelines

### Workflow Customization
Modify instruction files to match your creative process:
- Adjust scene structure requirements
- Change character development approaches
- Customize quality review criteria

Remember: Novel-OS is designed to adapt to your creative process, not replace it. Use it as a framework to enhance your writing with AI assistance while maintaining your unique voice and vision.
