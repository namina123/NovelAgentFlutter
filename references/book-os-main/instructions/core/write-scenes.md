---
description: Rules to initiate writing of scenes and chapters using Novel-OS
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

Initiate writing of one or more scenes or chapters for a given story outline.

<pre_flight_check>
  EXECUTE: @~/.novel-os/instructions/meta/pre-flight.md
</pre_flight_check>

<process_flow>

<step number="1" name="scene_assignment">

### Step 1: Scene Assignment

Identify which scenes or chapters to write from the outline (using story_outline_reference file path and optional specific_scenes array), defaulting to the next unwritten scene if not specified.

<scene_selection>
  <explicit>user specifies exact scene(s) or chapter(s)</explicit>
  <implicit>find next unwritten scene in tasks.md</implicit>
</scene_selection>

<instructions>
  ACTION: Identify scene(s) to write
  DEFAULT: Select next unwritten scene if not specified
  CONFIRM: Scene selection with user
</instructions>

</step>

<step number="2" subagent="context-researcher" name="context_analysis">

### Step 2: Context Analysis

Use the context-researcher subagent to gather minimal context for scene understanding by always loading story tasks.md, and conditionally loading @.novel-os/novel/premise-lite.md, story-outline-lite.md, and sub-specs/character-profiles.md if not already in context.

<instructions>
  ACTION: Use context-researcher subagent to:
    - REQUEST: "Get novel premise from premise-lite.md"
    - REQUEST: "Get story summary from story-outline-lite.md"
    - REQUEST: "Get character details from character-profiles.md"
  PROCESS: Returned information
</instructions>

<context_gathering>
  <essential_docs>
    - tasks.md for writing breakdown
  </essential_docs>
  <conditional_docs>
    - premise-lite.md for story alignment
    - story-outline-lite.md for narrative summary
    - character-profiles.md for character consistency
  </conditional_docs>
</context_gathering>

</step>

<step number="3" name="writing_environment_check">

### Step 3: Check Writing Environment

Check for any distractions or conflicting processes and prepare optimal writing environment.

<environment_check_flow>
  <if_distractions_found>
    ASK user to address them
    WAIT for response
  </if_distractions_found>
  <if_environment_clear>
    PROCEED immediately
  </if_environment_clear>
</environment_check_flow>

<user_prompt>
  Writing environment check complete.
  Ready to begin focused writing session? (yes/no)
</user_prompt>

<instructions>
  ACTION: Verify optimal writing conditions
  CONDITIONAL: Address any environmental issues
  PROCEED: When environment is writing-ready
</instructions>

</step>

<step number="4" subagent="writing-workflow" name="manuscript_version_management">

### Step 4: Manuscript Version Management

Use the writing-workflow subagent to manage manuscript versions to ensure proper backup by creating or updating the appropriate version for the story.

<instructions>
  ACTION: Use writing-workflow subagent
  REQUEST: "Check and manage manuscript version for story: [STORY_FOLDER]
            - Create backup if needed
            - Set up current draft version
            - Handle any unsaved changes"
  WAIT: For version setup completion
</instructions>

<version_naming>
  <source>story folder name</source>
  <format>exclude date prefix</format>
  <example>
    - folder: 2025-03-15-mystery-novel
    - version: mystery-novel-v1.0
  </example>
</version_naming>

</step>

<step number="5" name="scene_writing_loop">

### Step 5: Scene Writing Loop

Write all assigned scenes and chapters using @~/.novel-os/instructions/core/write-scene.md instructions, continuing until all scenes are complete.

<execution_flow>
  LOAD @~/.novel-os/instructions/core/write-scene.md ONCE

  FOR each scene assigned in Step 1:
    EXECUTE instructions from write-scene.md with:
      - scene_number
      - all associated writing elements
    WAIT for scene completion
    UPDATE tasks.md status
  END FOR
</execution_flow>

<loop_logic>
  <continue_conditions>
    - More unfinished scenes exist
    - User has not requested stop
  </continue_conditions>
  <exit_conditions>
    - All assigned scenes marked complete
    - User requests early termination
    - Creative block prevents continuation
  </exit_conditions>
</loop_logic>

<scene_status_check>
  AFTER each scene writing:
    CHECK tasks.md for remaining scenes
    IF all assigned scenes complete:
      PROCEED to next step
    ELSE:
      CONTINUE with next scene
</scene_status_check>

<instructions>
  ACTION: Load write-scene.md instructions once at start
  REUSE: Same instructions for each scene iteration
  LOOP: Through all assigned scenes
  UPDATE: Scene status after each completion
  VERIFY: All scenes complete before proceeding
  HANDLE: Creative blocks appropriately
</instructions>

</step>

<step number="6" subagent="prose-reviewer" name="prose_quality_review">

### Step 6: Review Written Scenes

Use the prose-reviewer subagent to review the written scenes for quality, consistency, and narrative flow, fixing any issues until the prose meets standards.

<instructions>
  ACTION: Use prose-reviewer subagent
  REQUEST: "Review the written scenes for:
            - Prose quality and style consistency
            - Character voice consistency
            - Narrative flow and pacing
            - Technical writing issues"
  WAIT: For prose-reviewer analysis
  PROCESS: Address any reported issues
  REPEAT: Until prose meets quality standards
</instructions>

<review_execution>
  <order>
    1. Review all written scenes
    2. Address quality issues
  </order>
  <requirement>High prose quality standard</requirement>
</review_execution>

<quality_handling>
  <action>revise and improve</action>
  <priority>before proceeding</priority>
</quality_handling>

</step>

<step number="7" subagent="writing-workflow" name="manuscript_workflow">

### Step 7: Manuscript Workflow

Use the writing-workflow subagent to save progress, update word counts, and create version checkpoint for the written scenes.

<instructions>
  ACTION: Use writing-workflow subagent
  REQUEST: "Complete manuscript workflow for [STORY_NAME] scenes:
            - Manuscript: [STORY_FOLDER_PATH]
            - Changes: All written scenes/chapters
            - Progress: [WORD_COUNT_INCREASE]
            - Status: [COMPLETION_STATUS]"
  WAIT: For workflow completion
  PROCESS: Save progress information
</instructions>

<save_process>
  <backup>
    <message>descriptive summary of scenes written</message>
    <format>include word count and chapter progress</format>
  </backup>
  <version>
    <target>current draft</target>
    <increment>version number if major milestone</increment>
  </version>
  <progress>
    <word_count>update total manuscript word count</word_count>
    <completion>update writing plan progress</completion>
  </progress>
</save_process>

</step>

<step number="8" name="writing_plan_progress_check">

### Step 8: Writing Plan Progress Check (Conditional)

Check @.novel-os/novel/writing-plan.md (if not in context) and update writing progress only if the written scenes may have completed a writing milestone.

<conditional_execution>
  <preliminary_check>
    EVALUATE: Did written scenes potentially complete a writing milestone?
    IF NO:
      SKIP this entire step
      PROCEED to step 9
    IF YES:
      CONTINUE with writing plan check
  </preliminary_check>
</conditional_execution>

<conditional_loading>
  IF writing-plan.md NOT already in context:
    LOAD @.novel-os/novel/writing-plan.md
  ELSE:
    SKIP loading (use existing context)
</conditional_loading>

<plan_criteria>
  <update_when>
    - scenes fully implement writing milestone
    - all related writing tasks completed
    - quality review passed
  </update_when>
  <caution>only mark complete if absolutely certain</caution>
</plan_criteria>

<instructions>
  ACTION: First evaluate if writing plan check is needed
  SKIP: If scenes clearly don't complete milestones
  CHECK: If writing-plan.md already in context
  LOAD: Only if needed and not in context
  EVALUATE: If current scenes complete writing goals
  UPDATE: Mark writing milestones complete if applicable
  VERIFY: Certainty before marking complete
</instructions>

</step>

<step number="9" name="completion_notification">

### Step 9: Writing Session Completion Notification

Play a system sound to alert the user that the writing session is complete.

<notification_command>
  afplay /System/Library/Sounds/Glass.aiff
</notification_command>

<instructions>
  ACTION: Play completion sound
  PURPOSE: Alert user that writing session is complete
</instructions>

</step>

<step number="10" name="completion_summary">

### Step 10: Writing Session Summary

Create a structured summary message with emojis showing what was written, word count progress, any creative decisions, and next writing steps.

<summary_template>
  ## ✅ What's been written

  1. **[SCENE_1]** - [ONE_SENTENCE_DESCRIPTION]
  2. **[SCENE_2]** - [ONE_SENTENCE_DESCRIPTION]

  ## 📊 Progress Update

  - Words written: [WORD_COUNT]
  - Total manuscript: [TOTAL_WORDS]
  - Completion: [PERCENTAGE]%

  ## ⚠️ Creative decisions made

  [ONLY_IF_APPLICABLE]
  - **[DECISION_1]** - [DESCRIPTION_AND_REASON]

  ## 📖 Ready for review

  [ONLY_IF_APPLICABLE]
  1. [REVIEW_STEP_1]
  2. [REVIEW_STEP_2]

  ## 📝 Next writing session

  Next up: [NEXT_SCENE_OR_CHAPTER]
</summary_template>

<summary_sections>
  <required>
    - scenes written recap
    - word count progress
  </required>
  <conditional>
    - creative decisions (if any)
    - review instructions (if needed)
    - next session preview
  </conditional>
</summary_sections>

<instructions>
  ACTION: Create comprehensive writing summary
  INCLUDE: All required sections
  ADD: Conditional sections if applicable
  FORMAT: Use emoji headers for scannability
</instructions>

</step>

</process_flow>

## Error Handling

<error_protocols>
  <creative_blocks>
    - document in tasks.md
    - mark with ⚠️ emoji
    - include in summary
  </creative_blocks>
  <quality_issues>
    - revise before proceeding
    - never save substandard prose
  </quality_issues>
  <narrative_roadblocks>
    - attempt 3 approaches
    - document if unresolved
    - seek user input
  </narrative_roadblocks>
</error_protocols>

<final_checklist>
  <verify>
    - [ ] Scene writing complete
    - [ ] Prose quality reviewed
    - [ ] tasks.md updated
    - [ ] Progress saved and backed up
    - [ ] Version checkpoint created
    - [ ] Writing plan checked/updated
    - [ ] Summary provided to user
  </verify>
</final_checklist>
