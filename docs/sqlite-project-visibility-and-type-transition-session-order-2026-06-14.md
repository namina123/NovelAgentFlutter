# NovelAgentFlutter SQLite 项目可见性、知识库对齐与项目类型互转任务顺序文档

最后更新：2026-06-14

主线代号：`SPT`（SQLite Project Visibility / Project Type Transition）

关联主要资料：

- `agent.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `docs/mumuainovel-absorption-analysis.md`
- `docs/storage-dual-compatibility-design.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
- `docs/important/sqlite-project-visibility-and-type-transition-analysis-2026-06-14.md`

关联历史任务顺序文档：

- `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md`
- `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md`
- `docs/release-readiness-productization-session-order-2026-06-05.md`
- `docs/context-token-budget-and-compaction-session-order-2026-06-14.md`

关联代码锚点：

- `packages/novel_agent_core/lib/src/project/`
- `packages/novel_agent_core/lib/src/use_cases/create_project_workspace_use_case.dart`
- `packages/novel_agent_core/lib/src/use_cases/update_project_manifest_use_case.dart`
- `packages/novel_agent_adapters/lib/src/storage/sqlite_project_*.dart`
- `packages/novel_agent_adapters/lib/src/storage/project_reference_*.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/project_launcher_view_data_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_visibility_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_display_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/renderers/document_resource_renderer_resolver.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`

---

## 1. 这份文档解决什么

这份文档要解决的，不是“把 `knowledge_base` 改成只能选 SQLite”这么窄的事情，而是把下面这整条主线正式收口：

```text
把“SQLite 已经存在，但项目类型语义、用户可见性、知识库定位、项目互转仍然半悬空”
收口成
“项目类型边界清楚、knowledge_base 与参考资产库对齐、SQLite 项目可理解可回看、
普通小说与长篇长任务可在同存储策略内互转、GUI 只消费稳定合同”的正式能力链。
```

完成本主线后，项目应具备：

1. 正式的项目类型与存储策略能力矩阵，而不是所有类型默认双策略。
2. `knowledge_base` 正式收束为 `sqlite_project_store` only。
3. 普通项目在选择 `sqlite_project_store` 后，正文与关键项目内容不再只是“文件优先 + 建库壳”，而是有真实的 SQLite 主事实源与写穿桥。
4. `knowledge_base` 的产品定位正式对齐应用级 `ReferenceEvidenceSubstrate`，不再是概念悬空的“本地知识库项目”。
5. SQLite 项目有正式的语义树、结构化浏览与只读诊断层，而不是把 `.db` 当作资源主入口。
6. `novel <-> long_novel` 的项目类型互转正式成立，且第一阶段严格保持原存储策略不变。
7. “项目类型转换”和“存储迁移”在架构上被彻底拆开，避免后续实现混线。
8. GUI、ViewModel、probe、未来 CLI 都消费同一套核心合同，而不是各自发明半套项目类型语义。
9. `sqlite` 项目的工具暴露、prompt 合同与执行分发，不再把 Markdown/file-tree first 能力误当成主路径。

---

## 2. 与旧文档的关系

### 2.1 它不是另起一套存储系统

这份文档不允许：

1. 重新造一套和 `ProjectStorageStrategy` 平行的“知识库专用存储体系”。
2. 为 `knowledge_base` 偷偷绕开现有 `create project / manifest / workspace` 主链。
3. 在 GUI 中直接写死“这个类型只能这样”，却不把规则下沉成核心合同。
4. 用新的数据库浏览器式页面，替代真正的语义投影树与结构化工作台。

正确方向是：

1. 继续保留 `markdown_project_store` 与 `sqlite_project_store` 两种主存储策略。
2. 把“哪些项目类型支持哪种策略”收束为正式目录能力矩阵。
3. 让 `knowledge_base` 与应用级参考资产库对齐，而不是做成悬空的第三套资料语义。
4. 让 SQLite 项目的用户可见层建立在投影合同上，而不是建立在裸表和物理文件上。

### 2.2 它继承哪些已有判断

1. `docs/storage-dual-compatibility-design.md`
   - 已经明确了“主存储策略”和“投影层”的长期边界。
2. `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
   - 已经明确了：
     - 应用级 `ReferenceEvidenceSubstrate`
     - 项目级 `ProjectReferenceAttachmentLayer`
     - 项目级 `ProjectInformationCapabilityLayer`
3. `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
   - 已经明确了 `knowledge_base / reference_extraction / writing` 不是一回事。
4. `docs/important/sqlite-project-visibility-and-type-transition-analysis-2026-06-14.md`
   - 已经给出了本轮冻结的判断：
      - `knowledge_base` 应为 sqlite-only
      - SQLite 项目要语义可见，不要裸露
      - `novel <-> long_novel` 先做类型互转，不混存储迁移
      - 普通项目 sqlite 还缺 storage-aware tool surface
5. `docs/mumuainovel-absorption-analysis.md`
   - 这一轮只吸收其中“结构化资产中心、语义管理优先于裸数据库展示”的产品思想，
   - 不吸收其 SaaS/Web 架构，也不把 SQLite 可见性做成数据库浏览器。

### 2.3 这份文档不处理什么

1. 不在本主线里完成真正的 `markdown <-> sqlite` 内容迁移。
2. 不在本主线里重做应用级参考资产库的全部提取运行时。
3. 不在本主线里重构 CLI 产品面；CLI 只要求不被新合同破坏，必要时补最小消费。
4. 不在本主线里讨论具体小说题材、长任务风格或表达限制策略。
5. 不把 SQLite 可见性做成数据库管理器或通用 SQL 浏览器。

---

## 3. 已有实现去重审计

### 3.1 已有可复用基础

1. `ProjectTypeCatalogService`
2. `ProjectTypeDefinition`
3. `ProjectStorageStrategy`
4. `CreateProjectWorkspaceUseCase`
5. `UpdateProjectManifestUseCase`
6. `ProjectManifestCodecService`
7. `ProjectRuntimeBaselineCatalogService`
8. `ProjectRuntimeProfileDocumentService`
9. `ProjectDirectoryLayoutService`
10. `SqliteProjectDatabaseInitializer`
11. `SqliteProjectReadableProjectionService`
12. `workspace_resource_visibility_service / display_service`
13. `WorkspaceInformationProjectionService`
14. `DocumentResourceRendererResolver`
15. `sqlite_*_repository` 与 `sqlite_reference_evidence_substrate`

这些都不应推倒重来。

### 3.2 已有但仍是半成品

1. 所有项目类型默认双存储策略，这对 `knowledge_base` 已不准确。
2. SQLite 项目目前只有最小 `project_brief` 投影，不足以形成真正的用户可见工作树。
3. `.db / .sqlite` 仍被当成 preview-like 文档资源，这只是临时兜底。
4. 项目类型转换还没有正式合同，当前只能“改 manifest”，不能真正安全转换。
5. `knowledge_base` 和应用级 `ReferenceEvidenceSubstrate` 在产品语义上仍未正式对齐。
6. SQLite 项目仍缺：
   - 语义树
   - 结构化浏览
   - 来源身份
   - 真相源回跳
   - 高级只读诊断层
7. 普通项目的 SQLite 主链仍未真正收口：
   - 正文写入主链仍主要走文件系统
   - `body_text_document / body_text_segment` 只有 schema，没有真实普通项目写入链
   - 几乎没有普通小说 + SQLite 的 focused validation 或真实 probe
8. 对照 MuMu 能确认：我们当前最先缺的不是一个更花的 SQLite 页面，而是“普通项目正文是否已经是结构化资产真相源”。
9. `sqlite` 项目的工具暴露和 prompt 合同仍主要按文件树项目组织：
   - 缺少 storage-aware tool exposure
   - 缺少 sqlite 项目的宿主提交/兼容读取边界
   - 缺少“低层文件工具在 sqlite 项目里只是兼容面”的正式收口

### 3.3 真正缺的层

1. `ProjectTypeStoragePolicy` 级别的能力矩阵
2. `ProjectTypeTransitionPolicy`
3. `ProjectTypeTransitionPlan`
4. `ExecuteProjectTypeTransitionUseCase`
5. 普通项目 SQLite 主事实源合同
6. 普通项目 SQLite 正文写穿/读桥
7. `SqliteProjectProjectionCatalog`
8. `SqliteProjectVisibilityPolicy`
9. `StructuredWorkspaceTreeBuilder`
10. `knowledge_base -> ReferenceEvidenceSubstrate` 的产品层对齐桥
11. 高保真 ViewModel 验证链，证明：
    - 创建知识库项目时只能选 SQLite
    - 普通小说 + SQLite 能真实写正文并回读
    - SQLite 项目不是展示裸 `.db`
    - `novel <-> long_novel` 互转确实收口了运行基准和长任务状态
12. `ProjectStorageAwareToolCapabilityMatrix`
13. `SqliteProjectToolExposureContract / SqliteCompatibilityToolPolicy`
14. storage-aware prompt / schema exposure bridge

---

## 4. 本轮冻结的架构边界

1. `knowledge_base` 的主事实源必须是 `sqlite_project_store`。
2. `knowledge_base` 是参考资产治理型项目，不是“项目知识卡的放大版”。
3. SQLite 项目的主浏览入口必须是“语义资源树/结构化视图”，不是物理 `.db` 文件。
4. 普通项目 SQLite 这轮必须先补“真实主事实源 + 正文写穿 + 读取桥”，再继续放大可见性包装。
5. `novel <-> long_novel` 第一阶段只做项目类型互转，不做内容迁移。
6. 项目类型转换必须保留原存储策略不变：
   - `md -> md`
   - `sqlite -> sqlite`
7. `knowledge_base` 当前不与写作项目互转；优先做挂载、提升、导出、引用。
8. 不允许把项目类型判断堆进 widget、controller 或 probe。
9. 不允许把 SQLite 可见性实现成数据库浏览器。
10. 不允许新建与现有 `project / manifest / workspace` 平行的另一条 runtime。
11. 不允许为了通过 GUI 路径而在 app 层补第二套项目类型真相。
12. 单文件接近 400 行时主动复核职责；接近 700 行必须拆。
13. 不允许把 Markdown/file-tree first 的低层工具继续作为 sqlite 项目的默认主能力面。
14. 语义级工具应尽量跨存储策略稳定，低层文件工具必须显式标注“主事实源 / 投影 / 兼容 / 调试”边界。
15. `referenceMountCommit` 这类 sqlite-first 宿主能力，如果当前没有真实 tool contract，不能只停留在 capability family 文案层。

---

## 5. 目标终态

完成本主线后，应达到以下终态：

1. `ProjectTypeDefinition` 能正式声明支持的存储策略。
2. `knowledge_base` 创建时只暴露 SQLite 选项，核心同样强约束，而不只是 UI 隐藏。
3. 普通小说项目若选择 SQLite：
   - 正文会进入 SQLite 主事实源
   - 文件树中的章节/场景成为投影或兼容层，而不是唯一真相
   - 至少能真实写入、回读、验证
4. 有正式的 `ProjectTypeTransitionPolicy / Plan / Execute UseCase`。
5. `novel -> long_novel` 时：
   - 能补齐或确认 runtime baseline
   - 能初始化最小长任务控制面状态
6. `long_novel -> novel` 时：
   - 会拒绝未归档的活跃长任务
   - 会保留历史运行记录但退出长任务主入口
7. SQLite 项目工作台默认看到的是：
   - 项目概览
   - 正文与章节
   - 大纲与设定
   - 项目资料
   - 参考资产挂载
   - 导入源
   - 提取与审核
   - 导出与投影
8. SQLite 项目中的 `.db` 不再作为普通资源树主入口出现。
9. `knowledge_base` 能在产品语义上被看作“参考资产治理工作台”，并和应用级资产库词汇一致。
10. `sqlite` 项目有正式的 storage-aware tool surface：
   - 语义工具可稳定使用
   - 低层文件工具不会再误导模型把文件树当主事实源
   - 必要的兼容读取和调试读取边界清楚
11. `referenceMountCommit` 相关宿主/监督者能力不再只是概念，而是有正式合同或显式占位策略。
12. focused tests、adapter tests、ViewModel probes 能证明这条主线真实可用，其中包含普通小说 + SQLite 的真实验证与工具暴露验证。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `16` 个 session。

顺序理由：

1. `SPT-01` 先做去重审计与矩阵冻结，防止中途反复争论“哪个项目应该支持什么”。
2. `SPT-02` 到 `SPT-04` 先把 core 合同、互转图、执行计划定稳。
3. `SPT-05` 到 `SPT-06` 先补普通项目 SQLite 的真实主事实源与写穿桥。
4. `SPT-07` 到 `SPT-08` 再把工具暴露、dispatcher、prompt contract 收成 storage-aware。
5. `SPT-09` 到 `SPT-11` 再落 SQLite 语义投影和 `knowledge_base` 对齐桥。
6. `SPT-12` 到 `SPT-14` 最后接 GUI：创建链、项目设置、工作台语义树。
7. `SPT-15` 做 focused tests 与最小 CLI 兼容审计。
8. `SPT-16` 做 ViewModel 级探针、回归、文档收口。

这条顺序明确避免：

1. 先改项目创建 UI，再回头改核心矩阵。
2. 先在工作台里补一堆显示规则，再发现 core 仍允许错误组合。
3. 先做项目类型切换按钮，再发现没有执行计划和兼容图。
4. 先用 SQLite 语义树包装界面，却发现普通项目正文其实还没真正进入 SQLite 主事实源。
5. 先用 probe 判定“可见性通过”，却没有 production 同源语义树合同。
6. 先让 sqlite 项目继续拿着 Markdown/file-tree first 工具面跑，再把稳定性问题误判成模型不听话。

---

## 7. 全局执行规则

所有 session 都必须遵守：

1. 先阅读本文档、`agent.md`、当前 session 必读文件。
2. 只做当前 session，不开启下一任务。
3. 优先扩已有合同和服务，不新造平行 runtime。
4. focused test / contract test 与实现同轮落地。
5. probe 与 GUI 只消费 production 同源合同，不写第二套项目类型真相。
6. `knowledge_base` 的对齐目标是 `ReferenceEvidenceSubstrate`，不是和项目知识卡重新耦死。
7. 所有“转换”必须显式区分：
   - 项目类型转换
   - 主存储迁移
8. 本轮不做 `markdown <-> sqlite` 存储迁移，只为未来留 hook。
9. 对 `gpt-5.4-mini` 尤其重要：
   - 不要推测未读代码
   - 不要为了省事把逻辑塞进 controller
   - 不要新增大而全文件
   - 不要在当前 session 顺手开做下一 session

---

## 8. Sessions

## SPT-01 基线审计与能力矩阵冻结

- 本轮目标：
  - 对当前项目类型、存储策略、SQLite 可见性、知识库语义和项目互转现状做最终基线审计，并冻结能力矩阵。
- 层级归属：
  - Documentation / Core boundary audit
- 必读文件：
  - 本文档
  - `agent.md`
  - `docs/important/sqlite-project-visibility-and-type-transition-analysis-2026-06-14.md`
  - `packages/novel_agent_core/lib/src/project/project_type_catalog_service.dart`
  - `packages/novel_agent_core/lib/src/project/project_type_definition.dart`
  - `packages/novel_agent_core/lib/src/project/project_storage_strategy.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_launcher_view_data_service.dart`
- 必须完成：
  - 列出当前全部项目类型及其实际支持的存储策略现状。
  - 冻结目标矩阵：
    - `novel`: markdown + sqlite
    - `long_novel`: markdown + sqlite
    - `knowledge_base`: sqlite only
    - `book_deconstruction`: markdown + sqlite
  - 列出第一阶段允许的项目类型转换图。
  - 把“类型转换 != 存储迁移”写成正式术语。
- 本轮不要做：
  - 不改实现
  - 不加 UI
  - 不改 probe
- 验收标准：
  - 文档里有最终矩阵和转换图，后续 session 不再争论边界。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-01` 执行。先阅读本文档、`agent.md`、`docs/important/sqlite-project-visibility-and-type-transition-analysis-2026-06-14.md`、`packages/novel_agent_core/lib/src/project/project_type_catalog_service.dart`、`packages/novel_agent_core/lib/src/project/project_type_definition.dart`、`packages/novel_agent_core/lib/src/project/project_storage_strategy.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/project_launcher_view_data_service.dart`。只做项目类型/存储策略/SQLite 可见性/项目互转的基线审计与能力矩阵冻结，明确第一阶段支持什么、不支持什么，并写成稳定术语。不要改实现，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-02 项目类型与存储策略能力矩阵落地

- 本轮目标：
  - 把冻结后的能力矩阵正式落到 core 目录定义中。
- 层级归属：
  - Core / domain
- 必读文件：
  - 本文档
  - `packages/novel_agent_core/lib/src/project/project_type_definition.dart`
  - `packages/novel_agent_core/lib/src/project/project_type_catalog_service.dart`
  - `packages/novel_agent_core/lib/src/use_cases/create_project_workspace_use_case.dart`
  - `packages/novel_agent_core/lib/src/project/project_manifest_codec_service.dart`
- 必须完成：
  - 让 `ProjectTypeDefinition` 能清楚表达支持的存储策略。
  - 把 `knowledge_base` 收束为 `sqlite_project_store` only。
  - 确保 create/manifest 主链在 core 层就会遵守这个约束，而不只是 UI 隐藏。
  - 补 focused tests：
    - `knowledge_base` 创建时只能归一化到 sqlite
    - 旧项目兼容行为不被破坏
- 本轮不要做：
  - 不做项目类型转换
  - 不做 GUI
  - 不做 SQLite 语义树
- 验收标准：
  - 从 core 层创建 `knowledge_base` 时，不可能再落到 markdown。
  - focused tests 通过。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-02` 执行。先阅读本文档、`agent.md`、`packages/novel_agent_core/lib/src/project/project_type_definition.dart`、`packages/novel_agent_core/lib/src/project/project_type_catalog_service.dart`、`packages/novel_agent_core/lib/src/use_cases/create_project_workspace_use_case.dart`、`packages/novel_agent_core/lib/src/project/project_manifest_codec_service.dart`。只做项目类型与存储策略能力矩阵落地：让 `knowledge_base` 在 core 层收束为 sqlite-only，并补 focused tests。不要做项目类型转换、不要接 GUI、不要开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-03 项目类型转换合同与兼容图

- 本轮目标：
  - 建立正式的项目类型转换合同，不执行，只定义图、限制和错误语义。
- 层级归属：
  - Core / domain contracts
- 必读文件：
  - 本文档
  - `packages/novel_agent_core/lib/src/project/`
  - `packages/novel_agent_core/lib/src/use_cases/update_project_manifest_use_case.dart`
  - `packages/novel_agent_core/lib/src/project/project_runtime_baseline_catalog_service.dart`
  - `packages/novel_agent_core/lib/src/project/project_runtime_profile_document_service.dart`
- 必须完成：
  - 新增类似：
    - `ProjectTypeTransitionPolicy`
    - `ProjectTypeTransitionRequest/Plan`
    - `ProjectTypeTransitionReason`
  - 定义第一阶段转换图：
    - `novel -> long_novel`
    - `long_novel -> novel`
  - 明确：
    - 保持原存储策略不变
    - 不支持 `knowledge_base` 互转
    - 不支持主存储迁移
  - 补 focused tests 覆盖允许/拒绝原因。
- 本轮不要做：
  - 不写执行 use case
  - 不写 GUI 按钮
  - 不改 SQLite 投影
- 验收标准：
  - 有正式合同对象和测试，后续执行链可以直接消费。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-03` 执行。先阅读本文档、`agent.md`、`packages/novel_agent_core/lib/src/project/`、`packages/novel_agent_core/lib/src/use_cases/update_project_manifest_use_case.dart`、`packages/novel_agent_core/lib/src/project/project_runtime_baseline_catalog_service.dart`、`packages/novel_agent_core/lib/src/project/project_runtime_profile_document_service.dart`。只做项目类型转换合同与兼容图：定义允许/拒绝规则、错误原因、第一阶段转换图，并补 focused tests。不要写执行用例，不接 GUI，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-04 项目类型转换计划与执行用例

- 本轮目标：
  - 把类型转换从纯合同推进到可执行的 core 用例。
- 层级归属：
  - Core / use case
- 必读文件：
  - 本文档
  - `packages/novel_agent_core/lib/src/use_cases/update_project_manifest_use_case.dart`
  - `packages/novel_agent_core/lib/src/project/project_manifest_codec_service.dart`
  - `packages/novel_agent_core/lib/src/project/project_runtime_profile_document_service.dart`
  - `packages/novel_agent_core/lib/src/project/project_runtime_baseline_catalog_service.dart`
  - `packages/novel_agent_core/lib/src/ports/project_workspace_port.dart`
- 必须完成：
  - 新增类似：
    - `ExecuteProjectTypeTransitionUseCase`
    - `ProjectTypeTransitionPreparationService`
  - 支持：
    - `novel -> long_novel`
    - `long_novel -> novel`
  - 处理：
    - runtime baseline 选择/归一化
    - 活跃长任务拒绝或前置清理要求
    - manifest / runtime_profile 的最小更新
  - focused tests 覆盖：
    - 转入长任务时需 baseline
    - 活跃长任务未处理时拒绝转回普通项目
    - 不会改变原存储策略
- 本轮不要做：
  - 不在这里做 GUI 流程
  - 不做长任务完整归档 UI
  - 不做存储迁移
- 验收标准：
  - Core 层能独立执行类型转换计划，且测试证明不串改存储策略。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-04` 执行。先阅读本文档、`agent.md`、`packages/novel_agent_core/lib/src/use_cases/update_project_manifest_use_case.dart`、`packages/novel_agent_core/lib/src/project/project_manifest_codec_service.dart`、`packages/novel_agent_core/lib/src/project/project_runtime_profile_document_service.dart`、`packages/novel_agent_core/lib/src/project/project_runtime_baseline_catalog_service.dart`、`packages/novel_agent_core/lib/src/ports/project_workspace_port.dart`。只做项目类型转换计划与执行用例，覆盖 `novel <-> long_novel`，保持存储策略不变，并补 focused tests。不要做 GUI，不做存储迁移，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-05 普通项目 SQLite 主事实源合同与正文仓储接口

- 本轮目标：
  - 先把普通项目在 SQLite 下“什么是事实源、什么是投影、正文如何进入 SQLite”定成正式合同。
- 层级归属：
  - Core / domain / shared persistence contracts
- 必读文件：
  - 本文档
  - `docs/important/sqlite-project-visibility-and-type-transition-analysis-2026-06-14.md`
  - `packages/novel_agent_core/lib/src/project/sqlite_project_body_text_document.dart`
  - `packages/novel_agent_core/lib/src/project/sqlite_project_body_text_policy_service.dart`
  - `packages/novel_agent_core/lib/src/use_cases/write_project_text_file_use_case.dart`
  - `packages/novel_agent_core/lib/src/ports/project_workspace_port.dart`
- 必须完成：
  - 冻结普通项目 SQLite 的主事实源规则：
    - 哪些内容必须进入 SQLite
    - 哪些内容允许继续作为投影/兼容文件存在
  - 新增正式合同，例如：
    - `ProjectBodyTextRepository`
    - `ProjectStructuredContentWritePolicy`
    - `ProjectStorageAwareWorkspacePolicy`
  - 明确普通项目正文写入、回读、投影之间的语义关系。
  - 补 focused tests，证明合同能区分：
    - markdown 主项目
    - sqlite 主项目
- 本轮不要做：
  - 不写 adapter 真正落库
  - 不改 GUI
  - 不做 SQLite 可见性
- 验收标准：
  - 普通项目 SQLite 的正文与投影边界在 core 层清楚，后续 adapters 不需要再猜。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-05` 执行。先阅读本文档、`agent.md`、`docs/important/sqlite-project-visibility-and-type-transition-analysis-2026-06-14.md`、`packages/novel_agent_core/lib/src/project/sqlite_project_body_text_document.dart`、`packages/novel_agent_core/lib/src/project/sqlite_project_body_text_policy_service.dart`、`packages/novel_agent_core/lib/src/use_cases/write_project_text_file_use_case.dart`、`packages/novel_agent_core/lib/src/ports/project_workspace_port.dart`。只做普通项目 SQLite 主事实源合同与正文仓储接口，定义事实源/投影边界并补 focused tests。不要写 adapter 真落库，不改 GUI，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-06 普通项目 SQLite 正文写穿/读桥与策略感知读写

- 本轮目标：
  - 把普通项目 SQLite 从“建库壳”推进到最小可用主存储：至少正文能真实写入、回读、验证。
- 层级归属：
  - Adapters / persistence / workflow bridge
- 必读文件：
  - 本文档
  - `packages/novel_agent_adapters/lib/src/storage/local_project_workspace_port.dart`
  - `packages/novel_agent_adapters/lib/src/storage/project_workspace_tool_host_adapter.dart`
  - `packages/novel_agent_adapters/lib/src/storage/sqlite_project_body_text_store.dart`
  - `packages/novel_agent_adapters/lib/src/tools/project_file_write_tool_executor.dart`
  - `packages/novel_agent_core/lib/src/tools/domain/submit_chapter_delivery_handler.dart`
- 必须完成：
  - 为普通项目 SQLite 建立最小正文写穿链：
    - 章节正式交付至少能写入 SQLite 正文主表
    - 能从 SQLite 回读正文
  - 让相关读写桥具备存储策略感知，不再永远只走文件系统。
  - 文件层可暂时保留投影/兼容，但不能再是唯一事实源。
  - 补 focused tests / adapter tests：
    - `novel + sqlite` 写正文后，SQLite 表中有真实记录
    - 普通读取链能回读
- 本轮不要做：
  - 不在这轮做全量项目资料写穿
  - 不做 GUI
  - 不做 SQLite 语义树
- 验收标准：
  - 普通项目 SQLite 至少对正文达成“真写入 + 真回读”，不再只是 schema 空壳。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-06` 执行。先阅读本文档、`agent.md`、`packages/novel_agent_adapters/lib/src/storage/local_project_workspace_port.dart`、`packages/novel_agent_adapters/lib/src/storage/project_workspace_tool_host_adapter.dart`、`packages/novel_agent_adapters/lib/src/storage/sqlite_project_body_text_store.dart`、`packages/novel_agent_adapters/lib/src/tools/project_file_write_tool_executor.dart`、`packages/novel_agent_core/lib/src/tools/domain/submit_chapter_delivery_handler.dart`。只做普通项目 SQLite 正文写穿/读桥与策略感知读写，并补 focused tests。不要做全量资料写穿，不改 GUI，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-07 SQLite 项目工具能力矩阵与暴露合同

- 本轮目标：
  - 把 `sqlite` 项目的工具能力面从“默认沿用文件树项目”收束成正式合同，明确哪些工具跨存储稳定、哪些只属于兼容层、哪些必须宿主/监督者收口。
- 层级归属：
  - Core / tool contracts / policy
- 必读文件：
  - 本文档
  - `docs/important/sqlite-project-visibility-and-type-transition-analysis-2026-06-14.md`
  - `packages/novel_agent_core/lib/src/tools/tool_exposure_policy_service.dart`
  - `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`
  - `packages/novel_agent_core/lib/src/tools/tool_capability_family_catalog_service.dart`
  - `packages/novel_agent_core/lib/src/tools/builtin_tool_catalog.dart`
  - `packages/novel_agent_core/lib/src/project/project_prompt_contract.dart`
- 必须完成：
  - 新增正式合同，例如：
    - `ProjectStorageAwareToolCapabilityMatrix`
    - `SqliteCompatibilityToolPolicy`
    - `ProjectToolExposureContext`
  - 冻结至少三层工具边界：
    - 跨存储稳定的语义工具
    - sqlite 项目允许的兼容/投影读取工具
    - 宿主或 supervisor 才能裁定的 sqlite-first 提交/挂载能力
  - 明确普通项目 `sqlite` 下，哪些低层文件工具：
    - 仍可读
    - 仅限兼容/诊断
    - 应默认拒绝或降级
  - 明确 `referenceMountCommit` 不能再只停留在 capability family 文案，至少要形成正式合同占位。
  - 补 focused tests：
    - 不同 `projectType + storageStrategy` 的工具矩阵可判定
    - `sqlite` 项目不会再把 Markdown/file-tree first 工具面当默认主能力面
- 本轮不要做：
  - 不写 dispatcher 真执行逻辑
  - 不改 GUI
  - 不做 SQLite 语义树
- 验收标准：
  - Core 层存在可消费的 storage-aware tool contract，后续 dispatcher、prompt、GUI 不再自行猜测 sqlite 项目该暴露什么。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-07` 执行。先阅读本文档、`agent.md`、`docs/important/sqlite-project-visibility-and-type-transition-analysis-2026-06-14.md`、`packages/novel_agent_core/lib/src/tools/tool_exposure_policy_service.dart`、`packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`、`packages/novel_agent_core/lib/src/tools/tool_capability_family_catalog_service.dart`、`packages/novel_agent_core/lib/src/tools/builtin_tool_catalog.dart`、`packages/novel_agent_core/lib/src/project/project_prompt_contract.dart`。只做 sqlite 项目工具能力矩阵与暴露合同，明确跨存储稳定工具、兼容读取工具、宿主收口工具，并补 focused tests。不要写 dispatcher 真执行，不改 GUI，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-08 Storage-aware Tool Dispatcher、Prompt Contract 与 Schema 暴露收口

- 本轮目标：
  - 把上一轮的 storage-aware tool contract 接到真实工具暴露与执行链，避免 sqlite 项目继续拿到误导性的 file-tree first 提示和执行出口。
- 层级归属：
  - Core / Adapters / prompt bridge / tool runtime
- 必读文件：
  - 本文档
  - `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`
  - `packages/novel_agent_adapters/lib/src/tools/project_tool_path_policy.dart`
  - `packages/novel_agent_adapters/lib/src/tools/project_file_read_tool_executor.dart`
  - `packages/novel_agent_adapters/lib/src/tools/project_file_write_tool_executor.dart`
  - `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`
  - `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`
  - `packages/novel_agent_core/lib/src/project/project_prompt_contract.dart`
  - `packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart`
- 必须完成：
  - 让工具 schema 暴露链能感知：
    - `project.projectType`
    - `project.storageStrategy`
    - 任务族 / 运行时意图
  - 让 sqlite 项目默认不再收到误导性的 file-tree first prompt 合同。
  - 让 dispatcher / read-write executor 至少具备：
    - storage-aware 拒绝
    - storage-aware 降级
    - storage-aware 兼容读取
  - 保证普通项目 `sqlite` 至少可以靠：
    - 语义工具
    - 必要兼容读取
    完成真实写作流程，而不是被卡在“既拿不到正确工具，又误拿到错误工具”。
  - 补 focused tests / adapter tests：
    - `sqlite` 项目暴露的 tool schemas 与 `markdown` 项目不同
    - `sqlite` 项目不会再默认把低层文件写入工具当主交付路径
    - 关键语义工具仍可正常暴露
- 本轮不要做：
  - 不在这轮做 GUI 工作台
  - 不做大规模 SQLite 投影实现
  - 不做数据库浏览器
- 验收标准：
  - sqlite 项目的工具暴露、prompt 合同和 dispatcher 行为已经同源收口，不再靠模型自己猜“现在该按文件树还是按 sqlite 来做”。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-08` 执行。先阅读本文档、`agent.md`、`packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`、`packages/novel_agent_adapters/lib/src/tools/project_tool_path_policy.dart`、`packages/novel_agent_adapters/lib/src/tools/project_file_read_tool_executor.dart`、`packages/novel_agent_adapters/lib/src/tools/project_file_write_tool_executor.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`、`packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`、`packages/novel_agent_core/lib/src/project/project_prompt_contract.dart`、`packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart`。只做 storage-aware tool dispatcher、prompt contract 与 schema 暴露收口，并补 focused tests。不要做 GUI，不做 SQLite 语义树，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-09 SQLite 语义投影合同与可见性模型

- 本轮目标：
  - 为 SQLite 项目建立正式的语义投影与可见性合同。
- 层级归属：
  - Core / shared projection contracts
- 必读文件：
  - 本文档
  - `docs/storage-dual-compatibility-design.md`
  - `packages/novel_agent_core/lib/src/project/`
  - `apps/novel_agent_app/lib/features/workbench/presentation/models/resource_entry_view_data.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_visibility_service.dart`
- 必须完成：
  - 设计稳定模型，例如：
    - `SqliteProjectionNode`
    - `SqliteProjectionNodeKind`
    - `SqliteProjectionSourceIdentity`
    - `SqliteVisibilityPolicy`
  - 冻结默认主语义树分组：
    - 项目概览
    - 正文与章节
    - 大纲与设定
    - 项目资料
    - 参考资产挂载
    - 导入源
    - 提取与审核
    - 导出与投影
  - 明确高级只读诊断层和主资源树的区别。
- 本轮不要做：
  - 不写 adapter 查询实现
  - 不改 UI 展示
  - 不处理 `.db` 渲染
- 验收标准：
  - 有稳定的投影与可见性合同，后续 adapters/app 可直接消费。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-09` 执行。先阅读本文档、`agent.md`、`docs/storage-dual-compatibility-design.md`、`packages/novel_agent_core/lib/src/project/`、`apps/novel_agent_app/lib/features/workbench/presentation/models/resource_entry_view_data.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_visibility_service.dart`。只做 SQLite 语义投影合同与可见性模型，冻结主语义树分组与高级只读诊断层边界。不要写 adapter 实现，不改 UI，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-10 SQLite 语义投影与可见性适配器实现

- 本轮目标：
  - 把 SQLite 项目的语义树与可见性模型落实到 adapters。
- 层级归属：
  - Adapters / persistence / projection
- 必读文件：
  - 本文档
  - `packages/novel_agent_adapters/lib/src/storage/sqlite_project_readable_projection_service.dart`
  - `packages/novel_agent_adapters/lib/src/storage/sqlite_project_content_repository.dart`
  - `packages/novel_agent_adapters/lib/src/storage/sqlite_project_body_text_store.dart`
  - `packages/novel_agent_adapters/lib/src/storage/sqlite_project_information_record_store.dart`
  - `packages/novel_agent_adapters/lib/src/storage/project_reference_projection_service.dart`
- 必须完成：
  - 实现 SQLite 项目语义投影构建服务。
  - 让 SQLite 项目不再只生成 `project_brief.md` 这一个可读入口。
  - 让投影节点能带：
    - 标题
    - 类型
    - 摘要
    - 来源身份
    - 真相源 identity
    - 是否只读投影
  - 补 focused tests 或 adapter tests：
    - 语义树节点能被构建
    - `.db` 不会被当作主工作树条目
- 本轮不要做：
  - 不改 widget
  - 不加数据库浏览器
  - 不碰项目类型转换
- 验收标准：
  - Adapter 层能为 SQLite 项目输出稳定语义树数据。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-10` 执行。先阅读本文档、`agent.md`、`packages/novel_agent_adapters/lib/src/storage/sqlite_project_readable_projection_service.dart`、`packages/novel_agent_adapters/lib/src/storage/sqlite_project_content_repository.dart`、`packages/novel_agent_adapters/lib/src/storage/sqlite_project_body_text_store.dart`、`packages/novel_agent_adapters/lib/src/storage/sqlite_project_information_record_store.dart`、`packages/novel_agent_adapters/lib/src/storage/project_reference_projection_service.dart`。只做 SQLite 语义投影与可见性适配器实现，并补 focused tests。不要改 widget，不做数据库浏览器，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-11 `knowledge_base` 与参考资产库对齐桥

- 本轮目标：
  - 在不重做提取主链的前提下，补齐 `knowledge_base` 的产品语义与应用级参考资产库的对齐桥。
- 层级归属：
  - Core / Adapters / shared workflow bridge
- 必读文件：
  - 本文档
  - `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
  - `packages/novel_agent_adapters/lib/src/storage/sqlite_reference_evidence_substrate.dart`
  - `packages/novel_agent_adapters/lib/src/storage/sqlite_project_reference_attachment_layer.dart`
  - `packages/novel_agent_adapters/lib/src/storage/project_reference_projection_service.dart`
  - `apps/novel_agent_app/lib/features/project_assets/application/services/project_reference_extraction_execution_service.dart`
- 必须完成：
  - 明确 `knowledge_base` 项目中哪些条目是：
    - 项目私有草稿资产
    - 待审核资产
    - 可提升到应用级资产库的正式资产
  - 让相关投影/摘要/标签使用统一文案：
    - 参考资产库
    - 项目资料挂载
    - 项目资料
  - 保证 `knowledge_base` 不再在产品面上被误导成“项目知识卡合集”。
  - 补 focused tests / projection tests 覆盖来源身份与状态分层。
- 本轮不要做：
  - 不重做 reference extraction runtime
  - 不扩充网络收集
  - 不做大规模 GUI 美化
- 验收标准：
  - `knowledge_base` 和 `ReferenceEvidenceSubstrate` 的关系在数据与文案层都清楚，且测试可验证。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-11` 执行。先阅读本文档、`agent.md`、`docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`、`packages/novel_agent_adapters/lib/src/storage/sqlite_reference_evidence_substrate.dart`、`packages/novel_agent_adapters/lib/src/storage/sqlite_project_reference_attachment_layer.dart`、`packages/novel_agent_adapters/lib/src/storage/project_reference_projection_service.dart`、`apps/novel_agent_app/lib/features/project_assets/application/services/project_reference_extraction_execution_service.dart`。只做 `knowledge_base` 与参考资产库对齐桥，明确资产状态分层、统一术语与投影来源。不要重做提取 runtime，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-12 项目创建链与 Launcher 收束

- 本轮目标：
  - 让 GUI 创建项目链准确消费新的能力矩阵。
- 层级归属：
  - App / GUI
- 必读文件：
  - 本文档
  - `apps/novel_agent_app/lib/features/workbench/application/services/project_launcher_view_data_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_create_panel.dart`
  - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_storage_strategy_option_tile.dart`
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- 必须完成：
  - `knowledge_base` 创建时只展示 SQLite 选项。
  - 创建链 UI 不再让用户看到一个实际不能提交的组合。
  - 文案收束：
    - `knowledge_base` 指向“资料知识库 / 参考资产治理”
    - 不再误导成普通写作壳
  - 补 GUI-focused tests 或 view data tests：
    - `knowledge_base` 只有 SQLite 选项
    - `novel / long_novel / book_deconstruction` 仍保留合法选项
- 本轮不要做：
  - 不接项目类型互转按钮
  - 不做资源树重构
  - 不做大型视觉翻新
- 验收标准：
  - GUI 创建链和 core 矩阵一致，不会暴露无效组合。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-12` 执行。先阅读本文档、`agent.md`、`apps/novel_agent_app/lib/features/workbench/application/services/project_launcher_view_data_service.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_create_panel.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_storage_strategy_option_tile.dart`、`apps/novel_agent_app/lib/app/state/app_shell_controller.dart`。只做项目创建链与 Launcher 收束，让 `knowledge_base` 只展示 SQLite，且文案对齐新定位，并补 focused tests。不要接互转按钮，不重做资源树，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-13 项目设置中的类型互转入口

- 本轮目标：
  - 为 `novel <-> long_novel` 接入受控的项目设置/工作台入口。
- 层级归属：
  - App / GUI
- 必读文件：
  - 本文档
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/workbench_project_panel_action_policy_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_project_panel_action_view_data.dart`
- 必须完成：
  - 新增受控的“项目类型转换”入口，只开放：
    - `novel -> long_novel`
    - `long_novel -> novel`
  - 在入口层展示拒绝原因：
    - 活跃长任务未归档
    - 缺少运行基准
    - 当前类型不支持转换
  - GUI 只消费 core 计划与错误原因，不自己判断。
  - 补 focused tests / controller tests。
- 本轮不要做：
  - 不做存储迁移 UI
  - 不开放 `knowledge_base` 互转
  - 不做复杂 wizard
- 验收标准：
  - 从 GUI 触发项目类型互转时，入口、校验、错误信息都来自同源 core 合同。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-13` 执行。先阅读本文档、`agent.md`、`apps/novel_agent_app/lib/app/state/app_shell_controller.dart`、`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/workbench_project_panel_action_policy_service.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_project_panel_action_view_data.dart`。只做项目设置中的类型互转入口，让 GUI 只消费 core 合同与错误原因，并补 focused tests。不要做存储迁移 UI，不开放 `knowledge_base` 互转，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-14 SQLite 工作台语义树与文档渲染切换

- 本轮目标：
  - 让 SQLite 项目在工作台里真正按语义树工作，而不是按 `.db` 文件工作。
- 层级归属：
  - App / GUI
- 必读文件：
  - 本文档
  - `apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_visibility_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_display_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart`
  - `apps/novel_agent_app/lib/features/workbench/presentation/renderers/document_resource_renderer_resolver.dart`
  - `apps/novel_agent_app/lib/features/workbench/presentation/renderers/document_structured_resource_renderer.dart`
  - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_tree_card.dart`
- 必须完成：
  - SQLite 项目资源树优先显示语义节点，不把 `.db` 暴露成主入口。
  - `DocumentResourceRendererResolver` 不再把 `.db/.sqlite` 当作正常工作流的 preview-like 主资源。
  - 对 SQLite 投影节点优先走 structured/resource projection 渲染。
  - 让条目展示：
    - 摘要
    - 来源身份
    - 真相源标签
    - 只读投影状态
  - 补 GUI-focused tests / view data tests。
- 本轮不要做：
  - 不做数据库浏览器
  - 不扩大成全局资源树大改版
  - 不补 unrelated UI polish
- 验收标准：
  - 打开 SQLite 项目时，用户首先看到的是语义内容，而不是 `.db` 文件。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-14` 执行。先阅读本文档、`agent.md`、`apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_visibility_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_display_service.dart`、`apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/renderers/document_resource_renderer_resolver.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/renderers/document_structured_resource_renderer.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_tree_card.dart`。只做 SQLite 工作台语义树与文档渲染切换，并补 focused tests。不要做数据库浏览器，不做无关 UI 翻新，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-15 Focused Tests、CLI 兼容审计与回归补缝

- 本轮目标：
  - 收口本主线的 focused tests、兼容测试和最小 CLI 审计。
- 层级归属：
  - Tests / regression / minimal CLI compatibility
- 必读文件：
  - 本文档
  - `packages/novel_agent_core/test/`
  - `packages/novel_agent_adapters/test/`
  - `apps/novel_agent_app/test/`
  - `apps/novel_agent_cli/`
- 必须完成：
  - 检查并补齐：
    - 项目类型矩阵 tests
    - 项目类型互转 tests
    - sqlite 项目工具暴露 / prompt contract / dispatcher tests
    - SQLite 语义树/可见性 tests
    - `knowledge_base` sqlite-only tests
  - 审计 CLI：
    - 若 CLI 已消费 create/open project 主链，应保证新矩阵不破坏 CLI
    - 若 CLI 没有项目类型互转入口，则不在本轮扩功能，只做兼容确认
  - 修复本主线引入的 focused regression。
- 本轮不要做：
  - 不做新的 CLI 产品功能
  - 不开新 probe 体系
  - 不做大规模重构
- 验收标准：
  - 相关 tests 通过，CLI 至少不被新合同破坏。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-15` 执行。先阅读本文档、`agent.md`、`packages/novel_agent_core/test/`、`packages/novel_agent_adapters/test/`、`apps/novel_agent_app/test/`、`apps/novel_agent_cli/`。只做本主线 focused tests、CLI 最小兼容审计与回归补缝。不要扩新的 CLI 产品功能，不开新 probe 体系，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## SPT-16 高保真 ViewModel 探针、验收与交接收口

- 本轮目标：
  - 用高保真 ViewModel 路径验证这条主线真能用，并收口文档与交接。
- 层级归属：
  - Probe / regression / documentation / handoff
- 必读文件：
  - 本文档
  - `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md`
  - `docs/important/high-fidelity-viewmodel-validation-analysis-2026-06-10.md`
  - `apps/novel_agent_app/tool/`
- 必须完成：
  - 新增或复用同源 ViewModel harness，验证：
    - 创建 `knowledge_base` 项目时只能选 SQLite
    - 创建普通小说 `sqlite_project_store` 项目时，至少能真实写入并回读一章正文
    - 同一条普通小说 sqlite 路径下，智能体拿到的是 storage-aware 工具面，而不是误导性的 Markdown/file-tree first 默认工具面
    - 打开 SQLite 项目时资源树走语义视图而不是 `.db`
    - `novel -> long_novel` 互转路径可用
    - `long_novel -> novel` 在活跃长任务时能给出正确拒绝理由
  - 报告必须区分：
    - technical failure
    - product flow failure
    - validation failure
    - waiting user / blocked external
  - 更新主线文档或 handoff，说明已完成项与残留项。
- 本轮不要做：
  - 不开新功能线
  - 不做题材型写作 probe
  - 不把 probe 变成第二套业务中心
- 验收标准：
  - 有真实 ViewModel 级证据证明本主线可用，并有清楚的收尾记录。
- 直接可用提示词：
  - 按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 `SPT-16` 执行。先阅读本文档、`agent.md`、`docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md`、`docs/important/high-fidelity-viewmodel-validation-analysis-2026-06-10.md`、`apps/novel_agent_app/tool/`。只做高保真 ViewModel 探针、验收与交接收口，验证 `knowledge_base` sqlite-only、普通小说 SQLite 正文可写可回读、SQLite 语义树、`novel <-> long_novel` 互转路径。不要开新功能线，不做题材型写作 probe，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

---

## 9. 总启动提示词

```text
你现在要按 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 逐个 session 执行 SQLite 项目可见性、knowledge_base 对齐与项目类型互转主线。

执行规则：

1. 先阅读：
   - `agent.md`
   - `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md`
   - 当前 session 指定的必读文件
2. 每次只做一个 session。
3. 不开启下一个 session。
4. 优先复用现有 core / adapters / app 合同，不新造平行 runtime。
5. 不把业务判断堆进 widget、controller、probe 或 CLI。
6. 不把“项目类型转换”和“存储迁移”混成一个功能。
7. `knowledge_base` 本轮必须保持 sqlite-only。
8. 普通项目 SQLite 本轮必须先补真实主事实源与正文写穿，不要只做外观可见性。
9. sqlite 项目的工具暴露、dispatcher 和 prompt contract 必须 storage-aware；不要继续把 file-tree first 工具面当默认主路径。
10. `novel <-> long_novel` 本轮只做同存储策略内的项目类型互转。
11. focused tests / contract tests 与实现同轮落地。
12. 如果发现上一个 session 的尾项没收好，先收好再继续当前 session。
13. 如果当前 session 做完，停止，不继续下一任务，并汇报：
    - 改了什么
    - 哪些测试已跑
    - 是否满足验收标准
    - 是否存在阻塞

你是 `gpt-5.4-mini`，所以尤其注意：

- 不要推测未读代码
- 不要把多个 session 糊成一轮
- 不要顺手做下一步
- 不要为了图快写大而全文件
- 不要在 GUI 层偷偷补第二套真相
```

---

## 9.1 恢复规则（CTC 主线已落地后）

这条规则专门用于解决一个已经出现过的“假阻塞”：

```text
上下文压缩 / token / compaction 主线（CTC）已经完成并进入提交历史，
但 SQLite 主线在恢复时，仍把 app/workbench 相关脏文件误判成“外部并行冲突”，
导致明明应该继续做 SPT-15 / SPT-16，却一直原地等待。
```

当前冻结判断：

1. 如果 `git log --oneline -5` 中已经出现：
   - `d6d678a feat: finalize ctc context pressure mainline`
2. 且当前没有新的、明确来自另一条未收口主线的并行任务说明

那么后续恢复 SQLite 主线时，必须采用下面这条更精确的判断：

1. `app_shell_controller.dart`
2. `workbench_workspace_controller.dart`
3. `project_launcher_view_data_service.dart`
4. `workspace_information_projection_service.dart`
5. `workspace_resource_visibility_service.dart`
6. `document_resource_renderer_resolver.dart`
7. 以及它们所对应的 workbench / renderer / sidebar / visual regression tests

即使当前仍是脏文件，也不能再仅凭“dirty”这个事实，就自动判定为外部冲突。

因为在 CTC 已收口后，这些文件更高概率代表的是：

1. SQLite 主线自己在 `SPT-12 ~ SPT-16` 阶段形成的未提交工作
2. 需要继续被当前恢复 run 读入、对齐和收口的“当前真相”

恢复时必须这样判断：

1. 先读当前文件内容，把它们视为最新 production truth。
2. 再判断 `SPT-15` / `SPT-16` 的回归、golden、ViewModel harness 是否需要跟随当前真相更新。
3. 不要因为这些文件仍是 dirty，就自动等待。

只有在下面两种情况下，才允许继续判定阻塞：

1. 明确存在另一条尚未收口、且仍在实时改动这些同一文件的并行主线。
2. 在当前恢复 run 内，发现这些文件在你未修改的情况下持续变化，足以证明存在外部并发写入。

换句话说：

```text
CTC 已落地后，
“dirty app/workbench files”
不再是 SQLite 主线恢复到 SPT-15 / SPT-16 的充分阻塞条件。
```

SQLite 主线恢复时，新的默认策略应是：

1. 读当前 app/workbench 真相
2. 对齐回归与 golden
3. 完成 SPT-15
4. 再进入 SPT-16

而不是继续无限等待一个已经完成的并行主线。

---

## 10. Session 完成记录占位

- `SPT-01`：已完成。冻结矩阵为 `novel / long_novel / book_deconstruction` 保持双策略，`knowledge_base` 收束为 `sqlite_project_store` only，第一阶段类型转换图仅保留 `novel <-> long_novel`，并明确 `类型转换 != 存储迁移`。
- `SPT-02`：已完成。`knowledge_base` 在 core 层收束为 `sqlite_project_store` only，并补了创建归一化与旧 manifest 兼容测试。
- `SPT-03`：已完成。补齐 `ProjectTypeTransitionPolicy / Request / Plan / Blocker`，冻结 `novel <-> long_novel` 第一阶段转换图，并补了允许/拒绝测试。
- `SPT-04`：已完成。补齐 `ProjectTypeTransitionPreparationService` 与 `ExecuteProjectTypeTransitionUseCase`，支持 `novel <-> long_novel` 的执行链并保持原存储策略不变。
- `SPT-05`：已完成。补齐普通项目 SQLite 主事实源合同、正文仓储接口与正文/工作区策略，明确 markdown 主项目与 sqlite 主项目的正文边界，并补 focused tests。
- `SPT-06`：
- `SPT-07`：
- `SPT-08`：
- `SPT-09`：
- `SPT-10`：
- `SPT-11`：
- `SPT-12`：
- `SPT-13`：
- `SPT-14`：
- `SPT-15`：
- `SPT-16`：

---

## 11. 生成后自检结论

1. 已明确“这份文档解决什么”。
2. 已说明与旧文档和旧分析的关系。
3. 已做已有实现去重审计，指出哪些已有、哪些半成品、真正缺哪几层。
4. 已冻结架构边界。
5. 已给出目标终态。
6. 已覆盖本轮分析中的全部核心目标：
   - `knowledge_base` sqlite-only
   - 普通项目 SQLite 真实主事实源
   - sqlite 项目 storage-aware tool surface
   - `knowledge_base` 与 `ReferenceEvidenceSubstrate` 对齐
   - SQLite 项目语义可见
   - `novel <-> long_novel` 类型互转
   - 类型转换与存储迁移拆开
7. 顺序遵守了：
   - core 合同
   - use case
   - adapters
   - GUI
   - tests / probes / handoff
8. 每个 session 都是单会话可完成任务，没有把 GUI/CLI 提前拿来补底层缺口。
9. 每个 session 都包含：
   - 本轮目标
   - 层级归属
   - 必读文件
   - 必须完成
   - 本轮不要做
   - 验收标准
   - 可直接复制的提示词
10. 已包含总启动提示词与完成记录占位。

---

## 12. 目标模式恢复提示词（CTC 已提交后）

```text
你现在恢复执行 `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md` 的 SQLite 主线，但要先应用其中的“9.1 恢复规则（CTC 主线已落地后）”。

恢复前先执行并确认：

1. 读取：
   - `agent.md`
   - `docs/sqlite-project-visibility-and-type-transition-session-order-2026-06-14.md`
   - `docs/important/sqlite-project-visibility-and-type-transition-analysis-2026-06-14.md`
2. 执行：
   - `git log --oneline -5`
   - `git status --short`
3. 如果日志里已经有：
   - `d6d678a feat: finalize ctc context pressure mainline`
   则视为 CTC 主线已经收口。

恢复判断规则：

1. 不要再把下面这些 dirty 文件自动判定成外部并行阻塞：
   - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
   - `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
   - `apps/novel_agent_app/lib/features/workbench/application/services/project_launcher_view_data_service.dart`
   - `apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart`
   - `apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_visibility_service.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/renderers/document_resource_renderer_resolver.dart`
   - 以及相关 workbench / renderer / sidebar / visual regression tests
2. 在 CTC 已提交后，这些文件默认视为 SQLite 主线当前 production truth 的一部分。
3. 你必须直接读取这些文件的当前内容，并基于当前内容继续完成 `SPT-15` 和 `SPT-16`。
4. 只有在你发现“同一批文件在当前 run 中持续被外部再次改动”时，才允许重新判定阻塞。

执行目标：

1. 从 `SPT-15` 开始恢复。
2. 先统一修复和更新：
   - `workbench_left_sidebar_compact_height_test.dart`
   - `workbench_rc13_regression_test.dart`
   - `workbench_sr14_visual_regression_test.dart`
   - 以及任何直接依赖当前 workbench 壳层语义的相关回归 / golden
3. 跑 `SPT-15` 需要的 focused tests，直到通过。
4. 然后继续 `SPT-16`，完成 ViewModel 级探针、验收与文档收口。

严格限制：

1. 不能新造第二套 app 壳层真相。
2. 不能为了省事回退当前 workbench 语义去迎合旧测试。
3. 只能让测试、golden、ViewModel harness 对齐当前 production truth。
4. 如果发现确实是外部并发写入，而不是当前 SQLite 主线自己的未提交改动，再报告阻塞。

完成每个 session 后，汇报：

1. session 编号
2. 修改文件
3. 测试结果
4. 是否进入下一 session
5. 若阻塞，给出“当前 run 内发现的实时外部并发证据”，不要只说文件是 dirty
```
