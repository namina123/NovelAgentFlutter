# Project Information Substrate 实现审计与落点图

最后更新：2026-06-05

关联文档：

- `docs/project-information-substrate-session-order-2026-06-05.md`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `docs/open-narrative-state-implementation-audit-2026-06-04.md`
- `agent.md`

---

## 1. 审计目标

本文件只完成 `PIS-01`：

1. 审计当前仓库里与“项目信息层”直接相关的实现。
2. 标记哪些继续复用，哪些只允许扩展，哪些要迁移语义，哪些必须冻结。
3. 明确后续信息层应落到 `core / adapters / app / cli / probe` 的哪里。
4. 明确 `knowledge/` 当前只是可读目录与兼容资源，不是正式事实源。
5. 明确 `ProjectWorkflowRuntimeService` 与 `ProjectContextActivationService` 后续不能继续吸收信息层算法。

本轮不做：

1. 不新增 `core information` 代码。
2. 不迁移旧文件。
3. 不运行真实 probe。
4. 不调整 GUI / CLI 行为。

---

## 2. 标记规则

- `keep`
  - 方向正确，后续继续作为正式底座复用。
- `extend`
  - 方向正确但信息不足，后续围绕它补合同、桥接或投影。
- `migrate`
  - 保留当前兼容语义，但后续主表达需要迁移到新的信息层合同。
- `freeze`
  - 暂停扩张，不再继续往里面塞新算法、新事实源职责或新题材特判。

---

## 3. 总判断

当前仓库已经具备四块可直接承接信息层的地基：

1. `ONS` 的开放叙事状态合同已经能表达 `claim / profile / review / constraint / activation`。
2. `assets/` 已有角色、世界、伏笔、关系、时间线、风格等稳定共享资产。
3. `request_gateway_tool` 与 `ProjectGatewayToolExecutor` 已经把联网/命令/媒体能力隔离在 adapters。
4. GUI / CLI / probe 最近几轮已经在消费稳定运行合同，而不是自己补生产逻辑。

当前最明显的缺口与风险也很明确：

1. `knowledge/` 目前只存在于目录兼容、prompt 提示、上下文候选和 checkpoint 建议里，还不是结构化事实源。
2. 拆书的 `mechanicHints`、`BookDeconstructionMechanicHint` 仍然带历史命名，短期能兼容，长期应迁移到中性 design / pattern 表达。
3. `ProjectWorkflowRuntimeService` 已达 `2617` 行，`ProjectContextActivationService` 已达 `595` 行；两者都不能继续吸收信息层算法。
4. `request_gateway_tool` 现在仍只是一次性执行器，不具备研究合同、来源提升、证据链接和权限审计。

结论：

```text
后续应该新增 Project Information Substrate，
而不是继续扩写 knowledge 目录、gateway 单次结果或 runtime 门面。
```

---

## 4. Core 审计

### 4.1 ONS narrative state 合同

#### `keep`

- `packages/novel_agent_core/lib/src/continuity/narrative_state/`
- 重点文件：
  - `narrative_state_claim.dart`
  - `narrative_profile.dart`
  - `narrative_semantic_review.dart`
  - `narrative_constraint_binding_proposal.dart`
  - `narrative_source_ref.dart`
  - `narrative_evidence_ref.dart`
  - `narrative_ref.dart`

判断：

1. 这套合同已经解决“开放事实、来源、证据、复核、约束”的骨架问题。
2. 信息层应复用它的 `source / evidence / ref / codec / validation` 思路，而不是另造一套封闭 facts 表。
3. 后续 `ProjectKnowledgeCard`、`DesignElementCard`、`ResearchNote`、`ReferenceWorkRecord` 应与这套合同并行协作，而不是把所有信息硬塞回 claim/profile。

### 4.2 共享资产层

#### `keep`

- `packages/novel_agent_core/lib/src/assets/world_rule_set.dart`
- `packages/novel_agent_core/lib/src/assets/character_profile.dart`
- `packages/novel_agent_core/lib/src/assets/organization_profile.dart`
- `packages/novel_agent_core/lib/src/assets/foreshadow_record.dart`
- `packages/novel_agent_core/lib/src/assets/relationship_record.dart`
- `packages/novel_agent_core/lib/src/assets/timeline_record.dart`
- `packages/novel_agent_core/lib/src/assets/style_profile.dart`
- `packages/novel_agent_core/lib/src/assets/shared_narrative_asset_reference.dart`

判断：

1. 这些类型已经承接“强结构写作资产”。
2. 信息层不应重做角色卡、世界规则卡、伏笔卡等已有资产。
3. 后续信息层应用于那些不适合硬塞进现有资产的开放知识、设计巧思、研究资料、来源边界。

#### `extend`

- `packages/novel_agent_core/lib/src/assets/shared_narrative_asset_reference.dart`
- `packages/novel_agent_core/lib/src/assets/shared_narrative_asset_reference_index.dart`

判断：

1. 后续信息层应能链接现有资产，但不该改写资产子域的主职责。
2. 信息层需要“指向资产”的引用能力，而不是把资产层改造成开放知识仓。

### 4.3 `knowledge/` 与工作区目录

#### `migrate`

- `packages/novel_agent_core/lib/src/project/project_workspace_catalog.dart`
- `packages/novel_agent_core/lib/src/runtime/project_context_file_selection_service.dart`
- `packages/novel_agent_core/lib/src/tools/tool_strategy_prompt_builder.dart`
- `packages/novel_agent_core/lib/src/session/session_goal_prompt_builder_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_transaction_context_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_checkpoint_review_task_suggestion_service.dart`

判断：

1. `project_workspace_catalog.dart` 把 `knowledge/` 放在 `legacyResourceCompatibilityDirs`，职责明确是“旧项目中的知识材料目录，兼容保留为可读资源”。
2. `project_context_file_selection_service.dart` 只把 `knowledge/` 作为优先级 `13` 的低优先级文本候选。
3. `tool_strategy_prompt_builder.dart` 仍把“知识库写入 knowledge/”作为 prompt 约定。
4. 长任务 checkpoint 相关服务目前也只把 `knowledge/` 当可读提示路径。

结论：

```text
knowledge/ 当前只是兼容资源目录、上下文候选和可读投影入口，
不是结构化事实源。
```

后续迁移方向：

1. 事实源迁到 `.novel_agent/information/*`。
2. `knowledge/*.md` 只保留为投影、摘要或用户素材入口。
3. prompt 不再把“写 knowledge/”等同于“信息正式入库”。

### 4.4 拆书 continuity hints 与 mechanic hints

#### `migrate`

- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_continuity_hints.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_mechanic_hint.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_narrative_bridge_service.dart`

判断：

1. `BookDeconstructionContinuityHints` 目前仍直接暴露 `mechanicHints`。
2. `BookDeconstructionMechanicHint` 仍依赖 `Continuity*Mode` 提示字段，更偏 continuity mechanic 解释，不够适合承接开放“巧思 / 结构设计 / 象征系统”。
3. `book_deconstruction_narrative_bridge_service.dart` 已经是未来桥接信息层的自然入口，但现在主落点仍是 continuity/analysis 语义。

后续方向：

1. 旧 `mechanic hint` 保留兼容读取。
2. 新信息层应新增中性 `DesignElementCard` / pattern hint 表达。
3. 拆书抽取出的“原作巧思、命名暗线、结构设计、象征系统”应迁入信息层，并保留 evidence/source。

---

## 5. Tools 与 Adapters 审计

### 5.1 领域工具骨架

#### `keep`

- `packages/novel_agent_core/lib/src/tools/domain/domain_tool_request.dart`
- `packages/novel_agent_core/lib/src/tools/domain/domain_tool_outcome.dart`
- `packages/novel_agent_core/lib/src/tools/domain/narrative_domain_tool_catalog.dart`
- `packages/novel_agent_core/lib/src/tools/domain/narrative_permission_policy_service.dart`

判断：

1. 信息层后续应直接沿用现有领域工具合同与 permission 决策骨架。
2. 不需要为了 knowledge/design/research/reference 另造第三套工具协议。

### 5.2 gateway 执行器

#### `extend`

- `packages/novel_agent_adapters/lib/src/tools/project_gateway_tool_executor.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_gateway_http_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_gateway_process_service.dart`

判断：

1. `ProjectGatewayToolExecutor` 已正确把 `fetch_url_content`、`search_internet`、`run_command`、`generate_image` 留在 adapters。
2. 当前返回仍以“一次性执行结果”为主，包含 `content`、`results`、`status_code` 等低层数据。
3. 这层应该继续做 host/gateway 能力，不应直接升级为研究事实源。

后续方向：

1. 新增 `ProjectResearchGatewayService`，消费 gateway 结果并生成 `ResearchNote draft`。
2. 研究合同、来源提炼、证据链接、权限审计在信息层桥接里做。
3. 不让 `request_gateway_tool` 直接等同于“信息入库”。

### 5.3 context activation adapter

#### `freeze`

- `packages/novel_agent_adapters/lib/src/workflow/project_context_activation_service.dart`

判断：

1. 当前服务已经同时负责项目文件、profiles、claims、constraints 的读取与激活报告拼装。
2. 文件体量已到 `595` 行，已经接近项目约束下的职责复核线。
3. 后续信息层不能继续把 knowledge/design/research/reference 的算法直接塞进这里。

允许的后续动作：

1. 保留它作为 adapter 入口。
2. 通过新的 `ProjectInformationActivationBridgeService` 薄接线。
3. 最终让它只聚合多个 bridge 产物，不自己判断信息排序、裁剪和证据策略。

### 5.4 workflow 总门面

#### `freeze`

- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`

判断：

1. `ProjectWorkflowRuntimeService` 当前已达 `2617` 行，属于明确的结构风险文件。
2. 它已经承载普通项目、长任务、checkpoint、delivery、review、runtime 装配等大量职责。
3. 信息层后续如果继续加在这里，几乎必然把它推成新的业务规则中心。

结论：

```text
ProjectWorkflowRuntimeService 后续只能做薄接线和结果回传，
不能成为 information lifecycle、research、projection、activation 的实现地。
```

### 5.5 本地存储与投影落点

#### `extend`

- `packages/novel_agent_adapters/lib/src/storage/`

判断：

1. adapters 现有本地 continuity repository 已证明“JSON/JSONL 事实源 + Markdown 投影”在本项目可行。
2. 信息层最自然的落点仍然是新增独立 repository，而不是混写进 `knowledge/` 或 continuation 旧目录。

后续推荐落点：

1. `.novel_agent/information/knowledge_cards/*.json`
2. `.novel_agent/information/design_elements/*.json`
3. `.novel_agent/information/research_notes/*.json`
4. `.novel_agent/information/reference_works/*.json`
5. `knowledge/*.md`、`research/*.md`、`references/*.md` 作为可读投影

---

## 6. App 审计

### 6.1 拆书展示层

#### `migrate`

- `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart`
- `apps/novel_agent_app/lib/features/book_deconstruction/presentation/models/book_deconstruction_continuity_view_data.dart`

判断：

1. 当前 view data 仍直接展示 `mechanicHintCount`，摘要文案仍是“机制提示 N 项”。
2. 这适合作为兼容 UI，但不适合作为后续信息层的正式名词体系。
3. 未来应迁移到中性 design/pattern/continuity hint 呈现，不在本轮改 UI。

### 6.2 长任务总站

#### `keep`

- `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
- `apps/novel_agent_app/lib/features/long_task_station/`

判断：

1. 当前 GUI 已能消费 `Activation / Delivery / Review / Continuity / Projection / 权限确认` 等稳定摘要。
2. 这说明 GUI 已经站在“消费稳定合同”的正确边界上。
3. 后续信息层进入 GUI 时，应沿用这种 summary + path entry 形式，而不是让 widget 直接解释开放 payload。

#### `extend`

- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/long_task_station/`

判断：

1. 未来只需要增加 information summary、projection 入口、pending confirmation 粗摘要。
2. 不应在 app 层建立 knowledge browser 逻辑中心，也不应把 proposal 审批规则写进 widget/controller。

---

## 7. CLI 审计

### 7.1 workflow 摘要链

#### `keep`

- `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
- `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`

判断：

1. CLI 目前已经只消费 run center、activation、delivery、review、continuity 等稳定摘要合同。
2. `workflow_output_summary_service.dart` 目前统计的仍是 continuity 变更，不包含 information 计数。
3. 这条链后续适合最小扩展 information summary，而不是去 CLI 里解释 knowledge/design/research/reference payload。

#### `extend`

- `apps/novel_agent_cli/tool/workflow_output_summary_probe.dart`

判断：

1. CLI 已有 focused probe 验证摘要输出。
2. 未来 PIS-29 只需在现有摘要链上增加 information 计数与投影路径，不需要重做 CLI 工作流。

---

## 8. Probe 审计

### 8.1 真实 probe 配置与 gating

#### `keep`

- `tools/probe_config_support.dart`
- `apps/novel_agent_app/tool/probe_support.dart`
- `apps/novel_agent_app/tool/real_general_novel_probe.dart`
- `apps/novel_agent_app/tool/real_long_task_probe.dart`
- `apps/novel_agent_app/tool/real_multiscope_pressure_probe.dart`

判断：

1. 真实 probe 已统一要求 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`，并优先读取 `local/probe_api.txt` 或环境变量指定配置。
2. `probe_support.dart` 明确把 probe 分类为 `success / technical_failure / waiting_user / budget_failure / content_quality_failure`，并强调只消费 production 合同。
3. 这条原则与 PIS 后续需要的 gated real probe framework 一致。

#### `freeze`

- `apps/novel_agent_app/tool/`
- `apps/novel_agent_cli/tool/`

判断：

1. probe 只能做验收与分类，不应成为研究入库、信息修复或生产旁路。
2. 信息层后续真实验证应复用现有 gated probe 支撑，不新增一批一次性脚本分叉业务判断。

---

## 9. 后续落点图

### 9.1 Core

新增主落点：

- `packages/novel_agent_core/lib/src/information/`

承接：

1. `ProjectKnowledgeCard`
2. `DesignElementCard`
3. `ResearchNote`
4. `ReferenceWorkRecord`
5. `InformationSourceRef`
6. `InformationUsagePolicy`
7. `InformationActivationPolicy`
8. repository ports / codec / validator / lifecycle service

### 9.2 Adapters

新增主落点：

- `packages/novel_agent_adapters/lib/src/storage/`
- `packages/novel_agent_adapters/lib/src/information/`

承接：

1. information repositories
2. projection writer
3. research gateway bridge
4. information activation bridge
5. runtime changed paths / checkpoint signal bridge

### 9.3 App / CLI

保持最小消费：

1. summary
2. projection 入口
3. pending confirmation 粗粒度展示

禁止：

1. 不在 GUI / CLI 解释开放 payload。
2. 不在 GUI / CLI 实现事实提升规则。
3. 不让 GUI / CLI 反向成为底层信息缺口的兜底层。

### 9.4 Probe

保持最后接入：

1. 先 mock suite。
2. 再 gated real probe framework。
3. 最后小预算真实验证。

禁止：

1. 不在 probe 内做私有 repair。
2. 不在 probe 内补 production 缺失的 research / information 逻辑。

---

## 10. 本轮结论

`PIS-01` 的结论可以收束为五条：

1. `ONS` 合同、领域工具骨架、现有共享资产、gated probe 机制都应直接复用。
2. `knowledge/` 只是兼容目录、上下文候选和未来投影入口，不是事实源。
3. 拆书里的 `mechanic hints` 需要保留兼容，但主语义应迁移到中性 design / pattern 信息对象。
4. `ProjectGatewayToolExecutor` 保持 host 能力；研究入库应通过新的 information bridge 完成。
5. `ProjectWorkflowRuntimeService` 与 `ProjectContextActivationService` 后续只能薄接线，不能继续吸收信息层算法。

本轮无运行时代码改动，下一轮可按顺序进入 `PIS-02`。
