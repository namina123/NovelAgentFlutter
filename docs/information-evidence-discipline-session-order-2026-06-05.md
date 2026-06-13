# 信息收集证据纪律闭环任务顺序文档

最后更新：2026-06-06

主线代号：`IED`（Information Evidence Discipline）

关联分析文档：

- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `docs/project-information-substrate-session-order-2026-06-05.md`
- `docs/project-information-substrate-implementation-audit-2026-06-05.md`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `docs/release-readiness-gui-core-consolidation-analysis-2026-06-05.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `agent.md`

关联代码锚点：

- `packages/novel_agent_core/lib/src/information/`
- `packages/novel_agent_core/lib/src/tools/domain/request_external_research_handler.dart`
- `packages/novel_agent_core/lib/src/tools/domain/information_domain_tool_handler_support.dart`
- `packages/novel_agent_core/lib/src/project/project_prompt_contract.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart`
- `packages/novel_agent_core/lib/src/workflow/narrative_supervisor_risk_policy_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_information_domain_tool_executor.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_research_gateway_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_information_import_collection_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`
- `packages/novel_agent_adapters/lib/src/config/local_settings_repository.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
- `apps/novel_agent_app/lib/features/settings/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/long_task_station/`
- `apps/novel_agent_cli/lib/commands/workflow/`
- `apps/novel_agent_app/tool/probe_support.dart`

---

## 1. 这份文档解决什么

PIS 主线已经把 `knowledge / design / research / reference` 四类信息对象、工具、持久化、投影、activation、普通项目、长任务、拆书和 GUI/CLI 最小消费做成了共享基座。

本文件不重做 PIS。

本文件专门补最后一段闭环：

```text
智能体判断需要资料
  -> 提交结构化 request_external_research / import request
  -> 宿主权限覆盖模型自声明
  -> 开放权限下自动执行，受限权限下轻确认
  -> 执行结果形成 research note / source audit / projection
  -> 章节和长任务看到 evidence gap / pending research / source quality 风险
  -> GUI / CLI 只展示人话摘要和必要确认
  -> probe 用生产合同验收，不另造判断
```

目标不是新增一个“信息限制中心”，而是把已有 `information` 合同、权限设置、工具结果、runtime gate 和 GUI/CLI 投影接顺。

---

## 2. 与旧文档的关系

### 2.1 PIS 是事实源基座，本主线只做证据纪律闭环

`docs/project-information-substrate-session-order-2026-06-05.md` 已完成 30 轮，覆盖：

1. Core information contracts。
2. Domain tools。
3. Local repositories。
4. Markdown projections。
5. Gateway research service。
6. Import collection service。
7. Activation bridge。
8. Ordinary / long task / deconstruction / explainer 接入。
9. Mock regression 与小预算真实 probe。
10. CLI / GUI 最小信息摘要。

本主线不要复制这些成果，只补：

1. 宿主权限进入 information tool 执行。
2. `user_granted_network_access` 不再由模型说了算。
3. `request_external_research` accepted 后能按权限自动 gateway / import。
4. 受限权限下能留下可确认、可恢复的 pending 状态。
5. evidence gap 能进入 writing result / supervisor / run summary。
6. GUI / CLI 只做轻确认和摘要，不解释开放 payload。

### 2.2 信息收集分析文档是边界，本主线负责落地

`docs/important/information-collection-agent-boundary-analysis-2026-06-05.md` 已明确：

1. 信息收集不是表达限制。
2. 信息收集不是技能或智能体人设。
3. 平台证据底线在 `ProjectConstitution / ModeGuidance / StyleProfile` 三层之外。
4. 用户可配置严格度、权限、资料规则，但不能关闭“不得假装知道”的底线。
5. 普通 GUI 不暴露 `information policy / raw tool request / runtime gate`。

本主线所有任务必须服从这个边界。

### 2.3 与发布收口文档的关系

发布收口要求 GUI 变得可用、稳定、自然。本主线只做与信息收集有关的最小产品化：

1. 必要确认。
2. 信息摘要。
3. 来源不足提示。
4. 打开投影文件。

不做完整 knowledge browser，不做复杂资料中心，不把生态设置搬进写作主面板。

---

## 3. 已有实现去重审计

### 3.1 已有，不重做

1. `InformationCollectionRequest`
2. `InformationSourceRequirements`
3. `InformationExtractionPolicy`
4. `InformationCollectionPolicyService`
5. `InformationSourceQualityService`
6. `InformationPermissionPolicyService`
7. `request_external_research` schema / parser / handler
8. `ProjectInformationDomainToolExecutor`
9. `.novel_agent/information/*` 本地事实源
10. `ProjectResearchGatewayService`
11. `ProjectInformationImportCollectionService`
12. `ProjectInformationProjectionWriterService`
13. `ProjectInformationActivationBridgeService`
14. 普通项目和长任务 information changed paths / summary
15. 长任务 station 和 workbench 最小 information 展示
16. PIS mock regression 与 gated probe framework

### 3.2 已有但只是半闭环

1. `request_external_research` 能登记 pending request，但默认不自动执行 gateway。
2. `ProjectResearchGatewayService.processPendingRequest(...)` 已存在，但还没被 runtime 稳定调用。
3. `user_granted_network_access` 字段仍可能来自模型 payload，需要宿主覆盖。
4. Settings 里已有 `allow_network`，但没有完整桥到 information tool 执行。
5. `needs_user_confirmation` 能落记录和摘要，但缺少统一确认/拒绝 action service。
6. information summary 能显示 0/非 0，但 evidence gap 还没有足够稳定地进入写作结果 gate。
7. source quality audit 已有，但 runtime 还没有统一判断“严谨来源不足”的交付风险。
8. GUI 能显示信息摘要，但缺少普通用户可理解的“确认联网研究 / 拒绝并保留缺口”闭环。

### 3.3 真正要补的层

1. Core host permission context / evidence gate 合同。
2. Adapters local settings -> information permission context 薄桥。
3. Tool dispatcher / information executor 的宿主授权覆盖。
4. Pending research confirmation action。
5. Auto research coordinator。
6. Ordinary / workflow runtime 接线。
7. Writing result / supervisor risk / checkpoint summary 接线。
8. Workbench / long task station 轻确认 GUI。
9. CLI 最小确认入口。
10. Mock regression 与 gated real probe。

---

## 4. 本轮冻结的架构边界

1. 不新增全能 information control center。
2. 不把信息收集做成表达限制 preset。
3. 不把信息收集写成技能授权。
4. 不让模型自声明网络授权覆盖宿主权限。
5. Core 不联网，不读本地设置文件。
6. Adapters 做权限桥、gateway、import、持久化，不做创作判断中心。
7. Runtime 只消费结构化 evidence signal，不读正文做复杂事实识别。
8. GUI / CLI 只消费 summary、pending records、projection paths，不解释开放 payload。
9. Probe 只验收生产合同，不补私有 repair 或私有业务判断。
10. 不写死快穿、死亡回归、多世界、神话、星象、八卦等题材分支。
11. 不继续膨胀 `ProjectWorkflowRuntimeService`、`ProjectContextActivationService`、widget 或 probe。

---

## 5. 目标终态

### 5.1 开放权限

```text
用户设置 allow_network=true / all-open
  -> 智能体调用 request_external_research
  -> runtime 覆盖 user_granted_network_access=true
  -> handler 返回 accepted
  -> request 先持久化
  -> coordinator 自动调用 ProjectResearchGatewayService
  -> 生成 research note / source audit / projection
  -> writing result 和 run record 显示已执行研究与 changed paths
```

### 5.2 受限权限

```text
用户设置 allow_network=false / safe
  -> 智能体调用 request_external_research
  -> runtime 覆盖 user_granted_network_access=false
  -> handler 返回 needs_user_confirmation
  -> pending record 持久化
  -> GUI / CLI 显示“需要联网研究确认”
  -> 用户确认后 coordinator 执行
  -> 用户拒绝后保留 evidence gap，不假装已研究
```

### 5.3 导入收集

```text
collection_mode=import
  -> 不需要联网权限
  -> 根据导入来源和权限执行 ProjectInformationImportCollectionService
  -> 生成 research note / candidate excerpts / projection
  -> 不冒充外部事实来源
```

### 5.4 证据 gate

```text
pending research / rigorous source insufficient / required info omitted
  -> information evidence signal
  -> writing execution result
  -> long task checkpoint / recovery / station summary
  -> probe report
```

---

## 6. Session 数量与顺序设计理由

本主线拆成 `18` 个 session。

理由：

1. `IED-01` 先审计现有半闭环，避免重复 PIS。
2. `IED-02` 到 `IED-04` 先补 core 合同和 gate，不碰 adapters。
3. `IED-05` 到 `IED-09` 补 adapters 权限桥、确认 action、自动 coordinator 和 tool/runtime 接线。
4. `IED-10` 到 `IED-12` 补普通写作、长任务和写作结果 evidence gate。
5. `IED-13` 先收 projection / summary，再给外层消费。
6. `IED-14` 到 `IED-16` 做 mock regression、GUI、CLI。
7. `IED-17` 做 gated real probe。
8. `IED-18` 做文档、agent 约束和交接收口。

每轮都应是一轮会话可完成；如果上一轮出现半成品或关联错误，先修上一轮，不开启新任务。

---

## 7. 全局执行规则

每个 session 都必须遵守：

1. 先读本文档、主分析文档、PIS 完成记录、`agent.md`。
2. 只做当前 session，不开启下一任务。
3. Core / domain 合同先行，GUI / CLI 最后消费。
4. 优先复用 `information` 合同、domain tool、repository、projection、activation、supervisor 风险服务。
5. 单文件超过 400 行复核职责，超过 700 行必须拆分。
6. 不把 fallback、probe、bridge、widget、runtime 门面写成新业务中心。
7. 每轮补 focused test / contract test，文档轮除外。
8. 真实 provider / 联网 probe 必须显式开闸。
9. 不提交 key、一次性探针、临时产物和无关 dirty 文件。

---

## 8. 设计目标覆盖表

| 目标 | 覆盖 session |
| --- | --- |
| 宿主权限覆盖模型自声明 | IED-02、IED-05、IED-06 |
| 受限权限轻确认 | IED-03、IED-07、IED-15、IED-16 |
| 开放权限自动执行研究 | IED-03、IED-08、IED-09、IED-10 |
| 导入收集闭环 | IED-03、IED-08、IED-14 |
| source quality / rigorous source gate | IED-04、IED-12、IED-14 |
| evidence gap 进入写作结果 | IED-04、IED-12 |
| 普通项目接线 | IED-10、IED-14、IED-15 |
| 长任务 / supervisor 接线 | IED-11、IED-14、IED-15 |
| 拆书 / 解书不私有化 | IED-12、IED-14、IED-18 |
| GUI 轻量消费 | IED-15 |
| CLI 最小消费 | IED-16 |
| probe 不造第二套判断 | IED-14、IED-17 |
| 文档与项目约束收口 | IED-18 |

---

## 9. Session 顺序

### IED-01：现有信息收集闭环审计

本轮目标：确认 PIS 之后信息收集链路还缺哪些桥，不重复已经完成的信息事实源和投影。

层级归属：Documentation / Architecture audit。

必读文件：

- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `docs/project-information-substrate-session-order-2026-06-05.md`
- `docs/project-information-substrate-implementation-audit-2026-06-05.md`
- `agent.md`
- `packages/novel_agent_adapters/lib/src/tools/project_information_domain_tool_executor.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_research_gateway_service.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/widgets/permissions_settings_panel.dart`

必须完成：

1. 新增或更新一份审计小节，列出 `request_external_research -> pending -> gateway/import -> research note -> evidence gate -> GUI/CLI` 的当前断点。
2. 标记已有实现、半成品、禁止重做项。
3. 明确 settings 的 `allow_network` 当前在哪里保存，哪里尚未消费。
4. 明确 `user_granted_network_access` 当前仍可能来自模型，需要宿主覆盖。
5. 回填本文档 IED-01 完成记录。

本轮不要做：

1. 不写业务代码。
2. 不跑真实联网。
3. 不改 GUI。
4. 不开启 IED-02。

验收标准：

1. 审计结果能直接指导 IED-02 到 IED-09。
2. 没有重复 PIS 已完成任务。
3. 没有把复杂中心或大 UI 作为方案。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-01，只做现有信息收集闭环审计。必须读取主分析文档、PIS 完成记录和 agent.md，明确 request_external_research 到 gateway/import/evidence gate/GUI 的断点，不写业务代码、不跑真实联网、不改 GUI、不开启下一任务。注意不要重复 PIS 已完成的信息事实源、工具、投影和 activation。
```

### IED-02：Core 宿主信息权限上下文合同

本轮目标：建立纯 core 的宿主信息权限上下文，让后续执行器能用宿主权限覆盖模型 payload。

层级归属：Core / domain contract。

必读文件：

- IED-01 审计结果
- `packages/novel_agent_core/lib/src/information/information_permission_policy_service.dart`
- `packages/novel_agent_core/lib/src/information/information_collection_request.dart`
- `packages/novel_agent_core/lib/src/tools/domain/request_external_research_handler.dart`

必须完成：

1. 新增 `HostInformationPermissionContext` 或等价纯 core 合同。
2. 字段至少表达：allowNetwork、allowImportCollection、permissionMode、confirmationMode、source、metadata。
3. 新增 resolver/policy：根据 host context 与 collection request 计算 effective network authorization。
4. 明确模型 payload 中的 `user_granted_network_access` 只能作为原始声明保留，不能作为最终授权。
5. 补 codec / focused tests。

本轮不要做：

1. 不读本地设置文件。
2. 不接 adapters。
3. 不改 handler 行为。
4. 不做 GUI。

验收标准：

1. Core tests 覆盖 open / safe / import / model lied / unknown mode。
2. 合同不依赖 Flutter、文件系统、provider。
3. 命名不把它做成表达限制或技能。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-02，只做 Core 宿主信息权限上下文合同。新增纯 core HostInformationPermissionContext 或等价合同，以及 effective authorization resolver；模型 payload 的 user_granted_network_access 只能作为 raw declaration，最终授权来自 host context。不接 adapters、不改 handler、不做 GUI、不开启下一任务。补 codec/focused tests。
```

### IED-03：Core 研究执行决策服务

本轮目标：把 network / import / hybrid / restricted 的执行决策收口为纯 core 服务，供 adapters 统一消费。

层级归属：Core / domain policy。

必读文件：

- IED-02 合同
- `packages/novel_agent_core/lib/src/information/information_collection_policy_service.dart`
- `packages/novel_agent_core/lib/src/information/information_permission_policy_service.dart`
- `packages/novel_agent_core/lib/src/information/information_permission_decision.dart`

必须完成：

1. 新增 `InformationResearchExecutionDecisionService` 或等价服务。
2. 输入：collection request、host permission context、information permission decision。
3. 输出：autoExecuteNetwork、autoExecuteImport、awaitUserConfirmation、blocked、reason、effective request。
4. 明确 hybrid：能导入的先导入，联网部分按权限决定。
5. 补 tests 覆盖 open / restricted / import / hybrid / high-risk reference / forbidden payload。

本轮不要做：

1. 不执行 gateway。
2. 不写 pending 文件。
3. 不改 dispatcher。
4. 不做 GUI。

验收标准：

1. 决策服务不依赖 adapters。
2. 输出足够让 adapters 决定下一步。
3. 不新增大而泛的 runtime policy 中心。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-03，只做 Core 研究执行决策服务。输入 collection request、host permission context、information permission decision，输出 network/import/hybrid 的 auto execute / await confirmation / blocked 决策。不执行 gateway、不写文件、不接 dispatcher/UI、不开启下一任务。补 focused tests。
```

### IED-04：Core information evidence gate 合同

本轮目标：定义 evidence gap、pending research、source quality insufficient 如何进入写作执行结果和 supervisor 风险。

层级归属：Core / workflow contract。

必读文件：

- `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_information_summary.dart`
- `packages/novel_agent_core/lib/src/workflow/narrative_supervisor_risk_policy_service.dart`
- `packages/novel_agent_core/lib/src/information/information_source_quality_service.dart`

必须完成：

1. 新增或扩展 `InformationEvidenceGateSignal` / `WritingExecutionInformationEvidenceSummary` 等小合同。
2. 覆盖 pending research、awaiting confirmation、gateway failed、rigorous source insufficient、required information omitted、external fact unverified。
3. 输出 severity / recommended disposition / summary / changed paths。
4. 接入 core writing result normalizer 的输入结构，但不改 adapters。
5. 补 tests 覆盖普通成功、pending、严谨来源不足、失败可恢复、等待用户。

本轮不要做：

1. 不读正文做 NLP 判断。
2. 不联网。
3. 不接 GUI。
4. 不改长任务 runtime。

验收标准：

1. gate 信号能被普通项目和长任务共用。
2. 技术失败、等待用户、内容证据不足能区分。
3. 不把 evidence gap 伪装成 expression review。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-04，只做 Core information evidence gate 合同。覆盖 pending research、awaiting confirmation、gateway failed、rigorous source insufficient、required information omitted、external fact unverified，并接入 writing result normalizer 的纯 core 输入/摘要。不读正文做 NLP、不联网、不接 adapters/GUI、不开启下一任务。补 focused tests。
```

### IED-05：Adapters 本地权限设置到 host context 薄桥

本轮目标：让应用/CLI 保存的 permission settings 能被 adapters 转为 IED-02 的 host permission context。

层级归属：Adapters / settings bridge。

必读文件：

- IED-02、IED-03 实现
- `packages/novel_agent_adapters/lib/src/config/local_settings_repository.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/widgets/permissions_settings_panel.dart`
- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`

必须完成：

1. 新增 `ProjectInformationPermissionSettingsResolverService` 或等价 adapter service。
2. 从 `permissionSettings` 中读取 `allow_network`、模式字段和未来兼容字段。
3. 输出 core host permission context。
4. 默认安全：缺失设置视为不自动联网。
5. 补 adapter tests。

本轮不要做：

1. 不改 settings UI。
2. 不执行 gateway。
3. 不改 domain handler。
4. 不接 workflow。

验收标准：

1. `allow_network=true` / false / missing / all mode 均有测试。
2. resolver 小而独立，不写进大 controller 或 runtime。
3. 不改变现有 settings 文件格式的向后兼容。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-05，只做 adapters 本地权限设置到 HostInformationPermissionContext 的薄桥。读取 permissionSettings 的 allow_network 等字段，缺失默认安全，不改 settings UI、不执行 gateway、不接 workflow、不开启下一任务。补 adapter focused tests，保持小 service。
```

### IED-06：Information tool payload 宿主授权覆盖

本轮目标：在 information domain tool 执行前，用宿主权限改写 effective research request，并保留模型原始声明用于审计。

层级归属：Adapters / tool execution bridge。

必读文件：

- IED-02、IED-05 实现
- `packages/novel_agent_adapters/lib/src/tools/project_information_domain_tool_executor.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`
- `packages/novel_agent_core/lib/src/tools/domain/request_external_research_handler.dart`

必须完成：

1. 让 `ProjectInformationDomainToolExecutor` 或其上游接收 host information permission context。
2. 对 `request_external_research` 构造 effective payload：
   - `user_granted_network_access` 使用宿主授权结果。
   - 模型原始值保留到 metadata/audit。
3. 保持其他 information tools 不受无关影响。
4. 补 tests：模型传 true 但宿主 false -> needs_user_confirmation；模型传 false 但宿主 true -> accepted。

本轮不要做：

1. 不自动执行 gateway。
2. 不改 core handler 去读宿主设置。
3. 不做 GUI。
4. 不开启下一任务。

验收标准：

1. 宿主权限完全覆盖模型声明。
2. 审计能看到 raw_model_user_granted_network_access。
3. dispatcher 和 executor 不变成权限大中心。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-06，只做 information tool payload 的宿主授权覆盖。让 request_external_research 的 effective user_granted_network_access 来自 HostInformationPermissionContext，并保留模型原始声明到 metadata/audit。不自动 gateway、不让 core handler 读设置、不做 GUI、不开启下一任务。补 dispatcher/executor tests。
```

### IED-07：Pending research 确认动作服务

本轮目标：提供统一确认/拒绝 pending research request 的 adapter action，不让 GUI/CLI 直接改隐藏 JSON。

层级归属：Adapters / action service。

必读文件：

- `packages/novel_agent_adapters/lib/src/tools/project_information_domain_tool_executor.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_research_gateway_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_information_path_service.dart`
- `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`

必须完成：

1. 新增 `ProjectPendingResearchActionService` 或等价服务。
2. 支持 list / approve / reject / markNeedsUserInfo。
3. approve 只更新授权状态或 request state，不直接绕过 IED-08 coordinator。
4. reject 保留 evidence gap 和 audit，不删除记录。
5. 补 tests 覆盖确认、拒绝、缺失 request、重复动作。

本轮不要做：

1. 不做 GUI。
2. 不执行 gateway。
3. 不让 action service 解释 research payload。
4. 不开启下一任务。

验收标准：

1. GUI/CLI 后续可以只调用 action service。
2. 拒绝后不会假装已研究。
3. 审计 changed paths 完整。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-07，只做 Pending research 确认动作服务。新增 list/approve/reject/markNeedsUserInfo 等 adapter action，GUI/CLI 后续不得直接改隐藏 JSON。approve 不直接执行 gateway，reject 保留 evidence gap 和 audit。不做 GUI、不执行 gateway、不开启下一任务。补 adapter tests。
```

### IED-08：自动研究执行协调器

本轮目标：把 accepted pending request 按决策自动分派到 gateway research 或 import collection。

层级归属：Adapters / runtime coordinator。

必读文件：

- IED-03、IED-05、IED-07 实现
- `packages/novel_agent_adapters/lib/src/tools/project_research_gateway_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_information_import_collection_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_research_gateway_run_result.dart`

必须完成：

1. 新增 `ProjectInformationResearchCoordinatorService` 或等价小 service。
2. 输入 project、request id、host context、执行预算。
3. 对 network/hybrid 调用 `ProjectResearchGatewayService.processPendingRequest`。
4. 对 import/hybrid 调用 `ProjectInformationImportCollectionService`。
5. 合并 changed paths、summary、execution result、source quality audit。
6. 补 tests 覆盖 network success、import success、hybrid partial、permission blocked、gateway failed。

本轮不要做：

1. 不接 tool executor。
2. 不做 GUI。
3. 不跑真实网络。
4. 不开启下一任务。

验收标准：

1. coordinator 不复制 gateway/import 内部逻辑。
2. 所有失败有结构化 state。
3. 结果能被 runtime summary 消费。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-08，只做自动研究执行协调器。复用 ProjectResearchGatewayService 和 ProjectInformationImportCollectionService，按 Core 决策处理 network/import/hybrid，合并 changed paths、summary、source audit。不接 tool executor、不做 GUI、不跑真实网络、不开启下一任务。补 fake gateway/import tests。
```

### IED-09：Information tool executor 自动执行接线

本轮目标：让 `request_external_research` 在宿主允许时从“登记 pending”闭环到“登记后自动执行”。

层级归属：Adapters / tool execution。

必读文件：

- IED-06、IED-08 实现
- `packages/novel_agent_adapters/lib/src/tools/project_information_domain_tool_executor.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`
- `packages/novel_agent_adapters/test/project_information_domain_tool_executor_test.dart`
- `packages/novel_agent_adapters/test/project_tool_dispatcher_domain_tools_test.dart`

必须完成：

1. 在 information executor 持久化 research request 后，调用 coordinator。
2. 开放权限下返回 `network_execution_performed=true` 或 import 执行结果。
3. 受限权限下保持 pending / needs_user_confirmation。
4. changed_paths 包含 request record、research note、projection、events。
5. 补 dispatcher/executor tests。

本轮不要做：

1. 不改普通/长任务 runtime。
2. 不做 GUI。
3. 不跑真实网络。
4. 不开启下一任务。

验收标准：

1. `request_external_research` 不再只停在 pending，开放权限下能自动执行 fake gateway。
2. 受限权限仍不打扰用户，只留下确认项。
3. tool result 摘要区分 registered / executed / pending / blocked。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-09，只做 Information tool executor 自动执行接线。request_external_research 持久化后调用 coordinator；开放权限下 fake gateway/import 自动执行，受限权限保持 needs_user_confirmation/pending。不要改普通/长任务 runtime，不做 GUI，不跑真实网络，不开启下一任务。补 executor/dispatcher tests。
```

### IED-10：普通写作 runtime 接线

本轮目标：让普通项目章节生成能传入宿主信息权限上下文，并把 information execution summary 写回 draft result。

层级归属：Adapters / ordinary writing runtime。

必读文件：

- IED-05、IED-09 实现
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
- `apps/novel_agent_app/lib/app/bootstrap/app_bootstrap.dart`

必须完成：

1. 普通 draft runtime 构造 tool dispatcher / executor 时传入 host information context。
2. final artifacts 合并 research execution changed paths。
3. draft result summary 区分：无信息变化、已执行研究、等待确认、来源不足。
4. 补 tests 覆盖普通章节开放权限自动研究、受限权限 pending、无资料需求不触发。

本轮不要做：

1. 不做 GUI 展示。
2. 不改长任务。
3. 不跑真实 provider。
4. 不开启下一任务。

验收标准：

1. 普通项目不再绕开证据纪律。
2. 无信息需求的项目不会被强行研究。
3. changed paths 和 summary 可被 workbench 投影消费。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-10，只做普通写作 runtime 接线。让普通 draft 运行向 information tools 传入宿主信息权限上下文，并把自动研究/pending/来源不足摘要与 changed paths 写回 draft result。不做 GUI、不改长任务、不跑真实 provider、不开启下一任务。补 ordinary runtime tests。
```

### IED-11：长任务 workflow / supervisor 接线

本轮目标：让长任务章节、checkpoint、recovery 稳定消费 information execution summary 和 evidence gate。

层级归属：Adapters + Core workflow runtime。

必读文件：

- IED-04、IED-09 实现
- `packages/novel_agent_core/lib/src/workflow/narrative_supervisor_risk_policy_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_checkpoint_review_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_checkpoint_review_service.dart`

必须完成：

1. 长任务 tool execution 传入 host information context。
2. checkpoint review 读取 information execution summary / evidence gate。
3. pending research -> waiting user 或 checkpoint_user。
4. gateway failed -> repair/manual_attention，不能误判为正文失败。
5. 补 core/adapters tests。

本轮不要做：

1. 不跑真实长任务。
2. 不写题材特例。
3. 不把算法塞进 `ProjectWorkflowRuntimeService`。
4. 不开启下一任务。

验收标准：

1. 长任务和普通项目共用同一 information gate 语义。
2. supervisor 能区分技术失败、等待确认、证据不足。
3. 长任务 station 后续可以读到稳定 summary。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-11，只做长任务 workflow / supervisor 接线。让长任务章节执行传入宿主信息权限上下文，checkpoint/recovery 消费 information execution summary 和 evidence gate，区分 pending research、gateway failed、source insufficient。不跑真实长任务、不写题材特例、不膨胀 ProjectWorkflowRuntimeService、不开启下一任务。补 core/adapters tests。
```

### IED-12：共享写作结果 evidence gate 收口

本轮目标：把 evidence gap 正式并入普通项目、长任务、拆书续写可共用的写作结果合同。

层级归属：Core + Adapters / writing result integration。

必读文件：

- IED-04、IED-10、IED-11 实现
- `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_outcome_statuses.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_postprocess_result_service.dart`

必须完成：

1. 扩展 writing execution result summary，稳定包含 information evidence gate。
2. 普通项目、长任务、拆书续写都能传入同一 gate 输入。
3. 轻微信息缺口只提示，不返修；阻断型缺口进入等待用户或 repair。
4. source quality 严重不足能进入 evidence warning。
5. 补 tests 覆盖普通/长任务共用路径。

本轮不要做：

1. 不新增 GUI。
2. 不新增 NLP 检测。
3. 不把拆书写成私有逻辑。
4. 不开启下一任务。

验收标准：

1. evidence gate 与字数/表达限制同属写作结果摘要，但不被表达限制吞并。
2. outcome status 不滥用 waiting_user。
3. 所有项目类型可以共用。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-12，只做共享写作结果 evidence gate 收口。把 information evidence gate 并入 WritingExecutionResult/summary，普通项目、长任务、拆书续写共用；轻微缺口提示，阻断型缺口进入等待用户或 repair。不做 GUI、不新增 NLP、不写拆书私有逻辑、不开启下一任务。补 focused tests。
```

### IED-13：运行投影与人话摘要收口

本轮目标：为 GUI / CLI / probe 提供统一的人话投影，避免外层解释 raw payload。

层级归属：Adapters / projection contract。

必读文件：

- IED-09 到 IED-12 实现
- `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_tool_entry_projection_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_information_summary.dart`

必须完成：

1. 新增或扩展 `InformationEvidenceProjectionService`。
2. 输出普通用户可读字段：需要资料、已执行研究、来源不足、等待确认、已拒绝、投影路径。
3. 开发诊断字段单独折叠，不默认给普通 GUI。
4. workbench 和 long task station 消费同一 projection。
5. 补 tests。

本轮不要做：

1. 不做 widget。
2. 不做 CLI command。
3. 不解释开放 payload。
4. 不开启下一任务。

验收标准：

1. 外层能不读隐藏 JSON 就展示信息状态。
2. 文案自然，不出现 `runtime gate`、`raw request` 等内部词。
3. projection 可覆盖普通和长任务。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-13，只做运行投影与人话摘要收口。新增/扩展 InformationEvidenceProjectionService，让 workbench、long task station、CLI/probe 后续消费同一 summary：需要资料、已执行研究、来源不足、等待确认、已拒绝、投影路径。不做 widget/CLI command，不解释开放 payload，不开启下一任务。补 tests。
```

### IED-14：Mock regression suite

本轮目标：用 fake provider / fake gateway 覆盖信息收集证据纪律全链路。

层级归属：Probe / regression。

必读文件：

- IED-02 到 IED-13 实现
- `tools/run_project_information_substrate_mock_regression_suite.ps1`
- `apps/novel_agent_app/tool/probe_support.dart`
- `packages/novel_agent_adapters/test/project_research_gateway_service_test.dart`

必须完成：

1. 新增或扩展一键 mock regression 脚本。
2. 覆盖：
   - open network auto execute。
   - restricted network pending confirmation。
   - import collection。
   - hybrid partial。
   - gateway failed。
   - rigorous source insufficient。
   - ordinary runtime。
   - long task checkpoint。
3. 报告区分 technical / waiting user / evidence quality / success。
4. 保留产物，不删除。

本轮不要做：

1. 不调用真实 provider。
2. 不联网。
3. 不修 GUI。
4. 不开启下一任务。

验收标准：

1. 一键 mock suite 全通过。
2. 报告消费 production 合同。
3. 没有新增一次性业务判断脚本。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-14，只做 mock regression suite。用 fake provider/fake gateway 覆盖 open auto research、restricted pending、import、hybrid、gateway failed、rigorous source insufficient、ordinary runtime、long task checkpoint；报告区分 technical/waiting/evidence/success。不真实联网、不调用真实 provider、不做 GUI、不开启下一任务。
```

### IED-15：GUI 轻确认与摘要消费

本轮目标：让普通用户能在 workbench / long task station 中确认或拒绝 pending research，并看到自然的信息摘要。

层级归属：App / GUI presentation。

必读文件：

- IED-07、IED-13 实现
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/long_task_station/`
- `apps/novel_agent_app/lib/features/settings/presentation/widgets/permissions_settings_panel.dart`
- `docs/release-readiness-gui-core-consolidation-analysis-2026-06-05.md`

必须完成：

1. workbench 工具时间线显示信息摘要：已执行研究、待确认、来源不足。
2. long task station detail 显示待确认研究项。
3. 提供确认/拒绝两个轻动作，调用 IED-07 action service。
4. 完全开放权限下不弹频繁确认。
5. 文案使用人话，不出现内部 id/raw JSON。
6. 补 widget/view data tests。

本轮不要做：

1. 不做完整资料中心。
2. 不做 knowledge browser。
3. 不让 widget 直接读隐藏 JSON。
4. 不开启下一任务。

验收标准：

1. 普通用户能看懂“为什么需要确认”。
2. 确认/拒绝后状态和投影刷新。
3. 窄屏不挤占主要写作面板。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-15，只做 GUI 轻确认与摘要消费。Workbench 和 Long Task Station 只消费 IED-13 projection 与 IED-07 action service，展示已执行研究、待确认、来源不足，并提供确认/拒绝轻动作。不要做完整资料中心/knowledge browser，不让 widget 读隐藏 JSON，不开启下一任务。补 view data/widget tests，注意窄屏可用性。
```

### IED-16：CLI 最小确认与摘要消费

本轮目标：让 CLI 能查看 pending research、确认/拒绝，并在 workflow summary 中显示 information evidence 状态。

层级归属：CLI / presentation shell。

必读文件：

- IED-07、IED-13 实现
- `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
- `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`
- `apps/novel_agent_cli/test/workflow_output_summary_service_test.dart`

必须完成：

1. workflow summary 显示 information evidence 摘要。
2. 增加最小 CLI action：list pending research、approve、reject。
3. CLI 只调用 adapter action service，不解释 payload。
4. 补 CLI tests。

本轮不要做：

1. 不补完整 CLI 主线。
2. 不做 TUI。
3. 不真实联网。
4. 不开启下一任务。

验收标准：

1. CLI 能完成非 GUI 环境下的轻确认。
2. 输出文案人话、短而清楚。
3. 不破坏现有 workflow command。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-16，只做 CLI 最小确认与摘要消费。Workflow summary 显示 information evidence 摘要，新增 list pending research / approve / reject 最小 action，CLI 只调用 adapter action service，不解释 raw payload。不补完整 CLI 主线、不做 TUI、不真实联网、不开启下一任务。补 CLI tests。
```

### IED-17：Gated real provider 小预算验收

本轮目标：用真实 provider 小预算验证开放权限自动研究、受限权限 pending、普通项目和长任务 summary。

层级归属：Probe / gated real validation。

必读文件：

- IED-14 到 IED-16 完成记录
- `apps/novel_agent_app/tool/probe_support.dart`
- `apps/novel_agent_app/tool/real_general_novel_probe.dart`
- `apps/novel_agent_app/tool/real_long_task_probe.dart`
- `tools/probe_config_support.dart`

必须完成：

1. 必须先确认 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`。
2. 使用本地配置，不硬编码 key/model。
3. 跑小预算：
   - 普通项目 2-3 章，包含一个明确需要外部资料的输入。
   - 普通项目 restricted 权限 pending 场景。
   - 长任务短链 3-5 步，验证 summary 和 checkpoint。
4. 保留产物。
5. 报告区分：success / waiting_user / evidence_quality_failure / technical_failure / budget_failure。

本轮不要做：

1. 不跑 200 章。
2. 不删除产物。
3. 不把真实失败偷偷改成 probe 私有成功。
4. 不开启下一任务。

验收标准：

1. 至少一个开放权限样本观察到 research note 或明确的 no-info-needed 解释。
2. 至少一个受限权限样本进入 pending confirmation。
3. 长任务 summary 能看到 information evidence 状态。
4. 报告保存到 `artifacts/`。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-17，只做 gated real provider 小预算验收。必须确认 NOVEL_AGENT_ENABLE_REAL_PROBES=1，使用本地配置不硬编码 key/model；跑普通项目 2-3 章含外部资料需求、restricted pending 场景、长任务 3-5 步 summary/checkpoint 验证。保留产物，报告区分 success/waiting_user/evidence_quality/technical/budget。不跑 200 章，不删除产物，不开启下一任务。
```

### IED-18：文档、项目约束与交接收口

本轮目标：把实现结果、剩余风险、使用边界和后续维护规则写清楚。

层级归属：Documentation / handoff。

必读文件：

- IED-01 到 IED-17 完成记录
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `agent.md`
- `README.md`
- `docs/project-information-substrate-session-order-2026-06-05.md`

必须完成：

1. 回填本文档所有完成记录。
2. 更新分析文档的实现状态与剩余风险。
3. 如有必要，微调 `agent.md` 中信息/证据纪律约束。
4. 新增一份短 handoff：说明如何开启/禁用联网研究、如何确认 pending、如何看报告。
5. 明确不完整项和后续优化项。

本轮不要做：

1. 不写新业务代码。
2. 不跑真实 probe。
3. 不扩 GUI。
4. 不开启新主线。

验收标准：

1. 文档能让下一会话直接维护该主线。
2. 没有把未完成能力写成已完成。
3. 剩余风险明确且不误导用户。

直接可用提示词：

```text
根据 `docs/information-evidence-discipline-session-order-2026-06-05.md` 开启 IED-18，只做文档、项目约束与交接收口。回填所有完成记录，更新信息收集分析文档实现状态和剩余风险，必要时微调 agent.md，新增短 handoff 说明联网研究权限、pending 确认、报告查看方式。不写新业务代码、不跑真实 probe、不扩 GUI、不开启新主线。
```

---

## 10. 总启动提示词

```text
根据目前的进度和文档：docs/information-evidence-discipline-session-order-2026-06-05.md 继续下一步。每次只确认完成一个具体任务；如果上个会话末尾卡在具体任务的一半未完成或者出现关联性错误，就先修好上个任务，不开启下一轮。你需要直接识别当前 session 的提示词、任务内容、层级职责和约束，完整完成并补 focused tests / contract tests。始终遵守解耦合、单一职责、复用现有 service/contract/repository/runtime hook、不让单文件过重、不把 GUI/CLI/probe/fallback 做成业务中心、不提交私有 key 或无关测试产物。GUI/CLI 只在最后消费稳定合同。如果已经完成最后一轮任务，则忽略自动继续内容，开启阻塞式控制台命令任务，等待我回来手动关闭。
```

---

## 11. 完成记录占位

- IED-01：已完成（2026-06-05，已读取 `agent.md`、`docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`、PIS 完成记录与当前 information/runtime/settings 实现，并把审计补充回填到 `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`。本轮确认：`request_external_research` 已能登记 pending request，但宿主权限尚未覆盖模型自声明的 `user_granted_network_access`；`ProjectInformationDomainToolExecutor` 只持久化 request 和 event，未自动触发 gateway/import coordinator；`ProjectResearchGatewayService` 与 `ProjectInformationImportCollectionService` 已能生成 research note / source audit / projection，但尚未被 runtime 权限链稳定调用；`NarrativeSupervisorRiskPolicyService`、`WritingExecutionResultNormalizerService`、long task station 与 CLI 已有最小 information summary 消费位，但 evidence gate 与 approve/reject 闭环仍未正式收口。另已确认 `allow_network` 目前由 settings panel 写入 `permissions.allow_network`，经 `AppShellController` 和 `LocalSettingsRepository` 持久化到 `novel_agent_settings.json`，但还没有桥到 information tool 执行链。因此下一轮应进入 `IED-02`，只补纯 core 的宿主信息权限上下文合同，不重做 PIS 基座。）
- IED-02：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增纯 core 合同 `HostInformationPermissionContext`、`HostInformationPermissionResolution` 与 `HostInformationPermissionResolverService`，把宿主权限与模型原始声明分离：上下文字段覆盖 `allowNetwork`、`allowImportCollection`、`permissionMode`、`confirmationMode`、`source`、`metadata`，resolver 则根据 `InformationCollectionRequest` 与宿主上下文生成 effective request，明确 `user_granted_network_access` 只代表 raw model declaration，而 `effectiveRequest.userGrantedNetworkAccess` 才是宿主生效授权。与此同时，`InformationCollectionRequest` 已新增 `rawModelUserGrantedNetworkAccess` 语义化 getter，并把 raw/effective 授权、host mode/source 等审计字段回写到 metadata，供后续 adapters 在不读 settings 文件的前提下接线；本轮没有修改 `RequestExternalResearchHandler` 行为，也没有接 adapters / GUI。已新增 `packages/novel_agent_core/test/host_information_permission_contracts_test.dart`，覆盖 open / safe / import / model lied / unknown mode / codec round-trip / validation 场景；`packages/novel_agent_core` 下 `dart test test/host_information_permission_contracts_test.dart test/information_policy_contracts_test.dart` 已通过，且针对新增文件的 `dart analyze ...` 已无问题。因此下一轮可进入 `IED-03`，只做 pure core 的 research execution decision service。）
- IED-03：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增 pure core 的 `InformationResearchExecutionDecision` 与 `InformationResearchExecutionDecisionService`，输入为 `InformationCollectionRequest`、`HostInformationPermissionContext`、`InformationPermissionDecision`，输出稳定收口 `autoExecuteNetwork`、`autoExecuteImport`、`awaitUserConfirmation`、`blocked`、`reason` 与 `effectiveRequest`。本轮明确了 hybrid 语义：导入部分可执行时先 `autoExecuteImport=true`，联网部分再按宿主权限与 permission decision 决定是 `autoExecuteNetwork`、`awaitUserConfirmation` 还是仅保留 import；`forbidden_auto_apply` 直接 blocked；`needs_user_confirmation` 则进入等待确认而不误判为 blocked。实现继续复用 IED-02 的 `HostInformationPermissionResolverService` 与既有 `InformationCollectionPolicyService`，没有执行 gateway、没有写 pending 文件、没有改 dispatcher/UI。已新增 `packages/novel_agent_core/test/information_research_execution_decision_service_test.dart`，覆盖 open / restricted / import / hybrid / high-risk reference / forbidden payload 场景；`packages/novel_agent_core` 下 `dart test test/information_research_execution_decision_service_test.dart test/host_information_permission_contracts_test.dart test/information_policy_contracts_test.dart` 已通过，且针对新增文件的 `dart analyze ...` 已无问题。因此下一轮可进入 `IED-04`，只做 pure core 的 information evidence gate 合同。）
- IED-04：已完成（2026-06-06，已在 `packages/novel_agent_core/lib/src/workflow/` 新增 pure core 合同 `InformationEvidenceGateSignal`，稳定表达 `severity`、`recommendedDisposition`、`summary`、`changedPaths` 以及 `pendingResearch / awaitingConfirmation / gatewayFailure / rigorousSourceInsufficient / requiredInformationOmitted / externalFactUnverified` 六类 evidence gate 计数；同时保持 `category / waiting_user / requires_repair / manual_attention_required` 旧字段兼容，不把 evidence gap 伪装成 expression review。本轮还扩展了 `WritingExecutionInformationSummary`，新增 `evidenceGate` 子合同，并在 `WritingExecutionResultNormalizerService` 中把松散 `informationSignal` 统一规范化为共享 evidence gate 语义：普通 pending research 只产生 warning，不误升格成 waiting user；真实 awaiting confirmation 进入 `checkpoint_user` / `user_action_required`；`gateway_failed` 与 `rigorous_source_insufficient` 进入 recoverable evidence repair；`external_fact_unverified` 与 `required information omitted` 也会进入同一 gate。与此同时，`NarrativeSupervisorRiskPolicyService` 已统一输出相同语义的 `information` signal，并兼容消费已有 `execution/result` 中提供的 evidence gate 输入，因此普通项目与长任务后续都能复用这一层，不需要 adapter 私有判断。本轮未改 adapters、GUI、长任务 runtime 或联网行为。已新增/补强 focused tests 于 `packages/novel_agent_core/test/writing_execution_result_contracts_test.dart` 与 `packages/novel_agent_core/test/narrative_supervisor_risk_policy_service_test.dart`，覆盖普通成功、plain pending、awaiting confirmation、严谨来源不足、gateway failed、外部事实未核验、高风险引用边界等场景；`packages/novel_agent_core` 下 `dart test test/writing_execution_result_contracts_test.dart test/narrative_supervisor_risk_policy_service_test.dart` 已通过，且针对新增/修改文件的 `dart analyze ...` 已无问题。因此下一轮可进入 `IED-05`，只做 adapters 本地权限设置到 host context 的薄桥。）
- IED-05：已完成（2026-06-06，已在 `packages/novel_agent_adapters/lib/src/config/` 新增 adapter 薄桥 `ProjectInformationPermissionSettingsResolverService`，负责把 `AppSettings.permissionSettings` 与持久化 `permissions` 段稳定映射到 IED-02 的 pure core `HostInformationPermissionContext`，不读取本地设置文件、不做 runtime/dispatcher 决策，也不改 GUI 保存结构。当前 bridge 已兼容 `mode / permission_mode / information_permission_mode`、`allow_network`、未来 `allow_import_collection` 与 `information_confirmation_mode` 字段，并把宿主设置原文保留到 metadata；映射规则保持默认安全：缺失设置时视为 `safe`、`allowNetwork=false`、`allowImportCollection=true`、`confirmationMode=user_confirmation_required`，因此不会因为缺省配置而自动联网。与此同时，本轮明确了与现有 GUI 设置的兼容关系：`PermissionsSettingsPanel` 仍继续保存 `mode` 与 `allow_network` 等旧字段，adapter bridge 只做翻译，不要求先改 settings UI；`import_only` 与未来显式 `allow_import_collection` / `information_confirmation_mode` 也已预留兼容口，供后续 IED-06 到 IED-09 接线时直接消费。本轮未改 `LocalSettingsRepository` 的读写结构、未接 `ProjectToolDispatcher`、未改 workflow/runtime，也未触碰 GUI/CLI。已新增 `packages/novel_agent_adapters/test/project_information_permission_settings_resolver_service_test.dart`，覆盖缺省安全、open、import_only、custom、未来兼容字段、unknown mode 场景；`packages/novel_agent_adapters` 下 `dart test test/project_information_permission_settings_resolver_service_test.dart test/local_settings_repository_test.dart` 已通过，且针对新增/修改文件的 `dart analyze ...` 已无问题。因此下一轮可进入 `IED-06`，只做 tool dispatcher / information executor 的宿主授权覆盖接线。）
- IED-06：已完成（2026-06-06，已在 `packages/novel_agent_adapters/lib/src/tools/project_information_domain_tool_executor.dart` 与 `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart` 完成宿主授权覆盖接线，但严格保持为 adapter 边界的薄改动：`ProjectInformationDomainToolExecutor` 新增可注入的 `HostInformationPermissionResolverService`，并在 `execute(..., hostPermissionContext:)` 中仅针对 `request_external_research` 把原始 `DomainToolRequest.requestPayload` 解析为 `InformationCollectionRequest`，用 IED-02 的 `HostInformationPermissionResolverService` 生成 effective request 后再交给既有 core handler；`ProjectToolDispatcher` 则仅新增可选构造参数 `hostInformationPermissionContext` 并向 information executor 透传，不读取 settings、不变成新的权限中心，也不改其他 information tools 的执行路径。这样一来，模型 payload 中的 `user_granted_network_access` 仍会作为 `raw_model_user_granted_network_access` 审计字段保留在 research request metadata 中，而真正生效的 `user_granted_network_access` 已由宿主上下文覆盖：host safe 能把 model `true` 压回 `false` 并进入 `awaiting_user_confirmation`，host open 也能把 model `false` 提升为可自动后续执行的 `pending_gateway_execution`；与此同时，`submit_research_note / propose_design_element / propose_reference_work / link_information_evidence` 等其他 information tools 未受影响。本轮补强了 `packages/novel_agent_adapters/test/project_information_domain_tool_executor_test.dart` 与 `packages/novel_agent_adapters/test/project_tool_dispatcher_domain_tools_test.dart`，覆盖 safe/open override、raw 审计保留、dispatcher 透传与非 research 工具不受影响场景；`packages/novel_agent_adapters` 下 `dart test test/project_information_domain_tool_executor_test.dart test/project_tool_dispatcher_domain_tools_test.dart` 与 `dart analyze lib/src/tools/project_information_domain_tool_executor.dart lib/src/tools/project_tool_dispatcher.dart test/project_information_domain_tool_executor_test.dart test/project_tool_dispatcher_domain_tools_test.dart` 已通过。因此下一轮可进入 `IED-07`，只做 pending research confirmation action，不开启自动 gateway 协调或 runtime 大接线。）
- IED-07：已完成（2026-06-06，已在 `packages/novel_agent_adapters/lib/src/tools/` 新增统一 adapter action service `ProjectPendingResearchActionService`，并导出到 `packages/novel_agent_adapters/lib/novel_agent_adapters.dart`，专门负责 pending research request 的 `list / approve / reject / markNeedsUserInfo`，从而让后续 GUI / CLI 只调用稳定 service，而不需要直接改 `.novel_agent/information/research_requests/*.json` 隐藏记录。本轮实现继续严格复用现有 information 持久化链：service 使用 `ProjectInformationPathService`、`ProjectJsonDocumentService`、`OpenNarrativeStateIndexDocumentService`、`OpenNarrativeStateRecordDocumentService` 与 `LocalInformationEventRepository` 统一读取/回写 request record、index 与 information event；`approve` 只把 request 从 `awaiting_user_confirmation / pending_review / needs_user_info` 等状态重新收口到 `pending_gateway_execution`，并把 `permission_decision.disposition` 更新为 `accepted`，但不直接执行 gateway，从而不绕过后续 `IED-08` coordinator；`reject` 只把 request 标记为 `rejected` 并保留 record / evidence gap / 审计事件，不删除记录也不伪装成已研究；`markNeedsUserInfo` 则把 request 置为 `needs_user_info`，明确还需用户补充资料，而不是误判为已拒绝或已完成。与此同时，service 为每次动作统一补写 `pending_research_actions` / `latest_pending_research_action` metadata、`resolved_by` / `resolution_note` / 时间戳，以及 `research_request_approved / research_request_rejected / research_request_needs_user_info` 生命周期事件，保证 changed paths 与审计事件稳定可追踪。已新增 `packages/novel_agent_adapters/test/project_pending_research_action_service_test.dart`，覆盖 actionable list 过滤、approve、reject、markNeedsUserInfo、缺失 request、重复 reject 幂等等 focused 场景，并回归验证 `packages/novel_agent_adapters/test/project_research_gateway_service_test.dart` 与 `test/project_long_task_station_detail_service_test.dart`，确保本轮状态扩展未破坏既有 pending/gateway/summary 消费；`packages/novel_agent_adapters` 下 `dart test test/project_pending_research_action_service_test.dart test/project_research_gateway_service_test.dart test/project_long_task_station_detail_service_test.dart` 与 `dart analyze lib/src/tools/project_pending_research_action_service.dart lib/novel_agent_adapters.dart test/project_pending_research_action_service_test.dart` 已通过。因此下一轮可进入 `IED-08`，只做自动研究执行协调器，把 accepted pending request 按决策分派到 gateway research 或 import collection，而不回退到 GUI/CLI 私有状态改写。）
- IED-08：已完成（2026-06-06，已在 `packages/novel_agent_adapters/lib/src/tools/` 新增小型 adapter 协调器 `ProjectInformationResearchCoordinatorService` 与结果合同 `ProjectInformationResearchCoordinatorResult`，并补导出 `ProjectInformationResearchExecutionBudget`，专门负责把已登记的 pending research request 按 IED-03 的 core 决策分派到既有 `ProjectResearchGatewayService` 或 `ProjectInformationImportCollectionService`，而不复制 gateway / import 内部逻辑，也不提前接到 tool executor。本轮明确收口了两个关键语义坑：其一，`IED-07` 中已被 `approve` 的 network / hybrid request 不再因为宿主仍处于 `safe` 或 `allowNetwork=false` 而在 coordinator 内再次被误拦截；协调器会基于 `latest_pending_research_action=approve` 做 request-level 执行 override，仅影响本条已批准 request 的执行决策与 gateway 放行，不篡改普通 request 的宿主权限语义。其二，hybrid request 会先执行 import，再根据宿主/权限决策决定是否继续 network；若联网仍需确认，则 request 保持 `awaiting_user_confirmation`，同时把 `import_execution_performed`、`generated_import_research_note_id`、`import_summary` 与 `execution_decision` 回写到 request record，避免下次 coordinator 重复导入。与此同时，`ProjectResearchGatewayService.processPendingRequest(...)` 已增加最小的 `permissionDecisionOverride` 注入点，供 coordinator 在“已 approve 的待执行 request”场景下复用既有 gateway 流程，而不是重写搜索/抓取/审计逻辑；普通 gateway 行为、导入服务、pending action service 与 executor 接线均未被重构。已新增 `packages/novel_agent_adapters/test/project_information_research_coordinator_service_test.dart`，覆盖 approved network success、import success、hybrid partial and no re-import、permission blocked、gateway failed 五个 IED-08 验收场景，并回归验证 `packages/novel_agent_adapters/test/project_research_gateway_service_test.dart` 与 `test/project_pending_research_action_service_test.dart`；`packages/novel_agent_adapters` 下 `dart test test/project_information_research_coordinator_service_test.dart test/project_research_gateway_service_test.dart test/project_pending_research_action_service_test.dart` 与 `dart analyze lib/src/tools/project_information_research_coordinator_service.dart lib/src/tools/project_information_research_coordinator_result.dart lib/src/tools/project_research_gateway_service.dart test/project_information_research_coordinator_service_test.dart` 已通过。因此下一轮可进入 `IED-09`，只做 information executor 在 request 持久化后调用 coordinator 的自动执行接线，不回退修改本轮 coordinator 语义。）
- IED-09：已完成（2026-06-06，已在 `packages/novel_agent_adapters/lib/src/tools/project_information_domain_tool_executor.dart` 与 `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart` 完成 information executor 的自动执行接线，让 `request_external_research` 不再只停在“登记 pending request”，而是在 request record 持久化后立即调用 IED-08 的 `ProjectInformationResearchCoordinatorService`，按宿主 `HostInformationPermissionContext` 决定是否自动执行 gateway/import，或保持 `awaiting_user_confirmation / pending`。本轮仍严格保持 adapter/tool execution 边界：没有改普通写作 runtime、没有改长任务 runtime、没有接 GUI，也没有跑真实网络；自动执行仅发生在 information executor 内部，且继续复用 IED-08 coordinator、IED-06 的宿主权限覆盖与既有 gateway/import services，而不把 dispatcher/executor 变成新的权限大中心。具体收口行为为：开放权限下，network request 会在持久化 research request 后自动生成 research note、projection 与相关 changed paths，并把 `network_execution_performed=true`、`research_execution` 摘要、生成的 note ids、最终 `request_state` 等结构化结果回写到 domain outcome；import request 则会自动导入并把 `import_execution_performed=true` 与导入摘要写回；受限权限下仍保持 `needs_user_confirmation / awaiting_user_confirmation`，不会偷偷联网执行。与此同时，`ProjectToolDispatcher` 已新增可注入的 `informationDomainToolExecutor` 入口，便于 focused tests 用 fake gateway 验证接线而不依赖真实网络；其 `tool_result_summary` 也已对 `request_external_research` 细分为“已登记并自动执行资料研究 / 已登记并执行导入研究 / 已登记待研究请求，等待用户确认 / 已登记待研究请求，但当前无法执行”等摘要，满足本轮验收要求中对 registered / executed / pending / blocked 的区分。为避免 `IED-09` 的新自动执行语义污染前序任务测试，本轮还把 `project_information_research_coordinator_service_test.dart` 与 `project_pending_research_action_service_test.dart` 的夹具显式切回 noop coordinator，从而继续只测试 IED-08/IED-07 自身边界，而不是被 executor 自动执行串改场景。已补强 `packages/novel_agent_adapters/test/project_information_domain_tool_executor_test.dart` 与 `packages/novel_agent_adapters/test/project_tool_dispatcher_domain_tools_test.dart`，覆盖 open 权限下 fake gateway 自动执行、import 自动执行、safe 权限仍等待确认、dispatcher 摘要与透传不影响其他 information tools；并完成回归验证 `packages/novel_agent_adapters/test/project_information_research_coordinator_service_test.dart`、`test/project_research_gateway_service_test.dart`、`test/project_pending_research_action_service_test.dart`。`packages/novel_agent_adapters` 下 `dart test test/project_information_research_coordinator_service_test.dart test/project_research_gateway_service_test.dart test/project_pending_research_action_service_test.dart test/project_information_domain_tool_executor_test.dart test/project_tool_dispatcher_domain_tools_test.dart` 与 `dart analyze lib/src/tools/project_information_domain_tool_executor.dart lib/src/tools/project_tool_dispatcher.dart test/project_information_domain_tool_executor_test.dart test/project_tool_dispatcher_domain_tools_test.dart test/project_information_research_coordinator_service_test.dart test/project_pending_research_action_service_test.dart` 已通过。因此下一轮可进入 `IED-10`，只做普通写作 runtime 传入宿主信息权限上下文与 information execution summary 回写，不回退本轮 executor 自动执行闭环。）
- IED-10：已完成（2026-06-06，已在 `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`、`packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`、`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`、`apps/novel_agent_app/lib/app/state/app_shell_controller.dart` 与 `apps/novel_agent_app/lib/app/bootstrap/app_bootstrap.dart` 完成普通写作 runtime 接线，确保普通会话不再绕开 information evidence discipline。本轮先修复了一个与验收直接相关的关联性错误：普通章节/修订会话原先仍把 `request_external_research` 从对话暴露工具里屏蔽，导致“开放权限自动研究 / 受限 pending”路径在 ordinary runtime 中根本不可达；现已把该工具纳入普通会话的 information tool 暴露集合，同时继续保留 `set_agent_tasks / call_sub_agent` 的阻断，不把长任务或委派能力误放回普通写作。与此同时，`ProjectToolDispatcher` 新增 `scopedWithHostInformationPermissionContext(...)`，GUI 普通会话通过 host-aware factory 按当前 `AppSettings.permissionSettings` 动态创建带宿主信息权限上下文的 scoped dispatcher，因此 `request_external_research` 在普通会话中也会复用 IED-06 到 IED-09 的宿主授权覆盖与自动研究闭环：开放权限下可自动执行 fake gateway/import，受限权限下保持 `awaiting_user_confirmation / pending`，且不影响长任务、CLI 与全局默认 tool port。普通 draft runtime 收尾阶段则新增了稳定的 information execution 聚合：`ProjectConversationDraftRuntimeArtifacts` 现在会回写 `informationStatus / informationSummary / informationChangedPaths`，并在 finalization 时把 domain result、adapter persistence 与 `research_execution.changed_paths` 统一并入 changed paths；摘要可区分 `no_information_change / executed_research / waiting_confirmation / source_insufficient / blocked / information_changed`，其中严谨来源不足来自 gateway 的 `source_quality_summary` 稳定字段而非字符串猜测。为了让现有 workbench 直接消费而不新增 GUI 结构，`WorkbenchConversationController` 已把 ordinary runtime 的 information summary 合并进 `contextSummary / generationStatus / toolCoreStatus`：无资料需求时显示“无 information 变更”，自动研究会显示“资料研究已执行”，待确认会显示“资料研究待确认”，来源不足会显示“资料来源不足”，并保持普通会话成功回写时不再被 session public summary 覆盖。已补强 focused tests：`packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart` 新增/更新 ordinary runtime 场景，覆盖普通章节暴露 `request_external_research`、开放权限自动研究 changed paths+summary、受限 pending waiting_confirmation、无资料需求不触发；`apps/novel_agent_app/test/workbench_conversation_controller_agent_selection_test.dart` 新增 GUI 层普通会话场景，覆盖宿主信息权限上下文透传到 host-aware factory，以及 ordinary runtime information summary 回写到 workbench status。验证方面，`packages/novel_agent_adapters` 下 `dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart test/project_conversation_draft_runtime_service_test.dart` 与 `dart test test/project_conversation_draft_runtime_service_test.dart` 已通过；`apps/novel_agent_app` 下 `dart analyze lib/features/workbench/application/controllers/workbench_conversation_controller.dart test/workbench_conversation_controller_agent_selection_test.dart` 与 `flutter test test/workbench_conversation_controller_agent_selection_test.dart` 已通过（该 app package 当前未单独声明 `package:test`，因此 focused app verification 使用 `flutter test` 而非 `dart test`）。因此下一轮可进入 `IED-11`，只做长任务 workflow / supervisor 的宿主信息权限上下文与 evidence gate 接线，不回退本轮 ordinary runtime 闭环。）
- IED-11：已完成（2026-06-06，已在 `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`、`apps/novel_agent_app/lib/app/bootstrap/app_bootstrap.dart` 与 `apps/novel_agent_cli/lib/bootstrap/cli_bootstrap.dart` 完成长任务 workflow / supervisor 的宿主信息权限上下文与 evidence gate 接线，但继续保持为薄适配层改动，没有把 `ProjectWorkflowRuntimeService` 膨胀成新的权限/证据中心。本轮先补上长任务 runtime 的核心缺口：`ProjectWorkflowRuntimeService` 新增可选 `hostAwareGenerateDraftUseCaseFactory` 与 `ProjectInformationPermissionSettingsResolverService` 注入点，长任务正文单步与 postprocess 两处 `GenerateDraftUseCase` 创建现在都会按当前 `AppSettings.permissionSettings` 解析 `HostInformationPermissionContext`，并通过 GUI / CLI bootstrap 里的 scoped `ProjectToolDispatcher` 透传给 information executor，因此长任务里的 `request_external_research` 也会复用 IED-06 到 IED-10 已打通的宿主授权覆盖与自动研究闭环，而不是继续绕过宿主权限。与此同时，本轮把长任务 checkpoint / recovery 的 information evidence gate 落点收紧到共享语义：runtime 成功收尾时不再只看 chapter gate 默认状态，而是优先消费 `checkpoint_review.review.continuation_disposition` 与 `information_signal.category`，将 `checkpoint_user` 稳定映射到 `waiting_user / resume_when_user_confirms`，将 `gateway_failed / rigorous_source_insufficient / required omitted` 等 `repair` 类信息信号稳定映射到 `pause_for_repair`，并将 `manual_attention` 映射到 `paused / pause_for_manual_attention`，从而避免把资料网关失败误判为普通写作失败，也避免把待确认研究吞成普通成功。由于 `LongTaskRunStepRecorderService`、`TaskQueueStopPolicyService`、`LongTaskRecoveryService` 与 shared `WritingExecutionResult` 之前已经消费同一套字段，本轮无需再改 core 调度状态机，就让 long-task run record、scheduler stop、checkpoint review 与 recovery 建议自动对齐到同一份 evidence gate 语义。已补强 focused tests 于 `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`，覆盖长任务 draft execution 收到宿主信息权限上下文、`awaiting_confirmation` 进入 `waiting_user`、`gateway_failed` 保持 repair 而非 technical failure 等场景，并回归验证 `packages/novel_agent_adapters/test/project_long_task_checkpoint_review_service_test.dart` 与 `packages/novel_agent_core/test/long_task_checkpoint_review_service_test.dart`、`test/long_task_runtime_services_test.dart`，确认 checkpoint review、run record 与 recovery 语义未回退。验证方面：`packages/novel_agent_adapters` 下 `dart analyze` 已通过，`dart test test/project_workflow_runtime_service_test.dart` 与 `dart test test/project_long_task_checkpoint_review_service_test.dart` 已通过；`packages/novel_agent_core` 下 `dart test test/long_task_checkpoint_review_service_test.dart test/long_task_runtime_services_test.dart` 已通过。另已确认 `packages/novel_agent_core` 的整包 `dart analyze` 仍有既存未改文件 warning（`sub_agent_execution_service.dart`、`tool_permission_profile_service.dart`、`import_customization_bundle_use_case.dart` 等 unused field），不属于本轮改动引入；`apps/novel_agent_app` 下 `flutter analyze lib/app/bootstrap/app_bootstrap.dart` 与 `apps/novel_agent_cli` 下 `dart analyze` 也已通过。因此下一轮可进入 `IED-12`，只做拆书/解书或共享写作结果 evidence gate 的后续接线，不回退本轮 long-task host context 与 checkpoint evidence discipline 闭环。）
- IED-12：已完成（2026-06-06，已在 `packages/novel_agent_core/lib/src/workflow/information_evidence_gate_signal.dart`、`packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart` 与 `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart` 完成共享写作结果 evidence gate 收口，并把普通项目、长任务、拆书续写统一对齐到同一份 `WritingExecutionResult` 合同，而没有新造拆书私有流程或 GUI/CLI 私有判断。本轮先收紧 shared evidence gate 语义：`InformationEvidenceGateSignal` 现在把“仅严谨来源不足”稳定保留为 evidence warning，不再自动升级成 `repair`；真正阻断继续的仍然只有 `awaiting_confirmation`、`gateway_failed`、`required_information_omitted`、`external_fact_unverified` 或人工注意类信号，因此满足“轻微信息缺口只提示、不返修；阻断型缺口进入 waiting_user 或 repair”的 IED-12 口径。与此同时，`WritingExecutionResultNormalizerService` 的顶层 `summary` 已稳定把 information evidence gate 收入共享摘要，在普通成功、waiting user、recoverable failure 等状态下都会在主摘要后补充 `Information：...` 证据摘要，但只在真的有 activation/evidence 信号时追加，不会把默认空文案污染到无资料变更路径，从而让 evidence gate 与字数/表达限制同属一份共享写作结果摘要且不被后者吞并。更关键的是，本轮补上了 ordinary path 的共享结果缺口：`ProjectConversationDraftRuntimeService.finalizeDraftRun(...)` 现在会把已有的 activation report、普通章节 delivery、information research 执行摘要与 changed paths 统一喂给 shared normalizer，产出 `ProjectConversationDraftRuntimeArtifacts.writingExecutionResult`；`chapter/revision` 会落为 `ordinary_project`，`book_deconstruction_followup / continuation / explainer` 一类 followup 会映射为共享的 `deconstruction_followup / explainer_followup` workflow kind，因此普通会话、长任务 workflow 与拆书续写都在吃同一 gate 输入合同，而不是继续各自维持私有 summary 字段。已补强 focused tests：`packages/novel_agent_core/test/writing_execution_result_contracts_test.dart` 现在覆盖 pending research 顶层摘要带 `Information：...`、严谨来源不足保持 warning 而非 repair、gateway failed 仍为 recoverable repair；`packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart` 现在覆盖 ordinary review 自动研究产出 shared `writing_execution_result`、pending confirmation 进入 `user_action_required / resume_when_user_confirms`、严谨来源不足在 ordinary path 里保持 warning、以及 deconstruction followup 映射到共享 workflow kind；同时回归验证长任务共享路径 `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart` 的 waiting_user / gateway_failed 场景与 `packages/novel_agent_core/test/long_task_runtime_services_test.dart`，确认 long-task signal/recovery 继续消费同一份摘要合同。本轮验证已通过：`packages/novel_agent_core` 下 `dart test test/writing_execution_result_contracts_test.dart`、`dart test test/long_task_runtime_services_test.dart`、`dart analyze lib/src/workflow/information_evidence_gate_signal.dart lib/src/workflow/writing_execution_result_normalizer_service.dart test/writing_execution_result_contracts_test.dart`；`packages/novel_agent_adapters` 下 `dart test test/project_conversation_draft_runtime_service_test.dart`、`dart test test/project_workflow_runtime_service_test.dart --plain-name "runWorkflowTaskOnce routes information awaiting confirmation to waiting_user checkpoint state"`、`dart test test/project_workflow_runtime_service_test.dart --plain-name "runWorkflowTaskOnce keeps gateway failed information signal as repair instead of technical failure"` 与 `dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart test/project_conversation_draft_runtime_service_test.dart`。因此下一轮可进入 `IED-13`，只做运行投影与人话摘要收口，不回退本轮 shared writing result evidence gate 合同。）
- IED-13：已完成（2026-06-06，已在 `packages/novel_agent_adapters/lib/src/projection/information_evidence_projection_service.dart`、`packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/conversation_tool_entry_projection_service.dart` 与 `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart` 完成运行投影与人话摘要收口，并把普通项目工具结果、长任务 narrative summary、CLI workflow summary 全部对齐到同一份 `InformationEvidenceProjectionService`，没有新增 widget、CLI command 或外层 payload 解释逻辑。本轮新增 `InformationEvidenceProjection` / `InformationEvidenceProjectionItem` 共享投影合同与 focused tests，使 adapters 可以从 `WritingExecutionInformationSummary`、tool result、workflow information contract 三种入口统一产出“需要资料 / 已执行研究 / 来源不足 / 等待确认 / 已拒绝 / 资料投影路径”这套普通用户可读摘要，同时把 `risk_category`、计数器等诊断字段折叠到 `diagnosticLines`，默认不进入普通 GUI；并在实现中修正了一个关联性错误：只有真的存在 information evidence 内容时，tool result 才会暴露资料状态与资料投影，避免普通文件读取、确认类工具被默认空态摘要污染。长任务侧现在通过读取 hidden information records 组装 permission records，再把 `information`、`informationProjectionItems`、`informationPermissionItems` 映射自同一 shared projection；Workbench 工具时间线的 `detailSummary/detailBody` 也改为优先消费 shared projection 的人话摘要，只有 diagnostic tier 才附加 information diagnostics；CLI narrative summary 则不再自己拼英文 `Information` 计数行，统一输出 `资料状态 / 资料投影` 人话行。已补强测试：新增 `packages/novel_agent_adapters/test/information_evidence_projection_service_test.dart`，并更新 `packages/novel_agent_adapters/test/project_long_task_station_detail_service_test.dart`、`apps/novel_agent_app/test/conversation_tool_entry_projection_service_test.dart`、`apps/novel_agent_cli/test/workflow_output_summary_service_test.dart` 断言以覆盖 waiting confirmation、rejected、source insufficient、projection paths、普通工具不被默认 information 空态污染等场景。验证方面已通过：`packages/novel_agent_adapters` 下 `dart test test/information_evidence_projection_service_test.dart test/project_long_task_station_detail_service_test.dart`、`dart analyze lib/src/projection/information_evidence_projection.dart lib/src/projection/information_evidence_projection_item.dart lib/src/projection/information_evidence_projection_service.dart lib/src/runtime/project_long_task_station_detail_service.dart`；`apps/novel_agent_app` 下 `flutter test test/conversation_tool_entry_projection_service_test.dart` 与定向 `dart analyze`；`apps/novel_agent_cli` 下 `dart test test/workflow_output_summary_service_test.dart`。因此下一轮可进入 `IED-14`，只做 mock regression suite，把 open auto research、restricted pending、import、hybrid、gateway failed、rigorous source insufficient、ordinary runtime、long task checkpoint 全链路改为用 production contracts 一键回归，不回退本轮 shared projection 与人话摘要收口。）
- IED-14：已完成（2026-06-06，已新增 `tools/run_information_evidence_discipline_mock_regression_suite.ps1` 与 `docs/information-evidence-discipline-mock-regression-suite-2026-06-06.md`，把 IED-02 到 IED-13 已落成的 production contracts 收成一键 mock regression suite，并明确只跑 fake/mock 路径、不访问真实 provider、不联网、不走 GUI 真交互。本轮没有重写业务判断或额外发明 probe 私有逻辑，而是直接复用现有 adapters/runtime 的 focused tests 作为场景真源，再把这些场景按 `success / waiting_user / technical_failure / information_quality_failure` 分类写出到 `artifacts/` 报告。suite 当前覆盖 10 个关键场景：`open_network_auto_execute`、`restricted_network_pending_confirmation`、`import_collection_auto_execute`、`hybrid_partial_waiting_confirmation`、`gateway_failed_request`、`rigorous_source_insufficient`、`ordinary_runtime_auto_research`、`ordinary_runtime_pending_confirmation`、`long_task_checkpoint_waiting_confirmation`、`long_task_checkpoint_gateway_failed`，分别对应 open auto research、restricted pending、import、hybrid partial、gateway failed、严谨来源不足、ordinary runtime 与 long task checkpoint 两类 evidence gate 落点，满足 IED-14 要求的全链路 fake 覆盖。脚本现在每次运行都会在 `artifacts/information_evidence_mock_regression_suite/<timestamp>/` 生成 `information_evidence_mock_regression_report.json` 与 `.md`，报告包含 scenario id、layer、expected report category、command、duration、pass/fail 与 summary，并额外汇总分类计数；其中分类直接反映 production-contract 测试意图，不在脚本层做第二套业务推断。实跑验证已通过：`powershell -ExecutionPolicy Bypass -File tools/run_information_evidence_discipline_mock_regression_suite.ps1` 成功执行全部 10 个场景，生成最新报告目录 `artifacts/information_evidence_mock_regression_suite/2026-06-05T19-43-48.983Z/`；报告汇总为 `success=3`、`waiting_user=4`、`technical_failure=2`、`information_quality_failure=1`，`overall_ok=true`。本轮中途只修正了一个脚本层关联性错误：PowerShell 严格模式下对空过滤结果直接取 `.Count` 会报错，因此已改为先归集 `$failedResults = @(...)` 再统计，不影响任何 production 业务合同。因此下一轮可进入 `IED-15`，只做 GUI 轻确认与摘要消费，继续复用 IED-07 action service 与 IED-13 projection，不回退本轮 mock regression suite 与 artifacts 报告入口。）
- IED-15：已完成（2026-06-06，已在 `apps/novel_agent_app/lib/features/long_task_station/` 与 `apps/novel_agent_app/lib/features/workbench/` 完成 GUI 轻确认与摘要消费，并继续严格复用 IED-07 的 `ProjectPendingResearchActionService` 与 IED-13 的 shared projection，没有把 widget 重新拉回 hidden JSON，也没有扩张成完整资料中心/knowledge browser。本轮先把 pending research 的 GUI 闭环补齐到两个真实消费入口：`LongTaskStationController` 与 `WorkbenchWorkspaceController` 现在都可调用统一 action service 执行 `approve / reject`，并在动作完成后立即刷新详情/侧栏投影，因此普通用户可以直接在长任务详情页与工作台资料侧栏对“资料待确认”做确认或拒绝，而不是只能打开隐藏确认记录。与此同时，`LongTaskStationViewDataService` 与 `WorkspaceInformationProjectionService` 现在会把 shared projection 中 research request 的稳定 request id 收进轻量 view data；`LongTaskRunDetailPanel` 与 `ResourceInformationSection` 则在保留“打开确认记录 / 查看待确认”入口的同时，仅对 pending research 项显示窄屏友好的“确认 / 拒绝”双按钮，其他知识卡/设计/引用待确认仍维持只读查看，避免本轮范围失控。展示层继续保持人话摘要消费：Workbench 侧栏与 Long Task Station 都展示已执行研究、待确认、来源不足等 shared summary，不暴露 raw payload、内部 JSON 或 runtime gate 术语；完全开放权限路径也未被额外插入频繁确认，只在真的存在 pending research 时提供动作。已补 focused tests：`apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`、`test/resource_manager_panel_test.dart` 新增确认/拒绝按钮渲染与回调断言，`test/long_task_station_view_data_service_test.dart` 与 `test/workspace_information_projection_service_test.dart` 覆盖 pending research request id 投影，`test/long_task_station_controller_auto_refresh_test.dart` 覆盖 approve 后刷新详情投影并移除待确认项。验证已通过：`apps/novel_agent_app` 下 `dart analyze lib/features/long_task_station/application/controllers/long_task_station_controller.dart lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart lib/features/workbench/application/controllers/workbench_workspace_controller.dart lib/features/workbench/application/services/workspace_information_projection_service.dart lib/features/workbench/presentation/widgets/resource_information_section.dart test/long_task_run_detail_panel_test.dart test/resource_manager_panel_test.dart test/long_task_station_view_data_service_test.dart test/workspace_information_projection_service_test.dart test/long_task_station_controller_auto_refresh_test.dart` 与 `flutter test test/long_task_run_detail_panel_test.dart test/resource_manager_panel_test.dart test/long_task_station_view_data_service_test.dart test/workspace_information_projection_service_test.dart test/long_task_station_controller_auto_refresh_test.dart`。因此下一轮可进入 `IED-16`，只做 CLI 最小确认与摘要消费，继续复用 adapter action service 与 shared projection，不回退本轮 GUI 轻确认闭环。）
- IED-16：已完成（2026-06-06，已在 `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`、`apps/novel_agent_cli/lib/bootstrap/cli_bootstrap.dart` 与 `apps/novel_agent_cli/test/workflow_command_test.dart` 完成 CLI 最小确认与摘要消费闭环，并继续严格复用 IED-07 的 `ProjectPendingResearchActionService` 与 IED-13 的 shared summary/projection，没有把 CLI 扩张成 TUI、资料中心或 payload 调试入口。本轮保持 `workflow` 入口为薄壳：在既有 `WorkflowOutputSummaryService` 已提供的 information evidence 人话摘要基础上，新增 `workflow pending-research list`、`workflow pending-research approve`、`workflow pending-research reject` 三个最小子命令，全部只经统一 action service 转发，不直接扫描 hidden research request 文件，也不输出 raw JSON payload；其中 `list` 只打印 `request id｜状态｜query｜简短原因` 这类短行，`approve/reject` 只回显请求号、更新后状态和 changed paths，满足非 GUI 环境下的轻确认需求。CLI bootstrap 现已显式注入 `ProjectPendingResearchActionService` 给 `WorkflowCommand`，因此 CLI 与 GUI 继续共用同一份 pending research 动作合同，没有新增第二套确认逻辑。已补 focused tests：新增 `apps/novel_agent_cli/test/workflow_command_test.dart`，覆盖 pending list 的人话输出、approve 参数转发到 action service、reject 缺失 request id 时直接失败且不误调用 service；同时保留并回归 `apps/novel_agent_cli/test/workflow_output_summary_service_test.dart`，确认 workflow summary 继续输出 `资料状态 / 资料投影`。验证已通过：`apps/novel_agent_cli` 下 `dart analyze lib/bootstrap/cli_bootstrap.dart lib/commands/workflow/workflow_command.dart test/workflow_output_summary_service_test.dart test/workflow_command_test.dart` 与 `dart test test/workflow_output_summary_service_test.dart test/workflow_command_test.dart`。因此下一轮可进入 `IED-17`，只做 gated real provider 小预算验收，不回退本轮 CLI 轻确认闭环。）
- IED-17：已完成（2026-06-06，已按显式开闸方式完成 gated real provider 小预算验收：运行前确认 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`，provider 配置来自 `local/probe_api.txt`，未硬编码 key 或 model；本轮只调整 probe 侧入口与验收口径，没有改 production 业务逻辑。为满足普通项目真实验收范围，已新增 `apps/novel_agent_app/tool/real_information_evidence_ordinary_probe.dart`，并把 `apps/novel_agent_app/tool/real_long_task_probe.dart` 扩展为支持 `--stop-after-sample`，从而让长任务真实验证聚焦在 planning + sample + checkpoint 的短链可见性，而不是额外强绑“必须落出第 02 章”旧假设。静态验证已通过：`cd apps/novel_agent_app && flutter analyze tool/real_information_evidence_ordinary_probe.dart tool/real_long_task_probe.dart`。真实探针也已在显式开闸下跑通：`cd apps/novel_agent_app && $env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'; dart run tool\real_information_evidence_ordinary_probe.dart` 与 `cd apps/novel_agent_app && $env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'; dart run tool\real_long_task_probe.dart --stop-after-sample`。其中普通项目报告 `artifacts/real_information_evidence_ordinary_probe_report.json` 为 `PASS`，开放权限样本观察到真实 research request / research note 行为，且 `open_network_project.report_category=success`；受限权限样本稳定进入待确认路径，`restricted_network_project.report_category=waiting_user`，并保留工作区 `artifacts/real_information_evidence_ordinary_probe_workspace/2026-06-06T04-36-55-312314/`。长任务报告 `artifacts/real_long_task_probe_report.json` 为 `PASS`，本次使用 `stop_after_sample=true`，已验证短链 sample checkpoint 的 information evidence 摘要可见，`sample.checkpoint_information_summary` 为“当前没有新的 information 风险信号。”，且 `sample_checkpoint_information_visible=true`；对应工作区保留在 `artifacts/real_long_task_probe_workspace/2026-06-06T04-42-51-687033/`。本轮还修正了上一会话卡住的关联性问题：ordinary real probe 不再把“必须正式交付章节”误当成唯一成功标准，而是允许在开放权限路径下记录真实研究行为或明确的 no-info-needed 解释；long-task real probe 也不再把 IED-17 的真实验证范围错误收紧为章节 02 物化。因此下一轮可进入 `IED-18`，只做文档、项目约束与交接收口，不再继续真实 probe。）
- IED-18：已完成（2026-06-06，已完成文档、项目约束与交接收口，并严格限定在文档层：没有新增业务代码、没有重跑真实 probe、没有扩 GUI。主顺序文档现已回填 `IED-01` 到 `IED-18` 全部完成记录，其中 `IED-17` 的真实验收结果与 artifact 路径已正式固化；同时已更新 `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md` 的实现状态、剩余风险与维护口径，明确本主线已经从“边界分析”进入“生产合同闭环可用”，但仍保留“没有完整 knowledge browser / information center”“real probe 只是小预算样本成立”“projection 不是事实源”“来源质量与真实命中率仍需继续观察”等未完成项，避免把边界内最小产品化误写成全量产品完成。另已新增短交接文档 `docs/information-evidence-discipline-handoff-2026-06-06.md`，集中说明如何开启/禁用联网研究、如何在 GUI / CLI 确认或拒绝 pending research、如何查看 projection 与 mock/real probe 报告，以及后续维护时不要回退的约束。`agent.md` 本轮已复核，但现有“信息 / 证据纪律的落位”与“真实探针规则”约束已经足够覆盖这条主线，因此未做重复性改写。至此 `IED` 主线 18 个 session 已全部完成；后续若再收到同一自动继续提示，应按总启动提示词中的约定，忽略自动续跑并改为开启阻塞式控制台命令等待人工接管。）

---

## 12. 生成后自检

1. 已说明本文解决什么。
2. 已说明与 PIS、信息收集分析、发布收口文档的关系。
3. 已做已有实现去重审计，明确已有、半闭环、真正要补的层。
4. 已冻结架构边界。
5. 已描述目标终态。
6. 已覆盖权限桥、模型授权覆盖、pending 确认、自动 gateway/import、evidence gate、普通/长任务 runtime、GUI、CLI、probe、文档收口。
7. 顺序为 core/domain 先行，adapters/runtime 随后，projection/probe，再 GUI/CLI，最后真实 probe 和文档。
8. 每个 session 均包含目标、层级、必读文件、必须完成、本轮不要做、验收标准和直接可用提示词。
9. 每个 session 控制在一次会话可完成范围内。
10. 没有让单一文件、GUI、CLI、probe 或 fallback 成为新的业务中心。
11. 已明确普通项目、长任务、拆书续写共享同一证据纪律，不做类型私有逻辑。
12. 已包含总启动提示词和完成记录占位。
