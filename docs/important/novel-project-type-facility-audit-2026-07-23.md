# 小说项目类型与设施审计记录

> 日期：2026-07-23
>
> 范围：`novel`、`long_novel`、`knowledge_base`、`book_deconstruction`、`short_collection` 的创建、打开、类型转换、工作区入口、导入、SQLite/Markdown 持久化、工具写入与 CLI 行为。

## 统一合同

项目类型决定可用设施，存储策略、运行基准和能力 trait 决定持久化/运行合同，三者不能被普通元数据编辑绕过：

1. `novel`、`long_novel`、`book_deconstruction` 支持 Markdown 或 SQLite；SQLite 项目的结构化正文、资料和叙事资产以 SQLite 为主，Markdown 仅为可读投影。
2. `knowledge_base` 为 SQLite-only，资料导入必须保持为知识类文档，不能退化为章节。
3. 项目类型只能经专用转换流程变更；运行基准只能由长篇项目的专用配置流程变更。
4. `book_deconstruction` 是持久化能力 trait。项目转换为写作类型后仍保留拆书入口和已沉淀的分析资料。
5. `short_collection` 只保留旧项目兼容，不再创建或转换进入。

## 设施矩阵

| 类型 | 存储与创建 | 工作流设施 | 审计结论 |
| --- | --- | --- | --- |
| `novel` | Markdown / SQLite；可新建 | 开局引导、工作台、章节/大纲/资产、通用导入和 CLI 项目操作 | 正常。SQLite 的手工保存、工具写入和文本导入已统一为主库先行。 |
| `long_novel` | Markdown / SQLite；创建必须选择运行基准 | 普通创作设施外，增加运行画像、长任务、检查点和恢复入口 | 正常。为旧项目补上“配置运行基准”入口，活跃长任务时禁止修改。 |
| `knowledge_base` | SQLite-only；创建时强制归一化 | 结构化资料/RAG 分支、资料资产页和检索入口 | 正常。Manifest 读写均强制 SQLite；默认导入文本写为 `knowledge`，不再误标为 `chapter`。 |
| `book_deconstruction` | Markdown / SQLite；可新建 | 原文导入、分章、预演、分析、选择性物化、确认进入创作、恢复和复合项目入口 | 正常。原生项目和转换后的复合写作项目均可使用拆书能力。 |
| `short_collection` | 历史兼容 | 可打开已有项目并走通用兼容入口 | 新建与类型转换已禁用；不再对外承诺一条未完整维护的新项目流程。 |

## 已修复问题

| 编号 | 问题 | 修复 |
| --- | --- | --- |
| PT-01 | `short_collection` 仍可能被当作可创建/可转换类型。 | 类型目录标记为禁用；Core 创建和转换策略同时拒绝，GUI 只展示启用类型。 |
| PT-02 | `knowledge_base + markdown` 可经旧 manifest 或手工构造重新写出。 | Manifest 的创建、解析和编码统一归一化为 SQLite；旧项目打开后按实际 manifest 合同解析。 |
| PT-03 | 普通项目资料编辑可携带任意 `projectType`，绕开转换约束。 | App 与 CLI 均拒绝该字段；只有专用转换用例可改类型。 |
| PT-04 | 拆书能力只依赖瞬时 type/mode，转换后的项目会失去入口。 | `additionalTraitIds` 贯通 descriptor、manifest、能力判定和导航；移除了 UI 未实际传递的临时 mode 能力来源。 |
| PT-05 | 缺少运行基准的旧 `long_novel` 无法修复。 | 增加 `ConfigureLongNovelRuntimeBaselineUseCase` 与工作台命令入口；先写运行画像再提交 manifest，失败时补偿恢复。 |
| PT-06 | SQLite 项目的手工保存、新建、拆书物化、源文归档、CLI 创建/导入、工具文件编辑等路径会先写或只写 Markdown。 | 在各入口接入 structured-content bridge，并将顺序收敛为 SQLite 主事实源先行、Markdown 投影随后；保留既有文档的状态和元数据。 |
| PT-07 | App/CLI 默认导入路径可落在项目根；知识库的 `imports/` 文本会被误判为章节。 | 默认目录改为 `ProjectStorageStrategyPathPolicyService` 的策略结果；知识库默认文本导入显式使用 `knowledge`。可解析的 txt/Markdown/EPUB 同步主库，二进制附件只保留文件附件。 |
| PT-08 | SQLite 投影路径 `imports/analysis/...` 会反推成 `chapter`，覆盖大纲、知识或资产的 `document_kind`。 | 补齐逆向路径策略，并覆盖组织、伏笔、时间线、关系四类叙事资产及其 SQLite 投影目录。 |
| PT-09 | 包导入、角色/组织/时间线/关系等资产仓储和低层文件工具存在结构化主库遗漏，删除/移动易遗留孤儿记录。 | 统一由 bridge/工具宿主协调写入、删除、移动和恢复；移动失败时按可恢复快照补偿文件与 SQLite 记录。 |
| PT-10 | Manifest 编码只在解析时归一化，手工构造无效对象仍可写出。 | `ProjectManifestCodecService.toJson` 也执行类型与存储策略归一化。 |
| PT-11 | 通用“编辑项目信息”用例仍可直接改写存储策略、长篇运行基准或附加能力 trait，绕过迁移、活跃任务和能力转换约束。 | 默认拒绝这三类合同字段的变化；仅项目类型转换和长篇运行基准专用流程显式授权。 |
| PT-12 | SQLite 知识库在工作台手工新建 `imports/` 文件时会被标为 `chapter`，与 GUI/CLI 导入的 `knowledge` 分类不一致。 | 工作台存储服务按知识库导入根统一写为 `knowledge`，保留分析、原文和派生子目录的原有分类。 |
| PT-13 | App 导入将“源文件无法读取”和“SQLite 主库写失败”一并吞掉，可解析资料可能只留下文件投影。 | 只把读取失败降级为附件；识别后的结构化主库写失败会阻断复制并向用户报告。 |
| PT-14 | 手工保存、工作台/CLI 新建与导入在 SQLite 主库先写成功、Markdown 投影失败时缺少当前条目补偿。 | 保存路径恢复原 SQLite 快照；通用新建/导入增加可选回滚 hook，App 与 CLI 均传入 SQLite 快照恢复逻辑。 |
| PT-15 | 项目概览先于 manifest 写入；manifest 提交失败时，概览可能已显示目标类型而项目合同仍为源类型。 | `UpdateProjectManifestUseCase` 在 manifest 失败时恢复原概览（无原文件时生成源项目概览），并保留原始写入错误。 |
| PT-16 | 任务中心页面监听器只在当前路由为任务中心时同步，且长任务命令在轮询刷新仍运行时发布终态；从工作台或长任务站创建/刷新队列时，终态可能丢失并长期显示“正在生成”。 | 任务中心监听器改为始终同步；命令编排在终态刷新前清除 in-flight，停止轮询脉冲，使成功或失败视图拥有最后一次刷新代次。 |
| PT-17 | SQLite 拆书派生章节位于 `imports/derived/...`，但派生续写/同人类型未被认作结构化正文。首次归档后，工作台或低层工具再次编辑只改 Markdown 投影，SQLite 主事实源保留旧正文。 | 将两类派生叙事纳入 SQLite 主事实源与工作区投影策略；覆盖工作台保存、工具宿主写入和主库回读。 |
| PT-18 | 新建项目时，显式传入未知 `projectTypeId` 会经通用 normalize 静默降级为 `novel`，用户选错类型却得到普通小说项目。 | `CreateProjectWorkspaceUseCase.prepare` 现在拒绝非空未登记类型；空值仍按兼容约定默认普通小说。 |
| PT-19 | `ProjectCreationPlan` 是公开对象，调用方可伪造 `readyToCreate` 后传给 `executePrepared`，绕过长篇运行基准、禁用类型和存储策略约束。 | `executePrepared` 以请求重新 prepare，只使用重新校验后的计划执行落盘。 |
| PT-20 | Manifest 的 `additional_trait_ids` 在创建、读取和编码边界未统一规范化，空值、空格和重复值会制造等价但漂移的复合能力合同。 | Manifest codec 在全部出入口去空、去重并保持首次出现顺序。 |
| PT-21 | 运行画像是 manifest 派生数据，但非 `long_novel` 项目仍可在 profile 中保留长任务基准及 unattended/自动推进选项。 | 运行画像的构建、解析和编码均按项目类型归一化基准；发生归一化时重建派生运行选项。 |
| PT-22 | Trait 解析器仍会直接采纳传入的长任务基准；普通小说若收到陈旧或手工构造的基准，会被授予 `long_task` 能力。 | Trait 解析前再次按项目类型归一化运行基准，防止公共低层 API 被绕过。 |
| PT-23 | 默认项目或显式项目打开时，底层加载异常会直接冒泡，调用方拿不到可恢复的失败状态。 | `ProjectLifecycleCoordinator` 把加载异常统一转换为既有的项目启动器恢复 resolution。 |
| PT-24 | 项目库扫描可在手动刷新、根目录切换和选择项目并发时让旧扫描覆盖新缓存或用户最新选择；扫描异常也会使入口丢失可用缓存。 | `ProjectOpenController` 串行化扫描、保留刷新期间的新选择、在同一目录扫描失败时保留缓存并显示可行动的失败提示。 |
| PT-25 | 已有 `short_collection` 项目在工作台副标题显示内部 ID，和目录中声明的历史兼容语义不一致。 | 副标题服务识别真实的 `short_collection` ID，并显示“短篇集项目”。 |
| PT-26 | `rename_project` 会用默认 manifest 重建项目，丢失长篇运行基准、SQLite 策略、知识库分支和复合拆书 trait；概览还会把多数类型标为“小说”。若 manifest 提交失败，已写概览也会与实际合同漂移。 | 重命名现在完整保留当前 manifest 合同，按五种类型写正确概览标签；manifest 缺失或损坏时，使用已加载 descriptor 的存储策略、知识库分支、运行基准和附加 trait 作为回退，避免元数据操作降级能力。先写概览后把 manifest 作为提交标记，提交失败即恢复原概览。已覆盖普通小说、长篇、知识库、拆书和历史短篇集。 |
| PT-27 | GUI 长任务真实探针把投影写入 `gui_viewmodel`，通用失败分类却只读取旧的 `viewmodel`，文件事实与 ViewModel 不一致时被误报为内容质量问题。 | 冲突判定优先读取 `gui_viewmodel`，再兼容旧字段；不一致结果稳定归类为 `contract_conflict`。 |

## 合理性边界与残余风险

1. 文件系统与 SQLite 不是同一事务管理器。当前采用“主库先写 + 投影后写 + 失败补偿”；进程在两个步骤之间被强制终止时，重开和可读投影仍需承担恢复职责。
2. 仅可解析的文本格式进入结构化主库；图片、压缩包及其他二进制文件按附件保留在文件树中，这是有意的边界，不应尝试按文本入库。
3. `ImportProjectFilesUseCase` 保持通用复制能力。新的宿主若直接调用它而未提供文本持久化与回滚 hook，应明确把该调用定位为附件复制；SQLite 文本入口必须同时提供主库同步和投影失败补偿。
4. CLI 当前提供通用项目操作和安全导入，不承诺覆盖 App 的完整拆书预演、确认和恢复交互；拆书全流程以 App 为正式宿主。
5. 自定义集成若直接向 `ProjectWorkspacePort` 写结构化内容而绕过工作区存储服务、工具宿主或 bridge，仍可能绕开 SQLite 主事实源。新增入口应复用现有 bridge/hook，而不是直接写 Markdown。
6. `ProjectCreationPlan`、运行画像和 capability/trait resolver 都是公开或可被外部数据驱动的边界；新入口必须重新按 manifest、项目类型和运行基准目录校验，不能将前端状态或缓存对象当作授权凭据。
7. 两个真实模型探针需要用户提供本机 API 配置，不能在无 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE` 时被当作离线自动化回归；其失败会明确报为环境前置条件缺失。

## 最终验证记录

```text
packages/novel_agent_core
  dart test
  # 1027 passed
  dart analyze
  # 12 条既有 warning，无 error

packages/novel_agent_adapters
  dart test -r expanded --concurrency=1
  # 501 passed
  dart test test/project_tool_dispatcher_path_test.dart -r expanded
  # 19 passed；覆盖五种项目类型的重命名合同和失败补偿
  dart analyze
  # 25 条既有 issue（24 warning、1 info），无 error

apps/novel_agent_cli
  dart test --concurrency=1
  # 99 passed
  dart analyze
  # No issues found

apps/novel_agent_app
  flutter test test/real_gui_viewmodel_information_long_task_probe_contract_test.dart
               test/probe_support_test.dart
  # 10 passed
  flutter test -r expanded
  # 632 passed / 12 skipped / 2 failed
  # 两项失败均为 HFVV-04/HFVV-06 缺少 local/probe_api.txt 或 NOVEL_AGENT_PROBE_API_FILE；
  # 12 项跳过均为缺少人工 golden 或 RE0 smoke artifact。
  flutter analyze
  # 38 条既有 issue（22 warning、16 info），无 error
```
