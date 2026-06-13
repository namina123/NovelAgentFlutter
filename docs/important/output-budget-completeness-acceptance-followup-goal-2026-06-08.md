# 输出预算与完整性交付验收补漏目标提示

适用时间：2026-06-08  
用途：给新的目标模式会话直接使用  
前置阅读：

- `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md`
- `docs/important/output-budget-and-completeness-contract-goal-prompt-2026-06-08.md`

---

## 一、这轮验收后的真实结论

上一轮实现不是空转，已经把以下东西真正落进代码：

1. `OutputBudgetPolicy`
2. `OutputCoverageContract`
3. `OutputCoverageLedger`
4. `OmissionReport`
5. `ContinuationRequest`
6. `OutputCompressionRisk`

而且相关 focused tests 也通过了。

但这轮还不能判定为完全收口，原因不是“没写”，而是“后果还不够硬”。

当前最关键的两个缺口是：

1. **不完整/高压缩风险结果虽然被识别出来了，但仍会走正常 finalize/export/project 链。**
2. **proposal 的 `coverage_dimension_ids` 经过过滤后可能为空，但当前生成器仍会把这类 proposal 作为有效候选放行。**

所以这轮新的目标，不是重做合同层，而是把这两个缺口优雅地收住。

---

## 二、这轮必须保留的已有成果

以下内容不得回退：

1. `ReferenceSourceDocumentExtractionService` 仍只是 seed/bootstrap，不是完整语义提取器。
2. `ReferenceIngestionBudgetPolicy` 继续保留，负责输入预算与切批。
3. `OutputBudgetPolicy` 这一层继续作为共享合同层存在，不得降级回纯 prompt 文案。
4. 默认单并发参考提取纪律继续保留。
5. 不允许把任何测试题材、作品名、题材机制写死进 core。
6. 不允许用大而杂的 runtime service 继续堆补丁，必须顺着现有分层自然收口。

---

## 三、当前验收卡住的两个具体事实

### 3.1 不完整结果仍会被正常 finalize / export / project

当前实现中：

1. `ExecuteReferenceExtractionFromSourceDocumentUseCase` 在拿到 `reviewOutcome` 后，会无条件继续 merge finalized snapshot 并写入 substrate。
2. `ReferenceExtractionPackageMergeService` 会把非 completed 结果描述为“阶段性结果/partial finalized”，但仍然生成正式 snapshot。
3. `ProjectReferenceExtractionRuntimeService` 后续仍会继续：
   - export bundle
   - attach to project
   - project 信息到项目知识层

这意味着系统虽然知道它“不完整”，但对上层消费路径来说，仍很像一次正常成功。

这会直接破坏我们要的语义边界：

1. 用户或上层流程会得到一个“已经完成”的包外观。
2. 但这个包可能只是 `continuation_recommended` 或 `coverage_insufficient`。
3. 这会让“不完整但诚实”的合同层，重新退化成“记录了问题，但照样当成功用”。

### 3.2 空 coverage 维度 proposal 仍可能混入候选集

当前生成器会：

1. 先读取 `coverage_dimension_ids`
2. 按 contract 允许列表过滤
3. 但过滤结果即使为空，也不会阻止 proposal 被加入 `proposals`

这会导致：

1. proposal 看起来结构合法
2. review 也可能基于 confidence/evidence 接受它
3. 但 coverage ledger 无法从这条 proposal 上拿到任何覆盖贡献

这相当于合同层留下了一个静默漏口。

---

## 四、本轮目标

把下面整段直接作为目标模式提示使用：

```text
请基于以下文档继续收口当前仓库中的 reference_extraction 输出预算与完整性交付合同：

- docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md
- docs/important/output-budget-and-completeness-contract-goal-prompt-2026-06-08.md
- docs/important/output-budget-completeness-acceptance-followup-goal-2026-06-08.md

你这轮不是从零开始实现合同层，因为核心合同已经落地并且 focused tests 通过了。你这轮要做的是把验收里还没收住的两个缺口钉死，让“不完整结果不会再伪装成正常成功”，并让 coverage contract 不再留静默漏口。

本轮必须先承认并保留以下现状：

1. 现有 OutputBudgetPolicy / OutputCoverageContract / OutputCoverageLedger / OmissionReport / ContinuationRequest / OutputCompressionRisk 已经存在，不要推翻重写。
2. ReferenceSourceDocumentExtractionService 仍然只是 seed/bootstrap，不是完整语义提取。
3. ReferenceIngestionBudgetPolicy 继续保留，负责输入预算与切批；本轮不要拿输出合同去替代它。
4. 默认单并发 reference_extraction 纪律继续保留。
5. 不允许把任何测试题材、作品名、哈利波特等写死进 core。
6. 不允许把修复做成新的大而重服务类，不允许继续把职责堆进一个 600+ 行文件。

你这轮至少必须完成下面四类结果：

第一类：正式收紧 finalize / export / project 语义
1. 明确建模并实现：当 outputCompletionStatus 不是 completed 时，reference_extraction 结果不能再沿用“正常完成”的消费语义。
2. 你需要在架构上给出优雅分支，而不是简单粗暴地把所有持久化都砍掉。允许的方向包括：
   - 仅保留 staging run，不生成正式 finalized snapshot；
   - 生成 partial snapshot，但它必须与正常 finalized/publishable/projectable 结果严格区分，且默认不能 export / attach / project；
   - 或其他更优雅但同等严格的合同分支。
3. 无论采用哪一种，都必须保证：上层 runtime、bundle export、project projection、project mount 不会把 continuation_recommended / coverage_insufficient 结果当成普通成功产物消费。
4. 同时保留可恢复性：系统仍要能根据 staging run、reviewOutcome、continuationRequest 继续下一轮提取，而不是丢状态。

第二类：堵住空 coverage proposal 漏口
1. 在 proposal generation 或更合适的合同边界上，拒绝 coverage_dimension_ids 过滤后为空的 proposal，除非你有更严格且更自然的替代合同。
2. 这个拒绝必须是结构性规则，不是靠 review 期望兜底。
3. 如果你认为应该保留这类 proposal，也必须让它们进入另一个显式分类，不得再以普通 coverage-bearing proposal 身份混入主链。

第三类：补齐 focused tests
1. 增加 focused test，证明 outputCompletionStatus 为 continuation_recommended 或 coverage_insufficient 时：
   - 不会再走普通 finalize 成功语义；
   - 不会 export bundle / attach to project / project 到知识层，除非明确允许 partial 分支并且该分支有不同语义；
   - staging/continuation 状态仍保留，后续可续跑。
2. 增加 focused test，证明空 coverage_dimension_ids proposal 不会进入正常候选集。
3. 如果你引入 partial snapshot 分支，也要补 test 证明它与 normal finalized snapshot 在元数据、可见性或消费路径上有明确差异。

第四类：保持实现优雅
1. 不要把判断逻辑同时塞进 use case、merge service、runtime service 三处各写一份。
2. 优先抽一个自然的合同或策略对象，让 core 定义状态语义，adapters/runtime 只消费。
3. 不要用布尔补丁把链路缝起来；要让“不完整结果”和“正常完成结果”在模型上就是两种不同交付状态。
4. 不要顺手引入与本轮无关的大改，比如 watchdog、并发调度器重写、整套 UI 重做。

本轮验收最低标准：

1. 现在的 focused tests 继续通过。
2. 新增 focused tests 证明“不完整结果不会伪装成普通成功”。
3. 新增 focused tests 证明“空 coverage proposal 已被合同层挡住”。
4. 核心代码分层依然清晰，没有再堆出新的职责怪物文件。

注意：这轮的目标不是“把参考提取所有问题都解决”，而是把已经实现出来的输出合同从“能识别问题”推进到“真的改变运行时交付语义”。
```

---

## 五、建议重点检查的文件

建议优先检查并在必要时重构这些位置：

1. `packages/novel_agent_core/lib/src/use_cases/execute_reference_extraction_from_source_document_use_case.dart`
2. `packages/novel_agent_core/lib/src/reference_extraction/reference_extraction_package_merge_service.dart`
3. `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart`
4. `packages/novel_agent_adapters/lib/src/reference_extraction/llm_reference_extraction_proposal_generator.dart`

---

## 六、这轮不算完成的假信号

以下情况都不应算完成：

1. 只是继续记录 `outputCompletionStatus`，但 runtime 仍 export / attach / project。
2. 只是把 description 文案改成“partial”，但上层消费路径不变。
3. 只是新增一个布尔开关，却没有形成清晰的交付状态模型。
4. 只是给 prompt 多写一句“每条 proposal 至少给一个 coverage 维度”，但代码仍放行空 coverage proposal。
5. 测试全绿，但没有覆盖“不完整结果被错误消费”的分支。

---

## 七、我这轮验收的结论

一句话结论：

```text
当前实现已经把“输出预算与完整性合同”做到了真正可运行的第一阶段，但还没有做到可放心交付给上层消费的第二阶段；新的目标应聚焦于收紧不完整结果的交付语义，并堵住空 coverage proposal 的合同漏口。
```
