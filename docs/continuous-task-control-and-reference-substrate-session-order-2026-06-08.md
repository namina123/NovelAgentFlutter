# NovelAgentFlutter 连续任务控制面与参考基底收口任务顺序文档

最后更新：2026-06-08

主线代号：`CTRS`（Continuous Task Runtime / Reference Substrate）

关联主分析文档：

- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
- `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md`
- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `agent.md`

关联历史任务顺序文档：

- `docs/project-information-substrate-session-order-2026-06-05.md`
- `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md`
- `docs/information-evidence-discipline-session-order-2026-06-05.md`
- `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md`
- `docs/release-readiness-productization-session-order-2026-06-05.md`

关联代码锚点：

- `packages/novel_agent_core/lib/src/reference_extraction/`
- `packages/novel_agent_core/lib/src/reference_substrate/`
- `packages/novel_agent_core/lib/src/information/`
- `packages/novel_agent_core/lib/src/continuity/`
- `packages/novel_agent_core/lib/src/workflow/`
- `packages/novel_agent_core/lib/src/tools/domain/`
- `packages/novel_agent_adapters/lib/src/reference_extraction/`
- `packages/novel_agent_adapters/lib/src/storage/`
- `packages/novel_agent_adapters/lib/src/workflow/`
- `packages/novel_agent_adapters/lib/src/runtime/`
- `packages/novel_agent_adapters/lib/src/tools/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/long_task_station/`
- `apps/novel_agent_app/lib/features/project_assets/`
- `apps/novel_agent_app/test/`
- `apps/novel_agent_app/tool/`
- `apps/novel_agent_cli/lib/commands/`

---

## 1. 这份文档解决什么

这份文档要解决的不是单点 bug，也不是只补哈利波特提取，而是把最近几轮已经分析清楚但仍分散在多份文档里的要求，收口成一条统一可执行的主线：

```text
把“长任务专属”味道过重的 runtime / watchdog / supervisor 视角，
正式提升为面向所有连续任务族的控制面；
同时把参考提取从“sqlite substrate + json 挂载 + md 大投影”的半收口状态，
推进到更接近 sqlite-first、source-identity-first、projection-lightweight 的终态。
```

它覆盖的终态包括：

1. `watchdog / supervisor / dispatcher / worker` 不再只服务长篇写作，也正式服务参考提取、研究整编、目标模式等连续任务族。
2. 参考提取不再停在“执行阶段有 sqlite，挂载阶段退回 json 仓储”的半状态。
3. `md` 投影回到轻摘要和人工校对定位，不再承担结构化事实源镜像。
4. 来源身份、证据锚点、挂载权限、工具暴露策略都能进入稳定合同。
5. 提取相关重工具默认绑定提取/研究智能体组，而不是污染普通写作线程。
6. 连续性冲突、作者失忆、设定回退等问题进入独立的证据保留与项目决议链，不塞进 `watchdog`。
7. GUI / CLI 只在稳定合同完成后消费，不反向承担业务补丁职责。

---

## 2. 与旧文档的关系

### 2.1 这不是平行新 runtime

本文件不允许再造：

1. 第二套连续任务控制面
2. 第二套参考提取挂载语义
3. 第二套稳定性探针真相
4. 第二套“更方便”的临时 supervisor / runtime service

正确方向是：

1. 复用并收口已有 `long-task + reference-extraction + project-information` 主链
2. 把共享能力上提成连续任务底座
3. 把专用差异压回 task profile、group profile、tool exposure policy

### 2.2 它吸收哪些旧主线

1. `PIS` 主线提供了共享信息基座方向，但参考提取挂载仍偏 `json + md projection`，还没进入最终形态。
2. `LTSR` 主线提供了 `watchdog / supervisor / review / repair` 的长任务稳定性结论，但还需要进一步泛化到所有连续任务族。
3. 参考提取分析文档已经把：
   - 摄取预算
   - 分批规划
   - 单并发默认纪律
   - 来源与证据
   - GUI 实提问题
   讲清楚了，但还没形成一份端到端实现顺序。

### 2.3 这份文档不处理什么

1. 不完整实现 CLI 产品化。
2. 不实现完整同人系统。
3. 不把快穿、死亡回归、哈利波特、修仙等测试题材写入 core。
4. 不把移动端系统级保活当成本轮必须交付的宿主能力；本轮重点仍是任务控制面可恢复、可继续、可诊断。

---

## 3. 已有实现去重审计

### 3.1 已有稳定基础，不重做

1. `SqliteReferenceEvidenceSubstrate` 已存在，不能推倒重来。
2. `ProjectReferenceAttachmentLayer` 已有基础能力。
3. `ReferenceSourceDocumentExtractionService` 的 bootstrap 定位已明确，不再拔高成整书完整提取引擎。
4. 长任务 `watchdog / supervisor / heartbeat / registry` 已有骨架。
5. `ProjectInformation` 的本地 repository、projection writer、activation bridge 已存在。
6. `Domain tool` 框架与智能体组加载框架已存在。
7. `ContextActivationReport`、continuity claims、semantic review 等共享合同已存在。

### 3.2 已有但仍是半闭环

1. 连续任务控制面仍偏“长任务章节队列”语义，提取/研究/目标模式没有完全成为一等公民。
2. 参考提取执行阶段使用了 sqlite substrate，但项目挂载出口仍指向本地 JSON 仓储。
3. 可读投影仍偏重，来源展示仍暴露绝对本地路径。
4. 提取预算/分批/覆盖/单并发纪律仍未正式进入 production 主链。
5. 提取类能力与写作类能力之间的暴露边界仍不够清晰。
6. 连续性冲突还没有正式的 `fact evidence / conflict cluster / canon decision` 收口链。

### 3.3 真正还缺的层

1. `continuous task family` 合同
2. `watchdog profile / supervisor profile / task profile` 合同
3. `reference source asset identity` 合同
4. `reference ingestion budget / batch plan / batch progress / coverage merge` 合同
5. `sqlite-first project information mount path`
6. `projection-lightweight` 与 `path-safe source display`
7. `tool exposure policy` 与 `capability family`
8. `conflict evidence / canon decision / review alert`
9. production 同源的 focused test / regression / probe 收口

---

## 4. 本轮冻结的架构边界

1. `watchdog` 只做活性与前进性监察，不做文学语义判断。
2. `supervisor` 做结构化调度决策，不直接替代提取、审稿或写作智能体。
3. 参考提取默认单并发主链，不把多并行做成默认实现。
4. 参考提取当前不是“再补一个 toolcall”问题，而是挂载出口与存储目标问题。
5. 重型提取工具默认只给提取/研究智能体组，不默认铺给写作组。
6. 参考提取的结构化事实源长期目标应是 `sqlite-first`；`json` 退回交换/兼容层，`md` 退回轻投影层。
7. 连续性冲突保留证据、由项目决议选择消费口径，不做简单覆盖。
8. probe 只消费 production 同源合同，不成为第二套业务中心。
9. GUI / CLI 只在稳定合同完成后接线，不在 UI / command 中硬写业务规则。
10. 任何单文件超过约 400 行都要主动复核职责；接近 700 行必须拆。

---

## 5. 目标终态

完成本主线后，应达到以下终态：

1. 项目拥有统一的 `continuous task control plane`，长任务、目标模式、参考提取、研究整编都只是不同 profile。
2. `watchdog`、`supervisor`、`dispatcher`、`worker` 边界清晰，所有连续任务族都能 pause / resume / retry / recover。
3. 参考提取从执行到项目挂载都走 `sqlite-first substrate`，不再默认退回本地 JSON 事实源。
4. 来源展示不再依赖绝对路径，而是稳定 `source_asset_id + display_name + resolver_uri`。
5. `md` 投影仅保留摘要、索引、人工校对草案，不再镜像大体量结构化快照。
6. 提取预算、分批规划、覆盖状态、单并发纪律正式进入 runtime 主链。
7. 提取类工具以智能体组和任务族为边界，通过暴露策略受控开放。
8. 连续性冲突以结构化证据保留、分簇、决议和审核提醒形式存在。
9. focused test、mock regression、real probe 都报告 production truth，而不是 probe-side 猜测。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `22` 个 session。

顺序理由：

1. `CTRS-01` 到 `CTRS-04` 先收口 core 合同与 failure / profile / identity 基线。
2. `CTRS-05` 到 `CTRS-08` 补齐参考提取与冲突处理的核心结构化合同。
3. `CTRS-09` 到 `CTRS-13` 收口 adapters / persistence / projection / mount path。
4. `CTRS-14` 到 `CTRS-17` 把 runtime、watchdog、supervisor、activation、tool exposure 接上统一主链。
5. `CTRS-18` 到 `CTRS-20` 做 focused tests、regression、real probe。
6. `CTRS-21` 到 `CTRS-22` 最后才做 GUI / CLI 最小消费与收口文档。

所有 session 都控制在单会话可完成范围内；过小任务已合并，避免无意义碎片化。

---

## 7. 全局执行规则

所有 session 均必须遵守：

1. 先读本文档、关联分析文档、`agent.md` 和当前 session 必读文件。
2. 只做当前 session，不开启下一任务。
3. 优先复用现有 contract / repository / runtime hook，不再起平行实现。
4. 保持 core / adapters / app / CLI 分层，不把业务判断推给 UI 或 probe。
5. focused test / contract test 与实现同轮落地；必要时再开 real probe。
6. 禁止把题材样本逻辑写进 core。
7. 不为了压低行数机械拆空壳文件；但也不允许继续堆大文件。

---

## 8. Sessions

## CTRS-01 基线审计与边界冻结

- 本轮目标：
  - 对已有连续任务控制面、参考提取挂载链、信息基底与 probe 现状做最终去重审计，形成本主线的实现基线。
- 层级归属：
  - Documentation / Core boundary audit
- 必读文件：
  - 本文档
  - `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
  - `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
  - `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart`
  - `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_mount_service.dart`
- 必须完成：
  - 列出当前真实 runtime 入口、挂载出口、投影出口、控制面入口
  - 标出可以复用与必须改写的具体类
  - 更新本文档完成记录占位
- 本轮不要做：
  - 不改 runtime 行为
  - 不补 probe
- 验收标准：
  - 能清楚说明“哪里已有、哪里半成品、哪里真缺口”
- 直接可用提示词：
  - 按 `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md` 的 `CTRS-01` 执行。先阅读本文档、`docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`、`docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md` 与参考提取 runtime / mount 代码。只做最终基线审计与边界冻结：列出连续任务控制面、挂载出口、投影出口的真实现状，明确哪些复用、哪些必须改写。不修改 runtime 行为，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

### CTRS-01 审计结论（2026-06-08）

- 当前真实 runtime 入口：
  - 连续任务控制面当前仍由长任务主线领跑。装配入口是 `packages/novel_agent_adapters/lib/src/bootstrap/adapter_bundle.dart` 中的 `LocalLongTaskRunRegistry -> LongTaskHeartbeatScheduler -> LongTaskWatchdog -> LongTaskSupervisor`；业务入口是 `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart` 的 `createLongTaskWorkflow / pauseLongTaskRun / resumeLongTaskRun`，GUI / CLI 分别经 `apps/novel_agent_app/lib/app/bootstrap/app_bootstrap.dart` 与 `apps/novel_agent_cli/lib/bootstrap/cli_bootstrap.dart` 注入消费。
  - 参考提取运行入口是 `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart` 的 `execute()`。它创建 `SqliteReferenceEvidenceSubstrate` 与 `FileReferenceExtractionStagingWorkspace`，随后调用 `ExecuteReferenceExtractionFromSourceDocumentUseCase.execute()`；这说明提取执行期已经是 `sqlite + staging`，不是纯 JSON。
- 当前真实挂载出口：
  - `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_mount_service.dart` 的 `attachAndProjectIfRequested()` 先调用 `SqliteProjectReferenceAttachmentLayer.upsertAttachment()` 写项目挂载关系，再进入 `ProjectReferenceProjectionService.projectMountedEntries()`。
  - 但 `ProjectReferenceExtractionMountService._buildProjectionService()` 仍现场组装 `LocalKnowledgeCardRepository`、`LocalDesignElementRepository`、`LocalResearchNoteRepository`、`LocalReferenceWorkRepository`，因此“提取完成 -> 项目主事实源”仍默认回落到 `.novel_agent/information/*.json`。
- 当前真实投影出口：
  - `packages/novel_agent_adapters/lib/src/storage/project_reference_projection_service.dart` 通过 `ReferenceEntryProjectionMapperService.buildDraftBundle()` 把 substrate entry 映射为项目层 draft，再调用各 `Local*Repository.update*()` 落盘。
  - `packages/novel_agent_adapters/lib/src/storage/project_information_projection_writer_service.dart` 从这些本地 repository 回读数据，交给 `packages/novel_agent_core/lib/src/information/information_markdown_projection_service.dart` 生成 `knowledge/*.md`、`research/*.md`、`references/*.md`。当前 `md` 仍附带大块“结构化参考快照（只读参考）”，尚未收回轻摘要定位。
- 当前真实控制面/消费入口：
  - `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart` 的 `buildTaskBridge()`，以及 `ProjectContextActivationService.buildReport()` + `ProjectInformationActivationBridgeService.buildItems()`，组成当前写作 / 审稿 runtime 的上下文激活入口，但信息资产来源仍是 `Local*Repository`。
  - `packages/novel_agent_adapters/lib/src/runtime/long_task_watchdog.dart` 当前只轮询 `LongTaskRunRegistry.listActive()` 并根据 `DefaultLongTaskHeartbeatPolicy` 派发 `heartbeat_due / stale_run` 事件；`packages/novel_agent_adapters/lib/src/runtime/long_task_supervisor.dart` 负责 registry 状态切换与写作结果信号收口。两者都仍是 `LongTask*` 命名和合同，尚未抽成所有连续任务族共享控制面。
- 可以直接复用：
  - `SqliteReferenceEvidenceSubstrate`
  - `ExecuteReferenceExtractionFromSourceDocumentUseCase`
  - `ReferenceSourceBatchPlannerService`、`ReferenceSourceBatchProgressService`
  - `ReferenceExtractionExecutionDiscipline`、`OutputBudgetPolicy`、`OmissionReport`、`ContinuationRequest`
  - `SqliteProjectReferenceAttachmentLayer`
  - `ProjectWorkflowRuntimeBridgeService` / `ProjectContextActivationService` 的宿主桥壳
  - `LocalLongTaskRunRegistry`、`LongTaskHeartbeatScheduler`、`LongTaskWatchdog`、`LongTaskSupervisor`、`SupervisorDecisionService` 的控制面骨架
- 必须改写 / 上提的边界：
  - `ProjectReferenceExtractionMountService`：当前把 attachment、projection、project fact sink 绑死在一起，且默认 sink 仍是 `Local*Repository`。
  - `ProjectReferenceProjectionService`：当前投影主路径是 “substrate entry -> project JSON repository”，尚未变成 sqlite-first 项目信息挂载桥。
  - `ProjectInformationProjectionWriterService` 与 `InformationMarkdownProjectionService`：当前仍输出重量级 md 快照，并以旧 `.novel_agent/information/*.json` 为 source-of-truth。
  - `ProjectInformationActivationBridgeService`：当前只从 `Local*Repository` 读项目信息，尚未从 attachment / substrate 稳定读取来源身份与证据身份。
  - `ProjectReferenceExtractionRuntimeService`：可继续作为提取入口，但尚未注册进共享 watchdog / supervisor 控制面。
  - `LocalLongTaskRunRegistry`、`LongTaskHeartbeatScheduler`、`LongTaskWatchdog`、`LongTaskSupervisor`、`DefaultLongTaskHeartbeatPolicy`：骨架可保留，但合同、命名与 profile 仍是 long-task-only，需要在后续 session 上提为 continuous-task family-aware 基座。
- 本轮基线判断：
  - 已有：提取执行期 `sqlite + staging + batch / coverage / output budget` 骨架已存在；长任务 watchdog / supervisor skeleton 已存在。
  - 半成品：项目挂载关系已进 sqlite attachment layer，但项目事实源、激活桥、md 投影仍回落到 local JSON / Markdown 侧。
  - 真缺口：统一 `continuous task family / profile`、sqlite-first 项目信息挂载出口、稳定来源身份合同、轻量投影、family-aware watchdog / supervisor 合同仍未正式收口。

## CTRS-02 连续任务族核心合同

- 本轮目标：
  - 引入面向所有连续任务族的核心合同，而不是继续默认“长任务 == 连续任务”。
- 层级归属：
  - Core / domain
- 必读文件：
  - `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
  - `packages/novel_agent_core/lib/src/workflow/`
  - `packages/novel_agent_core/lib/src/reference_extraction/`
- 必须完成：
  - 新增或收口 `ContinuousTaskFamily`、`ContinuousTaskProfile`、`ContinuousTaskRunKind`
  - 表达不同任务族共享的活性/恢复语义
  - focused contract tests
- 本轮不要做：
  - 不接 UI
  - 不改具体 watchdog 行为
- 验收标准：
  - 长任务、目标模式、参考提取、研究整编都能映射到同一族合同
- 直接可用提示词：
  - 按本文档的 `CTRS-02` 执行。只在 core 层补连续任务族核心合同，让长任务、目标模式、参考提取、研究整编共享同一控制面语义。不要接 UI，不改具体 runtime 行为。补 focused contract tests，不开启下一任务，注意解耦与单一职责。

### CTRS-02 实施结论（2026-06-08）

- 已新增 core 合同：
  - `packages/novel_agent_core/lib/src/workflow/continuous_task_family.dart`
  - `packages/novel_agent_core/lib/src/workflow/continuous_task_run_kind.dart`
  - `packages/novel_agent_core/lib/src/workflow/continuous_task_profile.dart`
  - `packages/novel_agent_core/lib/src/workflow/continuous_task_profile_resolver_service.dart`
- 本轮收口口径：
  - `ContinuousTaskFamilies` 统一表达 `long_form_writing / goal_mode / reference_extraction / research_consolidation`
  - `ContinuousTaskRunKinds` 统一表达 `chapter_queue / conversation_loop / batch_pipeline / research_sweep`
  - `ContinuousTaskProfile` 统一表达共享活性/恢复语义：`supports_pause / resume / retry / recovery / cancel`、`uses_durable_run_record`、`watchdog_eligible`、`supervisor_eligible`
  - `ContinuousTaskProfileResolverService` 已让长任务模式、目标模式、参考提取、研究整编都能映射到同一稳定 JSON 合同
- 本轮明确未做：
  - 未改 `LongTaskWatchdog`、`LongTaskSupervisor` 具体行为
  - 未接 UI / CLI
  - 未新造平行 runtime，仅新增 core 合同与 resolver
- focused tests：
  - `packages/novel_agent_core/test/continuous_task_profile_resolver_service_test.dart`
  - 额外回归 `packages/novel_agent_core/test/reference_extraction_strategy_profile_resolver_service_test.dart`，确认新合同未破坏现有 reference extraction strategy resolver

## CTRS-03 watchdog / supervisor profile 与 failure taxonomy

- 本轮目标：
  - 把所有连续任务族共享的 `watchdog / supervisor` profile 与 failure taxonomy 正式合同化。
- 层级归属：
  - Core / workflow
- 必读文件：
  - `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
  - `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
  - 现有 long-task heartbeat / supervisor 相关代码
- 必须完成：
  - 统一 pause / stop / cancel / complete / failed 状态语义
  - 引入 task-family-aware profile 合同
  - focused tests
- 本轮不要做：
  - 不实现具体重试调度
- 验收标准：
  - 任何连续任务实例都能声明自己的 watchdog / supervisor profile 与 stop reason 口径
- 直接可用提示词：
  - 执行 `CTRS-03`。只做 core 层的 watchdog / supervisor profile 与 failure taxonomy 合同收口，统一 pause、stop、cancel、complete、failed 语义。不要实现具体重试调度，不接 UI，不开启下一任务，补 focused tests。

### CTRS-03 实施结论（2026-06-08）

- 已完成事项：
  - 在 `packages/novel_agent_core/lib/src/workflow/` 新增共享连续任务控制合同：
    - `ContinuousTaskRunPhases`
    - `ContinuousTaskTerminalDispositions`
    - `ContinuousTaskStopCategories`
    - `ContinuousTaskLifecycleState`
    - `ContinuousTaskLifecycleStateResolverService`
    - `ContinuousTaskWatchdogProfile`
    - `ContinuousTaskSupervisorProfile`
    - `ContinuousTaskControlProfile`
    - `ContinuousTaskControlProfileResolverService`
  - `ContinuousTaskLifecycleStateResolverService` 明确把现有 `LongTaskRunStatus + LongTaskStopOutcome + legacy stop reason` 投影到统一的：
    - `pause`
    - `waiting_user`
    - `manual_attention`
    - `stopped`
    - `completed / cancelled / failed` terminal disposition
  - `LongTaskStopOutcomeCategories` 已改为直接复用 `ContinuousTaskStopCategories`，避免再长一套平行 failure taxonomy
  - `ContinuousTaskControlProfileResolverService` 已让长任务、目标模式、参考提取、研究整编都能声明自己的：
    - `watchdog_profile`
    - `supervisor_profile`
    - `supported_run_phases`
    - `supported_stop_categories`
  - `reference extraction` 的控制画像已显式保留：
    - 单主链默认 `default_concurrency = 1`
    - 仍走共享 watchdog / supervisor 语义，而不是另造 extraction-only 控制面
- 本轮明确未做：
  - 未改 `LongTaskWatchdog`、`LongTaskSupervisor`、heartbeat scheduler 的具体运行行为
  - 未实现具体 retry/backoff/recovery 调度
  - 未接 UI / CLI
  - 未新造 probe-side 业务判断；long-task 投影复用现有 `LongTaskStopOutcomeResolverService`
- focused tests / regression：
  - `packages/novel_agent_core/test/continuous_task_control_profile_resolver_service_test.dart`
  - `packages/novel_agent_core/test/continuous_task_lifecycle_state_resolver_service_test.dart`
  - `packages/novel_agent_core/test/continuous_task_profile_resolver_service_test.dart`
  - `packages/novel_agent_core/test/supervisor_decision_service_test.dart`
  - `packages/novel_agent_core/test/reference_extraction_strategy_profile_resolver_service_test.dart`
  - `packages/novel_agent_core/test/task_runtime_services_test.dart`

## CTRS-04 来源身份与解析合同

- 本轮目标：
  - 建立 `source_asset_id / display_name / source_kind / resolver_uri / local_hint_path` 这套稳定来源身份合同。
- 层级归属：
  - Core / information / reference substrate
- 必读文件：
  - `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md`
  - `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
  - 现有 `source_refs` / `evidence_refs` 合同
- 必须完成：
  - 定义稳定来源身份对象与编码规则
  - 明确绝对路径仅为可选 debug metadata
  - focused tests
- 本轮不要做：
  - 不改 sqlite schema
- 验收标准：
  - 来源身份不再依赖绝对路径才能成立
- 直接可用提示词：
  - 执行 `CTRS-04`。只做 core 层来源身份与解析合同：引入 `source_asset_id / display_name / resolver_uri / local_hint_path` 等字段语义，明确绝对路径只作为可选 debug metadata。不要改持久化 schema，不开启下一任务，补 focused tests。

### CTRS-04 实施结论（2026-06-08）

- 已完成事项：
  - 在 `packages/novel_agent_core/lib/src/common/source_asset_identity.dart` 新增共享 `SourceAssetIdentity` 合同，正式定义：
    - `source_asset_id`
    - `display_name`
    - `source_kind`
    - `resolver_uri`
    - `local_hint_path`
  - `SourceAssetIdentity.fromJson()` 已支持从以下口径宽兼容回读并投影到统一来源身份：
    - 新合同 `source_identity / source_asset_id / display_name / source_kind / resolver_uri / local_hint_path`
    - 旧合同 `source_type / source_id / label`
  - `NarrativeSourceRef` 已升级为双口径兼容：
    - 继续保留 `source_type / source_id / label`
    - 同时稳定输出 `source_asset_id / display_name / source_kind / resolver_uri / local_hint_path / source_identity`
  - `InformationSourceRef` 已正式透出 `sourceIdentity`，使 `source_refs` 不再只能靠旧 `source_type/source_id` 理解来源
  - `ReferenceSourceDocumentExtractionService` 已收口源文档来源身份：
    - 当上游给出绝对路径时，不再把绝对路径作为 `source_asset_id`
    - `local_hint_path` 会降级为相对/文件名提示
    - 绝对路径只进入 `debug_local_absolute_path` metadata
  - `ReferenceEntryProjectionMapperService` 与 `ProjectInformationPromotionMapperService` 已为：
    - `reference_substrate_entry`
    - `project_information_artifact`
    建立稳定 `resolver_uri`，避免后续 UI / CLI / activation 再各猜来源定位方式
- 本轮明确未做：
  - 未改 sqlite schema，也未改 `sqlite_reference_evidence_substrate` 的表结构
  - 未改挂载层持久化目标；sqlite-first 收口仍留待后续 session
  - 未接 UI / CLI
  - 未新造平行 source truth chain；现有 `NarrativeSourceRef / InformationSourceRef / source_refs / evidence_refs` 仍消费同一来源身份合同
- focused tests / regression：
  - `packages/novel_agent_core/test/source_asset_identity_contracts_test.dart`
  - `packages/novel_agent_core/test/reference_source_document_source_identity_test.dart`
  - `packages/novel_agent_core/test/narrative_reference_contracts_test.dart`
  - `packages/novel_agent_core/test/information_policy_contracts_test.dart`
  - `packages/novel_agent_core/test/reference_substrate_contracts_test.dart`
  - `packages/novel_agent_core/test/execute_reference_extraction_from_source_document_use_case_test.dart`
  - `packages/novel_agent_core/test/reference_extraction_strategy_profile_resolver_service_test.dart`

## CTRS-05 参考提取预算与分批合同

- 本轮目标：
  - 正式落下 `ReferenceIngestionBudgetPolicy / Resolver / BatchPlan / BatchProgress / CoverageMerge` 合同。
- 层级归属：
  - Core / reference extraction
- 必读文件：
  - `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
  - `packages/novel_agent_core/lib/src/reference_extraction/`
- 必须完成：
  - 预算、分批、覆盖、单并发策略的核心对象
  - 明确 structure-first、chapter-first、oversize split 语义
  - focused tests
- 本轮不要做：
  - 不接 runtime
- 验收标准：
  - 合同可以表达章节优先、结构优先、超限裂解、缺结构退化
- 直接可用提示词：
  - 执行 `CTRS-05`。只做 core 层参考提取预算与分批合同：`BudgetPolicy / Resolver / BatchPlan / BatchProgress / CoverageMerge`。不要接 runtime，不改 GUI，不开启下一任务，补 focused tests，并保持结构优先、预算逼近、超限裂解、缺结构退化的原则。

### CTRS-05 实施结论（2026-06-08）

- 已完成事项：
  - 在现有 `ReferenceIngestionBudgetPolicy / Resolution` 上正式补齐了批次策略合同：
    - `planning_mode`
    - `oversize_section_split_policy`
    - `batch_goal_kind`
    - `allow_structure_fallback`
  - `ReferenceIngestionBudgetResolverService` 现在会把这些策略语义一起投影到 resolved budget 合同里，而不是只返回字符预算
  - `ReferenceSourceBatchPlan` 已新增稳定计划语义：
    - `planning_mode`
    - `batch_goal_kind`
    - `structure_fallback_used`
    - `oversize_split_applied`
  - `ReferenceSourceBatchPlannerService` 已正式区分：
    - `structure_first`
    - `chapter_first`
    - `oversized_section_split`
    - 缺章节结构时的 `structure_fallback`
  - `ReferenceSourceBatchProgress` 已正式透出：
    - `pending_batch_count`
    - `consolidation_ready`
  - 已新增：
    - `ReferenceExtractionCoverageState`
    - `ReferenceExtractionCoveredRange`
    - `ReferenceExtractionCoverageMergeService`
  - `ReferenceExtractionCoverageMergeService` 现在可以把：
    - `batch plan`
    - `batch progress`
    - `proposal.coverageDimensionIds`
    - `coverage ledger`
    - `omission reports`
    - `continuation requests`
    合并为正式 coverage state，输出：
    - `total/completed/failed/pending segment count`
    - `covered_section_ranges`
    - `requires_followup_segment_ids`
    - `covered/uncovered dimension ids`
    - `consolidation_ready`
  - 单并发主链约束本轮未另造新对象，而是继续复用现有 `ReferenceExtractionExecutionDiscipline`；新增 focused test 明确内置策略仍默认：
    - `concurrency_mode = single`
    - `max_concurrent_batches = 1`
    - `allow_parallel_heavy_text_consumption = false`
- 本轮明确未做：
  - 未改 GUI / CLI
  - 未新接 runtime 调度器；`ExecuteReferenceExtractionFromSourceDocumentUseCase` 继续消费既有 budget/planner/progress 主线
  - 未把多并行做成默认实现
  - 未改 sqlite schema 或挂载层持久化目标
- focused tests / regression：
  - `packages/novel_agent_core/test/reference_ingestion_budget_contracts_test.dart`
  - `packages/novel_agent_core/test/reference_source_batch_planner_service_test.dart`
  - `packages/novel_agent_core/test/reference_extraction_coverage_merge_service_test.dart`
  - `packages/novel_agent_core/test/execute_reference_extraction_from_source_document_use_case_test.dart`
  - `packages/novel_agent_core/test/reference_extraction_strategy_profile_resolver_service_test.dart`

## CTRS-06 连续性冲突与项目 canon 决议合同

- 本轮目标：
  - 建立 `fact evidence / conflict cluster / project canon decision / review alert` 合同。
- 层级归属：
  - Core / continuity / information
- 必读文件：
  - `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
  - `packages/novel_agent_core/lib/src/continuity/`
- 必须完成：
  - 冲突簇、决议、提醒的核心模型
  - 至少覆盖正常演化、条件性变化、视角差异、未解释冲突、高疑似失误
  - focused tests
- 本轮不要做：
  - 不做智能体提示词
- 验收标准：
  - 同一主体属性的多版本事实可以共存并被结构化分类
- 直接可用提示词：
  - 执行 `CTRS-06`。只做 core 层连续性冲突与项目 canon 决议合同，建立 `fact evidence / conflict cluster / project canon decision / review alert` 这套模型。不要做提示词层，不开启下一任务，补 focused tests，保持证据先保留、后归并、再决议的原则。

### CTRS-06 实施结论（2026-06-08）

- 已完成事项：
  - 在 `packages/novel_agent_core/lib/src/continuity/narrative_state/` 新增连续性冲突与 canon 决议核心合同：
    - `NarrativeFactEvidence`
    - `NarrativeConflictCluster`
    - `ProjectCanonDecision`
    - `ContinuityReviewAlert`
    - `ContinuityConflictValidationCodes`
  - `NarrativeFactEvidence` 已正式把：
    - `subject_ref`
    - `attribute_key`
    - `value_payload`
    - `claim_snapshot`
    - `evidence_refs`
    - `source`
    收为稳定合同，确保“事实先保留证据与 claim 快照，再进入后续冲突归并”
  - `NarrativeConflictCluster` 已允许同一主体同一属性的多版本事实并存，并正式区分：
    - `normal_evolution`
    - `conditional_change`
    - `perspective_difference`
    - `worldline_or_memory_condition`
    - `unexplained_conflict`
    - `probable_author_error`
  - `ProjectCanonDecision` 已可表达项目级消费口径，而不是直接覆盖旧事实：
    - `adopt_primary_fact`
    - `keep_parallel_versions`
    - `adopt_conditional_interpretation`
    - `defer_unresolved`
    - `mark_probable_author_error`
  - `ContinuityReviewAlert` 已可把未解释冲突与高疑似失误升级为结构化提醒，而不是塞进 `watchdog` 或直接抹平事实
  - 所有新合同都直接复用现有：
    - `NarrativeStateClaim`
    - `NarrativeEvidenceRef`
    - `NarrativeRef`
    - `NarrativeSourceRef`
    没有新造平行事实链、平行证据链或平行冲突 runtime
  - `packages/novel_agent_core/lib/src/continuity/narrative_state.dart` 已导出这些新合同，保持 continuity 主线单出口
- 本轮明确未做：
  - 未实现自动冲突分类器、自动 canon 裁决器或提示词层逻辑
  - 未把连续性语义塞进 `watchdog` / supervisor
  - 未改 runtime、GUI / CLI、sqlite schema 或挂载目标
  - 未删除或覆盖旧事实；本轮只补“保留、归并、决议、提醒”的稳定合同
- focused tests / regression：
  - `packages/novel_agent_core/test/continuity_conflict_contracts_test.dart`
  - `packages/novel_agent_core/test/narrative_state_claim_contracts_test.dart`
  - `packages/novel_agent_core/test/narrative_semantic_review_contracts_test.dart`
  - `packages/novel_agent_core/test/semantic_review_information_bridge_service_test.dart`
  - `packages/novel_agent_core/test/narrative_state_ledger_contracts_test.dart`
  - `packages/novel_agent_core/test/continuity_contract_models_test.dart`

## CTRS-07 提取能力族与暴露策略合同

- 本轮目标：
  - 正式定义 `capability family + tool exposure policy + task profile binding`。
- 层级归属：
  - Core / tools / agent runtime
- 必读文件：
  - `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
  - 现有 domain tool catalog 与 agent group / loadout 相关代码
- 必须完成：
  - 抽象提取、研究、写作、审核等 capability family
  - 定义默认开放、需确认、仅宿主/监督层可调的暴露级别
  - focused tests
- 本轮不要做：
  - 不改具体 tool 实现
- 验收标准：
  - 能表达“提取组默认拥有重型提取工具，写作组默认只消费挂载结果”
- 直接可用提示词：
  - 执行 `CTRS-07`。只做 core 层 capability family 与 tool exposure policy 合同，不改具体 tool 实现。目标是让提取/研究/写作/审核等任务族可以声明默认工具暴露组合。补 focused tests，不开启下一任务。

## CTRS-08 sqlite substrate schema 扩展

- 本轮目标：
  - 在 sqlite substrate 层补来源身份、批次进度、覆盖状态、冲突/决议所需 schema。
- 层级归属：
  - Adapters / persistence
- 必读文件：
  - `packages/novel_agent_adapters/lib/src/storage/sqlite_reference_evidence_substrate.dart`
  - 相关 migrator / opener
  - `CTRS-04`、`CTRS-05`、`CTRS-06` 合同
- 必须完成：
  - 增量 schema 迁移
  - 读写接口扩展
  - focused persistence tests
- 本轮不要做：
  - 不改项目挂载出口
- 验收标准：
  - substrate 能稳定持久化来源身份、批次进度、覆盖状态等新合同
- 直接可用提示词：
  - 执行 `CTRS-08`。只做 adapters/persistence 层的 sqlite substrate schema 扩展，让来源身份、批次进度、覆盖状态、冲突相关数据可持久化。不要改项目挂载出口，不开启下一任务，补 focused persistence tests。

## CTRS-09 sqlite-first 项目信息挂载仓储

- 本轮目标：
  - 引入面向项目信息挂载的 sqlite-first 仓储或桥接层，替代直接写 `Local*Repository` 的默认出口。
- 层级归属：
  - Adapters / persistence
- 必读文件：
  - `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_mount_service.dart`
  - `packages/novel_agent_adapters/lib/src/storage/local_knowledge_card_repository.dart`
  - `packages/novel_agent_adapters/lib/src/storage/project_information_path_service.dart`
- 必须完成：
  - 抽出挂载出口接口
  - 让项目挂载主事实源可落到 sqlite-first 基底
  - 保留 json 兼容/导出位，但不再作为主出口
  - focused tests
- 本轮不要做：
  - 不接 GUI
- 验收标准：
  - “提取执行完成 -> 项目挂载” 不再天然写死到 `.novel_agent/information/*.json`
- 直接可用提示词：
  - 执行 `CTRS-09`。只改参考提取的项目挂载出口，把默认主事实源从 `Local*Repository` 直写 json 收口到 sqlite-first 仓储/桥接层。保留 json 兼容位，但不再让它做主出口。不要接 GUI，不开启下一任务，补 focused tests。

### CTRS-09 实施结论（2026-06-08）

- 已在 adapters/storage 层新增 sqlite-first 项目信息记录基底与四类仓储：
  - `packages/novel_agent_adapters/lib/src/storage/sqlite_project_information_record_store.dart`
  - `sqlite_knowledge_card_repository.dart`
  - `sqlite_design_element_repository.dart`
  - `sqlite_research_note_repository.dart`
  - `sqlite_reference_work_repository.dart`
- 已把挂载出口抽成稳定 port/factory：
  - `packages/novel_agent_adapters/lib/src/storage/project_reference_projection_port.dart`
  - `packages/novel_agent_adapters/lib/src/storage/sqlite_first_project_reference_projection_port_factory.dart`
  - `ProjectReferenceExtractionMountService` 不再现场组装 `Local*Repository`，默认改由 sqlite-first projection port 承接项目挂载。
- `ProjectReferenceProjectionService` 现支持“主出口 + 可选兼容导出”双层语义：
  - 主事实源写入默认走 sqlite-first repositories；
  - JSON 兼容路径收口为显式可选的 `ProjectInformationJsonCompatibilityExportService`，不再是默认主出口。
- 本轮明确未做：
  - 未改 GUI / CLI；
  - 未瘦身 `md` 投影；
  - 未把其余信息消费链从 `Local*Repository` 全量切换，这仍留给后续 session 按顺序推进。
- 验收结论：
  - “提取执行完成 -> 项目挂载” 默认已不再天然写死到 `.novel_agent/information/*.json`；
  - sqlite 数据库 `/.novel_agent/sqlite/novel_agent.db` 现在成为默认挂载事实源落点；
  - JSON 仍保留为显式 compatibility/export 位，而非默认真相链。

## CTRS-10 轻量投影与来源展示收口

- 本轮目标：
  - 让 `md` 投影回到轻摘要，并改掉绝对路径来源展示。
- 层级归属：
  - Core / Adapters / projection
- 必读文件：
  - `packages/novel_agent_core/lib/src/information/information_markdown_projection_service.dart`
  - `packages/novel_agent_adapters/lib/src/storage/project_information_projection_writer_service.dart`
- 必须完成：
  - 精简投影内容
  - 以 `source_display_name / source_asset_id` 为主展示来源
  - 为人工补充草案保留入口
  - focused tests
- 本轮不要做：
  - 不改数据事实源
- 验收标准：
  - 投影明显瘦身，且不再暴露绝对本地路径作为主来源名片
- 直接可用提示词：
  - 执行 `CTRS-10`。只做信息投影层收口：把 `md` 投影瘦成轻摘要，来源展示改为 `source_display_name / source_asset_id` 优先。不要改事实源语义，不开启下一任务，补 focused tests。

### CTRS-10 实施结论（2026-06-08）

- 已在 core/information 投影层收口轻摘要语义：
  - `packages/novel_agent_core/lib/src/information/information_markdown_projection_service.dart`
  - 四类信息投影都移除了整块“结构化参考快照”镜像，不再把完整 JSON 结构塞回 Markdown。
- 来源展示已切到稳定身份优先：
  - 知识卡、设计元素、引用作品边界现在用 `display_name + source_asset_id + source_kind` 生成来源身份摘要；
  - 研究笔记的来源定位会对绝对本地路径做安全降级，不再把绝对路径直接当作主来源名片输出。
- frontmatter 中的 `source_of_truth_paths` 已从旧 JSON 文件树路径收口为稳定逻辑标识：
  - 例如 `project-information://knowledge_cards`
  - 本轮没有改事实源本身，只改投影展示口径与人工补充入口。
- 人工补充入口仍保留：
  - `knowledge / design / research / reference work` 四类 draft block 都继续存在；
  - `InformationMarkdownBridgeService` 相关解析回归已保持通过。
- 本轮明确未做：
  - 未改 sqlite-first 数据事实源；
  - 未改 GUI / CLI；
  - 未扩展 activation/runtime/supervisor 行为。
- 验收结论：
  - Markdown 投影已明显瘦身，只保留摘要、来源身份/定位、风险与人工补充入口；
  - 投影不再把绝对本地路径作为主来源展示，也不再承担结构化事实源镜像职责。

## CTRS-11 批次规划接入 runtime 主链

- 本轮目标：
  - 把预算、分批、覆盖、单并发策略正式接进 reference extraction runtime。
- 层级归属：
  - Adapters / runtime
- 必读文件：
  - `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart`
  - `packages/novel_agent_adapters/lib/src/reference_extraction/llm_reference_extraction_proposal_generator.dart`
  - `CTRS-05`、`CTRS-08`
- 必须完成：
  - runtime 使用正式 batch plan
  - 记录 batch progress / coverage state
  - 明确单并发 execution discipline
  - focused runtime tests
- 本轮不要做：
  - 不做多并行默认实现
- 验收标准：
  - reference extraction runtime 不再只是 seed 式一次性主链
- 直接可用提示词：
  - 执行 `CTRS-11`。只改 reference extraction runtime，把预算、分批、覆盖状态、单并发纪律正式接进主链。不要做多并行默认实现，不开启下一任务，补 focused runtime tests。

### CTRS-11 实施结论（2026-06-08）

- 已把 runtime 结果正式接到 production 同源的 batch execution state：
  - `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart`
  - runtime 现在在 use case 执行完成后读取 `ReferenceEvidenceSubstrate.readBatchExecutionState(...)`，并用已持久化的 `batchPlan / batchProgress / coverageState / coverageLedger` 作为结果回报主依据，而不是只依赖 staging 临时态。
- `ProjectReferenceExtractionResult` 已扩展为可稳定回报：
  - 单并发执行纪律：`executionConcurrencyMode / executionMaxConcurrentBatches / allowParallelHeavyTextConsumption`
  - 正式分批信息：`batchPlanningMode / batchGoalKind / batchStructureMode`
  - 正式预算信息：`availableContextChars / batchTargetSourceChars / batchMaxSourceChars`
  - 正式进度与覆盖信息：`completedBatchCount / failedBatchCount / pendingBatchCount / coveredCoverageDimensionIds / uncoveredCoverageDimensionIds / followupSegmentIds / coverageRequiresFollowup`
- 单并发纪律本轮已在 runtime 结果侧变成可验证事实：
  - 即使策略画像请求 `reserved_parallel` 与更高并发数，runtime 最终仍回报经 production 主链归一化后的 `single + 1 + no parallel heavy text consumption`。
- 本轮顺带补齐上一 session 的 runtime 测试断裂：
  - `project_reference_extraction_runtime_service_test.dart` 里原先残留的 JSON 文件树主出口断言已改回 sqlite-first 口径，避免 probe side 继续把旧 JSON 路径当真相链。
- 本轮明确未做：
  - 未实现默认多并行；
  - 未改 watchdog / supervisor；
  - 未接 GUI / CLI。
- 验收结论：
  - reference extraction runtime 现已不再只是 seed 式一次性入口，而是正式回报预算、分批、覆盖与单并发纪律的 production 主链结果。

## CTRS-12 watchdog profile 泛化到提取/研究任务

- 本轮目标：
  - 让 `watchdog / supervisor profile` 不只服务长任务，也服务参考提取与研究整编。
- 层级归属：
  - Adapters / runtime / workflow
- 必读文件：
  - 现有 long-task watchdog / supervisor 代码
  - `CTRS-02`、`CTRS-03`
- 必须完成：
  - task-family-aware profile 接线
  - 提取/研究流程的 pause / resume / retry / recover 语义
  - focused tests
- 本轮不要做：
  - 不加新 UI
- 验收标准：
  - 参考提取是 watchdog 的正式对象，而非一次性例外
- 直接可用提示词：
  - 执行 `CTRS-12`。只把 watchdog / supervisor profile 泛化到参考提取与研究整编任务，不加新 UI。目标是让提取任务成为连续任务控制面的正式对象。补 focused tests，不开启下一任务。

### CTRS-12 实施结论（2026-06-08）

- 已完成项：
  - 新增共享 `ContinuousTaskLongTaskStatusMapperService`，把共享 `ContinuousTaskLifecycleState` 反向映射回现有 `LongTaskRunStatus`，避免参考提取/研究整编再长一套平行 run-status 语义。
  - `LongTaskSupervisor` 新增 `trackContinuousTaskRun / applyContinuousTaskState`，正式消费 `ContinuousTaskControlProfile + ContinuousTaskLifecycleState + LongTaskRecoveryState`，并把 `continuous_task_profile / control_profile / lifecycle_state` 写入同一个 `RunInstance.metadata`。
  - 新增 `ContinuousTaskSupervisorBridgeService`，用现有 `LongTaskSupervisor + LocalLongTaskRunRegistry + LongTaskWatchdog` 跟踪 reference extraction 与 research consolidation，统一提供 `pause / resume / recover / retry` 入口，不新造 extraction watchdog 或 research supervisor。
  - `ProjectReferenceExtractionRuntimeService` 现通过 `ReferenceExtractionContinuousTaskSyncService` 在 production 主链中把“启动中 / 覆盖未完成暂停 / 技术失败恢复 / publishable 完成停止”同步回共享运行站；CLI 与 App bootstrap 也已接入这条桥，形成最小稳定消费入口，但未新增 UI。
- focused 验证：
  - `packages/novel_agent_adapters/test/continuous_task_supervisor_bridge_service_test.dart`
  - `packages/novel_agent_adapters/test/long_task_supervisor_test.dart`
  - `packages/novel_agent_adapters/test/project_reference_extraction_runtime_service_test.dart`
- 本轮明确未做：
  - 未新增 UI。
  - 未新增平行 runtime / watchdog / supervisor / probe-side 状态判断。
  - 未改多并行默认纪律；参考提取仍沿用单并发主链真相。

## CTRS-13 tool exposure policy 接到智能体组与任务画像

- 本轮目标：
  - 把 `capability family / tool exposure policy` 接到智能体组和任务 profile 解析上。
- 层级归属：
  - Adapters / tools / workflow
- 必读文件：
  - 现有 agent group / loadout / runtime resolver 代码
  - `CTRS-07`
- 必须完成：
  - 提取组默认开放重型提取能力
  - 写作组默认只开放消费型能力
  - 通过 task profile 决定是否扩展权限
  - focused tests
- 本轮不要做：
  - 不大改单个 tool 内部
- 验收标准：
  - 工具开放边界能由任务画像与智能体组共同决定
- 直接可用提示词：
  - 执行 `CTRS-13`。只把 capability family 与 tool exposure policy 接到智能体组和任务画像解析上，让提取组与写作组默认能力边界清晰。不要大改单个 tool 内部，不开启下一任务，补 focused tests。

### CTRS-13 实施结论（2026-06-08）

- 已完成项：
  - 在 core 新增 `AgentGroupToolCapabilityScopeService`、`ContinuousTaskToolExposureRuntimeResolverService` 与 `ContinuousTaskToolExposureRuntimeResolution`，把“任务画像 + 智能体组 capability families + tool exposure profile”收口为同一份 runtime 解析合同。
  - builtin optional groups、starter groups 与 workflow single-member fallback group 现都能稳定声明 `tool_capability_family_ids`；写作组默认支持 `mounted_reference_consumption + writing + review + research`，提取/研究组默认支持 `mounted_reference_consumption + review + research + reference_extraction`。
  - `GenerateDraftUseCase`、`SubAgentEffectiveExecutionProfileService`、`ProjectWorkflowRuntimeBridgeService`、`ProjectWorkflowRuntimeService` 与 `ProjectConversationDraftRuntimeService` 现统一消费同源 resolver：普通章节/会话写作链默认裁掉重型提取工具，提取任务则只在提取组上正式开放重型提取能力。
  - workflow/runtime 现把 `continuous_task_tool_exposure_resolution` 写回 execution/main context，child run 与 bridge 均不再各自重写 probe-side 业务判断。
- focused 验证：
  - `packages/novel_agent_core/test/continuous_task_tool_exposure_runtime_resolver_service_test.dart`
  - `packages/novel_agent_core/test/draft_generation_use_case_test.dart`
  - `packages/novel_agent_adapters/test/project_workflow_runtime_bridge_service_test.dart`
  - `packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart`
  - `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`
  - 回归：`packages/novel_agent_adapters/test/continuous_task_supervisor_bridge_service_test.dart`、`long_task_supervisor_test.dart`、`project_reference_extraction_runtime_service_test.dart`
- 本轮明确未做：
  - 未大改单个 tool handler 内部。
  - 未新增平行 runtime / supervisor / mount / probe truth chain。
  - 未新增 GUI / CLI 业务补丁；表层仍只消费稳定合同。

## CTRS-14 信息激活桥与消费路径收口

- 本轮目标：
  - 让上下文激活桥消费 sqlite-first 信息基底与来源身份，而不是隐含依赖 json 文件树。
- 层级归属：
  - Adapters / workflow / activation
- 必读文件：
  - `packages/novel_agent_adapters/lib/src/workflow/project_information_activation_bridge_service.dart`
  - `packages/novel_agent_adapters/lib/src/workflow/project_context_activation_service.dart`
- 必须完成：
  - 激活候选读取从稳定基底出发
  - source refs / evidence refs / source display 同步进入 activation metadata
  - focused tests
- 本轮不要做：
  - 不改 GUI 渲染
- 验收标准：
  - 写作/审核/提取消费信息资产时不再依赖 json 文件树约定
- 直接可用提示词：
  - 执行 `CTRS-14`。只收口信息激活桥与消费路径，让 activation 从 sqlite-first 信息基底读取，并携带稳定的来源/证据身份。不要改 GUI，不开启下一任务，补 focused tests。

### CTRS-14 实施结论（2026-06-08）

- 已完成项：
  - `ProjectInformationActivationBridgeService` 默认已不再从 `Local*Repository` 读取信息资产，而是改为消费 sqlite-first `SqliteKnowledgeCardRepository / SqliteDesignElementRepository / SqliteResearchNoteRepository / SqliteReferenceWorkRepository`，让 activation 默认回到 `CTRS-09` 已建立的项目信息主事实源。
  - `ProjectInformationPathService` 新增 `project-information://...` 逻辑 locator，information activation item 的 `target_path` 与 fallback refs 已从旧 `.novel_agent/information/*.json` 路径切换到稳定 source-of-truth locator，不再把隐藏 json 文件树当成运行时消费真相链。
  - information activation metadata 现统一带出 `source_of_truth_locator`、`source_display`、`source_refs` 与可用的 `evidence_refs`；`ProjectContextActivationService` 生成的 `selected_context_sections / omitted_context_sections / truncated_context_sections` 也同步回写这些字段，让 workflow/conversation/runtime 能消费同源 activation 证据，而不是重新猜来源定位。
  - 普通 chapter conversation 与 workflow activation 相关 focused tests 已改为以 sqlite-first 项目信息仓储供数，并验证默认路径下不再需要 `.novel_agent/information/*.json` 主事实源文件存在。
- focused 验证：
  - `packages/novel_agent_adapters/test/project_information_activation_bridge_service_test.dart`
  - `packages/novel_agent_adapters/test/project_context_activation_service_test.dart`
  - `packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart`
  - `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`
  - 回归：`packages/novel_agent_adapters/test/project_workflow_runtime_bridge_service_test.dart`、`continuous_task_supervisor_bridge_service_test.dart`、`long_task_supervisor_test.dart`、`project_reference_extraction_runtime_service_test.dart`
- 本轮明确未做：
  - 未改 GUI 渲染或 CLI 表层消费。
  - 未大改 information tool executor / import / gateway 写入主链；本轮只收口 activation 默认读取口与 metadata。
  - 未新增平行 activation/probe-side 真相链。

## CTRS-15 连续性冲突持久化与决议桥

- 本轮目标：
  - 把 `conflict cluster / canon decision / review alert` 持久化并接入项目级工作流。
- 层级归属：
  - Adapters / persistence / workflow
- 必读文件：
  - `CTRS-06`
  - continuity 相关 repository / workflow 代码
- 必须完成：
  - 持久化入口
  - 项目级读取与最小工作流桥接
  - focused tests
- 本轮不要做：
  - 不实现复杂 UI 决策面板
- 验收标准：
  - 冲突不再只是临时分析结论，而能进入结构化项目资产
- 直接可用提示词：
  - 执行 `CTRS-15`。只做连续性冲突与项目 canon 决议的持久化和最小工作流桥接，不实现复杂 UI 面板。补 focused tests，不开启下一任务。

### CTRS-15 实施结论（2026-06-08）

- 已完成项：
  - `SqliteReferenceEvidenceSubstrate` 现新增 `reference_continuity_ledger` header 持久化层，`ReferenceEvidenceContinuityLedger` 的 `updated_at / metadata` 与“已初始化但暂无冲突”的空 ledger 状态可以稳定落库并读回，不再把空连续性账本误判为不存在。
  - `ProjectReferenceExtractionRuntimeService` 现通过 `ProjectReferenceContinuityBridgeService.ensureLedger(...)` 在 production 提取主链里为每次提取结果初始化 continuity ledger，并把 `conflictClusterCount / canonDecisionCount / reviewAlertCount / requiresManualContinuityReview / unresolvedConflictCount` 写回正式的 `ProjectReferenceExtractionResult`，让连续性决议信号进入 runtime 合同而不是停留在临时分析层。
  - `ProjectReferenceContinuityBridgeService` 现复用既有 `ProjectReferenceAttachmentLayer + ProjectReferenceAccessPolicyService + SqliteReferenceEvidenceSubstrate` 提供项目级 continuity report / 轻量 markdown summary，按挂载与访问策略读取已挂载参考包的 `conflict cluster / canon decision / review alert`，不新造平行挂载链或 probe-side 真相链。
  - `ProjectWorkflowRuntimeBridgeService` 已把 `reference_continuity_report / reference_continuity_context_markdown / reference_continuity_summary` 接入 workflow bridge 与 execution artifacts，最小工作流消费入口现可直接读到 continuity 决议状态，同时继续保持 GUI / CLI 只消费稳定合同、不承担底层业务判断。
- focused 验证：
  - `packages/novel_agent_adapters/test/project_reference_continuity_bridge_service_test.dart`
  - `packages/novel_agent_adapters/test/project_workflow_runtime_bridge_service_test.dart`
  - `packages/novel_agent_adapters/test/project_reference_extraction_runtime_service_test.dart`
  - `packages/novel_agent_adapters/test/sqlite_reference_evidence_substrate_test.dart`
  - 回归：`packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`、`project_conversation_draft_runtime_service_test.dart`
- 本轮明确未做：
  - 未实现复杂 UI 决策面板。
  - 未新增平行 runtime / supervisor / mount / probe truth chain。
  - 未把连续性语义判断塞进 watchdog，也未抢跑 `CTRS-16`。

## CTRS-16 supervisor 消费 coverage / mount / conflict 信号

- 本轮目标：
  - 让 supervisor 正式消费提取覆盖、挂载状态、冲突提醒等共享信号。
- 层级归属：
  - Adapters / runtime / supervisor
- 必读文件：
  - `CTRS-03`、`CTRS-11`、`CTRS-15`
  - 现有 supervisor 相关代码
- 必须完成：
  - 明确技术失败、覆盖未完成、挂载未完成、等待用户、内容冲突等不同结局
  - focused tests
- 本轮不要做：
  - 不写 probe 专属判断
- 验收标准：
  - supervisor 可以基于 production signal 做 continue / retry / pause / manual attention
- 直接可用提示词：
  - 执行 `CTRS-16`。只让 supervisor 正式消费 coverage、mount、conflict 等共享信号，区分技术失败、覆盖未完成、挂载未完成、等待用户、内容冲突等结局。不要写 probe 专属判断，不开启下一任务，补 focused tests。

### CTRS-16 实施结论（2026-06-09）

- 已完成项：
  - `ProjectReferenceExtractionResult` 现正式带出 `attachToProjectRequested / projectMountedEntriesRequested / projectMountStatus / projectMountWarningCodes`，让参考提取 runtime 的挂载/投影结果进入稳定 production 合同，而不是只靠 staging 结果或 probe 文本判断 supervisor 该怎么停。
  - adapters/reference_extraction 新增 `ReferenceExtractionSupervisorSignalService`，统一把 production 提取结果中的 `coverageRequiresFollowup / needsContinuation / projectMountStatus / projectMountWarningCodes / requiresManualContinuityReview / unresolvedConflictCount` 投影成连续任务控制面同源 `ContinuousTaskLifecycleState + metadata`；`watchdog` 继续只做保活，不承担任何内容语义或 probe-side 分支判断。
  - `ReferenceExtractionContinuousTaskSyncService` 现不再只按粗粒度 `runStatus` 回写 supervisor，而是正式消费上述共享信号，并把结果区分为：
    - 技术失败：`recovering + technical_failure`
    - 覆盖未完成：`paused + constraint_gate_pause + reference_coverage_followup_required`
    - 挂载等待用户确认：`waiting_user + reference_mount_confirmation_required`
    - 挂载未完成：`paused + constraint_gate_pause + reference_mount_incomplete`
    - 连续性内容冲突：`manual_attention + reference_continuity_conflict_requires_review`
    - 正常完成：`stopped + completed_naturally`
  - `ProjectReferenceExtractionRuntimeService` 现把挂载状态与 warning code 从真实 `ProjectReferenceExtractionMountService / ProjectReferenceProjectionService` 主链写回 runtime result，确保 supervisor 消费的是 sqlite-first / attachment-layer / projection-layer 的 production 信号，而不是另造一套挂载真相链。
- focused 验证：
  - `packages/novel_agent_adapters/test/project_reference_extraction_runtime_service_test.dart`
  - `packages/novel_agent_adapters/test/continuous_task_supervisor_bridge_service_test.dart`
  - `packages/novel_agent_adapters/test/long_task_supervisor_test.dart`
  - 回归：`packages/novel_agent_adapters/test/reference_substrate_chain_test.dart`、`project_reference_continuity_bridge_service_test.dart`
- 本轮明确未做：
  - 未写 probe 专属判断。
  - 未新增平行 supervisor / runtime / watchdog 决策链。
  - 未触碰 GUI / CLI 表层消费，也未抢跑 `CTRS-17`。

## CTRS-17 focused contract / persistence / runtime 回归

- 本轮目标：
  - 集中补齐本主线新增合同、持久化、runtime 的 focused tests。
- 层级归属：
  - Probe / regression / tests
- 必读文件：
  - 本主线前 16 个 session 的实现
- 必须完成：
  - 缺失 focused tests
  - 回归旧用例
  - 修复明显断裂
- 本轮不要做：
  - 不跑 real probe
- 验收标准：
  - 新增合同、持久化和 runtime 接线都有 focused test 保护
- 直接可用提示词：
  - 执行 `CTRS-17`。只做 focused contract/persistence/runtime 回归测试补齐与断裂修复，不跑 real probe，不开启下一任务。确保新增主线都有测试保护。

### CTRS-17 实施结论（2026-06-09）

- 已完成项：
  - 为 `CTRS-16` 新增的 `ReferenceExtractionSupervisorSignalService` 补上独立 focused unit test，并通过 `novel_agent_adapters.dart` 导出该服务，避免“挂载确认 / 挂载未完成 / 连续性冲突 / 覆盖续跑 / attach-only 完成态”的优先级判断只靠重型 runtime test 间接保护。
  - 保留并复跑了参考提取主链上的 runtime / persistence / continuity focused tests，确认 `ProjectReferenceExtractionResult` 新增的挂载状态合同、`SqliteReferenceEvidenceSubstrate` 的 continuity ledger header 持久化、`ProjectReferenceContinuityBridgeService` 的项目级 continuity 读取与 `ProjectWorkflowRuntimeBridgeService` 的 bridge 消费都没有在 `CTRS-16` 之后断裂。
  - 额外补跑 core 侧本主线关键合同/主链回归，覆盖来源身份、预算/分批合同、连续性冲突合同、reference substrate 合同、连续任务生命周期投影、工具暴露运行时解析与 reference extraction use case 主链，确保前 16 个 session 的核心 contract / persistence / runtime 增量仍由 focused test 保护，而不是只在高层集成里“看起来还能跑”。
- focused 验证：
  - adapters：
    - `packages/novel_agent_adapters/test/reference_extraction_supervisor_signal_service_test.dart`
    - `packages/novel_agent_adapters/test/project_reference_extraction_runtime_service_test.dart`
    - `packages/novel_agent_adapters/test/sqlite_reference_evidence_substrate_test.dart`
    - `packages/novel_agent_adapters/test/project_reference_continuity_bridge_service_test.dart`
    - `packages/novel_agent_adapters/test/project_workflow_runtime_bridge_service_test.dart`
    - `packages/novel_agent_adapters/test/reference_substrate_chain_test.dart`
  - core：
    - `packages/novel_agent_core/test/source_asset_identity_contracts_test.dart`
    - `packages/novel_agent_core/test/reference_ingestion_budget_contracts_test.dart`
    - `packages/novel_agent_core/test/continuity_conflict_contracts_test.dart`
    - `packages/novel_agent_core/test/reference_substrate_contracts_test.dart`
    - `packages/novel_agent_core/test/continuous_task_lifecycle_state_resolver_service_test.dart`
    - `packages/novel_agent_core/test/continuous_task_tool_exposure_runtime_resolver_service_test.dart`
    - `packages/novel_agent_core/test/execute_reference_extraction_from_source_document_use_case_test.dart`
- 本轮明确未做：
  - 未跑 real probe。
  - 未新增 probe-side 业务判断或平行 regression 真相链。
  - 未改 GUI / CLI 表层，也未抢跑 `CTRS-18`。

## CTRS-18 生产同源 regression suite

- 本轮目标：
  - 建立或收口 production 同源的 regression suite，覆盖长任务与参考提取共享控制面。
- 层级归属：
  - Probe / regression
- 必读文件：
  - 现有 mock regression 与 runtime suite
- 必须完成：
  - 区分技术失败、等待用户、覆盖未完成、内容冲突、正常完成
  - 避免 probe side 另写业务判断
- 本轮不要做：
  - 不改核心合同
- 验收标准：
  - regression suite 读的是 production truth，不是目录猜测
- 直接可用提示词：
  - 执行 `CTRS-18`。只收口 production 同源 regression suite，覆盖长任务与参考提取共享控制面，并区分技术失败、等待用户、覆盖未完成、内容冲突、正常完成。不要改核心合同，不开启下一任务。

### CTRS-18 实施结论（2026-06-09）

- 已新增 production 同源 regression suite：
  - `packages/novel_agent_adapters/test/continuous_task_control_plane_regression_suite_test.dart`
- 本轮 regression truth chain：
  - 长任务分支直接复用 `SupervisorDecisionService + SupervisorInputBundle.fromWritingExecutionResult(...) + ContinuousTaskLifecycleStateResolverService`，不在 probe / suite 侧重写技术失败、等待用户、人工介入或正常完成的判定逻辑。
  - 参考提取分支直接复用 `ReferenceExtractionSupervisorSignalService`，由 production signal 统一给出覆盖未完成、挂载等待确认、连续性冲突与正常完成的 lifecycle state / stop category。
- 本轮覆盖场景：
  - 长任务：`technical_failure / waiting_user / manual_attention / normal_completion`
  - 参考提取：`coverage_incomplete / mount_waiting_user / content_conflict / normal_completion`
  - 共享验收维度：`technical_failure / waiting_user / coverage_incomplete / content_conflict / normal_completion`
- 验收结论：
  - regression suite 读取的是 production truth contract，而不是目录结构、文件名或 probe-side stop reason 猜测；suite 只负责组装夹具与核对共享生命周期输出。
  - 本轮未改核心合同、未新增平行 supervisor / runtime / probe truth chain，也未抢跑 real probe 或 GUI / CLI。
- 本轮验证：
  - `dart test test/continuous_task_control_plane_regression_suite_test.dart test/reference_extraction_supervisor_signal_service_test.dart`
  - `dart test test/project_reference_extraction_runtime_service_test.dart`
  - `dart test test/supervisor_decision_service_test.dart`
  - `dart test test/continuous_task_lifecycle_state_resolver_service_test.dart`

## CTRS-19 哈利波特第一卷真实提取 probe

- 本轮目标：
  - 用 `references/files/Harry Potter - Volume 1 Raw.txt` 做真实提取 probe，验证 sqlite-first 挂载、来源身份、轻投影、coverage 状态是否成立。
- 层级归属：
  - Probe / real validation
- 必读文件：
  - 本主线相关实现
  - `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md`
- 必须完成：
  - 跑真实提取
  - 核查结果结构
  - 明确 common / tricky facts 覆盖情况
- 本轮不要做：
  - 不粉饰 provider 500
- 验收标准：
  - 结果能诚实区分“结构成功但上游波动”与“主链没接上”
- 直接可用提示词：
  - 执行 `CTRS-19`。使用 `references/files/Harry Potter - Volume 1 Raw.txt` 跑真实提取 probe，验证 sqlite-first 挂载、来源身份、轻投影、coverage 状态。诚实报告 common/tricky facts 覆盖，不粉饰 provider 500，不开启下一任务。

### CTRS-19 实施结论（2026-06-09）

- 本轮真实 probe 入口与产物：
  - 复跑 use-case 真实探针：`apps/novel_agent_app/tool/reference_extraction_real_probe.dart`
  - 新增 runtime 真实探针：`apps/novel_agent_app/tool/reference_extraction_runtime_real_probe.dart`
  - 最新产物：
    - `artifacts/reference_extraction_real_probe_report.json`
    - `artifacts/reference_extraction_runtime_real_probe_report.json`
- 当前 production 主链的真实结构结果：
  - use-case 真实探针已再次跑通，源文件确认为 `Harry Potter - Volume 1 Raw.txt`，`source_decode_mode=gbk`，`11` 个 batch 全部执行完毕。
  - 但当前 production 完整性合同已不再把“batch 全跑完”误判为正式完成：最新 use-case 报告中 `proposal_count=59`、`accepted=44`，同时 `output_completion_status=coverage_insufficient`、`delivery_status=staging_only`、`compression=high`、`finalized_entry_count=0`，并明确跳过 `package_finalize`。
  - runtime 真实探针同样给出一致方向的 production truth：`proposal_count=60`、`accepted=56`、`run_status=awaiting_semantic_continuation`、`output_completion_status=continuation_recommended`、`needs_continuation=true`、`coverage_requires_followup=true`、`finalized_entry_count=0`。
- sqlite-first 挂载、来源身份、轻投影验证：
  - runtime 真实探针报告显示 `attach_to_project_requested=true`、`project_mounted_entries_requested=true`，但由于当前没有 finalized package，`project_mount_status=missing_package`，`bundle_output_directory=""`，`generated_projection_paths=[]`。
  - 项目侧 `.novel_agent/sqlite/novel_agent.db` 在本次 runtime probe 中没有被误建，说明 sqlite-first 挂载链已按 production 合同正确收口为“未正式完成就不挂载、不投影”，而不是回退到 JSON / Markdown 假完成。
  - 来源身份样本已在最新 runtime probe 产物中稳定保留：`source_asset_id=workspace-file://Harry%20Potter%20-%20Volume%201%20Raw.txt`，并同时保留 `display_name / resolver_uri / local_hint_path`。
  - 因为本轮真实结果停在 `staging_only`，所以轻投影没有被生成；这符合“`md` 投影只服务已正式消费资产，不再镜像未完成结构化真相链”的主线要求。
- common / tricky facts 覆盖结论：
  - common facts 在当前 runtime staging proposals 中可见：`哈利 / 德思礼 / 海格 / 对角巷 / 女贞路` 均有明确标题或摘要命中。
  - tricky facts 不再像旧历史包那样只停在开篇导读：当前 runtime staging proposals 中已能直接检出 `分院帽`、`古灵阁`、`奇洛`、`麦格`、`伏地魔`、`厄里斯魔镜`、`魁地奇`、`斯莱特林`、`格兰芬多` 等第一卷中后段关键锚点。
  - 但覆盖仍未达正式消费门槛：`尼可勒梅` 在本轮最新 runtime probe 中仍未命中；同时 `covered_coverage_dimension_ids` 与 `uncovered_coverage_dimension_ids` 并存，说明系统已经能诚实表达“有明显进展，但语义覆盖仍未收口完成”。
- 关于 provider 500 / 超时与主链断裂的区分：
  - 历史 GUI/controller 真实 probe（`artifacts/real_gui_reference_extraction_probe_report.json`）记录过上游 `500`，本轮重跑旧 GUI probe 又在 `8` 分钟测试预算内超时，说明 GUI 探针口存在真实 provider 波动与长耗时现象。
  - 但本轮 use-case probe 与新增 runtime probe 都已在同一真实 provider 下跑出 production truth，且 runtime probe 能稳定给出 `delivery / coverage / mount / source identity` 结果；因此本轮应归类为“主链已接通，且能诚实阻止未达标结果进入正式挂载”，而不是“参考提取主链没接上”。
  - 也因此，本轮没有粉饰 provider 波动：GUI probe 的 `500/timeout` 被保留为真实风险事实，但不再被误判成 sqlite-first 挂载链本身断裂。

## CTRS-20 端到端消费验证

- 本轮目标：
  - 用真实提取结果驱动一次信息消费验证，证明写作侧消费的是真实参考资产，而不是裸猜。
- 层级归属：
  - Probe / end-to-end validation
- 必读文件：
  - `CTRS-19` 产物
  - 写作消费链相关代码
- 必须完成：
  - 用提取后的资产进行一次最小真实消费验证
  - 检查 activation metadata / source refs / evidence refs 是否进入写作上下文
- 本轮不要做：
  - 不做题材特化 core 修补
- 验收标准：
  - 至少一条真实消费链可证明信息资产被实际使用
- 直接可用提示词：
  - 执行 `CTRS-20`。只做端到端消费验证：用真实提取结果驱动一条最小写作或审稿消费链，证明上下文里真实带入了信息资产、来源和证据。不要做题材特化 core 修补，不开启下一任务。

### CTRS-20 实施结论（2026-06-09）

- 本轮真实消费 probe 入口与产物：
  - 更新并复跑 `apps/novel_agent_app/tool/real_reference_consumption_story_probe.dart`
  - 最新产物：
    - `artifacts/real_reference_consumption_story_probe_report.json`
    - `artifacts/real_reference_consumption_story_probe_report.md`
- 本轮 production 同源消费链证据：
  - probe 继续通过 `ProjectReferenceExtractionMountService` 挂载 `artifacts/reference_extraction_real_probe_workspace/hp_volume1_rerun_20260608/bundle`，并复用 sqlite-first 项目信息仓储与现有轻投影，不再回退旧 JSON projection truth chain。
  - 写作 runtime 已真实完成最小消费交付：最新报告 `story_generation.ok=true`，故事文件落为 `chapters/第一章_天师新生.md`，正文中可见 `霍格沃茨 / 哈利 / 罗恩 / 海格` 与 `调息 / 天师 / 符箓` 等消费痕迹。
  - activation report 现由 probe 直接读取 production `selected_context_sections` / `items[selected=true]` 合同，而不是靠 probe side 文本猜测；最新结果为：
    - `reported_selected_section_count=9`
    - `selected_section_count=3`（真正 materialized 进入上下文的 section）
    - `selected_with_source_refs=3`
    - `selected_with_evidence_refs=1`
    - `selected_with_project_information_locator=3`
  - 最新 selected sample 已同时覆盖：
    - `project-information://knowledge_cards/cultivation_knowledge_card_001`
    - `project-information://reference_works/...`
    说明这条写作链不只消费真实提取出的 reference 边界，也把带 `evidence_refs` 的知识卡正式带进了上下文。
- 本轮探针侧收口方式：
  - 修正了 `real_reference_consumption_story_probe.dart` 的 activation report 解析，严格读取 production report 的 `selected_context_sections / metadata.source_refs / metadata.evidence_refs / source_of_truth_locator`，不再因 JSON 结构读取偏差把已选中的上下文误判成 `0`。
  - 为 probe 内部自种的 `cultivation_knowledge_card_001` 明确声明 `required + pinned + preferred_budget_chars=260`，让 production activation planner 在不改 core 语义的前提下，稳定把一条带 `evidence_refs` 的知识资产注入本轮上下文；这仍然是同一条 production activation truth chain，不是 probe side 另写业务判断。
- 本轮明确未做：
  - 未改 GUI / CLI。
  - 未新增平行 runtime / supervisor / mount / probe truth chain。
  - 未做题材特化 core 修补，也未开启 `CTRS-21`。

## CTRS-21 GUI 最小消费与状态呈现

- 本轮目标：
  - 让 GUI 正确显示连续任务状态、来源身份、提取挂载结果和轻投影入口。
- 层级归属：
  - App / GUI
- 必读文件：
  - `apps/novel_agent_app/lib/features/workbench/`
  - `apps/novel_agent_app/lib/features/long_task_station/`
  - 本主线相关 read model / projection
- 必须完成：
  - 最小 GUI 接线
  - 不把业务判断推到 widget
  - focused UI/service tests 视风险补齐
- 本轮不要做：
  - 不重做界面风格
- 验收标准：
  - 用户至少能看懂：任务停在哪里、来源怎么显示、提取资产从哪里看
- 直接可用提示词：
  - 执行 `CTRS-21`。只做 GUI 最小消费与状态呈现接线，让用户能看懂连续任务状态、来源身份、提取挂载结果和轻投影入口。不要重做界面风格，不把业务判断塞进 widget，不开启下一任务。

### CTRS-21 实施结论（2026-06-09）

- 本轮已在 app/workbench 最小消费层接入 production 投影合同：
  - `WorkspaceInformationProjectionService` 现在直接从轻投影 markdown 的 frontmatter `source_of_truth_paths` 与正文 `来源身份：...` 行提取 GUI 所需的 `真相源 / 来源身份 / 已挂载` 字段，不新增 probe-side 真相链。
  - `WorkbenchInformationEntryViewData` 与 `ResourceInformationSection` 新增只读展示槽位，让用户在“资料与设定”里直接看到 `project-information://...` 真相定位、来源身份摘要与挂载状态，同时继续通过“打开摘要”进入轻投影文件。
- 本轮明确复用而未重写的部分：
  - 连续任务“停在哪里”继续复用现有 `WorkbenchProjectPanel` / `ProjectLongTaskSummaryPanel` 最小状态呈现，不新造平行 GUI runtime，不把 stop reason 判断搬进 widget。
- 本轮明确未做：
  - 未重做界面风格；
  - 未改长任务 / watchdog / supervisor / mount runtime；
  - 未开启 `CTRS-22`。
- 验收结论：
  - 用户现在可以在现有 GUI 中同时看懂：连续任务停在什么状态、资料来源怎么显示、提取资产挂载到哪个稳定真相源、以及从哪里打开轻投影回看内容。
- 本轮验证：
  - `flutter test test/workspace_information_projection_service_test.dart test/resource_manager_panel_test.dart test/workbench_project_panel_test.dart`

## CTRS-22 CLI 最小入口与总收口

- 本轮目标：
  - 给 CLI 接上最小稳定入口，并完成文档、handoff、剩余边界与项目级约束收口。
- 层级归属：
  - CLI / Documentation / handoff
- 必读文件：
  - `apps/novel_agent_cli/lib/commands/`
  - 本文档
  - `agent.md`
- 必须完成：
  - 最小 CLI 入口只消费稳定合同
  - 更新 handoff / 分析 / 约束
  - 记录剩余边界
- 本轮不要做：
  - 不把 CLI 做成另一个业务中心
- 验收标准：
  - CLI 至少有最小稳定入口，且所有剩余边界都有诚实记录
- 直接可用提示词：
  - 执行 `CTRS-22`。只做 CLI 最小稳定入口和总收口文档更新，让 CLI 消费稳定合同，不成为新的业务中心。诚实记录剩余边界，不开启下一任务。

### CTRS-22 实施结论（2026-06-09）

- 本轮已把 CLI 收口到最小稳定消费入口，而不是继续扩成业务中心：
  - `WorkflowOutputSummaryService` 新增参考提取摘要投影，直接复用 production `ReferenceExtractionSupervisorSignalService` 与 `ProjectReferenceExtractionResult`，统一输出控制面结论、停止原因、coverage/followup、挂载状态、continuity 摘要、资料产物与轻投影入口。
  - `workflow extract-reference` 不再在命令层散写 coverage / mount / continuity 判断，而是打印正式 `参考提取摘要` block。
  - `workflow pause` / `resume` 与 `pending-research` 继续保持 shared runtime / action service 消费壳层，不新增 CLI 专属业务判定。
- 本轮 handoff / 约束 / 剩余边界已收口到：
  - `docs/continuous-task-control-and-reference-substrate-cli-handoff-2026-06-09.md`
- 本轮明确未做：
  - 未把 CLI 做成完整工作台；
  - 未新增平行 runtime / supervisor / mount / probe truth chain；
  - 未把 source identity、continuity 决议或 sqlite 事实源做成 CLI 内联编辑器。
- 验收结论：
  - CLI 现在至少有一条稳定、同源、可验证的最小入口来消费连续任务控制面与参考提取主链结果，并且所有剩余边界都已诚实记录。
- 本轮验证：
  - `dart test test/workflow_output_summary_service_test.dart test/workflow_command_test.dart`
  - `dart analyze`
  - `dart run tool/workflow_output_summary_probe.dart`

---

## 9. 总启动提示词

```text
根据 `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md` 按顺序推进 `CTRS` 主线。先完整阅读本文档，再结合：

- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
- `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md`
- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
- `agent.md`

严格按 session 顺序执行，每次只完成一个 session，不抢跑下一任务。若发现上一个 session 还存在半完成、相关断裂或验收未过，先在当前 session 内把这些尾项收口，再确认完成。必须始终遵守：

1. 不再造平行 runtime。
2. 不把哈利波特、修仙、快穿等测试题材写死进 core。
3. 不把“没写成 sqlite”误判成“缺少 toolcall”；优先修挂载出口与持久化目标。
4. `watchdog` 服务所有连续任务族，不只服务长任务。
5. 重型提取工具默认只对提取/研究智能体组开放，并通过暴露策略受控扩展。
6. GUI / CLI 最后接线，只消费稳定合同。
7. 保持解耦合、单一职责、避免单文件过重；补 focused tests / contract tests / regression。

如果某轮做完后发现无法安全开启下一轮，请明确说明阻断点与剩余边界；否则只确认当前 session 完成，不额外开启新 session。
```

---

## 10. 完成记录占位

- `CTRS-01`：已完成（2026-06-08）。基线审计确认：提取执行期已走 `ProjectReferenceExtractionRuntimeService -> ExecuteReferenceExtractionFromSourceDocumentUseCase -> SqliteReferenceEvidenceSubstrate + staging`；项目挂载仍由 `ProjectReferenceExtractionMountService -> ProjectReferenceProjectionService -> Local*Repository -> ProjectInformationProjectionWriterService` 回落到 `.novel_agent/information/*.json + knowledge/*.md`；连续任务控制面当前仍是 `AdapterBundle.standard -> LocalLongTaskRunRegistry / LongTaskHeartbeatScheduler / LongTaskWatchdog / LongTaskSupervisor` 的 long-task-only 骨架，可复用但需在后续 session 泛化。
- `CTRS-02`：已完成（2026-06-08）。已在 core 层新增 `ContinuousTaskFamilies / ContinuousTaskRunKinds / ContinuousTaskProfile / ContinuousTaskProfileResolverService`，并让长任务、目标模式、参考提取、研究整编映射到同一连续任务合同；focused tests 与 reference extraction 相关回归已通过，且未改具体 watchdog/runtime/UI 行为。
- `CTRS-03`：已完成（2026-06-08）。已在 core/workflow 层新增共享 `ContinuousTaskRunPhases / TerminalDispositions / StopCategories / LifecycleState / WatchdogProfile / SupervisorProfile / ControlProfile` 合同，并用 `ContinuousTaskLifecycleStateResolverService` 将现有 long-task status + stop outcome 投影到统一 `pause / waiting_user / manual_attention / stopped / completed / cancelled / failed` 语义；`LongTaskStopOutcomeCategories` 现直接复用共享 taxonomy，长任务、目标模式、参考提取、研究整编都可声明 family-aware watchdog/supervisor profile，focused tests 与相关 regression 已通过，且未改具体 runtime/watchdog/UI 行为。
- `CTRS-04`：已完成（2026-06-08）。已在 core/common + continuity + information + reference_substrate 层新增共享 `SourceAssetIdentity` 合同，并让 `NarrativeSourceRef / InformationSourceRef / source_refs / evidence_refs` 宽兼容接入 `source_asset_id / display_name / source_kind / resolver_uri / local_hint_path`；源文档提取链已把绝对路径降级为 `debug` metadata，不再让来源身份依赖绝对路径成立，focused tests 与参考提取相关回归已通过，且未改 sqlite schema、挂载目标或 UI/CLI。
- `CTRS-05`：已完成（2026-06-08）。已在 core/reference_extraction 层补齐 `ReferenceIngestionBudgetPolicy / Resolver / BatchPlan / BatchProgress / CoverageState / CoverageMergeService` 合同，并让 budget 策略可正式表达 `structure_first / chapter_first / oversize split / structure fallback / batch goal`；planner 与 coverage merge focused tests 已证明章节优先、结构优先、超限裂解、缺结构退化与覆盖状态收口都进入稳定合同，同时保留内置策略默认单并发主链，且未改 GUI、sqlite schema 或多并行默认行为。
- `CTRS-06`：已完成（2026-06-08）。已在 core/continuity/narrative_state 层新增 `NarrativeFactEvidence / NarrativeConflictCluster / ProjectCanonDecision / ContinuityReviewAlert` 合同，并让同一主体属性的多版本事实可在复用现有 `NarrativeStateClaim / NarrativeEvidenceRef / NarrativeRef` 的前提下共存、分类、决议与提醒；focused tests 与 claim/review/ledger 回归已通过，且未把连续性语义塞进 watchdog、prompt 或 runtime。
- `CTRS-07`：已完成（2026-06-08）。已在 core/tools + core/workflow 层新增 `ToolCapabilityFamilyProfile / ToolCapabilityFamilyCatalogService / ToolExposureLevels / ToolCapabilityExposurePolicy / ContinuousTaskToolExposureProfile / ContinuousTaskToolExposureProfileResolverService`，正式把“能力族 -> 暴露级别 -> 连续任务画像绑定”收口成稳定合同；当前合同已能表达写作主链默认只消费挂载结果并把重型提取能力保留为 `host_or_supervisor_only`，同时让参考提取 / 研究整编任务默认开放研究与重型提取能力族，但不把连续任务控制与挂载提交权下放给普通线程。focused tests 与现有连续任务/工具暴露/参考提取组回归已通过，且未修改具体 tool handler、runtime 或 GUI/CLI 行为。
- `CTRS-08`：已完成（2026-06-08）。已在 core/reference_substrate + ports 与 adapters/storage 层新增 `ReferenceEvidenceBatchExecutionState / ReferenceEvidenceContinuityLedger / ReferenceSourceAssetLinkRecord` 合同，并把 `ReferenceEvidenceSubstrate` 扩展为可读写 `batch_plan + batch_progress + coverage_state + coverage_ledger + conflict_cluster + canon_decision + review_alert + source asset links` 的稳定接口；`SqliteReferenceEvidenceSubstrate` 现通过新增 `reference_source_asset / reference_entry_source_asset / reference_extraction_batch_state / reference_continuity_*` 表把来源身份、批次进度、覆盖状态与连续性冲突决议正式持久化，且 `ExecuteReferenceExtractionFromSourceDocumentUseCase` 已在 production 主链中同步回写 batch execution state，不再只停留在 staging JSON。focused persistence tests、提取主链回归与 continuity/reference substrate 合同回归已通过，且本轮未改项目挂载出口。
- `CTRS-09`：已完成（2026-06-08）。已在 adapters/storage + reference_extraction 层新增 `SqliteProjectInformationRecordStore` 与四类 sqlite-first 项目信息仓储，并用 `ProjectReferenceProjectionPort / SqliteFirstProjectReferenceProjectionPortFactory` 把参考提取挂载出口从 `ProjectReferenceExtractionMountService` 里解耦出来；默认挂载主事实源现写入 `/.novel_agent/sqlite/novel_agent.db`，不再天然回落到 `.novel_agent/information/*.json`。同时新增 `ProjectInformationJsonCompatibilityExportService` 作为显式可选导出位，保留 JSON 兼容路径但不再让它充当默认真相链。focused tests `project_reference_extraction_mount_service_test.dart`、`sqlite_project_information_repositories_test.dart`、`reference_substrate_chain_test.dart` 与 `project_information_projection_writer_service_test.dart` 已通过，且本轮未接 GUI / CLI、未改轻投影语义。
- `CTRS-10`：已完成（2026-06-08）。已在 `InformationMarkdownProjectionService` 把四类 Markdown 投影从“摘要 + 大块结构化参考快照”收口为轻摘要、来源身份/来源定位、风险提示和人工 draft 入口，并将 `source_of_truth_paths` 从旧 `.novel_agent/information/*.json` 路径替换为稳定逻辑标识如 `project-information://knowledge_cards`；知识卡、设计元素、引用作品边界现优先展示 `display_name + source_asset_id`，研究笔记对绝对本地路径来源做安全降级，不再把绝对路径当主来源名片。focused tests `packages/novel_agent_core/test/information_markdown_projection_services_test.dart`、`packages/novel_agent_adapters/test/project_information_projection_writer_service_test.dart` 与集成回归 `packages/novel_agent_adapters/test/reference_substrate_chain_test.dart`、`project_reference_extraction_mount_service_test.dart` 已通过，且本轮未改事实源语义、未接 GUI / CLI。
- `CTRS-11`：已完成（2026-06-08）。已在 adapters/reference_extraction 层把 runtime 结果正式接到 `ReferenceEvidenceSubstrate` 的 batch execution state：`ProjectReferenceExtractionRuntimeService` 现在会读取已持久化的 `batchPlan / batchProgress / coverageState / coverageLedger` 并回报到扩展后的 `ProjectReferenceExtractionResult`，包括正式预算、分批信息、批次完成度、覆盖维度与 followup 信号；同时 runtime 结果也会稳定回报经 production 主链归一化后的单并发执行纪律，确保“请求并行 ≠ 默认并行真相”。focused runtime tests `packages/novel_agent_adapters/test/project_reference_extraction_runtime_service_test.dart` 已验证 batch-state readback、chapter-first 规划、coverage 信号与 single-concurrency 归一化，相关回归 `project_reference_extraction_mount_service_test.dart`、`project_information_projection_writer_service_test.dart`、`reference_substrate_chain_test.dart` 已通过，且本轮未实现多并行默认主链、未改 watchdog / supervisor、未接 GUI / CLI。
- `CTRS-12`：已完成（2026-06-08）。已在 core/workflow + adapters/runtime/reference_extraction 层把共享 watchdog/supervisor 控制面真正泛化到参考提取与研究整编：`LongTaskSupervisor` 现可正式消费 `ContinuousTaskControlProfile + ContinuousTaskLifecycleState`，`ContinuousTaskSupervisorBridgeService` 复用现有 registry/watchdog/supervisor 跟踪非长任务连续任务族，`ProjectReferenceExtractionRuntimeService` 则通过 `ReferenceExtractionContinuousTaskSyncService` 把运行中、覆盖未完成暂停、技术失败恢复、publishable 完成等状态同步回同源 `RunInstance`。focused tests `continuous_task_supervisor_bridge_service_test.dart`、`long_task_supervisor_test.dart`、`project_reference_extraction_runtime_service_test.dart` 已通过，CLI / App bootstrap 也已接入最小稳定消费入口，且本轮未新增 UI、未新造平行 watchdog/runtime。
- `CTRS-13`：已完成（2026-06-08）。已在 core/agents + core/workflow 层新增 `AgentGroupToolCapabilityScopeService`、`ContinuousTaskToolExposureRuntimeResolverService` 与 `ContinuousTaskToolExposureRuntimeResolution`，把 capability family / tool exposure policy 正式接到“任务画像 + 智能体组 + runtime bridge / child run”同源合同上；builtin groups、starter groups 与 workflow single-member fallback group 现都能稳定声明 `tool_capability_family_ids`，普通写作/会话章节链默认裁掉 `request_external_research / propose_knowledge_card / propose_design_element / link_information_evidence / propose_reference_work` 等研究/重型提取能力，而参考提取任务只在提取组上正式开放 `research + reference_extraction` 能力族。focused tests `packages/novel_agent_core/test/continuous_task_tool_exposure_runtime_resolver_service_test.dart`、`draft_generation_use_case_test.dart`、`packages/novel_agent_adapters/test/project_workflow_runtime_bridge_service_test.dart`、`project_conversation_draft_runtime_service_test.dart`、`project_workflow_runtime_service_test.dart` 已通过，相关回归 `continuous_task_supervisor_bridge_service_test.dart`、`long_task_supervisor_test.dart`、`project_reference_extraction_runtime_service_test.dart` 亦通过，且本轮未大改单个 tool 内部、未新增平行 runtime / probe truth chain、未开启下一 session。
- `CTRS-14`：已完成（2026-06-08）。已在 adapters/workflow + storage 层把 information activation 默认读取口收回 sqlite-first 项目信息基底：`ProjectInformationActivationBridgeService` 现默认消费 `SqliteKnowledgeCardRepository / SqliteDesignElementRepository / SqliteResearchNoteRepository / SqliteReferenceWorkRepository`，并通过 `ProjectInformationPathService` 新增的 `project-information://...` locator 把 activation item 的 `target_path` 与 fallback refs 从旧 `.novel_agent/information/*.json` 路径切换到稳定 source-of-truth locator；同时 `source_of_truth_locator / source_display / source_refs / evidence_refs` 已同步进入 activation metadata 与 `selected_context_sections / omitted_context_sections / truncated_context_sections`。focused tests `project_information_activation_bridge_service_test.dart`、`project_context_activation_service_test.dart`、`project_conversation_draft_runtime_service_test.dart`、`project_workflow_runtime_service_test.dart` 已通过，相关回归 `project_workflow_runtime_bridge_service_test.dart`、`continuous_task_supervisor_bridge_service_test.dart`、`long_task_supervisor_test.dart`、`project_reference_extraction_runtime_service_test.dart` 亦通过，且本轮未改 GUI/CLI、未新造平行 activation 真相链、未开启下一 session。
- `CTRS-15`：已完成（2026-06-08）。已在 adapters/storage + reference_extraction + workflow 层把 continuity 冲突决议正式收口到 sqlite-first 参考基底：`SqliteReferenceEvidenceSubstrate` 新增 `reference_continuity_ledger` header 持久化，空 ledger 也能稳定读回；`ProjectReferenceExtractionRuntimeService` 现通过 `ProjectReferenceContinuityBridgeService.ensureLedger(...)` 在 production 提取主链初始化 continuity ledger，并把 `conflictClusterCount / canonDecisionCount / reviewAlertCount / requiresManualContinuityReview / unresolvedConflictCount` 写回 `ProjectReferenceExtractionResult`；`ProjectWorkflowRuntimeBridgeService` 同步暴露 `reference_continuity_report / reference_continuity_context_markdown / reference_continuity_summary` 作为最小工作流消费入口。focused tests `project_reference_continuity_bridge_service_test.dart`、`project_workflow_runtime_bridge_service_test.dart`、`project_reference_extraction_runtime_service_test.dart`、`sqlite_reference_evidence_substrate_test.dart` 已通过，相关回归 `project_workflow_runtime_service_test.dart`、`project_conversation_draft_runtime_service_test.dart` 亦通过，且本轮未改复杂 UI、未新造平行真相链、未开启下一 session。
- `CTRS-16`：已完成（2026-06-09）。已在 adapters/reference_extraction + runtime 层让 shared supervisor 正式消费参考提取的 production signal：`ProjectReferenceExtractionResult` 现稳定回报 `projectMountStatus / projectMountWarningCodes / attachToProjectRequested / projectMountedEntriesRequested`，`ReferenceExtractionSupervisorSignalService` 则把 `coverageRequiresFollowup / needsContinuation / mount status / mount warnings / requiresManualContinuityReview / unresolvedConflictCount` 统一投影成同源 `ContinuousTaskLifecycleState + metadata`；`ReferenceExtractionContinuousTaskSyncService` 因而可把技术失败、覆盖未完成、挂载等待确认、挂载未完成、连续性内容冲突与正常完成分别落成 `recovering / paused / waiting_user / manual_attention / stopped` 等明确结局，而不再只靠粗粒度 `runStatus` 或 probe-side stop reason。focused tests `project_reference_extraction_runtime_service_test.dart`、`continuous_task_supervisor_bridge_service_test.dart`、`long_task_supervisor_test.dart` 已通过，相关回归 `reference_substrate_chain_test.dart`、`project_reference_continuity_bridge_service_test.dart` 亦通过，且本轮未写 probe 专属判断、未新增平行 supervisor/watchdog 真相链、未开启下一 session。
- `CTRS-17`：已完成（2026-06-09）。已在 tests 层集中补齐本主线前 16 个 session 的 focused contract / persistence / runtime 保护面：`ReferenceExtractionSupervisorSignalService` 现有独立 focused unit test，`novel_agent_adapters.dart` 也已导出该服务，防止挂载确认/挂载未完成/连续性冲突/覆盖续跑等 supervisor signal precedence 只靠重型 runtime 回归间接覆盖；同时 adapters 侧已复跑 `project_reference_extraction_runtime_service_test.dart`、`sqlite_reference_evidence_substrate_test.dart`、`project_reference_continuity_bridge_service_test.dart`、`project_workflow_runtime_bridge_service_test.dart`、`reference_substrate_chain_test.dart`，core 侧已复跑 `source_asset_identity_contracts_test.dart`、`reference_ingestion_budget_contracts_test.dart`、`continuity_conflict_contracts_test.dart`、`reference_substrate_contracts_test.dart`、`continuous_task_lifecycle_state_resolver_service_test.dart`、`continuous_task_tool_exposure_runtime_resolver_service_test.dart`、`execute_reference_extraction_from_source_document_use_case_test.dart`，确认来源身份、预算/分批、冲突合同、sqlite substrate、continuous-task lifecycle、tool exposure 与 extraction use case 主链都有 focused test 保护。本轮未跑 real probe、未新增 probe-side 判断、未开启下一 session。
- `CTRS-18`：已完成（2026-06-09）。已新增 `packages/novel_agent_adapters/test/continuous_task_control_plane_regression_suite_test.dart` 作为 production 同源 regression suite，用 `SupervisorDecisionService + ContinuousTaskLifecycleStateResolverService` 与 `ReferenceExtractionSupervisorSignalService` 直接读取长任务、参考提取的共享控制面真相，覆盖技术失败、等待用户、覆盖未完成、内容冲突、正常完成五类验收维度；suite 不再依赖 probe-side 业务判断或目录猜测。focused regression `continuous_task_control_plane_regression_suite_test.dart`、`reference_extraction_supervisor_signal_service_test.dart`、`project_reference_extraction_runtime_service_test.dart`、`supervisor_decision_service_test.dart`、`continuous_task_lifecycle_state_resolver_service_test.dart` 已通过，且本轮未改核心合同、未开启下一 session。
- `CTRS-19`：已完成（2026-06-09）。已对 `references/files/Harry Potter - Volume 1 Raw.txt` 复跑真实提取，并新增 `apps/novel_agent_app/tool/reference_extraction_runtime_real_probe.dart` 以 production runtime 直接输出 `delivery / coverage / mount / source identity` 证据。最新 use-case 报告 `artifacts/reference_extraction_real_probe_report.json` 与 runtime 报告 `artifacts/reference_extraction_runtime_real_probe_report.json` 一致表明：当前主链已能把 `batch_coverage=1.00` 与 `semantic coverage` 分开，未达标时正式落成 `staging_only + coverage_insufficient/continuation_recommended + high compression risk`，不会再错误 finalize、错误挂载或错误生成轻投影；同时来源身份已稳定保留为 `source_asset_id + display_name + resolver_uri + local_hint_path`。common facts 已可见，tricky facts 已明显好于旧历史包，但 `尼可勒梅` 等缺口仍在，本轮因此诚实记录“主链接通且阻止假完成”，而不是把 GUI probe 的 `500/timeout` 粉饰成成功或误写成挂载链断裂。本轮未开启 `CTRS-20`。
- `CTRS-20`：已完成（2026-06-09）。已更新并复跑 `apps/novel_agent_app/tool/real_reference_consumption_story_probe.dart`，让 probe 直接读取 production activation report 的 `selected_context_sections / source_refs / evidence_refs / project-information locator` 合同，并用真实提取包 `artifacts/reference_extraction_real_probe_workspace/hp_volume1_rerun_20260608/bundle` 驱动一条最小写作消费链。最新报告 `artifacts/real_reference_consumption_story_probe_report.json` 表明：故事正式交付成功，真实进入上下文的 `3` 条 materialized section 中同时包含 reference work 与带 `evidence_refs` 的 knowledge card，`selected_with_source_refs=3`、`selected_with_evidence_refs=1`、`selected_with_project_information_locator=3`，从而证明写作侧实际消费了 sqlite-first 项目信息资产、来源身份与证据，而不是裸猜或 probe side 文本拼接。本轮未开启 `CTRS-21`。
- `CTRS-21`：已完成（2026-06-09）。已在 `apps/novel_agent_app` 的 workbench 最小消费层把 GUI 直接接到 production 轻投影合同：`WorkspaceInformationProjectionService` 现从 markdown frontmatter `source_of_truth_paths` 与正文 `来源身份：...` 行解析 `project-information://...` 真相定位、来源身份摘要与 `已挂载` 状态，`WorkbenchInformationEntryViewData` / `ResourceInformationSection` 则把这些信息显示在“资料与设定”条目里，同时保留“打开摘要”作为轻投影入口；连续任务状态侧继续复用现有 `WorkbenchProjectPanel` / `ProjectLongTaskSummaryPanel` 的稳定合同消费，不新造 GUI 业务判断。focused tests `workspace_information_projection_service_test.dart`、`resource_manager_panel_test.dart`、`workbench_project_panel_test.dart` 已通过，且本轮未重做界面风格、未改 runtime/supervisor/mount 主链、未开启下一 session。
- `CTRS-22`：已完成（2026-06-09）。已在 `apps/novel_agent_cli` 把 CLI 收口到最小稳定入口：`WorkflowOutputSummaryService` 新增参考提取摘要投影，并直接复用 `ReferenceExtractionSupervisorSignalService + ProjectReferenceExtractionResult` 这条 production 控制面合同来呈现 `control-plane outcome / stop reason / coverage followup / mount status / continuity summary / projection entry`；`workflow extract-reference` 现输出正式 `参考提取摘要` block，而不是在命令层散写优先级判断。与此同时，长任务 `pause/resume` 与 `pending-research` 入口继续保持 shared runtime / action service 壳层定位，剩余边界、handoff 与项目级约束已写入 `docs/continuous-task-control-and-reference-substrate-cli-handoff-2026-06-09.md`。验证已通过 `dart test test/workflow_output_summary_service_test.dart test/workflow_command_test.dart`、`dart analyze` 与 `dart run tool/workflow_output_summary_probe.dart`；本轮未把 CLI 做成第二业务中心，也未开启下一任务。
