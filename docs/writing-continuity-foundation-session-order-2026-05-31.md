# NovelAgentFlutter 写作连续性基础与拆书派生承接任务顺序文档

最后更新：2026-05-31

关联文档：

- `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
- `docs/long-task-mode-1-architecture.md`
- `docs/long-task-runtime-observability-session-order-2026-05-31.md`
- `docs/writing-model-registry-session-order-2026-05-30.md`
- `references/MuMuAINovel-main`

关联代码锚点：

- `packages/novel_agent_core/lib/src/assets/character_profile.dart`
- `packages/novel_agent_core/lib/src/assets/world_rule_set.dart`
- `packages/novel_agent_core/lib/src/assets/timeline_record.dart`
- `packages/novel_agent_core/lib/src/assets/foreshadow_record.dart`
- `packages/novel_agent_core/lib/src/assets/relationship_record.dart`
- `packages/novel_agent_core/lib/src/assets/character_stage_state_record.dart`
- `packages/novel_agent_core/lib/src/assets/character_state_update_request.dart`
- `packages/novel_agent_core/lib/src/assets/timeline_state_update_request.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_extraction_result.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_application_plan.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_mode_context_path_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_project_file_section_plan_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_timeline_repository.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_timeline_state_update_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_character_runtime_state_repository.dart`
- `apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`
- `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart`

---

## 1. 这份文档解决什么

这一轮不是继续把“拆书续写”当成一个孤立功能补丁，而是要把它收束成：

**整个写作系统共享的连续性基础设施 + 拆书作为其中一条高密度输入与派生链。**

完成这份文档对应的全部 session 后，目标应当是：

1. 一般项目和拆书项目都能落到同一套连续性底座
2. 系统能正式表达：
   - 事实在哪个作用域生效
   - 事实如何跨阶段、跨世界、跨回档点连续或重置
3. 拆书不再只是结构化资产预览，而能稳定产出可继续创作的续写基座
4. 拆书后续菜单成为完整工程菜单，但底层仍保持“源工程 / 基座构建 / 派生执行项目”分层
5. 长任务、普通续写、未来特殊写作路线都复用同一 continuity runtime，而不是各自再造一套

这份文档要解决的，不是某一个题材的特例，而是整个写作工程面对以下情形时的正式能力：

- 普通单线长篇
- 多世界 / 快穿
- 死亡回归 / 回档 / 读档恢复
- 梦境线 / 幻境线 / 支线分叉
- 拆书后的超长篇承接

---

## 2. 旧判断冲突修正

如果过去文档或讨论里的说法与当前分析冲突，以本节为准。

### 2.1 共享基础优先于拆书专属命名

过去分析里出现过 `DeconstructionContinuationPackage` 这类命名。

现在统一修正为：

1. 共享核心对象优先使用中性命名，例如：
   - `ProjectContinuityBundle`
   - `ContinuationScope`
   - `ContinuityMechanicProfile`
   - `ContinuityFrame`
2. 拆书专属对象只负责：
   - hints
   - extraction
   - derivation
3. 不把“continuity layer”继续命名成看起来只属于拆书的子系统

### 2.2 “拆完再选路线”修正为“创建时选主目标方向，完成后仍可重分流”

如果过去有“必须拆完以后再决定后续路线”的说法，这里修正为混合方案：

1. 创建拆书承接源工程时，只记录：
   - `主目标方向 / 默认导向`
2. 拆书与基座构建会按该导向准备默认资源
3. 拆书完成后仍保留完整后续工程菜单
4. 真正的执行项目类型只在派生时最终确定

也就是：

- 创建时不是先建最终执行项目
- 也不是完全没有方向
- 而是先定默认导向，再保留后续多路派生能力

### 2.3 “分析长任务”修正为“续写基座构建流程”

过去如果把拆书后的前置资源构建直接叫“分析长任务”，这里统一修正：

1. 产品语义上不叫“分析长任务”
2. 正式名称应是：
   - `续写基座构建`
   - 或 `连续性基座构建`
3. 它可以复用长流程、可恢复、检查点等 runtime 能力
4. 但产品语义上不能和正式写作长任务混为一谈

### 2.4 不把快穿、死亡回归等写死成题材枚举

过去如果有“先支持快穿 / 多世界”这种偏题材化表述，这里统一修正为：

1. `作用域覆盖系统` 负责回答“哪里生效”
2. `连续性机制系统` 负责回答“怎么连续 / 回滚 / 分叉 / 保留”
3. 快穿、回档、梦境线等只是不同策略组合，不应成为核心代码里的硬编码题材分支

---

## 3. 已有实现去重审计

后续执行本顺序文档时，必须先承认下面这些已经存在，避免重复造轮子。

### 3.1 已有结构化事实层，不要重建第二套角色卡/世界卡

这些文件已经提供了当前系统最值得复用的 canonical-ish 资产：

1. `CharacterProfile`
2. `WorldRuleSet`
3. `TimelineRecord`
4. `ForeshadowRecord`
5. `RelationshipRecord`
6. `CharacterStageStateRecord`
7. `CharacterStateUpdateRequest`
8. `TimelineStateUpdateRequest`

后续要做的不是复制出一套新的“连续性角色卡”，而是：

1. 明确哪些字段属于全局稳定事实
2. 增加作用域覆盖与连续性解析层
3. 让现有资产能被 scope / frame 正式挂接

### 3.2 已有状态落盘与更新通路，不要重写 runtime state 仓储

下面这些已经是很好的持久化基础：

1. `ProjectTimelineRepository`
2. `ProjectTimelineStateUpdateService`
3. `ProjectCharacterRuntimeStateRepository`
4. 相关 structured memory tool executor / state update service

后续需要补的是：

1. continuity bundle 的仓储与路径策略
2. 作用域/帧解析的读取层
3. 由 continuity runtime 驱动的上下文装配

不是把 timeline / character runtime repository 推翻重写。

### 3.3 已有拆书抽取与应用计划，不要再造第二条 preview/apply 链

这些已经存在：

1. `BookDeconstructionExtractionResult`
2. `BookDeconstructionAssetMappingService`
3. `BookDeconstructionApplicationPlanBuilderService`
4. `BookDeconstructionController`
5. 现有 preview / confirm / apply UI 节奏

后续应当新增的是：

1. 拆书 continuity hints
2. 基座构建规格
3. 派生执行项目计划

不是重新发明一条平行的拆书确认流程。

### 3.4 已有长任务上下文与漂移检测骨架，不要另造“续写专用长任务”

这些可复用：

1. `LongTaskModeContextPathService`
2. `LongTaskProjectFileSectionPlanService`
3. 各类 drift signal service
4. long-task runtime / checkpoint / resume 基础

后续要做的是：

1. 让这些服务能吃 continuity bundle / active frame / scope overlays
2. 把 continuity facts 接入已有长任务上下文规划

不是造一个新的“拆书续写专用 runtime”。

---

## 4. 本轮冻结的架构边界

### 4.1 continuity layer 是共享核心层，不放在 deconstruction feature 里做主实现

共享核心职责应落在新的 core continuity 目录，例如：

- `packages/novel_agent_core/lib/src/continuity/*`

拆书目录只保留：

- extraction hints
- source mapping
- derivation planning

### 4.2 作用域系统与连续性机制系统必须分开

至少要拆成两类对象：

1. 作用域层
   - scope tree
   - overlay priority
   - active scope chain
2. 连续性机制层
   - reset / carry-over / fork / overwrite policy
   - memory visibility
   - identity continuity
   - branch semantics

禁止把这两类规则揉进一个巨型对象或单个 service。

### 4.3 一般项目与拆书项目共享 runtime contract

不能出现：

1. 一般项目一套 continuity 运行链
2. 拆书项目另一套 continuity 运行链

正确关系应是：

1. 一般项目可以直接声明或逐步积累 continuity facts
2. 拆书项目只是额外拥有一条“从既有作品提取 continuity hints”的输入路径
3. 两者最终都进入同一套 runtime resolver

### 4.4 默认体验低心智负担，高级机制只在需要时显露

产品层不直接暴露大量底层术语。

默认应优先用用户能理解的话表达：

- 世界
- 卷 / 阶段
- 路线
- 回档点
- 当前承接线

高级设置里才出现更正式的 continuity / scope / frame 术语。

### 4.5 不允许单一文件继续变成“连续性总控中心”

后续实现时：

1. pure contracts 在 core model 文件
2. resolver 在独立 service 文件
3. repository / path policy 在 adapters
4. view-data / orchestration 在 app

不得把：

- scope 规则
- frame 规则
- build spec
- deconstruction mapping
- UI projection

全塞进一个 manager/controller/service 文件。

---

## 5. 责任落点建议

### 5.1 Core 层

建议新增目录：

- `packages/novel_agent_core/lib/src/continuity/`

共享核心职责放这里：

1. continuity contracts
2. scope / overlay contracts
3. mechanic / frame contracts
4. runtime resolver
5. bundle build spec contracts
6. context assembly contracts
7. derived project plan contracts

### 5.2 Core 的 deconstruction 子域

继续放在：

- `packages/novel_agent_core/lib/src/deconstruction/`

只负责：

1. 从拆书结果提 continuity hints
2. 拆书 source facts 与 continuity facts 的映射
3. 拆书派生执行项目计划

### 5.3 Adapters 层

建议新增：

- `packages/novel_agent_adapters/lib/src/continuity/`
- 或 `packages/novel_agent_adapters/lib/src/storage/continuity/`

只负责：

1. continuity bundle 持久化
2. scope/frame 文档读写
3. continuation package 路径策略
4. 基座构建记录与派生计划落盘
5. 从项目工作区读取 continuity runtime 输入

### 5.4 App 层

建议职责拆分为：

1. `book_deconstruction`
   - 源工程创建
   - preview / confirm / build / derive 节奏
2. `project creation`
   - 主目标方向与默认构建规格输入
3. `general writing settings / workbench`
   - 一般项目 continuity 基础设置与轻量编辑
4. `long task`
   - continuity runtime 可视化与调试信息消费

不要把 continuity 的主业务算法写进 widget 或 controller。

---

## 6. 推荐最终核心对象

这一节是后续实现时的目标合同，不要求一轮做完，但顺序必须围绕它收口。

### 6.1 共享 continuity facts

建议首批对象：

1. `ProjectContinuityBundle`
2. `ContinuationScope`
3. `ContinuationScopeOverlay`
4. `ContinuityMechanicProfile`
5. `ContinuityFrame`
6. `ContinuityBuildSpec`
7. `ContinuityCoverage`
8. `ContinuityHint`

### 6.2 runtime 解析对象

建议新增：

1. `ActiveContinuityFrame`
2. `ActiveScopeChain`
3. `ContinuityResolutionResult`
4. `ContinuityContextSelection`
5. `ContinuityRuntimeDefaults`

### 6.3 拆书专属对象

建议新增：

1. `BookDeconstructionContinuityHints`
2. `BookDeconstructionScopeMap`
3. `BookDeconstructionIdentityMappingHints`
4. `BookDeconstructionMechanicHints`
5. `BookDeconstructionDerivedProjectPlan`

### 6.4 不建议直接新增的对象

下面这些方向应避免：

1. 巨大的 `ContinuityManager`
2. UI 直连 JSON 的 `continuity_settings_blob`
3. 把普通项目和拆书项目揉在一起的 `BookContinuationProjectController`

---

## 7. 总规则

后续每个 session 都必须遵守：

1. 每次只完成一个具体任务
2. 如果上一轮卡在半截或出现关联错误，先收口，不开下一轮
3. 先做 core contracts，再做 adapters，再做 runtime integration，最后接 app/front-end
4. 不复制现有资产模型，优先做挂接与扩展
5. 不把 continuity 规则写进 widget、本地页面状态或单个 controller
6. 不把“快穿 / 回档 / 梦境”做成硬编码题材 if/else
7. 一般项目必须始终是第一等公民，不能让 continuity 只在拆书项目里可用
8. 拆书源工程、续写基座构建、派生执行项目必须分层，不得混成一个项目语义
9. 每轮都要补 focused test、probe 或明确说明为何本轮只做文档/合同
10. 完成记录要回填本文，不要只在会话里口头说明

---

## 8. Session 列表

---

## 8.1 Session WCF-01：建立共享 continuity core 合同

### 本轮目标

先在 core 中正式建立 continuity layer 的共享合同与目录，不接拆书、不接 UI。

### 必读文件

- `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
- `packages/novel_agent_core/lib/src/assets/character_profile.dart`
- `packages/novel_agent_core/lib/src/assets/world_rule_set.dart`
- `packages/novel_agent_core/lib/src/assets/character_stage_state_record.dart`
- `packages/novel_agent_core/lib/src/assets/timeline_record.dart`

### 必须完成

1. 新增 `src/continuity/` 目录
2. 建立首批共享合同：
   - `ProjectContinuityBundle`
   - `ContinuationScope`
   - `ContinuationScopeOverlay`
   - `ContinuityMechanicProfile`
   - `ContinuityFrame`
   - `ContinuityCoverage`
3. 明确这些合同与现有资产模型的关系：
   - 哪些是引用
   - 哪些是 overlay
   - 哪些是 runtime state
4. 导出公共入口，但不接 app
5. 补 focused test 或纯模型 contract test

### 本轮不要做

- 不动拆书抽取
- 不动 adapters
- 不接 long-task
- 不做 UI

### 重点拆耦

- continuity contracts
- existing asset references
- future runtime resolver

### 完成判定

- core 中已经有可复用的 continuity 基础合同
- 后续不需要再把 continuity 定义散落到 deconstruction / workflow / app 各处

### 直接可用提示词

```text
按 docs/writing-continuity-foundation-session-order-2026-05-31.md 的 Session WCF-01 执行。只在 core 新建 continuity 共享合同与目录，建立 ProjectContinuityBundle、ContinuationScope、ContinuationScopeOverlay、ContinuityMechanicProfile、ContinuityFrame、ContinuityCoverage 等基础类型，并明确它们与现有资产模型的引用关系。不要改拆书、adapters、long-task 和 UI，不开启下一任务。
```

### 本轮完成记录

1. 已在 `packages/novel_agent_core/lib/src/continuity/` 新增共享 continuity contracts：
   - `continuity_asset_reference.dart`
   - `continuation_scope.dart`
   - `continuation_scope_overlay.dart`
   - `continuity_coverage.dart`
   - `continuity_mechanic_profile.dart`
   - `continuity_frame.dart`
   - `project_continuity_bundle.dart`
2. 已建立首批共享合同：
   - `ProjectContinuityBundle`
   - `ContinuationScope`
   - `ContinuationScopeOverlay`
   - `ContinuityMechanicProfile`
   - `ContinuityFrame`
   - `ContinuityCoverage`
3. 已把“与现有资产模型的关系”直接落进合同结构：
   - `canonicalAssetReferences` 表达全局稳定事实引用
   - `ContinuationScopeOverlay.assetReferences` 表达作用域覆盖引用
   - `ContinuityFrame.stateReferences` 表达帧级运行状态引用
4. `ContinuityAssetReference` 当前支持引用现有核心资产类型：
   - `CharacterProfile`
   - `CharacterStageStateRecord`
   - `ForeshadowRecord`
   - `OrganizationProfile`
   - `RelationshipRecord`
   - `StyleProfile`
   - `TimelineRecord`
   - `WorldRuleSet`
5. `ContinuityMechanicProfile` 已先把连续性机制的核心政策维度显式化：
   - identity
   - memory
   - state
   - causal
   - branch
   - visibility
6. 已导出 root library 入口：
   - `packages/novel_agent_core/lib/novel_agent_core.dart`
7. 已补 focused contract test：
   - `packages/novel_agent_core/test/continuity_contract_models_test.dart`
   - 覆盖：
     - 全局事实引用
     - 作用域覆盖引用
     - 帧级运行状态引用
     - 普通单线项目的保守默认值
8. 本轮刻意未做：
   - 未实现 resolver
   - 未实现 normalizer / codec
   - 未接 deconstruction
   - 未接 adapters
   - 未接 long-task
   - 未接 UI
9. 已验证：
   - `dart format lib/src/continuity/continuity_asset_reference.dart lib/src/continuity/continuation_scope.dart lib/src/continuity/continuation_scope_overlay.dart lib/src/continuity/continuity_coverage.dart lib/src/continuity/continuity_mechanic_profile.dart lib/src/continuity/continuity_frame.dart lib/src/continuity/project_continuity_bundle.dart lib/novel_agent_core.dart test/continuity_contract_models_test.dart`
   - `dart analyze lib/src/continuity/continuity_asset_reference.dart lib/src/continuity/continuation_scope.dart lib/src/continuity/continuation_scope_overlay.dart lib/src/continuity/continuity_coverage.dart lib/src/continuity/continuity_mechanic_profile.dart lib/src/continuity/continuity_frame.dart lib/src/continuity/project_continuity_bundle.dart lib/novel_agent_core.dart test/continuity_contract_models_test.dart`
   - `dart test test/continuity_contract_models_test.dart`

---

## 8.2 Session WCF-02：建立 continuity runtime resolver

### 本轮目标

在 core 建立 active scope / active frame / continuity resolution 的正式解析链。

### 必读文件

- WCF-01 新增 continuity contracts
- `packages/novel_agent_core/lib/src/assets/character_stage_state_record.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_mode_context_path_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_project_file_section_plan_service.dart`

### 必须完成

1. 新增 runtime 解析服务，例如：
   - `continuity_runtime_resolver_service.dart`
   - `active_scope_chain_service.dart`
2. 支持：
   - scope overlay 合并
   - frame inheritance / reset / fork 规则
   - identity continuity
   - memory/state visibility 基本判断
3. 输出结构化 `ContinuityResolutionResult`
4. 先不管拆书输入来源，先只做纯 resolver
5. 补 focused test：
   - 单线默认连续
   - world overlay 覆盖
   - fork frame
   - reset frame

### 本轮不要做

- 不接 adapters 仓储
- 不接 deconstruction
- 不接 app

### 重点拆耦

- scope resolution
- mechanic resolution
- context selection

### 完成判定

- 系统已经能回答“当前在哪条 continuity frame 上，哪些事实生效”

### 直接可用提示词

```text
按 docs/writing-continuity-foundation-session-order-2026-05-31.md 的 Session WCF-02 执行。只在 core 建立 continuity runtime resolver，支持 scope overlay、frame 继承/重置/分叉、identity continuity 和基本可见性判断，并补 focused test。不要接 adapters、拆书和 UI，不开启下一任务。
```

### 本轮完成记录

1. 已在 `packages/novel_agent_core/lib/src/continuity/` 新增 runtime 解析相关对象：
   - `active_scope_chain.dart`
   - `active_continuity_frame.dart`
   - `continuity_resolution_result.dart`
   - `continuity_runtime_resolver_service.dart`
2. 已建立首版 continuity runtime resolver：
   - `ContinuityRuntimeResolverService.resolve(...)`
   - 输入 `ProjectContinuityBundle`
   - 支持可选：
     - `frameId`
     - `scopeId`
     - `mechanicProfileId`
3. 当前 resolver 已正式输出：
   - `ActiveScopeChain`
   - `ActiveContinuityFrame`
   - `ContinuityResolutionResult`
4. 已实现首版作用域解析：
   - 按当前 frame 或显式 scope 解析 active scope
   - 构建从父到子的 scope chain
   - 按 scope chain 顺序收集 overlay asset references
5. 已实现首版 frame 解析：
   - 按显式 `frameId`、bundle 默认 frame、scope 命中、首个 frame 的顺序选择 active frame
   - 构建从父到子的 frame chain
6. 已实现首版 mechanic profile 选择：
   - 显式 `mechanicProfileId`
   - frame 自带 mechanic profile
   - bundle 默认 mechanic profile
   - 最后回退到保守 default profile
7. 已实现本轮约定的最小继承/重置规则：
   - `reset` / `overwrite` frame 不继承父状态
   - `reset` / `overwrite` frame 不继承父记忆
   - 其他 relation 在 `stateMode != resetPerFrame` 时继承父状态
   - 其他 relation 在 `memoryMode != resetPerFrame` 时继承父记忆
   - `fork` 或 `branchMode == forkOnTransition` 会标记 `branchesFromParent`
   - `replay` 或 `causalMode == replayAware` 会标记 `replayAware`
8. `ContinuityResolutionResult` 当前已提供：
   - `canonicalAssetReferences`
   - `overlayAssetReferences`
   - `stateAssetReferences`
   - `effectiveAssetReferences`
   - `inheritsParentState`
   - `inheritsParentMemory`
   - `branchesFromParent`
   - `replayAware`
9. 已导出 root library 入口：
   - `ActiveScopeChain`
   - `ActiveContinuityFrame`
   - `ContinuityResolutionResult`
   - `ContinuityRuntimeResolverService`
10. 已补 focused test：
    - `packages/novel_agent_core/test/continuity_runtime_resolver_service_test.dart`
    - 覆盖：
      - 普通单线默认连续
      - world overlay 作用域覆盖
      - fork frame 继承父状态
      - reset frame 丢弃父状态与父记忆
11. 本轮刻意未做：
    - 未实现 codec / normalizer
    - 未实现持久化仓储
    - 未接 deconstruction continuity hints
    - 未接 long-task context path / section plan
    - 未做更细的 visibility filtering / identity mapping 解析细则
12. 已验证：
    - `dart format lib/src/continuity/active_scope_chain.dart lib/src/continuity/active_continuity_frame.dart lib/src/continuity/continuity_resolution_result.dart lib/src/continuity/continuity_runtime_resolver_service.dart lib/novel_agent_core.dart test/continuity_runtime_resolver_service_test.dart`
    - `dart analyze lib/src/continuity/active_scope_chain.dart lib/src/continuity/active_continuity_frame.dart lib/src/continuity/continuity_resolution_result.dart lib/src/continuity/continuity_runtime_resolver_service.dart lib/novel_agent_core.dart test/continuity_runtime_resolver_service_test.dart`
    - `dart test test/continuity_contract_models_test.dart test/continuity_runtime_resolver_service_test.dart`

---

## 8.3 Session WCF-03：把 continuity bundle 落入 adapters 持久化链

### 本轮目标

建立 continuity bundle / scope / frame / build spec 的仓储与路径策略。

### 必读文件

- `packages/novel_agent_adapters/lib/src/storage/project_timeline_repository.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_timeline_state_update_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_character_runtime_state_repository.dart`
- WCF-01 / WCF-02 新增 continuity contracts 与 resolver

### 必须完成

1. 新增 continuity 路径策略与仓储
2. 设计最小持久化布局，例如：
   - `tracking/continuity/bundle.json`
   - `tracking/continuity/scopes/*.json`
   - `tracking/continuity/frames/*.json`
   - `analysis/continuity/*.md`
3. 建立 codec / normalizer
4. 不复制 timeline/character runtime 存储，只做 continuity 层自己的持久化
5. 补 adapters focused test

### 本轮不要做

- 不接拆书 controller
- 不接 project creation UI
- 不接 long-task runtime

### 重点拆耦

- continuity persistence
- existing asset repositories
- runtime consumption boundary

### 完成判定

- continuity layer 已经有稳定、可恢复、可派生的工作区事实源

### 直接可用提示词

```text
按 docs/writing-continuity-foundation-session-order-2026-05-31.md 的 Session WCF-03 执行。只在 adapters 建立 continuity bundle/scopes/frames/build spec 的持久化仓储、路径策略与 codec，复用现有项目工作区与已有资产仓储，不要接 UI 和 long-task，不开启下一任务。
```

### 本轮完成记录

1. 为了承接 `WCF-03` 的 build spec 持久化需求，已在 core 先补最小合同：
   - `packages/novel_agent_core/lib/src/continuity/continuity_build_spec.dart`
2. `ContinuityBuildSpec` 当前只承担持久化与后续扩展承载，不提前写死 `WCF-07` 的三档语义。
3. 已在 adapters 新增 continuity 路径策略：
   - `packages/novel_agent_adapters/lib/src/storage/project_continuity_path_policy.dart`
4. 当前 continuity 持久化布局已明确为：
   - `tracking/continuity/bundle.json`
   - `tracking/continuity/scopes/*.json`
   - `tracking/continuity/frames/*.json`
   - `tracking/continuity/build_specs/index.json`
   - `tracking/continuity/build_specs/*.json`
   - 以及预留的 `analysis/continuity/*.md` 路径方法
5. 已在 adapters 新增 continuity JSON codec 支撑层：
   - `project_continuity_json_codec_support.dart`
   - 负责 bundle/scopes/overlays/mechanics/frames/build specs 的 JSON 映射
6. 已新增 adapter-side codec services：
   - `project_continuity_document_codec_service.dart`
   - `project_continuity_scope_document_codec_service.dart`
   - `project_continuity_frame_document_codec_service.dart`
   - `project_continuity_build_spec_document_codec_service.dart`
7. 已新增 continuity scope 文档对象：
   - `project_continuity_scope_document.dart`
   - 用于把 `ContinuationScope` 与其 overlays 绑定到同一文档
8. 已新增两层仓储，而不是做成一个巨仓：
   - `ProjectContinuityRepository`
   - `ProjectContinuityBuildSpecRepository`
9. `ProjectContinuityRepository` 当前负责：
   - 读写 `bundle.json`
   - 按 `scope_ids` 加载 scope docs
   - 按 `frame_ids` 加载 frame docs
   - 把 scopes / overlays / frames 与 bundle summary 重新组装成 `ProjectContinuityBundle`
10. `bundle.json` 现在会显式写入：
    - `scope_ids`
    - `frame_ids`
    这样读取只消费当前 bundle 明确声明的子文档，避免历史残留 scope/frame 文档污染 load 结果。
11. `ProjectContinuityBuildSpecRepository` 当前负责：
    - 读写 `build_specs/index.json`
    - 根据 `build_spec_ids` 读写单个 build spec 文档
12. 当前这轮没有重写现有 timeline / character runtime 存储，而是单独为 continuity layer 建了自己的持久化边界。
13. 已导出 adapters 入口：
    - continuity path policy
    - codec services
    - repositories
14. 已补 focused tests：
    - `packages/novel_agent_adapters/test/project_continuity_repository_test.dart`
    - `packages/novel_agent_adapters/test/project_continuity_build_spec_repository_test.dart`
15. 测试覆盖：
    - bundle summary + scope/frame docs 往返持久化
    - build spec index + spec docs 往返持久化
16. 本轮刻意未做：
    - 未接 deconstruction continuity hints
    - 未接 long-task context path / section plan
    - 未写 analysis/continuity markdown 实体内容
    - 未做删除/清理策略的完整实现
17. 已验证：
    - `dart format lib/src/storage/project_continuity_path_policy.dart lib/src/storage/project_continuity_scope_document.dart lib/src/storage/project_continuity_json_codec_support.dart lib/src/storage/project_continuity_document_codec_service.dart lib/src/storage/project_continuity_scope_document_codec_service.dart lib/src/storage/project_continuity_frame_document_codec_service.dart lib/src/storage/project_continuity_build_spec_document_codec_service.dart lib/src/storage/project_continuity_repository.dart lib/src/storage/project_continuity_build_spec_repository.dart lib/novel_agent_adapters.dart test/project_continuity_repository_test.dart test/project_continuity_build_spec_repository_test.dart`
    - `dart format lib/src/continuity/continuity_build_spec.dart lib/novel_agent_core.dart`
    - `dart analyze lib/src/storage/project_continuity_path_policy.dart lib/src/storage/project_continuity_scope_document.dart lib/src/storage/project_continuity_json_codec_support.dart lib/src/storage/project_continuity_document_codec_service.dart lib/src/storage/project_continuity_scope_document_codec_service.dart lib/src/storage/project_continuity_frame_document_codec_service.dart lib/src/storage/project_continuity_build_spec_document_codec_service.dart lib/src/storage/project_continuity_repository.dart lib/src/storage/project_continuity_build_spec_repository.dart lib/novel_agent_adapters.dart test/project_continuity_repository_test.dart test/project_continuity_build_spec_repository_test.dart`
    - `dart analyze lib/src/continuity/continuity_build_spec.dart lib/novel_agent_core.dart`
    - `dart test test/project_continuity_repository_test.dart`
    - `dart test test/project_continuity_build_spec_repository_test.dart`

---

## 8.4 Session WCF-04：建立一般项目的 continuity 输入路径

### 本轮目标

让一般项目在不依赖拆书的情况下也能声明和积累 continuity facts。

### 必读文件

- WCF-01 到 WCF-03 新增 continuity 基础
- `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
- 当前一般项目创建与设置相关 app/service 文件

### 必须完成

1. 定义一般项目 continuity defaults：
   - 单线连续
   - 正常状态累积
   - 无特殊回档
2. 提供一般项目 continuity seed / override 写入服务
3. 允许一般项目逐步积累：
   - scope
   - overlays
   - frame
   - mechanic profile
4. 产品层只接轻量入口，不暴露过多术语
5. 补 focused test / probe

### 本轮不要做

- 不接拆书 hint 提取
- 不做复杂可视化编辑器
- 不接长任务上下文

### 重点拆耦

- general project defaults
- persistence bridge
- UI lightweight projection

### 完成判定

- 一般项目已经不是 continuity 的旁路用户

### 直接可用提示词

```text
按 docs/writing-continuity-foundation-session-order-2026-05-31.md 的 Session WCF-04 执行。只建立一般项目的 continuity 输入路径与默认值，让非拆书项目也能声明和积累 continuity facts，但 UI 先保持轻量，不做复杂编辑器，不开启下一任务。
```

### 本轮完成记录

1. 已在 core 新增一般项目 continuity 轻量输入档案：
   - `packages/novel_agent_core/lib/src/continuity/project_continuity_input_profile.dart`
2. `ProjectContinuityInputProfile` 当前承载的是“轻量声明”而不是 runtime facts，本轮字段覆盖：
   - `usesMultipleWorlds`
   - `usesBranchingRoutes`
   - `usesReplayResets`
   - `requiresScopedIdentityOverlays`
   - `worldLabels`
   - 各 continuity policy 的可选 override
   - `notes`
   - `metadata`
3. 已在 core 新增一般项目 continuity 默认值服务：
   - `packages/novel_agent_core/lib/src/continuity/general_project_continuity_defaults_service.dart`
4. `GeneralProjectContinuityDefaultsService` 当前可把一般项目描述 + 轻量输入档案转换成保守默认 bundle：
   - 默认单线项目 -> `global` scope + `mainline` frame + 单线线性 mechanic
   - 多世界输入 -> 生成 `global` + world scopes
   - 分支/回档/身份覆盖输入 -> 映射到默认 mechanic profile 的对应 policy
5. 这轮没有把一般项目 continuity 输入直接混进 runtime bundle 文档，而是明确保留：
   - `ProjectContinuityInputProfile` = 轻量输入层
   - `ProjectContinuityBundle` = 运行事实层
6. 已在 adapters 新增一般项目 continuity 输入路径：
   - `packages/novel_agent_adapters/lib/src/storage/project_continuity_input_path_service.dart`
   - 当前路径为：
     - `.novel_agent/settings/project_continuity_input.json`
7. 已在 adapters 新增输入档案 codec 与仓储：
   - `project_continuity_input_document_codec_service.dart`
   - `project_continuity_input_repository.dart`
8. 已在 adapters 新增一般项目 continuity 初始化/应用服务：
   - `project_general_continuity_setup_service.dart`
9. `ProjectGeneralContinuitySetupService` 当前提供两条正式路径：
   - `ensureInitialized(project)`
     - 项目尚无 continuity bundle 时，用已保存输入档案或保守默认值生成初始 bundle
   - `applyInput(project, input)`
     - 保存轻量输入档案
     - 用输入重新生成并写回 derived bundle
10. 这轮的“一般项目 continuity 输入路径”已经正式成立：
    - 项目级可保存轻量 continuity 声明
    - 可稳定生成默认 continuity bundle
    - 后续 scope / frame / overlays / mechanic profile 继续以 bundle 为事实源逐步积累
11. 已导出 core / adapters 入口：
    - `ProjectContinuityInputProfile`
    - `GeneralProjectContinuityDefaultsService`
    - `ProjectContinuityInputPathService`
    - `ProjectContinuityInputDocumentCodecService`
    - `ProjectContinuityInputRepository`
    - `ProjectGeneralContinuitySetupService`
12. 已补 focused tests：
    - core：
      - `packages/novel_agent_core/test/general_project_continuity_defaults_service_test.dart`
    - adapters：
      - `packages/novel_agent_adapters/test/project_general_continuity_setup_service_test.dart`
13. 测试覆盖：
    - 一般项目保守单线默认值
    - 多世界 + 分支 + 回档输入映射
    - `ensureInitialized(...)` 默认初始化
    - `applyInput(...)` 保存轻量输入并重写 derived bundle
14. 本轮刻意未做：
    - 未改项目创建 UI
    - 未改设置页或 workbench 前端
    - 未做复杂 continuity 编辑器
    - 未接 deconstruction continuity hints
    - 未接 long-task context path / section plan
15. 已验证：
    - `dart format lib/src/continuity/project_continuity_input_profile.dart lib/src/continuity/general_project_continuity_defaults_service.dart lib/novel_agent_core.dart test/general_project_continuity_defaults_service_test.dart`
    - `dart format lib/src/storage/project_continuity_input_path_service.dart lib/src/storage/project_continuity_input_document_codec_service.dart lib/src/storage/project_continuity_input_repository.dart lib/src/storage/project_general_continuity_setup_service.dart lib/novel_agent_adapters.dart test/project_general_continuity_setup_service_test.dart`
    - `dart analyze lib/src/continuity/project_continuity_input_profile.dart lib/src/continuity/general_project_continuity_defaults_service.dart lib/novel_agent_core.dart test/general_project_continuity_defaults_service_test.dart`
    - `dart analyze lib/src/storage/project_continuity_input_path_service.dart lib/src/storage/project_continuity_input_document_codec_service.dart lib/src/storage/project_continuity_input_repository.dart lib/src/storage/project_general_continuity_setup_service.dart lib/novel_agent_adapters.dart test/project_general_continuity_setup_service_test.dart`
    - `dart test test/general_project_continuity_defaults_service_test.dart`
    - `dart test test/project_general_continuity_setup_service_test.dart`

---

## 8.5 Session WCF-05：把 continuity runtime 接入长任务上下文装配

### 本轮目标

让已有 long-task context path / section plan 正式消费 continuity runtime。

### 必读文件

- `packages/novel_agent_core/lib/src/workflow/long_task_mode_context_path_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_project_file_section_plan_service.dart`
- 各 drift signal service
- WCF-02 continuity runtime resolver

### 必须完成

1. 给 long-task context 规划层增加 continuity 输入
2. 支持按 active frame / active scope chain 选择：
   - 全局圣经
   - 作用域覆盖
   - 阶段状态
   - 尾部窗口
3. 把 continuity 相关 facts 纳入 drift / review 可消费上下文
4. 保持长任务现有 runtime 主线不被打碎
5. 补 focused test：
   - 普通单线长任务
   - world overlay 长任务
   - fork/reset frame 长任务

### 本轮不要做

- 不接拆书 UI
- 不做新的 long-task runtime
- 不重写 drift signal 框架

### 重点拆耦

- continuity resolver
- long-task context path selection
- drift consumption

### 完成判定

- 长任务看到的上下文和 continuity layer 已经统一

### 直接可用提示词

```text
按 docs/writing-continuity-foundation-session-order-2026-05-31.md 的 Session WCF-05 执行。只把 continuity runtime 接入 LongTaskModeContextPathService 和 LongTaskProjectFileSectionPlanService，让长任务上下文能按 active frame/scope chain 选择全局事实、覆盖层、阶段状态和尾部窗口。不要重写长任务 runtime，不开启下一任务。
```

### 本轮完成记录

1. 已在 core 新增 continuity -> long-task 的共享投影模型：
   - `packages/novel_agent_core/lib/src/workflow/long_task_continuity_context_projection.dart`
2. 已在 core 新增 continuity -> long-task 的共享投影服务：
   - `packages/novel_agent_core/lib/src/workflow/long_task_continuity_context_projection_service.dart`
3. `LongTaskContinuityContextProjectionService` 当前会先复用 `ContinuityRuntimeResolverService` 做 runtime 解析，再把结果压成长任务可直接消费的 4 组上下文路径：
   - `canonicalPaths`
   - `overlayPaths`
   - `statePaths`
   - `tailWindowPaths`
4. 当前投影服务的路径来源已经明确分层：
   - canonical facts -> `bundle.metadata['context_paths']` + `canonicalAssetReferences.sourcePath`
   - scope overlays -> `overlay.metadata['context_paths']` + `overlay.assetReferences.sourcePath`
   - frame state -> `frame.metadata['context_paths']` + `stateReferences.sourcePath`
   - tail window -> `bundle.metadata['tail_window_paths']` + `frame.metadata['tail_window_paths']`
5. 已把 continuity runtime 接入 `LongTaskModeContextPathService`：
   - 新增可选参数：
     - `continuityBundle`
     - `continuityFrameId`
     - `continuityScopeId`
     - `continuityMechanicProfileId`
   - `persistentContextPaths(...)` 现在可把 continuity 投影路径并入长任务长期约束路径
   - `mergeTaskSourcePaths(...)` 也会复用同一套 continuity persistent paths
6. 已把 continuity runtime 接入 `LongTaskProjectFileSectionPlanService`：
   - 新增同一组 continuity 可选参数
   - `build(...)` 现在会在原有 generic persistent/source sections 之前补 continuity 专属 sections
7. 当前 continuity 专属 section 已拆成 4 类，不把 continuity 规则揉进 generic section：
   - `continuity_global_context`
   - `continuity_scope_overlays`
   - `continuity_runtime_state`
   - `continuity_tail_window`
8. 本轮也处理了路径去重边界：
   - generic `task_persistent_context` 会剔除 continuity 已覆盖的路径
   - generic `task_source_paths` 也会剔除 continuity persistent paths
   - 避免同一条 continuity 上下文既出现在 continuity section 又出现在普通 source/persistent section
9. 这样长任务 context assembly / review / drift 后续继续只吃 `project_file_section_plan` 即可，不需要直接知道 continuity runtime 内部细节。
10. 已导出 core 入口：
    - `LongTaskContinuityContextProjection`
    - `LongTaskContinuityContextProjectionService`
11. 已补 focused tests：
    - `packages/novel_agent_core/test/long_task_continuity_context_projection_service_test.dart`
    - `packages/novel_agent_core/test/long_task_mode_context_path_service_test.dart`
    - `packages/novel_agent_core/test/long_task_project_file_section_plan_service_test.dart`
12. 测试覆盖：
    - continuity canonical / overlay / state / tail-window 投影
    - continuity persistent paths 并入 long-task context paths
    - continuity sections 插入 project file section plan，且不会污染 generic task sections
13. 本轮刻意未做：
    - 未改 adapters runtime 实际加载 continuity bundle 的链路
    - 未重写 `ProjectWorkflowRuntimeService`
    - 未重写 drift signal services
    - 未改 deconstruction / app / UI
14. 已验证：
    - `dart format lib/src/workflow/long_task_continuity_context_projection.dart lib/src/workflow/long_task_continuity_context_projection_service.dart lib/src/workflow/long_task_mode_context_path_service.dart lib/src/workflow/long_task_project_file_section_plan_service.dart lib/novel_agent_core.dart test/long_task_continuity_context_projection_service_test.dart test/long_task_mode_context_path_service_test.dart test/long_task_project_file_section_plan_service_test.dart`
    - `dart analyze lib/src/workflow/long_task_continuity_context_projection.dart lib/src/workflow/long_task_continuity_context_projection_service.dart lib/src/workflow/long_task_mode_context_path_service.dart lib/src/workflow/long_task_project_file_section_plan_service.dart lib/novel_agent_core.dart test/long_task_continuity_context_projection_service_test.dart test/long_task_mode_context_path_service_test.dart test/long_task_project_file_section_plan_service_test.dart`
    - `dart test test/long_task_continuity_context_projection_service_test.dart test/long_task_mode_context_path_service_test.dart test/long_task_project_file_section_plan_service_test.dart`

---

## 8.6 Session WCF-06：建立拆书 continuity hints 与 scope/mechanic 提取层

### 本轮目标

在 deconstruction 子域中补齐 continuity hints，而不是直接产出一套平行 continuity runtime。

### 必读文件

- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_extraction_result.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_asset_mapping_service.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_application_plan_builder_service.dart`
- WCF-01 continuity contracts

### 必须完成

1. 扩展拆书结果或新增 companion object，支持：
   - scope map hints
   - identity mapping hints
   - continuity mechanic hints
   - coverage/source range hints
2. 明确“源事实”与“推断事实”分层
3. 不直接在 extraction result 里塞入整个 runtime bundle
4. 让拆书 hints 能被后续 continuity bundle builder 消费
5. 补 focused test / fixture

### 本轮不要做

- 不直接派生项目
- 不改 book deconstruction page UI 大结构
- 不接 long-task

### 重点拆耦

- source facts
- inferred continuity hints
- runtime bundle build inputs

### 完成判定

- 拆书已经能为 continuity layer 提供高密度 hints，但没有重新造一套底层

### 直接可用提示词

```text
按 docs/writing-continuity-foundation-session-order-2026-05-31.md 的 Session WCF-06 执行。只在 deconstruction 子域补 continuity hints，包括 scope map、identity mapping、mechanic hints 和 coverage/source range hints，并明确源事实与推断事实分层。不要直接派生项目，不开启下一任务。
```

### 本轮完成记录

1. 已在 `packages/novel_agent_core/lib/src/deconstruction/` 新增拆书 continuity hints 相关合同：
   - `book_deconstruction_hint_source_kind.dart`
   - `book_deconstruction_source_range_hint.dart`
   - `book_deconstruction_coverage_hint.dart`
   - `book_deconstruction_scope_hint.dart`
   - `book_deconstruction_scope_map.dart`
   - `book_deconstruction_identity_mapping_hint.dart`
   - `book_deconstruction_mechanic_hint.dart`
   - `book_deconstruction_continuity_hints.dart`
2. 已把 `BookDeconstructionExtractionResult` 扩展为携带 companion continuity 对象：
   - `continuityHints = const BookDeconstructionContinuityHints()`
3. 这一轮明确采用“高密度 hints companion”路线，而不是把拆书结果直接膨胀成一套平行 runtime bundle：
   - `scope map hints`
   - `identity mapping hints`
   - `mechanic hints`
   - `coverage/source range hints`
4. 已把“源事实”与“推断事实”正式分层：
   - `BookDeconstructionHintSourceKind.sourceFact`
   - `BookDeconstructionHintSourceKind.inferredHint`
5. 当前 hints 分层表达已经覆盖：
   - 来源覆盖范围与分段
   - 作用域提示与默认 scope
   - 规范实体到作用域实体的身份映射提示
   - identity / memory / state / causal / branch / visibility 等 mechanic policy hints
6. 已导出 root library 入口：
   - `packages/novel_agent_core/lib/novel_agent_core.dart`
7. 已补 focused test：
   - `packages/novel_agent_core/test/book_deconstruction_continuity_hints_test.dart`
   - 覆盖：
     - `BookDeconstructionExtractionResult` 可独立携带 `continuityHints`
     - `BookDeconstructionContinuityHints.hasContent`
     - `BookDeconstructionContinuityHints.hasInferredHints`
     - source fact 与 inferred hint 的语义分层
8. 已补 integration guard test，确认当前 application plan 仍不消费这些 continuity hints：
   - `packages/novel_agent_core/test/book_deconstruction_application_plan_builder_service_test.dart`
   - 证明现有 preview/apply 资产映射链保持不变，没有偷偷长出平行 continuity runtime 行为
9. 本轮刻意未做：
   - 未直接生成 derived project
   - 未改 book deconstruction page UI 大结构
   - 未接 long-task
   - 未在 extraction result 中塞入 `ProjectContinuityBundle`
   - 未建立 continuity bundle builder
10. 已验证：
   - `dart format packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_hint_source_kind.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_source_range_hint.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_coverage_hint.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_scope_hint.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_scope_map.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_identity_mapping_hint.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_mechanic_hint.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_continuity_hints.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_extraction_result.dart packages/novel_agent_core/lib/novel_agent_core.dart packages/novel_agent_core/test/book_deconstruction_continuity_hints_test.dart packages/novel_agent_core/test/book_deconstruction_application_plan_builder_service_test.dart`
   - `dart analyze packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_hint_source_kind.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_source_range_hint.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_coverage_hint.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_scope_hint.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_scope_map.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_identity_mapping_hint.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_mechanic_hint.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_continuity_hints.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_extraction_result.dart packages/novel_agent_core/lib/novel_agent_core.dart packages/novel_agent_core/test/book_deconstruction_continuity_hints_test.dart packages/novel_agent_core/test/book_deconstruction_application_plan_builder_service_test.dart`
   - `dart test test/book_deconstruction_continuity_hints_test.dart`
   - `dart test test/book_deconstruction_application_plan_builder_service_test.dart`

---

## 8.7 Session WCF-07：建立续写基座构建流程与分档 build spec

### 本轮目标

把“快速承接 / 标准基座 / 深度重构”做成正式 build spec 与构建流程。

### 必读文件

- `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
- WCF-03 continuity persistence
- WCF-06 deconstruction continuity hints
- 现有 long-task runtime observability 文档与实现

### 必须完成

1. 正式建立 build spec：
   - `quick_bridge`
   - `standard_foundation`
   - `deep_reconstruction`
2. 定义每档输出什么：
   - 尾部承接
   - 全局圣经
   - 分阶段摘要
   - 状态表
   - 冲突与缺口分析
3. 建立“续写基座构建流程”合同：
   - preview
   - confirm
   - build
   - publish
4. 如需复用可恢复 runtime，只复用引擎，不把产品语义叫成长任务
5. 补 focused test / probe

### 本轮不要做

- 不先做完整后续工程菜单
- 不先做派生执行项目
- 不把 build flow 直接绑死某个智能体组

### 重点拆耦

- build spec
- build runtime contract
- future derivation outputs

### 完成判定

- 系统已经有正式“续写基座构建”概念，而不是零散分析步骤

### 直接可用提示词

```text
按 docs/writing-continuity-foundation-session-order-2026-05-31.md 的 Session WCF-07 执行。只建立续写基座构建流程与三档 build spec（快速承接、标准基座、深度重构），定义每档输出，并在需要时复用可恢复 runtime 引擎但不把产品语义叫成长任务。不要做派生项目和完整后续菜单，不开启下一任务。
```

### 本轮完成记录

1. 已把 `ContinuityBuildSpec` 从最小持久化壳升级为正式 build spec 合同：
   - `packages/novel_agent_core/lib/src/continuity/continuity_build_spec.dart`
2. 当前 `ContinuityBuildSpec` 已正式具备：
   - `ContinuityBuildTier`
     - `quickBridge`
     - `standardFoundation`
     - `deepReconstruction`
   - `ContinuityBuildOutputKind`
     - `tailBridge`
     - `globalBible`
     - `stageSummaries`
     - `stateTables`
     - `conflictGapAnalysis`
   - `ContinuityBuildRuntimeHost`
     - `directExecution`
     - `resumableWorkflowEngine`
   - `recommended`
3. 已在 core 新增续写基座构建流程合同：
   - `packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_stage.dart`
   - `packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_flow.dart`
4. 当前流程合同已明确四阶段：
   - `preview`
   - `confirm`
   - `build`
   - `publish`
5. 已在 core 新增正式 catalog service：
   - `packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_catalog_service.dart`
6. `ContinuityFoundationBuildCatalogService` 现在正式提供三档内置规格：
   - `quick_bridge`
     - 偏尾部承接与近期状态
     - 输出：`tailBridge` + `stateTables`
     - 默认 runtime host：`directExecution`
   - `standard_foundation`
     - 默认推荐档
     - 输出：`tailBridge` + `globalBible` + `stageSummaries` + `stateTables`
     - 默认 runtime host：`resumableWorkflowEngine`
   - `deep_reconstruction`
     - 面向超长篇 / 结构混乱 / 深度重构
     - 输出：`tailBridge` + `globalBible` + `stageSummaries` + `stateTables` + `conflictGapAnalysis`
     - 默认 runtime host：`resumableWorkflowEngine`
7. 这轮也把“如需复用可恢复 runtime，只复用引擎，不把产品语义叫成长任务”正式落进了合同：
   - spec 层只声明 `preferredRuntimeHost`
   - flow 层只声明是否支持 `supportsStepRetry` / `supportsPartialArtifacts`
   - 产品语义仍然叫 `续写基座构建`
8. 当前 flow 合同没有直接绑定具体智能体组、具体 long-task mode 或派生项目类型，只提供后续 orchestration 可复用的中性骨架。
9. 已导出 root library 入口：
   - `ContinuityBuildSpec`
   - `ContinuityFoundationBuildStage`
   - `ContinuityFoundationBuildFlow`
   - `ContinuityFoundationBuildCatalogService`
10. 已把 adapters 持久化链同步升级到正式 spec 语义：
    - `packages/novel_agent_adapters/lib/src/storage/project_continuity_json_codec_support.dart`
11. 当前 build spec codec 已支持：
    - 新枚举字段的读写
    - `preferred_runtime_host`
    - `recommended`
    - 对旧 tier/output 命名的兼容别名解析，例如：
      - `quick` -> `quickBridge`
      - `standard` -> `standardFoundation`
      - `bible` -> `globalBible`
      - `arc_summary` -> `stageSummaries`
      - `state_snapshot` -> `stateTables`
12. 已补 focused tests：
    - core：
      - `packages/novel_agent_core/test/continuity_foundation_build_catalog_service_test.dart`
    - adapters：
      - `packages/novel_agent_adapters/test/project_continuity_build_spec_repository_test.dart`
13. 测试覆盖：
    - 三档正式 build spec 的存在、输出与 runtime host
    - `preview / confirm / build / publish` 四阶段流程合同
    - build spec repository 对新合同结构的持久化往返
14. 本轮刻意未做：
    - 未做完整后续工程菜单
    - 未做派生执行项目
    - 未把 flow 绑定具体智能体组
    - 未接 app / UI
    - 未开始真正的基座构建执行 orchestration
15. 已验证：
    - `dart format packages/novel_agent_core/lib/src/continuity/continuity_build_spec.dart packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_stage.dart packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_flow.dart packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_catalog_service.dart packages/novel_agent_core/lib/novel_agent_core.dart packages/novel_agent_core/test/continuity_foundation_build_catalog_service_test.dart packages/novel_agent_adapters/lib/src/storage/project_continuity_json_codec_support.dart packages/novel_agent_adapters/test/project_continuity_build_spec_repository_test.dart`
    - `dart analyze packages/novel_agent_core/lib/src/continuity/continuity_build_spec.dart packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_stage.dart packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_flow.dart packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_catalog_service.dart packages/novel_agent_core/lib/novel_agent_core.dart packages/novel_agent_core/test/continuity_foundation_build_catalog_service_test.dart`
    - `dart analyze packages/novel_agent_adapters/lib/src/storage/project_continuity_json_codec_support.dart packages/novel_agent_adapters/test/project_continuity_build_spec_repository_test.dart`
    - `dart test test/continuity_foundation_build_catalog_service_test.dart`
    - `dart test test/project_continuity_build_spec_repository_test.dart`

---

## 8.8 Session WCF-08：建立拆书源工程的“主目标方向 + 完整后续菜单”派生链

### 本轮目标

实现混合方案：创建时记录主目标方向，完成后仍可多路派生。

### 必读文件

- `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
- `apps/novel_agent_app/lib/features/book_deconstruction/*`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_application_plan.dart`
- WCF-07 build flow contracts

### 必须完成

1. 在拆书承接源工程创建时记录：
   - `普通续写优先`
   - `长任务续写优先`
   - `先拆书分析`
2. 这只是默认导向，不是最终执行项目类型
3. 拆书完成后提供完整后续工程菜单：
   - 一般续写
   - 各种长任务续写
   - 未来其他路线
4. 默认高亮主目标方向对应路线与 build spec
5. 支持从同一源工程派生多个执行项目
6. 补 focused UI/service test

### 本轮不要做

- 不让创建时直接生成最终执行项目
- 不删掉源工程的独立语义
- 不要求默认先选智能体组

### 重点拆耦

- source project
- target direction preference
- derived execution project plan

### 完成判定

- “创建时有方向”与“完成后可分流”已经同时成立

### 直接可用提示词

```text
按 docs/writing-continuity-foundation-session-order-2026-05-31.md 的 Session WCF-08 执行。只建立拆书承接源工程的主目标方向记录与完整后续工程菜单，让创建时有默认导向、完成后仍可多路派生，并支持从同一源工程派生多个执行项目。不要把创建时选择错误实现成最终执行项目类型，不开启下一任务。
```

### 本轮完成记录

1. 已在 core deconstruction 子域新增“拆书源工程主目标方向”正式合同：
   - `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_continuation_direction.dart`
2. 当前主目标方向已正式支持三种值：
   - `generalNovelPreferred`
   - `longTaskPreferred`
   - `analysisFirst`
3. 这轮明确把“主目标方向”定义成：
   - source project 的默认导向
   - 不是最终执行项目类型
   - 后续仍允许从同一源工程多路派生
4. 已把该字段接入 `BookDeconstructionInput`：
   - `preferredContinuationDirection`
   - 默认值为 `analysisFirst`
5. 已在 core 新增拆书后续菜单合同：
   - `book_deconstruction_followup_option.dart`
   - `book_deconstruction_followup_group.dart`
   - `book_deconstruction_followup_menu.dart`
6. 已在 core 新增拆书派生执行项目计划合同：
   - `book_deconstruction_derived_project_plan.dart`
7. 已在 core 新增菜单构建与派生计划服务：
   - `book_deconstruction_followup_menu_builder_service.dart`
   - `book_deconstruction_derived_project_plan_builder_service.dart`
8. `BookDeconstructionFollowupMenuBuilderService` 当前已正式生成“拆书完成后的完整后续工程菜单”：
   - `general_writing`
     - `general_novel`
   - `long_task_writing`
     - `seed_autopilot_novel`
     - `full_outline_consensus`
     - `volume_checkpoint_handoff`
     - `chapter_brief_supervised`
     - `salvage_restructure_existing`
   - `future_extensions`
     - 当前保留为空分组，作为未来续写路线的稳定扩展位
9. 当前 follow-up menu 已正式支持：
   - 默认高亮 group / option
   - 默认高亮 build tier
   - `allowsMultipleDerivedProjects = true`
10. 默认高亮规则当前为：
    - `generalNovelPreferred`
      - 高亮 `general_writing` / `general_novel`
      - 默认 build tier = `quickBridge`
    - `longTaskPreferred`
      - 高亮 `long_task_writing` / `seed_autopilot_novel`
      - 默认 build tier = `standardFoundation`
    - `analysisFirst`
      - 只高亮 build tier = `standardFoundation`
      - 不预选最终执行路线
11. 这一点是本轮刻意确认的设计判断：
    - `analysisFirst` 本身不是执行项目类型
    - 因此不会把“先拆书分析”错误实现成某个最终派生项目
12. `BookDeconstructionDerivedProjectPlanBuilderService` 当前可从同一 source project 输入和任一 follow-up option 生成独立派生计划：
    - plan id
    - source extraction id
    - target project type / strategy / mode
    - recommended build tier
    - suggested project title
13. 这意味着同一拆书源工程现在已经在合同层支持：
    - 一般续写派生
    - 各种长任务续写派生
    - 未来新增路线继续派生
14. 这轮没有把 follow-up menu 塞回 `BookDeconstructionApplicationPlan`，而是保持两条链分离：
    - `application plan` 继续只处理 preview/apply 资产映射
    - `follow-up menu / derived project plan` 专门处理后续工程分流
15. 已把上述合同接入当前 app service 草稿构建结果：
    - `apps/novel_agent_app/lib/features/book_deconstruction/application/models/book_deconstruction_draft_build_result.dart`
    - `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart`
16. 当前 `BookDeconstructionDraftBuildResult` 已额外携带：
    - `followupMenu`
17. `BookDeconstructionDraftBuilderService.build(...)` 现已支持显式传入：
    - `preferredContinuationDirection`
18. 因此这轮即使还没接页面，app service 层已经可以正式表达：
    - 创建时带默认导向
    - 构建完成后得到完整后续菜单
19. 已导出 root library 入口：
    - `BookDeconstructionContinuationDirection`
    - `BookDeconstructionFollowupOption`
    - `BookDeconstructionFollowupGroup`
    - `BookDeconstructionFollowupMenu`
    - `BookDeconstructionDerivedProjectPlan`
    - `BookDeconstructionFollowupMenuBuilderService`
    - `BookDeconstructionDerivedProjectPlanBuilderService`
20. 已补 focused tests：
    - core：
      - `packages/novel_agent_core/test/book_deconstruction_followup_menu_builder_service_test.dart`
    - app：
      - `apps/novel_agent_app/test/book_deconstruction_draft_builder_service_test.dart`
21. 测试覆盖：
    - 完整 follow-up menu 分组与长任务模式收口
    - 三种主目标方向的默认高亮规则
    - `analysisFirst` 不预选最终路线
    - 从某个 follow-up option 派生独立执行项目计划
    - draft builder 会把偏好和 follow-up menu 一起带出
22. 本轮刻意未做：
    - 未改 project creation UI
    - 未改 book deconstruction page UI 展示
    - 未真正创建派生项目工作区
    - 未绑定具体智能体组
    - 未做 continuity 前端联系层
23. 已验证：
    - `dart format packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_continuation_direction.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_option.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_group.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_menu.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_derived_project_plan.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_menu_builder_service.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_derived_project_plan_builder_service.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_input.dart packages/novel_agent_core/lib/novel_agent_core.dart packages/novel_agent_core/test/book_deconstruction_followup_menu_builder_service_test.dart apps/novel_agent_app/lib/features/book_deconstruction/application/models/book_deconstruction_draft_build_result.dart apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart apps/novel_agent_app/test/book_deconstruction_draft_builder_service_test.dart`
    - `dart analyze packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_continuation_direction.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_option.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_group.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_menu.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_derived_project_plan.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_menu_builder_service.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_derived_project_plan_builder_service.dart packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_input.dart packages/novel_agent_core/lib/novel_agent_core.dart packages/novel_agent_core/test/book_deconstruction_followup_menu_builder_service_test.dart`
    - `dart analyze apps/novel_agent_app/lib/features/book_deconstruction/application/models/book_deconstruction_draft_build_result.dart apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart apps/novel_agent_app/test/book_deconstruction_draft_builder_service_test.dart`
    - `dart test test/book_deconstruction_followup_menu_builder_service_test.dart`
    - `flutter test test/book_deconstruction_draft_builder_service_test.dart`

---

## 8.9 Session WCF-09：补一般项目与拆书项目的 continuity 前端联系层

### 本轮目标

把 continuity 的前端接入做成“轻量默认 + 高级入口”，并兼顾一般项目与拆书项目。

### 必读文件

- 一般项目设置/创建相关 app 文件
- `apps/novel_agent_app/lib/features/book_deconstruction/*`
- WCF-04 / WCF-08 相关服务

### 必须完成

1. 一般项目：
   - 提供轻量 continuity 默认设置入口
   - 让用户可声明是否有多世界/回档/多路线等特殊机制
2. 拆书项目：
   - 在 preview / confirm / build / derive 节奏中展示 continuity 关键信息
3. 高级设置才展示更细的 scope/mechanic 编辑
4. 统一中文语义，不把用户暴露在内部 id / 术语墙前
5. focused widget/service test 覆盖

### 本轮不要做

- 不在一个页面堆满所有 continuity 细节
- 不把 UI 变成调试台
- 不让 widget 自己推断 continuity 业务规则

### 重点拆耦

- app orchestration
- view-data projection
- core continuity facts

### 完成判定

- 用户在一般项目和拆书项目里都能低心智负担地进入 continuity 能力

### 直接可用提示词

```text
按 docs/writing-continuity-foundation-session-order-2026-05-31.md 的 Session WCF-09 执行。只补 continuity 的前端联系层：一般项目提供轻量默认入口，拆书项目在 preview/confirm/build/derive 节奏中展示 continuity 关键信息，高级设置再承接更细编辑。不要把页面做成调试台，不开启下一任务。
```

### 本轮完成记录

1. 一般项目创建链已正式接入轻量 continuity 输入：
   - `apps/novel_agent_app/lib/features/workbench/presentation/models/project_create_request_view_data.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/models/project_launcher_view_data.dart`
   - `apps/novel_agent_app/lib/features/workbench/application/services/project_launcher_view_data_service.dart`
2. 项目创建浮层现在会在一般小说与长篇小说类型下展示中文轻量 continuity 入口：
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_continuity_input_panel.dart`
   - 支持声明：
     - 多世界/多舞台切换
     - 多路线/支线分叉
     - 回档/回归/重跑
     - 局部身份覆盖
     - 世界/舞台标签
     - 补充说明
3. 创建面板当前按“轻量默认 + 后续摘要”节奏承接 continuity：
   - 项目类型阶段显示完整轻量输入
   - 后续阶段只显示 compact summary
   - 未把高级 scope/mechanic 编辑塞进本轮创建页
4. `ProjectCreationController` 已把 continuity 输入贯通到真实创建链，而不是停留在假 UI：
   - `apps/novel_agent_app/lib/features/project_creation/application/controllers/project_creation_controller.dart`
   - 创建完成后会对 `novel` / `long_novel` 调用
     `ProjectGeneralContinuitySetupService.applyInput(...)`
5. app bootstrap / app shell 已完成 continuity 创建服务装配：
   - `apps/novel_agent_app/lib/app/bootstrap/app_bootstrap.dart`
   - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
6. 拆书预览侧已补上 continuity 前端投影，而没有把 continuity 业务规则塞进 widget：
   - `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart`
   - `apps/novel_agent_app/lib/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart`
7. 当前拆书 preview 已正式展示：
   - 默认导向
   - 推荐基座档位
   - 默认高亮后续路线
   - 作用域提示 / 身份映射 / 机制提示计数
   - follow-up menu 分组与选项
   - continuity 摘要文案
8. 这轮刻意保持职责分离：
   - continuity facts 仍来自 core / adapters
   - app 层只做创建入口编排与 view-data 投影
   - 未把 follow-up / derive 语义揉进 `BookDeconstructionApplicationPlan`
9. 为了让新入口在真实壳挂载下稳定可用，这轮顺手修了两个滚动容器与 `PrimaryScrollController` 的冲突点：
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_create_panel.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_empty_state_panel.dart`
10. 已补 focused tests：
    - `apps/novel_agent_app/test/project_create_panel_continuity_test.dart`
    - `apps/novel_agent_app/test/project_creation_controller_test.dart`
    - `apps/novel_agent_app/test/book_deconstruction_view_data_service_test.dart`
11. 本轮额外回归通过：
    - `apps/novel_agent_app/test/widget_test.dart`
12. 本轮刻意未做：
    - 未做高级 scope / mechanic 编辑页
    - 未做真正的拆书 derive project UI
    - 未开启 WCF-10 总回归与机制矩阵验证
13. 已验证：
    - `dart analyze apps/novel_agent_app/lib/features/workbench/presentation/models/project_create_request_view_data.dart apps/novel_agent_app/lib/features/workbench/presentation/models/project_launcher_view_data.dart apps/novel_agent_app/lib/features/workbench/application/services/project_launcher_view_data_service.dart apps/novel_agent_app/lib/features/project_creation/application/controllers/project_creation_controller.dart apps/novel_agent_app/lib/app/bootstrap/app_bootstrap.dart apps/novel_agent_app/lib/app/state/app_shell_controller.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_create_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_continuity_input_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_launcher_overlay.dart apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart apps/novel_agent_app/lib/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart apps/novel_agent_app/lib/features/book_deconstruction/presentation/models/book_deconstruction_view_data.dart apps/novel_agent_app/lib/features/book_deconstruction/presentation/models/book_deconstruction_continuity_view_data.dart apps/novel_agent_app/test/project_creation_controller_test.dart apps/novel_agent_app/test/project_create_panel_continuity_test.dart apps/novel_agent_app/test/book_deconstruction_view_data_service_test.dart apps/novel_agent_app/test/widget_test.dart`
    - `flutter test test/project_create_panel_continuity_test.dart`
    - `flutter test test/project_creation_controller_test.dart`
    - `flutter test test/book_deconstruction_view_data_service_test.dart`
    - `flutter test test/widget_test.dart -r expanded`

---

## 8.10 Session WCF-10：总回归、题材机制矩阵验证与文档回填

### 本轮目标

做 continuity layer 整条链的 focused 回归，确保不是“只对某一个题材刚好能跑”。

### 必读文件

- WCF-01 到 WCF-09 涉及的 core / adapters / app 文件
- `docs/book-deconstruction-continuation-analysis-2026-05-31.md`

### 必须完成

1. 跑完 continuity 核心 focused test
2. 验证至少这些场景：
   - 普通单线项目
   - 多世界/快穿式作用域覆盖
   - 死亡回归/回档
   - 梦境/幻境局部异常线
   - 拆书快速承接
   - 拆书标准基座
   - 拆书深度重构 + 长任务派生
3. 验证从同一拆书源工程派生多条执行项目
4. 回填本文完成记录
5. 如用户要求，再进行打包或截图核验

### 本轮不要做

- 不新增功能
- 不改路线定义
- 不把验证时发现的问题悄悄留到以后

### 完成判定

- continuity 这条链对一般项目、拆书项目、特殊剧情机制都已经有成体系验证

### 直接可用提示词

```text
按 docs/writing-continuity-foundation-session-order-2026-05-31.md 的 Session WCF-10 执行。只做写作连续性基础与拆书派生承接整条链的总回归、题材机制矩阵验证与文档回填，覆盖普通单线、多世界、回档、梦境线、拆书三档基座和多路派生。不要新增功能，不开启下一任务。
```

### 本轮完成记录

1. 已完成 continuity layer 的 WCF-10 focused regression，不新增功能、不改路线定义，只补验证与文档回填。
2. 本轮新增 WCF-10 专用矩阵测试：
   - `packages/novel_agent_core/test/writing_continuity_validation_matrix_test.dart`
3. 这组矩阵测试已明确钉住以下场景：
   - 普通单线项目默认连续
   - 多世界/快穿式作用域覆盖
   - 死亡回归/回档 reset 线
   - 梦境/幻境局部异常线
   - 拆书快速承接
   - 拆书标准基座
   - 拆书深度重构 + 长任务派生
   - 从同一拆书源工程派生多条执行项目
4. 这一轮没有引入新的 continuity 功能，而是把已有 contracts / resolver / build spec / deconstruction follow-up / front-end contact layer 串成了一套成体系回归矩阵。
5. 本轮确认的一般项目链路覆盖现状：
   - `GeneralProjectContinuityDefaultsService` 已覆盖普通单线默认值与特殊机制轻量输入派生
   - `ProjectGeneralContinuitySetupService` 已覆盖项目初始化与轻量 continuity 输入落盘
   - app 创建链已覆盖创建面板输入与 controller 落盘联动
6. 本轮确认的 continuity runtime 覆盖现状：
   - `ContinuityRuntimeResolverService` 已验证：
     - 单线保守默认
     - 多世界 overlay 解析
     - fork frame 继承
     - reset frame 丢弃父状态
     - 梦境/幻境类 overwrite 异常线局部覆盖
7. 本轮确认的拆书与派生链覆盖现状：
   - `BookDeconstructionFollowupMenuBuilderService`
   - `BookDeconstructionDerivedProjectPlanBuilderService`
   - `BookDeconstructionDraftBuilderService`
   - `BookDeconstructionViewDataService`
   已覆盖：
   - 三档基座映射
   - analysis-first 不预选最终路线
   - 长任务推荐路线
   - 同源多路派生
8. 本轮确认的长任务 continuity 上下文覆盖现状：
   - `LongTaskContinuityContextProjectionService` 已验证 canonical / overlay / state / tail-window 四类路径投影
   - 说明 continuity 事实已能进入长任务上下文装配链，而不是只停留在静态模型层
9. 本轮运行的 focused regression：
   - core:
     - `dart test test/continuity_runtime_resolver_service_test.dart test/general_project_continuity_defaults_service_test.dart test/continuity_foundation_build_catalog_service_test.dart test/book_deconstruction_followup_menu_builder_service_test.dart test/book_deconstruction_continuity_hints_test.dart test/long_task_continuity_context_projection_service_test.dart test/writing_continuity_validation_matrix_test.dart`
   - adapters:
     - `dart test test/project_general_continuity_setup_service_test.dart test/project_continuity_repository_test.dart test/project_continuity_build_spec_repository_test.dart`
   - app:
     - `flutter test test/project_create_panel_continuity_test.dart test/project_creation_controller_test.dart test/book_deconstruction_draft_builder_service_test.dart test/book_deconstruction_view_data_service_test.dart`
10. 本轮额外静态校验：
    - `dart analyze packages/novel_agent_core/test/writing_continuity_validation_matrix_test.dart`
11. 已验证结果：
    - 上述 core / adapters / app focused tests 全部通过
    - 新增 WCF-10 矩阵测试通过
12. 本轮没有继续扩展的内容：
    - 没有新增 continuity 编辑功能
    - 没有改写 follow-up menu 定义
    - 没有新增新的题材硬编码分支
13. 到 WCF-10 收口后，当前 continuity 链已经具备成体系验证：
    - 一般项目与拆书项目共用底座
    - 特殊剧情机制不靠题材硬编码
    - 拆书源工程、基座构建、派生执行项目保持分层
14. 仍需单独注意但不属于本轮 continuity 链失败的事项：
    - 仓库里仍存在少量与本条任务线无关的旧测试/接口漂移问题，未在本轮一并处理
    - continuity 这条线本身的 focused regression 结果是干净的

---

## 9. 建议推进方式

后续建议统一用下面这段话推进：

```text
根据目前的进度和文档：docs/writing-continuity-foundation-session-order-2026-05-31.md继续下一步，每次只确认完成一个具体的任务，如果上个会话末尾卡在具体任务的一半未完成或者出现了关联性错误，那么就先把这些做好，不需要开启下一轮任务；如果已经确认可以开启下一轮任务，那么可以直接开始。注意共享 continuity layer 优先、先 core 再 adapters 再 runtime integration 再 app/front-end、一般项目与拆书项目共用底座、作用域系统与连续性机制系统分开、不要把快穿/回档做成硬编码题材分支、不要让单一文件过大。开始吧。
```

---

## 10. 最后一句定义

这条链最终不是为了给拆书加一个“更会分析的后续按钮”，而是为了：

**把整个写作系统真正补上一层可复用、可派生、可恢复、可承接超长篇与特殊剧情机制的连续性基础设施，而拆书只是这套基础设施最强的一条输入与派生路径。**
