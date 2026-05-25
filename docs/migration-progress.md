# NovelAgent Flutter 迁移进度文档

最后更新：2026-05-25

## 本轮长任务收口补丁

- 已把项目级 `runtime_profile.json` 真正接入长任务启动链：
  - adapters 新增 `ProjectRuntimeProfileRepository`
  - adapters 新增 `ProjectTaskQueueRuntimeOptionResolver`
  - `ProjectWorkflowRuntimeService.runWorkflowTaskQueue(...)` 现在会先读取项目隐藏目录下的 runtime profile，再与本次显式参数合并
  - `TaskQueueOptionService / LongTaskRunOptionService` 已补保留：
    - `runtime_baseline_id`
    - `runtime_mode`
    - `unattended`
    - `auto_advance_chapters`
    - `keep_alive_across_project_switch`
- 已把 `chapter_collaboration_autorun` 的章级 gate 从“只有合同”推进到“自动 repair + 真阻塞下游”：
  - adapters 新增 `ProjectLongTaskChapterGateService`
  - review 任务若属于 `chapter_gate_review` 且报告有 issue / suggestion：
    - 自动派生或复用 repair revision 任务
    - 自动把直接依赖该 gate review 的下游任务改挂到 repair 任务
    - repair 任务继承 `runtime_baseline_id`、`workflow_mode`、长期上下文路径与前置 review 依赖
- 已新增验证：
  - `project_long_task_chapter_gate_service_test.dart`
  - `project_workflow_runtime_service_test.dart` 新增 runtime profile 启动读取用例
  - `project_long_task_review_repair_task_service_test.dart` 补继承字段断言

当前验证结果：

- `packages/novel_agent_core` 相关回归测试通过
- `packages/novel_agent_adapters` 针对本轮改动的定向测试通过
- `dart analyze packages/novel_agent_core packages/novel_agent_adapters apps/novel_agent_app apps/novel_agent_cli` 通过
- adapters 全量仍只剩既有 4 条失败：
  - `openai_llm_gateway_test.dart` 1 条
  - `project_tool_dispatcher_path_test.dart` 3 条

## 本轮 Session 01 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 01 落地项目主存储策略合同
- core 已新增：
  - `ProjectStorageStrategy`
  - `ProjectContentRepository`
  - `ProjectReadableProjectionService`
  - `ProjectDirectoryLayout`
  - `ProjectDirectoryLayoutService`
- `ProjectManifest / ProjectDescriptor / ProjectManifestCodecService` 已带 `storage_strategy`
- adapters 已新增：
  - `markdown_project_content_repository`
  - `sqlite_project_content_repository`
  - `project_storage_strategy_resolver`
  - 两个 delegating 分发壳
  - 两个 readable projection 壳
- 创建项目 use case 已正式改成：
  - 目录布局解析
  - 主内容初始化
  - 可读投影生成
- Flutter app bootstrap 与本轮相关 probe / test 构造点已补齐新的用例依赖
- 已新增针对 Session 01 的最小测试：
  - `project_manifest_storage_strategy_test.dart`
  - `project_directory_layout_service_test.dart`

当前仍明确未做：

- 新目录树真正切换
- SQLite schema / 表结构细节
- 跨策略迁移
- UI 创建流程改造

## 本轮 Session 02 收口

- 已把项目创建链正式改成“三段式领域流程”的基础版本：
  - 项目类型
  - 主存储策略
  - 长任务运行基准预留
- core 已新增：
  - `ProjectCreateRequest`
  - `ProjectCreationPlan`
  - `ProjectCreationNextStep`
  - `ProjectRuntimeBaselineDefinition`
  - `ProjectRuntimeBaselineCatalogService`
- `CreateProjectWorkspaceUseCase` 已新增：
  - `prepare(...)`
  - `executePrepared(...)`
- 当前规则已经明确：
  - 普通项目可直接创建
  - 长任务项目若未补选运行基准，只返回“下一步需要选择运行基准”的计划结果
  - 直接落盘入口不再绕过这条规则
- app 创建浮层已接入最小闭环：
  - 基础信息页可选项目类型与主存储策略
  - 选择长任务项目后会进入运行基准补选页
  - 补选完成后才正式创建并打开项目
- 现有长任务探针脚本已补成显式 `runtimeBaselineId`，避免被新规则卡住
- 已新增 Session 02 最小测试：
  - `packages/novel_agent_core/test/create_project_workspace_use_case_test.dart`

当前仍明确未做：

- 长任务运行基准写入项目元数据与初始运行配置
  - 已在后续 Session 09 完成
- 最终版项目创建 UI 打磨
- 基于项目类型限制不同模板 / 资产预设的创建阶段

## 本轮 Session 03 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 03 落地 Markdown 项目骨架重排
- core 已调整：
  - `ProjectWorkspaceCatalog`
    - 顶层用户认知目录改为 `premise / outlines / drafts / assets / tasks / analysis / exports`
    - 新增 `visibleWorkspaceSkeletonDirs`
    - 隐藏目录扩成 `.novel_agent/state|runtime|runs|threads|tasks|checkpoints|indexes|cache|settings|logs|modes|sqlite`
  - `ProjectDirectoryLayoutService`
    - Markdown 主内容目录与 SQLite 可读投影目录都切到新的骨架目录列表
- adapters 已调整：
  - 新增 `MarkdownProjectDirectorySkeletonService`
  - `MarkdownProjectContentRepository` 只负责触发骨架初始化，不再自己内嵌目录创建细节
  - `MarkdownProjectReadableProjectionService` 改为写入 `premise/project_brief.md`
  - `SqliteProjectReadableProjectionService` 的可读入口也同步到 `premise/project_brief.md`
- app 已调整：
  - 新增 `WorkspaceResourceDisplayService`
  - 资源树中文映射、隐藏规则、排序规则与“大纲按钮”候选路径已从 `AppShellController` 抽离
  - 资源树现在按新目录结构显示中文映射，但底层真实路径仍保持英文
- 旧占位清理策略：
  - 新骨架不再生成 `README.md`
  - 资源树继续隐藏根目录和一级子目录的 `README.md`
  - 项目清单默认隐藏 `.novel_agent/project_manifest.json` 与 `.novel_agent/` 内部结构
- 已新增 / 更新验证：
  - `packages/novel_agent_core/test/project_directory_layout_service_test.dart`
  - `packages/novel_agent_adapters/test/markdown_project_directory_skeleton_service_test.dart`

当前仍明确未做：

- 旧 runtime / tool / workflow 路径全面切换到新目录语义
- SQLite 主内容 schema 与正文字段设计
- 长任务系统对新目录结构的彻底迁移

## 本轮 Session 04 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 04 落地 `sqlite_project_store` 基础仓储壳
- core 已新增 SQLite 正文主存储模型：
  - `SqliteProjectBodyTextStorageFormat`
  - `SqliteProjectBodyTextSegment`
  - `SqliteProjectBodyTextDocument`
  - `SqliteProjectBodyTextPolicyService`
- 当前 core 已明确表达：
  - SQLite 正文只能是 `plain_text` 或 `segmented_text`
  - 明确禁止把整篇 Markdown blob 当作正文主存储
- adapters 已新增并拆分：
  - `SqliteProjectDirectorySkeletonService`
  - `SqliteProjectDatabaseOpener`
  - `SqliteProjectDatabaseInitializer`
  - `SqliteProjectMetadataStore`
  - `SqliteProjectBodyTextStore`
- `SqliteProjectContentRepository` 现在只编排两件事：
  - 创建 SQLite 项目的高级/隐藏目录骨架
  - 执行最小建库初始化
- 当前最小 SQLite schema 已落地：
  - `project_store_meta`
  - `body_text_document`
  - `body_text_segment`
- 初始化时会写入最小项目元数据：
  - `storage_strategy`
  - `project_type`
  - `schema_version`
  - `body_storage_policy`
  - `body_markdown_blob_allowed=false`

当前仍明确未做：

- SQLite 正文读写仓储的真正 save/load 用例
- SQLite 资产表、关系表、投影表
- SQLite -> Markdown 导出 codec
- 跨策略迁移与互转

## 本轮 Session 05 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 05 把长任务从“项目内功能”正式提升为 core 里的全局运行合同
- core 已新增 runtime 基础模型与目录：
  - `RuntimeBaseline`
  - `RuntimeBaselineCatalogService`
  - `RunProjectReference`
  - `RunInstance`
  - `LongTaskRunStatus`
  - `LongTaskRunRegistry`
  - `LongTaskHeartbeatPolicy`
  - `DefaultLongTaskHeartbeatPolicy`
  - `LongTaskRunStateMachine`
  - `RunInstanceFactoryService`
- 当前已明确：
  - 长任务运行实例是全局对象，不依赖某个页面是否打开
  - 运行基线不是模式策略本身，而是独立 runtime 合同
  - 项目关联通过 `RunProjectReference` 显式表达
  - 基础状态机统一使用：
    - `drafting_guidance`
    - `ready_to_start`
    - `running`
    - `waiting_gate`
    - `paused`
    - `recovering`
    - `failed_manual_attention`
    - `stopped`
- `ProjectRuntimeBaselineCatalogService` 已内部复用新的 runtime baseline 目录，保持项目创建链与全局 runtime 基线一致
- 当前心跳策略只定义：
  - 哪些状态需要心跳
  - 心跳间隔
  - 何时算 stale
  - 不包含自动恢复实现

当前仍明确未做：

- `LongTaskRunRegistry` 的本地持久化 adapter
- `LongTaskSupervisor` 与心跳轮询调度
- 自动恢复策略与恢复动作
- 现有 `workflow` map 结构与新 typed runtime model 的正式对接

## 本轮 Session 06 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 06 在 adapters 落地长任务全局运行适配层
- 新增 `runtime/` 子域并明确拆分为：
  - `LocalLongTaskRuntimePathService`
  - `RunInstanceDocumentCodecService`
  - `LocalLongTaskRunRegistry`
  - `LongTaskHeartbeatScheduler`
  - `LongTaskSupervisor`
  - `LongTaskHeartbeatEvent`
- 当前职责已经分开：
  - `registry` 只负责全局运行实例落盘与查询
  - `scheduler` 只负责扫描活跃运行实例并派发心跳 / stale 事件
  - `supervisor` 只负责编排 registry 与 scheduler，不直接推进 workflow
- 全局运行实例当前默认持久化到用户级设置根目录下：
  - `long_task_runtime/runs/*.json`
- `AdapterBundle` 已新增：
  - `longTaskRunRegistry`
  - `longTaskSupervisor`
  但尚未接入 Flutter 页面
- 当前心跳基础调度已实现：
  - 支持 `start/stop`
  - 支持 `pollOnce`
  - 支持基于 runtime baseline 与 heartbeat policy 的 due/stale 判断
  - 明确不包含自动恢复动作

当前仍明确未做：

- supervisor 与现有项目内 `ProjectWorkflowRuntimeService` 的正式对接
- app 级 `long_task_station` 子域
- CLI 对全局运行实例的查看 / 暂停 / 恢复入口
- 自动恢复与恢复后动作策略

## 本轮 Session 07 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 07 在 Flutter app 落地独立 `long_task_station` 子域
- 新增 app 级子域文件：
  - `features/long_task_station/application/controllers/long_task_station_controller.dart`
  - `features/long_task_station/application/models/long_task_station_snapshot.dart`
  - `features/long_task_station/application/services/long_task_station_view_data_service.dart`
  - `features/long_task_station/presentation/*`
- 当前职责已经拆开：
  - `LongTaskStationController` 只负责全局运行实例查询、选中态和动作入口壳
  - `LongTaskStationViewDataService` 只负责把 runtime snapshot 投影成 Flutter 展示模型
  - 页面与列表/详情控件只负责展示和交互
- app 壳层当前只做最薄接线：
  - 新增 `AppDestination.longTaskStation`
  - `AppRouter` 已接入独立页面
  - `AppBootstrap` 负责实例化 `LongTaskStationController`
  - `AppShellController` 只保留导航入口与刷新转发，不承接总站业务状态
- adapters 侧补齐了总站动作需要的 supervisor 壳：
  - `pauseRun(...)`
  - `resumeRun(...)`
  - `stopRun(...)`
  这些动作统一复用 core 的 `LongTaskRunStateMachine`
- 工作台左栏底部快捷入口已新增“长任务总站”，保证 GUI 里存在独立全局入口
- 已补最小验证：
  - `packages/novel_agent_adapters/test/long_task_supervisor_test.dart` 新增暂停/恢复/停止状态迁移测试

当前仍明确未做：

- 长任务总站详情树、章节树和运行事件时间线
- supervisor 与真实 workflow runtime 的自动恢复联动
- CLI 侧的全局长任务总站命令入口
- 长任务总站最终 UI 打磨

## 本轮 Session 08 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 08 把第二种长任务运行基准正式压进 core 运行链
- core 已新增并接通：
  - `RuntimeBaselineExecutionModeService`
  - `LongTaskChapterGatePolicyService`
  - `LongTaskChapterGateReviewTaskFactoryService`
- 当前已经明确：
  - `continuous_autonomous` 默认映射到 `seed_to_full_novel`
  - `chapter_collaboration_autorun` 默认映射到 `human_outline_ai_draft`
- `ModeGuidancePlanInput` 已正式带：
  - `runtimeBaselineId`
  - `runtime_baseline_id`
  并且：
  - mode 1 会输出 `continuous_autonomous`
  - mode 2 会输出 `chapter_collaboration_autorun`
  - mode 2 默认 `checkpoint_interval` 已收紧为 `0`，避免和逐章 gate 的自动推进语义冲突
- `LongTaskPlanRecordService / LongTaskRunOptionService / LongTaskRunRecordService` 已开始保留 `runtime_baseline_id`
- `LongTaskTaskFactoryService` 已新增 baseline 感知：
  - 先由 baseline 解析实际 runtime mode
  - `chapter_collaboration_autorun` 下会在每章后自动插入 gate review 任务
  - 下一章依赖会接到 gate review 后面，而不是直接接前一章
- `LongTaskDynamicTaskFactoryService` 已开始继承和回传 `runtime_baseline_id`
- `LongTaskTaskCompletionPolicyService` 已新增 baseline 规则：
  - `chapter_collaboration_autorun` 下的 `chapter / review / revision` 成功后默认自动 `succeeded`
  - 不再沿用“非 chapter 一律 waiting_user”的旧口径
- `TaskExecutionPlanService` 已能为章级 gate 任务显式补出：
  - 章级审稿闸门
  - 必要时自动返工
  - 闸门通过后推进下一章
- `LongTaskControllerProfileService / LongTaskUnattendedStrategyService` 已新增 baseline-aware 画像：
  - `checkpoint_policy=after_chapter_gate`
  - `autonomy_level=chapter_gate_autorun`
  - 运行画像里会显式回传 `runtime_baseline_id`
- 已补 Session 08 定向测试：
  - `runtime_baseline_execution_mode_service_test.dart`
  - `long_task_chapter_gate_policy_service_test.dart`
  - `long_task_chapter_gate_review_task_factory_service_test.dart`
  - `long_task_task_factory_runtime_baseline_test.dart`
  - 同时更新了 mode guidance / completion policy / execution plan 相关测试

当前仍明确未做：

- adapter 侧“review 报告判定后自动创建 repair task 并阻塞下一章”的自动物化还没正式接上
- scheduler / workflow runtime 还没有把 `reviewOutcomeDecision(...)` 接成真正的章级放行器
- UI 仍未消费新的 baseline 解释信息，本轮也未触碰 UI

## 本轮 Session 09 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 09 把“长任务项目 -> 运行基准选择”正式闭环回项目创建链
- core 已新增并落地：
  - `ProjectRuntimeProfile`
  - `ProjectRuntimeProfileDocumentService`
- 当前项目创建链已明确形成两层结果：
  - `manifest` 保存项目级静态元数据
  - `runtime_profile` 保存项目级初始运行配置快照
- `CreateProjectWorkspaceUseCase` 现在在长任务项目创建成功后会同时写入：
  - `.novel_agent/project_manifest.json`
  - `.novel_agent/settings/runtime_profile.json`
- 当前落盘规则已经明确：
  - `runtime_baseline_id` 进入 `ProjectManifest`
  - 初始运行配置会显式保存：
    - `runtime_baseline_id`
    - `runtime_mode`
    - `auto_start_on_create=false`
    - `unattended`
    - `auto_advance_chapters`
    - `keep_alive_across_project_switch`
- `ProjectDescriptor / LocalProjectRepository / LoadProjectWorkspaceUseCase / DiscoverProjectsUseCase` 已全部补齐 `runtimeBaselineId`
- `UpdateProjectManifestUseCase` 已改为保留现有项目的 `runtimeBaselineId`，避免项目简介更新时把长任务基准写丢
- 当前 Session 09 的后续扩展点已经固定在：
  - `packages/novel_agent_core/lib/src/project/project_runtime_profile.dart`
  - `packages/novel_agent_core/lib/src/project/project_runtime_profile_document_service.dart`
  - `packages/novel_agent_core/lib/src/use_cases/create_project_workspace_use_case.dart`
  - `packages/novel_agent_adapters/lib/src/storage/local_project_repository.dart`

本轮已验证：

- `dart analyze` in `packages/novel_agent_core`
- `dart analyze` in `packages/novel_agent_adapters`
- `dart test test/create_project_workspace_use_case_test.dart test/project_manifest_storage_strategy_test.dart` in `packages/novel_agent_core`
- `dart test test/local_project_repository_test.dart` in `packages/novel_agent_adapters`

## 本轮 Session 10 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 10 收束共享角色卡 / 组织卡 / 风格绑定 / 项目级智能体覆写合同
- core 已新增并明确：
  - `AgentProfile` 强类型合同
  - `AgentProfileMapperService`
  - `ProjectAgentBinding`
  - `ProjectAgentBindingNormalizerService`
  - `ProjectAgentBindingResolverService`
  - `ProjectAgentModelOverride`
  - `ProjectAgentModelOverrideNormalizerService`
  - `ProjectStyleBinding`
  - `ProjectStyleBindingNormalizerService`
  - `ProjectStyleBindingResolverService`
  - `CharacterProfile`
  - `CharacterProfileNormalizerService`
  - `CharacterProfileIdentityService`
  - `OrganizationProfile`
  - `OrganizationProfileNormalizerService`
- 当前已经明确分层：
  - `AgentProfile` 只描述智能体身份与能力定义
  - `ProjectAgentBinding` 只描述项目内启用/默认/阶段作用域与可选模型覆写
  - `ProjectAgentModelOverride` 只描述项目内这个智能体默认使用的模型与参数
  - `ProjectStyleBinding` 只描述项目如何采用某个风格，而不污染风格资产本体
  - `CharacterProfile.id` 与 `displayName` 已彻底分开，角色改名不再等于换身份
- 共享运行链当前已开始消费新合同：
  - `AgentProfileCatalogService` 已新增强类型输出入口
  - `ModelExecutionProfileService.resolve(...)` 已支持：
    - `projectAgentBinding`
    - `projectAgentModelOverride`
  - 项目级模型覆写会先于智能体自身覆盖层生效
- 同时补平了两个老口子：
  - `AgentPackageMetadataProfileService` 现在会正确拆分逗号字符串形式的 `skills / stages / skill_groups`
  - `AgentProfileNormalizerService` 现在会统一对智能体采样参数做裁剪，不再让扩展字段绕过规范化

当前 Session 10 的后续扩展点已经固定在：

- `packages/novel_agent_core/lib/src/agents/project_agent_binding*.dart`
- `packages/novel_agent_core/lib/src/agents/project_agent_model_override*.dart`
- `packages/novel_agent_core/lib/src/assets/project_style_binding*.dart`
- `packages/novel_agent_core/lib/src/assets/character_profile*.dart`
- `packages/novel_agent_core/lib/src/assets/organization_profile*.dart`
- `packages/novel_agent_core/lib/src/settings/model_execution_profile_service.dart`

本轮已验证：

- `dart analyze` in `packages/novel_agent_core`
- `dart test test/agent_services_test.dart test/model_execution_profile_service_test.dart test/project_agent_binding_services_test.dart test/project_style_binding_resolver_service_test.dart test/character_profile_identity_service_test.dart` in `packages/novel_agent_core`

## 本轮 Session 11 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 11 收束伏笔 / 时间线 / 关系三类共享写作资产
- core 已新增并明确：
  - `TimelineRecord`
  - `TimelineRecordNormalizerService`
  - `TimelineRecordMarkdownParserService`
  - `TimelineRecordMarkdownCodecService`
  - `RelationshipRecord`
  - `RelationshipRecordNormalizerService`
  - `RelationshipRecordMarkdownParserService`
  - `RelationshipRecordMarkdownCodecService`
  - `SharedNarrativeAssetReference`
  - `SharedNarrativeAssetReferenceIndex`
  - `SharedNarrativeAssetReferenceIndexService`
- 当前已经明确：
  - `ForeshadowRecord` 不再只是轻量备注对象，而是正式带有：
    - `relatedTimelineIds`
    - `relatedRelationshipIds`
    - `sourcePath`
  - 三类资产都已统一成：
    - 稳定 `id`
    - 独立摘要
    - 与实体 ID 解耦的引用字段
    - 可读 Markdown 往返合同
  - 最小共享关联规则已经落成统一索引，而不是散在长任务或 UI 内部：
    - 正向引用会被识别
    - 单边引用会自动补成反向邻接
    - 缺失引用会保留为 `missingReferenceKeys`
    - 关系资产会统一暴露 `left/right entity` 与补充实体引用
- 这意味着一般小说项目与长任务项目现在都可以通过同一入口读取三类资产的共享引用视图，而不需要先绑定图谱页面或长任务 mode

当前 Session 11 的后续扩展点已经固定在：

- `packages/novel_agent_core/lib/src/assets/timeline_record*.dart`
- `packages/novel_agent_core/lib/src/assets/relationship_record*.dart`
- `packages/novel_agent_core/lib/src/assets/shared_narrative_asset_reference*.dart`
- `packages/novel_agent_core/lib/src/assets/foreshadow_record*.dart`

当前仍明确未做：

- 时间线 / 关系资产的项目级导入导出闭环
- 资产中心 GUI 对时间线 / 关系的编辑入口
- SQLite 侧对三类资产的拆表投影
- 基于共享引用索引的连续性检查、伏笔回收分析、图谱视图

本轮已验证：

- `dart analyze` in `packages/novel_agent_core`
- `dart test test/asset_markdown_parser_service_test.dart test/shared_narrative_asset_reference_index_service_test.dart` in `packages/novel_agent_core`
- `dart test test/customization_use_cases_test.dart` in `packages/novel_agent_core`

## 本轮 Session 12 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 12 把“章节分析结果 -> 建议对象 -> 重写计划 -> 建议转任务”闭环落到 core
- core 已新增并明确：
  - `ChapterAnalysisIssue`
  - `ChapterAnalysisIssueNormalizerService`
  - `ChapterAnalysisSuggestion`
  - `ChapterAnalysisSuggestionNormalizerService`
  - `ChapterAnalysisTargetSegment`
  - `ChapterAnalysisResult`
  - `ChapterAnalysisResultNormalizerService`
  - `ChapterRewriteActionKind`
  - `ChapterRewritePlan`
  - `ChapterRewritePlanBuilderService`
  - `ChapterRewriteTaskFactoryService`
- 当前已经明确：
  - 章节分析结果是正式领域对象，不再直接暴露 provider 原始响应字段
  - 建议对象已经能区分三种路径：
    - `rewrite_full`
    - `rewrite_partial`
    - `suggestions_only`
  - 局部重写现在有正式的 `target segment` 合同，不需要把“片段范围”塞成临时字符串
  - 建议转任务已经进入共享 revision 链：
    - 整章重写计划可直接转 `revision` 任务
    - 局部重写计划可直接转 `revision` 任务
    - 只建议型计划不会自动变成修订任务
    - 但用户选中的建议仍然可以单独转成 `revision` 任务
- 当前这层与既有 review / task 的边界已经明确：
  - `analysis result` 负责表达结构化判断与建议
  - `rewrite plan` 负责表达“准备怎么改”
  - `revision task` 仍然是实际进入任务中心和执行链的对象

当前 Session 12 的后续扩展点已经固定在：

- `packages/novel_agent_core/lib/src/review/chapter_analysis_*.dart`
- `packages/novel_agent_core/lib/src/review/chapter_rewrite_*.dart`

当前仍明确未做：

- 章节分析结果的 Markdown / JSON 文档编解码
- 章节分析结果与现有审稿报告之间的桥接投影
- GUI / CLI 的“分析结果页、建议勾选、一键转任务”入口
- provider 侧把真实模型响应映射成 `ChapterAnalysisResult` 的适配层

本轮已验证：

- `dart analyze` in `packages/novel_agent_core`
- `dart test test/chapter_analysis_services_test.dart test/review_report_services_test.dart test/customization_use_cases_test.dart` in `packages/novel_agent_core`

## 本轮 Session 13 收口

- 已按 `docs/major-redesign-session-order.md` 的 Session 13 把项目级导入导出与资产 bundle 体系先立成 core 合同
- core 已新增 bundle 基座：
  - `BundleKind`
  - `BundleHeader`
  - `BundleHeaderBuilderService`
  - `BundleHeaderNormalizerService`
  - `BundleChecksumService`
  - `BundleValidationIssue`
  - `BundleValidationResult`
  - `BundleValidationService`
  - `BundleConflictItem`
  - `BundleImportPreview`
  - `BundleImportPreviewBuilderService`
  - `BundleConflictPreviewService`
- 当前已经明确：
  - 所有新 bundle 都走统一版本头：
    - `kind`
    - `schema_version`
    - `bundle_version`
    - `title`
    - `description`
    - `created_at`
    - `checksum`
  - checksum 现在已进入 core 合同，且不依赖最终 zip 方案
  - 冲突预检也已统一成共享模型，不再让不同 bundle 各自长一套统计口径
- 已新增四类正式 bundle 文档合同：
  - `CharacterCardBundleDocumentService`
  - `StyleBundleDocumentService`
  - `PromptTemplateBundleDocumentService`
  - `ProjectPackageDocumentService`
- 已新增对应的冲突预检服务：
  - `CharacterCardBundleImportPreviewService`
  - `StyleBundleImportPreviewService`
  - `PromptTemplateBundleImportPreviewService`
  - `ProjectPackageImportPreviewService`
- 当前项目包合同已经明确可表达：
  - `project manifest`
  - `runtime profile`
  - 角色 / 组织 / 风格 / 伏笔 / 关系 / 时间线
  - prompt templates
  但这轮仍只停在 core 合同和预检，不进入 zip/目录打包实现

当前 Session 13 的后续扩展点已经固定在：

- `packages/novel_agent_core/lib/src/bundles/*.dart`
- `packages/novel_agent_core/lib/src/assets/project_asset_bundle_document_service.dart`
- `packages/novel_agent_core/lib/src/customization/customization_bundle_document_service.dart`

当前仍明确未做：

- bundle 到 zip / 目录导出的 adapter 实现
- 项目包真实导入写盘用例
- 角色卡包 / 风格包 / 模板包的真实导入写盘用例
- bundle 级别的跨存储策略迁移实现
- GUI / CLI 的正式导入导出入口编排

本轮已验证：

- `dart analyze` in `packages/novel_agent_core`
- `dart test test/bundle_contract_services_test.dart test/customization_use_cases_test.dart` in `packages/novel_agent_core`

## 本轮文档骨架更新

- 新增 `docs/absorption/` 吸收层目录骨架
- 将参考项目吸收工作拆成：
  - `00-governance` 治理层
  - `10-projects` 单项目档案层
  - `20-synthesis` 跨项目归并层
- 为后续逐个总结 `references/` 中参考项目预留统一入口
- 明确吸收层只吸收理念、能力与架构启发，不转译 GPL 等受限项目实现
- 已完成第一份单项目吸收档案：`references/Ai-Novel-main`
- 已完成第二份单项目吸收档案：`references/AIxiezuo-main`
- 已完成第三份单项目吸收档案：`references/Writingway-main`
- 已完成第四份单项目吸收档案：`references/novel-writer-main`
- 已完成第五份单项目吸收档案：`references/book-os-main`
- 已完成第六份单项目吸收档案：`references/DeepSeek-TUI-main`
- 已新增重构级总设计文档：`docs/major-redesign-master-plan.md`
- 已新增会话级重构顺序文档：`docs/major-redesign-session-order.md`

## 当前结论

当前项目已经不只是空壳：

- 工作台可以加载项目、浏览资源、打开文档、编辑文档、保存文档
- 会话栏顶部模型 / 智能体选择已经接成真实选择器，不再只是伪下拉展示
- 文档工具栏的“渲染”已经改成当前 Markdown 文档级切换，不再把中宽布局误切进常驻文档工作区
- 资源树目录默认折叠，目录标题追加直接下级计数，占位 `README.md` 对用户隐藏
- 生态页可以浏览项目级与内置生态条目
- 生态页可以创建项目级智能体、技能、技能组、智能体组，并真实落盘
- 生态页可以打开项目内源文件进入工作区编辑
- 生态页可以预检并导入 `.customization.json` 生态包
- 生态页可以生成生态根索引和本地市场索引
- 项目级智能体 / 智能体组已经进入共享生成链和子智能体链
- CLI 与 GUI 已共用生态包预检、导入、索引生成和生态包导出核心链

但项目还没有达到“与旧项目别无二致”的状态，当前新的主线缺口已经转向：

- 第一种长任务模式的真正分阶段引导
- `Markdown + SQLite` 双兼容存储层
- 长任务模式状态与共享资产的结构化落盘
- Prompt Debug 组合页
- 生态导出 UI 入口
- 更完整的最终打包回归

## 这一轮最新收口

### 0. 执行阶段长期约束终于真正进入模型调用

- core 新增 `ModeGuidanceAssetContextSectionService`
- adapters 新增 `ProjectModeGuidanceMemorySectionService`
- `GenerateDraftUseCase.execute(...)` 现在支持显式注入：
  - `memorySections`
  - `projectFileSectionPlan`
  - `projectFileContents`
- `ProjectWorkflowRuntimeService` 现在不只是：
  - 在 `prepareWorkflowTaskExecution(...)` 里生成一个好看的执行包

也会在真正的 `runWorkflowTaskOnce(...)` 模型调用时，把：

- 模式引导衍生出的风格 / 世界 / 角色锚点
- 显式任务来源文件计划
- 计划文件正文内容

一起送入共享上下文组装链。

另外顺手补强了：

- `set_agent_tasks` 工具的任务字段表达
- `ProjectTaskToolExecutor` 对 `mode / task_type / source_paths / output_paths / metadata / persistent_context_paths` 的真实保留

这样模型在规划阶段临时扩出来的新任务，不会因为落盘时丢字段而失去长任务上下文。

### 0.1 检查点复盘包进入长任务主链

- core 新增：
  - `LongTaskCheckpointReviewService`
  - `LongTaskCheckpointReviewMarkdownRenderer`
- adapters 新增：
  - `ProjectLongTaskCheckpointReviewService`

当前 `runWorkflowTaskOnce(...)` 在正文 / 规划单步结束后，会自动生成：

- `tracking/checkpoint_reviews/*.json`
- `tracking/checkpoint_reviews/*.md`

复盘包里不只是路径，还明确给出：

- 当前最该确认什么
- 漂移警戒项
- 下一步建议
- 本轮工具与产物

这层是第一种长任务模式后续继续做：

- 风格漂移检查
- 自动修订建议
- 检查点确认 UI / CLI

的共享基座。

### 0.2 长任务运行记录已能挂到复盘引用

- `LongTaskRunStepRecorderService` 现在会把：
  - `checkpoint_review_path`
  - `checkpoint_review_summary`

写进长任务运行步骤。

这意味着后面的：

- 任务中心运行回放
- CLI 长任务运行查看
- 检查点确认入口

都可以从运行记录直接追到对应复盘包，而不必重新扫任务目录猜测。

### 0.3 检查点复盘现在可以物化审稿任务

- core 新增：
  - `LongTaskCheckpointReviewTaskSuggestionService`
- adapters 新增：
  - `ProjectLongTaskCheckpointReviewTaskService`
- `ProjectWorkflowRuntimeService` 新增：
  - `createCheckpointReviewTasks(...)`

当前共享链路已经不只是“生成一个复盘包供人看”。

对于第一种长任务模式，真实执行后的 checkpoint review 现在可以继续物化成：

- 连续性检查任务
- 剧情检查任务
- 样章 / 风格相关的文风审稿任务

这一层目前仍保持“手动触发”，没有直接硬塞回自动调度；这样 GUI、CLI 和后续模式策略可以共用同一个入口，但各自决定何时插入。

另外这一轮顺手补了一个必要闭环：

- `ReviewTaskFactoryService.reviewTaskFromSource(...)` 现在会保留外部传入 `metadata`

所以由 checkpoint review 派生出来的审稿任务，已经能稳定追溯：

- 来源 task
- 对应 checkpoint review
- 建议来源路径
- 建议的 review type

### 0.4 审稿报告现在可以继续物化返工任务

- adapters 新增：
  - `ProjectLongTaskReviewRepairTaskService`
- `ProjectWorkflowRuntimeService` 新增：
  - `createWorkflowReviewRepairTask(...)`

现在共享运行链已经从：

- `chapter / planning -> checkpoint review`
- `checkpoint review -> review task`

继续推进到：

- `review task -> review report -> revision task`

这一层同样保持手动入口，不会偷偷回灌自动调度；GUI、CLI 和后续策略层都可以复用同一入口决定何时创建返工任务。

另外这轮顺手修了一个真实路径坑：

- `reviews/*.json -> reviews/*.md` 的兄弟路径换算之前少了一个点

现在 `json-first` 的报告输出顺序也能稳定回到正确的 Markdown 报告路径。

### 0.5 revision 后处理现在会回写执行记录与检查点

- core 新增 / 补强：
  - `ReviewPathPolicyService.reviewMarkdownPath(...)`
- adapters 新增：
  - `ProjectLongTaskPostprocessResultService`

当前 `runWorkflowTaskPostprocessOnce(...)` 不再只是把模型后处理结果返回给调用方。

对于 revision 任务，这一步现在会真实做三件事：

- 更新 chapter atomic execution 记录中的 `postprocess_output_paths / events / steps`
- 提取后处理阶段写出的 `reviews/*.md + *.json`
- 生成独立的 postprocess checkpoint review，并把路径回写到任务文件

因此返工链已经不再停在：

- `revision main step 已修改正文`

而是能继续留下：

- `postprocess_review_report_path`
- `postprocess_review_report_json_path`
- `postprocess_checkpoint_review_path`
- `postprocess_checkpoint_review_summary`

这意味着 GUI / CLI 之后做“修复后复核、确认通过、继续返工、回滚”时，终于有了稳定的共享状态抓手。

### 0.6 review / repair 任务现在会继承 mode 1 长期约束

- checkpoint review 派生出的 review 任务，现在会继承：
  - 运行时 `workflow_mode`
  - `persistent_context_paths`
- review report 派生出的 revision 任务，现在也会继续继承：
  - mode
  - `persistent_context_paths`
  - 来源 review task 追溯信息

这轮修复的是一个很关键但容易隐身的问题：

- 如果 review / repair 任务回退成 `single_chapter_atomic`
- mode 1 的风格 / 世界 / 角色锚点就会在返工时慢慢失忆

现在这条断点已经补上。

这意味着第一种长任务模式的“长期约束”不再只存在于：

- `guidance.md`
- SQLite
- execution record

而是会实际影响后续工作流执行。

### 0.7 revision 收口动作层已抽成共享合同

- core 新增：
  - `LongTaskRevisionResolutionService`
- adapters 新增：
  - `ProjectLongTaskRevisionResolutionService`
- `ProjectWorkflowRuntimeService` 新增：
  - `buildRevisionResolution(...)`
  - `applyRevisionResolutionAction(...)`

现在 revision 在完成后处理以后，不再只有：

- `acceptRevisionTask(...)`
- `rollbackRevisionTask(...)`

这两个散落入口。

共享 runtime 已经能基于 revision 任务当前状态、diff、postprocess 报告和检查点复盘，统一生成一份“修订收口动作合同”，里面会明确给出：

- 接受修复
- 继续返工
- 回滚修复
- 回到检查点
- 根据当前 checkpoint review 继续物化后续审稿任务

这层是纯规则层，不碰项目存储；真正的落盘动作才由 adapter 层执行。

因此后面无论是：

- Flutter 任务中心
- CLI workflow 命令
- mode 1 专属检查点界面

都可以直接吃同一份动作合同，而不需要各自重新判断“现在能不能继续返工 / 能不能回到检查点 / 能不能继续生成 follow-up review task”。

### 0.8 review -> repair 现在会继承来源 checkpoint

这轮顺手补了一处关键链路缺口：

- `ProjectLongTaskReviewRepairTaskService`

现在在把 review report 物化成 revision 任务时，会继续继承：

- `origin_checkpoint_review_path`
- `origin_checkpoint_review_id`

这样 revision 在 postprocess checkpoint 不存在时，仍然可以回退到来源长任务 checkpoint 做“回到检查点 / 继续物化后续审稿任务”的共享动作判断，而不用让 UI 或控制器自己猜。

### 0.9 checkpoint review 已带严重度与动作包

- core 新增：
  - `LongTaskCheckpointSeverityService`
  - `LongTaskCheckpointActionContractService`
- adapters 新增：
  - `ProjectLongTaskCheckpointActionService`
- `ProjectWorkflowRuntimeService` 新增：
  - `buildCheckpointReviewActionPackage(...)`
  - `applyCheckpointReviewAction(...)`

现在 checkpoint review 不再只是：

- `summary`
- `confirmation_focus`
- `drift_watch_items`
- `next_actions`

而是会进一步带出结构化的：

- `severity`
- `severity_label`
- `severity_reasons`
- `suggested_actions`
- `action_summary`
- `recommended_action_id`

其中“建议动作”目前已经真正物化了第一条稳定动作：

- `create_followup_review_tasks`

也就是可以直接基于 checkpoint review 再生成 review 任务，而不需要上层自己再推断一轮“这个检查点该不该继续做审稿”。

这一层同样保持了解耦：

- 严重度判断在 core
- 动作合同在 core
- 项目态加载与物化在 adapters
- runtime 只暴露薄入口

### 1.0 长任务运行回放现在会挂出 checkpoint 风险信息

- `LongTaskRunStepRecorderService`
- `LongTaskRunMarkdownRenderer`

现在长任务运行记录的每一步，在挂 `checkpoint_review_path` 之外，还会继续挂：

- `checkpoint_review_severity`
- `checkpoint_review_action_summary`

因此任务中心 / CLI 的运行回放不再只是知道“这里有个检查点文件”，而是能直接看到：

- 这个检查点风险级别多高
- 当前更建议继续主链、补审稿，还是先回看长期约束

这一层对第一种模式很重要，因为它让“托管式长篇”的人工确认点开始变成真正可回看的决策节点，而不是静态附件。

### 1.1 mode 1 的漂移判断已拆成专门信号层

- core 新增：
  - `LongTaskStyleDriftSignalService`
  - `LongTaskWorldDriftSignalService`
  - `LongTaskEntityDriftSignalService`
  - `LongTaskCheckpointDriftSignalService`

现在 checkpoint review 不再只靠：

- `drift_watch_items`

这种平铺提示。

它会先生成结构化的：

- `drift_signals`

每条信号都会明确给出：

- `domain`
  - `style`
  - `world`
  - `entity`
- `severity`
- `title`
- `note`

然后再由：

- `LongTaskCheckpointSeverityService`
- `LongTaskCheckpointReviewMarkdownRenderer`

继续消费这些信号，分别输出：

- 更稳的严重度判断
- 更可读的复盘 Markdown

这样 mode 1 后面继续做：

- 风格漂移专检
- 世界规则漂移专检
- 角色锚点漂移专检

时，就不需要再推翻当前 checkpoint 结构，只需要继续细化每个领域的信号来源和判断规则。

### 1.2 CLI 已接入 checkpoint / revision 共享动作合同

- `workflow checkpoint-actions`
- `workflow apply-checkpoint-action`
- `workflow revision-resolution`
- `workflow apply-revision-resolution`

现在 CLI 不再只有旧的：

- `accept-revision`
- `rollback-revision`

这两个硬入口。

它已经能直接读取共享 runtime 给出的：

- checkpoint action package
- revision resolution package

并应用其中已经稳定物化的动作。

当前 CLI 已经能真实跑通的动作包括：

- `create_followup_review_tasks`

这意味着：

- GUI
- CLI
- 后续专门检查点页

终于开始真正共用同一套动作合同，而不是“core 只是出建议，CLI / GUI 各自再写一套解释逻辑”。

### 1.3 Flutter 任务中心已接入共享动作合同

- app 新增：
  - `TaskCenterContractActionViewDataService`
- UI 新增：
  - `TaskCenterSharedActionsPanel`

现在 Flutter 任务中心在选中任务后，会额外读取并展示：

- checkpoint action package
- revision resolution package

其中：

- revision 收口动作已经可以直接在 GUI 里执行
- checkpoint 动作里已接通宿主的动作会直接开放按钮
- 尚未接通宿主的动作会保留建议，但明确显示为不可执行

另外旧的：

- `接受修复`
- `回滚修复`

也已经改成转走共享 revision resolution 入口，不再是 GUI 自己单独打一条旧分支。

### 1.4 drift signal 已开始反哺 follow-up review 建议顺序

- `LongTaskCheckpointReviewTaskSuggestionService`

现在不再只是“根据路径猜 review type”。

它会继续结合：

- `style / world / entity` 漂移信号
- 旧的 `drift_watch_items`
- 当前 task type / stage / source path

共同决定：

- 是否额外补 continuity / style 审稿
- follow-up review 建议的 `priority_score`
- 建议顺序 `priority_rank`
- 每条建议的 `priority_reason`
- 重点关注域 `drift_focus`

这意味着 mode 1 的 checkpoint review 已经不只是给出风险展示，还开始真实影响后续“先审什么”。

### 1.5 checkpoint 已能真正放行主链与确认显式检查点

- `ProjectLongTaskCheckpointActionService`
- `LongTaskCheckpointActionContractService`

现在 checkpoint 合同里不再只有：

- `create_followup_review_tasks`

这一条真正可执行。

又新增物化了两条共享动作：

- `continue_long_task`
- `confirm_checkpoint_continue`

也就是：

- 对于低风险 chapter / planning checkpoint，用户已经可以直接“继续主链”
- 对于显式 `checkpoint` 任务，用户已经可以直接“确认检查点”

而且这两条动作不是 GUI 私货，已经走进共享 runtime，所以：

- Flutter
- CLI

都会一起受益。

### 1.6 高风险 checkpoint 已能生成“长期约束回看包”

- core 新增：
  - `LongTaskCheckpointGuidanceRevisitService`
- adapters 新增：
  - `ProjectModeGuidanceRevisitService`

现在高风险 checkpoint 的：

- `revisit_mode_guidance`

不再只是一个空建议。

它已经可以真实返回一份共享回看包，里面会按 drift signal 聚焦：

- 风格锚点
- 世界规则
- 角色身份
- 模式摘要

并补出：

- 对应 Markdown 路径
- 高亮摘要
- 内容预览

这意味着 mode 1 在高风险节点已经开始有“先回看什么”的结构化抓手，而不是只剩一句提示文案。

### 1. 第一种长任务模式进入“共享资产层”

- 新增 `ModeGuidanceAssetBundle`
- 新增 `ModeGuidanceAssetBundleBuilderService`
- 现在模式引导结果不再只有：
  - `guidance.md`
  - 投影 Markdown

还会同步压缩成共享资产对象：

- `StyleProfile`
- `WorldRuleSet`
- `EntityIdentity`

这意味着：

- 第一种模式的风格、世界锚点、主角身份不再只是散文摘要
- 第二种模式也能直接复用同一套资产投影骨架
- 后续上下文注入、图谱、结构化浏览和策略复用终于有了稳定抓手

### 2. SQLite 双存储进入第二批

- 新增 `ProjectModeGuidanceAssetSqliteStore`
- 当前已把模式引导衍生资产拆表写入：
  - `style_profile`
  - `style_rule`
  - `world_rule_set`
  - `world_rule_entry`
  - `entity_identity`
  - `entity_alias`

这轮继续遵守：

- Markdown 负责用户可读内容
- SQLite 负责结构化索引
- 不把大 JSON blob 再塞回数据库

### 3. 任务工具链闭环补齐一处真缺口

真实探针暴露出：

- `set_agent_tasks` 只回传计划
- `mark_task_status` 却要求真实任务文件

现在已经修正为：

- `set_agent_tasks` 会把计划任务真实落成 `tasks/*.task.json`
- `mark_task_status` 与 GUI / CLI / 探针共享同一批任务实体

这块是实打实的链路补洞，不是测试放水。

### 4. 两种长任务模式真实探针再次通过

这轮新增或更新：

- `apps/novel_agent_app/tool/probe_support.dart`
- `apps/novel_agent_app/tool/seed_autopilot_mode_probe.dart`
- `apps/novel_agent_app/tool/full_outline_mode_probe.dart`

当前串行实测结果：

1. `seed_autopilot_novel`
   - `gap_probe` 通过
   - `plan_probe` 通过
2. `full_outline_consensus`
   - `gap_probe` 通过
   - `plan_probe` 通过

说明当前不是只有“模式开局能问问题”，而是：

- 第一种模式能补问，也能建可恢复队列
- 第二种模式也已经在同一套复用骨架上跑通

### 5. 新增验证

- `packages/novel_agent_core/test/mode_guidance_asset_bundle_builder_service_test.dart`
- `packages/novel_agent_core/test/mode_guidance_asset_context_section_service_test.dart`
- `packages/novel_agent_adapters/test/project_task_tool_executor_test.dart`
- `packages/novel_agent_adapters/test/project_mode_guidance_repository_test.dart` 已扩展验证资产投影
- `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart` 已扩展验证模式资产片段会进入执行包上下文
- `packages/novel_agent_adapters/test/project_long_task_checkpoint_review_service_test.dart`
- `apps/novel_agent_cli/tool/mode_guidance_cli_probe.dart`
- `apps/novel_agent_app/tool/seed_autopilot_execution_probe.dart`
- `apps/novel_agent_app/tool/seed_autopilot_queue_probe.dart`
- `apps/novel_agent_app/tool/seed_autopilot_review_task_probe.dart`
- `apps/novel_agent_app/tool/seed_autopilot_review_repair_probe.dart`
- `apps/novel_agent_app/tool/seed_autopilot_revision_postprocess_probe.dart`
- `apps/novel_agent_app/tool/seed_autopilot_revision_resolution_probe.dart`
- `apps/novel_agent_app/tool/seed_autopilot_checkpoint_action_probe.dart`
- `apps/novel_agent_app/tool/seed_autopilot_drift_signal_probe.dart`
- `apps/novel_agent_app/test/task_center_contract_action_view_data_service_test.dart`
- `packages/novel_agent_core/test/long_task_checkpoint_guidance_revisit_service_test.dart`
- `packages/novel_agent_adapters/test/project_mode_guidance_revisit_service_test.dart`
- `apps/novel_agent_app/tool/seed_autopilot_checkpoint_continue_probe.dart`
- `apps/novel_agent_app/tool/seed_autopilot_checkpoint_revisit_probe.dart`

本轮已通过：

- `dart analyze packages/novel_agent_core packages/novel_agent_adapters apps/novel_agent_app`
- 以上定向测试
- 两种模式真实 API 探针
- `seed_autopilot_execution_probe` 真实 API 探针，已确认：
  - planning task 会带入长期约束资产片段
  - chapter task 会同时带入长期约束 + 任务指定来源
  - `runWorkflowTaskOnce(...)` 会真实写出规划结果
- `seed_autopilot_execution_probe` 再次通过，已确认：
  - `runWorkflowTaskOnce(...)` 会真实生成 `tracking/checkpoint_reviews/*`
  - 复盘 Markdown 中已出现“漂移警戒 / 下一步建议”
- `seed_autopilot_queue_probe` 真实 API 探针，已确认：
  - `runWorkflowTaskQueue(...)` 的长任务运行记录步骤会挂上 `checkpoint_review_path`
- `seed_autopilot_review_task_probe` 真实 API 探针，已确认：
  - chapter 执行后的 checkpoint review 可以真实物化成 review 任务
  - 生成的 review 任务已经带有 `checkpoint_review_suggestion` 追溯元数据
- `seed_autopilot_review_repair_probe` 真实 API 探针，已确认：
  - review 任务会真实写出 `reviews/*.md + *.json`
  - 报告可以继续物化成 revision 任务
- `seed_autopilot_revision_postprocess_probe` 真实 API 探针，已确认：
  - revision 后处理会真实写出 postprocess review report
  - execution record 会挂上 `postprocess_output_paths`
  - task 会回写 `postprocess_checkpoint_review_path`
- `seed_autopilot_revision_resolution_probe` 真实 API 探针，已确认：
  - revision 后处理后的收口动作合同可以真实生成
  - repair 任务会保留来源 checkpoint 元数据
  - `create_followup_review_tasks` 可以基于 postprocess checkpoint review 真实再物化一批审稿任务
- `seed_autopilot_checkpoint_action_probe` 真实 API 探针，已确认：
  - chapter 执行后的 checkpoint review 会真实带出严重度与动作包
  - `create_followup_review_tasks` 可以从 chapter checkpoint review 继续真实物化审稿任务
- `seed_autopilot_drift_signal_probe` 真实 API 探针，已确认：
  - chapter 执行后的 checkpoint review 会真实带出 `style / world / entity` 三类漂移信号
  - 严重度与动作包继续兼容这层新结构
- `seed_autopilot_review_task_probe` 再次通过，已确认：
  - drift signal 不会打坏 checkpoint review -> review task 物化链
  - follow-up review 建议会按新的优先级顺序落盘
- `seed_autopilot_checkpoint_continue_probe` 真实 API 探针，已确认：
  - 真实 chapter checkpoint review 可以继续主链
  - 显式 checkpoint 任务可以共享确认并继续调度
- `seed_autopilot_checkpoint_revisit_probe` 真实 API 探针，已确认：
  - 高风险 checkpoint 可以真实生成长期约束回看包
  - 回看包会带路径与内容预览，不只是空动作名
- `seed_autopilot_queue_probe` 再次通过，已确认：
  - 长任务运行回放继续稳定
  - 步骤记录会保留 checkpoint 路径，并且新的风险字段没有打坏原队列链
- `workflow_resolution_cli_probe` 真实 API + CLI 探针，已确认：
  - CLI 可以读取 checkpoint action package
  - CLI 可以应用 `create_followup_review_tasks`
  - CLI 可以读取 revision resolution package
  - CLI 可以继续应用 revision 的 follow-up review 动作
- CLI `guidance-status / create-from-guidance` 探针，已确认能生成真实任务队列

## 本轮正在推进

### 1. 双存储设计补齐

- 新增 `docs/storage-dual-compatibility-design.md`
- 正式明确：
  - 用户主内容以 Markdown 为主
  - SQLite 只做结构化索引 / 恢复 / 关系查询
  - `.novel_agent/` 作为隐藏内部层
  - 资源树默认隐藏内部状态与数据库文件

### 2. 第一种长任务模式开始进入真正实施

当前正在落地：

- 策略层基础对象
- 模式引导状态机
- 模式摘要 Markdown
- 隐藏 JSON 状态
- SQLite 索引表
- 真实 API 探针
- 共享资产对象化
- 任务工具链闭环

这一轮的目标不是再写“预设计”，而是把第一种模式真正推到可运行骨架。

## 本轮新增完成

### 1. 提供商兼容边界补齐

- 新增 `docs/provider-compatibility-baseline.md`
- 在 `agent.md` 中新增：
  - GPL 参考边界
  - 多协议兼容边界
- 正式明确：
  - 调度层可共用
  - OpenAI Chat / Responses、Anthropic、Gemini native / OpenAI compatibility 只在协议层分流
  - Responses API 不得继续伪装成 Chat Completions

### 2. 第一种长任务模式 core 骨架落地

- 新增 `strategy/`
- 新增 `assets/`
- 新增 `entity/`
- 新增 `modes/`
- 新增：
  - `ModeGuidanceState`
  - `ModeGuidanceQuestion`
  - `ModeGuidanceTransitionService`
  - `ModeGuidanceSummaryMarkdownRenderer`
  - `ModeGuidanceProjectionDocumentService`
  - `LoadModeGuidanceStateUseCase`
  - `AnswerModeGuidanceStageUseCase`

### 3. 双存储落地第一批实现

- 新增 `ProjectModeGuidanceRepository`
- 新增 `ProjectModeGuidanceSqliteStore`
- 新增 `ProjectSqlitePathService`

当前第一种模式会同时落：

- `tracking/modes/<mode_id>/guidance.md`
- `.novel_agent/modes/<mode_id>/guidance_state.json`
- `.novel_agent/sqlite/novel_agent.db`

并自动投影到用户可见 Markdown：

- `inspiration/seed_autopilot_seed.md`
- `specs/seed_autopilot_constraints.md`
- `world/seed_autopilot_world_anchor.md`
- `characters/seed_autopilot_protagonist.md`
- `styles/seed_autopilot_style.md`

### 4. 第一种长任务模式 UI / 应用层接线一轮

- 长任务模式列表中，`灵感托管式长篇` 不再直接跳生成
- 现在先进入模式引导态
- 当前阶段支持：
  - 选项式作答
  - 自由输入作答
  - 完成后再进入 `long_task.create_queue`

### 5. 真实 API 探针通过

新增：

- `apps/novel_agent_app/tool/seed_autopilot_mode_probe.dart`
- `apps/novel_agent_app/tool/full_outline_mode_probe.dart`
- `apps/novel_agent_app/tool/probe_support.dart`

当前已通过两条真实链路：

1. `gap_probe`
   - 信息不足时，模型会先读模式投影资产或摘要，再进入 `present_user_options`
2. `plan_probe`
   - 信息足够时，模型会先读模式摘要或投影资产，再完成真实规划动作

并且这条结论现在适用于：

- 第一种模式 `seed_autopilot_novel`
- 第二种模式 `full_outline_consensus`

## 本轮前已完成

### 架构与基础

- 建立 `agent.md`
- 建立 core / adapters / app / ui 分层
- 建立桌面与移动端默认根目录策略

### 核心逻辑迁移

- 上下文预算与组装
- 会话记录与历史
- 生成记录
- revision diff
- task queue / task runtime
- workflow runtime、chapter atomic、long task 的一批核心纯逻辑
- 调度层：run center contract、scheduler tick plan、unattended strategy、next batch plan 等

### 生态与包结构

- `AGENT.md / SKILL.md` 解析与构建基础
- 项目级与内置技能加载
- `load_agent_skill` 真正接入项目技能作用域
- 项目级 `skill_groups / agent_groups` 目录扫描与加载

### GUI 侧已打通

- 项目创建、项目加载
- 资源树显示与中文映射
- 文档工作区编辑与保存
- 生态页浏览、创建、打开源文件

## 本轮新增完成

### 1. 维护恢复文档

- 新建本文件 `docs/migration-progress.md`
- 新建顺序文档 `docs/migration-order.md`

### 2. 文档编辑闭环

- 工作区正文从只读改成可编辑
- 增加 `activeDocumentDirty`
- 保存、打开、生成后正确清理脏状态

### 3. 生态页真实落盘

- 创建智能体、技能、技能组、智能体组时生成脚手架内容
- 用统一文本写入用例写到项目目录
- 刷新生态快照并自动选中新条目
- 自动打开源文件进入工作区

### 4. 项目级生态分组加载

- `skill_groups`
- `agent_groups`

### 5. 项目级协作智能体进入共享运行链

- `GenerateDraftUseCase`
- `SubAgentExecutionService`

现在都能合并项目级智能体与智能体组，而不是只依赖内置协作素材。

### 6. 生态包共享链补齐

- 新增共享预检用例 `PreviewCustomizationBundleImportUseCase`
- 新增共享导入用例 `ImportCustomizationBundleUseCase`
- 新增共享导出用例 `SaveCustomizationBundleUseCase`
- 新增共享本地市场索引用例 `SaveCustomizationMarketIndexUseCase`
- 新增共享根目录索引生成 `GenerateCustomizationIndexesUseCase`
- 修正 `SKILL.md / AGENT.md` 渲染，保留 `id + name`，不再丢显示名

### 7. GUI / CLI 同源生态入口

- Flutter 生态页增加导入弹层
- Flutter 生态页支持预检摘要、导入状态和索引生成状态
- CLI 新增：
  - `project import-bundle`
  - `project generate-index`
  - `project save-bundle`

### 8. 项目创建进一步补齐

- 新建项目时自动生成四个生态根目录的 `index.json`

### 9. 任务 / 审稿 / 模板 GUI 真接线

- Flutter 新增并接通：
  - `taskCenter`
  - `reviewCenter`
  - `promptTemplates`
- 三页都不再只是目录浏览壳，而是接到共享服务：
  - `ProjectWorkflowRuntimeService`
  - `ProjectReviewReportService`
  - `ProjectPromptTemplateService`
- 新增 app 层小型视图映射服务，避免继续把文案与展示规则堆进 `AppShellController`
- 工作台入口与文档工具栏入口改为真实跳转 / 真实动作：
  - 任务按钮 -> 长任务中心
  - 审稿按钮 -> 审稿中心
  - 模板按钮 -> 模板页
  - 文档栏审稿 -> 为当前文档创建审稿任务并跳任务中心
  - 文档栏大纲 -> 自动尝试打开常见大纲文件

### 10. CLI workflow 共享运行入口扩展

- `workflow` 不再只有 `draft`
- 已新增：
  - `create`
  - `list`
  - `next`
  - `preflight`
  - `chain`
  - `plan`
  - `prepare`
  - `run-once`
  - `run-next`
  - `run-queue`
  - `postprocess-once`
  - `postprocess-next`
  - `complete-next`
  - `pause`
  - `resume`
  - `accept-revision`
  - `rollback-revision`

### 11. 审稿报告落盘链补齐

- `run_continuity_check` 现在不再只写 Markdown
- 现在会同时写：
  - `reviews/.../*.json`
  - `reviews/.../*.md`
- 这样 GUI 审稿列表、详情页、修复任务生成就能稳定复用同一份结构化报告

### 12. 生态页编辑闭环补齐

- 新增 `EcosystemEntryEditorService`
- 生态页项目级条目现在可以直接拉起表单编辑，而不是只能打开源文件手改
- 支持：
  - 项目级 `AGENT.md`
  - 项目级 `SKILL.md`
  - 项目级 `skill_group.json`
  - 项目级 `agent_group.json`
- 保存时会：
  - 重新渲染标准文件内容
  - 支持改 ID 后迁移到新路径
  - 删除旧路径
  - 刷新生态快照并回选新条目
- 删除时只删除项目级条目，不会动内置条目

### 13. 长任务链路树 / 回放 / 日志视图补齐一轮

- core 新增 `TaskChainViewService`
- `workflowChainView` 不再只是平铺节点，已恢复为按 `plan_id` 分组的链路视图
- `saveWorkflowChainSnapshot` 现在同时落：
  - `tracking/task_chain_views/*.json`
  - `tracking/task_chain_views/*.md`
- 任务中心新增：
  - 链路树页签
  - 最近长任务运行记录列表
  - 最近受控连续运行记录列表
  - 两类记录的 Markdown 回放 / 日志视图

### 14. CLI 命令组继续拆分

- 新增独立 `review` 命令组：
  - `list`
  - `show`
  - `types`
  - `create-task`
  - `repair-task`
- 新增独立 `template` 命令组：
  - `list`
  - `show`
  - `preview`
  - `save`
  - `delete`
  - `restore`
- 这样 `workflow` 不再继续挤进审稿 / 模板职责

### 15. 工具宿主能力补齐一轮

- `reorder_project_file` 不再返回未执行占位
- 新增内部排序元数据：
  - `.novel_agent/project_tree_order.json`
- 资源树 / CLI / 工作区列举现在都会应用同一份同级排序结果
- 内部排序元数据不会出现在普通项目资源树中
- `request_gateway_tool` 现在已经真正接通：
  - `fetch_url_content`
  - `search_internet`
  - `run_command`
- `generate_image` 不再返回旧式 `notExecuted` 占位，而是进入真实 gateway 分发分支，当前先保留为受参数约束的轻量实现
- 新增桌面端进程执行器 `DesktopProcessRunner`
- 新增适配器测试：
  - `project_tree_order_service_test.dart`
  - `project_gateway_tool_executor_test.dart`

### 16. 设置页与工作台交互修整一轮

- 接口设置：
  - 不再向用户暴露接口内部 `id`
  - 新建接口时由标题自动生成内部 `id`
  - 名称冲突时自动追加 `_1`、`_2`
  - 协议改为下拉选择，当前只开放：
    - OpenAI Compatible
    - Anthropic Compatible
  - 不再在接口页维护“默认接口 / 默认模型”
- 模型设置：
  - 改为单独维护接口选择、模型 ID、兼容上下文长度、应用上下文长度、流式模式、API 模式
  - 去掉默认智能体 ID 与自动保存草稿开关
- 主题设置：
  - 收缩为稳定可用的主题模式切换
  - 工作台主面板、按钮、资源树、编辑区等自绘组件已开始响应亮暗主题
- 权限页 / 工具策略页：
  - 模式切换现在会真实改写开关集合，不再只是改一行文案
- 工作台：
  - 二栏模式已支持拖拽调宽
  - 三栏改为更接近 VSCode 的连续分栏，不再显示成三张卡片夹分割线
  - 左栏操作区改为紧凑工具条，资源树成为主视图
- 资源树改为可展开目录结构
- 默认隐藏 `.json / .jsonl / .novel_agent`，避免用户误改内部结构
- 顶层目录按创作认知顺序重排，而不是纯字典序

### 17. 模型运行参数真实接线一轮

- 新增共享执行视图服务：
  - `ModelExecutionProfileService`
  - `ProviderRequestOptionsService`
- 设置文件中的模型默认参数现在已经真正进入 GUI / CLI / 长任务共用运行链：
  - `stream`
  - `temperature`
  - `top_p`
  - `top_k`
  - 深度思考开关与强度
  - 自定义高级参数条目
- 智能体层的模型重写也已接入执行链，不再只是 core 中孤立可用：
  - `thinking_enabled`
  - `thinking_effort`
  - `temperature`
  - `top_p`
  - `advanced_model_overrides`
- OpenAI 兼容网关已经开始真正透传这些请求参数，而不是只固定发送 `model + messages + tools`

### 18. Responses API 当前结论

- 已确认：`Responses API` 支持非流式请求
- 因此，“API 模式 = Responses API” 时，不应禁用“是否流式”开关
- 当前产品策略：
  - 默认仍是 `聊天 API`
  - 默认仍是“流式请求”
  - `Responses API` 相关设置先保留，但真实 HTTP 分流尚未完成
- 当前不要把 `Responses API` 误当成“只能流式”
- 当前也不要把 `Responses API` 假装成已经完全接通；它还处于“设置已保留、事实已确认、网关分流待补”的状态

### 19. 网络代理与共享生成入口补齐一轮

- 代理设置现在改为更贴近用户视角：
  - 代理模式只分为“系统网络环境 / 自定义代理”
  - 协议头允许留空，也可选：
    - `HTTP`
    - `SOCKS5`
  - 自定义代理拆成独立字段：
    - `代理 IP`
    - `代理端口`
    - `代理用户名（可选）`
    - `代理密码（可选）`
- 代理端口范围已收敛到共享策略：
  - 新增 `NetworkProxyPortPolicy`
  - GUI 输入与设置持久化统一复用同一套 `1-65535` 固定合法范围
- OpenAI 兼容网关现在会真正吃到设置页网络参数：
  - 自定义代理优先覆盖系统代理
  - 支持代理认证
  - 协议头留空时，仍按通用代理地址输入解释执行
- GUI / CLI / 长任务运行时三条链路都已补齐 `networkSettings` 传递：
  - 普通会话生成
  - CLI `workflow draft`
  - 长任务正文执行
  - 长任务后处理执行
- 去掉了几处过于内部化的用户可见文案：
  - `ToolCore: ...`
  - `上下文准备中 · 等待模型读取会话与项目信息`
  - 设置页中关于“临时代理”的旧迁移期说明

### 20. 真实选项工具链修复完成

- 使用真实模型链路探针复现并确认：
  - `present_user_options` 之前并不是单纯 UI 丢状态
  - 真正的问题在 OpenAI 兼容流式工具调用聚合
- 根因：
  - 首个 `tool_call` 分片带 `id + name`
  - 后续参数分片只带 `index + arguments`
  - 旧实现按 `id` 或 `index` 二选一建 key，导致同一工具被拆成两条半成品记录
  - 最终留下“有名字没参数”的那条，`present_user_options` 被执行成空参数，于是反复空转
- 已修复：
  - `OpenAiLlmGateway` 统一按稳定 builder key 合并同一条流式工具调用
  - 新增适配器测试，专门覆盖“首包有 id，后续只给 index”的真实兼容行为
- 已用真实链路再次验证：
  - 现在会正确执行 `read_project_file -> present_user_options`
  - `waitingForUserChoice = true`
  - `pendingOptionsFromState` 能稳定长出真实按钮
  - 不再连续重复调用 `present_user_options`

### 21. 全工具探针脚本建立并完成首轮通过

- 新增保留型探针脚本：
  - `apps/novel_agent_app/tool/all_tools_probe.dart`
- 脚本特性：
  - 自动复制默认项目到隔离副本
  - 自动补齐探针夹具
  - 逐项验证项目工具、网关工具与 `call_sub_agent`
  - 落本轮 JSON 报告，方便后续切换模型或继续回归
- 首轮通过结果：
  - `31 / 31` 全通过
- 本轮顺手修复一处真实工具 bug：
  - `run_continuity_check` 的 `json_path` 之前误生成为 `Probe_Reviewjson`
  - 现已修正为标准兄弟文件 `Probe_Review.json`

### 22. 工具暴露过滤层与当前语义补强完成一轮

- core 新增：
  - `ToolExposurePolicyService`
  - `ToolPlatformPolicy`
- 现在 GUI / CLI 共用生成入口与子智能体入口都会先过工具暴露过滤，再生成模型 schema
- 当前约束已经落实：
  - 传输层工具不会暴露给模型
  - `request_gateway_tool` 虽然仍保留给宿主探针 / 手工调试，但不会进入模型可见工具集合
  - 移动端未来如继续引入桌面专属工具，也能在同一层统一拦截
- `GenerateDraftUseCase` 与 `SubAgentExecutionService` 已接入平台识别后的同源过滤结果

### 23. 当前工具语义继续补强

- `read_project_file`
  - 支持 `start_line / end_line / limit`
  - 支持负数行号
  - 支持 `exclude_line_numbers`
  - 局部读取时会返回稳定行窗和 `selected_lines`
- `edit_project_file`
  - 支持 `pattern + use_regex`
  - 支持 `start_text / end_text`
  - 支持锚点范围替换与范围删除
- `manipulate_project_file_lines`
  - 支持 `sourceRelativePath` 等源路径别名
  - 支持负数行号
- `search_project_files`
  - 支持 `use_regex`

### 24. 保留探针已扩展到 35/35 全通过

- `apps/novel_agent_app/tool/all_tools_probe.dart` 新增验证：
  - `read_project_file.line_window`
  - `edit_project_file.regex_replace`
  - `edit_project_file.anchored_range`
  - `manipulate_project_file_lines.negative_lines`
- 最新报告：
  - `apps/novel_agent_app/artifacts/tool_probes/probe_2026-05-25T01-52-20-866022/tool_probe_report.json`

### 25. 高风险 checkpoint 的“建议返工”已落成共享动作

- adapters 新增：
  - `ProjectLongTaskCheckpointRevisionFollowupService`
- core 调整：
  - `LongTaskCheckpointActionContractService`

现在 `request_revision_followup` 不再只是一个高风险建议文案。

它已经被明确物化成：

- 基于当前 checkpoint review 生成或复用 follow-up review 任务
- 把关联 review 任务重新收束回源任务
- 在源任务上留下可恢复状态：
  - `followup_request_state`
  - `followup_request_checkpoint_review_path`
  - `followup_request_task_ids`
  - `followup_request_task_paths`

这一层当前故意没有越级直接生成 `revision` 任务，而是先把高风险节点导向：

- 更细的 review 分支
- 再由 review report -> repair task 的既有共享链继续推进

这样 mode 1 的高风险 checkpoint 终于有了稳定的“先返工判断、再进入修复”共用入口，而不是让 GUI / CLI 或人工自己记住应该先补哪条链。

另外这一轮顺手调整了动作合同：

- `request_revision_followup` 现在已经是 `apply_checkpoint_review_action`
- 对高风险 checkpoint，它会优先成为 `recommended_action_id`

### 26. mode 1 的 checkpoint revisit / revision-followup 真实探针再次通过

- `apps/novel_agent_app/tool/seed_autopilot_checkpoint_revision_followup_probe.dart`
- `apps/novel_agent_app/tool/seed_autopilot_checkpoint_revisit_probe.dart`

这次不是只跑定向单元测试，而是继续用真实 provider 链路确认：

- 高风险 checkpoint 可以真实进入 `request_revision_followup`
- follow-up review 任务会真实生成或复用
- 源任务会留下 follow-up 请求状态
- 长期约束回看包在这轮集成后再次 `PASS`

## 已验证

最近一次通过验证：

- `dart test test/draft_generation_use_case_test.dart test/mode_guidance_asset_context_section_service_test.dart test/context_assembler_service_test.dart` in `packages/novel_agent_core`
- `dart test test/long_task_checkpoint_review_service_test.dart` in `packages/novel_agent_core`
- `dart test test/long_task_runtime_services_test.dart` in `packages/novel_agent_core`
- `dart test test/project_workflow_runtime_service_test.dart` in `packages/novel_agent_adapters`
- `dart test test/project_long_task_checkpoint_review_service_test.dart` in `packages/novel_agent_adapters`
- `flutter test` in `apps/novel_agent_app` after retry / guide-scope / timeline scroll integration
- `dart test test/agent_run_services_test.dart` in `packages/novel_agent_core`
- `flutter analyze` in `apps/novel_agent_app`
- `flutter test` in `apps/novel_agent_app`
- `dart analyze` in `apps/novel_agent_cli`
- `dart run bin/novel_agent.dart workflow help` in `apps/novel_agent_cli`
- `dart run bin/novel_agent.dart review help` in `apps/novel_agent_cli`
- `dart run bin/novel_agent.dart template help` in `apps/novel_agent_cli`
- `dart test` in `packages/novel_agent_core`
- `dart analyze` in `packages/novel_agent_adapters`
- `dart test` in `packages/novel_agent_adapters`
- `dart run tool/real_option_probe.dart` in `apps/novel_agent_app`
- `dart run tool/all_tools_probe.dart` in `apps/novel_agent_app` -> `35/35`
- `dart run tool/seed_autopilot_execution_probe.dart` in `apps/novel_agent_app` -> `PASS`
- `dart run tool/seed_autopilot_queue_probe.dart` in `apps/novel_agent_app` -> `PASS`
- `dart run tool/seed_autopilot_mode_probe.dart` in `apps/novel_agent_app` -> `gap_probe PASS`, `plan_probe PASS`
- `dart run tool/full_outline_mode_probe.dart` in `apps/novel_agent_app` -> `gap_probe PASS`, `plan_probe PASS`
- `dart test test/long_task_checkpoint_action_contract_service_test.dart` in `packages/novel_agent_core`
- `dart test test/project_long_task_checkpoint_action_service_test.dart` in `packages/novel_agent_adapters`
- `dart analyze packages/novel_agent_core packages/novel_agent_adapters apps/novel_agent_app`
- `dart run tool/seed_autopilot_checkpoint_revision_followup_probe.dart` in `apps/novel_agent_app` -> `PASS`
- `dart run tool/seed_autopilot_checkpoint_revisit_probe.dart` in `apps/novel_agent_app` -> `PASS`
- `dart run tool/mode_guidance_cli_probe.dart` in `apps/novel_agent_cli` -> `PASS`
- `flutter build windows --release` in `apps/novel_agent_app`
- `dart run tool/real_long_task_probe.dart` in `apps/novel_agent_app` -> `PASS`
- `dart analyze apps/novel_agent_app`
- `flutter test test/widget_test.dart` in `apps/novel_agent_app`
- `dart test test/project_directory_layout_service_test.dart test/project_manifest_storage_strategy_test.dart test/create_project_workspace_use_case_test.dart test/runtime_baseline_catalog_service_test.dart test/runtime_baseline_execution_mode_service_test.dart test/long_task_run_state_machine_test.dart test/long_task_task_factory_runtime_baseline_test.dart test/long_task_task_completion_policy_service_test.dart test/long_task_chapter_gate_policy_service_test.dart test/long_task_chapter_gate_review_task_factory_service_test.dart` in `packages/novel_agent_core`
- `dart test test/markdown_project_directory_skeleton_service_test.dart test/sqlite_project_content_repository_test.dart test/project_storage_strategy_resolver_test.dart test/local_long_task_run_registry_test.dart test/long_task_supervisor_test.dart test/long_task_heartbeat_scheduler_test.dart` in `packages/novel_agent_adapters`
- `dart analyze packages/novel_agent_core packages/novel_agent_adapters apps/novel_agent_app`
- `dart run tool/full_outline_mode_probe.dart` in `apps/novel_agent_app` -> `gap_probe PASS`, `plan_probe PASS`
- `flutter test test/widget_test.dart` in `apps/novel_agent_app` after Session 16 regression pass

## 当前仍存在的明确缺口

### 本轮新增完成

- Session 16 已完成一次围绕四条主链的联调回归：
  - 目录新结构
  - 项目主存储策略创建链
  - 长任务全局运行实例链
  - 第二种运行基准 `chapter_collaboration_autorun`
- 本轮没有发现新的核心主线断裂，唯一实际修复项落在真实探针基础设施：
  - `apps/novel_agent_app/tool/probe_support.dart`
- 修复内容：
  - 真实探针读取接口配置时，优先使用 `test_api.txt`
  - 如果当前机器没有 `test_api.txt`，自动回退读取 `temp/novel_agent_settings.json`
  - 回退读取现已兼容 snake_case 字段：
    - `default_provider_id`
    - `default_model_id`
    - `base_url`
    - `api_key`
    - `model_id`
- 修复后的联调结果：
  - `full_outline_mode_probe.dart` 已恢复可跑
  - mode 2 的“信息不足补问 / 信息充分建纲”两条真实链路都再次通过
  - Session 15 的 app 壳层拆分没有打断项目创建、双存储策略、全局运行链和第二运行基准

- Session 15 已完成第一轮 app 壳层拆分收口：
  - `app/state/app_shell_destination_controller.dart`
  - `features/project_creation/application/controllers/project_creation_controller.dart`
  - `features/workbench/application/controllers/workbench_workspace_controller.dart`
  - `features/workbench/application/controllers/workbench_conversation_controller.dart`
  - `features/workbench/application/models/workbench_project_runtime_state.dart`
  - `features/workbench/application/models/workbench_conversation_runtime_state.dart`
- `AppShellController` 已从 `5621` 行收缩到 `3635` 行，壳层职责改为：
  - 全局装配
  - 目的地切换
  - 非工作台子域的桥接刷新
- 工作台职责已拆成两个明确扩展点：
  - `WorkbenchWorkspaceController`：项目加载、资源树、文档标签、工作区命令
  - `WorkbenchConversationController`：会话发送链、会话历史、引导态、模型/智能体选择
- 项目入口职责已拆成独立扩展点：
  - `ProjectCreationController`：默认项目恢复、项目创建、桌面端打开已有项目、启动器状态
- 壳层导航已拆成独立扩展点：
  - `AppShellDestinationController`：`shell -> destination` 切换与页面级刷新触发
- `WorkbenchPage` 已不再直接把整个 `AppShellController` 作为资源/文档/会话三类 handler 传入，而是显式接：
  - `resourceManagerHandler`
  - `documentWorkspaceHandler`
  - `conversationHandler`

- skill / agent 包元数据已收紧为“通用核心字段 + `metadata.novel_agent` 扩展字段”的双层规范
- `load_agent_skill` 默认改为返回执行摘要，避免超长技能正文直接挤占上下文；完整正文改为显式按需读取
- 风格资产已落成独立 `style` 结构、Markdown codec 与标准化服务
- 伏笔资产已落成独立 `foreshadow` 结构、Markdown codec 与标准化服务
- 项目级资产包已补齐基础闭环：导出文档、导入预检、正式导入
- 这轮资产层先做 core 基座，GUI/CLI 后续只接入口与浏览，不再各自重复造导入导出逻辑
- 已新增项目资产中心 GUI 入口：风格中心、伏笔中心、资产包导入/导出
- 已新增 CLI `asset` 命令组，直接复用同一套项目资产服务
- 已补 style / foreshadow Markdown 解析器，项目资产现在可以从标准 Markdown 真实回读

### 本轮已补

- `seed_to_full_novel` 的常规章节现在默认写入 `chapters/`，样章仍保留在 `drafts/` 作为确认门槛
- 长任务章节成功后的完成状态已拆成共享策略：样章/监督队列继续等待用户，常规章节可自动 `succeeded`
- 章节总字数约束已进入共享任务参数，并支持“是否开启”的共享设置语义
- `default_generalist` 现已允许读取 `novel-control-station`，真实长任务探针中已观察到 `load_agent_skill` 被调用
- OpenAI 兼容网关已加入“有限内置传输重试”能力，默认用于 `Connection closed before full header` 一类瞬时错误
- 新增真实长任务探针：`apps/novel_agent_app/tool/real_long_task_probe.dart`
- 选项区、重试区、子智能体活动已并入同一会话滚动区，不再出现“选项出现后滚轮只卡在底部区域”的分裂滚动体验
- 同轮语义完全一致的重复工具调用现在会在 core 侧去重，不再因为不同 `tool_call id` 被重复执行
- 会话失败后已经补上可重试入口；重试会清掉上一条失败展示和重试按钮，且失败内容默认不进入后续上下文
- 长篇项目已加入“长任务开局 -> 模式细分页”入口，模式定义下沉进 core
- 已新增能力分类文档：`docs/migrated-capability-classification.md`
- 已新增第一种长任务模式的架构设计文档：`docs/long-task-mode-1-architecture.md`
- 已新增策略优先预设计文档：`docs/strategy-first-predesign.md`
- 已新增策略优先实施顺序文档：`docs/implementation-order-strategy-first.md`
- Session 14 已完成第一批 core 落地：新增共享 `inspiration` 子域，正式定义灵感记录、收束阶段目录与从灵感到 `premise/style/world/characters` 的共享映射入口
- `ModeGuidanceState` 到共享灵感记录的转换已抽成独立 mapper，现有长任务开局链开始复用共享灵感域，而不再把“灵感收束”写死在长任务私有 builder 里
- `ModeGuidanceAssetBundle` 已补 premise / character profile 视角，现有上下文注入现在可以直接带入“故事前提”而不只有风格、世界与实体摘要

### 生态系统

- Flutter 侧生态包导出入口还没做成单独 UI

### 共享运行链与更深交互

- 审稿中心目前已能看报告、建修复任务，但“直接发起审稿执行”的更完整引导仍可继续细化
- 模板页已能编辑、预览、保存、恢复、删覆盖，但还没有独立的 prompt debug 组合页
- `Responses API` 真实网关分流仍未补齐，目前运行链默认仍走 Chat API 兼容实现

### 工具与宿主适配

- 生态导出 GUI 入口仍未补齐
- `generate_image` 目前是轻量 gateway 分支，不是完整供应商图片工作流

## 当前工作原则

- 先消灭空入口，再做体验打磨
- 先走真实用例，再做表单壳
- 不把业务逻辑压进控制器
- 能抽服务就抽服务，能放 core 不放 app

## 下一步精确入口

恢复时从这里继续：

1. 把“传输层有限内置重试”的设置真正接到 GUI 可见文案与 CLI 配置说明
2. 把风格 / 伏笔 / 资产包接进真实 GUI/CLI 入口，而不是只停在 core
3. 把资产中心继续细化成图谱/时间线/默认风格切换，而不只停在表单中心
4. 补生态页生态包导出 UI 入口
5. 做独立 prompt debug 组合页
6. 补 `Responses API` 的真实 HTTP 分流，而不是只保留设置项
7. 继续把图片类 gateway 做成更完整的供应商 / 输出文件闭环
8. 做 Android 打包回归
9. 继续推进第一种长任务模式的“执行后漂移控制 / 检查点复盘 / 风格守恒”节点
10. 在已有复盘包与 review task 物化之上，继续补“review report -> repair task / 返工建议”这一层共享规则
11. 给第一种长任务模式补更细的风格 / 世界 / 角色漂移严重度判断
12. 把 checkpoint action package 与 revision resolution package 接到 Flutter 任务中心的真实用户入口

## 恢复注意事项

- 若上下文压缩，优先读取本文件
- 不要回退到“只做 UI 壳”的路线
- 不要把新逻辑继续堆进 `AppShellController`
- 大块功能进入前，优先抽独立 service / use case / adapter
