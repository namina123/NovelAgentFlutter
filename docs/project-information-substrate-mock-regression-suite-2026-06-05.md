# Project Information Substrate Mock Regression Suite

最后更新：2026-06-05

## 1. 目的

这套 mock regression suite 是 `PIS-26` 的一键回归入口，用来在不触发真实 provider、不联网、不过 GUI/CLI 真流程的前提下，先验证信息层的核心合同、工具链、仓储、activation、ordinary、long task、deconstruction 没有回退。

运行入口：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_project_information_substrate_mock_regression_suite.ps1
```

规则：

1. 只跑 `dart test`。
2. 不访问真实 API，不执行真实 gateway 联网。
3. 失败时优先看步骤标签和测试名，不先去 probe 或 UI 层找补丁。

## 2. 覆盖矩阵

### 2.1 Core contracts / domain tools

1. `namespace / policy / card / repository ports`
   对应：
   - `packages/novel_agent_core/test/project_information_namespace_smoke_test.dart`
   - `packages/novel_agent_core/test/information_policy_contracts_test.dart`
   - `packages/novel_agent_core/test/project_knowledge_card_contracts_test.dart`
   - `packages/novel_agent_core/test/design_element_card_contracts_test.dart`
   - `packages/novel_agent_core/test/research_note_contracts_test.dart`
   - `packages/novel_agent_core/test/reference_work_record_contracts_test.dart`
   - `packages/novel_agent_core/test/information_repository_ports_test.dart`
2. `structured information tool calls`
   对应：
   - `packages/novel_agent_core/test/information_tool_call_reliability_test.dart`
   说明：
   这里验证 `propose_knowledge_card`、`propose_design_element`、`request_external_research`、`submit_research_note`、`link_information_evidence`、`propose_reference_work` 作为一等 domain tools 的 parse + handler 通路，而不是把 `write_project_file` 或 `request_gateway_tool` 误当成信息入库。

### 2.2 Analysis / long task / deconstruction core bridges

1. `semantic review -> analysis information proposals`
   对应：
   - `packages/novel_agent_core/test/semantic_review_information_bridge_service_test.dart`
2. `long task checkpoint consumes information signal`
   对应：
   - `packages/novel_agent_core/test/long_task_checkpoint_review_service_test.dart`
3. `deconstruction -> knowledge / design / research / reference`
   对应：
   - `packages/novel_agent_core/test/book_deconstruction_narrative_bridge_service_test.dart`

### 2.3 Adapter repositories / projections / executors / gateway

1. `hidden information store`
   对应：
   - `packages/novel_agent_adapters/test/local_project_information_repositories_test.dart`
2. `markdown projection refresh`
   对应：
   - `packages/novel_agent_adapters/test/project_information_projection_writer_service_test.dart`
3. `local information executor persistence`
   对应：
   - `packages/novel_agent_adapters/test/project_information_domain_tool_executor_test.dart`
4. `dispatcher routes information tools without confusing gateway tools`
   对应：
   - `packages/novel_agent_adapters/test/project_tool_dispatcher_domain_tools_test.dart`
5. `fake gateway research bridge`
   对应：
   - `packages/novel_agent_adapters/test/project_research_gateway_service_test.dart`

### 2.4 Activation / ordinary / long task / review runtime

1. `information activation bridge`
   对应：
   - `packages/novel_agent_adapters/test/project_information_activation_bridge_service_test.dart`
2. `ordinary conversation runtime`
   对应：
   - `packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart`
   说明：
   这里同时验证普通章节 flow 会注入 information activation、暴露安全 information tools，并把 knowledge/design delta 的 `changed_paths` 带回最终 artifacts。
3. `long task checkpoint persistence`
   对应：
   - `packages/novel_agent_adapters/test/project_long_task_checkpoint_review_service_test.dart`
4. `review runtime persistence`
   对应：
   - `packages/novel_agent_adapters/test/project_workflow_review_runtime_service_test.dart`

## 3. 执行结果应该怎么看

1. 如果脚本停在 `Core information contract suite`，先看信息合同、开放 payload 或 repository port 有没有回退。
2. 如果脚本停在 `Core information workflow suite`，先看 analysis / long task / deconstruction bridge 的 namespace、proposal status、information signal 是否断链。
3. 如果脚本停在 `Adapters information storage and tool suite`，先看隐藏仓储、projection、executor、dispatcher 或 fake gateway research 的持久化通路。
4. 如果脚本停在 `Adapters information runtime suite`，先看 activation、ordinary 写作链、checkpoint review 或 semantic review runtime 的薄接线。

## 4. 与真实 Probe 的关系

1. 这套 suite 通过后，才应该继续 `PIS-27` 的 gated real probe framework。
2. 真实 probe 只能消费 production 同源合同；如果 mock suite 失败，先修合同和 runtime 接线，不要在 probe 层补私有判断。
