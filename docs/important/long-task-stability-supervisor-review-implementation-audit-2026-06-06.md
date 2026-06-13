# 长任务稳定性 / 监督层 / 审核闭环实现审计 2026-06-06

关联主线：`LTSR-01`

关联文档：

- `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md`
- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- `docs/expression-constraint-execution-policy-session-order-2026-06-06.md`
- `docs/information-evidence-discipline-session-order-2026-06-05.md`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- `agent.md`

---

## 1. 本文结论

当前仓库已经具备长任务正式主链所需的大部分底座，但还没有把这些底座收口成一条统一、稳定、可诊断的 production chain。

可以直接复用的部分已经很多，不应重做：

1. 长任务 runtime 身份、状态机、heartbeat、supervisor 骨架。
2. 章节交付、路径归一、共享 `WritingExecutionResult` 与恢复摘要。
3. 表达限制执行策略主线 `ECP`。
4. 信息证据纪律主线 `IED`。
5. continuity 的开放 claims / review / projection 基座。
6. 普通项目、长任务、GUI/CLI、probe 的若干 shared projection 与 focused tests。

真正还缺的是“统一合同收口层”，而不是新建平行 runtime：

1. failure taxonomy / stop reason 仍偏字符串化、投影层兜底较多。
2. review / repair 仍同时存在 legacy review-report 链和 narrative semantic review 链，尚未统一。
3. 审核触发权、执行权、调度权尚未形成共享正式 policy。
4. chapter delivery failure 与 recovery 虽有基础，但还没在所有路径稳定映射为统一结局。
5. supervisor 仍在消费多套近似信号，shared execution discipline 还没完全并入同一输入包。

因此，`LTSR` 后续 26 轮不应重做 `ECP / IED / continuity / long-task runtime`，而应优先补“统一合同、统一调度、统一诊断”。

---

## 2. 当前稳定基础

### 2.1 长任务运行时骨架已稳定存在

可直接复用：

1. `packages/novel_agent_core/lib/src/runtime/run_instance.dart`
2. `packages/novel_agent_core/lib/src/runtime/long_task_run_status.dart`
3. `packages/novel_agent_core/lib/src/runtime/long_task_run_state_machine.dart`
4. `packages/novel_agent_adapters/lib/src/runtime/long_task_supervisor.dart`
5. `packages/novel_agent_core/lib/src/workflow/long_task_run_step_recorder_service.dart`
6. `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`

结论：

1. 已经不是“没有 supervisor”，而是 supervisor 输入与 stop reason 还未完全统一。
2. `watchdog / heartbeat / pause / resume / stopped` 方向已经存在，不应另起第二套。

### 2.2 章节交付与共享写作结果底座已存在

可直接复用：

1. `packages/novel_agent_core/lib/src/tools/domain/submit_chapter_delivery_handler.dart`
2. `packages/novel_agent_core/lib/src/workflow/chapter_delivery_state_machine.dart`
3. `packages/novel_agent_core/lib/src/project/chapter_output_path_policy_service.dart`
4. `packages/novel_agent_core/lib/src/workflow/writing_execution_result.dart`
5. `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart`
6. `packages/novel_agent_core/lib/src/workflow/long_task_writing_execution_signal_service.dart`
7. `packages/novel_agent_adapters/lib/src/workflow/chapter_delivery_outcome_projection_service.dart`

结论：

1. 空正文、错路径、标题口径、evidence 缺失已有结构化落点。
2. 但 delivery failure 还没有上升为统一 failure taxonomy 的正式成员。

### 2.3 表达限制共享主线已完成可复用基座

直接复用 `ECP` 成果：

1. `packages/novel_agent_core/lib/src/creative/expression_constraint_execution_policy.dart`
2. `packages/novel_agent_core/lib/src/creative/expression_constraint_execution_policy_resolver_service.dart`
3. `packages/novel_agent_core/lib/src/workflow/expression_constraint_gate_signal.dart`
4. `packages/novel_agent_core/lib/src/workflow/expression_constraint_supervisor_signal_service.dart`
5. `packages/novel_agent_adapters/lib/src/projection/expression_constraint_status_projection_service.dart`

结论：

1. 表达限制已经可以作为 shared execution discipline 输入。
2. `LTSR-12` 应只做接线，不应重做 `ECP` core。

### 2.4 信息证据纪律共享主线已完成可复用基座

直接复用 `IED` 成果：

1. `packages/novel_agent_core/lib/src/information/`
2. `packages/novel_agent_core/lib/src/workflow/information_evidence_gate_signal.dart`
3. `packages/novel_agent_adapters/lib/src/projection/information_evidence_projection_service.dart`
4. `packages/novel_agent_adapters/lib/src/tools/project_pending_research_action_service.dart`
5. `packages/novel_agent_adapters/lib/src/tools/project_information_research_coordinator_service.dart`

结论：

1. `pending research / awaiting confirmation / source insufficient / gateway failed` 已具备稳定合同。
2. `LTSR-13` 应只并入 unified supervisor input / stop reason，不应重做 IED。

### 2.5 continuity 开放状态与 claims 基座已存在

可直接复用：

1. `packages/novel_agent_core/lib/src/continuity/project_continuity_bundle.dart`
2. `packages/novel_agent_core/lib/src/continuity/continuity_runtime_resolver_service.dart`
3. `packages/novel_agent_core/lib/src/continuity/narrative_state/chapter_narrative_submission.dart`
4. `packages/novel_agent_core/lib/src/continuity/narrative_state/narrative_state_claim.dart`
5. `packages/novel_agent_core/lib/src/continuity/narrative_state/narrative_semantic_review.dart`
6. `packages/novel_agent_adapters/lib/src/tools/project_narrative_domain_tool_executor.dart`

结论：

1. continuity 已有从 `claims -> review -> projection` 的新基座。
2. 但 legacy `special_mechanic` 兼容层仍存在，尚未完全降级出主链。

---

## 3. 当前半闭环与主要缺口

### 3.1 failure taxonomy 仍未正式统一

现状：

1. `LongTaskRunStatus` 只覆盖 `running / waiting_gate / paused / recovering / failed_manual_attention / stopped`。
2. `stop_reason` 仍大量以字符串散落在 runtime、CLI summary、station detail、tests 中。
3. `LongTaskWritingExecutionSignalService` 只把共享结果粗分为 `success / recoverable / waiting_user / content_quality_failed / technical_failed / budget_failed`。

缺口：

1. 还没有统一 core 合同表达 `completed_naturally / budget_exhausted / technical_failure / delivery_failure / constraint_gate_pause / waiting_user / manual_attention / recovery_exhausted`。
2. projection 层目前还承担了一部分 stop reason 归类工作。

### 3.2 review 体系同时存在两条链

现状：

1. 旧链：`packages/novel_agent_core/lib/src/review/` + `review_task_factory_service.dart` + review report / repair task。
2. 新链：`packages/novel_agent_core/lib/src/continuity/narrative_state/narrative_semantic_review.dart`。

缺口：

1. 两条链都可用，但还不是同一份 review contract。
2. `reviewer id / role / basis / findings / risk level / recommended disposition / repair brief / evidence paths` 还没有一个共享的一等模型。

### 3.3 repair lane 仍偏 task-factory 化，未正式共享

现状：

1. `packages/novel_agent_core/lib/src/review/review_task_factory_service.dart`
2. `packages/novel_agent_adapters/lib/src/workflow/project_long_task_review_repair_task_service.dart`
3. `packages/novel_agent_adapters/lib/src/workflow/project_long_task_execution_constraint_repair_task_service.dart`

缺口：

1. repair 已经存在，但还是“从某类结果派生某类任务”居多。
2. 缺共享的 `repair request / repair task / repair outcome` 正式合同。

### 3.4 审核触发权、执行权、调度权仍未拆净

现状：

1. review 触发散落在 workflow runtime、checkpoint review、review task factory、expression constraint review projection 等不同入口。
2. 组内 reviewer / critic / editor 的选择规则还没有收口成共享 policy。

缺口：

1. 普通项目与长任务还没有形成“同一合同、不同触发权”的正式边界。
2. reviewer selection policy 仍未成为单点事实源。

### 3.5 supervisor 输入仍偏多源拼装

现状：

1. `packages/novel_agent_core/lib/src/workflow/narrative_supervisor_risk_policy_service.dart` 已能消费表达限制与信息信号。
2. 但 delivery / review / repair / length / information / expression / continuity 还没有一个统一 bundle 合同。

缺口：

1. `LTSR-08` 之前，supervisor 仍在消费多份近似结构和 legacy reason。
2. stop reason 依旧容易在 adapter / projection 侧被二次发明。

---

## 4. 已完成主线的直接复用口径

### 4.1 `ECP` 可直接复用

不要重做：

1. expression constraint execution policy contract
2. resolver
3. gate signal
4. station / CLI projection
5. mock regression suite

在 `LTSR` 中的正确位置：

1. `LTSR-11` 只并入 supervisor input。
2. `LTSR-18` 只消费统一 projection truth。
3. `LTSR-19` 到 `LTSR-21` 只消费 production contracts。

### 4.2 `IED` 可直接复用

不要重做：

1. host permission / research request / coordinator
2. information evidence gate signal
3. pending research action service
4. GUI / CLI 的最小资料确认闭环
5. mock / real probe 产物结构

在 `LTSR` 中的正确位置：

1. `LTSR-13` 只把 information discipline 接入统一审核与调度主链。
2. `LTSR-18` 只让 station/summary 读取统一 information summary。
3. `LTSR-19` 到 `LTSR-21` 复用同源 probe contract。

### 4.3 continuity 可直接复用

不要重做：

1. continuity bundle / frame / scope / resolver
2. narrative claims / semantic review / projection
3. `submit_narrative_state_claims`

在 `LTSR` 中的正确位置：

1. `LTSR-17` 只做 claims 入口与 legacy `special_mechanic` 降级收口。
2. 不再新增题材 if/else 或新的 special runtime。

---

## 5. 26 轮代码锚点映射

| Session | 主要代码锚点 |
| --- | --- |
| `LTSR-01` | `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`、`docs/expression-constraint-execution-policy-session-order-2026-06-06.md`、`docs/information-evidence-discipline-session-order-2026-06-05.md`、`agent.md` |
| `LTSR-02` | `packages/novel_agent_core/lib/src/runtime/long_task_run_status.dart`、`packages/novel_agent_core/lib/src/workflow/long_task_writing_execution_signal_service.dart`、`packages/novel_agent_core/lib/src/workflow/writing_execution_outcome_statuses.dart` |
| `LTSR-03` | `packages/novel_agent_core/lib/src/agents/`、`packages/novel_agent_core/lib/src/review/`、`packages/novel_agent_core/lib/src/workflow/` |
| `LTSR-04` | `packages/novel_agent_core/lib/src/review/`、`packages/novel_agent_core/lib/src/continuity/narrative_state/narrative_semantic_review.dart` |
| `LTSR-05` | `packages/novel_agent_core/lib/src/review/review_task_factory_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_long_task_review_repair_task_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_long_task_execution_constraint_repair_task_service.dart` |
| `LTSR-06` | `packages/novel_agent_core/lib/src/tools/domain/submit_chapter_delivery_handler.dart`、`packages/novel_agent_core/lib/src/workflow/chapter_delivery_state_machine.dart`、`packages/novel_agent_core/lib/src/project/chapter_output_path_policy_service.dart` |
| `LTSR-07` | `packages/novel_agent_adapters/lib/src/runtime/long_task_supervisor.dart`、`packages/novel_agent_core/lib/src/runtime/default_long_task_heartbeat_policy.dart` |
| `LTSR-08` | `packages/novel_agent_core/lib/src/workflow/narrative_supervisor_risk_policy_service.dart`、`packages/novel_agent_core/lib/src/workflow/long_task_writing_execution_signal_service.dart` |
| `LTSR-09` | `packages/novel_agent_core/lib/src/workflow/long_task_checkpoint_review_service.dart`、`packages/novel_agent_core/lib/src/workflow/narrative_supervisor_risk_policy_service.dart` |
| `LTSR-10` | `packages/novel_agent_core/lib/src/workflow/long_task_recovery_service.dart`、`packages/novel_agent_core/lib/src/runtime/long_task_run_state_machine.dart` |
| `LTSR-11` | `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`、`packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_summary.dart` |
| `LTSR-12` | `packages/novel_agent_core/lib/src/creative/expression_constraint_execution_policy_resolver_service.dart`、`packages/novel_agent_core/lib/src/workflow/expression_constraint_gate_signal.dart` |
| `LTSR-13` | `packages/novel_agent_core/lib/src/workflow/information_evidence_gate_signal.dart`、`packages/novel_agent_adapters/lib/src/tools/project_information_research_coordinator_service.dart` |
| `LTSR-14` | `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`、`packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart` |
| `LTSR-15` | `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`、`packages/novel_agent_core/lib/src/workflow/long_task_*` |
| `LTSR-16` | `packages/novel_agent_core/lib/src/agents/agent_selection_service.dart`、`packages/novel_agent_core/lib/src/agents/builtin_collaborator_catalog_service.dart` |
| `LTSR-17` | `packages/novel_agent_core/lib/src/continuity/narrative_state/`、`packages/novel_agent_core/lib/src/workflow/legacy_continuity_mechanic_importer_service.dart` |
| `LTSR-18` | `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`、`packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_narrative_summary.dart`、`apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart` |
| `LTSR-19` | `apps/novel_agent_app/tool/probe_support.dart`、`apps/novel_agent_app/tool/mock_long_task_probe.dart`、`apps/novel_agent_app/tool/mock_expression_constraint_policy_probe.dart` |
| `LTSR-20` | `tools/run_expression_constraint_policy_mock_regression_suite.ps1`、`tools/run_information_evidence_discipline_mock_regression_suite.ps1`、`apps/novel_agent_app/tool/mock_long_task_probe.dart` |
| `LTSR-21` | `apps/novel_agent_app/tool/real_long_task_probe.dart`、`apps/novel_agent_app/tool/real_general_novel_probe.dart`、`apps/novel_agent_app/tool/real_information_evidence_ordinary_probe.dart` |
| `LTSR-22` | 以 `LTSR-21` 实际报告指向的 core/adapters 最小归属层为准，优先 `packages/novel_agent_core/lib/src/workflow/` 或 `packages/novel_agent_adapters/lib/src/workflow/` |
| `LTSR-23` | `apps/novel_agent_app/lib/features/long_task_station/`、`apps/novel_agent_app/lib/features/workbench/` |
| `LTSR-24` | `apps/novel_agent_app/lib/features/long_task_station/application/controllers/long_task_station_controller.dart`、`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart` |
| `LTSR-25` | `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`、`apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart` |
| `LTSR-26` | `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md`、`docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`、`agent.md` |

---

## 6. 对下一轮的直接约束

下一轮应从 `LTSR-02` 开始，只做统一 failure taxonomy 与 stop reason core 合同。

原因：

1. `LTSR-01` 已确认：runtime、delivery、ECP、IED、continuity 都有可复用底座。
2. 目前最早且最影响后续 25 轮共享消费的缺口，就是 failure taxonomy 仍未正式统一。
3. 如果不先做 `LTSR-02`，后面的 review / repair / projection / probe 还会继续各自发明 stop reason。

本轮明确禁止：

1. 不回退去重做 `ECP / IED`。
2. 不把 `special_mechanic` 重新抬成主线中心。
3. 不把 GUI / CLI 提前当业务真相源。

