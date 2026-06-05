import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'writing_execution_collaboration_summary.dart';
import 'writing_execution_constraint_summary.dart';
import 'writing_execution_delivery_summary.dart';
import 'writing_execution_information_summary.dart';
import 'writing_execution_outcome_statuses.dart';
import 'writing_execution_recovery_summary.dart';

class WritingExecutionResult {
  const WritingExecutionResult({
    required this.executionId,
    required this.workflowKind,
    required this.overallStatus,
    required this.summary,
    required this.delivery,
    required this.constraints,
    required this.information,
    required this.collaboration,
    required this.recovery,
    this.nextAction = '',
    this.blocksProgress = false,
    this.retryable = false,
    this.requiresUserAction = false,
    this.schemaVersion = 1,
    this.metadata = const <String, Object?>{},
  });

  final String executionId;
  final String workflowKind;
  final String overallStatus;
  final String summary;
  final WritingExecutionDeliverySummary delivery;
  final WritingExecutionConstraintSummary constraints;
  final WritingExecutionInformationSummary information;
  final WritingExecutionCollaborationSummary collaboration;
  final WritingExecutionRecoverySummary recovery;
  final String nextAction;
  final bool blocksProgress;
  final bool retryable;
  final bool requiresUserAction;
  final int schemaVersion;
  final JsonMap metadata;

  factory WritingExecutionResult.fromJson(JsonMap json) {
    // 中文注释: 聚合结果回读时固定五段子合同形状，方便后续 session 逐步接线而不反复改宿主协议。
    return WritingExecutionResult(
      executionId: ValueReaders.stringValue(json['execution_id']).trim(),
      workflowKind: ValueReaders.stringValue(json['workflow_kind']).trim(),
      overallStatus: ValueReaders.stringValue(json['overall_status']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      delivery: WritingExecutionDeliverySummary.fromJson(
        ValueReaders.mapValue(json['delivery']),
      ),
      constraints: WritingExecutionConstraintSummary.fromJson(
        ValueReaders.mapValue(json['constraints']),
      ),
      information: WritingExecutionInformationSummary.fromJson(
        ValueReaders.mapValue(json['information']),
      ),
      collaboration: WritingExecutionCollaborationSummary.fromJson(
        ValueReaders.mapValue(json['collaboration']),
      ),
      recovery: WritingExecutionRecoverySummary.fromJson(
        ValueReaders.mapValue(json['recovery']),
      ),
      nextAction: ValueReaders.stringValue(json['next_action']).trim(),
      blocksProgress: ValueReaders.boolValue(json['blocks_progress']),
      retryable: ValueReaders.boolValue(json['retryable']),
      requiresUserAction: ValueReaders.boolValue(json['requires_user_action']),
      schemaVersion: ValueReaders.intValue(json['schema_version'], 1),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 聚合结果序列化为稳定 JSON 后，ordinary/long task/deconstruction 都能消费同一壳层协议。
    return <String, Object?>{
      'execution_id': executionId,
      'workflow_kind': workflowKind,
      'overall_status': overallStatus,
      'summary': summary,
      'delivery': delivery.toJson(),
      'constraints': constraints.toJson(),
      'information': information.toJson(),
      'collaboration': collaboration.toJson(),
      'recovery': recovery.toJson(),
      'next_action': nextAction,
      'blocks_progress': blocksProgress,
      'retryable': retryable,
      'requires_user_action': requiresUserAction,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 聚合校验只检查共享合同能否稳定传输，不再重跑 delivery/review/recovery 业务算法。
    final result = <String>[];
    if (executionId.trim().isEmpty) {
      result.add('missing_writing_execution_result_id');
    }
    if (workflowKind.trim().isEmpty) {
      result.add('missing_writing_execution_result_workflow_kind');
    }
    if (!WritingExecutionOutcomeStatuses.knownValues.contains(overallStatus)) {
      result.add('invalid_writing_execution_result_status');
    }
    result.addAll(delivery.validateBasics());
    result.addAll(constraints.validateBasics());
    result.addAll(information.validateBasics());
    result.addAll(collaboration.validateBasics());
    result.addAll(recovery.validateBasics());
    return result;
  }
}
