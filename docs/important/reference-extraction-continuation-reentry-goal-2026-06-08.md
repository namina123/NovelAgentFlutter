# reference_extraction 续提重入语义补漏目标提示

适用时间：2026-06-08  
用途：给新的目标模式会话直接使用  
前置阅读：

- `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md`
- `docs/important/output-budget-and-completeness-contract-goal-prompt-2026-06-08.md`
- `docs/important/output-budget-completeness-acceptance-followup-goal-2026-06-08.md`

---

## 一、这轮验收结论

上一轮不是失败，而是**完成了第二阶段的大半**：

1. 非 completed 结果现在已经不会再走 publishable/export/project 主消费链。
2. 空 `coverage_dimension_ids` proposal 也已经被挡在合同层外。
3. focused tests 证明了：
   - incomplete result 会停留在 staging；
   - export / attach / project 会被跳过；
   - invalid coverage proposal 会被拒绝。

但这轮仍然**不能判定为完全通过**，因为还缺最后一个关键行为：

```text
不完整结果虽然被正确留在 staging，
但它还没有真正具备“继续续提”的重入语义。
```

---

## 二、当前剩余问题

### 2.1 同一个 runId 遇到已有 reviewOutcome 时会直接短路返回

当前 `ExecuteReferenceExtractionFromSourceDocumentUseCase` 中：

1. 只要 `resumableRun && existingRun.reviewOutcome != null`
2. 就会直接 return 旧的 `ReferenceExtractionRunResult`

这意味着：

1. 如果上一次是 `continuation_recommended`
2. 或者是 `coverage_insufficient`
3. 这一次再用同一个 `runId` 调用
4. 也不会进入新的 proposal generation / continuation 批次
5. 而是直接把旧结果再返回一次

于是现在系统的状态是：

1. **它会诚实地告诉你“不完整”。**
2. **但它还不会顺着这个不完整状态继续推进下一轮提取。**

这和我们前几轮一直追求的目标还有一层距离：

```text
诚实识别不完整
不等于
真正具备可续跑、可续提、可恢复的运行语义
```

### 2.2 当前“resume”只覆盖中断恢复，还没有覆盖“合同要求续提”

现有 resume 测试证明的是：

1. batch 执行中途 technical failure 之后
2. 可以从 staging 继续没跑完的 batch

这很好，但它不是同一种问题。

我们现在缺的是另一类续跑：

1. 运行本身没有技术失败；
2. review 明确给出 `continuation_recommended`；
3. 系统应允许下一轮继续补提；
4. 而不是把当前 reviewOutcome 当成终态卡死。

所以当前 resume 语义还只完成了一半：

1. **technical resume**：已有
2. **semantic continuation**：还没有正式建成

---

## 三、这轮必须保留的已有成果

以下内容不得回退：

1. 非 completed 结果继续保持 `staging_only`，不能回退成 publishable。
2. export / attach / project 对 incomplete result 的阻断继续保留。
3. 空 coverage proposal 的拒绝继续保留。
4. `OutputBudgetPolicy / OutputCoverageContract / OmissionReport / ContinuationRequest / OutputCompressionRisk` 继续作为共享合同层存在。
5. `ReferenceSourceDocumentExtractionService` 仍只是 seed/bootstrap。
6. 默认单并发 reference_extraction 纪律继续保留。

---

## 四、直接可用的目标提示

把下面整段作为目标模式提示使用：

```text
请继续收口当前仓库中的 reference_extraction 输出预算与完整性交付链。这一轮不是重做已完成的 delivery gating，而是补上最后一个关键缺口：让 continuation_recommended / coverage_insufficient 结果真正具备“可续提”的重入语义，而不是只停留在 staging 里。

请先阅读：

- docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md
- docs/important/output-budget-and-completeness-contract-goal-prompt-2026-06-08.md
- docs/important/output-budget-completeness-acceptance-followup-goal-2026-06-08.md
- docs/important/reference-extraction-continuation-reentry-goal-2026-06-08.md

本轮必须先承认并保留以下事实：

1. 非 completed 结果现在已经正确停留在 staging_only，不再 publish/export/project；这一点不要回退。
2. 空 coverage proposal 已被结构性拒绝；这一点不要回退。
3. 现有 technical resume（批次中断后续跑）已经存在；本轮要补的是 semantic continuation，不是重复做 technical resume。
4. ReferenceSourceDocumentExtractionService 仍然只是 seed/bootstrap，不是完整语义提取器。
5. 不允许把任何测试题材、作品名、哈利波特等写死进 core。
6. 不允许通过新增一个大而重的万能 runtime service 来糊住问题。

本轮核心目标：

第一类：让 incomplete result 真正可续提
1. 当前 execute use case 在 `resumableRun && existingRun.reviewOutcome != null` 时会直接返回旧结果；你需要把这里演化为更自然的续提判定。
2. 至少要区分：
   - publishable completed result：可直接返回；
   - technical interruption unfinished run：继续未完成 batch；
   - semantic incomplete result（continuation_recommended / coverage_insufficient）：允许进入新的 continuation 轮次，而不是直接返回旧结果。
3. 新的 continuation 轮次不应粗暴清空旧状态，也不应简单重复前一轮全部工作。你需要给出合理的 continuation 语义，例如：
   - 复用既有 staging state / accepted proposals / omission reports / continuation requests；
   - 基于 continuation request 生成下一轮 focus；
   - 或通过新的 batch / slot / focus contract 进入补提阶段；
   - 但无论如何，必须是真正能“向前推进”的，而不是只读回旧结果。

第二类：明确 continuation 的状态模型
1. 不要把 continuation 只做成一个布尔补丁。
2. 最好让 core 明确表达：
   - completed publishable
   - incomplete awaiting continuation
   - continuation in progress
   - technical failure resumable
   - exhausted / manual attention（如果你认为需要）
3. 这些状态不一定都要 fully UI 化，但至少要在 core/adapters 运行链里可表达、可测试、可持久化。

第三类：补 focused tests，覆盖这轮真正缺的场景
1. 增加 test，证明第一次运行得到 continuation_recommended 后，再用同一个 runId 重入时，不会直接短路返回旧结果，而会进入 continuation 路径。
2. 增加 test，证明 continuation 路径能够在不回退 publish/export gating 的前提下，推进 staging state 或提案状态。
3. 增加 test，证明 completed publishable run 仍然可以像现在一样安全短路返回，不被新的 continuation 逻辑破坏。
4. 如果你引入新的 continuation phase / status / metadata，也要补持久化与读取测试。

第四类：保持实现优雅
1. 不要把 continuation 逻辑同时分散到 use case、runtime service、staging workspace、proposal generator 四处各写一份。
2. 优先在 core 中抽一个自然的小合同或判定服务，让“是否可直接返回 / 是否需要 semantic continuation / 是否继续 technical resume”有统一口径。
3. continuation focus 可以来自 continuation request / omission report / coverage ledger，但不要把 prompt 文案硬编码成题材特例。
4. 不要顺手扩大成“重做整个 reference_extraction 系统”。

本轮最低验收标准：

1. 之前的 focused tests 继续通过。
2. 新增 focused tests 证明 semantic continuation 不再被 `existingRun.reviewOutcome != null` 这条短路卡死。
3. publishable completed 结果仍保持当前的 delivery gating 语义。
4. 分层清晰，没有新堆出职责怪物文件。
```

---

## 五、建议重点检查的代码位置

优先看这些位置：

1. `packages/novel_agent_core/lib/src/use_cases/execute_reference_extraction_from_source_document_use_case.dart`
2. `packages/novel_agent_core/lib/src/reference_extraction/reference_extraction_run_models.dart`
3. `packages/novel_agent_core/lib/src/reference_extraction/reference_extraction_review_models.dart`
4. `packages/novel_agent_adapters/lib/src/reference_extraction/file_reference_extraction_staging_workspace.dart`
5. `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart`

---

## 六、这轮不算完成的假信号

以下都不算完成：

1. 只是保留 staging，但同一个 runId 仍直接返回旧 reviewOutcome。
2. 只是新增 `canContinue=true` 之类字段，但没有真正进入新的 continuation 路径。
3. 只是让 UI 显示“可续提”，但 core 运行链仍不会推进。
4. 只是强行改成每次都新开 runId，丢掉之前 staging state。
5. 只是用 prompt 多写几句“请继续补充”，但没有正式 continuation 状态语义与 focused tests。

---

## 七、一句话结论

```text
当前实现已经把“不完整结果不再伪装成普通成功”这一步做成了，但还没有把“不完整结果如何自然地继续下一轮提取”这一步做完；下一轮目标应专注于补 semantic continuation 的重入语义。
```
