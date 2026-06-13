# 参考资产提取智能体组实现目标提示

适用时间：2026-06-07 之后  
用途：给其他会话窗口直接开启目标模式使用  
关联主文档：

- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`

---

## 1. 直接可用的目标提示

把下面整段作为目标模式提示使用：

```text
请以 `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md` 和 `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md` 为本轮最高优先级架构依据，在当前仓库中正式收口“参考资产提取任务族”的智能体组与执行主链。不要把现有程序化 seed extraction 继续包装成完整知识库提取；也不要另起一套和现有项目、多智能体、ReferenceEvidenceSubstrate 完全割裂的新系统。

你必须严格保留以下判断，不得回退：

1. 当前 `reference_source_document_extraction_service.dart` 的定位只是 source bootstrap / evidence seeding / index scaffold，不是完整语义提取。
2. 真正的参考资产提取必须由智能体主导语义提取与审核，程序负责导入、切片、索引、证据定位、任务调度、包体落库与投影。
3. 参考资产提取不是新的写作分支，而是新的任务族 `reference_extraction`；它必须拥有独立的优先智能体组选择策略。
4. 参考资产提取默认不得复用普通写作智能体组作为主执行组；写作组只能在缺省兜底或消费结果阶段参与。
5. 该能力既要能被普通项目调用，也要能被专门入口调用；底层执行链不得依赖某个专门项目类型才成立。
6. 无论任务是从普通项目里发起，还是未来从专门提取型入口或提取型项目里发起，主执行组都必须优先选提取型智能体组，而不是写作型智能体组。
7. 项目默认智能体组仍然是用户主心智；`reference_extraction` 应通过“任务族执行覆盖层”在运行时优先解析提取型智能体组，而不是回写或篡改项目默认写作组语义。
8. 这条能力不应主要依赖“主智能体自由决定何时调用子智能体”来成立，而应以确定性的 workflow 阶段编排为主、智能体承担阶段语义职责为辅。
9. 应用级 `ReferenceEvidenceSubstrate`、项目级 `ProjectReferenceAttachmentLayer`、项目级 `ProjectInformationCapabilityLayer` 的三层分工不能被打乱；提取任务应先产出参考资产包，再按需要投影到项目层。
10. 不允许把题材例子、同人名词、具体作品机制写死进 core。
11. 不允许把计划、智能体组选择、运行包构建、审核 gate、package merge、落库、投影继续堆进一个大文件或一个全能 service。

本轮必须真正完成以下结果，而不是只补文档或空接口：

1. 正式建立 `reference_extraction` 任务族所需的 core contracts。
2. 正式建立“项目默认智能体组 + 任务族覆盖智能体组”的解析与选择主链，至少覆盖 `reference_extraction`，并确保它不破坏现有 writing/review 路径。
3. 让参考资产提取运行时能够按任务族优先选择提取型智能体组、其次选择项目级 override、最后受控回退到单智能体提取兜底，而且不回写项目默认写作组语义。
4. 明确区分：
   - seed extraction
   - agent-driven extraction
   - staging / proposal workspace
   - review / acceptance
   - package finalize
5. 明确把候选提案与正式 substrate 入库分开；未通过审核的候选不直接污染正式 package snapshot。
6. 至少补一条从 source document -> seed evidence -> agent extraction proposal -> review gate -> finalized ReferenceEvidenceSubstrate package snapshot 的真实或 mock 主链验证。
7. 至少补一条“普通项目发起参考资产提取但仍走提取型智能体组”的验证。
8. 至少补一条“没有提取组时回退到单智能体提取模式，但不退回写作 prompt / 写作工具权限”的验证。
9. 至少补一条 focused/mocked 验证，证明这条链由确定性 workflow 阶段调度，而不是完全依赖主 agent 自由 call_sub_agent 才能成立。
10. 如需改 builtin group / agent contracts，只允许以通用职责位扩展，例如 extraction lead / evidence reader / structure analyst / style analyst / reviewer / curator，不允许硬编码具体题材或作品。
11. 即便实现“提取型项目”或“提取工作台”入口，也不得再写出一条独立于共享 reference_extraction 任务族之外的平行核心执行链。

实现风格要求：

1. 优先修合同和职责边界，不做补丁式堆叠。
2. 如果一个文件开始同时承担 planning、dispatch、review、merge、persistence、projection 中两种以上重职责，先停下来拆分，再继续实现。
3. 行数阈值只是报警器，不是设计目标；不要为了把文件压到某个数字以下而机械拆空壳文件，也不要因为暂时没超阈值就继续混职责。
4. 不要把这轮实现继续堆进 `SubAgentExecutionService`、`ProjectWorkflowRuntimeService`、`ReferenceSourceDocumentExtractionService` 或某个新的万能 runtime service。
5. 优先做成小而稳定的服务，例如：
   - task family group override resolver
   - reference extraction orchestration policy
   - reference extraction run package builder
   - reference extraction staging workspace service
   - reference extraction review gate
   - reference extraction package merge service
   - reference extraction result projector
6. 新增 adapters 只负责宿主桥接、持久化、运行记录，不承担新的领域规则中心。

完成标准必须是可验证的：

1. 文档口径已纠正：当前程序抽取被重新定性为 seed extraction，而不是完整知识库提取。
2. core 中存在 `reference_extraction` 任务族合同、组选择合同、review gate 合同和 package merge 合同。
3. 至少一条 mock 或 focused runtime 验证证明“提取任务优先选提取组而不是写作组”。
4. 至少一条 mock 或 focused runtime 验证证明“回退时仍是提取型约束，不是写作型约束”。
5. 至少一条验证证明 staging/proposal 与 finalized package snapshot 分离成立。
6. 至少一条 substrate 验证证明提取结果最终形成正式 package snapshot，而不是只停在项目知识卡或临时字符串。
7. 整体实现遵守分层，不新增明显职责混堆的大文件。

范围边界：

1. 本轮主目标是核心架构与最小可验证主链，不要求把 GUI/CLI 做成完整资产管理器。
2. 不要求一次性做完整提取 UI，但必须把后续 UI 接入所需的合同和运行投影打稳。
3. 不要用 probe 脚本替代正式业务结构；probe 只能作为验证，不是业务中心。
4. 如果局部做不完，可以留下清晰剩余边界，但前提是主链已成、职责已拆清、验证已成立。
```

---

## 2. 推荐的一句 objective

如果要压缩成目标工具的一句 objective，推荐：

```text
在当前仓库中依照 docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md 正式落地 reference_extraction 任务族：完成任务族智能体组覆盖解析、确定性 workflow 阶段调度、提取型 run package、staging/review/finalize 主链与最小 substrate 验证，确保参考资产提取默认使用提取型智能体组而不是写作组，且不通过新的全能大文件或补丁式 runtime 堆叠实现。
```

---

## 3. 不应被当作完成的假信号

以下情况都不应被视为完成：

1. 只是把当前程序抽取改了个名字，没有智能体提取主链。
2. 只是新增一个 `reference_extraction_group_id` 字段，没有任务族覆盖解析与验证。
3. 只是让写作组多看一点资料，然后继续充当主提取器。
4. 只是新增几个内置 agent json，没有实际接入任务选择与运行链。
5. 只是补 probe，没有 core/adapters 正式合同。
6. 只是把逻辑继续堆进已有大文件。
7. 只是为了“分文件”把一个巨型类切成多个 part 文件，但职责仍然混在一起。
8. 只是让主智能体更积极地 `call_sub_agent`，却没有正式 workflow phase、staging 和 review/finalize 分层。
