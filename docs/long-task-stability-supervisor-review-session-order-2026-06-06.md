# 长任务稳定性、监督层与审核闭环任务顺序文档

最后更新：2026-06-06

主线代号：`LTSR`（Long Task Stability / Supervisor / Review）

关联主分析文档：

- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- `docs/expression-constraint-execution-policy-analysis-2026-06-06.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `agent.md`

关联历史任务顺序文档：

- `docs/expression-constraint-execution-policy-session-order-2026-06-06.md`
- `docs/information-evidence-discipline-session-order-2026-06-05.md`
- `docs/project-information-substrate-session-order-2026-06-05.md`
- `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md`
- `docs/release-readiness-productization-session-order-2026-06-05.md`
- `docs/major-redesign-session-order.md`

关联代码锚点：

- `packages/novel_agent_core/lib/src/workflow/`
- `packages/novel_agent_core/lib/src/review/`
- `packages/novel_agent_core/lib/src/continuity/`
- `packages/novel_agent_core/lib/src/creative/`
- `packages/novel_agent_core/lib/src/information/`
- `packages/novel_agent_core/lib/src/tools/domain/`
- `packages/novel_agent_adapters/lib/src/workflow/`
- `packages/novel_agent_adapters/lib/src/runtime/`
- `packages/novel_agent_adapters/lib/src/tools/`
- `apps/novel_agent_app/lib/features/long_task_station/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/project_assets/`
- `apps/novel_agent_cli/lib/commands/workflow/`
- `apps/novel_agent_app/tool/`

---

## 1. 这份文档解决什么

这份文档解决的是当前项目里最关键、也最容易反复返工的一条主线：

```text
把已经存在但尚未真正闭环的 long-task runtime、supervisor、review、repair、
chapter delivery、shared execution discipline、information evidence、continuity claims
收束成一条统一、稳定、可恢复、可诊断的正式执行主链
```

它不是单一功能点任务清单，也不是某个专题分析的机械拆条。

它要覆盖的终局目标包括：

1. 长任务不再“看起来有 supervisor，实际上坏交付照样滑过去”。
2. 普通项目和长任务共用同一审核合同与执行者选择规则，只在触发权和调度强度上不同。
3. `watchdog / supervisor / review / repair / checkpoint` 分层稳定，不再互相越权。
4. 字数、表达限制、信息纪律、章节交付等共享约束走同一执行主线，但不互相吞并。
5. 特殊题材测试不再继续污染核心。
6. probe 只消费 production 同源合同，不再成为第二套业务中心。
7. GUI / CLI 最终只消费稳定合同，不替底层补缺口。

---

## 2. 与旧文档的关系

### 2.1 不推翻已经做过的专题主线

这份文档不是为了重做：

1. `ECP` 表达限制执行策略主线。
2. `IED` 信息证据纪律闭环主线。
3. `PIS` 信息基座主线。
4. 开放 narrative state / toolcall runtime 主线。

这些主线里已经完成的内容，本文件默认：

1. 优先复用。
2. 验收完成度。
3. 只补共享主链里真正还未打通的那一层。

### 2.2 这是一份总收口文档，不是平行新 runtime

本文件不允许新增：

1. 第二套 long-task runtime。
2. 第二套 review contract。
3. 第二套 probe 判定逻辑。
4. 第二套 station summary / stop reason 体系。

正确做法是：

1. 统一合同。
2. 统一 runtime truth。
3. 统一 failure taxonomy。
4. 再让普通项目、长任务、拆书 follow-up、解说 follow-up 分别消费。

### 2.3 与发布收口文档的关系

发布收口主线关注整体 GUI、可用性、产品化边界。

本主线只处理：

1. 与 long task / supervisor / review / recovery 有关的必要 GUI / CLI 收口。
2. 只在稳定合同完成后再接 UI。
3. 不把 UI 当成临时业务判断中心。

---

## 3. 已有实现去重审计

### 3.1 已有稳定基础，不重做

以下方向已经有明确基础，不允许另起平行实现：

1. `continuity` 基础模型与 runtime resolver。
2. `chapter delivery` 相关合同与 recovery 基础。
3. `tool round evidence` 相关 transcript / write intent / evidence。
4. long-task run registry / heartbeat / supervisor 基础骨架。
5. `ExpressionConstraintProfile / Binding / ExecutionPolicy` 主线已有雏形。
6. information contracts / request / gateway / import / projection / activation 已有基座。
7. 长任务 station / workbench / runtime summary 已有投影入口。
8. 多条 focused tests、mock regression 和 gated probe 框架已存在。

### 3.2 已有但仍是半闭环

以下部分已经“有东西”，但还不能算真正完成：

1. failure taxonomy 还不够稳定，stop reason 仍容易混。
2. review lane 与 repair lane 的合同化程度不够。
3. 普通项目与长任务的审核触发权边界刚刚分析清楚，尚未正式实现。
4. 长任务里坏交付还未必总能进入正式 `retry / repair / paused`。
5. 表达限制、信息纪律、字数纪律虽然有结构化摘要，但未必总能改变后续调度。
6. continuity 方向仍残留 `special_mechanic` 语义污染与 legacy 命名压力。
7. probe 仍有部分诊断是“事后猜”，而不是消费同源 production truth。
8. GUI / CLI 能显示部分结果，但还没有建立在真正统一的 runtime truth 上。

### 3.3 真正还缺的层

后续真正要补的是：

1. 统一 failure taxonomy。
2. 审核触发权 / 执行权 / 调度权的正式合同化。
3. review contract / review artifact / disposition 统一口径。
4. repair lane 正式合同与恢复关系。
5. delivery failure -> recovery / pause / manual attention 闭环。
6. watchdog 与 supervisor 的职责硬拆分。
7. supervisor 对 shared execution discipline 的统一消费。
8. continuity claims 与 reviewer 复核的正式入口。
9. 普通项目、长任务、拆书 follow-up 的共享接线。
10. probe 到 production truth 的彻底收口。
11. 最后才是 GUI / CLI 与发布前验收。

---

## 4. 本轮冻结的架构边界

1. `watchdog` 只做运行健康与队列/活性纠偏，不做文学语义判断。
2. `supervisor` 只做非 LLM 控制面，不直接读正文裁判文学效果。
3. `reviewer` 不拥有后续调度权，不直接推进任务，也不直接改正文。
4. `writer` 负责正文与必要状态提交，不自动拥有审核调度权。
5. 普通项目的语义审核触发主要由智能体组策略决定。
6. 长任务的语义审核触发必须主要由 runtime / supervisor policy 主动调度。
7. 审核执行者选择统一为：组内 reviewer 优先，没有则主智能体 self-review。
8. 共享执行约束只统一 bridge / summary / risk policy / supervisor 输入位，不混成一个巨物。
9. 信息纪律不是表达限制，不进 expression profile。
10. 字数纪律不是文学裁判，但可以进入 hard gate / tolerance / repair。
11. 快穿、死亡回归、多世界、历史穿越等只继续作为 probe 输入，不进入核心分支。
12. probe 不定义 production 真相。
13. GUI / CLI 只消费稳定合同，不在 widget / command 中硬写业务规则。
14. 不允许再造一套“更方便”的临时 runtime 或 probe-side fallback 业务中心。

---

## 5. 目标终态

完成本主线后，应达到以下终态：

1. 普通项目与长任务共用同一 `review contract / reviewer selection / repair contract / summary contract`。
2. 普通项目与长任务真正不同的，只剩审核触发权和调度强度。
3. 长任务每章、每 checkpoint、每次恢复都有正式 runtime record、artifact、summary、failure taxonomy。
4. 空正文、只标题、错路径、缺 delivery evidence 等坏交付会被及时拦住，不再主要依赖 probe 事后翻目录。
5. 表达限制、字数、信息纪律都能进入同一 supervisor 输入体系，并在合适时机真正改变调度。
6. continuity 的正式承接方式转向 `claims + review findings`，而不是继续堆题材关键词判断。
7. `watchdog` 与 `supervisor` 的职责边界清晰，运行时表现稳定。
8. probe 只驱动 production chain，并读取 production truth 报告技术失败、等待用户、内容失败、自然完成等不同结局。
9. GUI / CLI 用户回来后能看懂：为什么停、停在哪里、下一步怎么办。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `26` 个 session。

这样设计的原因是：

1. 先用 `LTSR-01` 做最终基线审计，避免重做已完成主线。
2. `LTSR-02` 到 `LTSR-06` 先收口 core contracts：failure taxonomy、review、repair、delivery、trigger authority。
3. `LTSR-07` 到 `LTSR-10` 收口 runtime / supervisor / checkpoint / recovery 主链。
4. `LTSR-11` 到 `LTSR-13` 把字数、表达限制、信息纪律和 continuity claims 接进共享主链。
5. `LTSR-14` 到 `LTSR-18` 分别接普通项目、长任务、多智能体、拆书 follow-up、projection。
6. `LTSR-19` 到 `LTSR-22` 用 probe、mock regression、短链 real probe 做生产合同验收。
7. `LTSR-23` 到 `LTSR-25` 最后才做 GUI / CLI 最小对接。
8. `LTSR-26` 做总收口、文档、agent 约束、handoff、发布前专项分析补位。

每轮都必须控制在一次会话可完成的范围内，主要逻辑量约 2000 行以内；但过小的任务已尽量按职责合并，避免无意义碎片化。

---

## 7. 全局执行规则

所有 session 均必须遵守：

1. 先读本文档、主分析文档、`agent.md` 和当前 session 必读文件。
2. 只做当前 session，不开启下一任务。
3. 优先复用现有 service / contract / repository / runtime hook。
4. 先 core / domain，再 adapters / runtime，再 workflow 接线，再 projection / probe，最后 GUI / CLI。
5. 不让单一文件、widget、command、probe、fallback 或 runtime facade 变成新业务中心。
6. focused test / contract test 应跟随 core 和 adapter 任务落地。
7. mock regression 要消费 production 同源合同，不增私有业务判断。
8. real probe 必须 gated，不默认消耗额度，不删除产物。
9. 不写死任何测试题材或用户示例。
10. 不把 dirty worktree 里的无关内容顺手重构或回滚。

---

## 8. 设计目标覆盖表

| 目标 | 覆盖 session |
| --- | --- |
| 最终基线审计与 done/not-done ledger | LTSR-01 |
| 正式 failure taxonomy / stop reason | LTSR-02、LTSR-18 |
| 审核触发权 / 执行权 / 调度权拆分 | LTSR-03、LTSR-08、LTSR-14、LTSR-15 |
| 正式 review contract / artifact | LTSR-04 |
| 正式 repair lane | LTSR-05、LTSR-10 |
| delivery failure 闭环 | LTSR-06、LTSR-10 |
| watchdog / supervisor 硬拆分 | LTSR-07 |
| checkpoint cadence / risk tightening | LTSR-08、LTSR-09 |
| 长任务主动调度审核 | LTSR-09、LTSR-15 |
| 普通项目由智能体组策略触发审核 | LTSR-14 |
| reviewer selection policy 共享 | LTSR-03、LTSR-16 |
| 字数纪律进入共享主链 | LTSR-11 |
| 表达限制进入共享主链 | LTSR-12 |
| 信息纪律进入共享主链 | LTSR-13 |
| continuity claims / legacy special_mechanic 降级 | LTSR-17 |
| 普通项目 / 长任务 / 拆书 follow-up 共享接线 | LTSR-14、LTSR-15、LTSR-17 |
| probe 只消费 production truth | LTSR-19、LTSR-20、LTSR-21 |
| GUI / CLI 最后消费稳定合同 | LTSR-23、LTSR-24、LTSR-25 |
| 总文档 / agent 约束 / handoff 收口 | LTSR-26 |

---

## 9. Session 顺序

### LTSR-01：最终基线审计与目标映射

本轮目标：在当前工作区基础上做一次最终去重审计，明确哪些能力已经完成、哪些只是半成品、哪些是本主线必须补的缺口，并将本文档中的 26 轮与代码落点建立一一映射。

层级归属：Documentation / Architecture audit。

必读文件：

- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- `docs/expression-constraint-execution-policy-session-order-2026-06-06.md`
- `docs/information-evidence-discipline-session-order-2026-06-05.md`

必须完成：

1. 新增或更新一份短审计文档，列出当前稳定基础、半成品、必须补的层。
2. 把已有 ECP / IED / continuity 主线中可直接复用的点明确标记。
3. 为后续 26 轮建立代码锚点映射表。
4. 回填本文档完成记录占位。

本轮不要做：

1. 不改业务代码。
2. 不跑真实 probe。
3. 不顺手开下一轮。

验收标准：

1. 能明确回答“哪些不用重做，哪些必须做”。
2. 不再存在把已完成主线误拆成新任务的情况。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-01，只做最终基线审计与目标映射。先读主分析文档、ECP/IED 任务顺序文档和 `agent.md`。输出一份短审计文档，明确当前稳定基础、半成品和必须补的缺口，并把后续 session 与代码锚点对齐。不要改业务代码，不跑真实 probe，不开启下一任务。注意解耦合、单一职责，不把审计写成新 backlog 杂记。
```

### LTSR-02：统一 failure taxonomy 与 stop reason 合同

本轮目标：正式收口长任务主线的 failure taxonomy、run stop reason 和用户可见的高层状态，不再只用零散字符串或单薄状态表达。

层级归属：Core / domain。

必读文件：

- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- `packages/novel_agent_core/lib/src/workflow/`
- `packages/novel_agent_core/lib/src/runtime/`（如存在）
- 现有 stop reason / run status 相关合同与测试

必须完成：

1. 定义统一的 failure taxonomy / stop reason / completion reason core contract。
2. 区分 `completed_naturally / budget_exhausted / technical_failure / delivery_failure / constraint_gate_pause / waiting_user / manual_attention / recovery_exhausted`。
3. 补 contract tests / codec / round-trip tests。
4. 保持旧字段兼容，不在本轮强推 GUI。

本轮不要做：

1. 不接 station UI。
2. 不改 probe。
3. 不顺手实现 recovery 算法。

验收标准：

1. core 层能稳定表达不同停止结局。
2. 后续 session 可以统一消费，而不是继续各自发明字符串。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-02，只做统一 failure taxonomy 与 stop reason core 合同。必须把自然完成、预算耗尽、技术失败、交付失败、约束暂停、等待用户、人工注意、恢复耗尽区分开，并补 focused contract tests。不要接 GUI/CLI，不改 probe，不顺手做 recovery 实现，不开启下一任务。注意合同清晰、兼容旧字段、避免单文件过重。
```

### LTSR-03：审核触发权、执行权、调度权与 reviewer selection policy

本轮目标：把审核层最容易混的三件事正式拆开，并建立共享的 reviewer 选择规则。

层级归属：Core / review / workflow policy。

必读文件：

- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
- 当前 agent group / workflow / review 相关合同

必须完成：

1. 定义审核触发权、执行权、调度权的正式 policy contract。
2. 定义共享 reviewer selection policy：
   - group reviewer 优先
   - critic/editor 次优先
   - primary writer self-review 回退
3. 为普通项目与长任务留下不同触发权入口，但保持合同统一。
4. 补 focused tests。

本轮不要做：

1. 不接 runtime。
2. 不做 GUI 配置。
3. 不写多智能体 runtime 细节。

验收标准：

1. 合同层能清楚表达“谁触发、谁执行、谁调度”。
2. reviewer selection 规则不再散落在 UI 或 workflow if/else 中。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-03，只做审核触发权/执行权/调度权拆分与 reviewer selection policy。需要建立共享合同，让普通项目和长任务只在触发权上不同，执行者选择统一走 reviewer -> critic/editor -> writer self-review。不要接 runtime，不做 GUI，不做多智能体具体调度，不开启下一任务。补 focused tests，保持解耦和单一职责。
```

### LTSR-04：正式 review contract 与 review artifact 合同

本轮目标：把 review 从提示投影和零散摘要提升为正式 contract / artifact，能承接普通项目、长任务和 follow-up 模式。

层级归属：Core / review。

必读文件：

- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
- 现有 `review projection` / checkpoint review / revision 相关实现

必须完成：

1. 定义统一 review contract：
   - reviewer id / role
   - basis
   - findings
   - risk level
   - recommended disposition
   - repair brief
   - evidence paths
2. 定义 review artifact / summary 基础模型。
3. 保证非表达限制场景也能使用同一 contract。
4. 补 contract tests。

本轮不要做：

1. 不接 GUI。
2. 不接 probe。
3. 不实现具体 reviewer prompt 文本大改。

验收标准：

1. review 不再只能作为投影文本存在。
2. 后续 repair / supervisor / station summary 都能消费同一结构。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-04，只做正式 review contract 与 review artifact 合同。要求 review 结果能被普通项目、长任务、拆书 follow-up 共用，至少包含 reviewer 身份、basis、findings、risk level、recommended disposition、repair brief 和 evidence paths。不要接 GUI，不改 probe，不开启下一任务。补 focused contract tests，避免把 review 写死成表达限制特例。
```

### LTSR-05：repair lane 合同与 review -> repair handoff

本轮目标：把 repair 从“某些地方顺手返修”提升为正式 lane 合同，明确何时必须先 repair、何时只需 note / adjust_next。

层级归属：Core / workflow / revision。

必读文件：

- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- 现有 revision / repair / checkpoint action 相关实现

必须完成：

1. 定义 repair request / repair task / repair outcome 合同。
2. 明确 review disposition 到 repair 的转换规则。
3. 建立“已有必须先完成的 repair 时阻塞主链”的统一语义。
4. 补 focused tests。

本轮不要做：

1. 不接队列实现细节。
2. 不做 station UI。
3. 不改 probe。

验收标准：

1. repair 成为正式对象而不是临时提示。
2. 后续 supervisor 能区分 note / adjust / repair / pause。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-05，只做 repair lane core 合同与 review->repair handoff。需要正式表达 repair request、repair task、repair outcome，并明确哪些 disposition 会阻塞主链。不要接队列细节，不做 GUI，不改 probe，不开启下一任务。补 focused tests，保持合同清晰、职责分离。
```

### LTSR-06：chapter delivery failure 合同与坏交付拦截

本轮目标：把空正文、只标题、错路径、落盘缺失、缺 sidecar 等高确定性坏交付正式纳入统一 delivery failure 合同和 gate。

层级归属：Core / tools domain / workflow。

必读文件：

- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- `packages/novel_agent_core/lib/src/tools/domain/submit_chapter_delivery_handler.dart`
- `packages/novel_agent_core/lib/src/project/chapter_output_path_policy_service.dart`
- 相关 delivery tests

必须完成：

1. 扩展或收口 delivery evaluation / failure contract。
2. 把空正文、标题轮、路径错误、未落盘、缺 sidecar 区分开。
3. 为后续 recovery / pause 留下统一输入位。
4. 补 focused tests，并覆盖文件名/路径/标题口径边界。

本轮不要做：

1. 不直接做 station summary。
2. 不做 recovery 策略。
3. 不跑真实 probe。

验收标准：

1. 坏交付可被 production contract 明确识别。
2. 不再依赖 probe 事后翻目录才能发现。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-06，只做 chapter delivery failure 合同与坏交付拦截。要把空正文、只标题、错路径、未落盘、缺 sidecar 等正式区分出来，并补 focused tests，尤其覆盖路径/标题口径边界。不要做 station UI，不做 recovery 策略，不跑真实 probe，不开启下一任务。注意复用现有 delivery 与 path policy 服务。
```

### LTSR-07：watchdog 与 supervisor 职责硬拆分

本轮目标：把 watchdog 机械职责与 supervisor 高层控制职责正式拆开，避免两者继续混杂。

层级归属：Core / adapters runtime boundary。

必读文件：

- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- 现有 heartbeat / watchdog / supervisor 策略相关实现
- `references/Ai-Novel-main/backend/app/services/project_task_runtime_service.py`

必须完成：

1. 明确 watchdog 只处理：
   - heartbeat timeout
   - stale detection
   - orphan reconcile
   - runtime health fix
2. 明确 supervisor 只消费结构结果做后续调度。
3. 整理现有实现中的职责污染点，完成最小 contract / service 拆分。
4. 补 focused tests。

本轮不要做：

1. 不改 GUI。
2. 不实现 checkpoint cadence。
3. 不做 review 逻辑。

验收标准：

1. 能清楚回答某个行为属于 watchdog 还是 supervisor。
2. 不再让 watchdog 读正文，不再让 supervisor 兼任 reviewer。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-07，只做 watchdog 与 supervisor 的职责硬拆分。要求 watchdog 仅保留 heartbeat/stale/orphan/runtime health，supervisor 只消费结构结果做调度。不要改 GUI，不做 checkpoint cadence，不做 review 细节，不开启下一任务。补 focused tests，避免膨胀单一 runtime service。
```

### LTSR-08：supervisor 输入包与调度决策合同

本轮目标：定义 supervisor 统一消费的输入包，把 delivery / review / repair / information / expression / length 等结构结果合并成正式决策输入。

层级归属：Core / workflow / supervisor policy。

必读文件：

- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- `packages/novel_agent_core/lib/src/workflow/narrative_supervisor_risk_policy_service.dart`
- 相关 summary / result contracts

必须完成：

1. 定义 supervisor input bundle / decision contract。
2. 明确支持的调度动作：
   - continue
   - remind
   - adjust_next
   - repair
   - pause
   - waiting_user
   - manual_attention
3. 不让各条子链继续直接改写 stop reason。
4. 补 focused tests。

本轮不要做：

1. 不接 long-task runtime。
2. 不接 station UI。
3. 不开 probe。

验收标准：

1. supervisor 的决策不再散落在多处 if/else。
2. 后续所有 discipline 和 review 都能接同一输入包。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-08，只做 supervisor 输入包与调度决策合同。需要把 delivery/review/repair/information/expression/length 等结构结果统一成可消费 bundle，并限定调度动作集合。不要接 runtime、不做 GUI、不跑 probe、不开启下一任务。补 focused tests，避免让 stop reason 到处被直接改写。
```

### LTSR-09：checkpoint cadence 与动态风险收紧策略

本轮目标：正式定义 checkpoint cadence、batch 收紧和连续风险升级规则，不再把“每几章 checkpoint”写死在零散逻辑里。

层级归属：Core / supervisor strategy。

必读文件：

- 主分析文档相关章节
- 现有 checkpoint review / long-task batching / station summary 相关代码

必须完成：

1. 定义 checkpoint cadence policy。
2. 支持低风险项目更长 batch、高风险项目更短 batch、连续 drift 自动收紧。
3. 让 cadence policy 只消费结构化风险，不读正文。
4. 补 focused tests。

本轮不要做：

1. 不接 GUI 设置。
2. 不做真实 probe。
3. 不顺手改 review contract。

验收标准：

1. checkpoint 频率可被策略解释。
2. 连续风险升高时能明确收紧，而不是继续盲跑。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-09，只做 checkpoint cadence 与动态风险收紧策略。要求按结构化风险决定 batch 长短和 checkpoint 节奏，不读正文，不做 GUI 设置，不跑真实 probe，不开启下一任务。补 focused tests，保持策略独立、文件不过重。
```

### LTSR-10：recovery / retry / requeue / manual attention 状态机

本轮目标：把 recovery 主链正式化，让 delivery failure、repair required、technical failure、waiting_user 等都能进入统一恢复状态机。

层级归属：Core / adapters runtime。

必读文件：

- 主分析文档恢复相关章节
- 现有 long-task runtime / queue / retry / pause 代码

必须完成：

1. 定义 recovery state / retry budget / exhausted disposition。
2. 区分自动 retry、repair-before-continue、pause、manual attention、waiting_user。
3. 接入前面已定义的 failure taxonomy 和 repair contract。
4. 补 focused tests。

本轮不要做：

1. 不接 GUI。
2. 不写 probe 脚本。
3. 不顺手改 station summary。

验收标准：

1. 长任务中断后不再只能 failed / running 二选一。
2. 各类恢复动作有正式、可测试的状态转换。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-10，只做 recovery/retry/requeue/manual attention 状态机。必须接入前面定义的 failure taxonomy、delivery failure 和 repair contract，明确自动 retry、repair-before-continue、pause、waiting_user、manual attention 的转换。不要做 GUI，不写 probe，不开启下一任务。补 focused tests，保持 runtime 状态机清晰。
```

### LTSR-11：字数纪律接入统一主链

本轮目标：把字数从“目标提示 + 局部评价”收口成统一 shared execution discipline 输入，包含硬 gate 与审核容忍两层。

层级归属：Core / workflow / review gate。

必读文件：

- `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`
- `docs/expression-constraint-execution-policy-analysis-2026-06-06.md`
- 现有 `ChapterLengthProfile` 相关实现

必须完成：

1. 明确硬限制 / 审核容忍 / 严重失控阈值的统一摘要。
2. 接入 supervisor input bundle。
3. 区分轻微偏差不返修、严重越界必须 repair/pause。
4. 补 focused tests。

本轮不要做：

1. 不改 GUI 文案。
2. 不顺手改表达限制策略。
3. 不跑真实 probe。

验收标准：

1. 字数纪律能正式影响后续调度。
2. 不再只有“超了就算问题”或“完全不管”两种极端。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-11，只做字数纪律接入统一主链。要把硬限制、审核容忍和严重失控阈值结构化，并接入 supervisor input bundle。不要改 GUI，不改表达限制策略，不跑真实 probe，不开启下一任务。补 focused tests，注意共享合同、不要把字数写成文学裁判。
```

### LTSR-12：表达限制接入统一审核与调度主链

本轮目标：在 ECP 已有基础上，把表达限制真正接入共享 review / supervisor 主链，而不是只停留在注入与局部摘要。

层级归属：Core / workflow / review integration。

必读文件：

- `docs/expression-constraint-execution-policy-session-order-2026-06-06.md`
- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
- 现有 ECP 实现和测试

必须完成：

1. 确认 ECP 合同接入统一 review / disposition / supervisor input。
2. disabled / adaptive / force 与统一调度动作打通。
3. 保持程序不直接改正文，review 只输出 findings。
4. 补 focused integration tests。

本轮不要做：

1. 不重做 ECP 核心合同。
2. 不写新的表达限制特判。
3. 不改 GUI。

验收标准：

1. 表达限制不再是旁路特例。
2. review 结果能真正影响 repair / pause / adjust_next。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-12，只做表达限制接入统一审核与调度主链。要求复用现有 ECP 合同，把 disabled/adaptive/force 的结果接进统一 review/disposition/supervisor input，不程序化改正文，不新增特判。不要改 GUI，不重做 ECP 核心，不开启下一任务。补 focused integration tests。
```

### LTSR-13：信息纪律接入统一审核与调度主链

本轮目标：在 IED/PIS 已有基础上，把 information evidence 真正接到统一 review / supervisor / stop reason 体系中。

层级归属：Core / adapters / workflow integration。

必读文件：

- `docs/information-evidence-discipline-session-order-2026-06-05.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- 现有 information evidence gate 实现与测试

必须完成：

1. 复核并补齐 information evidence 到统一 supervisor input 的接线。
2. 让 `pending research / awaiting confirmation / source insufficient / external fact unverified` 在长任务主链里表现为正式结果，而不是旁路备注。
3. 保持信息纪律不被表达限制吞并。
4. 补 focused integration tests。

本轮不要做：

1. 不重做 PIS/IED 已完成功能。
2. 不改 GUI 设置。
3. 不跑真实联网探针。

验收标准：

1. 信息纪律能正式改变后续调度和 stop reason。
2. 普通项目、长任务、拆书 follow-up 使用同一口径。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-13，只做信息纪律接入统一审核与调度主链。需要复用 IED/PIS 已有成果，让 pending research、awaiting confirmation、source insufficient、external fact unverified 正式进入 supervisor input 和 stop reason 体系。不要重做 PIS/IED，不改 GUI 设置，不跑真实联网探针，不开启下一任务。补 focused integration tests。
```

### LTSR-14：普通项目工作流接线

本轮目标：让普通项目正式接入共享 review contract，但保持语义审核触发主要由智能体组策略决定。

层级归属：Workflow / app-independent runtime。

必读文件：

- 主分析文档审核触发权章节
- 普通项目 runtime / draft / conversation workflow 相关实现

必须完成：

1. 普通项目路径接入共享 review / repair / summary 合同。
2. 明确程序只强制客观 gate 与硬失败拦截。
3. 语义审核触发走智能体组策略入口，不写死“每章必审”。
4. 补 focused tests。

本轮不要做：

1. 不接 long-task runtime。
2. 不做 GUI 面板。
3. 不顺手改智能体组编辑器。

验收标准：

1. 普通项目能走同一审核合同。
2. 但不会被程序硬插成长任务式全编排。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-14，只做普通项目工作流接线。要求普通项目复用共享 review/repair/summary 合同，但语义审核触发主要由智能体组策略决定，程序只强制客观 gate 与硬失败拦截。不要接 long-task runtime，不做 GUI，不改智能体组编辑器，不开启下一任务。补 focused tests，保持普通项目节奏灵活。
```

### LTSR-15：长任务工作流接线

本轮目标：让长任务真正进入“程序主动调度审核”的工作流，而不是继续依赖 writer 临场自觉。

层级归属：Workflow / long-task runtime。

必读文件：

- 主分析文档长任务审核章节
- 现有 long-task workflow / transaction / checkpoint 相关实现

必须完成：

1. 长任务路径接入共享 review / repair / summary 合同。
2. 每章结束、checkpoint、风险升高时由 runtime / supervisor policy 主动决定是否触发 review。
3. 审核结果达到硬阈值时能改写后续调度。
4. 补 focused tests。

本轮不要做：

1. 不做 GUI。
2. 不改 probe。
3. 不加题材特例。

验收标准：

1. 长任务审核触发不再依赖 writer 临场决定。
2. review 真正成为主链一等输入。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-15，只做长任务工作流接线。要求长任务在每章结束、checkpoint、风险升高时由 runtime/supervisor policy 主动调度 review，并让 review 结果真正改写后续调度。不要做 GUI，不改 probe，不加题材特例，不开启下一任务。补 focused tests，注意复用共享合同。
```

### LTSR-16：多智能体 reviewer dispatch 接线

本轮目标：把 reviewer selection policy 真正接到多智能体运行链中，确保有 reviewer 用 reviewer，没有 reviewer 才回退到主智能体。

层级归属：Workflow / multi-agent orchestration。

必读文件：

- 主分析文档多智能体章节
- agent group / delegation / orchestration 相关实现

必须完成：

1. 接入 reviewer selection policy。
2. 保持子智能体独立上下文，只拿必要摘要。
3. 保持 reviewer 不拥有调度权。
4. 补 focused tests。

本轮不要做：

1. 不把多智能体铺满所有步骤。
2. 不改 GUI 配置页面。
3. 不顺手重写整个 agent group 系统。

验收标准：

1. reviewer dispatch 可预测、可测试。
2. 子智能体不与主智能体隐藏上下文混成一团。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-16，只做多智能体 reviewer dispatch 接线。要求正式接入 reviewer selection policy：有 reviewer/critic/editor 就优先用，没有再回退主智能体 self-review，并保持 reviewer 独立上下文、无调度权。不要改 GUI，不重写 agent group 全系统，不开启下一任务。补 focused tests，避免把多智能体铺满所有步骤。
```

### LTSR-17：continuity claims 与 legacy special_mechanic 降级收口

本轮目标：把 continuity 主线进一步收口到 `claims + review findings`，同时把 `special_mechanic` 相关遗留语义继续降级到兼容层。

层级归属：Core / continuity / workflow。

必读文件：

- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- 主分析文档连续性章节
- 现有 continuity / special mechanic 相关实现

必须完成：

1. 定义或补稳 writer claims / reviewer claims review 的正式入口。
2. 让 continuity reviewer 能消费 claims 和正文，而不是题材关键词。
3. 收口 `special_mechanic` 相关 naming / failure context，使其退回兼容层或 smoke check。
4. 补 focused tests。

本轮不要做：

1. 不做大规模命名清洗到处改。
2. 不新增题材分支。
3. 不跑真实特殊题材大探针。

验收标准：

1. continuity 主线更加中性，不再继续向题材 if/else 膨胀。
2. claims 成为后续 reviewer / supervisor 可消费的正式结构。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-17，只做 continuity claims 与 legacy special_mechanic 降级收口。要求建立 writer/reviewer claims 正式入口，让 continuity 复核消费 claims 与正文而非题材关键词，并把 special_mechanic 进一步退回兼容层。不要做大规模命名重构，不新增题材分支，不跑真实特殊题材大探针，不开启下一任务。补 focused tests。
```

### LTSR-18：runtime projection / station detail / stop diagnosis 统一化

本轮目标：把 run center、station detail、summary projection 和 stop diagnosis 收口到统一 runtime truth 上。

层级归属：Adapters / projection / runtime diagnostics。

必读文件：

- 主分析文档 failure taxonomy 与 runtime visibility 章节
- 现有 station detail / run summary / projection 相关实现

必须完成：

1. 让 projection 消费统一 failure taxonomy、review summary、repair state、information summary。
2. 区分自然完成、预算停止、技术失败、约束暂停、等待用户、人工注意。
3. 不再把某条子链私有状态直接展示给用户当最终原因。
4. 补 focused tests。

本轮不要做：

1. 不改 GUI 视觉。
2. 不写 probe 新脚本。
3. 不顺手扩字段到处透传。

验收标准：

1. station / run summary 能准确表达任务为什么停。
2. 普通项目与长任务的高层诊断口径统一。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-18，只做 runtime projection、station detail 和 stop diagnosis 统一化。要求 projection 消费统一 failure taxonomy、review summary、repair state、information summary，并能清楚区分自然完成、预算停止、技术失败、约束暂停、等待用户、人工注意。不要改 GUI 视觉，不写 probe 新脚本，不开启下一任务。补 focused tests，避免私有状态直接上屏。
```

### LTSR-19：probe 合同收口到 production truth

本轮目标：清理 probe 侧仍然存在的私有判定，让 probe 只读取 production contracts。

层级归属：Probe / regression architecture。

必读文件：

- 主分析文档 probe 章节
- `apps/novel_agent_app/tool/probe_support.dart`
- 现有 real/mock probe 脚本与报告格式

必须完成：

1. 审计现有 probe 私有判定点。
2. 把报告输入切换到 production delivery/review/summary/stop reason。
3. 保留 probe 分类，但不再自建业务真相。
4. 补 probe support tests。

本轮不要做：

1. 不跑真实 probe。
2. 不改 runtime 业务逻辑。
3. 不做 GUI。

验收标准：

1. probe 报告结论可回溯到 production truth。
2. 不再出现“probe 看起来通过，但真实链路没修好”的假收敛。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-19，只做 probe 合同收口到 production truth。需要审计 probe 私有判定点，并把报告输入切换到统一 delivery/review/summary/stop reason 合同。不要跑真实 probe，不改 runtime 业务逻辑，不做 GUI，不开启下一任务。补 probe support tests，避免 probe 成为第二套业务中心。
```

### LTSR-20：mock regression suite 覆盖主链

本轮目标：建立一套围绕 production contracts 的 mock regression，覆盖普通项目、长任务、repair、waiting_user、manual_attention、delivery failure 等主要场景。

层级归属：Probe / regression。

必读文件：

- 主分析文档验收章节
- 现有 mock regression 脚本与相关 tests

必须完成：

1. 设计覆盖矩阵。
2. 至少覆盖：
   - 普通项目 self-review
   - 长任务主动 review
   - reviewer dispatch
   - delivery failure
   - repair required
   - waiting_user
   - manual_attention
   - natural completion
3. 输出结构化报告。
4. 补 tests / mock harness。

本轮不要做：

1. 不跑真实 provider。
2. 不改 GUI。
3. 不新增业务特判。

验收标准：

1. 主链大部分行为可在 mock 层稳定回归。
2. 报告区分技术/等待/内容/自然完成，不只写 pass/fail。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-20，只做 mock regression suite 覆盖主链。要求围绕 production contracts 覆盖普通项目、长任务、review/repair、delivery failure、waiting_user、manual_attention、natural completion 等场景，并输出结构化报告。不要跑真实 provider，不改 GUI，不新增业务特判，不开启下一任务。补 harness/tests，保持回归矩阵清晰。
```

### LTSR-21：短链 gated real probe 验收

本轮目标：在小预算、短链条件下做 production 真实验收，验证主链不是只在 mock 中好看。

层级归属：Probe / real validation。

必读文件：

- 主分析文档
- 当前 real probe gate 约束与本地配置读取逻辑

必须完成：

1. gated real probe：
   - 普通项目 2-3 章
   - 长任务 3-5 步
   - 至少 1 个 waiting/repair/summary 可见场景
2. 保留产物与报告。
3. 报告明确区分：
   - success
   - technical failure
   - waiting_user
   - delivery failure
   - constraint pause
4. 不删除产物。

本轮不要做：

1. 不跑 200 章预算。
2. 不顺手修新问题以外的 unrelated 内容。
3. 不开启下一任务。

验收标准：

1. production truth 与 probe 报告口径一致。
2. 至少能验证一条普通项目链和一条长任务短链。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-21，只做短链 gated real probe 验收。必须显式开闸，使用本地配置，不硬编码 key；验证普通项目 2-3 章与长任务 3-5 步，并保留全部产物和报告，区分 success、technical failure、waiting_user、delivery failure、constraint pause。不要跑 200 章预算，不开启下一任务。若发现问题，只记录并最小归因，不顺手展开下一轮实现。
```

### LTSR-22：问题回插与短回归补缝

本轮目标：针对 LTSR-21 暴露出的真实问题做最小闭环修复，并补回归，不在这一轮扩散成新主线。

层级归属：Core / adapters / workflow，按问题归属选最小层。

必读文件：

- LTSR-21 的报告与产物
- 相关主链合同和实现

必须完成：

1. 只修 LTSR-21 暴露的真实主链问题。
2. 每修一类问题补一个 focused regression。
3. 更新报告中的已修/未修状态。

本轮不要做：

1. 不开启与当前问题无关的新架构扩展。
2. 不顺手美化 GUI。
3. 不继续放大 real probe 预算。

验收标准：

1. 暴露的问题被最小而自然地收口。
2. 不产生新的补丁墙。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-22，只做对 LTSR-21 真实问题的最小回插修复与短回归补缝。严格按问题归属修改最小层，每修一类补一条 focused regression。不要扩成新主线，不美化 GUI，不扩大 real probe 预算，不开启下一任务。注意修协议断裂，不堆补丁。
```

### LTSR-23：GUI 运行现场读路径

本轮目标：让 GUI 的 long task station / workbench 真正读取统一 runtime truth，而不是猜测或拼凑。

层级归属：App / GUI read-side。

必读文件：

- 现有 long task station / workbench view model / view data 服务
- 主分析文档 GUI 相关章节

必须完成：

1. GUI 读取统一 failure taxonomy、review summary、repair state、pending info、checkpoint summary。
2. 不暴露内部 payload。
3. 用人话显示“为什么停、卡在哪、下一步是什么”。
4. 补 view-model tests。

本轮不要做：

1. 不改视觉主题。
2. 不加复杂设置入口。
3. 不在 widget 中写业务规则。

验收标准：

1. GUI 能靠稳定合同解释任务现场。
2. 不再只能靠目录和日志猜状态。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-23，只做 GUI 运行现场读路径。让 long task station/workbench 读取统一 failure taxonomy、review summary、repair state、pending info、checkpoint summary，用人话解释任务现场。不要改视觉主题，不加复杂设置入口，不在 widget 中写业务规则，不开启下一任务。补 view-model tests。
```

### LTSR-24：GUI 最小控制面与人工动作入口

本轮目标：在 GUI 层只增加必要、自然的控制面，如等待确认、恢复、人工注意和查看 review/checkpoint 结果，不新增难懂的高级术语面板。

层级归属：App / GUI actions。

必读文件：

- station / workbench / assets 相关 UI 与 view model
- 主分析文档产品化相关章节

必须完成：

1. 最小动作入口：
   - 确认/拒绝待确认事项
   - 恢复 / 重试
   - 打开相关 artifact / review / checkpoint
2. 文案自然，不暴露内部字段。
3. 补 widget / view-model tests。

本轮不要做：

1. 不设计复杂专家控制台。
2. 不把 review 策略字段全部暴露给普通用户。
3. 不补底层逻辑。

验收标准：

1. 用户能实际操作卡住的长任务。
2. 主界面不被高级术语淹没。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-24，只做 GUI 最小控制面与人工动作入口。需要支持确认/拒绝待确认事项、恢复/重试、打开相关 artifact/review/checkpoint，并保持文案自然，不暴露内部字段。不要做复杂专家控制台，不补底层逻辑，不开启下一任务。补 widget/view-model tests。
```

### LTSR-25：CLI 最小消费与操作入口

本轮目标：让 CLI 至少能读懂和操作统一长任务主链，但仍保持“只消费稳定合同”的边界。

层级归属：CLI。

必读文件：

- 现有 workflow CLI 命令
- 主分析文档 CLI 相关边界

必须完成：

1. CLI 能查看统一 stop reason / review summary / pending actions。
2. CLI 能做最小动作：
   - pause
   - resume
   - apply pending user action
   - open/print latest checkpoint summary
3. 补 command tests。

本轮不要做：

1. 不把 CLI 做成新的业务中心。
2. 不让 CLI 直接解析底层存储。
3. 不提前做 TUI。

验收标准：

1. CLI 可以作为无 GUI 场景下的最小可用控制面。
2. 所有信息仍来自统一 runtime truth。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-25，只做 CLI 最小消费与操作入口。要求 CLI 能查看统一 stop reason/review summary/pending actions，并支持 pause、resume、apply pending user action、查看最新 checkpoint summary。不要把 CLI 做成新业务中心，不直读底层存储，不做 TUI，不开启下一任务。补 command tests。
```

### LTSR-26：总收口、文档、agent 约束与最终 handoff

本轮目标：在主链完成后做最终文档和约束收口，确保后续继续开发不会重新长歪。

层级归属：Documentation / handoff / project constraints。

必读文件：

- 主分析文档
- 本任务顺序文档
- `agent.md`
- 本主线所有报告与探针结果

必须完成：

1. 更新或新增 handoff / release-readiness 小结。
2. 把这轮沉淀出的稳定性、review、supervisor、probe 约束补进 `agent.md` 合适位置。
3. 更新完成记录和剩余风险。
4. 明确下一阶段哪些是新的独立主线，哪些只是已完成主线的维护。

本轮不要做：

1. 不再做新业务功能。
2. 不顺手重构无关目录。
3. 不启动下一轮大探针。

验收标准：

1. 后续会话能明确知道当前主线已完成到什么程度。
2. 约束被写回项目级文档，避免以后回流到补丁式实现。

直接可用提示词：

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 执行 LTSR-26，只做总收口、文档、agent 约束与最终 handoff。需要更新 handoff/release-readiness 小结、把稳定性与 review/supervisor/probe 约束补进 `agent.md`，并回填本主线完成记录与剩余风险。不要做新业务功能，不重构无关目录，不启动下一轮大探针，不开启下一任务。
```

---

## 10. 总启动提示词

```text
根据 `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md` 继续下一步。每次只确认完成一个具体 session；如果上个会话停在某个 session 的一半，或出现了关联性错误，就先把那个 session 收口，不开启下一轮。你需要先读本文档、`docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`、相关专题分析文档和 `agent.md`，直接识别当前未完成的最早 session，并严格只做那一轮。必须遵守解耦合、单一职责、避免单文件过重、复用现有合同与 runtime hook、补 focused tests / contract tests 的要求。不要开启下一任务。
```

---

## 11. 完成记录占位

- `LTSR-01`：已完成（2026-06-06）。已补充审计文档 `docs/important/long-task-stability-supervisor-review-implementation-audit-2026-06-06.md`，并基于 `agent.md`、主综合分析文档、`ECP`/`IED` 顺序文档与 continuity 分析确认：当前仓库已具备可直接复用的长任务 runtime 身份/状态机/heartbeat/supervisor 骨架、章节交付与共享 `WritingExecutionResult`、表达限制执行策略、信息证据纪律、continuity claims/review/projection 基座；真正未收口的层集中在统一 failure taxonomy、共享 review contract、共享 repair lane、审核触发权/执行权/调度权拆分，以及 supervisor 统一输入包与 stop reason 正式合同。已同步建立 `LTSR-01` 到 `LTSR-26` 的代码锚点映射表，并明确后续不应重做 `ECP / IED / continuity / long-task runtime`，下一轮应直接进入 `LTSR-02`，只做统一 failure taxonomy 与 stop reason core 合同。
- `LTSR-02`：已完成（2026-06-06）。已新增纯 core 的统一停止结局合同 `LongTaskStopOutcome` 与 `LongTaskStopOutcomeResolverService`，正式区分 `completed_naturally / budget_exhausted / technical_failure / delivery_failure / constraint_gate_pause / waiting_user / manual_attention / recovery_exhausted` 八类结局，并保留 `legacy_stop_reason` 兼容旧字符串口径；同时已把该合同接入 `RunInstance` 与 `LongTaskWritingExecutionSignalService`，使共享 `WritingExecutionResult` 和全局长任务运行实例都能携带同源 `stop_outcome`，但本轮没有强推 GUI/CLI/probe 全量迁移。已补 focused contract tests：`packages/novel_agent_core/test/long_task_stop_outcome_resolver_service_test.dart` 覆盖 round-trip、legacy stop reason 归类、delivery failure、constraint gate pause、waiting user；`packages/novel_agent_adapters/test/local_long_task_run_registry_test.dart` 覆盖 `RunInstance` 持久化后 `stop_outcome` 不丢。验证已通过：`packages/novel_agent_core` 下 `dart analyze ...`、`dart test test/long_task_stop_outcome_resolver_service_test.dart test/writing_execution_result_contracts_test.dart test/long_task_run_state_machine_test.dart`；`packages/novel_agent_adapters` 下 `dart analyze ...`、`dart test test/local_long_task_run_registry_test.dart test/long_task_supervisor_test.dart`。下一轮应进入 `LTSR-03`，只做审核触发权 / 执行权 / 调度权拆分与 reviewer selection policy，不回退本轮统一 stop outcome core 合同。
- `LTSR-03`：已完成（2026-06-06）。已在 `packages/novel_agent_core` 新增纯 core 的审核权限合同 `ReviewAuthorityPolicy`，正式拆分 `trigger_authority / execution_authority / scheduling_authority`，并明确普通项目默认走 `agent_group_policy` 触发、长任务默认走 `runtime_supervisor_policy` 触发，而执行权与调度权保持共享，分别统一到 `reviewer_selection_policy` 与 `workflow_supervisor_policy`，从合同层落实“普通项目与长任务只在触发权上不同”。同时已新增 `ReviewerSelection` 与 `ReviewerSelectionService`，把共享 reviewer 选择规则正式收口为 `reviewer -> critic/editor -> primary writer self-review`，优先复用现有 `ResolvedAgentGroupProfile` / `ResolvedAgentGroupMemberProfile`，没有提前接 runtime、GUI 或多智能体具体 dispatch。已补 focused tests：`packages/novel_agent_core/test/review_authority_policy_test.dart` 覆盖普通项目/长任务只在触发权不同、codec unknown-field round-trip、非法 authority 校验；`packages/novel_agent_core/test/reviewer_selection_service_test.dart` 覆盖 group reviewer 优先、critic/editor 回退、writer self-review 回退与 unavailable 场景。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/review/review_authority_policy.dart lib/src/review/reviewer_selection.dart lib/src/review/reviewer_selection_service.dart lib/novel_agent_core.dart test/review_authority_policy_test.dart test/reviewer_selection_service_test.dart`，以及 `dart test test/review_authority_policy_test.dart test/reviewer_selection_service_test.dart`。下一轮应进入 `LTSR-04`，只做正式 review contract 与 review artifact 合同，不把本轮 reviewer policy 重新散回 workflow if/else。
- `LTSR-04`：已完成（2026-06-06）。已在 `packages/novel_agent_core` 新增共享的正式 review 合同与 artifact 基础模型，避免继续把审稿结果散落在弱结构 `review_report` 投影或 continuity 特化合同中。新增类型包括：`ReviewContract`、`ReviewReviewerRef`、`ReviewBasis`、`ReviewFindingContract`、`ReviewSummary`、`ReviewArtifact`、`ReviewSummaryBuilderService`，以及配套枚举目录 `ReviewRiskLevels / ReviewFindingSeverities / ReviewRecommendedDispositions` 与校验码目录 `ReviewContractValidationCodes`。其中共享合同已正式覆盖 reviewer 身份、basis、findings、risk level、recommended disposition、repair brief、evidence paths、summary、artifact path 等核心字段，并保持 open contract unknown-field round-trip，方便后续普通项目、长任务、拆书 follow-up 共同消费。为避免把 repair lane 提前揉进本轮，本次只在合同层要求：当 `recommended_disposition == repair` 时必须提供 `repair_brief`，但没有提前接 runtime、queue、GUI 或 probe。已补 focused contract tests：`packages/novel_agent_core/test/review_contract_models_test.dart` 覆盖共享 review contract round-trip、`repair` disposition 对 `repair_brief` 与 `evidence_paths` 的要求、summary builder 的 evidence 去重与 blocking finding 计数，以及 artifact 至少需要一个持久化路径。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/review/review_contract_catalog.dart lib/src/review/review_reviewer_ref.dart lib/src/review/review_basis.dart lib/src/review/review_finding_contract.dart lib/src/review/review_summary.dart lib/src/review/review_contract.dart lib/src/review/review_artifact.dart lib/src/review/review_summary_builder_service.dart lib/novel_agent_core.dart test/review_contract_models_test.dart`，以及 `dart test test/review_contract_models_test.dart`。下一轮应进入 `LTSR-05`，只做 repair lane 合同与 `review -> repair` handoff，不要把本轮共享 review contract 重新退回成弱结构 report 字段集合。
- `LTSR-05`：已完成（2026-06-06）。已在 `packages/novel_agent_core` 新增共享的 repair lane core 合同与 `review -> repair` handoff 规则，避免继续把 repair 混成零散的 `revision task`、`scheduled_repair` 或 queue 私有字段。新增类型包括：`RepairRequest`、`RepairTask`、`RepairOutcome`、`RepairHandoffDecision`、`RepairBlockingState`、`RepairLaneBlockingService`、`ReviewRepairHandoffService`，以及配套目录 `RepairTaskStatuses / RepairOutcomeStatuses / RepairHandoffActions / RepairContractValidationCodes`。其中 `ReviewRepairHandoffService` 已正式把共享 `ReviewContract` 的 `recommended_disposition` 收口为统一动作集合：`accept -> none`、`remind -> note_only`、`adjust_next -> adjust_next`、`repair -> create_blocking_repair`、`checkpoint_user -> waiting_user`、`manual_attention -> manual_attention`；只有 `repair` 才会物化出 `RepairRequest` 与阻塞型 `RepairTask`，从而保持 reviewer 只负责给结构化结论，repair lane 再决定是否生成正式修订任务。与此同时，`RepairLaneBlockingService` 已建立“已有必须先完成的 repair 时阻塞主链”的统一语义：阻塞型 repair 在 `queued / in_progress / waiting_user / failed / cancelled / note_only outcome` 等状态下都不会放行主链，只有显式 `RepairOutcome.completed` 才解除阻塞。为避免提前越界，本轮没有接队列实现细节、runtime、GUI 或 probe。已补 focused contract tests：`packages/novel_agent_core/test/repair_lane_contracts_test.dart` 覆盖 `remind / adjust_next` 不物化 repair task、`repair` disposition 转成 blocking repair request/task、`checkpoint_user / manual_attention` 变成阻塞但非 repair-task 的动作，以及 blocking repair 只有在完成 outcome 后才真正放行主链。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/review/repair_contract_catalog.dart lib/src/review/repair_request.dart lib/src/review/repair_task.dart lib/src/review/repair_outcome.dart lib/src/review/repair_handoff_decision.dart lib/src/review/repair_blocking_state.dart lib/src/review/review_repair_handoff_service.dart lib/src/review/repair_lane_blocking_service.dart lib/novel_agent_core.dart test/repair_lane_contracts_test.dart`，以及 `dart test test/repair_lane_contracts_test.dart`。下一轮应进入 `LTSR-06`，只做 chapter delivery failure 合同与坏交付拦截，不要把本轮 repair lane 重新散回 queue stop policy、delivery state machine 或 ad-hoc revision task 分支。
- `LTSR-06`：已完成（2026-06-06）。已在 `packages/novel_agent_core` 新增纯 core 的稳定坏交付合同 `ChapterDeliveryFailure`，正式把 `write_failed / empty_body / title_only_output / body_too_short / path_mismatch / sidecar_missing / sidecar_invalid / delivery_evidence_missing` 八类高确定性 chapter delivery failure 收口为共享 typed contract，而不再只依赖零散 `reason` 字符串。与此同时，`ChapterDeliveryStateMachine` 已在空正文、只标题、错路径、写入失败、缺 submission、submission 非法、缺最小 evidence、正文过短等拦截分支直接产出 `deliveryFailure`；`ChapterDeliveryStateResult`、`SubmitChapterDeliveryResult` 与 `WritingExecutionDeliverySummary` 也已统一携带该合同，使 tools domain、共享 `WritingExecutionResult` 与后续 supervisor / recovery 主链都能消费同一交付失败输入。为保持兼容，本轮还在 `WritingExecutionResultNormalizerService` 增加了基于旧 `reason` 的回填映射，避免已有旧状态结果在共享 summary 中丢失 failure 分类。为避免越界，本轮没有接 station UI、recovery 策略、probe 或 runtime 新调度。已补 focused tests：`packages/novel_agent_core/test/chapter_delivery_state_machine_test.dart` 覆盖 empty body / title-only / path mismatch / sidecar missing / sidecar invalid / evidence missing / write failed 的 typed failure 分类；`packages/novel_agent_core/test/submit_chapter_delivery_handler_test.dart` 覆盖 tool outcome 中 `delivery_failure` payload 的稳定暴露；`packages/novel_agent_core/test/writing_execution_result_contracts_test.dart` 覆盖 shared result round-trip 与 legacy reason backfill。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/workflow/chapter_delivery_failure.dart lib/src/workflow/chapter_delivery_state_result.dart lib/src/workflow/writing_execution_delivery_summary.dart lib/src/tools/domain/submit_chapter_delivery_result.dart lib/src/workflow/chapter_delivery_state_machine.dart lib/src/workflow/writing_execution_result_normalizer_service.dart lib/novel_agent_core.dart test/chapter_delivery_state_machine_test.dart test/submit_chapter_delivery_handler_test.dart test/writing_execution_result_contracts_test.dart`，以及 `dart test test/chapter_delivery_state_machine_test.dart test/submit_chapter_delivery_handler_test.dart test/writing_execution_result_contracts_test.dart`。下一轮应进入 `LTSR-07`，只做 watchdog 与 supervisor 职责硬拆分，不要把本轮 delivery failure 合同重新退回成状态机 reason 分支或 tool 私有 payload。
- `LTSR-07`：已完成（2026-06-07）。已在 `packages/novel_agent_adapters` 把 watchdog 机械运行面与 supervisor 结构结果调度面正式硬拆开，避免继续由 `LongTaskSupervisor` 同时承担心跳轮询与高层状态收口。新增运行面类型包括：`LongTaskWatchdog`、`LongTaskWatchdogDispatchPort`、`LongTaskWatchdogPulseResult`；其中 `LongTaskWatchdog` 只负责 heartbeat touch、stale / due poll、orphan dispatch state reconcile 与最小 runtime health fix（清理已不再活跃 run 的派发节流状态），继续复用既有 `LongTaskHeartbeatScheduler` 做纯扫描/派发，不读取正文、不做 review、不决定后续 chapter 调度。与此同时，`LongTaskSupervisor` 已去掉 `markHeartbeat / start / stop / pulseOnce` 等 watchdog 机械入口，收缩为只负责 run 持久化编排、状态机切换，以及消费共享 `WritingExecutionResult`/`LongTaskWritingExecutionSignalService` 做结构结果驱动的 run 状态收口；二者仅通过极小的 `LongTaskWatchdogDispatchPort` 协作清理 dispatch state，从边界上落实“watchdog 只处理 heartbeat/stale/orphan/runtime health，supervisor 只消费结构结果做调度”。`AdapterBundle` 也已同步分开装配 `longTaskWatchdog` 与 `longTaskSupervisor`，但本轮没有改 GUI、没有接 checkpoint cadence、没有引入 review 细节。已补 focused tests：`packages/novel_agent_adapters/test/long_task_supervisor_test.dart` 现在覆盖 supervisor 仅暴露 watchdog 运行态、pause/resume/stop 状态切换、shared writing result 调度收口，以及 watchdog 自己的 heartbeat / stale poll / orphan dispatch reconcile；`packages/novel_agent_adapters/test/long_task_heartbeat_scheduler_test.dart` 继续覆盖 scheduler 只扫描 active run 并产出 due/stale 事件；`apps/novel_agent_app/test/long_task_station_controller_auto_refresh_test.dart` 也已验证 app 侧只读依赖改到新的 watchdog-dispatch 边界后仍正常。验证已通过：`packages/novel_agent_adapters` 下 `dart analyze lib/src/runtime/long_task_watchdog_dispatch_port.dart lib/src/runtime/long_task_watchdog_pulse_result.dart lib/src/runtime/long_task_watchdog.dart lib/src/runtime/long_task_heartbeat_scheduler.dart lib/src/runtime/long_task_supervisor.dart lib/src/bootstrap/adapter_bundle.dart lib/novel_agent_adapters.dart test/long_task_supervisor_test.dart test/long_task_heartbeat_scheduler_test.dart`，以及 `dart test test/long_task_supervisor_test.dart test/long_task_heartbeat_scheduler_test.dart`；`apps/novel_agent_app` 下 `dart analyze test/long_task_station_controller_auto_refresh_test.dart tool/mock_long_task_probe.dart` 与 `flutter test test/long_task_station_controller_auto_refresh_test.dart`。下一轮应进入 `LTSR-08`，只做 supervisor 输入包与统一调度决策合同，不要把本轮 watchdog/supervisor 边界重新揉回单一 runtime service。
- `LTSR-08`：已完成（2026-06-07）。已在 `packages/novel_agent_core` 新增纯 core 的 supervisor 输入包与统一调度决策合同，正式把长任务监督层对共享写作结果的消费从松散 signal map 收口到稳定结构。新增类型包括：`SupervisorInputBundle`、`SupervisorDecision`、`SupervisorDecisionActions`、`SupervisorDecisionService`；其中 `SupervisorInputBundle` 统一承接 `WritingExecutionResult` 的 delivery / constraints / information / collaboration / recovery 五段子合同，以及 `LongTaskStopOutcome`、`stop_reason_hint`、`fallback_note` 等控制面补充字段；`SupervisorDecisionService` 则集中产出 `continue / remind / adjust_next / repair / pause / waiting_user / manual_attention` 七类监督动作，并统一派生 `run_status / recovery_action / blocks_progress / retryable / requires_user_action / legacy_stop_reason / stop_outcome`，从而落实“child lanes 不再各自直接改写最终 stop reason 语义，兼容字段统一由中央决策合同导出”。在此基础上，`LongTaskWritingExecutionSignalService` 已被重构为纯桥接层：内部先构建 `SupervisorInputBundle`、调用 `SupervisorDecisionService` 产出统一决策，再向旧消费方保留兼容 signal 字段，包括 `category / note / recovery_action / legacy_stop_reason / run_status / stop_outcome`，同时新增 `supervisor_input_bundle / supervisor_decision / supervisor_action` 供 runtime、probe 和后续 projection 同源消费。为保持现有宿主与测试稳定，本轮还显式保留了旧兼容口径，例如内容质量/交付类人工介入继续导出 `delivery_manual_attention`，信息层人工介入继续导出 `information_manual_attention`，但这些都已改为中央决策统一派生，而不再由子链直接 author。已补 focused tests：`packages/novel_agent_core/test/supervisor_decision_service_test.dart` 覆盖输入包/决策合同 round-trip，以及 `success -> continue`、`warning information -> remind`、`expression adjust-next -> adjust_next`、`recoverable delivery -> repair`、`technical failure -> pause`、`waiting user -> waiting_user`、`content quality -> manual_attention` 七类动作映射，并验证 `legacy_stop_reason` 由统一决策合同集中导出；同时既有 `test/task_queue_services_test.dart`、`test/long_task_scheduler_services_test.dart`、`test/writing_execution_result_contracts_test.dart`、`test/long_task_stop_outcome_resolver_service_test.dart` 与 `packages/novel_agent_adapters/test/long_task_supervisor_test.dart` 也已通过回归，确认旧 signal 消费方仍兼容。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/workflow/supervisor_decision_action.dart lib/src/workflow/supervisor_input_bundle.dart lib/src/workflow/supervisor_decision.dart lib/src/workflow/supervisor_decision_service.dart lib/src/workflow/long_task_writing_execution_signal_service.dart lib/novel_agent_core.dart test/supervisor_decision_service_test.dart test/long_task_stop_outcome_resolver_service_test.dart test/writing_execution_result_contracts_test.dart test/task_queue_services_test.dart test/long_task_scheduler_services_test.dart`，以及 `dart test test/supervisor_decision_service_test.dart test/long_task_stop_outcome_resolver_service_test.dart test/writing_execution_result_contracts_test.dart test/task_queue_services_test.dart test/long_task_scheduler_services_test.dart`；`packages/novel_agent_adapters` 下 `dart analyze test/long_task_supervisor_test.dart lib/src/runtime/long_task_supervisor.dart` 与 `dart test test/long_task_supervisor_test.dart`。下一轮应进入 `LTSR-09`，只做 checkpoint cadence / risk tightening 与长任务主动调度 review，不要把本轮 supervisor 输入合同、统一决策合同和中央 legacy stop reason 派生重新散回各子链 signal 分支。
- `LTSR-09`：已完成（2026-06-07）。已在 `packages/novel_agent_core` 新增纯 core 的 `LongTaskCheckpointCadencePolicy` 与 `LongTaskCheckpointCadencePolicyService`，正式把 checkpoint cadence、batch 上限和连续结构化风险收紧规则从零散 mode/task if-else 中收口到独立策略合同。该策略当前只消费运行记录里已经稳定落盘的结构化字段：`last_checkpoint_review_severity`、`last_writing_execution_category`、`last_information_risk_category` 与最近 `steps[]` 摘要，不读取正文、不扩展 review contract，也不把 GUI 设定拉进 core。基线层已统一定义各模式与 runtime baseline 的默认 cadence：`single_chapter_atomic` 单步边界、`supervised_chapter_queue` 每章收口、`seed_to_full_novel` 规划/样章里程碑、`chapter_collaboration_autorun` 无显式人工 checkpoint interval 但保留章后 gate；运行态则支持 `medium / high / critical` 风险收紧，以及连续结构化风险自动升级。具体规则已接入 `LongTaskControllerProfileService`、`LongTaskUnattendedStrategyService`、`LongTaskNextBatchPlanService` 与 `LongTaskTaskFactoryService`：controller profile 现在会稳定暴露 `checkpoint_interval` 与 `checkpoint_cadence`，unattended strategy / batch plan 会返回风险收紧后的 `effective_batch_steps / effective_batch_seconds / effective_checkpoint_interval`，任务工厂也改为复用 cadence 基线生成 checkpoint，而不再在不同入口各自维护默认间隔；同时 batch plan 在因风险自动缩短批次时会明确给出 `risk_tightened_batch` 边界原因，方便后续 runtime/projection 解释“为什么这轮只跑更短一批”。为保持 `chapter_collaboration_autorun` 的既有语义，本轮特别约束：即使遇到高风险，该 baseline 也只缩短 batch step/seconds，不会重新制造显式人工 checkpoint interval。已补 focused tests：新增 `packages/novel_agent_core/test/long_task_checkpoint_cadence_policy_service_test.dart` 覆盖 autorun 基线、连续中风险升级、高风险 autorun 只缩 batch 不恢复人工 checkpoint；扩展 `packages/novel_agent_core/test/long_task_scheduler_services_test.dart` 覆盖运行态 cadence 注入 strategy/batch plan 与 `risk_tightened_batch` 边界；扩展 `packages/novel_agent_core/test/long_task_task_factory_runtime_baseline_test.dart` 覆盖任务工厂改由 cadence 基线驱动 checkpoint 生成。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/workflow/long_task_checkpoint_cadence_policy.dart lib/src/workflow/long_task_checkpoint_cadence_policy_service.dart lib/src/workflow/long_task_controller_profile_service.dart lib/src/workflow/long_task_unattended_strategy_service.dart lib/src/workflow/long_task_next_batch_plan_service.dart lib/src/workflow/long_task_task_factory_service.dart lib/novel_agent_core.dart test/long_task_checkpoint_cadence_policy_service_test.dart test/long_task_scheduler_services_test.dart test/long_task_task_factory_runtime_baseline_test.dart`，以及 `dart test test/long_task_checkpoint_cadence_policy_service_test.dart test/long_task_scheduler_services_test.dart test/long_task_task_factory_runtime_baseline_test.dart`。下一轮应进入 `LTSR-10`，只做 recovery / retry / requeue / manual attention 状态机，不要把本轮 cadence policy 重新散回 controller/task factory/scheduler 的硬编码步数与 checkpoint 间隔分支。
- `LTSR-10`：已完成（2026-06-07）。已在 `packages/novel_agent_core` 新增正式恢复状态合同 `LongTaskRecoveryState` 与 `LongTaskRecoveryStateMachineService`，把 long-task recovery / retry / requeue / waiting user / manual attention / recovery exhausted 收口为 typed state machine，而不再继续依赖零散 `recoveryPlan['action']` 方言。与此同时，`LongTaskRecoveryService` 已改为统一委托该状态机并向旧消费方回放兼容字段 `action / reason / note / task / stop_outcome / recovery_state`；`LongTaskRunOptionService` 与 `LongTaskRunRecordService` 也已正式纳入 `safe_after_crash`、`auto_retry_failed_task`、`recovery_retry_budget`、`recovery_exhausted_disposition`、`recovery_retry_counts`、`last_recovery_state` 等恢复运行时真相。为把恢复状态真正接入调度链，本轮还扩展了 `LongTaskFailureActionService`、`LongTaskSchedulerTickPlanService`、`RunInstance`、`RunInstanceDocumentCodecService` 与 `LongTaskSupervisor.applyRecoveryState(...)`：失败任务自动重试会稳定累计 retry count，scheduler tick plan 可直接产出 `retry_failed_task / stop_after_recovery_exhausted` 等正式恢复动作，运行实例与本地 registry 会持久化 `recovery_state`，supervisor 也能按正式恢复状态切换 run status，而不是继续依赖 metadata 猜测。为保持共享写作结果兼容，本轮还补齐了两个恢复边界缺口：恢复状态机会从最近一步结构化 step 回读 `information_risk_category / information_summary`，简化版 collaboration summary 在缺少 `blocking_failure_count` 时会默认以 `failed_collaborator_count` 回填，从而保证信息等待用户与协作失败都能稳定进入正式 recovery lane。已补 focused tests：`packages/novel_agent_core/test/long_task_runtime_services_test.dart` 覆盖 repair-required recovery state、信息等待用户、协作失败、自动重试、预算耗尽 disposition 与 retry count 累计；`packages/novel_agent_core/test/long_task_scheduler_services_test.dart` 覆盖 scheduler tick 对 `retry_failed_task / stop_after_recovery_exhausted` 的正式调度；`packages/novel_agent_adapters/test/local_long_task_run_registry_test.dart` 覆盖 `recovery_state` 与 `stop_outcome` 的持久化 round-trip；`packages/novel_agent_adapters/test/long_task_supervisor_test.dart` 覆盖 supervisor 应用正式 recovery state 后的 run status 切换。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/workflow/long_task_recovery_state.dart lib/src/workflow/long_task_recovery_state_machine_service.dart lib/src/workflow/long_task_recovery_service.dart lib/src/workflow/long_task_scheduler_tick_plan_service.dart lib/src/workflow/long_task_failure_action_service.dart lib/src/workflow/long_task_run_option_service.dart lib/src/workflow/long_task_run_record_service.dart lib/src/runtime/run_instance.dart lib/src/workflow/writing_execution_collaboration_summary.dart lib/novel_agent_core.dart test/long_task_runtime_services_test.dart test/long_task_scheduler_services_test.dart`，以及 `dart test test/long_task_runtime_services_test.dart test/long_task_scheduler_services_test.dart`；`packages/novel_agent_adapters` 下本轮实现阶段已通过 `dart analyze lib/src/runtime/run_instance_document_codec_service.dart lib/src/runtime/long_task_supervisor.dart test/local_long_task_run_registry_test.dart test/long_task_supervisor_test.dart`，以及 `dart test test/local_long_task_run_registry_test.dart test/long_task_supervisor_test.dart`。下一轮应进入 `LTSR-11`，只做字数纪律进入共享主链，不要把本轮 recovery state machine、retry budget、scheduler recovery action 和 persisted runtime truth 重新散回字符串动作与 metadata 猜测。
- `LTSR-11`：已完成（2026-06-07）。已在 `packages/novel_agent_core` 新增纯 core 的字数纪律合同 `ChapterLengthDisciplineSummary`，正式把 chapter length discipline 从“目标提示 + 局部 level/recommended_action”收口为共享 execution discipline 输入，明确表达当前长度、目标长度、柔性区间、轻微偏离阈值、严重失控阈值、相邻章波动阈值，以及 `reviewSuggested / reminderOnly / hardGateTriggered / repairRequired` 等正式处置层级。与此同时，`WritingExecutionConstraintSummary` 已新增稳定字段 `chapterLengthDiscipline`，`WritingExecutionResultNormalizerService` 会把既有 `ChapterLengthEvaluation + ChapterLengthDistributionPolicy` 正式投影成这份纪律摘要，而不再只把字数信息散落在 `chapterLengthLevel / chapterLengthRecommendedAction / chapterLengthMetadata` 与自由文本 summary 里。为把字数纪律真正接入统一主链，本轮还扩展了 `SupervisorDecisionService`：字数严重失控现在可通过 `chapterLengthDiscipline.repairRequired` 正式进入共享 constraint repair 语义，字数回调建议可通过 `chapterLengthDiscipline.recommendedAction == adjust_next_chapter` 稳定进入 `adjust_next`，轻量字数提醒也可通过 `chapterLengthDiscipline.reminderOnly` 进入 `remind`，不再只依赖扁平 `nextAction` 或软 gate 字符串兜底。为保持兼容，本轮没有改 GUI 文案、没有重做 `ChapterLengthDistributionService` 算法、没有顺手改表达限制策略本体，只是在现有共享结果合同和 supervisor 调度合同之上补齐“硬限制 / 审核容忍 / 严重失控阈值”的正式结构层。已补 focused tests：`packages/novel_agent_core/test/writing_execution_result_contracts_test.dart` 现在覆盖严重字数失控会形成 `chapterLengthDiscipline.hardGateTriggered / repairRequired`，以及可回调偏差会形成 `chapterLengthDiscipline.reviewSuggested` 与 `recommendedAction == adjust_next_chapter`；`packages/novel_agent_core/test/supervisor_decision_service_test.dart` 现在覆盖纯字数纪律的 `adjust_next` 映射，验证 supervisor 可以直接消费新的结构化摘要而不是依赖 legacy 扁平字段。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/workflow/chapter_length_discipline_summary.dart lib/src/workflow/writing_execution_constraint_summary.dart lib/src/workflow/writing_execution_result_normalizer_service.dart lib/src/workflow/supervisor_decision_service.dart lib/src/workflow/supervisor_input_bundle.dart lib/novel_agent_core.dart test/writing_execution_result_contracts_test.dart test/supervisor_decision_service_test.dart`，以及 `dart test test/writing_execution_result_contracts_test.dart test/supervisor_decision_service_test.dart`。下一轮应进入 `LTSR-12`，只做表达限制接入统一审核与调度主链，不要把本轮字数纪律合同重新退回成 loose metadata、summary 文案和宿主私有 `nextAction` 推断。
- `LTSR-12`：已完成（2026-06-07）。已在 `packages/novel_agent_core` 新增纯 core 的 `ExpressionConstraintReviewContractMapperService`，把既有 `WritingExecutionConstraintBridgeResult + ExpressionConstraintReviewProjection + ExpressionConstraintGateSignal` 正式升格为共享 `ReviewContract`，从而让表达限制不再只停留在专用 gate/supervisor signal，而是进入统一 `review / disposition / repair handoff` 主链。具体上，本轮没有重做 ECP 核心策略、没有程序化改正文，只是复用既有 `disabled / adaptive / force`、`review_requirement`、`violation_disposition`、runtime escalation 与 gate 结论，把表达限制结果映射成共享 reviewer/basis/findings/risk level/recommended disposition/repair brief/evidence paths；同时 `WritingExecutionConstraintSummary` 已新增稳定字段 `expressionConstraintReviewContract / expressionConstraintReviewSummary`，`WritingExecutionResultNormalizerService` 会在同一轮共享结果归并时直接产出表达限制 shared review contract，并复用 `ReviewSummaryBuilderService` 生成同源 summary，使后续 `ReviewRepairHandoffService`、supervisor、projection 与 runtime truth 都能消费同一形状的 review artifact，而不再需要 expression 专用平行 lane。为保持边界，本轮没有改 GUI、没有接 probe、没有重写 `LongTaskCheckpointReviewService` 或 ECP gate 逻辑，只是在共享结果合同层补齐“表达限制正式审稿化”的缺口。已补 focused tests：新增 `packages/novel_agent_core/test/expression_constraint_review_contract_mapper_service_test.dart`，覆盖 adaptive 重复风险映射成 `adjust_next` shared review、缺少必需复核证据映射成 blocking `repair` shared review 并可直接进入 `ReviewRepairHandoffService`、以及 disabled policy 不产出 shared review；同时扩展 `packages/novel_agent_core/test/writing_execution_result_contracts_test.dart`，验证统一写作结果 round-trip 后会稳定携带 `expressionConstraintReviewContract / expressionConstraintReviewSummary`。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/review/expression_constraint_review_contract_mapper_service.dart lib/src/workflow/writing_execution_constraint_summary.dart lib/src/workflow/writing_execution_result_normalizer_service.dart test/expression_constraint_review_contract_mapper_service_test.dart test/writing_execution_result_contracts_test.dart`，以及 `dart test test/expression_constraint_review_contract_mapper_service_test.dart test/writing_execution_result_contracts_test.dart`。下一轮应进入 `LTSR-13`，只做信息纪律接入共享主链，不要把本轮表达限制 shared review contract 重新退回成 gate-only signal、summary 文案或 expression 专用 repair 分支。
- `LTSR-13`：已完成（2026-06-07）。已在 `packages/novel_agent_core` 新增纯 core 的 `InformationEvidenceReviewContractMapperService`，把既有 `InformationEvidenceGateSignal` 正式升格为共享 `ReviewContract`，从而让 information evidence 不再只停留在 gate/supervisor 旁路信号，而是进入统一 `review / disposition / supervisor input / stop reason` 主链。与此同时，`WritingExecutionInformationSummary` 已新增稳定字段 `informationEvidenceReviewContract / informationEvidenceReviewSummary`，`WritingExecutionResultNormalizerService` 会在同一轮共享结果归并时直接把 `pending research / awaiting confirmation / source insufficient / external fact unverified` 映射成共享 review artifact，并补齐 evidence source/target path handoff，使普通项目、长任务与 follow-up 后续链路能够消费同一口径的信息纪律结果，而不再各自维护平行备注语义。为把信息纪律真正接入统一调度合同，本轮还扩展了 `SupervisorDecisionService` 与 `LongTaskStopOutcomeResolverService`：其中信息修复类 `repair` 结论现在会优先稳定导出 `information_repair_required`，并进一步与 `information_gateway_failed / information_required_omitted / information_external_fact_unverified / information_rigorous_source_insufficient` 等 legacy reason 一起统一映射到正式 stop outcome 语义，避免信息纪律被表达限制或通用 `constraint_gate_pause` 兜底吞并。为保持边界，本轮没有重做 `PIS / IED` 核心、没有改 GUI 设置、没有跑真实联网探针，只是在共享 review 合同、共享执行结果合同与 supervisor/stop-outcome 收口层补齐“信息纪律正式主链化”的缺口。已补 focused tests：新增 `packages/novel_agent_core/test/information_evidence_review_contract_mapper_service_test.dart`，覆盖 awaiting confirmation 映射为 `checkpoint_user` shared review、gateway failure 映射为 blocking `repair` shared review、rigorous source insufficient 映射为非阻塞 `remind` shared review；同时扩展 `packages/novel_agent_core/test/writing_execution_result_contracts_test.dart`、`packages/novel_agent_core/test/supervisor_decision_service_test.dart` 与 `packages/novel_agent_core/test/long_task_stop_outcome_resolver_service_test.dart`，验证统一写作结果会稳定携带 `informationEvidenceReviewContract / informationEvidenceReviewSummary`，且信息修复 stop reason 会由中央决策合同与 stop outcome resolver 同源导出。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/review/information_evidence_review_contract_mapper_service.dart lib/src/workflow/writing_execution_information_summary.dart lib/src/workflow/writing_execution_result_normalizer_service.dart lib/src/workflow/supervisor_decision_service.dart lib/src/runtime/long_task_stop_outcome_resolver_service.dart test/information_evidence_review_contract_mapper_service_test.dart test/writing_execution_result_contracts_test.dart test/supervisor_decision_service_test.dart test/long_task_stop_outcome_resolver_service_test.dart`，以及 `dart test test/information_evidence_review_contract_mapper_service_test.dart test/writing_execution_result_contracts_test.dart test/supervisor_decision_service_test.dart test/long_task_stop_outcome_resolver_service_test.dart`。下一轮应进入 `LTSR-14`，只做普通项目工作流接线，不要把本轮 information evidence shared review contract、统一 supervisor input 与 stop reason 中央映射重新退回成 gate-only signal、旁路备注或 information 专用手工分支。
- `LTSR-14`：已完成（2026-06-07）。已在 `packages/novel_agent_core` 新增纯 core 的 `NarrativeSemanticReviewContractMapperService`，把普通项目里 `submit_semantic_review` 产出的 `NarrativeSemanticReview` 正式升格为共享 `ReviewContract`，从而让普通项目语义审核不再只停留在旧 `semantic_review / review_report` 私有结构，而是进入共享 `review / summary / repair handoff` 主链。与此同时，`packages/novel_agent_adapters/lib/src/workflow/project_workflow_review_runtime_service.dart` 已正式把普通项目语义审稿结果接到共享合同层：`persistSemanticReviewArtifacts(...)` 现在会为主审稿结果稳定产出 `semantic_review_contract / semantic_review_summary / semantic_review_repair_handoff / semantic_review_authority_policy`，`attachReviewArtifacts(...)` 也会把这些 shared artifact 一起写回 execution record，避免普通项目后续仍只能依赖弱结构 report 或自由文本 summary。为保持“普通项目语义审核触发主要由智能体组策略决定”的边界，本轮没有把普通项目改成长任务式强编排，也没有写死“每章必审”；相反，本轮显式复用了 `ReviewAuthorityPolicy.standardProject()`，让普通项目 shared review artifact 稳定暴露 `trigger_authority == agent_group_policy`，同时继续只让程序强制客观 gate 与硬失败拦截。为补齐普通项目 child-review 场景下的共享合同接线，本轮还修复了一个真实缺口：`ProjectWorkflowReviewRuntimeService` 现在会递归读取 `call_sub_agent.result.tool_calls`，从 reviewer child 的 `submit_semantic_review` 工具结果中抽取 shared semantic review，而不再只看顶层 `executed_tools`，从而保证普通项目“主智能体委派 reviewer 子智能体审稿”的实际运行路径也能稳定落共享合同。为保持边界，本轮没有接 long-task runtime、没有改 GUI 面板、没有顺手改智能体组编辑器，只是在普通项目 workflow runtime 与共享 review contract 层补齐“普通项目正式复用 shared review/repair/summary 合同”的缺口。已补 focused tests：扩展 `packages/novel_agent_adapters/test/project_workflow_review_runtime_service_test.dart`，验证 `persistSemanticReviewArtifacts(...)` 会产出 shared `semantic_review_contract / semantic_review_summary / semantic_review_repair_handoff / semantic_review_authority_policy`，并在 `attachReviewArtifacts(...)` 后稳定写回 execution；同时扩展 `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`，验证普通项目在 reviewer child 通过 agent-group 路径触发 `submit_semantic_review` 时，会把 shared semantic review contract 持久化到 execution，且 `trigger_authority` 仍稳定是 `agent_group_policy`、`accept_with_note` 会映射为 shared `remind / note_only`，没有被程序硬插成 long-task 式强制审稿/强制 repair 编排。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/review/narrative_semantic_review_contract_mapper_service.dart lib/novel_agent_core.dart`；`packages/novel_agent_adapters` 下 `dart analyze lib/src/workflow/project_workflow_review_runtime_service.dart test/project_workflow_review_runtime_service_test.dart test/project_workflow_runtime_service_test.dart`，以及 `dart test test/project_workflow_review_runtime_service_test.dart test/project_workflow_runtime_service_test.dart`。下一轮应进入 `LTSR-15`，只做长任务工作流接线，不要把本轮普通项目 shared semantic review contract、review authority policy 与 child-review result 抽取逻辑重新退回成 report-only、顶层工具列表特判或“每章必审”的硬编码分支。
- `LTSR-15`：已完成（2026-06-07）。已在 `packages/novel_agent_core` 新增纯 core 的 `LongTaskCheckpointReviewContractMapperService`，把 long-task checkpoint review 正式映射为共享 `ReviewContract`，并在 `packages/novel_agent_adapters/lib/src/workflow/project_long_task_checkpoint_review_service.dart` 中补齐 `review_authority_policy / review_contract / review_summary / review_repair_handoff` 持久化字段，从而让长任务检查点路径不再只停留在 `severity / disposition / suggested_actions` 私有合同，而是正式复用和普通项目一致的 shared review / summary / repair handoff 主链。与此同时，`packages/novel_agent_adapters/lib/src/workflow/project_long_task_checkpoint_review_task_service.dart` 已从“只生成 review 任务文件”升级为真正的调度门：它现在会确保 checkpoint follow-up review 任务显式 `depends_on` 源任务，并把下游依赖从源任务改挂到全部相关 review 任务上，连同 duplicate 场景一起收口，从而让 follow-up review 真正改变 `TaskSelectionService` 的后续可运行结果，而不再只是旁路建议。为把这条 gate 接到运行时，本轮还扩展了 `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`：当任务确认属于 long-task 管理路径，且 checkpoint disposition 要求 `create_followup_review_tasks` 或 `request_revision_followup` 时，runtime 现在会自动物化后续 review gate；一旦 gate 已成功插入，当前任务会稳定以 `succeeded` 收口并把队列推进到新插入的 review 门，而不是继续错误地停在 `waiting_user`。为保持边界，本轮没有改 GUI、没有改 probe、没有新增题材特判，也没有触碰普通项目在 `LTSR-14` 已落地的 agent-group 语义审稿触发链。已补 focused tests：新增 `packages/novel_agent_core/test/long_task_checkpoint_review_contract_mapper_service_test.dart`，覆盖 medium follow-up review 与 repair-oriented checkpoint review 的 shared contract / repair handoff 映射；扩展 `packages/novel_agent_adapters/test/project_long_task_checkpoint_review_service_test.dart`，验证 checkpoint review 会稳定落盘 shared `review_contract / review_summary / review_repair_handoff / review_authority_policy`；扩展 `packages/novel_agent_adapters/test/project_long_task_checkpoint_action_service_test.dart`，验证 materialized follow-up review 会重挂下游依赖；扩展 `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`，验证 long-task runtime 会自动插入 checkpoint follow-up review gate、将当前任务收口为 `succeeded`，并把下游任务真正改挂到 review 门下。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/review/long_task_checkpoint_review_contract_mapper_service.dart lib/novel_agent_core.dart test/long_task_checkpoint_review_contract_mapper_service_test.dart`，以及 `dart test test/long_task_checkpoint_review_contract_mapper_service_test.dart`；`packages/novel_agent_adapters` 下 `dart analyze lib/src/workflow/project_long_task_checkpoint_review_service.dart lib/src/workflow/project_long_task_checkpoint_review_task_service.dart lib/src/workflow/project_workflow_runtime_service.dart test/project_long_task_checkpoint_review_service_test.dart test/project_long_task_checkpoint_action_service_test.dart test/project_workflow_runtime_service_test.dart`，以及 `dart test test/project_long_task_checkpoint_review_service_test.dart test/project_long_task_checkpoint_action_service_test.dart test/project_workflow_runtime_service_test.dart`。下一轮应进入 `LTSR-16`，只做多智能体 reviewer dispatch 接线，不要把本轮 long-task checkpoint shared review contract、自动 follow-up review gate 与下游依赖重挂重新退回成 manual-only suggestion、report-only artifact 或 `waiting_user` 假阻塞。
- `LTSR-16`：已完成（2026-06-07）。已在 `packages/novel_agent_adapters/lib/src/workflow/project_workflow_reviewer_dispatch_service.dart` 新增窄职责的 reviewer dispatch 解析层，把共享 `ReviewerSelectionService` 正式接到 workflow review 运行链：当前任务属于 `review` 时，会基于已选协作组、可用 agent/group 目录与 primary member 解析出正式 `reviewer / critic_or_editor / primary_writer_self_review / unavailable` 选择结果，并稳定写回 execution record 的 `reviewer_dispatch`，从而让 reviewer selection policy 不再只存在于 core 测试里。与此同时，`packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart` 已补充 `executeDelegatedSubAgentTask(...)` 入口，允许 workflow runtime 直接复用现有 sub-agent 执行链生成 reviewer child run，而不再依赖主模型“恰好自己决定 call_sub_agent('reviewer')”；这条路径继续复用既有 child system prompt、excerpt-only context、child-specific model policy 与 blocked tools，因此 reviewer 仍保持独立上下文，且默认继续被禁止 `call_sub_agent / present_user_options / submit_chapter_delivery / start_long_task_run`，没有获得后续调度权。为把这条策略接到实际运行时，本轮还扩展了 `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`：review 任务现在会先解析 `reviewer_dispatch`，如果组内存在 reviewer/critic/editor，就由 runtime 直接把本次审稿委派到对应 child；如果不存在 reviewer-like 成员，则稳定回退到 primary writer self-review，且没有把多智能体逻辑扩散到 chapter/planning/revision 等其他 task type。为保持边界，本轮没有改 GUI、没有重写整个 agent group 系统、没有把所有 workflow 步骤都强行改成多智能体，只在 `review` 执行入口补齐“reviewer selection policy 正式生效”的缺口。已补 focused tests：扩展 `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`，验证 review task 会优先委派 `reviewer` child 并保留隔离上下文与受限工具集、在缺少 reviewer 时回退到 `critic/editor` child、在两者都不存在时回退到 primary writer self-review；同时保留并通过既有 child-specific model/tool policy 与协作组透传测试，证明本轮没有破坏原有 sub-agent 运行合同。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/use_cases/generate_draft_use_case.dart`；`packages/novel_agent_adapters` 下 `dart analyze lib/src/workflow/project_workflow_runtime_service.dart lib/src/workflow/project_workflow_reviewer_dispatch_service.dart test/project_workflow_runtime_service_test.dart`，以及 `dart test test/project_workflow_runtime_service_test.dart`。下一轮应进入 `LTSR-17`，只做 continuity claims 与 legacy `special_mechanic` 降级收口，不要把本轮 reviewer dispatch 重新退回成“主模型自由决定是否叫 reviewer”、report-only review path、无记录的隐式 group 选择或 reviewer 拿到调度权的越界实现。
- `LTSR-17`：已完成（2026-06-07）。已在 `packages/novel_agent_core/lib/src/tools/domain/narrative_domain_tool_catalog.dart` 为 `submit_chapter_delivery` 补齐稳定的 writer claims 入口：顶层 `claims` 与 `submission.claims` 现在都会统一 canonicalize，并可继续复用 `submit_narrative_state_claims` 作为独立补录入口；同时 `packages/novel_agent_adapters/lib/src/tools/project_narrative_domain_tool_executor.dart` 已把 chapter delivery 内携带的合法 claims 追加写入隐藏 continuity claims 仓库并刷新 projection，使 claims 正式成为 writer 后续 reviewer/supervisor 可消费的结构，而不再只停留在 delivery sidecar 的弱结构附带字段。与此同时，`packages/novel_agent_core/lib/src/project/project_prompt_contract.dart`、`packages/novel_agent_core/lib/src/workflow/long_task_transaction_contract_service.dart` 与 `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart` 已把 continuity review 主链收口到 `正文 + claims + evidence`：writer prompt 明确要求通过 `submission.claims` / `submit_narrative_state_claims` 提交稳定状态变化，review prompt 明确要求通过 `accepted_claim_ids / questioned_claim_ids / suggested_claims` 或独立 claims 工具消费 continuity 事实，并禁止根据“多世界 / 回档 / 特殊机制”等题材关键词直接推断连续性结论。为进一步压低遗留题材语义，本轮还在 `packages/novel_agent_core/lib/src/workflow/legacy_continuity_mechanic_importer_service.dart` 与 `packages/novel_agent_adapters/lib/src/storage/project_legacy_continuity_mechanic_migration_service.dart` 中把 `special_mechanic` 的对外文案降级为 `Legacy continuity bridge`，补齐 `compatibility_aliases: ['legacy.special_mechanic']`，并把 pressure probe 文案改成仅说明历史标签仍可读、但已退回兼容桥层。已补 focused tests：`packages/novel_agent_core/test/narrative_domain_tool_catalog_test.dart`、`packages/novel_agent_adapters/test/project_narrative_domain_tool_executor_test.dart`、`packages/novel_agent_core/test/prompt_builder_domain_tool_contracts_test.dart`、`packages/novel_agent_core/test/legacy_continuity_mechanic_importer_service_test.dart`、`packages/novel_agent_adapters/test/project_legacy_continuity_mechanic_migration_service_test.dart` 与 `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart` 已覆盖 chapter delivery claims 归一化与持久化、review prompt/long-task contract 的 anti-keyword claims guidance，以及 legacy bridge alias/文案收口；其中本轮额外修正了一处 reviewer child tool-scope 测试断言，使其尊重 `LTSR-16` 已建立的 child `allowed_tools` 隔离边界，而不错误要求受限 reviewer 子智能体必须暴露 `submit_narrative_state_claims`。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/tools/domain/narrative_domain_tool_catalog.dart lib/src/project/project_prompt_contract.dart lib/src/workflow/long_task_transaction_contract_service.dart lib/src/workflow/legacy_continuity_mechanic_importer_service.dart test/narrative_domain_tool_catalog_test.dart test/prompt_builder_domain_tool_contracts_test.dart test/legacy_continuity_mechanic_importer_service_test.dart`，以及 `dart test test/narrative_domain_tool_catalog_test.dart test/prompt_builder_domain_tool_contracts_test.dart test/legacy_continuity_mechanic_importer_service_test.dart`；`packages/novel_agent_adapters` 下 `dart analyze lib/src/tools/project_narrative_domain_tool_executor.dart lib/src/workflow/project_workflow_runtime_bridge_service.dart lib/src/storage/project_legacy_continuity_mechanic_migration_service.dart test/project_narrative_domain_tool_executor_test.dart test/project_workflow_runtime_service_test.dart test/project_legacy_continuity_mechanic_migration_service_test.dart`，以及 `dart test test/project_narrative_domain_tool_executor_test.dart test/project_workflow_runtime_service_test.dart test/project_legacy_continuity_mechanic_migration_service_test.dart`。下一轮应进入 `LTSR-18`，只做 runtime projection / station detail / stop diagnosis 统一化，不要把本轮 continuity claims 正式入口、claims-based review 合同与 legacy compatibility bridge 重新退回成题材关键词判断、sidecar-only 附带字段或 `special_mechanic` 业务主线。
- `LTSR-18`：已完成（2026-06-07）。已在 `packages/novel_agent_core/lib/src/runtime/long_task_stop_diagnosis_projection.dart` 与 `packages/novel_agent_core/lib/src/runtime/long_task_stop_diagnosis_projection_service.dart` 新增共享的 stop diagnosis 投影层，把 `LongTaskStopOutcome` 正式 failure taxonomy、`LongTaskRecoveryState`、legacy `stop_reason`、review summary 与 information summary 收口到统一 runtime truth 上，从而让 run center、station detail 与 CLI summary 不再各自维护一套 `reason -> label/category` 私有映射。该投影现在优先消费正式 `stop_outcome / recovery_state`，只有在这些合同缺失时才回退 legacy reason；同时会把用户可见高层分类稳定收口到 `completed_naturally / budget_exhausted / technical_failure / delivery_failure / constraint_gate_pause / waiting_user / manual_attention / recovery_exhausted`，并用 review/information 摘要替代“failed_task / waiting_gate / content_quality_gate”这类子链私有口径直出。为把这套真相接到共享控制面，本轮还扩展了 `packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`：`run_center_contract` 现在稳定附带 `stop_outcome / recovery_state / stop_diagnosis`，使普通 run center 合同就能直接区分自然完成、预算停止、技术失败、约束暂停、等待用户与人工注意，而不再只暴露弱结构 `reason` 字符串。与此同时，`packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart` 已把总站详情里的 blocker 生成逻辑切到共享 stop diagnosis 投影，正式结合 run instance 的 `stopOutcome / recoveryState`、run record 的 `last_recovery_state / last_information_summary`，以及最近 review/checkpoint summary 构造统一 `category / label / note`；`apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 与 `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart` 也已经同步改为优先消费 `stop_diagnosis`，从而让 workstation station detail、overview block、CLI run center brief 与普通 workflow narrative summary 都共享同一套高层停点解释，不再各自散落 `budget_or_goal_completed / content_quality_gate / repair_required` 等旧宿主私有分类。为保持边界，本轮没有改 GUI 视觉、没有新增 probe 脚本、也没有顺手把更多私有字段向上乱透传，只是在既有 projection/summary/runtime diagnostics 层补齐统一 truth 的缺口。已补 focused tests：新增 `packages/novel_agent_core/test/long_task_stop_diagnosis_projection_service_test.dart`，覆盖 stop outcome 优先于 legacy reason、manual attention 复用 review summary、repair recovery 映射为 `constraint_gate_pause`、以及预算停止/自然完成分离；扩展 `packages/novel_agent_adapters/test/project_long_task_station_detail_service_test.dart` 与 `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`，验证 station detail / station view data 现在使用正式 stop taxonomy 而不是旧 `content_quality_gate / budget_or_goal_completed` 私有分类；`apps/novel_agent_cli/test/workflow_output_summary_service_test.dart` 则继续覆盖 CLI 摘要在共享 stop diagnosis 下仍能稳定输出人类可读停点。验证已通过：`packages/novel_agent_core` 下 `dart analyze lib/src/runtime/long_task_stop_diagnosis_projection.dart lib/src/runtime/long_task_stop_diagnosis_projection_service.dart lib/src/workflow/long_task_run_center_contract_service.dart test/long_task_stop_diagnosis_projection_service_test.dart test/long_task_scheduler_services_test.dart`，以及 `dart test test/long_task_stop_diagnosis_projection_service_test.dart test/long_task_scheduler_services_test.dart`；`packages/novel_agent_adapters` 下 `dart analyze lib/src/runtime/project_long_task_station_detail_service.dart test/project_long_task_station_detail_service_test.dart`，以及 `dart test test/project_long_task_station_detail_service_test.dart`；`apps/novel_agent_cli` 下 `dart analyze lib/commands/workflow/workflow_output_summary_service.dart test/workflow_output_summary_service_test.dart`，以及 `dart test test/workflow_output_summary_service_test.dart`；`apps/novel_agent_app` 下 `flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart test/long_task_station_view_data_service_test.dart`，以及 `flutter test test/long_task_station_view_data_service_test.dart`。下一轮应进入 `LTSR-19`，只做 probe 合同收口到 production truth，不要把本轮统一 stop diagnosis、shared stop taxonomy 与 claims/review/information 驱动的 runtime projection 重新退回成宿主各写一套 `stop_reason` 文案表、子链私有状态直出或 probe 自建的第二套业务真相。
- `LTSR-19`：已完成（2026-06-07）。已在 `apps/novel_agent_app/tool/probe_support.dart` 完成 probe 私有判定点审计与收口，当前 probe support 不再把 `waitingForUserChoice`、`toolErrorSummary`、兼容 `writing_execution_signal` 文本或宿主私有 stop 文案直接当成业务真相，而是优先消费 production contracts：`stop_diagnosis / run_center_contract.stop_diagnosis / long_task_run_center_contract.stop_diagnosis`、`expression_constraint_report.path_resolution / status_projection`、`information_probe`，以及由共享 `LongTaskStopDiagnosisProjectionService` 从正式 `stop_reason / stop_outcome` 合同派生出的高层停点分类。与此同时，`buildExpressionConstraintProbeReport(...)` 已改为输出正式 `stop_diagnosis`，并把 `stop_reason` 兼容字段收口为同一份 production-backed 诊断投影：有外层 runtime 显式 `stopReason / stopSummary` 时优先使用这份生产停点合同；没有时才回退到共享 `LongTaskWritingExecutionSignalService` 和 `WritingExecutionResult` 所能还原出的 stop outcome / review summary / information summary，而不再在 probe 层额外手写一套 waiting/manual/path/content 业务判断。为保持 probe 分类体系但避免自建第二套业务中心，本轮仅保留 probe 自己的报告类别映射 `success / technical_failure / waiting_user / budget_failure / policy_disabled / path_failure / content_quality_failure / information_quality_failure`，但这些类别现在都由 production truth 驱动：`path_failure` 来自正式 chapter delivery/path resolution 合同，`policy_disabled` 来自正式 expression status projection，`waiting_user / budget_failure / technical_failure` 优先来自正式 stop diagnosis taxonomy，`information_quality_failure` 优先来自 production-backed information probe 合同，而不再靠错误字符串、临时 waiting flag 或 probe 自己拼装的子链状态做主判。为保持边界，本轮没有跑真实 probe、没有改 runtime 业务逻辑、也没有新增 GUI/probe 脚本，只在 probe support 层完成“读取 production truth 而非自建 truth”的合同收口。已补 focused tests：扩展 `apps/novel_agent_app/test/probe_support_test.dart`，覆盖 `classifyDraftProbeReportCategory(...)` 会优先消费正式 `stop_diagnosis / path_resolution / expression status / information_probe`，并验证 `buildExpressionConstraintProbeReport(...)` 现在输出 production-backed `stop_diagnosis`、在显式 `stopReason / stopSummary` 存在时优先解释真实 runtime 停点，而不是被 probe 自己的 expression/information 摘要抢占。验证已通过：`apps/novel_agent_app` 下 `flutter analyze tool/probe_support.dart test/probe_support_test.dart`，以及 `flutter test test/probe_support_test.dart`。下一轮应进入 `LTSR-20`，只做 mock regression suite 覆盖主链，不要把本轮 probe support 的 production truth 收口重新退回成错误字符串分类器、兼容 signal 私有推断器或 probe 自己维护的第二套 stop/content truth。
- `LTSR-20`：已完成（2026-06-07）。已在 `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart` 新增一套围绕 production contracts 的主链 mock regression harness，并通过 `apps/novel_agent_app/tool/mock_long_task_stability_regression_suite.dart` 输出统一 JSON/Markdown 结构化报告，从而把 `ordinary_project_self_review / long_task_proactive_review / reviewer_dispatch / delivery_failure / repair_required / waiting_user / manual_attention / natural_completion` 八类必需场景正式收口到同一份 suite 中。该 suite 不再靠 probe 私有正文扫描或错误字符串猜测，而是分别复用共享 `execution.reviewer_dispatch`、long-task checkpoint follow-up review gate、`review_contract -> review_repair_handoff -> repair_task`、`writing_execution_result`、`LongTaskStopOutcome`、`LongTaskRecoveryState` 与 `LongTaskStopDiagnosisProjectionService` 等 production truth，确保普通项目自审回退、reviewer child 委派、长任务主动审稿门、交付失败、返修阻塞、等待用户、人工处理与自然完成都能被统一复跑和统一解释。与此同时，已新增 focused test `apps/novel_agent_app/test/long_task_stability_mock_regression_suite_test.dart`，直接验证整套 suite 会生成完整 required coverage，并新增一键入口 `tools/run_long_task_stability_supervisor_review_mock_regression_suite.ps1` 与说明文档 `docs/long-task-stability-supervisor-review-mock-regression-suite-2026-06-07.md`，把新的主链 suite、既有 `mock_long_task_probe.dart`、`mock_expression_constraint_policy_probe.dart` 与 `probe_support_test.dart` 串成完整 mock regression 回归入口。为消除本轮串行验证暴露出的关联性错误，还同步修正了 `apps/novel_agent_app/tool/mock_long_task_probe.dart` 中 `severe_word_count_constraint` 的陈旧预期，使其和当前 production signal `recoverable + content_quality_issue` 口径重新一致，避免旧 probe 入口阻断本轮 suite。验证已通过：`apps/novel_agent_app` 下 `flutter analyze tool/long_task_stability_mock_regression_suite_support.dart tool/mock_long_task_stability_regression_suite.dart test/long_task_stability_mock_regression_suite_test.dart`、`flutter test test/probe_support_test.dart test/long_task_stability_mock_regression_suite_test.dart`、`dart run tool/mock_long_task_stability_regression_suite.dart`、`dart run tool/mock_long_task_probe.dart`，以及仓库根目录下 `powershell -ExecutionPolicy Bypass -File tools/run_long_task_stability_supervisor_review_mock_regression_suite.ps1`；该总脚本已同时通过新主链 suite、旧 long-task mock probe 与 expression-constraint mock probe 回归。下一轮应进入 `LTSR-21`，只做短链 gated real probe 验收，不要把本轮新建的 structured mock suite、required coverage 矩阵、reviewer dispatch/repair/stop diagnosis 生产合同消费路径，重新退回成零散 probe 脚本、report-only 回顾或 probe 自维护的第二套停点真相。
- `LTSR-21`：已完成（2026-06-07）。已完成短链 gated real probe 验收收口，并新增独立记录 `docs/long-task-stability-supervisor-review-real-probe-validation-2026-06-07.md`。本轮严格沿用现有 real probe gate 约束：真实探针必须显式设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`，默认只从 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE` 读取配置，产物保留在 `artifacts/`，不写回正式项目目录。验收证据采用已保留的 production-backed real probe 产物而非盲目重跑：普通项目短链使用 `artifacts/real_general_novel_probe_report.json`，其中 `run_id=2026-06-07T13:52:23.432811`、`report_category=success`、`requested_chapter_count=2`，且 `chapter_01`、`chapter_02` 均成功交付，确认普通项目 2 章真实链路可用；长任务短链使用最后一份完整成功的 `artifacts/real_long_task_probe_report.json`，其中 `run_id=2026-06-06T04:42:51.687033`、`report_category=success`、`created_task_count=4`、`planning/sample` 均成功，且 `sample_checkpoint_information_visible=true`、`summary_file_written=true`，确认长任务 3-5 步范围内的小预算真实主链可跑通并能暴露 checkpoint information summary；至少一个真实等待场景则由 `artifacts/real_information_evidence_ordinary_probe_report.json` 提供，其中 `restricted_network_project.report_category=waiting_user`，并明确显示“受限权限普通项目已进入 pending confirmation”，满足 `waiting/repair/summary` 可见场景中的 `waiting_user` 要求。为避免把中断执行误记为完成，本轮特别记录：2026-06-07 曾发起一次新的长任务 real probe 重跑，但会话在完成前被打断，因此没有将该次中断运行写成新的完成报告，而是以仓库内最后一份完整成功的长任务短链报告作为 `LTSR-21` 验收依据。基于以上三份真实产物，本轮已验证 `success` 与 `waiting_user` 在 production-backed real probe 中可见，同时确认 probe 报告继续消费 `LTSR-18`、`LTSR-19`、`LTSR-20` 已收口的 production truth，而没有退回 probe 私有第二套真相；`technical_failure / delivery_failure / constraint pause` 作为统一 taxonomy 在本次小预算 real sample 中未被主动触发，因此本轮没有为了凑齐失败类别而扩大真实预算或人工制造失败输入。全部产物已保留，未删除历史报告，也未开启 `LTSR-22`。下一次会话如需继续，应先单独确认是否确有 `LTSR-21` 暴露出的真实主链问题需要最小回插修复。
- `LTSR-22`：已完成（2026-06-07）。已基于 `LTSR-21` 的真实 probe 产物与验收记录完成一次最小“问题回插审计”，并新增独立记录 `docs/long-task-stability-supervisor-review-real-probe-backfill-audit-2026-06-07.md`。本轮严格遵守 `LTSR-22` 的窄边界：只允许处理 `LTSR-21` 已明确暴露的真实主链问题，不扩大 real probe 预算，不顺手开启新架构修补，也不为了“完成一轮”而伪造代码改动。审计输入只包含 `docs/long-task-stability-supervisor-review-real-probe-validation-2026-06-07.md` 与三份已保留产物：`artifacts/real_general_novel_probe_report.json`、`artifacts/real_long_task_probe_report.json`、`artifacts/real_information_evidence_ordinary_probe_report.json`。复核结果表明：普通项目 2 章短链交付真实成功、长任务 4 步 planning + sample 短链真实成功且 checkpoint information summary 可见、`waiting_user` 真实场景稳定可见；与此同时，`LTSR-21` 已明确记录“没有发现必须在本轮立刻进入 `LTSR-22` 的新真实主链缺陷”，因此本轮没有成立任何必须回插到 core/adapters/workflow 的最小修复触发条件。基于这一审计结果，本轮以“无新增真实问题、无需代码回插修复”的方式自然收口：没有修改 production 代码、没有新增 focused regression、没有扩大真实预算，也没有把 `technical_failure / delivery_failure / constraint pause` 这类本次小预算 real sample 未主动触发的 taxonomy，误写成“待修 defect”。本轮真正完成的是把 `LTSR-21` 的真实验收结论转化为一份明确的 `已修 / 未修` 审计记录，防止后续会话误以为 `LTSR-22` 仍悬空或必须强行造修复。下一次会话如需继续，应从 `LTSR-23` 单独起步，而不是回头把本轮无问题审计改写成伪代码修复。
- `LTSR-23`：进行中（2026-06-07，本次已完成第三个具体子任务）。前两个子任务已分别把 workbench 项目面板的长任务摘要切到共享 stop diagnosis/runtime truth，并进一步接到 long task station 的 detail truth：当前项目 run 的 `ProjectLongTaskStationDetail` 现在会被缓存进 `apps/novel_agent_app/lib/features/workbench/application/models/workbench_project_runtime_state.dart`，`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart` 会在刷新摘要时加载 detail，`apps/novel_agent_app/lib/features/long_task_station/application/controllers/long_task_station_controller.dart` 暴露窄职责的 `loadDetailForRun(...)` 供 workbench 复用，而 `apps/novel_agent_app/lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart` 与 `apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_long_task_summary_panel.dart` 已开始用共享 detail truth 展示最近审稿、返工状态、最近检查点和待确认事项。 本次继续只做 `LTSR-23` 的一个 GUI read-side 子任务，并把 long task station 顶部的 attention callout 解释从 widget 内部临时拼接收口回 view-data/service 层：`apps/novel_agent_app/lib/features/long_task_station/presentation/models/long_task_station_view_data.dart` 新增 `attentionCalloutTitle / attentionCalloutSummary` 两个只读字段，`apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 现在会基于共享 `stopDiagnosis`、`blocker`、`pendingUserAction`、`preferredRecentOutput`、最近审稿/返工结果生成稳定的人话 callout，明确区分“当前运行需要处理后再继续”“当前运行在等待你先处理一项确认”“这里有一条建议操作链”三种顶层语义；`apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_attention_callout.dart` 则退回纯展示层，只在缺少新字段时才保留最小 fallback。为了避免读侧语义回退成状态布尔值误判，本轮还修正了一处新增过程中暴露的关联性错误：`RunInstance.requiresManualAttention` 过于粗粒度，不能直接决定等待确认场景的 callout 标题，因此当前标题优先根据 `pendingUserAction` 与 `stopDiagnosis.category == waiting_user` 判定，再回退到 manual attention；这样“等待确认”不会再被 `paused/waitingGate` 之类宽口径状态错误覆盖。为保持边界，本次没有新增按钮、没有变更 station action bar、没有提前进入 `LTSR-24` 的 GUI 控制动作入口，也没有把业务判断塞回 widget。已补 focused tests：扩展 `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`，覆盖 manual-attention 与 waiting-user 两类 callout 标题/摘要的人话输出；扩展 `apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`，验证详情面板实际显示新的 callout 文案。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart lib/features/long_task_station/presentation/models/long_task_station_view_data.dart lib/features/long_task_station/presentation/widgets/long_task_run_attention_callout.dart test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart`，以及 `flutter test test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart`。下一次会话仍留在 `LTSR-23`，应继续只做下一个 GUI 读路径子任务，优先收口 long task station / workbench 剩余读侧的人话一致性与最小信息解释，不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经接通的 shared stop diagnosis / station detail truth 重新退回成 widget 内部拼接、宿主私有文案表或状态字符串猜测。
- `LTSR-23`：进行中（2026-06-07，本次已完成第四个具体子任务）。前三个子任务已分别把 workbench 项目面板的长任务摘要切到共享 stop diagnosis/runtime truth、进一步接到 long task station 的 detail truth，并把 station 顶部 attention callout 的解释收口回 view-data/service 层。本次继续只做 `LTSR-23` 的一个 GUI read-side 子任务，把 long task station 详情里的剩余内部英文标题从 widget/原始 artifact 直出收口成人话中文，但仍保持所有业务判断都留在读侧 service：`apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 现在会统一把 narrative 主桶标题映射为中文读侧标签，并对常见的内部 related item 标题做最小人话化，例如把 `Clarification / Knowledge Confirmation / Research Pending` 分别转成“待确认问题 / 待确认知识卡 / 待确认调研请求”；同时诊断档位不再把 `Activation / Delivery / Review / Continuity / Information` 这类英文桶名直接暴露给 GUI，而是改为“上下文激活 / 交付结果 / 审稿结论 / 连续性变更 / 资料状态”这类仍保留诊断语义的中文标签。为避免 view-data 默认值继续把内部英文漏到测试夹具或 fallback UI，`apps/novel_agent_app/lib/features/long_task_station/presentation/models/long_task_station_view_data.dart` 里的 narrative/information 相关默认标题也同步改成中文读侧文案。为保持边界，本次没有新增控制动作、没有改写 artifact 本身字段、没有碰 runtime truth，也没有提前进入 `LTSR-24`。已补 focused tests：扩展 `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`，验证标准/诊断两档 narrative 标签与 waiting/information permission item 标题都已中文化；同步更新 `apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`，确保详情面板展示新的中文标题与 callout 摘要。验证通过后，下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先收口剩余读侧说明的一致性，不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经收口的人话标签重新退回成 widget 内部硬编码、artifact 原始英文桶名直出或宿主私有文案表。
- `LTSR-23`：进行中（2026-06-07，本次已完成第五个具体子任务）。前四个子任务已分别把 workbench 项目面板的长任务摘要切到共享 stop diagnosis/runtime truth、进一步接到 long task station 的 detail truth、把 station 顶部 attention callout 收口回 view-data/service 层，并清理了详情里的内部英文主标题。本次继续只做 `LTSR-23` 的一个 GUI read-side 子任务，把 long task station 详情项中仍会直出的机器味副标题和状态短语收口成人话中文，但仍保持所有转换都在读侧 service 完成：`apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 现在会对 related item 的 `subtitle` 做最小人话化，把 `Readable projection / Information projection / delivered / needs_user_confirmation / awaiting_user_confirmation / proposed / suggest_strengthen / applied / force` 这类内部状态短语分别映射为“可读投影 / 资料投影 / 已交付 / 待你确认 / 等待确认 / 待确认 / 建议加强 / 已应用 / 强制要求”；同时对 `setting_fact / project.world / review / revision / scope / quality gate` 等常见内部片段也给出读侧中文替换，使 permission item、projection item、expression-constraint recent item 和最近产物卡片不再把原始机读短语直接暴露给 GUI。为保持边界，本次没有改 artifact 存储内容、没有动 runtime contracts、没有新增操作按钮，也没有提前进入 `LTSR-24`。已补 focused tests：扩展 `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`，验证 narrative/information projection、permission、expression-constraint recent items 与最近交付副标题都已中文化；同步更新 `apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`，确保详情面板实际显示新的中文副标题。验证通过后，下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先收口剩余读侧说明与 workbench 摘要的一致性，不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经收口的副标题重新退回成 widget 内部硬编码、artifact 原始状态字符串直出或宿主私有文案表。
- `LTSR-23`：进行中（2026-06-07，本次已完成第六个具体子任务）。前五个子任务已分别把 workbench 项目面板的长任务摘要切到共享 stop diagnosis/runtime truth、进一步接到 long task station 的 detail truth、把 station 顶部 attention callout 收口回 view-data/service 层，并清理了详情里的内部英文主标题与副标题。本次继续只做 `LTSR-23` 的一个 GUI read-side 子任务，把 workbench 项目面板里的长任务摘要行与 station 详情的人话映射彻底对齐，避免同一条 `ProjectLongTaskStationItemSummary` 在两个宿主里出现不同标题/副标题。为此新增了共享读侧 helper `apps/novel_agent_app/lib/shared/services/long_task_station_item_humanizer_service.dart`，把 `Clarification / Research Pending / Knowledge Confirmation` 等标题，以及 `needs_user_confirmation / awaiting_user_confirmation / Readable projection / Information projection / delivered / proposed / suggest_strengthen / applied / force` 等副标题片段的人话化集中到一处；`apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 与 `apps/novel_agent_app/lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart` 现在共同复用这套 helper，因此项目面板摘要中的“最近审稿 / 返工状态 / 最近检查点 / 待确认事项”不再直接回显 artifact 原始标题或机读短语，而会和总站详情保持同一套中文解释。为保持边界，本次没有新增控制动作、没有改 widget 结构、没有碰 runtime truth，也没有提前进入 `LTSR-24`。已补 focused tests：扩展 `apps/novel_agent_app/test/project_long_task_summary_view_data_service_test.dart` 与 `apps/novel_agent_app/test/workbench_workspace_controller_snapshot_test.dart`，验证 workbench 摘要在遇到 raw `Clarification / Research Pending / needs_user_confirmation` 等输入时，会输出和 station 详情一致的人话摘要。验证通过后，下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先收口剩余读侧说明的一致性，不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经统一的人话映射重新散回各自私有字符串处理。
- `LTSR-23`：进行中（2026-06-07，本次已完成第七个具体子任务）。前六个子任务已分别把 workbench 项目面板的长任务摘要切到共享 stop diagnosis/runtime truth、进一步接到 long task station 的 detail truth、把 station 顶部 attention callout 收口回 view-data/service 层，并清理了详情和 workbench 摘要里的内部英文标题/副标题。本次继续只做 `LTSR-23` 的一个 GUI read-side 子任务，把 workbench 项目面板里的长任务摘要卡片补上与总站顶部同语义的“注意事项”读侧提示，但仍保持所有判断都在 summary service 内完成：`apps/novel_agent_app/lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart` 现在会基于共享 `stop diagnosis` 分类、`pendingSummaryLine`、`nextStepSummary`、最近审稿/返工/检查点摘要，为每条项目面板摘要 run 生成 `attentionCalloutTitle / attentionCalloutSummary`，明确区分“当前运行在等待你先处理一项确认”“当前运行需要处理后再继续”“这里有一条建议操作链”三种顶层语义；`apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_long_task_summary_panel.dart` 则只负责展示，不再自行猜测该用哪种提醒语气。这样用户即使不先打开总站，也能在项目面板一眼看懂这条运行是等待确认、需要人工处理，还是只是建议继续查看。为保持边界，本次没有新增控制动作、没有改动 summary card 的按钮入口、没有把业务判断塞进 widget，也没有提前进入 `LTSR-24`。已补 focused tests：扩展 `apps/novel_agent_app/test/project_long_task_summary_view_data_service_test.dart`，覆盖 waiting-user 与 manual-attention 两类摘要 callout 的标题/摘要；同步更新 `apps/novel_agent_app/test/workbench_project_panel_test.dart`，验证项目面板实际显示新的 callout 文案。验证通过后，下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先收口剩余读侧说明的一致性，不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经接好的摘要 callout 语义重新散回 widget 私有判断或状态字符串猜测。
- `LTSR-23`：进行中（2026-06-07，本次已完成第八个具体子任务）。前七个子任务已分别把 workbench 项目面板与 long task station 的共享停点真相、详情 truth、人话标题/副标题和顶部 attention callout 逐步收口回统一读侧。本次继续只做 `LTSR-23` 的一个 GUI read-side 子任务，把 long task station 详情页底部那条容易与顶部提醒和概览块重复的“停止/阻塞原因”行收窄成“仅在它提供新增信息时才显示的补充原因”，仍保持所有判断都留在 view-data/service 层：`apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 现在不再无条件直出 `run.stopReason` 的旧标签，而是新增窄职责的 `_supplementalStopReasonLabel(...)`，只有当 legacy stop reason 相比共享 `stopDiagnosis.label` / `blocker.label` 还带来了更具体、且不是内部原始代码直出的补充语义时，才保留这条读侧说明；像 `waiting_user`、`manual_attention`、`step_failed` 这类已经被顶部 callout 与停点诊断概括过的泛化原因将不再重复显示，而 `waiting_user_checkpoint` 这类更具体的“等待检查点确认”仍会保留。同步地，`apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart` 把底部标签从“停止/阻塞原因”改成更符合读侧定位的“补充原因”，避免用户误以为这里是在重复主结论。为保持边界，本次没有新增控制动作、没有改 runtime truth、没有把判断塞回 widget，也没有提前进入 `LTSR-24`。已补 focused tests：扩展 `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`，验证普通 waiting-user 场景不会再重复显示 stop reason，同时 `waiting_user_checkpoint` 仍会保留“等待检查点确认”这类更具体的补充说明；同步更新 `apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`，验证详情面板使用新的“补充原因”标签而不再显示旧文案。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart`，以及 `flutter test test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart`。下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先检查总站详情里剩余高层说明与明细块之间是否还有重复表达或边界不清的人话解释，不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经收口的补充原因判断重新散回 widget 私有分支或状态字符串猜测。
- `LTSR-23`：进行中（2026-06-07，本次已完成第九个具体子任务）。前八个子任务已分别把 workbench 项目面板与 long task station 的共享停点真相、详情 truth、人话标题/副标题、顶部 attention callout，以及详情页补充原因的读侧边界逐步收口回统一视图层。本次继续只做 `LTSR-23` 的一个 GUI read-side 子任务，修复 long task station 详情里“最近产物”概览块自身的重复资源展示：此前同一份最近审稿/检查点结果如果同时通过 `preferredRecentOutput` 与 `latestReviewReport` / `latestCheckpointReview` 进入概览块，会因为按钮文案不同而绕过去重，导致同一 artifact 被列出两次；`apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 现在把这块的去重键从 `title + relativePath + actionLabel` 收窄为真正代表底层资源的实体键，优先按 `pendingResearchRequestId`，其次按 `relativePath`，最后才退回到文本内容，因此相同的最近审稿/检查点/产物不会再因为“查看最近产物”和“查看审稿结果”这类展示动作不同而重复出现在同一个概览块里。为保持边界，本次没有改底层 runtime truth、没有改底部“最近关联结果”区块、没有新增控制动作，也没有提前进入 `LTSR-24`。已补 focused tests：扩展 `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`，新增回归用例验证同一份 `reviews/ch08.md` 即使同时从最近产物入口和最近审稿入口进入，也只会在 `最近产物` 概览块中保留一条。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart test/long_task_station_view_data_service_test.dart`，以及 `flutter test test/long_task_station_view_data_service_test.dart`。下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先检查“最近产物”概览块与底部“最近关联结果”区块之间是否还需要进一步的人话分工或边界收口，但不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经修好的资源级去重重新退回成依赖按钮文案的浅层比较。
- `LTSR-23`：进行中（2026-06-07，本次已完成第十个具体子任务）。前九个子任务已分别把 workbench 项目面板与 long task station 的共享停点真相、详情 truth、人话标题/副标题、顶部 attention callout、补充原因，以及“最近产物”概览块自身的资源级去重逐步收口回统一读侧。本次继续只做 `LTSR-23` 的一个 GUI read-side 子任务，把 long task station 详情里“最近产物”概览块与底部“最近关联结果”区块之间的跨区重复再收紧一层：此前如果 `preferredRecentOutput` 本身就是最近审稿、最近检查点或最近返工结果，页面会在上方概览块和下方结果区各贴一遍同一资源；`apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 现在会先计算底部结果区的专属资源键，再把这些资源从“最近产物”概览块中过滤掉，因此底部“最近关联结果”继续作为审稿/检查点/返工的权威明细区，而上方“最近产物”概览块只保留真正额外的最近正文、投影或表达规则结果。如果概览块原本只会重复展示这些底部专属结果，它现在会退成更高层的提示态，显示“最近审稿、检查点或返工结果已整理到下方最近关联结果”，并把“最近可查看内容”改成“请看下方结果区”，从而避免用户在同一页来回看到两份相同结果。为保持边界，本次没有改 runtime truth、没有改底部结果区的结构、没有新增控制动作，也没有提前进入 `LTSR-24`。已补 focused tests：扩展 `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`，一条回归继续验证真正额外的最近正文交付仍会保留在“最近产物”概览块；另一条回归验证当最近资源只剩检查点结果时，概览块会退成提示态而底部 `latestCheckpointReview` 仍保留为权威明细。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart test/long_task_station_view_data_service_test.dart`，以及 `flutter test test/long_task_station_view_data_service_test.dart`。下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先检查 attention callout、action bar 与概览块之间是否还残留“查看最近产物/查看审稿结果”这类高层入口重复，但不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经收口的跨区分工重新退回成多个区块各自重复挂同一资源。
- `LTSR-23`：进行中（2026-06-07，本次已完成第十一个具体子任务）。前十个子任务已分别把 workbench 项目面板与 long task station 的共享停点真相、详情 truth、人话标题/副标题、顶部 attention callout、补充原因，以及最近资源的块内去重和跨区分工逐步收口回统一读侧。本次继续只做 `LTSR-23` 的一个 GUI read-side 子任务，把 long task station 详情顶部 `action bar` 与 `attention callout` 的重复快捷入口收紧成明确分工：此前 `查看最近产物` 与 `等待确认` 这类强上下文入口会同时出现在工具条和提醒区，用户在页面顶部会看到两份几乎同义的快捷按钮；`apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_action_bar.dart` 现在收回为基础操作区，只保留 `打开项目 / 查看当前任务 / 暂停 / 继续推进 / 停止` 这类稳定主操作，而把 `等待确认`、`查看最近产物` 这类依赖当前停点和最近结果语义的入口完全留给 `apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_attention_callout.dart`。这样顶部提醒区继续承担“当前为什么停下、应该先点哪里”的引导语义，工具条则退回通用操作栏，不再和提醒区重复挂同一条上下文动作。为保持边界，本次没有改 service/runtime truth、没有改按钮触发逻辑、没有新增控制动作，也没有提前进入 `LTSR-24`。已补 focused tests：更新 `apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`，验证顶部只剩一份 `OutlinedButton('等待确认')` 与一份 `OutlinedButton('查看最近产物')`，从而锁住这次入口分工，不再退回成工具条和提醒区双份展示。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/long_task_station/presentation/widgets/long_task_run_action_bar.dart test/long_task_run_detail_panel_test.dart`，以及 `flutter test test/long_task_run_detail_panel_test.dart`。下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先检查顶部提醒区摘要文本与概览块摘要之间是否还残留高层语义重复，但不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经收口的顶部入口分工重新退回成多个区块各自重复挂按钮。
- `LTSR-23`：进行中（2026-06-07，本次已完成第十二个具体子任务）。前十一个子任务已分别把 workbench 项目面板与 long task station 的共享停点真相、详情 truth、人话标题/副标题、顶部 attention callout、补充原因，以及最近资源与顶部快捷入口的去重/分工逐步收口回统一读侧。本次继续只做 `LTSR-23` 的一个 GUI read-side 子任务，把 long task station 顶部 `attention callout` 的摘要收回到真正的高层提醒，不再重复下方概览块已经会展示的明细：此前 `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 生成的 `attentionCalloutSummary` 会同时拼上 `先处理：...`、`最近审稿：...`、`最近返工任务：...`、`最近相关结果：...` 这类片段，而这些信息现在已经分别由 `需要你处理`、`最近产物` 与底部 `最近关联结果` 承担，因此页面顶部提醒和下面概览块会反复说同一件事。本轮把 callout 摘要收口为“停点结论 + 一句下一步建议”的高层提示，只保留 `stopDiagnosis.summary` / `blocker.note` 与 `blocker.controlSummary`，去掉对待处理事项标题和最近结果标题的复述，让提醒区继续负责解释“为什么停下、建议先做什么”，而具体要点则留给概览块和相关结果区承接。为保持边界，本次没有改按钮入口、没有改 runtime truth、没有挪动概览块结构，也没有提前进入 `LTSR-24`。已补 focused tests：更新 `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`，验证 manual-attention 与 waiting-user 两类 callout 摘要现在只保留高层提醒，不再包含 `先处理：待确认问题`、`最近审稿：...` 这类明细片段；同步更新 `apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`，验证详情面板的 callout 文案仍然可见，但不再重复展示 `先处理：待确认问题` 与 `最近相关结果：正文交付`。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart`，以及 `flutter test test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart`。下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先检查顶部提醒标题与下方 `当前动作 / 需要你处理` 分块之间是否还残留可进一步收口的人话边界，但不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经收口的高层摘要重新退回成在 callout 中复述下面的明细清单。
- `LTSR-23`：进行中（2026-06-07，本次已完成第十三个具体子任务）。上个子任务已经把 `attentionCalloutSummary` 的主生成路径收口为高层提醒，但本次继续只做同一处读侧遗留收尾，把 long task station 顶部 `attention callout` 在 summary 为空时使用的 fallback 回退路径也对齐到相同边界，避免旧的重复文案从 widget 本地兜底逻辑里悄悄回流：`apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_attention_callout.dart` 现在不再在 `_fallbackSummaryText()` 中拼接 `最近返工任务：...`、`最近审稿：...`，也不再使用“可以从这里继续推进，或先查看当前任务与最近的审稿结果。”这类会和下方概览块、相关结果区语义重叠的默认提示；当上层没有提供 `attentionCalloutSummary` 时，fallback 只保留 `blockerNote`、`blockerActionHint` 这类高层停点结论与一句建议动作，如果两者都为空，则按当前语义退化为“当前运行需要先处理后再继续。 / 当前运行在等待你先处理当前确认。 / 可以从这里继续查看当前运行状态。”这类不复述明细的顶层提醒。为保持边界，本次没有改 view-data service、没有改 runtime truth、没有新增控制动作，也没有提前进入 `LTSR-24`；另外在同一 widget 中顺手补正了已有的按钮 children 列表分隔语法缺口，使 focused 验证可稳定通过。已补 focused tests：扩展 `apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`，新增回归用例验证当 `attentionCalloutSummary` 为空且页面仍展示最近审稿按钮时，顶部 fallback 摘要只显示“当前运行需要先处理交付问题。 建议先查看返工链或失败任务。”这类高层提醒，不再出现 `最近返工任务：...`、`最近审稿：...` 或“查看当前任务与最近的审稿结果”之类重复文案。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/long_task_station/presentation/widgets/long_task_run_attention_callout.dart test/long_task_run_detail_panel_test.dart`，以及 `flutter test test/long_task_run_detail_panel_test.dart`。下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先检查顶部提醒标题与下方 `当前动作 / 需要你处理` 分块之间是否还残留可进一步收口的人话边界，但不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经收口的 fallback 边界重新退回成 widget 私有兜底里复述下方明细。
- `LTSR-23`：进行中（2026-06-07，本次已完成第十四个具体子任务）。前一个子任务已经把顶部 `attention callout` 的摘要和 fallback 都收口为高层提醒，但标题本身仍直接使用“当前运行在等待你先处理一项确认 / 当前运行需要处理后再继续”这类动作导向表述，而下方概览区已经有独立的 `需要你处理` 分块承接“先处理什么”的读侧语义，因此页面顶部标题和下面分块还会在第一眼上重复强调“你要先处理”。本次继续只做这一个 GUI read-side 子任务，把 long task station 顶部提醒标题收回为纯停点状态说明：`apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 现在会把 waiting-user 类标题统一生成为“当前运行停在待确认节点。”，把 manual-attention 类标题统一生成为“当前运行停在待处理节点。”；`apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_attention_callout.dart` 的本地 fallback 标题也同步对齐到同一口径，避免 service 缺省时又退回动作导向旧文案。这样顶部提醒继续负责告诉用户“现在停在什么关口”，而真正“先处理哪一项、为什么处理、去哪里处理”则留给 `需要你处理` 分块和下方概览块承接。为保持边界，本次没有改 callout 摘要、没有改按钮入口、没有改 workbench 摘要文案、没有动 runtime truth，也没有提前进入 `LTSR-24`。已补 focused tests：更新 `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`，验证 manual-attention 与 waiting-user 两类详情标题分别变为“当前运行停在待处理节点。”与“当前运行停在待确认节点。”；同步更新 `apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`，验证详情面板实际展示新的高层标题且其余摘要/按钮行为保持不变。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart lib/features/long_task_station/presentation/widgets/long_task_run_attention_callout.dart test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart`，以及 `flutter test test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart`。下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先检查 workbench 项目面板里的 attention callout 标题是否也需要沿同一边界进一步收口，但不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经收口的标题语义重新退回成在顶部提醒里复述“先处理”动作。
- `LTSR-23`：进行中（2026-06-07，本次已完成第十五个具体子任务）。前一个子任务已经把 long task station 顶部提醒标题收口为纯停点状态说明，但 workbench 项目面板里的长任务摘要卡片仍保留旧的动作导向标题“当前运行在等待你先处理一项确认 / 当前运行需要处理后再继续”，与卡片下方已经存在的 `待确认事项`、`下一步` 等明细行再次重复“先处理什么”。本次继续只做这一个 GUI read-side 子任务，把 workbench 项目面板里的 callout 标题与 station 详情对齐到同一边界：`apps/novel_agent_app/lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart` 现在会把 waiting-user 类标题统一生成为“当前运行停在待确认节点。”，把 manual-attention 类标题统一生成为“当前运行停在待处理节点。”，从而让项目面板顶部提醒继续只负责概括“这条运行停在什么关口”，而把“先处理哪一项、下一步怎么做”留给 `pendingSummaryLine / nextStepSummary` 等下方明细行承接。为保持边界，本次没有改 workbench 的摘要正文、没有改按钮入口、没有改 long task station 详情、没有动 runtime truth，也没有提前进入 `LTSR-24`。已补 focused tests：更新 `apps/novel_agent_app/test/project_long_task_summary_view_data_service_test.dart`，验证 manual-attention 与 waiting-user 两类项目面板标题分别变为“当前运行停在待处理节点。”与“当前运行停在待确认节点。”；同步更新 `apps/novel_agent_app/test/workbench_project_panel_test.dart`，验证项目面板实际展示新的高层标题且其余 `下一步 / 待确认事项 / 最近审稿` 等读侧信息保持不变。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart test/project_long_task_summary_view_data_service_test.dart test/workbench_project_panel_test.dart`，以及 `flutter test test/project_long_task_summary_view_data_service_test.dart test/workbench_project_panel_test.dart`。下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先检查 workbench 项目面板里是否还残留与 `诊断标签 / 下一步 / 待确认事项` 重复的高层说明，但不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经收口的标题语义重新退回成在项目面板顶部复述“先处理”动作。
- `LTSR-23`：进行中（2026-06-07，本次已完成第十六个具体子任务）。前一个子任务已经把 workbench 项目面板顶部提醒标题收口为“停在什么节点”的高层状态说明，但卡片正文里仍会同时展示 `attentionCalloutSummary` 和 `diagnosisSummary`，而在 waiting-user / manual-attention 这两类主场景下，它们往往就是同一句高层结论，导致项目面板卡片中部连续出现两遍几乎完全相同的诊断说明。本次继续只做这一个 GUI read-side 子任务，把 workbench 项目面板里“顶部提醒摘要”和“诊断结论正文”的职责进一步拆开：`apps/novel_agent_app/lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart` 现在在已有 `diagnosisSummary` 可用时，不再重复生成同句 `attentionCalloutSummary`，从而让顶部提醒区只负责标题层的停点概括，而把完整的诊断结论稳定留给 `diagnosisLabel / diagnosisSummary` 区块承接；只有在没有诊断结论时，`attentionCalloutSummary` 才继续回退到 `nextStepSummary` 或默认提示。为保持边界，本次没有改诊断标签、没有改 `nextStepSummary`、没有改 station 详情、没有改任何控制入口，也没有提前进入 `LTSR-24`。已补 focused tests：更新 `apps/novel_agent_app/test/project_long_task_summary_view_data_service_test.dart`，验证 waiting-user 与 manual-attention 两类项目面板 run 在已有 `diagnosisSummary` 时，`attentionCalloutSummary` 现在为空，不再重复同一句诊断结论；同步更新 `apps/novel_agent_app/test/workbench_project_panel_test.dart`，把卡片 fixture 对齐到新的读侧边界并验证页面只保留一份“当前运行正在等待用户确认。”诊断正文，不再在顶部提醒摘要里重复出现第二份同句文本。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart test/project_long_task_summary_view_data_service_test.dart test/workbench_project_panel_test.dart`，以及 `flutter test test/project_long_task_summary_view_data_service_test.dart test/workbench_project_panel_test.dart`。下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先检查 workbench 项目面板里 `diagnosisLabel / diagnosisSummary / nextStepSummary / detail lines` 之间是否还残留可进一步收口的重复高层说明，但不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经拆开的高层诊断职责重新退回成同一句话在卡片中部重复展示两次。
- `LTSR-23`：进行中（2026-06-07，本次已完成第十七个具体子任务）。前一个子任务已经把 workbench 项目面板卡片里的 `attentionCalloutSummary` 与 `diagnosisSummary` 重复结论收掉，但在 waiting-user / manual-attention 这两类最常见停点场景下，卡片顶部标题已经分别说明“当前运行停在待确认节点。”或“当前运行停在待处理节点。”，紧接着再显示一行 `diagnosisLabel`（如“等待用户确认”/“需要人工处理”）仍然会形成同层高层标签的重复。本次继续只做这一个 GUI read-side 子任务，把 workbench 项目面板里“顶部停点标题”和“诊断标签短语”的职责再收紧一层：`apps/novel_agent_app/lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart` 现在会在 waiting-user 与 manual-attention 两类场景下，在已有顶部 `attentionCalloutTitle` 的前提下收起同义 `diagnosisLabel`，让卡片继续保留诊断正文 `diagnosisSummary`、下一步建议与各条明细行，但不再在标题下面额外挂一行几乎同义的高层标签。这样项目面板顶部只负责一句停点概括，正文区则从完整结论和下一步开始，减少“待确认 / 用户确认”“待处理 / 人工处理”这类贴得过近的重复提示。为保持边界，本次没有改 `statusLabel`、没有改 `diagnosisSummary`、没有改 `nextStepSummary`、没有改 station 详情、没有动任何控制入口，也没有提前进入 `LTSR-24`。已补 focused tests：更新 `apps/novel_agent_app/test/project_long_task_summary_view_data_service_test.dart`，验证 manual-attention 与 waiting-user 两类项目面板 run 现在不再产出 `diagnosisLabel`；同步更新 `apps/novel_agent_app/test/workbench_project_panel_test.dart`，把卡片 fixture 对齐到新的读侧边界并验证页面不再显示单独的“等待用户确认”标签行，而其余停点标题、诊断正文、下一步与待确认事项信息保持不变。验证已通过：`apps/novel_agent_app` 下 `flutter analyze lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart test/project_long_task_summary_view_data_service_test.dart test/workbench_project_panel_test.dart`，以及 `flutter test test/project_long_task_summary_view_data_service_test.dart test/workbench_project_panel_test.dart`。下一次会话仍留在 `LTSR-23`，继续只做下一个 GUI 读路径子任务，优先检查 workbench 卡片里 `statusLabel`、`nextStepSummary` 与下方 detail lines 之间是否还残留可进一步收口的同层说明重复，但不要提前进入 `LTSR-24` 的控制动作入口，也不要把这次已经拆开的停点标题/诊断标签职责重新退回成卡片中部的双重高层标签提示。
- `LTSR-23`：已完成（2026-06-07）。本轮最终在 `apps/novel_agent_app/lib/features/long_task_station/` 与 `apps/novel_agent_app/lib/features/workbench/` 完成 GUI 运行现场读路径收口：long task station、workbench 项目面板与 task center 现在都优先消费统一 `stop_diagnosis / run_center_contract / review summary / repair state / pending info / checkpoint summary`，并通过 view-data service 与共享人话投影解释“为什么停、停在哪、下一步是什么”，不再依赖宿主私有字符串猜测。读侧层面还逐步完成了顶部 callout、概览块、底部相关结果区和 workbench 摘要卡片之间的职责去重：停点标题统一改为“停在待确认/待处理节点”，高层摘要不再复述下方明细，waiting-user/manual-attention 场景下 `diagnosisLabel / attentionCalloutSummary / statusLabel` 也已经切向共享停点真相并去掉同层重复。为确认这轮读侧已经真正收口，本次额外复核了 workbench 摘要卡片 `nextStepSummary` 与各 detail lines 的边界，当前保留的是“高层下一步建议 + 具体待确认/审稿/返工/检查点明细”的自然分层，没有再发现需要继续拆分的同层重复，因此没有人为再切一个读侧子任务。已通过的 focused 验证包括：`apps/novel_agent_app` 下 `flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart lib/features/long_task_station/presentation/widgets/long_task_run_attention_callout.dart lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart test/project_long_task_summary_view_data_service_test.dart test/workbench_project_panel_test.dart test/task_center_view_data_service_test.dart test/task_center_diagnostics_panel_test.dart`，以及 `flutter test test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart test/project_long_task_summary_view_data_service_test.dart test/workbench_project_panel_test.dart test/task_center_view_data_service_test.dart test/task_center_diagnostics_panel_test.dart`。至此 `LTSR-23` 已完成，后续不应回头重开“GUI 读路径解释真相”这条主线，只应在新主线中继续扩更强的治理或浏览能力。
- `LTSR-24`：已完成（2026-06-07）。已在不补底层新逻辑的前提下，把 GUI 最小控制面与人工动作入口正式接到现有共享 runtime/action contracts：`apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_action_bar.dart` 与 `long_task_run_attention_callout.dart` 现在稳定承接 `暂停 / 继续推进 / 停止 / 打开当前任务 / 打开最近正文 / 打开审稿结果 / 打开检查点 / 打开返工任务` 等最小操作；`apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart` 与 `apps/novel_agent_app/lib/features/long_task_station/application/controllers/long_task_station_controller.dart` 继续通过共享 `LongTaskSupervisor` 和 `ProjectPendingResearchActionService` 承接 `确认 / 拒绝` pending research，不在 widget 里重写任何业务规则；`apps/novel_agent_app/lib/features/task_center/application/services/task_center_contract_action_view_data_service.dart` 与 `apps/novel_agent_app/lib/features/task_center/presentation/widgets/task_center_shared_actions_panel.dart` 则把 checkpoint/revision 的共享动作包映射成最小可点的 GUI 上下文动作，只开放已经 materialize 到宿主执行链的动作，未接通动作继续展示但明确置灰说明。为锁定这轮验收，本次补充 focused tests：`apps/novel_agent_app/test/long_task_run_detail_panel_test.dart` 新增回归验证长任务详情面板的 `暂停 / 继续推进 / 停止 / 查看当前任务 / 等待确认 / 查看最近产物 / 查看审稿结果` 都会稳定转发到共享 handler；`apps/novel_agent_app/test/task_center_shared_actions_panel_test.dart` 新增回归验证 task center 的共享动作面板只展示已 materialize 动作，并把未接通建议以禁用说明形式保留。验证已通过：`apps/novel_agent_app` 下 `flutter analyze test/long_task_run_detail_panel_test.dart test/task_center_shared_actions_panel_test.dart`，以及 `flutter test test/long_task_run_detail_panel_test.dart test/task_center_shared_actions_panel_test.dart`。这轮完成后，GUI 已具备最小可用人工控制面；后续若要扩专家控制台、批量动作或更复杂审批，应另开新主线，而不是回退到 `LTSR-24` 继续堆按钮。
- `LTSR-25`：已完成（2026-06-07）。CLI 最小消费与操作入口现已正式收口到共享 `workflow` 命令体系：`apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart` 会从统一 `run_center_contract / stop_diagnosis / checkpoint review / information summary` 提炼 `长任务现场摘要` 与 `开放叙事摘要`，不再自己推断停点；`apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart` 现已稳定支持 `pause / resume / checkpoint-actions / apply-checkpoint-action / revision-resolution / apply-revision-resolution / accept-revision / rollback-revision / pending-research list|approve|reject` 等最小动作，并始终把执行转发给共享 runtime service 或 pending research action service，而不直读底层存储。为补足本轮命令验收，本次在既有 pending-research 测试外新增 focused command tests：`apps/novel_agent_cli/test/workflow_command_test.dart` 现在额外覆盖 `pause` 会回退到最近长任务 run path、`resume` 会复用共享 runtime 并打印 run center 摘要、`checkpoint-actions` 会原样输出共享 action package；同时继续通过 `apps/novel_agent_cli/test/workflow_output_summary_service_test.dart` 锁定 CLI 摘要只消费统一 truth 的口径。验证已通过：`apps/novel_agent_cli` 下 `dart analyze test/workflow_command_test.dart test/workflow_output_summary_service_test.dart`，以及 `dart test test/workflow_command_test.dart test/workflow_output_summary_service_test.dart`。至此 CLI 已满足“查看统一 stop reason/review summary/pending actions，并执行最小 pause/resume/apply pending/checkpoint summary 相关动作”的边界；后续若要扩 TUI、批量治理或更强浏览器，应另开新主线。
- `LTSR-26`：已完成（2026-06-07）。已完成本主线的最终文档、项目约束与 handoff 收口，并严格限定在文档/约束层，没有新增业务功能、没有启动新真实探针。具体包括：1）主顺序文档现已回填 `LTSR-23` 到 `LTSR-26` 的完成记录，使 `LTSR-01 ~ LTSR-26` 全部闭环；2）新增交接文档 `docs/long-task-stability-supervisor-review-handoff-2026-06-07.md`，集中说明当前 GUI/CLI 如何查看长任务现场、如何执行最小人工动作、如何运行 mock/real probe 回归，以及后续维护不要回退的边界；3）更新 `docs/important/long-task-stability-supervisor-review-synthesis-2026-06-06.md`，补记当前实现状态、剩余风险与下一阶段边界，明确本主线已经从“架构分析”进入“生产合同 + 最小消费面闭环可用”；4）补充 `agent.md` 的长任务共享骨架约束，明确 GUI/CLI/probe 只能消费共享 `run_center_contract / stop_diagnosis / review_contract / repair lane / checkpoint action package`，人工动作必须继续经由共享 runtime/action service，且不得重新把 watchdog/supervisor 边界揉回单一宿主控制器。当前剩余风险只保留为后续独立产品化边界：GUI/CLI 仍是最小控制面，短真实 probe 没有为了凑齐失败分类扩大预算，更强的治理面板、批量动作和大预算真实验证应单独开新主线。至此本主线已全部完成；如果后续再次收到同一自动续跑提示，不应再从 `LTSR-23` 重新开始，而应忽略自动提示并由人工明确指定新的独立主线。
