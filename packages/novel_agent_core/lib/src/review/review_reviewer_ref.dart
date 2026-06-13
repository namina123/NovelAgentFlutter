import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'review_contract_catalog.dart';

const _reviewReviewerRefCodecService = OpenJsonContractCodecService();
const _reviewReviewerRefValidatorService = OpenJsonStructureValidatorService();
const _reviewReviewerRefKnownFields = <String>{
  'reviewer_id',
  'reviewer_role',
  'label',
  'metadata',
};

class ReviewReviewerRef {
  const ReviewReviewerRef({
    required this.reviewerId,
    required this.reviewerRole,
    this.label = '',
    this.metadata = const <String, Object?>{},
  });

  final String reviewerId;
  final String reviewerRole;
  final String label;
  final JsonMap metadata;

  ReviewReviewerRef copyWith({
    String? reviewerId,
    String? reviewerRole,
    String? label,
    JsonMap? metadata,
  }) {
    return ReviewReviewerRef(
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerRole: reviewerRole ?? this.reviewerRole,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ReviewReviewerRef.fromJson(JsonMap json) {
    return ReviewReviewerRef(
      reviewerId: ValueReaders.stringValue(json['reviewer_id']).trim(),
      reviewerRole: ValueReaders.stringValue(json['reviewer_role']).trim(),
      label: ValueReaders.stringValue(json['label']).trim(),
      metadata: _reviewReviewerRefCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _reviewReviewerRefKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _reviewReviewerRefCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'reviewer_id': reviewerId,
        'reviewer_role': reviewerRole,
        'label': label,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _reviewReviewerRefValidatorService.requireNonBlankString(
        reviewerId,
        ReviewContractValidationCodes.missingReviewerId,
      ),
    );
    result.addAll(
      _reviewReviewerRefValidatorService.requireNonBlankString(
        reviewerRole,
        ReviewContractValidationCodes.missingReviewerRole,
      ),
    );
    return result;
  }
}
