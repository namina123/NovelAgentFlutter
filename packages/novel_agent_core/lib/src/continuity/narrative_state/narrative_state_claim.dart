import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_evidence_ref.dart';
import 'narrative_ref.dart';
import 'narrative_source_ref.dart';
import 'narrative_state_claim_validation_codes.dart';

const _narrativeStateClaimCodecService = OpenJsonContractCodecService();
const _narrativeStateClaimValidatorService =
    OpenJsonStructureValidatorService();
const _narrativeStateClaimKnownFields = <String>{
  'claim_id',
  'claim_namespace',
  'claim_label',
  'claim_payload',
  'affected_refs',
  'context_refs',
  'evidence_refs',
  'source',
  'confidence',
  'uncertainty',
  'schema_version',
  'metadata',
};

class NarrativeStateClaim {
  const NarrativeStateClaim({
    required this.claimId,
    required this.claimNamespace,
    required this.claimPayload,
    required this.source,
    this.claimLabel = '',
    this.affectedRefs = const <NarrativeRef>[],
    this.contextRefs = const <NarrativeRef>[],
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.confidence = 0,
    this.uncertainty = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String claimId;
  final String claimNamespace;
  final String claimLabel;
  final JsonMap claimPayload;
  final List<NarrativeRef> affectedRefs;
  final List<NarrativeRef> contextRefs;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final NarrativeSourceRef source;
  final double confidence;
  final String uncertainty;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeStateClaim copyWith({
    String? claimId,
    String? claimNamespace,
    String? claimLabel,
    JsonMap? claimPayload,
    List<NarrativeRef>? affectedRefs,
    List<NarrativeRef>? contextRefs,
    List<NarrativeEvidenceRef>? evidenceRefs,
    NarrativeSourceRef? source,
    double? confidence,
    String? uncertainty,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: claim 会在 review、proposal 和 ledger 阶段被局部修补，这里统一提供稳定 copy 入口。
    return NarrativeStateClaim(
      claimId: claimId ?? this.claimId,
      claimNamespace: claimNamespace ?? this.claimNamespace,
      claimLabel: claimLabel ?? this.claimLabel,
      claimPayload: claimPayload ?? this.claimPayload,
      affectedRefs: affectedRefs ?? this.affectedRefs,
      contextRefs: contextRefs ?? this.contextRefs,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      uncertainty: uncertainty ?? this.uncertainty,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeStateClaim.fromJson(JsonMap json) {
    // 中文注释: claim_payload 保持开放 JSON 字典，避免后续未知流派被固定字段或枚举截断。
    return NarrativeStateClaim(
      claimId: ValueReaders.stringValue(json['claim_id']).trim(),
      claimNamespace: ValueReaders.stringValue(json['claim_namespace']).trim(),
      claimLabel: ValueReaders.stringValue(json['claim_label']).trim(),
      claimPayload: _narrativeStateClaimCodecService.readOpenMap(
        json['claim_payload'],
      ),
      affectedRefs: ValueReaders.mapList(
        json['affected_refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      contextRefs: ValueReaders.mapList(
        json['context_refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      evidenceRefs: ValueReaders.mapList(
        json['evidence_refs'],
      ).map(NarrativeEvidenceRef.fromJson).toList(growable: false),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      confidence: ValueReaders.doubleValue(json['confidence']),
      uncertainty: ValueReaders.stringValue(json['uncertainty']).trim(),
      schemaVersion: _narrativeStateClaimCodecService.readSchemaVersion(json),
      metadata: _narrativeStateClaimCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _narrativeStateClaimKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: claim 输出时坚持结构化键名，供后续 repository、tool result 和测试直接复用。
    return _narrativeStateClaimCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'claim_id': claimId,
          'claim_namespace': claimNamespace,
          'claim_label': claimLabel,
          'claim_payload': ValueReaders.deepCopyMap(claimPayload),
          'affected_refs': affectedRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'context_refs': contextRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'evidence_refs': evidenceRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'source': source.toJson(),
          'confidence': confidence,
          'uncertainty': uncertainty,
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    // 中文注释: 这里只做最小合同校验，不掺入题材解释、ledger 语义或正文级判断。
    final result = <String>[];
    result.addAll(
      _narrativeStateClaimValidatorService.requireNonBlankString(
        claimId,
        NarrativeStateClaimValidationCodes.missingClaimId,
      ),
    );
    result.addAll(
      _narrativeStateClaimValidatorService.requireNonBlankString(
        claimNamespace,
        NarrativeStateClaimValidationCodes.missingClaimNamespace,
      ),
    );
    result.addAll(
      _narrativeStateClaimValidatorService.requireNonBlankString(
        source.sourceType,
        NarrativeStateClaimValidationCodes.missingSourceType,
      ),
    );
    result.addAll(
      _narrativeStateClaimValidatorService.validateConfidence(
        confidence,
        NarrativeStateClaimValidationCodes.invalidConfidence,
      ),
    );
    return result;
  }
}
