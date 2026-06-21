import '../common/json_types.dart';
import 'rag_chunk_models.dart';
import 'rag_contract_typedefs.dart';
import 'rag_corpus_models.dart';
import 'rag_processing_models.dart';
import 'rag_retrieval_models.dart';
import 'rag_source_models.dart';

/// RAG 源文稿标准化器。
abstract interface class RagSourceNormalizer {
  bool supportsSourceKind(String sourceKind);

  RagNormalizedSource normalize(RagSourceDocument sourceDocument);
}

/// RAG 分段策略。
abstract interface class RagSegmentationStrategy {
  String get strategyId;

  bool supportsNormalizedSource(RagNormalizedSource normalizedSource);

  RagSegmentationResult segment(RagNormalizedSource normalizedSource);
}

/// RAG chunk 构建器。
abstract interface class RagChunkBuilder {
  RagChunkBuildResult buildChunks(RagSegmentationResult segmentationResult);
}

/// embedding 提供者端口。
abstract interface class EmbeddingProviderPort {
  String get providerId;

  String get providerKind;

  bool get isLocal;

  bool get isRemote;

  // 中文注释: embedding 取向量通常要走网络或本地模型推理，统一为异步合同，
  // 避免实现被迫在 UI 线程上做同步阻塞调用。
  Future<List<List<num>>> embedTexts(List<String> texts);

  JsonMap describeCapabilities();
}

/// 检索索引端口。
abstract interface class RetrievalIndexPort {
  Future<RagIndexHandle> createIndex(RagCorpusPackage corpusPackage);

  Future<RagIndexHandle> rebuildIndex(RagIndexHandle handle, List<RagChunk> chunks);

  Future<RagIndexHandle> upsertChunks(RagIndexHandle handle, List<RagChunk> chunks);

  Future<RagIndexHandle> removeChunks(
    RagIndexHandle handle,
    List<RagChunkId> chunkIds,
  );
}

/// 检索查询端口。
abstract interface class RetrievalSearchPort {
  Future<List<RetrievalHit>> search(RetrievalQuery query);

  Future<List<RetrievalHit>> searchWithinMounts(
    RetrievalQuery query,
    List<RetrievalMountBinding> bindings,
  );

  Future<List<RetrievalHit>> searchByCorpus(
    RetrievalQuery query,
    RagCorpusId corpusId,
  );
}

/// 检索健康端口。
abstract interface class RetrievalHealthPort {
  bool isAvailable();

  String describeFailure();

  JsonMap hostCapabilityProfile();
}

/// RAG 提取运行端口。
abstract interface class RetrievalIngestionPort {
  Future<RagIngestionResult> ingestRagCorpus(
    RagCorpusPackage corpusPackage,
    List<RagSourceDocument> sourceDocuments,
  );

  Future<RagIngestionResult> rebuildRagCorpus(RagCorpusPackage corpusPackage);

  Future<RagIngestionResult> resumeIngestion(RagCorpusPackage corpusPackage);
}
