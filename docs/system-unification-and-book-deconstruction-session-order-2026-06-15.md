# NovelAgentFlutter 系统收口、开局统一、工具暴露、连续任务与拆书导入总任务顺序文档

最后更新：2026-06-15

主线代号：`SUBD`（System Unification / Book Deconstruction）

关联主要分析文档：

- `docs/important/project-unreasonable-areas-audit-2026-06-15.md`
- `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`
- `docs/important/opening-default-constraint-followup-2026-06-09.md`
- `docs/important/high-fidelity-viewmodel-validation-analysis-2026-06-10.md`
- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`

关联历史任务顺序文档：

- `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md`
- `docs/full-module-sweep-collaboration-session-order-2026-06-09.md`
- `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md`
- `docs/context-token-budget-and-compaction-session-order-2026-06-14.md`

关联项目约束：

- `agent.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`

关联代码锚点：

- `apps/novel_agent_app/lib/app/state/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/inspiration_workbench/`
- `apps/novel_agent_app/lib/features/book_deconstruction/`
- `apps/novel_agent_app/lib/features/project_creation/`
- `apps/novel_agent_app/lib/features/settings/`
- `packages/novel_agent_core/lib/src/opening/`
- `packages/novel_agent_core/lib/src/tools/`
- `packages/novel_agent_core/lib/src/agents/`
- `packages/novel_agent_core/lib/src/workflow/`
- `packages/novel_agent_core/lib/src/project/`
- `packages/novel_agent_core/lib/src/deconstruction/`
- `packages/novel_agent_adapters/lib/src/workflow/`
- `packages/novel_agent_adapters/lib/src/storage/`
- `apps/novel_agent_app/test/`
- `apps/novel_agent_app/tool/`

---

## 1. 这份文档解决什么

这份文档不是单独解决某一个 bug，也不是只补拆书导入，而是把当前项目已经暴露出来的两大问题簇合并收口：

```text
一类是系统级不合理：
开局分裂、工具暴露分裂、多智能体协作分裂、样章/正文/产物路径分裂、
会话恢复分裂、GUI 入口语义分裂、连续任务调度职责分裂。

另一类是拆书与导入链不完整：
原文留存不稳定、来源解析底座不共享、文件夹/多格式支持不足、
continuation / fanfic 分流未正式闭环、一般项目导入智能分析边界不清。
```

本文件的职责，是把这两类问题按正确顺序压成一条可执行主线，让新的 `gpt-5.4-mini` 会话可以逐 session 处理，而不会只修一半、漏一半，或者为了快再长出一套平行实现。

完成本主线后，项目应达到：

1. 开局、工具暴露、协作调度、产物落盘都具备清楚的唯一正式出口。
2. 普通项目、长任务、拆书项目、知识类项目之间共享正确的底座，不再把通用能力做成某个类型的私有逻辑。
3. 拆书导入、原文留存、文件夹扫描、多格式解析、续写/同人后续导向具备正式主链。
4. GUI / ViewModel / probe / regression 只消费 production 同源合同，不再偷偷生出第二套业务判断。
5. 项目进一步接近“真正可发布”而不是“功能很多但语义分裂”的状态。

---

## 2. 与旧文档的关系

### 2.1 这是合并继任版，不是平行新主线

本文件直接继承并合并：

1. `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md`
2. `docs/important/project-unreasonable-areas-audit-2026-06-15.md`

它不是另起一条平行主线，而是把“系统级收口”和“拆书导入后续链”并到同一条更高优先级的主线上。

### 2.2 它继承哪些旧判断

以下判断在本文件中继续有效：

1. 不为 probe、fallback、viewmodel、widget helper 再造业务中心。
2. Core / domain 合同先行，GUI / CLI / 外层消费放后。
3. 拆书项目当前不直接改造成知识库项目。
4. 拆书后的 `continuation` 与 `fanfic` 必须明确分流。
5. 一般项目导入与拆书导入共享来源解析底座，但业务编排不同。
6. 表达限制、审核、连续任务监管要做成通用架构，不写死在特定题材测试上。

### 2.3 这份文档替代哪些局部安排

下列旧文档仍可作为历史依据，但任务执行以本文件为准：

1. `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md`
2. `docs/full-module-sweep-collaboration-session-order-2026-06-09.md`

### 2.4 本文件不处理什么

1. 不在这条主线里把 TUI 完整产品化。
2. 不在这条主线里补全所有 CLI 体验，仅允许最小消费口顺手接上。
3. 不把快穿、死亡回归、哈利波特、历史科技流等测试题材写死进 core。
4. 不为了赶进度接受新的平行 runtime、平行 path policy 或平行开局链。

---

## 3. 已有实现去重审计

### 3.1 已有稳定基础，不重做

以下基础已存在，应优先复用：

1. opening / mode guidance / project opening projection 基础。
2. 工具策略、工具提示词、部分 runtime tool exposure 基础。
3. 智能体组、技能组、能力域、子智能体调度基础。
4. 长任务 supervisor / watchdog / review / repair 骨架。
5. `ProjectWorkflowRuntimeService`、`ProjectConversationDraftRuntimeService` 等既有运行时。
6. 项目内容、章节、continuity、information、reference substrate、SQLite 相关基础。
7. 拆书控制器、拆书 draft builder、拆书 narrative persistence、工作台导入执行服务。
8. 高保真 ViewModel probe 与一批 focused tests / regression tests。

### 3.2 已有但仍是半成品

这些方向目前最容易制造“看起来做了，其实没真正闭环”的假象：

1. 开局已经部分智能体化，但仍有机械控制入口残留。
2. 工具暴露已经有 runtime resolver，但提示词层、适配层、工作流层仍可能各说各话。
3. 单智能体不该调子智能体的逻辑已补到部分链路，但不代表所有 workflow / reviewer 路径都统一。
4. 样章和正文的设计边界已明确，但 path truth 仍较分散。
5. 历史会话恢复链存在，但显示投影、滚动定位、历史面板可见性仍可能分离。
6. 默认表达限制已补一部分，但限制层还不算完全统一。
7. 拆书链已经能运行，但原文留存、来源解析、目录语义、多格式与 followup 分流仍不够正式。

### 3.3 真正要补的层

本主线真正缺的是下面这些正式层：

1. 开局语义唯一合同层。
2. 工具暴露与工具确认唯一合同层。
3. 单/多智能体/审核智能体统一协作合同层。
4. 样章/正文/规划/信息/来源产物统一分类与路径合同层。
5. 会话恢复、历史显示、滚动定位统一状态真相层。
6. 项目类型与存储载体能力矩阵层。
7. 用户确认与智能体自补全边界层。
8. 表达限制/审核限制/默认约束装载统一运行时层。
9. watchdog / supervisor / reviewer / extraction shared liveness 层。
10. 共享来源解析与拆书 followup 底座。

---

## 4. 本轮冻结的架构边界

1. 开局语义必须收成单一正式出口，不允许 workbench、inspiration、prompt builder、action resolver 各保留一套实义。
2. 工具暴露的最终 truth 必须由正式合同与 runtime 决定，prompt 只负责解释，不负责另起第二套策略。
3. 单智能体、子智能体、审核智能体、reviewer dispatch 的能力判断必须共享同一组正式规则。
4. 样章、正文、规划、信息、来源、拆书预演不得再混写到同一目录语义层。
5. 会话恢复、历史显示、滚动状态的真相不允许散落在 shell、controller、sidebar、widget 各自维护。
6. 项目类型与存储载体不是 UI 文案问题，而是核心能力矩阵问题；类型限制先落 core，再让 GUI 消费。
7. 用户是否必须确认、智能体何时可自行补全，必须走策略与合同，不允许写死成僵硬表单，也不允许默认随便脑补。
8. 表达限制、审核限制、默认装载策略必须是通用架构，不得只为 `de_ai` 或某一条测试线写特例。
9. watchdog / supervisor / extraction continuity 共享生命周期概念，但不允许互相混成一个巨型 service。
10. 拆书项目当前不直接改造成知识库项目，这个边界保留。
11. 一般项目导入的“智能分析”只属于已有项目导入，不进入拆书主链。
12. GUI / CLI / probe 只能消费稳定合同，不承担补底层缺口的职责。
13. 单文件接近 400 行主动复核职责；接近 700 行必须拆分，不再接受把新逻辑继续堆进 2000+ 行控制器。

---

## 5. 目标终态

完成本主线后，应达到以下终态：

1. 项目拥有统一、可解释的开局链，普通项目与长任务都遵循同一开局哲学。
2. 工具暴露、能力域、确认策略、长耗时工具显示语义统一。
3. 单智能体不会再误拉子智能体，多智能体与审核智能体的职责边界清楚。
4. 样章、正文、规划、信息、来源、拆书预演在路径与命名层完全分层。
5. 会话恢复后，历史会话、活跃会话、滚动位置、上下文投影都正确。
6. 项目类型、存储载体、类型转换与工具暴露矩阵对齐既定设计。
7. 用户确认边界灵活但可信：该问的会问，不该默认脑补的不会脑补。
8. 表达限制与审核层可通用于普通项目、长任务、拆书续写与后续提取链。
9. watchdog / supervisor / extraction liveness 能稳定承担连续任务保活与恢复职责。
10. 拆书导入拥有正式的共享来源解析底座、原文归档、文件夹与多格式支持、`continuation / fanfic` 分流。
11. 高保真 probes 与 focused regressions 可以证明这些主链确实成立。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `24` 个 session。

顺序理由如下：

1. `SUBD-01` 到 `SUBD-04` 先冻结四个最核心的 truth contract：
   - 开局
   - 工具暴露
   - 多智能体协作
   - 产物分类与路径
2. `SUBD-05` 到 `SUBD-10` 再把这些合同真正下沉到 runtime / workflow / project-type / session-state 主链。
3. `SUBD-11` 到 `SUBD-15` 处理中高风险但跨链的策略层：
   - 用户确认边界
   - 表达限制
   - watchdog / liveness
   - 大控制器拆责
4. `SUBD-16` 到 `SUBD-20` 再把拆书导入、共享来源解析、多格式支持、followup 分流、一般导入智能分析正式收口。
5. `SUBD-21` 到 `SUBD-23` 最后接 GUI / ViewModel / probe / regression / product shell 收口。
6. `SUBD-24` 负责最终文档、验收记录、交接与后续入口。

这样安排的目的，不是平均分配工作量，而是尽量保证：

1. 先修真正的中心，不在边缘层打补丁。
2. 拆书导入不会先接 UI 再回头发现底层合同不够。
3. probe 不会先写，再反过来变成业务判断来源。
4. `gpt-5.4-mini` 可以一轮一轮稳步推进，而不是在大杂烩任务里乱跳。

---

## 7. Session 设计

## SUBD-01 开局 truth contract 冻结

- 本轮目标：
  把“项目如何开始、何时收集用户信息、何时进入正式运行”冻结成唯一正式合同。
- 层级归属：
  `Core / domain`
- 必读文件：
  - `docs/important/project-unreasonable-areas-audit-2026-06-15.md`
  - `packages/novel_agent_core/lib/src/opening/opening_next_action_resolver.dart`
  - `packages/novel_agent_core/lib/src/workflow/long_task_entry_prompt_builder_service.dart`
  - `packages/novel_agent_core/lib/src/workflow/long_task_opening_prompt_builder_service.dart`
- 必须完成：
  1. 设计并冻结统一的 opening intent / opening phase / readiness contract。
  2. 明确普通项目与长任务共享什么开局哲学，哪些只是模式差异。
  3. 明确“智能体引导优先”与“程序结构化动作”的关系，避免双中心。
  4. 为后续 app / runtime 改造提供单一 truth model。
- 本轮不要做：
  1. 不直接改 GUI 文案。
  2. 不碰拆书导入。
  3. 不顺手修其他 controller。
- 验收标准：
  1. 新合同能解释当前 opening / mode guidance / direct start 的全部已知分歧。
  2. 有 focused contract tests 或最小建模测试。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-01`。只做开局 truth contract 冻结，落在 core/domain；不要做 GUI、不要碰拆书、不启动下一任务。必须解耦合、单一职责、避免单文件过重，并补 focused contract tests。

## SUBD-02 工具暴露与确认策略统一合同

- 本轮目标：
  把工具是否可见、是否默认开放、是否需确认、是否仅 host/supervisor 可用，收成统一合同。
- 层级归属：
  `Core / domain`
- 必读文件：
  - `packages/novel_agent_core/lib/src/tools/tool_strategy_service.dart`
  - `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`
  - `packages/novel_agent_core/lib/src/tools/tool_strategy_prompt_builder.dart`
- 必须完成：
  1. 冻结工具暴露矩阵模型。
  2. 区分 capability family、default open、requires confirmation、host only。
  3. 明确 prompt 解释层与 runtime enforcement 层的边界。
  4. 预留对长耗时工具状态显示的元信息位。
- 本轮不要做：
  1. 不接 GUI。
  2. 不写具体工具文案。
  3. 不碰 reviewer 链。
- 验收标准：
  1. 可以清楚回答某工具为什么在某项目/某组/某阶段出现或不出现。
  2. focused tests 覆盖关键分支。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-02`。只做工具暴露与确认策略统一合同，落在 core/domain；不要接 GUI、不要改 probe、不要开启下一任务。必须复用现有 service/contract，避免新造平行策略，并补 focused tests。

## SUBD-03 多智能体、子智能体、审核智能体协作合同

- 本轮目标：
  冻结单智能体、多智能体、审核智能体、reviewer dispatch 的统一协作合同。
- 层级归属：
  `Core / domain`
- 必读文件：
  - `packages/novel_agent_core/lib/src/agents/agent_group_delegation_capability_service.dart`
  - `packages/novel_agent_core/lib/src/agents/agent_collaboration_brief_service.dart`
  - `packages/novel_agent_adapters/lib/src/workflow/project_workflow_reviewer_dispatch_service.dart`
- 必须完成：
  1. 明确什么时候允许 `call_sub_agent`。
  2. 明确没有专职审核智能体时谁兜底。
  3. 明确 reviewer dispatch 与主智能体自审的合同关系。
  4. 形成统一 capability decision model。
- 本轮不要做：
  1. 不改 UI。
  2. 不顺手改工具提示词文案。
  3. 不做具体工作流编排。
- 验收标准：
  1. 单智能体组不会被合同层误判成可拉起子智能体。
  2. 多智能体与审核兜底逻辑可被 focused tests 验证。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-03`。只做多智能体/子智能体/审核智能体协作合同冻结；不要接 UI、不要改拆书、不启动下一任务。要解耦、避免把能力判断分散在多个 runtime，并补 focused tests。

## SUBD-04 产物分类与路径 truth contract

- 本轮目标：
  正式冻结样章、正文、规划、信息、来源、拆书预演、研究产物的统一分类与路径合同。
- 层级归属：
  `Core / domain`
- 必读文件：
  - `packages/novel_agent_core/lib/src/project/chapter_output_path_policy_service.dart`
  - `packages/novel_agent_core/lib/src/project/project_content_path_policy_service.dart`
  - `packages/novel_agent_core/lib/src/project/project_narrative_artifact_path_policy_service.dart`
  - `packages/novel_agent_core/lib/src/workflow/chapter_atomic_output_path_service.dart`
- 必须完成：
  1. 明确 artifact taxonomy。
  2. 明确样章不是正文，样章进入何处。
  3. 明确 continuation 原作正文、fanfic 来源正文、正式新写正文的边界。
  4. 为后续 adapter 与 GUI 提供唯一路径判定接口。
- 本轮不要做：
  1. 不大量改现有 path services。
  2. 不接 workbench 资源树。
  3. 不做拆书 reader。
- 验收标准：
  1. 合同能覆盖当前已知的样章/正文/分析文件混写问题。
  2. 有 focused path classification tests。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-04`。只做产物分类与路径 truth contract，落在 core/domain；不要接 GUI、不要大规模改 controller、不启动下一任务。保持单一职责，并补 focused path tests。

## SUBD-05 Opening runtime 与 workflow 正式收口

- 本轮目标：
  把 `SUBD-01` 的开局合同真正接到 core/workflow/runtime 主链，不再让多个入口各自带实义。
- 层级归属：
  `Workflow / runtime`
- 必读文件：
  - `packages/novel_agent_core/lib/src/opening/`
  - `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
  - `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- 必须完成：
  1. 收敛 opening 阶段运行时判定。
  2. 移除或降级重复的“直接启动长任务”语义中心。
  3. 让 runtime 能稳定消费统一的 opening phase / readiness model。
- 本轮不要做：
  1. 不改 workbench UI 排版。
  2. 不处理 session history。
  3. 不碰拆书导入。
- 验收标准：
  1. 普通项目与长任务在 runtime 侧遵循一致开局哲学。
  2. 相关 focused tests / integration tests 通过。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-05`。只做 opening runtime 与 workflow 正式收口；不要接 GUI、不要做拆书、不启动下一任务。必须复用既有 runtime hook，避免新造第二套开局链，并补 focused/integration tests。

## SUBD-06 路径与产物落盘适配层统一

- 本轮目标：
  将 `SUBD-04` 的产物分类合同落到 adapters/path policy 主链，清理最危险的重复路径判断。
- 层级归属：
  `Adapters / persistence`
- 必读文件：
  - `packages/novel_agent_adapters/lib/src/workflow/workflow_runtime_satisfied_output_path_service.dart`
  - `packages/novel_agent_core/lib/src/runtime/draft_file_path_service.dart`
  - `packages/novel_agent_core/lib/src/workflow/long_task_path_policy_service.dart`
- 必须完成：
  1. 统一关键产物路径决策的正式出口。
  2. 修正样章/正文/规划/来源落盘最核心的冲突点。
  3. 为文件名保留章号加标题的稳定命名合同。
- 本轮不要做：
  1. 不做 workbench 资源树改造。
  2. 不做 UI 文案。
  3. 不扩写新的 path helper 丛林。
- 验收标准：
  1. 章节文件命名与产物落盘不再依赖多个零散路径判断。
  2. focused tests 覆盖样章、正文、来源、分析等关键分支。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-06`。只做路径与产物落盘适配层统一；不要接 GUI、不要改导入流程、不启动下一任务。避免再长 path helper 丛林，并补 focused tests。

## SUBD-07 工具暴露运行时统一落地

- 本轮目标：
  把 `SUBD-02` 的工具暴露合同真正接入 runtime/adapters 主链。
- 层级归属：
  `Workflow / runtime`
- 必读文件：
  - `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`
  - `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
  - `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- 必须完成：
  1. 统一 default open / confirmation / host only 的运行时消费口。
  2. 明确长耗时工具状态元信息传递。
  3. 清理最危险的 runtime 二次过滤分叉。
- 本轮不要做：
  1. 不改 GUI 时间线展示。
  2. 不补 probe。
  3. 不碰 reviewer。
- 验收标准：
  1. 相同工具在相同项目/组/阶段下暴露结果一致。
  2. integration tests 覆盖 representative cases。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-07`。只做工具暴露运行时统一落地；不要接 GUI、不要做 probe、不启动下一任务。要复用统一合同，清理重复过滤，并补 integration tests。

## SUBD-08 多智能体与 reviewer runtime 收口

- 本轮目标：
  让长任务、普通会话、reviewer dispatch 共同消费 `SUBD-03` 的协作合同。
- 层级归属：
  `Workflow / runtime`
- 必读文件：
  - `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
  - `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
  - `packages/novel_agent_adapters/lib/src/workflow/project_workflow_reviewer_dispatch_service.dart`
- 必须完成：
  1. 打通 delegation capability 在主要 runtime 链的统一消费。
  2. 明确 reviewer 存在与不存在时的兜底路径。
  3. 消除“单智能体仍试图调子智能体”的残余 runtime 分支。
- 本轮不要做：
  1. 不补新的 agent UI。
  2. 不改工具提示词文案。
  3. 不碰拆书导入。
- 验收标准：
  1. 主要运行时对协作能力的判断一致。
  2. focused + integration tests 覆盖单智能体、多智能体、审核兜底。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-08`。只做多智能体与 reviewer runtime 收口；不要接 GUI、不要做拆书、不启动下一任务。避免把协作判断再散到各 service，并补 focused/integration tests。

## SUBD-09 会话恢复、历史投影、滚动定位统一状态层

- 本轮目标：
  将项目重载后的 session 恢复、历史列表显示、active session、滚动定位收成统一状态层。
- 层级归属：
  `App state / application service`
- 必读文件：
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart`
- 必须完成：
  1. 明确恢复真相来自哪里。
  2. 明确 show history 与 active session 的状态所有权。
  3. 为滚动锚点恢复提供正式状态或 hook。
  4. 清理“数据有但 UI 看起来像没有”的高风险分裂。
- 本轮不要做：
  1. 不做视觉重设计。
  2. 不顺手改 opening 入口。
  3. 不改拆书。
- 验收标准：
  1. 重新加载项目后，历史会话可被稳定恢复与显示。
  2. 会话恢复后滚动位置策略有明确测试。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-09`。只做会话恢复、历史投影、滚动定位统一状态层；不要做视觉大改、不要碰拆书、不启动下一任务。注意状态所有权清晰，并补 focused tests。

## SUBD-10 项目类型、存储载体、类型转换能力矩阵

- 本轮目标：
  正式收口项目类型与存储载体的能力矩阵，并统一类型转换边界。
- 层级归属：
  `Core / Adapters / workflow`
- 必读文件：
  - `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md`
  - `packages/novel_agent_core/lib/src/use_cases/update_project_manifest_use_case.dart`
  - `packages/novel_agent_adapters/lib/src/storage/project_sqlite_path_service.dart`
- 必须完成：
  1. 明确哪些项目类型可选 `md`，哪些只能 `sqlite`。
  2. 明确一般写作与一般长任务互转的正式边界。
  3. 明确知识类项目的 SQLite-only 规则。
  4. 收口工具暴露与项目类型之间的能力映射。
- 本轮不要做：
  1. 不做 GUI 选择器美化。
  2. 不做拆书 reader。
  3. 不写项目 id 手填式过渡 UI。
- 验收标准：
  1. 项目类型与存储载体关系在 core 层可被明确判定。
  2. focused tests 覆盖类型限制与转换限制。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-10`。只做项目类型、存储载体、类型转换能力矩阵；不要接 GUI、不要做 reader、不启动下一任务。保持合同先行，并补 focused tests。

## SUBD-11 用户确认边界与智能体自补全策略层

- 本轮目标：
  设计并实现灵活但可信的用户确认边界，解决“智能体擅自补全”与“硬表单过死”两极问题。
- 层级归属：
  `Core / workflow`
- 必读文件：
  - `docs/important/opening-default-constraint-followup-2026-06-09.md`
  - `packages/novel_agent_core/lib/src/opening/`
  - `packages/novel_agent_core/lib/src/tools/tool_strategy_prompt_builder.dart`
- 必须完成：
  1. 定义哪些信息默认必须问用户。
  2. 定义哪些可由智能体提出选项再确认。
  3. 定义哪些只在用户明确授权时可自行补全。
  4. 让普通项目、长任务、导入分析可以共享这套策略层。
- 本轮不要做：
  1. 不做项目创建 UI 重排。
  2. 不顺手改 tool exposure。
  3. 不碰拆书导入流程。
- 验收标准：
  1. 开局不会再默认自行脑补关键角色/主线设定。
  2. focused tests 覆盖 must-ask / option-first / may-autofill 三类边界。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-11`。只做用户确认边界与智能体自补全策略层；不要改大 UI、不要碰拆书、不启动下一任务。要保持灵活性，避免硬表单化，并补 focused tests。

## SUBD-12 表达限制、审核限制、默认装载统一运行时

- 本轮目标：
  把表达限制、审核限制、默认约束装载、运行时消费与结果审查统一起来。
- 层级归属：
  `Core / workflow / adapters`
- 必读文件：
  - `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
  - `docs/important/opening-default-constraint-followup-2026-06-09.md`
  - 相关 expression constraint / review / project binding 代码锚点
- 必须完成：
  1. 统一默认表达限制装载策略。
  2. 明确限制层是如何进入生成、审核、重试链的。
  3. 让限制不是“说调用了”而是真被 runtime 消费。
  4. 为未来激进/常规/禁止等策略保留接口。
- 本轮不要做：
  1. 不做设置页最终美化。
  2. 不新增过多限制类型。
  3. 不做题材特例逻辑。
- 验收标准：
  1. 限制装载、运行、审核、记录链是闭环的。
  2. focused tests 覆盖默认装载与运行时消费。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-12`。只做表达限制、审核限制、默认装载统一运行时；不要做 UI 美化、不要写题材特例、不启动下一任务。要解耦，并补 focused/integration tests。

## SUBD-13 watchdog / supervisor / reviewer 生命周期模型

- 本轮目标：
  冻结并落地 watchdog、supervisor、reviewer 的生命周期职责边界。
- 层级归属：
  `Core / workflow`
- 必读文件：
  - `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
  - 现有 watchdog / supervisor / registry / heartbeat 相关实现
- 必须完成：
  1. 明确 watchdog 的职责是保活与重拉，不承载业务真相。
  2. 明确 supervisor 的职责是调度与状态推进。
  3. 明确 reviewer 的职责是内容/合同审查，而不是任务存活判断。
  4. 抽出统一生命周期状态与事件模型。
- 本轮不要做：
  1. 不写 GUI 面板。
  2. 不顺手改开局。
  3. 不扩散到 CLI。
- 验收标准：
  1. 可以清楚解释暂停、继续、恢复、结束、失败、待用户确认的状态流转。
  2. 有 focused lifecycle tests。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-13`。只做 watchdog/supervisor/reviewer 生命周期模型；不要接 GUI、不要改开局、不启动下一任务。必须保持职责分离，并补 focused lifecycle tests。

## SUBD-14 长任务与提取任务共享连续性调度层

- 本轮目标：
  让长任务写作链与提取/拆解链共享连续性调度底座，而不是各自半独立保活。
- 层级归属：
  `Workflow / runtime`
- 必读文件：
  - `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
  - 提取任务、长任务、watchdog 相关 runtime 代码
- 必须完成：
  1. 抽出共享连续任务 profile / state / heartbeat / retry hook。
  2. 明确长任务与提取任务各自特化点。
  3. 避免“提取任务也连续，但没吃到正式 watchdog 模型”的断层。
- 本轮不要做：
  1. 不改 UI。
  2. 不补探针。
  3. 不改 reader。
- 验收标准：
  1. 写作长任务与提取长任务都能挂到同一 continuity substrate。
  2. integration tests 覆盖至少两个任务族。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-14`。只做长任务与提取任务共享连续性调度层；不要接 GUI、不要补 probe、不启动下一任务。避免再造第二套保活链，并补 integration tests。

## SUBD-15 大控制器与巨型 runtime 拆责

- 本轮目标：
  对超大文件进行职责拆分，优先拆掉最影响后续协作和真相统一的部分。
- 层级归属：
  `App / workflow / adapters`
- 必读文件：
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
  - `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- 必须完成：
  1. 先做职责切片与正式子服务抽取。
  2. 把已收口的 truth contract 从巨型控制器中剥出来。
  3. 确保不是机械拆文件，而是按职责与所有权拆。
- 本轮不要做：
  1. 不借机大重命名全工程。
  2. 不做外观改版。
  3. 不碰拆书 reader。
- 验收标准：
  1. 至少一到两个巨型文件被实质性减重。
  2. 新抽出的服务拥有 focused tests。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-15`。只做大控制器与巨型 runtime 拆责；不要做外观改版、不要碰 reader、不启动下一任务。必须按职责拆，不要机械切文件，并补 focused tests。

## SUBD-16 共享来源导入合同冻结

- 本轮目标：
  把拆书与一般项目导入共享的 source import contract 正式冻结。
- 层级归属：
  `Core / domain`
- 必读文件：
  - `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md`
  - `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_source_document.dart`
  - `packages/novel_agent_core/lib/src/use_cases/import_project_files_use_case.dart`
- 必须完成：
  1. 设计中性的 source import request / selection / normalized document 合同。
  2. 让合同能表达单文件、目录扫描、多来源、来源身份、排序、媒体类型、相对路径提示。
  3. 避免把拆书私有语义写进共享来源层。
- 本轮不要做：
  1. 不写 EPUB reader。
  2. 不接 GUI。
  3. 不做 continuation/fanfic 业务编排。
- 验收标准：
  1. 共享合同可被拆书与一般项目导入同时消费。
  2. focused contract tests 覆盖编解码和规范化。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-16`。只做共享来源导入合同冻结；不要接 GUI、不要写 reader、不要开启下一任务。保持中性底座，并补 focused contract tests。

## SUBD-17 共享来源发现、扫描与多格式 reader 底座

- 本轮目标：
  建立共享来源发现、目录扫描、递归、格式识别与 reader 底座。
- 层级归属：
  `Adapters / persistence`
- 必读文件：
  - `apps/novel_agent_app/lib/shared/services/desktop_text_file_picker_service.dart`
  - `packages/novel_agent_core/lib/src/use_cases/import_project_files_use_case.dart`
  - 拆书导入与一般导入现有入口
- 必须完成：
  1. 支持单文件、目录、递归扫描、格式过滤。
  2. 为 `.txt / .md / .markdown / epub` 建立正式 reader 路线。
  3. 支持未来扩展其他格式，而不是写死特判。
- 本轮不要做：
  1. 不做 followup 分流。
  2. 不做 GUI 最终交互。
  3. 不做知识库提取。
- 验收标准：
  1. 来源发现与解析层可独立测试。
  2. focused tests 覆盖多文件、多层级、格式识别。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-17`。只做共享来源发现、扫描与多格式 reader 底座；不要做 GUI、不要做 followup 分流、不启动下一任务。避免只加扩展名假装支持格式，并补 focused tests。

## SUBD-18 拆书原文归档与项目内容层重分层

- 本轮目标：
  让拆书原文必留，并将来源层、预演层、正式正文层彻底分开。
- 层级归属：
  `Core / Adapters / workflow`
- 必读文件：
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart`
  - `packages/novel_agent_core/lib/src/deconstruction/`
- 必须完成：
  1. 拆书任意入口导入后原文都稳定归档。
  2. 拆书预演纪要不再写进正文层。
  3. continuation 原作正文、fanfic 来源材料、预演结果各归其层。
- 本轮不要做：
  1. 不做 UI 美化。
  2. 不接一般项目智能分析。
  3. 不做最终 probe。
- 验收标准：
  1. 不再出现拆书原文只在内存中存在或混写到 `chapters/` 的情况。
  2. focused tests 覆盖归档与目录分层。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-18`。只做拆书原文归档与项目内容层重分层；不要做 UI 美化、不要做最终 probe、不启动下一任务。必须依据统一产物路径合同落地，并补 focused tests。

## SUBD-19 continuation / fanfic 分流与一般导入智能分析

- 本轮目标：
  完成拆书 followup 分流，并正式接一般项目导入的智能分析边界。
- 层级归属：
  `Workflow / runtime`
- 必读文件：
  - `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_import_action_policy_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_import_execution_service.dart`
- 必须完成：
  1. 拆书 followup 至少支持 `continuation` 与 `fanfic`。
  2. `continuation` 让原作章节进入叙事连续体。
  3. `fanfic` 让原作停留在来源/参考层。
  4. 一般项目导入支持智能分析，且只在已有项目导入时出现。
  5. 智能分析允许指定分析智能体或智能体组。
- 本轮不要做：
  1. 不做完整 GUI polish。
  2. 不做最终 release。
  3. 不把拆书改造成知识库项目。
- 验收标准：
  1. `continuation` 与 `fanfic` 在路径和后续语义上明显区分。
  2. 一般项目导入不会污染拆书主链。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-19`。只做 continuation/fanfic 分流与一般导入智能分析；不要做 GUI polish、不要做 release、不启动下一任务。保持拆书与一般导入共享底座但不同编排，并补 focused/integration tests。

## SUBD-20 导入与拆书主链 GUI / ViewModel 对接

- 本轮目标：
  让 GUI / ViewModel 正式消费 `SUBD-16` 到 `SUBD-19` 的稳定合同。
- 层级归属：
  `App / GUI`
- 必读文件：
  - `apps/novel_agent_app/lib/features/book_deconstruction/`
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_import_action_policy_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_import_execution_service.dart`
- 必须完成：
  1. GUI 入口不再依赖旧内存态或临时导入行为。
  2. 文件/目录导入、followup 选择、智能分析入口都消费正式合同。
  3. 只暴露应该暴露的项目类型与存储选择。
- 本轮不要做：
  1. 不做最终视觉大改。
  2. 不再向 core 回写新判断。
  3. 不做最终 probe。
- 验收标准：
  1. GUI 能走完整的导入与拆书主链。
  2. widget / controller 不再偷藏业务判断。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-20`。只做导入与拆书主链 GUI/ViewModel 对接；不要做视觉大改、不要反向改 core 逻辑、不启动下一任务。GUI 只能消费稳定合同，并补 focused widget/controller tests。

## SUBD-21 开局、工具暴露、多智能体、限制层高保真验收

- 本轮目标：
  用 production 同源的高保真路径验证开局、工具暴露、多智能体、表达限制、用户确认边界。
- 层级归属：
  `Probe / regression`
- 必读文件：
  - `docs/important/high-fidelity-viewmodel-validation-analysis-2026-06-10.md`
  - `apps/novel_agent_app/tool/`
  - 相关 focused regression tests
- 必须完成：
  1. 新项目普通会话开局不再默认直写正文。
  2. 长任务开局经过统一开局链。
  3. 单智能体组不再误拉子智能体。
  4. 多智能体组能在需要时合理调子智能体/审核智能体。
  5. 表达限制在运行时与交付结果中真实可见。
- 本轮不要做：
  1. 不在 probe 里复制业务判断。
  2. 不为了让 probe 通过去改 mock 成功条件。
  3. 不跳过前置用户收集阶段。
- 验收标准：
  1. 高保真报告能区分技术失败、等待用户、内容失败、策略失败。
  2. probe 真实消费 production 合同。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-21`。只做开局、工具暴露、多智能体、限制层高保真验收；不要复制业务判断到 probe、不要跳过前置阶段、不启动下一任务。发现问题先修主链再重跑，并保留结构化报告。

## SUBD-22 拆书与导入链高保真验收

- 本轮目标：
  验证拆书导入、原文留存、文件夹扫描、多格式 reader、followup 分流、一般项目智能分析的真实可用性。
- 层级归属：
  `Probe / regression`
- 必读文件：
  - `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`
  - `apps/novel_agent_app/tool/`
  - `references/files/` 中可用于导入的测试资产
- 必须完成：
  1. 验证单文件、目录、多格式导入。
  2. 验证拆书原文必留。
  3. 验证 `continuation` 原作章节进入正确内容层。
  4. 验证 `fanfic` 原作不污染新正文层。
  5. 验证一般项目导入的智能分析入口仅在该场景出现。
- 本轮不要做：
  1. 不在 probe 里替主链做分类。
  2. 不把测试脚本写成第二套 path truth。
  3. 不顺手改 UI 文案。
- 验收标准：
  1. 结构化报告能完整记录来源、归档、分流、落盘结果。
  2. 关键路径失败时可回链到正式合同或 runtime。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-22`。只做拆书与导入链高保真验收；不要复制分类逻辑到 probe、不要顺手改 UI、不启动下一任务。发现问题先修主链再重跑，并输出结构化报告。

## SUBD-23 产品壳层与主工作台收口

- 本轮目标：
  收口最直接影响“像不像可发布软件”的壳层与主工作台问题。
- 层级归属：
  `App / GUI`
- 必读文件：
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/`
  - `apps/novel_agent_app/lib/features/project_creation/`
  - `apps/novel_agent_app/lib/features/settings/`
- 必须完成：
  1. 无项目时进入正确的新建/打开入口，不生成无目录默认项目。
  2. 物理返回键与面板返回逻辑更符合用户心智。
  3. 清理竖屏重复入口、莫名文案、不该直露的高级选项。
  4. 项目类型、知识库类型、默认约束入口对齐设计。
  5. workbench 与 inspiration workbench 的入口职责更清晰。
- 本轮不要做：
  1. 不回头补 core 逻辑。
  2. 不大做视觉炫技。
  3. 不做 CLI 完整对齐。
- 验收标准：
  1. 主要 GUI 入口不再显得像调试壳。
  2. focused widget / controller tests 覆盖关键壳层路径。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-23`。只做产品壳层与主工作台收口；不要回头补 core 逻辑、不要做 CLI 完整对齐、不启动下一任务。以用户心智为主，补 focused widget/controller tests。

## SUBD-24 文档、验收台账与交接收口

- 本轮目标：
  整理本主线的收口证据、残留问题、正式文档与下一阶段入口。
- 层级归属：
  `Documentation / handoff`
- 必读文件：
  - 本文档
  - 本主线过程中新增或更新的分析文档
  - 相关 probe / regression 报告
- 必须完成：
  1. 更新或新增必要的分析文档与完成台账。
  2. 标记哪些 session 已完成、哪些因外部条件暂缓。
  3. 汇总 residual risk 与后续入口。
  4. 确保文档能支持下一会话继续推进，而不是重新摸索。
- 本轮不要做：
  1. 不再大改生产代码。
  2. 不顺手重构无关模块。
  3. 不再新开平行顺序文档。
- 验收标准：
  1. 文档可直接作为新会话交接材料。
  2. 残留问题、已收口问题、未测问题一眼可见。
- 直接可用提示词：
  根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md` 执行 `SUBD-24`。只做文档、验收台账与交接收口；不要再大改生产代码、不要新开平行顺序文档、不启动下一任务。把已完成、未完成、残留风险记录清楚。

---

## 8. 总启动提示词

```text
根据 `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md`，从当前最早未完成的 `SUBD` session 开始执行，一次只做一个 session。

严格要求：

1. 先读本文档对应 session，再读该 session 的“必读文件”。
2. 只完成当前 session，不能提前开启下一个。
3. 必须优先修改正式主链，不允许为了快把逻辑写进 probe、widget、fallback、mock、临时脚本。
4. 必须遵守解耦合、单一职责、避免单文件过重；接近 400 行主动复核职责，接近 700 行必须拆分。
5. 每轮都要补 focused tests / contract tests / integration tests 中与本轮风险相匹配的最小覆盖。
6. 如果发现当前 session 受上个 session 未收口影响，先把该前置缺口补齐，但不要越过 session 边界扩写别的任务。
7. 如果遇到阻塞，必须明确：
   - 阻塞点
   - 关联文件
   - 为什么不能继续
   - 恢复条件
8. 完成当前 session 后，给出：
   - 修改摘要
   - 验证结果
   - 是否已达到该 session 验收标准
   - 下一 session 编号，但不要启动下一 session

现在开始执行最早未完成的 `SUBD` session。
```

---

## 9. 完成记录占位

- `SUBD-01`：2026-06-15 已完成。关键修改点：核查并确认 opening 主链已由 `OpeningOrchestrationService`、`OpeningReadinessEvaluator`、`OpeningStageRecordBuilderService` 和 `OpeningNextActionResolver` 统一承载，普通项目与长任务共用同一套 opening intent / readiness / stage records / suggested actions 合同；app 侧 `ProjectOpeningMaturityAssessmentService`、`ConversationOpeningStateViewDataService`、`ConversationOpeningGuideViewDataService` 已消费该统一投影，没有新增平行 opening truth。主要文件：`packages/novel_agent_core/lib/src/opening/opening_orchestration_service.dart`、`packages/novel_agent_core/lib/src/opening/opening_readiness_evaluator.dart`、`packages/novel_agent_core/lib/src/opening/opening_stage_record_builder_service.dart`、`packages/novel_agent_core/lib/src/opening/opening_next_action_resolver.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/project_opening_session_projection_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/conversation_opening_state_view_data_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/conversation_opening_guide_view_data_service.dart`。测试/验证结果：`dart test test/opening_orchestration_service_test.dart` 通过；`flutter test test/project_opening_maturity_assessment_service_test.dart test/conversation_opening_state_view_data_service_test.dart` 通过。残留风险：`ProjectOpeningMaturityAssessment` 仍作为展示/入口门控投影存在，但当前不反向决定 opening 业务语义，后续 session 再继续收束其职责。
- `SUBD-02`：2026-06-15 已完成。关键修改点：确认工具暴露已经由 `ToolCapabilityFamilyCatalogService`、`ToolCapabilityExposurePolicy`、`ContinuousTaskToolExposureProfileResolverService`、`ContinuousTaskToolExposureRuntimeResolverService` 形成正式矩阵，区分了 capability family、default open、requires confirmation、host or supervisor only；`ToolStrategyService` 与 `ToolStrategyPromptBuilder` 仅保留策略开关与 prompt 解释层职责，没有把 runtime enforcement 混回提示词中心。主要文件：`packages/novel_agent_core/lib/src/tools/tool_strategy_service.dart`、`packages/novel_agent_core/lib/src/tools/tool_strategy_prompt_builder.dart`、`packages/novel_agent_core/lib/src/tools/tool_capability_family_catalog_service.dart`、`packages/novel_agent_core/lib/src/tools/tool_capability_exposure_policy.dart`、`packages/novel_agent_core/lib/src/tools/tool_exposure_level.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_profile_resolver_service.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolution.dart`。测试/验证结果：`dart test test/continuous_task_tool_exposure_runtime_resolver_service_test.dart test/tool_strategy_service_test.dart test/tool_exposure_policy_service_test.dart` 通过。残留风险：当前 prompt 层仍承载面向模型的工具解释文本，后续 runtime/UI session 需要继续保持它与矩阵合同同步，但没有发现第二套工具 truth。
- `SUBD-03`：2026-06-15 已完成。关键修改点：确认单智能体 / 多智能体 / 审核智能体 / reviewer dispatch 已经由 `AgentGroupDelegationCapabilityService`、`AgentCollaborationBriefService`、`ReviewerSelectionService` 与 `ProjectWorkflowReviewerDispatchService` 形成统一协作合同；单智能体组会被正确降级为不开放子智能体委派，reviewer 缺失时会稳定回落到 self-review，而 runtime 侧只消费该协作决策，不再额外维护第二套协作判断。主要文件：`packages/novel_agent_core/lib/src/agents/agent_group_delegation_capability_service.dart`、`packages/novel_agent_core/lib/src/agents/agent_collaboration_brief_service.dart`、`packages/novel_agent_core/lib/src/agents/single_agent_group_adapter_service.dart`、`packages/novel_agent_core/lib/src/agents/reviewer_selection_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_workflow_reviewer_dispatch_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`。测试/验证结果：`dart test test/agent_group_delegation_capability_service_test.dart test/reviewer_selection_service_test.dart` 通过；`dart test test/project_workflow_runtime_service_test.dart -n "reviewer"` 通过。残留风险：协作能力解释文案仍分布在 core 与 runtime 两侧，但当前没有出现可见的双主链或能力误判。
- `SUBD-04`：2026-06-15 已完成。关键修改点：确认产物分类与路径真相已经由 `ProjectContentPathPolicyService`、`ProjectNarrativeArtifactPathPolicyService`、`ChapterOutputPathPolicyService` 和 `LongTaskChapterOutputPolicyService` 共同收口，样章、正文、场景、规划和章节命名不再依赖彼此冲突的零散判断；其中样章明确不是正文，场景仅作为局部叙事片段，章节路径命名继续由章号与标题的稳定合同决定。主要文件：`packages/novel_agent_core/lib/src/project/project_content_path_policy_service.dart`、`packages/novel_agent_core/lib/src/project/project_narrative_artifact_path_policy_service.dart`、`packages/novel_agent_core/lib/src/project/chapter_output_path_policy_service.dart`、`packages/novel_agent_core/lib/src/workflow/chapter_atomic_output_path_service.dart`、`packages/novel_agent_core/lib/src/workflow/long_task_chapter_output_policy_service.dart`、`packages/novel_agent_core/lib/src/project/project_workspace_catalog.dart`。测试/验证结果：新增 `packages/novel_agent_core/test/project_narrative_artifact_path_policy_service_test.dart`；并通过 `dart test test/project_narrative_artifact_path_policy_service_test.dart test/chapter_output_path_policy_service_test.dart test/project_content_path_policy_service_test.dart test/long_task_chapter_output_policy_service_test.dart`。残留风险：`ProjectContentPathPolicyService` 仍保留对未知根目录的章节级兼容回退，后续导入/reader session 需要继续把来源、研究与拆书产物路径收束到更具体合同上。
- `SUBD-05`：2026-06-15 已完成。关键修改点：确认 opening 合同已经被 runtime / projection 主链稳定消费，`ProjectOpeningSessionProjectionService` 统一把项目类型、智能体组、模式引导和 readiness 收束成 `OpeningSessionProjection`，`LongTaskStartActionPolicyService` 只暴露单一长任务启动动作，而 `ConversationGuideViewDataService` 也改为直接消费 opening projection 的 agent-first 收束语义，没有再分裂出第二套开局决定中心。主要文件：`packages/novel_agent_core/lib/src/opening/opening_orchestration_service.dart`、`packages/novel_agent_core/lib/src/opening/opening_readiness_evaluator.dart`、`packages/novel_agent_core/lib/src/opening/opening_stage_record_builder_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/project_opening_session_projection_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/long_task_start_action_policy_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/conversation_guide_view_data_service.dart`。测试/验证结果：`dart test test/opening_orchestration_service_test.dart` 通过；`flutter test test/project_opening_session_projection_service_test.dart test/long_task_start_action_policy_service_test.dart test/conversation_guide_view_data_service_test.dart` 通过。残留风险：`ProjectConversationDraftRuntimeService` 仍按 taskType 进行普通会话/连续任务上下文分流，后续 runtime session 需要继续与 opening projection 的单一入口语义保持同步。
- `SUBD-06`：2026-06-15 已完成。关键修改点：补齐 `analysis` 的正式内容目录映射，避免分析产物回落到章节目录；同步收紧 `ProjectWorkflowRuntimeService` 对 planning 产物“已存在”的判定，空文件不再被当作满足的 canonical artifact；并新增 `WorkflowRuntimeSatisfiedOutputPathService` focused 测试，确认 non-empty planning outputs 可从磁盘复用回运行时输出集合。主要文件：`packages/novel_agent_core/lib/src/project/project_content_path_policy_service.dart`、`packages/novel_agent_core/lib/src/runtime/draft_file_path_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/workflow_runtime_satisfied_output_path_service.dart`、`packages/novel_agent_core/test/project_content_path_policy_service_test.dart`、`packages/novel_agent_core/test/draft_file_path_service_test.dart`、`packages/novel_agent_adapters/test/workflow_runtime_satisfied_output_path_service_test.dart`。测试/验证结果：`dart test test/project_content_path_policy_service_test.dart test/draft_file_path_service_test.dart` 通过；`dart test test/workflow_runtime_satisfied_output_path_service_test.dart` 通过；`dart test test/project_workflow_runtime_service_test.dart -n "canonical planning artifact"` 通过。残留风险：planning 复用合同已对齐，但后续仍需在更广泛的导入/来源分流 session 里继续确认来源层、分析层与正式正文层不会重新交叉。
- `SUBD-07`：2026-06-15 已完成。关键修改点：确认工具暴露运行时主链已由 `ContinuousTaskToolExposureRuntimeResolverService` 统一承接，`ProjectWorkflowRuntimeBridgeService` 将 bridge 输出的 `workflow_tool_ids` 统一投影给 `ProjectConversationDraftRuntimeService` 与 `ProjectWorkflowRuntimeService`，`set_agent_tasks` 与 `call_sub_agent` 的抑制/开放仍然只由统一合同消费；conversation 侧只保留单成员组的 `call_sub_agent` 安全收口，不再自造一套独立暴露矩阵。主要文件：`packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`。测试/验证结果：`dart test test/project_workflow_runtime_bridge_service_test.dart test/project_conversation_draft_runtime_service_test.dart` 通过；`dart test test/project_workflow_runtime_service_test.dart -n "canonical planning artifact"` 已通过同一文件中的 planning 复用回归链验证，确认 runtime 侧不会在 planning 工件上再分叉工具暴露。残留风险：conversation/runtime 两条入口仍各自做少量任务型抑制逻辑，后续需要在更高层 session 继续观察是否还能进一步合并为单一入口投影。
- `SUBD-08`：2026-06-15 已完成。关键修改点：确认 reviewer / delegation 协作合同已由 `AgentGroupDelegationCapabilityService`、`AgentCollaborationBriefService`、`ReviewerSelectionService` 与 `ProjectWorkflowReviewerDispatchService` 共同承载，review 任务在 runtime 中会按 reviewer-like -> critic/editor -> primary self-review 顺序稳定收束；`ProjectWorkflowRuntimeService` 只消费 reviewer dispatch 结果，不再单独发明 reviewer 判断中心。主要文件：`packages/novel_agent_core/lib/src/agents/agent_group_delegation_capability_service.dart`、`packages/novel_agent_core/lib/src/agents/agent_collaboration_brief_service.dart`、`packages/novel_agent_core/lib/src/review/reviewer_selection_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_workflow_reviewer_dispatch_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`。测试/验证结果：`dart test test/agent_group_delegation_capability_service_test.dart test/reviewer_selection_service_test.dart` 通过；`dart test test/project_workflow_runtime_service_test.dart -n "dispatches review tasks to the selected reviewer child with isolated tool scope|falls back to primary writer self-review when no reviewer-like child exists"` 通过。残留风险：`project_workflow_runtime_service_test.dart` 中仍有一个邻接的 child-specific tool-policy 测试对当前工具暴露预期较激进，属于工具策略邻域而不是 reviewer dispatch 主线，后续可在 `SUBD-07`/`SUBD-12` 邻近 session 里再单独收口。
- `SUBD-09`：2026-06-15 已完成。关键修改点：核查并确认会话恢复真相由 `ProjectSessionWorkspaceService.loadSessions` 提供，`WorkbenchConversationController.restoreProjectSessions` 负责把持久化的 `sessionRecord` 通过 `ConversationSessionStateService.restoreSession` 还原为稳定会话骨架，再由 `WorkbenchConversationRuntimeState` 统一持有 `sessions`、`activeSessionId` 与 `showSessionHistory`；历史投影继续由 `ConversationSessionStateService.historyEntries` 收口，不再散落到 widget。滚动锚点方面，`ConversationTimeline` 已用内部 `_anchoredToLatest` + `ConversationTimelineAutoRevealPolicy` 形成明确的自动回揭 hook，`ConversationTimeline` 初次渲染会稳定追到最新内容，满足恢复后滚动策略的可测合同。主要文件：`apps/novel_agent_app/lib/app/state/app_shell_controller.dart`、`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_timeline.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/services/conversation_timeline_auto_reveal_policy.dart`。测试/验证结果：`flutter test test/conversation_session_state_service_test.dart test/conversation_timeline_auto_reveal_policy_test.dart test/conversation_timeline_test.dart test/workbench_workspace_controller_snapshot_test.dart` 通过。残留风险：当前滚动锚点仍是 widget 局部状态回揭合同，尚未提升为跨会话持久化状态；但这不影响本轮“项目重载后稳定恢复与显示”的验收。
- `SUBD-10`：2026-06-15 已完成。关键修改点：确认项目类型、存储载体与类型转换能力矩阵已经由 `ProjectTypeDefinition`、`ProjectTypeCatalogService`、`ProjectStorageStrategy`、`ProjectManifestCodecService`、`ProjectTypeTransitionPolicy`、`ProjectTypeTransitionPreparationService`、`ExecuteProjectTypeTransitionUseCase` 与 `ProjectStorageAwareToolCapabilityMatrix` 共同收口；`knowledge_base` 在 core 层维持 `sqlite_project_store` only，`novel <-> long_novel` 第一阶段互转图保持唯一可用图且不混入存储迁移，转换执行只补运行基准与运行配置，不新增平行项目类型语义。主要文件：`packages/novel_agent_core/lib/src/project/project_type_definition.dart`、`packages/novel_agent_core/lib/src/project/project_type_catalog_service.dart`、`packages/novel_agent_core/lib/src/project/project_storage_strategy.dart`、`packages/novel_agent_core/lib/src/project/project_manifest_codec_service.dart`、`packages/novel_agent_core/lib/src/project/project_type_transition_policy.dart`、`packages/novel_agent_core/lib/src/project/project_type_transition_preparation_service.dart`、`packages/novel_agent_core/lib/src/use_cases/execute_project_type_transition_use_case.dart`、`packages/novel_agent_core/lib/src/use_cases/update_project_manifest_use_case.dart`、`packages/novel_agent_core/lib/src/tools/project_storage_aware_tool_capability_matrix.dart`、`packages/novel_agent_adapters/lib/src/storage/project_sqlite_path_service.dart`。测试/验证结果：`dart test test/project_type_catalog_service_test.dart test/project_type_transition_policy_test.dart test/project_manifest_storage_strategy_test.dart test/project_type_transition_use_case_test.dart test/project_storage_aware_tool_capability_matrix_test.dart` 通过；`dart test test/project_storage_strategy_resolver_test.dart` 通过。残留风险：后续 `SUBD-11 ~ SUBD-16` 仍需持续把这套矩阵下沉到 GUI / ViewModel / probe 消费层，避免壳层重新长出第二套项目类型语义或 storage-aware 偏差。
- `SUBD-11`：2026-06-15 已完成。关键修改点：确认用户确认边界与智能体自补全策略已经由 `ProjectFactAcquisitionContractService`、`ProjectFactAcquisitionContract`、`ProjectFactAcquisitionLane`、`ProjectFactAcquisitionStatus` 以及 `OpeningOrchestrationService`、`SessionGoalPromptBuilderService`、`LongTaskEntryPromptBuilderService`、`LongTaskOpeningPromptBuilderService` 共同收口；三态语义 `confirmed / pending_confirmation / tentative_assumption` 已分别对应长期已确认事实、候选待确认方向与低风险暂借假设，普通项目、长任务和导入/开局提示都消费同一份合同，不再各自发明一套确认边界。主要文件：`packages/novel_agent_core/lib/src/project/project_fact_acquisition_contract_service.dart`、`packages/novel_agent_core/lib/src/project/project_fact_acquisition_contract.dart`、`packages/novel_agent_core/lib/src/project/project_fact_acquisition_lane.dart`、`packages/novel_agent_core/lib/src/project/project_fact_acquisition_status.dart`、`packages/novel_agent_core/lib/src/opening/opening_orchestration_service.dart`、`packages/novel_agent_core/lib/src/session/session_goal_prompt_builder_service.dart`、`packages/novel_agent_core/lib/src/workflow/long_task_entry_prompt_builder_service.dart`、`packages/novel_agent_core/lib/src/workflow/long_task_opening_prompt_builder_service.dart`。测试/验证结果：`dart test test/project_fact_acquisition_contract_service_test.dart test/opening_orchestration_service_test.dart test/session_goal_prompt_builder_service_test.dart test/long_task_entry_prompt_builder_service_test.dart test/project_prompt_contract_test.dart` 通过。残留风险：当前合同仍以 markdown/prompt 投影为主，后续 `SUBD-12` 需要继续把表达限制与审核限制收口到真正的运行时消费链，避免边界语义只停留在提示词文本里。
- `SUBD-12`：2026-06-15 已完成。关键修改点：确认表达限制的默认装载、运行时注入、review 投影与 gate/supervisor 消费已经由 `ProjectCreationExpressionConstraintDefaultsSettingsService`、`ProjectCreationExpressionConstraintDefaultsService`、`ProjectExpressionConstraintBindingResolverService`、`ExpressionConstraintExecutionPolicyResolverService`、`ExpressionConstraintInjectionPolicyService`、`WritingExecutionConstraintBridgeService`、`ExpressionConstraintReviewProjectionService`、`ExpressionConstraintReviewContractMapperService`、`ExpressionConstraintGateSignalService` 与 `ExpressionConstraintSupervisorSignalService` 共同收口；默认装载支持 builtin fallback / custom / disabled 三态，运行时会把 bindings、policy、review 证据与 supervisor 信号串成同一条链，review 不是只停留在 prompt 文本，而是会进入结构化合同与 gate 结果。主要文件：`packages/novel_agent_core/lib/src/creative/expression_constraint_execution_policy.dart`、`packages/novel_agent_core/lib/src/creative/expression_constraint_injection_policy_service.dart`、`packages/novel_agent_core/lib/src/creative/project_expression_constraint_binding_resolver_service.dart`、`packages/novel_agent_core/lib/src/creative/expression_constraint_review_projection_service.dart`、`packages/novel_agent_core/lib/src/review/expression_constraint_review_contract_mapper_service.dart`、`packages/novel_agent_core/lib/src/workflow/expression_constraint_gate_signal_service.dart`、`packages/novel_agent_core/lib/src/workflow/expression_constraint_supervisor_signal_service.dart`、`packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`、`apps/novel_agent_app/lib/features/project_creation/application/services/project_creation_expression_constraint_defaults_settings_service.dart`、`apps/novel_agent_app/lib/features/project_creation/application/services/project_creation_expression_constraint_defaults_service.dart`。测试/验证结果：`dart test test/expression_constraint_execution_policy_resolver_service_test.dart test/expression_constraint_injection_policy_service_test.dart test/expression_constraint_review_contract_mapper_service_test.dart test/writing_execution_constraint_bridge_service_test.dart test/project_prompt_contract_test.dart` 通过；`flutter test test/project_creation_expression_constraint_defaults_settings_service_test.dart test/project_creation_expression_constraint_defaults_service_test.dart test/project_creation_expression_constraint_defaults_panel_test.dart test/project_creation_expression_constraint_defaults_view_data_service_test.dart` 通过。残留风险：表达限制相关实现文件较多，后续 `SUBD-13` 仍需继续把 watchdog / supervisor / reviewer 生命周期边界收紧，避免 gate 信号和 review 合同在更高层再次分叉。
- `SUBD-13`：2026-06-15 已完成。关键修改点：补齐统一生命周期事件合同 `ContinuousTaskLifecycleEvent` 与 `ContinuousTaskLifecycleEventResolverService`，把 pause / resume / recover / waiting_user / manual_attention / finish / fail / cancel / stop 统一投影为可序列化、可验证的正式事件；与既有 `ContinuousTaskLifecycleState`、`ContinuousTaskLifecycleStateResolverService`、`ContinuousTaskLifecycleStopOutcomeResolverService` 共同收口 watchdog / supervisor / reviewer 的职责边界，避免把存活判断和内容审查混回同一层。主要文件：`packages/novel_agent_core/lib/src/workflow/continuous_task_lifecycle_event.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_lifecycle_event_resolver_service.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_lifecycle_state.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_lifecycle_state_resolver_service.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_lifecycle_stop_outcome_resolver_service.dart`、`packages/novel_agent_core/test/continuous_task_lifecycle_event_test.dart`、`packages/novel_agent_core/test/continuous_task_lifecycle_state_resolver_service_test.dart`、`packages/novel_agent_core/test/continuous_task_lifecycle_stop_outcome_resolver_service_test.dart`、`packages/novel_agent_core/test/continuous_task_recovery_state_factory_service_test.dart`。测试/验证结果：`dart test test/continuous_task_lifecycle_event_test.dart test/continuous_task_lifecycle_state_resolver_service_test.dart test/continuous_task_lifecycle_stop_outcome_resolver_service_test.dart test/continuous_task_recovery_state_factory_service_test.dart` 通过。残留风险：事件模型目前先作为核心正式合同与验证点落地，后续 `SUBD-14` 及其后的连续性底座 session 还要继续把它稳定消费到更宽的运行链里，避免重新分裂出旁路事件语义。
- `SUBD-14`：2026-06-15 已完成。关键修改点：确认长任务写作链与参考提取链已经通过统一的 continuous task 合同接入同一连续性底座，`ContinuousTaskProfileResolverService` 负责把 long task / goal mode / reference extraction / research consolidation 投影成同一 `ContinuousTaskProfile`，`ContinuousTaskSupervisorBridgeService` 与 `LongTaskSupervisor` 共同承载 pause / resume / recover / retry / heartbeat / recovery state 的正式主链，`ReferenceExtractionContinuousTaskSyncService` 则把 reference extraction 的开始、结果、失败和恢复信号稳定同步到同一监督面；提取链没有再长出独立保活 runtime，长任务与提取任务都消费同一 watchdog / supervisor 纪律。主要文件：`packages/novel_agent_core/lib/src/workflow/continuous_task_profile_resolver_service.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_profile.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_control_profile.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_supervisor_profile.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_recovery_state_factory_service.dart`、`packages/novel_agent_core/lib/src/reference_extraction/reference_extraction_execution_discipline.dart`、`packages/novel_agent_core/lib/src/reference_extraction/reference_extraction_run_models.dart`、`packages/novel_agent_adapters/lib/src/runtime/continuous_task_supervisor_bridge_service.dart`、`packages/novel_agent_adapters/lib/src/runtime/long_task_supervisor.dart`、`packages/novel_agent_adapters/lib/src/runtime/long_task_watchdog.dart`、`packages/novel_agent_adapters/lib/src/runtime/long_task_heartbeat_scheduler.dart`、`packages/novel_agent_adapters/lib/src/reference_extraction/reference_extraction_continuous_task_sync_service.dart`、`packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart`。测试/验证结果：`dart test test/continuous_task_supervisor_bridge_service_test.dart test/long_task_supervisor_test.dart` 通过；`dart test test/continuous_task_profile_resolver_service_test.dart` 通过。残留风险：提取链与长任务链已经共享同一连续性底座，但后续 `SUBD-15` 仍要继续拆掉过大的控制器和 runtime，避免这套正式合同又被壳层和巨型 service 重新吞回去。
- `SUBD-15`：2026-06-15 已完成。关键修改点：把任务中心刷新与命令编排从 `AppShellController` 中拆出到 `TaskCenterRefreshService`、`TaskCenterCommandOrchestrationService`，并把 `ProjectWorkflowRuntimeService` 的 workflow 选路收束到 `ProjectWorkflowTaskSelectionService` 与 `TaskCenterRuntimeQueryPort`；壳层控制器现在只保留状态编排与正式委派，不再自己承担 task center 的重度拼装逻辑。主要文件：`apps/novel_agent_app/lib/features/task_center/application/services/task_center_refresh_service.dart`、`apps/novel_agent_app/lib/features/task_center/application/services/task_center_command_orchestration_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_workflow_task_selection_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/task_center_runtime_query_port.dart`、`apps/novel_agent_app/lib/app/state/app_shell_controller.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`。测试/验证结果：`flutter test test/task_center_refresh_service_test.dart test/task_center_command_orchestration_service_test.dart` 通过；`flutter test test/app_shell_task_center_workflow_create_request_test.dart` 通过；`flutter test test/app_shell_task_center_long_task_refresh_regression_test.dart` 通过。残留风险：`AppShellController` 仍然是体量很大的壳层控制器，且 task center / long task station 的回流链仍需继续观察，但本轮已把最重的 task center 事实源从控制器中正式收束到专用服务。
- `SUBD-16`：2026-06-15 已完成。关键修改点：冻结了中性的 source import contract 底座，新增 `SourceImportRequest`、`SourceImportSelection`、`SourceImportNormalizedDocument` 与 `SourceImportNormalizationService`，统一表达单文件、目录、集合、多来源、来源身份、排序、媒体类型与相对路径提示；拆书侧通过 `BookDeconstructionInput.fromSourceImportDocuments` 与 `BookDeconstructionSourceDocument.fromSourceImportDocument` 消费同一份标准化来源文档，一般导入用例也可通过新 request 入口消费同一合同，而没有把拆书私有语义写回共享来源层。主要文件：`packages/novel_agent_core/lib/src/imports/source_import_request.dart`、`packages/novel_agent_core/lib/src/imports/source_import_selection.dart`、`packages/novel_agent_core/lib/src/imports/source_import_normalized_document.dart`、`packages/novel_agent_core/lib/src/imports/source_import_normalization_service.dart`、`packages/novel_agent_core/lib/src/use_cases/import_project_files_use_case.dart`、`packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_input.dart`、`packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_source_document.dart`、`packages/novel_agent_core/test/source_import_contract_test.dart`。测试/验证结果：`dart test test/source_import_contract_test.dart test/book_deconstruction_application_plan_builder_service_test.dart test/book_deconstruction_narrative_bridge_service_test.dart` 通过；`dart test test/writing_continuity_validation_matrix_test.dart` 通过。残留风险：共享导入合同当前仍停留在中性规范化与桥接层，尚未进入目录扫描、EPUB reader 或 GUI 分流，后续 `SUBD-17` 将继续把发现/扫描/格式识别正式落到适配器层。
- `SUBD-17`：2026-06-15 已完成。关键修改点：在 adapters / persistence 层建立了共享来源发现与多格式 reader 底座，新增 `SourceImportDiscoveryService`、`SourceImportPathScannerService`、`SourceDocumentFormatCatalogService`、`SourceDocumentTextReaderService`、`SourceDocumentEpubReaderService` 与 `ReferenceSourceDocumentFileReaderService` 的正式路由，统一支持单文件、目录、递归扫描、格式过滤，并把 `.txt / .md / .markdown / .epub` 收口到同一条可扩展格式目录；`ImportProjectFilesUseCase` 现在可以消费 discovery 结果来保留目录层级，GUI 桌面文件选择器也复用同一格式目录提示，避免只靠扩展名拼特判。主要文件：`packages/novel_agent_core/lib/src/imports/source_import_discovery_port.dart`、`packages/novel_agent_core/lib/src/imports/source_import_discovery_result.dart`、`packages/novel_agent_core/lib/src/use_cases/import_project_files_use_case.dart`、`packages/novel_agent_adapters/lib/src/storage/source_import_discovery_service.dart`、`packages/novel_agent_adapters/lib/src/storage/source_import_path_scanner_service.dart`、`packages/novel_agent_adapters/lib/src/storage/source_document_format_catalog_service.dart`、`packages/novel_agent_adapters/lib/src/storage/source_document_text_reader_service.dart`、`packages/novel_agent_adapters/lib/src/storage/source_document_epub_reader_service.dart`、`packages/novel_agent_adapters/lib/src/storage/reference_source_document_file_reader_service.dart`、`apps/novel_agent_app/lib/shared/services/desktop_text_file_picker_service.dart`。测试/验证结果：`dart test test/import_project_files_use_case_test.dart` 通过；`dart test test/source_import_discovery_service_test.dart test/reference_source_document_file_reader_service_test.dart test/reference_source_document_ingestion_service_test.dart` 通过；`flutter test test/project_import_execution_service_test.dart` 通过；`dart analyze packages/novel_agent_core packages/novel_agent_adapters apps/novel_agent_app` 无错误，仅保留仓库既有 warning 噪声。残留风险：EPUB reader 当前覆盖常见 container / OPF / spine / XHTML 路线，后续若要支持更复杂的加密或异常容器再继续扩展，但本轮目标所需的正式 reader 路线已经收口。
- `SUBD-18`：2026-06-15 已完成。关键修改点：拆书导入入口现在会通过正式 reader 读取源文件后，立即把原文归档到 `sources/original/`，并把预演纪要稳定写入 `analysis/`，不再把原文或预演混写进 `chapters/`；`BookDeconstructionTargetPathService` 统一承载原文归档路径和预演路径，`BookDeconstructionNarrativePersistenceService` 继续把拆书确认后的结构化产物写回正式信息层，而不是让 GUI 自己分流目录真相。主要文件：`apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`、`apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart`、`apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart`、`packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_target_path_service.dart`、`apps/novel_agent_app/test/book_deconstruction_controller_test.dart`。测试/验证结果：`flutter test test/book_deconstruction_controller_test.dart` 通过。残留风险：continuation / fanfic 的后续分流还需要在下一轮 session 中继续正式收口，但原文留存与预演分层已经先稳定下来。
- `SUBD-19`：2026-06-15 已完成。关键修改点：拆书 followup 菜单正式收口为 `continuation` 与 `fanfic` 两条主分流，并在核心合同里新增 `BookDeconstructionSourceInheritanceMode`、`BookDeconstructionFollowupOption`、`BookDeconstructionDerivedProjectPlan` 的来源继承字段，让 `continuation` 进入叙事连续体、`fanfic` 保留在来源 / 参考层；一般项目导入则通过 `ProjectImportRequest`、`ProjectImportActionPolicy`、`ProjectImportExecutionService` 和 `ProjectImportWorkspaceCommandViewDataService` 接入智能分析边界，分析报告稳定写入 `analysis/project_import_analysis.md`，且仅在已有项目导入场景出现，不污染拆书主链。主要文件：`packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_menu_builder_service.dart`、`packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_followup_option.dart`、`packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_derived_project_plan.dart`、`packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_derived_project_plan_builder_service.dart`、`packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_source_inheritance_mode.dart`、`apps/novel_agent_app/lib/features/workbench/application/models/project_import_request.dart`、`apps/novel_agent_app/lib/features/workbench/application/models/project_import_action_policy.dart`、`apps/novel_agent_app/lib/features/workbench/application/models/project_import_execution_result.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/project_import_action_policy_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/project_import_execution_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/project_import_workspace_command_view_data_service.dart`、`apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart`。测试/验证结果：`dart test test/book_deconstruction_followup_menu_builder_service_test.dart` 通过；`flutter test test/book_deconstruction_view_data_service_test.dart test/book_deconstruction_draft_builder_service_test.dart test/project_import_action_policy_service_test.dart test/project_import_execution_service_test.dart test/workspace_command_overlay_test.dart` 通过。残留风险：一般导入的智能分析目前仍采用轻量内容分类启发式，后续若要接入更强的分析智能体执行链，可以在 `SUBD-20` 之后继续扩展，但当前 session 的分流与边界已经收口。
- `SUBD-20`：2026-06-15 已完成。关键修改点：GUI / ViewModel 侧已经正式消费 `SUBD-16` 到 `SUBD-19` 的稳定合同，`BookDeconstructionPage`、`BookDeconstructionController`、`BookDeconstructionImportPanel`、`BookDeconstructionPreviewPanel` 与 `WorkspaceCommandOverlay` 都只通过 view data / action handler / import policy / execution result 来串起导入、预览、确认与一般导入智能分析；拆书预览、followup 路线和共享资料桥都只读 `BookDeconstructionViewData`，一般导入侧则只读 `ProjectImportActionPolicy` / `ProjectImportExecutionResult`，不再把旧内存态或临时导入判断留在 widget 层。主要文件：`apps/novel_agent_app/lib/features/book_deconstruction/presentation/pages/book_deconstruction_page.dart`、`apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`、`apps/novel_agent_app/lib/features/book_deconstruction/presentation/widgets/book_deconstruction_import_panel.dart`、`apps/novel_agent_app/lib/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/widgets/workspace_command_overlay.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/project_import_workspace_command_view_data_service.dart`。测试/验证结果：`flutter test test/book_deconstruction_preview_panel_test.dart test/book_deconstruction_controller_test.dart` 通过；`flutter test test/book_deconstruction_view_data_service_test.dart test/project_import_action_policy_service_test.dart test/project_import_execution_service_test.dart test/workspace_command_overlay_test.dart` 通过。残留风险：页面与面板当前仍以稳定合同里的英文 route id 作为正式标签，若后续需要把这层再做中文化展示，应单独在展示层做本地化投影，不要回写到 core 合同里。
- `SUBD-21`：2026-06-15 已完成。关键修改点：`SessionGoalPromptBuilderService` 在 `continue_writing` 模式下会根据当前打开文档或片段里的章号显式补出“下一章目标”提示，避免只把上一章门前状态喂给运行时；`AppShellController` 透出可等待的 `openResource` 公开入口，供高保真探针用真实 controller 路径把上一章打开为活动文档；`real_gui_chaptered_continuation_probe.dart` 改为先打开第 02 章再触发继续创作，并把 activation report 选择逻辑收束为最新成功轮次，避免把前一轮失败的旧 report 当成最终证据。主要文件：`packages/novel_agent_core/lib/src/session/session_goal_prompt_builder_service.dart`、`packages/novel_agent_core/test/session_goal_prompt_builder_service_test.dart`、`apps/novel_agent_app/lib/app/state/app_shell_controller.dart`、`apps/novel_agent_app/tool/real_gui_chaptered_continuation_probe.dart`。测试/验证结果：`dart test test/session_goal_prompt_builder_service_test.dart` 通过；`dart test test/project_conversation_draft_runtime_service_test.dart -n \"prepareDraftRun resolves target chapter from mixed prompt\"` 通过；`NOVEL_AGENT_ENABLE_REAL_PROBES=1 NOVEL_AGENT_PROBE_API_FILE=local/probe_api.txt flutter test test/real_gui_chaptered_continuation_probe_test.dart` 通过；最终成功 lane：`artifacts/high_fidelity_viewmodel_validation/2026-06-15T18-10-46-289841/lane_ordinary_chaptered_continuation/lane_report.json`，其中 `ok=true`、`report_category=success`、`continuity_selected=true`、`chapter_3_path=chapters/第03章_试手.md`、`chapter_3_body_length=2514`、`chapter_3_delivery_has_handoff=true`。残留风险：该 lane 仍依赖真实 provider 与测试种子资产结构，但目前没有发现新的 production 语义缺口。
- `SUBD-22`：2026-06-15 已完成。关键修改点：补齐并验证了拆书与导入链的高保真 probe，真实探针 `real_gui_book_deconstruction_import_probe.dart` 通过正式 controller / reader / import / smart-analysis 主链验证了拆书原文归档、目录发现、多格式读取、continuation / fanfic 分流与一般导入智能分析可见性；一般导入智能分析在读取导入文件时优先走 `ReferenceSourceDocumentFileReaderService`，再在必要时回退到项目工作区读文本，确保 `.txt / .md / .epub` 仍沿同一正式 reader 路线消费。主要文件：`apps/novel_agent_app/tool/real_gui_book_deconstruction_import_probe.dart`、`apps/novel_agent_app/test/real_gui_book_deconstruction_import_probe_test.dart`、`apps/novel_agent_app/test/project_import_execution_service_test.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/project_import_execution_service.dart`、`apps/novel_agent_app/tool/README.md`。测试/验证结果：`flutter test test/project_import_execution_service_test.dart` 通过；`flutter test test/real_gui_book_deconstruction_import_probe_test.dart` 通过。残留风险：真实 probe 仍依赖本地显式开闸与 `local/probe_api.txt` 配置，后续若要扩大样本或增加异常容器格式，需要继续在正式 reader / import 主链上扩展，而不要把分类逻辑回流到 probe。
- `SUBD-23`：2026-06-15 已完成。关键修改点：确认产品壳层已经通过 `AppShell` 的 `PopScope` 与 `handleSystemBackRequested` 形成统一返回链，紧凑壳层会先关闭抽屉再把系统返回交回壳层判断，不再把 back 语义留给页面自己各自处理；同时复核项目打开、项目创建与知识库类型创建的投影合同，`ProjectOpenViewDataService`、`ProjectCreationController`、`ProjectLauncherViewDataService`、`ProjectCreatePanel` 与 `WorkbenchProjectPanelActionPolicyService` 都保持了“打开项目 / 新建项目 / 资料知识库 SQLite-only / 普通写作双存储”的正式入口语义。主要文件：`apps/novel_agent_app/lib/app/state/app_shell_controller.dart`、`apps/novel_agent_app/lib/shared/widgets/app_shell.dart`、`apps/novel_agent_app/lib/shared/widgets/app_shell_compact_scaffold.dart`、`apps/novel_agent_app/lib/features/project_creation/application/controllers/project_creation_controller.dart`、`apps/novel_agent_app/lib/features/project_open/application/services/project_open_view_data_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/workbench_project_panel_action_policy_service.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_create_panel.dart`、`apps/novel_agent_app/test/app_shell_compact_scaffold_test.dart`、`apps/novel_agent_app/test/project_creation_controller_test.dart`、`apps/novel_agent_app/test/project_launcher_view_data_service_test.dart`、`apps/novel_agent_app/test/project_create_panel_continuity_test.dart`、`apps/novel_agent_app/test/project_open_view_data_service_test.dart`。测试/验证结果：`flutter test test/app_shell_compact_scaffold_test.dart` 通过；`flutter test test/project_creation_controller_test.dart` 通过；`flutter test test/project_launcher_view_data_service_test.dart` 通过；`flutter test test/project_create_panel_continuity_test.dart` 通过；`flutter test test/project_open_view_data_service_test.dart` 通过。残留风险：`AppShellController` 体量仍然偏大，且部分入口文案仍使用工作台/启动器内部术语；当前没有发现新的入口语义漂移，但若后续再加壳层能力，仍需继续防止新入口回流成第二套调度中心。
- `SUBD-24`：2026-06-15 已完成。关键修改点：整理并固化了本主线的收口证据与交接入口，补写了主任务文档的全部完成记录，并新增 `subd-mainline-handoff-2026-06-15.md` 作为一页式交接摘要，集中列出已完成范围、关键 probe / regression 证据、残留风险和下一阶段入口；没有再扩大生产代码改动。主要文件：`docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md`、`docs/important/subd-mainline-handoff-2026-06-15.md`、`docs/important/project-unreasonable-areas-audit-2026-06-15.md`、`docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`、`docs/important/high-fidelity-viewmodel-validation-analysis-2026-06-10.md`。测试/验证结果：复核并引用了 `artifacts/real_gui_book_deconstruction_import_probe_report.md`、`artifacts/real_gui_book_deconstruction_import_probe_report.json`、`artifacts/high_fidelity_viewmodel_validation/2026-06-15T18-10-46-289841/lane_ordinary_chaptered_continuation/lane_report.json`，并确认前序 focused tests 全部通过。残留风险：当前残留项已登记为可延后风险，若后续开启新主线，应先重新读取主任务文档与交接摘要，避免重新摸索。
