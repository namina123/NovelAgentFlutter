import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'continuity_conflict_validation_codes.dart';
import 'narrative_evidence_ref.dart';
import 'narrative_ref.dart';
import 'narrative_source_ref.dart';
import 'narrative_state_claim.dart';

const _narrativeFactEvidenceCodecService = OpenJsonContractCodecService();
const _narrativeFactEvidenceValidatorService =
    OpenJsonStructureValidatorService();
const _narrativeFactEvidenceKnownFields = <String>{
  'fact_evidence_id',
  'subject_ref',
  'attribute_key',
  'value_payload',
  'value_summary',
  'condition_summary',
  'perspective_summary',
  'claim_snapshot',
  'evidence_refs',
  'source',
  'confidence',
  'schema_version',
  'metadata',
};

class NarrativeFactEvidence {
  const NarrativeFactEvidence({
    required this.factEvidenceId,
    required this.subjectRef,
    required this.attributeKey,
    required this.valuePayload,
    required this.claimSnapshot,
    required this.source,
    this.valueSummary = '',
    this.conditionSummary = '',
    this.perspectiveSummary = '',
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.confidence = 0,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String factEvidenceId;
  final NarrativeRef subjectRef;
  final String attributeKey;
  final JsonMap valuePayload;
  final String valueSummary;
  final String conditionSummary;
  final String perspectiveSummary;
  final NarrativeStateClaim claimSnapshot;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final NarrativeSourceRef source;
  final double confidence;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeFactEvidence copyWith({
    String? factEvidenceId,
    NarrativeRef? subjectRef,
    String? attributeKey,
    JsonMap? valuePayload,
    String? valueSummary,
    String? conditionSummary,
    String? perspectiveSummary,
    NarrativeStateClaim? claimSnapshot,
    List<NarrativeEvidenceRef>? evidenceRefs,
    NarrativeSourceRef? source,
    double? confidence,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    return NarrativeFactEvidence(
      factEvidenceId: factEvidenceId ?? this.factEvidenceId,
      subjectRef: subjectRef ?? this.subjectRef,
      attributeKey: attributeKey ?? this.attributeKey,
      valuePayload: valuePayload ?? this.valuePayload,
      valueSummary: valueSummary ?? this.valueSummary,
      conditionSummary: conditionSummary ?? this.conditionSummary,
      perspectiveSummary: perspectiveSummary ?? this.perspectiveSummary,
      claimSnapshot: claimSnapshot ?? this.claimSnapshot,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeFactEvidence.fromJson(JsonMap json) {
    return NarrativeFactEvidence(
      factEvidenceId: ValueReaders.stringValue(json['fact_evidence_id']).trim(),
      subjectRef: NarrativeRef.fromJson(
        ValueReaders.mapValue(json['subject_ref']),
      ),
      attributeKey: ValueReaders.stringValue(json['attribute_key']).trim(),
      valuePayload: _narrativeFactEvidenceCodecService.readOpenMap(
        json['value_payload'],
      ),
      valueSummary: ValueReaders.stringValue(json['value_summary']).trim(),
      conditionSummary: ValueReaders.stringValue(
        json['condition_summary'],
      ).trim(),
      perspectiveSummary: ValueReaders.stringValue(
        json['perspective_summary'],
      ).trim(),
      claimSnapshot: NarrativeStateClaim.fromJson(
        ValueReaders.mapValue(json['claim_snapshot']),
      ),
      evidenceRefs: ValueReaders.mapList(
        json['evidence_refs'],
      ).map(NarrativeEvidenceRef.fromJson).toList(growable: false),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      confidence: ValueReaders.doubleValue(json['confidence']),
      schemaVersion: _narrativeFactEvidenceCodecService.readSchemaVersion(json),
      metadata: _narrativeFactEvidenceCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _narrativeFactEvidenceKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _narrativeFactEvidenceCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'fact_evidence_id': factEvidenceId,
          'subject_ref': subjectRef.toJson(),
          'attribute_key': attributeKey,
          'value_payload': ValueReaders.deepCopyMap(valuePayload),
          'value_summary': valueSummary,
          'condition_summary': conditionSummary,
          'perspective_summary': perspectiveSummary,
          'claim_snapshot': claimSnapshot.toJson(),
          'evidence_refs': evidenceRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'source': source.toJson(),
          'confidence': confidence,
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _narrativeFactEvidenceValidatorService.requireNonBlankString(
        factEvidenceId,
        ContinuityConflictValidationCodes.missingFactEvidenceId,
      ),
    );
    result.addAll(
      _narrativeFactEvidenceValidatorService.requireNonBlankString(
        subjectRef.refType,
        ContinuityConflictValidationCodes.missingSubjectRefType,
      ),
    );
    result.addAll(
      _narrativeFactEvidenceValidatorService.requireNonBlankString(
        subjectRef.refId,
        ContinuityConflictValidationCodes.missingSubjectRefId,
      ),
    );
    result.addAll(
      _narrativeFactEvidenceValidatorService.requireNonBlankString(
        attributeKey,
        ContinuityConflictValidationCodes.missingAttributeKey,
      ),
    );
    result.addAll(
      _narrativeFactEvidenceValidatorService.requireNonBlankString(
        claimSnapshot.claimId,
        ContinuityConflictValidationCodes.missingClaimId,
      ),
    );
    result.addAll(
      _narrativeFactEvidenceValidatorService.requireNonBlankString(
        source.sourceType,
        ContinuityConflictValidationCodes.missingSourceType,
      ),
    );
    result.addAll(
      _narrativeFactEvidenceValidatorService.validateConfidence(
        confidence,
        ContinuityConflictValidationCodes.invalidConfidence,
      ),
    );
    return result;
  }
}
