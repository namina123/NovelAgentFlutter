import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../runtime/long_task_run_status.dart';
import '../runtime/long_task_stop_outcome.dart';

abstract final class LongTaskRecoveryStates {
  static const String idle = 'idle';
  static const String resumeReady = 'resume_ready';
  static const String readyRetry = 'ready_retry';
  static const String retrying = 'retrying';
  static const String pausedFailure = 'paused_failure';
  static const String repairRequired = 'repair_required';
  static const String waitingUser = 'waiting_user';
  static const String manualAttention = 'manual_attention';
  static const String reviewRequired = 'review_required';
  static const String exhausted = 'exhausted';
  static const String terminal = 'terminal';

  static const List<String> knownValues = <String>[
    idle,
    resumeReady,
    readyRetry,
    retrying,
    pausedFailure,
    repairRequired,
    waitingUser,
    manualAttention,
    reviewRequired,
    exhausted,
    terminal,
  ];
}

abstract final class LongTaskRecoveryExhaustedDispositions {
  static const String manualAttention = 'manual_attention';
  static const String waitingUser = 'waiting_user';
  static const String pause = 'pause';
  static const String stopRun = 'stop_run';

  static const List<String> knownValues = <String>[
    manualAttention,
    waitingUser,
    pause,
    stopRun,
  ];
}

class LongTaskRecoveryState {
  const LongTaskRecoveryState({
    this.present = false,
    this.state = '',
    this.runStatus = '',
    this.recommendedAction = '',
    this.reason = '',
    this.note = '',
    this.retryCount = 0,
    this.retryBudget = 0,
    this.retriesRemaining = 0,
    this.autoRetryEligible = false,
    this.blocksProgress = false,
    this.waitingUser = false,
    this.requiresRepair = false,
    this.manualAttentionRequired = false,
    this.exhausted = false,
    this.exhaustedDisposition = '',
    this.taskId = '',
    this.taskTitle = '',
    this.taskPath = '',
    this.stopOutcome = const LongTaskStopOutcome(),
    this.schemaVersion = 1,
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String state;
  final String runStatus;
  final String recommendedAction;
  final String reason;
  final String note;
  final int retryCount;
  final int retryBudget;
  final int retriesRemaining;
  final bool autoRetryEligible;
  final bool blocksProgress;
  final bool waitingUser;
  final bool requiresRepair;
  final bool manualAttentionRequired;
  final bool exhausted;
  final String exhaustedDisposition;
  final String taskId;
  final String taskTitle;
  final String taskPath;
  final LongTaskStopOutcome stopOutcome;
  final int schemaVersion;
  final JsonMap metadata;

  factory LongTaskRecoveryState.fromJson(JsonMap json) {
    // 中文注释: 恢复状态需要稳定回读，方便 runtime/scheduler/registry 持久化同一份恢复现场。
    return LongTaskRecoveryState(
      present: ValueReaders.boolValue(json['present']),
      state: ValueReaders.stringValue(json['state']).trim(),
      runStatus: ValueReaders.stringValue(json['run_status']).trim(),
      recommendedAction: ValueReaders.stringValue(
        json['recommended_action'],
      ).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      note: ValueReaders.stringValue(json['note']).trim(),
      retryCount: ValueReaders.intValue(json['retry_count']),
      retryBudget: ValueReaders.intValue(json['retry_budget']),
      retriesRemaining: ValueReaders.intValue(json['retries_remaining']),
      autoRetryEligible: ValueReaders.boolValue(json['auto_retry_eligible']),
      blocksProgress: ValueReaders.boolValue(json['blocks_progress']),
      waitingUser: ValueReaders.boolValue(json['waiting_user']),
      requiresRepair: ValueReaders.boolValue(json['requires_repair']),
      manualAttentionRequired: ValueReaders.boolValue(
        json['manual_attention_required'],
      ),
      exhausted: ValueReaders.boolValue(json['exhausted']),
      exhaustedDisposition: ValueReaders.stringValue(
        json['exhausted_disposition'],
      ).trim(),
      taskId: ValueReaders.stringValue(json['task_id']).trim(),
      taskTitle: ValueReaders.stringValue(json['task_title']).trim(),
      taskPath: ValueReaders.stringValue(json['task_path']).trim(),
      stopOutcome: LongTaskStopOutcome.fromJson(
        ValueReaders.mapValue(json['stop_outcome']),
      ),
      schemaVersion: ValueReaders.intValue(json['schema_version'], 1),
      metadata: ValueReaders.deepCopyMap(ValueReaders.mapValue(json['metadata'])),
    );
  }

  JsonMap toJson() {
    // 中文注释: 对外只暴露恢复控制面需要的稳定字段，不把完整 record/task 再次塞回合同。
    return <String, Object?>{
      'present': present,
      'state': state,
      'run_status': runStatus,
      'recommended_action': recommendedAction,
      'reason': reason,
      'note': note,
      'retry_count': retryCount,
      'retry_budget': retryBudget,
      'retries_remaining': retriesRemaining,
      'auto_retry_eligible': autoRetryEligible,
      'blocks_progress': blocksProgress,
      'waiting_user': waitingUser,
      'requires_repair': requiresRepair,
      'manual_attention_required': manualAttentionRequired,
      'exhausted': exhausted,
      'exhausted_disposition': exhaustedDisposition,
      'task_id': taskId,
      'task_title': taskTitle,
      'task_path': taskPath,
      'stop_outcome': stopOutcome.toJson(),
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 基础校验只检查恢复状态壳层自洽，不在这里重跑恢复策略判定本身。
    if (!present) {
      return const <String>[];
    }
    final result = <String>[];
    if (!LongTaskRecoveryStates.knownValues.contains(state)) {
      result.add('invalid_long_task_recovery_state');
    }
    if (runStatus.trim().isEmpty ||
        LongTaskRunStatus.fromId(runStatus).id != runStatus.trim()) {
      result.add('invalid_long_task_recovery_run_status');
    }
    if (recommendedAction.trim().isEmpty) {
      result.add('missing_long_task_recovery_action');
    }
    if (reason.trim().isEmpty) {
      result.add('missing_long_task_recovery_reason');
    }
    if (retryCount < 0 || retryBudget < 0 || retriesRemaining < 0) {
      result.add('invalid_long_task_recovery_retry_values');
    }
    if (exhausted &&
        !LongTaskRecoveryExhaustedDispositions.knownValues.contains(
          exhaustedDisposition,
        )) {
      result.add('invalid_long_task_recovery_exhausted_disposition');
    }
    result.addAll(stopOutcome.validateBasics());
    return result;
  }
}
