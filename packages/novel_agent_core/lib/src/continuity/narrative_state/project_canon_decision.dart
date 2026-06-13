import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'continuity_conflict_validation_codes.dart';
import 'narrative_ref.dart';

const _projectCanonDecisionCodecService = OpenJsonContractCodecService();
const _projectCanonDecisionValidatorService =
    OpenJsonStructureValidatorService();
const _projectCanonDecisionKnownFields = <String>{
  'decision_id',
  'cluster_id',
  'decision_kind',
  'selected_fact_evidence_ids',
  'retained_fact_evidence_ids',
  'rejected_fact_evidence_ids',
  'applicable_scope_refs',
  'summary',
  'rationale',
  'decided_by',
  'decided_at',
  'review_required',
  'schema_version',
  'metadata',
};

abstract final class ProjectCanonDecisionKinds {
  static const String adoptPrimaryFact = 'adopt_primary_fact';
  static const String keepParallelVersions = 'keep_parallel_versions';
  static const String adoptConditionalInterpretation =
      'adopt_conditional_interpretation';
  static const String deferUnresolved = 'defer_unresolved';
  static const String markProbableAuthorError = 'mark_probable_author_error';

  static const List<String> knownValues = <String>[
    adoptPrimaryFact,
    keepParallelVersions,
    adoptConditionalInterpretation,
    deferUnresolved,
    markProbableAuthorError,
  ];
}

class ProjectCanonDecision {
  const ProjectCanonDecision({
    required this.decisionId,
    required this.clusterId,
    required this.decisionKind,
    this.selectedFactEvidenceIds = const <String>[],
    this.retainedFactEvidenceIds = const <String>[],
    this.rejectedFactEvidenceIds = const <String>[],
    this.applicableScopeRefs = const <NarrativeRef>[],
    this.summary = '',
    this.rationale = '',
    this.decidedBy = '',
    this.decidedAt = '',
    this.reviewRequired = false,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String decisionId;
  final String clusterId;
  final String decisionKind;
  final List<String> selectedFactEvidenceIds;
  final List<String> retainedFactEvidenceIds;
  final List<String> rejectedFactEvidenceIds;
  final List<NarrativeRef> applicableScopeRefs;
  final String summary;
  final String rationale;
  final String decidedBy;
  final String decidedAt;
  final bool reviewRequired;
  final String schemaVersion;
  final JsonMap metadata;

  ProjectCanonDecision copyWith({
    String? decisionId,
    String? clusterId,
    String? decisionKind,
    List<String>? selectedFactEvidenceIds,
    List<String>? retainedFactEvidenceIds,
    List<String>? rejectedFactEvidenceIds,
    List<NarrativeRef>? applicableScopeRefs,
    String? summary,
    String? rationale,
    String? decidedBy,
    String? decidedAt,
    bool? reviewRequired,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    return ProjectCanonDecision(
      decisionId: decisionId ?? this.decisionId,
      clusterId: clusterId ?? this.clusterId,
      decisionKind: decisionKind ?? this.decisionKind,
      selectedFactEvidenceIds:
          selectedFactEvidenceIds ?? this.selectedFactEvidenceIds,
      retainedFactEvidenceIds:
          retainedFactEvidenceIds ?? this.retainedFactEvidenceIds,
      rejectedFactEvidenceIds:
          rejectedFactEvidenceIds ?? this.rejectedFactEvidenceIds,
      applicableScopeRefs: applicableScopeRefs ?? this.applicableScopeRefs,
      summary: summary ?? this.summary,
      rationale: rationale ?? this.rationale,
      decidedBy: decidedBy ?? this.decidedBy,
      decidedAt: decidedAt ?? this.decidedAt,
      reviewRequired: reviewRequired ?? this.reviewRequired,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ProjectCanonDecision.fromJson(JsonMap json) {
    return ProjectCanonDecision(
      decisionId: ValueReaders.stringValue(json['decision_id']).trim(),
      clusterId: ValueReaders.stringValue(json['cluster_id']).trim(),
      decisionKind: ValueReaders.stringValue(json['decision_kind']).trim(),
      selectedFactEvidenceIds: ValueReaders.stringList(
        json['selected_fact_evidence_ids'],
      ),
      retainedFactEvidenceIds: ValueReaders.stringList(
        json['retained_fact_evidence_ids'],
      ),
      rejectedFactEvidenceIds: ValueReaders.stringList(
        json['rejected_fact_evidence_ids'],
      ),
      applicableScopeRefs: ValueReaders.mapList(
        json['applicable_scope_refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      rationale: ValueReaders.stringValue(json['rationale']).trim(),
      decidedBy: ValueReaders.stringValue(json['decided_by']).trim(),
      decidedAt: ValueReaders.stringValue(json['decided_at']).trim(),
      reviewRequired: ValueReaders.boolValue(json['review_required']),
      schemaVersion: _projectCanonDecisionCodecService.readSchemaVersion(json),
      metadata: _projectCanonDecisionCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _projectCanonDecisionKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _projectCanonDecisionCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'decision_id': decisionId,
          'cluster_id': clusterId,
          'decision_kind': decisionKind,
          'selected_fact_evidence_ids': selectedFactEvidenceIds,
          'retained_fact_evidence_ids': retainedFactEvidenceIds,
          'rejected_fact_evidence_ids': rejectedFactEvidenceIds,
          'applicable_scope_refs': applicableScopeRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'summary': summary,
          'rationale': rationale,
          'decided_by': decidedBy,
          'decided_at': decidedAt,
          'review_required': reviewRequired,
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _projectCanonDecisionValidatorService.requireNonBlankString(
        decisionId,
        ContinuityConflictValidationCodes.missingCanonDecisionId,
      ),
    );
    result.addAll(
      _projectCanonDecisionValidatorService.requireNonBlankString(
        clusterId,
        ContinuityConflictValidationCodes.missingConflictClusterId,
      ),
    );
    result.addAll(
      _projectCanonDecisionValidatorService.requireNonBlankString(
        decisionKind,
        ContinuityConflictValidationCodes.missingDecisionKind,
      ),
    );
    if (!ProjectCanonDecisionKinds.knownValues.contains(decisionKind)) {
      result.add(ContinuityConflictValidationCodes.invalidDecisionKind);
    }
    if ((decisionKind == ProjectCanonDecisionKinds.adoptPrimaryFact ||
            decisionKind ==
                ProjectCanonDecisionKinds.adoptConditionalInterpretation) &&
        selectedFactEvidenceIds.isEmpty) {
      result.add(
        ContinuityConflictValidationCodes.decisionRequiresSelectedFactEvidence,
      );
    }
    return result;
  }
}
