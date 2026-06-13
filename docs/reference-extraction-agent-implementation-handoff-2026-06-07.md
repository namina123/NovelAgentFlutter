# Reference Extraction Agent Implementation Handoff

日期：2026-06-07

关联文档：

- `docs/important/reference-extraction-agent-goal-prompt-2026-06-07.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`

## 本轮已正式落地

### 1. `reference_extraction` 任务族合同

已在 `packages/novel_agent_core/lib/src/agents/agent_task_family.dart` 正式定义：

- `writing`
- `review`
- `research`
- `reference_extraction`
- `deconstruction`
- `explainer`

### 2. 项目默认组 + 任务族覆盖层

已在以下合同中补出任务族覆盖：

- `ProjectAgentGroupSelection.taskFamilyIds`
- `ProjectAgentGroupSelectionNormalizerService`
- `ProjectAgentGroupSelectionResolverService`
- `ProjectAgentGroupCandidateResolverService`

当前行为：

1. 项目默认组仍然保留为用户主心智。
2. 当传入 `taskFamilyId` 时，任务族专用 selection 会优先于普通 selection。
3. 没有任务族专用 selection 时，原有 writing/review 路径不受影响。

### 3. 参考资产提取组解析主链

已新增：

- `ReferenceExtractionTaskFamilySupportService`
- `ReferenceExtractionAgentGroupResolverService`

当前解析顺序：

1. 优先任务族专用 group override
2. 其次选择声明支持 `reference_extraction` 的可用 group
3. 若无提取组，回退到受控单智能体 extraction fallback

注意：

- fallback 仍使用 `reference_extraction.single_agent`
- fallback 仍使用 `reference_extraction.standard`
- 不会退回写作 prompt / 写作工具权限语义

### 4. staging / proposal / review / finalize 主链

已新增：

- `ReferenceExtractionProposal`
- `ReferenceExtractionReviewDecision`
- `ReferenceExtractionReviewOutcome`
- `ReferenceExtractionStagingRun`
- `ReferenceExtractionStagingWorkspace`
- `ReferenceExtractionReviewGateService`
- `ReferenceExtractionPackageMergeService`
- `ExecuteReferenceExtractionFromSourceDocumentUseCase`

当前确定性阶段为：

1. `seed_extraction`
2. `group_resolution`
3. `proposal_generation`
4. `review_gate`
5. `package_finalize`

这条链不依赖主 agent 自由 `call_sub_agent` 才能成立。

### 5. seed extraction 的正式定位已被保留

当前 `ReferenceSourceDocumentExtractionService` 继续只承担：

1. source bootstrap
2. evidence seeding
3. index scaffold

完整语义提取、审核和定稿已转入 `reference_extraction` 任务族 use case。

## 已有验证

### focused 新增验证

- `packages/novel_agent_core/test/reference_extraction_agent_group_resolver_service_test.dart`
  - 普通项目发起提取时，优先选提取组而不是写作组
  - 没有提取组时，回退到 extraction fallback，而不是 writing prompt

- `packages/novel_agent_core/test/execute_reference_extraction_from_source_document_use_case_test.dart`
  - 验证 `source document -> seed -> proposal -> review -> finalized snapshot`
  - 验证 proposal/staging 与 finalized snapshot 分离
  - 验证 deterministic phase order

### 回归验证

- `packages/novel_agent_core/test/project_agent_group_candidate_resolver_service_test.dart`
- `packages/novel_agent_core/test/reference_substrate_contracts_test.dart`
- `packages/novel_agent_adapters/test/project_agent_group_binding_repository_test.dart`

## 当前边界

本轮已经完成 core 主链与最小可验证实现，但仍保留这些后续扩展点：

1. `ReferenceExtractionStagingWorkspace` 目前是 port，生产级持久化 adapter 还可继续补。
2. `ReferenceExtractionProposalGenerator` 目前是 port，真实 agent/runtime 桥接还可继续接入。
3. GUI / CLI 工作台还没有做成完整提取中心，但底层合同已可供接线。

## 本轮结论

这次实现已经不再把 seed extraction 冒充为完整知识库提取，而是正式补出了 `reference_extraction` 任务族、组覆盖解析、staging/review/finalize 主链，以及最小可验证 substrate 定稿链。
