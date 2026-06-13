# NovelAgentFlutter 全模块审计台账

最后更新：2026-06-09

关联主线：

- `docs/full-module-sweep-collaboration-session-order-2026-06-09.md`
- `docs/important/full-module-sweep-collaboration-chunking-analysis-2026-06-09.md`
- `agent.md`

---

## 1. 本台账的职责

这份台账是 `FMSC` 主线的唯一正式模块审计入口。

它解决三件事：

1. 把当前项目稳定能力块先台账化，而不是继续按文件名或临时报错找活。
2. 把“哪个块还没收口、收口证据是什么、下一步该从哪里进”固定成可接力格式。
3. 防止后续会话各自新写一份审计说明，最后又把同一逻辑审出两套口径。

本台账当前只完成 `FMSC-01` 范围：

1. 固定字段。
2. 固定填写标准。
3. 列出稳定能力块清单。

本台账当前刻意不做：

1. 不冻结各块主实现出口。
2. 不冻结各块事实源。
3. 不替 `FMSC-02` 预写重复实现风险台账。
4. 不替 `FMSC-03` 提前做块边界裁决。

---

## 2. 维护纪律

后续所有 `FMSC` 会话都必须继续使用本文件，不另开第二份模块总台账。

维护规则如下：

1. 同一稳定能力块只保留一行正式台账记录。
2. `FMSC-01` 只允许填骨架字段、块清单、现有依据和待补入口，不提前替后续 session 下结论。
3. `FMSC-02` 只新增风险台账并回链到本文件，不在这里复制一份风险明细表。
4. `FMSC-03` 才正式补齐 `主实现出口 / 事实源 / 验证入口 / 主要消费者`。
5. `FMSC-04` 之后每次只更新当前负责块对应行，以及必要的共享合同依赖说明。
6. 若问题跨块，先在 `共享合同依赖` 字段登记，再串行落地，不允许在多个块各补一份近似逻辑。
7. `viewmodel / probe / fallback / compat / widget helper / tool script` 只能记为消费者、验证器或兼容层，不能在台账里登记成主出口。

---

## 3. 固定字段与填写标准

| 字段 | 含义 | `FMSC-01` 填写要求 | 后续维护阶段 |
| --- | --- | --- | --- |
| `block_id` | 稳定能力块编号 | 必填，保持稳定不改名 | 全程稳定 |
| `block_name` | 块名称 | 必填，使用能力语义命名 | 全程稳定 |
| `responsibility` | 该块负责什么 | 必填，写单一能力闭环 | 全程维护 |
| `layer_span` | 覆盖哪些层 | 必填，如 `core / adapters / app / cli / probe` | 全程维护 |
| `key_code_anchors` | 首轮代码锚点 | 必填，列目录或关键入口文件 | 可增补 |
| `existing_basis` | 已有基础或历史主线依据 | 必填，写已存在主线/文档/实现 | 可增补 |
| `audit_status` | 当前审计状态 | `listed` 起步 | 按 session 更新 |
| `completion_basis` | 为什么判断为当前状态 | 必填，写“看过哪些入口/文档/现状” | 按 session 更新 |
| `open_gaps` | 尚未闭环的缺口 | 必填，先写高层缺口，不写补丁方案 | 按 session 更新 |
| `issue_types` | 缺口类型 | 必填，使用下面固定枚举 | 按 session 更新 |
| `shared_contract_dependency` | 跨块共享缺口 | `none` 或待抽合同说明 | 按 session 更新 |
| `duplicate_impl_risk_note` | 与双实现风险相关的简述 | 只写高层提醒，不展开风险台账 | `FMSC-02` 后回链风险台账 |
| `primary_outlet` | 正式主实现出口 | `待 FMSC-03 冻结` | `FMSC-03` 补齐 |
| `truth_source` | 事实源 | `待 FMSC-03 冻结` | `FMSC-03` 补齐 |
| `main_consumers` | 主要消费者 | `待 FMSC-03 冻结` | `FMSC-03` 补齐 |
| `validation_entrypoints` | focused validation / integration / probe 入口 | `待 FMSC-03 冻结` | `FMSC-03` 补齐 |
| `owner_session` | 当前主负责 session | `未分配` 或当前 session 编号 | 按 session 更新 |
| `handoff_ready` | 是否已达到可安全接力 | `no` / `partial` / `yes` | 按 session 更新 |
| `next_entry` | 下一步应从哪里进 | 必填，写精确入口 | 按 session 更新 |

### 3.1 `audit_status` 固定枚举

- `listed`
- `auditing`
- `bounded`
- `in_progress`
- `partially_closed`
- `closed`
- `blocked`

### 3.2 `issue_types` 固定枚举

- `missing_path`
- `incomplete_contract_consumption`
- `shadow_logic`
- `state_truth_blur`
- `recovery_gap`
- `ux_surface_mismatch`
- `test_coverage_gap`
- `ownership_blur`

### 3.3 `handoff_ready` 判定标准

- `no`：块边界和缺口仍模糊，后续会话容易顺手补第二套实现。
- `partial`：块边界已基本可说清，但主出口、真相源或验证入口仍有待冻结。
- `yes`：主出口、事实源、验证入口、当前残留和下一步入口都已明确，后续可以安全接力。

---

## 4. 更新方式

后续每个 `FMSC` session 都按下面顺序更新：

1. 只定位当前负责块。
2. 更新该块的 `audit_status / completion_basis / open_gaps / issue_types / shared_contract_dependency / owner_session / next_entry`。
3. 如已进入 `FMSC-03` 或之后，再更新 `primary_outlet / truth_source / main_consumers / validation_entrypoints`。
4. 如果消除了双实现风险，只在本行简述并回链 `FMSC-02` 风险台账，不在本文件复制整张风险表。
5. 追加一条会话更新记录，说明本轮收口块、主出口位置和删除/降级了什么双实现风险。

---

## 5. 首轮稳定能力块清单

以下清单是 `FMSC-01` 的正式起始块集合。

它们代表当前项目已经形成、且适合作为协作治理单位的稳定能力块，而不是简单按目录分拆的文件集合。

| block_id | block_name | responsibility | layer_span | key_code_anchors | existing_basis | audit_status | completion_basis | open_gaps | issue_types | shared_contract_dependency | duplicate_impl_risk_note | primary_outlet | truth_source | main_consumers | validation_entrypoints | owner_session | handoff_ready | next_entry |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `FMSC-B01` | 控制面块 | 连续任务控制面、watchdog、supervisor、pause/resume/recover、stop diagnosis 共享语义 | `core / adapters / app / cli` | `packages/novel_agent_core/lib/src/workflow/`; `packages/novel_agent_adapters/lib/src/runtime/`; `packages/novel_agent_adapters/lib/src/workflow/` | `CTRS`; `LTSR`; 现有 `continuous_task_*` 与 `long_task_*` 骨架 | `partially_closed` | `FMSC-04` 已把 `continuous_task lifecycle -> stop_outcome / recovery_state` 的 technical-failure recovery shell 收口到 core 共享合同：`ContinuousTaskLifecycleStopOutcomeResolverService` 与 `ContinuousTaskRecoveryStateFactoryService`；`LongTaskSupervisor`、`ContinuousTaskSupervisorBridgeService`、`ReferenceExtractionContinuousTaskSyncService` 已改为同源消费，并以 focused tests 覆盖 resolver/factory、bridge、supervisor、reference runtime | 主链 technical-failure recovery shell 已收口；剩余 `stop_diagnosis` 的 GUI / CLI / probe 消费侧 shadow logic 继续留待 `FMSC-12`、`FMSC-14`、`FMSC-15` 串行清理 | `shadow_logic`; `test_coverage_gap` | 已抽出共享合同 `continuous_task_lifecycle_stop_outcome_resolver / continuous_task_recovery_state_factory`；后续控制面入口不得再手写 technical-failure 的 `stop_outcome / recovery_state` 壳层 | 见 `FMSC-R01`、`FMSC-R10` | `packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart` | `RunInstance.stop_outcome + recovery_state + 项目内 long_task run record`；`stop diagnosis` 由 `LongTaskStopDiagnosisProjectionService` 投影 | `LongTaskWatchdog`；`LongTaskSupervisor`；`ProjectLongTaskStationDetailService`；`ProjectLongTaskSummaryViewDataService`；`WorkflowOutputSummaryService`；`probe_support.dart` | `packages/novel_agent_core/test/long_task_stop_diagnosis_projection_service_test.dart`；`packages/novel_agent_core/test/continuous_task_lifecycle_stop_outcome_resolver_service_test.dart`；`packages/novel_agent_core/test/continuous_task_recovery_state_factory_service_test.dart`；`packages/novel_agent_adapters/test/continuous_task_supervisor_bridge_service_test.dart`；`packages/novel_agent_adapters/test/long_task_supervisor_test.dart`；`packages/novel_agent_adapters/test/project_reference_extraction_runtime_service_test.dart`；`packages/novel_agent_adapters/test/continuous_task_control_plane_regression_suite_test.dart`；`apps/novel_agent_app/test/project_long_task_summary_view_data_service_test.dart`；`apps/novel_agent_cli/test/workflow_output_summary_service_test.dart` | `FMSC-04` | `yes` | 控制面主链已删除一类 duplicate recovery shell；后续只在 `FMSC-12 / FMSC-14 / FMSC-15` 继续清理 GUI / CLI / probe 对 `stop_diagnosis` 的影子解释 |
| `FMSC-B02` | 写作执行块 | 普通写作、长任务写作、章节交付、执行约束桥与共享交付链 | `core / adapters / app / cli` | `packages/novel_agent_core/lib/src/workflow/`; `packages/novel_agent_core/lib/src/creative/`; `packages/novel_agent_adapters/lib/src/workflow/` | `LTSR`; 表达限制与交付链相关历史主线 | `partially_closed` | `FMSC-05` 已从 `ProjectWorkflowRuntimeService` 主链抽出 adapter 共享合同 `packages/novel_agent_adapters/lib/src/workflow/project_writing_execution_contract_service.dart`，并让 `ProjectWorkflowRuntimeService`、`ProjectConversationDraftRuntimeService` 统一经该服务消费 `chapter_delivery -> ChapterDeliveryStateResult`、`execution_constraints -> WritingExecutionConstraintBridgeResult`、`activation_report -> ContextActivationReport` 与 `expression_constraint_projection` 派生装配；focused validation 已覆盖 `project_writing_execution_contract_service_test.dart`、`project_conversation_draft_runtime_service_test.dart`、`project_workflow_runtime_service_test.dart` | 普通任务与普通会话写作在 `writing_execution_result` 前置装配已收口；剩余 review / postprocess 邻接链路的共享执行语义收紧留待 `FMSC-06` 继续串行清理 | `shadow_logic`; `ownership_blur` | 需先守住 `writing_execution_result / chapter_delivery contract / activation report / repair handoff` 共享合同 | 见 `FMSC-R04`、`FMSC-R06`、`FMSC-R10` | `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart` | `WritingExecutionResult + chapter_delivery_* + execution record`；主持久化由 `ProjectTaskRepository` 承接 | `ProjectWorkflowRuntimeBridgeService`；`ProjectConversationDraftRuntimeService`；`ProjectDraftExecutionConstraintRuntimeService`；`ProjectWorkflowReviewRuntimeService`；CLI/GUI 摘要消费者 | `packages/novel_agent_adapters/test/project_writing_execution_contract_service_test.dart`；`packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`；`packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart`；`packages/novel_agent_adapters/test/project_workflow_runtime_bridge_service_test.dart` | `FMSC-05` | `yes` | `FMSC-06`：继续从 `ProjectWorkflowReviewRuntimeService` 与相邻 review / postprocess 消费链收紧剩余共享执行语义 |
| `FMSC-B03` | 审稿与修复块 | review、repair、disposition、delivery gating、checkpoint follow-up | `core / adapters / app / cli / probe` | `packages/novel_agent_core/lib/src/review/`; `packages/novel_agent_adapters/lib/src/workflow/`; `apps/novel_agent_app/lib/features/review_center/` | `LTSR`; 表达限制审稿分析文档 | `partially_closed` | `FMSC-06` 已把普通 semantic review 落盘出来的 report / repair task 链收回到同一条 shared repair contract：`ProjectWorkflowReviewRuntimeService` 现在会把 `review_contract / review_summary / review_repair_handoff` 一并持久化进 review JSON；`ProjectReviewReportService` 与 `ProjectLongTaskReviewRepairTaskService` 则优先消费这组共享工件，由新 adapter 合同 `packages/novel_agent_adapters/lib/src/workflow/project_review_repair_task_contract_service.dart` 统一把 `ReviewRepairHandoffService` 产出的 repair 语义物化为 workflow revision 任务。focused validation 已覆盖 `project_review_repair_task_contract_service_test.dart`、`project_workflow_review_runtime_service_test.dart`、`project_long_task_review_repair_task_service_test.dart`、`project_workflow_runtime_service_test.dart` | 普通 semantic review 的 report -> repair task 平行语义已收口；剩余 review / repair 对 GUI / CLI consumer 的解释层收紧留待后续消费者 session 继续串行清理 | `ux_surface_mismatch`; `test_coverage_gap` | 需先守住 `review_contract / review_artifact / repair_lane / checkpoint_action_package` 共享合同 | 见 `FMSC-R04`、`FMSC-R07`、`FMSC-R08` | `packages/novel_agent_core/lib/src/review/review_repair_handoff_service.dart` | `ReviewContract / ReviewArtifact / RepairRequest / RepairTask / RepairOutcome` shared contracts；workflow 持久化记录只消费这些合同 | `ProjectWorkflowReviewRuntimeService`；`ProjectReviewReportService`；`ProjectLongTaskReviewRepairTaskService`；`ProjectLongTaskStationDetailService`；`review_center`；`task_center`；`workflow_command.dart` | `packages/novel_agent_adapters/test/project_review_repair_task_contract_service_test.dart`；`packages/novel_agent_adapters/test/project_workflow_review_runtime_service_test.dart`；`packages/novel_agent_adapters/test/project_long_task_review_repair_task_service_test.dart`；`packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`；`packages/novel_agent_core/test/review_contract_models_test.dart`；`packages/novel_agent_core/test/repair_lane_contracts_test.dart` | `FMSC-06` | `yes` | `FMSC-07`：继续保持 `ReviewRepairHandoffService` 为唯一主出口，后续再按消费者 session 清理 GUI / CLI 的影子解释 |
| `FMSC-B04` | 连续性与状态块 | continuity、narrative claims、ledger、canon decision、state truth 与 projection 边界 | `core / adapters / storage / app` | `packages/novel_agent_core/lib/src/continuity/`; `packages/novel_agent_core/lib/src/information/`; `packages/novel_agent_adapters/lib/src/storage/` | continuity 与 reference continuity 历史主线 | `partially_closed` | `FMSC-07` 已把 `ProjectContextActivationService` 中最直接的一类 state truth blur 收口：新增 adapter 共享合同 `packages/novel_agent_adapters/lib/src/workflow/project_narrative_claim_activation_contract_service.dart`，让 narrative claim 激活候选优先消费 `NarrativeStateLedgerService` 对应的 ledger-backed entry truth；`accepted/questioned` 继续作为正式 continuity truth，`proposed/observed` 降级为待裁决 submission，`rejected/superseded` 不再进入 activation 候选。focused validation 已覆盖 `project_context_activation_service_test.dart` 与 `project_workflow_runtime_bridge_service_test.dart` | `ProjectContextActivationService` 已不再把 raw claim log 混读成正式 truth；剩余 continuity readable projection 与 GUI / assets consumer 的影子解释留待 `FMSC-13` 串行清理 | `shadow_logic`; `ownership_blur` | 已抽出共享合同 `project_narrative_claim_activation_contract_service`，后续 continuity 消费层不得再自行把 `claims.jsonl` 当作正式状态真相口 | 见 `FMSC-R05` | `packages/novel_agent_core/lib/src/continuity/narrative_state/narrative_state_ledger_service.dart` | `NarrativeStateClaim + ledger entries + conflict cluster + canon decision + review alert`；其中 narrative claim 的正式激活真相以 ledger entry disposition 为准，持久化由 continuity records 与 reference continuity ledger 承接 | `ContinuityRuntimeResolverService`；`ProjectContextActivationService`；`ProjectReferenceContinuityBridgeService`；`OpenNarrativeStateProjectionWriterService`；`workbench/project_assets` | `packages/novel_agent_core/test/narrative_state_ledger_service_test.dart`；`packages/novel_agent_core/test/narrative_state_claim_contracts_test.dart`；`packages/novel_agent_core/test/narrative_semantic_review_contracts_test.dart`；`packages/novel_agent_adapters/test/project_context_activation_service_test.dart`；`packages/novel_agent_adapters/test/project_workflow_runtime_bridge_service_test.dart`；`packages/novel_agent_adapters/test/open_narrative_state_projection_writer_service_test.dart` | `FMSC-07` | `yes` | `FMSC-13`：继续沿 `NarrativeStateLedgerService` 主出口清理 readable projection、workspace 与 project assets 对 continuity 状态的影子解释 |
| `FMSC-B05` | 参考提取块 | reference extraction runtime、mount、batch/coverage、source identity、substrate 链 | `core / adapters / storage / app / cli / probe` | `packages/novel_agent_core/lib/src/reference_extraction/`; `packages/novel_agent_core/lib/src/reference_substrate/`; `packages/novel_agent_adapters/lib/src/reference_extraction/`; `packages/novel_agent_adapters/lib/src/storage/` | `CTRS`; 参考提取 runtime sweep 与 substrate 主线 | `partially_closed` | `FMSC-08` 已把 runtime / mount / projection 之间最直接的一类挂载结果语义分叉收口为 adapter 共享合同：新增 `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_mount_outcome.dart` 与 `project_reference_mount_outcome_resolver_service.dart`，由 `ProjectReferenceExtractionRuntimeService` 只负责判断 `published snapshot` 是否可用，`ProjectReferenceExtractionMountService` 统一返回正式 `ProjectReferenceMountOutcome`，`ReferenceExtractionSupervisorSignalService` 也改为消费同一套 `projectMountStatus` 语义。focused validation 已覆盖 `project_reference_extraction_mount_service_test.dart`、`project_reference_extraction_runtime_service_test.dart`、`reference_extraction_supervisor_signal_service_test.dart` 与 `reference_substrate_chain_test.dart` | 参考提取主链的 attach/project 结果口径已收口；剩余 markdown/json projection consumer、workspace 信息消费与 probe 同源化仍留待 `FMSC-09`、`FMSC-13`、`FMSC-15` 串行清理 | `shadow_logic` | 需继续守住 `source_asset_identity / batch coverage / projection access policy / supervisor signal / project_reference_mount_outcome` 共享合同；后续消费者不得再私有重建 mount status | 见 `FMSC-R02`、`FMSC-R09` | `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart` | `SqliteReferenceEvidenceSubstrate + ProjectReferenceAttachmentLayer + batch execution state`；挂载与投影只消费这条 substrate 主链 | `ProjectReferenceExtractionMountService`；`ProjectReferenceProjectionService`；`ReferenceExtractionContinuousTaskSyncService`；`ProjectInformationActivationBridgeService`；`WorkflowOutputSummaryService`；real probes | `packages/novel_agent_adapters/test/project_reference_extraction_runtime_service_test.dart`；`packages/novel_agent_adapters/test/reference_substrate_chain_test.dart`；`packages/novel_agent_adapters/test/reference_extraction_supervisor_signal_service_test.dart`；`apps/novel_agent_app/tool/reference_extraction_runtime_real_probe.dart` | `FMSC-08` | `yes` | `FMSC-09 / FMSC-15`：后续只允许沿已冻结的 `ProjectReferenceMountOutcome` 与 sqlite-first substrate 真相继续清理信息 consumer 与 probe，不得重建第二套 mount/projection 解释 |
| `FMSC-B06` | 信息基底与激活块 | knowledge/design/research/reference work、activation bridge、projection 与上下文激活消费 | `core / adapters / storage / app / cli` | `packages/novel_agent_core/lib/src/information/`; `packages/novel_agent_adapters/lib/src/workflow/`; `packages/novel_agent_adapters/lib/src/storage/`; `apps/novel_agent_app/lib/features/workbench/` | `CTRS`; project information substrate 历史主线 | `partially_closed` | `FMSC-09` 已先把信息块主链内一类 locator 双口径收口为 core 共享合同：新增 `packages/novel_agent_core/lib/src/information/information_source_of_truth_locator_service.dart`，让 `InformationMarkdownProjectionService` 与 `ProjectInformationPathService` 同源生成 `project-information://...` 真相 locator；`ProjectInformationActivationBridgeService` 与 `ProjectContextActivationService` 继续只消费这条 sqlite-first locator 链。focused validation 已覆盖 `information_source_of_truth_locator_service_test.dart`、`information_markdown_projection_services_test.dart`、`project_information_activation_bridge_service_test.dart`、`project_information_projection_writer_service_test.dart` 与 `project_context_activation_service_test.dart` | 信息块主链的 locator 口径已收口；剩余 workspace/CLI consumer 仍在各自解析 projection/activation report 的轻投影摘要，留待 `FMSC-11`、`FMSC-13`、`FMSC-14` 串行清理 | `ux_surface_mismatch` | 需继续守住 `project-information:// locator / source_of_truth_locator / evidence_refs / activation selection / information_source_of_truth_locator_service` 共享合同；后续消费者不得再私造 locator 或把 projection frontmatter 当主真相生成器 | 见 `FMSC-R02`、`FMSC-R03`、`FMSC-R05` | `packages/novel_agent_adapters/lib/src/workflow/project_information_activation_bridge_service.dart` | `SqliteProjectInformationRecordStore + SqliteKnowledgeCardRepository / SqliteDesignElementRepository / SqliteResearchNoteRepository / SqliteReferenceWorkRepository` | `ProjectContextActivationService`；`ProjectWorkflowRuntimeBridgeService`；`ProjectWorkflowRuntimeService`；`WorkspaceInformationProjectionService`；`WorkflowOutputSummaryService` | `packages/novel_agent_adapters/test/project_information_activation_bridge_service_test.dart`；`packages/novel_agent_adapters/test/project_information_projection_writer_service_test.dart`；`packages/novel_agent_adapters/test/project_context_activation_service_test.dart`；`packages/novel_agent_core/test/information_markdown_projection_services_test.dart`；`apps/novel_agent_app/test/workspace_information_projection_service_test.dart` | `FMSC-09` | `yes` | `FMSC-11 / FMSC-13 / FMSC-14`：后续只允许沿已冻结的 `project-information://` locator 合同清理 GUI / workspace / CLI consumer，不得重新从 markdown 或宿主层拼一套信息真相路径 |
| `FMSC-B07` | 智能体生态块 | agent、agent group、skill、loadout、tool exposure policy、默认级与项目级配置消费 | `core / adapters / app / cli` | `packages/novel_agent_core/lib/src/agents/`; `packages/novel_agent_core/lib/src/tools/`; `packages/novel_agent_adapters/lib/src/packages/`; `apps/novel_agent_app/lib/features/settings/` | `CTRS-07`; agent/package/settings 现有骨架 | `partially_closed` | `FMSC-10` 已把默认候选工具集合的解释链收口回 `ContinuousTaskToolExposureRuntimeResolverService`：runtime resolver 现在会基于 `ContinuousTaskProfile + runtimeContext + ToolStrategyService.defaultSettings()` 统一生成 `default candidate tool ids`，`ProjectWorkflowRuntimeBridgeService` 与 `SubAgentEffectiveExecutionProfileService` 都改为在未显式声明 `allowed_tool_ids` 时只消费这条主链，不再各自私写一份 task-type / child fallback 规则。`FMSC-16` 的真实普通项目 probe 又回补了一处 earlier-session 残留：普通写作入口先前只暴露 `default_allowed_tool_ids`，把 `requires_confirmation` 的 research 工具整个藏掉，导致受限权限场景连正式 `request_external_research` 出口都看不见；现已把“默认开放”与“可见但需确认”正式拆成同一条共享合同 `visible_tool_ids`，并让 `ProjectWorkflowRuntimeBridgeService`、`ProjectConversationDraftRuntimeService`、`GenerateDraftUseCase` 与 `SubAgentEffectiveExecutionProfileService` 同源消费，focused validation 已覆盖 `continuous_task_tool_exposure_runtime_resolver_service_test.dart`、`sub_agent_effective_execution_profile_service_test.dart`、`sub_agent_execution_service_test.dart`、`project_workflow_runtime_bridge_service_test.dart` 与 `project_conversation_draft_runtime_service_test.dart`，真实入口验证已覆盖 `apps/novel_agent_app/tool/real_information_evidence_ordinary_probe.dart` | 默认候选工具集合与“可见但需确认”的 research 工具出口都已回收到同一 runtime tool exposure 主链；剩余 settings/UI 对 loadout、binding、group selection 的消费边界与可视化清理留待后续外层消费者 session 串行处理 | `ownership_blur`; `test_coverage_gap` | 需继续守住 `runtime tool exposure resolution / visible_tool_ids / group capability scope / resolved loadout / tool strategy defaults` 共享合同；后续 settings 或 bootstrap 不得再补第二套默认候选工具推导，也不得重新把 `requires_confirmation` 工具藏回普通入口之外 | 见 `FMSC-R06` | `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart` | `ContinuousTaskProfile + ContinuousTaskToolExposureProfile + agent-group capability scope + resolved loadout/binding documents` | `ProjectWorkflowRuntimeBridgeService`；`ProjectConversationDraftRuntimeService`；`GenerateDraftUseCase`；`SubAgentEffectiveExecutionProfileService`；`project_agent_group_binding` 持久化链；`settings` 消费层 | `packages/novel_agent_core/test/continuous_task_tool_exposure_runtime_resolver_service_test.dart`；`packages/novel_agent_core/test/sub_agent_effective_execution_profile_service_test.dart`；`packages/novel_agent_core/test/sub_agent_execution_service_test.dart`；`packages/novel_agent_adapters/test/project_workflow_runtime_bridge_service_test.dart`；`packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart`；`apps/novel_agent_app/tool/real_information_evidence_ordinary_probe.dart` | `FMSC-10` | `yes` | 后续会话只允许沿 `ContinuousTaskToolExposureRuntimeResolverService` 主出口继续清理 settings / loadout / binding 消费边界，不得重新在 workflow bridge、sub-agent、ordinary conversation 或 settings fallback 中拼默认候选工具集合，亦不得把需确认 research 工具从正式入口移除 |
| `FMSC-B08` | 宿主壳与工作台 GUI 消费块 | workbench、long task station、task center、project assets 等 GUI 主链消费 | `app` | `apps/novel_agent_app/lib/features/workbench/`; `apps/novel_agent_app/lib/features/long_task_station/`; `apps/novel_agent_app/lib/features/task_center/`; `apps/novel_agent_app/lib/features/project_assets/` | `LTSR-23`; `LTSR-24`; `CTRS-21` | `partially_closed` | `FMSC-11` 已先从 workbench 信息区删除一类 GUI shadow logic：`WorkspaceInformationProjectionService` 不再消费宿主再包装的 `selected_context_sections / omitted_context_sections`，而是直接读取正式 `ContextActivationReport.items` 来生成“本轮已使用 / 未使用”的资料摘要；`FMSC-12` 继续从 long task station 删除一类 control-plane shadow logic：`LongTaskStationViewDataService` 与 `LongTaskRunDetailPanel` 不再把 legacy `run.stopReason` 再翻译成 GUI 私有 `补充原因`，而是只消费正式 `stopDiagnosis / blocker` 投影；`FMSC-13` 再从 project assets 删除一类 shared identity shadow logic：`ProjectAssetsController` 不再私拆 `referenceKey` 的 `kind:id` 规则，而是统一通过 `SharedNarrativeAssetReferenceIndex.referenceByKey(...)` 消费正式 reference identity 合同。focused validation 已覆盖 `workspace_information_projection_service_test.dart`、`resource_manager_panel_test.dart`、`workbench_project_panel_test.dart`、`workbench_workspace_controller_snapshot_test.dart`、`long_task_station_view_data_service_test.dart`、`long_task_run_detail_panel_test.dart`、`project_assets_controller_expression_constraint_context_test.dart` 与 `shared_narrative_asset_reference_index_service_test.dart` | workbench 信息区、long task station 与 project assets graph/reference 导航的三类 GUI shadow logic 已收口；剩余 task center 的 GUI 解释层继续保留为后续 consumer maintenance 观察项 | `ux_surface_mismatch`; `shadow_logic` | GUI 只允许消费 `stop_diagnosis / run_center_contract / shared action package / source identity / project-information locator / context_activation_report`，不得自建业务真相 | 见 `FMSC-R01`、`FMSC-R02`、`FMSC-R03`、`FMSC-R07` | `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart` | `RunInstance + ProjectLongTaskStationDetail + WorkbenchInformationViewData + workspace entries`；GUI 本身无独立事实源 | `workbench` 页面与侧栏；`long_task_station`；`task_center`；`project_assets`；相关 widgets/view-data services | `apps/novel_agent_app/test/project_long_task_summary_view_data_service_test.dart`；`apps/novel_agent_app/test/workspace_information_projection_service_test.dart`；`apps/novel_agent_app/test/resource_manager_panel_test.dart`；`apps/novel_agent_app/test/workbench_project_panel_test.dart`；`apps/novel_agent_app/test/workbench_workspace_controller_snapshot_test.dart`；`apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`；`apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`；`apps/novel_agent_app/test/project_assets_controller_expression_constraint_context_test.dart`；`packages/novel_agent_core/test/shared_narrative_asset_reference_index_service_test.dart`；`apps/novel_agent_app/test/task_center_diagnostics_panel_test.dart` | `FMSC-13` | `yes` | `FMSC-14` 起不再允许 GUI 侧继续私拆 shared reference identity；后续只保留 task center 等剩余 consumer 的边界加固 |
| `FMSC-B09` | CLI 与自动化消费块 | CLI workflow/project/review 命令与 automation/tool 最小稳定消费 | `cli / app tool / adapters` | `apps/novel_agent_cli/lib/commands/`; `apps/novel_agent_app/tool/`; `packages/novel_agent_adapters/lib/src/workflow/` | `LTSR-25`; `CTRS-22`; 现有工具脚本规则 | `partially_closed` | `FMSC-14` 已先收口 CLI workflow 摘要层里一类 control-plane shadow logic：`WorkflowOutputSummaryService.extractNarrativeRuntimeContract(...)` 不再默认用 `stop_outcome / recovery_state / stop_reason` 在 CLI 侧重建一份 `stop_diagnosis`，而是优先直接消费正式 `run_center_contract.stop_diagnosis`；只有共享合同缺位时才走兼容兜底。focused validation 已覆盖 `workflow_output_summary_service_test.dart`、`workflow_command_test.dart` 与 `workflow_output_summary_probe.dart` | workflow 命令的一类 stop diagnosis 二次投影已收口；剩余 CLI / automation 对 shared action package、reference extraction summary 与其余 workflow consumer 的边界清理留待后续继续串行检查 | `shadow_logic`; `ux_surface_mismatch`; `ownership_blur` | CLI/自动化只允许消费 `run_center_contract / narrative runtime contract / pending action package / reference extraction summary`，不得自建 workflow 真相 | 见 `FMSC-R01`、`FMSC-R08` | `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart` | `run_center_contract + narrative runtime contract + reference extraction result + pending action package`；CLI 无独立事实源 | `workflow` 命令；`apps/novel_agent_cli/tool/*` probes；自动化调用者 | `apps/novel_agent_cli/test/workflow_command_test.dart`；`apps/novel_agent_cli/test/workflow_output_summary_service_test.dart`；`apps/novel_agent_cli/tool/workflow_output_summary_probe.dart` | `FMSC-14` | `yes` | 后续会话只允许沿 `run_center_contract / narrative runtime contract` 主出口继续清理 CLI / automation consumer，不得在命令层重新长出第二份 stop diagnosis 或 workflow 摘要解释器 |
| `FMSC-B10` | Probe 与回归块 | focused tests、mock regression、real probe、production-same-source 验证纪律 | `test / tool / app / cli / adapters / core` | `apps/novel_agent_app/test/`; `apps/novel_agent_app/tool/`; `packages/novel_agent_core/test/`; `packages/novel_agent_adapters/test/` | `LTSR-19` 到 `LTSR-22`; `CTRS-17` 到 `CTRS-20`; `agent.md` probe 规则 | `partially_closed` | `FMSC-15` 已把 `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart` 里一组 mock regression stop 场景从 probe 侧直接 `LongTaskStopDiagnosisProjectionService.project(...)` 收回到正式 `LongTaskRunCenterContractService.runCenterContract(...).stop_diagnosis`；同时把 `long_task_proactive_review` 的验证切回生产同源的 `checkpoint_followup.review_task_ids + sourceTask.checkpoint_followup_task_ids` 合同，不再盯旧的磁盘依赖重写细节。focused validation 已覆盖 `apps/novel_agent_app/test/long_task_stability_mock_regression_suite_test.dart` 与 `apps/novel_agent_app/test/probe_support_test.dart` | mock regression suite 已删除一类 host-side `stop_diagnosis` shadow judgment；剩余 real probe 与其他 probe support 入口仍需继续按 production-same-source 纪律串行清理 | `shadow_logic`; `test_coverage_gap` | probe 块自身不拥有业务真相；mock/real probe 只能继续消费 `run_center_contract / stop_diagnosis / checkpoint_followup / activation_report / reference extraction runtime result / substrate snapshot`，不得在 probe 侧重建控制面或 follow-up 判断 | 见 `FMSC-R01`、`FMSC-R09` | `packages/novel_agent_adapters/test/continuous_task_control_plane_regression_suite_test.dart` | `production truth only`：`run_center_contract / stop_diagnosis / checkpoint_followup / activation_report / reference extraction runtime result / substrate snapshot`；probe 块本身无独立事实源 | `apps/novel_agent_app/tool/*` real probes；`apps/novel_agent_cli/tool/*` probes；focused tests 与 regression suites | `packages/novel_agent_adapters/test/continuous_task_control_plane_regression_suite_test.dart`；`packages/novel_agent_adapters/test/reference_substrate_chain_test.dart`；`apps/novel_agent_app/test/long_task_stability_mock_regression_suite_test.dart`；`apps/novel_agent_app/test/probe_support_test.dart`；`apps/novel_agent_app/tool/reference_extraction_runtime_real_probe.dart`；`apps/novel_agent_app/tool/real_reference_consumption_story_probe.dart`；`apps/novel_agent_cli/tool/workflow_resolution_cli_probe.dart` | `FMSC-15` | `yes` | `FMSC-16` 前不再为 probe 新增 host-side stop/follow-up 解释器；后续只允许回到剩余 real probe 入口继续按正式合同做小规模验证 |

---

## 6. FMSC-17 发布面残留优先级重排

本节只从“接近可发布的软件”视角重排残留，不新增设计，不改块边界，也不把 GUI / CLI / probe / fallback 升格成新的业务中心。

### 6.1 必须修

| priority | linked_blocks | main_outlet | residual | evidence |
| --- | --- | --- | --- | --- |
| `P0` | `FMSC-B01`; `FMSC-B02`; `FMSC-B03` | `packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`; `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`; `packages/novel_agent_core/lib/src/review/review_repair_handoff_service.dart` | 真实 provider 下的长任务正式交付、失败停点与后续推进仍未稳定锁成同一条主链真相；如果发布口径包含“稳定自主长任务写作”，这是当前首要阻断 | `docs/release-readiness-final-closeout-2026-06-05.md` 第 4 节；`docs/real-provider-regression-report-2026-06-05.md` 第 2~4 节；`apps/novel_agent_app/tool/real_long_task_probe.dart --stop-after-sample` 仅证明 sample checkpoint path 当前可过，不等于多章节真实稳定性已闭环 |
| `P0` | `FMSC-B08` | `apps/novel_agent_app/android/app/build.gradle.kts` | Android 分发面仍使用示例 `applicationId` 和 debug signing，不能作为正式对外分发构件 | `apps/novel_agent_app/android/app/build.gradle.kts` 中 `applicationId = "com.example.novel_agent_app"` 与 `release { signingConfig = signingConfigs.getByName("debug") }`；`docs/release-readiness-final-closeout-2026-06-05.md` 第 5 节 |

### 6.2 可延后

| linked_blocks | main_outlet | residual | why_deferable_now | evidence |
| --- | --- | --- | --- | --- |
| `FMSC-B09` | `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart` | CLI 仍有较多运维/迁移型命令，`session` 也明确仍在迁移期 | CLI 已被定性为共享 core/adapters 的运维/实验壳层，不是 GUI beta 主承诺；只要不把它包装成完整会话产品面，就不阻断当前发布面 | `docs/cli-release-boundary-2026-06-05.md`；`apps/novel_agent_cli/lib/commands/session/session_command.dart` |
| `FMSC-B08` | `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart` | task center 仍保留一整套操作员式消费面与动作入口，和“旧入口已折返长任务总站”的壳层边界并存 | 主导航已把旧任务中心入口统一折返到长任务总站；只要当前 beta 不把 task center 当正式主产品面，可先保留为次级/运维面，后续再继续清 consumer cleanup 与移除计划 | `apps/novel_agent_app/lib/app/state/app_shell_destination_controller.dart`；`apps/novel_agent_app/lib/app/state/app_shell_controller.dart`；`apps/novel_agent_app/lib/features/task_center/` |
| `FMSC-B10` | `packages/novel_agent_adapters/test/continuous_task_control_plane_regression_suite_test.dart` | remaining real/shared probe support 仍有继续同源化空间 | `FMSC-16` 已用最小真实入口确认当前 ordinary path 与 sample long-task path；剩余 probe 清理不会直接决定产品放行，只要不再让 probe 变第二解释器即可后移 | `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 中 `FMSC-15`、`FMSC-16` 完成记录 |

### 6.3 纯优化

| linked_blocks | main_outlet | residual | evidence |
| --- | --- | --- | --- |
| `FMSC-B08` | `apps/novel_agent_app/lib/` | Windows / Android 真机视觉、DPI 与长操作链人工回归继续增强 | `docs/gui-critical-path-test-matrix-2026-06-05.md`；`docs/release-readiness-final-closeout-2026-06-05.md` 第 5 节 |
| `FMSC-B08` | `apps/novel_agent_app/lib/` | 如未来系统字体回退不稳，再补正式 OSS 中文字体资产 | `docs/release-readiness-final-closeout-2026-06-05.md` 第 5 节 |
| `FMSC-B09` | `apps/novel_agent_cli/lib/commands/` | CLI help、运维文档与更多自动化覆盖继续打磨 | `docs/cli-release-boundary-2026-06-05.md` |

---

## 7. 会话更新记录

- `FMSC-01`：
  - 新建本台账，固定字段、枚举、更新纪律和首轮稳定能力块清单。
  - 本轮收口块：`Documentation / Audit`。
  - 本轮正式主实现出口：`docs/full-module-sweep-module-audit-ledger-2026-06-09.md`。
  - 本轮已消除的双实现风险：后续会话不再各写一份“自己的模块审计清单”，统一回到本台账续填。
- `FMSC-02`：
  - 已将各块 `duplicate_impl_risk_note` 统一回链到 `docs/full-module-sweep-duplicate-implementation-risk-ledger-2026-06-09.md`。
  - 本轮收口块：`Documentation / Audit`。
  - 本轮正式主实现出口：`docs/full-module-sweep-duplicate-implementation-risk-ledger-2026-06-09.md`。
  - 本轮已消除的双实现风险：后续会话不再各自新写一份“风险清单”，统一按 `risk_id` 更新同一张风险台账。
- `FMSC-03`：
  - 已为 `10` 个稳定能力块补齐 `primary_outlet / truth_source / main_consumers / validation_entrypoints`，并把 `audit_status` 统一推进到 `bounded`。
  - 本轮收口块：`Documentation / Core boundary audit`。
  - 本轮正式主实现出口：`docs/full-module-sweep-module-audit-ledger-2026-06-09.md`。
  - 本轮已消除的双实现风险：后续代码 session 不再把 `viewmodel / probe / fallback / summary service / projection writer` 误当主链，且各块已明确下一跳应改哪一个正式主出口。
- `FMSC-04`：
  - 本轮收口块：`FMSC-B01 控制面块`。
  - 本轮正式主实现出口：`packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`；本轮新增并冻结的共享合同出口：`packages/novel_agent_core/lib/src/workflow/continuous_task_lifecycle_stop_outcome_resolver_service.dart` 与 `packages/novel_agent_core/lib/src/workflow/continuous_task_recovery_state_factory_service.dart`。
  - 已删除的残留问题：`ContinuousTaskSupervisorBridgeService` 与 `ReferenceExtractionContinuousTaskSyncService` 不再各自手写 technical-failure 的 `LongTaskRecoveryState + LongTaskStopOutcome` 壳层；`LongTaskSupervisor` 也不再自带一份私有 lifecycle->stop-outcome 映射，从而把 control-plane technical-failure recovery truth 收口为单一共享合同。
  - 本轮已消除的双实现风险：移除了 control-plane main chain 里一类“同一 lifecycle truth 在 supervisor/bridge/sync 各补一份 recovery shell”的多实现苗头，并补上 focused validation，确保 `stop_outcome` metadata 不再在 recovery 路径中丢失。
- `FMSC-07`：
  - 本轮收口块：`FMSC-B04 连续性与状态块`。
  - 本轮正式主实现出口：`packages/novel_agent_core/lib/src/continuity/narrative_state/narrative_state_ledger_service.dart`；本轮新增并冻结的 adapter 共享合同出口：`packages/novel_agent_adapters/lib/src/workflow/project_narrative_claim_activation_contract_service.dart`。
  - 已删除的残留问题：`ProjectContextActivationService` 不再直接把 `claims.jsonl` 的 raw narrative claim 当正式 continuity truth 来激活，而是统一改为优先消费 ledger-backed claim entry；`accepted/questioned` 继续进入正式状态上下文，`proposed/observed` 只保留为待裁决 submission，`rejected/superseded` 退出 activation 候选。
  - 本轮已消除的双实现风险：移除了 activation 主链里一类“raw claim log 与 ledger disposition 并行充当 state truth”的混读风险，并通过 focused validation 固定 `ledger truth > submission log` 的边界，后续 continuity readable projection 与 GUI / assets 只能继续按后续消费者 session 串行清理。
- `FMSC-08`：
  - 本轮收口块：`FMSC-B05 参考提取块`。
  - 本轮正式主实现出口：`packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart`；本轮新增并冻结的共享合同出口：`packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_mount_outcome.dart` 与 `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_mount_outcome_resolver_service.dart`。
  - 已删除的残留问题：`ProjectReferenceExtractionMountService` 先前用 `ReferenceProjectionResult? / null` 隐式表达 attach-only、projection applied 与未投影等结果，而 `ProjectReferenceExtractionRuntimeService` 又私有补了一份挂载状态解释去重新推导同一语义；现已统一改为由共享合同产出正式 `ProjectReferenceMountOutcome`，runtime 只判断 `published snapshot` 是否可用，mount/supervisor/测试同源消费同一 `projectMountStatus`。
  - 本轮已消除的双实现风险：移除了 runtime / mount / projection 链里一类“同一挂载结果语义在两处各补一版解释”的分叉风险，并通过 focused validation 固定 `published snapshot availability -> shared mount outcome -> supervisor signal` 的单一路径。
- `FMSC-09`：
  - 本轮收口块：`FMSC-B06 信息基底与激活块`。
  - 本轮正式主实现出口：`packages/novel_agent_adapters/lib/src/workflow/project_information_activation_bridge_service.dart`；本轮新增并冻结的 core 共享合同出口：`packages/novel_agent_core/lib/src/information/information_source_of_truth_locator_service.dart`。
  - 已删除的残留问题：信息块里原本由 `InformationMarkdownProjectionService` 与 `ProjectInformationPathService` 各自私写一套 `project-information://...` locator 口径；现已统一改为通过同一条 core locator 合同生成 collection / entry truth locator，让 markdown projection、activation bridge 与上下文激活回指只消费同一套 sqlite-first 信息真相标识。
  - 本轮已消除的双实现风险：移除了信息主链里一类“projection 侧和 activation 侧各自拼一版 source-of-truth locator”的分叉风险，并通过 focused validation 固定 `sqlite information truth -> shared locator contract -> activation/projection metadata` 的单一路径。
- `FMSC-10`：
  - 本轮收口块：`FMSC-B07 智能体生态块`。
  - 本轮正式主实现出口：`packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`。
  - 已删除的残留问题：`ProjectWorkflowRuntimeBridgeService` 原先私有维护一份基于 `task_type + ToolStrategyService.defaultSettings()` 的 workflow 默认候选工具排序，而 `SubAgentEffectiveExecutionProfileService` 在 child package / agent 未声明 `allowed_tool_ids` 时又私有回退到另一份 `defaultSettings()` 结果；现已统一改为由 `ContinuousTaskToolExposureRuntimeResolverService` 在同一条 runtime tool exposure 主链里生成 `default candidate tool ids`，workflow bridge 与 sub-agent 两条消费链都只传上下文，不再各自补 fallback。
  - 本轮已消除的双实现风险：移除了智能体生态块里一类“默认级、项目级与运行时各自长一版默认候选工具集合”的配置分叉风险，并通过 focused validation 固定 `runtime context + task profile + group capability scope + tool strategy defaults -> shared default candidate tool ids -> exposure policy filtering` 的单一路径。
- `FMSC-11`：
  - 本轮收口块：`FMSC-B08 宿主壳与工作台 GUI 消费块`。
  - 本轮正式主实现出口：`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`；本轮直接收紧的 GUI 消费服务：`apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart`。
  - 已删除的残留问题：workbench 信息区先前通过 `WorkspaceInformationProjectionService` 直接读取 `activation_report.json` 里宿主再包装的 `selected_context_sections / omitted_context_sections`，在 GUI 侧私有维护一份“本轮已使用 / 未使用哪些资料”的轻量解释器；现已统一改为直接消费正式 `ContextActivationReport.items` 合同，让 workbench 只读取主链 activation truth，而不再依赖额外的 GUI projection metadata。
  - 本轮已消除的双实现风险：移除了 GUI 消费块里一类“同一 activation truth 既在主链 report.items 里存在、又在宿主 metadata 里再投影一份给 workbench 解析”的 shadow projection 风险，并通过 focused validation 固定 `context_activation_report.items -> WorkspaceInformationProjectionService -> ResourceManagerPanel / WorkbenchProjectPanel` 的单一路径。
- `FMSC-15`：
  - 本轮收口块：`FMSC-B10 Probe 与回归块`。
  - 本轮正式主实现出口：`packages/novel_agent_adapters/test/continuous_task_control_plane_regression_suite_test.dart`；本轮直接收紧的 probe/regression 入口：`apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`。
  - 已删除的残留问题：`long_task_stability_mock_regression_suite_support.dart` 先前在 `delivery_failure / repair_required / waiting_user / manual_attention / natural_completion` 五个 mock 场景里直接 new `LongTaskStopDiagnosisProjectionService()`，让 probe 自己再长出一条 stop 诊断解释链；现已统一改为先构造正式 `run_center_contract`，再只消费其中的 `stop_diagnosis`。同时把 `long_task_proactive_review` 的 probe 判定从旧的 `downstreamTask.depends_on` 细节检查切回生产同源的 `checkpoint_followup.review_task_ids + sourceTask.checkpoint_followup_task_ids` 合同。
  - 本轮已消除的双实现风险：移除了 probe/regression 块里一类“mock suite 为了分类报告顺手再投影一份 stop diagnosis”的 shadow interpreter，并通过 focused validation 固定 `run_center_contract.stop_diagnosis -> mock regression report` 与 `checkpoint_followup contract -> proactive review gate assertion` 的单一路径。
- `FMSC-16`：
  - 本轮收口块：`Integration / Probe`；真实失败最终归因并回补到 earlier owning block：`FMSC-B07 智能体生态块`。
  - 本轮正式主实现出口：`packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`；本轮直接扩展的共享合同出口：`packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolution.dart` 中的 `visible_tool_ids`。
  - 已删除的残留问题：真实普通项目 probe 首次运行时，受限权限 ordinary chapter 入口虽然按设计应通过 `request_external_research` 落成 pending confirmation，但实际只暴露了 `default_allowed_tool_ids`，把 `requires_confirmation` research 工具整个藏掉，导致模型退回 `present_user_options` 并生成 generic `ordinary_conversation_waiting_user_choice`；现已统一改为让 workflow bridge、ordinary conversation 与 draft use case 只消费同一条 `visible_tool_ids` 合同，research 工具保持“可见但需宿主确认”，重型提取工具仍继续 gated。
  - 本轮已消除的双实现风险：移除了 ordinary-project real probe 暴露出来的一类“tool exposure 主链只在 runtime resolution 里保留 requires-confirmation 语义、入口消费层却各自把它过滤掉”的分叉风险，并通过 focused validation 固定 `runtime tool exposure resolution -> workflow/ordinary/sub-agent visible tools` 的单一路径。真实入口验证结果为：`apps/novel_agent_app/tool/real_information_evidence_ordinary_probe.dart` 从 `FAIL` 转为 `PASS`，`apps/novel_agent_app/tool/real_long_task_probe.dart --stop-after-sample` 保持 `PASS`，从而确认 `FMSC-16` 没有通过 probe 侧补丁过关。
- `FMSC-17`：
  - 本轮收口块：`Productization / Audit`。
  - 本轮正式主实现出口：`docs/full-module-sweep-module-audit-ledger-2026-06-09.md` 与 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 中的发布面残留分级；本轮不新开代码主出口。
  - 已收口的残留问题：项目残留清单已从“研究 backlog”重排为“接近可发布的软件”视角。当前明确的 `必须修` 只保留两类：一是 `FMSC-B01 / B02 / B03` 交界上的真实 provider 长任务稳定性阻断，二是 `apps/novel_agent_app/android/app/build.gradle.kts` 仍使用示例 `applicationId` 与 debug signing 的正式分发缺口。
  - 本轮已消除的双实现风险：明确把 task center、CLI session 迁移壳、remaining probe cleanup 从“可能继续顺手扩成第二业务中心”的模糊状态，降级为仅在其仍被纳入正式产品承诺时才升级处理的 `可延后` 消费层残留；后续接手者不应再把这些外围面误判成当前最高优先级主修块。
- `FMSC-18`：
  - 本轮收口块：`Documentation / Handoff`。
  - 本轮正式主实现出口：`docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 中的总收口与接力提示；本轮不新增代码主出口。
  - 已收口的残留问题：`FMSC` 主线的完成记录、发布面分级、接力顺序和推荐后续提示词已经集中回到正式文档，后续会话不需要再依赖对话记忆判断“当前 sweep 做到哪一步、下一块该接哪里”。
  - 本轮已消除的双实现风险：后续接手者不再需要自己补写一份“FMSC 总结”或另开一份新的总任务顺序文档；`FMSC` 主线正式闭合后，任何继续推进都应直接回到现有块台账和已分级残留，而不是重新发明第二条 sweep 主线。
