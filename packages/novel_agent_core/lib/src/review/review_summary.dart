import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'review_contract_catalog.dart';

const _reviewSummaryCodecService = OpenJsonContractCodecService();
const _reviewSummaryValidatorService = OpenJsonStructureValidatorService();
const _reviewSummaryKnownFields = <String>{
  'review_id',
  'review_type',
  'reviewer_id',
  'reviewer_role',
  'risk_level',
  'recommended_disposition',
  'finding_count',
  'blocking_finding_count',
  'summary',
  'repair_brief',
  'evidence_paths',
  'metadata',
};

class ReviewSummary {
  const ReviewSummary({
    required this.reviewId,
    required this.reviewType,
    required this.reviewerId,
    required this.reviewerRole,
    required this.riskLevel,
    required this.recommendedDisposition,
    this.findingCount = 0,
    this.blockingFindingCount = 0,
    this.summary = '',
    this.repairBrief = '',
    this.evidencePaths = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String reviewId;
  final String reviewType;
  final String reviewerId;
  final String reviewerRole;
  final String riskLevel;
  final String recommendedDisposition;
  final int findingCount;
  final int blockingFindingCount;
  final String summary;
  final String repairBrief;
  final List<String> evidencePaths;
  final JsonMap metadata;

  ReviewSummary copyWith({
    String? reviewId,
    String? reviewType,
    String? reviewerId,
    String? reviewerRole,
    String? riskLevel,
    String? recommendedDisposition,
    int? findingCount,
    int? blockingFindingCount,
    String? summary,
    String? repairBrief,
    List<String>? evidencePaths,
    JsonMap? metadata,
  }) {
    return ReviewSummary(
      reviewId: reviewId ?? this.reviewId,
      reviewType: reviewType ?? this.reviewType,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerRole: reviewerRole ?? this.reviewerRole,
      riskLevel: riskLevel ?? this.riskLevel,
      recommendedDisposition:
          recommendedDisposition ?? this.recommendedDisposition,
      findingCount: findingCount ?? this.findingCount,
      blockingFindingCount: blockingFindingCount ?? this.blockingFindingCount,
      summary: summary ?? this.summary,
      repairBrief: repairBrief ?? this.repairBrief,
      evidencePaths: evidencePaths ?? this.evidencePaths,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ReviewSummary.fromJson(JsonMap json) {
    return ReviewSummary(
      reviewId: ValueReaders.stringValue(json['review_id']).trim(),
      reviewType: ValueReaders.stringValue(json['review_type']).trim(),
      reviewerId: ValueReaders.stringValue(json['reviewer_id']).trim(),
      reviewerRole: ValueReaders.stringValue(json['reviewer_role']).trim(),
      riskLevel: ValueReaders.stringValue(
        json['risk_level'],
        ReviewRiskLevels.none,
      ).trim(),
      recommendedDisposition: ValueReaders.stringValue(
        json['recommended_disposition'],
        ReviewRecommendedDispositions.accept,
      ).trim(),
      findingCount: ValueReaders.intValue(json['finding_count']),
      blockingFindingCount: ValueReaders.intValue(
        json['blocking_finding_count'],
      ),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      repairBrief: ValueReaders.stringValue(json['repair_brief']).trim(),
      evidencePaths: ValueReaders.stringList(json['evidence_paths']),
      metadata: _reviewSummaryCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _reviewSummaryKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _reviewSummaryCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'review_id': reviewId,
        'review_type': reviewType,
        'reviewer_id': reviewerId,
        'reviewer_role': reviewerRole,
        'risk_level': riskLevel,
        'recommended_disposition': recommendedDisposition,
        'finding_count': findingCount,
        'blocking_finding_count': blockingFindingCount,
        'summary': summary,
        'repair_brief': repairBrief,
        'evidence_paths': evidencePaths,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _reviewSummaryValidatorService.requireNonBlankString(
        reviewId,
        ReviewContractValidationCodes.missingSummaryReviewId,
      ),
    );
    result.addAll(
      _reviewSummaryValidatorService.requireNonBlankString(
        reviewType,
        ReviewContractValidationCodes.missingSummaryReviewType,
      ),
    );
    result.addAll(
      _reviewSummaryValidatorService.requireNonBlankString(
        reviewerId,
        ReviewContractValidationCodes.missingSummaryReviewerId,
      ),
    );
    result.addAll(
      _reviewSummaryValidatorService.requireNonBlankString(
        reviewerRole,
        ReviewContractValidationCodes.missingSummaryReviewerRole,
      ),
    );
    if (!ReviewRiskLevels.knownValues.contains(riskLevel)) {
      result.add(ReviewContractValidationCodes.invalidSummaryRiskLevel);
    }
    if (!ReviewRecommendedDispositions.knownValues.contains(
      recommendedDisposition,
    )) {
      result.add(
        ReviewContractValidationCodes.invalidSummaryRecommendedDisposition,
      );
    }
    result.addAll(
      _reviewSummaryValidatorService.validateNonNegativeInt(
        findingCount,
        ReviewContractValidationCodes.invalidSummaryFindingCount,
      ),
    );
    result.addAll(
      _reviewSummaryValidatorService.validateNonNegativeInt(
        blockingFindingCount,
        ReviewContractValidationCodes.invalidSummaryFindingCount,
      ),
    );
    return result;
  }
}
