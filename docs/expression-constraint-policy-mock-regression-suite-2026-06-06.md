# Expression Constraint Policy Mock Regression Suite

最后更新：2026-06-06

## 1. 目的

这套 mock regression suite 是 `ECP-13` 的一键回归入口，用来在不触发真实 provider、不联网、不过 GUI 真流程的前提下，先验证表达限制执行策略、普通项目写作、长任务逐章、拆书/解书 intent、技术轮次排除和章节路径合同没有回退。

运行入口：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_expression_constraint_policy_mock_regression_suite.ps1
```

规则：

1. 只跑 `dart test`、`flutter test` 和本地 mock probe。
2. 不访问真实 API，不读取真实 key。
3. 失败时先看步骤标签、测试名和 probe report，不先去 GUI 层打补丁。

## 2. 覆盖矩阵

### 2.1 Core contracts

1. `policy mode / resolver / injection bridge / shared result / chapter path`
   对应：
   - `packages/novel_agent_core/test/expression_constraint_execution_policy_contracts_test.dart`
   - `packages/novel_agent_core/test/expression_constraint_execution_policy_resolver_service_test.dart`
   - `packages/novel_agent_core/test/expression_constraint_injection_policy_service_test.dart`
   - `packages/novel_agent_core/test/writing_execution_constraint_bridge_service_test.dart`
   - `packages/novel_agent_core/test/writing_execution_result_contracts_test.dart`
   - `packages/novel_agent_core/test/chapter_output_path_policy_service_test.dart`

### 2.2 Adapter runtime / projection

1. `status projection / ordinary runtime / workflow runtime / long task detail / delivery path projection`
   对应：
   - `packages/novel_agent_adapters/test/expression_constraint_status_projection_service_test.dart`
   - `packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart`
   - `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`
   - `packages/novel_agent_adapters/test/project_long_task_station_detail_service_test.dart`
   - `packages/novel_agent_adapters/test/chapter_delivery_outcome_projection_service_test.dart`

### 2.3 App mock probes

1. `probe support categories`
   对应：
   - `apps/novel_agent_app/test/probe_support_test.dart`
2. `long task chapter-by-chapter mock regression`
   对应：
   - `apps/novel_agent_app/tool/mock_long_task_probe.dart`
   说明：
   这里覆盖逐章交付、内容质量 gate、等待用户、预算恢复、technical failure 等长任务共享合同链路。
3. `expression constraint policy / intent / exclusion / path mock regression`
   对应：
   - `apps/novel_agent_app/tool/mock_expression_constraint_policy_probe.dart`
   说明：
   这里覆盖 `disabled / adaptive / force`、ordinary project、`book_deconstruction_followup`、`book_deconstruction_continuation`、`book_explainer_summary`、research/tool/path exclusion，以及重复章号路径归一化。

## 3. 报告怎么读

1. `mock_long_task_probe` 和 `mock_expression_constraint_policy_probe` 都会把 JSON/Markdown 报告写到 `artifacts/*_workspace/<timestamp>/`。
2. 这两个报告都按 production 合同分类，不靠 probe 私有正文扫描。当前关键分类至少包括：
   - `technical_failure`
   - `waiting_user`
   - `policy_disabled`
   - `content_quality_failure`
   - `path_failure`
3. 如果 `policy_disabled` 回退，优先看 policy resolver / runtime bridge / ordinary runtime。
4. 如果 `path_failure` 或重复章号 path regression 回退，优先看 chapter path policy 和 delivery projection。
5. 如果 `waiting_user`、`technical_failure`、`content_quality_failure` 分类错位，优先看 shared `WritingExecutionResult` 合同和 long task signal 投影。

## 4. 与真实 Probe 的关系

1. 这套 suite 通过后，后续短 probe 才应该继续做更细的报告消费。
2. 如果 mock suite 失败，先修 core/adapters/app 的同源合同，不要在 probe 层补私有判断。
