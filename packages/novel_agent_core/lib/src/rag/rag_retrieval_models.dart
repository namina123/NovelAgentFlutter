import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'rag_contract_typedefs.dart';
import 'rag_validation_codes.dart';

const _ragIndexHandleCodecService = OpenJsonContractCodecService();
const _ragIndexHandleValidatorService = OpenJsonStructureValidatorService();

class RagIndexHandle {
  const RagIndexHandle({
    required this.indexHandleId,
    required this.corpusId,
    this.backendKind = '',
    this.backendLocation = '',
    this.embeddingDimension = 0,
    this.status = '',
    this.version = '',
    this.lastBuiltAt = '',
    this.metadata = const <String, Object?>{},
  });

  final RagIndexHandleId indexHandleId;
  final RagCorpusId corpusId;
  final String backendKind;
  final String backendLocation;
  final int embeddingDimension;
  final String status;
  final String version;
  final String lastBuiltAt;
  final JsonMap metadata;

  factory RagIndexHandle.fromJson(JsonMap json) {
    // 中文注释: 索引句柄只记录 backend 连接与状态，不把向量实现细节提升到 core。
    return RagIndexHandle(
      indexHandleId: ValueReaders.stringValue(json['index_handle_id']).trim(),
      corpusId: ValueReaders.stringValue(json['corpus_id']).trim(),
      backendKind: ValueReaders.stringValue(json['backend_kind']).trim(),
      backendLocation: ValueReaders.stringValue(
        json['backend_location'],
      ).trim(),
      embeddingDimension: ValueReaders.intValue(json['embedding_dimension']),
      status: ValueReaders.stringValue(json['status']).trim(),
      version: ValueReaders.stringValue(json['version']).trim(),
      lastBuiltAt: ValueReaders.stringValue(json['last_built_at']).trim(),
      metadata: _ragIndexHandleCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: const <String>{
          'index_handle_id',
          'corpus_id',
          'backend_kind',
          'backend_location',
          'embedding_dimension',
          'status',
          'version',
          'last_built_at',
          'metadata',
        },
      ),
    );
  }

  JsonMap toJson() {
    return _ragIndexHandleCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'index_handle_id': indexHandleId,
        'corpus_id': corpusId,
        'backend_kind': backendKind,
        'backend_location': backendLocation,
        'embedding_dimension': embeddingDimension,
        'status': status,
        'version': version,
        'last_built_at': lastBuiltAt,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 索引句柄至少要能追踪到自己和所属 corpus，便于宿主做 capability 探测。
    final result = <String>[];
    result.addAll(
      _ragIndexHandleValidatorService.requireNonBlankString(
        indexHandleId,
        RagValidationCodes.missingRagIndexHandleId,
      ),
    );
    result.addAll(
      _ragIndexHandleValidatorService.requireNonBlankString(
        corpusId,
        RagValidationCodes.missingRagIndexHandleCorpusId,
      ),
    );
    return result;
  }
}

const _retrievalMountBindingCodecService = OpenJsonContractCodecService();
const _retrievalMountBindingValidatorService =
    OpenJsonStructureValidatorService();

class RetrievalMountBinding {
  const RetrievalMountBinding({
    required this.bindingId,
    required this.projectId,
    required this.corpusId,
    this.mountScope = '',
    this.priority = 0,
    this.usagePolicy = '',
    this.activationPolicy = '',
    this.createdAt = '',
    this.metadata = const <String, Object?>{},
  });

  final RetrievalMountBindingId bindingId;
  final String projectId;
  final RagCorpusId corpusId;
  final String mountScope;
  final int priority;
  final String usagePolicy;
  final String activationPolicy;
  final String createdAt;
  final JsonMap metadata;

  factory RetrievalMountBinding.fromJson(JsonMap json) {
    // 中文注释: 挂载绑定只描述项目与语料的正式关系，不承载任何检索实现细节。
    return RetrievalMountBinding(
      bindingId: ValueReaders.stringValue(json['binding_id']).trim(),
      projectId: ValueReaders.stringValue(json['project_id']).trim(),
      corpusId: ValueReaders.stringValue(json['corpus_id']).trim(),
      mountScope: ValueReaders.stringValue(json['mount_scope']).trim(),
      priority: ValueReaders.intValue(json['priority']),
      usagePolicy: ValueReaders.stringValue(json['usage_policy']).trim(),
      activationPolicy: ValueReaders.stringValue(
        json['activation_policy'],
      ).trim(),
      createdAt: ValueReaders.stringValue(json['created_at']).trim(),
      metadata: _retrievalMountBindingCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: const <String>{
              'binding_id',
              'project_id',
              'corpus_id',
              'mount_scope',
              'priority',
              'usage_policy',
              'activation_policy',
              'created_at',
              'metadata',
            },
          ),
    );
  }

  JsonMap toJson() {
    return _retrievalMountBindingCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'binding_id': bindingId,
        'project_id': projectId,
        'corpus_id': corpusId,
        'mount_scope': mountScope,
        'priority': priority,
        'usage_policy': usagePolicy,
        'activation_policy': activationPolicy,
        'created_at': createdAt,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 挂载绑定的最小要求是能说明谁挂了谁。
    final result = <String>[];
    result.addAll(
      _retrievalMountBindingValidatorService.requireNonBlankString(
        bindingId,
        RagValidationCodes.missingRetrievalMountBindingId,
      ),
    );
    result.addAll(
      _retrievalMountBindingValidatorService.requireNonBlankString(
        projectId,
        RagValidationCodes.missingRetrievalMountBindingProjectId,
      ),
    );
    result.addAll(
      _retrievalMountBindingValidatorService.requireNonBlankString(
        corpusId,
        RagValidationCodes.missingRetrievalMountBindingCorpusId,
      ),
    );
    return result;
  }
}

const _retrievalQueryCodecService = OpenJsonContractCodecService();
const _retrievalQueryValidatorService = OpenJsonStructureValidatorService();

class RetrievalQuery {
  const RetrievalQuery({
    required this.queryId,
    required this.queryText,
    this.projectId = '',
    this.corpusFilters = const <String>[],
    this.sourceFilters = const <String>[],
    this.language = '',
    this.topK = 20,
    this.queryMode = '',
    this.rerankPolicy = '',
    this.evidenceBudget = 0,
    this.metadata = const <String, Object?>{},
  });

  final RetrievalQueryId queryId;
  final String queryText;
  final String projectId;
  final List<String> corpusFilters;
  final List<String> sourceFilters;
  final String language;
  final int topK;
  final String queryMode;
  final String rerankPolicy;
  final int evidenceBudget;
  final JsonMap metadata;

  factory RetrievalQuery.fromJson(JsonMap json) {
    // 中文注释: 查询合同只描述检索意图，不把 backend 参数和宿主路由混进来。
    return RetrievalQuery(
      queryId: ValueReaders.stringValue(json['query_id']).trim(),
      queryText: ValueReaders.stringValue(json['query_text']).trim(),
      projectId: ValueReaders.stringValue(json['project_id']).trim(),
      corpusFilters: ValueReaders.objectList(json['corpus_filters'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      sourceFilters: ValueReaders.objectList(json['source_filters'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      language: ValueReaders.stringValue(json['language']).trim(),
      topK: ValueReaders.intValue(json['top_k'], 20),
      queryMode: ValueReaders.stringValue(json['query_mode']).trim(),
      rerankPolicy: ValueReaders.stringValue(json['rerank_policy']).trim(),
      evidenceBudget: ValueReaders.intValue(json['evidence_budget']),
      metadata: _retrievalQueryCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: const <String>{
          'query_id',
          'query_text',
          'project_id',
          'corpus_filters',
          'source_filters',
          'language',
          'top_k',
          'query_mode',
          'rerank_policy',
          'evidence_budget',
          'metadata',
        },
      ),
    );
  }

  JsonMap toJson() {
    return _retrievalQueryCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'query_id': queryId,
        'query_text': queryText,
        'project_id': projectId,
        'corpus_filters': corpusFilters.toList(growable: false),
        'source_filters': sourceFilters.toList(growable: false),
        'language': language,
        'top_k': topK,
        'query_mode': queryMode,
        'rerank_policy': rerankPolicy,
        'evidence_budget': evidenceBudget,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 检索请求至少要能定位到一条文本和一个查询身份。
    final result = <String>[];
    result.addAll(
      _retrievalQueryValidatorService.requireNonBlankString(
        queryId,
        RagValidationCodes.missingRetrievalQueryId,
      ),
    );
    result.addAll(
      _retrievalQueryValidatorService.requireNonBlankString(
        queryText,
        RagValidationCodes.missingRetrievalQueryText,
      ),
    );
    return result;
  }
}

const _retrievalHitCodecService = OpenJsonContractCodecService();
const _retrievalHitValidatorService = OpenJsonStructureValidatorService();

class RetrievalHit {
  const RetrievalHit({
    required this.hitId,
    required this.corpusId,
    required this.sourceDocumentId,
    this.score = 0,
    this.rerankScore = 0,
    this.excerpt = '',
    this.rangeStart = 0,
    this.rangeEnd = 0,
    this.chapterTitle = '',
    this.evidencePath = '',
    this.metadata = const <String, Object?>{},
  });

  final RetrievalHitId hitId;
  final RagCorpusId corpusId;
  final RagSourceDocumentId sourceDocumentId;
  final double score;
  final double rerankScore;
  final String excerpt;
  final int rangeStart;
  final int rangeEnd;
  final String chapterTitle;
  final String evidencePath;
  final JsonMap metadata;

  factory RetrievalHit.fromJson(JsonMap json) {
    // 中文注释: 命中结果保留可引用片段与路径，避免把原始 backend 结构直接泄露给宿主。
    return RetrievalHit(
      hitId: ValueReaders.stringValue(json['hit_id']).trim(),
      corpusId: ValueReaders.stringValue(json['corpus_id']).trim(),
      sourceDocumentId: ValueReaders.stringValue(
        json['source_document_id'],
      ).trim(),
      score: ValueReaders.doubleValue(json['score']),
      rerankScore: ValueReaders.doubleValue(json['rerank_score']),
      excerpt: ValueReaders.stringValue(json['excerpt']).trim(),
      rangeStart: ValueReaders.intValue(json['range_start']),
      rangeEnd: ValueReaders.intValue(json['range_end']),
      chapterTitle: ValueReaders.stringValue(json['chapter_title']).trim(),
      evidencePath: ValueReaders.stringValue(json['evidence_path']).trim(),
      metadata: _retrievalHitCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: const <String>{
          'hit_id',
          'corpus_id',
          'source_document_id',
          'score',
          'rerank_score',
          'excerpt',
          'range_start',
          'range_end',
          'chapter_title',
          'evidence_path',
          'metadata',
        },
      ),
    );
  }

  JsonMap toJson() {
    return _retrievalHitCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'hit_id': hitId,
        'corpus_id': corpusId,
        'source_document_id': sourceDocumentId,
        'score': score,
        'rerank_score': rerankScore,
        'excerpt': excerpt,
        'range_start': rangeStart,
        'range_end': rangeEnd,
        'chapter_title': chapterTitle,
        'evidence_path': evidencePath,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 命中结果必须可定位到来源，否则召回片段无法被复核。
    final result = <String>[];
    result.addAll(
      _retrievalHitValidatorService.requireNonBlankString(
        hitId,
        RagValidationCodes.missingRetrievalHitId,
      ),
    );
    result.addAll(
      _retrievalHitValidatorService.requireNonBlankString(
        corpusId,
        RagValidationCodes.missingRetrievalHitCorpusId,
      ),
    );
    result.addAll(
      _retrievalHitValidatorService.requireNonBlankString(
        sourceDocumentId,
        RagValidationCodes.missingRetrievalHitSourceDocumentId,
      ),
    );
    return result;
  }
}

const _retrievalActivationPackageCodecService = OpenJsonContractCodecService();
const _retrievalActivationPackageValidatorService =
    OpenJsonStructureValidatorService();

class RetrievalActivationPackage {
  const RetrievalActivationPackage({
    required this.activationPackageId,
    required this.querySummary,
    this.selectedHits = const <RetrievalHit>[],
    this.sourceSummaries = const <String>[],
    this.warningNotes = const <String>[],
    this.citationPaths = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final RetrievalActivationPackageId activationPackageId;
  final String querySummary;
  final List<RetrievalHit> selectedHits;
  final List<String> sourceSummaries;
  final List<String> warningNotes;
  final List<String> citationPaths;
  final JsonMap metadata;

  factory RetrievalActivationPackage.fromJson(JsonMap json) {
    // 中文注释: 激活包是给上层消费的正式结果，不直接把原始 hit 列表裸露给 prompt。
    return RetrievalActivationPackage(
      activationPackageId: ValueReaders.stringValue(
        json['activation_package_id'],
      ).trim(),
      querySummary: ValueReaders.stringValue(json['query_summary']).trim(),
      selectedHits: ValueReaders.mapList(json['selected_hits'])
          .map(RetrievalHit.fromJson)
          .toList(growable: false),
      sourceSummaries: ValueReaders.objectList(json['source_summaries'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      warningNotes: ValueReaders.objectList(json['warning_notes'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      citationPaths: ValueReaders.objectList(json['citation_paths'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      metadata: _retrievalActivationPackageCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: const <String>{
              'activation_package_id',
              'query_summary',
              'selected_hits',
              'source_summaries',
              'warning_notes',
              'citation_paths',
              'metadata',
            },
          ),
    );
  }

  JsonMap toJson() {
    return _retrievalActivationPackageCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'activation_package_id': activationPackageId,
        'query_summary': querySummary,
        'selected_hits': selectedHits
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'source_summaries': sourceSummaries.toList(growable: false),
        'warning_notes': warningNotes.toList(growable: false),
        'citation_paths': citationPaths.toList(growable: false),
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 激活包至少要能说明自己是谁、以及这次查询的总结是什么。
    final result = <String>[];
    result.addAll(
      _retrievalActivationPackageValidatorService.requireNonBlankString(
        activationPackageId,
        RagValidationCodes.missingRetrievalActivationPackageId,
      ),
    );
    result.addAll(
      _retrievalActivationPackageValidatorService.requireNonBlankString(
        querySummary,
        RagValidationCodes.missingRetrievalActivationPackageQuerySummary,
      ),
    );
    return result;
  }
}

