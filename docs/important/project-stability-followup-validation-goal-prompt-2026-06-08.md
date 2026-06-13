# 全项目稳定性补测与长任务探针收口目标提示

适用时间：2026-06-08 之后  
用途：给另一个会话窗口直接开启目标模式使用，专门补做可能遗漏的扫描、检测、长任务探针与真实验收  
关联主文档：

- `docs/important/project-stability-and-reference-extraction-goal-prompt-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`

---

## 1. 直接可用的目标提示

把下面整段作为目标模式提示使用：

```text
你现在不要假定上一轮已经把“广泛扫描、检测、长任务探针、真实验收”做完。请以当前工作树、当前 artifacts、当前测试结果和当前 probe 产物作为唯一可信依据，重新补做这部分工作。

最高优先级遵守：

- `docs/important/project-stability-and-reference-extraction-goal-prompt-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`

本轮的唯一目标不是继续泛泛开发，而是补做上一轮可能遗漏的“扫描、检测、长任务探针和真实验收”，并对扫描中发现的问题做针对性修复。你必须默认上一轮可能只做了部分实现，没有做完整验证；未经当前证据证明，不得把任何能力视为已经可用。

这轮重点仍然是：

1. 非针对性、广泛性扫描整个项目。
2. 抓出真实影响可用性、稳定性、完整性、关联性和用户体验的问题。
3. 对每个关键问题做针对性处理或完善。
4. 尤其保证一般长任务与内置另一种长任务运行的稳定性与可用性。

但这里的“尤其”只是加权，不是排他。其他地方只要有关键问题，也必须修。

本轮必须严格保留以下架构判断，不得回退：

1. 当前 `ReferenceSourceDocumentExtractionService` 仍只是 source bootstrap / seed extraction / evidence scaffolding，不是完整语义提取。
2. 正式参考提取仍属于独立任务族 `reference_extraction`，不得回退成“写作顺带多看资料”。
3. 应用级 `ReferenceEvidenceSubstrate`、项目级 `ProjectReferenceAttachmentLayer`、项目级 `ProjectInformationCapabilityLayer` 三层分工不得被打乱。
4. 参考提取 runtime 当前默认应保持单并发，尤其是重文本消费阶段默认单路执行。
5. 未来可扩展多并行能力可以预留合同和策略位，但本轮不要把多并行做成默认主线。
6. 分批策略必须遵守“结构优先，预算逼近，超限裂解，缺结构退化”。
7. 不允许把哈利波特、快穿、死亡回归、修仙穿越等测试题材写死进 core。
8. 不允许继续把 planning、batching、progress、review、merge、persistence、projection、UI glue 堆进大文件或万能 service。

本轮工作方式必须这样执行：

第一步：重新扫描与审计
1. 检查当前工作树与已有 artifacts，不相信口头“做完了”。
2. 整理出：
   - 真实阻断项
   - 共享主链缺口
   - GUI 主路径问题
   - 探针/测试未做或做得不够的地方
3. 把问题按严重度排序，先修最影响真实可用性的部分。

第二步：补做关键检测
你必须至少重新确认以下几类证据，而不是只看单条测试：
1. focused unit / contract tests 是否覆盖新增合同。
2. runtime integration tests 是否覆盖长任务与参考提取主链。
3. GUI 或 viewmodel 入口是否仍能触发正确实现。
4. probe 是否真的测到了目标，而不是脚本本身只做了更窄的事情。

第三步：补做长任务探针
必须重新检查并在必要时重跑以下两类真实或准真实探针：
1. 一般长任务探针
   - 验证章节推进
   - 验证正文落盘
   - 验证表达限制是否真实生效
   - 验证中断/修订/继续链是否真实可用
2. 内置另一种长任务探针
   - 验证调度稳定性
   - 验证不会无故停摆
   - 验证真正问题和假失败已区分
   - 验证 supervisor / review / repair / delivery 等共享链是否可用

必要时可新增 focused probe，但 probe 只是验证工具，不是正式业务中心。

第四步：补做参考提取相关检测
至少确认：
1. 预算与分批正式合同是否已进入主链；如果没有，继续实现并补 focused tests。
2. chapter-first / structure-first batching 是否有真实验证。
3. 单并发 execution discipline 是否只是写在文档里，还是已有正式表达与验证。
4. batch progress / coverage state 是否已成为最小可验证主链。

第五步：真实验收
完成修复后，必须按顺序做这些验收：

A. 《哈利波特》第一卷提取验证
- 确认提取结果真实落盘到正确结构
- 确认参考资产可被后续消费
- 确认不是只靠程序 seed 假装完成知识库提取

B. 《哈利波特》完整剧情提取验证
- 仅在 A 通过后才做
- 目标是验证整书/整套剧情级提取主链，而不是小样本

C. 参考资产真实消费写作验证
- 若已有样章或 probe 产物，先审查它是否真的测到了目标
- 不能因为脚本只写了一章样章，就把它误当成长链消费验证完成
- 若表达限制没有显式绑定或没有真实生效，则该验证不算通过

本轮必须诚实处理一个常见假象：
如果某条 probe 脚本本来只设计成“单章样章交付”，那它“只出一章”不一定是 runtime 失败；但它也绝不能被描述成“长链消费验证已经完成”。你必须区分：
1. 脚本目标本来就只有一章
2. 系统本应继续却异常停止

验收标准必须同时满足：

1. 至少重新补做一轮真实的广泛扫描，不只是继续开发。
2. 至少修掉一批扫描中发现的关键问题，而不是只生成报告。
3. 一般长任务与内置另一种长任务，至少各有一条可信的验证证据支持其可用性改善。
4. 参考提取 runtime 的预算/分批/单并发纪律/覆盖状态，至少有一部分已正式进入主链并被验证。
5. 任何 probe 如果没有显式挂上需要验证的约束（例如表达限制），就不能把 probe 结果当成那项能力已通过。
6. 如果某条真实消费写作验证中出现了明显 AI 腔或已知风险句式，且对应表达限制并未显式接线或未生效，则必须修正后重验。
7. 不得粉饰未完成项；凡是只完成样章、只完成单条链、只完成最小落盘，都必须明确写明边界。

本轮不要做的事：
1. 不要只因为 artifacts 存在就默认能力通过。
2. 不要只跑一条窄测试就支持一个很宽的结论。
3. 不要只修 probe 脚本表面而不修正式 runtime。
4. 不要把 CLI 表面接线当主线。
5. 不要为了赶进度继续制造大文件和万能中心。
```

---

## 2. 推荐的一句 objective

如果要压缩成目标工具的一句 objective，推荐：

```text
在当前仓库中依照 docs/important/project-stability-and-reference-extraction-goal-prompt-2026-06-08.md 补做上一轮可能遗漏的全项目扫描、关键检测与长任务探针：以当前工作树和 artifacts 为证据重新审计并修复关键问题，重点验证一般长任务、内置特殊长任务和参考提取 runtime 的真实可用性，必要时重跑哈利波特提取与参考资产消费写作验证，并严格区分“样章通过”和“长链通过”。
```

---

## 3. 不应被当作完成的假信号

以下情况都不应被视为完成：

1. 只是口头说上一轮已经做完了。
2. 只是看到一个章节文件落盘，就说长任务消费验证通过了。
3. 只是 probe 报告写了 `PASS`，却没有核它到底测了什么。
4. 只是样章里出现了参考资产元素，就说表达限制、知识卡、研究链都已真实工作。
5. 只是 artifacts 很多，就说广泛扫描和长任务探针已补齐。
6. 只是顺手修了一两个 bug，没有重新建立可信的验证证据。
