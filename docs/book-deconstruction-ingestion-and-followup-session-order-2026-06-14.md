# NovelAgentFlutter 拆书导入、原文留存、文件夹解析与后续导向任务顺序文档

最后更新：2026-06-14

主线代号：`BDI`（Book Deconstruction Ingestion）

关联主要资料：

- `agent.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`
- `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`

关联历史任务顺序文档：

- `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md`
- `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md`
- `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md`
- `docs/context-token-budget-and-compaction-session-order-2026-06-14.md`

关联代码锚点：

- `apps/novel_agent_app/lib/features/book_deconstruction/`
- `apps/novel_agent_app/lib/features/workbench/application/services/project_import_action_policy_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/project_import_execution_service.dart`
- `apps/novel_agent_app/lib/shared/services/desktop_text_file_picker_service.dart`
- `packages/novel_agent_core/lib/src/deconstruction/`
- `packages/novel_agent_core/lib/src/use_cases/import_project_files_use_case.dart`
- `packages/novel_agent_adapters/lib/src/storage/local_project_file_mutation_adapter.dart`

---

## 1. 这份文档解决什么

这份文档不是只解决“拆书多支持一个 `epub` 扩展名”这么窄的事情，而是把当前这条已经半成型、但边界还不干净的主线正式收口：

```text
把“拆书导入、原文归档、自动拆书预演、一般项目导入、文件夹/多格式支持、续写/同人分流”
收口成
“共享来源解析底座 + 拆书专属编排 + 一般导入智能分流 + 原文必留 + 后续导向明确”的正式能力链。
```

完成本主线后，项目应具备：

1. 拆书项目和一般项目都能消费同一套“来源发现 / 解析 / 标准化来源文档”底座。
2. 拆书原文在任何入口下都必留，不再出现“专用拆书面板只读内存、不归档原文”的断层。
3. 来源材料、拆书预演纪要、正式正文不再混写到同一内容层。
4. 拆书项目具备正式的“后续导向”次级选项：
   - `continuation`
   - `fanfic`
5. `continuation` 与 `fanfic` 的目录策略、后续桥接语义、正文接入方式明确分开。
6. 文件夹导入、多格式扫描、标准化来源文档成为共享底座，而不是拆书特例。
7. `epub` 被当作正式 reader 方向来实现，而不是只加扩展名。
8. 一般项目导入拥有“智能分析”能力，但这层只属于已有项目导入，不进入拆书主链。
9. 智能分析必须允许显式指定分析智能体或智能体组，不默认偷绑到主写作智能体。
10. probe / regression 消费 production 同源合同，不再靠第二套手搓判断。

---

## 2. 与旧文档的关系

### 2.1 它不是把拆书改造成知识库项目

这份文档明确继承并冻结下面这个判断：

1. 当前拆书项目先不接入知识库系统。
2. 拆书项目的主职责仍然是：
   - 导入来源作品
   - 结构化拆解
   - 为后续创作承接提供可复核底稿
3. 知识库治理和拆书分析存在重叠，但不是同一个产品入口。

所以这份文档不允许：

1. 把 `book_deconstruction` 直接改造成知识库项目。
2. 为了实现原文留存和多格式导入，绕过现有项目主链另起一套 runtime。
3. 把拆书提取结果强制写进知识库工作流，导致入口职责混杂。

### 2.2 它继承哪些已有判断

1. `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`
   - 已经给出本轮冻结边界，是本顺序文档的主依据。
2. `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
   - 提供了拆书续写这条线之前的产品语义判断。
3. `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
   - 提醒“所有有效信息都提取出来”不能按一次性全提完理解，而应具备可复跑、可补提、可追溯能力。

### 2.3 这份文档不处理什么

1. 不在这条主线里把拆书项目正式接入知识库系统。
2. 不在这条主线里做完整的“全书深度知识提取运行时”。
3. 不在这条主线里重构 CLI/TUI。
4. 不在这条主线里设计同人知识库或大框架知识体系。
5. 不把 UI 皮肤优化和导入架构主线混做一团。

---

## 3. 已有实现去重审计

### 3.1 已有可复用基础

1. `BookDeconstructionController`
2. `BookDeconstructionDraftBuilderService`
3. `BookDeconstructionNarrativePersistenceService`
4. `BookDeconstructionPreviewMarkdownService`
5. `ProjectImportActionPolicyService`
6. `ProjectImportExecutionService`
7. `ImportProjectFilesUseCase`
8. `ProjectToolHostPort.readExternalTextFile`
9. `WriteProjectTextFileUseCase`
10. `BookDeconstructionSourceDocument`

这些都不该推倒重来。

### 3.2 已有但仍是半成品

1. 专用拆书面板导入源文件后，只把内容放在内存中，不保证原文归档。
2. 工作台自动拆书会先导入文件，但默认把拆书项目原文放进 `chapters/`。
3. 自动拆书预演纪要对拆书项目默认也写进 `chapters/`。
4. 当前文件选择器只支持文本和 Markdown，不支持目录扫描，不支持 `epub`。
5. 当前自动拆书只支持单个 `.txt / .md / .markdown` 文件。
6. `BookDeconstructionSourceDocument` 结构过轻，不足以承担多来源、来源范围、归档身份、派生策略等信息。
7. 当前不存在共享“来源解析层”，只有零散的读文件和复制文件动作。
8. 一般项目导入还没有“智能分析”合同，更没有“选择分析智能体”的入口。
9. 拆书项目与一般项目尚未正式分开：
   - 共享什么解析底座
   - 不共享什么业务编排

### 3.3 真正缺的层

1. `source discovery / normalization` 核心合同
2. 文件夹导入与多格式 reader 层
3. 拆书原文归档统一策略
4. 拆书项目目录语义重分层
5. `followup_intent / deconstruction_target_mode` 合同
6. `continuation` 与 `fanfic` 的派生目录与正文映射规则
7. 一般项目导入智能分类合同
8. `analyzerAgentId / analyzerAgentGroupId` 合同与调度口
9. 高保真 probe / regression，验证：
   - 拆书原文必留
   - 拆书续写时原作章节进入正文连续体
   - 拆书同人时原作不污染正文
   - 一般项目导入智能分析只在已有项目导入时出现

---

## 4. 本轮冻结的架构边界

1. 拆书项目当前不接知识库系统，这个边界不动摇。
2. 拆书后的“续写 / 同人”是后续导向，不是新的主项目类型。
3. 拆书原文必须必留，不允许只存在于控制器内存或临时变量里。
4. 来源材料、拆书预演纪要、正式正文必须分层，不能继续混写在 `chapters/`。
5. `continuation` 与 `fanfic` 必须分开：
   - `continuation` 把原作视作同一叙事连续体的前段
   - `fanfic` 把原作视作来源体系与参考边界
6. 文件夹导入、多格式解析、标准化来源文档是共享底座，不是拆书私有逻辑。
7. 智能分析只属于“已有项目导入”，拆书导入不走智能分类。
8. 智能分析必须允许选择执行分析的智能体或智能体组。
9. 不允许为了快，把业务判断堆到 widget / controller / probe。
10. 不允许为了支持 `epub` 只加扩展名却继续用 `File.readAsString()` 假装支持。
11. 单文件接近 400 行时主动复核职责；接近 700 行必须拆。

---

## 5. 目标终态

完成本主线后，应达到以下终态：

1. 项目存在正式的共享来源解析层，能处理：
   - 单文件
   - 文件夹
   - 递归扫描
   - 支持格式识别
   - 标准化来源文档
2. 拆书项目任意入口导入后，原文都被归档到稳定来源层。
3. 拆书项目目录策略清楚区分：
   - 来源层
   - 预演/分析层
   - 正文层
4. 拆书确认时能显式选择后续导向：
   - `continuation`
   - `fanfic`
5. `continuation` 下，导入原作章节进入正文体系，但带有来源元数据与冻结身份。
6. `fanfic` 下，原作章节停留在来源/参考层，不直接进入正文。
7. 一般项目导入支持目录和多格式，并可默认开启智能分析。
8. 智能分析可指定分析智能体或分析智能体组，分析结果只提供建议，不直接替用户落盘。
9. focused tests 与高保真 probe 能证明主链稳定成立。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `12` 个 session。

顺序理由：

1. `BDI-01` 到 `BDI-03` 先冻结 core 合同与共享解析底座，不让 app 层提前乱接。
2. `BDI-04` 到 `BDI-06` 再补拆书主链最核心的原文归档、目录语义与后续导向分流。
3. `BDI-07` 到 `BDI-08` 再处理 `continuation / fanfic` 的差异化落盘和一般项目智能分析。
4. `BDI-09` 到 `BDI-10` 最后接 app / GUI / ViewModel，确保只消费稳定合同。
5. `BDI-11` 到 `BDI-12` 用 production 同源 probe 验收，再做文档和交接收口。

---

## 7. Session 设计

## BDI-01 共享来源导入合同冻结

- 本轮目标：
  把“导入什么、扫描出什么、标准化后交给上层什么”冻结成正式 core 合同。
- 层级归属：
  `Core / domain`
- 必读文件：
  - `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`
  - `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_source_document.dart`
  - `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_input.dart`
- 必须完成：
  1. 设计并落地共享来源导入合同，例如：
     - `SourceImportRequest`
     - `SourceImportSelection`
     - `SourceDocumentBundle`
     - `SourceDocumentIdentity`
  2. 扩充 `BookDeconstructionSourceDocument` 或引入替代合同，使其能表达：
     - 来源标题
     - 文本内容
     - 媒体类型
     - 源路径/相对路径提示
     - 顺序
     - 来源元数据
     - 分段范围
     - 是否来自目录扫描
  3. 明确共享来源合同是中性底座，不带拆书/一般导入专属判断。
- 本轮不要做：
  1. 不做 GUI。
  2. 不做 `epub` 真 reader。
  3. 不在 controller 里临时拼结构。
- 验收标准：
  1. 共享来源合同可同时服务拆书和一般项目导入。
  2. focused tests 覆盖新合同的编解码/规范化。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-01`。只做共享来源导入合同冻结，落在 core/domain；不要做 GUI、不要做 reader、不要开启下一任务。必须解耦合、单一职责、避免单文件过重，并补 focused contract tests。

## BDI-02 共享来源发现与扫描底座

- 本轮目标：
  建立文件/文件夹/递归扫描/支持格式识别的共享发现层。
- 层级归属：
  `Core / Adapters`
- 必读文件：
  - `packages/novel_agent_core/lib/src/use_cases/import_project_files_use_case.dart`
  - `apps/novel_agent_app/lib/shared/services/desktop_text_file_picker_service.dart`
  - `packages/novel_agent_adapters/lib/src/storage/local_project_file_mutation_adapter.dart`
- 必须完成：
  1. 抽出共享来源发现与扫描服务。
  2. 支持：
     - 单文件
     - 目录
     - 递归扫描
     - 支持格式过滤
  3. 先把当前明确支持的 `.txt / .md / .markdown` 收进正式 reader 注册。
  4. 为 `epub` 留出正式 reader 扩展口，而不是写死在 if/else。
- 本轮不要做：
  1. 不做拆书续写落盘。
  2. 不做智能分析。
  3. 不在 app 层直接写目录扫描逻辑。
- 验收标准：
  1. 输入文件或目录，都能产出稳定 `SourceDocumentBundle`。
  2. focused tests 覆盖目录扫描、排序、过滤、空目录与非法路径。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-02`。只做共享来源发现与扫描底座，落在 core/adapters；不要做 GUI、不要做拆书后续导向、不要开启下一任务。保持解耦和小文件职责，并补 focused tests。

## BDI-03 多格式 reader 与 `epub` 扩展位

- 本轮目标：
  让多格式支持真正落到 reader 层，而不是停在扩展名列表。
- 层级归属：
  `Adapters / persistence`
- 必读文件：
  - `apps/novel_agent_app/lib/shared/services/desktop_text_file_picker_service.dart`
  - `packages/novel_agent_adapters/lib/src/storage/local_project_file_mutation_adapter.dart`
- 必须完成：
  1. 抽出 reader registry / reader dispatcher。
  2. 正式实现文本与 Markdown reader。
  3. 为 `epub` 实现至少一个清晰可接入的 reader contract：
     - 可先做 placeholder / not yet supported outcome
     - 但必须是正式 reader，不是 UI 文案级支持
  4. 更新文件选择/目录扫描支持格式提示。
- 本轮不要做：
  1. 不把 `epub` 做成假支持。
  2. 不做拆书项目业务编排。
- 验收标准：
  1. 多格式 reader 层可以独立测试。
  2. 对 `epub` 的当前状态有真实、可审计的能力表达。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-03`。只做多格式 reader 与 `epub` 扩展位，保持 reader/discovery/business orchestration 分层；不要接 GUI 大流程，不要开启下一任务，并补 focused adapter tests。

## BDI-04 拆书原文必留统一

- 本轮目标：
  收口“工作台导入会留原文、专用拆书面板不一定留”的断层。
- 层级归属：
  `Workflow / runtime`
- 必读文件：
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_import_execution_service.dart`
- 必须完成：
  1. 抽出拆书来源归档动作。
  2. 让专用拆书面板与工作台自动拆书都走同一条来源归档合同。
  3. 原文归档必须早于预演确认，不再依赖“确认后也许会写”。
  4. 归档结果应能回写到 snapshot/view data。
- 本轮不要做：
  1. 不改续写/同人分流。
  2. 不把原文继续默认塞进 `chapters/`。
- 验收标准：
  1. 两个入口导入同一来源时，原文留存语义一致。
  2. focused integration tests 覆盖专用拆书面板与工作台导入两条路径。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-04`。只修拆书原文必留统一，不能顺手做 followup intent 或 GUI 漂亮化；不要开启下一任务。优先修协议断层，不堆隐式副作用，并补 focused integration tests。

## BDI-05 拆书目录语义重分层

- 本轮目标：
  停止把拆书原文和预演纪要默认写进 `chapters/`。
- 层级归属：
  `Core / Workflow / Adapters`
- 必读文件：
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_import_action_policy_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_import_execution_service.dart`
- 必须完成：
  1. 设计并落地拆书项目的来源层、分析层、正文层路径策略。
  2. 调整自动拆书预演纪要默认路径。
  3. 调整拆书来源归档默认路径。
  4. 让路径策略服务化，不把判断写死在 UI。
- 本轮不要做：
  1. 不直接做续写章节投影。
  2. 不做一般项目智能分析。
- 验收标准：
  1. 拆书项目默认不再把原文和预演纪要塞进 `chapters/`。
  2. focused tests 覆盖路径策略。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-05`。只做拆书目录语义重分层，路径策略必须下沉到服务/合同，不要把判断堆到 UI 或 controller，不要开启下一任务，并补 focused tests。

## BDI-06 拆书后续导向合同

- 本轮目标：
  正式建立 `continuation / fanfic` 后续导向合同，而不是继续靠隐式约定。
- 层级归属：
  `Core / Workflow`
- 必读文件：
  - `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`
  - `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
  - `packages/novel_agent_core/lib/src/deconstruction/`
- 必须完成：
  1. 引入正式合同，例如：
     - `DeconstructionFollowupIntent`
     - `DeconstructionFollowupPlan`
  2. 让拆书输入/预演/确认链能携带后续导向。
  3. 默认值和覆盖策略明确。
  4. 让后续步骤可依据此合同决定落盘与桥接行为。
- 本轮不要做：
  1. 不新增新的主项目类型。
  2. 不做 GUI 最终接线。
- 验收标准：
  1. 后续导向有正式合同和 focused tests。
  2. 不需要依赖字符串文案判断是否续写/同人。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-06`。只做拆书后续导向合同，留在 core/workflow；不要做 GUI，不要做章节投影实现，不要开启下一任务，并补 focused contract tests。

## BDI-07 `continuation` 正文接入与来源冻结

- 本轮目标：
  实现拆书续写时“原作章节进入正文体系，但仍保留来源身份与冻结语义”。
- 层级归属：
  `Workflow / Adapters`
- 必读文件：
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart`
  - `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_narrative_bridge_service.dart`
- 必须完成：
  1. 为 `continuation` 设计章节投影规则。
  2. 原作章节进入正文层时携带来源身份与冻结元数据。
  3. 区分“导入的原作正文”和“后续新创作正文”。
  4. 保证后续续写能把这些内容当连续体消费。
- 本轮不要做：
  1. 不把 `fanfic` 也投进正文层。
  2. 不重做整套拆书提取器。
- 验收标准：
  1. `continuation` 下原作章节能稳定进入正文体系。
  2. 元数据足以让后续运行时区分导入正文与新创作正文。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-07`。只做 `continuation` 正文接入与来源冻结，不碰 `fanfic` 主逻辑，不开启下一任务。必须分清来源正文与新创作正文职责，并补 focused workflow tests。

## BDI-08 `fanfic` 来源层与一般项目智能分析

- 本轮目标：
  一次把两个边界都收紧：
  - `fanfic` 不污染正文
  - 智能分析只属于已有项目导入，且能选分析智能体
- 层级归属：
  `Core / Workflow / App`
- 必读文件：
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_import_action_policy_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_import_execution_service.dart`
- 必须完成：
  1. `fanfic` 下原作保持在来源/参考层，不进入正文。
  2. 引入一般项目导入智能分析合同：
     - 建议分类
     - 建议用途
     - 置信度
     - `analyzerAgentId / analyzerAgentGroupId`
  3. 明确拆书导入绕过智能分析。
  4. 明确一般项目导入默认可开启智能分析。
- 本轮不要做：
  1. 不把智能分析塞进拆书链。
  2. 不直接上复杂 GUI。
- 验收标准：
  1. `fanfic` 与 `continuation` 路径语义清楚分开。
  2. 智能分析合同存在且不耦合主写作智能体。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-08`。只做 `fanfic` 来源层与一般项目智能分析合同；不要把智能分析接进拆书主链，不要开启下一任务，并补 focused tests。

## BDI-09 文件选择、目录导入与 ViewModel 接线

- 本轮目标：
  让 app 层真正消费新底座：文件/目录导入、多格式来源、一般项目智能分析入口。
- 层级归属：
  `App / GUI`
- 必读文件：
  - `apps/novel_agent_app/lib/shared/services/desktop_text_file_picker_service.dart`
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_import_execution_service.dart`
- 必须完成：
  1. 文件选择器支持目录选择或明确的目录入口。
  2. 拆书导入支持文件/目录。
  3. 一般项目导入支持文件/目录和智能分析开关。
  4. 一般项目导入可指定分析智能体/智能体组。
- 本轮不要做：
  1. 不把业务判断写死在 widget。
  2. 不顺手重做整个工作台布局。
- 验收标准：
  1. ViewModel 能完整表达：
     - 来源选择
     - 目录导入
     - 智能分析开关
     - 分析智能体选择
  2. widget 只消费 view data，不偷做业务推断。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-09`。只做文件选择、目录导入与 ViewModel 接线，不重做整套 UI，不开启下一任务。确保业务判断留在 service/controller 层，并补 focused app tests。

## BDI-10 拆书面板与工作台导入体验收口

- 本轮目标：
  把拆书导入与一般导入的用户面语义整理干净。
- 层级归属：
  `App / GUI`
- 必读文件：
  - `apps/novel_agent_app/lib/features/book_deconstruction/`
  - `apps/novel_agent_app/lib/features/workbench/`
- 必须完成：
  1. 拆书面板显式暴露后续导向选择：
     - `continuation`
     - `fanfic`
  2. 拆书面板不显示智能分析开关。
  3. 一般项目导入显示智能分析开关，默认勾选。
  4. 一般项目导入可显式选择分析智能体或智能体组。
  5. 导入提示文案与结果文案反映真实落盘语义。
- 本轮不要做：
  1. 不做全局 UI 重构。
  2. 不补没有合同支撑的新功能。
- 验收标准：
  1. 拆书和一般导入两种用户流语义不再混淆。
  2. 没有“拆书也要先智能判断是不是书”的奇怪体验。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-10`。只做拆书面板与工作台导入体验收口；不要新增底层合同，不要开启下一任务。保持 UI 只消费稳定语义，并补 focused GUI tests。

## BDI-11 高保真 probe 与回归

- 本轮目标：
  用 production 同源合同把这条主线测透，而不是再写一套平行判断。
- 层级归属：
  `Probe / regression`
- 必读文件：
  - `apps/novel_agent_app/tool/`
  - 相关 viewmodel probe / regression 脚本
- 必须完成：
  1. 新增或更新 probe，覆盖：
     - 拆书专用面板导入后原文必留
     - 工作台自动拆书后原文必留
     - `continuation` 原作章节进入正文连续体
     - `fanfic` 原作停留在来源层
     - 一般项目导入智能分析仅在已有项目导入出现
  2. 区分技术失败、配置失败、内容失败。
  3. probe 尽量消费 production service/contract。
- 本轮不要做：
  1. 不在 probe 里重新实现路径判断。
  2. 不用假数据掩盖真实目录策略。
- 验收标准：
  1. probe 能稳定跑通主链。
  2. 失败报告能指出失败层。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-11`。只做高保真 probe 与回归，尽量消费 production 同源合同；不要开启下一任务，不要在 probe 中重写业务判断，并补必要的 focused regressions。

## BDI-12 文档、交接与收口

- 本轮目标：
  把实现结果和剩余边界明确记录下来，避免后面回头又长歪。
- 层级归属：
  `Documentation / handoff`
- 必读文件：
  - `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`
  - 当前任务顺序文档
  - 实际改动涉及的 README / 说明文档
- 必须完成：
  1. 更新分析文档中的实现状态。
  2. 如有必要，补 README / 使用说明中的导入能力说明。
  3. 记录：
     - 当前支持的格式
     - 目录导入范围
     - `epub` 当前真实状态
     - 拆书与一般导入的语义边界
  4. 标记后续尚未做的深度提取运行时。
- 本轮不要做：
  1. 不新增功能。
  2. 不顺手做其他 unrelated refactor。
- 验收标准：
  1. 文档和实现状态一致。
  2. 后续接手者能看懂哪些已经完成、哪些只是扩展位。
- 直接可用提示词：
  根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 执行 `BDI-12`。只做文档、交接与收口，不新增功能，不开启下一任务。把已实现与未实现边界写清楚，避免后续误判。

---

## 8. 总启动提示词

```text
根据 `docs/book-deconstruction-ingestion-and-followup-session-order-2026-06-14.md` 依序执行本主线任务。

当前要求：

1. 每次只完成一个 session。
2. 如果上个 session 只做了一半，先收口上个 session，不开启下一轮。
3. 严格遵守文档里的层级归属、必读文件、必须完成、本轮不要做、验收标准。
4. 先 core / adapters / workflow，后 app / GUI，最后 probe / docs。
5. 不把智能分析接进拆书主链。
6. 不把拆书项目改造成知识库项目。
7. 不把路径、来源语义、后续导向判断堆进 widget、controller 或 probe。
8. 避免单文件过重，接近 400 行主动复核职责，接近 700 行必须拆。
9. 每轮都补 focused test / contract test / regression；probe 尽量消费 production 同源合同。
10. 当前 session 完成后停止，不要自动开启下一个 session。
```

---

## 9. 完成记录占位

- `BDI-01`：
- `BDI-02`：
- `BDI-03`：
- `BDI-04`：
- `BDI-05`：
- `BDI-06`：
- `BDI-07`：
- `BDI-08`：
- `BDI-09`：
- `BDI-10`：
- `BDI-11`：
- `BDI-12`：
