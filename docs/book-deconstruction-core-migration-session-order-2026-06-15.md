# NovelAgentFlutter 拆书主链迁移到 Core / Adapters 任务顺序文档

最后更新：2026-06-15

主线代号：`BDCM`（Book Deconstruction Core Migration）

关联依据：

- `docs/important/project-unreasonable-areas-audit-2026-06-15.md`
- `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md`
- `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`

关联当前问题锚点：

- `apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`
- `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart`
- `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart`
- `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart`
- `packages/novel_agent_core/lib/src/deconstruction/`
- `packages/novel_agent_adapters/lib/src/storage/reference_source_document_file_reader_service.dart`

---

## 1. 这份文档解决什么

这份文档只解决一件事：

**把目前仍然误压在 GUI / app 层的拆书业务主链，迁回 core / adapters / workflow 的正式位置。**

当前拆书虽然已经有一部分进入 `packages/novel_agent_core/lib/src/deconstruction/`，但仍存在明显的 app 层越权：

1. `BookDeconstructionDraftBuilderService` 在 app 层直接做：
   - 源标题推断
   - 媒体类型判断
   - 章节切分
   - 总纲摘要
   - 前提构造
   - 抽取结果拼装
   - followup 菜单拼装前置
2. `BookDeconstructionController` 在 app 层直接决定：
   - 导入后如何归档
   - 预演前哪些字段进入正式拆书输入
   - 预览如何失效、如何重建
3. `BookDeconstructionViewDataService` 不只是 view mapping，也掺了较重的 followup 语义解释与路线状态拼装。

这意味着现在的拆书主链还不是：

```text
GUI 收集输入
-> core/adapters 构建正式拆书请求
-> workflow 产出正式结果
-> app 只负责投影和交互
```

而更像：

```text
GUI/application service 自己先做半套业务判断
-> 再把结果塞给 core
-> 再在 app 层继续解释一轮
```

这就是需要迁移的根因。

---

## 2. 当前判断

### 2.1 拆书没有“完全写错层”，但确实还没迁完

当前不是说拆书完全不在 core。

已经在 core 的部分包括：

1. `BookDeconstructionInput`
2. `BookDeconstructionSourceDocument`
3. `BookDeconstructionNarrativeBridgeService`
4. `BuildBookDeconstructionApplicationPlanUseCase`
5. followup option / derived project plan 等一部分模型和服务

但 app 层仍承担了太多“真正的拆书前处理和业务拼装”。

### 2.2 最明显的错位点

#### A. `BookDeconstructionDraftBuilderService`

它名义上在 app/application 层，但现在实际上承担的是“拆书预演构建器”，这是业务中心，不是 GUI 薄层。

#### B. `BookDeconstructionController`

它现在不只是控制交互，还掺了导入归档编排、拆书输入构造触发、预览失效策略。

#### C. `BookDeconstructionViewDataService`

它本来应该保留在 app 层，但目前内部有一部分 continuation / fanfic / shared information 的路线语义是硬编码解释，这部分应更多来自 core/workflow 结果，而不是 view service 自己再解释。

---

## 3. 迁移原则

1. 纯业务判断迁到 `core`。
2. 文件读取、来源发现、归档写入、路径转换迁到 `adapters`。
3. 多步业务编排迁到 `workflow/runtime` 或 use case。
4. `app` 层只保留：
   - 用户输入收集
   - 调用正式 use case / workflow service
   - 状态管理
   - view data projection
5. `view data service` 可以留在 app，但只能做 projection，不能再补业务真相。
6. 迁移时不能只是把大文件从 app 剪切到 core；要按职责拆成多个小服务。

---

## 4. 目标终态

完成迁移后，应达到：

1. app 层不再直接做章节切分、总纲摘要、标题推断、抽取结果拼装。
2. 导入后的归档、路径、来源文档标准化由 adapters / workflow 正式处理。
3. 拆书预演结果由 core/workflow 直接产出，app 只消费结果。
4. continuation / fanfic / shared information 的正式语义来自 core 结果模型，而不是 view service 自行脑补。
5. `BookDeconstructionController` 显著变薄。
6. 拆书链可被普通 probe、GUI probe、未来 CLI 消费，而不会依赖 app 私有逻辑。

---

## 5. Session 数量与顺序设计理由

本主线拆成 `8` 个 session。

顺序理由：

1. 先冻结“哪些逻辑必须迁、哪些可以留在 app”。
2. 再先抽 core 的纯逻辑。
3. 再抽 adapters 的来源读取/归档/路径编排。
4. 再建立 workflow/use case 编排层。
5. 最后再瘦 controller 和 view data service。

---

## 6. Session 设计

## BDCM-01 拆书职责边界冻结

- 本轮目标：
  冻结拆书链在 `core / adapters / workflow / app` 的职责边界。
- 层级归属：
  `Documentation / architecture`
- 必读文件：
  - 本文档
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart`
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`
  - `packages/novel_agent_core/lib/src/deconstruction/`
- 必须完成：
  1. 标出哪些逻辑必须迁出 app。
  2. 标出哪些逻辑可以留在 app。
  3. 固定正式新出口候选。
- 本轮不要做：
  1. 不改 GUI。
  2. 不开始大搬代码。
- 验收标准：
  1. 有一份清晰迁移清单，可直接指导后续实现。

## BDCM-02 源文稿标准化与轻量抽取逻辑迁入 core

- 本轮目标：
  将标题推断、媒体类型、章节切分、摘要归纳等纯逻辑从 `BookDeconstructionDraftBuilderService` 抽到 core。
- 层级归属：
  `Core / domain`
- 必读文件：
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart`
  - `packages/novel_agent_core/lib/src/deconstruction/`
- 必须完成：
  1. 抽出小而清晰的 pure services。
  2. 让 app 层不再拥有这些算法。
  3. 补 focused tests。
- 本轮不要做：
  1. 不处理归档写入。
  2. 不改 controller。
- 验收标准：
  1. app 层 builder 不再直接实现这些纯逻辑。

## BDCM-03 拆书预演结果构造 use case

- 本轮目标：
  建立正式的 core/workflow use case 来产出 `BookDeconstructionDraftBuildResult` 所需结果。
- 层级归属：
  `Core / workflow`
- 必读文件：
  - `BookDeconstructionDraftBuildResult`
  - `BuildBookDeconstructionApplicationPlanUseCase`
  - `BookDeconstructionNarrativeBridgeService`
- 必须完成：
  1. 用正式 use case 串起输入、抽取、application plan、narrative artifacts、followup menu。
  2. app 层只调用 use case。
- 本轮不要做：
  1. 不改 view data。
  2. 不改导入 UI。
- 验收标准：
  1. 拆书预演主结果由 core/workflow 正式产出。

## BDCM-04 来源读取、归档与目标路径编排迁入 adapters/workflow

- 本轮目标：
  收口拆书导入后的文件读取、归档、目标路径编排。
- 层级归属：
  `Adapters / workflow`
- 必读文件：
  - `ReferenceSourceDocumentFileReaderService`
  - `BookDeconstructionTargetPathService`
  - `BookDeconstructionController`
- 必须完成：
  1. 将归档写入编排尽量从 controller 中抽离。
  2. 建立正式 import/archive workflow service。
  3. 补 focused/integration tests。
- 本轮不要做：
  1. 不做 followup 分流。
  2. 不做 UI polish。
- 验收标准：
  1. controller 不再直接承担导入归档主编排。

## BDCM-05 Controller 瘦身

- 本轮目标：
  让 `BookDeconstructionController` 回到状态管理和动作转发职责。
- 层级归属：
  `App / application`
- 必读文件：
  - `book_deconstruction_controller.dart`
  - 前几轮新抽出的 services/use cases
- 必须完成：
  1. controller 只做输入收集、状态推进、调用正式服务。
  2. 清掉最重的业务拼装。
- 本轮不要做：
  1. 不做视觉改版。
  2. 不回写 core 新判断。
- 验收标准：
  1. controller 行数与职责都显著下降。

## BDCM-06 ViewDataService 去语义硬编码

- 本轮目标：
  保留 view data projection，但移除不该由 app 层再解释的业务语义。
- 层级归属：
  `App / presentation projection`
- 必读文件：
  - `book_deconstruction_view_data_service.dart`
  - core 中 followup / route / artifact 结果模型
- 必须完成：
  1. 把 continuation / fanfic / shared information 的正式状态尽量改成消费上游结果。
  2. 保留纯展示文案映射。
- 本轮不要做：
  1. 不新造第二套结果模型。
  2. 不做 UI 主题优化。
- 验收标准：
  1. view data service 主要做 projection，而不是语义再创造。

## BDCM-07 GUI 与 probe 回归收口

- 本轮目标：
  确保 GUI 和 probe 都消费迁移后的正式主链。
- 层级归属：
  `App / Probe / regression`
- 必读文件：
  - `apps/novel_agent_app/test/book_deconstruction_*`
  - `apps/novel_agent_app/tool/real_gui_book_deconstruction_import_probe.dart`
- 必须完成：
  1. 调整测试到新主链。
  2. 验证没有回退到 app 私有逻辑。
- 本轮不要做：
  1. 不继续重构无关工作台。
- 验收标准：
  1. 迁移后 GUI 与 probe 仍然通过。

## BDCM-08 文档与残留口收口

- 本轮目标：
  收口迁移记录、残留风险和下一阶段入口。
- 层级归属：
  `Documentation / handoff`
- 必读文件：
  - 本文档
  - 本次迁移中新增测试与实现
- 必须完成：
  1. 更新完成记录。
  2. 记录仍未迁出的合理残留。
- 本轮不要做：
  1. 不再大改生产代码。
- 验收标准：
  1. 下个会话能直接接力，不需重新分析。

---

## 7. 总启动提示词

```text
根据 `docs/book-deconstruction-core-migration-session-order-2026-06-15.md`，从最早未完成的 `BDCM` session 开始，一次只做一个 session。

要求：

1. 只迁移拆书主链错层逻辑，不顺手扩写其他模块。
2. 纯业务逻辑迁到 core，文件读取/归档/路径迁到 adapters/workflow，app 只保留状态与投影。
3. 不允许把 app 层的重逻辑整体原样剪切到一个更大的 core 文件里，必须按职责拆分。
4. 每轮都补 focused tests，必要时补 integration/probe。
5. 完成一个 session 后，如果达到验收标准，就更新记录并继续下一个，直到全部完成或遇到明确阻塞。
```

---

## 8. 完成记录占位

- `BDCM-01`：
- `BDCM-02`：
- `BDCM-03`：
- `BDCM-04`：
- `BDCM-05`：
- `BDCM-06`：
- `BDCM-07`：
- `BDCM-08`：
