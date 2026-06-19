import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'rag_chunk_models.dart';
import 'rag_contract_typedefs.dart';
import 'rag_corpus_models.dart';
import 'rag_source_models.dart';
import 'rag_validation_codes.dart';

abstract final class RagSegmentationStrategyKinds {
  static const String ruleChapter = 'rule_chapter';
  static const String modelChapter = 'model_chapter';
  static const String hybridChapter = 'hybrid_chapter';
}

abstract final class RagChunkStrategyKinds {
  static const String defaultOverlap = 'default_overlap';
  static const String chapterAligned = 'chapter_aligned';
  static const String segmentAligned = 'segment_aligned';
}

const _ragSegmentationSegmentCodecService = OpenJsonContractCodecService();
const _ragSegmentationSegmentValidatorService =
    OpenJsonStructureValidatorService();
const _ragSegmentationSegmentKnownFields = <String>{
  'segment_id',
  'source_document_id',
  'source_kind',
  'segment_index',
  'chapter_index',
  'chapter_title',
  'start_unit_index',
  'end_unit_index',
  'text',
  'normalized_text',
  'source_unit_ids',
  'has_model_assistance',
  'notes',
  'metadata',
};

class RagSegmentationSegment {
  const RagSegmentationSegment({
    required this.segmentId,
    required this.sourceDocumentId,
    required this.text,
    this.sourceKind = '',
    this.segmentIndex = 0,
    this.chapterIndex = 0,
    this.chapterTitle = '',
    this.startUnitIndex = 0,
    this.endUnitIndex = 0,
    this.normalizedText = '',
    this.sourceUnitIds = const <String>[],
    this.hasModelAssistance = false,
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final RagSegmentationSegmentId segmentId;
  final RagSourceDocumentId sourceDocumentId;
  final String sourceKind;
  final int segmentIndex;
  final int chapterIndex;
  final String chapterTitle;
  final int startUnitIndex;
  final int endUnitIndex;
  final String text;
  final String normalizedText;
  final List<String> sourceUnitIds;
  final bool hasModelAssistance;
  final String notes;
  final JsonMap metadata;

  factory RagSegmentationSegment.fromJson(JsonMap json) {
    // 中文注释: 分段结果要保留章节、索引和来源单元，方便后续 chunk 构建与回溯。
    return RagSegmentationSegment(
      segmentId: ValueReaders.stringValue(json['segment_id']).trim(),
      sourceDocumentId: ValueReaders.stringValue(
        json['source_document_id'],
      ).trim(),
      text: ValueReaders.stringValue(json['text']).trim(),
      sourceKind: ValueReaders.stringValue(json['source_kind']).trim(),
      segmentIndex: ValueReaders.intValue(json['segment_index']),
      chapterIndex: ValueReaders.intValue(json['chapter_index']),
      chapterTitle: ValueReaders.stringValue(json['chapter_title']).trim(),
      startUnitIndex: ValueReaders.intValue(json['start_unit_index']),
      endUnitIndex: ValueReaders.intValue(json['end_unit_index']),
      normalizedText: ValueReaders.stringValue(
        json['normalized_text'],
      ).trim(),
      sourceUnitIds: ValueReaders.objectList(json['source_unit_ids'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      hasModelAssistance: ValueReaders.boolValue(
        json['has_model_assistance'],
      ),
      notes: ValueReaders.stringValue(json['notes']).trim(),
      metadata: _ragSegmentationSegmentCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _ragSegmentationSegmentKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _ragSegmentationSegmentCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'segment_id': segmentId,
        'source_document_id': sourceDocumentId,
        'source_kind': sourceKind,
        'segment_index': segmentIndex,
        'chapter_index': chapterIndex,
        'chapter_title': chapterTitle,
        'start_unit_index': startUnitIndex,
        'end_unit_index': endUnitIndex,
        'text': text,
        'normalized_text': normalizedText,
        'source_unit_ids': sourceUnitIds.toList(growable: false),
        'has_model_assistance': hasModelAssistance,
        'notes': notes,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 分段合同至少要能说明自己是谁、来自哪份源文稿、承载了哪些正文。
    final result = <String>[];
    result.addAll(
      _ragSegmentationSegmentValidatorService.requireNonBlankString(
        segmentId,
        RagValidationCodes.missingRagSegmentationSegmentId,
      ),
    );
    result.addAll(
      _ragSegmentationSegmentValidatorService.requireNonBlankString(
        sourceDocumentId,
        RagValidationCodes.missingRagSegmentationSegmentSourceDocumentId,
      ),
    );
    result.addAll(
      _ragSegmentationSegmentValidatorService.requireNonBlankString(
        text,
        RagValidationCodes.missingRagSegmentationSegmentText,
      ),
    );
    return result;
  }
}

const _ragSegmentationResultCodecService = OpenJsonContractCodecService();
const _ragSegmentationResultValidatorService = OpenJsonStructureValidatorService();
const _ragSegmentationResultKnownFields = <String>{
  'segmentation_result_id',
  'corpus_id',
  'source_document_id',
  'source_kind',
  'segmentation_strategy',
  'used_model',
  'segments',
  'warnings',
  'notes',
  'metadata',
};

class RagSegmentationResult {
  const RagSegmentationResult({
    required this.segmentationResultId,
    required this.corpusId,
    required this.sourceDocumentId,
    required this.segments,
    this.sourceKind = '',
    this.segmentationStrategy = '',
    this.usedModel = false,
    this.warnings = const <String>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final RagSegmentationResultId segmentationResultId;
  final RagCorpusId corpusId;
  final RagSourceDocumentId sourceDocumentId;
  final String sourceKind;
  final String segmentationStrategy;
  final bool usedModel;
  final List<RagSegmentationSegment> segments;
  final List<String> warnings;
  final String notes;
  final JsonMap metadata;

  factory RagSegmentationResult.fromJson(JsonMap json) {
    // 中文注释: 分段结果只保存策略、切分片段与警告，不在这里混入 chunk 逻辑。
    return RagSegmentationResult(
      segmentationResultId: ValueReaders.stringValue(
        json['segmentation_result_id'],
      ).trim(),
      corpusId: ValueReaders.stringValue(json['corpus_id']).trim(),
      sourceDocumentId: ValueReaders.stringValue(
        json['source_document_id'],
      ).trim(),
      sourceKind: ValueReaders.stringValue(json['source_kind']).trim(),
      segmentationStrategy: ValueReaders.stringValue(
        json['segmentation_strategy'],
      ).trim(),
      usedModel: ValueReaders.boolValue(json['used_model']),
      segments: ValueReaders.mapList(json['segments'])
          .map(RagSegmentationSegment.fromJson)
          .toList(growable: false),
      warnings: ValueReaders.objectList(json['warnings'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      notes: ValueReaders.stringValue(json['notes']).trim(),
      metadata: _ragSegmentationResultCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _ragSegmentationResultKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _ragSegmentationResultCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'segmentation_result_id': segmentationResultId,
        'corpus_id': corpusId,
        'source_document_id': sourceDocumentId,
        'source_kind': sourceKind,
        'segmentation_strategy': segmentationStrategy,
        'used_model': usedModel,
        'segments': segments
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'warnings': warnings.toList(growable: false),
        'notes': notes,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 分段结果必须可追踪到 corpus、source 和具体策略。
    final result = <String>[];
    result.addAll(
      _ragSegmentationResultValidatorService.requireNonBlankString(
        segmentationResultId,
        RagValidationCodes.missingRagSegmentationResultId,
      ),
    );
    result.addAll(
      _ragSegmentationResultValidatorService.requireNonBlankString(
        corpusId,
        RagValidationCodes.missingRagSegmentationResultCorpusId,
      ),
    );
    result.addAll(
      _ragSegmentationResultValidatorService.requireNonBlankString(
        sourceDocumentId,
        RagValidationCodes.missingRagSegmentationResultSourceDocumentId,
      ),
    );
    result.addAll(
      _ragSegmentationResultValidatorService.requireNonBlankString(
        segmentationStrategy,
        RagValidationCodes.missingRagSegmentationResultStrategy,
      ),
    );
    return result;
  }
}

const _ragIngestionResultCodecService = OpenJsonContractCodecService();
const _ragIngestionResultValidatorService = OpenJsonStructureValidatorService();
const _ragIngestionResultKnownFields = <String>{
  'ingestion_result_id',
  'corpus_package',
  'normalized_sources',
  'segmentation_results',
  'chunk_build_results',
  'warnings',
  'notes',
  'metadata',
};

class RagIngestionResult {
  const RagIngestionResult({
    required this.ingestionResultId,
    required this.corpusPackage,
    this.normalizedSources = const <RagNormalizedSource>[],
    this.segmentationResults = const <RagSegmentationResult>[],
    this.chunkBuildResults = const <RagChunkBuildResult>[],
    this.warnings = const <String>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final RagIngestionResultId ingestionResultId;
  final RagCorpusPackage corpusPackage;
  final List<RagNormalizedSource> normalizedSources;
  final List<RagSegmentationResult> segmentationResults;
  final List<RagChunkBuildResult> chunkBuildResults;
  final List<String> warnings;
  final String notes;
  final JsonMap metadata;

  int get normalizedUnitCount => normalizedSources.fold<int>(
        0,
        (total, source) => total + source.normalizedUnits.length,
      );

  int get discardedUnitCount => normalizedSources.fold<int>(
        0,
        (total, source) => total + source.discardedUnits.length,
      );

  int get uncertainUnitCount => normalizedSources.fold<int>(
        0,
        (total, source) => total + source.uncertainUnits.length,
      );

  int get segmentCount =>
      segmentationResults.fold<int>(0, (total, result) => total + result.segments.length);

  int get chunkCount =>
      chunkBuildResults.fold<int>(0, (total, result) => total + result.chunks.length);

  factory RagIngestionResult.fromJson(JsonMap json) {
    // 中文注释: ingestion 结果把整条处理链的产物放在一起，方便宿主做摘要和恢复。
    return RagIngestionResult(
      ingestionResultId: ValueReaders.stringValue(
        json['ingestion_result_id'],
      ).trim(),
      corpusPackage: RagCorpusPackage.fromJson(
        ValueReaders.mapValue(json['corpus_package']),
      ),
      normalizedSources: ValueReaders.mapList(json['normalized_sources'])
          .map(RagNormalizedSource.fromJson)
          .toList(growable: false),
      segmentationResults: ValueReaders.mapList(json['segmentation_results'])
          .map(RagSegmentationResult.fromJson)
          .toList(growable: false),
      chunkBuildResults: ValueReaders.mapList(json['chunk_build_results'])
          .map(RagChunkBuildResult.fromJson)
          .toList(growable: false),
      warnings: ValueReaders.objectList(json['warnings'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      notes: ValueReaders.stringValue(json['notes']).trim(),
      metadata: _ragIngestionResultCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _ragIngestionResultKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _ragIngestionResultCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'ingestion_result_id': ingestionResultId,
        'corpus_package': corpusPackage.toJson(),
        'normalized_sources': normalizedSources
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'segmentation_results': segmentationResults
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'chunk_build_results': chunkBuildResults
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'warnings': warnings.toList(growable: false),
        'notes': notes,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: ingestion 结果至少要能追踪到 corpus 包和自身身份。
    final result = <String>[];
    result.addAll(
      _ragIngestionResultValidatorService.requireNonBlankString(
        ingestionResultId,
        RagValidationCodes.missingRagIngestionResultId,
      ),
    );
    result.addAll(corpusPackage.validateBasics());
    return result;
  }
}
