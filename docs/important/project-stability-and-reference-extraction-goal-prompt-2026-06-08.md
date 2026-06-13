# 全项目稳定性治理与参考提取收口目标提示

适用时间：2026-06-08 之后  
用途：给下一个会话窗口直接开启目标模式使用  
关联主文档：

- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`

---

## 1. 直接可用的目标提示

把下面整段作为目标模式提示使用：

```text
请以 `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md` 为本轮最高优先级总分析依据，并同时遵守：

- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`

在当前仓库中开展一次非针对性的、广泛性的全项目扫描与治理。你的目标不是只修某一条链，而是抓出当前项目中真实影响可用性、稳定性、完整性、关联性和用户体验的关键问题，并逐个收口。请特别关注“一般长任务”与“内置的另一种长任务”的稳定性与可用性，但这个“特别关注”不代表可以忽略其他模块；其他地方只要发现关键问题，也必须修正。

本轮必须严格保留以下架构判断，不得回退：

1. 当前 `ReferenceSourceDocumentExtractionService` 的定位仍只是 source bootstrap / seed extraction / evidence scaffolding，不是完整语义提取。
2. 正式参考提取仍属于独立任务族 `reference_extraction`，不得退回为“写作 prompt 顺带多看资料”。
3. 应用级 `ReferenceEvidenceSubstrate`、项目级 `ProjectReferenceAttachmentLayer`、项目级 `ProjectInformationCapabilityLayer` 三层分工不得被打乱。
4. 参考提取 runtime 当前默认应保持单并发，尤其是重文本消费阶段默认单路执行；不得把“同一 source batch 多线程重复重读原文”做成默认实现。
5. 未来可扩展多并行能力可以预留合同和策略扩展位，但本轮不要把多并行做成默认主线。
6. 分批策略必须遵守“结构优先，预算逼近，超限裂解，缺结构退化”。
7. 不允许把哈利波特、快穿、死亡回归、修仙穿越等测试题材写死进 core。
8. 不允许为了赶进度把 planning、batching、progress、review、merge、persistence、projection、UI glue 继续堆进一个大文件或万能 service。

本轮工作方式要求：

1. 先广泛扫描整个项目，整理真实阻断项、共享主链缺口、明显设计回退和用户面不合理处。
2. 按严重度排序后实施修复；先修影响真实可用性的阻断项，再修共享主链缺口，再收口其余明显问题。
3. 对长任务与参考提取主链，必要时可以使用 focused probe / mock / real probe 验证，但 probe 不能替代正式业务结构。
4. CLI 本轮不是重点；如果核心能力收口后能顺手接入最小入口，可以顺手做，但不得因此拖慢主线。
5. 全程遵守解耦合、单一职责、core/adapters/app 分层、避免单文件过重、真实问题真实验证，不粉饰未完成项。

本轮至少应完成以下结果：

1. 对整个项目做一次真实问题扫描，并以代码实现为中心修复关键问题，而不是只出报告。
2. 明确收口一般长任务与内置特殊长任务中仍影响稳定性与可用性的关键问题，必要时补 focused test / mock / probe。
3. 收口参考提取 runtime 中尚未正式落地的关键主链缺口，至少包括：
   - 预算与分批正式合同
   - chapter-first / structure-first batching 主链
   - 单并发 execution discipline 或等价策略表达
   - batch progress / coverage state 的最小可验证主链
4. 对共享逻辑做一次审视：凡是本应普通任务、长任务、拆书、提取共用的逻辑，不应继续被写死在某一条路径中。
5. 保证 GUI 主路径不会因为这轮修复而退化；如有必要，顺手修复明显误导或实际不可用的用户面问题。
6. 若某个大问题一轮无法完全做完，必须留下清晰剩余边界，但前提是主链已经更稳定、更自然，而不是停在半补丁状态。

完成上述修复后，请按下面顺序做真实验证：

第一阶段：参考提取验证
1. 先验证《哈利波特》第一卷提取可用。
2. 这一步需要确认：
   - 提取结果真实落到了正确结构中
   - 参考资产可被后续消费
   - 不是只靠程序 seed 假装完成了知识库提取

第二阶段：完整提取验证
1. 在第一阶段通过后，再做哈利波特完整剧情的提取。
2. 这一步的目标是验证整书/整套剧情级提取主链，而不是只看一个小样本。

第三阶段：端到端消费验证
1. 以提取结果为基础，写一篇故事：
   - 主角是来自地球的中国人
   - 地球原本无法修炼，但主角偶然获得修仙功法
   - 主角前世作为天师老死后穿越到哈利波特世界，转生成中国人
   - 被霍格沃兹选中后进入霍格沃兹，与哈利同级
   - 在魔法世界中利用修仙知识发展日常、解决问题
   - 需要解决原作中的意难平，并写好由此带来的剧情偏移
   - 整体基调偏轻松向
2. 这条写作验证中，修仙相关知识请优先通过知识卡测试，并通过联网搜索生成知识卡或研究结果，而不是完全裸写。
3. 这一步的目标不是做题材特化，而是验证：
   - 提取结果能否被真实消费
   - 项目知识卡与外部研究链能否真实参与写作
   - 写作结果是否明显受信息资产影响，而不是仍然只靠模型裸猜

验收标准必须诚实：

1. 至少修复一批真实阻断可用性的核心问题，而不是只补文档。
2. 一般长任务与内置特殊长任务的稳定性有真实证据支持的改善。
3. 参考提取 runtime 的预算/分批/单并发纪律/覆盖状态至少有一部分已正式进入主链并得到验证。
4. 《哈利波特》第一卷提取必须真实可用后，才能推进完整剧情提取。
5. 最终写作验证必须真实消费提取结果、知识卡和必要的外部研究，而不是空喊“应该会用到”。
6. 若某部分仍未完成，必须明确记录剩余边界与原因，不得粉饰为已完成。

本轮不要做的事：

1. 不要把哈利波特或修仙题材写死进 core。
2. 不要把多并行做成默认实现。
3. 不要为了证明“我们也有 CLI”而把大量时间耗在 CLI 表面接线。
4. 不要用更多 probe 去掩盖正式 runtime 没收口。
5. 不要通过继续堆大文件、万能 runtime service、跨层偷逻辑的方式赶工。
```

---

## 2. 推荐的一句 objective

如果要压缩成目标工具的一句 objective，推荐：

```text
在当前仓库中依照 docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md 开展一次全项目真实可用性治理：广泛扫描并修复关键问题，重点收口一般长任务与内置特殊长任务稳定性，以及 reference_extraction runtime 的预算/分批/单并发/覆盖状态主链，并在修复后先完成《哈利波特》第一卷提取验证，再做完整剧情提取，最后用提取结果、知识卡和联网研究真实驱动一条哈利波特派生写作验证链。
```

---

## 3. 不应被当作完成的假信号

以下情况都不应被视为完成：

1. 只是新增了新的分析文档，没有真实修复项目问题。
2. 只是把“单并发”写成注释，没有正式策略表达与验证。
3. 只是让哈利波特第一卷跑出一点结果，就说整书提取可用。
4. 只是跑了 probe，没有把 runtime 主链收口。
5. 只修参考提取，不修广泛扫描中暴露出的其他关键问题。
6. 只是让最终故事写出来，但其实没有真实消费提取结果、知识卡和外部研究。
7. 通过把题材测试逻辑写进 core 来换取表面通过。
