---
description: Rules to write a specific scene and its elements using Novel-OS
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

## Path Resolution Instructions

**CRITICAL**: Before executing any steps in this workflow:

1. **Determine the user profile path**:
   - Windows: Run `Bash(echo $USERPROFILE)` to get the path (e.g., `C:\Users\Sonny`)
   - macOS/Linux: Run `Bash(echo $HOME)` to get the path (e.g., `/home/username`)

2. **Replace all `~` references** in this document with the actual user profile path:
   - `~/.novel-os/` becomes `C:\Users\Sonny\.novel-os\` (Windows)
   - `~/.novel-os/` becomes `/home/username/.novel-os/` (Unix)

3. **Use absolute paths** for all file operations

# Scene Writing Rules

## Overview

Write a specific scene along with its narrative elements systematically following a structured creative writing workflow.

<pre_flight_check>
  EXECUTE: @~/.novel-os/instructions/meta/pre-flight.md
</pre_flight_check>

<process_flow>

<step number="1" name="scene_understanding">

### Step 1: Scene Understanding

Read and analyze the given scene and all its elements from tasks.md to gain complete understanding of what needs to be written.

<scene_analysis>
  <read_from_tasks_md>
    - Scene description and purpose
    - All scene elements and requirements
    - Scene dependencies and connections
    - Expected outcomes and word count
  </read_from_tasks_md>
</scene_analysis>

<instructions>
  ACTION: Read the specific scene and all its elements
  ANALYZE: Full scope of writing required
  UNDERSTAND: Character goals and story function
  NOTE: Narrative requirements for each element
</instructions>

</step>

<step number="2" name="story_context_review">

### Step 2: Story Context Review

Search and extract relevant sections from story-outline.md to understand the narrative context and character state for this scene.

<selective_reading>
  <search_story_outline>
    FIND sections in story-outline.md related to:
    - Current scene's story function
    - Character states and relationships
    - Plot progression requirements
    - Thematic elements to include
  </search_story_outline>
</selective_reading>

<instructions>
  ACTION: Search story-outline.md for scene-relevant sections
  EXTRACT: Only narrative details for current scene
  SKIP: Unrelated story elements
  FOCUS: Character goals and story progression for this specific scene
</instructions>

</step>

<step number="3" subagent="context-researcher" name="writing_style_review">

### Step 3: Writing Style Review

Use the context-researcher subagent to retrieve relevant sections from @~/.novel-os/standards/writing-style.md that apply to the current scene's narrative approach and genre requirements.

<selective_reading>
  <search_writing_style>
    FIND sections relevant to:
    - Scene's narrative voice and POV
    - Dialogue style for characters involved
    - Description and pacing approaches
    - Genre-specific conventions
  </search_writing_style>
</selective_reading>

<instructions>
  ACTION: Use context-researcher subagent
  REQUEST: "Find writing style sections relevant to:
            - Narrative voice: [CURRENT_POV]
            - Scene type: [CURRENT_SCENE_TYPE]
            - Characters involved: [CHARACTER_LIST]
            - Genre conventions needed"
  PROCESS: Returned style guidelines
  APPLY: Relevant patterns to scene writing
</instructions>

</step>

<step number="4" subagent="context-researcher" name="character_voice_review">

### Step 4: Character Voice Review

Use the context-researcher subagent to retrieve relevant character details from character-profiles.md for the characters appearing in this scene.

<selective_reading>
  <search_character_profiles>
    FIND character details for:
    - Characters appearing in this scene
    - Character relationships and dynamics
    - Character voice and dialogue patterns
    - Character motivations and goals
  </search_character_profiles>
</selective_reading>

<instructions>
  ACTION: Use context-researcher subagent
  REQUEST: "Find character details for:
            - Scene characters: [CHARACTERS_IN_SCENE]
            - Character relationships and dynamics
            - Dialogue patterns and voice
            - Current motivations and conflicts"
  PROCESS: Returned character information
  APPLY: Consistent character portrayal
</instructions>

</step>

<step number="5" name="scene_writing">

### Step 5: Scene Writing and Elements

Write the scene and all its narrative elements in order using structured creative writing approach.

<typical_scene_structure>
  <opening>Establish setting and character state</opening>
  <development>Advance plot and character goals</development>
  <climax>Scene conflict or revelation</climax>
  <resolution>Transition to next story beat</resolution>
</typical_scene_structure>

<writing_order>
  <scene_planning>
    IF scene element 1 is "Plan scene structure":
      - Outline scene beats and character goals
      - Establish setting and mood
      - Plan dialogue and action sequences
      - Set scene word count target
      - Mark scene planning complete
  </scene_planning>

  <scene_drafting>
    FOR each writing element (2 through n-1):
      - Write the specific scene content
      - Maintain character voice consistency
      - Advance plot as outlined
      - Include thematic elements
      - Mark element complete
  </scene_drafting>

  <scene_polishing>
    IF final element is "Review and polish scene":
      - Review entire scene for flow
      - Check character consistency
      - Verify plot advancement
      - Polish prose quality
      - Mark final element complete
  </scene_polishing>
</writing_order>

<prose_management>
  <new_content>
    - Written in planning phase
    - Covers all aspects of scene function
    - Includes character development and plot advancement
  </new_content>
  <prose_refinement>
    - Made during writing elements
    - Improve clarity and flow
    - Maintain narrative voice
  </prose_refinement>
</prose_management>

<instructions>
  ACTION: Write scene elements in their defined order
  RECOGNIZE: First element typically plans scene structure
  IMPLEMENT: Middle elements build narrative content
  VERIFY: Final element ensures quality and consistency
  UPDATE: Mark each element complete as finished
</instructions>

</step>

<step number="6" subagent="prose-reviewer" name="scene_quality_verification">

### Step 6: Scene-Specific Quality Verification

Use the prose-reviewer subagent to review and verify only the prose written for this specific scene (not the entire manuscript) to ensure the writing meets quality standards.

<focused_review_execution>
  <review_only>
    - All new prose written for this scene
    - Character dialogue and voice consistency
    - Narrative flow within the scene
    - Style adherence for this section
  </review_only>
  <skip>
    - Full manuscript review (done later in write-scenes.md)
    - Unrelated scenes or chapters
  </skip>
</focused_review_execution>

<quality_verification>
  IF any quality issues:
    - Revise and improve the specific problems
    - Re-review only the revised sections
  ELSE:
    - Confirm scene meets quality standards
    - Ready to proceed
</quality_verification>

<instructions>
  ACTION: Use prose-reviewer subagent
  REQUEST: "Review prose quality for [this scene's content]"
  WAIT: For prose-reviewer analysis
  PROCESS: Returned quality feedback
  VERIFY: High quality standard for scene-specific content
  CONFIRM: This scene's prose is polished
</instructions>

</step>

<step number="7" name="scene_status_updates">

### Step 7: Scene Status Updates

Update the tasks.md file immediately after completing each scene to track writing progress.

<update_format>
  <completed>- [x] Scene description</completed>
  <incomplete>- [ ] Scene description</incomplete>
  <blocked>
    - [ ] Scene description
    ⚠️ Creative block: [DESCRIPTION]
  </blocked>
</update_format>

<blocking_criteria>
  <attempts>maximum 3 different approaches</attempts>
  <action>document creative block</action>
  <emoji>⚠️</emoji>
</blocking_criteria>

<instructions>
  ACTION: Update tasks.md after each scene completion
  MARK: [x] for completed items immediately
  DOCUMENT: Creative blocks with ⚠️ emoji
  LIMIT: 3 attempts before marking as blocked
</instructions>

</step>

</process_flow>
