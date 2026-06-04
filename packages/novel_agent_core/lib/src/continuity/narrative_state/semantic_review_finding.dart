import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_evidence_ref.dart';
import 'semantic_review_severity.dart';
import 'semantic_review_validation_codes.dart';

const _semanticReviewFindingValidatorService =
    OpenJsonStructureValidatorService();

class SemanticReviewFinding {
  const SemanticReviewFinding({
    required this.findingId,
    required this.severity,
    required this.summary,
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.relatedClaimIds = const <String>[],
    this.suggestedAction = '',
    this.unableToLocateEvidence = false,
    this.unlocatableReason = '',
    this.confidence = 0,
    this.metadata = const <String, Object?>{},
  });

  final String findingId;
  final SemanticReviewSeverity severity;
  final String summary;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final List<String> relatedClaimIds;
  final String suggestedAction;
  final bool unableToLocateEvidence;
  final String unlocatableReason;
  final double confidence;
  final JsonMap metadata;

  SemanticReviewFinding copyWith({
    String? findingId,
    SemanticReviewSeverity? severity,
    String? summary,
    List<NarrativeEvidenceRef>? evidenceRefs,
    List<String>? relatedClaimIds,
    String? suggestedAction,
    bool? unableToLocateEvidence,
    String? unlocatableReason,
    double? confidence,
    JsonMap? metadata,
  }) {
    // 中文注释: finding 只承接 reviewer 的结构化意见，不在这里做任何自动调度或状态变更。
    return SemanticReviewFinding(
      findingId: findingId ?? this.findingId,
      severity: severity ?? this.severity,
      summary: summary ?? this.summary,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      relatedClaimIds: relatedClaimIds ?? this.relatedClaimIds,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      unableToLocateEvidence:
          unableToLocateEvidence ?? this.unableToLocateEvidence,
      unlocatableReason: unlocatableReason ?? this.unlocatableReason,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }

  factory SemanticReviewFinding.fromJson(JsonMap json) {
    // 中文注释: finding 允许“无法定位证据”的显式表达，避免 reviewer 为了过校验伪造 evidence。
    return SemanticReviewFinding(
      findingId: ValueReaders.stringValue(json['finding_id']).trim(),
      severity: SemanticReviewSeverity.fromId(
        ValueReaders.stringValue(json['severity']),
      ),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      evidenceRefs: ValueReaders.mapList(
        json['evidence_refs'],
      ).map(NarrativeEvidenceRef.fromJson).toList(growable: false),
      relatedClaimIds: ValueReaders.stringList(json['related_claim_ids']),
      suggestedAction: ValueReaders.stringValue(
        json['suggested_action'],
      ).trim(),
      unableToLocateEvidence: ValueReaders.boolValue(
        json['unable_to_locate_evidence'],
      ),
      unlocatableReason: ValueReaders.stringValue(
        json['unlocatable_reason'],
      ).trim(),
      confidence: ValueReaders.doubleValue(json['confidence']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: finding 输出结构固定，后续 gate、repository 和投影层可直接复用。
    return <String, Object?>{
      'finding_id': findingId,
      'severity': severity.id,
      'summary': summary,
      'evidence_refs': evidenceRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'related_claim_ids': relatedClaimIds,
      'suggested_action': suggestedAction,
      'unable_to_locate_evidence': unableToLocateEvidence,
      'unlocatable_reason': unlocatableReason,
      'confidence': confidence,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: finding 至少要么给出 evidence，要么明确说明无法定位，避免模糊 blocking 建议。
    final result = <String>[];
    result.addAll(
      _semanticReviewFindingValidatorService.requireNonBlankString(
        findingId,
        SemanticReviewValidationCodes.missingFindingId,
      ),
    );
    result.addAll(
      _semanticReviewFindingValidatorService.requireNonBlankString(
        summary,
        SemanticReviewValidationCodes.missingFindingSummary,
      ),
    );
    result.addAll(
      _semanticReviewFindingValidatorService.validateConfidence(
        confidence,
        SemanticReviewValidationCodes.invalidConfidence,
      ),
    );
    if (evidenceRefs.isEmpty &&
        (!unableToLocateEvidence || unlocatableReason.trim().isEmpty)) {
      result.add(
        SemanticReviewValidationCodes.findingNeedsEvidenceOrUnlocatableReason,
      );
    }
    return result;
  }
}
