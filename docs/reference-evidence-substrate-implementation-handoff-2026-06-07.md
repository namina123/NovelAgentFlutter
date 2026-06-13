# 参考证据基座实现交接

日期：2026-06-07

关联依据：

- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-goal-prompt-2026-06-07.md`

---

## 1. 本轮已正式落地的骨架

本轮已经在当前仓库中正式落地下面三层的最小主链：

1. `ReferenceEvidenceSubstrate`
   - 应用级参考证据基座
   - core 合同位于：
     - `packages/novel_agent_core/lib/src/reference_substrate/*`
     - `packages/novel_agent_core/lib/src/ports/reference_evidence_substrate.dart`
   - SQLite adapter 位于：
     - `packages/novel_agent_adapters/lib/src/storage/sqlite_reference_evidence_substrate.dart`
     - `packages/novel_agent_adapters/lib/src/storage/reference_substrate_database_*`

2. `ProjectReferenceAttachmentLayer`
   - 项目参考挂载层
   - core 合同位于：
     - `packages/novel_agent_core/lib/src/reference_substrate/reference_access_models.dart`
     - `packages/novel_agent_core/lib/src/ports/project_reference_attachment_layer.dart`
   - SQLite adapter 位于：
     - `packages/novel_agent_adapters/lib/src/storage/sqlite_project_reference_attachment_layer.dart`
     - `packages/novel_agent_adapters/lib/src/storage/project_reference_attachment_database_*`

3. `ProjectInformationCapabilityLayer`
   - 继续复用现有：
     - `ProjectKnowledgeCard`
     - `DesignElementCard`
     - `ResearchNote`
     - `ReferenceWorkRecord`
   - 未做强迁移，仍然保持项目级 JSON 事实源 + Markdown 投影。

---

## 2. 已落地的核心合同

### 2.1 应用级 package / version / entry identity

已新增：

1. `ReferencePackageRecord`
2. `ReferencePackageVersionRecord`
3. `ReferenceEntryRecord`
4. `ReferenceDependencyRecord`
5. `ReferencePromotionRecord`
6. `ReferencePackageSnapshot`

它们共同承担：

1. package / version / entry 的逻辑独立 identity
2. promotion 审计轨迹
3. dependency 留口
4. 应用级到 bundle 的稳定载体

### 2.2 项目挂载与权限合同

已新增：

1. `ProjectReferenceAttachment`
2. `ProjectReferenceAccessRequest`
3. `ProjectReferenceAccessDecision`
4. `ProjectReferenceAccessPolicyService`

已固化的权限判断：

1. 智能体默认只能消费已挂载 package
2. `summary_only` 不能投影到项目知识层
3. `projectable` 才能做应用级到项目级投影
4. `manager` + `allows_promotion` 才能承接 promotion 级操作
5. `requires_confirmation` 会卡住需要显式确认的操作

### 2.3 bundle contract

已新增：

1. `ReferenceBundleManifest`
2. `ReferenceBundleDocument`
3. `ReferenceBundleExportRequest`
4. `ReferenceBundleImportResult`

并在 adapter 中落了目录合同：

1. `manifest.json`
2. `payload/package.json`
3. `payload/version.json`
4. `payload/entries.json`
5. `payload/dependencies.json`
6. `payload/promotions.json`
7. `projections/summary.md`
8. `attachments/README.md`
9. `integrity/checksums.json`

这意味着当前已经不是“只能存在运行时 SQLite 里”，而是具备了 bundle 化导入导出主链。

---

## 3. 已落地的主链服务

### 3.1 应用级参考包 -> 项目知识能力层

服务：

- `ProjectReferenceProjectionService`

职责：

1. 先检查项目挂载层
2. 走 `ProjectReferenceAccessPolicyService`
3. 从 `ReferenceEvidenceSubstrate` 读取 snapshot
4. 用 `ReferenceEntryProjectionMapperService` 把 entry 映射为：
   - `ProjectKnowledgeCard`
   - `DesignElementCard`
   - `ResearchNote`
   - `ReferenceWorkRecord`
5. 写回现有项目级 JSON 仓储
6. 调 `ProjectInformationProjectionWriterService` 重建可读投影

### 3.2 项目知识能力层 -> 应用级显式 promotion

服务：

- `ProjectInformationPromotionService`

职责：

1. 从项目级 JSON 仓储读取显式指定的 artifact
2. 使用 `ProjectInformationPromotionMapperService` 构造 package/version/entry/promotion record
3. 合并进现有应用级 package snapshot
4. 写回 SQLite 基座

这里保持了正式原则：

```text
默认单向派生，显式提升。
```

投影不会反写全局，只有显式 promotion 才会写回应用级基座。

### 3.3 bundle export / import

服务：

1. `ReferenceBundleExportService`
2. `ReferenceBundleImportService`
3. `ReferenceBundleDirectoryCodecService`

职责：

1. 从 SQLite 基座导出 bundle
2. 从 bundle 重建 package snapshot
3. 保留完整性 checksum 骨架
4. 为后续附件、大文本、分享与迁移预留稳定目录合同

### 3.4 原始书稿 -> reference package 正式主链

本轮后半段已补上此前缺失的最后一段：

1. `ReferenceSourceDocumentExtractionService`
   - 纯 core 抽取服务
   - 负责把原始文稿按章节/片段、实体线索、风格画像、引用边界转成结构化 entry

2. `BuildReferencePackageFromSourceDocumentUseCase`
   - 正式 use case
   - 负责把 source document 抽取结果直接写入 `ReferenceEvidenceSubstrate`

3. `ReferenceSourceDocumentFileIngestionService`
   - adapter 侧文件入口
   - 负责读取 `.txt` 文稿、调用 use case，并可选直接导出 bundle

这意味着现在已经不是：

```text
source document -> ResearchNote -> 以后再说
```

而是已经有正式主链：

```text
source document -> structured reference package -> SQLite substrate -> bundle / projection
```

### 3.5 目标语言策略

本轮补入了正式语言字段：

1. `source_language`
2. `target_language`

当前落点：

1. `ReferencePackageRecord`
2. `ReferenceBundleManifest`
3. source-document 抽取 payload
4. bundle summary projection
5. bundle attachments README

当前默认策略：

1. source language 可自动粗判
2. target language 默认 `zh-CN`
3. bundle 可读投影与说明按 `target_language` 输出

因此对于中文目标项目，现在生成的知识库摘要和导出说明默认走中文，而不是技术英文。

---

## 4. 当前已覆盖的硬边界

本轮不是把所有高级能力做满，而是把正式边界做进架构骨架。

当前已经明确落口的边界包括：

1. schema migration
   - 应用级与项目挂载层各自独立 migrator

2. bundle contract
   - 目录结构、manifest、payload、projection、integrity 已定型

3. 索引 / 检索入口
   - `ReferenceQuery`
   - `ReferenceQueryResult`
   - SQLite `search_text` 字段与相关索引

4. projection 重建入口
   - `ProjectReferenceProjectionService`
   - `ProjectInformationProjectionWriterService`

5. 权限不足 / 缺包 / 版本不匹配
   - 通过 access decision 与 projection result 明确返回

6. promotion 审计
   - `ReferencePromotionRecord`

7. 删除 / 级联预留
   - 当前表结构已按 package / version / entry 的级联关系落地

8. 附件 / 大文本承载边界
   - `ReferenceAttachmentPointer`
   - bundle `attachments/` 目录

9. 原始文稿直达结构化包
   - `source document -> package snapshot -> substrate -> bundle`

10. 目标语言输出纪律
   - `target_language=zh-CN` 时，bundle 摘要和导出说明走中文

---

## 5. 验证证据

已新增测试：

1. `packages/novel_agent_core/test/reference_substrate_contracts_test.dart`
   - 覆盖 access policy
   - 覆盖 projection mapper
   - 覆盖 promotion mapper

2. `packages/novel_agent_adapters/test/reference_substrate_chain_test.dart`
   - 覆盖应用级参考包 -> 项目挂载 -> 项目知识层投影
   - 覆盖 bundle export / import
   - 覆盖权限限制生效
   - 覆盖显式 promotion 生效且 projection 不隐式反写全局

3. `packages/novel_agent_core/test/reference_source_document_extraction_service_test.dart`
   - 覆盖原始 source document -> 结构化 reference package 抽取
   - 覆盖 `target_language=zh-CN`

4. `packages/novel_agent_adapters/test/reference_source_document_ingestion_service_test.dart`
   - 覆盖 `.txt -> reference package -> bundle 中文摘要`
   - 覆盖 `Harry Potter - Volume 1 Raw.txt` 样本回归

已验证命令：

1. `dart test test/reference_substrate_contracts_test.dart`
2. `dart test test/reference_substrate_chain_test.dart`
3. `dart test test/reference_source_document_extraction_service_test.dart`
4. `dart test test/reference_source_document_ingestion_service_test.dart`
5. `dart run apps/novel_agent_app/tool/reference_source_document_probe.dart`
6. `dart analyze lib test`
   - `novel_agent_adapters` 无新增问题
   - `novel_agent_core` 仍存在仓库里原有未使用字段 warning，但本轮新增文件未再引入新 warning

真实 probe 现已直接对：

1. `references/files/Harry Potter.txt`

执行一次原始书稿抽取，并产出：

1. `artifacts/reference_source_document_probe_report.json`
2. `artifacts/reference_source_document_probe_report.md`
3. `artifacts/reference_source_document_probe_workspace/.../bundle/`
4. `bundle/projections/summary.md`

最近一次 probe 结果显示：

1. `source_language = en`
2. `target_language = zh-CN`
3. `generated_entry_count = 18`
4. 已生成 `knowledge_fact / design_element / style_technique / reference_work_boundary`

---

## 6. 当前刻意保留为后续扩展的部分

本轮已经把正式主链钉住，但仍有一些内容是“留口”而不是“做满”：

1. 还没有做 GUI 资料管理器
2. 还没有做 bundle 签名或强校验
3. 还没有做 FTS 或更复杂的排序策略
4. 还没有做附件二进制内容的自动搬运
5. 还没有把删除策略提升成独立 use case
6. 还没有把项目页挂载状态接进 app / cli 视图层

这些都属于后续迭代项，但不会再推翻当前三层和合同边界。

---

## 7. 本轮后的正式判断

当前仓库已经不再只是“项目知识卡 JSON + 零散研究笔记”。

它已经具备了：

1. 应用级参考证据基座
2. 项目级参考挂载层
3. 项目级知识能力层
4. 应用级 -> 项目级投影主链
5. 项目级 -> 应用级显式 promotion 主链
6. bundle 化导入导出主链

也就是说，这轮的核心设计已经从分析文档进入正式实现骨架，而不是仍停留在讨论态。
