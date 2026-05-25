import 'long_task_heartbeat_policy.dart';
import 'long_task_run_status.dart';
import 'run_instance.dart';
import 'runtime_baseline.dart';

class DefaultLongTaskHeartbeatPolicy implements LongTaskHeartbeatPolicy {
  const DefaultLongTaskHeartbeatPolicy();

  @override
  Duration heartbeatIntervalFor(
    RunInstance instance,
    RuntimeBaseline baseline,
  ) {
    // 中文注释: 心跳节奏只由运行状态和基线决定，先不引入自动恢复或宿主级动态调参。
    switch (instance.status) {
      case LongTaskRunStatus.running:
        return baseline.defaultHeartbeatInterval;
      case LongTaskRunStatus.waitingGate:
        return baseline.waitingGateHeartbeatInterval;
      case LongTaskRunStatus.recovering:
        return baseline.recoveringHeartbeatInterval;
      case LongTaskRunStatus.draftingGuidance:
      case LongTaskRunStatus.readyToStart:
      case LongTaskRunStatus.paused:
      case LongTaskRunStatus.failedManualAttention:
      case LongTaskRunStatus.stopped:
        return Duration.zero;
    }
  }

  @override
  Duration staleAfterFor(RunInstance instance, RuntimeBaseline baseline) {
    return baseline.staleAfter;
  }

  @override
  DateTime? nextHeartbeatAt(RunInstance instance, RuntimeBaseline baseline) {
    final interval = heartbeatIntervalFor(instance, baseline);
    if (interval == Duration.zero) {
      return null;
    }
    final anchor =
        instance.lastHeartbeatAt ?? instance.startedAt ?? instance.updatedAt;
    return anchor.add(interval);
  }

  @override
  bool isHeartbeatDue(
    RunInstance instance,
    RuntimeBaseline baseline, {
    DateTime? now,
  }) {
    final dueAt = nextHeartbeatAt(instance, baseline);
    if (dueAt == null) {
      return false;
    }
    final currentTime = now ?? DateTime.now();
    return !currentTime.isBefore(dueAt);
  }

  @override
  bool isStale(
    RunInstance instance,
    RuntimeBaseline baseline, {
    DateTime? now,
  }) {
    if (!instance.status.isActive) {
      return false;
    }
    final anchor =
        instance.lastHeartbeatAt ?? instance.startedAt ?? instance.updatedAt;
    final currentTime = now ?? DateTime.now();
    return currentTime.difference(anchor) > staleAfterFor(instance, baseline);
  }
}
