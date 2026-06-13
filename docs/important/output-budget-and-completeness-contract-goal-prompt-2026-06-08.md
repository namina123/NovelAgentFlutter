# 输出侧预算与完整性合同目标提示

适用时间：2026-06-08 之后  
用途：给其他会话窗口直接开启目标模式使用  
关联主文档：

- `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md`
- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`

---

## 1. 直接可用的目标提示

把下面整段作为目标模式提示使用：

```text
请以 `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md` 为本轮最高优先级分析依据，并同时遵守：

- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`

在当前仓库中正式收口“输出侧预算与完整性合同”这条共享能力，并首先接入 `reference_extraction` 主链。你的目标不是只改 prompt 文案，而是把“输出被压缩、被概括、未覆盖充分却被误判为完成”的问题，正式变成可建模、可验证、可继续运行的运行时合同。

本轮必须严格保留以下判断，不得回退：

1. 当前 `ReferenceSourceDocumentExtractionService` 的定位仍只是 source bootstrap / seed extraction / evidence scaffolding，不是完整语义提取。
2. 现有 `ReferenceIngestionBudgetPolicy` 仍然保留，它解决的是输入预算与切批，不应被新合同取代。
3. 新增能力应补的是“输出侧预算、完整性交付、遗漏显式报告、续提机制、覆盖账本”，而不是把 seed/bootstrap 做得更重。
4. 默认单并发的参考提取纪律继续保留；本轮不要把多并发做成默认主线。
5. 不允许把哈利波特或任何测试题材写死进 core。
6. 不允许用“请更全面一些”这类 prompt 文案替代正式合同层。
7. 不允许让 watchdog 承担输出完整性判断；watchdog 仍只负责活性与前进性保底。
8. 不允许通过继续堆大文件、万能 runtime service 或跨层偷逻辑来实现。

本轮至少应完成以下结果：

1. 在 core 中正式建立可复用的输出侧合同，至少覆盖：
   - `OutputBudgetPolicy`
   - `OutputCoverageContract`
   - `OutputCoverageLedger`
   - `OmissionReport`
   - `ContinuationRequest`
   - `OutputCompressionRisk` 或等价表达
2. 把这套合同优先接入 `reference_extraction` 主链，而不是只停留在文档。
3. 让 proposal generation / review / finalize 至少有一部分真正消费这套合同，能够区分：
   - 结构完成
   - 语义覆盖不足
   - 输出压缩风险
   - 需要继续提取
4. 让模型在当前轮装不下、或无法全面覆盖时，可以显式提交遗漏报告或续提请求，而不是静默压缩。
5. 让 coverage 不再只表达“批跑完了”，而开始表达“哪些维度覆盖了、哪些没覆盖”。
6. 至少补 focused tests，证明系统不会再把“少量大概括条目 + 格式合规”直接误判为完整完成。
7. 如需改 prompt，只允许作为合同消费层的配套；不得把问题重新降级成纯 prompt engineering。

实现风格要求：

1. 优先做共享合同层，不要把逻辑写死在 `reference_extraction` 独占实现里。
2. 程序负责合同、状态、分类、续提与账本；智能体负责按合同交付语义内容。
3. 不要让程序直接做文学意义上的强判定，但可以做结构完整性、维度覆盖和压缩风险口径判断。
4. 保持 core / adapters / app 分层；新增 adapters 只负责桥接与持久化，不成为新规则中心。
5. 如果一个文件开始同时承担预算解析、prompt 拼装、review 判断、merge、持久化多种重职责，先拆再继续。

本轮验证要求：

1. 至少补一条 focused 验证，证明输出不足时会进入 `OmissionReport` 或 `ContinuationRequest`，而不是假成功。
2. 至少补一条 focused 验证，证明“条目数量少但概括过大”的结果会触发输出压缩风险或覆盖不足信号。
3. 至少补一条 focused 验证，证明 `reference_extraction` runtime 能消费新的输出合同，并把状态带到后续 review / finalize 或继续运行分支。
4. 如时间允许，再做一条哈利波特第一卷的 focused 回归，证明这套合同能帮助识别第一卷中后段关键设定覆盖不足，而不是继续把它误判成 PASS。

本轮不要做的事：

1. 不要把问题扩大成“重做整个参考提取系统”。
2. 不要把输出预算与完整性逻辑塞进 watchdog。
3. 不要靠新增更长的 prompt 文案假装解决问题。
4. 不要为了追求单轮完整，把每个 batch 都做成极长极重的输出。
5. 不要让 probe 脚本替代正式业务结构。
```

---

## 2. 推荐的一句 objective

如果要压缩成目标工具的一句 objective，推荐：

```text
在当前仓库中依照 docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md 正式落地“输出侧预算与完整性合同”共享能力，并首先接入 reference_extraction 主链：建立 OutputBudgetPolicy / OutputCoverageContract / OmissionReport / ContinuationRequest / CoverageLedger 等核心合同，让系统不再把被压缩、被概括、覆盖不足但格式合规的输出误判为完成。
```

---

## 3. 不应被当作完成的假信号

以下情况都不应被视为完成：

1. 只是给 prompt 多加了“请全面输出”之类的文字提醒。
2. 只是继续调大 `responseReserveRatio`，没有正式输出合同。
3. 只是让单轮能输出更长文本，没有遗漏报告和续提机制。
4. 只是让 tests 通过，但 runtime 仍无法区分“批跑完了”和“语义覆盖完成了”。
5. 只是把问题写进文档，没有 core/adapters 的正式实现。
