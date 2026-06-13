# NovelAgentFlutter 重复实现风险台账

最后更新：2026-06-09

关联主线：

- `docs/full-module-sweep-collaboration-session-order-2026-06-09.md`
- `docs/full-module-sweep-module-audit-ledger-2026-06-09.md`
- `docs/important/full-module-sweep-collaboration-chunking-analysis-2026-06-09.md`
- `agent.md`

---

## 1. 本台账的职责

这份台账是 `FMSC` 主线下唯一正式的“重复实现风险台账”。

它只做三件事：

1. 固定当前项目里最常见的双实现风险类型。
2. 记录当前已知的高风险入口、跨块共享地带和最容易长出第二套语义的消费层。
3. 标出首轮串行清理顺序，让后续 session 不会各自挑一处“顺手补一下”。

这份台账当前只完成 `FMSC-02` 范围：

1. 固定风险类型。
2. 首填当前高风险入口。
3. 标出高风险块与首要清理顺序。

本台账当前刻意不做：

1. 不直接删旧实现。
2. 不提前替 `FMSC-03` 冻结主实现出口。
3. 不用“风险台账”替代模块台账。
4. 不把 GUI、CLI、probe、fallback 升格成业务真相中心。

---

## 2. 维护纪律

1. 同一重复实现风险只保留一个正式 `risk_id`。
2. 风险描述必须落到具体块、具体入口或具体文件，不写空泛“可能有重复”。
3. 如果风险跨块，必须先在本台账标出共享合同依赖，再串行清理，不允许两边各补一份。
4. `FMSC-03` 起如已明确主出口，必须把风险项更新为“主链 / 兼容层 / 待移除入口”。
5. `FMSC-04` 之后每次只更新当前 session 直接命中的风险项，不顺手改整张风险表。
6. 如果某风险已消除，要记录是“删除”“降级为兼容层”还是“附移除计划保留”，不能只写“已处理”。

---

## 3. 固定风险类型

| risk_type | 含义 | 本项目中的典型形态 |
| --- | --- | --- |
| `consumer_shadow_projection` | 外层消费者对同一 production truth 再解释一遍 | GUI/CLI/viewmodel 对 stop reason、review、reference state 再做人话推断 |
| `projection_truth_split` | 投影层、缓存层、兼容层被误当成事实源 | sqlite-first 已存在，但 markdown/json/projection 仍可能被消费者当主真相 |
| `cross_layer_contract_fork` | core、adapters、app 分别补同一语义缺口 | 同一执行约束、交付判断、repair 决策在多层各写一份 |
| `legacy_parallel_path` | 新旧链并存但未显式标主次 | 新合同已落地，但旧入口仍长期存活且继续被消费 |
| `config_resolution_split` | 默认级、项目级、运行时各自解释同一配置 | tool exposure、agent group、loadout、settings 各保留一套解释 |
| `probe_side_interpreter` | probe / regression / script 自己长出第二解释器 | 探针不再只是读取 production truth，而是重建一套判定 |
| `host_action_bypass` | GUI/CLI/脚本绕过共享 action service 直接改状态 | 宿主入口自己推 stop reason 或直接改 run/request 记录 |
| `shared_hotspot_multi_owner` | 同一文件/共享地带过大，天然吸引多人同时改 | 超大 runtime / summary / detail service 同时承载多块职责 |

---

## 4. 风险严重度与串行清理规则

### 4.1 风险严重度

- `critical`
  - 不先记账和冻结边界，后续最容易在多个块同时长出第二实现。
- `high`
  - 已有主链，但外层消费者、兼容层或旧链仍可能继续复制语义。
- `medium`
  - 当前可用，但放任不管会持续制造伪完成感或后续协作歧义。

### 4.2 串行清理规则

1. 先在 `FMSC-03` 冻结跨块共享合同风险，不提前开代码修。
2. `FMSC-04` 之后严格按正式 session 顺序清理，不因为某处“更好修”跳块。
3. 同一风险如果同时命中多个块，只允许当前主负责 session 修主链，其余块先登记为消费者整改。

---

## 5. 首轮风险清单

| risk_id | risk_type | severity | primary_blocks | risk_surface | concrete_entrypoints | why_risky_now | forbidden_shortcut | first_serial_cleanup_slot | status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `FMSC-R01` | `consumer_shadow_projection` | `critical` | `FMSC-B01`; `FMSC-B08`; `FMSC-B09`; `FMSC-B10` | 控制面停点真相在 GUI/CLI/probe 多侧再次解释 | `packages/novel_agent_core/lib/src/runtime/long_task_stop_diagnosis_projection_service.dart`; `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`; `apps/novel_agent_app/lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart`; `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`; `apps/novel_agent_app/tool/probe_support.dart` | `FMSC-04` 已先把 control-plane main chain 内部的 technical-failure recovery shell 收口到 `ContinuousTaskLifecycleStopOutcomeResolverService + ContinuousTaskRecoveryStateFactoryService`；`FMSC-12` 继续把 long task station GUI 里一类 legacy `run.stopReason -> 补充原因` 的二次人话解释删掉，让详情面板只消费正式 `stopDiagnosis / blocker` 投影；`FMSC-14` 再把 CLI workflow 摘要层里一类 narrative stop diagnosis 重建收紧为“优先消费 `run_center_contract.stop_diagnosis`，合同缺位时才兼容兜底”；`FMSC-15` 又把 `long_task_stability_mock_regression_suite_support.dart` 里五个 mock stop 场景的 probe-side stop diagnosis 直投影改为只消费正式 `run_center_contract.stop_diagnosis`。当前剩余高风险主要收敛到 `probe_support.dart`、少量 real probe 入口与 task center 等其他 consumer | 不允许在 widget、view-data service、CLI summary、probe 脚本里各补一套 stop reason 映射 | 先在 `FMSC-03` 冻结正式主出口，再由 `FMSC-04`、`FMSC-12`、`FMSC-14`、`FMSC-15` 串行清理消费者 | `main_chain_hardened_consumer_cleanup_pending` |
| `FMSC-R02` | `projection_truth_split` | `critical` | `FMSC-B05`; `FMSC-B06`; `FMSC-B08`; `FMSC-B09` | 参考提取挂载、项目信息投影和工作台消费之间仍存在“事实源 / 投影”混读风险 | `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_mount_service.dart`; `packages/novel_agent_adapters/lib/src/storage/project_reference_projection_service.dart`; `packages/novel_agent_adapters/lib/src/storage/project_information_projection_writer_service.dart`; `packages/novel_agent_adapters/lib/src/storage/sqlite_first_project_reference_projection_port_factory.dart`; `apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart` | `FMSC-08` 已先把 `FMSC-B05` 主链内最直接的一类重复解释收紧；`FMSC-09` 继续把 `FMSC-B06` 主链里的 `project-information://...` locator 口径收回到 `InformationSourceOfTruthLocatorService`，避免 information projection 和 activation bridge 各自拼一套 source-of-truth locator。当前剩余高风险主要落在 workspace/CLI consumer 仍可能把 markdown/json projection 重新当真相层 | 不允许把 markdown projection、workspace 摘要或 JSON 兼容导出重新拉回事实源 | 先在 `FMSC-03` 冻结“事实源 vs 投影”边界，再按 `FMSC-08` -> `FMSC-09` -> `FMSC-13` 串行清理 | `main_chain_hardened_consumer_cleanup_pending` |
| `FMSC-R03` | `projection_truth_split` | `high` | `FMSC-B06`; `FMSC-B02`; `FMSC-B08` | 信息激活链、写作消费链和工作台资料面可能继续保留双口径 | `packages/novel_agent_adapters/lib/src/workflow/project_information_activation_bridge_service.dart`; `packages/novel_agent_adapters/lib/src/workflow/project_context_activation_service.dart`; `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`; `apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart` | `FMSC-09` 已先把信息主链内部的 locator 共享缺口收紧：activation bridge 与 markdown projection 不再各自定义 `project-information://...` 规则。`FMSC-11` 继续把 workbench 信息区的一类 GUI shadow projection 去掉：`WorkspaceInformationProjectionService` 不再解析宿主再包装的 `selected_context_sections / omitted_context_sections`，而是直接消费正式 `ContextActivationReport.items`。当前剩余高风险主要落在 workspace 仍会直接读取 projection frontmatter、以及 project assets / CLI consumer 对信息真相的轻投影摘要 | 不允许在 prompt builder、workspace viewmodel、CLI 摘要层直接补“信息事实解释器” | `FMSC-03` 先冻结共享合同缺口，再按 `FMSC-09`、`FMSC-11`、`FMSC-13` 串行清理 | `main_chain_hardened_consumer_cleanup_pending` |
| `FMSC-R04` | `cross_layer_contract_fork` | `high` | `FMSC-B02`; `FMSC-B03`; `FMSC-B01` | 写作执行、审稿修复、交付后置链仍可能在多 runtime/service 各补一份共享语义 | `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`; `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`; `packages/novel_agent_adapters/lib/src/workflow/project_draft_execution_constraint_runtime_service.dart`; `packages/novel_agent_adapters/lib/src/workflow/project_workflow_review_runtime_service.dart` | `FMSC-05` 已先把普通写作 shared execution 装配统一到 `project_writing_execution_contract_service.dart`；`FMSC-06` 继续把普通 semantic review 的 `report -> repair task` 平行语义收口到 `review_contract / review_repair_handoff` 主链，并由 `project_review_repair_task_contract_service.dart` 统一物化 workflow revision 任务。当前剩余高风险主要落在 review / repair 共享合同被 GUI / CLI 消费层重新解释 | 不允许在普通写作 runtime、长任务 runtime、review runtime、postprocess service 各自修一版执行约束语义 | `FMSC-03` 标记共享合同热点后，按 `FMSC-05` -> `FMSC-06` 串行清理 | `main_chain_hardened_consumer_cleanup_pending` |
| `FMSC-R05` | `projection_truth_split` | `high` | `FMSC-B04`; `FMSC-B06`; `FMSC-B08` | 连续性真相、状态投影和工作台/资产展示之间仍可能混读 | `packages/novel_agent_adapters/lib/src/workflow/project_context_activation_service.dart`; `packages/novel_agent_adapters/lib/src/workflow/project_narrative_claim_activation_contract_service.dart`; `packages/novel_agent_adapters/lib/src/storage/open_narrative_state_projection_writer_service.dart`; `packages/novel_agent_adapters/lib/src/storage/project_continuity_repository.dart`; `packages/novel_agent_core/lib/src/continuity/`; `apps/novel_agent_app/lib/features/workbench/`; `apps/novel_agent_app/lib/features/project_assets/` | `FMSC-07` 已先把 activation 主链里最直接的一类混读收紧：`ProjectContextActivationService` 不再把 raw `claims.jsonl` 直接当正式 continuity truth，而是统一通过 `project_narrative_claim_activation_contract_service.dart` 优先消费 ledger-backed claim disposition；当前剩余高风险主要落在 readable projection、workspace 展示与 assets 浏览仍可能把可读投影再误当真相 | 不允许在 GUI 资源面、projection writer 或 activation consumer 中直接补 continuity 真相修复，尤其不允许重新把 `claims.jsonl` 拉回正式状态出口 | `FMSC-03` 先冻结事实源候选，再由 `FMSC-07` 与 `FMSC-13` 串行清理 | `main_chain_hardened_consumer_cleanup_pending` |
| `FMSC-R06` | `config_resolution_split` | `high` | `FMSC-B07`; `FMSC-B02`; `FMSC-B01` | 默认级、项目级、运行时 tool exposure / agent group / loadout 解释链可能复制 | `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`; `packages/novel_agent_core/lib/src/agents/sub_agent_effective_execution_profile_service.dart`; `packages/novel_agent_core/lib/src/tools/tool_strategy_service.dart`; `packages/novel_agent_adapters/lib/src/storage/project_agent_group_binding_repository.dart`; `apps/novel_agent_app/lib/features/settings/` | `FMSC-10` 已把最直接的一类分叉风险收回主链：`ProjectWorkflowRuntimeBridgeService` 与 `SubAgentEffectiveExecutionProfileService` 不再各自从 `ToolStrategyService.defaultSettings()` 私造默认候选工具集合，而是统一改为由 `ContinuousTaskToolExposureRuntimeResolverService` 基于 task profile、runtime context、group capability scope 与 tool strategy defaults 生成正式 `default candidate tool ids`。`FMSC-16` 的真实 ordinary-project probe 又进一步验证并回补了同一主链的残留：入口消费层先前只看 `default_allowed_tool_ids`，把 `requires_confirmation` 的 research 工具藏掉，导致普通受限权限写作入口退回 generic 选项工具；现已统一扩成同源 `visible_tool_ids` 合同，让 workflow / ordinary / sub-agent 入口都只消费同一可见工具集合。当前剩余高风险主要落在 settings / loadout / binding 外层消费仍可能试图重新解释项目级配置或可视化默认值 | 不允许 settings 页面、bootstrap、runtime fallback 各自解释同一 tool exposure 或 loadout 默认值，也不允许消费者擅自把 `requires_confirmation` 工具从正式入口过滤掉 | `FMSC-03` 冻结边界后，由 `FMSC-10` 串行清理；`FMSC-16` 只允许回 owning block 回补真实入口验证暴露出的残留 | `main_chain_hardened_real_probe_verified_consumer_cleanup_pending` |
| `FMSC-R07` | `consumer_shadow_projection` | `high` | `FMSC-B08`; `FMSC-B01`; `FMSC-B03`; `FMSC-B06` | GUI view-data service 容易从共享合同退回宿主私有人话逻辑 | `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart`; `apps/novel_agent_app/lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart`; `apps/novel_agent_app/lib/features/task_center/application/services/task_center_view_data_service.dart`; `apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart`; `apps/novel_agent_app/lib/features/project_assets/application/controllers/project_assets_controller.dart` | `FMSC-11` 已先清掉 workbench 信息区里一类最直接的 shadow logic：GUI 不再从 activation report metadata 再推导“本轮已使用 / 未使用”的资料口径，而是直接消费 `ContextActivationReport.items`。`FMSC-12` 继续清掉 long task station 详情里一类 stop reason shadow logic：`LongTaskStationViewDataService` 不再基于 legacy `run.stopReason` 生成额外 `stopReasonLabel`，`LongTaskRunDetailPanel` 也不再展示 `补充原因`。`FMSC-13` 再清掉 project assets graph/reference 导航里一类 shared identity shadow logic：`ProjectAssetsController` 不再私拆 `referenceKey` 的 `kind:id` 规则，而是统一消费 `SharedNarrativeAssetReferenceIndex.referenceByKey(...)`。当前剩余高风险主要落在 task center 的 view-data / guidance consumer 仍可能继续补宿主侧人话判断 | 不允许为了“先显示正确”在 view-data service、controller 或 widget helper 里补业务判断 | 在 `FMSC-03` 标记为消费者层整改，再按 `FMSC-11` -> `FMSC-13` 串行清理 | `main_chain_hardened_consumer_cleanup_pending` |
| `FMSC-R08` | `host_action_bypass` | `medium` | `FMSC-B09`; `FMSC-B01`; `FMSC-B03`; `FMSC-B05` | CLI / 自动化最容易把共享摘要和共享动作再包一层私有命令逻辑 | `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`; `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`; `apps/novel_agent_app/tool/`; `apps/novel_agent_cli/tool/` | `FMSC-14` 已先清掉 workflow 命令摘要里一类最直接的 control-plane bypass：`WorkflowOutputSummaryService` 不再默认在 CLI 侧重建 narrative `stop_diagnosis`，而是优先消费正式 `run_center_contract.stop_diagnosis`。当前剩余高风险主要落在命令层和工具脚本仍可能继续对 shared action package、reference extraction summary 或其余 workflow contracts 再包一层私有语义 | 不允许在 command、tool script 中直接改 run/request 记录或重建一套 workflow 语义 | 由 `FMSC-14` 专门清理，期间其余 session 只允许把 CLI/脚本当消费者 | `main_chain_hardened_consumer_cleanup_pending` |
| `FMSC-R09` | `probe_side_interpreter` | `high` | `FMSC-B10`; `FMSC-B01`; `FMSC-B05`; `FMSC-B06` | 真实 probe、mock regression、CLI probe 仍可能重建第二解释器 | `apps/novel_agent_app/tool/real_gui_viewmodel_information_long_task_probe.dart`; `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`; `apps/novel_agent_cli/tool/workflow_output_summary_probe.dart`; `apps/novel_agent_cli/tool/workflow_resolution_cli_probe.dart`; `apps/novel_agent_app/tool/reference_extraction_runtime_real_probe.dart` | `FMSC-15` 已先清掉 `long_task_stability_mock_regression_suite_support.dart` 里一类最直接的 probe-side interpreter：mock suite 不再自己 `project(...)` stop diagnosis，也不再盯旧的 downstream task dependency 重写细节，而是改为只验证正式 `run_center_contract.stop_diagnosis` 与 `checkpoint_followup.review_task_ids` 合同。当前剩余高风险主要落在 shared `probe_support.dart` 与若干 real probe / CLI probe 入口仍可能顺手补 host-side 判断 | 不允许 probe 为了通过验证去新增 production 侧没有的判断口径 | 由 `FMSC-15` 集中同源化，`FMSC-16` 前不得扩新一批一次性解释脚本 | `partially_closed_same_source_hardened` |
| `FMSC-R10` | `shared_hotspot_multi_owner` | `critical` | `FMSC-B01`; `FMSC-B02`; `FMSC-B03`; `FMSC-B06`; `FMSC-B08`; `FMSC-B09` | 超大共享文件天然吸引多会话并发改动，且内部已跨多个块职责 | `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`（4010 行）; `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`（1319 行）; `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`（928 行）; `apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart`（500 行） | `FMSC-04` 已先把控制面 technical-failure recovery shell 从 adapter 入口私有拼装中抽成 core 共享合同，减少了后续继续往 supervisor/bridge/sync 热点入口各堆一份近似逻辑的风险；其余超大热点文件仍需按各自 session 串行治理 | 不允许在边界未冻结前多人同时往这些热点文件里堆补丁 | `FMSC-03` 必须先标清块边界、主出口候选和共享合同缺口，再进入 `FMSC-04+` 代码清理 | `shared_contract_extracted` |

---

## 6. 高风险块首轮串行清理顺序

下面的顺序不是重新发明主线，而是把当前高风险块按正式 `FMSC` session 对齐后的首轮清理序列固定下来。

| serial_order | target_block | why_first | matching_session | linked_risks |
| --- | --- | --- | --- | --- |
| `01` | 共享合同与边界冻结 | 先锁住跨块共享缺口，避免热点文件和消费层继续各补一份 | `FMSC-03` | `FMSC-R01`; `FMSC-R02`; `FMSC-R03`; `FMSC-R10` |
| `02` | 控制面块 | 停点、恢复、状态真相会污染 GUI/CLI/probe 全链路 | `FMSC-04` | `FMSC-R01`; `FMSC-R10` |
| `03` | 写作执行块 | 普通任务与长任务最容易在执行约束和交付判断上各长一套 | `FMSC-05` | `FMSC-R04` |
| `04` | 审稿与修复块 | review/repair/disposition 若不统一，外围层最容易自己补判断 | `FMSC-06` | `FMSC-R04`; `FMSC-R07` |
| `05` | 连续性与状态块 | 不先明确事实源，后面的投影与资产展示都会继续模糊 | `FMSC-07` | `FMSC-R05` |
| `06` | 参考提取块 | runtime、mount、projection、probe 天然容易并行长语义 | `FMSC-08` | `FMSC-R02`; `FMSC-R09` |
| `07` | 信息基底与激活块 | activation / projection / consumer 混读会重新制造第二真相层 | `FMSC-09` | `FMSC-R02`; `FMSC-R03` |
| `08` | 智能体生态块 | 默认级、项目级、运行时若不统一，后面所有宿主都要补兼容 | `FMSC-10` | `FMSC-R06` |
| `09` | GUI 消费块 | GUI 必须最后按稳定合同回收，不得先变业务补丁层 | `FMSC-11`; `FMSC-12`; `FMSC-13` | `FMSC-R01`; `FMSC-R03`; `FMSC-R05`; `FMSC-R07` |
| `10` | CLI / 自动化块 | 只允许最小消费稳定合同，不允许变第二控制面 | `FMSC-14` | `FMSC-R08` |
| `11` | probe / regression 块 | 最后统一到 production-same-source，防止探针继续自带解释器 | `FMSC-15` | `FMSC-R01`; `FMSC-R09` |

---

## 7. 会话更新记录

- `FMSC-02`：
  - 新建本风险台账，固定重复实现风险类型、严重度口径和首轮串行清理顺序。
  - 当前高风险块：控制面、参考提取、信息基底与激活、probe 与 regression、宿主 GUI 消费、CLI / 自动化。
  - 本轮正式主实现出口：`docs/full-module-sweep-duplicate-implementation-risk-ledger-2026-06-09.md`。
  - 本轮已消除的双实现风险：后续会话不再各自写一份“自己的风险列表”，统一按 `risk_id` 回链同一风险台账。
- `FMSC-03`：
  - 已把当前 `10` 条重复实现风险统一推进到 `boundary_frozen`，说明正式主出口、事实源候选和消费者边界已冻结。
  - 本轮收口块：`Documentation / Core boundary audit`。
  - 本轮正式主实现出口：`docs/full-module-sweep-module-audit-ledger-2026-06-09.md`。
  - 本轮已消除的双实现风险：后续代码 session 不再把 `projection writer / summary service / view-data service / probe support / CLI summary` 误当主链入口。
- `FMSC-04`：
  - 本轮收口块：`FMSC-B01 控制面块`。
  - 本轮正式主实现出口：`packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`；新增共享合同出口：`packages/novel_agent_core/lib/src/workflow/continuous_task_lifecycle_stop_outcome_resolver_service.dart` 与 `packages/novel_agent_core/lib/src/workflow/continuous_task_recovery_state_factory_service.dart`。
  - 本轮已消除的双实现风险：`ContinuousTaskSupervisorBridgeService` 与 `ReferenceExtractionContinuousTaskSyncService` 不再各补一份 technical-failure recovery shell，`LongTaskSupervisor` 也不再私有维护一份 lifecycle->stop-outcome 映射；当前 `FMSC-R01` 已收紧到“主链已统一、消费者待清理”，`FMSC-R10` 已从控制面入口热点里抽出一条明确共享合同。
- `FMSC-08`：
  - 本轮收口块：`FMSC-B05 参考提取块`。
  - 本轮正式主实现出口：`packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart`；新增共享合同出口：`packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_mount_outcome.dart` 与 `project_reference_mount_outcome_resolver_service.dart`。
  - 本轮已消除的双实现风险：`ProjectReferenceExtractionMountService` 与 `ProjectReferenceExtractionRuntimeService` 不再各补一份 attach/project 结果语义解释，`FMSC-R02` 已从“边界冻结但主链仍可能各自解释 mount/projection 结果”降到“主链已统一、projection consumer 待清理”；`FMSC-R09` 本轮保持冻结态且未扩 probe 侧特判，避免为了验证再长一份 host-side 解释器。
- `FMSC-09`：
  - 本轮收口块：`FMSC-B06 信息基底与激活块`。
  - 本轮正式主实现出口：`packages/novel_agent_adapters/lib/src/workflow/project_information_activation_bridge_service.dart`；新增共享合同出口：`packages/novel_agent_core/lib/src/information/information_source_of_truth_locator_service.dart`。
  - 本轮已消除的双实现风险：`InformationMarkdownProjectionService` 与 `ProjectInformationPathService` 不再各自手写一套 `project-information://...` locator 规则，`FMSC-R02` 已进一步收紧为“主链 locator 已统一、projection consumer 待清理”，`FMSC-R03` 也从“边界冻结”推进到“主链已统一、runtime / GUI / workspace consumer 待清理”。
- `FMSC-10`：
  - 本轮收口块：`FMSC-B07 智能体生态块`。
  - 本轮正式主实现出口：`packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`。
  - 本轮已消除的双实现风险：`ProjectWorkflowRuntimeBridgeService` 与 `SubAgentEffectiveExecutionProfileService` 不再各补一份 `ToolStrategyService.defaultSettings()` 驱动的默认候选工具集合，`FMSC-R06` 已从“边界冻结”推进到“主链已统一、settings / loadout / binding consumer 待清理”；focused validation 已固定 workflow task 与 child-agent 在未声明 `allowed_tool_ids` 时都只消费同一条 runtime default candidate contract。
- `FMSC-11`：
  - 本轮收口块：`FMSC-B08 宿主壳与工作台 GUI 消费块`。
  - 本轮正式主实现出口：`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`。
  - 本轮已消除的双实现风险：`WorkspaceInformationProjectionService` 不再从 `activation_report.json` 的宿主 metadata 再补一版 `selected_context_sections / omitted_context_sections` 解释，`FMSC-R07` 已从“边界冻结”推进到“主链已统一一类 workbench information usage 读法、其余 GUI consumer 待清理”，`FMSC-R03` 也进一步收紧为“activation report 主链已统一、workspace 其余 projection consumer 待清理”。
- `FMSC-12`：
  - 本轮收口块：`FMSC-B08 宿主壳与工作台 GUI 消费块`。
  - 本轮正式主实现出口：`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`；本轮直接收紧的 GUI 消费服务：`apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart`。
  - 本轮已消除的双实现风险：`LongTaskStationViewDataService` 不再基于 legacy `run.stopReason` 生成额外 `stopReasonLabel`，`LongTaskRunDetailPanel` 也不再展示 `补充原因`；long task station 详情改为只消费正式 `LongTaskStopDiagnosisProjectionService -> stopDiagnosis` 与 blocker 投影，避免 GUI 在 control-plane 停点真相旁边再长一条宿主私有人话出口。focused validation 已固定 `stopDiagnosis / blocker -> LongTaskStationViewDataService -> LongTaskRunDetailPanel` 的单一路径。
- `FMSC-13`：
  - 本轮收口块：`FMSC-B08 宿主壳与工作台 GUI 消费块`。
  - 本轮正式主实现出口：`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`；本轮直接收紧的 GUI 消费服务：`apps/novel_agent_app/lib/features/project_assets/application/controllers/project_assets_controller.dart`。
  - 本轮已消除的双实现风险：`ProjectAssetsController` 不再私拆 `referenceKey` 的 `kind:id` 规则来决定 graph/inspector/sidebar 的导航落点，而是统一通过正式共享合同 `SharedNarrativeAssetReferenceIndex.referenceByKey(...)` 读取 `assetKind / assetId / referenceKey`。这删除了一类 project assets GUI 自带 shared asset identity 解释器的风险，并通过 focused validation 固定 `SharedNarrativeAssetReferenceIndex -> ProjectAssetsController` 的单一路径。
- `FMSC-14`：
  - 本轮收口块：`FMSC-B09 CLI 与自动化消费块`。
  - 本轮正式主实现出口：`apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`；本轮直接收紧的 CLI 消费服务：`apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`。
  - 本轮已消除的双实现风险：`WorkflowOutputSummaryService.extractNarrativeRuntimeContract(...)` 不再默认基于 `stop_outcome / recovery_state / stop_reason` 在 CLI 侧再投影一份 `stop_diagnosis`，而是优先直接消费正式 `run_center_contract.stop_diagnosis`；只有共享合同缺位时才走兼容兜底。这样删除了一类“命令摘要层顺手再长一份 control-plane stop diagnosis 解释器”的风险，并通过 focused validation 固定 `run_center_contract.stop_diagnosis -> WorkflowOutputSummaryService -> workflow_command / workflow_output_summary_probe` 的单一路径。
- `FMSC-15`：
  - 本轮收口块：`FMSC-B10 Probe 与回归块`。
  - 本轮正式主实现出口：`packages/novel_agent_adapters/test/continuous_task_control_plane_regression_suite_test.dart`；本轮直接收紧的 probe/regression 入口：`apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`。
  - 本轮已消除的双实现风险：mock regression suite 不再在 probe 侧直接 `LongTaskStopDiagnosisProjectionService.project(...)` 一份 `stop_diagnosis`，而是统一改为消费正式 `run_center_contract.stop_diagnosis`；`long_task_proactive_review` 也改为只验证正式 `checkpoint_followup.review_task_ids` 与源任务落盘的 `checkpoint_followup_task_ids`。这把 `FMSC-R09` 从“边界冻结”推进到“已清掉一类最直接的 mock probe interpreter，剩余 real/shared probe 入口待继续清理”，也把 `FMSC-R01` 进一步收紧到“主要剩余 shared probe support 与少量 consumer 待清理”。
- `FMSC-16`：
  - 本轮收口块：`Integration / Probe`，但真实失败归因并回补到 earlier owning block `FMSC-B07 智能体生态块`。
  - 本轮正式主实现出口：`packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`；本轮新增并落地的共享消费边界：`visible_tool_ids`。
  - 本轮已消除的双实现风险：真实普通项目入口不再把 `requires_confirmation` research 工具静默过滤成“模型根本看不见的能力”，workflow bridge、ordinary conversation、draft use case 与 sub-agent 入口现在只消费同一条 `visible_tool_ids` 合同；因此 real ordinary probe 不再需要靠 `present_user_options` 或 probe-side 判断绕过缺口，而是回到正式 `request_external_research -> pending confirmation` 主链。focused validation 已覆盖 `continuous_task_tool_exposure_runtime_resolver_service_test.dart`、`project_workflow_runtime_bridge_service_test.dart`、`project_conversation_draft_runtime_service_test.dart`；真实入口验证已覆盖 `real_information_evidence_ordinary_probe.dart` 与 `real_long_task_probe.dart --stop-after-sample`。
- `FMSC-17`：
  - 本轮收口块：`Productization / Audit`。
  - 本轮正式主实现出口：`docs/full-module-sweep-module-audit-ledger-2026-06-09.md` 中的发布面残留分级与 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 中的 `FMSC-17` 完成记录。
  - 本轮已消除的双实现风险：把“发布阻断”和“外围消费层清理”明确拆开，避免后续会话同时去修 CLI session、task center、probe support、Android packaging、长任务稳定性四类不同层级问题，重新制造多会话并行改热点的局面。经本轮重排后，真正的发布面 `必须修` 只保留真实 provider 长任务稳定性与 Android 正式分发缺口；`task center`、CLI 迁移壳和剩余 probe cleanup 明确降为 `可延后` 或 `纯优化`，不得再冒充当前主发布阻断。
- `FMSC-18`：
  - 本轮收口块：`Documentation / Handoff`。
  - 本轮正式主实现出口：`docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 中的总收口记录与接力提示。
  - 本轮已消除的双实现风险：`FMSC` 主线收官后，后续会话不再需要各自补写一份“新的 sweep 总结”“新的接力顺序”或“新的总提示词”，从而避免文档层再次长出第二套主线口径；今后的工作应直接复用既有 `risk_id`、块台账和收官后的接力顺序，而不是重开平行 sweep。
