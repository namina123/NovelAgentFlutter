# 拆书主链迁移边界冻结清单

日期：2026-06-15

对应主线：`BDCM` / `Book Deconstruction Core Migration`

关联主文档：

- `docs/book-deconstruction-core-migration-session-order-2026-06-15.md`
- `docs/important/project-unreasonable-areas-audit-2026-06-15.md`
- `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md`
- `docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md`
- `agent.md`

---

## 1. 这份清单解决什么

这份清单只做一件事：把拆书主链在 `core / adapters / workflow / app` 之间的职责边界冻结下来，作为后续 `BDCM-02` 到 `BDCM-08` 的统一执行基线。

它不是实现方案，也不是最终设计稿，而是后续每轮迁移时的“裁判标准”。

---

## 2. 当前已经确认的正式出口

以下能力已经具备正式出口雏形，后续优先复用，而不是重新造一套平行实现。

### 2.1 Core 侧正式合同

- `BookDeconstructionInput`
- `BookDeconstructionSourceDocument`
- `BookDeconstructionApplicationPlanBuilderService`
- `BookDeconstructionNarrativeBridgeService`
- `BookDeconstructionInformationBridgeService`
- `BookDeconstructionFollowupMenuBuilderService`
- `BookDeconstructionTargetPathService`

这些对象已经承担了正式合同、派生结果或稳定路径推导职责。

### 2.2 Shared import / source contract

- `SourceImportRequest`
- `SourceImportSelection`
- `SourceImportNormalizedDocument`
- `SourceImportNormalizationService`
- `SourceImportDiscoveryService`
- `SourceImportPathScannerService`
- `SourceDocumentFormatCatalogService`
- `SourceDocumentTextReaderService`
- `SourceDocumentEpubReaderService`

这些能力是拆书主链的共享来源底座，不属于拆书 app 私有逻辑。

### 2.3 App 侧保留的正式消费口

- `BookDeconstructionController`
- `BookDeconstructionViewDataService`
- `BookDeconstructionDraftBuilderService`

它们可以继续存在，但职责必须收缩到输入收集、状态管理、正式 use case 调用和纯投影。

---

## 3. 必须迁出的逻辑

以下逻辑不允许继续留在 `BookDeconstructionDraftBuilderService` 或 `BookDeconstructionController` 里作为事实源。

### 3.1 纯业务逻辑

- 标题推断
- 媒体类型判断
- 章节切分
- 总纲摘要归纳
- 前提构造
- 抽取结果拼装
- followup 菜单语义构造

这些都必须进入 `core`，并拆成职责明确的小服务，而不是把 app 层的大块逻辑原样搬过去。

### 3.2 导入 / 归档 / 路径编排

- 来源文件发现
- 文件读取
- 原文归档
- 目标路径推导
- 预演写入路径选择
- 归档后刷新与资源同步编排

这些必须迁到 `adapters / workflow`，controller 只负责触发正式流程。

### 3.3 ViewData 里的业务真相再创造

- continuation / fanfic 语义解释
- followup route 的正式路线判断
- 资产状态的业务来源判断

`BookDeconstructionViewDataService` 只能投影上游结果，不能自己补业务真相。

---

## 4. 可以留在 App 的内容

以下内容可以保留在 app 层，但只能作为壳层职责存在。

- 用户输入收集
- 当前项目读取
- 嵌入式状态快照
- 表单字段变更
- 预览选择状态
- 已有 use case / workflow 的调用
- 结果到 view data 的投影
- 交互提示文案

一句话：app 可以告诉用户“发生了什么”，但不应该自己决定“这件事本身是什么”。

---

## 5. 本轮正式新出口候选

后续实现时，优先把正式出口固定成下面几类。

### 5.1 共享来源解析出口

职责：

- 文件 / 目录发现
- 多格式识别
- 标准化 source document 产出
- 原始来源元数据保留

归属：

- `adapters / storage`
- `core / imports`

### 5.2 拆书预演正式 use case

职责：

- 接收标准化输入
- 汇总抽取结果
- 构造应用计划
- 构造 narrative / information 结果
- 产出正式的 draft build result

归属：

- `core / workflow`

### 5.3 导入 / 归档 workflow service

职责：

- 读取来源
- 归档原文
- 预演纪要写入
- 结果同步
- 路径编排

归属：

- `adapters / workflow`

### 5.4 Projection-only view data service

职责：

- 把正式结果投影成 UI 可读结构
- 不再补业务判断

归属：

- `app / presentation`

---

## 6. 冻结后的迁移顺序

后续 `BDCM` 的推进顺序保持如下：

1. `BDCM-02` 先把纯业务逻辑抽进 `core`。
2. `BDCM-03` 再建立正式预演结果 use case。
3. `BDCM-04` 再收口导入 / 归档 / 路径编排。
4. `BDCM-05` 再瘦 controller。
5. `BDCM-06` 再瘦 view data service。
6. `BDCM-07` 和 `BDCM-08` 负责回归、收尾和文档补齐。

这个顺序不能倒，因为它对应的是“先立真相，再削壳层”的依赖方向。

---

## 7. `BDCM-01` 验收口径

如果后续某轮要判断当前边界是否仍然成立，只检查这几件事：

1. app 层有没有重新长出标题推断、媒体判断、章节切分、摘要归纳。
2. controller 有没有重新承担导入 / 归档 / 路径主编排。
3. view data service 有没有重新变成业务语义解释器。
4. core 里的正式出口是否仍然清晰、单一、可复用。
5. adapters / workflow 是否已经承担来源发现、读取、归档和路径编排。

只要这五条仍然成立，这份边界冻结就仍然有效。

