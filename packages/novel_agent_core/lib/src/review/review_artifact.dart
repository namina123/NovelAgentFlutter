import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'review_contract_catalog.dart';
import 'review_summary.dart';

const _reviewArtifactCodecService = OpenJsonContractCodecService();
const _reviewArtifactValidatorService = OpenJsonStructureValidatorService();
const _reviewArtifactKnownFields = <String>{
  'artifact_id',
  'review_id',
  'summary',
  'json_path',
  'markdown_path',
  'created_at',
  'metadata',
};

class ReviewArtifact {
  const ReviewArtifact({
    required this.artifactId,
    required this.reviewId,
    required this.summary,
    this.jsonPath = '',
    this.markdownPath = '',
    this.createdAt = '',
    this.metadata = const <String, Object?>{},
  });

  final String artifactId;
  final String reviewId;
  final ReviewSummary summary;
  final String jsonPath;
  final String markdownPath;
  final String createdAt;
  final JsonMap metadata;

  ReviewArtifact copyWith({
    String? artifactId,
    String? reviewId,
    ReviewSummary? summary,
    String? jsonPath,
    String? markdownPath,
    String? createdAt,
    JsonMap? metadata,
  }) {
    return ReviewArtifact(
      artifactId: artifactId ?? this.artifactId,
      reviewId: reviewId ?? this.reviewId,
      summary: summary ?? this.summary,
      jsonPath: jsonPath ?? this.jsonPath,
      markdownPath: markdownPath ?? this.markdownPath,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ReviewArtifact.fromJson(JsonMap json) {
    return ReviewArtifact(
      artifactId: ValueReaders.stringValue(json['artifact_id']).trim(),
      reviewId: ValueReaders.stringValue(json['review_id']).trim(),
      summary: ReviewSummary.fromJson(ValueReaders.mapValue(json['summary'])),
      jsonPath: ValueReaders.stringValue(json['json_path']).trim(),
      markdownPath: ValueReaders.stringValue(json['markdown_path']).trim(),
      createdAt: ValueReaders.stringValue(json['created_at']).trim(),
      metadata: _reviewArtifactCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _reviewArtifactKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _reviewArtifactCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'artifact_id': artifactId,
        'review_id': reviewId,
        'summary': summary.toJson(),
        'json_path': jsonPath,
        'markdown_path': markdownPath,
        'created_at': createdAt,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _reviewArtifactValidatorService.requireNonBlankString(
        artifactId,
        ReviewContractValidationCodes.missingArtifactId,
      ),
    );
    result.addAll(
      _reviewArtifactValidatorService.requireNonBlankString(
        reviewId,
        ReviewContractValidationCodes.missingArtifactReviewId,
      ),
    );
    result.addAll(summary.validateBasics());
    result.addAll(
      _reviewArtifactValidatorService.requireCondition(
        jsonPath.trim().isNotEmpty || markdownPath.trim().isNotEmpty,
        ReviewContractValidationCodes.missingArtifactPath,
      ),
    );
    return result;
  }
}
