# 职责边界冻结与唯一出口清单

日期：2026-06-17

对应主线：`RBR` / `Responsibility Boundary Refactor`

关联文档：

- `docs/important/responsibility-boundary-refactor-session-order-2026-06-17.md`
- `docs/important/responsibility-boundary-audit-analysis-2026-06-17.md`
- `docs/important/project-unreasonable-areas-audit-2026-06-15.md`
- `docs/architecture.md`
- `agent.md`

---

## 1. 这份清单的用途

这份清单只做一件事：把本轮必须收口的几条主链真相源先冻结下来，作为后续 `RBR-02` 到 `RBR-15` 的统一裁判标准。

它不是实现方案，也不是迁移计划书，而是后续 session 用来判断“谁是正式出口、谁只是消费层”的边界表。

---

## 2. 冻结总则

1. 同一职责只能有一个正式出口。
2. `fallback`、`bridge`、`probe`、`viewmodel helper`、`UI action handler` 都不允许重新长成第二条业务主链。
3. app 层只能消费稳定合同，不允许继续反向决定核心语义。
4. adapters 层只能实现与桥接，不允许吞掉策略真相。
5. 已经存在的巨石对象，后续只允许朝正式出口和薄 facade 收口，不允许再扩新职责。

---

## 3. 真相源冻结清单

### 3.1 开局真相源

当前主实现：

- `packages/novel_agent_core/lib/src/opening/opening_orchestration_service.dart`
- `packages/novel_agent_core/lib/src/opening/opening_next_action_resolver.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/project_opening_session_projection_service.dart`

当前重复入口：

- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
- `apps/novel_agent_app/lib/features/inspiration_workbench/application/controllers/inspiration_workbench_controller.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_entry_prompt_builder_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_opening_prompt_builder_service.dart`

目标正式出口：

- `OpeningOrchestrationService` + `OpeningNextActionResolver` 作为唯一正式开局事实源
- app 只消费 `OpeningSessionProjection` / `OpeningSuggestedAction`
- 所有入口只做投影或转发，不再自带开局业务判断

冻结备注：

- `opening.start_long_task_run`、`guide.create_workflow_from_mode_guidance` 这类动作只能由正式开局合同派生，不能在 controller 里再手写一套进入语义。

### 3.2 工具暴露真相源

当前主实现：

- `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`
- `packages/novel_agent_core/lib/src/tools/tool_exposure_policy_service.dart`
- `packages/novel_agent_core/lib/src/tools/tool_schema_builder_service.dart`
- `packages/novel_agent_core/lib/src/tools/host_tool_permission_policy_service.dart`

当前重复入口：

- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
- `packages/novel_agent_core/lib/src/tools/tool_strategy_prompt_builder.dart`
- `packages/novel_agent_core/lib/src/tools/tool_strategy_service.dart`
- `packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart`

目标正式出口：

- `ContinuousTaskToolExposureRuntimeResolverService` 作为工具暴露事实源
- `ToolExposurePolicyService` 作为 host/project 过滤事实源
- `ToolSchemaBuilderService` 作为 schema 投影出口

冻结备注：

- prompt builder 只能消费工具真相，不允许反过来决定工具真相。
- runtime bridge 只能转译与过滤，不允许额外编造工具语义。

### 3.3 子智能体调度真相源

当前主实现：

- `packages/novel_agent_core/lib/src/agents/agent_group_delegation_capability_service.dart`
- `packages/novel_agent_core/lib/src/agents/agent_group_tool_capability_scope_service.dart`
- `packages/novel_agent_core/lib/src/agents/sub_agent_effective_execution_profile_service.dart`

当前重复入口：

- `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
- `packages/novel_agent_core/lib/src/tools/tool_strategy_prompt_builder.dart`

目标正式出口：

- `AgentGroupDelegationCapabilityService` + `AgentGroupToolCapabilityScopeService` 作为子智能体资格唯一出口
- `SubAgentEffectiveExecutionProfileService` 只消费资格结果，不再自造资格判断

冻结备注：

- 单智能体组、derived single-agent 组、明确 child delegation 组要按同一套资格合同消费。
- `call_sub_agent` 只能被资格合同放行或阻断，不能靠各层各自回退。

### 3.4 审核调度真相源

当前主实现：

- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_reviewer_dispatch_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_review_report_service.dart`

当前重复入口：

- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_checkpoint_review_task_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_review_repair_task_service.dart`

目标正式出口：

- `ProjectWorkflowReviewerDispatchService` 作为审核调度唯一出口
- `ProjectReviewReportService` 只负责记录与读取，不负责重新决定 reviewer dispatch

冻结备注：

- review 任务是否委派、委派给谁、何时回退自审，只能由审核调度合同决定。
- app 侧的 review center / task center 只做投影与触发，不再重写委派逻辑。

### 3.5 样章 / 正文 / 章节 / 规划 / 信息产物真相源

当前主实现：

- `packages/novel_agent_core/lib/src/project/project_content_path_policy_service.dart`
- `packages/novel_agent_core/lib/src/project/chapter_output_path_policy_service.dart`
- `packages/novel_agent_core/lib/src/project/project_narrative_artifact_path_policy_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_path_policy_service.dart`
- `packages/novel_agent_core/lib/src/review/review_path_policy_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_output_path_service.dart`

当前重复入口：

- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/workflow_runtime_satisfied_output_path_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`

目标正式出口：

- core 侧 path policy family 作为唯一正式路径合同
- adapters 侧只负责落盘、读取、桥接与结果投影
- app 侧只消费输出路径与工件结果，不再自己决定命名与分类

冻结备注：

- 样章、正文、章节、规划产物、信息产物都必须回到正式路径合同。
- 任何“临时为 GUI 好展示”的路径规则都只能是投影，不能成为事实源。

### 3.6 会话恢复真相源

当前主实现：

- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/project_opening_session_projection_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`

当前重复入口：

- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_sidebar.dart`

目标正式出口：

- `ConversationSessionStateService` 作为会话状态恢复正式合同
- `ProjectSessionWorkspaceService` / 持久化层只做存取
- `ProjectOpeningSessionProjectionService` 只做恢复投影，不再判断恢复成败

冻结备注：

- 恢复是否成功、恢复后是否显示历史会话、滚动定位如何落点，都不能分散成多个正式出口。

### 3.7 拆书项目创建路线与导入能力真相源

当前主实现：

- `docs/important/book-deconstruction-core-migration-boundary-map-2026-06-15.md`
- `docs/important/book-deconstruction-core-migration-handoff-2026-06-15.md`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_menu_builder_service.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_target_path_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/book_deconstruction_import_archive_workflow_service.dart`

当前重复入口：

- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
- `apps/novel_agent_app/lib/features/project_creation/application/controllers/project_creation_controller.dart`
- `apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`

目标正式出口：

- 创建路线以 core followup/menu/path contract 为准
- 导入能力以 adapters/workflow 的正式 workflow service 为准
- app 侧只负责输入收集、状态推进和投影

冻结备注：

- 创建期决定后续路线，导入期只做来源选择与解析，不允许再补一套“导入时临时问后续类型”的链路。

### 3.8 provider / model 选择、筛选、应用结果真相源

当前主实现：

- `apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart`
- `apps/novel_agent_app/lib/features/settings/application/services/provider_connection_validation_service.dart`
- `apps/novel_agent_app/lib/features/settings/application/services/provider_settings_directory_service.dart`

当前重复入口：

- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/models/model_editor_view_data.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/models/settings_view_data.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`

目标正式出口：

- `ProviderConnectionValidationService` 作为 provider/model 连接与可用性真相源
- `ModelSettingsViewDataService` 明确退回 projection facade
- 选择、筛选、应用结果统一由同一套 shared contract 解释

冻结备注：

- 筛选只能约束候选提示，不能限制用户手动输入自由 model id。
- “筛选”语义必须是集合，不是单选替代。
- 输入捕获、自动展开、手动展开、选中应用、默认厂商范围要走同一条合同。

---

## 4. 本主线禁止继续碰撞的并行脏区

以下区域在本轮后续 session 中必须当作并行脏区处理，优先消费稳定合同，不直接重写真相源：

1. `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
2. `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
3. `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
4. `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
5. `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`
6. `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
7. `apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart`
8. `apps/novel_agent_app/lib/features/settings/application/services/provider_connection_validation_service.dart`
9. `apps/novel_agent_app/lib/features/inspiration_workbench/application/controllers/inspiration_workbench_controller.dart`

这些文件不是不能碰，而是只能在下一轮 session 指定目标下，沿着正式合同做收口，不能临时把它们重新变成业务中心。

---

## 5. 本轮后续接力顺序

1. 先做 `RBR-02` 的 runtime family 合同建模。
2. 再做 `RBR-03` 的巨石 runtime 抽离。
3. 再收 `RBR-04` 到 `RBR-07` 的开局、工具、产物、恢复合同。
4. 最后再拆 controller 与 shell。

这个顺序不能倒，因为后续所有 GUI / probe / adapter 收口都要消费这份边界冻结清单。

