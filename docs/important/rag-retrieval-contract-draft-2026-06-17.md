# RAG Retrieval 合同草案

日期：2026-06-17

关联分析：

- `docs/important/rag-parallel-knowledge-branch-analysis-2026-06-17.md`
- `docs/project-information-substrate-implementation-audit-2026-06-05.md`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `docs/architecture.md`
- `agent.md`

---

## 1. 这份文档解决什么

这份文档把上一份分析里的结论，继续收成：

**NovelAgent 如果要增加 RAG 平行知识分支，底层至少需要哪些正式合同、这些合同的职责边界是什么、宿主层该怎么消费它们。**

这不是实现文档，也不是选型文档。

它的职责只有一个：

**先把 Retrieval / RAG 的正式合同形状钉住，避免后续实现时把 GUI 流程、Flutter 包、sidecar、远端服务、结构化知识体系重新揉成一团。**

---

## 2. 基本原则

所有后续实现必须先接受下面这几条原则。

### 2.1 RAG 不是事实源

RAG 在 NovelAgent 中的正式定位是：

- 检索证据层
- 原文召回层
- 模糊检索层

不是：

- 正式长期知识层
- 角色/世界观/规则的唯一真相源

### 2.2 结构化知识体系继续是正式主线

以下内容继续保留为正式结构化事实层：

- `knowledge_cards`
- `design_elements`
- `research_notes`
- `reference_works`

RAG 必须和它们并行，而不是替代它们。

### 2.3 共享的是合同，不共享的是底层实现

Flutter GUI、CLI、Docker 可以接不同 Retrieval backend。

共享的应该是：

- 提取语义
- 挂载语义
- 检索查询语义
- 结果合同

不共享的是：

- embedding 生成方式
- 向量索引实现
- 本地/远端/sidecar 的具体跑法

### 2.4 GUI 不是真相层

GUI 只负责：

- 用户输入
- 模式选择
- 构建状态
- 资产摘要
- 项目挂载

GUI 不应解释底层 RAG 真相，不应自己维护第二套语义。

---

## 3. 整体结构草案

正式结构建议如下：

```text
Structured Knowledge Layer
  -> knowledge_cards / design_elements / research_notes / reference_works

Retrieval Evidence Layer
  -> rag corpus / retrieval chunks / retrieval index handle / retrieval mount

Readable Projection Layer
  -> knowledge/*.md / research/*.md / future rag summaries
```

其中：

1. 结构化知识层回答“正式结论是什么”
2. 检索证据层回答“相关原文或资料片段在哪里”
3. 投影层回答“用户看什么”

---

## 4. 正式术语草案

为了避免后面命名再次漂移，建议先冻结一组正式术语。

### 4.1 资产级术语

- `StructuredKnowledgePackage`
- `RagCorpusPackage`
- `HybridReferencePackage`

### 4.2 运行级术语

- `RetrievalMountBinding`
- `RetrievalQuery`
- `RetrievalHit`
- `RetrievalActivationPackage`

### 4.3 提取级术语

- `RagSourceDocument`
- `RagNormalizedSource`
- `RagSegmentationResult`
- `RagChunkBuildResult`
- `RagIngestionResult`

### 4.4 provider 级术语

- `EmbeddingProviderPort`
- `RetrievalIndexPort`
- `RetrievalSearchPort`
- `RetrievalHealthPort`

---

## 5. 正式模型草案

这里不写 Dart 代码，而是先写模型职责。

## 5.1 `RagCorpusPackage`

表示一份可挂载的 RAG 语料资产包。

建议字段：

- `corpus_id`
- `title`
- `description`
- `source_kind`
- `language`
- `build_mode`
- `segmentation_strategy`
- `chunk_strategy`
- `embedding_backend`
- `index_backend`
- `version`
- `created_at`
- `updated_at`
- `source_count`
- `chapter_count`
- `chunk_count`
- `is_model_assisted`
- `capability_flags`

职责：

- 表达“这份 RAG 资产包是什么”
- 不直接存 chunk 内容本体

## 5.2 `RagSourceDocument`

表示导入进来的源文稿对象。

建议字段：

- `source_id`
- `corpus_id`
- `source_kind`
- `display_name`
- `origin_path`
- `origin_format`
- `language`
- `content_hash`
- `metadata`

职责：

- 表达原始来源
- 支持后续重新分段、重建索引、定位错误来源

## 5.3 `RagNormalizedSource`

表示标准化后的文稿结果。

建议字段：

- `source_id`
- `normalized_units`
- `discarded_units`
- `uncertain_units`
- `normalization_notes`
- `strategy_id`
- `used_model`

职责：

- 作为“源输入 -> 可分段正文”的正式边界
- 让模型辅助标准化不再是黑盒

## 5.4 `RagSegmentationResult`

表示分章/分段结果。

建议字段：

- `source_id`
- `segments`
- `chapter_titles`
- `chapter_indices`
- `segment_ranges`
- `warnings`
- `strategy_id`

职责：

- 表达章节或正文分段边界
- 为后续 chunk 构建提供稳定输入

## 5.5 `RagChunk`

表示一个可检索 chunk。

建议字段：

- `chunk_id`
- `corpus_id`
- `source_id`
- `chapter_index`
- `chapter_title`
- `segment_index`
- `text`
- `normalized_text`
- `token_estimate`
- `range_start`
- `range_end`
- `metadata`

职责：

- 表达真正进入检索库的最小文本单元

## 5.6 `RagIndexHandle`

表示检索后端中的索引身份。

建议字段：

- `index_id`
- `corpus_id`
- `backend_kind`
- `backend_location`
- `embedding_dim`
- `status`
- `version`
- `last_built_at`

职责：

- 把 RAG 资产与具体 backend 连接起来
- 允许将来切换 backend 而不破坏上层语义

## 5.7 `RetrievalMountBinding`

表示项目对某个检索语料的挂载。

建议字段：

- `binding_id`
- `project_id`
- `corpus_id`
- `mount_scope`
- `priority`
- `usage_policy`
- `activation_policy`
- `created_at`

职责：

- 表达“哪个项目挂了哪份 RAG 资产”
- 决定查询时是否对当前项目可见

## 5.8 `RetrievalQuery`

表示一次正式检索请求。

建议字段：

- `query_text`
- `project_id`
- `corpus_filters`
- `source_filters`
- `language`
- `top_k`
- `query_mode`
- `rerank_policy`
- `evidence_budget`

职责：

- 把“检索意图”合同化

## 5.9 `RetrievalHit`

表示一次命中的证据结果。

建议字段：

- `chunk_id`
- `corpus_id`
- `source_id`
- `score`
- `rerank_score`
- `excerpt`
- `range`
- `chapter_title`
- `evidence_path`
- `metadata`

职责：

- 表达给智能体或用户看的“命中了什么”

## 5.10 `RetrievalActivationPackage`

表示给智能体实际注入的检索结果包。

建议字段：

- `query_summary`
- `selected_hits`
- `source_summaries`
- `warning_notes`
- `citation_paths`

职责：

- 防止把原始 hit 列表直接塞给智能体
- 形成稳定、可控、带来源路径的注入结果

---

## 6. 正式接口族草案

这部分是整个设计里最重要的工程边界。

## 6.1 输入标准化接口

### `RagSourceNormalizer`

职责：

- 接收 txt / md / epub / folder 等来源
- 输出统一 `RagNormalizedSource`

最低能力：

- `supportsSourceKind`
- `normalize`
- `explainNormalizationFailure`

约束：

- 不直接做 embedding
- 不直接做项目挂载

## 6.2 分段策略接口

### `RagSegmentationStrategy`

职责：

- 规则分章
- 模型分章
- 混合分章

最低能力：

- `strategyId`
- `supportsNormalizedSource`
- `segment`

约束：

- 只负责分段
- 不直接落盘

## 6.3 chunk 构建接口

### `RagChunkBuilder`

职责：

- 从分段结果构建 chunk
- 控制 overlap / chunk size / metadata 注入

最低能力：

- `buildChunks`
- `estimateChunkCount`

## 6.4 embedding provider 接口

### `EmbeddingProviderPort`

职责：

- 生成 embedding
- 声明自身能力

最低能力：

- `providerId`
- `providerKind`
- `isLocal`
- `isRemote`
- `embedTexts`
- `describeCapabilities`

## 6.5 检索索引接口

### `RetrievalIndexPort`

职责：

- 建索引
- 增量更新
- 删除 chunk
- 重建索引

最低能力：

- `createIndex`
- `upsertChunks`
- `removeChunks`
- `rebuildIndex`

## 6.6 检索查询接口

### `RetrievalSearchPort`

职责：

- 查询
- 过滤
- rerank

最低能力：

- `search`
- `searchWithinMounts`
- `searchByCorpus`

## 6.7 健康探测接口

### `RetrievalHealthPort`

职责：

- 声明 backend 是否可用
- 让宿主判断当前环境是否支持某 provider

最低能力：

- `isAvailable`
- `describeFailure`
- `hostCapabilityProfile`

## 6.8 提取运行时编排接口

### `RetrievalIngestionPort`

职责：

- 把 normalize -> segment -> chunk -> index 这条链作为正式编排入口

最低能力：

- `ingestRagCorpus`
- `rebuildRagCorpus`
- `resumeIngestion`

约束：

- 不直接承担 GUI 状态管理

---

## 7. 元数据基座草案

### 7.1 SQLite 的角色

建议继续用 SQLite 做：

- corpus 元数据
- source 元数据
- chunk 元数据
- mount 关系
- backend handle
- 版本记录

### 7.2 SQLite 不直接等于向量库本体

这里必须避免一个误区：

**SQLite 是元数据与映射基座，不必强行承担所有向量索引实现。**

这意味着：

- GUI / CLI / Docker 都可以共享一套 SQLite 语义
- 底层检索后端可以自由替换

### 7.3 建议的最小表族

建议后续至少会出现：

- `rag_corpora`
- `rag_sources`
- `rag_chunks`
- `rag_mount_bindings`
- `rag_index_handles`
- `rag_ingestion_runs`

注意：

第一阶段不需要一次建完全部高级表，但表族方向应该先固定。

---

## 8. GUI / CLI / Docker 的消费边界

## 8.1 GUI

GUI 首批只消费：

- 提取入口
- 模式选择
- 状态摘要
- 资产卡片
- 挂载入口

GUI 不应直接消费：

- 底层 backend 细节
- 原始 embedding 结果
- 原始索引结构

## 8.2 CLI

CLI 可以更强一些。

CLI 合适消费：

- corpus 构建
- corpus rebuild
- mount / unmount
- diagnostics
- health check

## 8.3 Docker

Docker 可以直接接：

- sidecar retrieval provider
- remote embedding provider
- remote search provider

但上层合同仍和 GUI / CLI 一致。

---

## 9. 两种 GUI 模式映射到合同层的方式

## 9.1 基础 RAG 提取

用户可见：

- 纯离线简单识别
- 首批只开放 txt

合同层真实含义：

- `RagSourceNormalizer`: 规则标准化
- `RagSegmentationStrategy`: 规则分章
- `RagChunkBuilder`: 默认 chunk 规则
- `EmbeddingProviderPort`: 可为空或使用远端默认提供者

## 9.2 模型辅助 RAG 提取

用户可见：

- 模型辅助智能拆书
- 支持 epub / folder / md 等
- 只有用户选择该模式时才启用模型辅助

合同层真实含义：

- `RagSourceNormalizer`: 允许接入现有智能拆书能力完成模型辅助标准化
- `RagSegmentationStrategy`: 允许复用现有智能拆书的章节识别 / 去噪结果
- `RagChunkBuilder`: 仍然走统一 chunk 规则
- `EmbeddingProviderPort`: 可选本地或远端

这里最重要的约束是：

**模型辅助模式只是前段标准化与分章增强，不是另一套 RAG 正式体系。**

更准确的合同表达是：

- `source_preprocessing_mode = offline_basic`
- `source_preprocessing_mode = smart_deconstruction_assisted`

这两个模式只影响 RAG ingestion 的前处理阶段，后续 `chunk build / corpus ingest / mount / retrieve / activation` 必须走同一套主链。

---

## 10. 不该出现在正式合同中的东西

为了防止职责漂移，下面这些东西不应进入合同层：

1. Flutter widget 状态
2. 某个下拉菜单是否展开
3. 某个本地包的私有模型名
4. 某个 sidecar 的 HTTP 路径细节
5. 某个 provider 的商用配置项

这些都应留在 adapter 或宿主层。

---

## 11. 第一版落地时最关键的取舍

如果只允许先做一小步，最值钱的不是“先支持所有格式”，而是：

1. 把 `RagCorpusPackage / RagSourceDocument / RagChunk / RetrievalMountBinding / RetrievalQuery / RetrievalHit` 这几个模型定下来
2. 把 `RagSourceNormalizer / RagSegmentationStrategy / RagChunkBuilder / RetrievalSearchPort / RetrievalIngestionPort` 这几个接口定下来
3. 让基础 `txt` 提取先打通
4. 让项目挂载和检索工具先跑通

只要这四件事做好，后面扩模型辅助模式、Flutter 本地 provider、CLI sidecar、Docker backend 都会顺很多。

---

## 12. 最终结论

这份合同草案的核心只有一句话：

**NovelAgent 的 RAG 不应先被实现成某个具体库，而应先被定义成一组正式 Retrieval 合同；现有结构化知识体系继续做事实层，RAG 只做平行的检索证据层。**

这样后续无论接：

- Flutter 本地 provider
- CLI native / sidecar provider
- Docker 外置检索服务
- 远端 embedding / 混合索引

都不会反向破坏项目已经建立起来的知识体系与架构边界。

## 13. 实施收口备注

这份草案对应的正式合同已经进入实现与回归验证，当前可按已落地基线理解：

1. `RagCorpusPackage`、`RagSourceDocument`、`RagNormalizedSource`、`RagSegmentationResult`、`RagChunk`、`RagIndexHandle`、`RetrievalMountBinding`、`RetrievalQuery`、`RetrievalHit`、`RetrievalActivationPackage` 等模型已经用于代码实现。
2. `RagSourceNormalizer`、`RagSegmentationStrategy`、`RagChunkBuilder`、`EmbeddingProviderPort`、`RetrievalIndexPort`、`RetrievalSearchPort`、`RetrievalHealthPort`、`RetrievalIngestionPort` 等接口族已经作为共享合同被消费。
3. 基础 txt ingestion、挂载、检索、activation bridge、provider capability reporting 以及 CLI / GUI 消费边界都已经按这份合同收口。
4. 这份文档现在主要承担“合同说明 + 扩展位保留”的角色，不再是待实现草案。
