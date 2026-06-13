# 表达限制执行策略任务顺序文档

最后更新：2026-06-06

主线代号：`ECP`（Expression Constraint Policy）

关联分析文档：

- `docs/expression-constraint-execution-policy-analysis-2026-06-06.md`
- `docs/unified-de-ai-writing-scheme-2026-05-28.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `docs/release-readiness-gui-core-consolidation-analysis-2026-06-05.md`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `agent.md`

关联代码锚点：

- `packages/novel_agent_core/lib/src/creative/expression_constraint_profile.dart`
- `packages/novel_agent_core/lib/src/creative/project_expression_constraint_binding.dart`
- `packages/novel_agent_core/lib/src/creative/expression_constraint_injection_policy_service.dart`
- `packages/novel_agent_core/lib/src/creative/expression_constraint_review_projection.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_result.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_summary.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart`
- `packages/novel_agent_core/lib/src/project/chapter_output_path_policy_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_chapter_output_policy_service.dart`
- `packages/novel_agent_core/lib/src/tools/domain/submit_chapter_delivery_handler.dart`
- `packages/novel_agent_adapters/lib/src/workflow/chapter_delivery_outcome_projection_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
- `apps/novel_agent_app/lib/features/project_assets/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/long_task_station/`
- `apps/novel_agent_cli/lib/commands/workflow/`
- `apps/novel_agent_app/tool/probe_support.dart`

---

## 1. 这份文档解决什么

这份文档把“表达限制执行策略”从分析落成可执行任务。它要解决的不是单个提示词变强，而是整条写作执行链里的五个问题：

1. 表达限制已经有 profile 和项目绑定，但缺少运行时执行策略，无法稳定表达“关闭 / 智能使用 / 强力约束”。
2. 当前 `ExpressionConstraintInjectionPolicyService` 只决定注入形态，不能决定 review 要求、违反处置、长期衰减升级和排除技术轮次。
3. 普通项目、长任务、拆书续写、解书/总结都需要共享表达限制能力，不能把它写成某个项目类型的私有逻辑。
4. 探针中出现的重复章号文件名、标题口径不稳、只生成九章等问题需要被单独诊断，不能错误归因给表达限制。
5. GUI 需要给用户自然的策略入口，但不暴露 `injection mode / binding id / stage id` 等内部字段。

最终目标是：

```text
profile/binding 负责“项目有哪些表达规则”
execution policy 负责“本次运行如何使用这些规则”
review/gate 负责“实际产物有没有明显失效以及如何处置”
runtime summary 负责“普通项目、长任务和探针可追踪”
GUI/CLI 负责“用人话展示和少量配置”
```

---

## 2. 与旧文档的关系

### 2.1 不推翻已有表达限制资源层

`ExpressionConstraintProfile` 和 `ProjectExpressionConstraintBinding` 是正确基础。本主线不重写资源层，不把内置 profile 变成项目私有对象，也不让项目级修改污染全局内置资源。

### 2.2 不重复信息基座和证据纪律

PIS / IED 主线已经负责 information、research、source quality、pending research 和 evidence gate。本主线只处理表达限制，不把信息收集塞进表达限制，也不让表达限制改变研究工具、路径、权限或来源证据。

### 2.3 不重新题材化连续性系统

快穿、死亡回归、明代穿越都只是测试输入，不是 core 分支。本主线只建立通用文本表达约束策略，不写死任何题材、世界观、时代或流派。

### 2.4 与发布收口文档的关系

发布收口要求 GUI 自然、可用、稳定。本主线的 GUI 任务只做表达限制相关的最小可用入口和摘要，不把项目资产页改成复杂专家控制台。

---

## 3. 已有实现去重审计

### 3.1 已有，不重做

1. `ExpressionConstraintProfile`：表达限制资源。
2. `ProjectExpressionConstraintBinding`：项目级启用、范围和权重。
3. `ExpressionConstraintInjectionPolicyService`：根据 intent / taskType / phase 解析注入形态。
4. `WritingExecutionConstraintBridgeService`：统一桥接字数和表达限制。
5. `WritingExecutionConstraintBridgeResult`：运行时约束结果载体。
6. `WritingExecutionConstraintSummary`：写作结果里的约束摘要。
7. `WritingExecutionResultNormalizerService`：把约束、交付、信息等结果归一。
8. `ExpressionConstraintReviewProjection`：表达限制审查投影。
9. 项目资产 GUI 中已有表达限制绑定入口。
10. 章节输出路径相关服务已有基础，不应另造一套路径规则。

### 3.2 已有但只是半成品

1. 注入模式只区分 `disabled / brief_only / brief_and_sections`，没有完整执行策略。
2. `expressionConstraintReviewRequired` 只表达是否需要审查，不表达为什么、如何处置、是否跳过。
3. `disabled` 和“本该审查但缺证据”容易在摘要层混淆。
4. 长任务连续多章表达限制衰减时，缺少结构化升级信号。
5. GUI 能绑定表达限制，但不能选择“关闭 / 智能使用 / 强力约束”。
6. 探针能发现风险，但容易形成私有判断，尚未完全消费 production 同源合同。
7. 章节文件名重复章号和标题口径问题已有修复基础，但需要被单独验收。
8. 长任务只生成九章的停止原因需要区分，不应由表达限制策略兜底。

### 3.3 真正要补的层

1. Core 执行策略合同。
2. Core 策略解析服务。
3. 注入策略服务与执行策略的分层接入。
4. Bridge result / summary / normalizer 的稳定字段。
5. 表达限制 review/gate 处置信号。
6. 最近章节摘要驱动的 adaptive 升级。
7. 普通项目、长任务、拆书/解书共享接线。
8. 章节路径/标题合同的独立回归。
9. Adapter projection / run center 消费。
10. Probe / regression 同源验收。
11. GUI / CLI 最小用户暴露。
12. 文档、agent 约束和交接收口。

---

## 4. 本轮冻结的架构边界

1. 表达限制不是 skill，不进入 skill loadout 语义。
2. 表达限制不是信息收集，不负责联网、导入、来源质量和研究权限。
3. 字数策略与表达限制同属写作执行约束，但不合并成一个大而泛的对象。
4. `ExpressionConstraintInjectionPolicyService` 保留为注入形态解析，不继续膨胀为全能策略中心。
5. 新 resolver 只做策略决策，不渲染 prompt、不读正文、不写文件。
6. Bridge 只聚合合同，不成为审稿算法中心。
7. Review/gate 可记录风险和处置建议，不用字符串扫描完全替代模型审查。
8. `force` 也不能污染工具 schema、工具参数、文件路径、调度状态、研究请求和 permission payload。
9. 普通项目、长任务、拆书续写、解书/总结必须共用同一 execution policy 合同。
10. GUI/CLI 只消费稳定合同，不解释 raw payload，不兜底底层设计缺口。
11. Probe 只消费 production 同源合同，不写第二套私有判定作为业务依据。
12. 不写死快穿、死亡回归、明代穿越、多世界、历史穿越等测试题材。

---

## 5. 目标终态

完成本主线后，应达到：

1. 用户可在项目级或运行级选择表达限制策略：关闭、智能使用、强力约束。
2. 内部以 `disabled / adaptive / force` 表达策略模式。
3. 策略输出稳定包含注入强度、审查要求、违反处置、是否允许升级和排除范围。
4. `disabled` 不误报缺少表达限制审查。
5. `adaptive` 能对正文、修订、总结等用户可见文本稳定使用表达限制，并对连续风险升级。
6. `force` 能强控正文与修订，但不污染工具协议、路径、研究和调度。
7. 普通项目每次生成都会重新解析项目绑定和策略，不依赖上一轮内存状态。
8. 长任务每章都会记录策略、注入、review、风险和处置，supervisor 能消费连续风险信号。
9. 拆书续写和解书/总结能按产物类型使用表达限制，不把正文规则强塞进分析阶段。
10. 章节文件名、正文 H1、delivery submission、GUI 列表标题有统一合同，重复章号问题有回归测试。
11. 长任务停止原因能区分预算/目标停止、等待用户、技术失败、内容质量失败和 gate 阻塞。
12. GUI 默认只展示人话策略和状态，高级诊断才显示内部字段。
13. CLI 至少能展示表达限制策略摘要和诊断状态，但不抢在 GUI 前做复杂配置。
14. 探针报告必须包含正文风险信号、review 证据、处置结果和章节路径/停止原因，不只看注入次数。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `18` 个 session。

理由：

1. `ECP-01` 先审计现状与探针失败面，避免重复已有修复。
2. `ECP-02` 到 `ECP-06` 先完成 core 合同、resolver、bridge、summary 和 gate。
3. `ECP-07` 到 `ECP-10` 接普通项目、长任务、拆书/解书和章节路径标题合同。
4. `ECP-11` 到 `ECP-12` 做 adapters projection 与 run center 消费。
5. `ECP-13` 到 `ECP-14` 做 regression 和 probe 框架，先保证生产合同可测。
6. `ECP-15` 到 `ECP-16` 才做 GUI / CLI 最小消费。
7. `ECP-17` 做 gated real probe，覆盖普通与长任务。
8. `ECP-18` 做文档、agent 约束、完成记录和交接。

每轮都应控制在一次会话可完成的实现量内。如果上一轮出现半成品或关联错误，先修上一轮，不开启本轮。

---

## 7. 全局执行规则

每个 session 都必须遵守：

1. 先读本文档、主分析文档、`agent.md` 和当前 session 的必读文件。
2. 只完成当前 session，不开启下一任务。
3. Core/domain 合同先行，GUI/CLI 最后消费。
4. 复用现有 profile、binding、bridge、summary、chapter output policy、domain tool、runtime hook。
5. 单文件超过 400 行复核职责，超过 700 行必须拆分。
6. 不把 fallback、probe、bridge、widget、runtime 门面写成新业务中心。
7. 每轮补 focused test / contract test，文档轮除外。
8. Probe 必须消费 production 同源合同，不另造私有业务判定。
9. 真实 provider 探针必须显式开闸，不默认消耗额度。
10. 不提交真实 key、一次性探针产物、无关 dirty 文件和不必要测试产物。
11. 不把测试题材、用户示例或探针 prompt 写成 core 分支。
12. 不因表达限制失败而把超长去 AI 文本硬塞进所有 prompt。

---

## 8. 设计目标覆盖表

| 目标 | 覆盖 session |
| --- | --- |
| 现状去重审计和探针失败归因 | ECP-01 |
| `disabled / adaptive / force` 核心合同 | ECP-02 |
| 策略解析与排除技术轮次 | ECP-03 |
| 注入策略与执行策略分层 | ECP-04 |
| Bridge result / summary / normalizer 稳定字段 | ECP-05 |
| review / gate / violation disposition | ECP-06 |
| adaptive 连续风险升级 | ECP-06、ECP-08、ECP-09 |
| 普通项目每次生成重算策略 | ECP-07 |
| 长任务逐章策略与 supervisor signal | ECP-08、ECP-12 |
| 拆书续写、解书/总结共享适配 | ECP-09 |
| 章节文件名、标题、delivery 口径统一 | ECP-10 |
| adapter projection 和 station detail | ECP-11、ECP-12 |
| probe 同源合同 | ECP-13、ECP-14、ECP-17 |
| GUI 用户友好暴露 | ECP-15 |
| CLI 最小消费 | ECP-16 |
| 文档、agent 约束和交接 | ECP-18 |

---

## 9. Session 顺序

### ECP-01：现有表达限制链路审计与失败归因

本轮目标：确认当前表达限制、章节路径、长任务停止诊断链路的真实现状，避免后续重复实现或错误归因。

层级归属：Documentation / Architecture audit。

必读文件：

- `docs/expression-constraint-execution-policy-analysis-2026-06-06.md`
- `agent.md`
- `packages/novel_agent_core/lib/src/creative/expression_constraint_injection_policy_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart`
- `packages/novel_agent_core/lib/src/project/chapter_output_path_policy_service.dart`
- `apps/novel_agent_app/tool/real_gui_viewmodel_information_long_task_probe.dart`
- `artifacts/real_gui_viewmodel_information_long_task_probe_workspace/2026-06-06T10-45-33-438435/明代社畜穿越资料纪律探针/chapters`

必须完成：

1. 新增或更新一份审计小节，列出现有 profile、binding、injection、bridge、summary、review、chapter path、long task stop signal 的 keep / extend / fix。
2. 明确重复章号文件名、标题口径、表达限制衰减、只生成九章分别属于哪条链路。
3. 标记哪些已有测试可复用，哪些缺 regression。
4. 回填本文档 ECP-01 完成记录。

本轮不要做：

1. 不写业务代码。
2. 不跑真实 provider。
3. 不改 GUI。
4. 不开启 ECP-02。

验收标准：

1. 审计结果能直接指导 ECP-02 到 ECP-14。
2. 没有把章节路径或停止诊断误归因给表达限制。
3. 没有重复已有 profile/binding 实现。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-01，只做现有表达限制链路审计与失败归因。必须读取主分析文档、agent.md、现有 expression constraint / writing constraint / chapter path 代码和这次 GUI viewmodel 探针产物，明确 keep / extend / fix，不写业务代码、不跑真实 provider、不改 GUI、不开启下一任务。注意不要把重复章号、标题口径、只生成九章误归因给表达限制。
```

### ECP-02：Core 执行策略合同

本轮目标：新增纯 core 的表达限制执行策略合同，稳定表达 disabled / adaptive / force 及其内部处置。

层级归属：Core / domain contract。

必读文件：

- ECP-01 审计结果
- `packages/novel_agent_core/lib/src/creative/expression_constraint_injection_mode.dart`
- `packages/novel_agent_core/lib/src/creative/expression_constraint_profile.dart`
- `packages/novel_agent_core/lib/src/creative/project_expression_constraint_binding.dart`
- `packages/novel_agent_core/lib/novel_agent_core.dart`

必须完成：

1. 新增 `ExpressionConstraintExecutionPolicy` 或等价合同。
2. 新增 mode、injection strength、review requirement、violation disposition 等小枚举或值对象。
3. 字段至少覆盖：mode、injectionStrength、reviewRequirement、violationDisposition、allowRuntimeEscalation、excludeToolProtocols、excludeResearchExecution、metadata。
4. 增加 codec / validation / copyWith / default adaptive。
5. 更新 core 导出。
6. 补 focused contract tests。

本轮不要做：

1. 不接 resolver。
2. 不改 bridge。
3. 不改 prompt。
4. 不做 GUI。

验收标准：

1. 合同纯 core，不依赖 adapters、Flutter、文件系统。
2. unknown metadata round-trip 不丢。
3. `disabled / adaptive / force` 默认值和校验清晰。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-02，只做 Core 表达限制执行策略合同。新增 ExpressionConstraintExecutionPolicy 或等价合同，覆盖 disabled/adaptive/force、injection strength、review requirement、violation disposition、runtime escalation、tool/research 排除范围和 metadata。不接 resolver/bridge/prompt/GUI、不开启下一任务。补 codec/validation/copyWith/focused tests，并保持小文件。
```

### ECP-03：Core 执行策略解析服务

本轮目标：把用户设置、项目类型、intent、taskType、phase、appliesTo、agent/mode/stage 和最近约束摘要解析成执行策略。

层级归属：Core / domain policy。

必读文件：

- ECP-02 合同
- `packages/novel_agent_core/lib/src/creative/expression_constraint_injection_policy_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_summary.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`

必须完成：

1. 新增 `ExpressionConstraintExecutionPolicyResolverService` 或等价服务。
2. 输入支持 override mode、intent、taskType、phase、appliesTo、projectTypeId、agentId、modeId、stageId、hasBindings、recent summaries。
3. 输出完整 execution policy 与 why applied / why skipped。
4. 明确技术轮次、tool-only、research execution、path resolution 默认排除。
5. `adaptive` 对正文/修订强于规划/研究，`force` 对用户可见文本强执行但仍排除协议轮次。
6. 补 tests 覆盖 disabled、adaptive、force、tool-only、research、review、long task recent violation escalation。

本轮不要做：

1. 不渲染 prompt。
2. 不读正文。
3. 不写文件。
4. 不改 GUI。

验收标准：

1. Resolver 只做决策，不成为审稿中心。
2. 所有策略输出可解释。
3. 没有题材分支。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-03，只做 Core 表达限制执行策略解析服务。输入 override、intent、taskType、phase、appliesTo、project/agent/mode/stage、hasBindings、recent summaries，输出 execution policy 和 why applied/skipped。必须排除 tool-only、research execution、path resolution 等技术轮次。不渲染 prompt、不读正文、不接 adapters/GUI、不开启下一任务。补 focused tests。
```

### ECP-04：注入策略服务接入执行策略

本轮目标：让现有注入模式服务继续负责注入形态，但由 ECP-03 的执行策略决定强弱和排除。

层级归属：Core / creative policy。

必读文件：

- ECP-02、ECP-03 实现
- `packages/novel_agent_core/lib/src/creative/expression_constraint_injection_policy_service.dart`
- `packages/novel_agent_core/lib/src/creative/creative_rule_stack.dart`
- `packages/novel_agent_core/test/expression_constraint_injection_policy_service_test.dart`

必须完成：

1. 改造或扩展 `ExpressionConstraintInjectionPolicyService`，接收 execution policy 或 policy mode/strength。
2. 保留现有 intent/taskType/phase 默认兼容行为，默认等价 `adaptive`。
3. `disabled` 清空表达限制 brief/section。
4. `force` 对用户可见文本输出强注入模式，但不改变 tool/path/research 排除。
5. 更新 focused tests，确保旧用法仍兼容。

本轮不要做：

1. 不接 `WritingExecutionConstraintBridgeService`。
2. 不改 result normalizer。
3. 不改 GUI。
4. 不重写 profile/binding。

验收标准：

1. 旧测试通过。
2. 新策略模式测试通过。
3. 注入服务不承担 review/gate 处置。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-04，只做注入策略服务接入执行策略。保留 ExpressionConstraintInjectionPolicyService 的职责为注入形态，接收 ECP-03 的 execution policy 或等价输入，默认兼容 adaptive。disabled 清空表达限制，force 强化用户可见文本注入，但不污染 tool/path/research。不接 bridge/normalizer/GUI、不开启下一任务。补兼容和新策略 tests。
```

### ECP-05：Writing execution bridge 与 summary 稳定字段

本轮目标：把执行策略接进 `WritingExecutionConstraintBridgeService`、bridge result 和 summary，让后续 runtime/probe 能稳定读取。

层级归属：Core / workflow contract。

必读文件：

- ECP-02 到 ECP-04 实现
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_result.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_summary.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart`
- `packages/novel_agent_core/test/writing_execution_constraint_bridge_service_test.dart`
- `packages/novel_agent_core/test/writing_execution_result_contracts_test.dart`

必须完成：

1. Bridge 输入新增策略 override 或用户设置入口，默认 adaptive。
2. Bridge result 输出 execution policy、injection strength、review requirement、violation disposition、applied/skipped reason。
3. Summary 能区分 disabled、skipped by policy、applied but review missing、applied and review provided、violation recorded。
4. Normalizer 不再把 disabled 当作缺审查。
5. runtimeReport 保留可解释字段，但不泄漏过多 raw payload。
6. 补 contract / normalizer tests。

本轮不要做：

1. 不接 adapters runtime。
2. 不接 long task supervisor。
3. 不改 GUI。
4. 不做真实探针。

验收标准：

1. 普通 draft 默认行为仍是 adaptive。
2. disabled 不触发 expression_constraint_review_missing。
3. force 缺审查能被明确识别。
4. Summary round-trip 稳定。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-05，只做 writing execution bridge/result/summary/normalizer 稳定字段。接入 execution policy，输出 policy mode、injection strength、review requirement、violation disposition、applied/skipped reason，并区分 disabled、skipped、review missing、review provided、violation recorded。不接 adapters/long task/GUI、不跑真实探针、不开启下一任务。补 contract/focused tests。
```

### ECP-06：表达限制 review/gate 处置信号

本轮目标：把表达限制审查结果转成结构化处置信号，支持提醒、下章调整、轻量修订和 force 模式修复。

层级归属：Core / workflow gate。

必读文件：

- ECP-05 实现
- `packages/novel_agent_core/lib/src/creative/expression_constraint_review_projection.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_summary.dart`
- `packages/novel_agent_core/test/expression_constraint_services_test.dart`

必须完成：

1. 新增或扩展表达限制 gate signal 小合同。
2. 支持 riskSignals、severity、naturalUsage、repeatedPattern、recommendedDisposition、repairRequired、adjustNextChapter。
3. 处置规则尊重 execution policy：disabled 不 gate，adaptive 优先 remind/adjust_next，force 可 repair。
4. 不用简单字符串扫描作为唯一判断，但允许把字符串命中作为风险证据之一。
5. Summary / normalizer 能记录 gate reasons 和 soft/hard action。
6. 补 tests 覆盖少量自然命中、严重重复、缺 review、force repair、disabled skip。

本轮不要做：

1. 不调用真实模型审稿。
2. 不写 GUI。
3. 不接 supervisor。
4. 不改 prompt 大文本。

验收标准：

1. gate 信号可被普通项目和长任务共用。
2. 轻微风险不机械修坏正文。
3. force 与 adaptive 行为清晰区分。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-06，只做表达限制 review/gate 处置信号。新增或扩展小合同，记录 riskSignals、severity、naturalUsage、repeatedPattern、recommendedDisposition、repairRequired、adjustNextChapter，并让 disabled/adaptive/force 产生不同处置。不调用真实模型、不写 GUI、不接 supervisor、不改 prompt 大文本、不开启下一任务。补 focused tests。
```

### ECP-07：普通项目写作运行接线

本轮目标：让普通项目每次生成都重新解析项目绑定和 execution policy，并把约束摘要稳定写入结果。

层级归属：Adapters / workflow runtime。

必读文件：

- ECP-05、ECP-06 实现
- `packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/generate_draft_use_case_factory.dart`

必须完成：

1. 普通项目 draft/revision/review 路径接入 execution policy。
2. 每次运行都从项目资源与用户设置重新解析，不依赖上一轮内存。
3. 工作台/会话运行结果保留 constraint summary。
4. disabled/adaptive/force 三档在普通项目 focused tests 中可区分。
5. 不让表达限制进入 tool/path/research 参数。

本轮不要做：

1. 不接长任务。
2. 不改 GUI 控件。
3. 不跑真实 provider。
4. 不重写 project assets。

验收标准：

1. 普通项目无绑定时不激活内置 profile。
2. 有项目绑定时 adaptive 可注入并要求合适 review。
3. disabled 有绑定也不误报缺审查。
4. 技术工具调用 payload 不被表达限制污染。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-07，只做普通项目写作运行接线。让 generate draft / conversation runtime 每次都从项目绑定和用户策略重新解析 execution policy，写入 constraint summary，并确保表达限制不进入 tool/path/research 参数。不接长任务、不改 GUI 控件、不跑真实 provider、不开启下一任务。补 adapters/core focused tests。
```

### ECP-08：长任务逐章执行策略与 supervisor 信号

本轮目标：让长任务每章都消费同一表达限制执行策略，并把连续风险转成 supervisor 可消费信号。

层级归属：Workflow / long task runtime。

必读文件：

- ECP-06、ECP-07 实现
- `packages/novel_agent_core/lib/src/workflow/long_task_task_factory_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_dynamic_task_factory_service.dart`
- `packages/novel_agent_core/lib/src/workflow/narrative_supervisor_risk_policy_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`

必须完成：

1. 长任务 chapter/revision/checkpoint 路径接入 execution policy。
2. 每章持久化或投影 policy、injection、review、gate disposition。
3. 最近 N 章表达限制风险可进入 adaptive escalation。
4. supervisor signal 区分：表达限制建议加强、需要轻修、等待审查证据、已关闭策略。
5. 停止原因不混入表达限制，仍保持预算/等待用户/技术失败/content gate 分离。
6. 补 long task focused tests。

本轮不要做：

1. 不跑 200 章真实探针。
2. 不写 GUI。
3. 不把任何特殊剧情写进代码。
4. 不膨胀 `ProjectWorkflowRuntimeService`。

验收标准：

1. 长任务每章都有 constraint summary。
2. 连续风险能产生结构化 signal。
3. disabled 长任务不误报 expression review missing。
4. supervisor 不读正文做文学判断。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-08，只做长任务逐章表达限制执行策略与 supervisor 信号。每章接入同一 execution policy，持久化/投影 policy、injection、review、gate disposition，并让最近章节风险进入 adaptive escalation。不得跑大探针、不得写 GUI、不得写死特殊剧情、不得膨胀 ProjectWorkflowRuntimeService、不开启下一任务。补 long task focused tests。
```

### ECP-09：拆书续写与解书/总结适配

本轮目标：让拆书续写、解书、总结、评书式转述等非普通正文路径正确使用表达限制策略。

层级归属：Core + adapters / project type integration。

必读文件：

- ECP-05 到 ECP-08 实现
- `packages/novel_agent_core/lib/src/deconstruction/`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`
- `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`

必须完成：

1. 明确拆书分析阶段、拆书续写正文阶段、解书/总结阶段的 intent/taskType/phase 映射。
2. 分析/拆解阶段不强套正文去 AI 规则。
3. 续写正文阶段使用项目表达限制、原作风格约束和字数策略的共享 bridge。
4. 解书/总结在 adaptive 下使用 brief 级约束，force 下强控用户可见文本但不牺牲事实准确性。
5. 补 focused tests 覆盖 deconstruction continuation、summary/explainer、information discipline priority。

本轮不要做：

1. 不实现新的拆书功能。
2. 不写 GUI。
3. 不写同人/穿书特殊分支。
4. 不联网。

验收标准：

1. 拆书/解书不再走表达限制的平行逻辑。
2. 信息纪律优先于表达限制。
3. 无题材硬编码。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-09，只做拆书续写与解书/总结的表达限制执行策略适配。明确分析、续写正文、解说总结的 intent/taskType/phase 映射，确保分析阶段不强套正文规则，续写正文共用 writing constraint bridge，信息纪律优先。不实现新拆书功能、不写 GUI、不写题材分支、不联网、不开启下一任务。补 focused tests。
```

### ECP-10：章节路径、标题与 delivery 口径统一

本轮目标：独立修复并验收章节文件名、正文 H1、delivery submission、GUI 列表标题的统一合同，解决重复章号风险。

层级归属：Core + adapters / chapter delivery contract。

必读文件：

- ECP-01 审计结果
- `packages/novel_agent_core/lib/src/project/chapter_output_path_policy_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_chapter_output_policy_service.dart`
- `packages/novel_agent_core/lib/src/tools/domain/submit_chapter_delivery_handler.dart`
- `packages/novel_agent_core/lib/src/tools/domain/submit_chapter_delivery_result.dart`
- `packages/novel_agent_adapters/lib/src/workflow/chapter_delivery_outcome_projection_service.dart`
- `packages/novel_agent_core/test/chapter_output_path_policy_service_test.dart`
- `packages/novel_agent_core/test/submit_chapter_delivery_handler_test.dart`

必须完成：

1. 明确章节编号、标题、文件路径、正文 H1、submission title 的单一来源。
2. 修复 `第04章_第04章.md` 类重复拼接风险。
3. 标题缺失时有稳定 fallback，但不把 fallback 写进路径两次。
4. Delivery outcome projection 使用规范化标题和路径。
5. 补 tests 覆盖已有标题、无标题、重复章号、模型传入奇怪 path、长任务 path。

本轮不要做：

1. 不改表达限制策略。
2. 不改 GUI 外观。
3. 不跑真实 provider。
4. 不把题材 prompt 写入 path policy。

验收标准：

1. 章节文件稳定为产品约定格式。
2. 正文 H1 与 GUI 标题同源。
3. delivery contract 可解释 path resolution。
4. 不再出现章号重复拼接。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-10，只做章节路径、标题与 delivery 口径统一。明确章节编号、标题、文件路径、正文 H1、submission title 的单一来源，修复重复章号文件名风险，并让 delivery projection 使用规范化结果。不改表达限制策略、不改 GUI 外观、不跑真实 provider、不写题材分支、不开启下一任务。补 path/delivery focused tests。
```

### ECP-11：Adapters 投影与持久化摘要

本轮目标：让 adapters 稳定保存和投影表达限制执行策略摘要，供 workbench、long task station、probe 共用。

层级归属：Adapters / projection and persistence。

必读文件：

- ECP-05 到 ECP-10 实现
- `packages/novel_agent_adapters/lib/src/workflow/chapter_delivery_outcome_projection_service.dart`
- `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
- `packages/novel_agent_adapters/test/project_long_task_station_detail_service_test.dart`

必须完成：

1. Adapter projection 消费 core summary，不重新解释 raw runtimeReport。
2. 章节/会话结果投影包含：策略状态、是否应用、是否建议加强、是否阻塞修订、是否关闭。
3. 长任务详情可读取最近章节表达限制状态。
4. 保持 projection 小服务职责，不塞进 runtime 大门面。
5. 补 adapter focused tests。

本轮不要做：

1. 不改 core 合同。
2. 不写 GUI widget。
3. 不跑真实 probe。
4. 不添加私有风险扫描。

验收标准：

1. Projection 与 core summary 字段一致。
2. Workbench 和 long task station 可共用同一摘要语义。
3. 不新增平行业务判断。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-11，只做 adapters 投影与持久化摘要。消费 core constraint summary，投影策略状态、是否应用、建议加强、阻塞修订、关闭状态，供 workbench、long task station、probe 共用。不改 core 合同、不写 GUI widget、不跑真实 probe、不添加私有扫描、不开启下一任务。补 adapter focused tests。
```

### ECP-12：长任务运行中心停止诊断与表达限制展示模型

本轮目标：让长任务运行中心模型能区分停止原因和表达限制状态，避免把九章停止误判成表达限制问题。

层级归属：Adapters + app application / run center model。

必读文件：

- ECP-08、ECP-11 实现
- `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
- `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart`
- `apps/novel_agent_app/lib/features/long_task_station/presentation/models/long_task_station_view_data.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_run_record_service.dart`

必须完成：

1. Detail/view-data 模型区分：预算/目标完成、等待用户、技术失败、内容质量 gate、表达限制建议加强、表达限制修订阻塞。
2. 不把表达限制状态作为长任务停止原因的兜底。
3. 运行中心摘要能显示最近章节表达限制状态。
4. 补 application/model tests。

本轮不要做：

1. 不改 presentation widget。
2. 不跑真实长任务。
3. 不改 supervisor 核心算法，除非 ECP-08 明确留下缺口。
4. 不写特殊题材逻辑。

验收标准：

1. 第 9 章停止类问题能从报告中看到明确类别。
2. 表达限制与停止诊断分离。
3. GUI 后续只需消费 view-data。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-12，只做长任务运行中心停止诊断与表达限制展示模型。让 detail/view-data 区分预算/目标完成、等待用户、技术失败、内容质量 gate、表达限制建议加强、表达限制修订阻塞，不把表达限制状态当停止原因兜底。不改 widget、不跑真实长任务、不写题材逻辑、不开启下一任务。补 application/model tests。
```

### ECP-13：Mock regression 套件

本轮目标：建立不消耗真实额度的表达限制执行策略回归套件，覆盖普通项目、长任务、拆书/解书和章节路径。

层级归属：Probe / regression。

必读文件：

- ECP-02 到 ECP-12 实现
- `apps/novel_agent_app/tool/probe_support.dart`
- `packages/novel_agent_core/test/expression_constraint_injection_policy_service_test.dart`
- `packages/novel_agent_core/test/writing_execution_constraint_bridge_service_test.dart`
- `apps/novel_agent_app/test/probe_support_test.dart`

必须完成：

1. 新增或更新 mock regression 脚本，不调用真实 provider。
2. 覆盖 disabled/adaptive/force。
3. 覆盖普通项目、长任务逐章、拆书续写/总结 intent。
4. 覆盖 tool/path/research 不被表达限制污染。
5. 覆盖重复章号 path regression。
6. 报告区分技术失败、等待用户、策略关闭、内容质量风险、路径失败。
7. 新增 docs 下短 regression suite 说明。

本轮不要做：

1. 不跑真实 API。
2. 不写 GUI。
3. 不把 mock 私有判断接回 runtime。
4. 不提交临时产物。

验收标准：

1. 一条命令可运行 mock suite。
2. 报告消费 production 合同。
3. 不依赖真实 key。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-13，只做表达限制执行策略 mock regression 套件。覆盖 disabled/adaptive/force、普通项目、长任务逐章、拆书续写/总结 intent、tool/path/research 排除、重复章号 path regression，并让报告区分技术失败、等待用户、策略关闭、内容质量风险、路径失败。不跑真实 API、不写 GUI、不把 mock 判断接回 runtime、不开启下一任务。补说明文档和测试。
```

### ECP-14：Probe 支持与短探针报告合同

本轮目标：让后续短探针能看见正文风险信号、review 证据、策略处置、章节路径和停止原因，不再只看注入次数。

层级归属：Probe / production contract consumption。

必读文件：

- ECP-13 mock suite
- `apps/novel_agent_app/tool/probe_support.dart`
- `apps/novel_agent_app/tool/real_gui_viewmodel_information_long_task_probe.dart`
- `docs/expression-constraint-execution-policy-analysis-2026-06-06.md`

必须完成：

1. Probe support 增加表达限制策略报告投影，消费 core/adapters summary。
2. 报告包含：policy mode、injection strength、review requirement、review provided、risk signals、disposition、chapter path resolution、stop reason。
3. 短探针默认不自动真实开闸。
4. 明确保存产物位置，不默认删除用户要读的正文。
5. 补 probe support tests。

本轮不要做：

1. 不跑真实 provider，除非用户明确要求。
2. 不把探针扫描逻辑当作 runtime gate。
3. 不改 GUI。
4. 不扩大到 200 章探针。

验收标准：

1. 以后短探针能定位表达限制是真失效还是证据缺失。
2. 路径/标题问题和停止原因能并列报告。
3. Probe 不形成第二套业务中心。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-14，只做 probe 支持与短探针报告合同。让 probe support 消费 production summary，报告 policy mode、injection strength、review requirement、review provided、risk signals、disposition、chapter path resolution、stop reason，并保留产物。不跑真实 provider、不把探针扫描当 runtime gate、不改 GUI、不扩大到 200 章、不开启下一任务。补 probe support tests。
```

### ECP-15：GUI 表达限制策略最小可用入口

本轮目标：在 GUI 中给用户自然地配置和查看表达限制策略，但不暴露内部字段。

层级归属：App / GUI。

必读文件：

- ECP-11、ECP-12 实现
- `apps/novel_agent_app/lib/features/project_assets/presentation/widgets/expression_constraint_binding_editor_panel.dart`
- `apps/novel_agent_app/lib/features/project_assets/application/services/project_assets_expression_constraint_view_data_service.dart`
- `apps/novel_agent_app/lib/features/project_assets/presentation/models/project_assets_view_data.dart`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/long_task_station/`

必须完成：

1. 项目资产页增加策略选择：关闭 / 智能使用 / 强力约束。
2. 默认显示人话字段：写作规则、适用范围、强度、使用策略。
3. profile id、binding id、agent id、stage id、injection mode 放进高级/诊断区域。
4. Workbench / long task station 显示“表达规则：已应用 / 建议加强 / 已阻塞修订 / 已关闭”。
5. 避免 `preset`、`Agent ID` 等不自然文案。
6. 竖屏/窄屏不让控件挤爆。
7. 补 focused widget/application tests。

本轮不要做：

1. 不改 core 决策。
2. 不做复杂资料中心。
3. 不把高级诊断放到主面板。
4. 不跑真实 provider。

验收标准：

1. 普通用户能理解三档策略。
2. 内部字段默认隐藏。
3. 设置只影响当前项目或当前运行约定，不修改全局内置 profile。
4. GUI tests 通过。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-15，只做 GUI 表达限制策略最小可用入口。项目资产页提供关闭/智能使用/强力约束，默认展示写作规则、适用范围、强度、使用策略；内部 id 和 injection mode 放进高级/诊断。Workbench/长任务站展示已应用/建议加强/已阻塞修订/已关闭。不改 core 决策、不做复杂资料中心、不把诊断塞主面板、不跑真实 provider、不开启下一任务。补 focused GUI tests。
```

### ECP-16：CLI 最小表达限制摘要

本轮目标：让 CLI 能读取并显示表达限制策略摘要和停止诊断，不实现复杂配置。

层级归属：CLI / outer consumption。

必读文件：

- ECP-11 到 ECP-14 实现
- `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
- `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`
- `apps/novel_agent_cli/test/workflow_output_summary_service_test.dart`

必须完成：

1. CLI workflow summary 显示表达限制策略状态。
2. 显示 review missing / violation recorded / disabled / suggested adjust / repair required。
3. 显示章节路径/标题诊断摘要和 stop reason。
4. 不实现复杂策略编辑，最多保留输入参数或配置读取占位。
5. 补 CLI focused tests。

本轮不要做：

1. 不重构 CLI 全流程。
2. 不抢 GUI 配置入口。
3. 不改 core/adapters 合同。
4. 不跑真实 provider。

验收标准：

1. CLI summary 与 GUI view-data 语义一致。
2. 没有 raw payload 噪音。
3. CLI tests 通过。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-16，只做 CLI 最小表达限制摘要。workflow summary 显示策略状态、review missing、violation recorded、disabled、suggested adjust、repair required、章节路径/标题诊断和 stop reason。不重构 CLI 全流程、不做复杂策略编辑、不改 core/adapters 合同、不跑真实 provider、不开启下一任务。补 CLI focused tests。
```

### ECP-17：短真实探针验收

本轮目标：在用户明确允许真实调用后，跑短探针验证普通项目和长任务表达限制链路，不追求大预算长跑。

层级归属：Probe / gated real validation。

必读文件：

- ECP-13、ECP-14 实现
- `apps/novel_agent_app/tool/real_gui_viewmodel_information_long_task_probe.dart`
- `apps/novel_agent_app/tool/real_general_novel_probe.dart`
- `tools/probe_config_support.dart`
- `docs/expression-constraint-execution-policy-analysis-2026-06-06.md`

必须完成：

1. 在确认不会泄漏 key 的前提下，跑普通项目 3 到 5 章探针。
2. 跑长任务 10 到 20 章短探针。
3. 覆盖 adaptive，必要时加 disabled/force 小样本。
4. 报告表达限制证据、风险信号、处置、章节路径、标题、停止原因。
5. 保留产物供人工阅读。
6. 如果真实 provider 不可用，改跑 mock suite 并明确阻塞原因。

本轮不要做：

1. 不跑 200 章大探针。
2. 不删除正文产物。
3. 不提交 key 或本地配置。
4. 不把探针失败直接修成临时补丁。

验收标准：

1. 能证明表达限制链路不再只看注入字段。
2. 章节路径没有重复章号。
3. 停止原因可解释。
4. 若发现问题，报告能指向具体 production 合同或服务。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-17，只做短真实探针验收。确认真实 key 不入仓库后，跑普通项目 3-5 章和长任务 10-20 章，覆盖 adaptive，必要时加 disabled/force 小样本；报告表达限制证据、风险信号、处置、章节路径、标题、停止原因，并保留产物。不跑 200 章、不删除正文、不提交 key、不做临时补丁、不开启下一任务。若 provider 不可用，跑 mock suite 并说明阻塞。
```

### ECP-18：文档、项目约束与交接收口

本轮目标：回填完成记录，更新分析文档实现状态，必要时补充 `agent.md` 维护约束，并留下交接说明。

层级归属：Documentation / handoff。

必读文件：

- 本文档全部完成记录
- `docs/expression-constraint-execution-policy-analysis-2026-06-06.md`
- `agent.md`
- ECP-17 探针报告或 mock 报告

必须完成：

1. 回填 ECP-01 到 ECP-18 完成记录。
2. 更新分析文档中的实现状态、剩余风险和后续建议。
3. 如有必要，更新 `agent.md`：表达限制不得污染工具/路径/研究协议，策略层与资源层分离，探针不能成为业务中心。
4. 新增短 handoff，说明如何配置三档策略、如何查看报告、如何运行 mock/短真实探针。
5. 明确是否可以进入更大预算长任务验证。

本轮不要做：

1. 不写新业务代码。
2. 不跑真实探针。
3. 不扩 GUI。
4. 不开启新主线。

验收标准：

1. 文档能让新会话准确接手。
2. 完成记录真实反映已做和剩余风险。
3. 项目级约束没有重复堆文案，但覆盖关键维护底线。

直接可用提示词：

```text
根据 `docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 开启 ECP-18，只做文档、项目约束与交接收口。回填全部完成记录，更新分析文档实现状态和剩余风险，必要时微调 agent.md，新增短 handoff 说明三档策略、报告查看、mock/短真实探针运行方式，并判断是否可进入更大预算长任务验证。不写新业务代码、不跑真实探针、不扩 GUI、不开启新主线。
```

---

## 10. 总启动提示词

```text
根据目前的进度和文档：`docs/expression-constraint-execution-policy-session-order-2026-06-06.md` 继续下一步。每次只确认完成一个具体任务；如果上个会话末尾卡在具体任务的一半未完成或者出现关联性错误，就先修好这些，不开启下一轮任务。如果已经确认可以开启下一轮任务，就直接开始当前 session。必须读取对应 session 的目标、层级归属、必读文件、必须完成、本轮不要做、验收标准和直接可用提示词。实现时遵守 core/adapters/app/CLI 分层、解耦合、单一职责、避免单文件过重、focused test/contract test、probe 同源合同、真实 key 不入仓库等约束。完成后只更新本文档中当前 session 的完成记录，不顺手推进下一 session。如果已经完成最后一轮任务，应忽略自动续跑并开启阻塞式控制台命令等待人工接管。
```

---

## 11. 完成记录占位

- ECP-01：已完成（2026-06-06）。已完成现状审计、失败归因、keep / extend / fix 结论与测试复用清单；确认重复章号属于 path/title/delivery contract，九章停止属于长任务停止诊断链，不应误归因给表达限制；下一轮应从 ECP-02 Core 执行策略合同开始。
- ECP-02：已完成（2026-06-06）。已新增 `ExpressionConstraintExecutionPolicy` core 合同及 mode / injection strength / review requirement / violation disposition 常量，覆盖 `disabled / adaptive / force`、runtime escalation、tool/research 排除和 metadata；已补 `fromJson / toJson / copyWith / validateBasics / default adaptive` 与 focused contract tests。
- ECP-03：已完成（2026-06-06）。已新增 `ExpressionConstraintExecutionPolicyResolutionContext`、`ExpressionConstraintExecutionPolicyResolution` 与 `ExpressionConstraintExecutionPolicyResolverService`，支持 override、intent、taskType、phase、appliesTo、project/agent/mode/stage、hasBindings、recent summaries，并输出完整 policy、why applied / why skipped、technical turn exclusion 与 runtime escalation 结果；已补 focused tests 覆盖 disabled、adaptive、force、tool-only、research、review、path resolution 与 recent violation escalation。
- ECP-04：已完成（2026-06-06）。已扩展 `ExpressionConstraintInjectionPolicyService` 支持显式 `executionPolicy / policyMode / policyInjectionStrength` 输入，默认仍兼容旧的 `intent / taskType / phase` 推断；`disabled` 会清空表达限制 brief/section，`force` 会映射到最强注入形态但不承担 tool/path/research 排除；已补 focused tests 验证旧行为兼容和新策略模式映射。
- ECP-05：已完成（2026-06-06）。已扩展 `WritingExecutionConstraintBridgeResult`、`WritingExecutionConstraintBridgeService`、`WritingExecutionConstraintSummary` 与 `WritingExecutionResultNormalizerService`，bridge 输入现支持策略 mode override 与 recent summaries，输出稳定包含 policy mode、injection strength、review requirement、violation disposition、applied/skipped reasons、runtime escalation 与 technical turn exclusion；summary 已能区分 disabled、skipped、review missing、review provided 与 violation recorded，normalizer 不再把 disabled 误判成缺少 review 证据；已补 focused tests 覆盖 adaptive 默认、disabled 不触发缺证据、skipped by policy、result round-trip。
- ECP-06：已完成（2026-06-06）。已新增 `ExpressionConstraintGateSignal` 与 `ExpressionConstraintGateSignalService`，把表达限制复核结果转成结构化处置信号，稳定输出 `riskSignals / severity / naturalUsage / repeatedPattern / recommendedDisposition / repairRequired / adjustNextChapter`；`WritingExecutionConstraintSummary` 已挂接 gate signal，`WritingExecutionResultNormalizerService` 现在会按 execution policy 区分 `disabled` 跳过、`adaptive` 的 remind / adjust_next 与 `force` 的 repair，并把 hard/soft gate reasons、summary 文案和共享结果中的 gate signal 一并记录；已补 focused tests 覆盖自然命中、重复风险、缺 review、force repair、disabled skip 与 result round-trip。
- ECP-07：已完成（2026-06-06）。已把普通项目会话写作运行改成在 `ProjectConversationDraftRuntimeService.prepareDraftRun(...)` 内每次从项目资源重新解析同一份 execution constraints，并把该 payload 连同 activation context 一起交给 `WorkbenchConversationController` 与 `GenerateDraftUseCase`；`finalizeDraftRun(...)` 现在会把同一份 bridge result 送入 `WritingExecutionResultNormalizerService`，稳定回写普通项目 `writingExecutionResult.constraints` 摘要。已补 focused tests 覆盖普通项目无 binding 不激活表达限制、adaptive/disabled/force 三档区分、controller 复用 preparation 内统一约束 payload，以及表达限制策略不混入 activation/tool bridge 元数据；普通会话 runtime 缺失时仍保留旧的 fallback resolve 兼容路径。
- ECP-08：已完成（2026-06-06）。已为长任务 `prepareWorkflowTaskExecution(...)` / `runWorkflowTaskOnce(...)` 接入同一套 recent expression constraint summaries 解析，并把完整 `execution_constraints` 持久化进 chapter atomic execution record；checkpoint review 现会投影稳定的 `writing_execution_constraints` 与 `expression_constraint_signal`，`NarrativeSupervisorRiskPolicyService` 新增 `expression_constraints` supervisor 分支，可区分 `policy_disabled / waiting_review_evidence / suggest_strengthen / light_repair`，同时保持 stop reason 仍走通用的 waiting_user / repair / manual_attention 语义而不新增表达限制专属停机码；已补 focused tests 覆盖 recent summaries 回灌、execution constraints 持久化、disabled 不误报、strengthen/light repair/waiting evidence 分类，以及 checkpoint markdown 展示。
- ECP-09：已完成（2026-06-06）。已在 `ProjectConversationDraftRuntimeService.prepareDraftRun(...)` 增加会话级 taskType 语义映射，区分拆书分析、拆书续写正文、解书/总结与 research/information 优先路径，分别落到 `deconstruction / writing / explanation / research_execution` 对应的 appliesTo、intent、stage、phase；拆书分析不再误走 primary writing 强约束，续写正文继续共用 writing constraint bridge，explainer/summary 在 adaptive 下走 brief、force 下走 full，带 `research / information` 标记的任务继续优先受信息纪律保护而跳过表达限制强控；已补 focused tests 覆盖 deconstruction followup、continuation writing、explainer summary 与 information-discipline priority。
- ECP-10：已完成（2026-06-06）。已把章节标题与路径归一化入口集中到 `ChapterOutputPathPolicyService.resolveChapterOutput(...)`，统一章节编号、规范标题、文件路径 fallback 与重复章号去重；`SubmitChapterDeliveryHandler` 现直接消费同一结果并同步规范化 submission title/path，`ProjectNarrativeDomainToolExecutor` 持久化章节正文时会把 H1 归一到同一标题，`ChapterDeliveryOutcomeProjectionService` 也会对历史/异常 payload 再做一次标题与路径规范化，避免 GUI/运行时继续看到 `第04章_第04章.md` 这类结果；已补 focused tests 覆盖已有标题、标题缺失 fallback、奇怪 model path、重复章号、长任务章节 stem 委托与 delivery projection 规范化。
- ECP-11：已完成（2026-06-06）。已新增 `ExpressionConstraintStatusProjection` 与 `ExpressionConstraintStatusProjectionService`，只消费 `WritingExecutionConstraintSummary`/`writing_execution_result.constraints` 投影 `present / status / status_label / summary / policy_mode / applied / suggest_strengthen / blocks_repair / disabled / review_required / review_provided / evidence_missing / runtime_escalated / technical_turn_excluded / applied_reasons / skipped_reasons`，不重新解释 `runtime_report`；普通项目与长任务写作结果现都会附带 `expression_constraint_projection`，`ProjectLongTaskStationDetailService` 也已能优先读取持久化 `writing_execution_result` 并在缺少投影时回退同源 `constraints` 摘要，输出当前章节与最近章节表达限制状态供 workbench / long task station / probe 共用；已补 adapter focused tests，并修正 `project_workflow_runtime_service_test.dart` 中 ECP-10 留下的章节规范化旧断言后重新通过 `expression_constraint_status_projection_service_test.dart`、`project_conversation_draft_runtime_service_test.dart`、`project_long_task_station_detail_service_test.dart` 与 `project_workflow_runtime_service_test.dart`。
- ECP-12：已完成（2026-06-06）。已在 `ProjectLongTaskStationBlockerSummary` 增加 `category / label`，由 `ProjectLongTaskStationDetailService` 把长任务停点明确归类为 `budget_or_goal_completed / waiting_user / repair_required / content_quality_gate / technical_failure / other`，从而把“第 9 章停下来了”与表达限制状态彻底拆开；`LongTaskStationViewDataService` 与 `LongTaskRunDetailViewData` 现新增 `stopDiagnosis`、`expressionConstraintStatus` 两组结构化 view-data，并把当前表达规则状态、最近章节表达限制状态接入现有 `overviewBlocks`/related items，支持区分预算或目标收尾、等待用户、技术失败、内容质量关口、表达规则建议加强与表达规则阻塞修订，而不再把表达限制状态当停止原因兜底；已补 `project_long_task_station_detail_service_test.dart` 与 `long_task_station_view_data_service_test.dart` 的 focused coverage，并重新通过 `project_long_task_station_detail_service_test.dart`、`long_task_station_view_data_service_test.dart` 与 `long_task_run_detail_panel_test.dart`。
- ECP-13：已完成（2026-06-06）。已补 `apps/novel_agent_app/tool/mock_expression_constraint_policy_probe.dart`，直接消费 `ProjectConversationDraftRuntimeService`、`ProjectDraftExecutionConstraintRuntimeService`、`WritingExecutionResultNormalizerService`、`ExpressionConstraintStatusProjectionService` 与 `ChapterDeliveryOutcomeProjectionService` 的 production 合同，覆盖 `disabled / adaptive / force`、ordinary project、`book_deconstruction_followup / book_deconstruction_continuation / book_explainer_summary` intent、research/tool/path exclusion、重复章号 path regression，以及 `technical_failure / waiting_user / policy_disabled / content_quality_failure / path_failure` 报告分类；`apps/novel_agent_app/tool/probe_support.dart` 与 `apps/novel_agent_app/test/probe_support_test.dart` 现已补 `policy_disabled / path_failure` 分类合同；新增一键入口 `tools/run_expression_constraint_policy_mock_regression_suite.ps1` 和说明文档 `docs/expression-constraint-policy-mock-regression-suite-2026-06-06.md`，把 focused core/adapters tests、`mock_long_task_probe.dart` 与新的表达限制 mock probe 串成单命令回归；已实际跑通该 suite，最新 mock 产物写入 `artifacts/mock_long_task_probe_workspace/<timestamp>/` 与 `artifacts/mock_expression_constraint_policy_probe_workspace/<timestamp>/`，不依赖真实 key，也未开启下一轮任务。
- ECP-14：已完成（2026-06-06）。已在 `apps/novel_agent_app/tool/probe_support.dart` 新增 `buildExpressionConstraintProbeReport(...)`，统一消费 `writing_execution_result.constraints / expression_constraint_projection / delivery / chapter_delivery / writing_execution_signal` 等 production 同源合同，稳定投影 `policy mode / injection strength / injection mode / review requirement / review required / review provided / evidence missing / risk signals / disposition / gate severity / path resolution / stop reason`，不在 probe 层重新扫描正文或补私有业务判断；`apps/novel_agent_app/test/probe_support_test.dart` 已补 focused tests，验证 force repair、disabled、路径归一和显式 stop reason fallback；`apps/novel_agent_app/tool/real_gui_viewmodel_information_long_task_probe.dart` 现已把该报告接入 ordinary step、长任务最近批次和 GUI selected-run 摘要，并显式保留 `workspace_root / run_artifact_dir / latest report` 产物位置，不会默认删正文；`apps/novel_agent_app/tool/mock_expression_constraint_policy_probe.dart` 也已挂接同一 helper，随后重新通过 `flutter test test/probe_support_test.dart`、`dart analyze ...probe_support.dart ...real_gui_viewmodel_information_long_task_probe.dart ...mock_expression_constraint_policy_probe.dart` 与整套 `tools/run_expression_constraint_policy_mock_regression_suite.ps1`，且未开启下一轮任务。
  - ECP-15：已完成（2026-06-06）。项目资产页现已提供“关闭 / 智能使用 / 强力约束”三档策略选择，并把默认展示收束为写作规则、适用范围、强度、使用策略；`profile / binding / agent / mode / stage` 等内部标识与注入方式已移入高级与诊断区，主面板不再暴露 `preset / Agent ID` 一类不自然文案。`ProjectSkillLoadoutViewDataService` 与 `LongTaskStationViewDataService` 现统一展示“表达规则：已应用 / 建议加强 / 已阻塞修订 / 已关闭”口径；已补并通过 focused widget / application tests，覆盖策略提交流、项目资产 view-data、长任务状态文案与 workbench 提示文案。
  - ECP-16：已完成（2026-06-06）。`WorkflowOutputSummaryService` 现已让 CLI workflow summary 直接消费现有 run center / writing execution / chapter delivery 合同，稳定显示表达规则状态、复核缺失、风险记录、关闭、建议加强、需修补后继续，以及章节路径归一、标题口径和停止原因的人话摘要；未新增复杂策略编辑，也未改 core/adapters 合同。已补并通过 focused CLI tests，覆盖 stop reason 映射、adaptive 建议加强、disabled、repair required 与路径/标题诊断。
  - ECP-17：已完成（2026-06-06，mock fallback）。已按文档要求先核对真实探针开闸条件：当前 `NOVEL_AGENT_ENABLE_REAL_PROBES` 与 `NOVEL_AGENT_PROBE_API_FILE` 均未设置，虽然本地存在 `local/probe_api.txt`，但在没有显式 real-probe opt-in 且本会话未取得真实计费调用许可的前提下，不运行 `real_general_novel_probe.dart` / `real_gui_viewmodel_information_long_task_probe.dart`。已改跑 `tools/run_expression_constraint_policy_mock_regression_suite.ps1` 并实际通过，串行验证 core contracts、adapters runtime、`apps/novel_agent_app/test/probe_support_test.dart`、`mock_long_task_probe` 与 `mock_expression_constraint_policy_probe`；最新 mock 产物位于 `artifacts/mock_long_task_probe_workspace/2026-06-06T17-35-48-344775/` 与 `artifacts/mock_expression_constraint_policy_probe_workspace/2026-06-06T17-35-58-309199/`。其中表达限制 mock probe 12/12 通过，已覆盖 ordinary `disabled / adaptive missing review / force repair`、拆书分析/续写、解书总结、research/tool/path exclusion、重复章号路径回归、waiting_user 与 technical_failure，足以证明 probe 报告已消费 production 同源合同并能报告表达限制证据、风险信号、处置、章节路径与停止原因；真实 provider 短探针留待后续在显式开闸后再执行，不在本轮继续开启 ECP-18。
- ECP-18：已完成（2026-06-06）。已完成文档收口：`docs/expression-constraint-execution-policy-analysis-2026-06-06.md` 现已补“当前实现状态”“剩余风险与后续建议”，明确 `ECP-01` 到 `ECP-18` 已落地、`ECP-17` 为 mock fallback、下一步应先做显式开闸后的短真实探针而非直接进入更大预算长跑；`agent.md` 已补表达限制执行策略维护边界，进一步固定 `profile/binding` 与 `execution policy` 分层、`force` 不得污染工具/路径/研究协议、probe 只能消费 production 同源合同；已新增交接文档 `docs/expression-constraint-execution-policy-handoff-2026-06-06.md`，说明三档策略配置、报告查看位置、mock/短真实探针运行方式，以及当前“不建议直接进入更大预算长任务真实验证”的判断。本轮未写新业务代码、未跑真实探针、未扩 GUI/CLI，也未开启新主线。

---

## 12. 生成后自检

1. 已明确“这份文档解决什么”。
2. 已说明与旧文档的关系。
3. 已做已有实现去重审计。
4. 已冻结架构边界。
5. 已写目标终态。
6. 所有设计目标均有 session 覆盖。
7. 顺序为 core / contract 先行，adapters / runtime 中段，probe / regression 后置，GUI / CLI 靠后。
8. 每个 session 均控制为单会话可完成。
9. 每个 session 均包含目标、层级、必读文件、必须完成、本轮不要做、验收标准和直接可用提示词。
10. 已避免让单一文件、UI、CLI、probe 或 fallback 成为新的业务中心。
11. 已明确普通项目、长任务、拆书续写、解书/总结共享同一表达限制执行策略。
12. 已把章节路径/标题问题和长任务停止诊断单独纳入，不把它们错误归因给表达限制。
13. 已包含总启动提示词和完成记录占位。
