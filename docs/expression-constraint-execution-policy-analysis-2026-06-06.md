# 表达限制执行策略分析文档

日期：2026-06-06

关联问题：

- GUI viewmodel 信息收集长任务探针中，章节从第 4 章开始出现 `第04章_第04章.md` 这类重复章号文件名。
- 前三章标题形态不稳定，用户人工阅读时感觉“章号有了，但标题/命名规则不够稳”。
- 第 2 章开始表达限制明显衰减，出现 Markdown 分割线、破折号密集、`不是……而是……` 等常见 AI 风表达。
- 任务只生成到第 9 章，需要区分是稳定性调度问题、策略停止问题，还是章节 gate / supervisor 没有继续接住。
- 用户提出表达限制可分为“激进、常规、禁止”三种策略，并要求辩证评估，避免堆补丁。

关联实现锚点：

- `packages/novel_agent_core/lib/src/creative/expression_constraint_profile.dart`
- `packages/novel_agent_core/lib/src/creative/project_expression_constraint_binding.dart`
- `packages/novel_agent_core/lib/src/creative/expression_constraint_injection_policy_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_result.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_summary.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart`
- `apps/novel_agent_app/lib/features/project_assets/presentation/widgets/expression_constraint_binding_editor_panel.dart`
- `apps/novel_agent_app/tool/real_gui_viewmodel_information_long_task_probe.dart`

关联文档：

- `docs/unified-de-ai-writing-scheme-2026-05-28.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `docs/release-readiness-gui-core-consolidation-analysis-2026-06-05.md`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`

---

## 1. 总结论

用户提出的“激进 / 常规 / 禁止”方向是对的，但它不应直接替换现有 `ExpressionConstraintProfile` 或 `ProjectExpressionConstraintBinding`。更准确的设计是新增一层：

```text
ExpressionConstraintExecutionPolicy
```

这层负责回答：

```text
当前这一次运行，应如何消费已经绑定到项目里的表达限制？
```

而不是回答：

```text
项目有哪些表达限制？
```

最终推荐的用户侧三档为：

1. `关闭`：不主动注入表达限制，也不要求表达限制审查。
2. `智能使用`：默认策略。根据任务意图、阶段、产物类型和风险信号决定注入强度与审查方式。
3. `强力约束`：用户明确要强控文本风味时使用。对正文、续写、修订、总结、解说等用户可见文本强注入、强审查，但仍不能污染工具协议、文件路径、调度元数据、研究执行和纯技术轮次。

内部字段不建议直接叫“激进 / 常规 / 禁止”，而建议使用稳定、可扩展的英文枚举：

```text
mode: disabled | adaptive | force
```

其中：

- `disabled` 对应用户侧“关闭”。
- `adaptive` 对应用户侧“智能使用 / 推荐”。
- `force` 对应用户侧“强力约束”。

这样既贴合用户直觉，又能避免把“激进”误解为无条件污染所有 prompt。

---

## 2. 当前项目已有基础

### 2.1 已经有 Profile 与 Binding

当前 `ExpressionConstraintProfile` 已经能承载：

- `id`
- `displayName`
- `summary`
- `kind`
- `rules`
- `riskSignals`
- `recommendedScope`
- `metadata`

`ProjectExpressionConstraintBinding` 已经能承载：

- `profileId`
- `enabled`
- `defaultForProject`
- `targetAgentIds`
- `targetModeIds`
- `targetStageIds`
- `weight`
- `metadata`

这说明项目已经完成了两件正确的事：

1. 表达限制被建模成可复用资源，而不是散落在提示词里的文本片段。
2. 项目级绑定已经能表达适用范围，且不会默认修改全局内置资源。

这两层不应推翻。

### 2.2 已经有注入模式，但语义还不完整

当前 `ExpressionConstraintInjectionPolicyService` 只返回：

```text
disabled
brief_only
brief_and_sections
```

它本质上回答的是：

```text
这次 prompt 要不要带表达限制？带简版还是带章节级 section？
```

它还没有正式回答：

1. 用户希望这次多强地执行表达限制。
2. 违反后是提醒、下章调整，还是本章修复。
3. 是否要求模型给出表达限制审查证据。
4. 哪些运行轮次必须排除在表达限制之外。
5. 长任务连续多章衰减时，如何升级策略。

所以它应继续保留，但需要被更高一层 execution policy 调用，而不是自己继续膨胀。

### 2.3 `WritingExecutionConstraintBridgeService` 是正确接点

当前 `WritingExecutionConstraintBridgeService` 已经把字数和表达限制统一桥接到运行时结果里，并产出：

- `chapterLengthMetadata`
- `expressionConstraintProfiles`
- `projectExpressionConstraintBindings`
- `expressionConstraintInjectionMode`
- `expressionConstraintReviewRequired`
- `runtimeReport`

这说明“写作执行约束共享层”已经存在。后续表达限制策略应优先接在这里，而不是分别塞进普通项目、长任务、拆书项目的独立流程。

---

## 3. 为什么不能只把提示词写强一点

这次探针里，用户人工阅读发现表达限制并没有持续生效。这个问题不能只靠“把提示词写得更凶”解决。

原因：

1. 长任务多章运行时，模型会逐步被当前章剧情、资料、工具调用和任务推进压过，早期约束容易衰减。
2. 表达限制是“文本呈现约束”，它必须出现在合适的 prompt 层，同时还需要在产物后被 review/gate 记录。
3. 只看报告字段不够。报告说注入了，不代表正文真的遵守。
4. 仅用程序字符串扫描也不够。破折号、`不是……而是……` 这类是风险信号，不是绝对禁词。少量自然使用可能成立，问题在于高频、模板化、无必要。
5. 不能让表达限制抢占工具协议。工具调用参数、路径、调度状态、研究请求不应被“去 AI 风”语言污染。

所以正确方案是：

```text
策略层决定是否/如何注入
审查层判断是否明显失效
gate 层决定提醒、下章调整、还是修复
报告层记录证据
GUI 层只暴露用户能理解的少量开关
```

---

## 4. 推荐的分层模型

### 4.1 资源层：Profile

表达限制 profile 是可复用资源。

它负责描述：

- 规则是什么。
- 风险信号是什么。
- 推荐适用场景是什么。
- 是否内置。

它不负责：

- 当前项目是否启用。
- 当前这轮运行是否注入。
- 违反后是否修复。
- 长任务是否升级强度。

### 4.2 项目绑定层：Binding

项目绑定负责把 profile 固定到项目里。

它回答：

- 这个项目是否启用某个表达限制。
- 适用于哪些智能体、模式、阶段。
- 权重/强度是多少。
- 是否项目默认启用。

它不应被全局内置资源反向污染。项目级修改只能影响当前项目。

### 4.3 执行策略层：Execution Policy

新增的执行策略负责：

- `disabled/adaptive/force` 三档模式。
- 注入强度：`none/brief/sections/full`。
- 审查要求：`none/when_applied/always_for_writing`。
- 违反处置：`remind/adjust_next/repair`。
- 是否允许随运行风险升级。
- 是否允许对非正文任务降级。

这层应是核心层合同，普通项目、长任务、拆书/解书共同消费。

### 4.4 审查与 Gate 层

审查层负责把正文与表达限制之间的差距转成结构化证据。

它不应只输出“通过/失败”，而应输出：

- 命中的风险信号。
- 严重程度。
- 是否属于偶发自然表达。
- 是否影响用户体验。
- 推荐动作。

Gate 层再决定：

- 本轮只记录提醒。
- 下章提示加强。
- 进入轻量修订。
- 触发长任务 supervisor 暂停或恢复策略。

### 4.5 GUI 暴露层

普通用户不应看到 `ExpressionConstraintInjectionMode`、profile id、binding id、stage id 这类工程字段。

建议用户侧只显示：

- 表达规则：开启了哪些规则。
- 适用范围：全书 / 当前智能体 / 当前写作阶段。
- 使用策略：关闭 / 智能使用 / 强力约束。
- 强度：弱 / 标准 / 强 / 严格。

高级设置或诊断模式才显示：

- profile id
- binding id
- agent id
- mode id
- stage id
- injection mode
- review requirement
- runtime report

---

## 5. 三档策略的精确定义

### 5.1 disabled：关闭

适用场景：

- 用户正在快速试写，不想被语言规则干扰。
- 纯资料整理、工具调试、模型连通性测试。
- 项目尚未选择任何表达限制。

行为：

- 不注入表达限制 prompt。
- 不要求表达限制 review。
- 不因表达限制缺少证据触发 hard gate。
- 已绑定 profile 仍保留在项目资产里，只是本次运行不消费。

不应做的事：

- 不删除项目绑定。
- 不删除内置 profile。
- 不影响字数、资料证据、章节交付等其他执行约束。

### 5.2 adaptive：智能使用

这是默认策略。

适用场景：

- 普通写作。
- 长任务自动写作。
- 拆书续写。
- 总结、解说、评书式转述。
- 大多数用户不想调细节的情况。

行为：

- 正文写作、续写、修订：使用 `brief_and_sections`。
- 审稿、章节后处理、总结：使用 `brief_only` 或轻量 section。
- 规划、大纲、设定整理：通常 brief 即可。
- 研究请求、工具协议、路径解析、调度元数据：不注入。
- 如果连续多章出现高风险表达，自动在后续章节升级提示强度或要求 review。
- 若只是偶发少量风险信号，优先提醒或下章调整，不立即修坏正文。

关键点：

```text
adaptive 不是“有时管、有时不管”的随意行为，
而是“根据产物类型和风险证据决定强度”的稳定策略。
```

### 5.3 force：强力约束

适用场景：

- 用户明确发现正文 AI 味很重。
- 用户正在做最终发布前修订。
- 某项目要求强文风统一。
- 探针需要验证表达限制链路是否能强制生效。

行为：

- 对正文、续写、修订、可公开文本总结使用最强注入。
- 对表达限制 review 默认 `always_for_writing`。
- 连续风险信号命中时允许触发轻量修订。
- 仍应保护正文完整性：轻微偏离不应机械返修。

必须排除：

- 工具 schema。
- 工具参数。
- 文件路径。
- 章节编号计算。
- 调度状态。
- research gateway 请求。
- permission/approval 文案的结构字段。

否则会再次出现“表达限制抢工具/抢路径/抢协议”的架构问题。

---

## 6. 与字数策略的关系

字数策略和表达限制同属写作执行约束，但不是同一种东西。

字数策略回答：

```text
这章大约应生成多少字？偏离多少需要提醒、下章调整或修复？
```

表达限制回答：

```text
这章应避免哪些表达习惯？文本风味是否明显偏离？
```

二者共同点：

- 都应注入到写作 prompt。
- 都应进入后置 evaluation/gate。
- 都应允许“硬限制 + 审核容忍”并存。
- 都不应由 GUI 暴露过多内部字段。

差异：

- 字数更容易程序化计量。
- 表达限制只能部分程序化识别，需要模型审查与风险信号结合。
- 字数轻微偏离不应破坏正文完整性。
- 表达限制轻微命中也不应机械替换自然语句。

后续可以把二者都纳入一个更宽的：

```text
WritingExecutionPolicy
```

但不建议现在强行合并成一个大对象。短期应先让表达限制执行策略独立成小合同，再由 `WritingExecutionConstraintBridgeService` 聚合。

---

## 7. 与信息收集策略的关系

信息收集不是表达限制，但会影响表达限制执行。

例如这次“明代社畜穿越”探针需要历史、科学、工艺、社会制度等资料纪律。表达限制不能阻止模型写 Markdown 分割线的同时，又把历史事实靠猜测写下去。

三者关系应是：

```text
表达限制：控制文本呈现与去 AI 风。
字数策略：控制章节规模与修订容忍。
信息纪律：控制事实、来源、权限、研究请求。
```

执行顺序建议：

1. 先由信息策略判断是否需要资料/研究。
2. 再由写作约束桥接字数与表达限制。
3. 生成正文。
4. 章节交付。
5. 后置 evaluation 检查字数、表达、事实证据、正文落盘。
6. supervisor 根据结构化 signal 决定继续、暂停、重试、修订。

不能把信息纪律塞进表达限制，也不能把表达限制塞进信息工具提示词。

---

## 8. 与普通项目、长任务、拆书/解书的适配

### 8.1 普通小说项目

普通项目不一定连续生成章节。用户可能写一章、读一章、调设置、再继续。

策略要求：

- 每次生成都重新解析项目绑定和执行策略。
- 不依赖上一轮内存里的表达限制状态。
- GUI 调整策略后，应只影响后续运行，不改写历史正文。
- 工作台应在本轮结果中显示“表达规则已应用/未应用/建议加强”，但默认折叠诊断细节。

### 8.2 长任务

长任务最容易发生约束衰减。

策略要求：

- 每章都必须重新进入约束桥接。
- 每章都必须持久化 constraint summary。
- 连续多章风险升高时，supervisor 应收到结构化 signal，而不是事后由 probe 猜。
- 长任务停止在第 9 章这种情况，必须能区分：
  - 模型失败。
  - 队列策略停止。
  - supervisor 暂停。
  - 章节 gate 阻塞。
  - 权限/资料等待。

表达限制策略不能承担长任务停止诊断，但它应提供足够 signal 帮助诊断。

### 8.3 拆书续写

拆书续写的表达限制来源更复杂：

- 用户自定义表达规则。
- 原作抽取出的文风特征。
- 项目目标文风。
- 去 AI 规则。
- 解构/分析时的客观语言要求。

策略要求：

- 原作风格不是简单“表达限制 profile”，但可以转化出部分表达约束。
- 分析/拆解阶段不要强行套正文去 AI 规则。
- 续写正文阶段需要把原作风格约束、用户表达限制和字数策略一起进入写作执行约束。

### 8.4 解书、总结、评书式转述

这些不是正文小说，但也是用户可见文本。

策略要求：

- `adaptive` 下使用 brief 级表达限制，避免 AI 腔解说。
- `force` 下可以强控文风，但不能牺牲事实准确性。
- 信息纪律优先于表达限制，不能为了“更自然”改写来源事实。

---

## 9. 对这次探针失败的归因

这次探针暴露的问题应拆开处理，不能都归到表达限制。

### 9.1 文件名重复章号

现象：

```text
第04章_第04章.md
第05章_第05章.md
...
```

归因：

- 这是章节输出路径/标题规范化或提交 payload 归一化问题。
- 不属于表达限制。
- 应由 `ChapterOutputPathPolicyService`、`LongTaskChapterOutputPolicyService`、`submit_chapter_delivery` 相关链路继续收口。

验收：

- 所有章节文件应稳定为 `第NN章.md` 或产品明确允许的统一格式。
- 标题应进入正文 H1 或章节 metadata，不应拼进文件名两次。

### 9.2 前三章标题形态不稳

现象：

- 当前实际文件中第 1 到第 3 章已有 H1 标题，但用户观察到“只有章号没有标题”的风险值得记录。

归因：

- 可能是不同视图/文件名/正文 H1 的呈现口径不统一。
- 需要统一章节标题 contract：文件路径、正文 H1、delivery submission、GUI 列表四处应同源。

### 9.3 表达限制从第 2 章后明显衰减

现象：

- `---` 分割线多次出现。
- `——` 破折号密集。
- `不是……而是……` 等风险句式高频出现。

归因：

- 当前注入模式是局部策略，不足以保证长链持续执行。
- review/gate 没有把“风险信号持续命中”转成下章加强或本章轻修。
- 探针报告不能只看注入字段，需要看正文与审查证据。

解决方向：

- 引入 `ExpressionConstraintExecutionPolicy`。
- 在 summary 中记录 policy mode、injection strength、review disposition。
- 在长任务 supervisor 中消费连续风险 signal。

### 9.4 只生成九章

归因待查：

- 可能是任务预算/停止策略。
- 可能是长任务 supervisor 或队列状态。
- 可能是章节 gate 没有继续恢复。
- 可能是 provider/工具调用失败。

表达限制策略只能提供一部分证据，不能替代长任务运行中心诊断。

### 9.5 ECP-01 审计结论：keep / extend / fix

以下结论基于 2026 年 6 月 6 日现有代码、`agent.md`、`real_gui_viewmodel_information_long_task_probe` 脚本以及探针产物
`artifacts/real_gui_viewmodel_information_long_task_probe_workspace/2026-06-06T10-45-33-438435/明代社畜穿越资料纪律探针/chapters`
中的真实章节文件名。

1. `ExpressionConstraintProfile`：`keep`
   - 资源层已经稳定表达规则、风险信号和适用范围。
   - 不应把用户侧三档策略直接塞回 profile。
2. `ProjectExpressionConstraintBinding`：`keep`
   - 项目级启用、作用域与权重表达已经成立。
   - 后续只需让 execution policy 消费 binding，而不是重写 binding 语义。
3. `ExpressionConstraintInjectionPolicyService`：`extend`
   - 当前服务适合作为“注入形态解析器”保留。
   - 需要上接新的 execution policy，不能继续独自承担 review、disposition、排除技术轮次等职责。
4. `WritingExecutionConstraintBridgeService` / `WritingExecutionConstraintBridgeResult`：`extend`
   - bridge 已经是字数与表达限制的共享接点，方向正确。
   - 但当前只稳定输出 `expression_constraint_injection_mode` 与 `expression_constraint_review_required`，缺少 policy mode、injection strength、review requirement、violation disposition、applied/skipped reason。
5. `WritingExecutionConstraintSummary` / `WritingExecutionResultNormalizerService`：`extend`
   - 当前已经能区分 profile-only inactive、review missing、repair required 这类基础状态，说明摘要层方向可复用。
   - 但还不能区分 `disabled`、`skipped by policy`、`adaptive suggested adjust`、`force repair required`，也没有 execution policy 的稳定摘要字段。
6. `ExpressionConstraintReviewProjection`：`extend`
   - review 投影已经能承接 authenticity、focus、voice notes。
   - 后续应补“违反处置”和“连续风险升级”的共享信号，而不是让 probe 或 GUI 私下二次解释。
7. `ChapterOutputPathPolicyService` / `submit_chapter_delivery` 链：`fix`
   - 当前 core 已经有 placeholder path upgrade 与去重前缀测试，方向正确。
   - 但真实探针仍落出 `第04章_第04章.md` 到 `第09章_第09章.md`，说明长任务链路上仍有调用点没有完全消费规范化结果。
   - 这个问题属于 path/title/delivery contract，不属于表达限制。
8. `ProjectLongTaskStationDetailService` 等停止诊断链：`keep + extend`
   - 当前已经明确把 `stop_reason`、`waiting_user`、`failed`、`waiting_gate` 当成独立诊断源，而不是表达限制兜底。
   - 但停止原因 taxonomy 还不够细，尚未稳定区分预算/目标完成、技术失败、内容 gate、等待用户、表达限制建议加强等更细类别。

### 9.6 可复用测试与缺失回归

可直接复用的已有测试：

1. `packages/novel_agent_core/test/writing_execution_result_contracts_test.dart`
   - 已覆盖 profile-only inactive、review missing、repair required 等基础约束摘要语义。
   - 后续可作为 ECP-05 与 ECP-06 的主 contract test 扩展点。
2. `packages/novel_agent_core/test/chapter_output_path_policy_service_test.dart`
   - 已覆盖 chapter prefix 去重与 placeholder path upgrade。
   - 可作为 ECP-10 的 path contract 基线。
3. `packages/novel_agent_core/test/submit_chapter_delivery_handler_test.dart`
   - 已覆盖 path resolution、submission normalization、sidecar repair required。
   - 可作为 ECP-10 的 delivery contract 基线。
4. `packages/novel_agent_adapters/test/project_long_task_station_detail_service_test.dart`
   - 已覆盖 `waiting_user_checkpoint` 等 blocker 读取逻辑。
   - 可作为 ECP-12 的停止诊断扩展基线。
5. `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`
   - 已覆盖等待确认、失败态、恢复动作等用户态投影。
   - 可作为 ECP-12 的 view-data 基线。
6. `apps/novel_agent_app/test/probe_support_test.dart`
   - 已覆盖 probe opt-in、分类与 information failure 分类。
   - 可作为 ECP-13 / ECP-14 的 probe contract 基线。

当前明确缺失的 regression：

1. 缺少 `ExpressionConstraintExecutionPolicy` 合同测试。
   - 当前仓库还没有 `disabled / adaptive / force` 的 core contract，也没有 codec / validation / metadata round-trip 覆盖。
2. 缺少 execution policy resolver focused tests。
   - 当前没有覆盖 tool-only、research execution、path resolution、long task recent violation escalation 的策略决策测试。
3. 缺少 injection policy 与 execution policy 分层回归。
   - 当前注入策略测试仍基于旧的 `disabled / brief_only / brief_and_sections` 语义。
4. 缺少 bridge / summary / normalizer 的新字段 contract tests。
   - 当前没有 policy mode、injection strength、review requirement、violation disposition、applied/skipped reason 的 round-trip 覆盖。
5. 缺少真实探针暴露的重复章号 integration regression。
   - 虽然 `ChapterOutputPathPolicyService` 单测已存在，但还没有覆盖“长任务写作 -> delivery -> path projection”整链仍生成 `第04章_第04章.md` 的场景。
6. 缺少“九章停止原因” taxonomy regression。
   - 当前已有 waiting/failed 类测试，但还没有把预算、目标完成、内容质量 gate、技术失败、等待用户、表达限制建议加强清晰拆开。
7. 缺少 probe 报告消费 production constraint summary 的测试。
   - 当前 probe support 还没有验证 policy mode、review requirement、risk signals、disposition、chapter path resolution、stop reason 的统一投影。

---

## 10. 目标合同草案

建议新增核心合同，名称可微调：

```text
ExpressionConstraintExecutionPolicy
```

建议字段：

```text
mode: disabled | adaptive | force
injection_strength: none | brief | sections | full
review_requirement: none | when_applied | always_for_writing
violation_disposition: remind | adjust_next | repair
allow_runtime_escalation: bool
exclude_tool_protocols: bool
exclude_research_execution: bool
metadata: map
```

建议解析服务：

```text
ExpressionConstraintExecutionPolicyResolverService
```

输入：

- 用户设置。
- 项目类型。
- intent。
- taskType。
- phase。
- appliesTo。
- agent/mode/stage。
- project bindings。
- 上一章/最近几章 constraint summary。

输出：

- 执行策略。
- 注入模式。
- review 要求。
- runtime report。

不要把这个 resolver 做成大文件。它应只做决策，不渲染 prompt、不读正文、不写文件。

---

## 11. 现有服务的演化建议

### 11.1 `ExpressionConstraintInjectionPolicyService`

保留。

调整方向：

- 继续负责“注入形态”。
- 接受 execution policy resolver 给出的 mode/strength。
- 不再独自决定所有表达限制行为。

### 11.2 `WritingExecutionConstraintBridgeService`

继续作为聚合接点。

调整方向：

- 增加 execution policy 输出。
- runtime report 中明确：
  - policy mode
  - injection strength
  - review requirement
  - disposition
  - why applied / why skipped
- 不把策略细节塞进普通 prompt 文本。

### 11.3 `WritingExecutionResultNormalizerService`

调整方向：

- 当前已有 expressionConstraintReviewRequired / EvidenceMissing。
- 后续应区分：
  - skipped by policy
  - applied but review missing
  - applied and review passed
  - applied and violation recorded
  - force mode violation requiring repair

否则 disabled 与失败缺证据容易混在一起。

### 11.4 GUI 项目资产页

调整方向：

- 表达限制 tab 中增加“使用策略”。
- 默认显示用户友好名称：关闭 / 智能使用 / 强力约束。
- profile/binding id 等细节放到高级区。
- 避免继续出现 `preset`、`Agent ID` 这类不自然文案。

### 11.5 长任务总站

调整方向：

- 在章节结果里显示“表达规则：已应用 / 建议加强 / 已阻塞修订 / 已关闭”。
- 诊断区显示内部 policy 和 signal。
- 不要让普通用户看到 injection mode 这类字段。

---

## 12. 最小可行实现顺序

这不是正式任务顺序文档，只是后续实现建议。

1. 新增核心 contract：`ExpressionConstraintExecutionPolicy`。
2. 新增 resolver：把 `disabled/adaptive/force` 映射到注入强度、审查要求、违反处置。
3. 改造 `WritingExecutionConstraintBridgeService`：接入 resolver，保留现有默认行为为 `adaptive`。
4. 改造 summary/normalizer：能区分 disabled、skipped、review missing、violation recorded。
5. 增加 focused tests：
   - 内置 profile 未绑定时不激活。
   - disabled 即使有绑定也不注入、不要求 review。
   - adaptive 对正文强于规划/研究。
   - force 对用户可见文本强执行，但不污染工具/路径/研究。
6. GUI 只接最小策略选择，不做复杂专家界面。
7. 重新跑短探针：普通项目 3 到 5 章，验证表达限制证据。
8. 再跑长任务 10 到 20 章，验证连续风险升级与停止诊断。

---

## 13. 验收标准

实现完成后，至少满足：

1. 表达限制是所有写作路径共享能力，不是长任务专属。
2. 普通项目、长任务、拆书续写都通过同一 bridge 消费策略。
3. `disabled` 不误报缺少表达限制审查。
4. `adaptive` 能在正文生成中稳定注入，并在连续风险时升级。
5. `force` 不污染工具协议、路径、调度、研究执行。
6. 项目级绑定修改不影响全局内置 profile。
7. GUI 默认文案自然，不暴露内部工程字段。
8. 探针报告不能只看“注入次数”，必须包含正文风险信号、review 证据、处置结果。
9. 文件名重复章号、标题不稳、只生成九章等问题有独立诊断，不被错误归因给表达限制。

---

## 14. 需要避免的错误方向

1. 不要把快穿、死亡回归、明代穿越等测试题材写进核心分支。
2. 不要用字符串扫描完全替代模型审查。
3. 不要因为表达限制失败，就把超长去 AI 文本硬塞进所有 prompt。
4. 不要让表达限制改变工具调用参数或文件路径。
5. 不要把用户可编辑 profile、项目绑定、运行策略混成一个对象。
6. 不要让 GUI 主面板塞满高级约束术语。
7. 不要把长任务停止问题伪装成表达限制问题。
8. 不要为了追求“强力约束”而机械修坏正文流畅度。

---

## 15. 本文最终取舍

这轮最重要的取舍是：

```text
表达限制不是单纯提示词，也不是技能，更不是后处理补丁。
它应是“资源 + 项目绑定 + 运行策略 + 审查 gate + 用户暴露协议”的组合能力。
```

短期不需要把所有执行约束合并成一个庞大系统。当前最稳的做法是：

1. 保留现有 profile/binding。
2. 在核心层新增小而清晰的 execution policy。
3. 让 bridge 输出可验证的运行证据。
4. 让普通项目、长任务、拆书/解书共享同一策略。
5. GUI 只暴露“关闭 / 智能使用 / 强力约束”这类用户能理解的控制。

这样既能解决这次探针暴露的表达限制失效问题，也不会把项目重新拖回“到处堆提示词补丁”的混乱状态。

---

## 16. 当前实现状态（截至 2026-06-06）

本分析文档对应的主线实现已完成 `ECP-01` 到 `ECP-18`，其中 `ECP-17` 按文档允许的 fallback 走了 mock 验证而非真实计费探针。

已经落地的关键结果：

1. core 已新增 `ExpressionConstraintExecutionPolicy`、resolver、gate signal 与稳定 summary/result contracts。
2. ordinary project、long task、拆书分析/续写、解书/总结都已接入同一套 execution policy / bridge / normalizer 合同。
3. expression constraint status projection、long task stop diagnosis、GUI/CLI 人话摘要都已消费同源 production contracts。
4. 章节路径、标题、delivery submission 与 H1 标题口径已收口到统一 contract，并补了 focused regression。
5. mock probe / probe support 已能稳定报告 policy mode、review evidence、risk signals、disposition、path resolution、stop reason。
6. GUI 已提供“关闭 / 智能使用 / 强力约束”三档入口，CLI 已提供最小状态摘要。

`ECP-17` 的实际完成形态：

1. 由于本地未设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`，且本会话没有显式真实计费调用许可，因此未运行短真实探针。
2. 已运行 `tools/run_expression_constraint_policy_mock_regression_suite.ps1`，并通过 core/adapters/app probe support/long task mock probe/expression constraint mock probe 整套回归。
3. 最新 mock probe 产物可直接作为人工阅读与后续接手依据：
   - `artifacts/mock_long_task_probe_workspace/2026-06-06T17-35-48-344775/`
   - `artifacts/mock_expression_constraint_policy_probe_workspace/2026-06-06T17-35-58-309199/`

---

## 17. 剩余风险与后续建议

当前剩余风险主要不在合同设计，而在“真实 provider 下的短样本确认”：

1. 真实计费短探针尚未执行。
   - 当前只能证明 production contracts、projection、summary、GUI/CLI/probe 消费链路已打通，且 mock 场景覆盖齐全。
   - 还不能用这轮结果替代真实模型在 3 至 5 章普通项目、10 至 20 章长任务里的最终行为确认。
2. 章节路径与标题问题虽然已补 contract regression，但仍建议在真实短探针时再人工检查一次落盘文件和 GUI 列表口径。
3. 表达限制的 review evidence 与 adaptive 升级虽然已有稳定字段，但真实模型是否会持续给出高质量 review 证据，仍需短真实探针确认。
4. 长任务停止原因 taxonomy 已结构化，但在真实 provider 下仍应观察 budget、waiting_user、repair_required、technical_failure 的实际分布是否自然。

后续建议顺序：

1. 先在显式开闸前提下跑一次 `ECP-17` 规定的短真实探针，不直接进入更大预算长跑。
2. 真实探针至少覆盖：
   - ordinary project `adaptive` 3 到 5 章
   - long task `adaptive` 10 到 20 章
   - 必要时补 `disabled / force` 各 1 个小样本
3. 人工验收时重点看：
   - probe report 是否有 review evidence / risk signal / disposition
   - 章节文件名、正文 H1、delivery title、GUI 列表是否继续同源
   - stop reason 是否可解释，且没有再把表达限制状态误当停止原因
4. 只有当短真实探针通过后，才建议进入更大预算的长任务验证。

结论：

```text
当前可以进入“显式开闸后的短真实探针验证”，
但还不建议直接进入更大预算长任务真实验证。
```
