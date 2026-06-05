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

const _designElementCardCodecService = OpenJsonContractCodecService();
const _designElementCardValidatorService = OpenJsonStructureValidatorService();
const _designElementCardKnownFields = <String>{
  'design_id',
  'design_namespace',
  'design_label',
  'design_payload',
  'source_refs',
  'evidence_refs',
  'scope_refs',
  'linked_refs',
  'activation_policy',
  'usage_policy',
  'confidence',
  'uncertainty',
  'lifecycle_status',
  'schema_version',
  'metadata',
};

class DesignElementCard {
  const DesignElementCard({
    required this.designId,
    required this.designNamespace,
    required this.designLabel,
    required this.designPayload,
    required this.sourceRefs,
    required this.activationPolicy,
    required this.usagePolicy,
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.scopeRefs = const <NarrativeRef>[],
    this.linkedRefs = const <NarrativeRef>[],
    this.confidence = 0,
    this.uncertainty = '',
    this.lifecycleStatus = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String designId;
  final String designNamespace;
  final String designLabel;
  final JsonMap designPayload;
  final List<InformationSourceRef> sourceRefs;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final List<NarrativeRef> scopeRefs;
  final List<NarrativeRef> linkedRefs;
  final InformationActivationPolicy activationPolicy;
  final InformationUsagePolicy usagePolicy;
  final double confidence;
  final String uncertainty;
  final String lifecycleStatus;
  final String schemaVersion;
  final JsonMap metadata;

  DesignElementCard copyWith({
    String? designId,
    String? designNamespace,
    String? designLabel,
    JsonMap? designPayload,
    List<InformationSourceRef>? sourceRefs,
    List<NarrativeEvidenceRef>? evidenceRefs,
    List<NarrativeRef>? scopeRefs,
    List<NarrativeRef>? linkedRefs,
    InformationActivationPolicy? activationPolicy,
    InformationUsagePolicy? usagePolicy,
    double? confidence,
    String? uncertainty,
    String? lifecycleStatus,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: 设计元素卡会在提案、确认和后续续写复用时被局部修补，这里统一提供稳定 copy 入口。
    return DesignElementCard(
      designId: designId ?? this.designId,
      designNamespace: designNamespace ?? this.designNamespace,
      designLabel: designLabel ?? this.designLabel,
      designPayload: designPayload ?? this.designPayload,
      sourceRefs: sourceRefs ?? this.sourceRefs,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      scopeRefs: scopeRefs ?? this.scopeRefs,
      linkedRefs: linkedRefs ?? this.linkedRefs,
      activationPolicy: activationPolicy ?? this.activationPolicy,
      usagePolicy: usagePolicy ?? this.usagePolicy,
      confidence: confidence ?? this.confidence,
      uncertainty: uncertainty ?? this.uncertainty,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory DesignElementCard.fromJson(JsonMap json) {
    // 中文注释: design_payload 和 design_label 保持开放，避免把巧思/结构设计提前固化成固定分类表。
    return DesignElementCard(
      designId: ValueReaders.stringValue(json['design_id']).trim(),
      designNamespace: ValueReaders.stringValue(
        json['design_namespace'],
      ).trim(),
      designLabel: ValueReaders.stringValue(json['design_label']).trim(),
      designPayload: _designElementCardCodecService.readOpenMap(
        json['design_payload'],
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
      linkedRefs: ValueReaders.mapList(
        json['linked_refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      activationPolicy: InformationActivationPolicy.fromJson(
        ValueReaders.mapValue(json['activation_policy']),
      ),
      usagePolicy: InformationUsagePolicy.fromJson(
        ValueReaders.mapValue(json['usage_policy']),
      ),
      confidence: ValueReaders.doubleValue(json['confidence']),
      uncertainty: ValueReaders.stringValue(json['uncertainty']).trim(),
      lifecycleStatus: ValueReaders.stringValue(
        json['lifecycle_status'],
      ).trim(),
      schemaVersion: _designElementCardCodecService.readSchemaVersion(json),
      metadata: _designElementCardCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _designElementCardKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 输出时保持壳层稳定，但 design payload 与 linked refs 继续保持开放可扩展。
    return _designElementCardCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'design_id': designId,
          'design_namespace': designNamespace,
          'design_label': designLabel,
          'design_payload': ValueReaders.deepCopyMap(designPayload),
          'source_refs': sourceRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'evidence_refs': evidenceRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'scope_refs': scopeRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'linked_refs': linkedRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'activation_policy': activationPolicy.toJson(),
          'usage_policy': usagePolicy.toJson(),
          'confidence': confidence,
          'uncertainty': uncertainty,
          'lifecycle_status': lifecycleStatus,
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    // 中文注释: 这里只做设计元素卡最小合同校验，不在这里实现分类、冲突判断或桥接逻辑。
    final result = <String>[];
    result.addAll(
      _designElementCardValidatorService.requireNonBlankString(
        designId,
        InformationValidationCodes.missingDesignElementId,
      ),
    );
    result.addAll(
      _designElementCardValidatorService.requireNonBlankString(
        designNamespace,
        InformationValidationCodes.missingDesignElementNamespace,
      ),
    );
    result.addAll(
      _designElementCardValidatorService.requireNonBlankString(
        designLabel,
        InformationValidationCodes.missingDesignElementLabel,
      ),
    );
    result.addAll(
      _designElementCardValidatorService.requireNonEmptyCollection(
        sourceRefs,
        InformationValidationCodes.missingDesignElementSourceRef,
      ),
    );
    result.addAll(
      _designElementCardValidatorService.requireNonBlankString(
        lifecycleStatus,
        InformationValidationCodes.missingDesignElementLifecycleStatus,
      ),
    );
    result.addAll(
      _designElementCardValidatorService.validateConfidence(
        confidence,
        InformationValidationCodes.invalidDesignElementConfidence,
      ),
    );
    result.addAll(activationPolicy.validateBasics());
    result.addAll(usagePolicy.validateBasics());
    return result;
  }
}
