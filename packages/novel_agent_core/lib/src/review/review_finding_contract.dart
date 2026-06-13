import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'review_contract_catalog.dart';

const _reviewFindingContractCodecService = OpenJsonContractCodecService();
const _reviewFindingContractValidatorService =
    OpenJsonStructureValidatorService();
const _reviewFindingContractKnownFields = <String>{
  'finding_id',
  'severity',
  'summary',
  'suggested_action',
  'evidence_paths',
  'metadata',
};

class ReviewFindingContract {
  const ReviewFindingContract({
    required this.findingId,
    required this.severity,
    required this.summary,
    this.suggestedAction = '',
    this.evidencePaths = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String findingId;
  final String severity;
  final String summary;
  final String suggestedAction;
  final List<String> evidencePaths;
  final JsonMap metadata;

  ReviewFindingContract copyWith({
    String? findingId,
    String? severity,
    String? summary,
    String? suggestedAction,
    List<String>? evidencePaths,
    JsonMap? metadata,
  }) {
    return ReviewFindingContract(
      findingId: findingId ?? this.findingId,
      severity: severity ?? this.severity,
      summary: summary ?? this.summary,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      evidencePaths: evidencePaths ?? this.evidencePaths,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ReviewFindingContract.fromJson(JsonMap json) {
    return ReviewFindingContract(
      findingId: ValueReaders.stringValue(json['finding_id']).trim(),
      severity: ValueReaders.stringValue(
        json['severity'],
        ReviewFindingSeverities.info,
      ).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      suggestedAction: ValueReaders.stringValue(
        json['suggested_action'],
      ).trim(),
      evidencePaths: ValueReaders.stringList(json['evidence_paths']),
      metadata: _reviewFindingContractCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _reviewFindingContractKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _reviewFindingContractCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'finding_id': findingId,
        'severity': severity,
        'summary': summary,
        'suggested_action': suggestedAction,
        'evidence_paths': evidencePaths,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _reviewFindingContractValidatorService.requireNonBlankString(
        findingId,
        ReviewContractValidationCodes.missingFindingId,
      ),
    );
    result.addAll(
      _reviewFindingContractValidatorService.requireNonBlankString(
        summary,
        ReviewContractValidationCodes.missingFindingSummary,
      ),
    );
    if (!ReviewFindingSeverities.knownValues.contains(severity)) {
      result.add(ReviewContractValidationCodes.invalidFindingSeverity);
    }
    return result;
  }
}
