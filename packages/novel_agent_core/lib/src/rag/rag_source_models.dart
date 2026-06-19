import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'rag_contract_typedefs.dart';
import 'rag_validation_codes.dart';

abstract final class RagSourceKinds {
  static const String txt = 'txt';
  static const String md = 'md';
  static const String epub = 'epub';
  static const String folder = 'folder';
  static const String unknown = 'unknown';
}

abstract final class RagNormalizationStrategyKinds {
  static const String ruleBased = 'rule_based';
  static const String modelAssisted = 'model_assisted';
  static const String hybrid = 'hybrid';
}

const _ragSourceDocumentCodecService = OpenJsonContractCodecService();
const _ragSourceDocumentValidatorService = OpenJsonStructureValidatorService();
const _ragSourceDocumentKnownFields = <String>{
  'source_document_id',
  'corpus_id',
  'source_kind',
  'display_name',
  'origin_path',
  'origin_format',
  'language',
  'content_hash',
  'metadata',
};

class RagSourceDocument {
  const RagSourceDocument({
    required this.sourceDocumentId,
    required this.corpusId,
    required this.sourceKind,
    required this.displayName,
    required this.originPath,
    this.originFormat = '',
    this.language = '',
    this.contentHash = '',
    this.metadata = const <String, Object?>{},
  });

  final RagSourceDocumentId sourceDocumentId;
  final RagCorpusId corpusId;
  final String sourceKind;
  final String displayName;
  final String originPath;
  final String originFormat;
  final String language;
  final String contentHash;
  final JsonMap metadata;

  factory RagSourceDocument.fromJson(JsonMap json) {
    // 中文注释: 源文稿对象只描述来源，不提前写入任何标准化或分段结果。
    return RagSourceDocument(
      sourceDocumentId: ValueReaders.stringValue(
        json['source_document_id'],
      ).trim(),
      corpusId: ValueReaders.stringValue(json['corpus_id']).trim(),
      sourceKind: ValueReaders.stringValue(json['source_kind']).trim(),
      displayName: ValueReaders.stringValue(json['display_name']).trim(),
      originPath: ValueReaders.stringValue(json['origin_path']).trim(),
      originFormat: ValueReaders.stringValue(json['origin_format']).trim(),
      language: ValueReaders.stringValue(json['language']).trim(),
      contentHash: ValueReaders.stringValue(json['content_hash']).trim(),
      metadata: _ragSourceDocumentCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _ragSourceDocumentKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _ragSourceDocumentCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'source_document_id': sourceDocumentId,
        'corpus_id': corpusId,
        'source_kind': sourceKind,
        'display_name': displayName,
        'origin_path': originPath,
        'origin_format': originFormat,
        'language': language,
        'content_hash': contentHash,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 这里只确认源文稿身份与路径，来源内容质量另由标准化阶段判断。
    final result = <String>[];
    result.addAll(
      _ragSourceDocumentValidatorService.requireNonBlankString(
        sourceDocumentId,
        RagValidationCodes.missingRagSourceDocumentId,
      ),
    );
    result.addAll(
      _ragSourceDocumentValidatorService.requireNonBlankString(
        displayName,
        RagValidationCodes.missingRagSourceDocumentDisplayName,
      ),
    );
    result.addAll(
      _ragSourceDocumentValidatorService.requireNonBlankString(
        originPath,
        RagValidationCodes.missingRagSourceDocumentOriginPath,
      ),
    );
    return result;
  }
}

const _ragNormalizedSourceUnitCodecService = OpenJsonContractCodecService();
const _ragNormalizedSourceUnitValidatorService =
    OpenJsonStructureValidatorService();
const _ragNormalizedSourceUnitKnownFields = <String>{
  'unit_id',
  'normalized_text',
  'raw_text',
  'unit_kind',
  'source_offset_start',
  'source_offset_end',
  'confidence',
  'notes',
  'metadata',
};

class RagNormalizedSourceUnit {
  const RagNormalizedSourceUnit({
    required this.unitId,
    required this.normalizedText,
    this.rawText = '',
    this.unitKind = '',
    this.sourceOffsetStart = 0,
    this.sourceOffsetEnd = 0,
    this.confidence = 0,
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final RagNormalizedSourceUnitId unitId;
  final String normalizedText;
  final String rawText;
  final String unitKind;
  final int sourceOffsetStart;
  final int sourceOffsetEnd;
  final double confidence;
  final String notes;
  final JsonMap metadata;

  factory RagNormalizedSourceUnit.fromJson(JsonMap json) {
    // 中文注释: 正常化单元保留原文与规范文本，方便后续重跑和诊断差异。
    return RagNormalizedSourceUnit(
      unitId: ValueReaders.stringValue(json['unit_id']).trim(),
      normalizedText: ValueReaders.stringValue(json['normalized_text']).trim(),
      rawText: ValueReaders.stringValue(json['raw_text']).trim(),
      unitKind: ValueReaders.stringValue(json['unit_kind']).trim(),
      sourceOffsetStart: ValueReaders.intValue(json['source_offset_start']),
      sourceOffsetEnd: ValueReaders.intValue(json['source_offset_end']),
      confidence: ValueReaders.doubleValue(json['confidence']),
      notes: ValueReaders.stringValue(json['notes']).trim(),
      metadata: _ragNormalizedSourceUnitCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _ragNormalizedSourceUnitKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _ragNormalizedSourceUnitCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'unit_id': unitId,
        'normalized_text': normalizedText,
        'raw_text': rawText,
        'unit_kind': unitKind,
        'source_offset_start': sourceOffsetStart,
        'source_offset_end': sourceOffsetEnd,
        'confidence': confidence,
        'notes': notes,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 正常化单元至少要有身份和可消费文本，避免把空壳结果带下游。
    final result = <String>[];
    result.addAll(
      _ragNormalizedSourceUnitValidatorService.requireNonBlankString(
        unitId,
        RagValidationCodes.missingRagNormalizedSourceUnitId,
      ),
    );
    result.addAll(
      _ragNormalizedSourceUnitValidatorService.requireNonBlankString(
        normalizedText,
        RagValidationCodes.missingRagNormalizedSourceUnitText,
      ),
    );
    return result;
  }
}

const _ragDiscardedSourceUnitCodecService = OpenJsonContractCodecService();
const _ragDiscardedSourceUnitValidatorService =
    OpenJsonStructureValidatorService();
const _ragDiscardedSourceUnitKnownFields = <String>{
  'unit_id',
  'raw_text',
  'discard_reason',
  'strategy_id',
  'metadata',
};

class RagDiscardedSourceUnit {
  const RagDiscardedSourceUnit({
    required this.unitId,
    required this.rawText,
    required this.discardReason,
    this.strategyId = '',
    this.metadata = const <String, Object?>{},
  });

  final RagDiscardedSourceUnitId unitId;
  final String rawText;
  final String discardReason;
  final String strategyId;
  final JsonMap metadata;

  factory RagDiscardedSourceUnit.fromJson(JsonMap json) {
    // 中文注释: 被剔除的干扰块保留原因与策略，方便后续复盘规则。
    return RagDiscardedSourceUnit(
      unitId: ValueReaders.stringValue(json['unit_id']).trim(),
      rawText: ValueReaders.stringValue(json['raw_text']).trim(),
      discardReason: ValueReaders.stringValue(json['discard_reason']).trim(),
      strategyId: ValueReaders.stringValue(json['strategy_id']).trim(),
      metadata: _ragDiscardedSourceUnitCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _ragDiscardedSourceUnitKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _ragDiscardedSourceUnitCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'unit_id': unitId,
        'raw_text': rawText,
        'discard_reason': discardReason,
        'strategy_id': strategyId,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 干扰块必须有身份和原因，否则就只是无法解释的丢弃。
    final result = <String>[];
    result.addAll(
      _ragDiscardedSourceUnitValidatorService.requireNonBlankString(
        unitId,
        RagValidationCodes.missingRagDiscardedSourceUnitId,
      ),
    );
    result.addAll(
      _ragDiscardedSourceUnitValidatorService.requireNonBlankString(
        discardReason,
        RagValidationCodes.missingRagDiscardedSourceUnitReason,
      ),
    );
    return result;
  }
}

const _ragUncertainSourceUnitCodecService = OpenJsonContractCodecService();
const _ragUncertainSourceUnitValidatorService =
    OpenJsonStructureValidatorService();
const _ragUncertainSourceUnitKnownFields = <String>{
  'unit_id',
  'raw_text',
  'uncertainty_reason',
  'confidence',
  'strategy_id',
  'metadata',
};

class RagUncertainSourceUnit {
  const RagUncertainSourceUnit({
    required this.unitId,
    required this.rawText,
    required this.uncertaintyReason,
    this.confidence = 0,
    this.strategyId = '',
    this.metadata = const <String, Object?>{},
  });

  final RagUncertainSourceUnitId unitId;
  final String rawText;
  final String uncertaintyReason;
  final double confidence;
  final String strategyId;
  final JsonMap metadata;

  factory RagUncertainSourceUnit.fromJson(JsonMap json) {
    // 中文注释: 不确定块保留置信度与原因，避免把模型犹疑误写成确定结论。
    return RagUncertainSourceUnit(
      unitId: ValueReaders.stringValue(json['unit_id']).trim(),
      rawText: ValueReaders.stringValue(json['raw_text']).trim(),
      uncertaintyReason: ValueReaders.stringValue(
        json['uncertainty_reason'],
      ).trim(),
      confidence: ValueReaders.doubleValue(json['confidence']),
      strategyId: ValueReaders.stringValue(json['strategy_id']).trim(),
      metadata: _ragUncertainSourceUnitCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _ragUncertainSourceUnitKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _ragUncertainSourceUnitCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'unit_id': unitId,
        'raw_text': rawText,
        'uncertainty_reason': uncertaintyReason,
        'confidence': confidence,
        'strategy_id': strategyId,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 不确定块也必须能解释“为什么不确定”，否则会损失诊断价值。
    final result = <String>[];
    result.addAll(
      _ragUncertainSourceUnitValidatorService.requireNonBlankString(
        unitId,
        RagValidationCodes.missingRagUncertainSourceUnitId,
      ),
    );
    result.addAll(
      _ragUncertainSourceUnitValidatorService.requireNonBlankString(
        uncertaintyReason,
        RagValidationCodes.missingRagUncertainSourceUnitReason,
      ),
    );
    return result;
  }
}

const _ragNormalizedSourceCodecService = OpenJsonContractCodecService();
const _ragNormalizedSourceValidatorService = OpenJsonStructureValidatorService();
const _ragNormalizedSourceKnownFields = <String>{
  'normalized_source_id',
  'corpus_id',
  'source_document_id',
  'source_kind',
  'normalization_strategy',
  'used_model',
  'normalized_units',
  'discarded_units',
  'uncertain_units',
  'notes',
  'metadata',
};

class RagNormalizedSource {
  const RagNormalizedSource({
    required this.normalizedSourceId,
    required this.corpusId,
    required this.sourceDocumentId,
    required this.sourceKind,
    required this.normalizationStrategy,
    this.usedModel = false,
    this.normalizedUnits = const <RagNormalizedSourceUnit>[],
    this.discardedUnits = const <RagDiscardedSourceUnit>[],
    this.uncertainUnits = const <RagUncertainSourceUnit>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final RagNormalizedSourceId normalizedSourceId;
  final RagCorpusId corpusId;
  final RagSourceDocumentId sourceDocumentId;
  final String sourceKind;
  final String normalizationStrategy;
  final bool usedModel;
  final List<RagNormalizedSourceUnit> normalizedUnits;
  final List<RagDiscardedSourceUnit> discardedUnits;
  final List<RagUncertainSourceUnit> uncertainUnits;
  final String notes;
  final JsonMap metadata;

  factory RagNormalizedSource.fromJson(JsonMap json) {
    // 中文注释: 标准化结果要把保留、丢弃和不确定部分一起封装，便于后续复跑与人工审阅。
    return RagNormalizedSource(
      normalizedSourceId: ValueReaders.stringValue(
        json['normalized_source_id'],
      ).trim(),
      corpusId: ValueReaders.stringValue(json['corpus_id']).trim(),
      sourceDocumentId: ValueReaders.stringValue(
        json['source_document_id'],
      ).trim(),
      sourceKind: ValueReaders.stringValue(json['source_kind']).trim(),
      normalizationStrategy: ValueReaders.stringValue(
        json['normalization_strategy'],
      ).trim(),
      usedModel: ValueReaders.boolValue(json['used_model']),
      normalizedUnits: ValueReaders.mapList(json['normalized_units'])
          .map(RagNormalizedSourceUnit.fromJson)
          .toList(growable: false),
      discardedUnits: ValueReaders.mapList(json['discarded_units'])
          .map(RagDiscardedSourceUnit.fromJson)
          .toList(growable: false),
      uncertainUnits: ValueReaders.mapList(json['uncertain_units'])
          .map(RagUncertainSourceUnit.fromJson)
          .toList(growable: false),
      notes: ValueReaders.stringValue(json['notes']).trim(),
      metadata: _ragNormalizedSourceCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _ragNormalizedSourceKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _ragNormalizedSourceCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'normalized_source_id': normalizedSourceId,
        'corpus_id': corpusId,
        'source_document_id': sourceDocumentId,
        'source_kind': sourceKind,
        'normalization_strategy': normalizationStrategy,
        'used_model': usedModel,
        'normalized_units': normalizedUnits
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'discarded_units': discardedUnits
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'uncertain_units': uncertainUnits
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'notes': notes,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 标准化结果必须可追踪到 corpus 与 source，并说明采用了哪条策略。
    final result = <String>[];
    result.addAll(
      _ragNormalizedSourceValidatorService.requireNonBlankString(
        normalizedSourceId,
        RagValidationCodes.missingRagNormalizedSourceId,
      ),
    );
    result.addAll(
      _ragNormalizedSourceValidatorService.requireNonBlankString(
        corpusId,
        RagValidationCodes.missingRagNormalizedSourceCorpusId,
      ),
    );
    result.addAll(
      _ragNormalizedSourceValidatorService.requireNonBlankString(
        sourceDocumentId,
        RagValidationCodes.missingRagNormalizedSourceSourceDocumentId,
      ),
    );
    result.addAll(
      _ragNormalizedSourceValidatorService.requireNonBlankString(
        normalizationStrategy,
        RagValidationCodes.missingRagNormalizedSourceStrategy,
      ),
    );
    return result;
  }
}

