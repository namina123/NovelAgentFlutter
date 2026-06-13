# 高保真 ViewModel 验收台账

最后更新：2026-06-13  
当前 session：`HFVV-05`  
当前 run id：`2026-06-10T01-35-42`

关联文档：

- `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md`
- `docs/important/high-fidelity-viewmodel-validation-analysis-2026-06-10.md`
- `docs/important/opening-default-constraint-followup-2026-06-09.md`
- `agent.md`

---

## 1. 本台账职责

这份台账是 `HFVV` 主线的正式 run ledger。  
`HFVV-01` 只做三件事：

1. 冻结本轮高保真验收范围、波次、lane 和失败分类。
2. 冻结产物目录、workspace 隔离、rerun 规则和最小证据清单。
3. 核查 API / 代理 / 语料 / 旧 probe 现状是否具备后续 session 启动条件。

本轮刻意不做：

1. 不启动真实长时间测试。
2. 不修业务代码。
3. 不推进 `HFVV-02` 及之后的 session。

---

## 2. HFVV-01 基线结论

### 2.1 入口与范围冻结

1. 本轮主验收入口冻结为 `GUI ViewModel / Controller / action handler` 路径。
2. 旧 real probe 与 legacy probe 只保留为参考基线、合同样例和风险对照，不可作为主验收入口。
3. 每条主测试线都必须从新项目开始，且使用独立 workspace 与独立报告目录。
4. 每一步必须联合读取 `ViewModel 状态 + 会话条目 + 工具状态 + 资源树 + 长任务站 + 项目文件 + 运行记录` 判定。

### 2.2 旧 probe 现状结论

1. 现有 `apps/novel_agent_app/tool/real_gui_viewmodel_information_long_task_probe.dart` 仍以底层 runtime/service 组织流程，不能直接充当本轮主验收 harness。
2. 现有 `apps/novel_agent_app/test/real_gui_viewmodel_information_long_task_probe_contract_test.dart` 只约束“普通开篇不直接短路到第 01 章”，可作为 `HFVV-02` 合同参考，但不足以覆盖高保真动态交互循环。
3. 旧 `artifacts/real_gui_viewmodel_information_long_task_probe_runs/` 可作为历史证据样例，但其目录结构与判定口径不能直接沿用为 `HFVV` 正式口径。

### 2.3 本地前提结论

1. `local/probe_api.txt` 存在，格式按 `local/README.md` 约定为三行配置；本轮只确认存在，不打印密钥与具体值。
2. 真实探针显式启用门槛已冻结：需要 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`，且默认只认 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE`。
3. `local/gui_viewmodel_probe/` 目录存在但当前为空，适合作为后续 `HFVV-02+` 本地主态辅助目录，不存在旧状态污染。
4. 仓库当前为脏工作树；后续 session 需要避免误覆盖用户未提交改动。

---

## 3. 波次与 lane 冻结

### 3.1 波次冻结

| wave | sessions | 目标 |
| --- | --- | --- |
| `Wave 0` | `HFVV-01` ~ `HFVV-03` | 基线审计、harness 合同、自检、语料与安全检查 |
| `Wave 1` | `HFVV-04` ~ `HFVV-05` | 启动 `Lane A/B/C/D/E`，普通项目与知识生成基础线 |
| `Wave 2` | `HFVV-06` ~ `HFVV-07` | 启动 `Lane F/G/H/I`，消费与长任务线 |
| `Wave 3` | `HFVV-08` ~ `HFVV-09` | 启动 `Lane J1/J2/J3/J4`，拆书续写多层级线 |
| `Wave 4` | `HFVV-10` ~ `HFVV-11` | 横切回归、共享底座重跑、发布前判定 |

### 3.2 Lane 冻结表

| lane_id | wave | 类型 | 新项目要求 | 依赖 | 当前状态 | workspace 约定 |
| --- | --- | --- | --- | --- | --- | --- |
| `lane_a_ordinary_information_before_writing` | `Wave 1` | 普通项目 | 必须 | 无 | `planned` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_a_ordinary_information_before_writing/` |
| `lane_b_ordinary_multi_agent` | `Wave 1` | 普通项目 | 必须 | 无 | `planned` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_b_ordinary_multi_agent/` |
| `lane_c_user_side_knowledge_base` | `Wave 1` | 知识库生成 | 必须 | 无 | `planned` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_c_user_side_knowledge_base/` |
| `lane_d_book_import_knowledge_base` | `Wave 1` | 书籍导入知识库 | 必须 | 无 | `planned` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_d_book_import_knowledge_base/` |
| `lane_e_network_knowledge_base` | `Wave 1` | 网络资料知识库 | 必须 | 无 | `planned` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_e_network_knowledge_base/` |
| `lane_f_harry_potter_fanfic_consumption` | `Wave 2` | 同人消费 | 必须 | `Lane D` | `blocked_by_dependency` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_f_harry_potter_fanfic_consumption/` |
| `lane_g_general_long_task_stability` | `Wave 2` | 长任务 | 必须 | 无 | `planned` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_g_general_long_task_stability/` |
| `lane_h_general_long_task_multi_agent` | `Wave 2` | 长任务多智能体 | 必须 | 无 | `planned` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_h_general_long_task_multi_agent/` |
| `lane_i_high_variance_story_arc` | `Wave 2` | 长任务高变化剧情 | 必须 | 无 | `planned` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_i_high_variance_story_arc/` |
| `lane_j1_continuation_from_raw_excerpt` | `Wave 3` | 拆书续写 | 必须 | `HFVV-03` 预处理 | `blocked_by_dependency` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_j1_continuation_from_raw_excerpt/` |
| `lane_j2_continuation_from_summary_layer` | `Wave 3` | 拆书续写 | 必须 | `HFVV-03` 预处理 | `blocked_by_dependency` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_j2_continuation_from_summary_layer/` |
| `lane_j3_continuation_from_structured_facts` | `Wave 3` | 拆书续写 | 必须 | `HFVV-03` 预处理 | `blocked_by_dependency` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_j3_continuation_from_structured_facts/` |
| `lane_j4_long_task_continuation` | `Wave 3` | 长任务式拆书续写 | 必须 | `HFVV-03` 预处理 | `blocked_by_dependency` | `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/lane_j4_long_task_continuation/` |

---

## 4. 失败分类冻结

后续所有 lane 的正式 `report_category` 与 `failure_category` 至少使用以下枚举：

| category | 含义 |
| --- | --- |
| `success` | 当前 lane 通过 |
| `technical_failure` | 代码异常、工具异常、写文件失败、provider 调用失败、路径错误 |
| `product_flow_failure` | GUI / ViewModel 路径不能自然继续，或状态提示误导用户 |
| `runtime_stability_failure` | 长任务停摆、watchdog/supervisor/recovery 失效 |
| `content_quality_failure` | 正文、续写、知识或表达限制未达验收线 |
| `validation_failure` | 证据不足，无法证明通过或失败 |
| `blocked_external` | 网络、模型服务、权限、输入文件等外部阻塞 |
| `waiting_user` | 正确停在用户确认点，不应误报失败 |

补充纪律：

1. `pending` 工具不是失败。
2. 空工具结果不是成功。
3. 若修复共享底座，必须重跑失败 lane 与受影响相邻 lane。

---

## 5. 产物与证据冻结

### 5.1 run 根目录

本轮 run 根目录冻结为：

`artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/`

run 根目录下还必须提供：

1. `run_manifest.json`
2. `run_budget_policy.json`
3. lane 级标准模板文件，避免后续 session 临时发明第二套报告口径

### 5.2 每条 lane 的最低证据

每条 lane 至少保留：

1. `lane_report.json`
2. `project_manifest.json`
3. `fix_log.md`
4. `step_XXX_viewmodel.json`
5. `step_XXX_model_event.json`
6. `step_XXX_tool_events.json`

`HFVV-01` 已为每条 lane 预创建以下启动骨架：

1. `lane_report.json`
2. `project_manifest.json`
3. `fix_log.md`

### 5.3 每一步的最小循环

1. 输入或确认动作。
2. 等待 ViewModel 状态进入可判定阶段。
3. 读取会话条目、工具状态、资源树、长任务站和项目文件变化。
4. 判断当前是 `pending / waiting_user / research / outline / writing / review / failure / completed` 哪一类。
5. 根据真实返回继续、等待、确认或冻结失败现场。

---

## 6. rerun 规则冻结

1. 任一 lane 失败后，立即冻结该 lane 现场，不等待其他 lane 全部结束。
2. 修复必须优先落在生产链路，不得只在 probe / harness 中吞错。
3. 修复后至少重跑：
   - 失败 lane
   - 对应 focused test 或 contract test
   - 受影响相邻 lane
4. rerun 次数、影响面和结果必须写回该 lane 的 `lane_report.json` 与 `fix_log.md`。

---

## 7. 预算策略冻结

`HFVV-01` 只冻结预算记录口径，不启动真实消耗。

后续所有 lane 必须记录：

1. `provider_id`
2. `model_id`
3. `request_count`
4. `tool_round_count`
5. `rerun_count`
6. `estimated_input_chars`
7. `estimated_output_chars`
8. `budget_notes`

预算纪律：

1. 不允许无限重试同一路径。
2. 同类失败连续出现时，优先定位与修复，不靠追加轮次硬顶。
3. 长任务线需要分波次记录批次推进和中途停点原因。
4. 外部阻塞时应尽早落为 `blocked_external` 或 `waiting_user`，而不是吞预算空转。

---

## 8. 基线存在性核查

### 7.1 API / 本地配置

| item | 结果 | 备注 |
| --- | --- | --- |
| `local/probe_api.txt` | `present` | 已确认存在；按安全约束不打印内容 |
| `local/probe_api.example.txt` | `present` | 可作为格式参考 |
| `NOVEL_AGENT_ENABLE_REAL_PROBES` 要求 | `documented` | 见 `local/README.md` 与 `tools/probe_config_support.dart` |
| 真实 probe 配置入口 | `frozen` | 仅 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE` |

### 7.2 代理 / 网络入口

| item | 结果 | 备注 |
| --- | --- | --- |
| `networkSettings.proxy_mode` | `present_in_app` | 设置页与 bootstrap 已有入口 |
| `permissionSettings.allow_network` | `present_in_app` | 后续联网 lane 可验证动态状态 |
| `information_permission_mode` | `present_in_probe_baseline` | 仅说明现有能力存在，不代表本轮已验证通过 |

### 7.3 语料存在性

| item | 结果 | 备注 |
| --- | --- | --- |
| `references/files/Harry Potter - Volume 1 Raw.txt` | `present` | 适合作为 `Lane D` 首选小规模输入 |
| `references/files/Harry Potter.txt` | `present` | 可在稳定后扩大规模 |
| `references/files/re从零开始的异世界生活.txt` | `present` | 供 `Wave 3` 预处理与拆书续写 |

### 7.4 风险提示

1. 当前真实高保真入口尚未冻结为 production-same-source 的 ViewModel harness，`HFVV-02` 需要先补合同与最小自检。
2. 仓库当前存在大量未提交改动；后续定位问题时必须先区分“既有改动”与“本轮修复”。
3. 旧 probe 目录与旧产物目录命名口径不符合 `HFVV` 正式目录标准，后续不得直接复用为正式 lane 报告。

---

## 9. session 状态

| session | 状态 | 说明 |
| --- | --- | --- |
| `HFVV-01` | `completed` | 已完成基线审计、lane 冻结、失败分类、产物目录、存在性核查 |
| `HFVV-02` | `completed` | 已冻结 production-same-source AppShell ViewModel harness，并通过 fake-provider smoke 验证新项目创建、pending tool、completed/failed tool、waiting_user 投影 |
| `HFVV-03` | `completed` | 已完成 Harry Potter / Re:Zero 语料复制、Re:Zero UTF-8 转换、约 100 万字边界定位、source asset manifest 与 session 报告落地 |
| `HFVV-04` | `completed` | Wave 1 lanes A/B/C/D/E 已完成真实 ViewModel 运行、内联修复与重跑收口；最终 summary `ok=true` |
| `HFVV-05` | `completed` | 已完成 Wave 1 失败修复与重跑收口复核；确认无残留失败、无残留 `blocked_external`，不进入 Wave 2 |

---

## 10. HFVV-02 完成结论

1. 已新增高保真测试支撑层：
   - `apps/novel_agent_app/test/hfvv_viewmodel_harness_support.dart`
   - `apps/novel_agent_app/test/hfvv_viewmodel_harness_smoke_test.dart`
2. 新 harness 使用真实 `AppShellController` 公共入口驱动：
   - `initialize()`
   - `onCreateProjectRequested()`
   - `onProjectCreationSubmitted(...)`
   - `onSendRequested(...)`
3. smoke test 明确验证了四类 GUI 判定口径：
   - `pending tool`：`conversationEntries.toolLifecycleStatus=running`，且 `toolCoreStatus` 呈现流式工具执行文案。
   - `completed tool`：`conversationEntries.toolLifecycleStatus=completed`。
   - `failed tool`：`conversationEntries.toolLifecycleStatus=failed`。
   - `waiting_user`：`pendingOptions` 非空，且 `toolCoreStatus=等待选择`。
4. 证据已落地到 `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_02/`，包含：
   - `step_001_viewmodel.json` ~ `step_004_viewmodel.json`
   - 对应 `model_event` 与 `tool_events` 文件
   - `hfvv_02_smoke_summary.json`
5. 同步回归结果：
   - `flutter test test/hfvv_viewmodel_harness_smoke_test.dart`
   - `flutter test test/real_gui_viewmodel_information_long_task_probe_contract_test.dart`
6. 本轮未修改生产业务链路；修订范围限定在测试 harness、证据写出与 HFVV 文档回填。
7. 2026-06-13 补强：已用真实 provider 跑通普通分章续写 lane，证明 `HFVV-02` 的 production-same-source harness 也能承载“普通项目正式分章续写”这一更贴近真实用户的高保真闭环；详见 `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_02/hfvv_02_real_ordinary_chaptered_continuation_followup_2026-06-13.md` 与 `artifacts/high_fidelity_viewmodel_validation/2026-06-13T00-41-33-097775/lane_ordinary_chaptered_continuation/`。

---

## 11. HFVV-03 完成结论

1. 已新增 HFVV-03 语料预处理工具与 focused test：
   - `packages/novel_agent_adapters/lib/src/reference_extraction/reference_source_boundary_locator_service.dart`
   - `packages/novel_agent_adapters/test/reference_source_boundary_locator_service_test.dart`
   - `packages/novel_agent_adapters/tool/hfvv_prepare_source_assets.dart`
2. 已把三份输入复制到正式 artifacts，并在 `local/hfvv_source_assets/2026-06-10T01-35-42/utf8/` 写出后续 session 可直接消费的 UTF-8 临时副本。
3. `Re:Zero` 已通过 production 侧现有 reader 检测为 `gbk`，并稳定转写为 UTF-8；`Harry Potter.txt` 与 `Harry Potter - Volume 1 Raw.txt` 也被识别为 `gbk` 源并同步写出 UTF-8 副本。
4. `约 100 万字` 附近边界定位结果已落到 `source_asset_manifest.json`：
   - `Harry Potter.txt`：`chapter_end @ 1007085`，临近 `CHAPTER THREE / CHAPTER FOUR`
   - `Harry Potter - Volume 1 Raw.txt`：文本总长 `442815`，低于目标阈值，已明确标注 `below_target`
   - `re从零开始的异世界生活.txt`：`paragraph_break @ 999987`，距目标仅 `13` 字
5. 证据与报告已落地到 `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_03/`，包含：
   - `source_asset_manifest.json`
   - `hfvv_03_report.md`
   - `source_assets/original/`
   - `source_assets/utf8/`
   - `source_assets/excerpts/`
6. 验证结果：
   - `dart test test/reference_source_boundary_locator_service_test.dart`
   - `dart run tool/hfvv_prepare_source_assets.dart`
7. 本轮未修改 references 原文件，未启动任何 reference extraction / knowledge base / real provider 长流程。

---

## 12. 会话更新记录

- `HFVV-01`
  - 新建本台账。
  - 冻结 `run_id=2026-06-10T01-35-42`。
  - 确认并行 lanes、波次依赖、失败分类、产物目录与 rerun 规则。
  - 完成 API / 代理入口 / 语料存在性核查，但未打印任何 key，未启动真实测试，未修业务代码。
  - 为 run 根目录与每条 lane 补齐预算策略和标准启动模板，确保后续 session 可直接按 ledger 启动独立测试线。
  - 已同步主顺序文档中的完成记录，并为本轮 run 补齐验收审计与证据索引，便于后续 session 和独立复核直接消费。
- `HFVV-02`
  - 新增 `AppShellController` 级高保真 ViewModel harness，避免继续依赖底层 runtime probe 作为主入口。
  - 以 fake provider 跑通“新项目 -> 发送普通项目背景请求 -> pending tool -> waiting user”的最小闭环。
  - 已把会话条目、工具状态、资源树、长任务总站、项目文件与模型/工具事件摘要写入正式 artifacts 目录。
  - 已完成 focused smoke test 与相邻合同回归，未开启 `HFVV-03`。
  - 2026-06-13 已补充真实普通分章续写真机验证：普通项目正式分章续写会按 `chapter` 任务进入 activation report，能选中上一章交付摘要与章末锚点，正式 delivery sidecar 含 handoff，且字数窗口通过生产链 gate 收口。
- `HFVV-03`
  - 新增通用文本边界定位 service，并用 focused test 锁定 chapter / paragraph / below-target 三类定位口径。
  - 已复制 Harry Potter 与 Re:Zero 源文本到 HFVV-03 artifacts，并写出 local UTF-8 临时副本供后续 lanes 直接消费。
  - 已检测并转换 Re:Zero 编码，同时记录 `Harry Potter.txt` / `Harry Potter - Volume 1 Raw.txt` 的实际 decode 模式。
  - 已在约 100 万字附近为后续消费线和拆书续写线落下可复用边界与 excerpt 证据。
  - 已完成脚本运行与报告回填，未开启 `HFVV-04`。
- `HFVV-05`
  - 已复核 `HFVV-04` 最终 Wave 1 summary 与 lanes A/B/C/D/E 终态报告，确认五条 lane 全部 `ok=true`、`report_category=success`、`failure_count=0`。
  - 已确认 Wave 1 真实失败的生产链修复、focused regression 与 rerun 闭环都已在 `HFVV-04` 收口完成，本 session 不再新增业务代码改动。
  - 已新增 `hfvv_05_acceptance_audit.md` 并更新证据索引、主顺序文档与本台账。
  - 已按 session 边界停在 `HFVV-05`，未开启 `HFVV-06`。

---

## 13. HFVV-04 完成结论

1. Wave 1 五条主线已全部完成最终 green rerun：
   - `lane_a_ordinary_information_before_writing`
   - `lane_b_ordinary_multi_agent`
   - `lane_c_user_side_knowledge_base`
   - `lane_d_book_import_knowledge_base`
   - `lane_e_network_knowledge_base`
2. 最终总报告：
   - `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_04_wave1_summary.json`
   - `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_04_wave1_summary.md`
   - 结果为 `ok=true`
3. 关键验收信号：
   - Lane A：`has_research_evidence=true`、`wrote_chapter_directly=false`，并落出 `chapters/information_risk_assessment.md`
   - Lane B：存在真实 `sub_agent_runs`
   - Lane C：`answer_has_expected_anchors=true`、`absolute_source_path_leak_detected=false`
   - Lane D：`answer_anchor_count=4`、`absolute_source_path_leak_detected=false`
   - Lane E：`has_network_knowledge_evidence=true`、`fake_success_detected=false`
4. 本轮收口同时确认了 Wave 1 所需的 production-path 修复已经进入当前工作树，并通过 focused regression 与真实 rerun 验证，没有把失败藏在 probe 内。
5. 本 session 验收审计已落地：
   - `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_04_acceptance_audit.md`
6. 按 session 边界约束，本轮只确认 `HFVV-04`，不自动进入 `HFVV-05`。

---

## 14. HFVV-05 完成结论

1. 已以 `HFVV-05` 口径复核 Wave 1 终态证据：
   - `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_04_wave1_summary.json`
   - lanes `A/B/C/D/E` 各自的 `lane_report.json`
2. 复核结果确认：
   - Wave 1 最终总报告为 `ok=true`
   - lanes `A/B/C/D/E` 全部 `ok=true`
   - lanes `A/B/C/D/E` 全部 `report_category=success`
   - lanes `A/B/C/D/E` 全部 `failure_count=0`
   - final acceptance state 不存在残留 `blocked_external`
3. `HFVV-05` 所要求的“分类、修生产链路、补 focused tests、重跑失败 lane”在本 run 中已经由 `HFVV-04` 的真实修复与重跑闭环满足；本 session 的职责是正式确认这一闭环已完成，而不是重复触发新一轮真实测试。
4. 本 session 未新增业务代码改动；原因是 authoritative Wave 1 证据已经证明修复后的生产链和 rerun 结果满足验收标准。
5. 本 session 验收审计已落地：
   - `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_05_acceptance_audit.md`
6. Wave 1 现已正式收口；按 session 边界约束，`HFVV-06` 及以后仍保持未开始。
