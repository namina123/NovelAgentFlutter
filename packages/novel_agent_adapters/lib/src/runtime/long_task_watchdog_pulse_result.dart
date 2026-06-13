import 'long_task_heartbeat_event.dart';

class LongTaskWatchdogPulseResult {
  const LongTaskWatchdogPulseResult({
    this.heartbeatEvents = const <LongTaskHeartbeatEvent>[],
    this.orphanDispatchStateReconciledCount = 0,
  });

  final List<LongTaskHeartbeatEvent> heartbeatEvents;
  final int orphanDispatchStateReconciledCount;
}
