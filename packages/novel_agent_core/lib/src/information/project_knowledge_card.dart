import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_evidence_ref.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import 'information_activation_policy.dart';
import 'information_source_ref.dart';
import 'information_usage_policy.dart';
import 'information_validation_codes.dart';

const _projectKnowledgeCardCodecService = OpenJsonContractCodecService();
const _projectKnowledgeCardValidatorService =
    OpenJsonStructureValidatorService();
const _projectKnowledgeCardKnownFields = <String>{
  'card_id',
  'card_namespace',
  'card_type',
  'title',
  'summary',
  'content_payload',
  'source_refs',
  'evidence_refs',
  'scope_refs',
  'activation_policy',
  'usage_policy',
  'confidence',
  'lifecycle_status',
  'schema_version',
  'metadata',
};

class ProjectKnowledgeCard {
  const ProjectKnowledgeCard({
    required this.cardId,
    required this.cardNamespace,
    required this.cardType,
    required this.title,
    required this.contentPayload,
    required this.sourceRefs,
    required this.activationPolicy,
    required this.usagePolicy,
    this.summary = '',
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.scopeRefs = const <NarrativeRef>[],
    this.confidence = 0,
    this.lifecycleStatus = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String cardId;
  final String cardNamespace;
  final String cardType;
  final String title;
  final String summary;
  final JsonMap contentPayload;
  final List<InformationSourceRef> sourceRefs;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final List<NarrativeRef> scopeRefs;
  final InformationActivationPolicy activationPolicy;
  final InformationUsagePolicy usagePolicy;
  final double confidence;
  final String lifecycleStatus;
  final String schemaVersion;
  final JsonMap metadata;

  ProjectKnowledgeCard copyWith({
    String? cardId,
    String? cardNamespace,
    String? cardType,
    String? title,
    String? summary,
    JsonMap? contentPayload,
    List<InformationSourceRef>? sourceRefs,
    List<NarrativeEvidenceRef>? evidenceRefs,
    List<NarrativeRef>? scopeRefs,
    InformationActivationPolicy? activationPolicy,
    InformationUsagePolicy? usagePolicy,
    double? confidence,
    String? lifecycleStatus,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: 知识卡会在 proposal、确认和后续投影中被局部修补，这里统一提供稳定 copy 入口。
    return ProjectKnowledgeCard(
      cardId: cardId ?? this.cardId,
      cardNamespace: cardNamespace ?? this.cardNamespace,
      cardType: cardType ?? this.cardType,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      contentPayload: contentPayload ?? this.contentPayload,
      sourceRefs: sourceRefs ?? this.sourceRefs,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      scopeRefs: scopeRefs ?? this.scopeRefs,
      activationPolicy: activationPolicy ?? this.activationPolicy,
      usagePolicy: usagePolicy ?? this.usagePolicy,
      confidence: confidence ?? this.confidence,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ProjectKnowledgeCard.fromJson(JsonMap json) {
    // 中文注释: content_payload 和 card_type 都保持开放，避免题材或文化信息被固定字段表提前锁死。
    return ProjectKnowledgeCard(
      cardId: ValueReaders.stringValue(json['card_id']).trim(),
      cardNamespace: ValueReaders.stringValue(json['card_namespace']).trim(),
      cardType: ValueReaders.stringValue(json['card_type']).trim(),
      title: ValueReaders.stringValue(json['title']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      contentPayload: _projectKnowledgeCardCodecService.readOpenMap(
        json['content_payload'],
      ),
      sourceRefs: ValueReaders.mapList(
        json['source_refs'],
      ).map(InformationSourceRef.fromJson).toList(growable: false),
      evidenceRefs: ValueReaders.mapList(
        json['evidence_refs'],
      ).map(NarrativeEvidenceRef.fromJson).toList(growable: false),
      scopeRefs: ValueReaders.mapList(
        json['scope_refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      activationPolicy: InformationActivationPolicy.fromJson(
        ValueReaders.mapValue(json['activation_policy']),
      ),
      usagePolicy: InformationUsagePolicy.fromJson(
        ValueReaders.mapValue(json['usage_policy']),
      ),
      confidence: ValueReaders.doubleValue(json['confidence']),
      lifecycleStatus: ValueReaders.stringValue(
        json['lifecycle_status'],
      ).trim(),
      schemaVersion: _projectKnowledgeCardCodecService.readSchemaVersion(json),
      metadata: _projectKnowledgeCardCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _projectKnowledgeCardKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 输出时固定壳层字段稳定，但 payload/source/evidence 继续保持开放结构。
    return _projectKnowledgeCardCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'card_id': cardId,
          'card_namespace': cardNamespace,
          'card_type': cardType,
          'title': title,
          'summary': summary,
          'content_payload': ValueReaders.deepCopyMap(contentPayload),
          'source_refs': sourceRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'evidence_refs': evidenceRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'scope_refs': scopeRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'activation_policy': activationPolicy.toJson(),
          'usage_policy': usagePolicy.toJson(),
          'confidence': confidence,
          'lifecycle_status': lifecycleStatus,
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    // 中文注释: 这里只做知识卡最小合同校验，不在这里引入语义理解、冲突裁决或权限执行。
    final result = <String>[];
    result.addAll(
      _projectKnowledgeCardValidatorService.requireNonBlankString(
        cardId,
        InformationValidationCodes.missingKnowledgeCardId,
      ),
    );
    result.addAll(
      _projectKnowledgeCardValidatorService.requireNonBlankString(
        cardNamespace,
        InformationValidationCodes.missingKnowledgeCardNamespace,
      ),
    );
    result.addAll(
      _projectKnowledgeCardValidatorService.requireNonBlankString(
        cardType,
        InformationValidationCodes.missingKnowledgeCardType,
      ),
    );
    result.addAll(
      _projectKnowledgeCardValidatorService.requireNonBlankString(
        title,
        InformationValidationCodes.missingKnowledgeCardTitle,
      ),
    );
    result.addAll(
      _projectKnowledgeCardValidatorService.requireNonEmptyCollection(
        sourceRefs,
        InformationValidationCodes.missingKnowledgeCardSourceRef,
      ),
    );
    result.addAll(
      _projectKnowledgeCardValidatorService.requireNonBlankString(
        lifecycleStatus,
        InformationValidationCodes.missingKnowledgeCardLifecycleStatus,
      ),
    );
    result.addAll(
      _projectKnowledgeCardValidatorService.validateConfidence(
        confidence,
        InformationValidationCodes.invalidKnowledgeCardConfidence,
      ),
    );
    result.addAll(activationPolicy.validateBasics());
    result.addAll(usagePolicy.validateBasics());
    return result;
  }
}
