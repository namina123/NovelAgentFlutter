import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'continuity_conflict_validation_codes.dart';
import 'narrative_source_ref.dart';

const _continuityReviewAlertCodecService = OpenJsonContractCodecService();
const _continuityReviewAlertValidatorService =
    OpenJsonStructureValidatorService();
const _continuityReviewAlertKnownFields = <String>{
  'alert_id',
  'cluster_id',
  'alert_kind',
  'severity',
  'related_fact_evidence_ids',
  'related_decision_id',
  'summary',
  'recommended_action',
  'requires_manual_review',
  'source',
  'schema_version',
  'metadata',
};

abstract final class ContinuityReviewAlertKinds {
  static const String continuityConflict = 'continuity_conflict';
  static const String canonDecisionRequired = 'canon_decision_required';
  static const String unresolvedConflict = 'unresolved_conflict';
  static const String probableAuthorError = 'probable_author_error';

  static const List<String> knownValues = <String>[
    continuityConflict,
    canonDecisionRequired,
    unresolvedConflict,
    probableAuthorError,
  ];
}

abstract final class ContinuityReviewAlertSeverities {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String blocking = 'blocking';

  static const List<String> knownValues = <String>[low, medium, high, blocking];
}

class ContinuityReviewAlert {
  const ContinuityReviewAlert({
    required this.alertId,
    required this.clusterId,
    required this.alertKind,
    required this.severity,
    required this.source,
    this.relatedFactEvidenceIds = const <String>[],
    this.relatedDecisionId = '',
    this.summary = '',
    this.recommendedAction = '',
    this.requiresManualReview = false,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String alertId;
  final String clusterId;
  final String alertKind;
  final String severity;
  final List<String> relatedFactEvidenceIds;
  final String relatedDecisionId;
  final String summary;
  final String recommendedAction;
  final bool requiresManualReview;
  final NarrativeSourceRef source;
  final String schemaVersion;
  final JsonMap metadata;

  ContinuityReviewAlert copyWith({
    String? alertId,
    String? clusterId,
    String? alertKind,
    String? severity,
    List<String>? relatedFactEvidenceIds,
    String? relatedDecisionId,
    String? summary,
    String? recommendedAction,
    bool? requiresManualReview,
    NarrativeSourceRef? source,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    return ContinuityReviewAlert(
      alertId: alertId ?? this.alertId,
      clusterId: clusterId ?? this.clusterId,
      alertKind: alertKind ?? this.alertKind,
      severity: severity ?? this.severity,
      relatedFactEvidenceIds:
          relatedFactEvidenceIds ?? this.relatedFactEvidenceIds,
      relatedDecisionId: relatedDecisionId ?? this.relatedDecisionId,
      summary: summary ?? this.summary,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      requiresManualReview: requiresManualReview ?? this.requiresManualReview,
      source: source ?? this.source,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ContinuityReviewAlert.fromJson(JsonMap json) {
    return ContinuityReviewAlert(
      alertId: ValueReaders.stringValue(json['alert_id']).trim(),
      clusterId: ValueReaders.stringValue(json['cluster_id']).trim(),
      alertKind: ValueReaders.stringValue(json['alert_kind']).trim(),
      severity: ValueReaders.stringValue(json['severity']).trim(),
      relatedFactEvidenceIds: ValueReaders.stringList(
        json['related_fact_evidence_ids'],
      ),
      relatedDecisionId: ValueReaders.stringValue(
        json['related_decision_id'],
      ).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      recommendedAction: ValueReaders.stringValue(
        json['recommended_action'],
      ).trim(),
      requiresManualReview: ValueReaders.boolValue(
        json['requires_manual_review'],
      ),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      schemaVersion: _continuityReviewAlertCodecService.readSchemaVersion(json),
      metadata: _continuityReviewAlertCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _continuityReviewAlertKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _continuityReviewAlertCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'alert_id': alertId,
          'cluster_id': clusterId,
          'alert_kind': alertKind,
          'severity': severity,
          'related_fact_evidence_ids': relatedFactEvidenceIds,
          'related_decision_id': relatedDecisionId,
          'summary': summary,
          'recommended_action': recommendedAction,
          'requires_manual_review': requiresManualReview,
          'source': source.toJson(),
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _continuityReviewAlertValidatorService.requireNonBlankString(
        alertId,
        ContinuityConflictValidationCodes.missingReviewAlertId,
      ),
    );
    result.addAll(
      _continuityReviewAlertValidatorService.requireNonBlankString(
        clusterId,
        ContinuityConflictValidationCodes.missingConflictClusterId,
      ),
    );
    result.addAll(
      _continuityReviewAlertValidatorService.requireNonBlankString(
        alertKind,
        ContinuityConflictValidationCodes.missingAlertKind,
      ),
    );
    if (!ContinuityReviewAlertKinds.knownValues.contains(alertKind)) {
      result.add(ContinuityConflictValidationCodes.missingAlertKind);
    }
    if (!ContinuityReviewAlertSeverities.knownValues.contains(severity)) {
      result.add(ContinuityConflictValidationCodes.invalidAlertSeverity);
    }
    result.addAll(
      _continuityReviewAlertValidatorService.requireNonBlankString(
        source.sourceType,
        ContinuityConflictValidationCodes.missingSourceType,
      ),
    );
    return result;
  }
}
