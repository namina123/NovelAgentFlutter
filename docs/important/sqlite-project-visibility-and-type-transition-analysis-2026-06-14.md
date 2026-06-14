# SQLite 项目可见性、知识库对齐与项目类型互转分析

日期：2026-06-14

关联文档：

- `agent.md`
- `docs/storage-dual-compatibility-design.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`

关联实现锚点：

- `packages/novel_agent_core/lib/src/project/project_type_catalog_service.dart`
- `packages/novel_agent_core/lib/src/project/project_type_definition.dart`
- `packages/novel_agent_core/lib/src/project/project_storage_strategy.dart`
- `packages/novel_agent_core/lib/src/tools/tool_exposure_policy_service.dart`
- `packages/novel_agent_core/lib/src/tools/builtin_tool_catalog.dart`
- `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`
- `packages/novel_agent_core/lib/src/project/project_prompt_contract.dart`
- `packages/novel_agent_core/lib/src/use_cases/create_project_workspace_use_case.dart`
- `packages/novel_agent_core/lib/src/use_cases/update_project_manifest_use_case.dart`
- `packages/novel_agent_adapters/lib/src/storage/sqlite_project_database_initializer.dart`
- `packages/novel_agent_adapters/lib/src/storage/sqlite_project_readable_projection_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_tool_path_policy.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_information_activation_bridge_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/project_launcher_view_data_service.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/renderers/document_resource_renderer_resolver.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart`

---

## 1. 这份文档解决什么

这一轮不是要直接实现，而是先把 `sqlite` 相关的几个混在一起的问题拆清：

1. `SQLite 项目` 到底应让用户看到什么，不该看到什么。
2. `knowledge_base` 项目类型，到底是不是应该和我们已经定义过的应用级参考资产库 / SQLite 基座正式对齐。
3. 哪些项目类型应允许双存储策略，哪些应被强约束为单一策略。
4. `普通小说` 与 `长篇长任务` 的互转，到底属于什么级别的能力，和存储迁移是什么关系。
5. 下一步如果要把这块做完善，真正该动哪里，不能动哪里。
6. 对照 `MuMu` 这类更偏结构化资产中心的产品，我们当前这条普通项目 `sqlite` 链到底成熟到什么程度。
7. `sqlite` 项目的工具暴露和工具执行面到底是否完备，是否还把 Markdown/file-tree first 的能力误暴露成主路径。

这份文档的目标，是把后续实现收束到一条清楚的主线上，而不是继续把：

- 项目类型
- 存储策略
- 全局参考资产库
- 项目内知识层
- 可见性
- 项目转换

重新搅成一个难以维护的大团。

---

## 2. 先给结论

### 2.1 四个概念必须彻底拆开

后续实现里必须正式区分：

1. `Project Type`
   - 这个项目是普通小说、长篇长任务、资料知识库、拆书承接中的哪一种。

2. `Storage Strategy`
   - 这个项目的主事实源是 `markdown_project_store` 还是 `sqlite_project_store`。

3. `ReferenceEvidenceSubstrate`
   - 应用级共享参考资产库，是跨项目复用和分发的长期基座。

4. `Project Information Capability Layer`
   - 项目运行期真正拿来消费的知识卡、研究记录、设计元素、引用边界等。

这四者有关联，但不是同一层东西。

### 2.2 `knowledge_base` 应当正式收束为 SQLite-first，且与参考资产库对齐

`knowledge_base` 不应继续作为一个“名字叫知识库，但内部仍可随便选 Markdown/SQLite 的普通项目壳”存在。

更合理的结论是：

1. `knowledge_base` 是一种以结构化资料治理为中心的项目类型。
2. 它的主事实源应是 `sqlite_project_store`。
3. Markdown 在这里的职责应退回到：
   - 用户可读投影
   - 导出
   - 审阅摘要
   - 分享附带说明
4. 它应天然对齐应用级 `ReferenceEvidenceSubstrate`，而不是平行长出一套新的“本地知识库宇宙”。

### 2.3 SQLite 项目必须可见，但不该把裸数据库表直接扔给用户

用户确实应该“看到 SQLite 里有什么”，否则 SQLite 项目会显得像黑箱。

但正确的可见方式不是：

1. 直接显示 `novel_agent.db`
2. 直接暴露所有表名
3. 直接让用户面对内部外键、运行状态表、审计表、缓存表

正确方式应是：

1. 以层级树或结构化面板的形式，展示“用户应理解的内容域”。
2. 这些视图来自受控投影，而不是来自裸表浏览。
3. 高级模式可以只读查看更深层信息，但仍不是默认把内部 schema 全摊开。

### 2.4 `普通小说 <-> 长篇长任务` 的互转应尽快引入，但它不是存储迁移

这一点非常关键。

下一阶段应优先做的是：

1. `novel <-> long_novel` 的项目类型互转。

但这条能力必须明确成：

```text
项目类型转换
!=
存储策略转换
```

也就是说，第一阶段只做：

1. `novel + markdown -> long_novel + markdown`
2. `long_novel + markdown -> novel + markdown`
3. `novel + sqlite -> long_novel + sqlite`
4. `long_novel + sqlite -> novel + sqlite`

而不在同一轮里掺入：

1. `markdown -> sqlite` 主存储迁移
2. `sqlite -> markdown` 主存储迁移

用户这轮提到的“`sqlite` 项目只能转成 `sqlite`，`md` 项目只能转成 `md`”是对的，这应该成为第一阶段硬约束。

### 2.5 `knowledge_base` 暂时不应和写作项目互转

至少在当前阶段，不建议开放：

1. `knowledge_base -> novel`
2. `knowledge_base -> long_novel`
3. `novel -> knowledge_base`
4. `long_novel -> knowledge_base`

理由不是它永远不可能，而是：

1. 这会把“项目壳转换”和“资产挂载/提取/导出”混成一个操作。
2. `knowledge_base` 的本质更接近资料治理工作台，不是写作壳的另一种皮肤。
3. 真正常见的用户需求，多半是：
   - 从知识库项目里提取资产并挂载到写作项目
   - 或从写作项目把某些资料提升到应用级资产库
   - 而不是把整个项目类型直接变种

更好的主线是“挂载 / 提升 / 导出 / 引用”，不是“硬转换项目类型”。

### 2.6 `SPT-01` 冻结的能力矩阵

结合现有实现与本轮审计，第一阶段冻结为下面这张矩阵：

| 项目类型 | 允许的主存储策略 | 备注 |
| --- | --- | --- |
| `novel` | `markdown_project_store`, `sqlite_project_store` | 保持双策略，后续再分别补齐主事实源与工具面。 |
| `long_novel` | `markdown_project_store`, `sqlite_project_store` | 保持双策略，但创建时仍可要求运行基准。 |
| `knowledge_base` | `sqlite_project_store` | 从产品语义上收束为 SQLite-only。 |
| `book_deconstruction` | `markdown_project_store`, `sqlite_project_store` | 第一阶段保持双策略，避免过早收紧承接型项目。 |
| `short_collection` | 无 | 当前仍为禁用态，不进入第一阶段可创建矩阵。 |

第一阶段允许的项目类型转换图冻结为：

```text
novel <-> long_novel
```

并明确满足以下边界：

1. `类型转换 != 存储迁移`
2. `sqlite` 项目在类型转换前后仍保持 `sqlite`
3. `markdown` 项目在类型转换前后仍保持 `markdown`
4. `knowledge_base` 本阶段不参与写作项目互转

其中，`knowledge_base` 的对外语义已冻结为：

```text
knowledge_base -> 参考资产治理型项目 -> sqlite_project_store only
```

---

## 3. 现状里真正不合理的地方

### 3.1 `knowledge_base` 当前仍是双存储可选

当前 `ProjectTypeDefinition` 默认对所有类型都开放：

- `markdown_project_store`
- `sqlite_project_store`

这对普通小说和长篇长任务还说得过去，但对 `knowledge_base` 来说已经不够准确。

因为一旦允许 `knowledge_base + markdown` 作为正式主路线，就会出现几个问题：

1. 产品心智混乱
   - 用户以为这是“知识库项目”，但主事实源却可能是散落 Markdown。

2. 数据能力打折
   - 检索、去重、挂载、提取覆盖、版本化、证据回链都天然偏向结构化存储。

3. 和应用级参考资产基座脱节
   - 前面已经决定应用级参考资产库以 SQLite 基座 + bundle 为主。
   - 如果知识库项目反而默认允许 Markdown 主存储，就会在产品层制造第二套语义。

### 3.2 SQLite 项目的可读性仍停在“有投影目录”，没到“有内容树”

当前 `SqliteProjectReadableProjectionService` 只保证了：

1. 建立可读目录
2. 写一个 `premise/project_brief.md`

这当然比什么都没有强，但它还远不足以支撑“SQLite 项目是可理解、可操作、可检查的”。

当前缺的不是再多写几个 `.md` 文件，而是：

1. 正式的 SQLite 投影树合同
2. 正式的结构化资源分组
3. 用户可见项与内部项的暴露策略
4. 从投影项回到真相源 identity 的映射

### 3.3 UI 当前把 `.db/.sqlite` 当成 preview-like 资源，这不对

`DocumentResourceRendererResolver` 当前把：

- `db`
- `sqlite`

视为 preview-like 资源。

这只能算临时兜底，不能算正式产品行为。

对 SQLite 项目来说，真正需要的不是“能预览一个数据库文件”，而是：

1. `结构化浏览`
2. `语义树`
3. `受控摘要`
4. `关系回跳`

### 3.4 项目类型转换几乎还没有正式建模

当前仓库里有：

1. 创建项目
2. 更新 manifest
3. 运行基准选择

但还缺：

1. 项目类型转换图
2. 转换前置条件
3. 转换策略
4. 转换副作用治理
5. 转换后的开局/运行时/资料层收口

如果没有这些合同，后面一旦开始做“普通 -> 长任务”的切换，很容易变成：

1. 只改 manifest
2. 留下一堆不兼容运行状态
3. UI 和实际能力不一致
4. 打开项目后到处是半新半旧的状态残留

### 3.5 普通项目的 SQLite 目前更像“建库壳”，还不是成熟主存储

这轮顺着普通项目真实链路往下核，结论需要单独说清：

```text
普通项目目前“可以创建 sqlite 项目”，
但还不能诚实地说“普通项目已经真正运行在 sqlite 主存储上”。
```

证据很直接：

1. `SqliteProjectContentRepository`
   - 当前只负责：
     - 建目录骨架
     - 初始化数据库
   - 并不负责后续正文、章纲、场景、项目资料的持续读写。

2. `SqliteProjectBodyTextStore`
   - 当前只有建表逻辑：
     - `body_text_document`
     - `body_text_segment`
   - 这说明我们已经定义了“正文应如何结构化存入 SQLite”的骨架，
   - 但还没有把普通项目真实写作链接上去。

3. `LocalProjectWorkspacePort`
   - `listEntries / readTextFile / writeTextFile`
   - 当前都是纯文件系统口径，且不感知 `storageStrategy`。
   - 这意味着普通项目在运行时读取、写入、列目录，仍然首先面对文件树。

4. `ProjectWorkspaceToolHostAdapter`
   - 直接委托 `workspacePort` 进行读写。
   - `WriteProjectTextFileUseCase` 也是直接走 `workspacePort.writeTextFile(...)`。
   - `ProjectFileWriteToolExecutor` 也是直接写 Markdown/文本文件到项目目录。

5. 普通写作与章节交付主链
   - 当前继续围绕：
     - `chapters/*.md`
     - `scenes/*.md`
     - `assets/**/*.md|json`
     - `workspacePort.readTextFile/listEntries`
   - 并没有看到普通项目正式把交付正文写入 `body_text_document / body_text_segment` 的主链。

6. 验证与探针侧
   - 目前几乎没有“普通小说 + sqlite_project_store”的真实 probe 或 focused validation。
   - 现有普通项目真实 probe 默认仍走 Markdown 路线。
   - 这意味着我们连“它真实可用”都还没有被系统性证明。

所以，对普通项目 SQLite 当前最准确的描述应是：

1. 已有：
   - 项目类型层面的 SQLite 选项
   - 最小数据库初始化
   - 可读目录投影壳
   - 正文结构化 schema 草图

2. 还没有：
   - 正文主链的 SQLite 写入
   - 章节/场景读取的 SQLite-first 消费
   - 策略感知的项目读写桥
   - 普通项目 SQLite 的真实验证闭环

换句话说：

```text
当前普通项目的 sqlite，更接近“文件优先项目 + 一个已建好的 sqlite 骨架”，
而不是“真正的 sqlite-first 普通写作项目”。
```

### 3.6 对照 MuMu 后更该诚实承认的缺口

如果对照 `docs/mumuainovel-absorption-analysis.md` 已经沉淀过的判断，这一轮最该说清楚的不是“我们也有 SQLite 了”，而是：

1. `MuMu` 更接近“结构化写作资产中心”
   - 它真正强的地方不是数据库这个壳，而是把章节、伏笔、关系、分析结果等对象做成稳定资产。

2. 我们当前普通项目的 `sqlite` 还没走到这一步
   - 现在更像“文件优先项目外面包了一个数据库初始化层”。
   - 这意味着 UI 即便先把 SQLite 项目做得更整齐，也仍然是在给半成品主链做包装。

3. 所以下一阶段最该吸收的，不是 MuMu 的页面形态，而是它背后的资产中心思路
   - 先把普通项目正文、章节级正文段，以及后续可扩的结构化对象，真正落到 SQLite 主事实源。
   - 再通过投影把这些对象语义化地暴露给用户。
   - 最后才谈“SQLite 项目更好看、更好浏览”。

这会直接影响任务顺序：

1. 先补普通项目 SQLite 主事实源。
2. 再补投影树与可见性。
3. 最后再做工作台层的可见化和项目设置收口。

### 3.7 `sqlite` 项目的工具面现在仍不完整，而且和存储语义没有真正对齐

这一轮继续往“工具暴露链 -> tool dispatcher -> prompt contract”串下来后，结论还需要再加重一句：

```text
当前 sqlite 项目的问题不只是“正文还没真正写进 SQLite”，
还包括“工具面仍基本按文件树项目来暴露和讲解”。
```

证据分几层：

1. `ToolExposurePolicyService`
   - 当前主要按：
     - 平台
     - 是否子智能体
     - `start_long_task_run` 是否仅限 `long_novel`
   - 做过滤。
   - 但没有看到“`markdown_project_store` 和 `sqlite_project_store` 暴露不同工具面”的正式判断。

2. `ContinuousTaskToolExposureRuntimeResolverService`
   - 默认候选工具仍以：
     - `read_project_file`
     - `list_project_files`
     - `write_project_file`
     - `edit_project_file`
     - `submit_chapter_delivery`
   - 为主。
   - 也就是说，它按任务族和能力族裁剪了一部分能力，但没有把“当前项目是不是 sqlite-first”编进默认工具心智。

3. `ProjectToolDispatcher`
   - 当前是一条“项目无差别”的统一分发器。
   - `write_project_file / read_project_file / create_project_entry / move_project_file / delete_project_file`
     这些低层工具都还是真实可执行分支。
   - 这里没有看到围绕 `project.storageStrategy` 的专门分岔。

4. `ProjectToolPathPolicy` 与 `ProjectFileReadToolExecutor`
   - 路径安全边界、可见根目录、列目录、读文件，仍然以工作区英文目录树为主语义。
   - 这对 Markdown 项目合理，
   - 但对 SQLite 项目只能算“兼容读取面”，还不是“主事实源读取面”。

5. `ProjectPromptContract`
   - 当前明确教模型：
     - 章节进 `chapters/`
     - 场景进 `scenes/`
     - 设定进 `assets/`
   - 并把 `list_project_files / read_project_file / write_project_file` 作为常规工具心智的一部分。
   - 这说明连 prompt 合同目前也是 file-tree first。

6. `referenceMountCommit` 能力族
   - `ToolCapabilityFamilyCatalogService` 已经有：
     - `referenceMountCommit`
     - 文案写的是“面向 sqlite-first 挂载、投影确认与项目事实源提交的宿主侧能力族”
   - 但它当前没有任何真正的 `toolIds`。
   - 这说明：
     - 设计意图已经存在
     - 真正的工具合同还没落地

但也不能把一切都说成没做：

1. 信息层其实已经比正文层更接近 SQLite-first
   - `ProjectInformationActivationBridgeService`
   - `SqliteKnowledgeCardRepository`
   - `SqliteDesignElementRepository`
   - `SqliteProjectInformationRecordStore`
   - 这些都说明知识卡、设计元素、研究笔记、引用作品这条链，已经在一定程度上把 SQLite 当作事实源。

2. 所以当前更准确的判断不是“整个 sqlite 项目都不能用”，而是：
   - `information / reference` 侧已经有部分 SQLite-first 基座
   - `ordinary writing tool surface` 仍主要停留在 file-tree first
   - 两边成熟度不一致

这会导向一个更精确的架构要求：

1. 语义级工具应尽量跨存储策略稳定
   - 例如：
     - `submit_chapter_delivery`
     - `submit_narrative_state_claims`
     - information tools
     - review tools

2. 低层文件工具不能再被当成 sqlite 项目的主能力面
   - `read_project_file / list_project_files`
     在 sqlite 项目里更适合退到：
     - 投影读取
     - 兼容读取
     - 调试/诊断辅助
   - `write_project_file / edit_project_file / create_project_entry / move_project_file / delete_project_file`
     则需要按策略区分：
     - 哪些仍可作为兼容层使用
     - 哪些对 sqlite 项目应降级、拒绝，或改为宿主桥接

3. 需要正式的“storage-aware tool contract”
   - 不只是“工具开关”
   - 而是要把：
     - 项目类型
     - 存储策略
     - 任务族
     - agent 角色
     - 宿主/监督者权限
   - 一起编进工具暴露与执行合同里

换句话说：

```text
普通项目 sqlite 当前缺两层：
一层是正文主事实源；
另一层是与之匹配的工具能力面。
```

---

## 4. 正式架构判断：SQLite 在本项目里到底是什么地位

### 4.1 不同层有不同的 SQLite 角色

SQLite 不是一个单一语义。

当前项目里，至少要区分两种角色：

1. `项目级 SQLite`
   - 每个项目一个 `novel_agent.db`
   - 负责该项目的主事实源、索引、结构化内容、运行辅助记录

2. `应用级参考资产 SQLite 基座`
   - 负责全局参考资产库的 catalog、entry、version、bundle 管理与挂载

这两者都可以是 SQLite，但不代表它们是同一个库、同一层职责、同一套 UI。

### 4.2 `knowledge_base` 项目应是“参考资产库工作台”，不是“又一个本地知识文件夹项目”

更准确的产品判断应是：

1. `knowledge_base` 是一种项目壳
2. 它的工作目标是：
   - 导入资料
   - 发起提取
   - 审核提取结果
   - 维护资产边界
   - 组织包、版本、来源、标签
   - 验证可消费性
3. 它的主事实源应直接围绕 SQLite 组织
4. 它的最终成果应能够：
   - 留在本地作为私有资产
   - 或提升/发布到应用级参考资产库

也就是说：

```text
knowledge_base 不是“项目知识卡的放大版”
而是“参考资产治理工作台”
```

### 4.3 普通写作项目与长任务写作项目继续允许双策略

对 `novel` 和 `long_novel`，当前仍应保持弹性：

1. 可以是 `markdown_project_store`
2. 也可以是 `sqlite_project_store`

原因是：

1. 这两类项目的主矛盾仍是写作体验与工作流，而不是资料治理本身。
2. 有些用户更喜欢文件树直写。
3. 有些用户未来会更需要结构化正文、连续性、索引与恢复能力。

所以这两类项目继续双策略是合理的。

但这里必须补上一条更诚实的现实判断：

1. “继续允许双策略”不等于“SQLite 路线已经对普通项目真正可用”。
2. 当前 `novel + sqlite` 和 `long_novel + sqlite` 更像：
   - 能创建
   - 能显示存储标签
   - 能保留最小数据库
   - 但正文与大量项目内容仍主要经由文件树流动
3. 因此下一阶段不应只做“限制哪些项目类型可选 SQLite”，还必须把：
   - 普通项目的 SQLite 主事实源
   - 正文写穿
   - 读取桥
   - 普通项目 SQLite 验证
   补成真实能力。

### 4.4 `book_deconstruction` 现阶段不必强制 SQLite-only

`book_deconstruction` 虽然和参考资产、结构化信息高度相关，但它同时承担：

1. 导入外部作品
2. 抽取结构和资料
3. 承接续写

它比 `knowledge_base` 更贴近“写作衔接型项目”，而不是纯资料治理台。

因此当前更稳的结论是：

1. `book_deconstruction` 暂时继续允许双策略
2. 但若选择 SQLite，应拥有更丰富的结构化视图
3. 后续如果事实证明 Markdown 主路线严重拖累续写与结构承接，再评估是否进一步收紧

---

## 5. SQLite 项目应如何对用户可见

### 5.1 正式目标：可见，但不是裸露

SQLite 项目必须解决两个相反但都真实的需求：

1. 不能黑箱
   - 用户必须知道数据里有什么
   - 必须能查到关键内容
   - 必须有回看和验证能力

2. 不能裸露
   - 不该把内部 schema、cache、runtime 细节全暴露给用户
   - 不该让用户去理解系统内部实现表
   - 不该把内部路径、迁移状态、临时记录混进主要工作台

所以正式原则应是：

```text
暴露语义，不暴露噪声；
暴露内容域，不暴露内部表。
```

但对于普通项目，还要再加一句：

```text
不要在“SQLite 还没真正接管主事实源”时，
先把可见性做得比真实能力更像已经完成。
```

否则就会出现一种很糟糕的状态：

1. UI 看起来很像结构化 SQLite 项目
2. 但底层正文与项目资料仍主要写在文件树
3. SQLite 只承接少量 metadata 或未来预留位

这会让用户和后续实现会话都误判成熟度。

### 5.2 推荐的可见性分层

建议把 SQLite 项目的用户可见层分成三层：

#### 第一层：主资源树

这是用户平时使用的默认树。

应看到的是类似这些语义节点：

1. `项目概览`
2. `正文与章节`
3. `大纲与设定`
4. `项目资料`
5. `参考资产挂载`
6. `导入源`
7. `提取与审核`
8. `导出与投影`

这里展示的是“可读入口”和“结构化入口”，不是数据库文件。

#### 第二层：结构化浏览面板

当用户点进某类节点时，再看到受控的结构化列表，例如：

1. 章节列表
2. 角色/组织/地点
3. 知识卡/研究记录/设计元素
4. 参考资产 package/version/entry
5. 导入源文档与来源身份
6. 提取 run、review、finalize 状态

这是 SQLite 项目真正应该提供的主能力层。

#### 第三层：高级只读诊断层

仅在高级模式或开发模式下开放。

允许用户看到：

1. 数据库所在位置
2. schema 版本
3. 某些内部 identity
4. 某条记录的真相源引用

但仍不建议默认开放：

1. 原始 SQL 表浏览
2. 任意改表
3. 裸表编辑

### 5.3 资源树展示的不是物理目录，而是投影目录

这里必须正式承认一件事：

对于 SQLite 项目，主资源树已经不应再等同于“文件系统目录树”。

它应该是：

```text
SQLite 主事实源
    -> 受控投影
    -> 语义资源树
```

这意味着后续很可能需要引入类似：

1. `SqliteProjectProjectionCatalogService`
2. `StructuredWorkspaceTreeBuilder`
3. `SqliteVisibilityPolicy`

这样的合同对象，而不是继续靠散落的 if 分支判断某个路径要不要显示。

### 5.4 “让用户知道 SQLite 里有什么”最合适的方式

比起暴露 `.db`，更好的方式是让每个投影条目都带：

1. 标题
2. 类型
3. 摘要
4. 来源身份
5. 真相源标识
6. 是否可编辑
7. 是否只读投影
8. 是否来自全局挂载

这样用户会知道：

1. 这个东西存在
2. 这个东西是什么
3. 这个东西来自哪里
4. 我能不能改
5. 改了会影响项目局部还是全局资产

这比“看见一个数据库文件”有用得多。

---

## 6. `knowledge_base` 与应用级参考资产库的正式对齐方式

### 6.1 不能再让 `knowledge_base` 成为悬空概念

当前最大风险不是功能缺失，而是语义悬空：

1. 名字叫知识库项目
2. 但用户很难判断它和项目资料、项目知识卡、全局参考资产库是什么关系

下一步必须钉死：

```text
knowledge_base 是参考资产治理型项目；
应用级 ReferenceEvidenceSubstrate 是共享资产事实源；
项目知识卡是写作项目内的工作知识层。
```

三者不是同义词。

### 6.2 推荐的对齐关系

推荐采用下面这条关系：

1. `ReferenceEvidenceSubstrate`
   - 应用级共享资产事实源

2. `knowledge_base`
   - 操作、提取、审核、整理、导入、验证这些资产的项目工作台

3. `novel / long_novel / book_deconstruction`
   - 消费这些资产、局部提取成项目知识层、必要时再反向提升资产的写作型项目

### 6.3 `knowledge_base` 项目的主成果不应只是 `.md`

它可以输出 `.md`，但 `.md` 不应是主事实源。

主成果应优先是：

1. 结构化 package/version/entry
2. 来源与证据绑定
3. 提取审核记录
4. 可挂载资产
5. bundle 导出单元

Markdown 应更多作为：

1. 人类复核摘要
2. 分发附带说明
3. 阅读投影
4. 审核报告

### 6.4 不建议把应用级资产库直接等同于某一个项目目录

即使 `knowledge_base` 和应用级资产库强相关，也不应把它们做成“同一个东西换个入口”。

更稳的做法是：

1. 应用级资产库继续作为共享底座存在
2. `knowledge_base` 项目通过挂载、提取 run、staging、promotion 与其交互
3. 项目里可以有：
   - 私有草稿资产
   - 待审核资产
   - 本项目只用但未发布资产
4. 真正共享时，再 promotion 到应用级资产库

这能避免：

1. 任一项目随手改动污染全局
2. 用户搞不清自己改的是项目私有还是全局共享

---

## 7. 项目类型互转应如何正式设计

### 7.1 第一阶段只做“写作壳互转”

下一步最合适的切入点，就是你提到的：

1. `novel <-> long_novel`

但它必须被设计成一个正式能力：

1. 有可用性图
2. 有前置条件
3. 有副作用处理
4. 有失败回滚
5. 有未来扩展口

### 7.2 正式引入“项目类型转换策略”

建议新增一层中性合同：

1. `ProjectTypeTransitionPolicy`
2. `ProjectTypeTransitionResolverService`
3. `ProjectTypeTransitionPlan`
4. `ExecuteProjectTypeTransitionUseCase`

这层的职责是：

1. 决定是否允许从 A 转到 B
2. 计算需要补齐和清退的状态
3. 决定是否需要用户确认
4. 执行 manifest 与运行时辅助状态更新

不要把这套逻辑塞进：

1. `UpdateProjectManifestUseCase`
2. 某个 GUI controller
3. 某个长任务 service

### 7.3 第一阶段允许的转换图

第一阶段推荐只支持：

1. `novel -> long_novel`
2. `long_novel -> novel`

同时要求：

1. 保持原存储策略不变
2. 保持原项目根目录不变
3. 保持用户正文与资料文件不重写
4. 只做必要的类型、运行基准、开局状态与控制面切换

### 7.4 转换前置条件

至少要检查：

1. 是否存在运行中的长任务
2. 是否存在待恢复的 supervisor / watchdog run
3. 是否存在未完成的关键 review / repair
4. 转入 `long_novel` 时是否已具备可选运行基准

推荐策略：

1. `novel -> long_novel`
   - 允许
   - 需要选择或确认 runtime baseline
   - 需要初始化长任务控制面最小状态

2. `long_novel -> novel`
   - 允许
   - 若有活跃长任务，必须先暂停/结束/归档
   - 需保留历史运行记录，但退出主工作流入口

### 7.5 转换后的副作用应是什么

转换不是只改一行 manifest。

至少应处理：

1. `project_type`
2. `runtimeBaselineId`
3. 开局阶段引导 profile
4. 默认工作台入口
5. 长任务控制面可见性
6. 连续任务相关的最小状态初始化或归档

但不应主动改写：

1. 章节正文
2. 用户设定文件
3. 项目知识卡内容
4. 用户手动创建的 agent/group 配置

除非某些绑定已经和新项目类型明确不兼容，此时也应：

1. 标记不兼容
2. 提醒用户
3. 提供受控修复

而不是静默重写。

### 7.6 存储迁移必须是另一条操作链

这点一定要写死：

```text
项目类型转换 != 主存储迁移
```

真正的：

1. `markdown -> sqlite`
2. `sqlite -> markdown`

应被建模为另一种能力，例如：

1. `ProjectStorageMigrationPlan`
2. `ExecuteProjectStorageMigrationUseCase`

否则后续实现很容易失控。

同时，这轮新增一个很重要的补充：

1. 在普通项目 SQLite 还没有真正接上主事实源之前，
2. 我们甚至还不应该急着把 `markdown -> sqlite` 存储迁移做成用户可点功能，
3. 因为那样迁过去的很可能只是：
   - 建好一个数据库
   - 但核心写作链仍继续写文件

这会制造“形式上迁移，实质上未迁移”的假完成状态。

---

## 8. 这轮用户想法里对的部分，以及需要修正的部分

### 8.1 对的部分

这轮你的几个核心直觉，我认为大方向是对的：

1. `knowledge_base` 很像只能选 SQLite 的项目类型。
2. SQLite 数据不能永远黑箱，用户应当有某种层级树式的理解入口。
3. 一般写作和一般长任务写作应该支持互转。
4. 第一阶段互转不应把 `md/sqlite` 混着改。

这些都应进入正式设计。

### 8.2 需要修正的部分

需要修正的不是方向，而是边界：

#### 修正一：用户不是在“看数据库”，而是在“看受控语义投影”

产品上应避免把这件事表达成“查看 SQLite 里的内容”，否则很容易把后续 UI 设计带偏成数据库浏览器。

更准确的表达应是：

```text
查看结构化项目内容与真相源投影
```

#### 修正二：`knowledge_base` 不应被等同于“应用级资产库本体”

它应是工作台，而不是全局底座本身。

#### 修正三：互转优先解决“工作流壳切换”，不是“所有项目类型互转”

当前最值得做的是 `novel <-> long_novel`。

不是一开始就让：

1. `book_deconstruction`
2. `knowledge_base`
3. 未来其他类型

全部进入一个大而全的转换系统。

#### 修正四：普通项目 SQLite 当前最该优先补的是“真实主存储”，不是先补更多可见性外观

这点是这轮审计后新增的关键修正。

如果只看产品直觉，很容易觉得 SQLite 这块现在最缺的是：

1. 更好的树
2. 更好的浏览
3. 更好的文案

但沿真实链路核下来，普通项目更根本的缺口其实是：

1. 正文没有真正写入 SQLite 主表
2. 常规读取没有真正从 SQLite-first 语义出发
3. 普通项目没有真实 SQLite 验证闭环

所以顺序上应当是：

1. 先补普通项目 SQLite 主事实源
2. 再补 SQLite 项目语义可见性
3. 最后再补更多产品层 polish

而不是反过来。

---

## 9. 下一步实现时真正该动哪里

### 9.1 Core

优先应动：

1. `project_type_definition`
   - 支持单类型显式声明可用存储策略

2. `project_type_catalog_service`
   - 把 `knowledge_base` 收束为 `sqlite` only

3. 新增 `project transition` 合同
   - `ProjectTypeTransitionPolicy`
   - `ProjectTypeTransitionPlan`
   - `ExecuteProjectTypeTransitionUseCase`

4. 新增 SQLite 可见性 / 投影合同
   - 不在 core 里写具体 UI
   - 但要有稳定的投影条目模型和分组语义

5. 新增普通项目 SQLite 主事实源合同
   - 例如：
     - `ProjectStructuredContentWritePolicy`
     - `ProjectBodyTextRepository`
     - `ProjectStorageAwareWorkspacePolicy`
   - 重点不是命名，而是正式回答：
     - 普通项目正文何时写 SQLite
     - 哪些路径是投影
     - 哪些读取可以先走结构化结果
     - 哪些仍保留文件兼容层

### 9.2 Adapters

优先应动：

1. SQLite 项目投影目录构建
2. 结构化投影项读取
3. 参考资产 package/version/entry 的投影适配
4. 项目类型转换时的最小 runtime 状态初始化/归档支持

还应补上：

5. 普通项目 SQLite 正文仓储实现
6. 章节交付 / 文本写入的 SQLite 写穿桥
7. 普通项目 SQLite 的读桥与最小索引查询
8. “文件兼容层 vs SQLite 真相源”的适配器边界

### 9.3 App / GUI

优先应动：

1. 项目创建页
   - 根据项目类型限制存储策略选项

2. SQLite 项目工作台
   - 不再把 `.db` 当资源主入口
   - 增加语义树 / 结构视图

3. 项目设置
   - 增加“项目类型转换”入口
   - 当前只开放 `novel <-> long_novel`

4. 高级信息入口
   - 只读显示 SQLite 真相源身份、挂载来源、包版本等

并且还需要：

5. 普通项目 SQLite 的真实验证入口
   - 至少要有 focused test 或高保真 harness
   - 证明普通小说项目在 SQLite 下：
     - 能创建
     - 能写正文
     - 能回读正文
     - 能在工作台中看到正确投影
   - 否则“SQLite 普通项目可用”只是推测

---

## 10. 不该做的事

下一步实现时，下面这些做法都应明确避免：

1. 为了让用户“看到 SQLite 内容”，直接做一个数据库表浏览器塞进主工作台。
2. 为了让 `knowledge_base` 对齐全局资产库，直接把某个项目目录当作全局资产库目录本体。
3. 在 `UpdateProjectManifestUseCase` 里顺手把项目类型转换、运行基准补齐、长任务归档全部塞进去。
4. 把 `novel <-> long_novel` 转换和 `markdown <-> sqlite` 迁移做成同一个按钮。
5. 让 GUI controller 自己推断复杂转换副作用。
6. 继续用“多写几个 `.md` 摘要文件”来假装 SQLite 项目已经可见。
7. 在普通项目正文仍未真正进入 SQLite 主链之前，就把 SQLite 项目对外包装成成熟结构化主存储。

---

## 11. 最终收口

这轮之后，关于 SQLite 这块，最稳的正式结论应该是：

1. `knowledge_base` 应收束为 `sqlite_project_store` only。
2. `knowledge_base` 的产品定位是“参考资产治理工作台”，并与应用级 `ReferenceEvidenceSubstrate` 正式对齐。
3. SQLite 项目必须有用户可理解的语义树和结构化浏览，但不应暴露裸数据库表作为主入口。
4. `novel <-> long_novel` 的互转应尽快引入，但它是“项目类型转换”，不是“存储迁移”。
5. 第一阶段项目互转必须保持 `md` 还是 `md`、`sqlite` 还是 `sqlite`。
6. `knowledge_base` 与写作项目之间，当前优先做的是挂载、提取、提升、导出，而不是整项目互转。
7. 普通项目的 SQLite 目前还不是成熟主存储；下一阶段必须先补“真实主事实源 + 正文写穿 + 读取桥 + 真实验证”，再继续放大可见性与产品包装。
8. `sqlite` 项目的工具面目前也还不成熟；下一阶段必须同步补“storage-aware tool exposure + dispatcher + prompt contract”，否则智能体仍会被 file-tree first 心智误导。

如果下一步按这个方向实现，SQLite 这块会开始像一个正式产品能力，而不再像“有数据库，但用户、项目类型和工作流都还没跟上”的半成品。
