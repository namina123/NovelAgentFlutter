import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'continuity_conflict_validation_codes.dart';
import 'narrative_fact_evidence.dart';
import 'narrative_ref.dart';

const _narrativeConflictClusterCodecService = OpenJsonContractCodecService();
const _narrativeConflictClusterValidatorService =
    OpenJsonStructureValidatorService();
const _narrativeConflictClusterKnownFields = <String>{
  'cluster_id',
  'subject_ref',
  'attribute_key',
  'classification',
  'cluster_status',
  'fact_evidences',
  'summary',
  'current_decision_id',
  'schema_version',
  'metadata',
};

abstract final class NarrativeConflictClassifications {
  static const String normalEvolution = 'normal_evolution';
  static const String conditionalChange = 'conditional_change';
  static const String perspectiveDifference = 'perspective_difference';
  static const String worldlineOrMemoryCondition =
      'worldline_or_memory_condition';
  static const String unexplainedConflict = 'unexplained_conflict';
  static const String probableAuthorError = 'probable_author_error';

  static const List<String> knownValues = <String>[
    normalEvolution,
    conditionalChange,
    perspectiveDifference,
    worldlineOrMemoryCondition,
    unexplainedConflict,
    probableAuthorError,
  ];
}

abstract final class NarrativeConflictClusterStatuses {
  static const String observed = 'observed';
  static const String needsDecision = 'needs_decision';
  static const String canonized = 'canonized';

  static const List<String> knownValues = <String>[
    observed,
    needsDecision,
    canonized,
  ];
}

class NarrativeConflictCluster {
  const NarrativeConflictCluster({
    required this.clusterId,
    required this.subjectRef,
    required this.attributeKey,
    required this.classification,
    this.clusterStatus = NarrativeConflictClusterStatuses.observed,
    this.factEvidences = const <NarrativeFactEvidence>[],
    this.summary = '',
    this.currentDecisionId = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String clusterId;
  final NarrativeRef subjectRef;
  final String attributeKey;
  final String classification;
  final String clusterStatus;
  final List<NarrativeFactEvidence> factEvidences;
  final String summary;
  final String currentDecisionId;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeConflictCluster copyWith({
    String? clusterId,
    NarrativeRef? subjectRef,
    String? attributeKey,
    String? classification,
    String? clusterStatus,
    List<NarrativeFactEvidence>? factEvidences,
    String? summary,
    String? currentDecisionId,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    return NarrativeConflictCluster(
      clusterId: clusterId ?? this.clusterId,
      subjectRef: subjectRef ?? this.subjectRef,
      attributeKey: attributeKey ?? this.attributeKey,
      classification: classification ?? this.classification,
      clusterStatus: clusterStatus ?? this.clusterStatus,
      factEvidences: factEvidences ?? this.factEvidences,
      summary: summary ?? this.summary,
      currentDecisionId: currentDecisionId ?? this.currentDecisionId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeConflictCluster.fromJson(JsonMap json) {
    return NarrativeConflictCluster(
      clusterId: ValueReaders.stringValue(json['cluster_id']).trim(),
      subjectRef: NarrativeRef.fromJson(
        ValueReaders.mapValue(json['subject_ref']),
      ),
      attributeKey: ValueReaders.stringValue(json['attribute_key']).trim(),
      classification: ValueReaders.stringValue(json['classification']).trim(),
      clusterStatus: ValueReaders.stringValue(
        json['cluster_status'],
        NarrativeConflictClusterStatuses.observed,
      ).trim(),
      factEvidences: ValueReaders.mapList(
        json['fact_evidences'],
      ).map(NarrativeFactEvidence.fromJson).toList(growable: false),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      currentDecisionId: ValueReaders.stringValue(
        json['current_decision_id'],
      ).trim(),
      schemaVersion: _narrativeConflictClusterCodecService.readSchemaVersion(
        json,
      ),
      metadata: _narrativeConflictClusterCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _narrativeConflictClusterKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _narrativeConflictClusterCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'cluster_id': clusterId,
          'subject_ref': subjectRef.toJson(),
          'attribute_key': attributeKey,
          'classification': classification,
          'cluster_status': clusterStatus,
          'fact_evidences': factEvidences
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'summary': summary,
          'current_decision_id': currentDecisionId,
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _narrativeConflictClusterValidatorService.requireNonBlankString(
        clusterId,
        ContinuityConflictValidationCodes.missingConflictClusterId,
      ),
    );
    result.addAll(
      _narrativeConflictClusterValidatorService.requireNonBlankString(
        subjectRef.refType,
        ContinuityConflictValidationCodes.missingSubjectRefType,
      ),
    );
    result.addAll(
      _narrativeConflictClusterValidatorService.requireNonBlankString(
        subjectRef.refId,
        ContinuityConflictValidationCodes.missingSubjectRefId,
      ),
    );
    result.addAll(
      _narrativeConflictClusterValidatorService.requireNonBlankString(
        attributeKey,
        ContinuityConflictValidationCodes.missingAttributeKey,
      ),
    );
    if (!NarrativeConflictClassifications.knownValues.contains(
      classification,
    )) {
      result.add(
        ContinuityConflictValidationCodes.invalidConflictClassification,
      );
    }
    if (!NarrativeConflictClusterStatuses.knownValues.contains(clusterStatus)) {
      result.add(
        ContinuityConflictValidationCodes.invalidConflictClusterStatus,
      );
    }
    result.addAll(factEvidences.expand((fact) => fact.validateBasics()));
    return result;
  }
}
