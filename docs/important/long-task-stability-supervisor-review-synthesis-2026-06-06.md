# 长任务稳定性、监督层与执行约束总分析 2026-06-06

## 目的

本文是当前阶段的主分析收口文档。

它不直接展开实现步骤，而是作为后续任务顺序文档的上游依据，回答下面这些已经反复暴露、但过去常被分散讨论的问题：

1. 我们的长任务为什么还不够稳定。
2. `watchdog / supervisor / checkpoint / review / repair` 到底该如何分层。
3. 表达限制、字数、信息纪律、章节交付这些共享约束，应该怎样统一，又怎样避免互相吞并。
4. 多智能体应该怎样参与长任务，而不是让主线程既写又审又调度。
5. 参考项目真正值得吸收的是什么，哪些只是表面相似、不能照搬。
6. 下一轮任务顺序文档要冲着什么最终状态去，而不是再修一轮局部补丁。

本文综合并收口以下既有专题分析：

1. `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
2. `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
3. `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
4. `docs/expression-constraint-execution-policy-analysis-2026-06-06.md`
5. `docs/absorption/10-projects/ai-novel/README.md`
6. `docs/absorption/10-projects/book-os/README.md`
7. `docs/absorption/10-projects/writingway/README.md`
8. `docs/absorption/10-projects/deepseek-tui/README.md`

本文的定位不是再多写一份“方向正确”的说明，而是给出：

1. 当前问题的统一归因。
2. 未来结构的正式边界。
3. 应吸收的成熟模式。
4. 必须具备的运行能力。
5. 明确的失败口径与验收口径。

---

## 一、当前阶段最核心的现实判断

### 1.1 我们已经不是没有架构，而是没有把架构完全兑现成运行时

当前项目并不是“没有设计”。

相反，我们已经有不少方向是对的：

1. 有 `continuity` 底座。
2. 有 `chapter delivery` 合同。
3. 有 `tool round evidence`。
4. 有 `long-task supervisor` 与 heartbeat 思路。
5. 有表达限制、字数策略、信息纪律这些共享执行约束的雏形。
6. 有 checkpoint、review、修复、暂停、恢复这些概念。

真正的问题是：

```text
这些能力还没有在所有真实长链路里被统一、强制、稳定地兑现
```

所以才会反复出现这类现象：

1. 探针里才发现缺章、空正文、标题轮、只读轮。
2. supervisor 有概念，但坏交付没有总被稳定拦下。
3. review 有概念，但没有总是变成正式调度输入。
4. 表达限制有注入记录，但正文读起来仍明显失效。
5. 信息收集有请求记录，但未必真正影响后续写作或暂停决策。

### 1.2 当前最大的问题不是“模型不够聪明”，而是控制面仍不够闭环

过去多轮探针反复说明了一件事：

长任务失败的主因，经常不是单纯内容质量差，而是：

1. 写作轮成功与否没有统一进入正式交付状态机。
2. review 结论没有总是进入后续调度。
3. 某些失败仍停留在“记录了”，而没有升级成 `retry / repair / paused / waiting_user`。
4. 某些风险是在 probe 里被猜到，而不是在 production contract 里被声明。
5. 共享约束能力仍有部分只在特定路径生效，普通项目、长任务、拆书之间没有完全同口径。

### 1.3 问题不能再按题材修

已经可以明确收口：

快穿、死亡回归、多世界、回档、穿书、历史穿越、资料型创作，这些都只能作为压力测试场景，不能再反向决定核心架构。

它们可以帮助我们发现：

1. 连续性状态表达不够。
2. 交付恢复不够。
3. 审核与修复不够正式。
4. 监督层没有接住真实失败。

但它们不应该让核心继续长成：

1. `special mechanic` 特判中心。
2. 某类题材关键词判断器。
3. 某两种测试题材专属工作流。

---

## 二、这轮必须守住的总原则

### 2.1 程序负责合同、证据、调度；智能体负责语义、文学、专业判断

这是这轮最重要的分界线。

程序应负责：

1. 任务身份与生命周期。
2. 章节交付是否真实发生。
3. 路径、正文、字数、必要 sidecar 是否存在。
4. 哪些约束被启用，哪些被排除。
5. review / repair / checkpoint / pause / resume 的状态转换。
6. 证据是否落盘，是否进入统一摘要。
7. supervisor 如何根据结构化结果调度下一步。

智能体应负责：

1. 这一章文学上是否自然。
2. 表达限制是否真的被遵守。
3. 角色声音、叙事边界、世界状态是否文学上成立。
4. 是否需要返修、提醒、下一章回调、或人工注意。
5. 某种风险是偶发自然表达，还是持续模板化。

如果这个分界再次被打破，系统会再次退回：

1. 程序硬判文学。
2. 题材 if/else 膨胀。
3. 后处理补丁堆积。
4. probe 与 production 真相分裂。

### 2.2 长任务必须被视为正式 runtime，而不是“长一点的循环”

长任务不是“普通写作多跑几章”。

它必须具备正式 runtime 特征：

1. 有正式 run identity。
2. 有 step / chapter / checkpoint 级别状态。
3. 有 heartbeat / stale detection。
4. 有 retry / pause / recover / manual attention。
5. 有 artifact、event、summary、evidence 的持久化。
6. 用户离开界面后回来，仍能看到真实运行现场。

### 2.3 共享约束必须共享，但不能被粗暴合并成一个巨物

当前已能明确的共享执行约束至少有：

1. 字数纪律。
2. 表达限制。
3. 信息纪律。
4. 章节交付纪律。
5. 恢复与暂停纪律。

它们都属于共享执行事实，但不是同一种能力。

未来正确的方向应是：

```text
shared execution discipline
  - length discipline
  - expression discipline
  - evidence discipline
  - delivery discipline
  - recovery discipline
```

这意味着：

1. 它们可以共享 bridge、summary、risk policy、supervisor 输入位。
2. 但不能把信息纪律伪装成表达限制。
3. 不能把字数策略伪装成文学审核。
4. 不能把交付失败伪装成题材问题。

---

## 三、我们最终要实现的长任务形态

### 3.1 目标不是“能跑完”，而是“可持续、可恢复、可诊断、可接管”

后续任务顺序文档的最终目标，不应再是“让长任务多跑几章”。

正确目标是让长任务达到以下状态：

1. 可以持续无人值守推进。
2. 可以在坏交付出现时及时止损。
3. 可以在轻风险时继续推进但留下正式信号。
4. 可以在中断后恢复，而不是从头猜测现场。
5. 可以让用户知道是技术失败、内容失败、等待确认、还是任务已自然完成。
6. 可以让普通项目、长任务、拆书 follow-up 共享同一骨架，只在策略强度不同。

### 3.2 最终运行闭环

后续应收口成这样一条正式主链：

```text
plan / prompt assembly
-> generation lane
-> chapter delivery gate
-> lightweight review lane
-> repair lane (when needed)
-> checkpoint review lane (when due)
-> supervisor lane decision
-> continue / pause / waiting_user / manual_attention / recover
```

关键点在于：

1. 不是所有 review 都阻塞主链。
2. 不是所有风险都立刻返修。
3. 但也不能再让问题静默扩散十几章之后才人工发现。

---

## 四、监督层的正式定位

### 4.1 watchdog 不是终点，只是 supervisor 的一个子职责

对比参考项目后，这一点已经很明确。

`watchdog` 更像是运行健康机制，主要负责：

1. heartbeat timeout
2. stale running detection
3. orphan queue reconcile
4. 最基础的 worker / runtime 健康纠偏

而我们真正要的 `supervisor / control plane` 应当覆盖：

1. watchdog 的全部职责。
2. retry / recover / requeue。
3. pause / resume / stop / waiting_user。
4. checkpoint cadence。
5. review lane / repair lane 调度。
6. 连续风险升级与 batch 收紧。
7. 对 delivery / review / evidence / constraint summary 的统一消费。

也就是说：

```text
watchdog 是 supervisor 的子职责
不是 supervisor 的替代物
```

### 4.2 当前最真实的结论

必须诚实：

1. 在架构 scope 上，我们的 supervisor 已经比 MuMu 式 watchdog 更全面。
2. 在运行时兑现度上，还不能说这套 supervisor 已经稳定接住所有真实失败。

当前缺口主要集中在：

1. 坏交付没有总是变成正式 `retry / repair / paused`。
2. review lane 与 repair lane 还没有完全成为主链一等输入。
3. 某些 failure taxonomy 还不够细，导致停机原因不够清楚。
4. 信息纪律、表达限制、字数纪律虽然有结构化摘要，但未必总能改变后续调度。

### 4.3 supervisor 必须只做非 LLM 控制面

这一步必须再次钉牢。

supervisor 可以决定：

1. 继续还是暂停。
2. 是否需要 repair。
3. 是否需要 checkpoint。
4. 是否等待用户确认。
5. 是否缩短后续 batch。

但 supervisor 不应：

1. 直接读正文判断文学效果。
2. 直接判断“这像不像快穿 / 死亡回归 / AI 腔”。
3. 直接改正文。
4. 直接扮演 reviewer。

否则控制面和语义裁判权又会重新混在一起。

---

## 五、审核层的正式定位

### 5.1 审核层不是可有可无，而是一般长项目的基础设施

这件事已经不需要再摇摆。

一般长项目至少需要四类审核：

1. 客观交付审核：
   正文是否存在、路径是否正确、字数是否严重越界、工具交付是否完整。
2. 轻量语义审核：
   是否明显开始跑偏、表达限制是否松动、是否出现连续模板化风险。
3. checkpoint 审核：
   角色、关系、设定、节奏、信息纪律、表达限制是否累计漂移。
4. 修复决策审核：
   是提醒即可、下章调整即可、还是必须插入 repair。

没有这几层，一般长项目会持续出现“看起来在推进，实际上产物已经不适合继续”的假象。

### 5.2 审核必须分层，而不是全同步或全放养

最合理的默认模式应是：

1. `硬阻塞同步审核`
   只处理高确定性失败。
2. `轻阻塞同步审核`
   每章结束后快速看本章是否明显开始歪。
3. `异步后台审核`
   持续积累 drift signal，不总是阻塞主链。
4. `checkpoint 同步审核`
   在阶段边界做更重的综合复核。

这比两种极端都更合理：

1. 每章都全量重审，吞吐太差。
2. 一口气写几十章再回头看，修复成本过高。

### 5.3 reviewer 不应直接拥有调度权或改稿权

最自然的正式形态应是：

1. writer 负责正文产出。
2. reviewer 负责结构化 finding。
3. repair lane 决定是否把 finding 物化为修订任务。
4. supervisor 决定是否继续、暂停、等待用户或人工接管。

这条边界要保持稳定，因为它同样适用于：

1. 单智能体自审。
2. 多智能体 writer + reviewer。
3. 未来拆书、解说、总结等 follow-up 模式。

### 5.4 必须彻底分开三件事：谁触发审核、谁执行审核、谁决定后续调度

这是这轮必须收口的关键点。

过去容易混乱的原因，是把下面三件事揉成了一件事：

1. 谁发起这次审核。
2. 谁来实际做这次审核。
3. 谁根据审核结果决定继续、暂停、返修还是等待用户。

后续必须强行拆开：

#### 触发权

决定“现在要不要进入 review”。

#### 执行权

决定“由哪个智能体或哪个角色来完成 review contract”。

#### 调度权

决定“review 结束后主链怎么走”。

这三者如果不拆开，系统就会再次退回到：

1. writer 一边写一边随意审。
2. reviewer 看了也不知道能不能拦主链。
3. supervisor 既像 reviewer 又像 runtime。

### 5.5 普通项目：审核触发应主要由智能体组策略决定

对于普通项目，最合理的形态不是程序强插一条固定审核链，而是：

1. 程序始终提供 review contract、repair contract、客观 gate 和结构化结果落盘能力。
2. 但“当前这一轮要不要做语义审核、何时做、做多重”，主要由当前智能体组的策略决定。

也就是说，普通项目里程序默认只强制做两类东西：

1. 客观交付 gate。
2. 明确声明过的硬失败拦截。

而更主观的审核触发，应该主要由智能体组自己决定，例如：

1. writer 完成本轮后主动自审。
2. writer 发现存在风险后主动调用 reviewer。
3. 某个工作流型智能体组约定“每章先写后审”。
4. 某个轻量创作型智能体组约定“只在疑似问题时才审核”。

换句话说：

```text
普通项目里
程序提供审核基础设施
智能体组决定是否启用、何时启用、如何启用语义审核
```

这更符合普通项目的真实使用方式，因为普通项目：

1. 节奏更灵活。
2. 用户可能生成一章就停下来读。
3. 用户可能边写边改，不需要每步都被程序强制编排。
4. 不同智能体组本来就可能有完全不同的工作方式。

### 5.6 长任务：审核触发必须由程序主动调度

长任务和普通项目的根本区别正在这里。

长任务一旦进入无人值守或半无人值守连续推进状态，就不能把“要不要审核”继续交给 writer 临场决定。

因此长任务里应明确：

1. 审核触发权属于 runtime / supervisor policy。
2. reviewer 只负责执行 review。
3. supervisor 只负责消费结果并决定后续动作。

也就是说：

```text
长任务里
程序必须主动调度 review
而不是等待智能体临场自觉
```

原因很简单：

1. 无人值守状态下，不能指望 writer 总能主动停下来复核自己。
2. 一旦连续几章都不审核，漂移成本会快速累积。
3. 长任务需要正式 checkpoint、repair、pause、waiting_user 这些结构化状态。
4. 如果审核触发权不在程序，supervisor 就失去真正的控制力。

所以长任务里，最合理的默认模型应是：

1. 每章结束后，程序决定是否触发轻量 review。
2. 到 checkpoint 时，程序决定触发更重的 review。
3. 连续风险升高时，程序决定收紧 review 节奏。
4. 审核结果只要达到当前策略的硬阈值，就由 supervisor 改写后续调度。

### 5.7 审核执行者选择：先看组内是否有 reviewer，没有就回退到主智能体

这一步也需要正式定下来，否则后面实现时会反复摇摆。

后续统一策略应是：

1. 当前智能体组里如果存在专门的 reviewer / critic / editor 角色，优先由该角色执行 review。
2. 如果不存在专门 reviewer，则由主智能体执行 self-review。

也就是说，审核执行者的选择规则应是：

```text
preferred reviewer agent in group
-> compatible critic/editor agent
-> primary writer agent self-review
```

这个规则同时适用于：

1. 普通项目中的智能体自发审核。
2. 长任务中的程序主动调度审核。

区别只在于：

1. 普通项目是谁来触发。
2. 长任务是谁来强制安排触发。

### 5.8 因此，普通项目与长任务的审核差异，真正只应落在“触发权”而非“审核合同”

这一步很重要。

后续不要把普通项目和长任务做成两套完全不同的审核系统。

更自然的做法应是：

1. review contract 共享。
2. reviewer selection policy 共享。
3. repair contract 共享。
4. review result summary 共享。
5. gate / supervisor 对 review disposition 的消费口径共享。

真正不同的只是：

1. 普通项目：审核触发主要由智能体组策略决定。
2. 长任务：审核触发主要由 runtime / supervisor 策略决定。

也就是说：

```text
普通项目与长任务
共用同一审核合同与执行者选择规则
主要区别在触发权和调度强度
```

### 5.9 需要继续守住的最终边界

收口之后，审核层的权责应稳定为：

1. 程序：
   提供合同、客观 gate、长任务审核触发、结果持久化、后续调度。
2. reviewer：
   输出结构化 findings 与 disposition suggestion。
3. writer：
   负责正文，必要时参与 self-review，但不自动拥有调度权。
4. supervisor：
   根据结构化 review/disposition 决定继续、暂停、repair、waiting_user。

这样普通项目和长任务都能成立，而且不会互相污染。

---

## 六、多智能体的正确参与方式

### 6.1 多智能体不能铺满整章主链

多智能体协作的价值是真实存在的，但它不应变成“所有地方都起一个子智能体”。

更合理的是只出现在这些专职节点：

1. reviewer
2. critic
3. continuity checker
4. information researcher
5. repair/revision planner
6. checkpoint analyzer

### 6.2 writer / reviewer / recovery / supervisor 必须职责分离

后续正式合同应清楚表达：

1. writer 交付正文与必要状态提交包。
2. reviewer 交付结构化复核。
3. recovery/repair worker 交付修复结果。
4. supervisor 只消费结构结果并调度下一步。

如果这四者继续混合，系统会再次退回到：

1. 主线程既写又审又修又决定。
2. 所有失败都难以定位到底是写作、审核、还是控制面问题。

### 6.3 子智能体必须是独立上下文，不共享主线程全部隐藏思路

这点参考 `book-os` 和 `DeepSeek-TUI` 都很明确。

子智能体应消费：

1. 项目资产。
2. 当前章节产物。
3. 必要的 continuity / constraint / evidence 摘要。
4. 明确的角色提示与输出合同。

但不应直接共享主智能体的全部隐式上下文，否则 reviewer 只是 writer 的回声，无法形成相对独立的质量检查。

### 6.4 先最短闭环，再扩多智能体协作组

这也是必须守住的顺序。

如果单 writer -> delivery -> review -> supervisor 闭环还不稳定，就不应继续往上堆复杂协作组。

所以多智能体不是当前稳定性的替代方案，而是建立在共享合同已经稳定之后的增强层。

---

## 七、共享执行约束的正式定位

### 7.1 表达限制

表达限制的正确定位已经很清楚：

1. 它是文本呈现约束资产。
2. 它通过 `profile + binding + execution policy + review + gate` 生效。
3. 程序只负责注入边界、证据增强、风险信号与处置输入。
4. 智能体负责“这是否真的不自然 / 模板化 / 破坏人物声音”的语义判断。

必须继续拒绝：

1. 按 `preset id` 写 production special case。
2. 用程序直接改正文来“实现去 AI”。
3. 让 probe 私有判断替代 production review contract。

### 7.2 字数纪律

字数不是表达限制，也不是死板上限。

它应被看作：

1. 给 writer 的目标窗口与硬限制。
2. 给 gate 的容忍区间与严重失控阈值。
3. 给 review / repair 的处置依据。

这意味着后续实现要继续守住两层：

1. `硬限制 / 硬 gate`
2. `审核容忍 / 环绕策略`

也就是：

1. 轻微超出目标但在审核容忍内，不必机械返修。
2. 严重偏离硬 gate 时，必须进入正式修复或暂停。

### 7.3 信息纪律

信息收集不是表达限制，但和长任务稳定性直接相关。

它控制的是：

1. 什么时候必须研究。
2. 什么时候可以直接写。
3. 什么时候只能标成设计灵感，不能伪装成事实。
4. 什么时候需要更严谨来源。
5. 什么时候因为权限或来源问题进入 `waiting_user / evidence repair`。

它不该被塞进表达限制，也不该只写进某个智能体原文。

正确定位应是：

1. 平台级证据纪律。
2. 工具使用准则。
3. 共享 execution result / supervisor signal 的正式来源。

### 7.4 章节交付纪律

长任务稳定性的最低底座，始终还是章节交付。

必须正式承接的失败至少包括：

1. 空正文。
2. 只标题无正文。
3. 路径错误。
4. 文件名异常。
5. 正文未落盘但模型轮已结束。
6. 缺必要 sidecar / delivery evidence。

这些失败不能再主要靠 probe 事后翻目录发现，而必须在 production delivery contract 中被声明并触发明确处置。

### 7.5 恢复纪律

一旦失败发生，系统必须明确：

1. 自动 retry 是否允许。
2. repair 是否必须先执行。
3. 是否转为 paused。
4. 是否需要人工注意。
5. 是否等待用户确认。
6. 是否可以从 checkpoint 或最近稳定状态恢复。

---

## 八、连续性与特殊机制的最终收口

### 8.1 不再以题材定义核心类型

后续核心只应认识这些中性概念：

1. scope
2. frame
3. segment
4. transition
5. change radius
6. memory visibility
7. state carry-over
8. continuity claim
9. review finding

而不是直接认识：

1. 快穿
2. 死亡回归
3. 多世界
4. 穿书
5. 回档

### 8.2 程序化剧情判断只能退回弱 smoke check，不应再做主 gate

像 `SpecialMechanicExecutionEvaluationService` 这类能力，若保留，也只能作为：

1. 兼容旧路径的弱 smoke check。
2. 历史探针迁移桥。
3. 非决定性风险信号来源。

不能再作为：

1. 正式主 gate。
2. 题材语义裁判。
3. 长期扩展方向。

### 8.3 连续性真正需要的是结构化 claims 与 semantic review

未来最自然的方向应是：

1. writer 提交章节正文与状态 claims。
2. reviewer / continuity checker 对 claims 与正文做结构化复核。
3. supervisor 消费 claims + findings + delivery，而不是读正文猜题材。

这条路既适用于特殊机制压力测试，也适用于普通小说里更轻的状态变化。

---

## 九、上下文、资产与记忆的正确吸收点

### 9.1 来自 Ai-Novel：运行层与资产层要正式化

最值得吸收的是：

1. 任务不是裸循环，而是正式 runtime object。
2. 任务有 heartbeat / pause / reconcile / recovery。
3. 记忆不是单一列表，而要分层。
4. 风格、提示模板、世界资料、运行记录都应是资产。

对我们来说，这意味着：

1. 长任务 runtime 要继续正规化。
2. checkpoint、review、repair、summary 都应是正式 artifact。
3. 记忆层要服务长任务上下文控制，而不是把所有东西塞进同一段 prompt。

### 9.2 来自 Book-OS：全局 / 项目 / 稿件 三层上下文与专职 agent

最值得吸收的是：

1. 上下文按作用域分层，而不是一锅端。
2. lite 资产与完整资产并存。
3. reviewer / continuity checker / researcher 这类专职角色边界清晰。

对当前主线最关键的启发是：

1. 主线程上下文要精简。
2. reviewer / researcher 应拿到明确、裁剪后的上下文包。
3. 资产应可有完整视图与压缩视图两套表示。

### 9.3 来自 Writingway：工作台与逻辑创作树

虽然它更偏 GUI，但它提醒我们：

1. 写作项目不应只是文件树。
2. 应有逻辑创作树、摘要链、知识侧栏、可选上下文源。
3. 这些能力对长任务同样重要，因为它们决定用户回来看任务现场时是否真的能理解发生了什么。

这对当前分析的影响是：

1. runtime 与 GUI 最终必须能投影成“人能读懂的现场”，而不是只剩日志。
2. checkpoint、summary、knowledge、review 都要能映射到用户可用界面。

### 9.4 来自 DeepSeek-TUI：模式、审批、工具表面与长会话寿命管理

最值得吸收的是：

1. 模式与审批分离。
2. 工具尽量走结构化表面。
3. 长输出、长分析、大结果要外置，只在主链保留决策摘要。
4. 子智能体是独立会话与独立输出合同。

这对长任务主线的直接要求是：

1. 不要再让大分析结果塞满主线程上下文。
2. tool result、review report、checkpoint artifact 要能句柄化、外置化、按需读取。
3. supervisor / GUI / CLI 应消费同一条 runtime truth，而不是各自猜。

---

## 十、当前失败形态的统一归因

### 10.1 失败不能再只分“成功/失败”

长任务要可用，必须把 failure taxonomy 正式化。

至少应区分：

1. `completed_naturally`
   任务自然完成，不是异常停止。
2. `budget_exhausted`
   预算或外部资源限制触发停止。
3. `technical_failure`
   provider、tool、runtime、gateway、storage 等技术失败。
4. `delivery_failure`
   空正文、错路径、标题轮、落盘缺失等交付失败。
5. `constraint_gate_pause`
   字数、表达限制、信息纪律或其他执行约束达到必须暂停的阈值。
6. `waiting_user`
   权限、确认、资料缺口、checkpoint_user 等等待用户动作。
7. `manual_attention`
   自动恢复不安全，需要人工接管。
8. `recovery_exhausted`
   已达到恢复/重试上限，进入最终人工接管或失败。

如果没有这套 taxonomy，后续任何探针都还会反复出现“只知道停了，不知道为什么停”的情况。

### 10.2 近期高频失败形态

基于过去几轮探针，当前最值得优先盯住的失败形态包括：

1. 写作轮结束，但没有正文。
2. 标题存在，但正文为空或极弱。
3. 文件名或目标路径不稳定。
4. 表达限制有注入记录，但真实正文明显失效。
5. 连续多章字数偏移过大，却没有及时进入正式修复。
6. 信息收集 request 存在，但未真正影响执行和暂停。
7. 长任务停下了，但 stop reason 不够清楚。
8. review 结果有了，但没有真正改变主链调度。

### 10.3 这些失败说明的不是更多特判需求，而是共享合同仍未完全闭环

这一步必须看清。

这些失败并不说明：

1. 需要更多题材特判。
2. 需要更多正则。
3. 需要更多写作提示词硬压。

它们真正说明的是：

1. delivery contract 仍不够硬。
2. review contract 仍不够正式。
3. supervisor inputs 仍不够统一。
4. failure taxonomy 仍不够清楚。
5. probe 与 production contract 仍有错位。

---

## 十一、后续实现必须达到的效果

### 11.1 对用户来说

最终用户体验至少要达到：

1. 长任务不会莫名其妙停住而无解释。
2. 坏交付会尽早被拦住，而不是写坏很多章后才发现。
3. 表达限制、字数限制、资料纪律都能在合适时机真正影响执行，而不是只体现在报告字段。
4. 用户能区分任务是完成、暂停、等待确认、还是失败。
5. 用户回来查看时，能看到 checkpoint、review、修复、资料、当前阻塞点，而不是只能翻目录猜。

### 11.2 对运行时来说

最终 runtime 至少要达到：

1. 所有章节执行都有正式 delivery summary。
2. 所有 review 都有正式 contract 与 disposition。
3. 所有 checkpoint 都有 artifact、summary、建议动作。
4. supervisor 能统一消费 delivery / review / information / expression / length 等结构结果。
5. 一旦需要 pause / recover / waiting_user，状态转换是正式、持久、可恢复的。

### 11.3 对探针来说

最终探针应只做两件事：

1. 驱动真实 production chain。
2. 消费 production contracts 给出诊断。

它不应再承担：

1. 私有业务判断中心。
2. 与 production 不一致的失败口径。
3. 只有探针看得见的特殊裁判逻辑。

---

## 十二、实现顺序上必须坚持的约束

### 12.1 先收口 core contracts，再扩 GUI/CLI

GUI、CLI 的对接仍应放后面。

当前优先顺序应是：

1. core contracts
2. runtime / supervisor / summary / taxonomy
3. adapters 真实接线
4. focused tests
5. mock regression
6. 小预算真实 probe
7. GUI / CLI 的自然投影与操作入口

### 12.2 先最短稳定闭环，再拓展大题材验证

继续跑 200 章双线探针之前，必须先保证：

1. 单章 delivery 闭环稳定。
2. 轻 review 与 gate 能真正改写后续动作。
3. failure taxonomy 能清楚区分停机原因。
4. 普通 3-10 章级别的长任务短链已经稳定。

否则只会重复制造更昂贵的大失败。

### 12.3 不允许把修复堆成补丁墙

后续实现必须继续遵守：

1. 不让单字段承载多重语义。
2. 中间层优先传合同对象，不传补丁参数。
3. 错误修复优先修协议断裂，不新增隐式副作用。
4. 主链和子链共用同一合同形态。

---

## 十三、这份总分析导向的后续任务目标

基于本文，后续任务顺序文档必须覆盖到这些终局目标，而不能只修局部表象：

1. 正式 failure taxonomy。
2. 正式 review contract。
3. 正式 repair lane。
4. delivery gate 与 recovery 的闭环。
5. watchdog 职责与 supervisor 职责的清晰拆分。
6. checkpoint cadence 与风险收紧策略。
7. 表达限制 execution policy 的共享运行时接线。
8. 字数纪律的硬限制 + 审核容忍并存。
9. 信息纪律进入共享 writing result / supervisor signal。
10. continuity claims 与 reviewer 复核的统一入口。
11. probe 只消费 production truth。
12. 多智能体只在专职节点引入，不污染主链。

这些目标必须共同完成，才算真正把长任务做成“好用、稳定、可发布的软件能力”，而不是继续靠人盯着目录和日志维持表面可用。

---

## 十四、最终结论

当前阶段最重要的收口结论是：

```text
我们缺的已经不是更多功能点
而是把已有的 runtime、review、delivery、constraint、information、supervisor
真正收束成一条统一、稳定、可恢复、可诊断的正式长任务主链
```

具体来说：

1. watchdog 要继续保留，但它只是 supervisor 的子职责。
2. supervisor 必须坚持只做非 LLM 控制面，不做文学裁判。
3. reviewer / repair / checkpoint 必须成为正式 lane，而不是附属日志。
4. 表达限制、字数、信息纪律、交付纪律必须共享 bridge 与 summary，但不能互相吞并。
5. 快穿、死亡回归、多世界等只能继续当压力测试，不得再写死进核心。
6. 多智能体必须建立在共享合同稳定之后，只在专职节点参与。
7. probe 的职责应收缩为“驱动 production + 读取 production truth”，而不是自带第二套业务中心。

如果后续任务顺序文档能严格覆盖本文这些结论，那么下一轮实现的目标就不该再是“某个探针勉强过了”，而应是：

1. 普通长项目可稳定运行。
2. 坏交付可及时止损。
3. 审核与修复真正进入正式调度。
4. 限制层与信息纪律合理触发。
5. 用户回来时能看懂任务为什么停、停在哪里、下一步怎么办。

这才是当前阶段真正值得完成的目标。

---

## 十五、当前实现状态补记（2026-06-07）

截至 2026-06-07，本分析文档对应的 `LTSR-01` 到 `LTSR-26` 已全部完成。

当前已实际落地的主线结果包括：

1. `core` 层已正式收口统一 `failure taxonomy / review contract / repair lane / delivery failure / supervisor input bundle / stop diagnosis`。
2. `adapters/runtime` 层已完成 `watchdog / supervisor` 硬拆分、checkpoint cadence 风险收紧、reviewer dispatch、生效的 repair handoff，以及 run center contract / station detail / probe truth 接线。
3. mock regression 与 gated short real probe 已闭环，且 real probe backfill audit 没有暴露必须立即回插修复的新真实主链问题。
4. GUI 已完成 `long task station / workbench / task center` 的最小消费与最小动作入口，CLI 已完成 `workflow` 命令的最小消费与最小动作入口。

## 十六、当前剩余风险

当前剩余风险已经不再是“主链未闭环”，而主要是产品深化边界：

1. GUI/CLI 目前是稳定合同的最小控制面，不是完整专家控制台。
2. 短真实 probe 已验证 `success / waiting_user` 等关键短链场景，但没有为了凑齐所有失败分类扩大真实预算强造样本。
3. 更大预算长任务真实压测、批量治理面板、丰富 artifact 浏览与跨 run 管理，属于后续独立产品化主线，不应回填成当前主线“未完成”。

## 十七、下一阶段边界

后续如果继续推进，不应重开本主线，而应把工作明确归入新的独立主线，例如：

1. 更大预算真实长任务验证与回归样本扩展。
2. 面向普通用户或高级运营的长任务治理产品深化。
3. 新长任务类型在共享骨架上的扩展。

不应作为新主线重开的内容包括：

1. 再做一轮 stop reason/failure taxonomy 重建。
2. 再在 probe/GUI/CLI 各自补第二套停点解释。
3. 再把 review/repair/checkpoint 动作散回宿主私有分支。
