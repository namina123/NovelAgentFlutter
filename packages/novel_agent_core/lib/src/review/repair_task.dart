import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'repair_contract_catalog.dart';

const _repairTaskCodecService = OpenJsonContractCodecService();
const _repairTaskValidatorService = OpenJsonStructureValidatorService();
const _repairTaskKnownFields = <String>{
  'task_id',
  'request_id',
  'title',
  'goal',
  'target_paths',
  'context_paths',
  'status',
  'blocks_main_flow',
  'metadata',
};

class RepairTask {
  const RepairTask({
    required this.taskId,
    required this.requestId,
    required this.title,
    required this.goal,
    this.targetPaths = const <String>[],
    this.contextPaths = const <String>[],
    this.status = RepairTaskStatuses.queued,
    this.blocksMainFlow = false,
    this.metadata = const <String, Object?>{},
  });

  final String taskId;
  final String requestId;
  final String title;
  final String goal;
  final List<String> targetPaths;
  final List<String> contextPaths;
  final String status;
  final bool blocksMainFlow;
  final JsonMap metadata;

  RepairTask copyWith({
    String? taskId,
    String? requestId,
    String? title,
    String? goal,
    List<String>? targetPaths,
    List<String>? contextPaths,
    String? status,
    bool? blocksMainFlow,
    JsonMap? metadata,
  }) {
    return RepairTask(
      taskId: taskId ?? this.taskId,
      requestId: requestId ?? this.requestId,
      title: title ?? this.title,
      goal: goal ?? this.goal,
      targetPaths: targetPaths ?? this.targetPaths,
      contextPaths: contextPaths ?? this.contextPaths,
      status: status ?? this.status,
      blocksMainFlow: blocksMainFlow ?? this.blocksMainFlow,
      metadata: metadata ?? this.metadata,
    );
  }

  factory RepairTask.fromJson(JsonMap json) {
    return RepairTask(
      taskId: ValueReaders.stringValue(json['task_id']).trim(),
      requestId: ValueReaders.stringValue(json['request_id']).trim(),
      title: ValueReaders.stringValue(json['title']).trim(),
      goal: ValueReaders.stringValue(json['goal']).trim(),
      targetPaths: ValueReaders.stringList(json['target_paths']),
      contextPaths: ValueReaders.stringList(json['context_paths']),
      status: ValueReaders.stringValue(
        json['status'],
        RepairTaskStatuses.queued,
      ).trim(),
      blocksMainFlow: ValueReaders.boolValue(json['blocks_main_flow']),
      metadata: _repairTaskCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _repairTaskKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _repairTaskCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'task_id': taskId,
        'request_id': requestId,
        'title': title,
        'goal': goal,
        'target_paths': targetPaths,
        'context_paths': contextPaths,
        'status': status,
        'blocks_main_flow': blocksMainFlow,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _repairTaskValidatorService.requireNonBlankString(
        taskId,
        RepairContractValidationCodes.missingRepairTaskId,
      ),
    );
    result.addAll(
      _repairTaskValidatorService.requireNonBlankString(
        requestId,
        RepairContractValidationCodes.missingRepairTaskRequestId,
      ),
    );
    result.addAll(
      _repairTaskValidatorService.requireNonBlankString(
        title,
        RepairContractValidationCodes.missingRepairTaskTitle,
      ),
    );
    result.addAll(
      _repairTaskValidatorService.requireNonBlankString(
        goal,
        RepairContractValidationCodes.missingRepairTaskGoal,
      ),
    );
    if (!RepairTaskStatuses.knownValues.contains(status)) {
      result.add(RepairContractValidationCodes.invalidRepairTaskStatus);
    }
    return result;
  }
}
