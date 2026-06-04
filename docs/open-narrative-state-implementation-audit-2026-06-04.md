# Open Narrative State 实现审计与 Legacy 降级图

最后更新：2026-06-04

关联文档：

- `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- `agent.md`

---

## 1. 审计目标

本文件只做 `ONS-01` 的现状审计，不推进 core 实现，不重命名文件，不改运行链。

本轮结论服务于后续 `ONS-02+`：

1. 明确哪些已有文件可以直接复用。
2. 明确哪些文件只能扩展，不能继续吸收新职责。
3. 明确哪些旧方向只能作为 legacy bridge。
4. 明确后续每一阶段应该碰哪些核心文件。
5. 明确当前绝对不该碰的边界，避免 UI、CLI、probe 反向兜底架构缺口。

---

## 2. 标记规则

- `keep`
  - 方向正确，后续继续作为底座复用。
- `extend`
  - 方向正确但信息不完整，后续应围绕它补合同或桥接层。
- `migrate`
  - 保留现状兼容，但后续主语义要迁移到新的开放叙事状态合同。
- `freeze`
  - 暂停扩张，不再继续往里堆新业务判断或新题材分支。
- `deprecate`
  - 明确降级为兼容、归档或历史输入，不再作为正式主线。

---

## 3. 现状总判断

当前仓库已经具备四类可复用底座：

1. `continuity` 的 scope / frame / profile / bundle 表达。
2. `workflow` 的章节原子执行、长任务控制面、gate / review / recovery 基础。
3. `runtime` 的运行实例、心跳、状态机、工具执行入口。
4. `deconstruction` 的拆书抽取、承接计划、continuity hints。

当前最明显的结构风险也有四个：

1. 章节交付仍主要依赖 `write_project_file` 组合，缺少领域级 delivery 合同。
2. tool evidence 还没有沉成独立的开放合同层，更多分散在执行链和测试里。
3. `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart` 体量已到 `2130` 行，后续只能薄接线，不能继续变成业务中心。
4. “特殊机制”主线虽然当前源文件中没有继续扩张成显式目录，但文档、探针语境和现有命名仍可能把后续实现拉回题材化分支，必须提前冻结。

---

## 4. 分域审计清单

### 4.1 Continuity 底座

#### `keep`

- `packages/novel_agent_core/lib/src/continuity/continuation_scope.dart`
- `packages/novel_agent_core/lib/src/continuity/continuation_scope_overlay.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_frame.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_mechanic_profile.dart`
- `packages/novel_agent_core/lib/src/continuity/project_continuity_bundle.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_runtime_resolver_service.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_asset_reference.dart`
- `packages/novel_agent_core/lib/src/continuity/active_scope_chain.dart`
- `packages/novel_agent_core/lib/src/continuity/active_continuity_frame.dart`

判断：

1. 这批文件已经把“作用域 / frame / profile / bundle / resolver”的中性骨架立起来了。
2. 后续 ONS 主线应在这些概念之上新增 `claim / profile proposal / ledger / context activation`，而不是另起题材化平行体系。

#### `extend`

- `packages/novel_agent_core/lib/src/continuity/project_continuity_input_profile.dart`
- `packages/novel_agent_core/lib/src/continuity/general_project_continuity_defaults_service.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_resolution_result.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_coverage.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_build_spec.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_catalog_service.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_flow.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_foundation_build_stage.dart`

判断：

1. 这批文件更偏 continuity 初始化、默认值和构建过程。
2. 后续可作为 profile proposal、foundation ingest、deconstruction 输入桥的承接点。
3. 不应把开放 claim / review / ledger 直接塞回这些构建文件。

#### `freeze`

- `packages/novel_agent_core/lib/src/continuity/continuity_mechanic_profile.dart`

补充约束：

1. 文件本身继续保留，但“mechanic”只能理解为 continuity 画像，不得重新长成“特殊题材类型表”。
2. 后续不得在此文件内加入快穿、死亡回归、多世界等 core 枚举判断。

### 4.2 章节交付与写作执行链

#### `keep`

- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_constants.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_event_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_execution_builder_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_intent_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_output_path_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_prompt_builder_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_result_recorder_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_step_state_service.dart`
- `packages/novel_agent_core/lib/src/use_cases/prepare_chapter_atomic_execution_use_case.dart`

判断：

1. 章节原子执行链已经把“准备执行、生成 prompt、确定输出路径、记录结果”拆开了。
2. 这条链是后续接入 `submit_chapter_delivery` 的自然入口。

#### `extend`

- `packages/novel_agent_core/lib/src/workflow/chapter_length_profile.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_length_profile_resolver_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_length_distribution_policy.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_length_distribution_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_length_measurement_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_length_evaluation.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_chapter_length_evaluation_service.dart`

判断：

1. 字数链已成形，但还没有接上未来的 `ConstraintBinding` 事实层。
2. 后续应做 binding bridge，不应继续把约束散落到宿主级 prompt 分支。

#### `migrate`

- `packages/novel_agent_core/lib/src/workflow/long_task_transaction_contract_service.dart`
- `packages/novel_agent_core/lib/src/tools/builtin_tool_catalog.dart`
- `packages/novel_agent_core/lib/src/tools/tool_schema_builder_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_file_write_tool_executor.dart`

判断：

1. 当前正式“写出章节”的领域动作仍被低层 `write_project_file` 主导。
2. 这条链必须保留兼容，但后续章节交付主语义要迁移到 `submit_chapter_delivery`。
3. `write_project_file` 未来应回到“底层文件工具”定位，不再永久承担章节完成语义。

#### `freeze`

- `packages/novel_agent_core/test/draft_generation_tool_call_reliability_test.dart`

判断：

1. 这份测试当前非常重要，锁定了“只写 sidecar 不等于交付章节”“双写入方案脆弱”的已知问题。
2. 它应作为 ONS 主线迁移前的回归锚点保留，直到新的领域 delivery 合同稳定接管。

### 4.3 Supervisor 与长任务控制面

#### `keep`

- `packages/novel_agent_core/lib/src/runtime/run_instance.dart`
- `packages/novel_agent_core/lib/src/runtime/run_instance_factory_service.dart`
- `packages/novel_agent_core/lib/src/runtime/long_task_run_status.dart`
- `packages/novel_agent_core/lib/src/runtime/long_task_run_state_machine.dart`
- `packages/novel_agent_core/lib/src/runtime/long_task_run_registry.dart`
- `packages/novel_agent_core/lib/src/runtime/long_task_heartbeat_policy.dart`
- `packages/novel_agent_core/lib/src/runtime/default_long_task_heartbeat_policy.dart`
- `packages/novel_agent_adapters/lib/src/runtime/long_task_supervisor.dart`
- `packages/novel_agent_adapters/lib/src/runtime/long_task_heartbeat_scheduler.dart`
- `packages/novel_agent_adapters/lib/src/runtime/long_task_heartbeat_event.dart`
- `packages/novel_agent_adapters/lib/src/runtime/local_long_task_run_registry.dart`
- `packages/novel_agent_adapters/lib/src/runtime/run_instance_document_codec_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_run_center_markdown_renderer.dart`

判断：

1. 运行实例、状态机、心跳、持久化 registry、Run Center 合同方向正确。
2. 这套控制面是后续 supervisor 风险策略消费 delivery / review / permission 结果的正式落点。

#### `extend`

- `packages/novel_agent_core/lib/src/workflow/long_task_failure_action_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_recovery_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_chapter_gate_policy_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_chapter_gate_disposition_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_checkpoint_review_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_checkpoint_review_task_suggestion_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_checkpoint_action_contract_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_chapter_gate_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_checkpoint_review_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_checkpoint_review_task_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_checkpoint_action_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_review_repair_task_service.dart`

判断：

1. 这批文件已经在做 gate / review / recovery / action 的职责拆分。
2. 后续应让它们消费新的 delivery outcome、semantic review finding 和 permission state，而不是继续围绕正文猜测。

#### `freeze`

- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`

判断：

1. 当前文件 `2130` 行，已经远超项目约束中的职责阈值。
2. 后续只能抽小服务、做薄接线、削减职责，不允许再把 profile、claim、risk policy、context activation 算法塞进去。

### 4.4 Tool Evidence 与工具回合状态

#### `keep`

- `packages/novel_agent_core/lib/src/agents/agent_tool_round_state_service.dart`
- `packages/novel_agent_core/lib/src/runtime/tool_execution_service.dart`
- `packages/novel_agent_core/lib/src/runtime/tool_execution_round_result.dart`

判断：

1. 当前已经有“本轮调用了哪些工具、是否有计划工具、执行结果如何”的最小骨架。
2. 这说明 ONS-03 不需要从零发明 tool evidence 入口，可以在现有执行链上抽出更稳定的引用与证据合同。

#### `extend`

- `packages/novel_agent_core/lib/src/agents/agent_loop_contract_service.dart`
- `packages/novel_agent_core/lib/src/agents/agent_tool_policy_service.dart`
- `packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart`

判断：

1. 当前工具轮语义还分散在执行用例、策略服务和测试里。
2. 后续需要把 narrative evidence、source、tool round ref、write intent 从“散落的运行时上下文”迁成正式领域小模型。

#### `migrate`

- `packages/novel_agent_core/test/draft_generation_tool_call_reliability_test.dart`
- `packages/novel_agent_core/test/draft_generation_use_case_test.dart`

判断：

1. 当前测试已经清楚证明低层工具流的已知盲区。
2. 后续新增 `NarrativeRef / NarrativeEvidenceRef / NarrativeSourceRef` 后，应把这些失效模式映射到新合同，而不是继续只盯 `write_project_file` 调用形状。

### 4.5 Review、Gate 与结构化审稿基础

#### `keep`

- `packages/novel_agent_core/lib/src/review/review_report_normalizer_service.dart`
- `packages/novel_agent_core/lib/src/review/review_report_summary_service.dart`
- `packages/novel_agent_core/lib/src/review/review_report_markdown_renderer.dart`
- `packages/novel_agent_core/lib/src/review/review_report_chapter_analysis_projection_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_review_report_service.dart`

判断：

1. 结构化 review report 已经存在，这对后续 `submit_semantic_review` 很重要。
2. 这条线应被提升为开放语义复核合同，而不是长期停留在“后处理报告”层。

#### `extend`

- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_postprocess_result_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_long_task_revision_resolution_service.dart`

判断：

1. 当前 review 后的 repair / resolution 已有适配层入口。
2. 后续要改的是输入事实源和风险策略，不是推翻这层接线。

### 4.6 Deconstruction 与续写承接链

#### `keep`

- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_input.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_source_document.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_source_range_hint.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_scope_hint.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_scope_map.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_continuity_hints.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_extraction_result.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_asset_mapping_service.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_application_plan.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_application_plan_builder_service.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_derived_project_plan.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_derived_project_plan_builder_service.dart`

判断：

1. 拆书输入、抽取、映射、派生计划链已经具备复用价值。
2. 后续不需要为 ONS 重新造一条拆书 runtime，只需要给它增加同源的 claims / proposal / review 输出桥。

#### `extend`

- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_mechanic_hint.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_identity_mapping_hint.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_continuation_direction.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_coverage_hint.dart`

判断：

1. 这些 hint 适合作为未来 `analysis namespace` 或 foundation ingest 的输入。
2. 后续应把它们映射到开放 namespace，而不是在 core 中解释成固定题材类型。

### 4.7 `special_mechanic_*` 现状与降级结论

#### `freeze`

- 当前源代码树中，未检索到活跃的 `special_mechanic_*` / `special_mechanics_*` / `project_special_mechanic_*` 文件。

判断：

1. 这不代表风险已经消失，只代表“特殊机制主线”当前没有以独立源文件继续扩张。
2. 相关设计压力已经转移到：
   - 文档中的历史讨论。
   - continuity / mechanic 命名残留。
   - 真实探针和历史脚本语境。

#### `deprecate`

- 任何未来若从历史分支、备份或旧会话中恢复出的：
  - `special_mechanic_*`
  - `special_mechanics_*`
  - `project_special_mechanic_*`
  - `mechanic_runtime_*` 中带题材硬编码判断的变体

统一结论：

1. 只能作为 legacy bridge、迁移输入、压力探针标签或历史兼容层。
2. 不允许继续作为 production 主线扩展。
3. 不允许再新增以 `special_mechanic` 为中心命名的新 core / workflow / supervisor 分支。

---

## 5. 后续阶段应碰的核心文件

### 5.1 Core domain 与合同阶段

优先触达：

- `packages/novel_agent_core/lib/src/continuity/`
- `packages/novel_agent_core/lib/src/runtime/`
- `packages/novel_agent_core/lib/src/tools/`
- `packages/novel_agent_core/lib/src/workflow/`
- `packages/novel_agent_core/test/`

重点策略：

1. 在 continuity 下建立开放叙事状态命名空间。
2. 在 runtime / tools 间补齐 narrative refs、evidence refs、domain tool schema。
3. 优先增加小合同、小测试，不把业务算法倒灌到大文件。

### 5.2 Adapters 持久化与投影阶段

优先触达：

- `packages/novel_agent_adapters/lib/src/storage/`
- `packages/novel_agent_adapters/lib/src/tools/`
- `packages/novel_agent_adapters/lib/src/workflow/`

重点策略：

1. 新事实源落 `.novel_agent/continuity/`、`.novel_agent/constraints/`、`.novel_agent/reviews/`。
2. Markdown 只做投影，不做唯一事实源。
3. adapter 只承接写入、读取、投影，不承担题材解释和风险策略。

### 5.3 Runtime 薄接线阶段

优先触达：

- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- 与之配套的新小型 bridge/service 文件

重点策略：

1. 先抽小服务，再接新合同。
2. 所有新增语义都优先落到小服务，避免主 runtime 文件继续膨胀。

### 5.4 Supervisor 风险策略阶段

优先触达：

- `packages/novel_agent_core/lib/src/runtime/`
- `packages/novel_agent_core/lib/src/workflow/long_task_*`
- `packages/novel_agent_adapters/lib/src/runtime/`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_supervisor_adapter.dart` 或等价后续文件

重点策略：

1. supervisor 只消费结构化 delivery / review / permission / ledger 结果。
2. 不读正文，不判题材，不做文学裁判。

### 5.5 Probe、GUI、CLI 收口阶段

优先触达：

- `apps/novel_agent_app/tool/`
- `apps/novel_agent_app/lib/features/task_center/`
- `apps/novel_agent_app/lib/features/book_deconstruction/`
- `apps/novel_agent_cli/`

重点策略：

1. 只能消费已经稳定的 production 合同。
2. 不允许反向补底层规则。

---

## 6. 当前明确禁止碰的边界

1. 不在 `app` 或 `cli` 中直接发明 narrative claim / profile / review 规则。
2. 不在 `adapters` 中引入“特殊题材判断器”。
3. 不在 `ProjectWorkflowRuntimeService` 中继续堆 profile、claim、permission、risk policy 算法。
4. 不新增以 `special_mechanic` 为中心命名的新文件。
5. 不把 `write_project_file` 包装成更多宿主私有特判，拖延领域工具落地。
6. 不把 Markdown 投影直接当运行时真相。
7. 不让 probe 脚本先行定义 production 语义。
8. 不从 `local/`、归档目录或历史 probe 里恢复一次性脚本作为正式实现入口。

---

## 7. ONS 主线的可执行结论

1. `ONS-02` 应直接建立中性的 core 命名空间，不需要再做一次“是否值得立项”的讨论。
2. `ONS-03` 到 `ONS-09` 可以建立在现有 continuity、tool execution、review、workflow 骨架之上，不需要推翻底座。
3. 章节交付的第一优先风险不是“题材表达不够强”，而是 `write_project_file` 仍承担领域语义，必须后续迁出。
4. supervisor 主线可以继续，但后续只应消费结构化结果，不能向正文语义回流。
5. deconstruction 应视为同源事实输入桥，而不是单独 runtime。
6. `special_mechanic` 已经不应再作为正式扩展方向；如果历史实现重新出现，统一按 `freeze/deprecate` 处理。

---

## 8. 本轮审计完成定义

本文件完成后，`ONS-01` 视为完成，当且仅当满足：

1. continuity、chapter delivery、supervisor、tool evidence、special_mechanic、deconstruction 六类对象都被点名审计。
2. 已明确 `keep / extend / migrate / freeze / deprecate`。
3. 已明确 `special_mechanic_*` 只允许作为 legacy bridge。
4. 已明确后续阶段该碰哪些文件、当前哪些边界禁止碰。
5. 本轮没有写 core 代码，没有顺手开启 `ONS-02`。
