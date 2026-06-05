import 'package:novel_agent_core/novel_agent_core.dart';

import 'long_task_heartbeat_event.dart';
import 'long_task_heartbeat_scheduler.dart';

class LongTaskSupervisor {
  LongTaskSupervisor({
    required LongTaskRunRegistry runRegistry,
    required LongTaskHeartbeatScheduler heartbeatScheduler,
    LongTaskRunStateMachine? runStateMachine,
    LongTaskWritingExecutionSignalService? writingExecutionSignalService,
  }) : _runRegistry = runRegistry,
       _heartbeatScheduler = heartbeatScheduler,
       _runStateMachine = runStateMachine ?? const LongTaskRunStateMachine(),
       _writingExecutionSignalService =
           writingExecutionSignalService ??
           const LongTaskWritingExecutionSignalService();

  final LongTaskRunRegistry _runRegistry;
  final LongTaskHeartbeatScheduler _heartbeatScheduler;
  final LongTaskRunStateMachine _runStateMachine;
  final LongTaskWritingExecutionSignalService _writingExecutionSignalService;

  bool get isRunning => _heartbeatScheduler.isRunning;

  Future<void> trackRun(RunInstance instance) {
    // 中文注释: supervisor 只做“监督入口”的编排，不改变 registry 的持久化语义，也不直接推进 workflow。
    _heartbeatScheduler.clearDispatchState(instance.id);
    return _runRegistry.save(instance);
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
    _heartbeatScheduler.clearDispatchState(runId);
    await _runRegistry.delete(runId);
  }

  Future<RunInstance?> markHeartbeat(
    String runId, {
    DateTime? occurredAt,
    String note = '',
  }) async {
    final instance = await _runRegistry.findById(runId);
    if (instance == null) {
      return null;
    }
    final now = occurredAt ?? DateTime.now();
    final next = instance.copyWith(
      lastHeartbeatAt: now,
      updatedAt: now,
      note: note.trim().isEmpty ? instance.note : note.trim(),
    );
    await _runRegistry.save(next);
    _heartbeatScheduler.clearDispatchState(runId);
    return next;
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
    final nextStatus = _statusFromSignal(
      signal,
      current: instance.status,
    );
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
        : _runStateMachine.transition(
            instance,
            nextStatus,
            occurredAt: now,
            note: ValueReaders.stringValue(signal['note']),
            stopReason: ValueReaders.stringValue(signal['legacy_stop_reason']),
          ).copyWith(
            metadata: <String, Object?>{
              ...ValueReaders.deepCopyMap(instance.metadata),
              'writing_execution_signal': signal,
            },
          );
    await _runRegistry.save(next);
    _heartbeatScheduler.clearDispatchState(runId);
    return next;
  }

  void start({
    Duration pollInterval = const Duration(seconds: 10),
    LongTaskHeartbeatEventHandler? onHeartbeatEvent,
  }) {
    _heartbeatScheduler.start(
      pollInterval: pollInterval,
      onEvent: onHeartbeatEvent,
    );
  }

  Future<void> stop() {
    return _heartbeatScheduler.stop();
  }

  Future<List<LongTaskHeartbeatEvent>> pulseOnce({
    DateTime? now,
    LongTaskHeartbeatEventHandler? onHeartbeatEvent,
  }) {
    return _heartbeatScheduler.pollOnce(now: now, onEvent: onHeartbeatEvent);
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
    _heartbeatScheduler.clearDispatchState(runId);
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
}
