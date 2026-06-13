# NovelAgentFlutter 发布收口与产品化任务顺序文档

最后更新：2026-06-05

主线代号：`RRP`（Release Readiness Productization）

关联分析文档：

- `docs/release-readiness-gui-core-consolidation-analysis-2026-06-05.md`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `docs/project-information-substrate-session-order-2026-06-05.md`
- `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md`
- `docs/skill-loadout-redesign-session-order.md`
- `docs/agent-group-opening-redesign-session-order.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `agent.md`

关联代码锚点：

- `packages/novel_agent_core/lib/src/workflow/`
- `packages/novel_agent_core/lib/src/runtime/`
- `packages/novel_agent_core/lib/src/information/`
- `packages/novel_agent_core/lib/src/agents/`
- `packages/novel_agent_core/lib/src/creative/`
- `packages/novel_agent_core/lib/src/tools/domain/`
- `packages/novel_agent_adapters/lib/src/workflow/`
- `packages/novel_agent_adapters/lib/src/runtime/`
- `packages/novel_agent_adapters/lib/src/tools/`
- `packages/novel_agent_adapters/lib/src/storage/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/long_task_station/`
- `apps/novel_agent_app/lib/features/agent_ecosystem/`
- `apps/novel_agent_app/lib/features/book_deconstruction/`
- `apps/novel_agent_app/lib/features/settings/`
- `apps/novel_agent_app/lib/app/theme/`
- `apps/novel_agent_app/lib/app/navigation/`

---

## 1. 这份文档解决什么

这份文档把“当前功能做成可实际发布软件”拆成可执行任务。它不再追求继续堆新能力，而是围绕两条近期主线收口：

1. **真实长链稳定性。** 普通项目、长任务、拆书续写都必须在章节交付、字数策略、表达限制、信息激活、失败恢复上走共享底座，不再依赖探针事后判断。
2. **信息 / 资料 / 巧思 / 拆书资产可用。** 结构化 information 合同、用户可读投影、智能体工具、上下文激活和 GUI 回看必须闭环，让资料真的能被保存、激活、引用和确认。

同时，本主线补齐发布必须的产品化收口：

1. GUI 默认路径更像小说软件，而不是工程控制台。
2. 长任务总站展示用户能理解的运行状态和恢复动作。
3. 多智能体从“已有对象和局部测试”推进到可证明的一主多子运行闭环。
4. 智能体组、技能组、智能体、技能继续通过专门设置 / 生态入口编辑，不进入写作主面板抢主流程。
5. 技能、权限、模型策略、约束、提示资源的关系通过合同解析，不在 UI、CLI 或 probe 里硬拼。
6. 视觉、字体、发布包、探针残留、密钥风险完成发布收口。

---

## 2. 与旧文档的关系

### 2.1 ONS / PIS / SL / AG 是底座，不重做

已有主线已经完成或基本完成：

- ONS：开放叙事状态、领域 toolcall、章节交付状态机、上下文激活、GUI/CLI 最小消费。
- PIS：information 合同、knowledge / design / research / reference、投影、激活桥、拆书桥。
- SL：skill / skill_group / skill_loadout 三层语义、项目级装载、历史快照、运行态消费。
- AG：项目级智能体组选择、opening、starter groups、长任务启动闭环。

本主线不复制这些实现，而是做三件事：

1. 审计已有实现是否真的进入普通项目、长任务、拆书、GUI 路径。
2. 补齐缺失的运行桥、权限守卫、失败恢复、可视化投影。
3. 做真实 provider、GUI 和发布包验收。

### 2.2 参考项目只吸收通用思想

继续只吸收：

- 后台任务可观察。
- 章节上下文分层。
- 角色 / 世界 / 伏笔 / 资料 / 巧思作为工程资料。
- 拆书导入后继续服务写作。
- 多智能体专家协作、模型槽位、工具权限 profile、任务恢复。

不复制任何参考项目代码、字段、文案、许可证风险和题材化结构。所有“快穿、死亡回归、多世界”等仍只是压力输入，不能进入 core 分支。

### 2.3 本文档与分析文档的差异

分析文档回答“哪里不够产品化、哪里有风险”。本文档回答“按什么顺序做完”。如果分析文档中某项没有对应 session 覆盖，应视为本文档缺陷，需要补 session 或合并到相邻 session。

---

## 3. 已有实现去重审计

### 3.1 已有，不重做

1. 章节交付与状态：
   - `ChapterDeliveryStateMachine`
   - `submit_chapter_delivery`
   - `ProjectConversationDraftRuntimeService` 的 formal delivery guard
   - `ProjectWorkflowRuntimeBridgeService.latestChapterDeliveryOutcome`

2. 长任务底座：
   - `LongTaskSupervisor`
   - `LongTaskRunStateMachine`
   - `LongTaskRecoveryService`
   - `LongTaskRunCenterContractService`
   - `ProjectLongTaskStationDetailService`

3. 信息层底座：
   - `ProjectKnowledgeCard`
   - `DesignElementCard`
   - `ResearchNote`
   - `ReferenceWorkRecord`
   - `InformationLink`
   - `InformationEvent`
   - `ProjectInformationActivationBridgeService`
   - `ProjectInformationProjectionWriterService`

4. 智能体与技能底座：
   - `AgentProfile`
   - `AgentGroupCatalogService`
   - `SkillGroupCatalogService`
   - `AgentSkillLoadoutResolverService`
   - `ProjectAgentSkillRuntimeLoadoutService`
   - `SubAgentRunPackageService`
   - `SubAgentExecutionService`
   - `SubAgentResultPackageService`

5. GUI 已有入口：
   - workbench opening / agent group picker
   - agent ecosystem page
   - project skill loadout detail panel
   - long task station
   - book deconstruction panels
   - settings model/provider panels

### 3.2 已有但不完整

1. 长任务稳定性：有 supervisor 和 delivery state，但真实长链仍需证明，并且失败原因要区分技术失败、等待用户、预算失败、内容质量失败。
2. 信息激活：有结构化卡片和 activation bridge，但真实模型是否自然提交和复用还需要 GUI / provider 验收。
3. 多智能体：有 sub-agent 包和工具执行，但 child-specific model / tool policy、预算退化、冲突仲裁、GUI 选择进入运行链仍需证明。
4. 技能生态：已有 loadout 和项目编辑，但不够好用；内置 / 非内置、技能生成草案、能力需求与权限兼容检查还需收口。
5. GUI 主路径：功能多，但入口仍偏工程控制台；默认路径、术语、长任务详情、主题字体需要发布级收口。
6. 发布资产：探针、真实 API 配置、参考项目、截图字体、打包脚本仍需最后检查。

### 3.3 真正要补的层

1. Core：共享写作运行结果、失败分类、协作预算、权限守卫、冲突仲裁。
2. Adapters：runtime bridge、supervisor 消费共享状态、项目快照与投影、provider 连接测试。
3. Workflow：普通项目 / 长任务 / 拆书统一消费交付、约束、信息、协作结果。
4. App：用户可理解 projection、主路径、生态设置、长任务总站、视觉字体。
5. Probe / regression：只消费 production 同源合同，先 mock 后真实 provider。
6. Packaging / documentation：发布包隔离、密钥扫描、用户文档与开发文档分层。

---

## 4. 本轮冻结的架构边界

1. 不新增平行 runtime；优先复用现有 core / adapters / app 合同。
2. 不把普通项目、长任务、拆书做成三套私有稳定性逻辑。
3. 不把题材、流派、特殊剧情机制写进 core 分支。
4. 不把技能等同于工具权限；技能是方法和上下文能力，权限由 tool / permission profile 决定。
5. 不把智能体组、技能组、智能体、技能编辑搬进写作主面板；它们属于专门设置 / 生态入口。
6. 资产来源只区分内置 / 非内置。非内置包括用户产生、导入或复制改造，不再拆成多个一级来源。
7. AI 生成技能只能是非内置草案 / proposal，不能直接变成可信正式技能。
8. GUI / CLI 不承担底层合同补洞，不拼业务 JSON，不解释 provider 私有字段。
9. Probe 不形成第二套业务判定，不硬编码真实 key、固定模型、用户绝对路径。
10. 新增文件继续遵守 `agent.md` 的解耦、文件体量和项目整洁性约束。

---

## 5. 目标终态

完成所有 session 后，项目应达到：

1. 用户能从 GUI 走通：首次配置模型 -> 新建作品 -> 写第一章 -> 续写 -> 查看资料 -> 启动短长任务 -> 恢复任务。
2. 普通项目、长任务、拆书续写共享章节交付、字数策略、表达限制、信息激活、失败恢复。
3. 长任务能用真实 provider 跑短中长三档验收，失败时能解释、重试、降级或等待用户。
4. information 资料、巧思、拆书资产能被结构化保存、用户回看、智能体复用，并有来源 / 生命周期 / 证据。
5. 多智能体能证明：GUI 选择的协作组进入运行链，子智能体隔离上下文，child model/tool policy 生效，结果合并回主链，失败可恢复。
6. 智能体组、技能组、智能体、技能通过专门生态入口管理；主面板只展示当前协作摘要和结果。
7. 非内置技能默认低权限；技能生成草案必须经过校验和用户确认。
8. GUI 默认隐藏内部术语，诊断信息折叠到高级 / 开发视图。
9. 中文字体、主题、按钮文本、长文本布局达到发布质量。
10. 发布包不包含探针产物、真实 key、参考项目和本地配置。

---

## 6. Session 数量与顺序设计理由

本主线安排 30 个 session。顺序不是按页面拆，而是按依赖关系拆：

1. `RRP-01 ~ RRP-08`：先收口共享稳定性和信息激活，避免后续 GUI 只是在坏链路上做包装。
2. `RRP-09 ~ RRP-16`：补多智能体、技能、权限、非内置草案等核心合同和 adapter 接线。
3. `RRP-17 ~ RRP-23`：做用户可理解 projection、主路径、长任务总站、资料资产、拆书后续、生态设置。
4. `RRP-24 ~ RRP-27`：主题字体、探针归档、打包、CLI 最小边界。
5. `RRP-28 ~ RRP-30`：mock / GUI / real provider 验收和最终交接。

每个 session 都应在一次会话内完成；若发现某 session 超过约 2000 行主要逻辑，应先拆服务或拆测试，不允许塞进大 controller / runtime service。

### 6.1 设计目标覆盖矩阵

1. 真实长链稳定性：
   - `RRP-02`、`RRP-03`、`RRP-04`、`RRP-05`、`RRP-06`、`RRP-29`

2. 普通项目 / 长任务 / 拆书共享写作底座：
   - `RRP-02`、`RRP-04`、`RRP-08`、`RRP-15`

3. information / 资料 / 巧思 / 拆书资产可保存、激活、回看：
   - `RRP-07`、`RRP-08`、`RRP-20`、`RRP-21`、`RRP-29`

4. 多智能体真实分工、隔离、合并、恢复：
   - `RRP-09`、`RRP-10`、`RRP-13`、`RRP-14`、`RRP-15`、`RRP-23`

5. 智能体组、技能组、智能体、技能的专门生态入口与安全配置：
   - `RRP-11`、`RRP-12`、`RRP-16`、`RRP-22`

6. 用户暴露协议与 GUI 主路径产品化：
   - `RRP-16`、`RRP-17`、`RRP-18`、`RRP-19`、`RRP-20`、`RRP-21`、`RRP-22`

7. 视觉、字体、主题、发布包和安全残留：
   - `RRP-24`、`RRP-25`、`RRP-26`

8. CLI 边界、自动化验收、真实 provider 验收、最终交接：
   - `RRP-27`、`RRP-28`、`RRP-29`、`RRP-30`

如果后续发现某一类目标没有被以上 session 实际完成，应先补同层 session 或调整相邻 session，不允许把遗漏目标推给最终 GUI/CLI 接线兜底。

---

## 7. 任务顺序

### Session RRP-01：发布收口基线审计与缺口锁定

层级归属：Documentation / regression planning / code audit

本轮目标：

- 建立本主线的可执行基线，确认哪些能力已实现、哪些只是半成品、哪些需要后续 session 真补。

必读文件：

- `docs/release-readiness-gui-core-consolidation-analysis-2026-06-05.md`
- `docs/release-readiness-productization-session-order-2026-06-05.md`
- `agent.md`
- `docs/project-information-substrate-implementation-audit-2026-06-05.md`
- `docs/project-information-substrate-mock-regression-suite-2026-06-05.md`

必须完成：

1. 检查本任务文档与实际代码锚点是否一致。
2. 生成或更新一份简短审计记录，列出 RRP 主线当前已实现、半成品、缺失项。
3. 确认后续 session 是否需要调整顺序，若需要只改本文档的顺序说明和完成记录，不改代码主线。
4. 运行低成本静态检查或 focused tests，记录可用基线。

本轮不要做：

- 不修大量业务代码。
- 不开启真实 provider 探针。
- 不新增 GUI 页面。

验收标准：

- 有明确的 RRP baseline 记录。
- 后续 session 无明显重复旧主线实现。
- 工作区未新增临时探针残留。

直接可用提示词：

```text
根据 `docs/release-readiness-productization-session-order-2026-06-05.md` 执行 Session RRP-01。只做发布收口基线审计与缺口锁定：核对分析文档、任务顺序文档、agent.md 和当前代码锚点，生成/更新简短 baseline 记录，运行低成本 focused 检查。不要修大量业务代码，不开启真实 provider 探针，不做 GUI 页面。完成后只确认 RRP-01，并写入本 session 完成记录；不要开启 RRP-02。注意解耦合、单一职责、项目整洁性。
```

### Session RRP-02：共享写作运行结果合同

层级归属：Core / domain

本轮目标：

- 定义普通项目、长任务、拆书续写共用的写作运行结果合同，让 delivery、constraints、information、collaboration、recovery 可以统一投影。

必读文件：

- `packages/novel_agent_core/lib/src/workflow/chapter_delivery_state_result.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_result.dart`
- `packages/novel_agent_core/lib/src/continuity/context_activation/context_activation_report.dart`
- `packages/novel_agent_core/lib/src/agents/sub_agent_result_package_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_recovery_service.dart`

必须完成：

1. 新增或补齐共享 result / summary 合同，覆盖章节交付、字数、表达限制、信息激活、协作、恢复建议。
2. 保持合同为 core 纯 Dart，不依赖 adapters / Flutter。
3. 补 codec / normalizer / focused tests。
4. 不替换全部 runtime 调用点，只提供稳定合同给后续 session 消费。

本轮不要做：

- 不改 GUI。
- 不改真实 provider 调用。
- 不把合同做成巨型 god object；内部要拆子合同。

验收标准：

- core tests 证明合同能表达 success / recoverable failure / user action required / content quality issue。
- 普通项目和长任务都能用同一合同类型描述结果。

直接可用提示词：

```text
根据 `docs/release-readiness-productization-session-order-2026-06-05.md` 执行 Session RRP-02。只做共享写作运行结果合同：在 core 层定义/补齐普通项目、长任务、拆书续写共用的 result/summary 子合同，覆盖 delivery、constraints、information、collaboration、recovery，并补 codec/normalizer/focused tests。不要接 GUI，不改真实 provider，不开启下一任务；避免 god object，拆清子合同，单文件过重必须拆分。完成后写入 RRP-02 完成记录。
```

### Session RRP-03：章节交付与恢复状态硬化

层级归属：Core / workflow

本轮目标：

- 让空正文、标题-only、路径漂移、字数严重偏离、表达限制缺失都进入明确交付状态，而不是只靠探针事后发现。

必读文件：

- `packages/novel_agent_core/lib/src/workflow/chapter_delivery_state_machine.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_delivery_state_request.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_length_evaluation.dart`
- `packages/novel_agent_core/lib/src/creative/expression_constraint_review_projection.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`

必须完成：

1. 审计 state machine 是否覆盖空正文、标题-only、正文过短、路径漂移、缺 evidence。
2. 补齐缺失状态和原因码。
3. focused tests 覆盖普通项目和长任务可共用的状态判定。
4. 若 adapters 里已有重复判断，标记后续 session 收口，不在本轮大改 runtime。

本轮不要做：

- 不重跑真实长任务。
- 不做 UI。
- 不把具体题材词写进状态机。

验收标准：

- 章节异常能被结构化分类。
- 测试能区分技术失败、内容质量失败、等待用户、可恢复失败。

直接可用提示词：

```text
执行 Session RRP-03：只硬化章节交付与恢复状态。阅读本 session 必读文件，补齐 core state machine 对空正文、标题-only、正文过短、路径漂移、缺 evidence、字数严重偏离、表达限制缺失的结构化分类和 focused tests。不要跑真实长任务，不做 UI，不写死题材词，不开启下一任务。完成后更新 `docs/release-readiness-productization-session-order-2026-06-05.md` 的 RRP-03 完成记录。
```

### Session RRP-04：共享字数与表达限制执行 gate 收口

层级归属：Core / workflow

本轮目标：

- 确保字数策略和表达限制是所有写作任务共享能力，而不是普通项目、长任务、拆书各自私接。

必读文件：

- `packages/novel_agent_core/lib/src/workflow/chapter_length_profile_resolver_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_length_evaluation.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`
- `packages/novel_agent_core/lib/src/creative/expression_constraint_injection_policy_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_draft_execution_constraint_runtime_service.dart`

必须完成：

1. 审计普通项目、长任务、拆书续写是否都走同一字数/表达限制 bridge。
2. 补齐 shared gate 输出到 RRP-02 共享结果合同。
3. 保留硬限制策略和审核容忍策略的区别。
4. focused tests 覆盖：目标字数偏差、轻微超限不修、严重偏离进入修复、表达限制注入与评估证据。

本轮不要做：

- 不调 prompt 文案大改。
- 不做 GUI。
- 不把字数做成死板最大值。

验收标准：

- 所有写作路径可复用同一评估结果。
- 测试证明硬限制和审核容忍分别生效。

直接可用提示词：

```text
执行 Session RRP-04：只收口共享字数与表达限制执行 gate。确认普通项目、长任务、拆书续写都能消费同一 core/adapters bridge，补齐输出到共享写作运行结果合同，保留硬限制策略与审核容忍策略区别，并补 focused tests。不要做 GUI，不大改 prompt，不把字数限制变成死板最大值，不开启下一任务。
```

### Session RRP-05：长任务 supervisor 消费共享状态

层级归属：Core / adapters runtime

本轮目标：

- 让 supervisor / recovery 不只看任务是否停止，而能消费章节交付、约束、信息、协作的共享状态。

必读文件：

- `packages/novel_agent_adapters/lib/src/runtime/long_task_supervisor.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_recovery_service.dart`
- `packages/novel_agent_core/lib/src/workflow/task_queue_stop_policy_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_failure_action_service.dart`
- RRP-02 产物

必须完成：

1. 设计并接入 supervisor 可消费的共享状态摘要。
2. 支持 stopped、recoverable、waiting_user、content_quality_failed、budget_failed 等分类。
3. 补 adapters/core tests，模拟空正文、只读轮、子任务失败、信息缺失。
4. 保持 supervisor 只做调度恢复，不做文学语义判断。

本轮不要做：

- 不跑真实 provider。
- 不在 supervisor 写题材规则。
- 不让 supervisor 直接读 GUI 状态。

验收标准：

- supervisor 能从共享状态生成合理恢复动作。
- 失败分类不会混成一个 generic stopped。

直接可用提示词：

```text
执行 Session RRP-05：只让长任务 supervisor/recovery 消费共享写作运行状态。接入 RRP-02/RRP-03/RRP-04 的状态摘要，支持 stopped、recoverable、waiting_user、content_quality_failed、budget_failed 等分类，补模拟空正文、只读轮、子任务失败、信息缺失的 tests。不要跑真实 provider，不写题材规则，不做 GUI，不开启下一任务。
```

### Session RRP-06：生产同源长任务稳定性 mock probe

层级归属：Probe / regression

本轮目标：

- 建立不消耗真实额度的长任务稳定性 mock probe，验证 supervisor、delivery、constraints、information 都走 production 同源合同。

必读文件：

- `apps/novel_agent_app/tool/`
- `docs/project-information-substrate-mock-regression-suite-2026-06-05.md`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/runtime/long_task_supervisor.dart`
- `agent.md` 的探针规则

必须完成：

1. 优先复用已有 probe support；若新增脚本，必须有稳定输入输出和 README/说明。
2. mock 至少覆盖：正常章节、空正文、标题-only、字数严重偏离、信息待确认、supervisor recovery。
3. 报告区分技术失败、内容质量失败、等待用户、预算/目标失败。
4. 不引入真实 key / 固定 provider / 用户绝对路径。

本轮不要做：

- 不跑真实 provider。
- 不新增多个重复 probe。
- 不把 probe 判定写成 production 之外的第二套业务逻辑。

验收标准：

- mock probe PASS 时能证明 production 合同链可恢复。
- FAIL 报告能指出是哪类失败。

直接可用提示词：

```text
执行 Session RRP-06：建立或收口生产同源长任务稳定性 mock probe。只用 mock，不消耗真实额度；覆盖正常章节、空正文、标题-only、字数严重偏离、信息待确认、supervisor recovery；报告必须区分技术失败、内容质量失败、等待用户、预算/目标失败。不要新增重复脚本，不写真实 key，不开启下一任务。
```

### Session RRP-07：information 激活与证据闭环验收

层级归属：Core / adapters workflow

本轮目标：

- 证明 knowledge / design / research / reference 能被保存、投影、激活、引用和回看。

必读文件：

- `packages/novel_agent_core/lib/src/information/`
- `packages/novel_agent_adapters/lib/src/workflow/project_information_activation_bridge_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_information_projection_writer_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_information_domain_tool_executor.dart`
- `packages/novel_agent_core/lib/src/tools/domain/`

必须完成：

1. 补齐 information activation 输出到共享运行结果。
2. focused tests 覆盖：保存卡片、写投影、activation selected/omitted/truncated、source refs。
3. 验证投影 Markdown 只是用户可读，不作为运行时事实源。
4. 检查拆书桥和 semantic review bridge 是否能写入 design/knowledge。

本轮不要做：

- 不做 GUI 页面。
- 不跑真实联网。
- 不把来源拆成超过内置/非内置两类。

验收标准：

- information 资料能进入 activation report。
- 用户投影与结构化事实源职责分离。

直接可用提示词：

```text
执行 Session RRP-07：只做 information 激活与证据闭环验收。补齐 knowledge/design/research/reference 保存、投影、activation selected/omitted/truncated/source refs 到共享运行结果的链路，并补 focused tests。不要做 GUI，不跑真实联网，不把来源拆成超过内置/非内置两类，不开启下一任务。
```

### Session RRP-08：普通项目 / 长任务 / 拆书共享信息桥

层级归属：Adapters / workflow

本轮目标：

- 确保 ordinary writing、long task、book deconstruction continuation 都能进入同一 information 桥。

必读文件：

- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_information_bridge_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_semantic_review_information_service.dart`
- `apps/novel_agent_app/lib/features/book_deconstruction/`

必须完成：

1. 审计三条路径是否都能写入和激活 information。
2. 补齐缺失 adapter bridge 或 runtime hook。
3. tests 覆盖普通项目一章、长任务一章、拆书导入小样本的信息写入/激活。
4. 保持拆书只是高密度输入方向，不生成私有信息层。

本轮不要做：

- 不做大型拆书真实测试。
- 不做 GUI 重构。
- 不引入题材化字段。

验收标准：

- 三类任务共享同一 information 合同。
- 拆书产物可被后续写作激活。

直接可用提示词：

```text
执行 Session RRP-08：只打通普通项目、长任务、拆书共享 information 桥。审计并补齐 adapter/runtime hook，让三条路径都能写入和激活同一 information 合同；补普通项目一章、长任务一章、拆书小样本的 focused tests。不要做大型真实拆书，不做 GUI 重构，不引入题材化字段，不开启下一任务。
```

### Session RRP-09：多智能体执行包合同收口

层级归属：Core / agents

本轮目标：

- 收口 `ExecutionPackage / ChildRunPackage / CollaborationResultPackage` 的合同形态，避免靠零散参数和长 prompt 传语义。

必读文件：

- `packages/novel_agent_core/lib/src/agents/sub_agent_run_package_service.dart`
- `packages/novel_agent_core/lib/src/agents/sub_agent_result_package_service.dart`
- `packages/novel_agent_core/lib/src/agents/resolved_agent_group_profile.dart`
- `packages/novel_agent_core/lib/src/agents/resolved_agent_skill_loadout.dart`
- RRP-02 产物

必须完成：

1. 审计当前 sub-agent 包字段是否足以表达目标、上下文、约束、技能、权限、模型、预算、失败策略。
2. 补齐缺失子合同或 builder，不做 god object。
3. tests 覆盖单成员组、多成员组、子上下文隔离、结果 package。
4. 与共享写作运行结果合同建立关系。

本轮不要做：

- 不接 GUI。
- 不跑 provider。
- 不让子智能体直接拥有正式交付权。

验收标准：

- 子任务包不包含完整主会话。
- 协作结果可结构化合并回主链。

直接可用提示词：

```text
执行 Session RRP-09：只收口多智能体执行包合同。审计并补齐 ExecutionPackage/ChildRunPackage/CollaborationResultPackage 的 core 合同或 builder，覆盖目标、上下文、约束、技能、权限、模型、预算、失败策略和结果合并；补单成员组、多成员组、上下文隔离 tests。不要接 GUI，不跑 provider，不给 child 默认正式交付权，不开启下一任务。
```

### Session RRP-10：child model / tool / permission policy 解析

层级归属：Core / adapters runtime

本轮目标：

- 让不同子智能体可以稳定使用不同模型、工具权限和权限边界。

必读文件：

- `packages/novel_agent_core/lib/src/agents/agent_model_override_service.dart`
- `packages/novel_agent_core/lib/src/agents/agent_tool_policy_service.dart`
- `packages/novel_agent_core/lib/src/agents/sub_agent_execution_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`

必须完成：

1. 建立 child effective execution profile 解析：model policy、tool policy、context budget、output budget。
2. 接入 adapters runtime，避免所有 child 只用父模型。
3. tests 覆盖 writer/reviewer/researcher 不同模型或不同工具权限。
4. 子智能体默认不能递归委派、不能请求用户、不能启动长任务。

本轮不要做：

- 不做完整 GUI 设置。
- 不引入真实 provider 测试。
- 不把技能当权限。

验收标准：

- mock 中能观测 child-specific model/tool policy 生效。
- 权限越界会被拒绝或降级。

直接可用提示词：

```text
执行 Session RRP-10：只补 child model/tool/permission policy 解析与运行接线。建立 child effective execution profile，接入 adapters runtime，测试 writer/reviewer/researcher 可用不同模型或工具权限。不要做 GUI，不跑真实 provider，不把技能当权限，不允许 child 递归委派/问用户/启动长任务，不开启下一任务。
```

### Session RRP-11：技能绑定与权限兼容检查

层级归属：Core / agents

本轮目标：

- 明确技能组、技能绑定、工具权限的兼容检查，避免用户以为启用技能就获得联网/写入/交付权限。

必读文件：

- `packages/novel_agent_core/lib/src/agents/agent_skill_loadout_resolver_service.dart`
- `packages/novel_agent_core/lib/src/agents/skill_loadout_conflict_policy_service.dart`
- `packages/novel_agent_core/lib/src/agents/skill_group_catalog_service.dart`
- `packages/novel_agent_core/lib/src/packages/skill_package_validator_service.dart`
- `agent.md` 的技能包规则

必须完成：

1. 补齐 skill capability requirement 与 tool permission profile 的兼容检查。
2. 输出用户可理解 issue，例如“需要联网权限但当前只读”。
3. 保持来源只分内置 / 非内置。
4. tests 覆盖技能组、额外技能、禁用技能、权限不匹配、可降级技能。

本轮不要做：

- 不做 GUI 编辑器。
- 不新增外部技能市场。
- 不把权限写进 skill 本身。

验收标准：

- 技能绑定能被校验和解释。
- 权限不匹配不会静默放行。

直接可用提示词：

```text
执行 Session RRP-11：只做技能绑定与权限兼容检查。补 skill capability requirement 与 tool permission profile 的校验和用户可理解 issue，覆盖技能组、额外技能、禁用技能、权限不匹配、可降级技能 tests。来源只分内置/非内置；不要做 GUI，不做技能市场，不把权限写进 skill 本身，不开启下一任务。
```

### Session RRP-12：非内置资产草案与 proposal 生命周期

层级归属：Core / agents / packages

本轮目标：

- 让 AI 生成技能、用户新增技能、导入资产都先进入非内置草案 / proposal，经过校验和确认再启用。

必读文件：

- `packages/novel_agent_core/lib/src/packages/skill_package_validator_service.dart`
- `packages/novel_agent_core/lib/src/packages/skill_markdown_package_parser_service.dart`
- `packages/novel_agent_core/lib/src/agents/skill_group_file_codec_service.dart`
- `packages/novel_agent_core/lib/src/agents/agent_group_file_codec_service.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/ecosystem_entry_editor_service.dart`

必须完成：

1. 定义或补齐非内置资产 proposal / draft 状态。
2. 支持技能、技能组、智能体、智能体组最小草案校验。
3. 校验能力需求、版本、摘要、风险说明。
4. tests 覆盖 proposal -> validated -> confirmed -> installed / rejected。

本轮不要做：

- 不实现完整 AI 生成器。
- 不做下载市场。
- 不把非内置资产自动授予高风险权限。

验收标准：

- AI 生成类资产不能直接进入正式技能库。
- 非内置资产有可审计生命周期。

直接可用提示词：

```text
执行 Session RRP-12：只做非内置资产草案与 proposal 生命周期。覆盖技能、技能组、智能体、智能体组的最小草案校验、能力需求、版本、摘要、风险说明，以及 proposal -> validated -> confirmed -> installed/rejected tests。不要实现完整 AI 生成器，不做下载市场，不自动授予高风险权限，不开启下一任务。
```

### Session RRP-13：协作预算、退化与局部重试

层级归属：Core / agents / workflow

本轮目标：

- 多智能体失败时先局部重试、降级或退回单主链，不扩大成长任务失败。

必读文件：

- `packages/novel_agent_core/lib/src/agents/sub_agent_execution_service.dart`
- `packages/novel_agent_core/lib/src/agents/sub_agent_result_package_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_failure_action_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_recovery_service.dart`
- RRP-09 / RRP-10 产物

必须完成：

1. 建立协作预算合同：concurrency、token、retry、child max rounds、timeout。
2. 定义 child failure disposition：retry_child、skip_child、fallback_single_main、require_user。
3. tests 覆盖 child timeout、空返回、工具错误、预算耗尽。
4. 输出共享运行结果中的 collaboration failure summary。

本轮不要做：

- 不调真实模型。
- 不做 GUI。
- 不让失败重跑整条长任务作为默认策略。

验收标准：

- 子智能体失败可局部恢复。
- 预算耗尽能退化或给出用户动作。

直接可用提示词：

```text
执行 Session RRP-13：只补多智能体协作预算、退化与局部重试。建立 concurrency/token/retry/child max rounds/timeout 合同，定义 retry_child/skip_child/fallback_single_main/require_user disposition，并测试 child timeout、空返回、工具错误、预算耗尽。不要跑真实模型，不做 GUI，不默认重跑整条长任务，不开启下一任务。
```

### Session RRP-14：协作冲突仲裁

层级归属：Core / agents / workflow

本轮目标：

- 当作者、审稿、连续性、资料专家意见冲突时，主链能记录、仲裁、采纳或请求用户确认。

必读文件：

- `packages/novel_agent_core/lib/src/agents/sub_agent_result_package_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_checkpoint_review_service.dart`
- `packages/novel_agent_core/lib/src/information/information_permission_policy_service.dart`
- `packages/novel_agent_core/lib/src/continuity/narrative_state/`
- RRP-09 产物

必须完成：

1. 定义 collaboration conflict record / arbitration result。
2. 子结果至少包含 risk、evidence、suggestion、adoption_hint、confidence。
3. 主链可自动处理低风险冲突，中高风险进入修订或用户确认。
4. tests mock 审稿与连续性意见冲突。

本轮不要做：

- 不做 GUI。
- 不让子智能体直接改长期规则。
- 不把冲突判断写成题材关键词。

验收标准：

- 冲突能结构化记录。
- 高风险冲突不会静默落盘。

直接可用提示词：

```text
执行 Session RRP-14：只做协作冲突仲裁合同与 focused tests。定义 collaboration conflict record/arbitration result，确保子结果包含 risk/evidence/suggestion/adoption_hint/confidence，主链可处理低风险冲突并将高风险转用户确认。不要做 GUI，不让 child 直接改长期规则，不写题材关键词，不开启下一任务。
```

### Session RRP-15：当前协作组与技能装载进入运行链

层级归属：Adapters / workflow runtime

本轮目标：

- 确保 GUI 当前选择的智能体组和项目技能装载真实进入普通项目与长任务运行链，不再 fallback 到第一个 optional group。

必读文件：

- `packages/novel_agent_adapters/lib/src/tools/project_agent_skill_runtime_loadout_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_agent_group_binding_repository.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_request_agent_resolver_service.dart`

必须完成：

1. 审计 group / skill resolution 在普通会话、长任务启动、长任务步骤中的输入来源。
2. 修复 optionalGroups.first 或摘要丢 profile 的问题。
3. tests 覆盖 GUI 选择 group -> runtime effective group -> child run package。
4. 确保单智能体项目走单成员组合同。

本轮不要做：

- 不做生态页 UI。
- 不跑真实 provider。
- 不把选择逻辑写进 widget。

验收标准：

- 当前项目选择的 group 真实进入运行链。
- skill loadout 与 group/member 上下文可追踪。

直接可用提示词：

```text
执行 Session RRP-15：只打通当前协作组与技能装载进入运行链。审计并修复普通会话、长任务启动、长任务步骤中 group/skill resolution 输入来源，避免 optionalGroups.first 和 profile 摘要丢失；测试 GUI 选择 group -> runtime effective group -> child run package，并验证单智能体走单成员组合同。不要做 UI，不跑真实 provider，不开启下一任务。
```

### Session RRP-16：运行投影与用户暴露协议服务

层级归属：Core / app application service

本轮目标：

- 把内部合同投影成普通用户、高级用户、开发诊断三层可见信息，避免 GUI 直接显示内部术语。

必读文件：

- `docs/release-readiness-gui-core-consolidation-analysis-2026-06-05.md`
- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_tool_entry_projection_service.dart`
- `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/agent_ecosystem_view_data_service.dart`

必须完成：

1. 定义或补齐 exposure projection service / policy。
2. 普通用户默认隐藏 prompt block id、tool profile id、execution constraint、raw JSON、sub_session_id。
3. 高级 / 诊断层仍可查看必要证据。
4. tests 覆盖普通、先进、诊断三层输出差异。

本轮不要做：

- 不重构所有页面。
- 不删除诊断信息。
- 不把 projection 逻辑写进 widget。

验收标准：

- 同一运行结果能投影为不同可见层。
- 普通层不泄漏内部 contract/tool/schema 名称。

直接可用提示词：

```text
执行 Session RRP-16：只做运行投影与用户暴露协议服务。定义/补齐 projection policy，让普通、高级、开发诊断三层看到不同信息；普通层隐藏 prompt block id、tool profile id、execution constraint、raw JSON、sub_session_id。补 tests。不要重构所有页面，不删除诊断信息，不把逻辑写进 widget，不开启下一任务。
```

### Session RRP-17：首次使用、新建作品与模型连接测试

层级归属：App / GUI / adapters edge

本轮目标：

- 让用户第一次打开软件时能自然完成：新建作品、配置模型、测试连接。

必读文件：

- `apps/novel_agent_app/lib/app/navigation/app_shell_navigation_catalog.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_launcher_overlay.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/widgets/provider_detail_pane.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/widgets/model_settings_panel.dart`
- `apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart`

必须完成：

1. 增强主导航或打开项目页的新建作品入口。
2. 模型设置提供清晰“测试连接”路径。
3. Base URL / 协议 / 高级参数默认折叠到高级设置。
4. 补 GUI focused tests 或 widget tests。

本轮不要做：

- 不改核心 provider 协议大结构，除非测试连接缺 adapter port。
- 不做主题大改。
- 不做长任务页面。

验收标准：

- 新用户能在 GUI 中找到新建和模型测试。
- 内部术语减少。

直接可用提示词：

```text
执行 Session RRP-17：只做首次使用、新建作品与模型连接测试 GUI 收口。增强新建作品入口，设置页提供清晰测试连接路径，高级参数折叠，补 focused/widget tests。不要做主题大改，不做长任务页面，不改 provider 协议大结构除非缺必要 port，不开启下一任务。
```

### Session RRP-18：Workbench 写作主路径产品化

层级归属：App / GUI

本轮目标：

- 普通项目打开后，主面板聚焦“写第一章、续写下一章、整理设定”，协作和工具细节默认摘要化。

必读文件：

- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_empty_state_panel.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_input_dock.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_opening_panel_view_data_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_tool_entry_projection_service.dart`
- RRP-16 产物

必须完成：

1. 优化普通项目 opening / empty state 的主动作。
2. 当前协作组只显示摘要和进入设置入口，不展开生态配置。
3. 工具调用默认折叠为“已保存正文 / 已更新资料 / 需要确认”。
4. tests 覆盖普通用户可见文案不含内部 id。

本轮不要做：

- 不做智能体/技能编辑器。
- 不改底层运行逻辑。
- 不做整站视觉重构。

验收标准：

- 普通小说项目首屏能自然开始写作。
- 主面板不展示复杂技能树。

直接可用提示词：

```text
执行 Session RRP-18：只做 Workbench 写作主路径产品化。优化普通项目 opening/empty state 主动作，协作组只显示摘要与设置入口，工具调用默认折叠成人话结果，并补 GUI tests。不要做智能体/技能编辑器，不改底层 runtime，不做整站视觉重构，不开启下一任务。
```

### Session RRP-19：长任务总站用户化与恢复动作

层级归属：App / GUI / adapters projection

本轮目标：

- 长任务详情默认展示进度、当前动作、需要我处理、最近产物，而不是内部字段堆叠。

必读文件：

- `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart`
- `apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart`
- `apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_action_bar.dart`
- `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
- RRP-05 / RRP-16 产物

必须完成：

1. 调整 view-data：默认四块信息，诊断信息折叠。
2. 恢复动作显示为用户可点击操作：继续、重试、等待确认、查看产物。
3. Information / Delivery / Review 等改成人话标签。
4. tests 覆盖失败类型投影和诊断折叠。

本轮不要做：

- 不改 supervisor 核心策略。
- 不做真实长任务。
- 不移除诊断数据。

验收标准：

- 用户能看懂任务为什么停、下一步做什么。
- 内部字段默认隐藏。

直接可用提示词：

```text
执行 Session RRP-19：只做长任务总站用户化与恢复动作。调整 view-data 和 detail panel 默认展示进度、当前动作、需要我处理、最近产物；诊断折叠；恢复动作人话化；补 tests。不要改 supervisor 核心策略，不跑真实长任务，不删除诊断数据，不开启下一任务。
```

### Session RRP-20：资料 / 巧思 / information GUI 回看与确认

层级归属：App / GUI / application service

本轮目标：

- 用户能在 GUI 中看到 information 资料、设计元素、研究摘要和待确认项，并能理解它们如何被使用。

必读文件：

- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_panel.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_display_service.dart`
- `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_information_projection_writer_service.dart`
- RRP-07 / RRP-16 产物

必须完成：

1. 建立 information GUI projection：知识、巧思/设计、研究、引用边界、待确认。
2. 展示“本轮为何使用/未使用这些资料”的摘要。
3. 支持从 GUI 打开对应投影文档或结构化摘要。
4. tests 覆盖普通用户术语和待确认项。

本轮不要做：

- 不做完整资料编辑器。
- 不跑联网。
- 不把 Markdown 投影当事实源。

验收标准：

- 用户能回看资料和巧思。
- 待确认资料能明确显示风险与动作。

直接可用提示词：

```text
执行 Session RRP-20：只做资料/巧思/information GUI 回看与确认。建立用户可理解 projection，展示知识、设计元素、研究、引用边界、待确认，以及本轮使用/未使用摘要；可打开投影文档或结构化摘要；补 tests。不要做完整资料编辑器，不跑联网，不把 Markdown 投影当事实源，不开启下一任务。
```

### Session RRP-21：拆书导入后续用途与信息资产桥 GUI

层级归属：App / GUI / adapters bridge

本轮目标：

- 拆书导入不只是一次性预览，而能显示后续用途、分析进度、生成资料和可用于哪些写作链。

必读文件：

- `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart`
- `apps/novel_agent_app/lib/features/book_deconstruction/presentation/`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_information_bridge_service.dart`
- RRP-08 / RRP-20 产物

必须完成：

1. 拆书 UI 增加后续用途摘要：普通续写、长任务续写、资料沉淀、解说等可选路线。
2. 展示已生成的设定、角色、伏笔、information / design 数量和可用状态。
3. 小样本拆书导入后能在 GUI 看到可复用资料。
4. tests 覆盖 view-data，不做真实大书。

本轮不要做：

- 不实现 1000 章批处理完整功能。
- 不做同人/题材专属逻辑。
- 不把拆书做成私有资料层。

验收标准：

- 拆书产物能进入共享 information GUI。
- 用户能看懂后续路线。

直接可用提示词：

```text
执行 Session RRP-21：只做拆书导入后续用途与信息资产桥 GUI。让拆书 UI 展示后续用途、分析/资料生成摘要、information/design 可用状态，并用小样本 view-data tests 证明产物能进入共享 information GUI。不要做 1000 章批处理，不做题材专属逻辑，不建私有资料层，不开启下一任务。
```

### Session RRP-22：生态设置入口最小安全编辑器

层级归属：App / GUI / application service

本轮目标：

- 专门设置 / 生态入口能安全编辑智能体组、技能组、智能体、技能摘要，而不是把复杂配置塞进主面板。

必读文件：

- `apps/novel_agent_app/lib/features/agent_ecosystem/`
- `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/ecosystem_entry_editor_service.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/project_skill_loadout_detail_panel.dart`
- RRP-11 / RRP-12 / RRP-16 产物

必须完成：

1. 生态页显示内置 / 非内置资产区别。
2. 支持复制内置组、增删成员、设置主智能体、绑定/解绑技能、查看权限边界摘要。
3. 显示配置校验 issue：无主智能体、多主、技能权限不匹配。
4. 不把完整 prompt block 编辑器作为本轮目标。

本轮不要做：

- 不搬到 workbench 主面板。
- 不做技能市场。
- 不让非内置草案绕过确认。

验收标准：

- GUI 能完成最小安全编辑。
- 配置错误能用人话提示。

直接可用提示词：

```text
执行 Session RRP-22：只做生态设置入口最小安全编辑器。生态页展示内置/非内置资产，支持复制内置组、增删成员、设置主智能体、绑定/解绑技能、查看权限边界摘要，并显示配置校验 issue。不要搬进 workbench 主面板，不做技能市场，不让非内置草案绕过确认，不开启下一任务。
```

### Session RRP-23：智能体协作 GUI 短探针

层级归属：App / probe / regression

本轮目标：

- 从 GUI viewmodel / application 层证明多智能体协作组选择、技能绑定、子任务结果能闭环。

必读文件：

- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_request_agent_resolver_service.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/sub_agent_activity_panel.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/sub_agent_run_detail_view.dart`
- RRP-09 ~ RRP-16 产物

必须完成：

1. mock LLM 主智能体调用至少两个子智能体。
2. 验证 GUI 当前组进入运行链。
3. 验证子智能体结果显示为“专家意见 / 证据 / 采纳情况”，原始 id 放诊断。
4. 验证 child 失败可降级。

本轮不要做：

- 不跑真实 provider。
- 不做长任务 200 章。
- 不把 probe 脚本混进主线业务。

验收标准：

- GUI/viewmodel 层多智能体短探针 PASS。
- 普通用户投影无内部 id 泄漏。

直接可用提示词：

```text
执行 Session RRP-23：只做智能体协作 GUI 短探针。用 mock LLM 从 GUI viewmodel/application 层验证当前协作组进入运行链、主智能体调用至少两个子智能体、结果以专家意见/证据/采纳情况展示、child 失败可降级。不要跑真实 provider，不做长任务压力探针，不把 probe 业务逻辑混进 production，不开启下一任务。
```

### Session RRP-24：字体、主题与视觉发布阻断修复

层级归属：App / GUI / visual regression

本轮目标：

- 修复中文方框、主题工程感、长文本溢出等发布阻断。

必读文件：

- `apps/novel_agent_app/pubspec.yaml`
- `apps/novel_agent_app/lib/app/theme/`
- `apps/novel_agent_app/lib/shared/theme/novel_theme_context.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/widgets/theme_settings_panel.dart`
- 现有截图 / visual artifacts

必须完成：

1. 确认字体策略，修复中文 tofu 方框。
2. 优化默认浅色和深色主题的对比、背景、边框、阅读区层级。
3. 处理按钮/卡片长文本溢出。
4. 用 Playwright / Flutter 截图或 widget tests 做桌面与窄屏检查。

本轮不要做：

- 不改业务逻辑。
- 不引入一味单色调主题。
- 不用装饰性 orb / bokeh。

验收标准：

- 中文截图无方框。
- 默认主题达到可发布阅读舒适度。
- 主要按钮文本不溢出。

直接可用提示词：

```text
执行 Session RRP-24：只做字体、主题与视觉发布阻断修复。确认并修复中文字体方框，优化默认浅/深主题对比和阅读层级，处理长文本溢出，并用截图或 widget tests 覆盖桌面与窄屏。不要改业务逻辑，不引入单调主题或装饰 orb，不开启下一任务。
```

### Session RRP-25：探针、真实 API 配置与发布包隔离

层级归属：Devtools / packaging / repository hygiene

本轮目标：

- 确认发布包不包含探针产物、真实 key、本地配置、参考项目和一次性脚本。

必读文件：

- `agent.md` 的探针与整洁性规则
- `.gitignore`
- `tools/repository_secret_scan.dart`
- `apps/novel_agent_app/tool/`
- `artifacts/`
- `local/`
- 打包脚本 / release 脚本

必须完成：

1. 审计正式 tool 目录里的 probe，归档或说明长期保留理由。
2. 确认真实 API 探针必须显式开闸，不默认消耗额度。
3. 运行密钥扫描。
4. 更新发布清单，确认参考项目、artifacts、local、不跟踪配置不打包。

本轮不要做：

- 不删除用户需要保留的人工测试产物，除非确认它们在 artifacts/local 且不入仓。
- 不重写 git 历史。
- 不跑真实 provider。

验收标准：

- 密钥扫描通过。
- 发布包隔离规则清晰。
- probe 不再像正式产品入口。

直接可用提示词：

```text
执行 Session RRP-25：只做探针、真实 API 配置与发布包隔离。审计 tool/probe、artifacts、local、.gitignore、发布脚本和密钥扫描，归档或说明长期保留 probe 的理由，确保真实 API 探针显式开闸且不打包真实 key/参考项目/本地配置。不要删用户要保留的人工产物，不重写 git 历史，不跑真实 provider，不开启下一任务。
```

### Session RRP-26：Windows / Android 打包发布冒烟

层级归属：Packaging / app

本轮目标：

- 双端打包冒烟，确认字体、资源、探针隔离、启动页面和基础功能可用。

必读文件：

- `apps/novel_agent_app/pubspec.yaml`
- `apps/novel_agent_app/android/`
- Windows 打包配置
- RRP-24 / RRP-25 产物
- 历史打包记录中关于 Android 工具路径的修正

必须完成：

1. 执行 Windows 打包或 release build 冒烟。
2. 执行 Android 打包或可行的构建检查，避免使用写死假工具路径。
3. 检查包内不含 local/test_api/artifacts/reference GPL 目录。
4. 记录构建命令、结果、失败原因。

本轮不要做：

- 不修大业务 bug，除非构建阻断。
- 不提交真实 key。
- 不忽略构建错误。

验收标准：

- 双端至少达到可说明的构建结果。
- 阻断项有明确下一步。

直接可用提示词：

```text
执行 Session RRP-26：只做 Windows / Android 打包发布冒烟。使用当前项目真实配置，避免假工具路径，检查字体/资源/探针隔离/启动页/基础功能，确认包内不含 local/test_api/artifacts/reference GPL 目录。不要修大业务 bug 除非构建阻断，不提交真实 key，不忽略错误，不开启下一任务。
```

### Session RRP-27：CLI 最小边界与不阻断策略

层级归属：CLI / shared core

本轮目标：

- CLI 当前未完全实现，但不能破坏共享 core；发布前明确 CLI 最小可用或实验边界。

必读文件：

- `apps/novel_agent_cli/`
- `packages/novel_agent_core/lib/`
- `packages/novel_agent_adapters/lib/`
- `agent.md`

必须完成：

1. 跑 CLI 现有 tests / analyze。
2. 确认 CLI 只消费 core/adapters 合同，不复制 GUI 业务判断。
3. 文档化 CLI 发布状态：可用命令、实验命令、暂不支持功能。
4. 如有小阻断，做最小修复。

本轮不要做：

- 不补完整 CLI 产品化。
- 不让 CLI 变成底层业务兜底。
- 不影响 GUI 发布主线。

验收标准：

- CLI 状态清楚，不阻断 GUI beta。
- CLI 无明显编译/分析错误。

直接可用提示词：

```text
执行 Session RRP-27：只做 CLI 最小边界与不阻断策略。运行 CLI analyze/tests，确认 CLI 消费共享 core/adapters 合同，不复制业务判断；文档化可用/实验/暂不支持命令，必要时做小阻断修复。不要补完整 CLI 产品化，不影响 GUI 发布主线，不开启下一任务。
```

### Session RRP-28：GUI 关键路径自动化验收

层级归属：App / GUI regression

本轮目标：

- 用 GUI/viewmodel 层覆盖发布前关键路径，不依赖手工猜文件。

必读文件：

- `apps/novel_agent_app/test/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/long_task_station/`
- `apps/novel_agent_app/lib/features/book_deconstruction/`
- `apps/novel_agent_app/lib/features/agent_ecosystem/`

必须完成：

1. 覆盖首次启动/新建作品/模型配置视图/普通写作/资料回看/短长任务/恢复动作/生态设置入口。
2. 优先 widget / viewmodel tests；必要时用 Playwright 截图。
3. 检查普通用户路径无内部术语。
4. 记录测试命令和结果。

本轮不要做：

- 不跑真实 provider。
- 不大改 UI。
- 不把测试脚本做成正式业务。

验收标准：

- GUI 关键路径自动化通过。
- 截图或测试能证明中文可读。

直接可用提示词：

```text
执行 Session RRP-28：只做 GUI 关键路径自动化验收。覆盖首次启动/新建作品/模型配置视图/普通写作/资料回看/短长任务/恢复动作/生态设置入口，优先 widget/viewmodel tests，必要时截图。不要跑真实 provider，不大改 UI，不把测试脚本变业务，不开启下一任务。
```

### Session RRP-29：真实 provider 短中长稳定性验收

层级归属：Real probe / regression

本轮目标：

- 在显式开闸和预算控制下，用真实 provider 验证普通项目、短长任务、中等长任务的稳定性。

必读文件：

- RRP-06 probe 产物
- `agent.md` 探针规则
- `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE` 使用约定
- `apps/novel_agent_app/tool/` 中长期保留 probe

必须完成：

1. 只有在 `NOVEL_AGENT_ENABLE_REAL_PROBES=1` 明确设置后才运行。
2. 跑普通项目 3-5 章。
3. 跑短长任务 10 章。
4. 跑中等长任务 30-50 章，至少包含一次 checkpoint/recovery 或明确证明无需恢复。
5. 验证 expression constraints、字数策略、information 命中、章节交付。
6. 保留产物供人工阅读，报告区分失败类型。

本轮不要做：

- 不跑 200 章压力线，除非短中档全部通过且用户明确要求。
- 不硬编码模型/key。
- 不删除测试产物。

验收标准：

- 真实 provider 报告明确 PASS/FAIL 和失败类型。
- 产物路径记录清楚。

直接可用提示词：

```text
执行 Session RRP-29：只做真实 provider 短中长稳定性验收。必须确认 NOVEL_AGENT_ENABLE_REAL_PROBES=1 后才运行，使用本地配置，不硬编码 key/model。跑普通项目 3-5 章、短长任务 10 章、中等长任务 30-50 章，验证章节交付、字数、表达限制、information 命中、恢复；保留产物，报告区分失败类型。不要跑 200 章压力线，除非短中档全通过且用户明确要求；不删除产物，不开启下一任务。
```

### Session RRP-30：最终发布收口、文档与交接

层级归属：Documentation / release readiness

本轮目标：

- 汇总所有 session 结果，判断能否作为 GUI beta 发布，并留下后续路线。

必读文件：

- `docs/release-readiness-productization-session-order-2026-06-05.md`
- `docs/release-readiness-gui-core-consolidation-analysis-2026-06-05.md`
- RRP-01 baseline
- RRP-28 / RRP-29 报告
- `agent.md`

必须完成：

1. 汇总 RRP-01 ~ RRP-29 完成状态。
2. 更新发布 readiness 结论：可发布、可 beta、阻断项。
3. 列出保留风险、后续 P2/P3 任务。
4. 确认密钥扫描、打包隔离、GUI 关键路径、真实 provider 验收状态。
5. 写出下一会话交接提示。

本轮不要做：

- 不再新增功能。
- 不开启真实长跑。
- 不把未完成项说成完成。

验收标准：

- 有最终发布收口报告。
- 能明确告诉用户距离发布还差什么。

直接可用提示词：

```text
执行 Session RRP-30：只做最终发布收口、文档与交接。汇总 RRP-01 ~ RRP-29 完成状态，更新发布 readiness 结论，列出阻断项、保留风险、后续 P2/P3，确认密钥扫描、打包隔离、GUI 关键路径、真实 provider 验收状态，并写下一会话交接提示。不要新增功能，不开启真实长跑，不粉饰未完成项。
```

---

## 8. 总启动提示词

```text
根据目前的进度和文档：docs\release-readiness-productization-session-order-2026-06-05.md 继续下一步。每次只确认完成一个具体的 session；如果上个会话末尾卡在某个任务的一半未完成或者出现了关联性错误，就先把这些做好，不要开启下一轮任务。如果已经确认可以开启下一轮任务，就直接开始当前文档中下一个未完成 session。需要直接识别相关提示词、任务内容、任务约束，并按文档要求完成：core/domain 先行，adapters/runtime 随后，projection/probe 再后，GUI/CLI/发布展示最后；解耦合、单一职责、复用现有合同，不让单一文件过重，不把 UI/CLI/probe/fallback 做成业务中心。完成后写入对应 session 完成记录，只确认这一个 session，不要自动开启下一 session。
```

---

## 9. 完成记录占位

### RRP-01 完成记录

- 状态：已完成
- 完成时间：2026-06-05 11:53:07
- 主要改动：
  - 新增 `docs/release-readiness-baseline-audit-2026-06-05.md`，记录 RRP 发布收口 baseline、代码锚点核对、顺序判断和 focused checks。
  - 核对 RRP 文档列出的 core / adapters / app 锚点目录，确认当前仓库全部存在且可继续作为后续 session 落点。
  - 刷新当前结构风险基线：`AppShellController` 约 `4759` 行，`ProjectWorkflowRuntimeService` 约 `2697` 行，`ProjectContextActivationService` 约 `641` 行。
- 验证命令：
  - `dart tools/repository_secret_scan.dart`
  - `dart test test/long_task_runtime_services_test.dart`
  - `dart test test/project_conversation_draft_runtime_service_test.dart`
  - `flutter test test/long_task_station_view_data_service_test.dart test/conversation_tool_entry_projection_service_test.dart`
- 验证结果：
  - 上述命令全部通过。
  - 当前 baseline 可确认：章节交付、长任务恢复、information 子域、普通写作 runtime 接线和 GUI 摘要投影都有可复用基础，但共享写作结果合同仍未正式收口。
  - 未发现需要调整 RRP session 顺序的证据，下一步仍应进入 `RRP-02`。
- 剩余风险：
  - 工作区仍有大量未提交改动与未跟踪文件，本轮未清理，只做只读审计和文档记录。
  - 发布阻断项仍包括 GUI 默认路径、中文字体/主题、真实 provider 验收、probe/打包隔离。
  - 共享写作结果合同尚未建立，`RRP-03 ~ RRP-05` 依赖这一前置收口。
- 下一步：
  - 执行 `RRP-02`：只做共享写作运行结果合同，拆分 delivery / constraints / information / collaboration / recovery 子合同并补 focused tests；不要开启 `RRP-03`。

### RRP-02 完成记录

- 状态：已完成
- 完成时间：2026-06-05 12:09:10
- 主要改动：
  - 在 `packages/novel_agent_core/lib/src/workflow/` 新增共享写作结果主合同与子合同：`WritingExecutionResult`、`WritingExecutionDeliverySummary`、`WritingExecutionConstraintSummary`、`WritingExecutionInformationSummary`、`WritingExecutionCollaborationSummary`、`WritingExecutionRecoverySummary`。
  - 新增 `WritingExecutionOutcomeStatuses`、`WritingExecutionResultCodecService`、`WritingExecutionResultNormalizerService`，把现有 `ChapterDeliveryStateResult`、`WritingExecutionConstraintBridgeResult`、`ChapterLengthEvaluation`、`ExpressionConstraintReviewProjection`、`ContextActivationReport`、sub-agent result package、`LongTaskRecoveryService` 输出归并到统一纯 Dart 合同。
  - 在 `packages/novel_agent_core/test/writing_execution_result_contracts_test.dart` 增加 focused tests，覆盖普通项目与长任务共用同一结果类型，以及 `success / recoverable_failure / user_action_required / content_quality_issue` 四类终态。
  - 在 `packages/novel_agent_core/lib/novel_agent_core.dart` 导出新合同、codec 和 normalizer，供后续 session 薄接线消费。
- 验证命令：
  - `dart test test/writing_execution_result_contracts_test.dart`
  - `dart test test/long_task_runtime_services_test.dart test/task_queue_services_test.dart`
- 验证结果：
  - 上述命令全部通过。
  - 新合同已能在不改 adapters / GUI / provider 调用链的前提下，统一表达章节交付、字数/表达限制、information 激活、协作结果和恢复建议。
  - focused tests 已证明普通项目与长任务可以使用同一 `WritingExecutionResult` 类型描述成功、可恢复失败、等待用户和内容质量问题。
- 剩余风险：
  - 当前只完成 core 合同、codec 和 normalizer，现有 runtime 调用点还未切换到新合同，后续 `RRP-03 ~ RRP-05` 需要逐步消费它。
  - 顶层分类仍以现有 delivery / constraint / information / recovery 信号归并为主，真实 provider 长链上的边界还要等后续 session 和 probe 验收继续硬化。
  - 协作摘要当前只消费稳定的 sub-agent result package，child-specific model/tool policy、冲突仲裁和预算退化仍留给后续多智能体 session。
- 下一步：
  - 执行 `RRP-03`：只硬化章节交付与恢复状态，补齐空正文、标题-only、正文过短、路径漂移、缺 evidence、字数严重偏离、表达限制缺失的结构化分类和 focused tests；不要开启 `RRP-04`。

### RRP-03 完成记录

- 状态：已完成
- 完成时间：2026-06-05 12:15:10
- 主要改动：
  - 扩展 `packages/novel_agent_core/lib/src/workflow/chapter_delivery_state_request.dart`，为状态机补充最小核心输入信号：`minimumBodyLength`、`requireEvidence`、`requireExpressionConstraintReview`、`chapterLengthEvaluation`、`expressionConstraintReview`。
  - 硬化 `packages/novel_agent_core/lib/src/workflow/chapter_delivery_state_machine.dart`，把“正文过短、缺 evidence、字数严重偏离、表达限制复核缺失”收回 core 层正式判定，不再只依赖探针或 runtime 旁路。
  - 在 `packages/novel_agent_core/test/chapter_delivery_state_machine_test.dart` 增加 focused tests，覆盖空正文、标题-only、正文过短、路径漂移、submission 缺失、缺 evidence、字数严重偏离、表达限制复核缺失，以及普通项目/长任务共用同一状态判定。
- 验证命令：
  - `dart test test/chapter_delivery_state_machine_test.dart`
  - `dart test test/submit_chapter_delivery_handler_test.dart test/writing_execution_result_contracts_test.dart test/task_queue_services_test.dart`
  - `dart test test/long_task_runtime_services_test.dart test/narrative_supervisor_risk_policy_service_test.dart`
- 验证结果：
  - 上述命令全部通过。
  - 状态机现已能把空正文和路径漂移归为可恢复失败，把标题-only、正文过短、字数严重偏离归为内容质量问题，把等待用户维持在统一检查点状态，把缺 evidence 和表达限制复核缺失归为已交付但需修补的结构化状态。
  - focused tests 已证明普通项目和长任务可以共享同一 core 判定逻辑，不需要分别维护两套章节异常分类。
- 剩余风险：
  - adapters 里仍保留重复 guard，例如 `ProjectConversationDraftRuntimeService` 的 `_ensureFormalChapterCompletion` 与 `_hasRecoverableInvalidChapterDeliveryAttempt`；本轮只记录它们，后续 session 再统一向共享合同收口。
  - “缺 evidence” 与“表达限制复核缺失”当前通过 request 显式信号进入状态机，后续 runtime 接线还需要把这些信号稳定传入，避免长期依赖调用点自行记得传。
  - 本轮没有重跑真实长任务，也没有动 GUI；真实 provider 行为与用户可理解投影仍要靠后续 session 继续验证。
- 下一步：
  - 执行 `RRP-04`：只收口共享字数与表达限制执行 gate，确保普通项目、长任务、拆书续写都能复用同一评估结果并输出到共享写作运行结果合同；不要开启 `RRP-05`。

### RRP-04 完成记录

- 状态：已完成
- 完成时间：2026-06-05 12:28:15
- 主要改动：
  - 扩展 `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart` 与 `writing_execution_constraint_bridge_result.dart`，为共享 bridge 正式补充表达限制注入模式、是否要求复核证据，以及 `execution_gate` 运行时报告，让普通项目、长任务和后续拆书续写都能消费同一 gate 语义。
  - 补强 `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_summary.dart` 的共享结果字段，并在 `writing_execution_result_normalizer_service.dart` 中把“严重字数偏离 / 表达限制复核缺失”收口为硬 gate，把“轻微波动 / 下章回调 / 已记录复核”收口为软 gate，不再把高强度真实性复核误判成自动返修。
  - 更新 `packages/novel_agent_adapters/lib/src/workflow/project_draft_execution_constraint_runtime_service.dart` 与 `project_workflow_runtime_service.dart`，让 ordinary conversation 和 workflow task 都把 intent / taskType 一并送入同一 bridge，并把表达限制 gate 摘要写回 session context markdown。
  - 在 `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart` 保持普通会话继续走同一约束 runtime bridge，并按当前 taskType 传入共享 gate 上下文。
  - 增加 focused tests：`packages/novel_agent_core/test/writing_execution_constraint_bridge_service_test.dart`、`writing_execution_result_contracts_test.dart`、`packages/novel_agent_adapters/test/project_draft_execution_constraint_runtime_service_test.dart`，并同步更新 workflow / app 相关替身签名，覆盖轻微偏离只提醒、严重偏离触发返修、表达限制注入与复核证据缺失三类关键边界。
- 验证命令：
  - `dart test test/writing_execution_constraint_bridge_service_test.dart test/writing_execution_result_contracts_test.dart test/chapter_length_distribution_service_test.dart test/expression_constraint_injection_policy_service_test.dart`
  - `dart test test/project_draft_execution_constraint_runtime_service_test.dart test/project_workflow_runtime_service_test.dart`
  - `flutter test test/workbench_conversation_controller_agent_selection_test.dart`
- 验证结果：
  - 上述命令全部通过。
  - 共享 bridge 现已稳定输出：字数 gate 的提醒/回调/返修语义、表达限制注入模式，以及是否要求表达限制复核证据。
  - 共享写作结果合同现已能区分：
    - `chapter_length_needs_rebalance` / `chapter_length_slightly_off` 这类软 gate；
    - `chapter_length_severely_off` / `expression_constraint_review_missing` 这类硬 gate。
  - focused tests 已证明：轻微或可回调的字数偏差不会误触发返修；严重偏离会进入硬 gate；表达限制一旦进入写作注入链，就必须留下复核证据。
- 剩余风险：
  - 本轮只收口了共享 gate 语义和 focused 消费口径，尚未让 long-task supervisor / recovery 正式消费 `WritingExecutionResult` 的完整约束摘要；这属于 `RRP-05` 范围。
  - `ProjectConversationDraftRuntimeService` 内部的章节交付补救 guard 仍然存在与共享结果合同并行的适配层判断；本轮未大改 ordinary runtime。
  - 拆书续写侧虽然能复用同一 core bridge 语义，但本轮没有单独扩写拆书专属集成测试，后续 session 仍需在真实链路里继续验证。
- 下一步：
  - 执行 `RRP-05`：只让长任务 supervisor / recovery 正式消费共享写作运行结果合同中的 delivery / constraints / information / collaboration / recovery 状态；不要开启 `RRP-06`。

### RRP-05 完成记录

- 状态：已完成
- 完成时间：2026-06-05 12:58:27
- 主要改动：
  - 在 `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart` 把 `WritingExecutionResultNormalizerService` 正式接入长任务 workflow runtime：`runWorkflowTaskOnce(...)` 现在会基于章节交付、执行约束、checkpoint review、information signal、恢复建议和协作结果构建 `writing_execution_result`，并在 `skip_review / gate_failed / waiting_user / formal_fail / success` 等关键分支统一返回、同时写回 execution record。
  - 为 runtime 补充最小私有桥接辅助：从 `chapter_delivery.state_result`、`activation_report`、`expression_constraint_review`、`information_signal` 和 `call_sub_agent` 结果抽取共享结果所需的 core 输入，不在 supervisor 里读取正文或追加文学语义判断。
  - 在 `packages/novel_agent_core/lib/novel_agent_core.dart` 导出 `LongTaskWritingExecutionSignalService`，保证 adapters runtime 能通过正式 core 导出消费共享写作结果信号。
  - 补 focused tests，覆盖 supervisor / stop policy / recovery / scheduler / workflow runtime 对共享状态的消费，场景包括：空正文或只读轮导致的正式交付缺失、用户确认等待、information 缺失修补、共享预算边界、协作失败信号、repair/manual-attention 调度分支。
- 验证命令：
  - `dart test test/task_queue_services_test.dart test/long_task_runtime_services_test.dart test/long_task_scheduler_services_test.dart`
  - `dart test test/project_workflow_runtime_service_test.dart test/long_task_supervisor_test.dart`
- 验证结果：
  - 上述 focused tests 全部通过。
  - 长任务 runtime 现在不再只靠 `step_failed / waiting_user / chapter_delivery_state` 的旧分支判断；step recorder、stop policy、recovery 和 supervisor 都能消费共享 `writing_execution_result` 摘要，识别 `recoverable / waiting_user / content_quality_failed / budget_failed` 等稳定分类。
  - `LongTaskSchedulerTickPlanService` 已验证能正确消费 `pause_for_repair` 与 `pause_for_manual_attention`，修复了此前恢复计划能产出但调度器未完全接线的缺口。
- 剩余风险：
  - `runWorkflowTaskOnce(...)` 当前对协作结果的共享摘要只消费稳定的 `call_sub_agent` 返回壳；更完整的 child model/tool policy、冲突仲裁和多子协作 GUI 投影仍属于后续多智能体 session 范围。
  - 当前 workflow runtime 的共享结果构建主要覆盖长任务单步主链；postprocess 路径虽然可继续复用同一合同，但本轮没有额外扩写独立 postprocess 专测。
  - 工作区仍有大量与其他主线相关的未提交改动；本轮只收口 `RRP-05` 所需链路，没有整理无关改动。
- 下一步：
  - 执行 `RRP-06`：只做 mock 长任务短链回归与报告，验证共享写作结果、章节交付、information、checkpoint/recovery 在 mock 链路上稳定闭环；不要直接开启真实 provider 验收。

### RRP-06 完成记录

- 状态：已完成
- 完成时间：2026-06-05 13:15:24
- 主要改动：
  - 新增 `apps/novel_agent_app/tool/mock_long_task_probe.dart`，建立 `RRP-06` 的 production 同源 mock probe：直接复用 `ProjectWorkflowRuntimeService`、`WritingExecutionResultNormalizerService`、`LongTaskWritingExecutionSignalService`、`LongTaskRecoveryService`、`LongTaskSchedulerTickPlanService` 和 `LongTaskSupervisor`，不联网、不读取真实 key、不走第二套业务判定。
  - 新增 `tools/run_release_readiness_long_task_mock_probe.ps1` 作为稳定 PowerShell 包装入口；新增 `docs/release-readiness-long-task-mock-probe-2026-06-05.md` 记录 probe 目的、输入输出、覆盖场景与使用规则。
  - 在 probe 内补齐 8 个稳定回归场景：`normal_chapter_success`、`empty_body_recoverable`、`title_only_quality_failure`、`severe_word_count_constraint`、`information_waiting_user`、`supervisor_budget_recovery`、`supervisor_shared_state_consumption`、`technical_failure_classification`。
  - 修复本轮落地过程中的关联性问题：
    - 补上 async 场景 `await` 和 `_mockSettings()` 的非合法 `const` 用法；
    - 为正常/异常 workflow 场景补齐最小合法 checkpoint review 信号，避免 probe 因 mock 输入缺失把成功/可恢复场景误升格成表达限制证据缺失；
    - 修正 `submit_chapter_delivery` mock 入参，显式传入 `title`，让 `title_only` 场景真正命中 production 状态机的 `title_only_output` 分支；
    - 按当前生产调度语义校正 budget 场景断言：`recovery_action=resume_dispatch`，而 scheduler tick 仍保持 `pause`，不再错误假设调度器会直接越过暂停态。
- 验证命令：
  - `dart format apps/novel_agent_app/tool/mock_long_task_probe.dart`
  - `dart run apps/novel_agent_app/tool/mock_long_task_probe.dart`
  - `powershell -ExecutionPolicy Bypass -File tools/run_release_readiness_long_task_mock_probe.ps1`
- 验证结果：
  - 上述命令全部通过。
  - probe 最新报告位于 `artifacts/mock_long_task_probe_workspace/<timestamp>/mock_long_task_probe_report.json` 与 `.md`，最近一次包装入口运行在 `2026-06-05T13-15-07.995159` 产出 `8/8` 通过。
  - 报告已稳定区分：
    - 正常章节交付 `success`
    - 空正文 `recoverable`
    - 标题-only / 严重字数偏离 `content_quality_failed`
    - information 等待确认 `waiting_user`
    - 预算边界 `budget_failed`
    - transport / failed-task `technical_failed`
  - 本轮同时验证了 `LongTaskSupervisor` 能消费共享写作结果把运行实例推进到 `failed_manual_attention`，以及 recovery/scheduler 链路会为预算边界保留 `resume_dispatch` 建议。
- 剩余风险：
  - 本轮是 mock probe 回归，不代表真实 provider 质量已验收；真实模型下的提示词稳定性、字数波动和 provider 差异仍需后续真实 probe session 继续验证。
  - 当前 probe 报告仍以 artifacts 工作区为输出，尚未接入更高层的统一回归索引；这不阻断 `RRP-06`，但后续 probe/packaging session 可再统一归档。
  - workflow runtime 在“业务执行成功但共享结果提示需修补/人工处理”时仍可能返回 `ok=true`；本轮 probe 已按共享结果合同而不是宿主布尔值验收，这一点后续 GUI/CLI 展示层仍需保持一致口径。
- 下一步：
  - 执行 `RRP-07`：只做 information / 资料 / 巧思 / 拆书资产的共享投影与可回看闭环，不开启真实 provider 验收，也不要跳到 `RRP-08`。

### RRP-07 完成记录

- 状态：已完成
- 完成时间：2026-06-05 13:25:18
- 主要改动：
  - 补强 `packages/novel_agent_adapters/lib/src/workflow/project_information_activation_bridge_service.dart`：information activation item 现在会在 metadata 中稳定保留 `source_refs`，research note 也显式带出 `source_url_or_ref`，不再只把来源埋在 activation 文本里。
  - 补强 `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart`：共享 `writing_execution_result.information.metadata` 现在会带出 activation report 的 `selected/omitted/truncated item ids`、source kind 计数、target paths，以及对应 source refs 摘要，让 information 激活证据能进入共享运行结果，而不是只剩总数统计。
  - 扩展 focused tests：
    - `packages/novel_agent_core/test/writing_execution_result_contracts_test.dart` 新增 information metadata 回写断言，覆盖 selected/omitted/truncated/source refs 进入共享结果；
    - `packages/novel_agent_adapters/test/project_information_activation_bridge_service_test.dart` 增加 activation item source refs / research source 回指断言；
    - 新增 `packages/novel_agent_adapters/test/project_semantic_review_information_service_test.dart`，验证 semantic review bridge 能把 analysis review 提案持久化为 knowledge/design/research，并刷新用户投影。
  - 本轮同时复核现有闭环而不新增 GUI/联网：
    - Markdown 投影继续只是用户可读投影，结构化事实源仍在 `.novel_agent/information/*`；
    - 拆书桥继续通过既有 `book_deconstruction_controller_test.dart` 验证能写入 knowledge/design/research/reference 并刷新投影。
- 验证命令：
  - `dart test test/writing_execution_result_contracts_test.dart test/project_context_file_selection_service_test.dart test/information_markdown_projection_services_test.dart test/semantic_review_information_bridge_service_test.dart`
  - `dart test test/project_information_activation_bridge_service_test.dart test/project_information_projection_writer_service_test.dart test/project_information_domain_tool_executor_test.dart test/project_context_activation_service_test.dart test/project_semantic_review_information_service_test.dart`
  - `flutter test test/book_deconstruction_controller_test.dart`
- 验证结果：
  - 上述命令全部通过。
  - 共享写作结果现在已经能携带 information 激活的关键闭环证据：selected / omitted / truncated item ids、source kind counts、target paths 与 source refs 摘要。
  - focused tests 已确认：
    - knowledge / design / research / reference 可保存并写出用户投影；
    - activation report 的 selected / omitted / truncated 结果与 source refs 能回流到共享结果；
    - `knowledge/项目知识摘要.md`、`knowledge/设计元素摘要.md`、`research/资料研究摘要.md`、`references/引用作品边界.md` 仍只是 projection，不会取代隐藏事实源；
    - semantic review bridge 与拆书桥都能把 design / knowledge 信息真实落盘。
- 剩余风险：
  - 当前共享结果只回写 information 激活的关键证据摘要，不会内嵌整份 activation report；若后续 GUI/CLI 需要更细粒度 drill-down，仍应读取正式 report 或事实源文件。
  - 本轮验证的是 focused contract / adapter / controller 闭环，不代表普通项目、长任务、拆书续写三条运行路径已经全部共用同一 information hook；这属于 `RRP-08` 范围。
  - 本轮没有开启真实联网或 GUI 新页面，外部 research provider 的真实行为与更大拆书样本仍留给后续 session。
- 下一步：
  - 执行 `RRP-08`：只打通普通项目、长任务、拆书共享 information 桥，补齐三条路径的 adapter/runtime hook 与 focused tests；不要开启 `RRP-09`。

### RRP-08 完成记录

- 状态：已完成
- 完成时间：2026-06-05
- 主要改动：
  - 审计确认普通项目会话章节与长任务章节都通过 `ProjectWorkflowRuntimeBridgeService -> ProjectContextActivationService -> ProjectInformationActivationBridgeService` 进入同一 information activation 合同；拆书路径继续通过 `BookDeconstructionNarrativePersistenceService` 将 knowledge/design/research/reference 写入同一 `.novel_agent/information/*` 事实源与共享投影。
  - 补强 `packages/novel_agent_adapters/test/project_workflow_runtime_service_test.dart`：长任务一章 focused test 现在会先写入 knowledge/design/research/reference，再验证 chapter runtime 同时暴露 information 写入工具、activation report 选中四类 information source，并把 `selected_item_ids` 回写到共享 `writing_execution_result.information.metadata`。
  - 补强 `apps/novel_agent_app/test/book_deconstruction_controller_test.dart`：拆书小样本在确认写入后，会立刻通过 `ProjectContextActivationService` 重新构建 activation report，验证拆书产物可被普通 chapter continuation 当作同一 information 合同选中，而不是停留在私有拆书层。
  - 本轮未新增 GUI、未跑真实 provider、未引入题材化字段；adapter/runtime hook 经审计无需再补代码，缺口只在 focused tests 与会话记录。
- 验证命令：
  - `dart test test/project_workflow_runtime_service_test.dart`（目录：`packages/novel_agent_adapters`）
  - `flutter test test/book_deconstruction_controller_test.dart`（目录：`apps/novel_agent_app`）
- 验证结果：
  - 长任务章节测试通过，确认 chapter runtime 已共享普通项目相同 information tool exposure 与 activation evidence 回写。
  - 拆书控制器测试通过，确认拆书写入的 knowledge/design/research/reference 可被同一 `ProjectContextActivationService` 重新激活。
  - `RRP-08` 验收目标已满足：ordinary writing、long task、book deconstruction continuation 三条路径共享同一 information 合同，拆书产物可被后续写作激活。
- 剩余风险：
  - 本轮仍是 focused contract/regression 覆盖，未做大型真实拆书样本或多章连续运行压测。
  - 拆书产物默认仍停留在 analysis namespace；是否提升到正式 writing namespace 仍取决于后续人工/策略确认，这符合当前约束。
- 下一步：
  - 停在 `RRP-08`，不要自动开启 `RRP-09`。

### RRP-09 完成记录

- 状态：已完成
- 完成时间：2026-06-05
- 主要改动：
  - 在 `packages/novel_agent_core/lib/src/agents/` 新增并导出强类型多智能体执行包合同：
    - `ExecutionPackage`
    - `ChildRunPackage`
    - `CollaborationResultPackage`
    - 以及 goal / context / permission / model / budget / failure / skill loadout / merge contract 等子合同
  - 重写 `sub_agent_run_package_service.dart`：
    - `buildSubAgentRunPackage(...)` 现在会同时产出兼容旧调用面的顶层 JSON，以及稳定的 `execution_package` / `child_run_package`
    - package 中显式记录目标、上下文摘录、约束、技能范围、权限边界、模型提示、预算、失败策略、计划子成员列表
    - 多成员 group 会保留完整 children outline，单次实际 child run 只选择其中一个 child package 执行
  - 重写 `sub_agent_result_package_service.dart`：
    - success / failure 结果都会附带稳定的 `collaboration_result_package`
    - merge contract 明确声明 `main_agent_merges`、`allows_direct_delivery=false`，并把 `execution_package_id` / `child_run_package_id` 传回主链
  - 更新 `sub_agent_execution_service.dart` 与 `writing_execution_result_normalizer_service.dart`：
    - parent agent / parent model 会进入 child run package
    - collaboration summary 现在可回收 execution package / child run package 关系，正式接到 RRP-02 共享写作结果合同
  - 默认禁止 child 正式交付：
    - run package 默认把 `submit_chapter_delivery` 加入 blocked tools
    - focused execution test 证明 child 直接尝试正式交付时会被 runtime 拦下
- 验证命令：
  - `dart test test/sub_agent_package_contracts_test.dart test/sub_agent_execution_service_test.dart test/agent_services_test.dart test/agent_run_services_test.dart test/writing_execution_result_contracts_test.dart`（目录：`packages/novel_agent_core`）
- 验证结果：
  - 上述 focused tests 全部通过。
  - 单成员组、多成员组、子上下文隔离、结果 package 与共享写作结果关系均已被覆盖。
  - 子任务包不再依赖完整主会话；协作结果可结构化回传主链，并被 `WritingExecutionResultNormalizerService` 消费。
- 剩余风险：
  - 本轮只收口 package contract，本身不解析 child-specific effective model/tool policy；那一层仍属于 `RRP-10`。
  - 当前 permission contract 只把“默认无正式交付权/无递归委派/无直接问用户”写稳并做回归验证，更多 child tool/profile 细粒度差异仍待下一轮。
- 下一步：
  - 停在 `RRP-09`，不要自动开启 `RRP-10`。

### RRP-10 完成记录

- 状态：已完成
- 完成时间：2026-06-05
- 主要改动：
  - 新增 `SubAgentEffectiveExecutionProfileService`，统一解析 child effective model/tool/budget profile，并在 `SubAgentExecutionService` 中真正使用 child-specific `model_id`、`request_options`、`allowed_tool_ids`。
  - 扩展 child permission contract，补齐 `allowed_tool_ids`；`SubAgentRunPackageService` 现在会收口 child `tool_policy`，并默认额外封禁 `call_sub_agent`、`present_user_options`、`submit_chapter_delivery`、`start_long_task_run`。
  - `GenerateDraftUseCase` 与 `ProjectWorkflowRuntimeService` 已把 `AppSettings` 和 child binding scope 透传到 child runtime，避免 workflow child 一律退回父模型。
  - 新增/扩展 tests，覆盖 writer/reviewer/researcher 的 child-specific model/tool policy，以及 child 默认不能递归委派、不能请求用户、不能启动长任务。
- 验证命令：
  - `cd packages/novel_agent_core && dart test test/sub_agent_execution_service_test.dart`
  - `cd packages/novel_agent_core && dart test test/sub_agent_package_contracts_test.dart test/model_execution_profile_service_test.dart`
  - `cd packages/novel_agent_adapters && dart test test/project_workflow_runtime_service_test.dart`
- 验证结果：
  - 上述命令均通过。
  - mock 已可观测 child-specific model/tool policy 生效，workflow runtime 中 child 不再默认继承父模型。
- 剩余风险：
  - 当前 project agent binding 已支持通过 runtime context 参与 child profile 解析，但尚未接入独立的项目级 binding 仓储读取链；后续若要做 GUI/项目持久化编辑，应在不破坏当前 runtime 合同的前提下补齐来源。
  - `provider_profile` 目前仍主要通过 runtime settings provider id / override model id 生效；如果后续要支持更复杂的 provider profile 路由，建议继续沿 `ModelExecutionProfileService` 扩展，而不要分叉第二套解析器。
- 下一步：
  - 停在 `RRP-10`，不要自动开启 `RRP-11`。

### RRP-11 完成记录

- 状态：已完成
- 完成时间：2026-06-05
- 主要改动：
  - 新增 `SkillCapabilityCatalogService`、`SkillCapabilityRequirementService`、`ToolPermissionProfileService`，把技能的 capability requirement 与工具权限画像解耦，明确“技能不是权限，权限来自独立 tool permission profile / tool policy”。
  - `SkillLoadoutConflictPolicyService` 现在会在技能展开/可用性过滤之后继续执行权限兼容检查：对缺失必需能力的技能做阻止装载或降级保留，对缺失可选能力的技能输出用户可理解 issue。
  - `AgentSkillLoadoutIssue` 扩展了 `message` 与 `metadata`，并补充 capability mismatch / degradable skill 相关 issue code；来源继续只区分 `builtin` / `non_builtin`。
  - `SkillPackageValidatorService` 新增 capability 词表检查，未识别 capability requirement 会显式告警，避免后续绑定阶段静默放行。
- 验证命令：
  - `cd packages/novel_agent_core && dart test test/agent_skill_loadout_contracts_test.dart`
  - `cd packages/novel_agent_core && dart test test/package_markdown_parser_service_test.dart`
  - `cd packages/novel_agent_adapters && dart test test/project_agent_skill_runtime_loadout_service_test.dart test/project_agent_skill_tool_executor_test.dart`
  - `cd packages/novel_agent_adapters && dart analyze lib/src/tools/project_agent_skill_tool_executor.dart`
- 验证结果：
  - 上述命令均通过。
  - tests 已覆盖技能组、额外技能、禁用技能、权限不匹配、可降级技能，并验证 issue message 会输出“需要联网权限但当前只读”这一类用户可理解说明。
- 剩余风险：
  - 当前 capability 词表仍是本轮收口出的第一版抽象，后续若新增新的宿主高风险能力，应优先扩展同一词表，而不是重新把具体工具名写回技能依赖。
  - 现有 UI/探针如果只展示 issue code 而不展示 issue message，还需要在后续界面轮次补 UI 投影；本轮 core/adapters 已把 message/metadata 准备好。
- 下一步：
  - 停在 `RRP-11`，不要自动开启 `RRP-12`。

### RRP-12 完成记录

- 状态：已完成
- 完成时间：2026-06-05
- 主要改动：
  - 在 `packages/novel_agent_core/lib/src/ecosystem/` 新增非内置生态资产 proposal 合同、路径服务、生命周期服务，以及 `skill-group` / `agent-group` 最小校验器，覆盖 `proposal -> validated -> confirmed -> installed / rejected`。
  - 补齐技能、智能体、技能组、智能体组的草案校验基线：版本、摘要、风险说明、能力需求审计，以及导入/保存后的 validation errors / warnings 留痕。
  - 将 `EcosystemEntryEditorService`、`EcosystemEntryCreationPlanService`、`ImportCustomizationBundleUseCase` 改为优先写入 `.novel_agent/ecosystem/proposals/...`，不再让非内置新增/导入资产直接落入正式安装目录；同时修正保存链路，避免 proposal 化时误删旧正式文件。
- 验证命令：
  - `dart test test/ecosystem_asset_proposal_service_test.dart`
  - `dart test test/customization_use_cases_test.dart test/package_markdown_parser_service_test.dart`
  - `flutter test test/ecosystem_entry_proposal_services_test.dart`
  - `flutter test test/agent_ecosystem_view_data_service_test.dart test/ecosystem_entry_proposal_services_test.dart`
- 验证结果：
  - 上述命令全部通过。
- 剩余风险：
  - proposal 文件已经具备可审计生命周期与保存入口，但“确认安装”目前主要通过 core service 能力和 tests 收口，GUI 侧还没有独立的确认/安装操作入口。
- 下一步：
  - 停在 `RRP-12`，不要自动开启 `RRP-13`。

### RRP-13 完成记录

- 状态：已完成
- 完成时间：2026-06-05
- 主要改动：
  - 在 `packages/novel_agent_core/lib/src/agents/` 为子智能体运行合同补齐协作预算字段：`max_concurrent_children`、`token_budget`、`max_retry_count`、`max_tool_rounds`、`timeout_seconds`，并新增标准 child failure disposition：`retry_child`、`skip_child`、`fallback_single_main`、`require_user`。
  - 更新 `SubAgentExecutionService` 与 `SubAgentResultPackageService`：支持子链 timeout / 模型失败 / 空返回的局部重试、工具硬错误的 skip-child、token budget 耗尽时 fallback-single-main，并把失败类别、disposition、attempt count、failure summary 写入稳定结果包。
  - 更新 `WritingExecutionCollaborationSummary` 与 normalizer：共享运行结果现在会输出协作 failure summary、blocking failure count、各 disposition 计数；`require_user` 会进入 user-action-required，`retry_child` 进入 recoverable-failure，`skip_child` / `fallback_single_main` 只标记 degraded，不默认放大成长任务失败。
- 验证命令：
  - `dart test test/sub_agent_package_contracts_test.dart test/sub_agent_execution_service_test.dart`
  - `dart test test/long_task_runtime_services_test.dart`
  - `dart test test/writing_execution_result_contracts_test.dart`
- 验证结果：
  - 上述命令全部通过。
- 剩余风险：
  - 当前 runtime 已经有预算合同和局部恢复策略，但 `max_concurrent_children` 仍主要作为合同与审计字段；真正的多子链并发 fanout 调度还没有在本 session 展开。
- 下一步：
  - 停在 `RRP-13`，不要自动开启 `RRP-14`。
- 验证命令：
- 验证结果：
- 剩余风险：
- 下一步：

### RRP-14 完成记录

- 状态：已完成
- 完成时间：2026-06-05 15:05:28
- 主要改动：
  - 在 `packages/novel_agent_core/lib/src/agents/` 新增 `CollaborationConflictRecord` / `CollaborationConflictEvidence` 与 `CollaborationArbitrationResult` 合同，并导出到 `novel_agent_core.dart`；风险等级、证据、建议、采纳提示、置信度现在有稳定结构，不再只靠 loose metadata。
  - 扩展 `CollaborationResultPackage` 与 `SubAgentResultPackageService`：
    - child success / failure result 现在都可稳定携带 `collaboration_conflicts` 与 `collaboration_arbitration_result`；
    - 支持 `collaboration_conflicts` 列表或 inline `risk/evidence/suggestion/adoption_hint/confidence` 字段自动归一化；
    - 默认按风险推导子级仲裁：低风险 `auto_resolved`，中风险 `needs_repair`，高风险 `needs_user_confirmation`。
  - 扩展 `WritingExecutionCollaborationSummary` 与 `WritingExecutionResultNormalizerService`：
    - 聚合层会汇总 conflict records，并按 `group_key/subject/target` 做仲裁归并；
    - 低风险冲突自动归并为共享结果中的协作摘要，不放大成失败；
    - 中风险冲突进入 `recoverable_failure` 与 `repair_collaboration_conflict`；
    - 高风险冲突进入 `user_action_required` 与 `confirm_collaboration_conflict`，不会静默落盘。
  - 扩展 checkpoint review 链：
    - `LongTaskCheckpointReviewService` 现在会从共享 `writing_execution_result` 投出 `collaboration_signal`；
    - `LongTaskCheckpointSeverityService`、`LongTaskCheckpointDispositionService`、`LongTaskCheckpointReviewMarkdownRenderer` 已消费该信号，让高风险协作冲突进入真正的 gate / 用户确认，而不是被旧的 narrative risk 逻辑忽略。
  - 补 focused tests，覆盖：
    - child result package 的 conflict/arbitration 合同；
    - 低风险自动归并；
    - 高风险转 `user_action_required`；
    - checkpoint review 对高风险协作冲突的拦截；
    - long-task recovery 对高风险协作冲突的等待用户确认路径。
- 验证命令：
  - `cd packages/novel_agent_core; dart test test/sub_agent_package_contracts_test.dart test/writing_execution_result_contracts_test.dart test/long_task_checkpoint_review_service_test.dart test/long_task_runtime_services_test.dart`
  - `cd packages/novel_agent_core; dart analyze lib/src/agents lib/src/workflow test/sub_agent_package_contracts_test.dart test/writing_execution_result_contracts_test.dart test/long_task_checkpoint_review_service_test.dart test/long_task_runtime_services_test.dart`
- 验证结果：
  - 上述 focused tests 全部通过。
  - `dart analyze` 仅报出两个既有 warning：
    - `lib/src/agents/sub_agent_execution_service.dart:91` 未使用字段 `_toolExposurePolicyService`
    - `lib/src/agents/tool_permission_profile_service.dart:11` 未使用字段 `_capabilityCatalogService`
  - `RRP-14` 验收目标已满足：协作冲突可结构化记录，低风险可自动处理，中高风险会进入修订或用户确认；高风险冲突不会静默通过主链。
- 剩余风险：
  - 当前冲突归并优先依赖 child result 提供的 `group_key/subject/target`；如果后续 provider/agent prompt 输出质量不稳定，仍应在 `RRP-15` 之后继续校验 runtime 侧是否稳定产出这些字段。
  - 本轮只收口 core / workflow 合同与 focused tests，GUI 侧尚未把 `collaboration_signal` 做成人类更容易浏览的专门面板；这属于后续多智能体可视化 session 范围。
  - 目前的冲突自动归并策略是“低风险 + 高置信优先”，后续若要支持更复杂的主次专家权重，应继续沿同一 arbitration contract 扩展，不要再分叉平行判定。
- 下一步：
  - 停在 `RRP-14`，不要自动开启 `RRP-15`。

### RRP-15 完成记录

- 状态：已完成
- 完成时间：2026-06-05
- 主要改动：
  - 在 `packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart` 为普通会话/长任务共享生成链新增 `selectedCollaborationGroup` 入口，并把当前协作组快照写入 `contextPack` 与 `mainContext`；修复原先直接使用 `optionalGroups.first` 的错误，同时为“项目仅有单智能体绑定、无显式 group”场景补上单成员协作组合同兜底。
  - 在 `packages/novel_agent_core/lib/src/agents/sub_agent_group_selection_service.dart` 与 `sub_agent_execution_service.dart` 收口子智能体选组优先级：当前项目选中的协作组和显式 `agent_id` 现在优先于启发式 `optional_review_room` / `optional_editorial_room` 回退，避免 child run package 漂到错误 group。
  - 在 `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart` 把 opening projection 的当前组转换为稳定 runtime group 文档并传入普通会话发送链；成员摘要缺失时，会用当前可用 agent 摘要兜底，避免 UI 投影里只剩 group id 造成运行链丢成员上下文。
  - 在 `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart` 新增项目组选择加载入口，长任务正文执行与 postprocess 现在都会读取项目已保存的 `ProjectAgentGroupSelection` 并传给 `GenerateDraftUseCase`；若项目仍是旧单智能体形态，则统一退化为单成员组合同，不再回落到第一个 optional group。
  - 在 app / cli 装配层接入 `ProjectAgentGroupBindingRepository.loadSelections(...)`；补 focused tests，覆盖：
    - GUI 当前 group -> 普通会话 runtime 参数
    - 项目已选 group -> workflow child run package `group_id`
    - 单智能体项目 -> 单成员协作组合同
- 验证命令：
  - `dart test test/draft_generation_use_case_test.dart`（目录：`packages/novel_agent_core`）
  - `dart test test/project_workflow_runtime_service_test.dart`（目录：`packages/novel_agent_adapters`）
  - `flutter test test/workbench_conversation_controller_agent_selection_test.dart`（目录：`apps/novel_agent_app`）
- 验证结果：
  - 上述 focused tests 全部通过。
  - 已证明当前项目选择的协作组会真实进入普通会话与 workflow runtime，并继续进入 child run package / collaboration result package，不再被 `optionalGroups.first` 或启发式内置组静默覆盖。
  - 单智能体项目在没有显式 group 的情况下会稳定生成单成员协作组合同，满足 `RRP-15` 的兼容性约束。
- 剩余风险：
  - workflow runtime 目前只读取项目级 group selection，不额外读取项目级 agent binding 仓储；对旧单智能体项目已用单成员组合同兜底，但若后续要把“agent binding -> opening projection -> runtime group”做成更细的跨作用域解释链，仍建议沿现有 resolver 扩展，而不要分叉新的 runtime 私有规则。
  - 本轮 focused tests 已证明运行链参数和 child run package 合同正确，但尚未把 skill loadout / group/member 上下文做成更高层 GUI 可视化摘要；这属于后续 runtime exposure / projection session 范围。
- 下一步：
  - 停在 `RRP-15`，不要自动开启 `RRP-16`。

### RRP-16 完成记录

- 状态：已完成
- 完成时间：2026-06-05 15:51:40
- 主要改动：
  - 在 `apps/novel_agent_app/lib/shared/services/` 新增 `runtime_exposure_policy_service.dart`，定义 `standard / advanced / diagnostic` 三层运行暴露协议，统一约束“普通层隐藏内部运行术语、内部标识与 raw JSON，进阶/诊断层保留证据”。
  - 更新 `conversation_tool_entry_projection_service.dart`：
    - 普通层工具标题改为人类可读标签，不再直接显示 `read_project_file` 这类原始工具名；
    - 普通层 detail 改为“执行依据”，默认隐藏 `prompt_block_id`、`tool_profile_id`、`execution_constraint`、`sub_session_id` 与 raw JSON；
    - 进阶层保留结构化参数/结果证据，诊断层额外保留 internal evidence 与完整原始事件 JSON。
  - 更新 `long_task_station_view_data_service.dart`、`long_task_station_view_data.dart` 与 `long_task_run_detail_panel.dart`：
    - 普通层把 `Activation / Delivery / Review / Continuity / Information` 改为“本轮上下文 / 正文交付 / 审查结果 / 连续性记录 / 资料与设定”；
    - 长任务详情新增主信息 / 运行诊断分层投影，普通层默认不显示 `workflowStrategyId`、`modeId`、storage strategy、runtime baseline 等技术元信息；
    - widget 仅消费 view-data 提供的标签与 metadata，不再在页面里硬编码暴露策略。
  - 更新 `agent_ecosystem_view_data_service.dart`：
    - 普通层默认隐藏生态条目内部 id、项目内路径、源文件路径；
    - 诊断层保留 `subtitle/id` 与文件来源证据，继续支持专门生态入口排查。
  - 补 focused tests，覆盖会话工具投影、长任务详情投影、生态条目投影在 `standard / advanced / diagnostic` 下的差异。
- 验证命令：
  - `dart analyze apps/novel_agent_app/lib/shared/services/runtime_exposure_policy_service.dart apps/novel_agent_app/lib/features/workbench/application/services/conversation_tool_entry_projection_service.dart apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart apps/novel_agent_app/lib/features/long_task_station/presentation/models/long_task_station_view_data.dart apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart apps/novel_agent_app/lib/features/agent_ecosystem/application/services/agent_ecosystem_view_data_service.dart`
  - `flutter test test/conversation_tool_entry_projection_service_test.dart test/long_task_station_view_data_service_test.dart test/agent_ecosystem_view_data_service_test.dart test/long_task_run_detail_panel_test.dart test/ecosystem_detail_panel_test.dart`
  - `dart analyze apps/novel_agent_app/test/conversation_tool_entry_projection_service_test.dart apps/novel_agent_app/test/long_task_station_view_data_service_test.dart apps/novel_agent_app/test/agent_ecosystem_view_data_service_test.dart apps/novel_agent_app/test/long_task_run_detail_panel_test.dart apps/novel_agent_app/test/ecosystem_detail_panel_test.dart`
- 验证结果：
  - 上述 analyze 与 focused/widget tests 全部通过。
  - 已证明同一运行结果/生态条目可以按 `standard / advanced / diagnostic` 三层输出不同可见信息。
  - 普通层默认不再直接泄漏 `prompt block id`、`tool profile id`、`execution constraint`、`raw JSON`、`sub_session_id`，并且长任务详情中的核心运行摘要已经切换到人类可读标签。
- 剩余风险：
  - 当前三层暴露协议已经进入应用服务与 view-data 默认链路，但“高级/诊断视图切换入口”本身还没有做成显式 GUI 控件；后续若需要让用户主动切换层级，应沿当前 `RuntimeExposureTier` 继续接线，不要在 widget 里分叉第二套规则。
  - 本轮只收口了会话工具时间线、长任务详情和生态条目列表/详情的数据暴露协议；Workbench 主路径和长任务总站更进一步的产品化布局仍属于 `RRP-18 / RRP-19`。
- 下一步：
  - 停在 `RRP-16`，不要自动开启 `RRP-17`。

### RRP-17 完成记录

- 状态：已完成
- 完成时间：2026-06-05 16:04:50
- 主要改动：
  - 首次使用入口改为更接近创作软件的“作品库”路径：`app_shell_navigation_catalog.dart`、`project_open_view_data.dart`、`project_open_view_data_service.dart`、`project_open_page.dart` 现已把主入口文案从“打开项目”收口为“作品库 / 新建作品 / 进入作品”，空状态也直接引导用户先新建作品或导入本地作品。
  - 在 `apps/novel_agent_app/lib/features/settings/application/services/` 新增 `provider_connection_validation_service.dart`，提供最小本地“测试连接”自检：检查接口名称、模型 ID、协议、Base URL、API Key 是否齐备，并给出用户可操作的失败说明或成功提示；本轮不直接发起真实联网请求，避免把 provider 调试链路扩成新的协议分支。
  - 重构 `provider_detail_pane.dart` 的默认路径：
    - 基础信息默认只保留 `接口/厂商名称` 与 `模型 ID`；
    - `测试连接` 按钮与结果反馈进入主路径；
    - `协议` / `Base URL` / `说明` 全部折叠进默认收起的“高级设置”。
  - 在 `model_settings_panel.dart` 增加首次配置提示，明确“先到接口页填写 API Key 并点击测试连接，再回来保存默认模型”的操作顺序。
  - 补 focused/widget tests，锁定：
    - 接口设置页默认隐藏协议与 Base URL；
    - 测试连接入口与失败反馈可见；
    - 作品库导航与首用文案已切换。
- 验证命令：
  - `cd apps/novel_agent_app && flutter test test/provider_settings_panel_test.dart`
  - `cd apps/novel_agent_app && flutter test test/project_open_view_data_service_test.dart`
  - `cd apps/novel_agent_app && flutter test test/app_shell_compact_scaffold_test.dart`
  - `cd apps/novel_agent_app && flutter test test/model_settings_panel_test.dart`
- 验证结果：
  - 上述 focused/widget tests 全部通过。
  - 已验证接口详情默认主路径只暴露首次配置所需字段，高级设置默认折叠，测试连接按钮可给出明确的本地校验反馈。
  - 已验证导航抽屉与作品库页文案同步更新，不会因为主入口改名导致紧凑壳层或项目页测试失效。
- 剩余风险：
  - 当前“测试连接”仍是本地结构化自检，不会真实请求 provider；如果后续需要做真实 provider 连通性探测，应优先沿现有 `provider_connection_validation_service.dart` 向下扩展最小 adapter 端口，而不要在 widget 里直接发请求。
  - 本轮只收口了首次配置和作品入口的默认路径，没有继续扩散到工作台内所有“打开项目”历史文案；这部分如需统一，应放到后续 GUI 主路径 session 中按范围审计后再做。
- 下一步：
  - 停在 `RRP-17`，不要自动开启 `RRP-18`。

### RRP-18 完成记录

- 状态：已完成
- 完成时间：2026-06-05 16:18:19
- 主要改动：
  - 收口 Workbench 普通写作主路径：
    - `conversation_empty_state_action_projection_service.dart` 现在会在普通小说项目的自然写作路径下优先投影 `写第一章 / 新建章节 / 续写下一章 / 整理设定` 这组动作；
    - 仍保留 opening-state 单动作优先级，不把开局中的强制下一步误改成多动作菜单。
  - 收口协作显示层，只保留摘要与设置入口：
    - `workbench_project_panel.dart` 的“项目协作基线”改为“当前协作摘要”，并新增单一 `协作设置` 入口；
    - `workbench_agent_panel.dart` 改成“协作 / 当前协作摘要 / 当前会话分工”，不再把项目协作入口渲染成一块生态配置列表；
    - `project_agent_group_display_text_policy.dart` 与 `conversation_group_display_text_policy.dart` 同步改为更产品化的摘要文案，避免侧栏、项目面板、会话层各说各话。
  - 收口普通项目的首屏引导语：
    - `conversation_opening_guide_view_data_service.dart` 现在直接提示用户可以“写第一章 / 续写下一章 / 整理设定”，并把 grounded / interactive guide 的首句改为章节、场景、设定导向，而不是泛泛地说“想让智能体做什么”。
  - 收口工具调用的人话结果：
    - `conversation_tool_entry_projection_service.dart` 在标准暴露层下，会把工具执行结果优先压缩成 `已保存正文 / 已更新资料 / 需要确认 / 已完成复核 / 需要处理` 这类结果语言；
    - 详细依据仍保留在 detail 区，不改 diagnostic / advanced 层的证据结构。
  - 补 focused tests，覆盖：
    - 空态主动作投影；
    - Workbench 项目/协作面板的可见文案与交互；
    - 工具结果摘要的人话化；
    - 协作摘要文案在 shell/service 层不泄漏旧“协作基线”说法。
- 验证命令：
  - `cd apps/novel_agent_app && flutter test test/conversation_empty_state_action_projection_service_test.dart`
  - `cd apps/novel_agent_app && flutter test test/workbench_project_panel_test.dart`
  - `cd apps/novel_agent_app && flutter test test/workbench_agent_panel_test.dart`
  - `cd apps/novel_agent_app && flutter test test/conversation_sidebar_test.dart`
  - `cd apps/novel_agent_app && flutter test test/conversation_tool_entry_projection_service_test.dart`
  - `cd apps/novel_agent_app && flutter test test/project_agent_group_panel_view_data_service_test.dart`
  - `cd apps/novel_agent_app && flutter test test/workbench_workspace_shell_view_data_service_test.dart`
  - `cd apps/novel_agent_app && flutter test test/workbench_center_pane_policy_service_test.dart`
- 验证结果：
  - 上述 focused/widget tests 全部通过。
  - 已验证普通小说项目的空态主路径会自然导向写作，不会把用户先带进工程控制台式动作列表。
  - 已验证项目/协作面板默认只展示摘要与设置入口，不会直接展开第二套生态配置入口。
  - 已验证工具时间线在标准层默认更接近“结果回执”，而不是直接暴露底层工具执行术语。
- 剩余风险：
  - 当前 empty-state 多动作优先只针对普通小说项目的自然写作路径；opening-state 仍保持单动作优先，这是有意保留的开局约束。如果后续希望把 opening-state 也做成多动作写作面板，需要单独审计会不会削弱强约束引导。
  - `ToolEventPresenterService` 底层仍保留更技术化的原始句式；本轮只在 app 层标准投影做了人话压缩，后续如果 CLI 也要同样的人话结果，应沿同一投影策略继续抽象，不要分叉第二套映射。
  - 部分视觉回归测试文件仍包含旧字符串常量，但本轮 focused 范围内的实际服务/widget 测试已经同步通过；如果后续重新启用这些视觉基线，应统一刷新快照与文案断言。
- 下一步：
  - 停在 `RRP-18`，不要自动开启 `RRP-19`。

### RRP-19 完成记录

- 状态：已完成
- 完成时间：2026-06-05 16:29:58
- 主要改动：
  - 在 `apps/novel_agent_app/lib/features/long_task_station/presentation/models/long_task_station_view_data.dart` 为长任务详情新增用户化投影字段：`overviewBlocks`、`resumeActionLabel`、`pendingUserActionLabel`、`pendingUserAction`、`preferredRecentOutput`，并补上默认四块信息区的结构合同。
  - 在 `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart` 收口 `RRP-19` 的默认详情投影：
    - 标准层默认生成四个信息块：`当前进度 / 当前动作 / 需要你处理 / 最近产物`；
    - 把 `failed / step_failed / manual_attention` 映射为 `重试当前步骤`；
    - 把 `waiting_user / waiting_user_checkpoint / waiting_gate` 映射为 `等待确认`，并优先投影可直接打开的确认记录；
    - 优先把最近正文交付、审稿或检查点结果整理成 `查看最近产物`，同时保留原有 narrative / information / diagnostic 数据，不改 supervisor 或 runtime 策略。
  - 更新 `long_task_run_action_bar.dart` 与 `long_task_run_attention_callout.dart`，把默认按钮文案收口为更接近用户动作的 `查看当前任务 / 查看最近产物 / 等待确认 / 继续推进 / 重试当前步骤`，不再把恢复入口只表达成技术化的 `恢复 / 重试推进`。
  - 更新 `long_task_run_detail_panel.dart`：
    - 默认优先展示四个概览块，而不是顺序 dump 全部底层字段；
    - 把诊断信息放进默认折叠的 `ExpansionTile`，仅在存在诊断元数据时显示 `运行诊断`；
    - 保留 narrative / information / related results 的可读标签与打开动作，不删除任何已有证据。
  - 补 focused tests，覆盖：
    - 失败型阻塞与等待确认型阻塞的用户动作投影；
    - 详情页默认出现四个概览块；
    - 诊断标题可见但诊断字段默认折叠，展开后才能看到内部字段。
- 验证命令：
  - `cd apps/novel_agent_app && flutter test test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart`
  - `cd apps/novel_agent_app && dart analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart lib/features/long_task_station/presentation/models/long_task_station_view_data.dart lib/features/long_task_station/presentation/widgets/long_task_run_action_bar.dart lib/features/long_task_station/presentation/widgets/long_task_run_attention_callout.dart lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart`
- 验证结果：
  - 上述 focused/widget tests 全部通过。
  - `dart analyze` 已无新增问题。
  - 已验证标准层详情默认不再直接暴露整串内部元数据，而是先显示四块用户可读信息；失败与等待确认类型会投影到可理解的恢复/确认动作；诊断信息默认折叠但仍可展开查看。
- 剩余风险：
  - 当前“等待确认 / 查看最近产物”仍复用现有 `onLongTaskStationResourceRequested(...)` 打开资源，相当于先把恢复动作产品化为明确入口文案；如果后续要支持更强的“在总站直接确认/继续”交互，应沿现有 view-data/action-handler 合同增量扩展，不要在 widget 内旁路业务动作。
  - `LongTaskRunDetailPanel` 现在仍同时保留 narrative / information / related results 的明细区，标准层已把默认关注点前置到四块概览，但如果后续还要进一步减少普通层信息密度，应继续沿 `overviewBlocks` 与 exposure tier 收口，而不要重新散落硬编码显示逻辑。
- 下一步：
  - 停在 `RRP-19`，不要自动开启 `RRP-20`。

### RRP-20 完成记录

- 状态：已完成
- 完成时间：2026-06-05 16:53:57 +08:00
- 主要改动：
  - 在 `apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart` 建立 `RRP-20` 的 information GUI projection，把用户侧资料回看统一收口为 `知识摘要 / 巧思与设计 / 研究摘要 / 引用边界 / 待确认` 五类视图项，并基于 `activation_report.json` 的 `selected_context_sections / omitted_context_sections` 生成“本轮已使用 / 未使用”的说明。
  - 在 `apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_information_view_data.dart`、`workbench_resource_view_data.dart`、`workbench_view_data.dart` 与 `workbench_pane_view_data_mapper_service.dart` 增加资料区 view-data 合同，让资源侧栏可以独立消费 information projection，而不把 Markdown 投影当事实源。
  - 在 `apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_information_section.dart` 与 `resource_manager_panel.dart` 新增资料区展示：
    - 默认在资源侧栏文件工具下方显示 `资料与设定`；
    - 展示资料摘要、使用/未使用摘要、四类 projection 入口以及 `待确认` 分组；
    - 所有入口继续复用现有 `onResourceEntrySelected(...)` 打开投影文档或结构化 JSON 摘要，不引入完整编辑器。
  - 在 `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart` 补齐控制器接线：
    - 新增 `_buildInformationViewData(...)`，在正常 workspace snapshot 之外，受控扫描 `.novel_agent/information/**` 与 `tracking/**/activation_report.json`，把隐藏的待确认资料和激活记录补回 GUI projection；
    - 在 `loadProject / reloadResourceEntries / restoreWorkbenchSnapshot / save / create / import / toggle directory` 等资源刷新链路中统一维护 `informationViewData`，避免资料区在刷新后丢失；
    - 保持资源树不直接暴露 `.novel_agent` 内部目录，只在资料区以用户术语投影这些内部记录。
  - 补 focused tests：
    - 新增 `apps/novel_agent_app/test/workspace_information_projection_service_test.dart`，覆盖普通用户术语、待确认项以及使用/未使用摘要；
    - 更新 `apps/novel_agent_app/test/resource_manager_panel_test.dart`，覆盖资料区展示和点击打开入口；
    - 回归运行 `workbench_workspace_controller_snapshot_test.dart`，确认控制器改动未破坏现有快照恢复合同。
- 验证命令：
  - `cd apps/novel_agent_app && dart analyze lib/features/workbench/application/controllers/workbench_workspace_controller.dart lib/features/workbench/application/services/workspace_information_projection_service.dart test/resource_manager_panel_test.dart test/workspace_information_projection_service_test.dart`
  - `cd apps/novel_agent_app && flutter test test/resource_manager_panel_test.dart test/workspace_information_projection_service_test.dart test/workbench_workspace_controller_snapshot_test.dart`
- 验证结果：
  - 上述 `dart analyze` 已通过，无新增问题。
  - 上述 focused/widget/controller tests 全部通过。
  - 已验证资源侧栏现在可以以普通用户术语展示知识、巧思、研究、引用边界和待确认项，并能打开对应投影文档或结构化摘要；同时可回看本轮为何使用/未使用这些资料。
- 剩余风险：
  - 本轮为了拿到 `.novel_agent/information/**` 的待确认记录，在 app 控制器中加入了受控的本地只读扫描；它只读取 `RRP-20` 需要的内部资料与激活报告，但后续如果要把这种内部索引能力产品化，应继续往共享 repository / adapter 合同收口，避免更多 GUI 控制器各自扫描内部目录。
  - 当前“为何未使用”仍依赖激活报告中的现有 `selected_context_sections / omitted_context_sections` 证据链；如果后续 runtime 想细分“未使用原因”的维度，应扩展同一报告合同，不要在 GUI 层再发明第二套推断逻辑。
- 下一步：
  - 停在 `RRP-20`，不要自动开启 `RRP-21`。

### RRP-21 完成记录

- 状态：已完成
- 完成时间：2026-06-05 17:01:56 +08:00
- 主要改动：
  - 在 `apps/novel_agent_app/lib/features/book_deconstruction/presentation/models/` 新增 `book_deconstruction_followup_route_view_data.dart`、`book_deconstruction_asset_status_view_data.dart`、`book_deconstruction_information_bridge_view_data.dart`，把拆书后的“后续路线”和“共享资料桥接状态”收口成独立 view-data，而不是把这些说明散落在 widget 文案里。
  - 在 `apps/novel_agent_app/lib/features/book_deconstruction/presentation/models/book_deconstruction_view_data.dart` 为拆书页增加 `informationBridge` 字段，让预览页既能继续显示 continuity 菜单，也能并行显示后续用途摘要与共享资料状态。
  - 在 `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart` 为 `RRP-21` 增加 app 层 GUI projection：
    - 新增 `普通续写 / 长任务续写 / 共享资料沉淀 / 解说与分析` 四类后续路线说明；
    - 基于 `BookDeconstructionDraftBuildResult.narrativeArtifacts` 和 `extractionResult` 生成 `设定与章纲 / 角色与组织 / 伏笔-时间线-关系 / information 资料 / design 巧思` 的数量与可用状态；
    - 明确把拆书产物描述为“确认后进入共享 information GUI”，与 `RRP-20` 的资料回看面板打通，不把拆书产物留在私有资料层。
  - 在 `apps/novel_agent_app/lib/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart` 新增 `后续用途与共享资料桥` 区块：
    - 用户能直接看到拆书后续可走的普通续写、长任务续写、资料沉淀、解说分析路线；
    - 用户能看到本次已生成的可复用资料数量，以及这些资料确认后会进入 `资料与设定 / 巧思与设计 / 研究 / 引用边界` 等共享信息视图。
  - 补 focused tests：
    - 更新 `apps/novel_agent_app/test/book_deconstruction_view_data_service_test.dart`，用小样本拆书输入验证路线、information/design 数量与共享资料状态；
    - 新增 `apps/novel_agent_app/test/book_deconstruction_preview_panel_test.dart`，验证 GUI 确实会展示后续路线和共享资料桥接术语。
- 验证命令：
  - `dart analyze apps/novel_agent_app/lib/features/book_deconstruction apps/novel_agent_app/test/book_deconstruction_view_data_service_test.dart apps/novel_agent_app/test/book_deconstruction_preview_panel_test.dart`
  - `cd apps/novel_agent_app && flutter test test/book_deconstruction_view_data_service_test.dart test/book_deconstruction_preview_panel_test.dart`
- 验证结果：
  - 上述 `dart analyze` 已通过，无新增问题。
  - 上述 focused/view-data/widget tests 全部通过。
  - 已验证小样本拆书导入后，GUI 能显示后续用途、information/design 可复用状态，以及这些资料会进入共享 information GUI，而不是停留在私有拆书层。
- 剩余风险：
  - 本轮只做了 GUI 投影与状态说明，没有新增“从拆书页直接跳转到共享资料页”的交互按钮；当前仍以确认后通过共享工作台回看资料为主。如果后续要加直接跳转，应沿现有 page/controller/action-handler 合同扩展，不要在 widget 内侧路由。
  - `BookDeconstructionDraftBuilderService` 当前小样本生成的 `foreshadow / timeline / relationship` 仍可能为 0，因此本轮只是把这些共享资产的状态显式展示出来；如果后续希望拆书阶段更稳定地产生这些连续性资产，应在 core 的 extraction / application plan 层单独推进，而不要在 GUI 层写死题材逻辑。
- 下一步：
  - 停在 `RRP-21`，不要自动开启 `RRP-22`。

### RRP-22 完成记录

- 状态：已完成
- 完成时间：2026-06-05 18:34:52 +08:00
- 主要改动：
  - 收口生态页内置 / 非内置资产区分：
    - `agent_ecosystem_view_data_service.dart` 现在会把生态条目统一投影为 `内置资产 / 项目草案 / 项目覆盖 / 非内置资产`，并把权限边界摘要、配置校验 issue、可复制内置组标记一起下发到 GUI；
    - 内置 `skill-groups / agent-groups` 现在会在列表与详情层明确标记为可复制草案，而不是一律被视为“不可编辑”。
  - 收口内置组最小安全复制编辑：
    - `app_shell_controller.dart` 放开了内置技能组与智能体组的编辑入口，只要当前项目已打开，就允许用空 `sourceContent` 打开预填编辑器；
    - `ecosystem_entry_editor_service.dart` 现在会把所有编辑保存统一写成 `.novel_agent/ecosystem/proposals/...` 下的 proposal，不绕过确认流程；
    - 对智能体组补上 `primary_agent_id / required_agent_ids / optional_agent_ids / member_roles` 的草案保存与校验视图，支持最小安全的主智能体、必需成员、可选成员编辑。
  - 收口生态详情 / 编辑弹层的人话提示：
    - `ecosystem_detail_panel.dart` 现在会显示权限边界、配置提示，并对内置组显示 `复制为项目草案`；
    - `ecosystem_editor_overlay.dart` 现在会显示来源说明、权限边界、配置 issue，并补上智能体组的主智能体 / 必需成员 / 可选成员字段；
    - 内置组的来源说明明确为“不能原地改写，复制后保存为项目草案”，避免误解为直接修改内置资产。
  - 收口项目技能装载的人话权限提示：
    - `project_skill_loadout_detail_panel.dart` 现在会把权限边界摘要和技能装载 issue 直接展示出来；
    - `project_skill_loadout_view_data_service.dart` 的新增权限边界摘要字段已在 GUI 侧完成消费，技能权限不匹配会用人话提示而不是只暴露内部 issue code。
  - 补 focused tests：
    - 更新 `agent_ecosystem_view_data_service_test.dart`、`ecosystem_detail_panel_test.dart`、`ecosystem_entry_proposal_services_test.dart`、`project_skill_loadout_view_data_service_test.dart`、`project_skill_loadout_detail_panel_test.dart`，锁定内置组复制入口、主智能体标注、proposal 保存字段、权限边界摘要和 issue 可见性。
- 验证命令：
  - `dart analyze apps/novel_agent_app/lib/features/agent_ecosystem/application/services/agent_ecosystem_view_data_service.dart apps/novel_agent_app/lib/features/agent_ecosystem/application/services/ecosystem_entry_editor_service.dart apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/ecosystem_detail_panel.dart apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/ecosystem_editor_overlay.dart apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/project_skill_loadout_detail_panel.dart apps/novel_agent_app/lib/app/state/app_shell_controller.dart apps/novel_agent_app/test/agent_ecosystem_view_data_service_test.dart apps/novel_agent_app/test/ecosystem_detail_panel_test.dart apps/novel_agent_app/test/ecosystem_entry_proposal_services_test.dart apps/novel_agent_app/test/project_skill_loadout_detail_panel_test.dart apps/novel_agent_app/test/project_skill_loadout_view_data_service_test.dart`
  - `cd apps/novel_agent_app && flutter test test/agent_ecosystem_view_data_service_test.dart test/ecosystem_detail_panel_test.dart test/ecosystem_entry_proposal_services_test.dart test/project_skill_loadout_view_data_service_test.dart test/project_skill_loadout_detail_panel_test.dart`
- 验证结果：
  - 上述 `dart analyze` 已通过，无新增问题。
  - 上述 focused service / widget / proposal tests 全部通过。
  - 已验证生态页现在能明确区分内置资产、项目草案和项目覆盖；内置组可复制为项目草案；智能体组能编辑主智能体 / 必需成员 / 可选成员；技能装载权限不匹配会在 GUI 直接显示人话提示。
- 剩余风险：
  - 本轮只做了“最小安全编辑器”，没有引入完整 prompt block 编辑器；智能体与技能正文仍以 Markdown 主体字段为主，这是有意保持范围收敛。
  - 当前编辑弹层里的 live review 使用本地 `EcosystemEntryEditorService.reviewRequest(...)` 即时计算摘要与 issue，但不会替代保存后的 proposal review；真正的安装确认与校验仍以 proposal 流程为准。
  - 权限边界摘要当前聚焦于 capability requirement 与成员关系，不会在生态页直接展开更深的 runtime/tool policy 细节；如果后续要补更完整的协作运行验证，应放到 `RRP-23` 的 GUI 短探针里继续证明，而不要把 probe 逻辑塞回生态编辑页。
- 下一步：
  - 停在 `RRP-22`，不要自动开启 `RRP-23`。

### RRP-23 完成记录

- 状态：已完成
- 完成时间：2026-06-05 17:41:10 +08:00
- 主要改动：
  - 在 `apps/novel_agent_app/lib/features/workbench/application/services/sub_agent_run_projection_service.dart` 新增子智能体运行投影服务，把 `call_sub_agent` 结果统一收口成 GUI 可消费的 `专家意见 / 证据 / 采纳情况 / 降级处理 / 运行诊断` 结构，不把协作冲突、仲裁结果和 failure disposition 直接散落到 widget。
  - 在 `conversation_session_state_service.dart` 改为通过上述投影服务生成 `SubAgentRunViewData`，让最终结果与流式过程都走同一 app 层投影；并在 `sub_agent_run_view_data.dart` 为子智能体详情增加 `expertOpinion / evidenceItems / adoptionSummary / degradationSummary / diagnosticItems` 字段。
  - 在 `sub_agent_run_detail_view.dart` 与 `sub_agent_run_preview_projection_service.dart` 收口普通用户显示口径：
    - 详情页优先展示 `专家意见 / 证据 / 采纳情况`；
    - child 失败可降级时显示 `降级处理`；
    - 原始 `run_id / agent_id / selected_conflict_id` 只放进折叠的 `运行诊断`；
    - 预览卡将“已降级返回”视为可恢复继续，而不是直接标成失败。
  - 在 `workbench_conversation_controller_agent_selection_test.dart` 增加 controller/viewmodel 级短探针：mock 主智能体一轮里调用两个子智能体，其中一个返回结构化协作建议，另一个以 `fallback_single_main` 方式降级，验证：
    - 当前 opening 协作组确实进入运行链；
    - GUI 状态里出现两个子智能体运行；
    - 成功 child 能投影专家意见/证据/采纳情况；
    - 失败 child 能投影为可恢复的降级继续。
  - 在 `conversation_sidebar_test.dart`、`conversation_streaming_state_service_test.dart`、`sub_agent_run_projection_service_test.dart`、`sub_agent_run_preview_projection_service_test.dart` 补 focused tests，锁定：
    - 普通用户层无原始 id 泄漏；
    - 诊断展开后才看到 raw id；
    - 流式子智能体结果也会投影出专家意见/证据/采纳情况；
    - 降级 child 在预览层不会被误标成硬失败。
- 验证命令：
  - `dart analyze apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart apps/novel_agent_app/lib/features/workbench/application/services/sub_agent_run_projection_service.dart apps/novel_agent_app/lib/features/workbench/presentation/models/sub_agent_run_view_data.dart apps/novel_agent_app/lib/features/workbench/presentation/services/sub_agent_run_preview_projection_service.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/sub_agent_run_detail_view.dart apps/novel_agent_app/test/conversation_streaming_state_service_test.dart apps/novel_agent_app/test/conversation_sidebar_test.dart apps/novel_agent_app/test/sub_agent_run_preview_projection_service_test.dart apps/novel_agent_app/test/sub_agent_run_projection_service_test.dart apps/novel_agent_app/test/workbench_conversation_controller_agent_selection_test.dart`
  - `cd apps/novel_agent_app && flutter test test/conversation_streaming_state_service_test.dart test/conversation_sidebar_test.dart test/sub_agent_run_preview_projection_service_test.dart test/sub_agent_run_projection_service_test.dart test/workbench_conversation_controller_agent_selection_test.dart`
- 验证结果：
  - 上述 `dart analyze` 已通过，无新增问题。
  - 上述 focused service / widget / controller tests 全部通过。
  - 已验证 GUI/viewmodel 层当前协作组会进入普通会话运行链；mock 主智能体可在一轮内回收至少两个 child 结果；普通用户视图展示的是专家意见、证据、采纳情况和降级提示，而不是内部 run id；raw id 只在诊断折叠层可见。
- 剩余风险：
  - 本轮短探针只覆盖 GUI/viewmodel/application 层的 mock 路径，没有跑真实 provider，也没有做更长的多轮协作稳定性验证；这正是本 session 的边界。
  - 子智能体详情现在已有人话分层，但普通层仍保留 `专家原文 / 推理摘要 / 协作轨迹` 明细；如果后续要继续压缩信息密度，应沿这套投影服务继续收口，而不要回到 widget 内直接解析原始 payload。
  - 当前 controller 级 probe 通过 scripted `DraftGenerationResult.executedTools` 模拟主智能体多 child 回合；后续若要继续证明 runtime 与 GUI 同步的更深一致性，应放到后续更接近 adapter/runtime 的 session 中做，而不要在 app 测试里重新拼第二套 runtime。
- 下一步：
  - 停在 `RRP-23`，不要自动开启 `RRP-24`。

### RRP-24 完成记录

- 状态：已完成
- 完成时间：2026-06-05 17:55:12 +08:00
- 主要改动：
  - 在 `apps/novel_agent_app/lib/app/theme/app_typography.dart` 建立 `RRP-24` 的中文字体 fallback 策略，并在 `theme_resolver.dart` 统一注入到 `ThemeData.textTheme / primaryTextTheme`，把 Windows / macOS / Linux 常见 CJK 字体回退链收口到主题底座，避免中文在未显式指定字体时退成 tofu 方框。
  - 在 `apps/novel_agent_app/lib/app/theme/theme_registry.dart` 强化默认暗色主题 token：拉开 `canvas / panel / sidebar / input` 层级差异，提升暗色主文字、弱文字、强调线的对比度，保持浅色主题主色系不大幅扰动，避免把已有 light golden 全部推翻。
  - 修复共享视觉组件的发布阻断：
    - `shared/widgets/action_button.dart` 把按钮文案放进 `Flexible`，解决窄宽度下长中文按钮和图标同行时的 `RenderFlex overflow`；
    - `shared/widgets/section_heading.dart` 改为统一消费 `NovelThemeContext` 的 surface 颜色，不再在深色模式下混用硬编码浅色调；
    - `features/settings/presentation/widgets/settings_header.dart` 改成窄宽度自动转竖排，避免返回按钮和标题说明挤爆页头；
    - `theme_option_tile.dart` 为主题卡片标题 / badge / 描述补 `maxLines + ellipsis`，收口卡片类长文本溢出；
    - `settings_labeled_text_field.dart`、`settings_labeled_dropdown_field.dart`、`settings_labeled_search_dropdown_field.dart`、`settings_switch_row.dart` 改为使用主题 surface 前景色和弱文字色，补齐设置页在深色主题下的可读性。
  - 补 focused/widget tests：
    - `test/app_theme_control_style_test.dart` 新增字体 fallback 与浅/深主题对比度合同；
    - `test/action_button_test.dart` 覆盖长中文按钮在窄宽度下不溢出；
    - `test/theme_settings_panel_test.dart` 覆盖主题设置页在桌面浅色与窄屏深色布局下稳定渲染，并继续验证保存主题设置逻辑。
- 验证命令：
  - `dart analyze apps/novel_agent_app/lib/app/theme/app_typography.dart apps/novel_agent_app/lib/app/theme/theme_resolver.dart apps/novel_agent_app/lib/app/theme/theme_registry.dart apps/novel_agent_app/lib/shared/widgets/action_button.dart apps/novel_agent_app/lib/shared/widgets/section_heading.dart apps/novel_agent_app/lib/features/settings/presentation/widgets/theme_option_tile.dart apps/novel_agent_app/lib/features/settings/presentation/widgets/settings_header.dart apps/novel_agent_app/lib/features/settings/presentation/widgets/settings_labeled_text_field.dart apps/novel_agent_app/lib/features/settings/presentation/widgets/settings_labeled_dropdown_field.dart apps/novel_agent_app/lib/features/settings/presentation/widgets/settings_labeled_search_dropdown_field.dart apps/novel_agent_app/lib/features/settings/presentation/widgets/settings_switch_row.dart apps/novel_agent_app/test/app_theme_control_style_test.dart apps/novel_agent_app/test/action_button_test.dart apps/novel_agent_app/test/theme_settings_panel_test.dart`
  - `cd apps/novel_agent_app && flutter test test/app_theme_control_style_test.dart test/action_button_test.dart test/theme_settings_panel_test.dart`
- 验证结果：
  - 上述 `dart analyze` 已通过，无新增问题。
  - 上述 focused/widget tests 全部通过。
  - 已验证主题底座现在带有中文字体 fallback；暗色主题的面板/输入/侧栏层级更清晰；长中文按钮和主题卡片在窄宽度下不再出现 overflow；设置页主题 tab 在桌面浅色与窄屏深色布局下均可稳定渲染。
- 剩余风险：
  - 本轮采用的是“主题底座统一注入 CJK fallback”而不是直接打包新的开源中文字体文件，因此对常见桌面发布环境已足够稳，但如果后续 `RRP-26` 打包验收发现某目标平台缺少这些 fallback 字体，应该在发布资产阶段补一个明确授权的 OSS CJK 字体，而不要让各页面各自硬编码字体名。
  - 目前仓库里仍有一批较老页面直接使用 `AppPalette` 常量；本轮已经收口共享标题、设置表单和主题页主路径，但如果后续要把“全应用深色一致性”继续做满，应沿 `NovelThemeContext` 继续把这些旧页面逐步迁移，而不要重新增加硬编码色值。
- 下一步：
  - 停在 `RRP-24`，不要自动开启 `RRP-25`。

### RRP-25 完成记录

- 状态：已完成
- 完成时间：2026-06-05 18:01:46 +08:00
- 主要改动：
  - 审计 `agent.md`、`.gitignore`、`tools/repository_secret_scan.dart`、`apps/novel_agent_app/tool/`、`artifacts/`、`local/` 后，确认：
    - `artifacts/`、`local/*`、`test_api.txt`、`.env*`、参考项目目录当前已在 `.gitignore` 隔离；
    - 仓库内目前没有独立 release orchestrator，`RRP-26` 将直接基于 Flutter/Gradle/Windows 构建入口做打包冒烟；
    - `artifacts/` 与 `local/` 中保留的人工探针产物没有被删除，本轮只做边界收口和发布清单更新。
  - 在 `tools/probe_config_support.dart` 与 `apps/novel_agent_app/tool/probe_support.dart` 收紧真实 probe 默认配置策略：
    - `loadLocalProbeApiConfig(...)` / `loadProbeApiConfig(...)` 现在默认只接受 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE`；
    - `test_api.txt` 与 `temp/novel_agent_settings.json` 不再作为默认真实 probe 配置源，只有兼容场景下显式打开 fallback 才允许使用；
    - 错误提示与注释同步改成人话边界，明确“真实额度探针默认不开旧回退”。
  - 补齐正式 probe 目录说明与发布清单：
    - 新增 `apps/novel_agent_app/tool/README.md`，说明 `tool/` 里的脚本属于开发探针而不是正式产品入口，并给出当前长期保留 probe 的分类与理由；
    - 新增 `docs/release-packaging-hygiene-checklist-2026-06-05.md`，收口 `RRP-25` 的发布隔离清单、真实 probe 配置源、密钥扫描命令和 `RRP-26` 打包前必须排除的目录；
    - 更新 `local/README.md`，明确 `NOVEL_AGENT_ENABLE_REAL_PROBES=1` 开闸要求，以及 `local/probe_api.txt` / `NOVEL_AGENT_PROBE_API_FILE` 的使用约定。
  - 对现存真实 probe 做最小边界修正：
    - `real_anthropic_compat_probe.dart` 补显式 `probeName`；
    - `real_workflow_loop_probe.dart` 与 `real_long_task_20_chapter_probe.dart` 显式禁用 legacy/temp fallback，避免它们继续“悄悄”吃旧配置。
  - 补 focused test：
    - `apps/novel_agent_app/test/probe_support_test.dart` 新增断言，验证默认情况下不会再回退到 `test_api.txt`。
- 验证命令：
  - `dart analyze tools/probe_config_support.dart tools/repository_secret_scan.dart`
  - `cd apps/novel_agent_app && flutter analyze tool/probe_support.dart tool/gateway_connect_probe.dart tool/real_anthropic_compat_probe.dart tool/real_general_novel_probe.dart tool/real_long_task_20_chapter_probe.dart tool/real_long_task_probe.dart tool/real_multiscope_pressure_probe.dart tool/real_openai_compat_probe.dart tool/real_option_probe.dart tool/real_workflow_loop_probe.dart test/probe_support_test.dart`
  - `cd apps/novel_agent_app && flutter test test/probe_support_test.dart`
  - `dart tools/repository_secret_scan.dart`
- 验证结果：
  - 上述 `dart analyze` 与 `flutter analyze` 已通过，无新增问题。
  - `probe_support_test.dart` 全部通过，已验证真实 probe 默认不再回退到 `test_api.txt`。
  - `dart tools/repository_secret_scan.dart` 返回 `repository_secret_scan: PASS`。
  - 已确认 `tool/` 下真实 probe 仍需通过显式开闸才能运行，且发布清单中已明确 `artifacts/`、`local/`、参考项目和不跟踪配置不进入打包范围。
- 剩余风险：
  - 本轮选择的是“说明长期保留理由 + 收紧默认边界”，没有大规模迁移 `apps/novel_agent_app/tool/` 里的历史真实 probe；如果后续探针数量继续增长，应在更靠近 devtools 整理的主线里把一部分长期低频脚本继续归档到专门目录，而不是让正式 `tool/` 再次膨胀。
  - 工作区本地仍存在 `local/probe_api.txt` 实文件，这是符合当前约定的本机配置，但 `RRP-26` 打包冒烟时仍需再次确认构建产物不把该文件或其引用链带入包内。
- 下一步：
  - 停在 `RRP-25`，不要自动开启 `RRP-26`。

### RRP-26 完成记录

- 状态：已完成
- 完成时间：2026-06-05 18:11:45 +08:00
- 主要改动：
  - 基于 `RRP-24` / `RRP-25` 的现状，直接对 `apps/novel_agent_app` 执行双端构建冒烟，没有引入新的假工具路径或本地脚本包装：
    - Windows：`flutter build windows --release`
    - Android：`flutter build apk --release`
  - 核对 Android 当前真实构建配置：
    - `android/local.properties` 使用当前机器的真实 `flutter.sdk` 与 `sdk.dir`；
    - `android/app/build.gradle.kts` 仍是默认 `com.example.novel_agent_app`，并且 release 仍复用 debug signing config，这次只记录为发布风险，不在本轮顺手改业务外配置。
  - 对构建产物做发布隔离检查：
    - Windows release 目录递归检查未发现 `local`、`artifacts`、`references`、`test_api.txt`、`MuMuAINovel-main` 等禁带项；
    - `app-release.apk` 内部条目检查同样未发现上述禁带项；
    - Windows 可执行文件做了 8 秒短启动烟测，进程能稳定拉起，随后人工停止，没有出现“启动即崩”。
- 验证命令：
  - `cd apps/novel_agent_app && flutter build windows --release`
  - `cd apps/novel_agent_app && flutter build apk --release`
  - Windows 包内容检查：
    - `Get-ChildItem -Recurse apps\\novel_agent_app\\build\\windows\\x64\\runner\\Release | ...`
  - APK 内容检查：
    - `Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::OpenRead(...app-release.apk) ...`
  - Windows 启动烟测：
    - `Start-Process build\\windows\\x64\\runner\\Release\\novel_agent_app.exe -WindowStyle Hidden -PassThru`
- 验证结果：
  - Windows release 构建通过，产物：`apps/novel_agent_app/build/windows/x64/runner/Release/novel_agent_app.exe`
  - Android release APK 构建通过，产物：`apps/novel_agent_app/build/app/outputs/flutter-apk/app-release.apk`
  - Windows 包内容检查结果：`WINDOWS_PACKAGE_FORBIDDEN_CHECK:PASS`
  - APK 包内容检查结果：`APK_PACKAGE_FORBIDDEN_CHECK:PASS`
  - Windows 启动烟测结果：`WINDOWS_LAUNCH_SMOKE:RUNNING_AFTER_8S`
  - Android 构建过程中只出现 `MaterialIcons-Regular.otf` tree-shake 提示，无额外构建错误。
- 剩余风险：
  - Android `release` 目前仍使用 debug signing config，只适合构建冒烟，不适合正式分发；后续真正发布必须换成正式签名。
  - Android `applicationId` 仍是默认示例值 `com.example.novel_agent_app`，这不是构建阻断，但会阻断正式上架或正式安装包标识。
  - `RRP-24` 采用的是系统 CJK fallback 而非打包 OSS 中文字体；这次双端构建本身通过，但若后续实机验收发现 Android/Windows 某端字体回退不稳定，仍应在发布资产阶段补明确授权字体。
  - 本轮只做了构建与短启动烟测，没有做完整 GUI 关键路径实机操作；这正是后续 `RRP-28` / `RRP-29` 的边界。
- 下一步：
  - 停在 `RRP-26`，不要自动开启 `RRP-27`。

### RRP-27 完成记录

- 状态：已完成
- 完成时间：2026-06-05 18:16:44 +08:00
- 主要改动：
  - 对 `apps/novel_agent_cli` 完成最小边界验收：运行 `dart analyze`、`dart test`，并用真实 `dart run bin/novel_agent.dart ... help` 输出核对当前 CLI 命令面。
  - 确认 CLI 仍保持“共享 core/adapters 的消费壳层”定位，而不是复制 GUI 业务判断：
    - `apps/novel_agent_cli/lib/bootstrap/cli_bootstrap.dart` 仍是唯一组装点，统一注入 `AdapterBundle.standard(...)`、shared repositories、shared services 和 command shell；
    - `workflow` 继续复用 `ProjectWorkflowRuntimeService`、`GenerateDraftUseCase`、模式引导 use case 等共享合同；
    - `project` / `review` / `asset` / `template` 主要负责参数解析、项目定位和终端输出，没有补第二套业务分支。
  - 新增 CLI 发布边界文档 `docs/cli-release-boundary-2026-06-05.md`，明确：
    - 当前最小可用命令；
    - 仍属实验/运维向的长任务、包导入导出类命令；
    - `session` 仍处于迁移期，GUI 仍是 beta 主路径。
  - 顺手修复两个 CLI 关联性错误，避免帮助信息误导当前 release 边界：
    - `template help` 的 `--vars` JSON 示例原本会打印成无效引号形式，现已修正；
    - `session` 原提示提到不存在的 `project inspect`，现已改成真实的 `project summary`。
- 验证命令：
  - `cd apps/novel_agent_cli && dart analyze`
  - `cd apps/novel_agent_cli && dart test`
  - `cd apps/novel_agent_cli && dart run bin/novel_agent.dart help`
  - `cd apps/novel_agent_cli && dart run bin/novel_agent.dart workflow help`
  - `cd apps/novel_agent_cli && dart run bin/novel_agent.dart project help`
  - `cd apps/novel_agent_cli && dart run bin/novel_agent.dart review help`
  - `cd apps/novel_agent_cli && dart run bin/novel_agent.dart asset help`
  - `cd apps/novel_agent_cli && dart run bin/novel_agent.dart template help`
  - `cd apps/novel_agent_cli && dart run bin/novel_agent.dart session`
- 验证结果：
  - `dart analyze` 通过：`No issues found!`
  - `dart test` 通过：`workflow_output_summary_service_test.dart` 共 3 条测试全部通过。
  - 根帮助和各命令帮助均可正常输出。
  - `template help` 现已正确显示 `--vars '{"review_goal":"检查连续性"}'` 示例。
  - `session` 现已明确提示“仍在迁移中，当前优先保证 workflow draft 与 project summary 可用”。
- 剩余风险：
  - CLI 自动化覆盖仍很轻，目前直接测试只覆盖 `workflow_output_summary_service_test.dart`；大量命令面的可信度主要来自 analyze、帮助输出和共享服务接线审查，而不是完整端到端回归。
  - `workflow` 下大量长任务编排、checkpoint、revision、resume 类命令虽然已接通共享 runtime，但更适合作为实验/运维入口，不应在 GUI beta 对外承诺为成熟产品能力。
  - `session` 入口仍只是迁移提示，不应让用户误解为桌面自动会话能力已经完成。
- 下一步：
  - 停在 `RRP-27`，不要自动开启 `RRP-28`。

### RRP-28 完成记录

- 状态：已完成
- 完成时间：2026-06-05 18:24:20 +08:00
- 主要改动：
  - 以现有 GUI widget/viewmodel 测试为基础，补齐并固化发布前关键路径的自动化验收矩阵，新增记录文档 `docs/gui-critical-path-test-matrix-2026-06-05.md`，明确以下路径的对应测试覆盖：
    - 首次启动 / 项目入口；
    - 新建作品；
    - 模型配置视图；
    - 普通写作；
    - 资料回看；
    - 短长任务；
    - 恢复动作；
    - 生态设置入口。
  - 顺手修正一处真实关联性错误：`workbench_navigation_sidebar_test.dart` 仍断言旧文案，已同步到当前实现中的用户口径：
    - 项目面板：`当前协作摘要`
    - 协作面板：`当前会话分工`、`当前智能体`、`项目基线组`
  - 把“普通用户路径无内部术语”收敛成自动断言，而不是只靠人工阅读：
    - `workbench_project_panel_test.dart` 新增 `run_center_contract`、`workflowStrategyId`、`tool_call`、`session.goal` 不应出现在普通项目面板的断言；
    - `task_center_view_data_service_test.dart` 新增恢复摘要不应暴露 `run_center_contract`、`requires_user_action`、`action_package_available`、`revision_resolution_available` 等原始合同字段名的断言。
- 验证命令：
  - `cd apps/novel_agent_app && flutter test test/widget_test.dart test/project_creation_controller_test.dart test/project_create_panel_continuity_test.dart test/project_open_view_data_service_test.dart test/provider_settings_panel_test.dart test/model_settings_panel_test.dart test/conversation_empty_state_action_projection_service_test.dart test/conversation_input_dock_test.dart test/workbench_project_panel_test.dart test/book_deconstruction_preview_panel_test.dart test/project_long_task_summary_view_data_service_test.dart test/long_task_run_detail_panel_test.dart test/task_center_view_data_service_test.dart test/app_shell_activity_rail_test.dart test/workbench_navigation_sidebar_test.dart test/ecosystem_detail_panel_test.dart`
- 验证结果：
  - 关键路径 GUI 自动化通过：`00:14 +37: All tests passed!`
  - 验收套件覆盖的主要路径与证据：
    - 首次启动 / 项目入口：`widget_test.dart`、`project_creation_controller_test.dart`、`project_open_view_data_service_test.dart`
    - 新建作品：`project_create_panel_continuity_test.dart`、`project_creation_controller_test.dart`
    - 模型配置：`provider_settings_panel_test.dart`、`model_settings_panel_test.dart`
    - 普通写作：`conversation_empty_state_action_projection_service_test.dart`、`conversation_input_dock_test.dart`、`workbench_project_panel_test.dart`
    - 资料回看：`book_deconstruction_preview_panel_test.dart`
    - 短长任务 / 恢复动作：`project_long_task_summary_view_data_service_test.dart`、`long_task_run_detail_panel_test.dart`、`task_center_view_data_service_test.dart`
    - 生态设置入口：`app_shell_activity_rail_test.dart`、`workbench_navigation_sidebar_test.dart`、`ecosystem_detail_panel_test.dart`
  - 本轮未跑真实 provider，但测试已证明关键界面可以在中文文案下正常渲染，且普通路径默认不暴露内部合同术语。
- 剩余风险：
  - 本轮是 widget/viewmodel 层验收，不等于完整桌面端人工操作回归；例如窗口级交互、文件选择器、真实本地项目读写组合路径仍主要依赖现有单点测试和后续人工关注。
  - 没有做 Playwright/截图留档，因为当前 widget/viewmodel 测试已足以证明关键中文文案存在且可读；如果后续在真机或不同 DPI 下发现版式问题，再补视觉截图更合适。
  - 真实 provider、长任务稳定性、checkpoint/recovery 的真实执行链仍未在本轮覆盖，这正是 `RRP-29` 的边界。
- 下一步：
  - 停在 `RRP-28`，不要自动开启 `RRP-29`。

### RRP-29 完成记录

- 状态：已完成
- 完成时间：2026-06-05 19:03:17 +08:00
- 主要改动：
  - 按 `RRP-29` 约束，在显式设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1` 后执行真实 provider 验收；只使用本地 probe 配置，不硬编码 key/model。
  - 新增本轮独立报告 `docs/real-provider-regression-report-2026-06-05.md`，把普通项目、10 章长任务、35 章长任务和补充 focused probe 的 PASS/FAIL、失败类型、产物路径统一收口。
  - 为了用同一条长期保留 probe 入口覆盖 `10` 章和 `35` 章两档，不新开脚本，只对 `apps/novel_agent_app/tool/real_long_task_20_chapter_probe.dart` 做最小参数化与产物留存修整：
    - 支持 `--chapter-count=<N>`；
    - 按每次 run 生成独立 `artifacts/real_long_task_chapter_probe_runs/.../report.json`；
    - 保留顶层 latest 报告路径，避免两档运行互相抹掉唯一产物；
    - 记录 `requested_chapter_count`、`checkpoint_interval`、`checkpoint_confirm_count`、`manual_resolution_count`。
- 验证命令：
  - `cd apps/novel_agent_app && dart analyze tool\\real_long_task_20_chapter_probe.dart`
  - `cd apps/novel_agent_app && $env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'; dart run tool\\real_general_novel_probe.dart --chapter-count=5`
  - `cd apps/novel_agent_app && $env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'; dart run tool\\real_long_task_20_chapter_probe.dart --chapter-count=10`
  - `cd apps/novel_agent_app && $env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'; dart run tool\\real_long_task_20_chapter_probe.dart --chapter-count=35`
  - `cd apps/novel_agent_app && $env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'; dart run tool\\real_long_task_probe.dart`
- 验证结果：
  - `dart analyze tool\\real_long_task_20_chapter_probe.dart` 通过。
  - 普通项目 5 章：`PASS`
    - 产物：`artifacts/real_general_novel_probe_report.json`
    - 结论：`ok=True`、`report_category=success`、`requested_chapter_count=5`
    - 5 章全部 `delivery_outcome=accept`
    - information probe 成功
    - 第 1 章字数策略证据：`2291 / 2200`，`preferred_min=1900`，`preferred_max=2500`，`level=balanced`，`recommended_action=pass`
  - 长任务 10 章：`FAIL`
    - 产物：`artifacts/real_long_task_chapter_probe_runs/2026-06-05T18-39-27.341997_chapters_10/report.json`
    - 结论：`report_category=content_quality_failure`
    - 只形成 `7` 个章节文件，最终缺少第 `4`、`5`、`9` 章交付
    - 显式失败步骤出现在 `第4章_·_旧磁带` 与 `第9章_·_回声的源头`
    - 说明真实长任务链会出现“部分章节失败但后续任务仍继续”的不稳定形态
  - 长任务 35 章：`FAIL`
    - 产物：`artifacts/real_long_task_chapter_probe_runs/2026-06-05T18-54-22.215982_chapters_35/report.json`
    - 结论：`report_category=content_quality_failure`
    - 只形成 `1` 个章节文件
    - `manual_resolution_count=2`，`checkpoint_confirm_count=0`，`postprocess_count=0`
    - 最终任务状态停在 `running=4`、`succeeded=4`
    - 说明中档长任务不是“跑久后衰减”，而是前期就可能陷入无法稳定扩展的状态
  - 补充 focused long-task probe：`FAIL`
    - 产物：`artifacts/real_long_task_probe_report.json`
    - 结论：`report_category=technical_failure`
    - 错误：`Bad state: 样章确认后未能推进出第02章任务。`
    - 这个 focused probe 反映的是当前真实长任务链路/探针假设不再稳定，不作为本轮唯一主结论，但会强化“长任务真实链仍不稳”的判断
- 剩余风险：
  - `RRP-29` 的真实 provider 结论已经明确是“普通项目可用、长任务不稳定”，因此不能把长任务自动推进能力当成 GUI beta 的稳定卖点。
  - `real_long_task_20_chapter_probe.dart` 当前能给出真实失败证据和独立产物，但还不是精细诊断器；例如缺章虽能被最终统计抓到，单步报告里仍可能出现 `ok=true` 但正式交付缺失的情况，后续若继续修长任务真实链，应优先补共享运行结果口径或 probe 归因颗粒度。
  - `real_long_task_probe.dart` 这条 focused probe 现在出现了“样章确认后未推进出第02章任务”的技术失败，说明部分历史 probe 假设已经落后于当前真实链路，后续若继续依赖它做精细验收，需要单独修 probe 逻辑或改成更通用的任务推进观察方式。
- 下一步：
  - 停在 `RRP-29`，不要自动开启 `RRP-30`。

### RRP-30 完成记录

- 状态：已完成
- 完成时间：2026-06-05 19:07:49 +08:00
- 主要改动：
  - 新增最终发布收口报告 `docs/release-readiness-final-closeout-2026-06-05.md`，基于 `RRP-01 ~ RRP-29` 已完成记录和 `RRP-28` / `RRP-29` 验收报告，统一收口：
    - 全部 session 完成状态；
    - 最终 release readiness 结论；
    - GUI beta 是否可放行及其范围边界；
    - 当前 P0 阻断项；
    - 保留风险；
    - 后续 `P2 / P3` 路线；
    - 下一会话交接提示。
  - 明确写出最终判断口径：
    - 密钥扫描、打包隔离、GUI 关键路径自动化、CLI 最小边界都已通过或已完成；
    - 真实 provider 普通项目路径通过；
    - 真实 provider 长任务路径在 10 章、35 章和 focused probe 上均未通过；
    - 因此当前仓库不能以“长任务自主推进已稳定可用”的口径发布。
  - 将 GUI beta 结论限定为“严格限范围可 beta”：
    - 可围绕模型配置、新建/打开项目、普通写作、资料回看、生态设置展开；
    - 必须排除、隐藏或标记实验的能力是长任务自主连续推进；
    - 如果 beta 的核心卖点必须包含稳定长任务自动写作，则当前结论应视为不可 beta。
- 验证命令：
  - `dart tools/repository_secret_scan.dart`
  - 文档交叉核对：
    - `docs/gui-critical-path-test-matrix-2026-06-05.md`
    - `docs/real-provider-regression-report-2026-06-05.md`
    - `docs/release-packaging-hygiene-checklist-2026-06-05.md`
    - `docs/cli-release-boundary-2026-06-05.md`
- 验证结果：
  - `dart tools/repository_secret_scan.dart` 返回 `repository_secret_scan: PASS`。
  - 已确认 `RRP-01 ~ RRP-29` 在本主文档中均为 `已完成`，本轮已补齐 `RRP-30` 最终收口。
  - 最终发布结论已和现有证据对齐，没有把真实长任务未完成项描述成可发布能力。
- 剩余风险：
  - 当前最主要阻断仍是 `RRP-29` 已证实的真实 provider 长任务不稳定，包括缺章、失败后仍继续推进、早期停滞与 focused probe 技术失败。
  - GUI 自动化通过不等于完整人工真机回归；Android 正式签名、正式 `applicationId`、以及字体资产策略仍是后续正式分发准备项。
  - 若后续仍要对外开启 beta，必须保证产品范围与本轮结论一致，避免对长任务自主能力过度承诺。
- 下一步：
  - `RRP` 主线到此完成，不再自动开启新 session。
  - 若继续推进，应新开“真实 provider 长任务阻断修复”主线，优先修共享交付连续性、supervisor/recovery 消费口径与 focused probe 诊断一致性。
