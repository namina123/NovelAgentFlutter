import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'repair_contract_catalog.dart';

const _repairOutcomeCodecService = OpenJsonContractCodecService();
const _repairOutcomeValidatorService = OpenJsonStructureValidatorService();
const _repairOutcomeKnownFields = <String>{
  'request_id',
  'task_id',
  'status',
  'summary',
  'produced_paths',
  'remaining_blocks_main_flow',
  'metadata',
};

class RepairOutcome {
  const RepairOutcome({
    required this.requestId,
    required this.status,
    required this.summary,
    this.taskId = '',
    this.producedPaths = const <String>[],
    this.remainingBlocksMainFlow = false,
    this.metadata = const <String, Object?>{},
  });

  final String requestId;
  final String taskId;
  final String status;
  final String summary;
  final List<String> producedPaths;
  final bool remainingBlocksMainFlow;
  final JsonMap metadata;

  RepairOutcome copyWith({
    String? requestId,
    String? taskId,
    String? status,
    String? summary,
    List<String>? producedPaths,
    bool? remainingBlocksMainFlow,
    JsonMap? metadata,
  }) {
    return RepairOutcome(
      requestId: requestId ?? this.requestId,
      taskId: taskId ?? this.taskId,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      producedPaths: producedPaths ?? this.producedPaths,
      remainingBlocksMainFlow:
          remainingBlocksMainFlow ?? this.remainingBlocksMainFlow,
      metadata: metadata ?? this.metadata,
    );
  }

  factory RepairOutcome.fromJson(JsonMap json) {
    return RepairOutcome(
      requestId: ValueReaders.stringValue(json['request_id']).trim(),
      taskId: ValueReaders.stringValue(json['task_id']).trim(),
      status: ValueReaders.stringValue(
        json['status'],
        RepairOutcomeStatuses.completed,
      ).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      producedPaths: ValueReaders.stringList(json['produced_paths']),
      remainingBlocksMainFlow: ValueReaders.boolValue(
        json['remaining_blocks_main_flow'],
      ),
      metadata: _repairOutcomeCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _repairOutcomeKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _repairOutcomeCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'request_id': requestId,
        'task_id': taskId,
        'status': status,
        'summary': summary,
        'produced_paths': producedPaths,
        'remaining_blocks_main_flow': remainingBlocksMainFlow,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _repairOutcomeValidatorService.requireNonBlankString(
        requestId,
        RepairContractValidationCodes.missingRepairOutcomeRequestId,
      ),
    );
    result.addAll(
      _repairOutcomeValidatorService.requireNonBlankString(
        summary,
        RepairContractValidationCodes.missingRepairOutcomeSummary,
      ),
    );
    if (!RepairOutcomeStatuses.knownValues.contains(status)) {
      result.add(RepairContractValidationCodes.invalidRepairOutcomeStatus);
    }
    return result;
  }
}
