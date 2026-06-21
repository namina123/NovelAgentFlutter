# 全量完成度与设计落差审计

最后更新：2026-06-22

关联文档：

- `docs/important/responsibility-boundary-freeze-map-2026-06-17.md`
- `docs/important/responsibility-boundary-refactor-handoff-2026-06-17.md`
- `docs/important/project-unreasonable-areas-audit-2026-06-15.md`
- `docs/important/product-design-ui-audit-2026-06-18.md`
- `docs/important/global-ui-freeze-root-cause-analysis-2026-06-19.md`
- `docs/important/global-ui-freeze-remediation-session-order-2026-06-19.md`
- `docs/important/user-facing-development-leftovers-followup-audit-2026-06-16.md`
- `docs/记录.md`

---

## 1. 这份文档的目的

在 2026-06-15 到 2026-06-20 多轮专项审计之后，本轮做一次**面向“当前代码实际能做到什么”的全量复核**，回答一个问题：

**这个项目看起来很大，实际上有多少能力是真正端到端可用的？**

本轮不再只看“设计文档说了什么”，而是直接读代码，逐个功能判定它处于 `COMPLETE / PARTIAL / BROKEN / OFF-TARGET` 哪一档，并给出文件级证据。

---

## 2. 一句话总判断

**项目在“合同层 / 数据层 / 策略层”普遍过度建设，却在“执行边界”系统性欠接线。**

具体表现是一个贯穿所有主功能的统一病灶：

1. 服务、策略、账本、JSON schema、freeze map 都已经写出来，看起来很完整。
2. 但让这些能力“真正咬合”的最后一跳——恢复重入、watchdog 启动、自动建 repair task、默认约束装载、runtime_profile.json 读取、embedding 检索实现——普遍缺失。
3. 于是功能在截图里像完成品，在真实使用里要么报错、要么静默回退、要么只是提示词层“口头执行”。

这正是用户反馈“看起来很大，实际上未完成；每种功能都或多或少不符合目标、难用、功能不全”的根因。

---

## 3. 未达成最后一次设计（文档说完成、代码未完成）

### 3.1 RBR 职责边界冻结只有约 40% 落到代码

`responsibility-boundary-refactor-handoff-2026-06-17.md` 声称 `RBR-01..15 已全部完成`，但代码核对发现 8 个冻结真相源里只有 3 个真正收口，4 个仍在漏业务逻辑：

| # | 真相源 | 现状 | 证据 |
| --- | --- | --- | --- |
| 1 | 开局真相源 | 仍在漏 | [workbench_conversation_controller.dart:1328-1346](../../apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart#L1328) 仍手写 `guide.create_workflow_from_mode_guidance` / `opening.start_long_task_run` 分支，且对 `OpeningOrchestrationService` 零引用 |
| 2 | 工具暴露真相源 | 仍在漏 | [project_conversation_draft_runtime_service.dart:219-235](../../packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart#L219) 自行重算暴露并拦截 `call_sub_agent`，绕过 resolver；[generate_draft_use_case.dart:596-602](../../packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart#L596) 叠了第二层过滤 |
| 3 | 子智能体调度真相源 | 仍在漏 | [tool_strategy_prompt_builder.dart:31-101](../../packages/novel_agent_core/lib/src/tools/tool_strategy_prompt_builder.dart#L31) 重新基于 `delegation.allowed` 选不同规则集 |
| 4 | 审核调度真相源 | 已收口 | app 层已无委派逻辑，[project_workflow_runtime_service.dart:4103](../../packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart#L4103) 委派给 dispatch service |
| 5 | 路径产物真相源 | 混合 | app 层已薄，但 [project_workflow_runtime_service.dart:694](../../packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart#L694) 等处仍硬拼 `tracking/*` 命名 |
| 6 | 会话恢复真相源 | 已收口 | shell 只转发到 `WorkbenchConversationController.restoreProjectSessions` |
| 7 | 拆书导入真相源 | 已收口 | 无“导入时临时问后续类型”的并行链 |
| 8 | provider/model 真相源 | 仍在漏 | [app_shell_controller.dart:853](../../apps/novel_agent_app/lib/app/state/app_shell_controller.dart#L853) 直接 new validation service，`:1497`/`:4676` 自行判活、列表注入 `__new__` |

### 3.2 “Facade” 名不副实

`responsibility-boundary-refactor-handoff` 声称 `ProjectWorkflowRuntimeService` 已“朝 facade 方向退化”，但它仍是 5256 行。其中：

- `runWorkflowTaskOnce` 占 1130–2586 行（约 1456 行），是真正的执行引擎。
- `_handleRetryableWorkflowTaskTransportFailure` 自算重试预算并按 `isPlanning`/`isFormalChapter` 分叉，是本应属于 `LongTaskRunLifecycleService` 的兜底策略。
- `_planningTaskBoundaryDecision`（2586–2847）是一个住在“facade”里的状态机。
- 仍内联 `tracking/` 路径插值与 `_persistExecutionOutputPaths` 等 I/O。

结论：这是一个“挂着委托表面的巨石”，不是退化后的 facade。

### 3.3 UI 卡死治理只做了一半

`global-ui-freeze-remediation-session-order-2026-06-19.md` 记录的 GF-05..08 是真的落地的：页面驻留（`Offstage`+缓存）、页面不再自刷新、`Isolate.run` 扫描、`UiStallProbe`/`NavigationTrace`/`HydrationTrace` 都已接线。但两条最深的结构建议没做：

1. **§9.2 项目生命周期协调器抽离未做。** [project_lifecycle_coordinator.dart](../../apps/novel_agent_app/lib/app/state/project_lifecycle_coordinator.dart) 只有 147 行，只是默认恢复/路径打开的策略包装；真正的 hydration 状态机和 12 处 `_recordProjectHydrationWrite` 仍内联在 [workbench_workspace_controller.dart:349-660](../../apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart#L349)。
2. **壳层仍是瓶颈且变更大。** `AppShellController` 从 5076 行涨到 **5236 行 / 166 个方法**，`_safeNotifyListeners()` 从 21 处被调用。GF 把扫描 runtime、trace、生态刷新等新接线**塞进了**这个巨石，而不是拆解它。

---

## 4. 未实现（已设计或已暴露入口，但功能不闭环）

### 4.1 P0：长任务总站（头号卖点）核心能力是坏的

- **恢复只是装饰。** [long_task_supervisor.dart:98-110](../../packages/novel_agent_adapters/lib/src/workflow/long_task_supervisor.dart#L98) 的 `resumeRun` 只把 `paused -> running`，**不再进入** `runWorkflowTaskQueue`，暂停/崩溃后的多章续跑无法继续。
- **Watchdog 生产环境从不启动。** [adapter_bundle.dart:117-123](../../packages/novel_agent_adapters/lib/src/workflow/adapter_bundle.dart#L117) 注入了它，但 `watchdog.start()` 只在测试里被调用；[long_task_watchdog.dart:40-48](../../packages/novel_agent_adapters/lib/src/workflow/long_task_watchdog.dart#L40) 的陈旧任务探测在运行时是空转的。
- **是有界批次，不是连续运行。** 循环 `while (stepsRun < max_steps)`，默认 3（[project_workflow_queue_runtime_service.dart:582](../../packages/novel_agent_adapters/lib/src/workflow/project_workflow_queue_runtime_service.dart#L582)）；叠加 resume 不重入，所谓“无人值守”跑一批就停。
- **runtime_profile.json 仍未在起任务时读取。** `apps/` 下所有 `runtime_profile` 引用读的都是内存 model 映射，不是设置文件；[记录.md:7](../记录.md) 自己承认这是 TODO。

### 4.2 P0：RAG 检索不是语义检索

- `retrieve_rag_passages` 工具已接，GUI 也真的能提取/挂载语料，但**全仓库没有任何** `RetrievalSearchPort` / `EmbeddingProviderPort` / `RetrievalIndexPort` 实现；`EmbeddingProviderPort.embedTexts` 从未被调用。
- dispatcher 在构造执行器时**不带 search port**，于是静默回退到 `_lexicalSearch`——纯子串/词频打分（[project_rag_retrieval_tool_executor.dart:131-151](../../packages/novel_agent_adapters/lib/src/tools/project_rag_retrieval_tool_executor.dart#L131)）。
- provider kind 字面量就是 `localPlaceholder` / `remotePlaceholder`（[rag_retrieval_provider_contracts.dart:3-6](../../packages/novel_agent_core/lib/src/tools/rag_retrieval_provider_contracts.dart#L3)）。
- `rag-retrieval-contract-draft-2026-06-17.md` 自称“已经按这份合同收口”——**夸大**。智能体拿到的是关键词命中，不是 embedding 召回。

### 4.3 P0：多模态/附件输入全线阻断

- [openai_attachment_bridge_policy.dart:57](../../packages/novel_agent_adapters/lib/src/providers/openai_attachment_bridge_policy.dart#L57) 与 `:81` 对任何非平凡附件返回 `isRequestSupported: false`（“桥接尚未实现”）。
- OpenAI 全家族 + Anthropic 的 payload builder 都经此 policy，于是用户附件一旦过了能力检查就抛 `UnsupportedError`——**硬错误，不是不发送**。
- UI 附件选择入口存在（`app_shell_controller.dart:5136`），但发任何图片/文件给视觉模型都会失败。

### 4.4 P1：审核/返工只是建议，不阻塞

- `auto_create_repair_task` 标志是**死的**——没有任何 adapter 在审核流水线里调用 `ProjectReviewReportService.createReviewRepairTask`。
- `blocks_next_chapter_until_gate_passed` 只存在于策略数据，没有执行代码读它来停调度器。
- 唯一咬合的是提交边界里的 `applyReviewOutcome` 硬失败；其上的策略层/repair 层全部非阻塞。[记录.md:5](../记录.md) 写的“下一步最自然的就是把 adapter 侧也接上”——半完成：决定了，但没执行。

### 4.5 P1：表达约束 / 连续性是纯提示词层

- 默认表达约束**不会自动装载**——[generate_draft_use_case.dart:188-189](../../packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart#L188) 默认空数组；全仓搜 `loadExpressionConstraint|defaultExpressionConstraint` 零命中，resolver 直接返回 `applied: false`。
- 约束只渲染成提示词文本，**没有任何后置校验/正则拦截/重生成**。强制力完全靠 LLM 自我遵守。
- 连续性只 `requiresManualAttention`，全 `continuity/` 搜不到 `enforce|hardGate|blockChapter|veto`——从不阻断章节。
- [long_task_chapter_gate_disposition_service.dart:15-28](../../packages/novel_agent_core/lib/src/workflow/long_task_chapter_gate_disposition_service.dart#L15) 除非 `runtimeBaselineId == 'chapter_collaboration_autorun'` 否则一律 `auto_continue`——除这一个窄基线外，所有运行时忽略约束违反。

### 4.6 其他未实现项

| 级别 | 项 | 证据 |
| --- | --- | --- |
| P1 | “停止”不能真正中断生成 | [workbench_conversation_controller.dart:786-805](../../apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart#L786) 注释“真实中断留给后续链路接通” |
| P1 | Gemini 原生协议无运行时 | [provider_interface_template_seed.dart:72](../../packages/novel_agent_adapters/lib/src/providers/provider_interface_template_seed.dart#L72) “运行时协议合同将在后续 session 正式接入” |
| P1 | RAG 结构化/混合提取是占位 | [project_rag_extraction_execution_service.dart:119-125](../../apps/novel_agent_app/lib/features/project_assets/application/services/project_rag_extraction_execution_service.dart#L119) 返回“暂未开放实现” |
| P2 | host capability port 是死桩 | [default_host_capability_port.dart:7](../../packages/novel_agent_adapters/lib/src/host/default_host_capability_port.dart#L7) 抛 `UnimplementedError`，全仓无实例化 |
| P2 | ZIP 导出未做 | 仅目录导出；`local_project_file_mutation_adapter.dart:89` 注“后续 zip 导出只需替换这一层” |
| P2 | Docker / TUI 未做 | 仅有可行性分析文档，无代码 |

---

## 5. 不易用（用户会真实撞到的体验问题）

1. **设置页“测试连接”是假按钮（P0 信任问题）。** [provider_connection_validation_service.dart:25](../../apps/novel_agent_app/lib/features/settings/application/services/provider_connection_validation_service.dart#L25) 与 `:109` 明确“不会直接发起联网请求”，只做本地表单形状校验。错的 key / 死的 URL 仍返回绿勾。用户无法在应用内确认一个 provider 真的能用。
2. **作品库打开无页面内反馈。** `_announce('正在打开项目...')` 写进的是 workbench view model，作品库页从不读它；冷启动还会短暂显示“还没有作品”空态，无法区分“加载中”与“真空”。
3. **作品库没有删除/派生动作。** `project_open_action_handler` 只有 open/create/import/refresh/select；删除只能去文件系统。
4. **存储策略被迫塞进所有项目类型创建流。** [project_creation_phase_resolver_service.dart:27](../../apps/novel_agent_app/lib/features/project_creation/application/services/project_creation_phase_resolver_service.dart#L27) 无条件插入 `storageStrategy` 阶段——新人写小说前先选 Markdown vs SQLite 后端，与 PRODUCT.md“低认知负担”相悖。
5. **窄屏布局仍挤。** 无纵向 reflow，无 `Orientation`/`MediaQuery` 分支。
6. **开局引导是机械模板。** [conversation_opening_guide_view_data_service.dart:81-231](../../apps/novel_agent_app/lib/features/workbench/application/services/conversation_opening_guide_view_data_service.dart#L81) 按项目类型硬编码字符串列表，不随真实状态自适应。
7. **半成品入口伪装成可用按钮。** 提示词优化链只 `_announce('当前先直接发送自然语言需求…')`（[workbench_conversation_controller.dart:750-753](../../apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart#L750)）；生成完成但 `writtenPaths` 为空且关掉 fallback 时，只提示“内容生成完成，尚未保存到项目目录”却不给保存动作（`:1822-1840`）。
8. **epub 导入脆弱。** 异常只回 `"读取源文件失败：$error"`，无重试/部分恢复。
9. **死功能膨胀了表面。** `review_center` 已从导航退役（只剩重定向 shim，[app_shell_destination_controller.dart:103-106](../../apps/novel_agent_app/lib/app/state/app_shell_destination_controller.dart#L103)），整目录孤儿；`settings_placeholder_panel.dart`（0 调用点）、`development_settings_panel.dart`（无 dev tab）仍在树里。
10. **入口套入口。** task_center 藏在 long_task_station 的工具栏按钮里（`long_task_station_page.dart:39-40`）。
11. **残留工程语。** [context_settings_panel.dart:141](../../apps/novel_agent_app/lib/features/settings/presentation/widgets/context_settings_panel.dart#L141) 仍可见“预留输出额度（token）”、`tool_strategy_settings_panel.dart:95` “允许 fallback 工具 JSON”等。

---

## 6. 不合理（结构性）

1. **巨石控制器仍在膨胀。** `app_shell_controller.dart` 5236 行 / 166 方法、`workbench_workspace_controller.dart` 2407 行、`workbench_conversation_controller.dart` 2286 行、`project_workflow_runtime_service.dart` 5256 行。`architecture.md` 自己规定“单文件超 700 行除生成文件必须拆分”——多个核心文件远超且持续变大。
2. **全局通知单点。** 21 处 `_safeNotifyListeners()` 共用一个壳层出口，任意域动作都会扩散到整壳。
3. **“假绿”模式。** 假测试连接 + 词汇回退冒充 RAG，是同一类病症：给用户“能用”的信号，实际什么都没做。这恰恰是 PRODUCT.md“可靠”承诺的反面。
4. **死代码/孤儿目录残留** 让“功能很多”的观感虚高。

---

## 7. 测试 / 构建健康度

- [记录.md](../记录.md) 点名的 3 条既有失败测试**仍在仓库**：`openai_llm_gateway_test.dart`、`project_tool_dispatcher_path_test.dart`、`agent_services_test.dart`（core 的标签归一化预期不一致）。
- `packages/novel_agent_adapters/lib` 仍有 10 处 `TODO/Unimplemented/未实现/待实现` 标记，`apps/novel_agent_app/lib` 3 处。
- Windows debug 包可编译；Android release 因 UFDL-03 设计不配 signing 而**有意失败**（非回归）。

---

## 8. 优先级收束（按“先堵用户血洞”排序）

### 必须最先收（用户会直接撞坏或被误导）

1. **长任务 resume 真正重入队列 + watchdog 生产启动**——否则头号卖点“连续写作”跑一批就停、崩了不能续。
2. **RAG：要么真接 embedding 检索，要么在 UI 明确降级表述**——当前“静默回退成关键词搜索”是对用户的隐性欺骗。
3. **多模态附件：要么实现桥接，要么在入口禁用**——现在是“能选不能发，发了硬报错”。
4. **设置页测试连接改成真联网（或改名“检查格式”）**——假绿勾直接破坏信任。
5. **runtime_profile.json 在 GUI/CLI 启动长任务时真正读取。**

### 紧随其后（让设计真正咬合）

6. 审核 `auto_create_repair_task` / `blocks_next_chapter` 真正接入执行边界。
7. 默认表达约束自动装载 + 至少一层非提示词强制。
8. RBR 剩余 4 个漏逻辑真相源（开局/工具暴露/子智能体/provider）真正收成单一出口，而不是停在 freeze 文档。
9. 抽离 `ProjectHydrationRuntime`，让 hydration 不再住进 workbench controller。
10. 拆 `AppShellController` 与 `project_workflow_runtime_service` 两块巨石（至少先把执行引擎从 facade 里抽出去）。

### 持续清扫

11. 删死代码（review_center 目录、settings_placeholder_panel、development_settings_panel）。
12. 作品库补删除/派生 + 打开反馈；存储策略退出默认创建流。
13. 半成品入口统一改成禁用或自然引导，不再用 `_announce` 文案冒充功能。
14. 收尾 3 条既有失败测试与残留工程语。

---

## 9. 最终结论

当前项目的核心问题**不是“功能太少”，也不是“某一个 bug”**，而是一种系统性落差：

**合同层和数据层已经写到“看起来完成”，但执行边界普遍没接上；同时多份交接文档把“已设计 / 已冻结 / 已收口”写成了“已完成”，夸大了真实完成度。**

这会同时造成三类代价：

1. 用户在每个主功能上都会或早或晚撞到“看起来能用、实际不行”。
2. 后续开发者会被文档误导，以为某条链已经稳定，于是在沙地上继续盖楼。
3. 验收成本极高，因为必须逐入口、逐项目类型、逐运行时实地试。

下一阶段最值得做的，不是再横向堆能力，而是**把已经画出来的合同逐条接到执行边界上，并把交接文档里“已完成”的表述校正到与代码一致**。
