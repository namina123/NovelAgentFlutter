# CLI Release Boundary - 2026-06-05

## Scope

This note records the `RRP-27` release stance for `apps/novel_agent_cli`.
The goal is to keep CLI available as a shared-core consumer without turning it
into a second business-logic center or a blocker for GUI beta delivery.

## Verification

- `cd apps/novel_agent_cli && dart analyze`
- `cd apps/novel_agent_cli && dart test`
- `cd apps/novel_agent_cli && dart run bin/novel_agent.dart help`
- `cd apps/novel_agent_cli && dart run bin/novel_agent.dart workflow help`
- `cd apps/novel_agent_cli && dart run bin/novel_agent.dart project help`
- `cd apps/novel_agent_cli && dart run bin/novel_agent.dart review help`
- `cd apps/novel_agent_cli && dart run bin/novel_agent.dart asset help`
- `cd apps/novel_agent_cli && dart run bin/novel_agent.dart template help`
- `cd apps/novel_agent_cli && dart run bin/novel_agent.dart session`

Result:

- `dart analyze`: pass
- `dart test`: pass (`workflow_output_summary_service_test.dart`, 3 tests)
- Root help and command help all execute successfully.
- `session` explicitly reports migration status instead of pretending to be complete.

## Shared Contract Boundary

The current CLI still respects the shared-core boundary:

- `lib/bootstrap/cli_bootstrap.dart` is the only composition root. It wires
  `AdapterBundle.standard(...)`, shared repositories, shared services, and
  command objects together.
- `workflow` uses shared runtime and generation contracts such as
  `ProjectWorkflowRuntimeService`, `GenerateDraftUseCase`,
  `BuildModeGuidancePlanInputUseCase`, and `LoadModeGuidanceStateUseCase`.
- `project`, `review`, `asset`, and `template` commands mainly do argument
  parsing, project lookup, terminal printing, and delegation into shared
  `novel_agent_core` / `novel_agent_adapters` services.
- `apps/novel_agent_cli/README.md` already states that shared business-rule
  duplication is a non-responsibility.

Conclusion:

- No new evidence was found that the CLI is copying GUI business decisions.
- The CLI is currently acting as a shell over shared contracts, which matches
  the release-readiness constraint.

## Release Classification

### Minimal usable commands

These commands are acceptable to expose as current CLI entry points because they
are wired end-to-end and are not stubbed:

- Root help: `help`, `--help`, `-h`
- `workflow draft`
- `project summary` and the default `project` entry
- `review list`, `review show`, `review types`, `review create-task`,
  `review repair-task`
- `asset list`, `asset show`, `asset save-style`, `asset save-foreshadow`,
  `asset delete-style`, `asset delete-foreshadow`
- `template list`, `template show`, `template preview`, `template save`,
  `template delete`, `template restore`

### Experimental commands

These commands are real and compiled, but should be treated as migration-phase
or operator-facing capabilities rather than GUI-beta release promises:

- Workflow orchestration and long-task queue commands:
  `workflow create`, `list`, `next`, `preflight`, `chain`,
  `guidance-status`, `create-from-guidance`, `plan`, `prepare`, `run-once`,
  `run-next`, `run-queue`, `postprocess-once`, `postprocess-next`,
  `complete-next`, `pause`, `resume`, `checkpoint-actions`,
  `apply-checkpoint-action`, `revision-resolution`,
  `apply-revision-resolution`, `accept-revision`, `rollback-revision`
- Project package and customization commands:
  `project create-file`, `create-folder`, `import`, `import-bundle`,
  `preview-package`, `import-package`, `export-package`, `generate-index`,
  `save-bundle`, `update-info`
- Asset bundle commands:
  `asset import-bundle`, `export-bundle`, `preview-style-bundle`,
  `import-style-bundle`, `export-style-bundle`,
  `preview-character-bundle`, `import-character-bundle`,
  `export-character-bundle`, `preview-project-asset-bundle`,
  `import-project-asset-bundle`, `export-project-asset-bundle`

### Unsupported / intentionally not promised

- `session` is still migration-only. The command exists only to tell the user
  that session flows are not fully connected yet.
- CLI does not promise GUI-equivalent session orchestration, desktop stateful
  workflows, or a polished operator UX.
- CLI must not become a fallback layer that repairs provider payloads, fills
  shared-contract holes, or re-implements runtime business branching.

## Small Fixes Made In This Session

- Fixed `template help` so the `--vars` example prints a valid JSON argument
  form instead of broken nested quotes.
- Fixed `session` migration text to reference the real `project summary`
  command instead of the non-existent `project inspect`.

## Release Recommendation

- GUI remains the primary beta path.
- CLI should not block GUI beta from moving forward.
- Experimental commands may keep serving internal validation and operator use,
  but should not be marketed as feature-complete product surface yet.
