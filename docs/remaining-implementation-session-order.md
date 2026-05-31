# NovelAgentFlutter 剩余实现会话顺序文档

最后更新：2026-05-26

## 0.6 Session 22 完成记录

- 已完成 `Session 22：漂移控制与 review -> repair -> continue 放行器`
- 已落地：
  - core 漂移与放行新增：
    - `LongTaskNarrativeDriftSignalService`
    - `LongTaskCheckpointDispositionService`
    - `LongTaskChapterGateDispositionService`
  - `LongTaskCheckpointDriftSignalService` 已正式纳入第四类共享叙事漂移：
    - `narrative`
    - 覆盖 `伏笔 / 时间线 / 关系`
  - `LongTaskCheckpointActionContractService` 不再只按 severity 硬开动作：
    - 改为先解析 `disposition`
    - 明确区分：
      - `auto_continue`
      - `blocked_wait_user`
      - `manual_attention`
    - 高风险 chapter/planning/checkpoint 会优先推荐：
      - `request_revision_followup`
    - 中风险会优先推荐：
      - `create_followup_review_tasks`
  - `LongTaskChapterGatePolicyService` 已改为消费正式 gate disposition：
    - `auto_continue`
    - `blocked_wait_user`
    - `auto_create_repair_task`
    - `manual_attention`
  - `LongTaskCheckpointReviewTaskSuggestionService` 已纳入 `narrative` 漂移压力：
    - `assets/foreshadows/`
    - `assets/timeline/`
    - `assets/relationships/`
    会进入 continuity 审稿优先级判断
  - adapters 侧已接通：
    - `ProjectLongTaskCheckpointReviewService`
      - 保存 `disposition`
      - 保存 `continuation_disposition / continuation_reason`
    - `ProjectLongTaskChapterGateService`
      - 返回 `gate_disposition / gate_reason / manual_attention_required`
    - `ProjectWorkflowRuntimeService`
      - gate 决策不再只是写个 `chapter_gate_action`
      - `blocked_wait_user / manual_attention` 会真实把当前 review 任务留在 `waiting_user`
      - 从而阻止下游章节自动推进
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart test test/long_task_checkpoint_drift_signal_service_test.dart test/long_task_checkpoint_disposition_service_test.dart test/long_task_chapter_gate_disposition_service_test.dart test/long_task_checkpoint_action_contract_service_test.dart test/long_task_chapter_gate_policy_service_test.dart test/long_task_checkpoint_review_service_test.dart test/long_task_checkpoint_review_task_suggestion_service_test.dart`
    - `dart analyze lib/src/review/review_issue_normalizer_service.dart lib/src/workflow/long_task_narrative_drift_signal_service.dart lib/src/workflow/long_task_checkpoint_disposition_service.dart lib/src/workflow/long_task_chapter_gate_disposition_service.dart lib/src/workflow/long_task_checkpoint_drift_signal_service.dart lib/src/workflow/long_task_checkpoint_action_contract_service.dart lib/src/workflow/long_task_chapter_gate_policy_service.dart lib/src/workflow/long_task_checkpoint_review_task_suggestion_service.dart lib/src/workflow/long_task_checkpoint_review_markdown_renderer.dart test/long_task_checkpoint_drift_signal_service_test.dart test/long_task_checkpoint_disposition_service_test.dart test/long_task_chapter_gate_disposition_service_test.dart test/long_task_checkpoint_action_contract_service_test.dart test/long_task_chapter_gate_policy_service_test.dart`
    - 全部通过
  - `packages/novel_agent_adapters`
    - `dart test test/project_long_task_checkpoint_review_service_test.dart test/project_long_task_chapter_gate_service_test.dart test/project_long_task_checkpoint_action_service_test.dart test/project_long_task_review_repair_task_service_test.dart`
    - `dart analyze lib/src/workflow/project_long_task_checkpoint_review_service.dart lib/src/workflow/project_long_task_chapter_gate_service.dart lib/src/workflow/project_workflow_runtime_service.dart test/project_long_task_checkpoint_review_service_test.dart test/project_long_task_chapter_gate_service_test.dart test/project_long_task_checkpoint_action_service_test.dart`
    - 全部通过
  - 真实探针：
    - `dart run tool/seed_autopilot_checkpoint_action_probe.dart` in `apps/novel_agent_app`
    - 通过，确认高风险 checkpoint 会真实给出返工跟进动作并可物化 followup 链
- 下一轮默认从 `Session 23` 开始，除非联调再次暴露 Session 22 回归问题

## 0.7 Session 23 完成记录

- 已完成 `Session 23：项目包 / 资产包导入导出真实 adapter 流程`
- 已落地：
  - adapter 侧公共 bundle 执行骨架：
    - `ProjectBundleDirectoryLayoutService`
    - `ProjectBundleFileAccessService`
    - `ProjectBundlePreviewMapperService`
    - `ProjectBundleWriteFile`
    - `ProjectBundleWritePlan`
    - `ProjectBundleApplyService`
  - 宿主外部文件写入口已补齐：
    - `ProjectToolHostPort.writeExternalTextFile(...)`
    - `ProjectWorkspaceToolHostAdapter`
    - `LocalProjectFileMutationAdapter`
  - 目录型 bundle 服务已正式拆开，不再把逻辑继续堆进旧的资产服务：
    - `ProjectStyleBundleLibraryService`
    - `ProjectCharacterBundleLibraryService`
    - `ProjectAssetBundleLibraryService`
    - `ProjectPackageLibraryService`
  - 项目包已打通真实目录导入导出，覆盖：
    - `project_manifest`
    - `runtime_profile`
    - `characters`
    - `organizations`
    - `styles`
    - `foreshadows`
    - `relationships`
    - `timelines`
    - `prompt_templates`
  - 角色/组织卡与组织 Markdown 支撑已补齐：
    - `OrganizationProfileMarkdownCodecService`
    - `OrganizationProfileMarkdownParserService`
    - `ProjectOrganizationProfileRepository`
    - `ProjectCharacterProfileRepository.listProfiles(...)`
  - 旧项目资产包路径已同步收束到新的资产目录语义：
    - `assets/styles/`
    - `assets/foreshadows/`
    - 不再继续把新导入内容写回旧的 `styles/` / `world/foreshadows/`
  - CLI 正式入口已补齐：
    - `project preview-package`
    - `project import-package`
    - `project export-package`
    - `asset preview-style-bundle`
    - `asset import-style-bundle`
    - `asset export-style-bundle`
    - `asset preview-character-bundle`
    - `asset import-character-bundle`
    - `asset export-character-bundle`
    - `asset preview-project-asset-bundle`
    - `asset import-project-asset-bundle`
    - `asset export-project-asset-bundle`
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart test test/bundle_contract_services_test.dart test/customization_use_cases_test.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart test test/project_bundle_library_services_test.dart test/project_tool_dispatcher_path_test.dart`
    - 通过
  - 全量静态检查：
    - `dart analyze apps/novel_agent_cli packages/novel_agent_adapters packages/novel_agent_core`
    - 通过
  - CLI 入口烟测：
    - `dart run bin/novel_agent.dart asset help`
    - `dart run bin/novel_agent.dart project help`
    - 均通过并显示新入口
- 后续扩展点：
  - 目录包当前的导入仍以 `bundle.json` 为规范事实来源，后续 zip 导出只需直接打包现有目录
  - GUI 侧后续可直接消费现有的：
    - `preview`
    - `write_plan`
    - `apply result`
    不必再自行拼导入规则
- 下一轮默认从 `Session 24` 开始，除非联调再次暴露 Session 23 回归问题

## 0.5 Session 21 完成记录

- 已完成 `Session 21：伏笔 / 时间线 / 关系回填主链`
- 已落地：
  - core 共享叙事资产回填基座：
    - `ForeshadowStatusCatalogService`
    - `ForeshadowStateUpdateRequest / Mapper / Planner`
    - `TimelineStateUpdateRequest / Mapper / Planner`
    - `RelationshipStateUpdateRequest / Mapper / Planner`
    - `ForeshadowFeedbackSignal / Extractor / Planner`
    - `SharedNarrativeAssetContextSectionService`
    - `SharedNarrativeAssetContextProjectionService`
  - adapters 共享叙事资产写盘链：
    - `ProjectForeshadowPathPolicy / Repository / StateUpdateService`
    - `ProjectTimelinePathPolicy / Repository / StateUpdateService`
    - `ProjectRelationshipPathPolicy / Repository / StateUpdateService`
    - `ProjectForeshadowFeedbackUpdateService`
  - `ProjectStructuredMemoryToolExecutor` 已正式接出：
    - `update_foreshadow_state`
    - `update_timeline_state`
    - `update_relationship_state`
  - `ProjectToolDispatcher`、`BuiltinToolCatalog`、`ToolSchemaBuilderService`、`ToolExecutionService` 已同步接通三类新工具
  - `run_continuity_check` 不再只是保存报告：
    - review issue 中的 `related_foreshadow_ids` 等字段会被规范化保留
    - 伏笔反馈会真实回写到 `assets/foreshadows/`
  - `ContextAssemblerService` 已开始注入三类共享上下文块：
    - `待回收伏笔`
    - `最近时间线`
    - `关键关系变化`
  - `ProjectContextFileSelectionService` 已提升：
    - `assets/foreshadows/`
    - `assets/timeline/`
    - `assets/relationships/`
    的读取优先级
  - 长任务后处理提示与章节原子后处理状态已同步认识三类新资产更新工具
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart test test/foreshadow_feedback_signal_extractor_service_test.dart test/shared_narrative_asset_context_projection_service_test.dart test/context_assembler_service_test.dart test/tool_execution_service_test.dart`
    - `dart analyze lib/src/assets lib/src/context/context_assembler_service.dart lib/src/runtime/project_context_file_selection_service.dart lib/src/runtime/tool_execution_service.dart lib/src/review/review_issue_normalizer_service.dart lib/src/tools/builtin_tool_catalog.dart lib/src/tools/tool_event_presenter_service.dart lib/src/tools/tool_schema_builder_service.dart lib/src/tools/tool_strategy_prompt_builder.dart lib/src/project/project_prompt_contract.dart lib/src/workflow/chapter_atomic_result_recorder_service.dart lib/src/workflow/long_task_postprocess_prompt_renderer.dart lib/src/workflow/long_task_transaction_contract_service.dart test/foreshadow_feedback_signal_extractor_service_test.dart test/shared_narrative_asset_context_projection_service_test.dart test/context_assembler_service_test.dart`
    - 全部通过
  - `packages/novel_agent_adapters`
    - `dart test test/project_foreshadow_state_update_service_test.dart test/project_timeline_state_update_service_test.dart test/project_relationship_state_update_service_test.dart test/project_foreshadow_feedback_update_service_test.dart`
    - `dart analyze lib/src/storage/project_foreshadow_feedback_update_service.dart lib/src/storage/project_foreshadow_path_policy.dart lib/src/storage/project_foreshadow_repository.dart lib/src/storage/project_foreshadow_state_update_service.dart lib/src/storage/project_relationship_path_policy.dart lib/src/storage/project_relationship_repository.dart lib/src/storage/project_relationship_state_update_service.dart lib/src/storage/project_timeline_path_policy.dart lib/src/storage/project_timeline_repository.dart lib/src/storage/project_timeline_state_update_service.dart lib/src/tools/project_structured_memory_tool_executor.dart lib/src/tools/project_tool_dispatcher.dart test/project_foreshadow_state_update_service_test.dart test/project_timeline_state_update_service_test.dart test/project_relationship_state_update_service_test.dart test/project_foreshadow_feedback_update_service_test.dart`
    - 全部通过
- 下一轮默认从 `Session 22` 开始，除非联调再次暴露 Session 21 回归问题

## 0.4 Session 20 完成记录

- 已完成 `Session 20：角色卡运行主链收束`
- 已落地：
  - core 角色运行链基座：
    - `CharacterProfileMarkdownCodecService`
    - `CharacterProfileMarkdownParserService`
    - `CharacterStageStateRecord`
    - `CharacterStageStateRecordMarkdownCodecService`
    - `CharacterStateUpdateRequest`
    - `CharacterStateUpdatePlannerService`
    - `CharacterStateHistoryMarkdownRenderer`
  - adapters 角色写盘主链：
    - `ProjectCharacterPathPolicy`
    - `ProjectCharacterProfileRepository`
    - `ProjectCharacterRuntimeStateRepository`
    - `ProjectCharacterStateUpdateService`
  - `update_character_state` 不再直接走“唯一文件名追加写入”，改为：
    - 主档固定写到 `assets/characters/<character_id>.md`
    - latest 状态固定写到 `.novel_agent/state/characters/<character_id>/latest.md`
    - 历史附录固定写到 `.novel_agent/state/characters/<character_id>/history.md`
  - 兼容读取旧的 `characters/<name>.md`，但后续正式写回统一回到新主路径
  - 上下文选择和检查点建议已同步改成：
    - 优先 `assets/characters/`
    - 兼容旧 `characters/`
- 下一轮默认从 `Session 21` 开始，除非联调再次暴露 Session 20 回归问题

## 0.3 Session 19 完成记录

- 已完成 `Session 19：constitution / guidance / style 三层正式收束`
- 已落地：
  - core 创作约束子域：
    - `ProjectConstitution`
    - `ModeGuidance`
    - `CreativeRuleStack`
  - 三层共享解析器、上下文片段生成器、提示摘要渲染器
  - ContextAssembler 正式注入“项目创作宪法 / 模式引导约束 / 项目风格规范”
  - 长任务事务提示与后处理提示复用同一套创作约束栈
  - 读取规则已明确支持：
    - `specs/project_spec.md` / `specs/constitution.md`
    - `premise/project_constitution.md` / `premise/constitution.md`
    - `tracking/modes/<mode_id>/guidance.md`
    - `styles/` / `assets/styles/`
- 下一轮默认从 `Session 20` 开始，除非联调再次暴露 Session 19 回归问题

## 0.2 Session 18 完成记录

- 已完成 `Session 18：章节字数分布策略`
- 已落地：
  - core 字数分布基座：
    - `ChapterLengthProfile`
    - `ChapterLengthDistributionPolicy`
    - `ChapterLengthRecord`
    - `ChapterLengthEvaluation`
    - `ChapterLengthMeasurementService`
    - `ChapterLengthProfileResolverService`
    - `ChapterLengthDistributionService`
  - 长任务任务构建、动态任务构建、事务提示中的项目级字数基准解析
  - 兼容旧 prompt 字段的 `chapter_word_target/min/max`
  - 后处理链真实字数评估：
    - 当前章字数
    - 相邻章差值
    - 最近若干章滚动均值
    - 偏离等级与建议动作
  - checkpoint review / markdown 复盘中的“章节字数评价”区块
- 下一轮默认从 `Session 19` 开始，除非联调再次暴露 Session 18 回归问题

## 0.1 Session 17 完成记录

- 已完成 `Session 17：技能路由策略正式化`
- 已落地：
  - core 技能路由模型：`SkillRoutingPolicy / StageSkillPreset / SkillActivationSignal / SkillLoadMemory`
  - 运行期技能去重记忆
  - 长任务 / 章节 / 审稿 / 修订阶段的默认技能预加载规则
  - `load_agent_skill.reference_path` 定点读取
  - 长任务事务提示中的技能路由区块
- 下一轮默认从 `Session 18` 开始，除非联调再次暴露 Session 17 回归问题

## 0. 文档目的

这份文档承接：

- `docs/major-redesign-session-order.md` 的 Session 01 ~ 16
- 当前 `docs/migration-progress.md` 里仍未闭环的能力
- `docs/absorption/` 与 `docs/mumuainovel-absorption-analysis.md` 中已经明确、但还没真正落进产品的部分

它的目标不是继续写“大方向”，而是把**当前还没实现完的东西**拆成：

- 一次提问内能做完
- 预计一轮改动量大致控制在 `<= 2000` 行上下
- 有明确完成判定
- 有明确“本轮不要做”
- 可以直接复制给 Codex 的执行提示词

## 1. 适用范围

本文件只负责 Session 17 之后的剩余实现顺序。

重点覆盖：

1. 技能调用策略真正产品化
2. 章节字数“可配置基准 + 分布均衡”策略
3. `constitution / guidance / style` 三层正式分家
4. 角色卡、伏笔、时间线、关系真正进入运行主链
5. `review -> repair -> continue` 更稳的自动放行 / 阻塞
6. 资产导入导出真实落地
7. 图谱 / 时间线 / 资产中心 / 分析重写等 UI 接线
8. 灵感模式、拆书模式等后续策略入口
9. 在若干核心链完成后，再统一规划工作台与相关中心页的 UI 体验

## 2. 全局硬约束

后续每一轮都必须继续遵守：

- 单一职责
- 单文件不要过重
- 策略模式优先
- GUI / CLI 共用 core
- app 不吞业务
- adapters 不反向长成业务中心
- 优先复用已有对象、服务、用例、port、adapter
- 新逻辑与复杂状态转换保留中文注释

### 2.1 文件体量约束

- 单文件超过 `400` 行必须自检
- 单文件接近 `700` 行必须拆
- 不允许继续把新职责塞回：
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`

### 2.2 UI 介入顺序约束

这轮开始允许做 UI，但不是一上来就大面积打磨。

必须先完成这些核心链，才允许进入“统一规划 UI”阶段：

1. 技能调用策略基座
2. 字数分布策略
3. `constitution / guidance / style` 三层合同
4. 角色卡运行主链
5. 伏笔 / 时间线 / 关系回填主链

也就是说：

- Session 17 ~ 22 以 core / adapters / app 装配为主
- Session 23 之后才逐步进入正式 UI 接线
- 真正统一规划工作台与各中心页布局，放到更后面单独一轮做

## 3. 关于字数策略的正式理解

从现在开始，项目里的“字数限制”不应再被理解为单一固定值。

### 3.1 正确目标

字数策略服务的是：

- 项目类型差异
- 平台投放差异
- 章节节奏差异
- 长任务不同阶段差异

所以它应该是：

- **可配置的字数基准**
- **按项目 / 模式 / 任务可调整**
- **偏重均衡分布，而不是死卡数字**

### 3.2 后续实现的统一方向

后续所有相关实现都要按这个方向走：

- 允许项目配置章节字数基准，例如：
  - `2000`
  - `3000`
  - `8000`
  - `20000`
- 允许不同任务选择不同字数档
- 核心关注：
  - 目标值
  - 柔性区间
  - 相邻章节差值
  - 最近若干章的分布均衡
- 默认不把它做成“严格硬拦截”

也就是说：

- 它是**分布策略**
- 不是**死数字阈值**

## 4. 执行顺序总览

建议按下面顺序推进：

### 第一组：先把运行链补稳

- Session 17：技能路由策略正式化
- Session 18：章节字数分布策略
- Session 19：`constitution / guidance / style` 三层收束
- Session 20：角色卡运行主链收束
- Session 21：伏笔 / 时间线 / 关系回填主链
- Session 22：漂移控制与 `review -> repair -> continue` 放行器

### 第二组：把资产与分析闭环从“合同”推进到“可用”

- Session 23：导入导出真实 adapter 流程
- Session 24：资产中心与图谱 / 时间线读侧接线
- Session 25：分析 -> 建议 -> 重写 GUI 闭环
- Session 26：长任务总站与工作台联动深化

### 第三组：扩模式，再统一规划 UI

- Session 27：灵感工作台共享能力落地
- Session 28：拆书模式 core 入口
- Session 29：拆书导入向导与结构化预览 UI
- Session 30：统一工作台 / 中心页 UI 规划与分层改造
- Session 31：总回归、探针、Windows 打包与文档回填

## 5. Session 17：技能路由策略正式化

### 本轮目标

把技能从“可被加载”推进到“由调度策略主动决定何时加载、加载到什么粒度”。

### 预计改动量

- 约 `1200 ~ 1900` 行

### 必读文档

- `agent.md`
- `docs/absorption/10-projects/book-os/README.md`
- `docs/absorption/10-projects/novel-writer/README.md`
- `docs/absorption/10-projects/ai-novel/README.md`
- `builtin_packages/skills/novel-control-station/SKILL.md`
- `builtin_packages/skills/novel-control-station/references/authenticity-and-de-ai-pass.md`

### 必须完成

1. 在 core 建立技能路由策略模型，例如：
   - `SkillRoutingPolicy`
   - `StageSkillPreset`
   - `SkillActivationSignal`
   - `SkillLoadMemory`
2. 把长任务 / 普通章节 / 审稿 / 修订等任务类型对应的默认技能预装载规则立到 core
3. 把“只加载摘要”与“按需细读 reference”做成正式策略，而不是靠模型自由发挥
4. 给运行链补“本轮已加载技能记忆”，避免重复读取同一技能
5. adapter / runtime 真正接这套策略

### 本轮重点拆耦

- 技能路由逻辑不要塞进 prompt builder
- 技能加载历史不要散落在 UI controller
- `load_agent_skill` 的执行器只负责加载，不负责决定何时加载

### 本轮不要做

- 不做 UI 打磨
- 不做去 AI 文案大改
- 不顺手重写所有内置技能

### 完成判定

- 至少两类任务已有明确的阶段性技能预装载策略
- 运行时已能记住“本轮 / 本任务已读过哪些技能”
- 技能不再完全依赖模型“想起来才调用”

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 17 执行。先阅读 agent.md、docs/absorption/10-projects/book-os/README.md、docs/absorption/10-projects/novel-writer/README.md、docs/absorption/10-projects/ai-novel/README.md，以及 builtin_packages/skills/novel-control-station/SKILL.md 和其 references/authenticity-and-de-ai-pass.md。把技能调用从“可加载”推进到“策略驱动加载”：在 core 建立 SkillRoutingPolicy、StageSkillPreset、SkillActivationSignal、SkillLoadMemory，接入长任务/章节/审稿/修订等任务阶段的默认技能预装载与按需细读 reference 机制。注意单一职责、不要把路由逻辑塞进 prompt builder 或 UI controller，不做 UI 打磨。完成后补测试并回填文档。
```

## 6. Session 18：章节字数分布策略

### 本轮目标

把“字数限制”改造成“可配置字数基准 + 分布均衡策略”。

### 预计改动量

- 约 `1000 ~ 1700` 行

### 必读文档

- `agent.md`
- `docs/mumuainovel-absorption-analysis.md`
- `docs/major-redesign-master-plan.md`
- `docs/provider-compatibility-baseline.md`

### 必须完成

1. 在 core 建立正式字数策略对象，例如：
   - `ChapterLengthProfile`
   - `ChapterLengthDistributionPolicy`
   - `ChapterLengthEvaluation`
2. 支持项目级可配置字数基准，而不是单一固定值
3. 让章节后处理能统计：
   - 当前章字数
   - 相邻章差值
   - 最近若干章均值
4. 让运行链能根据偏离程度给出：
   - 正常通过
   - 轻微提醒
   - 建议下章回调
   - 严重偏离时进入 review / repair 提示
5. 保持与现有 prompt 级字数提示兼容

### 本轮重点拆耦

- 字数评估不要写死在长任务 mode 里
- 不要把统计逻辑塞到 UI
- 不要把“分布策略”和“provider prompt 文案”写成一个类

### 本轮不要做

- 不做最终设置页美化
- 不顺手改所有模式默认字数
- 不把它做成严格硬拦截

### 完成判定

- 项目级字数基准已可表达
- 后处理链已有字数分布评估结果
- 现有探针能看到“章节字数评价”而不只是 prompt 中的数字

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 18 执行。先阅读 agent.md、docs/mumuainovel-absorption-analysis.md、docs/major-redesign-master-plan.md、docs/provider-compatibility-baseline.md。把当前“字数限制”升级成“可配置字数基准 + 分布均衡策略”：在 core 建立 ChapterLengthProfile、ChapterLengthDistributionPolicy、ChapterLengthEvaluation，并接入章节后处理，统计当前章字数、相邻章差值、滚动均值与偏离等级。注意它是柔性分布策略，不是死卡阈值；不要把统计逻辑塞进 UI 或长任务单一 mode。完成后补探针与文档回填。
```

## 7. Session 19：`constitution / guidance / style` 三层正式收束

### 本轮目标

把项目级创作宪法、模式引导和语言风格三层边界立硬。

### 预计改动量

- 约 `1200 ~ 2000` 行

### 必读文档

- `agent.md`
- `docs/absorption/10-projects/novel-writer/README.md`
- `docs/absorption/10-projects/book-os/README.md`
- `docs/long-task-mode-1-architecture.md`
- `docs/strategy-first-predesign.md`

### 必须完成

1. 在 core 正式建立三层对象与解析优先级：
   - `ProjectConstitution`
   - `ModeGuidance`
   - `StyleProfile` / `ProjectStyleBinding`
2. 让上下文组装能区分这三层来源和优先级
3. 让 review / revision / long task 后处理也复用同一优先级解析
4. 明确去 AI / 自然表达类规范应落在哪一层
5. 把相关目录和读取规则回填到项目合同文档

### 本轮重点拆耦

- 不要把 constitution 写成 style 的一部分
- 不要让 mode guidance 继续冒充长期项目宪法
- 不要把风格优先级散落到多个 prompt 拼接器

### 本轮不要做

- 不做风格中心 UI 完整打磨
- 不做文案全面改写
- 不顺手重构所有旧风格文件

### 完成判定

- 三层合同和解析顺序已明确进入 core
- 运行链已有统一读取与注入方式
- 文档中已不再模糊混用这三个概念

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 19 执行。先阅读 agent.md、docs/absorption/10-projects/novel-writer/README.md、docs/absorption/10-projects/book-os/README.md、docs/long-task-mode-1-architecture.md、docs/strategy-first-predesign.md。把 constitution / guidance / style 三层正式收束到 core：建立 ProjectConstitution、ModeGuidance、StyleProfile/ProjectStyleBinding 的正式模型与解析优先级，并让上下文组装、review、revision、long task 后处理共享同一套解析规则。注意单一职责、不要把 constitution 写成 style 的一部分，也不要把优先级散落在多个 prompt builder 里。完成后更新相关设计文档。
```

## 8. Session 20：角色卡运行主链收束

### 本轮目标

选定一条稳定角色卡路线，并让运行主链真正按这条路线更新角色状态。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/mumuainovel-absorption-analysis.md`
- `docs/major-redesign-master-plan.md`
- `docs/migration-progress.md`

### 必须完成

1. 正式选定现阶段角色卡路线：
   - 名字固定即可，但路径与更新方式必须稳定
2. 把 `update_character_state` 从“散状态文件”改成正式运行链：
   - 角色主档案
   - 阶段状态记录
   - 必要的历史附录或时间线引用
3. 明确普通项目与长任务项目共用同一角色卡更新入口
4. 调整资源树和读取选择策略，减少重复状态碎片

### 本轮重点拆耦

- 角色卡主模型与角色状态更新服务分开
- 不要把“角色显示方式”混到运行写盘逻辑里
- 不要把角色状态更新直接塞进大而全 postprocess 类

### 本轮不要做

- 不做完整角色中心 UI
- 不处理复杂改名迁移
- 不顺手做组织卡大改

### 完成判定

- 真实运行链不再继续产出一串 `角色名_2 / _3 / _4`
- 角色状态写入路径和历史表达已稳定
- 普通项目与长任务能共用这套角色更新逻辑

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 20 执行。先阅读 agent.md、docs/mumuainovel-absorption-analysis.md、docs/major-redesign-master-plan.md、docs/migration-progress.md。把角色卡运行主链收束成一条稳定路线：现阶段允许名字固定，但 update_character_state 不能再散成一串重复状态文件。请把角色主档案、阶段状态记录和必要历史表达拆开设计，并让普通项目与长任务共用同一更新入口。注意单一职责，不要把角色显示逻辑混进写盘逻辑，也不要顺手做完整角色中心 UI。完成后补探针或测试并回填文档。
```

## 9. Session 21：伏笔 / 时间线 / 关系回填主链

### 本轮目标

把伏笔、时间线、关系从“已有合同”推进到“章节完成后真的会回填”。

### 预计改动量

- 约 `1300 ~ 2000` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/long-task-mode-1-architecture.md`
- `docs/absorption/10-projects/ai-novel/README.md`
- `docs/absorption/10-projects/deepseek-tui/README.md`

### 必须完成

1. 让章节后处理能正式回填：
   - `ForeshadowRecord`
   - `TimelineRecord`
   - `RelationshipRecord`
2. 让 review / analysis 结果能反哺伏笔状态迁移
3. 让上下文选择开始利用“待回收伏笔 / 最近相关时间线 / 关键关系变化”
4. 保持普通项目与长任务共用

### 本轮重点拆耦

- 伏笔状态机不要耦合某个长任务 mode
- 关系 / 时间线 / 伏笔不要合并成一个巨型资产更新器
- UI 层不能参与状态迁移判断

### 本轮不要做

- 不做图谱页面
- 不做复杂可视化
- 不顺手做资产中心美化

### 完成判定

- 真实章节完成后会产出或更新伏笔 / 时间线 / 关系资产
- review / analysis 能更新伏笔状态，而不只是摘要里提到“这是伏笔”
- 上下文选择已能读取这些共享资产

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 21 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/long-task-mode-1-architecture.md、docs/absorption/10-projects/ai-novel/README.md、docs/absorption/10-projects/deepseek-tui/README.md。把伏笔 / 时间线 / 关系从已有合同推进到运行主链：章节完成和 review/analysis 后处理要能真实回填 ForeshadowRecord、TimelineRecord、RelationshipRecord，并让上下文选择开始使用待回收伏笔、相关时间线和关键关系变化。注意单一职责，不做图谱 UI，不把三类资产塞进一个巨型更新器。完成后补探针。
```

## 10. Session 22：漂移控制与 `review -> repair -> continue` 放行器

### 本轮目标

把风格 / 世界 / 角色 / 伏笔四类漂移检测和放行逻辑收紧，让长任务更稳。

### 预计改动量

- 约 `1200 ~ 1900` 行

### 必读文档

- `docs/migration-progress.md`
- `docs/major-redesign-master-plan.md`
- `docs/absorption/10-projects/deepseek-tui/README.md`
- `docs/absorption/10-projects/ai-novel/README.md`

### 必须完成

1. 在 core 收束四类漂移严重度判断：
   - 风格
   - 世界
   - 角色
   - 伏笔 / 关系
2. 把 review 结果到 repair 任务、再到下游放行的规则继续收紧
3. 明确：
   - 自动继续
   - 阻塞等待
   - 自动派生修复
   - 人工中断
4. 让真实长任务探针能验证至少一种自动 repair / 阻塞链

### 本轮重点拆耦

- 漂移评估器与 repair 派生器拆开
- 不要把所有放行逻辑压进 scheduler
- UI 只消费动作结果，不参与是否放行判断

### 本轮不要做

- 不做工作台最终视觉
- 不做拆书
- 不顺手补所有中心页

### 完成判定

- 四类漂移严重度进入共享运行链
- `review -> repair -> continue` 至少一条真实路径更稳定
- 长任务卡住时能更清楚知道是“继续、返工还是中断”

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 22 执行。先阅读 docs/migration-progress.md、docs/major-redesign-master-plan.md、docs/absorption/10-projects/deepseek-tui/README.md、docs/absorption/10-projects/ai-novel/README.md。把风格 / 世界 / 角色 / 伏笔四类漂移检测和 review -> repair -> continue 放行器继续收紧：在 core 建立更明确的严重度判断和自动/阻塞/人工中断规则，并让真实长任务探针验证至少一种自动 repair 或阻塞链。注意不要把全部逻辑压进 scheduler，UI 只消费动作结果。完成后回填验证结果。
```

## 11. Session 23：项目包 / 资产包导入导出真实 adapter 流程

### 本轮目标

把 bundle 从 core 合同推进到可执行的 adapter 流程。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/storage-dual-compatibility-design.md`
- `docs/migration-progress.md`

### 必须完成

1. 落地真实流程：
   - `preview -> write plan -> apply`
2. 先做目录导入导出 adapter
3. 至少打通：
   - 项目包
   - 角色卡包
   - 风格包
   - 伏笔 / 项目资产包
4. CLI 侧接正式入口

### 本轮重点拆耦

- bundle 校验与真正写盘执行分开
- 目录导出实现与 UI 入口分开
- 不要把 zip 逻辑提前揉进目录导出流程

### 本轮不要做

- 不做完整 GUI
- 不做所有格式迁移
- 不顺手做生态页大改

### 完成判定

- 至少一条资产 bundle 的 preview / apply 真实可跑
- CLI 可以直接消费这套入口
- 目录导入导出不再只是合同层

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 23 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/storage-dual-compatibility-design.md、docs/migration-progress.md。把项目包 / 资产包导入导出从 core 合同推进到真实 adapter 流程：先做 preview -> write plan -> apply，再落地目录导入导出，至少打通项目包、角色卡包、风格包、伏笔/项目资产包，并给 CLI 接正式入口。注意 bundle 校验和真正写盘执行分开，不做完整 GUI，也不要提前揉 zip 逻辑。
```

## 12. Session 24：资产中心与图谱 / 时间线读侧接线

### 本轮目标

开始正式接 UI，但先做读侧与浏览，不急着做最终美化。

### 预计改动量

- 约 `1200 ~ 1900` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/absorption/10-projects/writingway/README.md`
- `docs/absorption/10-projects/ai-novel/README.md`
- `docs/responsibility-matrix.md`

### 必须完成

1. 让资产中心真实读取：
   - 风格
   - 伏笔
   - 时间线
   - 关系
2. 提供读侧图谱 / 时间线 / 关联检视壳
3. 建立独立 controller / view data，不回堆到 `AppShellController`

### 本轮重点拆耦

- 资产中心 controller 与图谱视图模型拆开
- 图谱视图先读已有资产，不要直接耦合模型原始响应
- 资源树 / 资产中心 / 工作台会话三者不要共用一个大 controller

### 本轮不要做

- 不追求最终视觉
- 不做复杂拖拽交互
- 不做写侧编辑全闭环

### 完成判定

- 用户已能在 GUI 里真实浏览风格 / 伏笔 / 时间线 / 关系资产
- 至少有基础图谱 / 时间线读侧壳
- 相关 app 层职责拆分保持干净

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 24 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/absorption/10-projects/writingway/README.md、docs/absorption/10-projects/ai-novel/README.md、docs/responsibility-matrix.md。开始做 UI 接线，但只做资产中心与图谱/时间线的读侧：让风格、伏笔、时间线、关系能在 GUI 真实浏览，并建立独立 controller / view data，不要再往 AppShellController 堆逻辑。注意先求结构正确，不追求最终视觉，不做复杂拖拽和写侧编辑全闭环。
```

### 完成记录

- 已完成 `Session 24`
- 资产中心现已独立为 `ProjectAssetsController`
- `AppShellController` 不再持有资产页快照、表单状态与保存/导入导出动作
- GUI 现已真实浏览：
  - 风格
  - 伏笔
  - 时间线
  - 关系
- 已补基础读侧壳：
  - 共享资产图谱
  - 时间线概览
  - 关联资产检视
- 当前仍刻意未做：
  - 图谱拖拽
  - 时间线编辑闭环
  - 关系编辑闭环
  - 最终视觉打磨

## 13. Session 25：分析 -> 建议 -> 重写 GUI 闭环

### 本轮目标

把已有 core 的分析 / 重写能力真正接成用户可用链。

### 预计改动量

- 约 `1200 ~ 2000` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/absorption/10-projects/writingway/README.md`
- `docs/absorption/10-projects/ai-novel/README.md`
- `docs/migration-progress.md`

### 必须完成

1. 分析结果真实展示
2. 建议对象和重写计划对象真实展示
3. 接出三种动作：
   - 整章重写
   - 局部重写
   - 只生成建议
4. 补最小对比 / 回放壳

### 本轮重点拆耦

- 分析结果 view model 与重写动作执行服务分开
- 局部重写范围选择不要写死在页面 widget 里
- 不把 provider 原始响应直接暴露给页面

### 本轮不要做

- 不做最终高级 diff UI
- 不做生态页
- 不顺手重构工作台所有布局

### 完成判定

- 分析结果可以直接发起重写
- 三条路径在 GUI 中可用
- 页面只消费结构化分析对象，不暴露传输层原文

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 25 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/absorption/10-projects/writingway/README.md、docs/absorption/10-projects/ai-novel/README.md、docs/migration-progress.md。把分析 -> 建议 -> 重写 GUI 闭环接起来：真实展示分析结果、建议对象和重写计划对象，并接出整章重写、局部重写、只生成建议三条路径，再补一个最小对比/回放壳。注意分离 view model 与动作执行服务，不暴露 provider 原始响应，不追求最终 diff UI。
```

### 完成记录

- 已完成 `Session 25`
- 审稿中心右侧已接入结构化分析面板
- 当前实现方式：
  - 从结构化 `review report` 投影出 `ChapterAnalysisResult`
  - 再由 `ChapterRewritePlanBuilderService` 构建三类计划
  - 再由 adapter 层把可执行计划物化为 `revision` 任务
- GUI 已可用的三条路径：
  - 整章重写
  - 局部重写
  - 只生成建议
- 已补最小回放壳：
  - 展示计划说明
  - 展示目标片段行号
  - 展示原文片段预览
- 当前仍刻意未做：
  - 高级 diff
  - 独立分析页
  - `analysis/` 独立落盘生态的完整读写闭环

## 14. Session 26：长任务总站与工作台联动深化

### 本轮目标

让长任务总站不只是“看运行对象”，而是能真正看到对应项目链路与关键阻塞点。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `docs/migration-progress.md`
- `docs/absorption/10-projects/deepseek-tui/README.md`
- `docs/architecture.md`

### 必须完成

1. 长任务总站接出：
   - 对应项目
   - 对应任务链
   - 最近 checkpoint / review / repair
   - 当前阻塞原因
2. 工作台与长任务总站之间建立清晰跳转
3. 维持全局运行对象不是页面状态的原则

### 本轮重点拆耦

- 运行实例列表、详情、跳转动作分开
- 不把任务链解析逻辑压进页面 widget
- 工作台页面不要直接读取 registry 细节

### 本轮不要做

- 不做最终视觉统一
- 不顺手补灵感模式
- 不改底层 provider

### 完成判定

- 长任务总站可定位具体项目和卡点
- 工作台与总站之间有清晰联动
- 相关 controller 继续保持拆分

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 26 执行。先阅读 docs/migration-progress.md、docs/absorption/10-projects/deepseek-tui/README.md、docs/architecture.md。把长任务总站继续做成“运行实例 -> 对应项目 -> 对应任务链 / 最近 checkpoint / review / repair / 阻塞原因”的联动视图，并和工作台建立清晰跳转。注意运行对象不是页面状态，运行实例列表、详情、跳转动作要分开，不要把任务链解析逻辑压进 widget。
```

### 完成记录

- 已完成 `Session 26`
- adapters 已新增总站只读详情链：
  - `ProjectLongTaskStationDetailService`
  - `ProjectLongTaskStationDetail`
  - `ProjectLongTaskStationChainSummary / ChainItem`
  - `ProjectLongTaskStationItemSummary`
  - `ProjectLongTaskStationBlockerSummary`
- 当前总站详情已不再只显示运行对象基础字段，而是会真实读取对应项目中的：
  - 当前活动任务
  - 对应任务链
  - 最近 checkpoint 复盘
  - 最近审稿报告
  - 最近返工任务
  - 当前阻塞摘要
- app 侧已补齐：
  - 长任务总站详情读态
  - 工作台 / 任务中心 / 审稿中心跳转
  - `LongTaskStationController` 只负责选择、刷新、动作和跳转委派
  - 任务链解析与项目读盘未再塞进 widget 或壳层
- 当前仍刻意未做：
  - 总站最终视觉统一
  - checkpoint 专属中心页
  - 更细粒度的链路内联编辑

## 15. Session 27：灵感工作台共享能力落地

### 本轮目标

把灵感模式从长任务前置引导推进成共享工作台能力。

### 预计改动量

- 约 `1100 ~ 1800` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/long-task-mode-1-architecture.md`
- `docs/major-redesign-master-plan.md`

### 必须完成

1. 让灵感对象在 GUI 中可真实整理与编辑
2. 打通到：
   - premise
   - style
   - world
   - characters
3. 让一般小说项目和长任务项目都能用这套入口

### 本轮重点拆耦

- 灵感工作台与长任务启动器分开
- 灵感收束逻辑与项目创建 UI 分开
- 灵感到资产映射服务继续放 core / app，不塞 widget

### 本轮不要做

- 不顺手做拆书
- 不做所有模式统一美化
- 不回堆壳层 controller

### 完成判定

- 灵感模式已是共享能力，不再只是某个长任务前置步骤
- GUI 可真实把灵感沉淀成项目资产

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 27 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/long-task-mode-1-architecture.md、docs/major-redesign-master-plan.md。把灵感模式从长任务前置引导推进成共享工作台能力：GUI 里可真实整理和编辑灵感对象，并打通到 premise/style/world/characters，让一般小说项目和长任务项目都能用。注意灵感工作台与长任务启动器分开，映射服务不要塞进 widget。
```

### 完成记录

- 已完成 `Session 27`
- app 侧已新增独立 `inspiration_workbench` 子域：
  - `InspirationWorkbenchController`
  - `InspirationWorkbenchLoaderService`
  - `InspirationWorkbenchViewDataService`
  - 独立 page / widgets / view data / action contract
- 当前已明确：
  - 灵感整理不再只藏在长任务会话引导里
  - 现在可从工作台资源区独立进入“灵感工作台”
  - 同一入口同时服务：
    - 一般小说项目
    - 长任务项目
  - 当前共享工作台直接复用已有：
    - `LoadModeGuidanceStateUseCase`
    - `AnswerModeGuidanceStageUseCase`
    - `ModeGuidanceAssetBundleBuilderService`
    - `ModeGuidanceProjectionDocumentService`
  - GUI 中现在可真实完成：
    - 模式切换
    - 阶段浏览
    - 阶段选项作答
    - 自由文本补充
    - `premise / style / world / characters` 四类共享资产预览
  - 阶段保存后会立即同步工作区资源树，确保项目侧投影文档与灵感页状态一致
- 当前仍刻意未做：
  - 灵感页直接发起长任务队列创建
  - 拆书模式接入灵感工作台
  - 灵感页与资产中心的最终统一视觉

## 16. Session 28：拆书模式 core 入口

### 本轮目标

正式建立拆书项目 / 拆书模式的 core 入口与结构化应用计划。

### 预计改动量

- 约 `1200 ~ 1900` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/absorption/10-projects/book-os/README.md`
- `docs/absorption/10-projects/ai-novel/README.md`
- `docs/major-redesign-master-plan.md`

### 必须完成

1. 定义拆书任务核心合同：
   - 输入
   - 结构化提取结果
   - 应用计划
2. 把拆书项目类型 / 模式入口正式立到领域层
3. 让它能落到现有资产体系，而不是另起一套野格式

### 本轮重点拆耦

- 拆书提取结果与最终应用动作分开
- 不要先做 UI 再倒推领域模型
- 不要把拆书结果直接写死成某供应商响应格式

### 本轮不要做

- 不做最终导入向导 UI
- 不做复杂文件解析器大全
- 不顺手改现有长任务链

### 完成判定

- 拆书模式已在 core 中有正式入口
- 结构化提取结果能映射到现有资产体系

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 28 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/absorption/10-projects/book-os/README.md、docs/absorption/10-projects/ai-novel/README.md、docs/major-redesign-master-plan.md。正式建立拆书模式的 core 入口：定义拆书任务输入、结构化提取结果、应用计划，并把拆书项目类型/模式入口立到领域层，让结果能映射到现有资产体系。注意先做领域合同，不要先堆 UI，也不要写死到某个供应商响应格式。
```

### 完成记录

- 已完成 `Session 28`
- core 已新增独立 `deconstruction` 子域：
  - `BookDeconstructionInput`
  - `BookDeconstructionSourceDocument`
  - `BookDeconstructionExtractionResult`
  - `BookDeconstructionChapterOutline`
  - `BookDeconstructionApplicationItem`
  - `BookDeconstructionApplicationPlan`
  - `BookDeconstructionTargetPathService`
  - `BookDeconstructionAssetMappingService`
  - `BookDeconstructionApplicationPlanBuilderService`
- 已新增 GUI / CLI 共用正式入口：
  - `BuildBookDeconstructionApplicationPlanUseCase`
- 当前已经明确：
  - 拆书结果先收束成结构化提取结果，再映射为应用计划
  - 应用计划只表达“可应用到哪里”，不直接承担写盘或覆盖冲突决策
  - 前提、总纲、章纲和共享资产已统一映射回现有目录体系：
    - `premise/`
    - `outlines/story/`
    - `outlines/chapters/`
    - `assets/styles/`
    - `assets/world/`
    - `assets/characters/`
    - `assets/organizations/`
    - `assets/foreshadows/`
    - `assets/timeline/`
    - `assets/relationships/`
  - 拆书不再只是策略字符串：
    - `ProjectTypeCatalogService` 已正式登记 `book_deconstruction`
    - `StrategyCatalogService` 已正式登记：
      - `book_deconstruction` project strategy
      - `book_asset_extraction` mode definition
  - 拆书项目不会误走长任务运行基准选择

本轮验证结果：

- `packages/novel_agent_core`
  - `dart test test/book_deconstruction_application_plan_builder_service_test.dart test/create_project_workspace_use_case_test.dart`
  - 通过
- `packages/novel_agent_core`
  - `dart analyze lib/novel_agent_core.dart lib/src/project/project_type_catalog_service.dart lib/src/strategy/strategy_catalog_service.dart lib/src/use_cases/update_project_manifest_use_case.dart test/book_deconstruction_application_plan_builder_service_test.dart test/create_project_workspace_use_case_test.dart`
  - 通过
- `packages/novel_agent_core`
  - `dart analyze lib/src/deconstruction lib/src/use_cases/build_book_deconstruction_application_plan_use_case.dart`
  - 通过

当前为后续保留的明确扩展点：

- `BookDeconstructionExtractionResult`
  - 后续可继续接更细的章节片段、主题母题、场景组块，而不破坏当前应用计划合同
- `BookDeconstructionApplicationPlan`
  - 后续可继续接冲突预检、覆盖策略和用户选择结果，但不应回流污染提取层对象
- `BookDeconstructionTargetPathService`
  - 后续若目录策略继续调整，只改这一层即可，不需要重写映射服务或 UI 预览

## 17. Session 29：拆书导入向导与结构化预览 UI

### 本轮目标

在已有拆书 core 入口基础上，接最小可用 GUI 向导。

### 预计改动量

- 约 `1000 ~ 1700` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/absorption/10-projects/writingway/README.md`
- `docs/responsibility-matrix.md`

### 必须完成

1. 拆书导入入口
2. 结构化预览
3. 选择应用到哪些资产
4. 应用前确认

### 本轮重点拆耦

- 向导状态 controller 独立
- 结构化结果 view data 独立
- 不把解析逻辑塞进页面

### 本轮不要做

- 不做最终视觉大统一
- 不做所有文件格式适配
- 不做高阶编辑器

### 完成判定

- 用户可以在 GUI 里走完拆书导入到结构化预览的最小流程

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 29 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/absorption/10-projects/writingway/README.md、docs/responsibility-matrix.md。在已有拆书 core 入口基础上做最小可用 GUI 向导：拆书导入、结构化预览、选择应用到哪些资产、应用前确认。注意向导状态 controller、结构化结果 view data、解析逻辑三者拆开，不追求最终视觉统一。
```

### 完成记录

- 已完成 `Session 29`
- app 已新增独立 `book_deconstruction` 子域：
  - `application/controllers/BookDeconstructionController`
  - `application/services/BookDeconstructionDraftBuilderService`
  - `application/services/BookDeconstructionPreviewMarkdownService`
  - `application/services/BookDeconstructionViewDataService`
  - `application/services/DesktopBookDeconstructionSourcePickerService`
  - 独立 page / widgets / presentation models / action contract
- 当前已经明确：
  - 拆书向导状态、结构化投影、源文本草稿构建三层已拆开
  - 页面只消费 `BookDeconstructionViewData`，不直接拼装 core 提取结果
  - 桌面端支持原生文件选择导入，移动端保留手动粘贴入口，不强绑额外权限
  - 结构化预览会按：
    - 前提
    - 故事总纲
    - 章节骨架
    - 风格 / 世界 / 角色 / 组织
    分区展示
  - 应用计划会按目标资产种类分组勾选，不把路径推导逻辑塞进 widget
  - 当前“应用前确认”先写入：
    - `analysis/book_deconstruction_preview.md`
    作为稳定预演纪要，后续真实 apply 链可直接复用这份合同继续往下接
  - 资产路径已修正为保留中文显示映射所需的可读 ID，不再把中文名压成 `_`

本轮验证结果：

- `apps/novel_agent_app`
  - `flutter test test/book_deconstruction_draft_builder_service_test.dart test/book_deconstruction_controller_test.dart test/inspiration_workbench_controller_test.dart`
  - 通过
- `apps/novel_agent_app`
  - `dart analyze lib/features/book_deconstruction lib/app/routing lib/app/state/app_shell_destination_controller.dart lib/app/state/app_shell_controller.dart lib/features/workbench/application/controllers/workbench_conversation_controller.dart test/book_deconstruction_draft_builder_service_test.dart test/book_deconstruction_controller_test.dart`
  - 通过
- `packages/novel_agent_core`
  - `dart analyze lib/src/deconstruction lib/src/session/session_guide_profile_service.dart`
  - 通过

当前为后续保留的明确扩展点：

- `BookDeconstructionDraftBuilderService`
  - 后续可替换成真正的多格式解析 / LLM 提取链，而不破坏当前向导状态与视图层
- `BookDeconstructionPreviewMarkdownService`
  - 后续可继续被真实 apply 前确认、导出预览、审计回放复用
- `DesktopBookDeconstructionSourcePickerService`
  - 后续若引入正式跨平台文件选择器，可只替换这一层，不影响 controller / page

## 18. Session 30：统一工作台 / 中心页 UI 规划与分层改造

### 本轮目标

在前面核心链和主要功能入口都接通后，统一规划真正合理的 UI。

### 预计改动量

- 约 `1500 ~ 2200` 行

### 必读文档

- `docs/absorption/10-projects/writingway/README.md`
- `docs/absorption/10-projects/mumuainovel/README.md`
- `docs/absorption/10-projects/deepseek-tui/README.md`
- `docs/architecture.md`
- `docs/responsibility-matrix.md`

### 必须完成

1. 统一规划并落地：
   - 工作台
   - 长任务总站
   - 资产中心
   - 分析 / 重写页
   - 灵感工作台
2. 重点做信息架构、分区、联动与密度，不追求花哨
3. 保持 controller / page / widget / view data 分层干净

### 本轮重点拆耦

- 布局策略服务独立
- 子域 controller 不合并回壳层
- 页面壳与具体子控件继续分层

### 本轮不要做

- 不顺手改 provider
- 不动底层文件协议
- 不把视觉改造变成业务重构

### 完成判定

- 主要工作域的 UI 信息架构已经统一
- 不再出现“功能虽有，但入口散、密度乱、控制器回堆”的情况

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 30 执行。先阅读 docs/absorption/10-projects/writingway/README.md、docs/absorption/10-projects/mumuainovel/README.md、docs/absorption/10-projects/deepseek-tui/README.md、docs/architecture.md、docs/responsibility-matrix.md。在前面核心链和主要功能入口都接通后，统一规划并落地工作台、长任务总站、资产中心、分析/重写页、灵感工作台的 UI 信息架构，重点做分区、联动、密度与入口清晰度，不追求花哨。注意继续保持 controller / page / widget / view data 分层，不要把子域 controller 合并回壳层。
```

### 完成记录

- 已完成 `Session 30`
- app 壳层已新增独立导航子域：
  - `app/navigation/AppShellNavigationActionHandler`
  - `AppShellNavigationCatalog`
  - `AppShellNavigationItem`
  - `AppShellNavigationSection`
  - `shared/widgets/AppShellActivityRail`
- 当前已经明确：
  - 桌面与宽屏布局不再只是“整页切换”，而是正式拥有全局活动栏入口
  - 全局入口已按职责收束为：
    - 项目
    - 创作
    - 运行
    - 资产
    - 系统
  - 导航分发统一经过 `AppShellDestinationController.showDestination(...)`
  - `AppShellController` 只承担壳层导航委派，不吸收新的子域业务状态
- app 已新增共享工作域页面骨架：
  - `WorkspacePageHeader`
  - `WorkspacePageScaffold`
  - `WorkspacePaneLayout`
- 当前已接入统一信息架构的页面：
  - 长任务总站
  - 项目资产中心
  - 灵感工作台
  - 拆书导入向导
  - 审稿中心
  - 任务中心
  - 模板中心
- 这轮统一后的 UI 方向是：
  - 壳层统一导航
  - 页面统一标题/状态/加载条
  - 中心页统一两栏/三栏自适应骨架
  - 继续维持 controller / page / widget 分层，不回堆 `AppShellController`

本轮验证结果：

- `apps/novel_agent_app`
  - `dart analyze lib/app/navigation lib/shared/widgets/app_shell.dart lib/shared/widgets/app_shell_activity_rail.dart lib/shared/widgets/workspace_page_header.dart lib/shared/widgets/workspace_page_scaffold.dart lib/shared/widgets/workspace_pane_layout.dart lib/app/state/app_shell_destination_controller.dart lib/app/state/app_shell_controller.dart lib/features/long_task_station/presentation/pages/long_task_station_page.dart lib/features/long_task_station/presentation/widgets/long_task_station_toolbar.dart lib/features/project_assets/presentation/pages/project_assets_page.dart lib/features/project_assets/presentation/widgets/project_assets_toolbar.dart lib/features/inspiration_workbench/presentation/pages/inspiration_workbench_page.dart lib/features/inspiration_workbench/presentation/widgets/inspiration_workbench_toolbar.dart lib/features/book_deconstruction/presentation/pages/book_deconstruction_page.dart lib/features/book_deconstruction/presentation/widgets/book_deconstruction_toolbar.dart lib/features/review_center/presentation/pages/review_center_page.dart lib/features/task_center/presentation/pages/task_center_page.dart lib/features/prompt_templates/presentation/pages/prompt_templates_page.dart`
  - 通过
- `apps/novel_agent_app`
  - `flutter test test/widget_test.dart test/book_deconstruction_controller_test.dart test/inspiration_workbench_controller_test.dart`
  - 通过

当前为后续保留的明确扩展点：

- `AppShellActivityRail`
  - 后续可继续接移动端抽屉 / 紧凑导航，而不需要回改各业务页
- `WorkspacePaneLayout`
  - 后续可继续细化为更强的双栏/三栏策略与拖拽分栏，而不需要重写各中心页
- `WorkspacePageScaffold`
  - 后续可继续接统一状态条、错误态和页面级命令区，而不污染子域控制器

## 19. Session 31：总回归、探针、Windows 打包与文档回填

### 本轮目标

做一轮以真实可用性为目标的总回归。

### 预计改动量

- 约 `800 ~ 1500` 行

### 必读文档

- `docs/migration-progress.md`
- `docs/remaining-implementation-session-order.md`
- `docs/provider-compatibility-baseline.md`

### 必须完成

1. 跑关键探针：
   - 技能路由
   - 长任务真实链
   - review / repair
   - 资产导入导出
   - 分析 -> 重写
2. 修回归暴露的问题，但不再开新主线
3. Windows 打包
4. 回填：
   - `docs/migration-progress.md`
   - 本顺序文档
   - 必要的能力分类 / 责任矩阵

### 本轮重点拆耦

- 只修联调问题
- 不借回归之名大改架构

### 本轮不要做

- 不开新主线
- 不临时扩张需求

### 完成判定

- 关键链路有探针或真实验证结果
- Windows 包可交付测试
- 文档状态与代码状态一致

### 建议提示词

```text
按 docs/remaining-implementation-session-order.md 的 Session 31 执行。先阅读 docs/migration-progress.md、docs/remaining-implementation-session-order.md、docs/provider-compatibility-baseline.md。做总回归：跑技能路由、长任务真实链、review/repair、资产导入导出、分析->重写等关键探针，只修联调暴露的问题，不开新主线。完成后打包 Windows 版，并回填 migration-progress 和本顺序文档。
```

### 完成记录

- 已完成 `Session 31`
- 本轮只修联调与探针回归，没有新开功能主线
- 已修复两处真实回归：
  - `apps/novel_agent_cli/tool/workflow_resolution_cli_probe.dart`
    - 不再把 checkpoint / revision 动作写死成固定命令
    - 现在会先读取动作包，优先应用 `recommended_action_id`，否则回退到第一条 `enabled` 动作
    - 这样 CLI 探针验证的是“共享动作合同是否可消费”，而不是旧命令名是否恰好可用
  - `apps/novel_agent_app/tool/real_long_task_probe.dart`
    - 不再强依赖 `temp/novel_agent_settings.json`
    - 已接回统一 `probe_support.dart` 的配置读取逻辑
    - 现在与其他真实探针一致，优先读 `test_api.txt`，回退读 `temp/novel_agent_settings.json`
- 本轮关键验证结果：
  - `packages/novel_agent_core`
    - `dart test test/skill_routing_policy_service_test.dart test/draft_generation_use_case_test.dart test/review_report_chapter_analysis_projection_service_test.dart test/chapter_analysis_services_test.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart test test/project_bundle_library_services_test.dart test/project_long_task_review_repair_task_service_test.dart test/project_chapter_rewrite_task_service_test.dart`
    - 通过
  - `apps/novel_agent_app`
    - `dart run tool/all_tools_probe.dart`
    - `35/35` 通过
  - `apps/novel_agent_app`
    - `dart run tool/seed_autopilot_review_repair_probe.dart`
    - `PASS`
  - `apps/novel_agent_app`
    - `dart run tool/seed_autopilot_revision_resolution_probe.dart`
    - `PASS`
  - `apps/novel_agent_cli`
    - `dart run tool/workflow_resolution_cli_probe.dart`
    - `PASS`
  - `apps/novel_agent_app`
    - `dart run tool/real_long_task_probe.dart`
    - `PASS`
  - `apps/novel_agent_app`
    - `flutter build windows --release`
    - 通过，产物：
      - `apps/novel_agent_app/build/windows/x64/runner/Release/novel_agent_app.exe`
- 本轮新增验证产物：
  - `apps/novel_agent_cli/artifacts/workflow_resolution_cli_probe_report.json`
  - `artifacts/real_long_task_probe_report.json`
- 当前这份顺序文档中的 Session 17 ~ 31 已全部完成；后续若继续推进，应另开新的剩余实现顺序文档，而不是回头重开本文件中的旧 session

## 20. 当前推荐起点

如果现在开始继续动工，建议优先从：

1. Session 18：章节字数分布策略
2. Session 19：`constitution / guidance / style` 三层正式收束
3. Session 20：角色卡运行主链收束

开始。

这是因为：

- 它们会直接影响后续生成稳定性
- 也会决定后续角色卡、伏笔回填、漂移控制该怎么接
- 如果这几条不先收紧，后面 UI 做得再漂亮，底下也还是漂的
