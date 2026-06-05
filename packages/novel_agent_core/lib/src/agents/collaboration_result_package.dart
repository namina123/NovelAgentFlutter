import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'collaboration_arbitration_result.dart';
import 'collaboration_conflict_record.dart';
import 'sub_agent_contract_components.dart';

class CollaborationResultPackage {
  const CollaborationResultPackage({
    this.packageId = '',
    this.executionPackageId = '',
    this.childRunPackageId = '',
    this.strategy = '',
    this.agentId = '',
    this.agentName = '',
    this.subSessionId = '',
    this.continueSessionId = '',
    this.task = '',
    this.status = '',
    this.retryable = false,
    this.cancelled = false,
    this.usedToolCount = 0,
    this.resultSummary = '',
    this.resultMarkdown = '',
    this.mergeContract = const CollaborationMergeContract(),
    this.conflicts = const <CollaborationConflictRecord>[],
    this.arbitrationResult = const CollaborationArbitrationResult(),
    this.metadata = const <String, Object?>{},
  });

  final String packageId;
  final String executionPackageId;
  final String childRunPackageId;
  final String strategy;
  final String agentId;
  final String agentName;
  final String subSessionId;
  final String continueSessionId;
  final String task;
  final String status;
  final bool retryable;
  final bool cancelled;
  final int usedToolCount;
  final String resultSummary;
  final String resultMarkdown;
  final CollaborationMergeContract mergeContract;
  final List<CollaborationConflictRecord> conflicts;
  final CollaborationArbitrationResult arbitrationResult;
  final JsonMap metadata;

  factory CollaborationResultPackage.fromJson(JsonMap json) {
    return CollaborationResultPackage(
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      executionPackageId: ValueReaders.stringValue(
        json['execution_package_id'],
      ).trim(),
      childRunPackageId: ValueReaders.stringValue(
        json['child_run_package_id'],
      ).trim(),
      strategy: ValueReaders.stringValue(json['strategy']).trim(),
      agentId: ValueReaders.stringValue(json['agent_id']).trim(),
      agentName: ValueReaders.stringValue(json['agent_name']).trim(),
      subSessionId: ValueReaders.stringValue(json['sub_session_id']).trim(),
      continueSessionId: ValueReaders.stringValue(
        json['continue_session_id'],
      ).trim(),
      task: ValueReaders.stringValue(json['task']).trim(),
      status: ValueReaders.stringValue(json['status']).trim(),
      retryable: ValueReaders.boolValue(json['retryable']),
      cancelled: ValueReaders.boolValue(json['cancelled']),
      usedToolCount: ValueReaders.intValue(json['used_tool_count']),
      resultSummary: ValueReaders.stringValue(json['result_summary']).trim(),
      resultMarkdown: ValueReaders.stringValue(json['result_markdown']).trim(),
      mergeContract: CollaborationMergeContract.fromJson(
        ValueReaders.mapValue(json['merge_contract']),
      ),
      conflicts: ValueReaders.mapList(
        json['conflicts'],
      ).map(CollaborationConflictRecord.fromJson).toList(growable: false),
      arbitrationResult: CollaborationArbitrationResult.fromJson(
        ValueReaders.mapValue(json['arbitration_result']),
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'package_id': packageId,
      'execution_package_id': executionPackageId,
      'child_run_package_id': childRunPackageId,
      'strategy': strategy,
      'agent_id': agentId,
      'agent_name': agentName,
      'sub_session_id': subSessionId,
      'continue_session_id': continueSessionId,
      'task': task,
      'status': status,
      'retryable': retryable,
      'cancelled': cancelled,
      'used_tool_count': usedToolCount,
      'result_summary': resultSummary,
      'result_markdown': resultMarkdown,
      'merge_contract': mergeContract.toJson(),
      'conflicts': conflicts
          .map((entry) => entry.toJson())
          .cast<Object?>()
          .toList(growable: false),
      'arbitration_result': arbitrationResult.toJson(),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (packageId.trim().isEmpty) {
      result.add('missing_collaboration_result_package_id');
    }
    if (executionPackageId.trim().isEmpty) {
      result.add('missing_collaboration_result_execution_package_id');
    }
    if (childRunPackageId.trim().isEmpty) {
      result.add('missing_collaboration_result_child_run_package_id');
    }
    if (agentId.trim().isEmpty && agentName.trim().isEmpty) {
      result.add('missing_collaboration_result_agent_identity');
    }
    if (status.trim().isEmpty) {
      result.add('missing_collaboration_result_status');
    }
    if (usedToolCount < 0) {
      result.add('invalid_collaboration_result_tool_count');
    }
    if (conflicts.expand((entry) => entry.validateBasics()).isNotEmpty) {
      result.add('invalid_collaboration_result_conflicts');
    }
    result.addAll(arbitrationResult.validateBasics());
    result.addAll(mergeContract.validateBasics());
    return result;
  }
}
