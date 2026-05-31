# NovelAgentFlutter 开局引导与智能体组重构会话顺序文档

最后更新：2026-05-27

## 0.8 Session AG-08 完成记录

- 已完成 `Session AG-08：内置 starter groups、长任务启动探针与总回归`
- 本轮正式补齐并固定了首批内置 starter groups：
  - `starter_novel_generalist`
  - `starter_long_novel_seed_generalist`
  - `starter_long_novel_full_outline_generalist`
  - `starter_book_deconstruction_generalist`
- 当前行为已经固定：
  - 长任务 starter group 不再是一个泛化组，而是按项目 traits / baseline 正式分成：
    - `continuous_autonomous -> starter_long_novel_seed_generalist`
    - `chapter_collaboration_autorun -> starter_long_novel_full_outline_generalist`
  - 普通小说与拆书项目仍保持各自独立 starter group，不再和长任务组混淆
  - `ProjectOpeningSessionProjectionService` 现已完成四类开局覆盖：
    - 普通小说
    - 长任务 seed-driven
    - 长任务 full-outline
    - 拆书项目
  - `start_long_task_run` 已通过真实 adapter/runtime 闭环探针确认：
    - seed-driven 长任务可直接从 opening ready 进入创建任务链
    - full-outline 长任务可直接从 opening ready 进入创建任务链
- 本轮联调暴露并已修复的真实问题：
  - `AgentGroupCatalogOverlayDocumentCodecService`
    - 之前当 overlay 只改 `display_label` 时，也会把空的 `applicability_scope` 和默认 `recommended_by_default=false` 一并写入
    - 结果会错误覆盖 starter group 原有 scope / trait 规则，导致 catalog 侧真实过滤失真
    - 现在已改为：
      - 只有显式提供 `recommended_by_default` 时才写入
      - 只有显式提供 `applicability_scope` 时才写入
    - 这样局部 overlay 不会再冲掉内置 starter group 的适用范围
- 本轮新增探针：
  - `apps/novel_agent_app/tool/agent_group_opening_probe.dart`
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart test test/opening_orchestration_service_test.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart test test/local_agent_catalogs_test.dart test/agent_group_catalog_overlay_repository_test.dart test/project_long_task_tool_executor_test.dart`
    - 通过
  - `apps/novel_agent_app`
    - `flutter test test/project_opening_session_projection_service_test.dart`
    - 通过
  - `apps/novel_agent_app`
    - `dart analyze tool/agent_group_opening_probe.dart`
    - 通过
  - `apps/novel_agent_app`
    - `dart run tool/agent_group_opening_probe.dart`
    - `PASS`
  - `apps/novel_agent_app`
    - `dart run tool/seed_autopilot_mode_probe.dart`
    - `gap_probe PASS`
    - `plan_probe PASS`
  - `apps/novel_agent_app`
    - `dart run tool/full_outline_mode_probe.dart`
    - `gap_probe PASS`
    - `plan_probe PASS`
- 本轮新增报告：
  - `apps/novel_agent_app/artifacts/agent_group_opening_probe_report.json`
  - `apps/novel_agent_app/artifacts/seed_autopilot_mode_probe_report.json`
  - `apps/novel_agent_app/artifacts/full_outline_mode_probe_report.json`
- 当前状态：
  - `docs/agent-group-opening-redesign-session-order.md` 中 `AG-01 ~ AG-08` 已全部完成
  - 这一条“项目级智能体组 + opening + 长任务启动”重构主线已收口
- 后续扩展点：
  - 真正的多成员 starter groups / 开局协作组，后续可继续在：
    - `packages/novel_agent_adapters/lib/src/packages/builtin_starter_agent_group_registration_service.dart`
    扩，而不需要回改 opening/domain 主链
  - 更复杂的 opening 状态持久化与生态编辑器，仍应另开 session，不借 AG-08 的探针回归继续膨胀

## 0.7 Session AG-07 完成记录

- 已完成 `Session AG-07：项目级智能体组选择 UI 与轻 opening UI`
- app / Flutter 端已新增并明确：
  - `ConversationOpeningPanelViewDataService`
  - `OpeningUnsupportedReasonTextService`
  - `ProjectOpeningAgentGroupBindingService`
  - `OpeningPanelViewData`
  - `OpeningAgentGroupOptionViewData`
  - `OpeningUnsupportedGroupViewData`
  - `OpeningSessionPanel`
  - `OpeningAgentGroupPicker`
  - `OpeningUnsupportedGroupPanel`
- 当前行为已经固定：
  - 会话空态与轻引导态现在都会显示项目级智能体组入口
  - 默认只展示当前项目可直接使用的 group
  - 不可用 group 被收进可折叠高级入口，并显示原因摘要
  - 项目内切换 group 会正式写入 `.novel_agent/settings/project_agent_groups.json`
  - opening UI 已收束成：
    - 一句状态摘要
    - 轻量 group picker
    - 原有 starter actions
    - 其余继续交给对话推进
  - 长任务项目仍保留显式启动动作链，不把启动入口藏进额外页面
- 本轮刻意未做：
  - group editor / ecosystem 大改
  - opening 状态持久化
  - 新视觉主线或大面积布局改版
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `dart analyze lib/app/state/app_shell_controller.dart lib/features/workbench/application/controllers/workbench_conversation_controller.dart lib/features/workbench/application/services/conversation_opening_panel_view_data_service.dart lib/features/workbench/application/services/opening_unsupported_reason_text_service.dart lib/features/workbench/application/services/project_opening_agent_group_binding_service.dart lib/features/workbench/presentation/widgets/conversation_sidebar.dart lib/features/workbench/presentation/widgets/conversation_empty_state_panel.dart lib/features/workbench/presentation/widgets/workflow_guide_card.dart lib/features/workbench/presentation/widgets/opening_session_panel.dart lib/features/workbench/presentation/widgets/opening_agent_group_picker.dart lib/features/workbench/presentation/widgets/opening_unsupported_group_panel.dart lib/features/workbench/presentation/models/workbench_view_data.dart lib/features/workbench/presentation/models/workbench_conversation_view_data.dart`
    - 通过
  - `apps/novel_agent_app`
    - `flutter test test/conversation_opening_panel_view_data_service_test.dart test/project_opening_agent_group_binding_service_test.dart test/conversation_sidebar_test.dart test/conversation_input_dock_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_canvas_workspace_shell_test.dart`
    - 通过
- 后续扩展点：
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_opening_agent_group_binding_service.dart`
    - 后续 `AG-08` 或后续 session 可继续补 mode / stage scoped 选择入口，但不必回改 widget
  - `apps/novel_agent_app/lib/features/workbench/application/services/conversation_opening_panel_view_data_service.dart`
    - 后续若要扩项目类型专属 opening 轻摘要，可继续在这里扩，不要把规则写回组件
  - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/opening_session_panel.dart`
    - 后续若要继续贴近 frontend evolution 的统一视觉，可单独替换 panel 组合，而不影响绑定与 projection 链

## 0.6 Session AG-06 完成记录

- 已完成 `Session AG-06：app 装配与开局对话最小闭环`
- app 侧已新增并明确：
  - `ProjectOpeningSessionProjectionService`
  - `OpeningSessionProjection`
  - `OpeningAgentGroupSummary`
  - `ConversationOpeningGuideViewDataService`
- 当前已经明确：
  - workbench 会话区现在会按当前项目异步收束 opening projection，而不是继续只靠旧的 `SessionGuideProfileService`
  - 当前项目进入会话后，app 已能得到并消费：
    - 当前有效智能体组
    - 当前项目可用组摘要
    - opening readiness
    - starter actions
  - 当项目运行基准可推断出默认 mode guidance 时：
    - `continuous_autonomous -> seed_autopilot_novel`
    - `chapter_collaboration_autorun -> full_outline_consensus`
    app 会尝试恢复该模式的持久化引导状态
  - `opening.start_long_task_run` 现已正式桥接到既有 `ProjectLongTaskToolExecutor.startLongTaskRun(...)`
  - 原本过于死板的长任务默认 guide 已收窄为：
    - 轻状态摘要
    - opening starter actions
    - 其余交给 AI 对话继续引导
- 本轮刻意未做：
  - 正式 group picker UI
  - 不可用 group 原因的专门界面
  - opening 状态持久化
  - 项目内切换智能体组的正式交互入口
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter test test/project_opening_session_projection_service_test.dart test/conversation_guide_view_data_service_test.dart`
    - 通过
  - `apps/novel_agent_app`
    - `dart analyze lib/features/workbench/application/controllers/workbench_conversation_controller.dart lib/features/workbench/application/models/opening_agent_group_summary.dart lib/features/workbench/application/models/opening_session_projection.dart lib/features/workbench/application/models/workbench_conversation_runtime_state.dart lib/features/workbench/application/services/conversation_guide_view_data_service.dart lib/features/workbench/application/services/conversation_opening_guide_view_data_service.dart lib/features/workbench/application/services/project_opening_session_projection_service.dart lib/app/state/app_shell_controller.dart lib/app/bootstrap/app_bootstrap.dart test/widget_test.dart`
    - 通过
- 后续扩展点：
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_opening_session_projection_service.dart`
    - 后续 `AG-07` 可继续补项目级 group picker、unsupported reason projection 与更多 project type opening 规则
  - `apps/novel_agent_app/lib/features/workbench/application/services/conversation_opening_guide_view_data_service.dart`
    - 后续 UI 若要把 opening 改成更正式的轻卡片或多段摘要，可继续复用这里的 projection 渲染
  - `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
    - 后续只需要继续补 action bridge，不应再把 opening 判定写回控制器

## 0.5 Session AG-05 完成记录

- 已完成 `Session AG-05：opening session 状态机与 readiness orchestration`
- core 已新增并明确：
  - `OpeningIntentSnapshot`
  - `OpeningStageRecord`
  - `OpeningMissingRequirement`
  - `OpeningReadinessAssessment`
  - `OpeningSuggestedAction`
  - `OpeningSessionState`
  - `OpeningOrchestrationResult`
  - `OpeningStageRecordBuilderService`
  - `OpeningReadinessEvaluator`
  - `OpeningNextActionResolver`
  - `OpeningOrchestrationService`
- 当前已经明确：
  - opening 现已不再依赖页面临时字段拼装
  - `OpeningOrchestrationService` 会把：
    - 项目类型
    - 当前有效智能体组
    - 运行基准
    - 长任务模式
    - `ModeGuidanceState`
    收束成稳定的 opening 快照
  - 长任务 opening 现已正式区分这些步骤：
    - 智能体组
    - 运行基准
    - 模式选择
    - mode guidance 分阶段收束
    - 启动长任务
  - 普通小说 opening 现已正式区分这些步骤：
    - 智能体组
    - 会话目标
    - 开局说明
    - 开始协作
  - readiness 现已能明确输出：
    - 是否可启动长任务
    - 是否可启动普通协作会话
    - 还缺哪些 requirement
    - 推荐下一步结构化动作
  - 当只有一个可用智能体组时，opening orchestration 会把它视为当前有效组，减少无意义确认
- 本轮刻意未做：
  - opening 状态持久化
  - app / Flutter 接线
  - 真实 prompt 文案与引导话术整合
  - `start_long_task_run` 的 app 级真正消费
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart analyze lib/novel_agent_core.dart lib/src/opening test/opening_orchestration_service_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/opening_orchestration_service_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/project_agent_group_candidate_resolver_service_test.dart test/agent_availability_resolver_service_test.dart test/agent_group_availability_resolver_service_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/mode_guidance_transition_service_test.dart test/mode_guidance_plan_input_builder_service_test.dart test/mode_guidance_full_outline_builder_service_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart analyze test/mode_guidance_transition_service_test.dart test/mode_guidance_plan_input_builder_service_test.dart test/mode_guidance_full_outline_builder_service_test.dart`
    - 通过
- 后续扩展点：
  - `packages/novel_agent_core/lib/src/opening/opening_orchestration_service.dart`
    - 后续 `AG-06` 可直接接 app 当前项目上下文、group candidate 与 mode guidance state
  - `packages/novel_agent_core/lib/src/opening/opening_readiness_evaluator.dart`
    - 后续可继续补 book_deconstruction / knowledge_base / short_collection 的专属 opening 规则
  - `packages/novel_agent_core/lib/src/opening/opening_next_action_resolver.dart`
    - 后续 app 侧 starter action / tool entry 可直接桥接这里的 commandId，而不用再散落硬分支
  - `packages/novel_agent_core/lib/src/opening/opening_stage_record_builder_service.dart`
    - 后续 UI 若要展示轻量进度条或阶段卡片，可直接复用这里的 stage projection

## 0.4 Session AG-04 完成记录

- 已完成 `Session AG-04：overlay / binding 持久化与内置注册`
- adapters 已新增并明确：
  - `AgentCatalogOverlayRepository`
  - `AgentGroupCatalogOverlayRepository`
  - `ProjectAgentGroupBindingRepository`
  - `BuiltinStarterAgentGroupRegistrationService`
  - `CatalogOverlayMergeService`
- core 已补齐最小文档归一化基座：
  - `AgentApplicabilityScopeNormalizerService`
  - `AgentGroupApplicabilityScopeNormalizerService`
  - `ProjectAgentGroupSelectionNormalizerService`
- 当前已经明确：
  - 产品侧 catalog overlay 现已正式落到全局设置根目录：
    - `catalog_overlays/agents/*.json`
    - `catalog_overlays/agent_groups/*.json`
  - 项目级智能体组绑定现已正式落到当前项目隐藏目录：
    - `.novel_agent/settings/project_agent_groups.json`
  - `LocalAgentPackageCatalog` 现在会在加载包定义后叠加 agent overlay
  - `LocalAgentGroupCatalog` 现在会：
    - 先注入内置 starter groups
    - 再叠加项目 / 内置目录组定义
    - 最后叠加 group overlay
  - starter group 这一轮先收束为“项目类型感知的单成员默认组”
    - 统一复用 `default_generalist`
    - 不在这一轮提前引入新的多成员开局组依赖
- 本轮刻意未做：
  - overlay 编辑 UI
  - app 对 project group binding 的正式消费
  - 导入导出与 overlay 仓储整合
  - 多成员 starter group 正式编排内容
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart analyze lib/novel_agent_core.dart lib/src/agents/agent_applicability_scope_normalizer_service.dart lib/src/agents/agent_group_applicability_scope_normalizer_service.dart lib/src/agents/project_agent_group_selection_normalizer_service.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart analyze lib/novel_agent_adapters.dart lib/src/bootstrap/adapter_bundle.dart lib/src/packages/agent_catalog_overlay_document_codec_service.dart lib/src/packages/agent_catalog_overlay_repository.dart lib/src/packages/agent_group_catalog_overlay_document_codec_service.dart lib/src/packages/agent_group_catalog_overlay_repository.dart lib/src/packages/builtin_starter_agent_group_registration_service.dart lib/src/packages/catalog_overlay_merge_service.dart lib/src/packages/catalog_overlay_path_service.dart lib/src/packages/local_agent_group_catalog.dart lib/src/packages/local_agent_package_catalog.dart lib/src/storage/project_agent_group_binding_document_codec_service.dart lib/src/storage/project_agent_group_binding_path_service.dart lib/src/storage/project_agent_group_binding_repository.dart test/agent_catalog_overlay_repository_test.dart test/agent_group_catalog_overlay_repository_test.dart test/project_agent_group_binding_repository_test.dart test/local_agent_catalogs_test.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart test test/agent_catalog_overlay_repository_test.dart test/agent_group_catalog_overlay_repository_test.dart test/project_agent_group_binding_repository_test.dart test/local_agent_catalogs_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/project_agent_group_candidate_resolver_service_test.dart test/agent_availability_resolver_service_test.dart test/agent_group_availability_resolver_service_test.dart`
    - 通过
- 后续扩展点：
  - `packages/novel_agent_adapters/lib/src/packages/agent_catalog_overlay_repository.dart`
    - 后续可直接接全局 overlay 编辑器与 CLI 编辑入口
  - `packages/novel_agent_adapters/lib/src/packages/agent_group_catalog_overlay_repository.dart`
    - 后续可直接接 group 可用性调优与默认推荐策略编辑
  - `packages/novel_agent_adapters/lib/src/storage/project_agent_group_binding_repository.dart`
    - 后续 `AG-06` 可直接接 app 当前项目 group 选择与恢复
  - `packages/novel_agent_adapters/lib/src/packages/builtin_starter_agent_group_registration_service.dart`
    - 后续 `AG-08` 可在这里扩充真正的首批开局默认组，而不用回改 catalog 主逻辑

## 0.3 Session AG-03 完成记录

- 已完成 `Session AG-03：availability resolver 与项目级绑定解析`
- core 已新增并明确：
  - `AgentAvailabilityContext`
  - `AgentAvailabilityReasonCode`
  - `AgentAvailabilityReason`
  - `AgentAvailabilityAssessment`
  - `AgentGroupAvailabilityAssessment`
  - `ProjectAgentGroupSelectionResolverService`
  - `AgentAvailabilityResolverService`
  - `AgentGroupAvailabilityResolverService`
  - `ProjectAgentGroupCandidateResolution`
  - `ProjectAgentGroupCandidateResolverService`
- 当前已经明确：
  - 单智能体 availability 现已正式区分：
    - 项目绑定禁用
    - 项目类型不匹配
    - mode 不匹配
    - stage 不匹配
    - required traits 缺失
    - excluded traits 命中
  - group availability 现已正式认识：
    - scope 是否匹配
    - required 成员是否缺失
    - primary 成员是否可用
    - optional 成员是否可裁剪
    - 是否允许 degraded run
  - `ProjectAgentGroupSelectionResolverService` 已把 group 绑定的：
    - enabled
    - mode scope
    - stage scope
    - selectedByDefault
    统一收口
  - `ProjectAgentGroupCandidateResolverService` 已补出两层候选解析：
    - 优先显式 `ProjectAgentGroupSelection`
    - 若项目还只有旧的 `ProjectAgentBinding`，则自动退化为单成员派生组候选
  - 这意味着旧项目即便还没正式切到 group binding，也不会因为这轮重构立刻失去默认候选
- 本轮刻意未做：
  - overlay 持久化
  - group selection normalizer / codec
  - app 装配
  - UI 不可用原因投影
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart test test/agent_availability_resolver_service_test.dart test/agent_group_availability_resolver_service_test.dart test/project_agent_group_candidate_resolver_service_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart analyze lib/src/agents/agent_availability_context.dart lib/src/agents/agent_availability_reason_code.dart lib/src/agents/agent_availability_reason.dart lib/src/agents/agent_availability_assessment.dart lib/src/agents/agent_group_availability_assessment.dart lib/src/agents/project_agent_group_selection_resolver_service.dart lib/src/agents/agent_availability_resolver_service.dart lib/src/agents/agent_group_availability_resolver_service.dart lib/src/agents/project_agent_group_candidate_resolution.dart lib/src/agents/project_agent_group_candidate_resolver_service.dart test/agent_availability_resolver_service_test.dart test/agent_group_availability_resolver_service_test.dart test/project_agent_group_candidate_resolver_service_test.dart lib/novel_agent_core.dart`
    - 通过
- 后续扩展点：
  - `packages/novel_agent_core/lib/src/agents/agent_availability_*.dart`
    - 后续 `AG-04` 可直接接 overlay scope 输入，不需要回改 reason 模型
  - `packages/novel_agent_core/lib/src/agents/project_agent_group_selection_resolver_service.dart`
    - 后续 group binding 仓储落地后可直接复用
  - `packages/novel_agent_core/lib/src/agents/project_agent_group_candidate_resolver_service.dart`
    - 后续 app 侧需要“当前 group / 默认 group / 是否从旧 agent binding 派生”时可直接消费

## 0.2 Session AG-02 完成记录

- 已完成 `Session AG-02：group-first runtime 合同与单智能体组适配`
- core 已新增并明确：
  - `ProjectAgentGroupSelection`
  - `ResolvedAgentGroupMemberProfile`
  - `ResolvedAgentGroupProfile`
  - `AgentGroupMemberRoleService`
  - `ResolvedAgentGroupProfileBuilderService`
  - `SingleAgentGroupAdapterService`
- 当前已经明确：
  - group-first 运行对象已不再只能依赖 `JsonMap`
  - `ResolvedAgentGroupProfile` 现在会正式区分：
    - `primary member`
    - `required members`
    - `optional members`
  - `SingleAgentGroupAdapterService` 已把单智能体路径统一包装成单成员组：
    - 单成员
    - 主成员
    - 必需成员
    - 默认不再需要额外维护“单智能体专用运行入口”合同
  - `AgentGroupMemberRoleService` 已支持从 group 文档中识别：
    - `primary_agent_id`
    - `required_agent_ids`
    - `optional_agent_ids`
    - `member_roles`
    并兼容从 `metadata` 读取
  - `ResolvedAgentGroupProfileBuilderService` 已能把：
    - 轻量 group 声明
    - 强类型 `AgentProfile`
    合成为正式运行对象
  - 当前默认规则也已固定：
    - 未显式声明 primary 时，首成员为 primary
    - primary 永远属于 required
    - 未显式声明 required 列表时，除 optional 外其余成员默认 required
- 本轮刻意未做：
  - availability resolver
  - 项目级 group 绑定持久化
  - opening orchestration
  - 对现有 map-based 子智能体运行链的大面积迁移
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart test test/resolved_agent_group_profile_builder_service_test.dart test/single_agent_group_adapter_service_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart analyze lib/src/agents/project_agent_group_selection.dart lib/src/agents/resolved_agent_group_member_profile.dart lib/src/agents/resolved_agent_group_profile.dart lib/src/agents/agent_group_member_role_service.dart lib/src/agents/resolved_agent_group_profile_builder_service.dart lib/src/agents/single_agent_group_adapter_service.dart test/resolved_agent_group_profile_builder_service_test.dart test/single_agent_group_adapter_service_test.dart lib/novel_agent_core.dart`
    - 通过
- 后续扩展点：
  - `packages/novel_agent_core/lib/src/agents/resolved_agent_group_profile*.dart`
    - 后续 `AG-03` 可直接在此基础上继续构建 availability resolver 和 default candidate 解析
  - `packages/novel_agent_core/lib/src/agents/project_agent_group_selection.dart`
    - 后续 `AG-04` 可继续接项目级持久化与 overlay 合并
  - `packages/novel_agent_core/lib/src/agents/single_agent_group_adapter_service.dart`
    - 后续 app / adapter 若仍有“单智能体直跑”老入口，可逐步统一改走这里，而不是继续分叉维护

## 0.1 Session AG-01 完成记录

- 已完成 `Session AG-01：项目 traits 与 applicability scope 核心合同`
- core 已新增并明确：
  - `ProjectTrait`
  - `ProjectTraitSet`
  - `ProjectTraitResolverService`
  - `AgentApplicabilityScope`
  - `AgentGroupApplicabilityScope`
  - `ApplicabilityMatchResult`
  - `ApplicabilityScopeMatcherService`
- 当前已经明确：
  - 项目 traits 不再依赖页面或临时字符串硬判断
  - `ProjectTypeDefinition` 已开始声明 `defaultTraits`
  - `ProjectTypeCatalogService` 现已内置：
    - `novel -> opening_guided`
    - `long_novel -> long_task + opening_guided`
    - `book_deconstruction -> book_deconstruction`
  - `ProjectTraitResolverService` 已能从：
    - `projectTypeId`
    - `runtimeBaselineId`
    - `modeId`
    - `additionalTraitIds`
    收束稳定 trait 集
  - applicability matcher 现已正式支持：
    - 项目类型过滤
    - required traits
    - excluded traits
    - mode scope
    - stage scope
  - 现有 `ProjectAgentBinding` 仍保持“项目内绑定关系”职责，没有被膨胀成适用性总表
- 本轮刻意未做：
  - overlay 文档格式
  - group-first runtime
  - 项目级 group 绑定持久化
  - opening 状态机
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart test test/project_trait_resolver_service_test.dart test/applicability_scope_matcher_service_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart analyze lib/src/project/project_trait.dart lib/src/project/project_trait_set.dart lib/src/project/project_trait_resolver_service.dart lib/src/project/project_type_definition.dart lib/src/project/project_type_catalog_service.dart lib/src/agents/agent_applicability_scope.dart lib/src/agents/agent_group_applicability_scope.dart lib/src/agents/applicability_match_result.dart lib/src/agents/applicability_scope_matcher_service.dart test/project_trait_resolver_service_test.dart test/applicability_scope_matcher_service_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart analyze lib/novel_agent_core.dart`
    - 通过
- 后续扩展点：
  - `packages/novel_agent_core/lib/src/project/project_trait*.dart`
    - 后续可继续接更多 built-in traits 或项目级自定义 traits，而不需要回改 matcher
  - `packages/novel_agent_core/lib/src/agents/agent_applicability_scope.dart`
  - `packages/novel_agent_core/lib/src/agents/agent_group_applicability_scope.dart`
  - `packages/novel_agent_core/lib/src/agents/applicability_scope_matcher_service.dart`
    - 后续 `AG-03` 可直接在此基础上继续构建 availability reason 与 resolver


## 0. 文档目的

这份文档服务于下一轮比较根部的演化：

1. 把“长任务 / 普通项目 / 拆书项目”的开局体验，从偏死板的引导页收束成：
   - 前端轻提示
   - 对话内 AI 主导引导
   - 底层仍然受控的 opening 状态机
2. 把“选智能体”正式收束成“选智能体组”：
   - 单智能体也走单成员组
   - 不再维护两套并行产品路径
3. 把智能体 / 智能体组的可用范围从硬编码走向产品侧 overlay：
   - 不改智能体源文件本体定义
   - 在本项目中单独定义适用项目类型 / traits / 子分组
4. 让项目级智能体组绑定、长任务启动工具、开局对话引导三者形成一个完整闭环。

这不是 UI 美化文档。

这轮的主轴是：

- 先 core
- 再 adapter
- 再 app 装配
- 最后才做 UI
- 在合适节点才开探针

---

## 1. 当前问题收束

结合现状，真正需要解决的不是“再加一个引导页”，而是下面几类结构问题：

1. 当前开局引导仍偏流程页思维，灵活性不够，用户一旦偏离预设路径，体验会变硬。
2. 智能体、智能体组、项目类型、长任务模式、开局阶段之间的可用性边界还不够正式。
3. 单智能体与智能体组如果继续双轨存在，后续项目级绑定、适用性过滤、UI 选择器都会反复分叉。
4. 如果把“适用于哪些项目”直接写回智能体源文件，会让内置包、第三方包、产品层策略耦死。
5. 如果过早做 UI，很容易又把 opening 状态、group 过滤、项目绑定逻辑堆回大 controller。

因此这轮的目标不是“加更多入口”，而是把：

- opening orchestration
- group-first runtime
- applicability overlay
- project-level binding

这四条先立成正式结构。

---

## 2. 本轮敲定的设计方向

### 2.1 开局体验方向

- 保留一个很轻的开场提示和少量 starter action
- 后续主要由 AI 在会话中引导用户补齐信息
- 但底层不能退化成完全自由聊天，仍要保留可判断“是否已可启动”的 opening session 状态

### 2.2 智能体运行方向

- 用户永远选“智能体组”
- 单智能体模式包装成“单成员组”
- 所有运行期解析、展示、项目绑定都以 group 为一等对象

### 2.3 适用性方向

- 不把“适用哪些项目”硬写死在 agent 包源文件里
- 采用产品侧 overlay 元数据补充：
  - 智能体适用范围
  - 智能体组适用范围
  - 默认组建议
  - 不可用原因

### 2.4 项目分类方向

- 少加硬 subtype
- 尽量采用 traits / tags 表达项目特征，例如：
  - `long_task`
  - `seed_driven`
  - `full_outline`
  - `opening_guided`
  - `book_deconstruction`

### 2.5 UI 显示方向

- 默认只显示可用的智能体组
- 但最好保留“查看不可用项及原因”的高级入口
- 不在这轮前半段就做复杂 UI

---

## 3. 全局硬约束

后续每个 session 都继续遵守：

- 单一职责
- 解耦优先
- 不让单文件过重
- core 不依赖 Flutter
- app 不吞业务
- adapter 不反向长成业务中心
- 优先复用已有：
  - `ProjectAgentBinding`
  - `ProjectAgentBindingResolverService`
  - `AgentGroupCatalogService`
  - `BuiltinCollaboratorCatalogService`
  - `start_long_task_run` 现有工具链

### 3.1 文件体量约束

- 单文件超过 `400` 行必须自检
- 单文件接近 `700` 行必须主动拆
- 不允许把新职责继续堆回：
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
  - 任何新的“超级 opening controller”
  - 任何新的“超级 group resolver”

### 3.2 设计模式约束

这轮优先使用：

- policy / resolver
- overlay repository
- state object
- orchestration service
- adapter / bridge

尽量避免：

- 大枚举混合多维语义
- 页面组件直接判断全部适用性规则
- 用一个 controller 同时管 opening、binding、availability、launch

### 3.3 UI 介入顺序约束

必须先完成这些核心部分，才进入 UI：

1. applicability 合同
2. group-first runtime 合同
3. project-level group binding 与 overlay 持久化
4. opening orchestration core
5. app 最小接线

也就是说：

- `AG-01 ~ AG-05` 以 core / adapter 为主
- `AG-06` 才进入 app 级接线
- `AG-07` 才做正式 UI
- 真实探针以 `AG-08` 为主，不提前硬跑

---

## 4. 关键批判与改良结论

针对“只让 AI 自由引导用户直到发起长任务”的原始想法，这里做几条正式收束：

### 4.1 不能完全放任自由聊天

如果完全依赖模型自由判断何时信息足够：

- 会导致不同模型表现漂移
- 容易重复追问
- 难以判定何时显示启动动作
- 探针很难稳定回归

因此要保留：

- `OpeningSessionState`
- `OpeningReadinessEvaluator`
- `OpeningOrchestrationService`

### 4.2 不建议“项目类型 x 智能体 x 智能体组 x 模式”全写成硬分支

那样会很快出现组合爆炸。

因此更合适的是：

- 项目类型保留主分类
- 再叠加 traits
- 智能体 / 组通过 applicability scope 与 trait matcher 判定可用性

### 4.3 不建议让“智能体组选择”和“智能体选择”并存为两套入口

否则：

- 项目绑定逻辑要做两套
- UI 要做两套
- 可用性过滤要做两套
- opening 启动默认组策略也要做两套

更好的做法是：

- 统一只选 group
- 单智能体由 single-member group 适配

### 4.4 不建议把所有 opening 逻辑继续塞在现有会话 UI 服务里

现有 `conversation_guide_view_data_service.dart` 可以继续保留一部分视图投影职责，但不应继续长成：

- opening domain state 持有者
- 启动资格判断器
- group 过滤器
- 项目级绑定协调器

这些必须拆出去。

---

## 5. 执行顺序总览

建议按下面顺序推进：

1. `Session AG-01`：项目 traits 与 applicability scope 核心合同
2. `Session AG-02`：group-first runtime 合同与单智能体组适配
3. `Session AG-03`：availability resolver 与项目级绑定解析
4. `Session AG-04`：overlay / binding 持久化与内置注册
5. `Session AG-05`：opening session 状态机与 readiness orchestration
6. `Session AG-06`：app 装配与开局对话最小闭环
7. `Session AG-07`：项目级智能体组选择 UI 与轻 opening UI
8. `Session AG-08`：内置 starter groups、长任务启动探针与总回归

---

## 6. Session AG-01：项目 traits 与 applicability scope 核心合同

### 本轮目标

先把“什么项目可用什么智能体 / 智能体组”的领域表达正式立起来，但先不碰 UI。

### 预计改动量

- 约 `900 ~ 1600` 行

### 必读文档

- `agent.md`
- `docs/major-redesign-master-plan.md`
- `docs/migration-progress.md`
- 本文档

### 必须完成

1. 在 core 建立项目特征表达，例如：
   - `ProjectTrait`
   - `ProjectTraitSet`
   - `ProjectTraitResolverService`
2. 建立适用范围合同，例如：
   - `AgentApplicabilityScope`
   - `AgentGroupApplicabilityScope`
   - `ApplicabilityMatchResult`
3. 明确适用性表达至少支持：
   - 项目类型
   - traits
   - 可选 stage / mode tags
4. 让 scope 合同和现有 `ProjectAgentBinding` 分层：
   - scope 负责“可不可用”
   - binding 负责“项目内当前绑定什么”

### 本轮不要做

- 不做项目级绑定持久化
- 不做 group 解析
- 不做 opening 状态机
- 不做任何 UI

### 本轮重点拆耦

- `trait contract`
- `scope contract`
- `scope matcher`

三者分开，不要用一个 normalize 文件全包。

### 完成判定

- core 已能表达项目 traits 与智能体 / 组的适用范围
- 不需要依赖 Flutter 或项目文件读写
- 现有 `ProjectAgentBinding` 没被误膨胀成适用性总表

### 建议提示词

```text
按 docs/agent-group-opening-redesign-session-order.md 的 Session AG-01 执行。先阅读 agent.md、docs/major-redesign-master-plan.md、docs/migration-progress.md 和本文件。先只做 core 合同：建立 ProjectTrait / ProjectTraitSet / ProjectTraitResolverService，以及 AgentApplicabilityScope / AgentGroupApplicabilityScope / ApplicabilityMatchResult，让项目类型、traits、可选 stage/mode tags 能正式参与可用性判定。不要做 UI，不要做持久化，不要把适用性硬塞进 ProjectAgentBinding。
```

---

## 7. Session AG-02：group-first runtime 合同与单智能体组适配

### 本轮目标

把“永远按智能体组运行”正式变成运行时规则，同时保留单智能体兼容。

### 预计改动量

- 约 `800 ~ 1500` 行

### 必读文档

- `agent.md`
- `docs/migration-progress.md`
- 本文档

### 必须完成

1. 在 core 建立 group-first 运行合同，例如：
   - `ResolvedAgentGroupProfile`
   - `ProjectAgentGroupSelection`
   - `SingleAgentGroupAdapterService`
2. 明确单智能体如何包装成单成员组
3. 明确组内成员角色：
   - required
   - optional
   - primary
4. 让后续运行解析都优先基于 group，而不是 agent

### 本轮不要做

- 不做可用性过滤 UI
- 不做 overlay 持久化
- 不做 opening 引导
- 不改底层子智能体调度策略

### 本轮重点拆耦

- `group runtime profile`
- `single-agent adapter`
- `member role policy`

### 完成判定

- 单智能体不再是另一条产品路径
- 运行层已能统一面向 group 对象
- 后续 UI 只需选择 group，不需双轨支持

### 建议提示词

```text
按 docs/agent-group-opening-redesign-session-order.md 的 Session AG-02 执行。先阅读 agent.md、docs/migration-progress.md 和本文件。把运行时正式收束成 group-first：建立 ResolvedAgentGroupProfile、ProjectAgentGroupSelection、SingleAgentGroupAdapterService，明确单智能体如何包装成单成员组，并区分 required/optional/primary 成员角色。不要做 UI，不要做 overlay 持久化，不要改底层子智能体调度。
```

---

## 8. Session AG-03：availability resolver 与项目级绑定解析

### 本轮目标

把“哪些组可见、哪些组不可见、当前项目默认选哪组”正式解析出来。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/migration-progress.md`
- 本文档

### 必须完成

1. 在 core 建立可用性解析层，例如：
   - `AgentGroupAvailabilityResolverService`
   - `AgentAvailabilityResolverService`
   - `AgentGroupAvailabilityReason`
2. 解析规则至少覆盖：
   - group scope 是否匹配项目
   - required 成员是否都可用
   - optional 成员是否可裁剪
   - 是否允许降级运行
3. 在现有 `ProjectAgentBinding` 基础上补出：
   - 项目当前 group 绑定解析
   - 默认 group 候选解析
4. 为 UI 准备：
   - `supported`
   - `unsupported`
   - `why`

### 本轮不要做

- 不做文件落盘
- 不做 app 页面
- 不做 opening orchestration

### 本轮重点拆耦

- `availability resolver`
- `binding resolution`
- `reason projection`

### 完成判定

- core 已能输出某项目下的 group 可用列表与原因
- 支持默认候选与项目当前绑定并存
- 没有把“可用性原因”直接做成 UI 文案常量堆

### 建议提示词

```text
按 docs/agent-group-opening-redesign-session-order.md 的 Session AG-03 执行。先阅读 agent.md、docs/migration-progress.md 和本文件。只做 core 解析层：建立 AgentGroupAvailabilityResolverService、AgentAvailabilityResolverService 和 availability reason 模型，解析 group scope、required/optional 成员、是否允许降级运行，并在现有 ProjectAgentBinding 基础上补项目当前 group 绑定解析与默认候选解析。不要做 UI，不要做文件持久化。
```

---

## 9. Session AG-04：overlay / binding 持久化与内置注册

### 本轮目标

把产品侧 overlay 和项目级 group 绑定正式落到 adapters，可读可写，但先不做复杂编辑 UI。

### 预计改动量

- 约 `1100 ~ 1900` 行

### 必读文档

- `agent.md`
- `docs/migration-progress.md`
- `docs/major-redesign-master-plan.md`
- 本文档

### 必须完成

1. 在 adapter 侧建立 overlay 读写骨架，例如：
   - `AgentCatalogOverlayRepository`
   - `AgentGroupCatalogOverlayRepository`
   - `ProjectAgentGroupBindingRepository`
2. 明确 overlay 存储格式至少覆盖：
   - applicability scope
   - 默认推荐信息
   - 可选显示标签
3. 内置 starter groups 注册入口
4. 让项目级 group 绑定只影响当前项目，不污染全局默认

### 本轮不要做

- 不做完整生态编辑器改版
- 不做项目导入导出整合
- 不做 UI 过滤页

### 本轮重点拆耦

- `overlay codec`
- `overlay repository`
- `project binding repository`

不要把 codec、repository、默认注册写成一个大文件。

### 完成判定

- overlay 与项目绑定都已有正式 adapter 存取口
- 内置与项目级扩展可以共存
- 新项目默认组与项目当前绑定已能被区分

### 建议提示词

```text
按 docs/agent-group-opening-redesign-session-order.md 的 Session AG-04 执行。先阅读 agent.md、docs/migration-progress.md、docs/major-redesign-master-plan.md 和本文件。把产品侧 overlay 与项目级智能体组绑定正式落到 adapters：建立 AgentCatalogOverlayRepository、AgentGroupCatalogOverlayRepository、ProjectAgentGroupBindingRepository，以及基础 codec 与内置 starter groups 注册入口。不要做复杂 UI，不要顺手改导入导出整合。注意 overlay codec、repository、默认注册分层。
```

---

## 10. Session AG-05：opening session 状态机与 readiness orchestration

### 本轮目标

把开局引导从“几个按钮 + 自由聊天”收束成正式的 opening session 受控能力。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/long-task-mode-1-architecture.md`
- 本文档

### 必须完成

1. 在 core 建立 opening 领域对象，例如：
   - `OpeningSessionState`
   - `OpeningStageRecord`
   - `OpeningIntentSnapshot`
2. 建立 orchestration / readiness 层，例如：
   - `OpeningOrchestrationService`
   - `OpeningReadinessEvaluator`
   - `OpeningNextActionResolver`
3. 支持至少两类开局：
   - 长任务相关项目
   - 普通小说相关项目
4. readiness 输出至少能表达：
   - 仍需补充什么
   - 是否已可启动长任务 / 普通写作链
   - 推荐下一步动作

### 本轮不要做

- 不做前端大改
- 不做复杂选项 UI
- 不直接把 readiness 绑定到具体模型提示词文案

### 本轮重点拆耦

- `opening state`
- `readiness evaluator`
- `next action resolver`

### 完成判定

- opening 已有正式领域状态，而不是靠零散会话字段拼装
- AI 可以继续自由引导，但系统能判断“是否就绪”
- 后续 `start_long_task_run` 能基于 opening 状态稳定触发

### 建议提示词

```text
按 docs/agent-group-opening-redesign-session-order.md 的 Session AG-05 执行。先阅读 agent.md、docs/long-task-mode-1-architecture.md 和本文件。只做 opening session 核心：建立 OpeningSessionState、OpeningStageRecord、OpeningIntentSnapshot，以及 OpeningOrchestrationService、OpeningReadinessEvaluator、OpeningNextActionResolver，让长任务项目和普通小说项目都能在对话中被受控引导，并能判断是否已可启动后续链路。不要做前端大改，不要把 readiness 直接写死成提示词文本。
```

---

## 11. Session AG-06：app 装配与开局对话最小闭环

### 本轮目标

把前面 core / adapter 的结果接回 app，让项目进入会话后已经能按项目正确解析 group、opening 状态和启动动作。

### 预计改动量

- 约 `1000 ~ 1700` 行

### 必读文档

- `agent.md`
- 本文档
- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_guide_view_data_service.dart`

### 必须完成

1. app 装配 opening orchestration 与 group availability 解析
2. 让当前项目进入会话时可得到：
   - 当前 group
   - 可用 groups
   - opening readiness
   - 推荐 starter actions
3. 复用已有 `start_long_task_run` 能力，不重造启动链
4. 把原本过于死板的长任务开局提示收窄成轻提示 + AI 引导

### 本轮不要做

- 不做正式 group picker UI
- 不做设置页
- 不做生态编辑器大改

### 本轮重点拆耦

- `app composition`
- `view data projection`
- `action bridge`

不要把装配结果重新堆进一个 giant workbench controller。

### 完成判定

- app 已能按项目上下文解析正确的开局状态与默认 group
- 长任务相关项目里可以稳定出现启动工具路径
- 原有 guide 逻辑没有继续膨胀

### 建议提示词

```text
按 docs/agent-group-opening-redesign-session-order.md 的 Session AG-06 执行。先阅读 agent.md、本文件，以及 apps/novel_agent_app/lib/features/workbench/application/services/conversation_guide_view_data_service.dart。把 core/adapters 的 opening orchestration、group availability、项目级 group 绑定接回 app：当前项目进入会话时能解析当前 group、可用 groups、opening readiness 和推荐 starter actions，并复用现有 start_long_task_run 链路。不要做正式 group picker UI，不要把逻辑堆回大 controller。
```

---

## 12. Session AG-07：项目级智能体组选择 UI 与轻 opening UI

### 本轮目标

在领域与 app 装配立住后，再做正式前端入口，保持轻量而不是再做一个重流程页。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- 本文档
- `docs/frontend-evolution-session-order.md`

### 必须完成

1. 项目级智能体组选择入口
2. 默认只展示支持当前项目的 groups
3. 提供一个轻量“查看不可用项及原因”的高级入口或调试入口
4. opening UI 保持轻：
   - 一句提示
   - 少量 starter actions
   - 其余交给对话
5. 长任务相关项目中，保留显式启动动作或工具入口

### 本轮不要做

- 不做完整生态中心重设计
- 不做 group 编辑器大改
- 不做新的视觉主线

### 本轮重点拆耦

- `group picker view data`
- `unsupported reason projection`
- `opening starter panel`

### 完成判定

- 用户能在项目内切换支持当前项目的智能体组
- 不支持的 group 不会干扰主流程，但可查看原因
- opening UI 变轻，不再逼用户走死板流程页

### 建议提示词

```text
按 docs/agent-group-opening-redesign-session-order.md 的 Session AG-07 执行。先阅读 agent.md、本文件、docs/frontend-evolution-session-order.md。只做项目级智能体组选择 UI 与轻 opening UI：默认只显示支持当前项目的 groups，提供查看不可用项及原因的高级入口，并把 opening 区收束成一句提示 + 少量 starter actions，其余由对话引导。不要做完整生态中心重设计，不要扩新视觉主线。注意 group picker view data、unsupported reason projection、opening starter panel 分开。
```

---

## 13. Session AG-08：内置 starter groups、长任务启动探针与总回归

### 本轮目标

只做收尾验证与必要修补，不再扩新主线。

### 预计改动量

- 约 `700 ~ 1400` 行

### 必读文档

- `agent.md`
- 本文档
- `docs/migration-progress.md`

### 必须完成

1. 补齐首批内置 starter groups：
   - 普通小说开局默认组
   - 长任务 seed-driven 默认组
   - 长任务 full-outline 默认组
   - 拆书 / 解构类默认组
2. 运行探针，至少覆盖：
   - 普通小说项目开局
   - 长任务 seed-driven 开局
   - 长任务 full-outline 开局
   - 拆书项目开局
3. 验证：
   - group 过滤是否正确
   - 项目级 group 绑定是否只作用当前项目
   - AI 引导是否能把用户带到可启动状态
   - `start_long_task_run` 是否在长任务项目中正确触发
4. 只修联调暴露的问题
5. 回填文档

### 本轮不要做

- 不再开新功能主线
- 不再改大视觉
- 不借探针之名重写 opening 架构

### 本轮重点拆耦

- 探针脚本与业务服务分开
- 只修局部问题，不新造大中心文件

### 完成判定

- 新开局链路已有真实探针结果
- group-first、opening orchestration、project-level binding 三条线一致
- 文档状态与代码状态一致

### 建议提示词

```text
按 docs/agent-group-opening-redesign-session-order.md 的 Session AG-08 执行。先阅读 agent.md、本文件、docs/migration-progress.md。只做首批 starter groups、长任务启动探针与总回归：覆盖普通小说、长任务 seed-driven、长任务 full-outline、拆书项目四类开局，验证 group 过滤、项目级 group 绑定、AI 引导到可启动状态，以及 start_long_task_run 在长任务项目中的正确触发。只修联调问题，不开新主线，完成后回填文档。
```

---

## 14. 探针开启时机

这轮不要过早跑真实探针。

建议节奏：

1. `AG-01 ~ AG-03`
   - 以 unit test / resolver test 为主
   - 不跑真实 opening 探针
2. `AG-04 ~ AG-05`
   - 可开始跑 repository smoke test
   - 可做 opening readiness 小探针
   - 仍不跑整条长任务真实链
3. `AG-06`
   - 开始做 app 级 smoke
   - 验证 starter action 与 group 解析
4. `AG-08`
   - 再跑真实探针
   - 重点验证对话引导到启动闭环

这样做的原因很简单：

- 过早探针只能测到半成品
- 容易把临时 UI 或临时桥接误当成正式设计
- 会倒逼把本该在 core 的逻辑提前写进 app

---

## 15. 执行规则

后续按本文件推进时，默认遵循：

1. 一次会话只完成一个 session。
2. 如果上轮停在半截，或者暴露强关联回归，先补完，不开启下一轮。
3. 每轮开始前至少复读：
   - `agent.md`
   - 本文件对应 session
   - 该 session 指向的相关文档
4. 每轮结束时都要说明：
   - 本轮完成了什么
   - 哪些文件是后续扩展点
   - 哪些点被明确延期
5. 即便做到 UI，也继续遵守：
   - 单一职责
   - 避免单文件过重
   - view data / controller / widget / policy 分层

---

## 16. 当前推荐起点

从当前状态看，最自然的起点是：

1. `Session AG-01`
2. `Session AG-02`
3. `Session AG-03`

原因很明确：

- 现在最容易失控的是适用性与 group 语义，而不是 UI
- 先立 traits / scope / resolver，后面 opening 与项目绑定才不会反复返工
- 如果这三步不先立住，后面再做项目级 group 选择 UI，基本一定会回头拆第二次
