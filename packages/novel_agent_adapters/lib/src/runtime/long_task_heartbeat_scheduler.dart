import 'dart:async';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'long_task_heartbeat_event.dart';

typedef LongTaskHeartbeatEventHandler =
    Future<void> Function(LongTaskHeartbeatEvent event);

class LongTaskHeartbeatScheduler {
  LongTaskHeartbeatScheduler({
    required LongTaskRunRegistry runRegistry,
    required RuntimeBaselineCatalogService runtimeBaselineCatalogService,
    LongTaskHeartbeatPolicy? heartbeatPolicy,
  }) : _runRegistry = runRegistry,
       _runtimeBaselineCatalogService = runtimeBaselineCatalogService,
       _heartbeatPolicy =
           heartbeatPolicy ?? const DefaultLongTaskHeartbeatPolicy();

  final LongTaskRunRegistry _runRegistry;
  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final LongTaskHeartbeatPolicy _heartbeatPolicy;

  final Map<String, DateTime> _lastDispatchedAtByRunId = <String, DateTime>{};

  Timer? _timer;
  LongTaskHeartbeatEventHandler? _handler;
  Duration _pollInterval = const Duration(seconds: 10);

  bool get isRunning => _timer != null;

  void start({
    Duration pollInterval = const Duration(seconds: 10),
    LongTaskHeartbeatEventHandler? onEvent,
  }) {
    // 中文注释: scheduler 只负责定期扫描和派发心跳事件，不承担运行实例持久化或 workflow 执行。
    _handler = onEvent;
    _pollInterval = pollInterval;
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) {
      unawaited(pollOnce(onEvent: _handler));
    });
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<List<LongTaskHeartbeatEvent>> pollOnce({
    DateTime? now,
    LongTaskHeartbeatEventHandler? onEvent,
  }) async {
    final currentTime = now ?? DateTime.now();
    final activeRuns = await _runRegistry.listActive();
    final events = <LongTaskHeartbeatEvent>[];
    for (final run in activeRuns) {
      final baseline = _runtimeBaselineCatalogService.byId(
        run.runtimeBaselineId,
      );
      if (baseline == null) {
        continue;
      }
      final stale = _heartbeatPolicy.isStale(run, baseline, now: currentTime);
      final due =
          !stale &&
          _heartbeatPolicy.isHeartbeatDue(run, baseline, now: currentTime);
      if (!stale && !due) {
        continue;
      }
      final event = LongTaskHeartbeatEvent(
        runInstance: run,
        occurredAt: currentTime,
        reason: stale ? 'stale_run' : 'heartbeat_due',
        stale: stale,
        nextHeartbeatAt: _heartbeatPolicy.nextHeartbeatAt(run, baseline),
      );
      if (!_shouldDispatch(event, baseline)) {
        continue;
      }
      events.add(event);
      _lastDispatchedAtByRunId[run.id] = currentTime;
      final handler = onEvent ?? _handler;
      if (handler != null) {
        await handler(event);
      }
    }
    return events;
  }

  void clearDispatchState(String runId) {
    _lastDispatchedAtByRunId.remove(runId.trim());
  }

  int reconcileDispatchState(Iterable<String> activeRunIds) {
    final activeIds = activeRunIds
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();
    final orphanIds = _lastDispatchedAtByRunId.keys
        .where((runId) => !activeIds.contains(runId))
        .toList(growable: false);
    for (final runId in orphanIds) {
      _lastDispatchedAtByRunId.remove(runId);
    }
    return orphanIds.length;
  }

  bool _shouldDispatch(LongTaskHeartbeatEvent event, RuntimeBaseline baseline) {
    // 中文注释: 即使宿主暂时还没处理事件，scheduler 也要避免在每次轮询里疯狂重复抛同一条心跳告警。
    final lastDispatchedAt = _lastDispatchedAtByRunId[event.runInstance.id];
    if (lastDispatchedAt == null) {
      return true;
    }
    final interval = _heartbeatPolicy.heartbeatIntervalFor(
      event.runInstance,
      baseline,
    );
    final cooldown = interval == Duration.zero ? _pollInterval : interval;
    return event.occurredAt.difference(lastDispatchedAt) >= cooldown;
  }
}
