# CLI Application Evolution Handoff - 2026-06-16

This handoff records the state after `CLIX-15`.

## Current Main Chain

- `session`
  - `list`
  - `show` / `load`
  - `resume`
  - `send`
  - `stats`
  - `compact`
  - `stop`
  - `start` remains the interactive REPL entry
- `approval`
  - `list`
  - `show`
  - `approve`
  - `reject`
  - `policy show`
- `workflow`
  - user layer: `start / status / continue / pause / resume / inspect / logs`
  - operator layer: `workflow debug ...`
- `config`
  - `show / get / set / provider list`
- `doctor`
  - `check`

## Release Boundary

- CLI is a shell over shared contracts, not a second business core.
- Approval truth lives in `core + adapters`, not in `workflow pending-research`.
- Session truth lives in shared session shell contracts, not in CLI-local state.
- `workflow debug ...` is operator-facing and should stay below the user layer.
- `probe` and smoke checks must keep consuming production contracts only.

## Residual Risks

- `workflow` still has a meaningful operator/debug surface, so future work should keep the user/operator split clean.
- `session start` is now fail-fast in non-interactive contexts, but the interactive REPL still depends on terminal behavior.
- `doctor` is diagnostic-only and intentionally does not auto-fix configuration or project state.
- Current smoke coverage is good, but any new command family should still add focused tests before expanding.

## TUI Entry Points

- Reuse the shared session shell and approval/workflow contracts.
- Do not invent new runtime truth in the TUI layer.
- Prefer projecting the same help, JSON, and status contracts used by the CLI.

## Verification

- `cd apps/novel_agent_cli && dart analyze`
- `cd apps/novel_agent_cli && dart test`

