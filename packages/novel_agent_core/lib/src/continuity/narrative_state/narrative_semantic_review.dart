import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_ref.dart';
import 'narrative_source_ref.dart';
import 'narrative_state_claim.dart';
import 'semantic_review_finding.dart';
import 'semantic_review_recommended_disposition.dart';
import 'semantic_review_validation_codes.dart';

const _narrativeSemanticReviewCodecService = OpenJsonContractCodecService();
const _narrativeSemanticReviewValidatorService =
    OpenJsonStructureValidatorService();

class NarrativeSemanticReview {
  const NarrativeSemanticReview({
    required this.reviewId,
    required this.source,
    required this.recommendedDisposition,
    this.targetRefs = const <NarrativeRef>[],
    this.acceptedClaimIds = const <String>[],
    this.questionedClaimIds = const <String>[],
    this.suggestedClaims = const <NarrativeStateClaim>[],
    this.findings = const <SemanticReviewFinding>[],
    this.summary = '',
    this.confidence = 0,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String reviewId;
  final NarrativeSourceRef source;
  final SemanticReviewRecommendedDisposition recommendedDisposition;
  final List<NarrativeRef> targetRefs;
  final List<String> acceptedClaimIds;
  final List<String> questionedClaimIds;
  final List<NarrativeStateClaim> suggestedClaims;
  final List<SemanticReviewFinding> findings;
  final String summary;
  final double confidence;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeSemanticReview copyWith({
    String? reviewId,
    NarrativeSourceRef? source,
    SemanticReviewRecommendedDisposition? recommendedDisposition,
    List<NarrativeRef>? targetRefs,
    List<String>? acceptedClaimIds,
    List<String>? questionedClaimIds,
    List<NarrativeStateClaim>? suggestedClaims,
    List<SemanticReviewFinding>? findings,
    String? summary,
    double? confidence,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: review 只表达 reviewer 建议，不承担 ledger 接受状态或 supervisor 决策。
    return NarrativeSemanticReview(
      reviewId: reviewId ?? this.reviewId,
      source: source ?? this.source,
      recommendedDisposition:
          recommendedDisposition ?? this.recommendedDisposition,
      targetRefs: targetRefs ?? this.targetRefs,
      acceptedClaimIds: acceptedClaimIds ?? this.acceptedClaimIds,
      questionedClaimIds: questionedClaimIds ?? this.questionedClaimIds,
      suggestedClaims: suggestedClaims ?? this.suggestedClaims,
      findings: findings ?? this.findings,
      summary: summary ?? this.summary,
      confidence: confidence ?? this.confidence,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeSemanticReview.fromJson(JsonMap json) {
    // 中文注释: accepted/questioned/suggested claim 在合同上并存，但都只是 review 建议，不代表 ledger 已变化。
    return NarrativeSemanticReview(
      reviewId: ValueReaders.stringValue(json['review_id']).trim(),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      recommendedDisposition: SemanticReviewRecommendedDisposition.fromId(
        ValueReaders.stringValue(json['recommended_disposition']),
      ),
      targetRefs: ValueReaders.mapList(
        json['target_refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      acceptedClaimIds: ValueReaders.stringList(json['accepted_claim_ids']),
      questionedClaimIds: ValueReaders.stringList(json['questioned_claim_ids']),
      suggestedClaims: ValueReaders.mapList(
        json['suggested_claims'],
      ).map(NarrativeStateClaim.fromJson).toList(growable: false),
      findings: ValueReaders.mapList(
        json['findings'],
      ).map(SemanticReviewFinding.fromJson).toList(growable: false),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      confidence: ValueReaders.doubleValue(json['confidence']),
      schemaVersion: _narrativeSemanticReviewCodecService.readSchemaVersion(
        json,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: review 输出不包含任何 ledger mutation 字段，显式保持“只是建议”的边界。
    return <String, Object?>{
      'review_id': reviewId,
      'source': source.toJson(),
      'recommended_disposition': recommendedDisposition.id,
      'target_refs': targetRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'accepted_claim_ids': acceptedClaimIds,
      'questioned_claim_ids': questionedClaimIds,
      'suggested_claims': suggestedClaims
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'findings': findings
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'summary': summary,
      'confidence': confidence,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: review 层只做最小身份与 finding 合同校验，不在本轮解释建议是否应该执行。
    final result = <String>[];
    result.addAll(
      _narrativeSemanticReviewValidatorService.requireNonBlankString(
        reviewId,
        SemanticReviewValidationCodes.missingReviewId,
      ),
    );
    result.addAll(
      _narrativeSemanticReviewValidatorService.requireNonBlankString(
        source.sourceType,
        SemanticReviewValidationCodes.missingSourceType,
      ),
    );
    result.addAll(
      _narrativeSemanticReviewValidatorService.validateConfidence(
        confidence,
        SemanticReviewValidationCodes.invalidConfidence,
      ),
    );
    result.addAll(findings.expand((finding) => finding.validateBasics()));
    return result;
  }
}
