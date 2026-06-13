import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'review_contract_catalog.dart';

const _reviewBasisCodecService = OpenJsonContractCodecService();
const _reviewBasisValidatorService = OpenJsonStructureValidatorService();
const _reviewBasisKnownFields = <String>{
  'basis_type',
  'summary',
  'source_paths',
  'target_paths',
  'policy_refs',
  'metadata',
};

class ReviewBasis {
  const ReviewBasis({
    required this.basisType,
    this.summary = '',
    this.sourcePaths = const <String>[],
    this.targetPaths = const <String>[],
    this.policyRefs = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String basisType;
  final String summary;
  final List<String> sourcePaths;
  final List<String> targetPaths;
  final List<String> policyRefs;
  final JsonMap metadata;

  ReviewBasis copyWith({
    String? basisType,
    String? summary,
    List<String>? sourcePaths,
    List<String>? targetPaths,
    List<String>? policyRefs,
    JsonMap? metadata,
  }) {
    return ReviewBasis(
      basisType: basisType ?? this.basisType,
      summary: summary ?? this.summary,
      sourcePaths: sourcePaths ?? this.sourcePaths,
      targetPaths: targetPaths ?? this.targetPaths,
      policyRefs: policyRefs ?? this.policyRefs,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ReviewBasis.fromJson(JsonMap json) {
    return ReviewBasis(
      basisType: ValueReaders.stringValue(json['basis_type']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      sourcePaths: ValueReaders.stringList(json['source_paths']),
      targetPaths: ValueReaders.stringList(json['target_paths']),
      policyRefs: ValueReaders.stringList(json['policy_refs']),
      metadata: _reviewBasisCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _reviewBasisKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _reviewBasisCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'basis_type': basisType,
        'summary': summary,
        'source_paths': sourcePaths,
        'target_paths': targetPaths,
        'policy_refs': policyRefs,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _reviewBasisValidatorService.requireNonBlankString(
        basisType,
        ReviewContractValidationCodes.missingBasisType,
      ),
    );
    result.addAll(
      _reviewBasisValidatorService.requireCondition(
        summary.trim().isNotEmpty ||
            sourcePaths.isNotEmpty ||
            targetPaths.isNotEmpty,
        ReviewContractValidationCodes.missingBasisAnchor,
      ),
    );
    return result;
  }
}
