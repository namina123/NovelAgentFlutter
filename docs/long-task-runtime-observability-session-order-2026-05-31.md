# NovelAgentFlutter 长任务运行现场合同与可观察性任务顺序文档

最后更新：2026-05-31

关联文档：

- `docs/long-task-mumu-gap-analysis-2026-05-31.md`
- `docs/long-task-mode-1-architecture.md`
- `docs/legacy-migration-boundary.md`
- `docs/mumuainovel-absorption-analysis.md`
- `docs/migration-progress.md`

---

## 1. 这份文档解决什么

根据 `references/MuMuAINovel-main` 与当前项目实际代码对照，长任务链路现在不是“没有 runtime”，而是缺一层正式的：

**长任务运行现场合同**

也就是让 GUI / CLI / 后续恢复入口都能稳定回答：

1. 当前长任务正在做什么
2. 当前处在哪个阶段
3. 当前关联哪条任务
4. 为什么暂停或停止
5. 下一步应该由系统继续，还是需要用户处理 checkpoint / repair / revision
6. 用户回来以后，如何低心智负担恢复现场

这条链不是重做长任务，不是复制 `MuMuAINovel` 的后台任务系统。

它只补我们当前确实缺的部分：

- 运行中阶段表达
- 运行现场投影
- Task Center 可观察性
- 恢复摘要
- focused test 与回归验证

---

## 2. 已有实现去重审计

后续执行这份文档时，必须先承认下面这些已经存在，避免重复造轮子。

### 2.1 已经实现，不要重做

1. 长任务共享 runtime
   - `ProjectWorkflowRuntimeService`
   - GUI / CLI 都走这条链
2. 长任务运行记录
   - `tracking/long_task_runs/*`
   - `LongTaskRunRecordService`
   - `LongTaskRunStepRecorderService`
3. 队列运行记录
   - `tracking/task_queue_runs/*`
   - queue-run 与 long-run 已经分开
4. checkpoint review / repair / revision 动作链
   - checkpoint review 已能落盘
   - action package 已有 GUI / CLI 映射
   - revision resolution 已有共享动作合同
5. markdown 回放
   - `LongTaskRunMarkdownRenderer`
   - `TaskQueueRecordRenderer`
6. 运行中心合同雏形
   - `LongTaskRunCenterContractService`
   - 已有 progress、active task、controls 等基础结构

### 2.2 已经部分实现，但需要升级

1. `LongTaskRunCenterContractService`
   - 已经能输出运行中心合同
   - 但 `progress.percent` 目前主要按成功任务数粗算
   - 还不是正式“运行现场快照”
2. `TaskCenterViewDataService`
   - 已经能列出 long task runs / task queue runs
   - 但 run item 只有 title / subtitle / log，缺少结构化现场字段
3. `resumeLongTaskRun`
   - 已能复用 queue-run 恢复推进
   - 但恢复前后的“用户可读现场摘要”不足

### 2.3 当前真正没做好的内容

1. 正式 progress snapshot 合同
2. runtime phase / active task / heartbeat 的统一投影
3. Task Center run item 的结构化现场字段
4. 恢复现场 brief
5. CLI 简短现场摘要
6. 针对这些合同的 focused test

---

## 3. 本轮冻结的产品与架构边界

### 3.1 不做 SaaS 后台任务模型

不引入：

- 后端数据库任务表
- Web 轮询 API
- 全局后台任务服务作为唯一真相源

我们的真相源仍是：

- 项目工作区
- long task run record
- task queue run record
- core 投影合同
- adapters 写盘

### 3.2 不把长任务降级成普通任务箱

长任务继续是项目级运行对象，不是“所有 AI 调用的后台列表”。

Task Center 增强的是：

- 当前项目长任务现场
- 当前项目任务链
- checkpoint / review / revision 的恢复与动作

不是新建一个“全局后台任务中心”。

### 3.3 不破坏 checkpoint / review / revision 主线

进度快照是补强，不是替代。

后续任何实现都不能让：

- checkpoint review
- action package
- revision resolution
- repair task

从主线退场。

### 3.4 不在 UI 层临时猜业务状态

运行阶段、进度、恢复摘要必须来自 core / adapter 的正式合同。

禁止让 widget 直接根据：

- `status`
- `stop_reason`
- `steps.length`
- markdown 文本

临时拼出业务判断。

### 3.5 不伪造连续进度条

如果运行时拿不到真实连续进度，就用：

- 阶段
- 当前任务
- 最近心跳
- 全局完成度
- 当前批次状态

不要为了视觉“像正在跑”而生成不可信百分比。

---

## 4. 推荐最终合同形状

这一节不是要求一次全部实现，但后续 session 应围绕它逐步收口。

### 4.1 `LongTaskProgressSnapshot`

建议字段：

- `schema_version`
- `run_id`
- `run_path`
- `status`
- `status_label`
- `phase`
- `phase_label`
- `message`
- `overall_percent`
- `runtime_percent`
- `phase_percent`
- `active_task`
- `active_task_title`
- `active_task_path`
- `waiting_user`
- `blocked`
- `blocker`
- `recommended_action_label`
- `heartbeat_at`
- `updated_at`

### 4.2 phase 建议枚举

先保持轻量，不做过细阶段。

建议首批：

- `idle`
- `ready`
- `queue_preflight`
- `running_task`
- `model_generating`
- `postprocessing`
- `checkpoint_reviewing`
- `waiting_checkpoint`
- `paused`
- `recovering`
- `failed`
- `completed`
- `stopped`

### 4.3 progress 分层

必须分开：

- `overall_percent`
  - 基于任务总数 / 成功数
  - 适合表达全局完成度
- `runtime_percent`
  - 当前运行批次或当前现场的粗略推进
  - 可以为空或回退到 overall
- `phase_percent`
  - 当前阶段内部进度
  - 没有真实依据时可以为空

### 4.4 恢复摘要

建议单独投影：

- `resume_title`
- `resume_summary`
- `last_step_summary`
- `next_action_summary`
- `requires_user_action`
- `action_package_available`
- `revision_resolution_available`

---

## 5. 总规则

后续每个 session 必须遵守：

1. 每次只完成一个具体任务
2. 如果上一轮卡在半截或出现关联错误，先收口，不开下一轮
3. 先做 core 合同，再接 adapters，再接 app view-data，最后处理 UI 与 CLI
4. 不把算法、状态推断、恢复判断写进 widget
5. 不把所有新字段直接塞进 run record 顶层，优先使用 projection / contract
6. 如果需要持久化 snapshot，只存最小事实，不存纯展示字段
7. 每轮都补 focused test 或明确为什么本轮只改文档/合同
8. 完成记录要写回本文，不要只口头说完成

---

## 6. Session 列表

---

## 6.1 Session LTO-01：建立长任务运行现场快照合同

### 本轮目标

先在 core 建立 `LongTaskProgressSnapshot` 或等价运行现场快照服务，不接 UI。

### 必读文件

- `docs/long-task-mumu-gap-analysis-2026-05-31.md`
- `packages/novel_agent_core/lib/src/workflow/long_task_run_record_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_run_step_recorder_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_next_batch_plan_service.dart`

### 必须完成

1. 新增 core 服务，例如：
   - `long_task_progress_snapshot_service.dart`
2. 从 run record + tasks + batch plan 生成结构化现场快照
3. 明确区分：
   - overall progress
   - runtime progress
   - phase progress
4. 首批 phase 不需要过细，但必须覆盖：
   - running
   - paused
   - waiting checkpoint / waiting user
   - failed
   - completed / stopped
5. 补 core focused test

### 本轮不要做

- 不改 `ProjectWorkflowRuntimeService`
- 不改 Task Center
- 不改 UI
- 不做心跳定时刷新

### 重点拆耦

- record 事实源
- progress snapshot 投影
- UI 展示字段

### 完成判定

- core 可以只凭 run record + tasks 产出稳定现场快照
- 不需要 widget 自己猜“当前正在做什么”

### 直接可用提示词

```text
按 docs/long-task-runtime-observability-session-order-2026-05-31.md 的 Session LTO-01 执行。只在 core 建立长任务运行现场快照合同与服务，从 long task run record、tasks、batch plan 产出 phase、progress、active task、waiting/blocked 等结构化字段，并补 focused test。不要改 ProjectWorkflowRuntimeService，不改 Task Center，不开启下一任务。
```

### 本轮完成记录（2026-05-31）

1. 已新增 core 服务：
   - `packages/novel_agent_core/lib/src/workflow/long_task_progress_snapshot_service.dart`
2. 已建立首版长任务运行现场快照合同，字段覆盖：
   - `phase`
   - `phase_label`
   - `message`
   - `overall_percent`
   - `runtime_percent`
   - `phase_percent`
   - `active_task`
   - `active_task_title`
   - `active_task_path`
   - `waiting_user`
   - `blocked`
   - `blocker`
   - `recommended_action_label`
   - `heartbeat_at`
   - `updated_at`
3. 当前 snapshot 由 run record + tasks + `LongTaskNextBatchPlanService` 推导，不依赖 UI 临时判断。
4. 已导出：
   - `src/workflow/long_task_progress_snapshot_service.dart`
5. 已补 focused test：
   - `packages/novel_agent_core/test/long_task_progress_snapshot_service_test.dart`
6. 测试覆盖：
   - runnable task batch -> `running_task`
   - ready checkpoint -> `waiting_checkpoint`
   - manual pause -> `paused`
   - failed task -> `failed`
7. 本轮刻意未做：
   - 未改 `ProjectWorkflowRuntimeService`
   - 未改 Task Center
   - 未接 `LongTaskRunCenterContractService`
   - 未改 UI
8. 已验证：
   - `dart format lib/src/workflow/long_task_progress_snapshot_service.dart test/long_task_progress_snapshot_service_test.dart lib/novel_agent_core.dart`
   - `dart analyze lib/src/workflow/long_task_progress_snapshot_service.dart test/long_task_progress_snapshot_service_test.dart lib/novel_agent_core.dart`
   - `dart test test/long_task_progress_snapshot_service_test.dart`

---

## 6.2 Session LTO-02：把运行现场快照接入运行中心合同

### 本轮目标

让 `LongTaskRunCenterContractService` 正式消费 LTO-01 的 snapshot，不再只靠粗略 progress。

### 必读文件

- `packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`
- LTO-01 新增的 snapshot service
- `packages/novel_agent_core/test/*long_task*`

### 必须完成

1. `runCenterContract(...)` 输出中加入 snapshot 字段或等价现场字段
2. 保留现有 controls / active_task / batch_plan 结构，不破坏旧调用点
3. 将原 `progress.percent` 分层为：
   - overall
   - runtime
   - phase
4. 保持旧字段兼容，必要时让旧 `progress.percent` 暂时指向 `overall_percent`
5. 补 focused test：
   - waiting checkpoint
   - paused
   - running
   - failed
   - completed

### 本轮不要做

- 不改 adapters 写盘
- 不改 app view-data
- 不改 CLI 输出

### 重点拆耦

- run center contract 是共享消费层
- snapshot service 是状态推导层

### 完成判定

- GUI / CLI 后续可以直接从 run center contract 读取现场状态

### 直接可用提示词

```text
按 docs/long-task-runtime-observability-session-order-2026-05-31.md 的 Session LTO-02 执行。只把 LTO-01 的长任务现场快照接入 LongTaskRunCenterContractService，分层输出 overall/runtime/phase progress，并保持现有 controls、active_task、batch_plan 兼容。不要改 adapters 和 Task Center，不开启下一任务。
```

### 本轮完成记录（2026-05-31）

1. 已将 `LongTaskRunCenterContractService` 正式接到 `LongTaskProgressSnapshotService`：
   - 新增可选依赖 `progressSnapshotService`
   - 默认内部自动构造 snapshot service
2. `runCenterContract(...)` 现在已输出：
   - `snapshot`
   - `phase`
   - `phase_label`
   - `message`
   - `waiting_user`
   - `blocked`
   - `blocker`
   - `recommended_action_label`
   - `heartbeat_at`
3. 已保持旧结构兼容：
   - `controls`
   - `active_task`
   - `batch_plan`
   - `progress.percent`
4. 已把 `progress` 分层扩为：
   - `percent`（兼容旧调用，当前指向 `overall_percent`）
   - `overall_percent`
   - `runtime_percent`
   - `phase_percent`
5. 已增强 `LongTaskRunCenterMarkdownRenderer`：
   - 新增阶段行
   - 新增现场 message 行
6. 已补 focused test 断言：
   - waiting checkpoint 合同会输出 `phase=waiting_checkpoint`
   - `waiting_user=true`
   - markdown 可见 `阶段：等待检查点`
7. 本轮刻意未做：
   - 未改 adapters
   - 未改 `ProjectWorkflowRuntimeService`
   - 未改 Task Center view-data
   - 未改 UI
8. 本轮涉及文件：
   - `packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`
   - `packages/novel_agent_core/lib/src/workflow/long_task_run_center_markdown_renderer.dart`
   - `packages/novel_agent_core/test/long_task_scheduler_services_test.dart`
9. 已验证：
   - `dart format lib/src/workflow/long_task_run_center_contract_service.dart lib/src/workflow/long_task_run_center_markdown_renderer.dart test/long_task_scheduler_services_test.dart`
   - `dart analyze lib/src/workflow/long_task_run_center_contract_service.dart lib/src/workflow/long_task_run_center_markdown_renderer.dart test/long_task_scheduler_services_test.dart`
   - `dart test test/long_task_scheduler_services_test.dart test/long_task_progress_snapshot_service_test.dart`

---

## 6.3 Session LTO-03：在项目 runtime 链路中稳定暴露现场合同

### 本轮目标

让 adapter 层的 `ProjectWorkflowRuntimeService` 能把新的 run center / snapshot 合同作为正式结果暴露给 GUI / CLI。

### 必读文件

- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
- `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`

### 必须完成

1. 在合适入口暴露新的现场合同：
   - `loadLongTaskRun(...)`
   - scheduler snapshot 相关入口
   - `runWorkflowTaskQueue(...)` 返回值
   - `pauseLongTaskRun(...)`
   - `resumeLongTaskRun(...)`
2. 不把纯 UI 字段写进 record 顶层
3. 如果需要落盘，只落最小 runtime facts
4. focused test 覆盖：
   - run queue 返回现场合同
   - pause 后合同显示 paused
   - resume 后合同显示 recovering / running

### 本轮不要做

- 不改 Task Center UI
- 不改 Task Center view-data
- 不改 CLI 文案

### 重点拆耦

- core 合同
- adapter 项目读写
- runtime 返回 envelope

### 完成判定

- app / CLI 不需要再自己组装 snapshot

### 直接可用提示词

```text
按 docs/long-task-runtime-observability-session-order-2026-05-31.md 的 Session LTO-03 执行。只在 ProjectWorkflowRuntimeService 中稳定暴露新的长任务现场合同，让 load/run/pause/resume 等入口返回可供 GUI/CLI 消费的 snapshot 或 run center contract。不要改 Task Center UI，不开启下一任务。
```

### 本轮完成记录（2026-05-31）

1. 已在 `ProjectWorkflowRuntimeService` 稳定暴露长任务现场合同：
   - `loadLongTaskRun(...)`
   - `pauseLongTaskRun(...)`
   - `runWorkflowTaskQueue(...)`
   - `resumeLongTaskRun(...)` 继续经由 queue 入口继承同一返回合同链
2. `loadLongTaskRun(...)` 现在会在原记录外追加：
   - `run_center_contract`
   - `scheduler_snapshot`
3. `pauseLongTaskRun(...)` 现在会返回：
   - `ok`
   - `record`
   - `run_center_contract`
   - `scheduler_snapshot`
4. `runWorkflowTaskQueue(...)` 现在会返回：
   - `long_task_run_center_contract`
   - 并继续保留原有 `record` / `long_task_record` / `stop_reason`
5. 本轮专门补了一层 adapter 边界兼容：
   - 新增 `_runCenterContractFromSchedulerSnapshot(...)`
   - 优先读取 snapshot 顶层 `run_center_contract`
   - 缺失时回退到 `scheduler_plan.run_center_contract`
   - 避免 core snapshot 包装层变化导致 GUI/CLI 再次拿到空合同
6. 为了降低消费心智负担，adapter 暴露出去的 `scheduler_snapshot` 也已补顶层镜像：
   - `scheduler_snapshot.run_center_contract`
   - 同时不改 run record 持久化结构
7. 已补 / 调整 focused test：
   - queue 运行结果包含 `long_task_run_center_contract.run_id`
   - queue 运行结果包含 `phase`
   - `loadLongTaskRun(...)` 会暴露 `run_center_contract`
   - `pauseLongTaskRun(...)` 会暴露 `phase=paused`
   - checkpoint action contract 用例已按当前 severity/disposition 规则对齐断言
8. 本轮刻意未做：
   - 未改 Task Center UI
   - 未改 Task Center view-data
   - 未改 CLI 文案
   - 未把展示字段写回 long task run record 顶层
9. 本轮涉及文件：
   - `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
   - `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`
10. 已验证：
   - `dart format lib/src/workflow/project_workflow_runtime_service.dart test/project_workflow_runtime_service_test.dart`
   - `dart analyze lib/src/workflow/project_workflow_runtime_service.dart test/project_workflow_runtime_service_test.dart`
   - `dart test test/project_workflow_runtime_service_test.dart`

---

## 6.4 Session LTO-04：扩展 Task Center view-data，先不重做页面

### 本轮目标

让 Task Center 的 view-data 正式承接现场合同，但只做数据层和轻量呈现，不大改页面布局。

### 必读文件

- `apps/novel_agent_app/lib/features/task_center/presentation/models/task_center_view_data.dart`
- `apps/novel_agent_app/lib/features/task_center/application/services/task_center_view_data_service.dart`
- `apps/novel_agent_app/lib/features/task_center/presentation/pages/task_center_page.dart`
- `apps/novel_agent_app/test/*task_center*`

### 必须完成

1. 扩展 `TaskCenterRunItemViewData`：
   - `statusLabel`
   - `phaseLabel`
   - `progressPercent`
   - `activeTaskTitle`
   - `updatedAt`
   - `isWaitingUser`
   - `controlSummary`
2. `TaskCenterViewDataService` 消费 LTO-03 暴露的现场合同
3. 保留现有 title / subtitle 兼容，避免页面一次性大改
4. 如果 `TaskCenterViewDataService` 明显变重，抽出：
   - `task_center_long_task_run_view_data_service.dart`
5. focused test 覆盖 run item 字段投影

### 本轮不要做

- 不重做 Task Center 页面布局
- 不加新导航
- 不改 checkpoint action panel

### 重点拆耦

- runtime contract
- app view-data
- widget 呈现

### 完成判定

- Task Center 数据层已经知道“当前长任务现场”，页面层无需再猜

### 直接可用提示词

```text
按 docs/long-task-runtime-observability-session-order-2026-05-31.md 的 Session LTO-04 执行。只扩展 Task Center 的长任务 run item view-data，让它消费新的 runtime snapshot / run center contract，增加 phase、progress、active task、waiting user、control summary 等字段。不要重做页面布局，不开启下一任务。
```

### 本轮完成记录（2026-05-31）

1. 已扩展 `TaskCenterRunItemViewData`，新增字段：
   - `statusLabel`
   - `phaseLabel`
   - `progressPercent`
   - `activeTaskTitle`
   - `updatedAt`
   - `isWaitingUser`
   - `controlSummary`
2. `TaskCenterViewDataService` 已开始正式消费 LTO-03 暴露的长任务现场合同：
   - 优先读取 `run_center_contract`
   - 缺失时回退到 `scheduler_snapshot.run_center_contract`
   - 再缺失时回退到 `scheduler_snapshot.scheduler_plan.run_center_contract`
3. 当前长任务 run item 映射已从合同投影：
   - `statusLabel`
   - `phaseLabel`
   - `progressPercent`
   - `activeTaskTitle`
   - `updatedAt`
   - `isWaitingUser`
   - `controlSummary`
4. 已保持现有页面兼容：
   - `title`
   - `subtitle`
   - `isSelected`
   仍然保留，未强迫 Task Center 页面本轮重构。
5. 当前 subtitle 也已开始轻量吸收现场字段：
   - phase
   - percent
   - active task
   - waiting user
   - 以及原 baseline / mode / stop reason / updatedAt
6. 本轮没有抽出新 mapper 文件：
   - 现阶段 `TaskCenterViewDataService` 增量仍可控
   - 等 LTO-05/LTO-06 真正继续扩展详情区与恢复 brief 时，再判断是否拆出 `task_center_long_task_run_view_data_service.dart`
7. 已补 focused test：
   - `apps/novel_agent_app/test/task_center_view_data_service_test.dart`
   - 覆盖 long task run item 对 `run_center_contract` 的字段投影
8. 补充边界确认：
   - 本轮只让 view-data “会消费正式合同”
   - 未扩大 app shell 对所有 long task run 列表项的批量 enrich 策略
   - 当前仍是“列表 records + 选中项 detail loadLongTaskRun(...)”的结构
   - 已把选中项 `loadLongTaskRun(...)` 返回的正式合同合并回对应列表 record，保证实际 Task Center 中选中 run item 能吃到 LTO-03 合同
   - 因此没有越界去做页面重构或全列表重拉策略
9. 本轮刻意未做：
   - 未重做 Task Center 页面布局
   - 未新增页面字段展示组件
   - 未改 checkpoint action panel
   - 未做全量 long run enrich 策略
10. 本轮涉及文件：
   - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
   - `apps/novel_agent_app/lib/features/task_center/presentation/models/task_center_view_data.dart`
   - `apps/novel_agent_app/lib/features/task_center/application/services/task_center_view_data_service.dart`
   - `apps/novel_agent_app/test/task_center_view_data_service_test.dart`
11. 已验证：
   - `dart format lib/app/state/app_shell_controller.dart lib/features/task_center/presentation/models/task_center_view_data.dart lib/features/task_center/application/services/task_center_view_data_service.dart test/task_center_view_data_service_test.dart`
   - `dart analyze lib/app/state/app_shell_controller.dart lib/features/task_center/presentation/models/task_center_view_data.dart lib/features/task_center/application/services/task_center_view_data_service.dart test/task_center_view_data_service_test.dart`
   - `flutter test test/task_center_view_data_service_test.dart`
   - `flutter test test/task_center_contract_action_view_data_service_test.dart`

---

## 6.5 Session LTO-05：Task Center 运行现场轻量可视化

### 本轮目标

在已有页面结构内，把 LTO-04 的字段轻量显示出来，让长任务列表和详情不再只是日志/摘要。

### 必读文件

- `apps/novel_agent_app/lib/features/task_center/presentation/pages/task_center_page.dart`
- `apps/novel_agent_app/lib/features/task_center/presentation/models/task_center_view_data.dart`
- 如已拆分，读取 `task_center_long_task_run_view_data_service.dart`

### 必须完成

1. long task run 列表项展示：
   - phase
   - progress
   - active task
   - waiting / blocked 状态
2. 详情区补一个轻量“运行现场”区块
3. 不删除 markdown 回放，只降低它作为唯一现场视图的职责
4. 视觉保持紧凑，不做大说明卡
5. focused widget test 或 golden test 覆盖：
   - running
   - waiting user
   - paused / failed

### 本轮不要做

- 不重做整个 Task Center
- 不新增后台任务页
- 不改左侧竖直栏入口

### 重点拆耦

- run item 紧凑呈现
- selected run 现场详情
- markdown 回放

### 完成判定

- 用户进入 Task Center 后能直接看懂长任务当前现场

### 直接可用提示词

```text
按 docs/long-task-runtime-observability-session-order-2026-05-31.md 的 Session LTO-05 执行。只在现有 Task Center 页面内轻量展示长任务运行现场：列表项和详情区显示 phase、progress、active task、waiting/blocked 状态，保留 markdown 回放但不让它继续承担唯一现场视图。不要重做整个页面，不开启下一任务。
```

### 本轮完成记录（2026-05-31）

1. 已在现有 Task Center 页面内轻量展示长任务运行现场：
   - 长任务列表项已不再只是 title/subtitle
   - 现在会显示 `statusLabel`、`phaseLabel`、`progressPercent`、`activeTaskTitle`、`updatedAt`、`isWaitingUser`、`controlSummary`
2. `TaskCenterDiagnosticsPanel` 已补运行现场摘要条：
   - 长任务运行 tab 顶部会显示当前选中 run 的轻量现场摘要
   - 保留 markdown 回放，不让它继续承担唯一现场视图
3. 长任务列表项 UI 已改为紧凑现场卡：
   - 支持 phase / progress / active task / waiting 状态的快速扫读
   - 视觉仍保持在现有 panel 风格内，没有重做整个 Task Center
4. 运行现场摘要条只来自已加载的 run item 合同：
   - 不在 widget 内重新推断状态
   - 不把算法、状态判断写进页面
5. 本轮只做了表现层轻量增强：
   - 未重做整个 Task Center
   - 未新增后台任务页
   - 未改左侧竖直栏入口
   - 未改 checkpoint action panel
6. 本轮专门补了 focused widget test：
   - `apps/novel_agent_app/test/task_center_diagnostics_panel_test.dart`
   - 覆盖“长任务运行”tab 的运行现场摘要
7. 本轮还保留了 LTO-04 的 app shell 合并结果：
   - 选中长任务详情合同仍会回填到列表项数据中
   - 这样页面右侧摘要和左侧列表项都能吃到 LTO-03 合同
8. 本轮涉及文件：
   - `apps/novel_agent_app/lib/features/task_center/presentation/widgets/task_center_diagnostics_panel.dart`
   - `apps/novel_agent_app/test/task_center_diagnostics_panel_test.dart`
9. 已验证：
   - `dart format lib/features/task_center/presentation/widgets/task_center_diagnostics_panel.dart test/task_center_diagnostics_panel_test.dart`
   - `dart analyze lib/features/task_center/presentation/widgets/task_center_diagnostics_panel.dart test/task_center_diagnostics_panel_test.dart`
   - `flutter test test/task_center_diagnostics_panel_test.dart`

---

## 6.6 Session LTO-06：恢复现场 brief 与 checkpoint/action 合同联动

### 本轮目标

补齐“用户回来后 10 秒内看懂现场”的恢复摘要，并让它复用现有 checkpoint / revision action contract。

### 必读文件

- `packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `apps/novel_agent_app/lib/features/task_center/application/services/task_center_contract_action_view_data_service.dart`
- `apps/novel_agent_app/lib/features/task_center/application/services/task_center_view_data_service.dart`

### 必须完成

1. 新增或扩展恢复摘要服务：
   - `long_task_resume_brief_service.dart`
   - 或在 run center contract 中加入 `resume_brief`
2. brief 至少包含：
   - 上次做到哪
   - 为什么停
   - 当前是否需要用户处理
   - 推荐下一动作
   - 是否有 checkpoint action / revision resolution
3. Task Center 详情区消费 brief
4. 不复制 action 判断逻辑，继续复用现有 action package / revision resolution
5. focused test 覆盖：
   - max_steps 停止
   - waiting checkpoint
   - failed step
   - manual pause

### 本轮不要做

- 不新增新的动作体系
- 不把 action package 重新写一套
- 不改 checkpoint review 生成逻辑

### 重点拆耦

- 恢复摘要
- checkpoint action contract
- revision resolution contract

### 完成判定

- 恢复不只是能继续执行，而是能让用户快速理解该怎么继续

### 直接可用提示词

```text
按 docs/long-task-runtime-observability-session-order-2026-05-31.md 的 Session LTO-06 执行。只补齐长任务恢复现场 brief，并让它复用现有 checkpoint action package 与 revision resolution 合同，说明上次做到哪、为什么停、是否需要用户处理和推荐下一动作。不要新造动作体系，不开启下一任务。
```

### 本轮完成记录（2026-05-31）

1. 已在 core 的 `LongTaskRunCenterContractService` 中补齐 `resume_brief`：
   - `resume_title`
   - `resume_summary`
   - `last_step_summary`
   - `next_action_summary`
   - `requires_user_action`
   - `action_package_available`
   - `revision_resolution_available`
2. `resume_brief` 的职责已明确限定为“解释现场”：
   - 说明上次做到哪
   - 说明为什么停
   - 说明当前是否需要用户处理
   - 说明建议下一动作
   - 不替代 checkpoint action package / revision resolution 的真实动作判断
3. brief 已继续复用现有动作主线，而没有新造动作体系：
   - checkpoint 仍由 `checkpointActionPackage` 决定是否可操作
   - revision 仍由 `revisionResolution` 决定是否可操作
   - brief 只补“这里为什么会停、该先看哪里”
4. adapter 层本轮未新增特殊桥接逻辑：
   - 因为 LTO-03 已经稳定透传 `run_center_contract`
   - `resume_brief` 已随 contract 自动出现在 `loadLongTaskRun(...)` / `pauseLongTaskRun(...)` / `runWorkflowTaskQueue(...)` 结果内
5. app 层已把 brief 接进 Task Center 详情区：
   - `TaskCenterViewData` 新增 `resumeBriefBody`
   - `TaskCenterViewDataService` 新增 `buildResumeBriefBody(...)`
   - `TaskCenterDetailPanel` 已展示恢复现场段落
6. brief 展示同时会提示动作区联动：
   - 若已有 checkpoint action package，会提示可在右侧上下文动作区处理
   - 若已有 revision resolution，会提示可在右侧上下文动作区处理
7. 已补 focused test：
   - core：
     - `packages/novel_agent_core/test/long_task_scheduler_services_test.dart`
     - 覆盖 waiting checkpoint / paused / failed 的 `resume_brief`
   - app：
     - `apps/novel_agent_app/test/task_center_view_data_service_test.dart`
     - `apps/novel_agent_app/test/task_center_detail_panel_test.dart`
8. 本轮刻意未做：
   - 未新增新的动作 contract
   - 未改 checkpoint review 生成逻辑
   - 未重写 revision resolution 逻辑
   - 未把 brief 再拆成单独 service 文件
9. 本轮涉及文件：
   - `packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`
   - `packages/novel_agent_core/test/long_task_scheduler_services_test.dart`
   - `apps/novel_agent_app/lib/features/task_center/presentation/models/task_center_view_data.dart`
   - `apps/novel_agent_app/lib/features/task_center/application/services/task_center_view_data_service.dart`
   - `apps/novel_agent_app/lib/features/task_center/presentation/widgets/task_center_detail_panel.dart`
   - `apps/novel_agent_app/lib/features/task_center/presentation/pages/task_center_page.dart`
   - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
   - `apps/novel_agent_app/test/task_center_view_data_service_test.dart`
   - `apps/novel_agent_app/test/task_center_detail_panel_test.dart`
10. 已验证：
   - `dart analyze lib/src/workflow/project_workflow_runtime_service.dart test/project_workflow_runtime_service_test.dart`（adapters）
   - `dart test test/project_workflow_runtime_service_test.dart`（adapters）
   - `dart analyze lib/src/workflow/long_task_run_center_contract_service.dart test/long_task_scheduler_services_test.dart`（core）
   - `dart test test/long_task_scheduler_services_test.dart`（core）
   - `dart analyze lib/features/task_center/presentation/models/task_center_view_data.dart lib/features/task_center/application/services/task_center_view_data_service.dart lib/features/task_center/presentation/widgets/task_center_detail_panel.dart lib/app/state/app_shell_controller.dart test/task_center_view_data_service_test.dart test/task_center_detail_panel_test.dart`（app）
   - `flutter test test/task_center_view_data_service_test.dart test/task_center_detail_panel_test.dart`（app）

---

## 6.7 Session LTO-07：CLI 简短现场摘要与兼容输出

### 本轮目标

让 CLI 在 run / pause / resume / preflight 时也能显示同一套现场摘要，但不改变命令语义。

### 必读文件

- `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`

### 必须完成

1. `workflow run-queue` 成功后输出：
   - phase
   - progress
   - active task
   - stop reason
   - next action summary
2. `workflow pause` / `workflow resume` 输出 brief 摘要
3. 保留原 JSON / record block 输出，不破坏调试能力
4. focused CLI probe 或 command test 覆盖关键输出

### 本轮不要做

- 不新增 CLI 子命令
- 不改 exit code 规则
- 不改 runtime 行为

### 重点拆耦

- runtime result
- CLI 输出提炼
- 调试 JSON 保留

### 完成判定

- CLI 与 GUI 使用同一套现场合同

### 直接可用提示词

```text
按 docs/long-task-runtime-observability-session-order-2026-05-31.md 的 Session LTO-07 执行。只让 CLI workflow run-queue/pause/resume/preflight 输出新的长任务现场摘要，保留原有 record/json 调试输出，不新增命令，不改变 exit code。不要改 Task Center，不开启下一任务。
```

### 本轮完成记录（2026-05-31）

1. 已让 CLI workflow 的共享结果输出新的长任务现场摘要：
   - `workflow run-queue`
   - `workflow pause`
   - `workflow resume`
   - `workflow preflight`
   这些入口现在可以从结果合同中提炼并输出同一套现场摘要。
2. CLI 摘要只做合同提炼，不改 runtime 行为：
   - 直接读取 `long_task_run_center_contract` / `run_center_contract`
   - 或从 `record.run_center_contract` 回退提取
   - 不在 CLI 层重新推断状态
3. CLI 已保留原有调试输出：
   - `response` 仍按原逻辑输出
   - `record` 仍按原逻辑输出
   - 新的“长任务现场摘要”只是额外块，不替换原 JSON / record block
4. 已将 CLI 摘要提炼逻辑抽成独立服务：
   - `WorkflowOutputSummaryService`
   - `WorkflowCommand` 只负责调用与打印
5. CLI 摘要至少覆盖：
   - 状态
   - 阶段
   - 进度
   - 当前任务
   - 停止原因 / 阻塞原因
   - 下一步
   - 恢复标题 / 摘要 / 最近停点 / 下一动作
6. 本轮未新增 CLI 子命令：
   - 仍然沿用现有 `workflow` 入口
   - 未改 exit code 规则
   - 未改 runtime 主行为
7. 因仓库当前没有现成 CLI `package:test` 依赖，本轮采用 focused probe 验证：
   - `apps/novel_agent_cli/tool/workflow_output_summary_probe.dart`
   - probe 直接用 Dart 断言提炼结果，执行通过即视为 CLI 摘要链可用
8. 本轮涉及文件：
   - `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
   - `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`
   - `apps/novel_agent_cli/tool/workflow_output_summary_probe.dart`
9. 已验证：
   - `dart analyze lib/commands/workflow/workflow_command.dart lib/commands/workflow/workflow_output_summary_service.dart tool/workflow_output_summary_probe.dart`
   - `dart run tool/workflow_output_summary_probe.dart`

---

## 6.8 Session LTO-08：运行中刷新与心跳策略审计

### 本轮目标

审视是否需要让 Task Center 在长任务运行中自动刷新现场，但不引入 Web 轮询 API。

### 必读文件

- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- `apps/novel_agent_app/lib/features/task_center/presentation/pages/task_center_page.dart`
- `packages/novel_agent_core/lib/src/runtime/default_long_task_heartbeat_policy.dart`
- `packages/novel_agent_core/lib/src/runtime/long_task_run_state_machine.dart`
- `packages/novel_agent_adapters/test/long_task_heartbeat_scheduler_test.dart`

### 必须完成

1. 审计现有 heartbeat / supervisor 是否已能支撑运行中刷新
2. 如果已有能力，接入 Task Center 刷新节奏
3. 如果能力不足，只补最小本地刷新策略
4. 不做远端 API 轮询
5. 不把刷新 timer 写成不可控的全局循环
6. focused test 覆盖：
   - 离开页面不继续无意义刷新
   - 当前项目切换后不读错 run
   - running 状态可刷新

### 本轮不要做

- 不新增后端
- 不做 Web SSE
- 不把所有页面都挂轮询

### 重点拆耦

- heartbeat policy
- app controller refresh
- Task Center 页面生命周期

### 完成判定

- 长任务运行中现场可以更新，但仍符合本地优先与项目作用域路线

### 直接可用提示词

```text
按 docs/long-task-runtime-observability-session-order-2026-05-31.md 的 Session LTO-08 执行。只审计并接入本地长任务运行中刷新/心跳策略，让 Task Center 能在运行中更新现场状态，但不引入 Web 轮询 API、SSE 或后台任务服务。不要改 runtime 主行为，不开启下一任务。
```

### 本轮完成记录（2026-05-31）

1. 已完成 heartbeat / supervisor 路线审计，并确认当前项目里真正可复用的事实源是：
   - `LongTaskRunStatus.isActive`
   - `RuntimeBaselineCatalogService`
   - `DefaultLongTaskHeartbeatPolicy`
   - `LongTaskStationController.refresh()`
2. 结合当前产品路由收束情况，本轮没有去给旧 Task Center 页面硬挂全局轮询，而是把“运行中本地刷新”接到当前实际可见的长任务总站：
   - `apps/novel_agent_app/lib/features/long_task_station/application/controllers/long_task_station_controller.dart`
3. 已新增最小刷新策略服务：
   - `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_runtime_refresh_policy_service.dart`
   - 只根据可见 run 的 active 状态和对应 runtime baseline 心跳间隔决定是否需要继续刷新，以及取哪一个本地刷新间隔
4. 已在 `LongTaskStationController` 接入受控单次 timer：
   - 只有开启 auto refresh 且存在 active run 时才会挂下一次刷新
   - 每次 tick 只触发一次 `refresh()`，刷新完成后再重新评估是否继续
   - 不做不可控的全局循环
5. 已把“离开页面停止无意义刷新”的守门放回壳层目的地切换：
   - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
   - 只有 `AppDestination.longTaskStation` 可见时才启用总站 auto refresh
   - 离开该主空间后会立即取消既有 timer
6. 这轮同时补了一层测试友好的细拆：
   - `LongTaskStationController` 现在支持注入 detail loader
   - 生产默认路径仍旧走原 `ProjectLongTaskStationDetailService`
   - 测试不需要再绑真实项目仓储与磁盘细节
7. 已补 focused test，覆盖本轮要求的三个核心边界：
   - running 状态会基于 heartbeat policy 挂刷新
   - paused 等非 active 状态不会继续刷新
   - 关闭 auto refresh（对应离开页面）后会取消已挂起的刷新
   - 当前项目筛选下，只会根据当前可见项目范围内的 run 决定是否刷新
8. 本轮刻意未做：
   - 未引入 Web 轮询 API
   - 未引入 SSE
   - 未新增后台任务服务
   - 未改 runtime 主行为
   - 未把状态判断塞进 widget
9. 本轮涉及文件：
   - `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_runtime_refresh_policy_service.dart`
   - `apps/novel_agent_app/lib/features/long_task_station/application/controllers/long_task_station_controller.dart`
   - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
   - `apps/novel_agent_app/test/long_task_station_runtime_refresh_policy_service_test.dart`
   - `apps/novel_agent_app/test/long_task_station_controller_auto_refresh_test.dart`
10. 已验证：
   - `dart format lib/features/long_task_station/application/services/long_task_station_runtime_refresh_policy_service.dart lib/features/long_task_station/application/controllers/long_task_station_controller.dart lib/app/state/app_shell_controller.dart test/long_task_station_runtime_refresh_policy_service_test.dart test/long_task_station_controller_auto_refresh_test.dart`（`apps/novel_agent_app`）
   - `dart analyze lib/features/long_task_station/application/services/long_task_station_runtime_refresh_policy_service.dart lib/features/long_task_station/application/controllers/long_task_station_controller.dart lib/app/state/app_shell_controller.dart test/long_task_station_runtime_refresh_policy_service_test.dart test/long_task_station_controller_auto_refresh_test.dart`（`apps/novel_agent_app`）
   - `flutter test test/long_task_station_runtime_refresh_policy_service_test.dart test/long_task_station_controller_auto_refresh_test.dart`（`apps/novel_agent_app`）

---

## 6.9 Session LTO-09：总回归、截图核验与文档回填

### 本轮目标

做整条链的 focused test、截图核验和完成记录。

### 必须完成

1. 跑完 core / adapters / app focused test：
   - progress snapshot
   - run center contract
   - ProjectWorkflowRuntimeService 暴露合同
   - Task Center view-data
   - Task Center 现场呈现
   - resume brief
   - CLI 摘要
2. 生成关键截图：
   - running long task
   - paused long task
   - waiting checkpoint
   - failed step
   - completed/stopped
3. 回填本文各 session 完成记录
4. 如用户要求，再进行打包

### 本轮不要做

- 不开新功能
- 不重做 Task Center 视觉
- 不继续扩展后台任务模型

### 完成判定

- 长任务现场合同链从 core 到 app/CLI 都有验证
- 用户能在 Task Center 明确看懂当前长任务现场

### 直接可用提示词

```text
按 docs/long-task-runtime-observability-session-order-2026-05-31.md 的 Session LTO-09 执行。只做长任务运行现场合同链的总回归、截图核验与文档回填，覆盖 running、paused、waiting checkpoint、failed、completed/stopped 等状态。如需打包再打包。不要加新功能，不开启下一任务。
```

### 本轮完成记录（2026-05-31）

1. 已完成整条长任务运行现场合同链 focused 回归，覆盖：
   - core
     - `packages/novel_agent_core/test/long_task_progress_snapshot_service_test.dart`
     - `packages/novel_agent_core/test/long_task_scheduler_services_test.dart`
   - adapters
     - `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`
   - app
     - `apps/novel_agent_app/test/task_center_view_data_service_test.dart`
     - `apps/novel_agent_app/test/task_center_diagnostics_panel_test.dart`
     - `apps/novel_agent_app/test/task_center_detail_panel_test.dart`
     - `apps/novel_agent_app/test/long_task_station_runtime_refresh_policy_service_test.dart`
     - `apps/novel_agent_app/test/long_task_station_controller_auto_refresh_test.dart`
   - CLI
     - `apps/novel_agent_cli/tool/workflow_output_summary_probe.dart`
2. 本轮回归结果已全部通过，没有发现需要先回头修的半成品或关联错误。
3. 已补 LTO-09 视觉核验测试：
   - `apps/novel_agent_app/test/long_task_runtime_observability_visual_regression_test.dart`
4. 已生成并核验 5 张关键状态截图，产物位于：
   - `artifacts/long_task_runtime_observability_screenshots/`
   - 文件包括：
     - `lto09_running_long_task.png`
     - `lto09_paused_long_task.png`
     - `lto09_waiting_checkpoint.png`
     - `lto09_failed_step.png`
     - `lto09_completed_stopped.png`
5. 本轮截图策略保持收敛，没有为了截图重做页面装配：
   - running / paused / completed-stopped 使用 `TaskCenterDiagnosticsPanel`
   - waiting checkpoint / failed step 使用 `TaskCenterDetailPanel`
   - 重点验证的是“现场合同已经能稳定投影为可读界面”，而不是额外扩展后台任务模型
6. 本轮刻意未做：
   - 未新增任何 runtime 功能
   - 未重做 Task Center 视觉结构
   - 未扩展后台任务服务
   - 未打包
7. 本轮涉及文件：
   - `apps/novel_agent_app/test/long_task_runtime_observability_visual_regression_test.dart`
   - `artifacts/long_task_runtime_observability_screenshots/lto09_running_long_task.png`
   - `artifacts/long_task_runtime_observability_screenshots/lto09_paused_long_task.png`
   - `artifacts/long_task_runtime_observability_screenshots/lto09_waiting_checkpoint.png`
   - `artifacts/long_task_runtime_observability_screenshots/lto09_failed_step.png`
   - `artifacts/long_task_runtime_observability_screenshots/lto09_completed_stopped.png`
8. 已验证：
   - `dart test test/long_task_progress_snapshot_service_test.dart test/long_task_scheduler_services_test.dart`（`packages/novel_agent_core`）
   - `dart test test/project_workflow_runtime_service_test.dart`（`packages/novel_agent_adapters`）
   - `flutter test test/task_center_view_data_service_test.dart test/task_center_diagnostics_panel_test.dart test/task_center_detail_panel_test.dart test/long_task_station_runtime_refresh_policy_service_test.dart test/long_task_station_controller_auto_refresh_test.dart`（`apps/novel_agent_app`）
   - `dart run tool/workflow_output_summary_probe.dart`（`apps/novel_agent_cli`）
   - `dart analyze test/long_task_runtime_observability_visual_regression_test.dart`（`apps/novel_agent_app`）
   - `flutter test --update-goldens test/long_task_runtime_observability_visual_regression_test.dart`（`apps/novel_agent_app`）
   - `flutter test test/long_task_runtime_observability_visual_regression_test.dart`（`apps/novel_agent_app`）
9. 到本轮为止，LTO-01 到 LTO-09 已全部完成，这份顺序文档对应的长任务运行现场合同链已收口。

---

## 7. 建议推进方式

后续建议统一用下面这段话推进：

```text
根据目前的进度和文档：docs/long-task-runtime-observability-session-order-2026-05-31.md继续下一步，每次只确认完成一个具体的任务，如果上个会话末尾卡在具体任务的一半未完成或者出现了关联性错误，那么就先把这些做好，不需要开启下一轮任务；如果已经确认可以开启下一轮任务，那么可以直接开始。注意解耦合、单一职责、先 core 合同再 adapters 再 app view-data 再 UI/CLI，不要把状态判断写进 widget，不要照搬 MuMuAINovel 的后台任务服务。开始吧。
```

---

## 8. 最后一句定义

这条链最终不是为了做一个“更像后台任务列表的长任务页”，而是为了：

**把我们已经很强的长任务执行、检查点、审稿、修订体系，补上一层 GUI / CLI 共用、可恢复、可观察、低心智负担的运行现场合同。**
