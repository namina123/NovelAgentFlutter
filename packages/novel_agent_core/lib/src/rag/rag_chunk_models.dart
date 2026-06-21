import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'rag_contract_typedefs.dart';
import 'rag_validation_codes.dart';

const _ragChunkCodecService = OpenJsonContractCodecService();
const _ragChunkValidatorService = OpenJsonStructureValidatorService();
const _ragChunkKnownFields = <String>{
  'chunk_id',
  'corpus_id',
  'source_document_id',
  'chapter_index',
  'chapter_title',
  'segment_index',
  'text',
  'normalized_text',
  'token_estimate',
  'range_start',
  'range_end',
  'metadata',
};

class RagChunk {
  const RagChunk({
    required this.chunkId,
    required this.corpusId,
    required this.sourceDocumentId,
    required this.text,
    this.chapterIndex = 0,
    this.chapterTitle = '',
    this.segmentIndex = 0,
    this.normalizedText = '',
    this.tokenEstimate = 0,
    this.rangeStart = 0,
    this.rangeEnd = 0,
    this.metadata = const <String, Object?>{},
  });

  final RagChunkId chunkId;
  final RagCorpusId corpusId;
  final RagSourceDocumentId sourceDocumentId;
  final int chapterIndex;
  final String chapterTitle;
  final int segmentIndex;
  final String text;
  final String normalizedText;
  final int tokenEstimate;
  final int rangeStart;
  final int rangeEnd;
  final JsonMap metadata;

  /// 复制 chunk 并替换部分字段；主要用于 ingestion 写入 embedding 时附加 metadata。
  RagChunk copyWith({JsonMap? metadata}) {
    return RagChunk(
      chunkId: chunkId,
      corpusId: corpusId,
      sourceDocumentId: sourceDocumentId,
      text: text,
      chapterIndex: chapterIndex,
      chapterTitle: chapterTitle,
      segmentIndex: segmentIndex,
      normalizedText: normalizedText,
      tokenEstimate: tokenEstimate,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      metadata: metadata ?? this.metadata,
    );
  }

  factory RagChunk.fromJson(JsonMap json) {
    // 中文注释: chunk 是检索最小单元，所以保持纯数据映射，不在这里引入任何索引后端语义。
    return RagChunk(
      chunkId: ValueReaders.stringValue(json['chunk_id']).trim(),
      corpusId: ValueReaders.stringValue(json['corpus_id']).trim(),
      sourceDocumentId: ValueReaders.stringValue(
        json['source_document_id'],
      ).trim(),
      chapterIndex: ValueReaders.intValue(json['chapter_index']),
      chapterTitle: ValueReaders.stringValue(json['chapter_title']).trim(),
      segmentIndex: ValueReaders.intValue(json['segment_index']),
      text: ValueReaders.stringValue(json['text']).trim(),
      normalizedText: ValueReaders.stringValue(
        json['normalized_text'],
      ).trim(),
      tokenEstimate: ValueReaders.intValue(json['token_estimate']),
      rangeStart: ValueReaders.intValue(json['range_start']),
      rangeEnd: ValueReaders.intValue(json['range_end']),
      metadata: _ragChunkCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _ragChunkKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _ragChunkCodecService.encodeWithUnknownFields(<String, Object?>{
      'chunk_id': chunkId,
      'corpus_id': corpusId,
      'source_document_id': sourceDocumentId,
      'chapter_index': chapterIndex,
      'chapter_title': chapterTitle,
      'segment_index': segmentIndex,
      'text': text,
      'normalized_text': normalizedText,
      'token_estimate': tokenEstimate,
      'range_start': rangeStart,
      'range_end': rangeEnd,
    }, metadata: metadata);
  }

  List<String> validateBasics() {
    // 中文注释: 这里只验证 chunk 的身份与归属，避免把内容质量规则混进基础合同。
    final result = <String>[];
    result.addAll(
      _ragChunkValidatorService.requireNonBlankString(
        chunkId,
        RagValidationCodes.missingRagChunkId,
      ),
    );
    result.addAll(
      _ragChunkValidatorService.requireNonBlankString(
        corpusId,
        RagValidationCodes.missingRagChunkCorpusId,
      ),
    );
    result.addAll(
      _ragChunkValidatorService.requireNonBlankString(
        sourceDocumentId,
        RagValidationCodes.missingRagChunkSourceDocumentId,
      ),
    );
    return result;
  }
}

const _ragChunkBuildResultCodecService = OpenJsonContractCodecService();
const _ragChunkBuildResultValidatorService = OpenJsonStructureValidatorService();

class RagChunkBuildResult {
  const RagChunkBuildResult({
    required this.chunkBuildResultId,
    required this.corpusId,
    required this.sourceDocumentId,
    this.chunkStrategy = '',
    this.chunks = const <RagChunk>[],
    this.warnings = const <String>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final RagChunkBuildResultId chunkBuildResultId;
  final RagCorpusId corpusId;
  final RagSourceDocumentId sourceDocumentId;
  final String chunkStrategy;
  final List<RagChunk> chunks;
  final List<String> warnings;
  final String notes;
  final JsonMap metadata;

  factory RagChunkBuildResult.fromJson(JsonMap json) {
    // 中文注释: chunk 构建结果把中间态和最终 chunk 一起保存，便于重跑和诊断。
    return RagChunkBuildResult(
      chunkBuildResultId: ValueReaders.stringValue(
        json['chunk_build_result_id'],
      ).trim(),
      corpusId: ValueReaders.stringValue(json['corpus_id']).trim(),
      sourceDocumentId: ValueReaders.stringValue(
        json['source_document_id'],
      ).trim(),
      chunkStrategy: ValueReaders.stringValue(json['chunk_strategy']).trim(),
      chunks: ValueReaders.mapList(json['chunks'])
          .map(RagChunk.fromJson)
          .toList(growable: false),
      warnings: ValueReaders.objectList(json['warnings'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      notes: ValueReaders.stringValue(json['notes']).trim(),
      metadata: _ragChunkBuildResultCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: const <String>{
          'chunk_build_result_id',
          'corpus_id',
          'source_document_id',
          'chunk_strategy',
          'chunks',
          'warnings',
          'notes',
          'metadata',
        },
      ),
    );
  }

  JsonMap toJson() {
    return _ragChunkBuildResultCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'chunk_build_result_id': chunkBuildResultId,
        'corpus_id': corpusId,
        'source_document_id': sourceDocumentId,
        'chunk_strategy': chunkStrategy,
        'chunks': chunks.map((entry) => entry.toJson()).toList(growable: false),
        'warnings': warnings.toList(growable: false),
        'notes': notes,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 结果包只保证身份字段存在，具体 chunk 内容仍交给 chunk 自己校验。
    final result = <String>[];
    result.addAll(
      _ragChunkBuildResultValidatorService.requireNonBlankString(
        chunkBuildResultId,
        RagValidationCodes.missingRagChunkBuildResultId,
      ),
    );
    result.addAll(
      _ragChunkBuildResultValidatorService.requireNonBlankString(
        corpusId,
        RagValidationCodes.missingRagChunkBuildResultCorpusId,
      ),
    );
    result.addAll(
      _ragChunkBuildResultValidatorService.requireNonBlankString(
        sourceDocumentId,
        RagValidationCodes.missingRagChunkBuildResultSourceDocumentId,
      ),
    );
    result.addAll(
      _ragChunkBuildResultValidatorService.requireNonBlankString(
        chunkStrategy,
        RagValidationCodes.missingRagChunkBuildResultStrategy,
      ),
    );
    return result;
  }
}
