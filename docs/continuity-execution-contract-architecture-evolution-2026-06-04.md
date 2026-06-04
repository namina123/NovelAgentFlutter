# 连续性执行合同架构演化分析 2026-06-04

## 目的

本文只做架构演化分析，不推进实现。

这轮要解决的不是“快穿探针”或“死亡回归探针”本身，而是这些探针持续暴露出的更底层问题：

**我们不应该让程序去硬判创作语义，也不应该把快穿、死亡回归、多世界、多转折这类剧情写法固化成核心工作流分支。**

这些题材与写法在当前阶段只应作为通用连续性、执行约束、章节交付、监管调度能力的压力测试。核心代码应承接的是：

1. 合同是否明确。
2. 章节是否真实交付。
3. 状态是否能持久化。
4. 作用域 / frame / segment 是否能表达。
5. 失败后是否能恢复。
6. 语义判断是否有结构化证据。
7. 新写法能否通过配置和智能体语义报告接入，而不是新增 if/else。

本文综合：

1. 最近两轮关于 `SpecialMechanicExecutionEvaluationService`、程序化锚点判断、快穿/死亡回归不应写死的讨论。
2. 当前项目已有 continuity、chapter delivery、supervisor control plane、tool round evidence 等基础。
3. MuMu 参考项目中可吸收的后台任务稳定性思想。
4. 之前文档中已经确定的“分离、可扩展、核心层优先、GUI/CLI 最后对接、不让单文件过重”等项目级约束。

最终目标是给出一条可执行的架构演化方向：让我们后续修稳定性时，不再在相似问题里堆补丁，而是把链路真正拉回自然、通用、可复用的结构。

---

## 一、最新纠偏结论

### 1.1 快穿 / 死亡回归不是核心语义

快穿、死亡回归、多世界、回档、梦境线、恢复存档、循环重开等，都不是核心代码应该直接认识的“剧情类型”。

它们更合理的身份是：

1. 用户输入的创作设定。
2. 项目级或章节级约束包。
3. continuity profile 的某种组合。
4. 智能体在写作和审稿时需要理解的语义任务。
5. 探针用来验证系统通用能力的高压场景。

核心代码可以认识 `scope`、`frame`、`transition`、`memory visibility`、`state carry-over`、`segment`、`delivery`、`sidecar`、`review finding`，但不应该直接内置“快穿必须怎样”“死亡回归必须怎样”。

### 1.2 程序化剧情判断不可穷举

`SpecialMechanicExecutionEvaluationService` 当前会读取正文，并用关键词、正则、信号词判断：

1. 是否出现世界切换。
2. 是否出现回归锚点。
3. 是否写出死亡触发。
4. 是否保留上一轮记忆。
5. 是否有路线变化。

这条路天然不稳。

原因不是当前关键词不够多，而是文学表达本身不可穷举。一个章节可以用无数方式表达“转折”“重置”“换世界”“记忆残留”“规则覆盖”。如果核心程序持续补关键词，最终会变成：

1. 越补越重。
2. 越补越误判。
3. 越补越题材化。
4. 越补越难迁移到其他特殊写法。
5. 越补越不像写作系统，而像一组脆弱文本分类器。

程序应该判定结构与合同，语义解释应交给智能体或专门的语义评审任务。

### 1.3 章节边界不足以表达全部连续性

多世界、回档、死亡回归只是最明显的例子。很多一般小说也会在同一章内部发生：

1. 场景转换。
2. 时间跳转。
3. 视角切换。
4. 幻境 / 现实切换。
5. 回忆插叙。
6. 主线 / 支线交叉。
7. 人物身份信息揭示。
8. 世界规则临时覆盖。

尤其是一章数千字乃至上万字的轻小说或长篇章节，关键转折可能出现在章中，而不是章首或章尾。

所以未来连续性系统不能只维护“上一章最终状态 -> 下一章初始状态”。更合理的是：

1. 每章可以有 0..N 个内部 segment。
2. 每个 segment 可以绑定 scope、frame、scene、time、POV、constraint coverage。
3. 每个 segment 可以记录 transition point。
4. 章节最终状态只负责推进下一章，但内部状态变更要能被检索、审稿、修复、拆书承接。

这点对普通小说、长任务、拆书续写、未来特殊写法都适用。

---

## 二、当前项目现状判断

### 2.1 已有的好基础

项目并不是从零开始，已有多块基础方向是对的。

#### continuity 层

已有：

1. `packages/novel_agent_core/lib/src/continuity/continuity_mechanic_profile.dart`
2. `packages/novel_agent_core/lib/src/continuity/continuity_frame.dart`
3. `packages/novel_agent_core/lib/src/continuity/continuation_scope.dart`
4. `packages/novel_agent_core/lib/src/continuity/continuity_runtime_resolver_service.dart`
5. `packages/novel_agent_core/lib/src/continuity/project_continuity_bundle.dart`

这些说明我们已经有“作用域 / frame / mechanic profile 组合”的底座。问题不是没有 continuity，而是后续某些实现又绕回了“特殊机制服务直接读正文判断题材语义”。

#### 章节交付层

已有：

1. `ChapterDeliveryContract`
2. `ChapterDeliveryExpectation`
3. `ChapterDeliveryEvidence`
4. `ChapterDeliveryEvaluation`
5. `ChapterDeliveryRecoveryPolicy`
6. `ChapterDeliveryRecoveryPlan`

这些是正确方向。真正需要继续补的是：把正文落盘、标题-only、空内容、路径漂移、同轮模型证据、重试决策、人工接管等统一纳入章节交付状态机，而不是散落在 probe、postprocess、runtime 分支里。

#### tool round evidence

已有：

1. `ToolRoundAssistantTranscript`
2. `ToolRoundNarrativeEvidence`
3. `ToolRoundToolCallEvidence`
4. `ToolRoundWriteIntent`

这是“模型同轮返回了什么 / 工具调用了什么 / 是否有写入意图 / 是否可修复”的关键合同基础。它应继续扩展为自然的 evidence contract，而不是新增一堆零散补丁参数。

#### supervisor control plane

已有：

1. `RunInstance`
2. `LongTaskRunStatus`
3. `LongTaskSupervisor`
4. `LongTaskHeartbeatScheduler`
5. `LongTaskSupervisorStrategy`
6. `Run Center / Task Center` 投影基础。

这条线和 MuMu 的后台任务思想方向一致：长时间 AI 写作必须变成稳定、可观察、可暂停、可恢复、可接管的任务对象。

#### 正文分段存储

已有：

1. `body_text_document`
2. `body_text_segment`
3. `SqliteProjectBodyTextSegment`

这为未来“章内 segment / transition point / 局部重写 / 精细检索”留下了合适入口。当前段模型还很轻，但方向正确。

### 2.2 已经偏离的地方

#### `special_mechanic` 命名与职责开始污染通用架构

当前存在：

1. `special_mechanic_execution_evaluation_service.dart`
2. `special_mechanic_execution_guidance_service.dart`
3. `special_mechanic_repair_prompt_builder_service.dart`
4. `project_special_mechanic_runtime_state_service.dart`
5. `special_mechanics_long_task`
6. `special_mechanics_supervisor_strategy`
7. `failureKindSpecialMechanicWeak`

这些命名容易让后续开发继续误以为“特殊机制”是一个正式核心类型。实际它应该逐步被降级为：

1. 旧版本兼容标签。
2. 某类 continuity constraint preset 的展示名。
3. 探针测试场景标签。
4. 临时迁移桥。

它不应继续作为核心架构的扩展方向。

#### `SpecialMechanicExecutionEvaluationService` 职责过界

它当前既读正文，又判语义，又输出状态，还驱动后续 repair。这会造成三个问题：

1. 程序成为文学语义裁判。
2. 单一服务持续吸收新题材信号。
3. 后续其他特殊写法也会被迫进入同一个判断器。

合理方向是：

1. 保留为 legacy weak smoke check，短期不继续扩展。
2. 不让它成为 gating 的主判断来源。
3. 迁移到通用 `ContinuitySemanticReview` 或 `ContinuitySidecar` 合同后逐步废弃。

#### `SpecialMechanicExecutionGuidanceService` 也应去题材化

它当前根据 profile 推导多世界 / replay 指令，提示词内容本身有价值，但不应写成固定“多世界/回归”分支。

更合理的方式是：

1. 通用 constraint package 提供 instruction snippets。
2. 用户或项目可以新增 / 引用 / 固化约束。
3. 内置 preset 只在应用层或 profile catalog 层提供，不进入核心 workflow 分支。
4. guidance service 只负责把约束包投影成写作提示，不硬判题材。

#### `special_mechanics_long_task` 不应成为长期正式类型

当前 registry 中的 `special_mechanics_long_task` 描述为“多世界、快穿、死亡回归、回档等特殊机制共用的连续性扩展画像”。这个画像短期可以作为兼容入口，但长期应迁移成更中性的类型，例如：

1. `continuity_constrained_long_task`
2. `constraint_guided_long_task`
3. `continuity_intensive_long_task`

核心判断应基于：

1. 是否有 continuity bundle。
2. 是否有约束包。
3. 是否需要 segment sidecar。
4. 是否需要 semantic review。
5. 是否启用更强章节交付恢复。

而不是基于“是否特殊机制”。

---

## 三、MuMu 可吸收与不可吸收

### 3.1 可吸收：后台任务的中心思想

MuMu 值得吸收的不是 GPL 代码，而是后台任务模型的中心思想：

1. 长时间 AI 过程必须是持久化任务对象。
2. 任务有统一生命周期。
3. 任务有状态、进度、错误、取消、重试、更新时间。
4. 前端消费稳定任务合同，而不是拼日志。
5. 批量生成要记录当前章节、已完成章节、失败章节、重试次数。
6. 用户关掉前端后回来，仍能看到任务现场。

这与我们已有 supervisor 方向一致，但我们需要更细：

1. 不只知道任务 `running / failed`。
2. 还要知道卡在第几章、哪个合同、哪个 gate、哪个证据缺失。
3. 还要知道能不能自动重试、是否需要人工接管。

### 3.2 不可吸收：粗粒度后台任务表不能替代我们的写作 runtime

MuMu 的后台任务模型不能直接替代本项目的 workflow。

NovelAgentFlutter 的核心复杂度在：

1. 章节原子交付。
2. 工具调用证据。
3. 章节修复。
4. 检查点审稿。
5. 连续性状态。
6. 执行约束。
7. 拆书派生。
8. 本地项目文件和数据库双轨存储。

所以我们应该吸收 MuMu 的“任务可观察 / 可恢复 / 可取消 / 可重试”的控制面思想，但不能把本项目压平成一个简单后台任务表。

更准确的定位是：

**本项目需要“本地 workflow 事实源 + 非 LLM supervisor 控制面 + 章节交付合同 + 语义 sidecar”的组合。**

### 3.3 MuMu 没有替我们解决的部分

MuMu 不解决：

1. 文学语义连续性。
2. 章内 segment。
3. 复杂约束包。
4. 拆书后续写承接。
5. 多作用域记忆覆盖。
6. 同轮模型 evidence 修复。

这些必须由我们自己的 continuity / constraint / delivery architecture 承担。

---

## 四、目标架构原则

### 4.1 程序管合同，智能体管语义

程序应该负责：

1. 合同是否存在。
2. 字段是否完整。
3. 文件是否落盘。
4. 路径是否正确。
5. 正文是否为空。
6. 字数是否严重偏离目标窗口。
7. sidecar 是否结构化。
8. 引用的 segment / scope / frame 是否存在。
9. 重试次数是否超过策略。
10. 任务是否心跳 stale。

智能体应该负责：

1. 本章是否真的发生了用户要求的转折。
2. 角色心理是否符合设定。
3. 回归锚点是否文学上清楚。
4. 世界边界是否被读者感知。
5. 前后文风是否连续。
6. 是否像 AI 腔。
7. 是否存在剧情逻辑断裂。

程序可以要求智能体输出结构化报告，但不应把关键词命中当作最终文学判断。

### 4.2 核心只建通用连续性能力，不建题材 if/else

核心层应认识的中性概念：

1. `ContinuityConstraintPackage`
2. `ContinuityRuntimeState`
3. `ContinuityScope`
4. `ContinuityFrame`
5. `ContinuitySegment`
6. `ContinuityTransition`
7. `ContinuityStateDelta`
8. `MemoryVisibility`
9. `StateCarryOverPolicy`
10. `SemanticReviewFinding`
11. `ChapterContinuitySidecar`

核心层不应认识的硬编码题材：

1. 快穿。
2. 死亡回归。
3. 多世界。
4. 回档。
5. 恢复存档。
6. 梦境线。
7. 任何未来用户自定义写法。

这些可以作为应用层 preset、测试输入、用户约束、智能体任务说明存在。

### 4.3 章节交付先于内容质量

真实稳定性首先要保证：

1. 该写第 N 章时，确实写出第 N 章。
2. 正文路径正确。
3. 正文不是空文件。
4. 正文不是只有标题。
5. 同轮 evidence 可追踪。
6. 写失败能重试。
7. 重试失败能清楚接管。

在这些成立之前，讨论“特殊机制信号强弱”会混入大量技术性假失败。

因此后续稳定性修复顺序应是：

1. 章节交付合同。
2. 交付恢复状态机。
3. 字数与表达限制执行约束。
4. continuity sidecar。
5. 语义评审。
6. 探针验收。

### 4.4 章内分段是连续性的长期关键

章节不应是连续性的最小单位。

目标模型：

1. Chapter 负责用户可读交付。
2. Segment 负责内部语义片段。
3. Transition 负责状态变化点。
4. Sidecar 负责把章节正文和 continuity 状态连接起来。

一个章节可能：

1. 无状态变化。
2. 有一个状态变化。
3. 有多个状态变化。
4. 在章中切换 scope。
5. 在章中回忆旧 frame。
6. 在章中触发约束的局部覆盖。

最终推进下一章的是“章节末状态”，但系统必须保留章内变化证据。

### 4.5 约束应是通用资产，而不是长任务私产

字数限制、表达限制、去 AI、风格限制、题材约束、连续性约束，不只属于长任务。

它们应适用于：

1. 普通小说项目。
2. 普通章节生成。
3. 长任务章节队列。
4. 拆书续写。
5. 分散式用户手动生成。
6. 未来其他写作模式。

长任务只是更依赖这些约束的场景，不应独占实现。

### 4.6 supervisor 是非 LLM 控制面，不是语义裁判

监管层应负责：

1. 心跳。
2. stale 检测。
3. pause / resume / stop。
4. dispatch。
5. retry。
6. recovery plan。
7. waiting user 与技术失败的区分。
8. 有界事件窗口。
9. 运行现场投影。

监管层不应负责：

1. 阅读正文判断文学效果。
2. 判断“这是否真正像死亡回归”。
3. 判断“这个世界切换是否足够有冲击力”。

语义判断可以由智能体评审任务产出结构化 finding，supervisor 根据 finding 的严重程度和策略决定是否阻塞。

---

## 五、建议目标合同

### 5.0 智能体产出时机与程序交互方式

如果只定义 sidecar、semantic review、constraint package，却不定义“谁在什么时候产出、通过什么方式交给程序”，这套架构仍然不完整。

本项目的事实源应继续坚持一个原则：

**智能体的大部分有效交互通过工具或结构化合同进入程序，程序不把聊天正文当成隐式状态源。**

也就是说，写作智能体可以在自然语言里思考、起草、说明，但真正会推进项目状态的，应是工具调用和工具结果。

#### 5.0.1 写作智能体：章节交付的第一责任人

写作智能体在“生成本章正文”的任务轮里，应承担两类产出：

1. 章节正文。
2. 本章连续性 sidecar 的最小结构化信息。

触发时机：

1. 程序派发一个明确的 `write_chapter` / `draft_chapter` 任务。
2. prompt 中包含本章目标、字数策略、表达限制、continuity context、上一章 sidecar 摘要、交付路径。
3. 智能体完成本章正文后，必须通过工具交付。

短期兼容形态：

1. 调用 `write_project_file` 写入 `chapters/第NN章.md`。
2. 再调用 `write_project_file` 写入 `tracking/continuity_sidecars/第NN章.json` 或同类约定路径。
3. 如果模型只写了正文但没写 sidecar，程序可把 sidecar 视为缺失的附属工件，进入轻量补做，而不是把正文交付判为完全失败。

长期更优形态：

1. 新增领域级工具，例如 `submit_chapter_delivery`。
2. 该工具一次性接收：
   - `chapter_path`
   - `chapter_content`
   - `sidecar`
   - `declared_written_segments`
   - `declared_transitions`
   - `constraint_coverage`
3. 工具内部负责写正文、写 sidecar、建立 evidence、返回统一 `ChapterDeliveryContract`。

长期形态比两个 `write_project_file` 更自然，因为“完成一章”本来就是一个领域动作，不应永久拆成一组脆弱文件写入动作。

#### 5.0.2 转折发生后谁记录

转折点、作用域切换、回忆插叙、回档、梦境、身份覆盖等，应该由“正在写这一章的写作智能体”在本章 sidecar 中声明。

原因：

1. 写作智能体最清楚自己刚刚写了什么。
2. 转折可能发生在章内任意位置，程序不应扫关键词猜测。
3. 让另一个评审智能体事后从零识别，会增加成本，也可能误读。

但写作智能体的声明不能无条件成为最终事实。

程序应做结构校验：

1. sidecar JSON 是否合法。
2. segment 顺序是否合理。
3. transition 引用的 segment 是否存在。
4. final state 是否可序列化。
5. scope/frame id 是否来自项目 continuity bundle，或被明确声明为新建候选。
6. evidence span 是否能在正文中找到大致对应文本。

评审智能体再做语义复核：

1. 写作智能体声明“发生了转折”，但正文是否真的让读者能感知。
2. 声明“主角保留记忆”，但正文是否让其他角色错误知道前轮信息。
3. 声明“进入新作用域”，但世界规则是否混写。

因此权责链应是：

1. 写作智能体声明。
2. 程序结构校验。
3. 评审智能体语义复核。
4. supervisor 根据策略决定接受、轻修、重写、暂停或人工接管。

#### 5.0.3 评审智能体：交付后运行，不替代写作交付

评审智能体不应该抢写作智能体的交付工具，也不应该在正文未落盘时讨论内容质量。

触发时机：

1. 章节正文已经落盘。
2. `ChapterDeliveryContract` 至少达到“正文存在且可读”。
3. sidecar 存在，或本章被策略标记为需要补做 sidecar。
4. 字数、表达限制、连续性等需要语义判断的检查进入 review 阶段。

输入：

1. 本章正文。
2. 本章 sidecar。
3. 上一章 sidecar。
4. 当前 continuity bundle。
5. 当前 constraint package。
6. 本章任务目标。

输出方式：

1. 通过工具保存结构化 review report。
2. 或调用未来的 `submit_semantic_review` 领域工具。

输出内容：

1. findings。
2. severity。
3. evidence excerpts。
4. confidence。
5. suggested repair intent。
6. 是否建议阻塞。

评审智能体只给建议，不直接拥有调度权。

#### 5.0.4 恢复 / 修复智能体：由程序调度，目标必须单一

当章节交付失败或质量 gate 失败时，程序可以派发恢复 / 修复任务。

触发时机：

1. 正文缺失。
2. `write_project_file` content 为空。
3. 只有标题或正文严重不足。
4. 路径漂移。
5. 字数严重偏离策略窗口。
6. 表达限制严重失败。
7. semantic review 给出阻塞级 finding。

交互方式：

1. 程序生成明确的 recovery plan。
2. 修复智能体只拿到必要上下文和目标文件。
3. 修复智能体通过 `edit_project_file` 或 `write_project_file(overwrite=true)` 修改目标。
4. 修复后重新进入 `ChapterDeliveryContract` 评估。

重要边界：

1. 恢复智能体不应同时承担“继续写下一章”和“修本章”的任务。
2. 修正文风和修正文缺失应分开。
3. 缺正文优先重写，不应先做语义评审。
4. 表达限制 / 字数轻微偏差不一定立刻重写，应遵守硬执行窗口与软审核窗口。

#### 5.0.5 supervisor：调度智能体，但不解释文学

supervisor 负责决定下一步派发哪个任务：

1. 继续下一章。
2. 重试当前章。
3. 补做 sidecar。
4. 运行 semantic review。
5. 运行 repair。
6. 回到 checkpoint。
7. 暂停等待用户。
8. 标记人工接管。

但 supervisor 不应直接读取正文判断“这是否像快穿”或“这是否像死亡回归”。

它只消费：

1. `ChapterDeliveryContract`
2. `ChapterContinuitySidecar`
3. `SemanticReviewReport`
4. `ExecutionConstraintEvaluation`
5. `ToolRoundEvidence`
6. `RunInstance` 状态
7. retry counters

调度权在 supervisor，语义解释权在智能体报告，结构真相在程序合同。

#### 5.0.6 工具层应演化为领域工具，而不是无限堆文件工具提示

当前 `write_project_file` 是必要底座，但它太低层。长期只靠提示词要求“请写正文、再写 sidecar、再写 review”会继续出现：

1. 漏写 sidecar。
2. 空 content。
3. 写错路径。
4. 只读轮。
5. 工具调用被其他任务抢走。
6. 程序难以判断这一轮到底是在完成章节、补证据还是写报告。

因此建议逐步引入领域工具：

1. `submit_chapter_delivery`
2. `submit_chapter_sidecar`
3. `submit_semantic_review`
4. `submit_repair_result`

这些工具不一定马上替代 `write_project_file`，但应成为后续架构方向。它们的价值是把“领域动作”显式交给程序，而不是让程序从一堆文件写入中反推意图。

### 5.1 `ChapterContinuitySidecar`

每章正文旁应有结构化 sidecar。它不替代正文，只描述正文与连续性状态的关系。

建议字段：

1. `chapter_id`
2. `chapter_path`
3. `source_run_id`
4. `segments`
5. `transitions`
6. `initial_state_ref`
7. `final_state_ref`
8. `constraint_coverage`
9. `semantic_review_summary`
10. `uncertainty`
11. `evidence_spans`

作用：

1. 给后续章节提供上下文。
2. 给 checkpoint review 提供结构化素材。
3. 给拆书承接提供可复用连续性材料。
4. 给恢复流程判断“上一轮到底写了什么”。
5. 避免程序直接读整章正文猜语义。

### 5.2 `ContinuitySegment`

建议字段：

1. `segment_id`
2. `ordinal`
3. `chapter_id`
4. `text_span`
5. `scope_id`
6. `frame_id`
7. `pov`
8. `time_marker`
9. `location_marker`
10. `segment_kind`
11. `summary`
12. `state_delta_ref`

它可以复用并扩展现有 `body_text_segment` 思路。短期不一定要马上把所有正文切成精细段，但合同要先朝这个方向设计。

### 5.3 `ContinuityTransition`

建议字段：

1. `transition_id`
2. `segment_id`
3. `transition_kind`
4. `from_scope_id`
5. `to_scope_id`
6. `from_frame_id`
7. `to_frame_id`
8. `trigger_summary`
9. `state_delta`
10. `memory_visibility_delta`
11. `evidence`
12. `confidence`

注意：`transition_kind` 应是开放字符串或可扩展 registry，不应是写死枚举。

快穿、回档、梦境、插叙、身份揭示、时间跳跃都可以映射成 transition，但核心不需要知道它们的题材名。

### 5.4 `ContinuityConstraintPackage`

建议字段：

1. `constraint_id`
2. `display_name`
3. `source`
4. `scope`
5. `visibility`
6. `prompt_instructions`
7. `review_instructions`
8. `hard_execution_policy`
9. `soft_review_policy`
10. `user_permission_policy`
11. `version`
12. `metadata`

这与之前讨论的远期执行约束层一致。短期不必全量实现权限系统，但新修改应向这个方向偏靠。

### 5.5 `ContinuitySemanticReviewTask`

语义评审不应是核心程序关键词判断，而应是一个可以被调度的智能体任务。

输入：

1. 本章正文。
2. 当前 continuity bundle。
3. 约束包。
4. 上一章 sidecar。
5. 本章目标。
6. 用户要求。

输出：

1. 结构化 findings。
2. evidence excerpts。
3. confidence。
4. suggested repairs。
5. 是否阻塞的建议，不直接拥有最终调度权。

### 5.6 `ChapterDeliveryStateMachine`

章节交付恢复要成为正式状态机，而不是散落逻辑。

它应识别：

1. `delivered`
2. `missing_artifact`
3. `empty_content`
4. `title_only`
5. `wrong_path`
6. `read_only_round`
7. `tool_argument_invalid`
8. `assistant_text_only_recoverable`
9. `length_severe_deviation`
10. `constraint_review_failed`
11. `manual_attention_required`

它应决策：

1. 直接接受。
2. 用同轮 assistant transcript 修复。
3. 要求模型重写同章。
4. 要求模型补写正文。
5. 要求模型按约束轻修。
6. 回到 checkpoint。
7. 暂停等待用户。
8. 标记人工接管。

这部分是稳定性最优先的生产链路，不应只留给 probe 判断。

---

## 六、现有实现的迁移方向

### 6.1 冻结 `SpecialMechanicExecutionEvaluationService` 的扩张

短期：

1. 保留现有服务以避免破坏旧测试和旧记录。
2. 标记为 legacy / advisory。
3. 不继续往里面添加新的剧情关键词。
4. 不让它成为长任务能否继续的唯一语义 gate。

中期：

1. 新增通用 `ContinuitySemanticReview` 合同。
2. 把特殊机制弱信号迁移为 semantic finding。
3. repair prompt 由 finding + constraint package 生成。

长期：

1. 删除或完全降级 `SpecialMechanicExecutionEvaluationService`。
2. 只保留兼容读取旧记录的 codec。

### 6.2 重命名或弱化 `special_mechanics_long_task`

短期：

1. 不直接删除，避免旧 run record 和测试断裂。
2. 文档明确它是历史兼容画像。
3. 新逻辑优先解析到 `continuity_guarded_long_task` 或未来的 `constraint_guided_long_task`。

中期：

1. 新增中性画像：`continuity_constrained_long_task`。
2. 把 artifact profile 从“特殊机制工件”改成“连续性约束工件”。
3. supervisor strategy 从“特殊机制监管策略”迁移到“约束密集型监管策略”。

长期：

1. `special_mechanics_long_task` 只作为 alias。
2. 探针场景可以仍叫快穿、死亡回归，但不影响核心类型。

### 6.3 改造 guidance 生成链

当前 `SpecialMechanicExecutionGuidanceService` 中的提示词指令应迁移为：

1. constraint package instruction。
2. continuity profile projection。
3. 项目级自定义约束。
4. 任务目标里的自然语言写法要求。

核心 guidance service 只负责组合：

1. 章节目标。
2. 字数策略。
3. 表达限制。
4. continuity sidecar 摘要。
5. constraint package 指令。
6. delivery contract 要求。

不负责识别“这是快穿还是死亡回归”。

### 6.4 把章内 segment 与正文存储接上

现有 `body_text_segment` 是很好的承接口。

建议演化：

1. 保留文档级 markdown 文件作为用户可读产物。
2. 保留 body text segment 作为结构化索引。
3. sidecar 记录 segment 与 continuity state 的关系。
4. 不要求第一阶段就自动切得完美，但要支持智能体生成 sidecar。
5. 后续拆书也可产出同形态 segment/transition，供续写复用。

### 6.5 章节交付恢复优先进入 core contract

应避免继续把缺章、空正文、标题-only、路径漂移修复塞进 `ProjectWorkflowRuntimeService`。

建议：

1. core 层定义状态机、分类、恢复 plan。
2. adapters 层负责读写项目文件、取 execution record、调工具。
3. runtime service 只做薄编排。
4. probe 只做验收，不做生产恢复逻辑。

### 6.6 语义评审和调度权分离

未来 semantic review 可以说：

1. 本章疑似没有完成世界切换。
2. 本章没有体现重置后的路线变化。
3. 本章角色记忆范围不清楚。
4. 本章与前文风格不一致。

但它不应直接决定任务停止。最终阻塞与否由：

1. supervisor strategy。
2. chapter delivery state。
3. constraint severity。
4. retry policy。
5. user policy。

共同决定。

---

## 七、任务类型与项目类型的协调

### 7.1 普通小说项目

普通项目也需要：

1. 字数目标。
2. 表达限制。
3. 去 AI。
4. 章节交付 gate。
5. 分散式生成后的上下文接续。
6. 可选 continuity sidecar。

普通项目不应因为不是长任务，就绕开执行约束和交付合同。

### 7.2 普通长任务

普通长任务应是：

1. 章节交付合同最强制。
2. checkpoint review 稳定。
3. 字数策略和表达限制稳定。
4. supervisor 能恢复缺章、空写、只读轮、路径漂移。

它不需要任何特殊剧情内置。

### 7.3 约束密集型长任务

这类任务可以覆盖当前所谓“特殊机制”测试。

它的本质不是特殊题材，而是：

1. 约束更多。
2. continuity state 更复杂。
3. 语义 sidecar 更重要。
4. review frequency 更高。
5. 恢复策略更谨慎。

### 7.4 拆书续写

拆书续写需要同样的底座，但额外强调：

1. 从原书抽取 continuity bundle。
2. 从原书抽取 segment / transition / state delta。
3. 派生项目固化所需约束与资产。
4. 后续续写走普通项目或长任务路径，不走拆书私有路径。

拆书是资源生成入口，不应拥有一套独立写作 runtime。

### 7.5 未来新类型

未来可能加入：

1. 剧本。
2. 互动小说。
3. 多主角群像。
4. 游戏剧情。
5. 世界观设定集。
6. 系列作品续写。

这些都不应逼迫 core 新增题材分支。应通过：

1. constraint package。
2. continuity profile。
3. delivery profile。
4. semantic review task。
5. supervisor strategy。

组合得到。

---

## 八、辩证取舍

### 8.1 为什么不完全依赖智能体

完全依赖智能体会带来：

1. 稳定性不可预测。
2. 失败后无法可靠恢复。
3. UI 无法知道任务现场。
4. 长任务可能静默停滞。
5. 同类错误反复消耗 token。

所以程序必须保留硬合同、状态机、持久化与调度权。

### 8.2 为什么不完全依赖程序

完全依赖程序会带来：

1. 创作语义不可穷举。
2. 关键词误判。
3. 新题材需要改代码。
4. 文学表达被迫模板化。
5. 用户自定义写法被系统误杀。

所以语义理解必须交给智能体或审稿任务。

### 8.3 最合理的中间路线

程序负责“可证明的事实”：

1. 文件存在。
2. 内容非空。
3. 路径正确。
4. 字数窗口。
5. 合同字段。
6. 状态引用。
7. 重试次数。
8. 心跳。

智能体负责“需要理解的语义”：

1. 剧情转折。
2. 文风。
3. 人设。
4. 世界规则表达。
5. 读者感知。
6. 前后呼应。

两者通过结构化 sidecar 和 findings 连接。

### 8.4 为什么现在要先纠偏，而不是继续硬测

继续用当前架构硬测 200 章双线探针，可能只会不断暴露同一类问题：

1. 程序化机制判断误判。
2. 缺正文恢复不完整。
3. 语义探针和生产链路混杂。
4. `special_mechanic` 继续膨胀。
5. 特定测试场景被误写成核心能力。

先纠偏架构，后续再跑长探针，结果才有意义。

---

## 九、后续应改哪里

### 9.1 core 层优先

优先新增或演化：

1. `packages/novel_agent_core/lib/src/continuity/chapter_continuity_sidecar.dart`
2. `packages/novel_agent_core/lib/src/continuity/continuity_segment.dart`
3. `packages/novel_agent_core/lib/src/continuity/continuity_transition.dart`
4. `packages/novel_agent_core/lib/src/continuity/continuity_constraint_package.dart`
5. `packages/novel_agent_core/lib/src/continuity/continuity_semantic_review.dart`
6. `packages/novel_agent_core/lib/src/workflow/chapter_delivery_state_machine.dart`
7. `packages/novel_agent_core/lib/src/workflow/chapter_delivery_failure_kind.dart`
8. `packages/novel_agent_core/lib/src/workflow/chapter_delivery_recovery_decision_service.dart`

这些应保持纯逻辑、无文件系统、无 UI、无模型调用。

### 9.2 adapters 层承接项目读写

应演化：

1. `project_chapter_delivery_evaluation_service.dart`
2. `project_chapter_delivery_recovery_service.dart`
3. `project_draft_postprocess_service.dart`
4. `project_continuity_runtime_payload_service.dart`
5. `sqlite_project_body_text_store.dart`
6. `project_special_mechanic_runtime_state_service.dart`

其中 `project_special_mechanic_runtime_state_service.dart` 应逐步迁移到中性 continuity runtime state 服务。

### 9.3 workflow runtime 保持薄编排

`project_workflow_runtime_service.dart` 已经过重。后续不应继续往里面堆：

1. 缺正文重试算法。
2. 标题-only 判断算法。
3. 章内 segment 解析算法。
4. 特殊机制语义判断。
5. 约束包权限策略。

它应只负责调用小服务并串联结果。

### 9.4 app / CLI 最后对接

GUI、CLI、探针都应最后消费稳定合同。

顺序应是：

1. core contract。
2. adapters 读写与 runtime 接线。
3. focused tests。
4. probe 更新。
5. CLI / GUI 投影。

不要先改 UI 去猜状态。

### 9.5 探针改造

探针应改成：

1. 不把快穿 / 死亡回归判断写成 production 逻辑。
2. 不在 probe 内实现恢复。
3. 只负责构造高压约束输入、启动真实 runtime、读取正式合同、验收结果。
4. 保留输出产物供人工阅读。
5. 报告中区分技术失败、交付失败、语义评审失败、验收目标未达成。

---

## 十、建议迁移阶段

### 阶段 1：冻结题材硬判扩张

目标：

1. 不再给 `SpecialMechanicExecutionEvaluationService` 加新规则。
2. 文档标记 special mechanic 为 legacy/advisory。
3. 新测试不要求核心程序认识具体题材。

完成标准：

1. 新增约束不进入 special mechanic if/else。
2. 现有测试仍可兼容运行。

### 阶段 2：补章节交付状态机

目标：

1. 缺正文、空正文、标题-only、路径漂移、read-only round 可分类。
2. 同章重试和同轮 evidence 修复可正式决策。
3. `waiting_user` 不再误用为技术失败。

完成标准：

1. 章节没写出时能自动恢复或明确人工接管。
2. supervisor 能读取正式状态，而不是从日志猜。

### 阶段 3：引入 sidecar 最小合同

目标：

1. 每章可选产出 continuity sidecar。
2. sidecar 至少记录 chapter summary、final state、constraint coverage、uncertainty。
3. 不要求第一阶段做到完美 segment。

完成标准：

1. 后续章节能读取上一章 sidecar。
2. review / repair 能引用 sidecar，而不是全靠扫正文。

### 阶段 4：迁移语义评审

目标：

1. 把特殊机制弱信号迁移为通用 semantic review finding。
2. LLM 输出结构化报告。
3. 程序只校验报告结构和引用。

完成标准：

1. 快穿 / 死亡回归探针不依赖程序关键词判断。
2. 其他用户自定义写法也能走同一评审链。

### 阶段 5：中性化任务画像与策略

目标：

1. 新增 `continuity_constrained_long_task` 或等价中性画像。
2. `special_mechanics_long_task` 降级为 alias。
3. supervisor strategy 根据约束密度、交付风险、review 策略决策。

完成标准：

1. 核心 long task 类型不再以题材命名。
2. 旧 run record 仍能兼容。

### 阶段 6：章内 segment 深化

目标：

1. 扩展 body text segment 模型。
2. sidecar 引用 segment。
3. transition 可在章内发生。

完成标准：

1. 一章内多个状态变化可以被记录。
2. 拆书与续写共享同一 segment/transition 合同。

### 阶段 7：重新跑真实长探针

目标：

1. 用快穿、死亡回归作为约束包测试，而不是核心题材测试。
2. 200 章以内预算可以保留，但不预排死每章剧情。
3. 分段长度由智能体根据创作节奏自由调整。
4. 至少三次转折作为验收目标由语义 sidecar/review 证明。

完成标准：

1. 技术交付稳定。
2. 缺章能恢复。
3. 字数策略可控。
4. 表达限制有效。
5. 语义目标有结构化证据。
6. 探针报告与人工阅读产物一致。

---

## 十一、对当前问题的最终判断

当前稳定性问题反复出现，不是因为某一个探针写得不够狠，也不是因为某个关键词漏了，而是因为几条职责边界混在了一起：

1. 章节交付失败和语义质量失败混在一起。
2. 程序结构校验和文学语义判断混在一起。
3. 特定测试题材和通用 continuity 能力混在一起。
4. production 恢复链和 probe 验收链混在一起。
5. supervisor 控制面和内容评审权混在一起。

正确演化方向是：

1. 章节交付先稳定。
2. 约束成为通用资产。
3. continuity 用 scope/frame/segment/transition 表达。
4. 语义由智能体结构化报告。
5. 程序只管合同、状态、恢复与一致性。
6. MuMu 式后台任务思想用于控制面，不用于替代我们的写作 runtime。
7. `special_mechanic` 从核心概念降级为历史兼容和探针标签。

这条路短期比继续补关键词更慢，但它能真正结束反复在同类问题里打转的状态。

---

## 十二、后续任务顺序文档应遵守的硬约束

如果基于本文生成任务顺序文档，应明确写入：

1. 不把快穿、死亡回归、多世界、回档等测试场景硬写进核心代码。
2. 每个任务必须能在一个会话内完成，约 2000 行以内变更量。
3. core 合同先行，adapters 接线其次，probe 验收再次，GUI/CLI 最后。
4. 不让 `ProjectWorkflowRuntimeService` 继续吸收新算法。
5. 不扩张 `SpecialMechanicExecutionEvaluationService`。
6. 不让 probe 成为 production recovery 的实现地。
7. 所有新语义判断必须通过结构化 sidecar / semantic review / findings 合同进入系统。
8. 所有新约束应默认适用于普通项目、长任务、拆书续写等多路径。
9. supervisor 只做非 LLM 控制面，不做文学语义裁判。
10. 旧 special mechanic 记录要兼容，但新架构命名必须中性化。

---

## 十三、过渡稿：从题材机制转向通用变化模型（已被第十四章替代）

本节保留为历史推理记录，不再作为后续实现依据。

它的价值是指出“题材机制不能进核心”，但它仍然沿用了若干容易被实现者误读成默认分类表的种子词汇。后续设计、任务顺序和实现应以第十四章的重设计为准：核心不预设变化种类，不把示例当范本，不从题材或少量状态维度出发，而从“系统如何承接未知叙事变化”出发。

### 13.1 新问题的本质

前文已经纠正了一个偏差：快穿、死亡回归、多世界、回档等不应该成为核心代码里的题材分支。

但这还不够。

这里必须先补一条更强的纠偏：**用户、探针和本文列出的所有题材、变化方式、状态维度都只是例子，不是范本，更不是分类全集。**

后续任何实现都不能把这些例子变成：

1. 固定枚举。
2. 题材判断分支。
3. 仅支持这些变化的 UI 选项。
4. 探针专属的验收清单。
5. 不能扩展的 prompt 模板。

真正要固定的是“如何承接未知变化”的合同，而不是“目前想到过哪些变化”。

真正更通用的问题是：**任何小说都不是静态连续性。**

普通小说也可能出现许多变化，例如：

1. 角色因为创伤、胜利、背叛、失去、觉醒而性格突变。
2. 角色被传送、被带走、流放、入学、入职、入狱，导致环境和周围角色变化。
3. 角色换身份、换阵营、换社会位置。
4. 关系网重组，敌友转换。
5. 世界规则被揭示、被推翻、被局部覆盖。
6. 时间、视角、叙事层级发生变化。
7. 主角信息量与其他角色信息量分离。

快穿、死亡回归、聊天群、主神空间等也只是更极端的压力样本，例如：

1. 快穿：scope 大幅切换，少数参与者携带状态，其余环境和关系网重建。
2. 死亡回归：frame 重置，环境和时间回滚，少数记忆或心理创伤保留。
3. 聊天群 / 主神空间：多个 scope 并行可见，角色可能在主世界和任务世界之间携带有限状态。
4. 一般搬迁 / 被带走：scope 切换较弱，身份和记忆通常连续，关系网局部替换。
5. 一般性格突变：scope 不变，但 character state / relationship state / value system 发生明显 delta。

这几类例子绝对不能被理解为“我们要支持的全部变化”。真实小说还可能出现大量暂时无法命名的叙事手法、流派、混合结构和作者自定义规则。系统必须优先支持未知形态进入结构化合同。

所以架构不应问：

1. 这是不是快穿？
2. 这是不是死亡回归？
3. 这是不是某个特殊流派？

而应问：

1. 哪些状态维度发生了变化？
2. 变化半径有多大？
3. 哪些事实保留，哪些事实重置，哪些事实对谁可见？
4. 哪些变化需要进入 sidecar，哪些只需要进入普通摘要？
5. 哪些变化需要语义评审，哪些只需要结构记录？

### 13.2 核心抽象：变化半径，而不是题材类型

建议把各种小说变化统一抽象为 `NarrativeChangeEvent` 或等价合同。它不是“剧情类型”，而是一个状态变化记录。

核心字段可以是：

1. `change_id`
2. `chapter_id`
3. `segment_id`
4. `change_kind`
5. `change_radius`
6. `affected_entities`
7. `affected_scopes`
8. `affected_frames`
9. `state_deltas`
10. `carry_over_policy`
11. `visibility_policy`
12. `evidence_spans`
13. `confidence`
14. `uncertainty`

其中 `change_kind` 应是开放字符串或可扩展 registry 值，不应成为硬编码枚举。下面只是种子词汇，用来帮助 prompt 和 UI 起步：

1. `character_state_shift`
2. `location_scope_shift`
3. `relationship_network_shift`
4. `identity_overlay`
5. `memory_visibility_shift`
6. `rule_reveal`
7. `frame_reset`
8. `parallel_scope_contact`
9. `custom`

核心程序只校验结构，不解释文学含义。遇到未知 `change_kind` 时，应保留原值和说明，最多标记为 `custom` / `unknown` 以便 review，而不是丢弃、拒绝或映射到错误类型。

`change_radius` 更重要。它表达这次变化的影响半径，而不是流派名字。可用轻量层级：

1. `local`：局部状态变化，如一场对话导致关系紧张。
2. `character`：角色心理、能力、身份、目标明显变化。
3. `relationship`：关系网、阵营、权力结构变化。
4. `scene_scope`：地点、场景规则、参与角色变化。
5. `arc_scope`：篇章目标或阶段环境变化。
6. `world_scope`：世界、时间线、规则系统明显变化。
7. `frame_scope`：因回档、梦境、模拟、轮回等导致因果框架变化。
8. `project_scope`：作品根设定或叙事协议变化。

这些值只能作为默认种子 registry，不能作为封闭枚举。程序可以根据半径决定是否需要 sidecar、review、checkpoint 或用户确认，而不是根据“快穿/死亡回归”判断。遇到新半径描述时，应允许智能体提交自定义值，并用 confidence / uncertainty / evidence 帮助后续 review。

### 13.3 状态维度：用向量表达，而不是试图列完流派

不同小说流派未来无法穷举，但连续性变化通常会落在一组相对稳定的状态维度上。

建议把 sidecar / semantic review 的 state delta 投影到若干常见维度。下面仍然只是种子维度，不是全部：

1. `identity`：角色身份、称谓、伪装、社会位置、肉身/壳体。
2. `memory`：谁记得什么，谁遗忘什么，谁拥有元信息。
3. `psychology`：性格、价值观、创伤、执念、动机变化。
4. `capability`：能力、装备、权限、资源变化。
5. `relationship`：亲疏、阵营、敌友、信任、债务、支配关系。
6. `location`：地点、世界、区域、空间规则。
7. `time`：时间点、回档点、跳跃、插叙、加速。
8. `causality`：因果线是否连续、覆盖、分叉、重写。
9. `visibility`：哪些事实对叙事者、主角、配角、读者可见。
10. `world_rule`：规则揭示、规则覆盖、局部例外。
11. `narrative_contract`：叙事视角、体裁手法、文风协议、章节结构。

如果某个作品需要新的状态维度，例如宗教仪式、经济系统、梦境规则、游戏数值、群体意识、叙述者可靠性、文本实验规则等，应允许新增自定义维度。核心只要求维度有 id、说明、影响范围和证据，不要求它必须属于内置清单。

这个模型的好处是：

1. 一般小说的性格突变可以记录为 `psychology` delta。
2. 被传送或被带走可以记录为 `location` / `relationship` delta。
3. 死亡回归可以记录为 `time` + `causality` + `memory` delta。
4. 快穿可以记录为 `location` + `identity` + `relationship` + `world_rule` delta。
5. 聊天群可以记录为 `visibility` + `parallel_scope_contact` + `relationship` delta。
6. 未来新流派可以组合、扩展、替换这些维度，而不是新增核心 if/else。

### 13.4 分层处理：不是所有变化都值得重流程

如果追求每个变化都精确建模，系统会变得过重。真正可用的产品需要分层。

建议分为四个连续性强度等级：

1. `lite`
   - 普通项目默认等级。
   - 只记录章节摘要、最终状态和少量显著变化。
   - 不强制章内 segment。

2. `standard`
   - 普通长篇、普通长任务默认等级。
   - 记录每章 final state、显著 change events、约束覆盖。
   - 只在高半径变化时要求 semantic review。

3. `intensive`
   - 约束密集型长任务、拆书续写、多线叙事。
   - 要求 sidecar，记录 segment / transition。
   - checkpoint 更频繁，review 更严格。

4. `forensic`
   - 只用于探针、失败复盘、复杂拆书承接或用户主动开启。
   - 尽量记录 evidence span、细 segment、review finding。
   - 成本高，不应作为默认。

这能解决“通用但不沉重”的矛盾：核心合同统一，但不同项目只开启不同强度的采样和评审。

### 13.5 智能体参与：让智能体设计 profile，但不让智能体独占事实

用户的直觉是对的：智能体参与设计可以减轻心智负担。

但不能完全依赖智能体。合理方式是把智能体放在三个位置：

#### continuity architect agent

项目创建或用户输入复杂设定后，由它生成一份 `ContinuityDesignBrief`。

它负责：

1. 从用户设定中识别可能的状态维度。
2. 建议 continuity intensity。
3. 建议哪些 change radius 需要记录。
4. 建议哪些约束需要进入 constraint package。
5. 给出 sidecar 输出模板。

它不负责：

1. 直接写 production 代码。
2. 替代用户决定作品方向。
3. 在每章都重新设计整套连续性架构。

#### writer agent

写章节时，它负责正文和本章 sidecar 的初稿声明。

它应该声明：

1. 本章是否有显著变化。
2. 变化影响了哪些状态维度。
3. 是否出现 scope / frame / relationship / psychology 等 delta。
4. 哪些证据位置支持这些声明。
5. 哪些地方它不确定。

#### reviewer agent

交付后，它只复核语义，不抢写作交付。

它负责：

1. 判断 writer sidecar 是否与正文一致。
2. 发现遗漏的显著变化。
3. 标注可能的连续性矛盾。
4. 给出 confidence 和 suggested repair。

#### supervisor

supervisor 只消费结构结果：

1. `ChapterDeliveryContract`
2. `ChapterContinuitySidecar`
3. `NarrativeChangeEvent`
4. `SemanticReviewFinding`
5. `ExecutionConstraintEvaluation`

它不直接判断“角色是否真的性格突变合理”，而是根据 finding severity、change radius、retry 策略决定是否继续、修复、暂停或 checkpoint。

### 13.6 触发策略：按风险触发，而不是按题材触发

什么时候需要 sidecar / review / checkpoint，不应由“这是快穿”决定，而应由风险信号决定。

建议触发因子：

1. `change_radius >= arc_scope`
2. 出现 `frame_scope` 或 `world_scope` 变化。
3. 角色核心状态维度变化超过阈值，如 identity / memory / psychology。
4. 本章与上一章 sidecar 的 final state 冲突。
5. 用户显式要求强连续性。
6. 拆书续写项目中进入原书高密度设定区。
7. 长任务连续生成超过一定章节，进入 checkpoint。
8. semantic review confidence 低。
9. 工具交付或 evidence 不完整。
10. 字数、表达限制、剧情约束同时出现偏离。

触发策略可以写成 `ContinuityRiskPolicy`，由项目配置和运行时状态共同决定。

这样，普通小说中的“主角被带去新城市”如果影响很大，也会触发更强记录；快穿中某个日常章如果没有状态变化，也不需要过度审查。

### 13.7 提示词与调度：不要让智能体自由发挥到失控

如果只是告诉智能体“请记录连续性变化”，它可能输出散文式分析，难以进入程序。

更稳的 prompt 合同应要求：

1. 只记录对后续章节有影响的变化。
2. 不要把每个小情绪都记录成 change event。
3. 每个 change event 必须绑定至少一个 state dimension。
4. 高半径变化必须给 evidence span。
5. 不确定时填 uncertainty，不要编造不存在的结构。
6. 没有显著变化时允许输出空 change list。
7. 不得使用题材名替代结构字段，例如不能只写“这是快穿转场”，必须写明 scope、memory、relationship、world_rule 如何变化。

推荐短期提示片段：

```text
请在交付本章正文后提交本章连续性 sidecar。
sidecar 只记录会影响后续章节的显著变化，不要记录普通细节。
每个变化必须说明影响维度，例如 identity、memory、psychology、relationship、location、time、causality、visibility、world_rule。
如果发生世界、时间、环境、关系网、角色性格或身份的重大变化，请声明 change_radius。
如果无法确认，请写入 uncertainty，不要编造。
```

这类提示应由 constraint / continuity 投影层生成，不应散落在每个探针或 workflow 分支里。

### 13.8 产品体验：默认简单，高级可见

用户不应该一开始就面对 scope、frame、transition、state vector 等术语。

建议产品层分成：

1. 默认模式
   - 用户只看到“连续性强度：轻量 / 标准 / 强化”。
   - 普通项目默认轻量或标准。
   - 长任务默认标准。
   - 拆书续写默认强化。

2. 高级模式
   - 用户可以查看和编辑 continuity profile。
   - 可以添加自定义约束。
   - 可以查看 sidecar / change event / review finding。

3. 探针 / 开发模式
   - 展示完整结构化证据。
   - 展示失败分类、retry、review、sidecar 质量。

这样既保留架构能力，也不把用户拖进内部模型。

### 13.9 对现有文档的修正结论

前文提出的 scope / frame / segment / transition / sidecar / semantic review 方向仍然正确，但需要补三点：

1. `transition` 不能只理解为“特殊机制转折”，而应升级为通用 `NarrativeChangeEvent` 或与其并列。
2. continuity sidecar 不应只记录世界切换或回档，也应记录普通小说中足够重要的状态变化。
3. 是否启用重审和强记录，不应由题材标签决定，而应由 change radius、state dimension、risk policy 决定。

也就是说，最终模型不是：

```text
题材 -> 特殊机制 -> 专门判断器
```

而是：

```text
用户设定 / 章节正文 / 项目配置
-> 智能体声明变化
-> 程序校验结构
-> 评审智能体复核语义
-> supervisor 按风险策略调度
```

### 13.10 建议新增或调整的核心合同

后续任务顺序文档中，应考虑这些更通用的合同：

1. `NarrativeChangeEvent`
   - 通用变化事件，不绑定题材。

2. `ContinuityStateDimension`
   - 可扩展 registry，默认提供 identity、memory、psychology、relationship、location、time、causality、visibility、world_rule 等。

3. `ContinuityChangeRadius`
   - 可扩展 registry，默认提供 local、character、relationship、scene_scope、arc_scope、world_scope、frame_scope、project_scope。

4. `ContinuityDesignBrief`
   - 由 continuity architect agent 或用户配置生成，指导项目如何记录变化。

5. `ContinuityRiskPolicy`
   - 根据变化半径、状态维度、项目类型、运行阶段决定是否触发 sidecar、review、checkpoint、repair。

6. `ChapterContinuitySidecar`
   - 保留，但其核心内容应引用 `NarrativeChangeEvent`，而不是只引用 transition。

7. `ContinuitySemanticReview`
   - 保留，但 review 的 findings 应引用 change event / state dimension / evidence span。

### 13.11 取舍：我们不追求一次理解所有小说流派

这里必须克制。

小说流派会持续演化，任何“内置所有写法”的方案都会失败。

我们真正要做到的是：

1. 不让新流派迫使核心代码新增题材分支。
2. 让用户和智能体可以把新写法表达成约束、变化事件和状态维度。
3. 让程序能校验结构、管理风险、恢复交付。
4. 让语义解释以结构化报告进入系统，而不是靠程序扫关键词。
5. 让普通项目默认轻量，不被复杂机制拖慢。
6. 让复杂项目可以逐步打开更强记录和评审。

这才是“均一处理”的平衡点：统一合同，不统一文学表达；统一调度，不统一题材写法；统一证据，不统一创作风格。

### 13.12 对下一轮实现顺序的影响

如果继续往任务顺序文档落地，应调整顺序：

1. 先补 `NarrativeChangeEvent` / `state dimension` / `change radius` 纯 core 合同。
2. 再调整 `ChapterContinuitySidecar`，让它引用 change events。
3. 再补 sidecar 结构校验和 risk policy，不接 UI。
4. 再让写作 prompt 投影出 sidecar/change event 指令。
5. 再做 mock 智能体工具调用测试，验证 writer 能提交正文 + sidecar，review 能提交 finding。
6. 再把旧 special mechanic 弱信号迁移成 semantic finding。
7. 最后才做 GUI / CLI 可视化和真实长探针。

重要约束：

1. 不能把快穿、死亡回归、聊天群、主神空间等写成核心类型。
2. 不能让智能体报告无结构地流入程序状态。
3. 不能让 supervisor 读取正文做文学判断。
4. 不能让普通项目强制承担 forensic 级别成本。
5. 不能让 `ProjectWorkflowRuntimeService` 吸收 change event / risk policy 的算法。

这轮补充后，架构目标应从“支持特殊机制”正式改成：

**支持任意小说中的显著叙事状态变化，并用统一合同、分层成本、智能体结构化报告和非 LLM 调度控制面来稳定承接。**

---

## 十四、重设计：开放叙事状态承接架构

### 14.1 设计立场

本章是对第十三章的重设计。第十三章提出了“变化半径、状态维度、change event”等方向，但仍然容易被后续实现误读成一套默认分类表。新的设计必须换一个起点：

**系统不负责预先定义世界上会出现哪些小说变化；系统只负责稳定承接、保存、验证、评审和调度任何被用户或智能体声明出来的叙事状态变化。**

也就是说，核心问题不再是：

1. 有哪些变化类型？
2. 哪些流派需要哪些字段？
3. 快穿、死亡回归、聊天群、主神空间分别怎么处理？

而是：

1. 未知变化如何进入系统？
2. 智能体如何把自己的理解变成结构化声明？
3. 程序如何校验声明结构，而不解释文学含义？
4. supervisor 如何根据风险和证据调度后续动作？
5. 用户如何在不理解内部术语的情况下获得稳定结果？

这不是沿用旧缺陷，也不是推倒现有可靠部分。它是保留正确骨架，替换错误抽象。

### 14.2 必须保留的可靠骨架

以下内容已经被反复验证为方向正确，应继续保留：

1. **章节交付先于内容质量**
   - 先保证正文真实落盘、路径正确、内容非空、不是标题-only。
   - 交付失败不能混入文学评审。

2. **程序管合同，智能体管语义**
   - 程序负责结构、状态、路径、重试、恢复。
   - 智能体负责解释文学意义，并通过结构化报告交回系统。

3. **supervisor 是非 LLM 控制面**
   - supervisor 负责心跳、暂停、继续、恢复、重试、人工接管。
   - supervisor 不读正文判断文学效果。

4. **tool round evidence 必须保留**
   - 模型返回了什么、调用了什么工具、工具参数是什么、工具结果是什么，必须可追踪。
   - 这是解决空 content、只读轮、路径漂移的事实源。

5. **sidecar / 结构化附属产物方向正确**
   - 正文不应承载全部机器状态。
   - 章节旁需要有结构化证据，供后续生成、审稿、修复和拆书承接使用。

6. **scope / frame / segment 仍有价值**
   - 它们不应变成题材分类器。
   - 它们应作为可选坐标系，用来描述“这条声明影响了哪里、处在哪个叙事上下文”。

7. **普通项目、长任务、拆书续写共享底座**
   - 字数、表达限制、连续性、交付合同不属于某一种项目。
   - 长任务只是更依赖这些能力，不应独占实现。

8. **分层成本策略必须保留**
   - 普通项目不能默认承受 forensic 级记录成本。
   - 复杂项目可以逐步开启更强 sidecar、review 和 checkpoint。

这些是地基，不动。

### 14.3 必须废弃或降级的错误抽象

以下内容必须从后续实现思路中降级：

1. **题材名驱动**
   - 不再出现“如果是快穿则怎样”“如果是死亡回归则怎样”的核心分支。
   - 题材名只能作为用户输入、preset 名称、测试样本、报告标签。

2. **封闭状态维度表**
   - 不允许把 identity、memory、relationship 等写成核心支持全集。
   - 这些只能作为内置提示词的种子表达，不能作为系统边界。

3. **封闭变化半径表**
   - 不允许因为某个变化不属于 local / world / frame 等种子词就丢弃。
   - 未知半径必须可保留、可评审、可被项目 profile 定义。

4. **程序化文学判断**
   - 不再通过关键词判断是否“真正发生转折”。
   - 程序最多判断 evidence span 是否存在、字段是否完整、引用是否可解析。

5. **低层文件工具永久承担领域动作**
   - `write_project_file` 是底座，不应永久承担“完成一章”的领域语义。
   - 长期应引入领域工具或领域合同。

6. **一次性设计完所有流派**
   - 这件事不可能，也不应该成为目标。
   - 目标是让未知流派以项目级 schema / profile / agent brief 进入系统。

### 14.4 新核心：叙事状态账本，而不是变化分类器

建议把核心连续性底座重命名或抽象为：

**Narrative State Ledger（叙事状态账本）**

它不是一个分类器，不回答“这是什么流派”。它只保存：

1. 发生了哪些被声明的叙事状态变化。
2. 谁声明的。
3. 基于哪些正文证据。
4. 影响哪些对象、范围或上下文。
5. 程序结构校验是否通过。
6. 评审智能体是否认可。
7. supervisor 对它采取了什么调度动作。

账本中的基本单位不是固定类型，而是开放声明：

```text
NarrativeStateClaim
```

它可以表达角色变化、环境变化、关系变化、叙事手法变化、规则变化，也可以表达未来我们现在完全想不到的变化。

### 14.5 `NarrativeStateClaim` 开放合同

`NarrativeStateClaim` 是重设计后的核心合同。建议字段：

1. `claim_id`
2. `source`
3. `chapter_ref`
4. `segment_refs`
5. `claim_label`
6. `claim_namespace`
7. `claim_payload`
8. `affected_refs`
9. `context_refs`
10. `evidence_refs`
11. `impact_hint`
12. `persistence_hint`
13. `visibility_hint`
14. `confidence`
15. `uncertainty`
16. `created_by`
17. `schema_version`

重点是 `claim_payload`。

它应是开放 JSON，而不是固定字段对象。核心只要求它是可序列化结构，并允许项目级 profile 对它做进一步解释。

`claim_namespace` 用来避免未来冲突，例如：

1. `builtin.continuity`
2. `project.custom`
3. `downloaded.profile.xxx`
4. `agent.generated`

但 namespace 也不能变成权限锁死的分类表。它只是解释来源和冲突隔离工具。

### 14.6 项目级解释器：把“未知变化”变成项目内可理解事实

真正能减轻心智负担的，不是让核心预置更多类型，而是让项目拥有自己的解释器。

建议引入：

```text
NarrativeChangeProfile
```

它是项目级或应用级资产，可以由用户、内置 preset、下载包或智能体生成。

它负责说明：

1. 本项目关注哪些叙事状态。
2. 哪些声明需要记录。
3. 哪些声明只进入摘要。
4. 哪些声明需要评审。
5. 哪些声明需要 checkpoint。
6. 哪些声明可以忽略。
7. 如何把用户自然语言映射成 sidecar 指令。

注意：`NarrativeChangeProfile` 不是核心枚举。它是可替换、可版本化、可复制进项目的解释层。

这和之前讨论的应用级 / 项目级限制资产理念一致：

1. 应用级 profile 只是模板。
2. 项目引用后应固化一份到项目内。
3. 应用级删除不破坏项目。
4. 项目内 profile 可由用户或智能体继续演化。

### 14.7 智能体的新职责：不是判断流派，而是维护解释器

智能体参与设计是必要的，但位置要放对。

建议拆成四类智能体职责：

#### 1. Profile Architect

在项目创建、导入拆书结果、用户新增复杂约束时运行。

它输出：

1. `NarrativeChangeProfile`
2. sidecar 输出协议
3. review 关注点
4. risk policy 建议
5. 用户可读摘要

它不输出：

1. 核心代码分支。
2. 封闭变化类型。
3. 固定题材流程。

#### 2. Writer

写正文时输出正文，同时提交本章 `NarrativeStateClaim` 列表。

它只声明自己确信、对后续有影响的变化。没有显著变化时允许提交空列表。

#### 3. Reviewer

交付后复核 claims。

它可以：

1. 接受 claim。
2. 标记 claim 证据不足。
3. 建议新增遗漏 claim。
4. 建议降级为普通摘要。
5. 建议 repair。

它不能：

1. 抢写作工具。
2. 直接推进下一章。
3. 替 supervisor 调度。

#### 4. Recovery Agent

只在明确 recovery plan 下运行。

它处理单一问题：缺正文、补 sidecar、修正文、修 claim、修 review。不得混合多个目标。

### 14.8 新的 sidecar：从“章节连续性文件”升级为“章节状态提交包”

旧 `ChapterContinuitySidecar` 方向正确，但命名和职责可以升级为：

```text
ChapterStateSubmission
```

它包括：

1. 正文交付摘要。
2. 章节最终可读状态。
3. `NarrativeStateClaim` 列表。
4. 与上一章或相关上下文的引用。
5. 证据引用。
6. 不确定性。
7. 本章是否需要 review 的建议。

它不是“本章所有变化的完整真相”。它只是 writer agent 的结构化提交。

最终事实应来自：

```text
ChapterStateSubmission
-> StructuralValidation
-> SemanticReview
-> SupervisorDisposition
-> NarrativeStateLedger
```

### 14.9 程序校验：只校验结构，不校验文学真伪

程序可以校验：

1. JSON 是否合法。
2. claim 是否有 id。
3. 引用路径是否存在。
4. evidence span 是否能定位到正文大致位置。
5. affected refs 是否可解析，或是否被声明为新候选。
6. confidence / uncertainty 是否存在。
7. payload 是否可序列化。
8. profile 要求的最小字段是否存在。

程序不校验：

1. 这个变化是否文学上合理。
2. 角色性格变化是否有说服力。
3. 世界变化是否有冲击力。
4. 用户设定是否属于某个流派。

文学判断全部通过 reviewer 的结构化 finding 进入系统。

### 14.10 风险策略：由 profile + 运行状态决定，而不是由示例决定

建议引入：

```text
NarrativeRiskPolicy
```

它不按题材判断，而按这些信息判断：

1. 项目 profile 规则。
2. claim 的 impact_hint。
3. claim 的 confidence / uncertainty。
4. evidence 完整度。
5. 是否影响后续任务 source paths。
6. 是否与 ledger 中已有 accepted claim 冲突。
7. 是否跨越多个 context refs。
8. 当前是否长任务连续运行。
9. 用户是否要求严格连续性。
10. 交付 gate 是否稳定。

输出不是文学结论，而是调度建议：

1. accept
2. accept_with_note
3. request_review
4. request_sidecar_repair
5. request_chapter_repair
6. checkpoint_user
7. manual_attention

这样才是通用的、稳定的、均一的。

### 14.11 用户体验：隐藏复杂度，但允许项目演化

用户默认不应看到 `NarrativeStateClaim` 这种术语。

用户只需要看到：

1. 连续性记录强度。
2. 当前项目关注哪些变化。
3. 最近重要变化摘要。
4. 哪些问题需要确认。
5. 是否允许智能体更新项目连续性规则。

高级设置里才展示：

1. 项目 profile。
2. claims。
3. ledger。
4. review findings。
5. risk policy。

这能避免把内部架构心智负担转嫁给普通用户。

### 14.12 实现上的迁移方向

后续任务顺序应按这个方向重新组织：

1. 先补开放合同模型。
   - `NarrativeStateClaim`
   - `ChapterStateSubmission`
   - `NarrativeChangeProfile`
   - `NarrativeRiskPolicy`

2. 再补结构校验。
   - 只验证 JSON、引用、证据、profile 最小要求。
   - 不做文学判断。

3. 再补 writer mock。
   - 验证智能体能提交正文 + submission。
   - 验证未知 claim namespace / payload 不被丢弃。

4. 再补 reviewer mock。
   - 验证 reviewer 能接受、质疑、补充 claim。
   - 验证 finding 引用 claim，而不是扫关键词进 production。

5. 再补 risk policy。
   - 根据 profile 和结构证据决定调度建议。
   - 不按题材判断。

6. 再迁移旧 special mechanic。
   - 旧字段作为 claim namespace / legacy profile 导入。
   - 不再扩张旧服务。

7. 再接 adapters / runtime。
   - 项目读写、ledger 持久化、supervisor 消费 disposition。

8. 最后接 GUI / CLI / probe。
   - GUI 隐藏内部复杂度。
   - probe 用极端题材作为压力样本，不作为核心代码模板。

### 14.13 对第十三章的最终修正

第十三章的“变化半径、状态维度、种子词汇”只能作为 profile architect 的提示素材，不能作为核心实现目标。

真正的目标是：

```text
开放声明
-> 项目解释器
-> 结构校验
-> 智能体语义复核
-> 风险调度
-> 状态账本
```

而不是：

```text
题材示例
-> 默认分类表
-> 程序判断
-> 固定修复流程
```

后续任何任务文档都必须写清楚：

1. 示例不是范本。
2. 内置 profile 不是全集。
3. 未知 claim 必须被保留。
4. 用户和智能体可以扩展项目解释器。
5. 核心只实现开放合同、结构校验、调度接口和持久化。

### 14.14 最终重设计结论

我们要建设的不是“特殊机制系统”，也不只是“连续性 sidecar 系统”。

更准确的名字是：

**开放叙事状态承接系统。**

它的职责是：

1. 承接任意小说中的未知叙事变化。
2. 让智能体把语义理解写成结构化声明。
3. 让程序把声明变成可校验、可追踪、可恢复的状态事实。
4. 让 supervisor 用非 LLM 控制面稳定调度。
5. 让用户不必理解内部结构，也能获得连续、稳定、可修复的写作体验。

这才是保留已有可靠骨架后的真正重设计。

---

## 十五、开放 Toolcall 架构：用受控领域工具替代运行时脚本

### 15.1 结论

既然 Dart / Flutter 不适合作为跨平台运行时脚本系统，后续开放能力不应建立在“执行用户脚本”上。

更合理的方向是：

```text
智能体 toolcall
-> 领域工具合同
-> 程序结构校验
-> 权限 / 风险策略
-> 项目持久化
-> MD 可读投影
-> supervisor 调度
```

也就是说，我们开放的是“智能体可以通过工具提出结构化理解、约束、规则、状态声明和修复建议”，而不是开放任意代码执行。

这条路线比脚本更安全，也更适合 Flutter / Android / iOS / 桌面 / CLI 共用。

### 15.2 Toolcall 的设计原则

新工具必须遵守这些原则：

1. 工具表达领域动作，不表达文件细节。
   - 不要让智能体永远拼 `write_project_file`。
   - “提交章节交付”“提出项目叙事 profile 更新”“绑定约束”都应是领域工具。

2. 工具接受开放 payload，但必须有稳定外壳。
   - 未知 claim / profile 不应丢弃。
   - 但 source、confidence、uncertainty、evidence、schema_version 必须存在。

3. 工具默认产出 proposal，不默认直接改高风险事实。
   - 低风险记录可自动接受。
   - 中风险进入 pending。
   - 高风险必须用户确认。

4. 工具结果必须可审计。
   - 谁调用。
   - 何时调用。
   - 输入是什么。
   - 程序校验结果是什么。
   - 是否进入 ledger。
   - 是否影响调度。

5. 工具不能把题材名变成核心分支。
   - 可以提交“项目自定义多世界解释器”。
   - 不能调用 `set_multi_world_mode(true)` 这类锁死工具。

### 15.3 建议工具族

#### `propose_narrative_profile_update`

用途：

让智能体根据用户设定、拆书结果或当前写作问题，提出项目级叙事状态解释器更新。

典型场景：

1. 用户说明作品有多个世界、多个叙事层或特殊记忆规则。
2. 拆书后发现原作有复杂作用域。
3. 写作中出现新的长期规则。
4. 用户新增自定义限制或写法。

输入建议：

```json
{
  "proposal_id": "string",
  "reason": "string",
  "profile_patch": {
    "namespace": "project.custom",
    "display_name": "string",
    "instructions_for_writer": [],
    "instructions_for_reviewer": [],
    "claim_schema_hints": {},
    "risk_policy_hints": {},
    "metadata": {}
  },
  "evidence_refs": [],
  "confidence": 0.0,
  "uncertainty": "string",
  "requires_user_confirmation": true
}
```

关键限制：

1. 只能提出 profile 更新，不直接改项目核心规则。
2. profile_patch 必须开放，不允许被内置题材枚举限制。
3. 程序校验结构后，根据风险策略决定自动接受、pending 或用户确认。

#### `submit_chapter_delivery`

用途：

让 writer agent 一次性提交章节正文、目标路径和结构化状态提交包，替代长期依赖多次 `write_project_file` 拼装。

输入建议：

```json
{
  "chapter_path": "chapters/第01章.md",
  "chapter_content": "string",
  "title": "string",
  "submission": {
    "summary": "string",
    "claims": [],
    "evidence_refs": [],
    "uncertainty": "string",
    "review_recommended": false
  },
  "constraint_coverage": {},
  "confidence": 0.0
}
```

关键限制：

1. 正文缺失、空内容、title-only 必须直接进入交付失败。
2. submission 不完整时，不应否定正文交付，可触发补 sidecar / 补 claim 任务。
3. 工具内部负责写正文、写结构化 submission、返回统一交付合同。

#### `submit_narrative_state_claims`

用途：

让智能体在写作、拆书、解书、审稿时提交开放叙事状态声明。

输入建议：

```json
{
  "source": "writer_generated | deconstruction_extracted | explainer_interpreted | reviewer_suggested | user_declared",
  "claims": [
    {
      "claim_id": "string",
      "claim_namespace": "string",
      "claim_label": "string",
      "claim_payload": {},
      "affected_refs": [],
      "context_refs": [],
      "evidence_refs": [],
      "impact_hint": "string",
      "persistence_hint": "string",
      "visibility_hint": "string",
      "confidence": 0.0,
      "uncertainty": "string",
      "schema_version": "string"
    }
  ]
}
```

关键限制：

1. 未知 namespace / payload 必须保留。
2. 核心只做结构校验，不做文学判断。
3. 低 confidence 或 evidence 不完整时进入 review / pending。

#### `submit_semantic_review`

用途：

让 reviewer agent 提交对正文、claims、约束执行情况的结构化复核。

输入建议：

```json
{
  "review_id": "string",
  "target_refs": [],
  "accepted_claims": [],
  "questioned_claims": [],
  "suggested_claims": [],
  "findings": [
    {
      "finding_id": "string",
      "severity": "info | low | medium | high | blocking",
      "summary": "string",
      "evidence_refs": [],
      "related_claim_ids": [],
      "suggested_action": "string",
      "confidence": 0.0
    }
  ],
  "recommended_disposition": "accept | accept_with_note | repair | checkpoint_user | manual_attention"
}
```

关键限制：

1. reviewer 不拥有最终调度权。
2. review finding 必须引用 evidence 或明确说明无法定位。
3. findings 进入 supervisor 风险策略，而不是直接改正文。

#### `propose_constraint_binding`

用途：

让智能体提出项目级或阶段级约束绑定，如风格限制、表达限制、字数策略、叙事规则、审稿规则。

输入建议：

```json
{
  "binding_id": "string",
  "constraint_ref": "string",
  "scope_ref": "string",
  "applies_to": ["writing", "review", "repair", "deconstruction", "explanation"],
  "hard_execution_policy": {},
  "soft_review_policy": {},
  "reason": "string",
  "confidence": 0.0,
  "requires_user_confirmation": true
}
```

关键限制：

1. 内置约束和用户约束走同一绑定合同。
2. 高风险约束必须用户确认。
3. 约束不属于长任务私产，普通项目、拆书、解书都可使用。

#### `request_profile_clarification`

用途：

当智能体无法可靠设计 profile 或约束时，通过工具请求最小用户确认，而不是在正文里散问。

输入建议：

```json
{
  "question": "string",
  "options": [],
  "freeform_allowed": true,
  "reason": "string",
  "blocking": true
}
```

关键限制：

1. 只在关键信息缺失时使用。
2. 问题必须小而具体。
3. 不得把普通写作偏好变成大型表单。

### 15.4 写作、拆书、解书的双边复用

这些工具不能只服务写作。

同一套工具应覆盖三条输入方向：

1. 写作生成
   - writer 调用 `submit_chapter_delivery`
   - writer / reviewer 调用 `submit_narrative_state_claims`

2. 拆书承接
   - analyzer 从原文抽取 claims。
   - architect 基于抽取结果提出 profile。
   - 后续续写复用同一 ledger。

3. 内容解说 / 分析
   - explainer 提交解释型 claims。
   - 不一定进入写作主 ledger，可进入 analysis namespace。
   - 用户确认后可提升为项目规则或续写事实。

所以每条 claim 必须带 `source`，并允许不同来源的 claims 进入不同状态：

1. `observed`
2. `proposed`
3. `accepted`
4. `questioned`
5. `rejected`
6. `superseded`

这避免拆书分析、写作生成、解说推断互相污染。

### 15.5 权限与风险分级

工具调用必须分级。

#### 自动接受

适合：

1. 本章局部 claim。
2. evidence 完整。
3. 不改变项目级 profile。
4. 不影响后续任务调度。

#### 自动提案

适合：

1. 新增项目关注点。
2. 新增低风险约束。
3. 拆书抽取到的 profile 建议。
4. reviewer 建议补充 claims。

#### 用户确认

适合：

1. 改变项目长期规则。
2. 改变风格或表达限制。
3. 改变主线承诺。
4. 改变写作 / 审稿 / 修复策略。
5. 覆盖或删除已有 profile。

#### 禁止自动执行

包括：

1. 执行任意脚本。
2. 修改核心内置 profile。
3. 删除用户项目规则。
4. 高风险覆盖正文且无备份。
5. 用题材名触发核心固定分支。

### 15.6 持久化与投影

结构化事实源建议：

```text
.novel_agent/continuity/narrative_profiles/*.json
.novel_agent/continuity/claims/*.jsonl
.novel_agent/continuity/ledger/*.jsonl
.novel_agent/constraints/bindings/*.json
.novel_agent/reviews/semantic/*.json
```

可读投影建议：

```text
continuity/叙事状态规则.md
continuity/最近状态变化.md
constraints/项目约束摘要.md
reviews/语义复核摘要.md
```

原则：

1. JSON / JSONL 是程序事实源。
2. MD 是用户和智能体可读投影。
3. 用户编辑 MD 后，应通过解析 / 智能体提案转回结构化 proposal。
4. 不允许把散文 MD 直接当作运行时真相。

### 15.7 Prompt 侧限制

所有开放 toolcall prompt 必须强调：

1. 示例不是范本。
2. 未知变化必须保留。
3. 不要用题材名替代结构化说明。
4. 不确定时写 uncertainty。
5. 没有显著变化时允许空 claims。
6. 不要为了显得完整而编造 claim。
7. 不要在写作任务里偷偷改项目长期规则。
8. profile 更新必须走 proposal。

短期可用系统提示片段：

```text
你可以通过项目工具提交结构化叙事状态声明、约束绑定或 profile 更新提案。
不要把示例题材当成固定类型。遇到未知写法时，保留其项目内原始语义，用开放 payload 表达。
项目长期规则只能通过 proposal 工具提交，不要在正文或普通 Markdown 中悄悄改变。
如果没有显著变化，请提交空 claims 或不提交 claims，不要编造。
```

### 15.8 实现限制

后续实现必须遵守：

1. 不引入运行时 Dart eval 作为核心能力。
2. 不把工具参数设计成题材枚举。
3. 不让 `write_project_file` 永久承担章节交付领域动作。
4. 不让 `ProjectWorkflowRuntimeService` 吸收 profile / claim / risk policy 算法。
5. 不让 GUI 直接解释 claim payload。
6. 不让 reviewer 直接推进任务。
7. 不让 supervisor 读取正文做文学判断。
8. 不让未知 claim 被静默丢弃。
9. 不让 MD 成为唯一事实源。
10. 不让智能体无权限修改项目长期规则。

### 15.9 最终判断

开放 toolcall 是正确方向，但必须是“受控开放”。

我们不是让智能体获得任意执行能力，而是给它一组领域入口：

1. 理解项目。
2. 提出 profile。
3. 提交状态声明。
4. 提交语义复核。
5. 提出约束绑定。
6. 请求必要澄清。

程序负责把这些入口变成可校验、可持久化、可回滚、可调度的系统事实。

这条路线既能支持多世界，也能支持普通小说变化；既能支持写作，也能支持拆书和解说；既开放给未来未知流派，又不把核心变成不可控脚本运行器。

---

## 十六、横向参考吸收：从 MuMu 与其他小说 Agent 中提炼可用设计

### 16.1 目的

本章不是竞品功能清单，也不是照搬其他项目。

目标是用更犀利的方式回答：

1. 其他小说写作系统已经证明哪些产品思想是有效的？
2. 哪些设计如果照搬，会和本项目目标冲突？
3. 我们还缺哪些“朴素但关键”的稳定能力？
4. 我们要做得最好，应该在哪些层面超过普通小说生成器？

需要再次强调：参考 MuMu 等项目时，只吸收产品与架构思想，不复制 GPL 项目的代码、文件、实现细节或文案。

更重要的是：**外部参考只能给既定基线添砖加瓦，不能动摇本项目已经确定的架构路线。**

不可动摇的基线包括：

1. `Flutter GUI + Dart CLI + 纯 Dart core + adapters` 的分层路线。
2. `core` 只放共享领域模型、用例、合同、策略，不引入 Flutter / adapters / provider 实现。
3. `adapters` 只承接存储、provider、host 能力、平台接入，不成为业务规则中心。
4. GUI 和 CLI 是壳层，不能复制 core 业务规则。
5. 普通项目、长任务、拆书、解书共享底座，不能为某个参考项目另造一套平行 runtime。
6. supervisor 是非 LLM 控制面，不做文学语义裁判。
7. 程序管合同与恢复，智能体管语义解释。
8. 不把快穿、死亡回归、多世界、聊天群等题材写入核心分支。
9. 不把运行时 Dart eval / 用户脚本作为核心开放能力。
10. 外部系统的功能若与以上基线冲突，只能吸收背后的产品问题，不能吸收其实现形态。

### 16.2 MuMu 可吸收：朴素后台任务模型

MuMu 的重要启发不是连续性语义，也不是开放 profile，而是一个很朴素但非常关键的事实：

**长时间 AI 生成必须首先是可观察、可取消、可重试、可查询的后台任务。**

MuMu 的后台任务模型包含这些值得吸收的点：

1. 任务拥有稳定 ID。
2. 任务绑定用户与项目。
3. 任务有类型、状态、进度、状态消息。
4. 任务保存输入、输出、错误。
5. 任务有取消标记。
6. 任务记录 retry_count / max_retries。
7. 任务有 created / started / completed / updated 时间。
8. 前端通过任务 API 查询状态。
9. SSE 进度按 init / loading / preparing / generating / parsing / saving / complete 分阶段上报。

这些设计不高级，但很稳。我们之前反复卡在长任务稳定性上，本质就是必须先达到这类朴素任务可靠性。

### 16.3 MuMu 不足：粗粒度任务表不能承接我们的写作运行时

MuMu 的后台任务模型不能直接成为本项目核心。

原因：

1. 它更像“生成任务状态表”，不是“章节交付状态机”。
2. 它不区分正文交付失败与文学质量失败。
3. 它不表达 tool round evidence。
4. 它不表达开放 claims / profile / ledger。
5. 它不表达 writer / reviewer / recovery / supervisor 的权责分离。
6. 它不解决普通项目、长任务、拆书、解书的双向复用。

所以我们要吸收的是：

```text
任务可观察性 / 状态 / 进度 / 取消 / 重试 / 查询
```

而不是把我们的 runtime 降级成一个简单 `background_tasks` 表。

### 16.4 Novelcrafter 可吸收：Codex 作为作品知识中枢

Novelcrafter 的 Codex 思想值得吸收：它把角色、地点、物品、支线、世界知识等作为故事数据仓库，而不是让所有信息都散在正文或聊天记录里。

对我们的启发：

1. `NarrativeStateLedger` 不应孤立存在，它需要和角色、地点、关系、伏笔、世界规则等资产互相引用。
2. 可读知识库与机器可用结构应并存。
3. 用户需要能看到“当前作品知识中枢”，否则智能体记忆对用户来说是黑箱。
4. 引用应是对象级，而不是只靠全文搜索。

但 Novelcrafter 式 Codex 也不能完全替代我们的开放 claims：

1. Codex 更偏静态知识库。
2. 我们还要记录“谁在什么时候声明了什么变化、证据是什么、是否被 review 接受”。
3. 所以 Codex/资产层是事实对象库，Ledger 是状态变化账本，两者应互补。

### 16.5 Sudowrite 可吸收：Story Bible 降低用户心智

Sudowrite 的 Story Bible 思想值得吸收：把故事核心元素集中起来，并引导用户从 synopsis、outline 到 scene 逐步推进。

对我们的启发：

1. 高级结构不能一开始暴露给用户。
2. 用户更容易理解“故事圣经 / 项目规则 / 当前阶段目标”，而不是理解 claims、ledger、risk policy。
3. Profile Architect agent 应输出用户可读摘要，让用户知道项目规则是什么。
4. 项目创建和拆书导入都应生成一份“当前项目写作圣经”的 MD 投影。

但 Story Bible 不能成为唯一事实源：

1. 散文式 Story Bible 程序难以稳定消费。
2. 它适合做人类可读投影。
3. 我们仍需要结构化 profile / claims / ledger 做运行时事实源。

### 16.6 NovelAI / SillyTavern 可吸收：Lorebook / Memory 的动态注入

NovelAI Lorebook 和 SillyTavern World Info / Lorebook 都证明了一件事：

**长文本创作不能把所有背景永远塞进 prompt，必须按上下文动态注入相关信息。**

SillyTavern 的 World Info 可按关键词触发相关 lore，并支持角色、persona、chat 等不同绑定范围。NovelAI 的 Lorebook 也强调作为补充信息仓库，在相关条目出现时加入上下文。

可吸收点：

1. 资产需要 activation / retrieval 策略。
2. lore / memory / claims 不应全量注入。
3. 绑定范围很重要：项目、角色、会话、章节、任务、分析链可能需要不同的激活域。
4. 需要 debug 能力：本轮到底注入了哪些内容，为什么注入。
5. 需要预算控制：不要因为 lore 太多挤掉当前任务。

不可照搬点：

1. 单纯关键词触发对小说连续性不够稳。
2. 它容易漏掉语义相关但关键词不匹配的信息。
3. 它不天然解决状态变化、review、repair 和 supervisor 调度。
4. 它容易让用户以为“写进 lorebook 就一定会生效”，但实际模型是否使用仍不保证。

我们的方案应升级为：

```text
Context Activation Contract
= 关键词 / 引用 / source path / claim refs / task type / profile policy / semantic retrieval 的组合
```

### 16.7 其他小说 Agent 的共同启发

横向看小说写作 Agent，大多数有效能力都落在五类：

1. **故事资料库**
   - 角色、地点、世界观、关系、伏笔、风格。

2. **阶段化创作流程**
   - 灵感、简介、大纲、章纲、场景、正文、润色、审稿。

3. **上下文注入策略**
   - Memory、Author Note、Lorebook、World Info、Codex snippets。

4. **可见进度和可恢复任务**
   - 后台任务、SSE、取消、重试、失败记录。

5. **可读规则与提示词资产**
   - Story Bible、Prompt Workshop、写作风格、技能参考。

这些都值得吸收，但我们的差异化不应是“把这些都堆一遍”。我们的目标应是把它们统一到一个更稳的运行时：

```text
资产库
-> 上下文激活
-> 领域 toolcall
-> 结构化状态提交
-> review finding
-> supervisor 调度
-> 可读投影
```

### 16.8 我们当前还缺的关键理念

纵观全局，当前设计还需要补强这些理念：

#### 1. 运行时事实源必须分层

不能只有 Markdown，也不能只有数据库对象。

建议明确四类事实：

1. `Author-facing truth`
   - 用户可读的 MD、摘要、规则说明。

2. `Machine truth`
   - JSON / JSONL / typed models。

3. `Execution truth`
   - tool round evidence、delivery contract、run status。

4. `Reviewed truth`
   - reviewer 接受后的 claims、findings、ledger disposition。

不同层不能互相冒充。

#### 2. 上下文注入需要可解释

每次模型调用都应能回答：

1. 注入了哪些项目规则？
2. 注入了哪些资产？
3. 注入了哪些 claims？
4. 为什么注入？
5. 被预算裁掉了什么？

否则用户无法判断“去 AI / 字数 / 连续性 / 多世界规则到底有没有生效”。

#### 3. 领域工具需要逐步替代低层工具组合

低层工具继续保留，但高频领域动作要升级：

1. 完成章节。
2. 提交 claims。
3. 提交 review。
4. 提出 profile 更新。
5. 绑定约束。
6. 提交 repair 结果。

这能减少“工具调用被抢”“漏写 sidecar”“空 content”这类问题。

#### 4. 项目级 profile 需要生命周期

Profile 不能只是一个文件。

它需要：

1. draft
2. proposed
3. accepted
4. active
5. deprecated
6. superseded
7. rejected

并且需要变更记录和回滚路径。否则智能体参与设计会变成隐性漂移。

#### 5. 拆书 / 解书不应是写作的附属

拆书、解说、分析不是“生成前处理”，它们是和写作平行的数据进入方向。

它们应该能产出：

1. claims
2. evidence refs
3. profile proposals
4. asset updates
5. semantic review findings

并通过 source 区分可信度。

### 16.9 “做得最好”的判断标准

如果我们要做得最好，不能只看生成文本质量。应该用这些标准判断：

1. **可靠**
   - 正文不丢，任务不断，失败可恢复。

2. **可解释**
   - 用户知道为什么 AI 这样写，哪些规则生效了。

3. **可审计**
   - 每个项目规则、claim、review、repair 都能追溯来源。

4. **可扩展**
   - 新流派、新写法、新约束不需要核心 if/else。

5. **可控**
   - 智能体可以提案，但不能悄悄改长期规则。

6. **可复用**
   - 普通项目、长任务、拆书、解书共享底座。

7. **可降级**
   - 复杂能力失败时，系统还能完成普通写作，而不是全链断掉。

8. **可读**
   - 高级结构必须有用户能理解的 MD 投影。

### 16.10 建议新增的架构原则

建议把以下原则纳入后续任务顺序文档和项目级约束：

1. **先后台任务可靠，再智能体复杂协作。**
2. **先领域工具，再开放 profile。**
3. **先结构化事实源，再 MD 投影。**
4. **先可解释上下文注入，再真实长探针。**
5. **先普通项目共用，再长任务增强。**
6. **先 project profile 生命周期，再允许智能体自动提案。**
7. **先 mock toolcall 验证，再真实 provider 消耗。**
8. **先最短章节闭环，再多智能体协作组。**

### 16.11 对下一步实现的影响

当前不建议马上做更复杂的多世界 / 特殊题材探针。

更合理的实现顺序是：

1. `submit_chapter_delivery` 的 core 合同和 mock。
2. `NarrativeStateClaim` 的开放模型和结构校验。
3. `propose_narrative_profile_update` 的 proposal 生命周期。
4. `submit_semantic_review` 的 finding 合同。
5. context activation explain report。
6. supervisor 消费 delivery / claims / review disposition。
7. 再跑普通项目和长任务短探针。
8. 最后才跑复杂题材压力探针。

这样能避免又陷回“探针先暴露一堆问题，然后 production 链被迫打补丁”的循环。

### 16.12 参考来源

本章只吸收公开产品思想和本地参考项目中的架构现象，不复制外部代码。

1. MuMu 本地参考项目：后台任务模型、任务 API、SSE 进度阶段。
2. Novelcrafter Codex / Codex snippets：作品资料库与 story data repository 思想。
3. Sudowrite Story Bible：集中管理故事核心元素和阶段化写作引导。
4. NovelAI Lorebook：补充信息仓库与上下文注入。
5. SillyTavern World Info / Lorebook：动态上下文注入、绑定范围、插入策略和调试需求。
