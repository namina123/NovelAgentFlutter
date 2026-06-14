# NovelAgentFlutter 上下文 Token 压力判定、压缩与指令兼容收口任务顺序文档

最后更新：2026-06-14

主线代号：`CTC`（Context Token Pressure / Compaction）

关联主要资料：

- `agent.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
- `docs/legacy-migration-boundary.md`
- `docs/absorption/10-projects/deepseek-tui/README.md`
- `docs/absorption/10-projects/book-os/README.md`
- `docs/absorption/10-projects/aixiezuo/README.md`

关联历史任务顺序文档：

- `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md`
- `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md`
- `docs/release-readiness-productization-session-order-2026-06-05.md`

关联代码锚点：

- `packages/novel_agent_core/lib/src/session/`
- `packages/novel_agent_core/lib/src/agents/`
- `packages/novel_agent_core/lib/src/workflow/`
- `packages/novel_agent_adapters/lib/src/`
- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/widgets/context_settings_panel.dart`

---

## 1. 这份文档解决什么

这份文档要解决的不是“把压缩阈值从字符改成 token”这么窄的事情，而是把当前会话上下文系统正式收口成一条可以长期站住的主线：

```text
把“字符阈值 + append 后立即压缩 + 压缩后真实历史不可追 + GUI 与模型上下文语义分裂”
收口成
“轻量 token 压力判定 + 发送前/续跑前决策 + 完整历史与工作上下文分离 + 可恢复压缩段 + 可被未来指令系统复用”。
```

完成本主线后，项目应具备：

1. 真正的轻量 `token` 估算与压力判断，而不是只靠字符数粗估。
2. 明确区分：
   - 完整转录 `full transcript`
   - 模型工作上下文 `working context`
   - 压缩归档 `compaction archive / segments`
3. 压缩提示词不再散落拼接，而是拥有正式的：
   - `compaction guidance`
   - `compaction output policy`
   - `compaction source scope`
   - `runtime continuation instruction`
   分层注入协议。
4. 自动压缩触发点从“每次追加消息后”迁移到：
   - 发送模型前
   - 工具轮准备继续前
   - 长任务/连续任务恢复前
5. GUI、持久化、模型输入三者看到的是同一套正式合同，而不是各自维护半套事实。
6. 后续 `CLI / TUI / 指令系统 / 目标模式 / 连续任务控制面` 能直接复用同一套压力判断、压缩动作与注入协议，而不是再写第二套。

---

## 2. 与旧文档的关系

### 2.1 它不是另起一套会话系统

这份文档不允许：

1. 新造第二套 `session record`
2. 新造第二套“压缩专用历史”
3. 在 GUI 层偷偷搞一套和 core 不一致的 transcript 管理
4. 用 probe / viewmodel / controller 临时拼出 token 压力判断真相

正确方向是：

1. 继续复用现有 `session/` 主链
2. 把粗糙的字符压缩实现升级为稳定的轻量 token 压力判定与 compaction 合同
3. 让 GUI、长任务、未来命令入口消费同源动作与状态

### 2.2 它吸收哪些已有判断

1. `DeepSeek-TUI` 提供了重要方向：
   - 当前上下文保守 token 估算优先
   - 预警与自动压缩分开
   - 自动压缩在发送前决策，而不是写入即压缩
2. `book-os / aixiezuo` 提供了另一个关键提醒：
   - “完整视图”和“压缩视图”应并存
   - 压缩结果本身应是正式资产，而不是随手一串摘要字符串
3. 我们自己现有的连续任务分析文档补上了：
   - 未来指令系统、目标模式、长任务、研究提取都需要共享上下文压力判断与压缩基础设施
4. 这轮新增判断补上了另一个关键前提：
   - 压缩后的质量与长度，不只由压缩算法决定，还由“压缩提示词如何注入、是否污染用户提示词、是否有独立长度策略”决定。

### 2.3 这份文档不处理什么

1. 不在本主线里完成完整 CLI/TUI 产品化。
2. 不在本主线里讨论具体小说题材工作流。
3. 不把表达限制、字数限制、知识库激活等全部吞进上下文压缩主线。
4. 不把 provider 的全量协议迁移当成本轮主任务；本轮只要求为 provider 精算 token 预留正确 adapter 口。

---

## 3. 已有实现去重审计

### 3.1 已有可复用基础

1. `SessionRecordNormalizerService`
2. `SessionRecordMutationService`
3. `SessionCompressionStrategyService`
4. `SessionContextRendererService`
5. `ConversationSessionStateService`
6. `WorkbenchConversationController`
7. 已有的上下文设置面板与模型 profile 配置
8. 已有的工具结果压缩服务：
   - `AgentRunCompactorService`
   - `AgentToolSummaryService`

这些都不该推倒重写。

### 3.2 已有但仍是半成品

1. 压缩阈值仍以 `compression_threshold_chars` 为核心，token 压力判断只是间接影子。
2. `SessionCompressionStrategyService` 仍采用 `context_length * 2` 这类字符近似。
3. `SessionRecordMutationService.sessionWithMessage()` 在追加消息后就会 `_maybeCompress()`。
4. `compressed_context` 仍是一整段字符串，不是结构化压缩资产。
5. GUI `entries` 与 `sessionRecord.context_messages` 是两条不同语义的链：
   - 运行中看到的历史
   - 持久化后真正会喂给模型的历史
   当前并不一致。
6. 重载后无法稳定重建压缩前完整会话。
7. 设置界面只暴露了“压缩阈值百分比”等旧口径，尚未进入 token 压力判定时代。
8. 压缩提示词、用户提示词、内部续跑指令当前还没有清晰的层级协议，后续很容易被随手拼接到同一段 prompt 中。

### 3.3 真正缺的层

1. `token pressure estimate` 核心合同
2. `context pressure` 核心合同
3. `full transcript / working context / compaction archive` 三分合同
4. `compaction segment / snapshot / fold metadata`
5. 发送前压缩决策服务
6. provider 可选精算 token port
7. `compaction guidance / output policy / source scope / continuation instruction` 合同
8. 指令兼容 action surface
9. GUI 侧正式的压缩段折叠与恢复语义

---

## 4. 本轮冻结的架构边界

1. token 压力判断优先放在 `core`，不是放在 widget、controller 或 CLI 命令里。
2. provider 精算 token 只能是可选 adapter 增强，不得把它写成当前阶段的重依赖，更不得把 core 绑死在某一家协议上。
3. 自动压缩的触发点必须从“消息写入”迁移为“发送前/续跑前”。
4. 压缩动作只能改 `working context`，不能直接毁掉 `full transcript`。
5. GUI 可以有折叠、分级显示，但不能自己发明第二套压缩事实源。
6. `compressed_context` 这类单字符串字段可以兼容迁移，但不能继续作为终态设计。
7. 本主线必须为未来 `指令系统 / 目标模式 / 连续任务控制面` 预留统一动作接口。
8. 不允许把“为了将来做命令”变成“现在先在 app 层写一堆命令式 if/else”。
9. `compaction guidance` 不允许直接追加到真实用户提示词后面，也不允许替换真实用户提示词。
10. 用户当前提示词默认保持原样；只有内部续跑、工具回合继续、恢复执行时，才允许注入独立的 `runtime continuation instruction`。
11. 压缩质量和长度策略必须建模为正式合同，不允许只靠一句“尽量简短”或散落 prompt 常量维持。
12. 单文件接近 400 行时要主动复核职责；接近 700 行必须拆。

---

## 5. 目标终态

完成本主线后，应达到以下终态：

1. 项目有正式的 `SessionTokenBudgetEstimatorService`，但它定位为轻量压力判定服务，而不是重型预算中心。
2. 项目有正式的 `SessionContextPressureService`。
3. 项目有正式的 `SessionCompactionDecisionService` 与 `SessionCompactionPlannerService`。
4. `full transcript`、`working context`、`compaction archive` 三层职责清楚。
5. 项目有正式的 `compaction guidance / output policy / source scope / continuation instruction` 注入协议，且不会污染真实用户提示词。
6. 模型输入上下文由正式工作上下文渲染，不再直接依赖“剩余 messages + 一段压缩字符串”。
7. GUI 运行中、GUI 重载后、模型实际吃到的上下文语义保持一致。
8. 设置面板与内部设置正式转向 token 压力口径，旧字符口径只保留兼容桥。
9. 有最小 `inspect / compact / clear working context / pin` 动作面，供未来命令系统直接消费。
10. focused tests、integration tests、GUI restore tests 覆盖主链，不再靠人肉猜测压缩是否发生。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `15` 个 session。

顺序理由：

1. `CTC-01` 到 `CTC-03` 先冻结核心术语与领域合同。
2. `CTC-04` 先把压缩提示词、长度策略和注入协议定成正式合同，避免后面的人顺手拼进 user prompt。
3. `CTC-05` 到 `CTC-07` 再把估算、压力、压缩决策这些纯逻辑定稳。
4. `CTC-08` 到 `CTC-09` 再做持久化兼容与 provider 适配口。
5. `CTC-10` 到 `CTC-11` 再把 runtime / conversation 主链接上。
6. `CTC-12` 到 `CTC-13` 最后处理 GUI 与设置，因为它们只能消费稳定合同。
7. `CTC-14` 做指令兼容 action surface，让未来命令功能有正式抓手。
8. `CTC-15` 最后做 focused regression、GUI 级探针与文档收口。

这条顺序明确避免：

1. 先改设置面板再反推 core
2. 先在 controller 里补 preflight if/else
3. 先做命令样式入口再补底层压力判断真相

---

## 7. 全局执行规则

所有 session 都必须遵守：

1. 先读本文档、`agent.md`、当前 session 必读文件。
2. 只做当前 session，不开启下一任务。
3. 优先抽小合同与小服务，不把逻辑继续堆在 `ConversationSessionStateService` 或 `WorkbenchConversationController`。
4. focused test 与实现同轮落地。
5. 不允许在 GUI、probe、临时脚本里复制 core 判断。
6. 保留兼容层时要明确：
   - 谁是新主链
   - 谁是迁移桥
   - 后续何时删旧字段
7. 压缩提示词协议、长度策略、用户提示词与内部续跑指令必须分层，不允许顺手拼成一个 prompt 字符串。

---

## 8. Sessions

## CTC-01 基线审计与术语冻结

- 本轮目标：
  - 对当前 `session` 主链做最终基线审计，并冻结本主线使用的术语与边界。
- 层级归属：
  - Documentation / Core boundary audit
- 必读文件：
  - 本文档
  - `agent.md`
  - `packages/novel_agent_core/lib/src/session/session_record_mutation_service.dart`
  - `packages/novel_agent_core/lib/src/session/session_context_renderer_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart`
- 必须完成：
  - 列出当前真实事实链：
    - 完整会话显示来自哪里
    - 模型上下文来自哪里
    - 持久化记录来自哪里
  - 在文档完成记录里写明“旧压缩真相”和“新术语表”
  - 冻结术语：
    - `full transcript`
    - `working context`
    - `compaction archive`
    - `context pressure`
    - `preflight compaction`
- 本轮不要做：
  - 不改实现
  - 不改 settings
  - 不做兼容迁移
- 验收标准：
  - 审计结论能精确说明现状分裂点，后续 session 不再反复争论术语
- 直接可用提示词：
  - 按 `docs/context-token-budget-and-compaction-session-order-2026-06-14.md` 的 `CTC-01` 执行。先阅读本文档、`agent.md`、`packages/novel_agent_core/lib/src/session/session_record_mutation_service.dart`、`packages/novel_agent_core/lib/src/session/session_context_renderer_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart`。只做上下文主链基线审计与术语冻结：明确完整会话显示、模型上下文、持久化记录分别来自哪里，并把 `full transcript / working context / compaction archive / context pressure / preflight compaction` 写成统一术语。不要改实现，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## CTC-02 Token 压力判定核心合同

- 本轮目标：
  - 在 `core` 层建立正式的轻量 token 压力判定合同。
- 层级归属：
  - Core / domain
- 必读文件：
  - `packages/novel_agent_core/lib/src/session/`
  - `docs/absorption/10-projects/deepseek-tui/README.md`
- 必须完成：
  - 新增或收口：
    - `SessionTokenBudgetSettings`
    - `SessionTokenBudgetEstimate`
    - `SessionContextPressureLevel`
    - `SessionContextPressureSnapshot`
    - `SessionTokenCountSource`
  - 明确输入字段：
    - system prompt
    - messages
    - reserved output budget
    - model context window
    - optional provider exact count hint
  - focused contract tests
- 本轮不要做：
  - 不改 GUI
  - 不接 provider
  - 不做 compaction 逻辑
- 验收标准：
  - token 压力、压力等级和估算来源都有稳定 JSON/Map 形态，且不再依赖字符阈值命名
- 直接可用提示词：
  - 按本文档的 `CTC-02` 执行。只在 core/session 层建立轻量 token 压力判定核心合同：`SessionTokenBudgetSettings`、`SessionTokenBudgetEstimate`、`SessionContextPressureLevel`、`SessionContextPressureSnapshot`、`SessionTokenCountSource`。这里的目标是支撑发送前压缩决策，不是做一个重型预算子系统。补 focused contract tests。不要接 GUI、不要接 provider、不要改 compaction 行为，不开启下一任务。注意解耦合、单一职责、避免把合同塞进大 service 文件。

## CTC-03 完整历史与工作上下文分层合同

- 本轮目标：
  - 正式建立 `full transcript / working context / compaction archive` 三分结构。
- 层级归属：
  - Core / session
- 必读文件：
  - `packages/novel_agent_core/lib/src/session/session_record_normalizer_service.dart`
  - `packages/novel_agent_core/lib/src/session/session_history_service.dart`
  - `docs/absorption/10-projects/book-os/README.md`
  - `docs/absorption/10-projects/aixiezuo/README.md`
- 必须完成：
  - 设计并落地新的 session record 子结构，例如：
    - `transcript_messages`
    - `working_context_messages`
    - `compaction_segments`
    - `pinned_context_refs`
  - 明确兼容策略：旧 `context_messages` 与 `compressed_context` 如何过渡
  - focused normalization tests
- 本轮不要做：
  - 不做估算算法
  - 不接 GUI 折叠显示
  - 不改 controller
- 验收标准：
  - session record 结构能正式表达“完整历史还在，但工作上下文已压缩”
- 直接可用提示词：
  - 按本文档的 `CTC-03` 执行。只在 core/session 层建立 `full transcript / working context / compaction archive` 三分合同，并给出旧 `context_messages / compressed_context` 的兼容迁移方案。补 focused normalization tests。不要接 GUI，不改 controller，不开启下一任务。保持单一职责，不要把新结构继续压回一个字符串字段。

## CTC-04 压缩提示词与注入协议合同

- 本轮目标：
  - 正式把压缩质量和长度控制所依赖的提示词协议建模，而不是留给后续 prompt builder 临时拼接。
- 层级归属：
  - Core / prompt-context contract
- 必读文件：
  - `packages/novel_agent_core/lib/src/session/`
  - `packages/novel_agent_core/lib/src/workflow/`
  - 本文档
- 必须完成：
  - 新增或收口：
    - `CompactionGuidanceContract`
    - `CompactionOutputPolicy`
    - `CompactionSourceScope`
    - `RuntimeContinuationInstructionContract`
  - 明确注入顺序：
    - `system foundation`
    - `project guidance`
    - `compaction guidance`
    - `context payload`
    - `current user prompt` 或 `runtime continuation instruction`
  - 明确规则：
    - `compaction guidance` 不追加到真实用户提示词后面
    - 用户提示词默认保持原样
    - 内部续跑指令独立存在，不伪装成用户消息
  - focused contract tests
- 本轮不要做：
  - 不实现具体压缩算法
  - 不接 GUI
  - 不改 provider
- 验收标准：
  - 压缩质量、长度策略和注入层次都有正式合同，后续实现不再需要猜“提示词往哪拼”
- 直接可用提示词：
  - 按本文档的 `CTC-04` 执行。只在 core 层建立压缩提示词与注入协议合同：`CompactionGuidanceContract`、`CompactionOutputPolicy`、`CompactionSourceScope`、`RuntimeContinuationInstructionContract`，并冻结注入顺序与“不要把 compaction guidance 直接追加到真实用户提示词后面”的规则。补 focused contract tests。不要实现具体压缩算法，不接 GUI，不开启下一任务。注意分层清楚，不要再造一个大 prompt builder 中心。

## CTC-05 保守估算器与压力快照服务

- 本轮目标：
  - 把 token 估算与压力快照做成独立纯逻辑服务。
- 层级归属：
  - Core / session
- 必读文件：
  - `packages/novel_agent_core/lib/src/session/`
  - `references/DeepSeek-TUI-main/crates/tui/src/compaction.rs`
  - `references/DeepSeek-TUI-main/crates/tui/src/tui/ui.rs`
- 必须完成：
  - 新增：
    - `SessionTokenBudgetEstimatorService`
    - `SessionContextPressureService`
  - 至少支持：
    - 保守文本估算
    - system prompt 估算
    - tool payload 估算
    - framing overhead
    - warning / critical 口径
  - focused tests覆盖：
    - 单轮消息
    - 多轮工具调用
    - system prompt 存在时
    - 上下文增长单调性
- 本轮不要做：
  - 不接 provider exact count
  - 不改 session mutation
- 验收标准：
  - 能稳定产出 `pressure snapshot`，且多轮工具调用时不会因为旧 usage 口径而乱跳
- 直接可用提示词：
  - 按本文档的 `CTC-05` 执行。只实现 `SessionTokenBudgetEstimatorService` 与 `SessionContextPressureService`，参考 DeepSeek-TUI 的“当前待发上下文保守估算优先”思路，但不要照搬其 UI glue。这里的目标是轻量压力判定，不是重型预算中心。补 focused tests，覆盖多轮工具调用与 system prompt。不要接 provider exact count，不改 session mutation，不开启下一任务。

## CTC-06 压缩规划与发送前决策服务

- 本轮目标：
  - 正式把“何时压缩、压哪些、保留哪些”从 mutation 中拆出来。
- 层级归属：
  - Core / session
- 必读文件：
  - `packages/novel_agent_core/lib/src/session/session_record_mutation_service.dart`
  - `packages/novel_agent_core/lib/src/session/session_message_service.dart`
- 必须完成：
  - 新增：
    - `SessionCompactionPlannerService`
    - `SessionCompactionDecisionService`
    - 如有必要，新增 `SessionCompactionSegmentBuilderService`
  - 支持：
    - 发送前判断
    - 工具轮继续前判断
    - 恢复前判断
    - pinned 上下文不被随意压掉
  - 移除“append message 即压缩”的主职责地位
  - focused tests
- 本轮不要做：
  - 不接 GUI
  - 不做 provider adapter
  - 不做 settings 改造
- 验收标准：
  - `SessionRecordMutationService` 不再承担完整压缩算法，压缩决策与规划有独立服务
- 直接可用提示词：
  - 按本文档的 `CTC-06` 执行。只把压缩规划与发送前决策从 `SessionRecordMutationService` 中拆出，建立 `SessionCompactionPlannerService`、`SessionCompactionDecisionService`，让自动压缩不再发生在 append message 后，而是发送前、工具轮继续前、恢复前。补 focused tests，不接 GUI、不改 settings、不开启下一任务。注意不要把 fallback 变成新的业务中心。

## CTC-07 上下文渲染主链迁移

- 本轮目标：
  - 让模型实际输入使用新的工作上下文合同渲染。
- 层级归属：
  - Core / session
- 必读文件：
  - `packages/novel_agent_core/lib/src/session/session_context_renderer_service.dart`
  - `packages/novel_agent_core/lib/src/session/session_record_normalizer_service.dart`
- 必须完成：
  - `SessionContextRendererService` 改为消费：
    - working context
    - compaction archive summary
    - pinned refs
    - `compaction guidance` 所需的稳定摘要块
  - 公开摘要也改用 token/pressure 口径，而不再只显示字符与阈值
  - focused renderer tests
- 本轮不要做：
  - 不改 GUI widget
  - 不接 runtime send hook
- 验收标准：
  - 渲染输出已经能准确说明“摘要来自 archive、最近消息来自 working context”
- 直接可用提示词：
  - 按本文档的 `CTC-07` 执行。只迁移 `SessionContextRendererService`：让模型输入上下文正式消费 working context、compaction archive summary、pinned refs，并为 `compaction guidance` 提供稳定可注入的摘要块；同时把公开摘要转向 token/pressure 口径。补 focused renderer tests。不要接 GUI widget、不要接 runtime send hook、不开启下一任务。

## CTC-08 持久化兼容与旧字段迁移

- 本轮目标：
  - 让新旧 session record 能稳定共存与迁移。
- 层级归属：
  - Core / adapters compatibility
- 必读文件：
  - `packages/novel_agent_core/lib/src/session/session_record_normalizer_service.dart`
  - `packages/novel_agent_core/lib/src/session/session_record_constants.dart`
  - 与 session 持久化相关测试
- 必须完成：
  - 定义旧字段兼容规则：
    - `compression_threshold_chars`
    - `compressed_context`
    - `context_messages`
  - 新记录默认写入新字段
  - 旧记录读入时自动归一化
  - focused migration tests
- 本轮不要做：
  - 不在本轮删旧字段所有痕迹
  - 不接 GUI 显示
- 验收标准：
  - 老项目历史会话不会因为新结构直接失效，且新记录不继续依赖旧字段当主真相
- 直接可用提示词：
  - 按本文档的 `CTC-08` 执行。只处理 session record 的持久化兼容与旧字段迁移：老记录可读，新记录默认写新结构，旧 `compression_threshold_chars / compressed_context / context_messages` 只保留兼容桥。补 focused migration tests。不要接 GUI，不开启下一任务。

## CTC-09 Provider 精算 token 适配口

- 本轮目标：
  - 给 token 压力判定链加一个可选 provider exact count port。
- 层级归属：
  - Core ports / Adapters
- 必读文件：
  - `packages/novel_agent_adapters/lib/src/`
  - `references/cc-switch-main/src/types/usage.ts`
- 必须完成：
  - 新增类似：
    - `ProviderTokenCountPort`
    - `ProviderTokenCountResult`
  - 规范：
    - exact count 可用时优先
    - 不可用时回退保守估算
    - reported usage 只作辅助，不直接替代当前上下文估算
  - adapter 侧最小实现或 stub
  - focused tests
- 本轮不要做：
  - 不把所有 provider 都实现一遍
  - 不把具体协议逻辑塞进 core
- 验收标准：
  - 核心压力判定链能表达“本次压力判断来自 exact count 还是 estimate”
- 直接可用提示词：
  - 按本文档的 `CTC-09` 执行。只为 token 压力判定链增加可选 `ProviderTokenCountPort` 适配口，让 exact count 可用时优先、不可用时回退 core 保守估算，同时明确 reported usage 只是辅助而不是当前上下文真相。这里的目标是预留可选增强口，不是要求本轮把各 provider 精算能力做全。补 focused tests。不要把具体 provider 协议塞进 core，不开启下一任务。

## CTC-10 会话状态服务与运行时发送前接线

- 本轮目标：
  - 让 conversation 主链在真正发模型前跑新的 preflight 压缩决策。
- 层级归属：
  - App workflow / runtime bridge
- 必读文件：
  - `apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
- 必须完成：
  - 在真正生成请求前接入：
    - pressure snapshot
    - preflight compaction
    - compaction guidance
    - current user prompt 与 runtime continuation instruction 的分层注入
  - 保证工具轮继续前也走同一入口
  - `sessionWithMessage()` 不再承担最终压缩触发
  - integration tests
- 本轮不要做：
  - 不做 GUI 折叠显示
  - 不改 settings 面板
- 验收标准：
  - 真实请求前能稳定看到“必要时先 compact，再渲染上下文，再发送”
- 直接可用提示词：
  - 按本文档的 `CTC-10` 执行。只把新的 pressure snapshot、preflight compaction、compaction guidance，以及 `current user prompt / runtime continuation instruction` 分层注入协议接到 conversation/runtime 真实发送前主链，并保证工具轮继续前复用同一入口。不要做 GUI 折叠显示，不改 settings 面板，不开启下一任务。注意把行为放在服务层/bridge 层，不要堆到 controller 巨文件里。

## CTC-11 重载恢复与时间线一致性收口

- 本轮目标：
  - 解决“运行中看到的历史”和“重载后可恢复历史”不一致的问题。
- 层级归属：
  - App / session state
- 必读文件：
  - `apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart`
  - 与会话重载相关测试
- 必须完成：
  - 让 `entries` 与持久化后的 transcript/archive 有稳定映射关系
  - 重载后能恢复：
    - 完整历史条目
    - 压缩段折叠条目
    - 当前 working context 提示
  - GUI restore tests
- 本轮不要做：
  - 不改视觉样式
  - 不加新设置入口
- 验收标准：
  - 同一会话重载前后，用户理解到的历史结构不再突变
- 直接可用提示词：
  - 按本文档的 `CTC-11` 执行。只修复会话重载一致性：让 live `entries` 与持久化 transcript/archive 有稳定映射，重载后可恢复完整历史条目、压缩段折叠条目和当前 working context 提示。补 GUI/session restore tests。不要改视觉样式，不开启下一任务。

## CTC-12 GUI 压缩段投影与上下文压力展示

- 本轮目标：
  - 把压缩状态正式投影到 GUI，但只消费稳定合同。
- 层级归属：
  - App / GUI
- 必读文件：
  - workbench 相关 transcript / sidebar / session view data 服务
  - `apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart`
- 必须完成：
  - 增加最小 GUI 投影：
    - 当前上下文压力
    - warning / critical 状态
    - archive/compaction 段折叠视图
  - 用户能区分：
    - 完整历史
    - 已压缩归档
    - 当前工作上下文窗口
  - focused widget / projection tests
- 本轮不要做：
  - 不重做整套工作台视觉
  - 不引入复杂动画
- 验收标准：
  - 用户能看懂“系统压缩了什么、为什么压缩、现在模型主要在看什么”
- 直接可用提示词：
  - 按本文档的 `CTC-12` 执行。只在 GUI 层做压缩段投影与上下文压力展示，消费稳定合同，不自己重算 token 或压缩判断。让用户能区分完整历史、已压缩归档、当前工作上下文窗口。补 focused widget/projection tests。不要重做整套视觉，不开启下一任务。

## CTC-13 设置面板与内部设置口径迁移

- 本轮目标：
  - 把设置面板从字符时代迁到 token 压力判定时代。
- 层级归属：
  - App / settings
- 必读文件：
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/context_settings_panel.dart`
  - 与 settings 映射相关 service / tests
- 必须完成：
  - 暴露正式设置：
    - context window hint / model window
    - warning threshold
    - critical threshold
    - reserved output tokens
    - auto compact policy
    - optional exact count preference（高级项或兼容位）
    - compaction output policy 的必要用户侧旋钮
  - 旧 `compression_threshold_percent` 做兼容桥或高级兼容位
  - focused settings tests
- 本轮不要做：
  - 不把所有低层参数都暴露给普通用户
  - 不回退成字符上限优先
- 验收标准：
  - GUI 设置文案与内部压力判定/压缩策略合同一致，且普通用户不会被一堆底层字段淹没
- 直接可用提示词：
  - 按本文档的 `CTC-13` 执行。只迁移上下文设置面板与内部设置口径：把正式设置改成 token 压力、warning/critical、reserved output、auto compact policy、可选 exact count preference，以及 `compaction output policy` 的必要用户侧旋钮；旧 `compression_threshold_percent` 只保留兼容桥。补 focused settings tests。不要把所有底层参数都暴露给普通用户，不开启下一任务。

## CTC-14 指令兼容动作面

- 本轮目标：
  - 为未来指令系统建立稳定 action surface，但不做完整 CLI/TUI。
- 层级归属：
  - Core / App action surface
- 必读文件：
  - `packages/novel_agent_core/lib/src/session/`
  - `apps/novel_agent_app/lib/features/workbench/application/`
- 必须完成：
  - 建立可被未来命令消费的动作接口，例如：
    - `inspectContext`
    - `compactNow`
    - `clearWorkingContext`
    - `pinContextSegment`
    - `unpinContextSegment`
    - `inspectCompactionGuidance`
  - 这些动作必须复用前面 session 的正式服务
  - focused action tests
- 本轮不要做：
  - 不做完整命令解析器
  - 不在 GUI 硬塞命令行壳
- 验收标准：
  - 未来指令系统不需要重新造一套压缩逻辑，只需调用现有动作面
- 直接可用提示词：
  - 按本文档的 `CTC-14` 执行。只建立未来指令系统可复用的上下文动作面：`inspectContext / compactNow / clearWorkingContext / pinContextSegment / unpinContextSegment / inspectCompactionGuidance`，并确保这些动作复用前面已建立的正式服务。补 focused action tests。不要做完整命令解析器，不要在 GUI 硬塞命令壳，不开启下一任务。

## CTC-15 回归、GUI 级探针与收口文档

- 本轮目标：
  - 用 production 同源链做最后验收，并补 handoff 文档。
- 层级归属：
  - Probe / regression / Documentation
- 必读文件：
  - 本文档
  - 前 13 个 session 相关 tests
  - 与会话探针相关既有脚本/测试
- 必须完成：
  - focused regression：
    - 普通对话多轮
    - 工具调用后继续
    - 重载恢复
    - warning / critical 阈值
    - manual compact
    - compaction guidance 不污染真实用户提示词
  - 最小 GUI viewmodel / controller 级探针：
    - 从新会话开始
    - 模拟多轮输入与工具回合
    - 验证压缩不会吃掉完整历史
    - 验证内部续跑指令没有伪装成真实用户消息
  - 输出一份简短 handoff：
    - 新主链是什么
    - 旧兼容桥还剩什么
    - 后续 CLI/TUI/指令功能接哪里
- 本轮不要做：
  - 不再扩新需求
  - 不顺手重构 unrelated 模块
- 验收标准：
  - 真实主链已能证明：轻量 token 压力判定、发送前压缩、压缩提示词分层注入、重载恢复、GUI 展示、动作面是同一套事实
- 直接可用提示词：
  - 按本文档的 `CTC-15` 执行。只做最终 regression、GUI 级探针与 handoff 收口：验证普通对话多轮、工具调用后继续、重载恢复、warning/critical 阈值、manual compact、`compaction guidance` 不污染真实用户提示词、内部续跑指令不伪装成用户消息，都走 production 同源主链，并补一份说明新主链、兼容桥和未来 CLI/TUI/指令接入点的 handoff。不要扩新需求，不开启下一任务。保持 probe 只消费 production truth。

---

## 9. 总启动提示词

```text
根据 `docs/context-token-budget-and-compaction-session-order-2026-06-14.md` 按顺序执行上下文 token 压力判定、压缩与指令兼容收口主线。

严格要求：

1. 每次只完成一个 session。
2. 先读本文档、`agent.md`、当前 session 必读文件。
3. 只做当前 session 写明的内容，完全确认做完后才能开启下一个session。
4. 必须坚持：
   - core 合同先行
   - provider 精算只做可选 adapter 口
   - 自动压缩从 append 后触发迁移到发送前/续跑前
   - `compaction guidance / output policy / source scope / continuation instruction` 单独成层
   - 不把 `compaction guidance` 直接追加到真实用户提示词后面
   - 完整历史、工作上下文、压缩归档三分
   - GUI 只消费稳定合同
   - 不让 controller/widget/probe 变成第二业务中心
5. 所有实现都要补 focused test；涉及恢复与 GUI 的要补 integration 或 widget/restore test。
6. 发现单文件继续变重时，优先拆服务或拆 view-data/projection，不要硬堆。
7. 本主线完成后，目标必须真正达成：项目正式具备轻量 token 压力判定、发送前压缩、压缩提示词分层注入、完整历史与工作上下文分离、GUI/持久化/模型输入一致、且为未来指令系统预留稳定 action surface 的能力。
```

---

## 10. 完成记录占位

- `CTC-01`：
  - 已完成基线审计，且本轮未改实现。
  - 真实事实链：
    - 完整会话展示来自 `apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart` 里的 `ConversationSessionState.entries`；重载时由 `restoreSession()` 从持久化 `sessionRecord` 投影回展示条目。
    - 模型输入上下文来自 `packages/novel_agent_core/lib/src/session/session_context_renderer_service.dart` 的 `sessionContextMarkdown()`；它直接消费 `sessionRecord.context_messages` 与 `sessionRecord.compressed_context`。
    - 持久化记录来自 `packages/novel_agent_core/lib/src/session/session_record_normalizer_service.dart` 维护的 `sessionRecord` 结构，当前主字段仍是 `context_messages / compressed_context / compression_count / compression_threshold_chars / total_context_chars`。
  - 旧压缩真相：
    - `SessionRecordMutationService.sessionWithMessage()` 在追加消息后立即调用 `_maybeCompress()`，压缩主逻辑仍然是字符阈值驱动。
    - 当前实现会把前半段消息折叠成一段文本写入 `compressed_context`，并把剩余消息留在 `context_messages` 里。
    - 这意味着“完整历史 / 工作窗口 / 压缩归档”还没有正式三分，GUI 时间线与模型工作上下文已经存在语义分裂。
  - 新术语冻结：
    - `full transcript`：完整历史转录，保留全部可恢复消息事实。
    - `working context`：当前实际送入模型的消息窗口。
    - `compaction archive`：被压缩收纳的历史段与其元数据。
    - `context pressure`：围绕模型上下文窗口的压力判断，而不是字符阈值命名。
    - `preflight compaction`：发送前、续跑前、恢复前的压缩决策。
- `CTC-02`：
  - 已完成轻量 token 压力判定核心合同落地，并补 focused contract tests。
  - 新增合同：
    - `SessionTokenBudgetSettings`
    - `SessionTokenBudgetEstimate`
    - `SessionContextPressureLevel`
    - `SessionContextPressureSnapshot`
    - `SessionTokenCountSource`
  - 稳定 Map / JSON 口径：
    - settings 使用 `model_context_window_tokens / reserved_output_tokens / warning_threshold_ratio / critical_threshold_ratio`
    - estimate 使用 `system_prompt_tokens / message_tokens / framing_tokens / total_input_tokens / token_count_source / provider_exact_count_hint_tokens`
    - snapshot 使用 `settings / estimate / pressure_level / input_budget_tokens / remaining_input_tokens / overflow_tokens / used_context_ratio / has_overflow`
  - 验证结果：
    - `dart test test/session_context_pressure_contracts_test.dart`
    - `dart test test/session_strategy_services_test.dart`
  - 备注：
    - 本轮只建立核心合同与稳定序列化形态，没有接 GUI、provider 或 compaction 行为。
- `CTC-03`：
  - 已完成 `full transcript / working context / compaction archive / pinned context refs` 三分结构落地，并保留旧字段兼容桥。
  - 新增或收口的 session record 字段：
    - `transcript_messages`
    - `working_context_messages`
    - `compaction_segments`
    - `pinned_context_refs`
  - 兼容策略：
    - 新记录默认写入三分结构，旧 `context_messages` 继续作为 `working_context_messages` 的桥。
    - 旧 `compressed_context` 会被归一化为结构化 `compaction_segments`，再渲染回兼容文本。
    - `context_messages` 与 `working_context_messages` 保持同源，`transcript_messages` 保留完整历史转录。
  - 同步收口：
    - `SessionHistoryService.sessionHistoryWindow()` 已优先读取 `working_context_messages`。
  - 验证结果：
    - `dart test test/session_record_normalizer_service_test.dart`
    - `dart test test/session_record_service_test.dart`
    - `dart test test/session_strategy_services_test.dart`
  - 备注：
    - 本轮没有改 GUI、controller 或压缩决策入口，只做 session record 的结构化迁移与兼容归一化。
- `CTC-04`：
  - 已完成压缩提示词与注入协议合同分层，且未把 `compaction guidance` 直接拼进真实用户提示词。
  - 新增合同：
    - `CompactionGuidanceContract`
    - `CompactionOutputPolicy`
    - `CompactionSourceScope`
    - `RuntimeContinuationInstructionContract`
  - 新增注入帧与顺序枚举：
    - `CompactionPromptInjectionFrame`
    - `CompactionPromptInjectionSectionKind`
  - 冻结注入顺序：
    - `system foundation`
    - `project guidance`
    - `compaction guidance`
    - `context payload`
    - `current user prompt` 或 `runtime continuation instruction`
  - 验证结果：
    - `dart test test/session_compaction_prompt_contracts_test.dart`
    - `dart test test/session_compaction_prompt_contracts_test.dart test/session_record_normalizer_service_test.dart test/session_record_service_test.dart test/session_strategy_services_test.dart`
  - 备注：
    - 本轮只建立协议层，不实现具体压缩算法，也没有接 GUI 或 provider。
- `CTC-05`：
  - 已完成保守 token 估算器与压力快照服务。
  - 新增服务：
    - `SessionTokenBudgetEstimatorService`
    - `SessionContextPressureService`
  - 已支持的估算维度：
    - 系统提示词估算
    - 消息正文估算
    - 工具载荷估算
    - framing overhead
  - 压力快照行为：
    - 直接从 `SessionTokenBudgetSettings` + `SessionTokenBudgetEstimate` 生成 `SessionContextPressureSnapshot`
    - `snapshotFromSessionRecord()` 优先消费 `working_context_messages`
  - 验证结果：
    - `dart test test/session_context_pressure_services_test.dart`
    - `dart test test/session_record_normalizer_service_test.dart test/session_record_service_test.dart test/session_strategy_services_test.dart`
  - 备注：
    - 本轮仍然是纯逻辑服务，没有接 provider exact count、没有改 mutation 接线、没有碰 GUI。
- `CTC-06`：
  - 已完成压缩规划与发送前决策拆分，append 路径不再触发自动压缩。
  - 新增并导出：
    - `SessionCompactionPlannerService`
    - `SessionCompactionDecisionService`
    - `SessionCompactionTriggerKind`
    - `SessionCompactionActionKind`
  - 行为收口：
    - planner 只计算保留窗口、压缩索引和 pinned refs，不直接改写 session。
    - decision 只在 `warning / critical / overLimit` 且存在候选消息时返回 `compact_now`。
    - `SessionRecordMutationService.sessionWithMessage()` 现在只追加消息并归一化，不再执行压缩。
  - 验证结果：
    - `dart test test/session_record_service_test.dart test/session_compaction_planner_decision_service_test.dart test/session_record_normalizer_service_test.dart test/session_context_pressure_services_test.dart test/session_compaction_prompt_contracts_test.dart`
- `CTC-07`：
  - 已完成 `SessionContextRendererService` 的主链迁移。
  - 现在 renderer 直接消费：
    - `working_context_messages`
    - `compaction_segments`
    - `pinned_context_refs`
    - `compaction guidance / output policy / source scope / runtime continuation instruction` 的稳定摘要块
  - 公开摘要已改成 token / pressure 口径：
    - 优先显示 pressure level、已用 token、输入预算、剩余 token 与 token 计数来源
    - 不再依赖字符阈值作为公开摘要主叙述
  - 兼容修正：
    - `pinned_context_refs` 现在按字符串引用保留，不再被误当成 map 丢失
  - 验证结果：
    - `dart test test/session_record_service_test.dart test/session_context_renderer_service_test.dart test/session_record_normalizer_service_test.dart test/session_context_pressure_services_test.dart test/session_compaction_prompt_contracts_test.dart`
- `CTC-08`：
  - 已完成持久化兼容与旧字段迁移收口。
  - 兼容规则：
    - 新记录默认写入 `transcript_messages / working_context_messages / compaction_segments / pinned_context_refs`
    - 旧 `context_messages` 继续作为 `working_context_messages` 的兼容桥
    - 旧 `compressed_context` 继续作为结构化 `compaction_segments` 的兼容输入与渲染输出来源
    - `compression_threshold_chars` 仍保留为兼容桥，但不再是主叙述合同
  - 新增回归：
    - 新会话骨架直接带出三分字段
    - 旧 `context_messages / compressed_context` 能归一化回三分结构
    - `pinned_context_refs` 作为字符串引用能够稳定保留
  - 验证结果：
    - `dart test test/session_record_normalizer_service_test.dart test/session_record_service_test.dart`
- `CTC-09`：
  - 已完成可选 provider exact count 适配口收口。
  - 新增核心合同：
    - `ProviderTokenCountPort`
    - `ProviderTokenCountRequest`
    - `ProviderTokenCountResult`
  - 行为边界：
    - exact count 可用时由 adapter 返回 result，并把 exact input token 作为 hint 进入现有压力链
    - exact count 不可用时由 port 返回 `null`，由 core 保守估算继续兜底
    - reported usage 仅作为辅助数据保留，不直接替代当前上下文估算
  - 轻量接线：
    - `SessionContextPressureService.snapshotFromProviderTokenCountResult()` 可以把 exact hint 送回现有 snapshot 链
  - adapter 侧最小实现：
    - `UnavailableProviderTokenCountPort` 作为当前阶段 stub，明确返回 `null`
  - 验证结果：
    - `dart test test/provider_token_count_port_test.dart test/session_context_pressure_services_test.dart test/session_context_pressure_contracts_test.dart`
    - `dart test test/provider_token_count_port_adapter_test.dart`
- `CTC-10`：
- `CTC-11`：
- `CTC-12`：
- `CTC-13`：
  - 已完成上下文设置面板与内部设置口径迁移，token 压力合同成为主叙述，旧字符字段保留为高级兼容桥。
  - 新增设置合同服务：
    - `ContextSettingsContractService`
  - 设置主合同字段：
    - `model_context_window_tokens`
    - `context_window_hint_tokens`
    - `warning_threshold_ratio`
    - `critical_threshold_ratio`
    - `reserved_output_tokens`
    - `auto_compact_policy`
    - `prefer_exact_count`
    - `compaction_output_policy`
  - 兼容桥字段继续保留：
    - `compression_threshold_percent`
    - `context_pack_budget_percent`
    - `max_context_file_chars`
    - `max_context_files_per_kind`
    - `reserved_output_chars`
  - 控制器收口：
    - `AppShellController` 在保存上下文设置时统一通过 `ContextSettingsContractService.normalizeForStorage()`
    - 运行时策略映射统一通过 `ContextSettingsContractService.runtimeStrategySettings()`
  - 验证结果：
    - `flutter test test/context_settings_contract_service_test.dart test/context_settings_panel_test.dart`
  - 备注：
    - 本轮把普通用户入口前置成 token 压力口径，并把旧字符时代字段收进可折叠兼容桥，没有把旧口径重新抬回主叙述。
- `CTC-14`：
  - 已完成指令兼容动作面收口，未来命令系统可以直接消费稳定 action surface。
  - 新增 core 动作面：
    - `SessionContextActionKind`
    - `SessionContextActionResult`
    - `SessionContextActionService`
  - 已覆盖动作：
    - `inspectContext`
    - `compactNow`
    - `clearWorkingContext`
    - `pinContextSegment`
    - `unpinContextSegment`
    - `inspectCompactionGuidance`
  - 动作面复用的正式服务：
    - `SessionContextRendererService`
    - `SessionCompactionDecisionService`
    - `SessionRecordNormalizerService`
  - 关键语义收口：
    - `clearWorkingContext` 只清工作窗口，不动完整历史和压缩归档
    - `pin / unpin` 只维护稳定字符串引用
    - `inspectCompactionGuidance` 只投影分层合同，不把真实用户提示词和 compaction guidance 搅在一起
  - normalizer 回归：
    - 显式空的 `working_context_messages` 现在会被保留为空，不再回退成 transcript
  - 验证结果：
    - `dart test test/session_context_action_service_test.dart test/session_record_normalizer_service_test.dart test/session_compaction_planner_decision_service_test.dart test/session_compaction_prompt_contracts_test.dart test/session_context_renderer_service_test.dart test/session_record_service_test.dart`
    - `flutter test test/context_settings_contract_service_test.dart test/context_settings_panel_test.dart`
- `CTC-15`：
  - 已完成最终 regression、GUI 级探针与 handoff 收口。
  - focused regression 覆盖：
    - 普通对话多轮
    - 工具调用后继续
    - 重载恢复
    - warning / critical 阈值
    - manual compact
    - `compaction guidance` 不污染真实用户提示词
    - 内部续跑指令不伪装成用户消息
  - 新增 controller / view-model 级探针：
    - `ctc15_workbench_conversation_probe_test.dart`
  - 复用的生产同源链：
    - controller 发送链
    - `ConversationSessionPreflightService`
    - `ConversationSessionContextProjectionService`
    - `ConversationSessionStateService.restoreSession()`
  - handoff 结论：
    - 新主链已经落在 core 的 token pressure / preflight / action surface 合同上
    - 旧兼容桥只剩 settings 字符桥、`context_messages` / `compressed_context` 与少量 runtime 兼容口
    - 未来 CLI / TUI / 指令系统接入点直接消费 `SessionContextActionService` 与 preflight / projection contract
  - 额外收口：
    - 修正了 `project_structured_content_bridge_service.dart` 对 `SqliteProjectBodyTextRepository` 的缺失导入，避免 app 侧编译阻塞 probe
  - 验证结果：
    - `flutter test test/ctc15_workbench_conversation_probe_test.dart test/conversation_session_preflight_service_test.dart test/conversation_session_context_projection_service_test.dart test/conversation_session_state_service_test.dart`

---

## 11. 文档自检

1. 已说明这份文档解决什么。
2. 已说明与旧文档和现有实现的关系。
3. 已做已有实现去重审计。
4. 已冻结架构边界。
5. 已给出清晰目标终态。
6. 全部设计目标均有 session 覆盖。
7. 顺序遵守：core 合同 -> 纯逻辑服务 -> 兼容/adapter -> runtime 接线 -> GUI/settings -> action surface -> regression/handoff。
8. 每个 session 都写明：
   - 本轮目标
   - 层级归属
   - 必读文件
   - 必须完成
   - 本轮不要做
   - 验收标准
   - 直接可用提示词
9. GUI 没有被提前当作兜底层。
10. 已明确为未来指令功能预留正式接入点，而不是临时命令补丁。
11. 已把“压缩提示词与用户提示词如何共存”上升成正式合同与 session，而不是留给实现时临时拼接。
