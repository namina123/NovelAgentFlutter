import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'repair_contract_catalog.dart';

const _repairRequestCodecService = OpenJsonContractCodecService();
const _repairRequestValidatorService = OpenJsonStructureValidatorService();
const _repairRequestKnownFields = <String>{
  'request_id',
  'source_review_id',
  'source_review_type',
  'source_disposition',
  'repair_brief',
  'finding_ids',
  'target_paths',
  'context_paths',
  'evidence_paths',
  'blocks_main_flow',
  'metadata',
};

class RepairRequest {
  const RepairRequest({
    required this.requestId,
    required this.sourceReviewId,
    required this.sourceReviewType,
    required this.sourceDisposition,
    required this.repairBrief,
    this.findingIds = const <String>[],
    this.targetPaths = const <String>[],
    this.contextPaths = const <String>[],
    this.evidencePaths = const <String>[],
    this.blocksMainFlow = false,
    this.metadata = const <String, Object?>{},
  });

  final String requestId;
  final String sourceReviewId;
  final String sourceReviewType;
  final String sourceDisposition;
  final String repairBrief;
  final List<String> findingIds;
  final List<String> targetPaths;
  final List<String> contextPaths;
  final List<String> evidencePaths;
  final bool blocksMainFlow;
  final JsonMap metadata;

  RepairRequest copyWith({
    String? requestId,
    String? sourceReviewId,
    String? sourceReviewType,
    String? sourceDisposition,
    String? repairBrief,
    List<String>? findingIds,
    List<String>? targetPaths,
    List<String>? contextPaths,
    List<String>? evidencePaths,
    bool? blocksMainFlow,
    JsonMap? metadata,
  }) {
    return RepairRequest(
      requestId: requestId ?? this.requestId,
      sourceReviewId: sourceReviewId ?? this.sourceReviewId,
      sourceReviewType: sourceReviewType ?? this.sourceReviewType,
      sourceDisposition: sourceDisposition ?? this.sourceDisposition,
      repairBrief: repairBrief ?? this.repairBrief,
      findingIds: findingIds ?? this.findingIds,
      targetPaths: targetPaths ?? this.targetPaths,
      contextPaths: contextPaths ?? this.contextPaths,
      evidencePaths: evidencePaths ?? this.evidencePaths,
      blocksMainFlow: blocksMainFlow ?? this.blocksMainFlow,
      metadata: metadata ?? this.metadata,
    );
  }

  factory RepairRequest.fromJson(JsonMap json) {
    return RepairRequest(
      requestId: ValueReaders.stringValue(json['request_id']).trim(),
      sourceReviewId: ValueReaders.stringValue(json['source_review_id']).trim(),
      sourceReviewType: ValueReaders.stringValue(
        json['source_review_type'],
      ).trim(),
      sourceDisposition: ValueReaders.stringValue(
        json['source_disposition'],
      ).trim(),
      repairBrief: ValueReaders.stringValue(json['repair_brief']).trim(),
      findingIds: ValueReaders.stringList(json['finding_ids']),
      targetPaths: ValueReaders.stringList(json['target_paths']),
      contextPaths: ValueReaders.stringList(json['context_paths']),
      evidencePaths: ValueReaders.stringList(json['evidence_paths']),
      blocksMainFlow: ValueReaders.boolValue(json['blocks_main_flow']),
      metadata: _repairRequestCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _repairRequestKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _repairRequestCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'request_id': requestId,
        'source_review_id': sourceReviewId,
        'source_review_type': sourceReviewType,
        'source_disposition': sourceDisposition,
        'repair_brief': repairBrief,
        'finding_ids': findingIds,
        'target_paths': targetPaths,
        'context_paths': contextPaths,
        'evidence_paths': evidencePaths,
        'blocks_main_flow': blocksMainFlow,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _repairRequestValidatorService.requireNonBlankString(
        requestId,
        RepairContractValidationCodes.missingRepairRequestId,
      ),
    );
    result.addAll(
      _repairRequestValidatorService.requireNonBlankString(
        sourceReviewId,
        RepairContractValidationCodes.missingRepairSourceReviewId,
      ),
    );
    result.addAll(
      _repairRequestValidatorService.requireNonBlankString(
        sourceDisposition,
        RepairContractValidationCodes.missingRepairSourceDisposition,
      ),
    );
    result.addAll(
      _repairRequestValidatorService.requireNonBlankString(
        repairBrief,
        RepairContractValidationCodes.missingRepairBrief,
      ),
    );
    result.addAll(
      _repairRequestValidatorService.requireNonEmptyCollection(
        targetPaths,
        RepairContractValidationCodes.missingRepairTargetPaths,
      ),
    );
    result.addAll(
      _repairRequestValidatorService.requireNonEmptyCollection(
        findingIds,
        RepairContractValidationCodes.missingRepairFindingIds,
      ),
    );
    return result;
  }
}
