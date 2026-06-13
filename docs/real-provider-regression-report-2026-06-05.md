# Real Provider Regression Report - 2026-06-05

This document records the `RRP-29` real-provider validation run.
The run was executed only after explicitly setting
`NOVEL_AGENT_ENABLE_REAL_PROBES=1`, and only through local probe config.

## Scope

- Ordinary project path: 5 chapters
- Short long-task path: 10 chapters
- Medium long-task path: 35 chapters
- No 200-chapter pressure line
- No hard-coded key/model

## Commands

```text
cd apps/novel_agent_app
$env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'
dart run tool\real_general_novel_probe.dart --chapter-count=5
dart run tool\real_long_task_20_chapter_probe.dart --chapter-count=10
dart run tool\real_long_task_20_chapter_probe.dart --chapter-count=35
dart run tool\real_long_task_probe.dart
```

## Result Summary

### 1. Ordinary project path: PASS

- Command:
  - `dart run tool\real_general_novel_probe.dart --chapter-count=5`
- Report:
  - `artifacts/real_general_novel_probe_report.json`
- Verdict:
  - `PASS`
- Failure type:
  - none
- Key evidence:
  - `ok=True`
  - `report_category=success`
  - `requested_chapter_count=5`
  - All `chapter_01 ~ chapter_05` entries have `ok=True`
  - All five chapters report `delivery_outcome=accept`
  - All five chapters report `information_probe.report_category=success`
  - Chapter 1 length evidence:
    - `current_length=2291`
    - `target_length=2200`
    - `preferred_min=1900`
    - `preferred_max=2500`
    - `level=balanced`
    - `recommended_action=pass`

Reading:

- The ordinary conversation-like writing path is currently usable with a real provider.
- Expression constraints, chapter length strategy, formal chapter delivery, and information writeback all have positive evidence on this path.

### 2. Short long-task path: FAIL

- Command:
  - `dart run tool\real_long_task_20_chapter_probe.dart --chapter-count=10`
- Run report:
  - `artifacts/real_long_task_chapter_probe_runs/2026-06-05T18-39-27.341997_chapters_10/report.json`
- Latest summary report:
  - `artifacts/real_long_task_20_probe_report.json`
- Verdict:
  - `FAIL`
- Failure type:
  - `content_quality_failure`
- Key evidence:
  - `requested_chapter_count=10`
  - `chapter_file_count=7`
  - `checkpoint_confirm_count=1`
  - `manual_resolution_count=0`
  - `postprocess_count=0`
  - Missing delivered chapter files from final chapter set:
    - chapter 4
    - chapter 5
    - chapter 9

Observed failure shapes:

- Explicit failed chapter runs:
  - `tasks/第4章_·_旧磁带.task.json`
  - `tasks/第9章_·_回声的源头.task.json`
- Chapter 5 also did not land a chapter file in final `chapter_paths`, even though the step itself did not surface as `ok=false`.
- The run therefore shows two layers of instability:
  - explicit chapter execution failure
  - partial delivery holes that still allow later tasks to continue

Reading:

- Real-provider long-task execution is not stable enough even at the 10-chapter scale.
- Formal delivery continuity is not trustworthy, because the chain can move forward while leaving missing chapter artifacts behind.

### 3. Medium long-task path: FAIL

- Command:
  - `dart run tool\real_long_task_20_chapter_probe.dart --chapter-count=35`
- Run report:
  - `artifacts/real_long_task_chapter_probe_runs/2026-06-05T18-54-22.215982_chapters_35/report.json`
- Latest summary report:
  - `artifacts/real_long_task_20_probe_report.json`
- Verdict:
  - `FAIL`
- Failure type:
  - `content_quality_failure`
- Key evidence:
  - `requested_chapter_count=35`
  - `chapter_file_count=1`
  - `checkpoint_confirm_count=0`
  - `manual_resolution_count=2`
  - `postprocess_count=0`
  - `safety_counter=5`
  - Final task status counts:
    - `running=4`
    - `succeeded=4`

Observed failure shape:

- The run advanced through planning and sample confirmation handling, but only produced `chapters/第01章.md`.
- After two manual-resolution style continuations, the chain did not progress into a usable multi-chapter steady state.

Reading:

- The medium long-task path is currently less stable than the 10-chapter path.
- This is not a late drift-only issue; it can stall near the start of the chain.

### 4. Supplemental focused long-task probe: FAIL

- Command:
  - `dart run tool\real_long_task_probe.dart`
- Report:
  - `artifacts/real_long_task_probe_report.json`
- Verdict:
  - `FAIL`
- Failure type:
  - `technical_failure`
- Key evidence:
  - `error=Bad state: 样章确认后未能推进出第02章任务。`
  - `created_task_count=4`
  - Only planning, outline checkpoint, sample chapter, and sample checkpoint were materialized

Reading:

- This is a focused probe-level technical failure rather than the main scale verdict.
- It still reinforces the broader conclusion that the real-provider long-task chain is not stable enough right now.

## Code Change Made During RRP-29

- Updated `apps/novel_agent_app/tool/real_long_task_20_chapter_probe.dart`
  so the same stable probe entry can be reused for:
  - `--chapter-count=10`
  - `--chapter-count=35`
- The same probe now also keeps a per-run artifact directory instead of only overwriting a single top-level report file.

## Overall Verdict

- Ordinary project path: `PASS`
- Short long-task path: `FAIL`
- Medium long-task path: `FAIL`
- `RRP-29` overall verdict: `FAIL`

## Release Readiness Reading

- Real-provider ordinary writing is currently good enough to prove the base drafting path can run with real configuration.
- Real-provider long-task execution is not yet stable enough for beta release claims involving sustained autonomous progression.
- The current blocker is not packaging, GUI wording, or mock-contract wiring.
- The blocker is real-provider long-task reliability:
  - missing chapter delivery
  - chapter execution failure
  - early-stage chain stall

## Artifact Paths

- Ordinary path:
  - `artifacts/real_general_novel_probe_report.json`
- Short long-task path:
  - `artifacts/real_long_task_chapter_probe_runs/2026-06-05T18-39-27.341997_chapters_10/report.json`
- Medium long-task path:
  - `artifacts/real_long_task_chapter_probe_runs/2026-06-05T18-54-22.215982_chapters_35/report.json`
- Supplemental focused probe:
  - `artifacts/real_long_task_probe_report.json`
