import '../common/json_types.dart';

/// RAG 语料包使用的稳定标识。
typedef RagCorpusId = String;

/// RAG 源文稿使用的稳定标识。
typedef RagSourceDocumentId = String;

/// RAG 标准化单元使用的稳定标识。
typedef RagNormalizedSourceUnitId = String;

/// RAG 丢弃单元使用的稳定标识。
typedef RagDiscardedSourceUnitId = String;

/// RAG 不确定单元使用的稳定标识。
typedef RagUncertainSourceUnitId = String;

/// RAG 标准化结果使用的稳定标识。
typedef RagNormalizedSourceId = String;

/// RAG 分段片段使用的稳定标识。
typedef RagSegmentationSegmentId = String;

/// RAG 分段结果使用的稳定标识。
typedef RagSegmentationResultId = String;

/// RAG chunk 构建结果使用的稳定标识。
typedef RagChunkBuildResultId = String;

/// RAG chunk 使用的稳定标识。
typedef RagChunkId = String;

/// RAG 索引句柄使用的稳定标识。
typedef RagIndexHandleId = String;

/// RAG 挂载绑定使用的稳定标识。
typedef RetrievalMountBindingId = String;

/// RAG 检索查询使用的稳定标识。
typedef RetrievalQueryId = String;

/// RAG 检索命中使用的稳定标识。
typedef RetrievalHitId = String;

/// RAG 激活包使用的稳定标识。
typedef RetrievalActivationPackageId = String;

/// RAG ingestion 结果使用的稳定标识。
typedef RagIngestionResultId = String;

/// RAG 合同里的开放 JSON payload。
typedef RagOpenPayload = JsonMap;
