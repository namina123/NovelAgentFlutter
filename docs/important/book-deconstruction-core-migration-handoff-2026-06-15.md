# 拆书主链迁移交接摘要

日期：2026-06-15

主线：`BDCM` / `Book Deconstruction Core Migration`

关联文档：

- `docs/book-deconstruction-core-migration-session-order-2026-06-15.md`
- `docs/important/book-deconstruction-core-migration-boundary-map-2026-06-15.md`
- `docs/important/project-unreasonable-areas-audit-2026-06-15.md`
- `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md`
- `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`

---

## 1. 已完成范围

`BDCM-01` 到 `BDCM-07` 已按顺序完成。

### 1.1 边界冻结

- 已明确 app 层必须迁出的纯业务逻辑。
- 已明确可以留在 app 的输入收集、状态管理和投影职责。
- 已冻结 core / adapters / workflow 的正式出口候选。

### 1.2 Core 纯逻辑迁移

- 标题推断迁入 `BookDeconstructionSourceTextMetadataService`。
- 媒体类型识别迁入 `BookDeconstructionSourceTextMetadataService`。
- 章节切分、总纲摘要和前提摘要迁入 `BookDeconstructionSourceTextOutlineService`。
- 风格、世界规则、角色和组织的轻量提取迁入 `BookDeconstructionSourceTextProfileService`。

### 1.3 正式预演 use case

- 拆书预演正式收束到 `BuildBookDeconstructionDraftUseCase`。
- `BookDeconstructionDraftBuildResult` 已迁入 core，app 侧只做薄壳转发。

### 1.4 导入 / 归档 workflow

- 新增 `BookDeconstructionImportArchiveWorkflowService`。
- controller 导入分支已改为调用正式 workflow，不再自己拼接读文件与归档写入。

### 1.5 Controller / ViewData / GUI / Probe

- controller 已移除导入归档专属依赖。
- controller 已移除预演确认写入主编排，确认链改为调用独立 workflow service。
- view data service 现以 core 的 followup menu 作为路线投影来源。
- GUI 和 real probe 仍然通过正式主链通过回归。

---

## 2. 当前正式出口

### 2.1 Core

- `BuildBookDeconstructionDraftUseCase`
- `BookDeconstructionSourceTextMetadataService`
- `BookDeconstructionSourceTextOutlineService`
- `BookDeconstructionSourceTextProfileService`
- `BookDeconstructionApplicationPlanBuilderService`
- `BookDeconstructionFollowupMenuBuilderService`
- `BookDeconstructionNarrativeBridgeService`
- `BookDeconstructionTargetPathService`

### 2.2 Adapters / workflow

- `ReferenceSourceDocumentFileReaderService`
- `BookDeconstructionImportArchiveWorkflowService`

### 2.3 App projection

- `BookDeconstructionController`
- `BookDeconstructionDraftBuilderService`
- `BookDeconstructionViewDataService`
- `BookDeconstructionPreviewMarkdownService`

---

## 3. 残留风险

这些风险已登记，但不属于高风险未登记残留。

1. `BookDeconstructionViewDataService` 仍保留少量展示文案和 UI 路线投影。
2. real probe 仍依赖本地开闸和 `local/probe_api.txt`。

---

## 4. 下一阶段入口

如果后续继续推进，建议优先顺序如下：

1. 继续检查 GUI / probe 的真实消费链，避免新增旁路。
2. 如果需要继续瘦 controller，优先继续清理纯交互状态重复或把更多壳层动作统一到薄 workflow service。
3. 若需要更强的拆书提取，可在 core 侧继续扩展正式抽取服务，但保持 use case 为唯一编排入口。

---

## 5. 交接结论

本次拆书主链迁移的正式事实源已经收敛到 core / adapters / workflow。

后续新会话可以直接从这份摘要和 session 顺序文档接力，不需要重新分析边界。
