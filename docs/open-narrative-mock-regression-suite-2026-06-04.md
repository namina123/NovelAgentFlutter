# Open Narrative Mock Regression Suite

最后更新：2026-06-04

## 1. 目的

这套 mock regression suite 是 `ONS-41` 的稳定前置门槛，用来在不触发真实 provider、不过 GUI、也不跑真实 probe 的前提下，先验证开放叙事 runtime 的关键合同没有回退。

运行入口：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_open_narrative_mock_regression_suite.ps1
```

规则：

1. 只跑 `dart test`，不访问真实 API。
2. 只覆盖 writer / delivery / review / permission / recovery 的 mock contract。
3. 失败时优先看测试名和当前步骤标签，不需要先翻 probe 脚本。

## 2. 场景矩阵

### 2.1 Writer / Delivery

1. `writer success`
   对应：
   - `packages/novel_agent_adapters/test/project_narrative_domain_tool_executor_test.dart`
   - `submit_chapter_delivery writes chapter body and hidden submission record`
2. `writer no tool`
   对应：
   - `packages/novel_agent_core/test/draft_generation_use_case_test.dart`
   - `generate draft assembles context and invokes gateway`
   说明：
   这里验证模型直接返回正文时，生成链不会伪造 tool success，也不会把“无 tool”误判为异常。
3. `empty content`
   对应：
   - `packages/novel_agent_core/test/submit_chapter_delivery_handler_test.dart`
   - `distinguishes empty content from title-only output`
   - `packages/novel_agent_adapters/test/project_narrative_domain_tool_executor_test.dart`
   - `submit_chapter_delivery keeps empty content as invalid without writes`
4. `title-only`
   对应：
   - `packages/novel_agent_core/test/chapter_delivery_state_machine_test.dart`
   - `distinguishes missing body from title-only output`
   - `packages/novel_agent_core/test/submit_chapter_delivery_handler_test.dart`
   - `distinguishes empty content from title-only output`
5. `submission invalid`
   对应：
   - `packages/novel_agent_core/test/chapter_delivery_state_machine_test.dart`
   - `invalid submission still keeps delivered_needs_repair rather than failing chapter body`
   - `packages/novel_agent_core/test/submit_chapter_delivery_handler_test.dart`
   - `invalid submission keeps delivered body and marks sidecar repair required`

### 2.2 Review / Permission / Recovery

1. `review blocking`
   对应：
   - `packages/novel_agent_core/test/narrative_supervisor_risk_policy_service_test.dart`
   - `treats blocking semantic review findings as repair and tracks claim disposition counts`
   - `packages/novel_agent_adapters/test/project_workflow_review_runtime_service_test.dart`
   - `persistSemanticReviewArtifacts appends repository review and mirrors report paths for gate workflow`
2. `permission waiting`
   对应：
   - `packages/novel_agent_core/test/narrative_supervisor_risk_policy_service_test.dart`
   - `keeps waiting_user for true permission confirmation only`
3. `recovery success`
   对应：
   - `packages/novel_agent_core/test/draft_generation_tool_call_reliability_test.dart`
   - `recovery can distinguish missing body from repaired chapter delivery`
   - `packages/novel_agent_adapters/test/project_workflow_review_runtime_service_test.dart`
   - `preflight creates recovery task and rewires downstream when chapter body is missing`

### 2.3 Ordinary / Long Task Runtime Wiring

1. `ordinary project writer wiring`
   对应：
   - `packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart`
2. `long task queue and delivery wiring`
   对应：
   - `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`

## 3. 执行结果应该怎么看

1. 如果脚本停在 `Core mock regression suite`，先看 delivery / permission / recovery 合同有没有回退。
2. 如果脚本停在 `Adapters mock regression suite`，先看普通项目接线、长任务接线或 review runtime 薄适配有没有断。
3. 如果某条失败名称里出现 `waiting_user_choice`、`delivered_needs_repair`、`missing_output_recoverable`、`invalid_output_rewrite_required`，优先按结构化状态机或 supervisor 风险链排查，不要先去看正文内容质量。

## 4. 与真实 Probe 的关系

1. 这套 suite 通过后，才应该继续跑 `ONS-42` 的真实 probe 同源化工作。
2. 真实 probe 只能消费 production 合同；如果 mock suite 失败，先修合同，不要在 probe 里补私有重试/修复逻辑。
