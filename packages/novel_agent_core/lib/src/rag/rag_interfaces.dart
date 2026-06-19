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

  List<List<num>> embedTexts(List<String> texts);

  JsonMap describeCapabilities();
}

/// 检索索引端口。
abstract interface class RetrievalIndexPort {
  RagIndexHandle createIndex(RagCorpusPackage corpusPackage);

  RagIndexHandle rebuildIndex(RagIndexHandle handle, List<RagChunk> chunks);

  RagIndexHandle upsertChunks(RagIndexHandle handle, List<RagChunk> chunks);

  RagIndexHandle removeChunks(RagIndexHandle handle, List<RagChunkId> chunkIds);
}

/// 检索查询端口。
abstract interface class RetrievalSearchPort {
  List<RetrievalHit> search(RetrievalQuery query);

  List<RetrievalHit> searchWithinMounts(
    RetrievalQuery query,
    List<RetrievalMountBinding> bindings,
  );

  List<RetrievalHit> searchByCorpus(
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
  RagIngestionResult ingestRagCorpus(
    RagCorpusPackage corpusPackage,
    List<RagSourceDocument> sourceDocuments,
  );

  RagIngestionResult rebuildRagCorpus(RagCorpusPackage corpusPackage);

  RagIngestionResult resumeIngestion(RagCorpusPackage corpusPackage);
}
