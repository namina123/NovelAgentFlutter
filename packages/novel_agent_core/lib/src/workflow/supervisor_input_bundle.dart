import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../runtime/long_task_stop_outcome.dart';
import 'writing_execution_collaboration_summary.dart';
import 'writing_execution_constraint_summary.dart';
import 'writing_execution_delivery_summary.dart';
import 'writing_execution_information_summary.dart';
import 'writing_execution_recovery_summary.dart';
import 'writing_execution_result.dart';

class SupervisorInputBundle {
  const SupervisorInputBundle({
    this.present = false,
    this.executionId = '',
    this.workflowKind = '',
    this.overallStatus = '',
    this.summary = '',
    this.nextAction = '',
    this.blocksProgress = false,
    this.retryable = false,
    this.requiresUserAction = false,
    this.stopReasonHint = '',
    this.fallbackNote = '',
    this.delivery = const WritingExecutionDeliverySummary(),
    this.constraints = const WritingExecutionConstraintSummary(),
    this.information = const WritingExecutionInformationSummary(),
    this.collaboration = const WritingExecutionCollaborationSummary(),
    this.recovery = const WritingExecutionRecoverySummary(),
    this.stopOutcome = const LongTaskStopOutcome(),
    this.schemaVersion = 1,
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String executionId;
  final String workflowKind;
  final String overallStatus;
  final String summary;
  final String nextAction;
  final bool blocksProgress;
  final bool retryable;
  final bool requiresUserAction;
  final String stopReasonHint;
  final String fallbackNote;
  final WritingExecutionDeliverySummary delivery;
  final WritingExecutionConstraintSummary constraints;
  final WritingExecutionInformationSummary information;
  final WritingExecutionCollaborationSummary collaboration;
  final WritingExecutionRecoverySummary recovery;
  final LongTaskStopOutcome stopOutcome;
  final int schemaVersion;
  final JsonMap metadata;

  factory SupervisorInputBundle.fromWritingExecutionResult(
    WritingExecutionResult executionResult, {
    LongTaskStopOutcome stopOutcome = const LongTaskStopOutcome(),
    String stopReasonHint = '',
    String fallbackNote = '',
  }) {
    // 中文注释: supervisor 输入包统一承接共享写作结果与 stop outcome，避免后续控制面继续直接拼零散字段。
    return SupervisorInputBundle(
      present: true,
      executionId: executionResult.executionId,
      workflowKind: executionResult.workflowKind,
      overallStatus: executionResult.overallStatus,
      summary: executionResult.summary,
      nextAction: executionResult.nextAction,
      blocksProgress: executionResult.blocksProgress,
      retryable: executionResult.retryable,
      requiresUserAction: executionResult.requiresUserAction,
      stopReasonHint: stopReasonHint.trim(),
      fallbackNote: fallbackNote.trim(),
      delivery: executionResult.delivery,
      constraints: executionResult.constraints,
      information: executionResult.information,
      collaboration: executionResult.collaboration,
      recovery: executionResult.recovery,
      stopOutcome: stopOutcome,
      metadata: ValueReaders.deepCopyMap(executionResult.metadata),
    );
  }

  factory SupervisorInputBundle.fromJson(JsonMap json) {
    // 中文注释: 输入包允许稳定回读，方便后续 runtime、probe 与 projection 统一消费监督层输入真相。
    return SupervisorInputBundle(
      present: ValueReaders.boolValue(json['present']),
      executionId: ValueReaders.stringValue(json['execution_id']).trim(),
      workflowKind: ValueReaders.stringValue(json['workflow_kind']).trim(),
      overallStatus: ValueReaders.stringValue(json['overall_status']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      nextAction: ValueReaders.stringValue(json['next_action']).trim(),
      blocksProgress: ValueReaders.boolValue(json['blocks_progress']),
      retryable: ValueReaders.boolValue(json['retryable']),
      requiresUserAction: ValueReaders.boolValue(json['requires_user_action']),
      stopReasonHint: ValueReaders.stringValue(json['stop_reason_hint']).trim(),
      fallbackNote: ValueReaders.stringValue(json['fallback_note']).trim(),
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
      stopOutcome: LongTaskStopOutcome.fromJson(
        ValueReaders.mapValue(json['stop_outcome']),
      ),
      schemaVersion: ValueReaders.intValue(json['schema_version'], 1),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 输入包序列化后只保留监督层真正需要的稳定字段，不把宿主私有拼装逻辑继续外泄。
    return <String, Object?>{
      'present': present,
      'execution_id': executionId,
      'workflow_kind': workflowKind,
      'overall_status': overallStatus,
      'summary': summary,
      'next_action': nextAction,
      'blocks_progress': blocksProgress,
      'retryable': retryable,
      'requires_user_action': requiresUserAction,
      'stop_reason_hint': stopReasonHint,
      'fallback_note': fallbackNote,
      'delivery': delivery.toJson(),
      'constraints': constraints.toJson(),
      'information': information.toJson(),
      'collaboration': collaboration.toJson(),
      'recovery': recovery.toJson(),
      'stop_outcome': stopOutcome.toJson(),
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 输入包校验只检查监督层合同是否成形，不在这里重跑 delivery、review 或 recovery 业务算法。
    if (!present) {
      return const <String>[];
    }
    final result = <String>[];
    if (executionId.trim().isEmpty) {
      result.add('missing_supervisor_input_execution_id');
    }
    if (workflowKind.trim().isEmpty) {
      result.add('missing_supervisor_input_workflow_kind');
    }
    result.addAll(delivery.validateBasics());
    result.addAll(constraints.validateBasics());
    result.addAll(information.validateBasics());
    result.addAll(collaboration.validateBasics());
    result.addAll(recovery.validateBasics());
    result.addAll(stopOutcome.validateBasics());
    return result;
  }
}
