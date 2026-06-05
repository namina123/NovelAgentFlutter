import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import 'information_usage_policy.dart';
import 'information_validation_codes.dart';

const _researchNoteCodecService = OpenJsonContractCodecService();
const _researchNoteValidatorService = OpenJsonStructureValidatorService();
const _researchNoteKnownFields = <String>{
  'research_id',
  'query',
  'source_kind',
  'source_url_or_ref',
  'citation',
  'summary',
  'usable_facts',
  'creative_suggestions',
  'uncertainty',
  'license_or_usage_note',
  'created_by',
  'linked_cards',
  'usage_policy',
  'schema_version',
  'metadata',
};

class ResearchNote {
  const ResearchNote({
    required this.researchId,
    required this.query,
    required this.sourceKind,
    required this.sourceUrlOrRef,
    required this.citation,
    required this.summary,
    required this.createdBy,
    required this.usagePolicy,
    this.usableFacts = const <Object?>[],
    this.creativeSuggestions = const <Object?>[],
    this.uncertainty = '',
    this.licenseOrUsageNote = '',
    this.linkedCards = const <NarrativeRef>[],
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String researchId;
  final String query;
  final String sourceKind;
  final String sourceUrlOrRef;
  final String citation;
  final String summary;
  final List<Object?> usableFacts;
  final List<Object?> creativeSuggestions;
  final String uncertainty;
  final String licenseOrUsageNote;
  final String createdBy;
  final List<NarrativeRef> linkedCards;
  final InformationUsagePolicy usagePolicy;
  final String schemaVersion;
  final JsonMap metadata;

  ResearchNote copyWith({
    String? researchId,
    String? query,
    String? sourceKind,
    String? sourceUrlOrRef,
    String? citation,
    String? summary,
    List<Object?>? usableFacts,
    List<Object?>? creativeSuggestions,
    String? uncertainty,
    String? licenseOrUsageNote,
    String? createdBy,
    List<NarrativeRef>? linkedCards,
    InformationUsagePolicy? usagePolicy,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: 研究笔记会在摘要整理、用户确认和后续提升阶段被增量修补，这里统一提供稳定 copy 入口。
    return ResearchNote(
      researchId: researchId ?? this.researchId,
      query: query ?? this.query,
      sourceKind: sourceKind ?? this.sourceKind,
      sourceUrlOrRef: sourceUrlOrRef ?? this.sourceUrlOrRef,
      citation: citation ?? this.citation,
      summary: summary ?? this.summary,
      usableFacts: usableFacts ?? this.usableFacts,
      creativeSuggestions: creativeSuggestions ?? this.creativeSuggestions,
      uncertainty: uncertainty ?? this.uncertainty,
      licenseOrUsageNote: licenseOrUsageNote ?? this.licenseOrUsageNote,
      createdBy: createdBy ?? this.createdBy,
      linkedCards: linkedCards ?? this.linkedCards,
      usagePolicy: usagePolicy ?? this.usagePolicy,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ResearchNote.fromJson(JsonMap json) {
    // 中文注释: usable_facts 与 creative_suggestions 明确分开，避免研究事实和创作启发重新混回同一字段。
    return ResearchNote(
      researchId: ValueReaders.stringValue(json['research_id']).trim(),
      query: ValueReaders.stringValue(json['query']).trim(),
      sourceKind: ValueReaders.stringValue(json['source_kind']).trim(),
      sourceUrlOrRef: ValueReaders.stringValue(
        json['source_url_or_ref'],
      ).trim(),
      citation: ValueReaders.stringValue(json['citation']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      usableFacts: ValueReaders.deepCopyList(
        ValueReaders.objectList(json['usable_facts']),
      ),
      creativeSuggestions: ValueReaders.deepCopyList(
        ValueReaders.objectList(json['creative_suggestions']),
      ),
      uncertainty: ValueReaders.stringValue(json['uncertainty']).trim(),
      licenseOrUsageNote: ValueReaders.stringValue(
        json['license_or_usage_note'],
      ).trim(),
      createdBy: ValueReaders.stringValue(json['created_by']).trim(),
      linkedCards: ValueReaders.mapList(
        json['linked_cards'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      usagePolicy: InformationUsagePolicy.fromJson(
        ValueReaders.mapValue(json['usage_policy']),
      ),
      schemaVersion: _researchNoteCodecService.readSchemaVersion(json),
      metadata: _researchNoteCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _researchNoteKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 输出时固定研究笔记壳层，但事实列表和创作建议继续允许开放结构。
    return _researchNoteCodecService.encodeWithUnknownFields(<String, Object?>{
      'research_id': researchId,
      'query': query,
      'source_kind': sourceKind,
      'source_url_or_ref': sourceUrlOrRef,
      'citation': citation,
      'summary': summary,
      'usable_facts': ValueReaders.deepCopyList(usableFacts),
      'creative_suggestions': ValueReaders.deepCopyList(creativeSuggestions),
      'uncertainty': uncertainty,
      'license_or_usage_note': licenseOrUsageNote,
      'created_by': createdBy,
      'linked_cards': linkedCards
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'usage_policy': usagePolicy.toJson(),
      'schema_version': schemaVersion,
    }, metadata: metadata);
  }

  List<String> validateBasics() {
    // 中文注释: 这里只校验研究笔记的最小可追溯合同，不在这里实现联网、版权审批或知识卡提升。
    final result = <String>[];
    result.addAll(
      _researchNoteValidatorService.requireNonBlankString(
        researchId,
        InformationValidationCodes.missingResearchNoteId,
      ),
    );
    result.addAll(
      _researchNoteValidatorService.requireNonBlankString(
        query,
        InformationValidationCodes.missingResearchNoteQuery,
      ),
    );
    result.addAll(
      _researchNoteValidatorService.requireNonBlankString(
        sourceKind,
        InformationValidationCodes.missingResearchNoteSourceKind,
      ),
    );
    result.addAll(
      _researchNoteValidatorService.requireNonBlankString(
        sourceUrlOrRef,
        InformationValidationCodes.missingResearchNoteSourceUrlOrRef,
      ),
    );
    result.addAll(
      _researchNoteValidatorService.requireNonBlankString(
        citation,
        InformationValidationCodes.missingResearchNoteCitation,
      ),
    );
    result.addAll(
      _researchNoteValidatorService.requireNonBlankString(
        summary,
        InformationValidationCodes.missingResearchNoteSummary,
      ),
    );
    result.addAll(
      _researchNoteValidatorService.requireNonBlankString(
        createdBy,
        InformationValidationCodes.missingResearchNoteCreatedBy,
      ),
    );
    result.addAll(usagePolicy.validateBasics());
    return result;
  }
}
