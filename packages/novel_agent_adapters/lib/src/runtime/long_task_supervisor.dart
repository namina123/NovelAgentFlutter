import 'package:novel_agent_core/novel_agent_core.dart';

import 'long_task_watchdog_dispatch_port.dart';

class LongTaskSupervisor {
  LongTaskSupervisor({
    required LongTaskRunRegistry runRegistry,
    LongTaskRunStateMachine? runStateMachine,
    LongTaskWritingExecutionSignalService? writingExecutionSignalService,
    LongTaskWatchdogDispatchPort? watchdogDispatchPort,
    ContinuousTaskLifecycleStopOutcomeResolverService?
    lifecycleStopOutcomeResolverService,
    ContinuousTaskLongTaskStatusMapperService?
    continuousTaskLongTaskStatusMapperService,
  }) : _runRegistry = runRegistry,
       _runStateMachine = runStateMachine ?? const LongTaskRunStateMachine(),
       _writingExecutionSignalService =
           writingExecutionSignalService ??
           const LongTaskWritingExecutionSignalService(),
       _watchdogDispatchPort = watchdogDispatchPort,
       _lifecycleStopOutcomeResolverService =
           lifecycleStopOutcomeResolverService ??
           const ContinuousTaskLifecycleStopOutcomeResolverService(),
       _continuousTaskLongTaskStatusMapperService =
           continuousTaskLongTaskStatusMapperService ??
           const ContinuousTaskLongTaskStatusMapperService();

  final LongTaskRunRegistry _runRegistry;
  final LongTaskRunStateMachine _runStateMachine;
  final LongTaskWritingExecutionSignalService _writingExecutionSignalService;
  final LongTaskWatchdogDispatchPort? _watchdogDispatchPort;
  final ContinuousTaskLifecycleStopOutcomeResolverService
  _lifecycleStopOutcomeResolverService;
  final ContinuousTaskLongTaskStatusMapperService
  _continuousTaskLongTaskStatusMapperService;

  bool get isRunning => _watchdogDispatchPort?.isWatchdogRunning ?? false;

  Future<void> trackRun(RunInstance instance) {
    // 中文注释: supervisor 只做“监督入口”的编排，不改变 registry 的持久化语义，也不直接推进 workflow。
    _watchdogDispatchPort?.clearDispatchState(instance.id);
    return _runRegistry.save(instance);
  }

  Future<void> trackContinuousTaskRun(
    RunInstance instance, {
    required ContinuousTaskControlProfile controlProfile,
    required ContinuousTaskLifecycleState lifecycleState,
    LongTaskRecoveryState recoveryState = const LongTaskRecoveryState(),
    JsonMap metadata = const <String, Object?>{},
  }) {
    final synchronized = _enrichContinuousTaskInstance(
      instance,
      controlProfile: controlProfile,
      lifecycleState: lifecycleState,
      recoveryState: recoveryState,
      metadata: metadata,
      occurredAt: instance.updatedAt,
    );
    return trackRun(synchronized);
  }

  Future<RunInstance?> loadRun(String runId) {
    return _runRegistry.findById(runId);
  }

  Future<List<RunInstance>> listAllRuns() {
    return _runRegistry.listAll();
  }

  Future<List<RunInstance>> listProjectRuns(String projectKey) {
    return _runRegistry.listByProject(projectKey);
  }

  Future<List<RunInstance>> listActiveRuns() {
    return _runRegistry.listActive();
  }

  Future<void> removeRun(String runId) async {
    _watchdogDispatchPort?.clearDispatchState(runId);
    await _runRegistry.delete(runId);
  }

  Future<RunInstance?> pauseRun(
    String runId, {
    DateTime? occurredAt,
    String note = '',
  }) {
    // 中文注释: 暂停入口只负责把运行实例切到 paused，并清理心跳派发节流状态。
    return _transitionRun(
      runId,
      LongTaskRunStatus.paused,
      occurredAt: occurredAt,
      note: note,
    );
  }

  Future<RunInstance?> resumeRun(
    String runId, {
    DateTime? occurredAt,
    String note = '',
  }) {
    // 中文注释: 当前恢复壳先统一回到 running；后续若引入更细恢复策略，再由 supervisor 内部继续分发。
    return _transitionRun(
      runId,
      LongTaskRunStatus.running,
      occurredAt: occurredAt,
      note: note,
    );
  }

  Future<RunInstance?> stopRun(
    String runId, {
    DateTime? occurredAt,
    String note = '',
    String stopReason = '',
  }) {
    // 中文注释: 停止会写入终止状态和原因，但不在这里做删除，让全局运行站仍能看到历史运行对象。
    return _transitionRun(
      runId,
      LongTaskRunStatus.stopped,
      occurredAt: occurredAt,
      note: note,
      stopReason: stopReason,
    );
  }

  Future<RunInstance?> applyWritingExecutionResult(
    String runId,
    JsonMap writingExecutionResult, {
    DateTime? occurredAt,
    String fallbackNote = '',
  }) async {
    final instance = await _runRegistry.findById(runId);
    if (instance == null) {
      return null;
    }
    final signal = _writingExecutionSignalService.signalFromPayload(
      result: <String, Object?>{
        'writing_execution_result': writingExecutionResult,
      },
      fallbackNote: fallbackNote,
    );
    if (!ValueReaders.boolValue(signal['present'])) {
      return instance;
    }
    final nextStatus = _statusFromSignal(signal, current: instance.status);
    final now = occurredAt ?? DateTime.now();
    final next = nextStatus == instance.status
        ? instance.copyWith(
            updatedAt: now,
            note: ValueReaders.stringValue(signal['note'], instance.note),
            stopReason: nextStatus == LongTaskRunStatus.stopped
                ? ValueReaders.stringValue(
                    signal['legacy_stop_reason'],
                    instance.stopReason,
                  )
                : instance.stopReason,
            metadata: <String, Object?>{
              ...ValueReaders.deepCopyMap(instance.metadata),
              'writing_execution_signal': signal,
            },
          )
        : _runStateMachine
              .transition(
                instance,
                nextStatus,
                occurredAt: now,
                note: ValueReaders.stringValue(signal['note']),
                stopReason: ValueReaders.stringValue(
                  signal['legacy_stop_reason'],
                ),
              )
              .copyWith(
                metadata: <String, Object?>{
                  ...ValueReaders.deepCopyMap(instance.metadata),
                  'writing_execution_signal': signal,
                },
              );
    await _runRegistry.save(next);
    _watchdogDispatchPort?.clearDispatchState(runId);
    return next;
  }

  Future<RunInstance?> applyRecoveryState(
    String runId,
    JsonMap recoveryPlan, {
    DateTime? occurredAt,
  }) async {
    // 中文注释: 恢复状态应用入口只消费正式 recovery_state 合同，并把运行实例切到对应 run status。
    final instance = await _runRegistry.findById(runId);
    if (instance == null) {
      return null;
    }
    final recoveryState = LongTaskRecoveryState.fromJson(
      ValueReaders.mapValue(recoveryPlan['recovery_state']),
    );
    if (!recoveryState.present) {
      return instance;
    }
    final desired = LongTaskRunStatus.fromId(recoveryState.runStatus);
    final now = occurredAt ?? DateTime.now();
    final next = _runStateMachine.canTransition(instance.status, desired)
        ? _runStateMachine
              .transition(
                instance,
                desired,
                occurredAt: now,
                note: recoveryState.note,
                stopReason: recoveryState.stopOutcome.legacyStopReason,
              )
              .copyWith(
                stopOutcome: recoveryState.stopOutcome.present
                    ? recoveryState.stopOutcome
                    : instance.stopOutcome,
                recoveryState: recoveryState,
                metadata: <String, Object?>{
                  ...ValueReaders.deepCopyMap(instance.metadata),
                  'last_recovery_plan': ValueReaders.deepCopyMap(recoveryPlan),
                },
              )
        : instance.copyWith(
            updatedAt: now,
            note: recoveryState.note,
            stopOutcome: recoveryState.stopOutcome.present
                ? recoveryState.stopOutcome
                : instance.stopOutcome,
            recoveryState: recoveryState,
            metadata: <String, Object?>{
              ...ValueReaders.deepCopyMap(instance.metadata),
              'last_recovery_plan': ValueReaders.deepCopyMap(recoveryPlan),
            },
          );
    await _runRegistry.save(next);
    _watchdogDispatchPort?.clearDispatchState(runId);
    return next;
  }

  Future<RunInstance?> applyContinuousTaskState(
    String runId, {
    required ContinuousTaskControlProfile controlProfile,
    required ContinuousTaskLifecycleState lifecycleState,
    LongTaskRecoveryState recoveryState = const LongTaskRecoveryState(),
    JsonMap metadata = const <String, Object?>{},
    DateTime? occurredAt,
    String note = '',
  }) async {
    final instance = await _runRegistry.findById(runId);
    if (instance == null) {
      return null;
    }
    final next = _transitionContinuousTaskInstance(
      instance,
      controlProfile: controlProfile,
      lifecycleState: lifecycleState,
      recoveryState: recoveryState,
      metadata: metadata,
      occurredAt: occurredAt ?? DateTime.now(),
      note: note,
    );
    await _runRegistry.save(next);
    _watchdogDispatchPort?.clearDispatchState(runId);
    return next;
  }

  Future<RunInstance?> _transitionRun(
    String runId,
    LongTaskRunStatus nextStatus, {
    DateTime? occurredAt,
    String note = '',
    String stopReason = '',
  }) async {
    final instance = await _runRegistry.findById(runId);
    if (instance == null) {
      return null;
    }
    final next = _runStateMachine.transition(
      instance,
      nextStatus,
      occurredAt: occurredAt,
      note: note,
      stopReason: stopReason,
    );
    await _runRegistry.save(next);
    _watchdogDispatchPort?.clearDispatchState(runId);
    return next;
  }

  LongTaskRunStatus _statusFromSignal(
    JsonMap signal, {
    required LongTaskRunStatus current,
  }) {
    final desired = LongTaskRunStatus.fromId(
      ValueReaders.stringValue(signal['run_status']),
    );
    if (_runStateMachine.canTransition(current, desired)) {
      return desired;
    }
    if (current == LongTaskRunStatus.paused &&
        desired == LongTaskRunStatus.waitingGate) {
      return LongTaskRunStatus.paused;
    }
    if (current == LongTaskRunStatus.paused &&
        desired == LongTaskRunStatus.failedManualAttention) {
      return LongTaskRunStatus.paused;
    }
    return current;
  }

  RunInstance _transitionContinuousTaskInstance(
    RunInstance instance, {
    required ContinuousTaskControlProfile controlProfile,
    required ContinuousTaskLifecycleState lifecycleState,
    required LongTaskRecoveryState recoveryState,
    required JsonMap metadata,
    required DateTime occurredAt,
    required String note,
  }) {
    final nextStatus = _continuousTaskLongTaskStatusMapperService
        .toLongTaskStatus(lifecycleState);
    final transitioned = nextStatus == instance.status
        ? instance.copyWith(updatedAt: occurredAt)
        : _runStateMachine.transition(
            instance,
            nextStatus,
            occurredAt: occurredAt,
            note: note,
            stopReason:
                lifecycleState.runPhase == ContinuousTaskRunPhases.stopped
                ? _lifecycleStopOutcomeResolverService.legacyStopReason(
                    lifecycleState,
                  )
                : '',
          );
    return _enrichContinuousTaskInstance(
      transitioned,
      controlProfile: controlProfile,
      lifecycleState: lifecycleState,
      recoveryState: recoveryState,
      metadata: metadata,
      occurredAt: occurredAt,
      note: note,
    );
  }

  RunInstance _enrichContinuousTaskInstance(
    RunInstance instance, {
    required ContinuousTaskControlProfile controlProfile,
    required ContinuousTaskLifecycleState lifecycleState,
    required LongTaskRecoveryState recoveryState,
    required JsonMap metadata,
    required DateTime occurredAt,
    String note = '',
  }) {
    final nextNote = note.trim().isNotEmpty
        ? note.trim()
        : (lifecycleState.reason.trim().isNotEmpty
              ? lifecycleState.reason.trim()
              : instance.note);
    final nextStopOutcome = _lifecycleStopOutcomeResolverService.resolve(
      lifecycleState,
      note: nextNote,
    );
    return instance.copyWith(
      updatedAt: occurredAt,
      note: nextNote,
      stopReason: lifecycleState.runPhase == ContinuousTaskRunPhases.stopped
          ? _lifecycleStopOutcomeResolverService.legacyStopReason(
              lifecycleState,
            )
          : instance.stopReason,
      stopOutcome: nextStopOutcome,
      recoveryState: recoveryState.present
          ? recoveryState
          : const LongTaskRecoveryState(),
      metadata: <String, Object?>{
        ...ValueReaders.deepCopyMap(instance.metadata),
        ...ValueReaders.deepCopyMap(metadata),
        'continuous_task_family_id': controlProfile.taskProfile.familyId,
        'continuous_task_run_kind': controlProfile.taskProfile.runKind,
        'continuous_task_profile': controlProfile.taskProfile.toJson(),
        'continuous_task_control_profile': controlProfile.toJson(),
        'continuous_task_lifecycle_state': lifecycleState.toJson(),
      },
    );
  }
}
