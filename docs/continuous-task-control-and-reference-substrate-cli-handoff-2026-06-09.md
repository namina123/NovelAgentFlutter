# Continuous Task Control And Reference Substrate CLI Handoff - 2026-06-09

## Scope

This handoff records the `CTRS-22` CLI closeout boundary.
The CLI remains a thin shell over shared core/adapters contracts.
It does not become a second runtime, a second supervisor, or a fallback repair
layer for provider payloads, mount decisions, or continuity semantics.

## Stable Entry Points

### `workflow extract-reference`

- Authoritative contracts:
  - `ProjectReferenceExtractionResult`
  - `ReferenceExtractionSupervisorSignalService`
  - `WorkflowOutputSummaryService.referenceExtractionBriefLines(...)`
- The CLI now shows a single production-sourced summary block for:
  - control-plane outcome
  - stop reason
  - coverage / followup status
  - mount status
  - continuity review pressure
  - light projection entry paths
- The command does not infer its own coverage or mount precedence.
  It reuses the same supervisor-signal ordering as the production runtime.

### `workflow pause` / `workflow resume`

- Authoritative contracts:
  - `ProjectWorkflowRuntimeService.pauseLongTaskRun(...)`
  - `ProjectWorkflowRuntimeService.resumeLongTaskRun(...)`
  - `run_center_contract`
  - `LongTaskStopDiagnosisProjectionService`
- The CLI summary remains limited to:
  - current status
  - phase
  - active task
  - stop diagnosis
  - next action

### `workflow pending-research list|approve|reject`

- Authoritative contracts:
  - `ProjectPendingResearchActionService`
- The CLI only consumes request id / state / note / changed paths.
  It does not decide whether research should be approved on its own.

## Remaining Boundaries

- The CLI is not a full workbench replacement.
  Source-identity drill-down, source-of-truth browsing, and manual review still
  happen through the generated markdown projections and GUI surfaces.
- The CLI does not inline sqlite inspection or file-tree guessing.
  If deeper detail is needed, read the formal projection files or runtime
  artifacts that were already written by production services.
- The CLI does not expose every runtime artifact as a polished operator
  workflow.
  Commands outside the verified minimal surface should still be treated as thin
  shared-runtime shells rather than a mature product center.
- The CLI does not repair provider failures, fake mount success, or overwrite
  continuity conflicts.
  If production runtime says `coverage followup`, `mount incomplete`, or
  `manual continuity review`, the CLI must report that state instead of hiding
  it.

## Constraints

- Do not re-encode continuous-task lifecycle rules in CLI commands.
  Reuse `run_center_contract`, `LongTaskStopDiagnosisProjectionService`, and
  `ReferenceExtractionSupervisorSignalService`.
- Do not add CLI-only truth chains for mount status, continuity conflict, or
  coverage state.
- Do not turn CLI help or output formatting into a place that promises more
  capability than the shared runtime can prove.
- Keep markdown projections as the light summary / manual review entry.
  Do not make CLI mirror structured fact payloads inline.

## Verification

- `dart test test/workflow_output_summary_service_test.dart test/workflow_command_test.dart`
- `dart analyze`
- `dart run tool/workflow_output_summary_probe.dart`
