import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'review_basis.dart';
import 'review_contract_catalog.dart';
import 'review_finding_contract.dart';
import 'review_reviewer_ref.dart';

const _reviewContractCodecService = OpenJsonContractCodecService();
const _reviewContractValidatorService = OpenJsonStructureValidatorService();
const _reviewContractKnownFields = <String>{
  'review_id',
  'review_type',
  'reviewer',
  'basis',
  'findings',
  'risk_level',
  'recommended_disposition',
  'repair_brief',
  'summary',
  'evidence_paths',
  'created_at',
  'schema_version',
  'metadata',
};

class ReviewContract {
  const ReviewContract({
    required this.reviewId,
    required this.reviewType,
    required this.reviewer,
    required this.basis,
    required this.riskLevel,
    required this.recommendedDisposition,
    this.findings = const <ReviewFindingContract>[],
    this.repairBrief = '',
    this.summary = '',
    this.evidencePaths = const <String>[],
    this.createdAt = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String reviewId;
  final String reviewType;
  final ReviewReviewerRef reviewer;
  final ReviewBasis basis;
  final List<ReviewFindingContract> findings;
  final String riskLevel;
  final String recommendedDisposition;
  final String repairBrief;
  final String summary;
  final List<String> evidencePaths;
  final String createdAt;
  final String schemaVersion;
  final JsonMap metadata;

  ReviewContract copyWith({
    String? reviewId,
    String? reviewType,
    ReviewReviewerRef? reviewer,
    ReviewBasis? basis,
    List<ReviewFindingContract>? findings,
    String? riskLevel,
    String? recommendedDisposition,
    String? repairBrief,
    String? summary,
    List<String>? evidencePaths,
    String? createdAt,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    return ReviewContract(
      reviewId: reviewId ?? this.reviewId,
      reviewType: reviewType ?? this.reviewType,
      reviewer: reviewer ?? this.reviewer,
      basis: basis ?? this.basis,
      findings: findings ?? this.findings,
      riskLevel: riskLevel ?? this.riskLevel,
      recommendedDisposition:
          recommendedDisposition ?? this.recommendedDisposition,
      repairBrief: repairBrief ?? this.repairBrief,
      summary: summary ?? this.summary,
      evidencePaths: evidencePaths ?? this.evidencePaths,
      createdAt: createdAt ?? this.createdAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ReviewContract.fromJson(JsonMap json) {
    return ReviewContract(
      reviewId: ValueReaders.stringValue(json['review_id']).trim(),
      reviewType: ValueReaders.stringValue(json['review_type']).trim(),
      reviewer: ReviewReviewerRef.fromJson(
        ValueReaders.mapValue(json['reviewer']),
      ),
      basis: ReviewBasis.fromJson(ValueReaders.mapValue(json['basis'])),
      findings: ValueReaders.mapList(
        json['findings'],
      ).map(ReviewFindingContract.fromJson).toList(growable: false),
      riskLevel: ValueReaders.stringValue(
        json['risk_level'],
        ReviewRiskLevels.none,
      ).trim(),
      recommendedDisposition: ValueReaders.stringValue(
        json['recommended_disposition'],
        ReviewRecommendedDispositions.accept,
      ).trim(),
      repairBrief: ValueReaders.stringValue(json['repair_brief']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      evidencePaths: ValueReaders.stringList(json['evidence_paths']),
      createdAt: ValueReaders.stringValue(json['created_at']).trim(),
      schemaVersion: _reviewContractCodecService.readSchemaVersion(json),
      metadata: _reviewContractCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _reviewContractKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _reviewContractCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'review_id': reviewId,
        'review_type': reviewType,
        'reviewer': reviewer.toJson(),
        'basis': basis.toJson(),
        'findings': findings.map((entry) => entry.toJson()).toList(
          growable: false,
        ),
        'risk_level': riskLevel,
        'recommended_disposition': recommendedDisposition,
        'repair_brief': repairBrief,
        'summary': summary,
        'evidence_paths': evidencePaths,
        'created_at': createdAt,
        'schema_version': schemaVersion,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _reviewContractValidatorService.requireNonBlankString(
        reviewId,
        ReviewContractValidationCodes.missingReviewId,
      ),
    );
    result.addAll(
      _reviewContractValidatorService.requireNonBlankString(
        reviewType,
        ReviewContractValidationCodes.missingReviewType,
      ),
    );
    result.addAll(reviewer.validateBasics());
    result.addAll(basis.validateBasics());
    if (!ReviewRiskLevels.knownValues.contains(riskLevel)) {
      result.add(ReviewContractValidationCodes.invalidRiskLevel);
    }
    if (!ReviewRecommendedDispositions.knownValues.contains(
      recommendedDisposition,
    )) {
      result.add(
        ReviewContractValidationCodes.invalidRecommendedDisposition,
      );
    }
    result.addAll(
      _reviewContractValidatorService.requireNonEmptyCollection(
        evidencePaths,
        ReviewContractValidationCodes.missingEvidencePaths,
      ),
    );
    if (recommendedDisposition == ReviewRecommendedDispositions.repair &&
        repairBrief.trim().isEmpty) {
      result.add(ReviewContractValidationCodes.repairDispositionNeedsBrief);
    }
    result.addAll(findings.expand((finding) => finding.validateBasics()));
    return result;
  }
}
