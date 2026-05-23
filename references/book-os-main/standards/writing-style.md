# Writing Style Guide

## Context

Global writing style rules for Novel-OS projects.

<conditional-block context-check="narrative-voice">
IF this Narrative Voice section already read in current context:
  SKIP: Re-reading this section
  NOTE: "Using Narrative Voice rules already in context"
ELSE:
  READ: The following narrative guidelines

## Narrative Voice

### Point of View
- **First Person**: Use for intimate, personal stories with strong character voice
- **Third Person Limited**: Use for character-focused narratives with single POV per scene
- **Third Person Omniscient**: Use sparingly, only when story requires multiple perspectives
- **Multiple POV**: Clearly delineate POV changes with chapter breaks or scene breaks

### Tense Consistency
- **Past Tense**: Standard for most fiction, provides narrative distance
- **Present Tense**: Use for immediacy and intensity, maintain throughout
- Never mix tenses within scenes unless for specific stylistic effect

### Voice and Tone
- Maintain consistent narrative voice throughout manuscript
- Adapt tone to match scene requirements while preserving overall voice
- Ensure character voice distinct from narrative voice in dialogue
</conditional-block>

<conditional-block context-check="dialogue-style">
IF this Dialogue Style section already read in current context:
  SKIP: Re-reading this section
  NOTE: "Using Dialogue Style rules already in context"
ELSE:
  READ: The following dialogue guidelines

## Dialogue Style

### Natural Speech Patterns
- Write dialogue that sounds natural when read aloud
- Use contractions and informal speech where appropriate
- Avoid overly formal or stilted dialogue unless character-specific

### Dialogue Tags
- Use "said" as the default dialogue tag
- Employ action beats instead of adverbs when possible
- Vary sentence structure to avoid repetitive patterns

### Character Voice
- Give each character distinct speech patterns and vocabulary
- Maintain consistency in character voice throughout manuscript
- Use dialogue to reveal character personality and background
</conditional-block>

<conditional-block task-condition="scene-description" context-check="description-style">
IF current task involves writing scene descriptions or world-building:
  IF description guidelines already read in current context:
    SKIP: Re-reading this section
    NOTE: "Using Description Style guidelines already in context"
  ELSE:
    <context_researcher_strategy>
      IF current agent is Claude Code AND context-researcher agent exists:
        USE: @agent:context-researcher
        REQUEST: "Get description and setting guidelines from writing-style/description-style.md"
        PROCESS: Returned style rules
      ELSE:
        READ the following description guidelines (only if not already in context):
        - @~/.novel-os/standards/writing-style/description-style.md (if not in context)
    </context_researcher_strategy>
ELSE:
  SKIP: Description style guidelines not relevant to current task
</conditional-block>

<conditional-block task-condition="genre-specific" context-check="genre-guidelines">
IF current task involves genre-specific writing:
  IF genre guidelines already read in current context:
    SKIP: Re-reading this section
    NOTE: "Using Genre Guidelines already in context"
  ELSE:
    <context_researcher_strategy>
      IF current agent is Claude Code AND context-researcher agent exists:
        USE: @agent:context-researcher
        REQUEST: "Get genre-specific guidelines from genre-guides/[GENRE]-style.md"
        PROCESS: Returned genre rules
      ELSE:
        READ the following genre guidelines (only if not already in context):
        - @~/.novel-os/standards/genre-guides/[GENRE]-style.md (if not in context)
    </context_researcher_strategy>
ELSE:
  SKIP: Genre guidelines not relevant to current task
</conditional-block>
