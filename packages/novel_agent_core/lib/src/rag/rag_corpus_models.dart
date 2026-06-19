import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'rag_contract_typedefs.dart';
import 'rag_validation_codes.dart';

abstract final class RagBuildModes {
  static const String basic = 'basic';
  static const String modelAssisted = 'model_assisted';
  static const String hybrid = 'hybrid';
}

const _ragCorpusCodecService = OpenJsonContractCodecService();
const _ragCorpusValidatorService = OpenJsonStructureValidatorService();
const _ragCorpusKnownFields = <String>{
  'corpus_id',
  'title',
  'description',
  'source_kind',
  'language',
  'build_mode',
  'segmentation_strategy',
  'chunk_strategy',
  'embedding_backend',
  'index_backend',
  'version',
  'created_at',
  'updated_at',
  'source_count',
  'chapter_count',
  'chunk_count',
  'is_model_assisted',
  'capability_flags',
  'metadata',
};

class RagCorpusPackage {
  const RagCorpusPackage({
    required this.corpusId,
    required this.title,
    required this.sourceKind,
    required this.buildMode,
    this.description = '',
    this.language = '',
    this.segmentationStrategy = '',
    this.chunkStrategy = '',
    this.embeddingBackend = '',
    this.indexBackend = '',
    this.version = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.sourceCount = 0,
    this.chapterCount = 0,
    this.chunkCount = 0,
    this.isModelAssisted = false,
    this.capabilityFlags = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final RagCorpusId corpusId;
  final String title;
  final String description;
  final String sourceKind;
  final String language;
  final String buildMode;
  final String segmentationStrategy;
  final String chunkStrategy;
  final String embeddingBackend;
  final String indexBackend;
  final String version;
  final String createdAt;
  final String updatedAt;
  final int sourceCount;
  final int chapterCount;
  final int chunkCount;
  final bool isModelAssisted;
  final List<String> capabilityFlags;
  final JsonMap metadata;

  RagCorpusPackage copyWith({
    RagCorpusId? corpusId,
    String? title,
    String? description,
    String? sourceKind,
    String? language,
    String? buildMode,
    String? segmentationStrategy,
    String? chunkStrategy,
    String? embeddingBackend,
    String? indexBackend,
    String? version,
    String? createdAt,
    String? updatedAt,
    int? sourceCount,
    int? chapterCount,
    int? chunkCount,
    bool? isModelAssisted,
    List<String>? capabilityFlags,
    JsonMap? metadata,
  }) {
    // 中文注释: RAG 语料包会在构建、重建和投影阶段被局部修补，这里统一提供稳定 copy 入口。
    return RagCorpusPackage(
      corpusId: corpusId ?? this.corpusId,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceKind: sourceKind ?? this.sourceKind,
      language: language ?? this.language,
      buildMode: buildMode ?? this.buildMode,
      segmentationStrategy: segmentationStrategy ?? this.segmentationStrategy,
      chunkStrategy: chunkStrategy ?? this.chunkStrategy,
      embeddingBackend: embeddingBackend ?? this.embeddingBackend,
      indexBackend: indexBackend ?? this.indexBackend,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceCount: sourceCount ?? this.sourceCount,
      chapterCount: chapterCount ?? this.chapterCount,
      chunkCount: chunkCount ?? this.chunkCount,
      isModelAssisted: isModelAssisted ?? this.isModelAssisted,
      capabilityFlags: capabilityFlags ?? this.capabilityFlags,
      metadata: metadata ?? this.metadata,
    );
  }

  factory RagCorpusPackage.fromJson(JsonMap json) {
    // 中文注释: corpus 壳层字段稳定，但 capability 和 metadata 继续保留开放结构，避免把后续 backend 能力写死。
    return RagCorpusPackage(
      corpusId: ValueReaders.stringValue(json['corpus_id']).trim(),
      title: ValueReaders.stringValue(json['title']).trim(),
      description: ValueReaders.stringValue(json['description']).trim(),
      sourceKind: ValueReaders.stringValue(json['source_kind']).trim(),
      language: ValueReaders.stringValue(json['language']).trim(),
      buildMode: ValueReaders.stringValue(json['build_mode']).trim(),
      segmentationStrategy: ValueReaders.stringValue(
        json['segmentation_strategy'],
      ).trim(),
      chunkStrategy: ValueReaders.stringValue(json['chunk_strategy']).trim(),
      embeddingBackend: ValueReaders.stringValue(
        json['embedding_backend'],
      ).trim(),
      indexBackend: ValueReaders.stringValue(json['index_backend']).trim(),
      version: ValueReaders.stringValue(json['version']).trim(),
      createdAt: ValueReaders.stringValue(json['created_at']).trim(),
      updatedAt: ValueReaders.stringValue(json['updated_at']).trim(),
      sourceCount: ValueReaders.intValue(json['source_count']),
      chapterCount: ValueReaders.intValue(json['chapter_count']),
      chunkCount: ValueReaders.intValue(json['chunk_count']),
      isModelAssisted: ValueReaders.boolValue(json['is_model_assisted']),
      capabilityFlags: ValueReaders.objectList(json['capability_flags'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      metadata: _ragCorpusCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _ragCorpusKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _ragCorpusCodecService.encodeWithUnknownFields(<String, Object?>{
      'corpus_id': corpusId,
      'title': title,
      'description': description,
      'source_kind': sourceKind,
      'language': language,
      'build_mode': buildMode,
      'segmentation_strategy': segmentationStrategy,
      'chunk_strategy': chunkStrategy,
      'embedding_backend': embeddingBackend,
      'index_backend': indexBackend,
      'version': version,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'source_count': sourceCount,
      'chapter_count': chapterCount,
      'chunk_count': chunkCount,
      'is_model_assisted': isModelAssisted,
      'capability_flags': capabilityFlags.toList(growable: false),
    }, metadata: metadata);
  }

  List<String> validateBasics() {
    // 中文注释: 这里只校验语料包最小可挂载合同，不在这里实现分段、嵌入或索引逻辑。
    final result = <String>[];
    result.addAll(
      _ragCorpusValidatorService.requireNonBlankString(
        corpusId,
        RagValidationCodes.missingRagCorpusId,
      ),
    );
    result.addAll(
      _ragCorpusValidatorService.requireNonBlankString(
        title,
        RagValidationCodes.missingRagCorpusTitle,
      ),
    );
    result.addAll(
      _ragCorpusValidatorService.requireNonBlankString(
        sourceKind,
        RagValidationCodes.missingRagCorpusSourceKind,
      ),
    );
    result.addAll(
      _ragCorpusValidatorService.requireNonBlankString(
        buildMode,
        RagValidationCodes.missingRagCorpusBuildMode,
      ),
    );
    return result;
  }
}

