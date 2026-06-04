# 共享叙事信息策略与长任务缺口分析

日期：2026-06-05

关联参考：

- `agent.md`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md`
- `docs/open-narrative-state-implementation-audit-2026-06-04.md`
- `docs/ons-44-pressure-validation-progress-2026-06-04.md`
- `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
- `references/MuMuAINovel-main`

本文只做分析与架构判断，不推进实现。

---

## 1. 总结论

当前项目已经完成了一个正确但还偏“运行时骨架”的阶段：

1. `ONS-01` 到 `ONS-44` 已经把开放叙事状态、领域 toolcall、章节交付、约束绑定、上下文激活、supervisor 风险消费、普通项目与长任务最小真实验证都立起来了。
2. `submit_chapter_delivery`、`NarrativeStateClaim`、`NarrativeProfile`、`SemanticReview`、`ConstraintBinding`、`ContextActivationReport` 这些合同方向是对的，不应推翻。
3. “快穿 / 死亡回归 / 多世界”已经被纠偏为压力测试输入，而不是 core 分支，这条基线必须继续保留。
4. 下一层真正缺口不再是“特殊剧情怎么写死”，而是“项目信息、外部研究、作品巧思、符号系统、来源证据、知识激活”如何成为普通小说、拆书、长任务、解书都共享的正式信息基座。

最核心的判断：

**后续不应该再补一个题材系统，而应该补一个共享的 Project Information Substrate。**

它承接：

1. 用户开篇注入的设定。
2. 写作过程中智能体发现的长期事实。
3. 拆书从原文抽取出的结构、巧思、符号系统和证据。
4. 解书 / 分析智能体提炼出的解释性信息。
5. 必要时通过联网或资料库研究得到的外部知识。
6. 未来同人、穿书、跨作品引用场景中的来源作品边界和使用策略。

---

## 2. 当前已有的可靠基础

### 2.1 ONS 底座是正确方向

当前已经有：

1. 开放叙事状态：
   - `packages/novel_agent_core/lib/src/continuity/narrative_state/`
   - `NarrativeStateClaim`
   - `NarrativeProfile`
   - `NarrativeStateLedger`
   - `NarrativeSemanticReview`
   - `NarrativeConstraintBindingProposal`

2. 领域工具：
   - `submit_chapter_delivery`
   - `submit_narrative_state_claims`
   - `propose_narrative_profile_update`
   - `submit_semantic_review`
   - `propose_constraint_binding`
   - `request_profile_clarification`

3. 运行时交付：
   - `ChapterDeliveryStateMachine`
   - `ProjectNarrativeDomainToolExecutor`
   - `ProjectConversationDraftRuntimeService`
   - `ProjectLongTaskChapterQueueRuntimeService`

4. supervisor 风险消费：
   - `NarrativeSupervisorRiskPolicyService`
   - `TaskQueueStopPolicyService`
   - `LongTaskRecoveryService`
   - `LongTaskFinishDispositionService`

5. 上下文可解释注入：
   - `ContextActivationPlan`
   - `ContextActivationReport`
   - `ProjectContextActivationService`

这些说明系统已经从“模型随便写文件”进化为“领域合同 + 事实源 + 恢复调度”。这是必须保留的地基。

### 2.2 MuMu 可吸收的是朴素稳定性，不是实现形态

MuMu 的可吸收点主要是：

1. 后台任务有稳定 ID、状态、进度、错误、取消、重试、时间戳。
2. 章节生成上下文有层级：核心大纲 / 最近章节 / 上章衔接 / 角色组织 / 记忆 / 伏笔提醒。
3. 拆书导入不是只生成报告，而是把章节、大纲、角色、世界观等继续变成创作工程资料。
4. 伏笔、记忆、角色状态都有来源、章节定位、状态和提醒策略。

不可吸收点：

1. 不能复制 GPL 代码、字段结构、文案或实现。
2. 不能把本项目压扁成一个粗粒度后台任务表。
3. 不能用 MuMu 的固定对象表替代 ONS 的开放 claim / profile / ledger。

所以我们的路线应是：

```text
MuMu 式可观察后台任务
+ Novelcrafter/Codex 式作品资料库
+ Lorebook 式动态激活
+ ONS 开放叙事状态与领域 toolcall
= 本项目自己的共享叙事信息基座
```

---

## 3. 长任务仍然不合理或可优化的地方

### 3.1 长任务稳定性已经改善，但仍偏“生产线”，不够像真实创作流

ONS-40 已经把开局预造 1..N 章任务改为动态续队列，这是对的。

剩余风险：

1. 长任务仍容易被“任务队列推进”绑架，而真实创作经常是：
   - 写一章。
   - 看结果。
   - 调整设定或约束。
   - 补资料。
   - 再继续下一章。
2. 章节窗口的生成应更多根据当前内容状态、checkpoint 结论、用户介入和 profile 风险动态决定，而不是只根据固定 batch / checkpoint interval。
3. 长任务不能只关注“下一章是否生成”，还要关注“本章是否新增了会影响后续的信息”，并决定是否需要补 claim、补知识卡、补研究卡、补 review。

建议：

1. 保留动态续队列，不回到预造 1..200 章。
2. 长任务每章结束后统一产出：
   - delivery outcome
   - activation report
   - chapter submission
   - claims / reviews / constraints delta
   - knowledge delta
   - next-window recommendation
3. `ProjectLongTaskChapterQueueRuntimeService` 继续只负责队列窗口和物化策略，不吸收信息解释算法。

### 3.2 supervisor 还缺“信息基座变化”的调度输入

当前 supervisor 主要消费：

1. delivery
2. semantic review
3. permission

这很好，但还不够。

未来应增加但不让 supervisor 读正文：

1. 新增/冲突知识卡数量。
2. 外部研究是否未完成。
3. 高权重来源证据是否不足。
4. 拆书承接来源是否和新写内容冲突。
5. 约束绑定是否被新 profile 改写。
6. 上下文激活是否连续多轮省略了 required 信息。

落点建议：

- core：新增 `InformationRiskPolicyService` 或扩展当前 risk policy 的信息输入模型。
- adapters：读取项目事实源和 activation report，形成结构化 risk signal。
- supervisor：只消费 signal，不读正文、不判断文学语义。

### 3.3 `ProjectWorkflowRuntimeService` 仍是结构风险

该文件已经长期被标记为过大，只能做薄接线。

后续任何新信息策略都不应塞进：

- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`

应拆到：

1. `ProjectInformationActivationService`
2. `ProjectResearchArtifactService`
3. `ProjectKnowledgeRepository`
4. `ProjectInformationProjectionWriterService`
5. `ProjectWorkflowRuntimeBridgeService` 的小型扩展点

---

## 4. 哪些逻辑应共享，但目前还不够共享

### 4.1 已经共享得比较好的逻辑

这些能力已经或正在走共享方向：

1. 章节交付：
   - 普通项目与长任务都应使用 `submit_chapter_delivery`。

2. 字数与表达限制：
   - `WritingExecutionConstraintBridgeService`
   - `ProjectDraftExecutionConstraintRuntimeService`
   - `NarrativeConstraintBindingProposal`

3. 上下文激活：
   - `ProjectContextActivationService`
   - `ContextActivationPlannerService`

4. 开放叙事状态：
   - claims / profiles / ledger / semantic review / projection

5. 拆书 ONS 桥：
   - `BookDeconstructionNarrativeBridgeService`
   - `BookDeconstructionNarrativePromotionService`
   - `BookDeconstructionDerivedProjectNarrativeInheritanceService`

### 4.2 仍然容易被写死到特定项目的逻辑

#### 1. `knowledge/` 只是目录，不是正式信息层

当前 `knowledge/` 在这些地方存在：

- 项目目录展示。
- content type 路由。
- prompt/tool 策略提示。
- context file selection 的低优先级候选。

问题：

1. 它还不是结构化知识事实源。
2. 它没有 source、evidence、confidence、scope、activation policy。
3. 它不能区分“用户设定”“拆书抽取”“外部研究”“AI 推断”“同人/引用作品资料”。
4. 它无法稳定表达“北欧神话命名体系”“星象象征系统”“八卦结构”“原作章节里的小巧思”。

结论：

`knowledge/` 可以继续作为可读投影或用户素材目录，但不能成为程序唯一事实源。

#### 2. 拆书里的 `mechanic hints` 命名仍偏历史遗留

当前拆书存在：

- `BookDeconstructionMechanicHint`
- `mechanicHints`
- UI 上的“机制提示”

它们短期可以作为兼容显示，但长期不应继续扩展成题材机制系统。

建议迁移方向：

1. 新增中性 `DesignElement` / `ContinuityHint` / `NarrativePatternHint`。
2. 旧 `mechanic_hint` 通过 bridge 进入 `analysis.deconstruction.*` namespace。
3. UI 文案从“机制提示”逐步改为“叙事规则 / 结构提示 / 重要变化提示”。

#### 3. 普通项目创建 UI 的多世界/回档快捷项不应变成能力边界

当前 UI 有：

- “包含多世界/多舞台切换”
- “包含回档/回归/重跑机制”

这类快捷项可以保留为低心智入口，但必须定位为：

1. 用户设定提示。
2. 内置 profile seed。
3. 可编辑/可删除/可替换的项目规则提案。

它不能成为 core 分支，也不能阻止用户表达其他变化，例如：

1. 人格突变。
2. 叙事视角突然切换。
3. 地域、组织、关系网迁移。
4. 身份误认。
5. 梦境嵌套。
6. 文本结构实验。
7. 现实作品穿书或同人引用。

---

## 5. 信息策略应如何重设计

### 5.1 新增共享层：Project Information Substrate

建议把未来信息层定义为：

```text
Project Information Substrate
= Narrative State Ledger
+ Story Knowledge Cards
+ Design/Motif Cards
+ Research Notes
+ Source Evidence
+ Context Activation Policy
+ Usage/Permission Policy
```

它服务所有项目类型：

1. 普通小说任务。
2. 普通长任务。
3. 拆书。
4. 拆书续写派生项目。
5. 解书 / 内容分析。
6. 未来同人或跨作品引用。

### 5.2 建议新增的核心对象

#### `ProjectKnowledgeCard`

用于保存项目可复用知识，不只限世界观。

字段方向：

1. `card_id`
2. `namespace`
3. `card_type`
4. `title`
5. `summary`
6. `content_payload`
7. `source_refs`
8. `evidence_refs`
9. `scope_refs`
10. `activation_policy`
11. `confidence`
12. `lifecycle_status`
13. `usage_policy`
14. `metadata`

可表达：

1. 世界规则。
2. 文化符号。
3. 神话体系。
4. 命名规则。
5. 叙事技巧。
6. 角色口头禅。
7. 特殊文体。
8. 原作结构巧思。

#### `DesignElementCard`

用于保存“作品设计小巧思”。

例如：

1. 北欧神话名称和命运主题的映射。
2. 星象与章节标题的对应。
3. 八卦结构作为组织层级。
4. 每卷开头暗藏某个诗句。
5. 角色名首字母形成伏笔。
6. 某类物件反复出现，作为主题线索。

它不应写死“神话 / 星象 / 八卦”枚举，而应使用开放 payload。

#### `ResearchNote`

用于保存外部研究结果。

字段方向：

1. `research_id`
2. `query`
3. `source_kind`
4. `source_url_or_ref`
5. `citation`
6. `summary`
7. `usable_facts`
8. `uncertainty`
9. `license_or_usage_note`
10. `created_by`
11. `created_at`
12. `linked_cards`

关键点：

1. 联网结果不能只停留在聊天上下文。
2. 研究结果必须可追溯来源。
3. 可用事实与创作建议要分开。
4. 外部资料进入项目前要经过权限与来源策略。

#### `ReferenceWorkRecord`

用于未来穿书、同人、跨作品引用。

当前不需要实现完整同人系统，但架构不能堵死。

它至少应预留：

1. 来源作品名。
2. 作者 / 版本 / 来源。
3. 用户声明的使用意图。
4. 引用范围。
5. 与项目的关系：
   - inspiration
   - deconstructed_source
   - fictional_in_world_work
   - fanfic_reference
   - crossover_reference
6. 使用边界：
   - 只借鉴设定结构。
   - 续写未完结源文本。
   - 穿书进入某个作品世界。
   - 同人创作。
7. 权限与风险备注。

这能解决用户提到的“穿书穿进现实小说”和“同人不同但相关”的边界问题。

---

## 6. 联网搜索应如何接入

### 6.1 不能让 core 直接联网

联网能力属于 adapters / host / gateway。

当前已有：

- `request_gateway_tool`
- `ProjectGatewayToolExecutor`
- `search_internet`
- `fetch_url_content`

但这些只是通用能力，不是叙事信息能力。

### 6.2 应新增研究型领域工具，而不是让智能体直接到处搜索

建议未来新增：

1. `request_external_research`
   - 请求研究某个主题。
   - 经过权限策略。
   - adapters 调用 gateway 搜索。

2. `submit_research_note`
   - 把研究结果提交为结构化 `ResearchNote`。
   - 必须带来源、摘要、可用事实和不确定性。

3. `propose_knowledge_card`
   - 把研究结果或拆书发现提升为 `ProjectKnowledgeCard` / `DesignElementCard` 提案。

4. `link_information_evidence`
   - 把正文片段、源书片段、研究 note、claim、knowledge card 建立引用关系。

### 6.3 搜索权限与版权边界

外部搜索必须有约束：

1. 默认不开启自动联网。
2. 高风险来源、版权作品、同人/穿书引用需要用户确认。
3. 不把搜索结果原文大量写入项目事实源。
4. 保存摘要、事实点、引用信息和使用边界。
5. 不让智能体把“搜到的信息”直接变成项目长期规则，仍应走 proposal / confirmation。

---

## 7. Agent 权重和工具参数应如何看

用户提到“智能体权重，用工具调用传递参数来设计具体内容情节”。这个方向部分成立，但要避免做成黑箱魔法旋钮。

更稳的设计是：

1. 权重不直接表示“让某智能体说了算”。
2. 权重应表达运行时职责和证据优先级。
3. 工具参数应传递可审计的策略，而不是隐含权力。

建议抽象为：

1. `role_authority`
   - writer / reviewer / researcher / deconstructor / architect 的建议权重。

2. `source_authority`
   - user_declared 高于 writer_generated。
   - deconstruction_extracted 高于 explainer_interpreted。
   - external_researched 取决于来源可信度。

3. `research_depth`
   - none / quick / standard / deep。

4. `activation_priority`
   - required / pinned / normal / reference / background。

5. `risk_tolerance`
   - low / normal / experimental。

6. `requires_confirmation`
   - 改长期规则、引用外部作品、覆盖旧事实时必须显式。

这样可以让智能体参与设计复杂项目，但不会让它无声篡改工程事实。

---

## 8. 普通任务、拆书、长任务如何共用

### 8.1 普通小说任务

普通任务应默认使用共享底座，但低成本启用：

1. 章节交付必须走 `submit_chapter_delivery`。
2. 字数、表达限制走 `ConstraintBinding`。
3. 重要变化可提交 claims。
4. 明显新增长期设定可提 knowledge card。
5. 不强制每章都做深度 review / research。

### 8.2 长任务

长任务是增强使用者，不是独占者：

1. 每章 delivery 必须稳定。
2. 每个窗口产出 activation report。
3. checkpoint 根据 delivery / review / knowledge delta / permission 决定是否继续。
4. 长任务可启用更强的 knowledge activation 和 research gate。
5. 不应硬编码某种题材或章节段落数。

### 8.3 拆书

拆书是高密度输入方向：

1. 原文片段应变成 source evidence。
2. 抽取出的世界观、角色、伏笔、结构巧思应变成 analysis namespace 下的 claims / knowledge cards / design elements。
3. 拆书智能体可以提出 profile、constraint、research note，但不能直接污染写作主 ledger。
4. 派生续写项目时，用户确认后再提升 accepted。

### 8.4 解书 / 内容解说

解书不是写作的附属，也应复用同一层：

1. explainer 输出 `analysis.explainer.*`。
2. 可进入 analysis ledger。
3. 用户确认后可提升为写作事实或项目规则。
4. 解释性推断与原文事实要分开。

---

## 9. 具体应改哪里

### 9.1 Core 层

建议新增目录或子域：

```text
packages/novel_agent_core/lib/src/information/
```

放：

1. `project_knowledge_card.dart`
2. `design_element_card.dart`
3. `research_note.dart`
4. `reference_work_record.dart`
5. `information_source_ref.dart`
6. `information_usage_policy.dart`
7. `information_activation_policy.dart`
8. `information_risk_policy_service.dart`
9. codec / validator / repository ports

注意：

1. 不放联网实现。
2. 不放 UI 文案。
3. 不写死神话、星象、八卦、快穿、同人等类型。
4. payload 开放，外壳稳定。

### 9.2 Core tools 层

扩展：

```text
packages/novel_agent_core/lib/src/tools/domain/
```

新增领域工具合同：

1. `request_external_research`
2. `submit_research_note`
3. `propose_knowledge_card`
4. `link_information_evidence`

它们应复用：

1. `DomainToolRequest`
2. `DomainToolOutcome`
3. `NarrativePermissionPolicyService` 或新的 information permission policy。

### 9.3 Adapters 层

建议新增：

```text
packages/novel_agent_adapters/lib/src/storage/local_project_information_repository.dart
packages/novel_agent_adapters/lib/src/storage/project_information_path_service.dart
packages/novel_agent_adapters/lib/src/information/project_research_gateway_service.dart
packages/novel_agent_adapters/lib/src/information/project_information_projection_writer_service.dart
```

存储建议：

```text
.novel_agent/information/knowledge_cards/*.json
.novel_agent/information/design_elements/*.json
.novel_agent/information/research_notes/*.json
.novel_agent/information/reference_works/*.json
knowledge/项目知识摘要.md
knowledge/设计元素摘要.md
research/资料研究摘要.md
```

规则：

1. `.novel_agent/information/*` 是事实源。
2. `knowledge/*.md` / `research/*.md` 是可读投影。
3. 用户编辑 MD 后进入 proposal，不直接覆盖事实源。

### 9.4 Runtime / Workflow 层

不要继续膨胀：

- `ProjectWorkflowRuntimeService`
- `ProjectContextActivationService`

建议拆出：

1. `ProjectInformationActivationBridgeService`
   - 把 knowledge cards / research notes / design elements 转成 activation items。

2. `ProjectInformationRuntimeBridgeService`
   - 把 tool outcome 中的信息变更写入 execution record / changed_paths。

3. `ProjectInformationReviewRuntimeService`
   - 只负责信息缺失、证据不足、来源冲突等 review task，不做文学判断。

### 9.5 GUI / CLI

GUI / CLI 应最后接入：

1. 先显示知识投影和研究投影。
2. 再做 proposal 审批。
3. 再做完整 knowledge ledger 浏览器。
4. 不在 GUI/CLI 解释 payload。
5. 不让 GUI/CLI 弥补 core/adapters 的事实源缺口。

---

## 10. 什么不要做

1. 不要新增 `quick_transmigration_mode`、`death_replay_mode`、`norse_myth_mode` 这类 core 分支。
2. 不要把“北欧神话、星象、八卦”写成内置全集。
3. 不要让 Markdown 成为唯一事实源。
4. 不要让联网搜索结果停留在聊天记录里。
5. 不要让智能体无确认地修改项目长期规则。
6. 不要让 reviewer 直接推进任务。
7. 不要让 supervisor 读正文判断文学意义。
8. 不要把 `knowledge/` 当成足够的信息系统。
9. 不要把同人、穿书、跨作品引用提前实现成完整产品功能；只预留 reference work 和 usage policy。
10. 不要把新算法塞进已经过重的 runtime 门面文件。

---

## 11. 优先级建议

近期最值得做的不是大规模真实长探针，而是补信息层的最小闭环：

1. Core：信息卡 / 研究 note / reference work 开放合同。
2. Core：信息 repository ports、validator、codec。
3. Core tools：研究与知识卡 proposal 工具合同。
4. Adapters：本地 JSON/JSONL 存储与 Markdown 投影。
5. Runtime：context activation 接入信息层，但不改主算法中心。
6. Deconstruction：把拆书中的作品巧思、符号系统、原文证据桥到信息层。
7. Ordinary / Long task：写作后可提交 knowledge delta，长任务可在 checkpoint 消费信息风险。
8. GUI / CLI：最后展示知识投影、研究摘要和待确认 proposal。

只有这些完成后，再做更长、更复杂的真实探针，才不会继续落入“模型没记住 / 规则没生效 / 不知道为什么没注入”的黑箱循环。

---

## 12. 最终判断

用户提出的方向是对的，但需要收束：

1. 对：原作中的写作巧思、符号系统、设定来源、文化资料必须能被拆出、写入、检索、复用。
2. 对：模型不可能知道所有细节，必要时需要联网或外部资料研究。
3. 对：关键信息必须持久化，不能只靠上下文记忆。
4. 对：普通小说、拆书、长任务、解书应共享这套信息基座。
5. 需要修正：不要把这些能力做成题材特例或固定分类表。
6. 需要修正：不要把联网工具直接暴露成“随便搜”，而应经过研究合同、来源证据、权限和投影。
7. 需要修正：不要把同人/穿书提前做成完整功能，但必须保留 reference work / usage policy 的架构入口。

因此后续最好的方案是：

```text
开放信息合同
-> 受控研究工具
-> 项目内结构化知识/设计/来源事实源
-> 可读投影
-> 可解释上下文激活
-> 写作/拆书/长任务/解书共用
-> supervisor 只消费结构化风险信号
```

这条路比继续补某个特殊题材更慢一点，但它会真正减少后续反复返工。
