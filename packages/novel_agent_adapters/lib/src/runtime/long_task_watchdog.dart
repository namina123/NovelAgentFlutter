import 'package:novel_agent_core/novel_agent_core.dart';

import 'long_task_heartbeat_scheduler.dart';
import 'long_task_watchdog_dispatch_port.dart';
import 'long_task_watchdog_pulse_result.dart';

class LongTaskWatchdog implements LongTaskWatchdogDispatchPort {
  LongTaskWatchdog({
    required LongTaskRunRegistry runRegistry,
    required LongTaskHeartbeatScheduler heartbeatScheduler,
  }) : _runRegistry = runRegistry,
       _heartbeatScheduler = heartbeatScheduler;

  final LongTaskRunRegistry _runRegistry;
  final LongTaskHeartbeatScheduler _heartbeatScheduler;

  @override
  bool get isWatchdogRunning => _heartbeatScheduler.isRunning;

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
    clearDispatchState(runId);
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

  Future<LongTaskWatchdogPulseResult> pulseOnce({
    DateTime? now,
    LongTaskHeartbeatEventHandler? onHeartbeatEvent,
  }) async {
    final activeRuns = await _runRegistry.listActive();
    final reconciledCount = _heartbeatScheduler.reconcileDispatchState(
      activeRuns.map((run) => run.id),
    );
    final heartbeatEvents = await _heartbeatScheduler.pollOnce(
      now: now,
      onEvent: onHeartbeatEvent,
    );
    return LongTaskWatchdogPulseResult(
      heartbeatEvents: heartbeatEvents,
      orphanDispatchStateReconciledCount: reconciledCount,
    );
  }

  @override
  void clearDispatchState(String runId) {
    _heartbeatScheduler.clearDispatchState(runId);
  }
}
