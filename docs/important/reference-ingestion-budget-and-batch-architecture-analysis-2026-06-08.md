# 参考提取摄取预算与分批生成架构分析

日期：2026-06-08

关联文档：

- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `docs/reference-extraction-agent-implementation-handoff-2026-06-07.md`

关联实现锚点：

- `packages/novel_agent_core/lib/src/reference_substrate/reference_source_document_extraction_service.dart`
- `packages/novel_agent_core/lib/src/reference_substrate/reference_source_document_models.dart`
- `packages/novel_agent_core/lib/src/reference_extraction/reference_extraction_run_models.dart`
- `packages/novel_agent_adapters/lib/src/storage/reference_source_document_file_ingestion_service.dart`
- `packages/novel_agent_adapters/lib/src/reference_extraction/llm_reference_extraction_prompt_builder_service.dart`
- `packages/novel_agent_adapters/lib/src/reference_extraction/llm_reference_extraction_proposal_generator.dart`

---

## 1. 本文解决什么

这轮要解决的不是“seed 条目是不是再多给几个”，而是一个更根本的问题：

```text
当用户导入一本书、一批章节、一个超长文档、甚至一套散装资料时，
系统到底该一次喂给智能体多少原文，如何分批，如何保证覆盖率，
又如何让这套机制既可控、可扩展，又不会把整个提取系统做成一坨硬编码。
```

用户这次提出的直觉是：

1. 一次可以考虑喂“用户可用上下文长度的一半”。
2. 这个界限最好可调。
3. 需要有最小下限，例如至少多少字、多少章。
4. 针对章节过长、章节结构不规范、或只是长文本数据集导入的情况，应做分批提取。

这个直觉方向是对的，但还不够完整。

真正需要建立的，不是一个单一百分比，而是一套正式的：

1. 摄取预算策略。
2. 批次规划器。
3. 提取覆盖状态。
4. 分批合并与去重规则。
5. 简洁但足够可控的用户暴露面。

---

## 2. 先确认现状：当前实现为什么不够

先把当前链路看清楚，避免在错误认知上继续加补丁。

### 2.1 当前 seed ingestion 的真实定位

当前 `ReferenceSourceDocumentExtractionService` 做的主要是：

1. 读取完整源文本。
2. 尝试按章节标题切段；找不到就退化为按段落聚合。
3. 生成少量章节片段 seed。
4. 提取少量高频实体线索。
5. 再补一个风格条目和边界条目。

它是：

1. `source bootstrap`
2. `seed extraction`
3. `evidence scaffolding`

它不是：

1. 面向整本书的完整参考资产提取。
2. 面向长文档的覆盖式知识生产流水线。
3. 面向多批次导入的稳定提取主链。

### 2.2 当前链路的几个硬限制

从实现上看，当前主要问题很明确：

1. `_extractSections()` 本质是 seed 启发式切片，不是正式 batch planner。
2. `maxChapterEntries` / `maxEntityEntries` 控的是“保留多少 seed 条目”，不是“给模型多少源文预算”。
3. LLM proposal 阶段吃到的是 `seedSnapshot.entries.take(seedEntryLimit)`，不是受控原文窗口。
4. 当前没有真正的分批计划对象，也没有覆盖状态对象。
5. 当前没有“这本书还剩多少没提”“哪些部分已经提过”“哪些批次失败可重试”的正式建模。

这意味着：

```text
现在这套实现，适合做 bootstrap，
不适合被继续拔高成“整本书高保真可复用提取系统”。
```

---

## 3. 对“半个上下文”的辩证判断

### 3.1 为什么这个想法有价值

用户提出“一次使用可用上下文长度的一半”并不草率，它至少抓住了三件真实的事：

1. 单次不能喂满，否则 prompt、工具约束、输出空间和安全余量都会被挤爆。
2. 单次喂太少，又会让提取结果过薄，尤其是风格、时间线、复杂人物关系这类需要跨段观察的内容。
3. 单次投喂量应该与所选模型/上下文容量相关，而不是永远写死一个字符数。

### 3.2 为什么不能直接把“半个上下文”写成规则

但把它直接写成硬规则会出问题：

1. 可用上下文并不只属于原文。
   - 系统指令要占。
   - 工具协议/JSON 结构要占。
   - 当前批次目标说明要占。
   - 已有摘要/前序批次结论要占。
   - 输出本身也要占。

2. 不同任务阶段对原文窗口的需求不同。
   - seed/bootstrap 阶段可以多喂原文，少带历史。
   - consolidate/review 阶段反而应该少喂原文，多喂中间结果。

3. 不同文档形态差异很大。
   - 章节规整的网文。
   - 一章上万字的轻小说。
   - OCR 后无清晰章名的整本文本。
   - 多文件资料包。
   - 纯散装事实资料集。

4. 上下文预算不仅取决于模型，也取决于输出要求。
   - 只是抽 seed 和摘要，输出预算较小。
   - 若要同时产出角色、地点、风格、时间线、引用边界，输出空间必须放大。

所以“半个上下文”应当保留为一种默认倾向，而不是最终规则。

---

## 4. 正式结论：我们需要“摄取预算策略”，不是单一截断公式

### 4.1 推荐引入的新核心对象

建议新增一层中性、任务族可复用的预算合同：

1. `ReferenceIngestionBudgetPolicy`
2. `ReferenceIngestionBudgetResolverService`
3. `ReferenceSourceBatchPlan`
4. `ReferenceSourceBatchPlannerService`
5. `ReferenceSourceBatchProgress`
6. `ReferenceExtractionCoverageMergeService`

这几层的职责应该分开：

1. `BudgetPolicy`
   - 决定预算理念与边界。
2. `BudgetResolver`
   - 根据模型、策略、任务阶段和输入形态求出本次预算。
3. `BatchPlanner`
   - 根据预算把源文切成批次计划。
4. `BatchProgress`
   - 记录已经完成到哪里、失败到哪里、哪些需要重试。
5. `CoverageMerge`
   - 合并多批次结果，去重、提炼、保留证据链。

不要把这些逻辑塞回 `ReferenceSourceDocumentExtractionService`，否则它会再次变成一个难以维护的总管服务。

### 4.2 预算策略至少应包含哪些维度

预算策略不应只有一个 `max_chars`。建议至少包含：

1. `sourceWindowRatio`
   - 单批原文预算占可用上下文的目标比例。

2. `minSourceChars`
   - 单批最低原文字数。

3. `maxSourceChars`
   - 单批最高原文字数。

4. `minSectionsPerBatch`
   - 至少覆盖多少个切片/章节。

5. `maxSectionsPerBatch`
   - 单批最多覆盖多少个切片/章节。

6. `instructionReserveRatio`
   - 给系统指令、工具协议、结构化输出预留的比例。

7. `carryForwardReserveRatio`
   - 给上批中间摘要、时间线、已知角色表等保留的比例。

8. `responseReserveRatio`
   - 给模型输出预留的比例。

9. `safetyReserveRatio`
   - 防止 token 估算误差的缓冲余量。

10. `oversizeSectionSplitPolicy`
   - 单章过长时，是按自然段、场景标记还是字数窗口再拆。

11. `batchGoalKind`
   - 当前批次是 seed、语义提取、风格提取、时间线提取还是 consolidate。

### 4.3 默认值不应太激进

如果只能先给一个默认建议，我更倾向于：

1. 原文窗口目标比例默认 30% 到 45%。
2. 不是直接 50%。
3. 只有在 seed/bootstrap 阶段且输出要求较轻时，才允许逼近 50%。

理由是：

1. 提取任务比普通聊天更依赖结构化输出。
2. 我们还要塞工具约束、边界纪律和中间结果。
3. 还要给模型保留稳定输出空间，不然很容易中途崩成半截 JSON 或草率摘要。

也就是说：

```text
“半个上下文”适合作为上限倾向，
不适合作为常态默认值。
```

---

## 5. 分批规划不应只有一种，至少要覆盖四类输入

### 5.1 章节清晰的书籍

这是最好处理的一类。

推荐策略：

1. 先识别章节边界。
2. 批次尽量与章节对齐。
3. 只有章节过长时才在章内再拆。

原因：

1. 章节通常天然承载阶段性情节与主题。
2. 有利于保留可追溯性。
3. 后续做时间线、人物弧线、风格演化时更自然。

### 5.2 单章极长的轻小说或实体书章节

这类不能死守“一章一个批次”。

推荐策略：

1. 先保留章节身份。
2. 再在章节内部按场景/段落群/字数预算做子分段。
3. 每个子分段必须带上 `chapter_id + local_segment_index`。

这样既不会把超长章节整章塞爆，又不会失去“这是同一章内部片段”的语义关联。

### 5.3 无章名、只有长文本的数据集

例如：

1. OCR 后整本拼接文本。
2. 导入的是若干长段说明文本。
3. 杂糅资料集。

推荐策略：

1. 先走结构识别。
2. 识别失败时退化到段落簇切分。
3. 切分时优先保自然段边界，不要简单固定字数硬劈。
4. 对每段生成稳定 `segment_id` 和源位置范围。

### 5.4 多文件资料包

例如：

1. 角色设定文档 + 世界观文档 + 年代表 + 外部参考资料。
2. 原作正文 + 附录 + 设定集。

这类不能先拼成一条长字符串再切。

正确做法应是：

1. 先保文件级边界。
2. 再做文件内分批。
3. Batch plan 里必须保留 `document_id / source_file / source_kind`。
4. consolidate 阶段再跨文件整合，而不是摄取阶段提前糊掉。

---

## 6. 真正的提取应该是“分阶段生产”，不是“直接把整本书摘要一次”

这点非常关键。

如果我们只讨论“单次喂多少”，仍然可能把系统误导成：

```text
喂一批 -> 出最终知识
```

这不够稳，也不够通用。

更合理的正式主链应是：

### 6.1 第一阶段：source bootstrap

职责：

1. 读取原文。
2. 标准化文本。
3. 识别章节/分段。
4. 建立 batch plan。
5. 产出可追溯源段与轻量 seed。

### 6.2 第二阶段：batch extraction

职责：

1. 按批读取源段。
2. 在预算内向提取智能体投喂原文。
3. 产出批次级中间结果，而不是直接写死为最终知识。

中间结果可包括：

1. 角色候选。
2. 地点候选。
3. 世界规则候选。
4. 叙事手法候选。
5. 章节事件摘要。
6. 风格特征观察。
7. 边界/引用风险。

### 6.3 第三阶段：coverage consolidation

职责：

1. 合并前面多个 batch 的中间结果。
2. 去重。
3. 解决别名与同一实体多次出现的问题。
4. 保留来源追踪。
5. 形成候选 reference entries。

### 6.4 第四阶段：review and finalize

职责：

1. 审核提取结果是否有证据。
2. 审核是否覆盖主要范围。
3. 审核是否存在过度臆断。
4. 再进入 package finalize。

这条链路比“整本一次摘要”重，但它才配得上我们想要的可复用、可分享、可扩展体系。

---

## 7. 用户可控，但不该把复杂度砸到用户脸上

### 7.1 用户说“这个界限最好可控制”是对的

预算策略必须允许控制，否则：

1. 大上下文模型会被浪费。
2. 小上下文模型会频繁爆掉。
3. 不同书种、不同提取目标的效果差异无法调试。

### 7.2 但控制面不能直接裸露一堆比率参数

如果把下面这些全扔给普通用户：

1. source ratio
2. instruction reserve
3. carry-forward reserve
4. response reserve
5. max batch chars
6. oversize split heuristic

那几乎一定会增加心智负担。

### 7.3 更好的暴露方式

推荐分两层暴露：

1. 普通层：提取强度/覆盖方式 profile
   - 自动
   - 保守
   - 标准
   - 深入

2. 高级层：预算覆盖高级设置
   - 单批原文上限
   - 单批最小下限
   - 章节优先 / 场景优先 / 自动切分
   - 是否允许章内再拆
   - 是否保留中间批次产物

也就是说：

```text
默认给 profile，
把精细预算放进高级选项，
不要让普通用户一上来就面对算法参数。
```

---

## 8. “最小下限”必须保留，而且不止一种下限

用户提到“应设最小下限，比如多少字多少章”，这个判断很重要，我同意，而且要再扩一层。

建议至少保留三种下限：

1. **字数下限**
   - 防止批次太碎，导致语义提炼只看到局部皮毛。

2. **段/节下限**
   - 防止只喂半段或孤立片段。

3. **语义完整性下限**
   - 优先在自然边界截断，不在一句话中间或一个场景最关键的转折处生硬截断。

这里第三种比前两种更重要，但也最难纯程序化判断。所以实际做法应当是：

1. 程序先尽量尊重自然边界。
2. 智能体在 batch extraction 时再标注“本批仍有明显未闭合语义，需要续批上下文”。

这样可以避免程序端自以为切得很好，实际上把一个关键人物反转切成两半。

---

## 9. 分批之后，必须正式承认“覆盖状态”是系统资产

如果没有 coverage state，多批提取很快就会退化成：

1. 不知道提到哪了。
2. 不知道哪些段没跑。
3. 不知道失败后该从哪续。
4. 不知道已完成结果是否足够形成全局知识。

所以建议正式建模：

1. `total_segment_count`
2. `completed_segment_count`
3. `failed_segment_count`
4. `pending_segment_count`
5. `covered_chapter_ranges`
6. `requires_followup_segments`
7. `consolidation_ready`

这不是 probe 才需要的东西，而是正式运行时资产。

---

## 10. 这套能力不只服务写作，同样服务拆书、解书、总结与未来同人

这点必须再强调一次。

如果我们把“摄取预算与分批生成”理解成只是为小说写作做准备，就会把它做窄。

它实际上服务的是：

1. 原作体系提取。
2. 历史/科学/神话资料包提取。
3. 多文件设定集导入。
4. 拆书与续写前置提取。
5. 解书、总结、评书式拆解。
6. 未来同人/参考改写的基础资产生成。

因此这层必须落在：

1. `reference_substrate`
2. `reference_extraction`

这种中性的基础层，

而不是绑死在某一个写作项目入口或某一个 GUI 页面逻辑里。

---

## 11. 对当前项目的正式建议

### 11.1 现在不该做什么

当前最不该做的是：

1. 继续增加 `maxChapterEntries` 之类的 seed 参数来假装解决全书提取。
2. 把“半个上下文”直接写成常量塞进 prompt builder。
3. 把 batch 逻辑硬塞进 `ReferenceSourceDocumentExtractionService`。
4. 把用户暴露面直接做成十几个低层参数。

### 11.2 现在最该做什么

下一步更正确的演化顺序应是：

1. 先正式立 `ReferenceIngestionBudgetPolicy` 合同。
2. 再立 `ReferenceSourceBatchPlan` 与 `BatchPlanner`。
3. 把当前 seed extraction 收缩回 bootstrap 身份。
4. 让正式 reference extraction 运行时消费 batch plan，而不是直接消费整本原文或几个 seed 条目。
5. 再考虑 GUI/CLI 如何以 profile + advanced 的方式暴露这套策略。

---

## 12. 最终结论

把这轮收成一句话：

```text
用户提出的“半个上下文 + 可控下限 + 分批生成”方向是对的，
但它不该落成一个简单截断公式，
而应升级为“摄取预算策略 + 批次规划 + 覆盖状态 + 分批合并”的正式架构层。
```

再说得更直白一点：

1. 当前提取系统已经有了“怎么开始”的能力。
2. 但还没有“怎么覆盖整本、整套资料并稳定收束”的能力。
3. 这次要补的，正是后者。

而且这一步补对了，后面无论是：

1. 哈利波特这种原作体系提取，
2. 历史与科技资料包提取，
3. 多文件设定集导入，
4. 未来拆书、解书、同人前置知识生产，

都会共用这一条主链，而不会每种场景都重新发明一套分批逻辑。

这才是值得投入的长期骨架。
