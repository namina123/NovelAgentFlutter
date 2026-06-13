# GUI Critical Path Test Matrix - 2026-06-05

This note records the `RRP-28` GUI regression coverage used before release.
The goal is to prove the app's key Chinese-first paths are still automated at
the widget/viewmodel layer without depending on a real provider.

## Verification Command

```text
cd apps/novel_agent_app
flutter test \
  test/widget_test.dart \
  test/project_creation_controller_test.dart \
  test/project_create_panel_continuity_test.dart \
  test/project_open_view_data_service_test.dart \
  test/provider_settings_panel_test.dart \
  test/model_settings_panel_test.dart \
  test/conversation_empty_state_action_projection_service_test.dart \
  test/conversation_input_dock_test.dart \
  test/workbench_project_panel_test.dart \
  test/book_deconstruction_preview_panel_test.dart \
  test/project_long_task_summary_view_data_service_test.dart \
  test/long_task_run_detail_panel_test.dart \
  test/task_center_view_data_service_test.dart \
  test/app_shell_activity_rail_test.dart \
  test/workbench_navigation_sidebar_test.dart \
  test/ecosystem_detail_panel_test.dart
```

Result:

- `flutter test`: pass
- Final summary: `00:14 +37: All tests passed!`

## Coverage Matrix

### First launch / project entry

- `test/widget_test.dart`
  - App shell can mount and show workbench entry points.
- `test/project_creation_controller_test.dart`
  - No default project enters guarded launcher flow.
- `test/project_open_view_data_service_test.dart`
  - Project library wording and default-root discovery remain user-facing.

### New project creation

- `test/project_create_panel_continuity_test.dart`
  - General novel creation accepts continuity input in Chinese.
- `test/project_creation_controller_test.dart`
  - Long-task and normal project creation flows still complete.

### Model configuration view

- `test/provider_settings_panel_test.dart`
  - Narrow-screen provider flow stays list-first and hides protocol details by default.
- `test/model_settings_panel_test.dart`
  - Writing-model controls stay visible while advanced protocol/runtime details remain collapsed until requested.

### Normal writing path

- `test/conversation_empty_state_action_projection_service_test.dart`
  - Empty-state actions keep only natural next steps for normal writing.
- `test/conversation_input_dock_test.dart`
  - Composer, model selector, send/stop actions, and reasoning chip remain usable.
- `test/workbench_project_panel_test.dart`
  - Project-side writing actions stay project-scoped and do not leak raw runtime jargon.

### Material review / information recap

- `test/book_deconstruction_preview_panel_test.dart`
  - Preview keeps visible Chinese routes for ordinary continuation, long-task continuation, and shared information reuse.

### Short / long task path

- `test/project_long_task_summary_view_data_service_test.dart`
  - Long-task summary prioritizes runs needing attention.
- `test/long_task_run_detail_panel_test.dart`
  - Long-task detail shows progress, current action, recent outputs, and readable information projections.

### Recovery actions

- `test/task_center_view_data_service_test.dart`
  - Resume brief renders Chinese recovery guidance instead of raw contract keys.

### Ecosystem / settings entry

- `test/app_shell_activity_rail_test.dart`
  - Activity rail exposes the agent ecosystem entry point.
- `test/workbench_navigation_sidebar_test.dart`
  - Sidebar panel switching stays scoped between files, project, and collaboration views.
- `test/ecosystem_detail_panel_test.dart`
  - Ecosystem detail panel keeps visible user actions and readable validation summaries.

## Small Fixes Made During RRP-28

- Updated `workbench_navigation_sidebar_test.dart` to match the current
  user-facing copy:
  - project panel uses `当前协作摘要`
  - collaboration panel uses `当前会话分工`, `当前智能体`, and `项目基线组`
- Tightened regression assertions so normal project/recovery paths do not leak
  raw terms like `run_center_contract`, `workflowStrategyId`,
  `requires_user_action`, or `action_package_available`.

## Release Readiness Reading

- The covered paths are automated without calling a real provider.
- The covered widgets and viewmodels visibly render Chinese UI copy.
- GUI beta can continue to treat these paths as release-checked, while real
  provider stability remains deferred to `RRP-29`.
