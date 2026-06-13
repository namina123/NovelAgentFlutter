import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../runtime/long_task_run_status.dart';
import '../runtime/long_task_stop_outcome.dart';
import 'supervisor_decision_action.dart';

class SupervisorDecision {
  const SupervisorDecision({
    this.present = false,
    this.action = '',
    this.reason = '',
    this.summary = '',
    this.note = '',
    this.runStatus = '',
    this.recoveryAction = '',
    this.blocksProgress = false,
    this.retryable = false,
    this.requiresUserAction = false,
    this.legacyStopReason = '',
    this.stopOutcome = const LongTaskStopOutcome(),
    this.schemaVersion = 1,
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String action;
  final String reason;
  final String summary;
  final String note;
  final String runStatus;
  final String recoveryAction;
  final bool blocksProgress;
  final bool retryable;
  final bool requiresUserAction;
  final String legacyStopReason;
  final LongTaskStopOutcome stopOutcome;
  final int schemaVersion;
  final JsonMap metadata;

  factory SupervisorDecision.fromJson(JsonMap json) {
    // 中文注释: 决策合同允许独立回读，方便 runtime/projection 不再重新猜测 supervisor 当时如何判定下一步。
    return SupervisorDecision(
      present: ValueReaders.boolValue(json['present']),
      action: ValueReaders.stringValue(json['action']).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      note: ValueReaders.stringValue(json['note']).trim(),
      runStatus: ValueReaders.stringValue(json['run_status']).trim(),
      recoveryAction: ValueReaders.stringValue(
        json['recovery_action'],
      ).trim(),
      blocksProgress: ValueReaders.boolValue(json['blocks_progress']),
      retryable: ValueReaders.boolValue(json['retryable']),
      requiresUserAction: ValueReaders.boolValue(json['requires_user_action']),
      legacyStopReason: ValueReaders.stringValue(
        json['legacy_stop_reason'],
      ).trim(),
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
    // 中文注释: 决策序列化显式保留 legacy_stop_reason 与 stop_outcome，确保兼容层字段全部由中央决策合同派生。
    return <String, Object?>{
      'present': present,
      'action': action,
      'reason': reason,
      'summary': summary,
      'note': note,
      'run_status': runStatus,
      'recovery_action': recoveryAction,
      'blocks_progress': blocksProgress,
      'retryable': retryable,
      'requires_user_action': requiresUserAction,
      'legacy_stop_reason': legacyStopReason,
      'stop_outcome': stopOutcome.toJson(),
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 决策校验只保证动作、状态和兼容字段自洽，不替代具体 runtime 的状态机转换规则。
    if (!present) {
      return const <String>[];
    }
    final result = <String>[];
    if (!SupervisorDecisionActions.knownValues.contains(action)) {
      result.add('invalid_supervisor_decision_action');
    }
    if (reason.trim().isEmpty) {
      result.add('missing_supervisor_decision_reason');
    }
    if (!_isKnownRunStatus(runStatus)) {
      result.add('invalid_supervisor_decision_run_status');
    }
    if (requiresUserAction &&
        action != SupervisorDecisionActions.waitingUser) {
      result.add('invalid_supervisor_decision_user_action_state');
    }
    result.addAll(stopOutcome.validateBasics());
    return result;
  }

  bool _isKnownRunStatus(String value) {
    // 中文注释: 这里集中约束 run status id，避免决策合同写出 runtime 无法识别的新状态字符串。
    for (final status in LongTaskRunStatus.values) {
      if (status.id == value.trim()) {
        return true;
      }
    }
    return false;
  }
}
