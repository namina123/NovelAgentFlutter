import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/long_task_station_snapshot.dart';

class LongTaskStationRuntimeRefreshDecision {
  const LongTaskStationRuntimeRefreshDecision({
    required this.shouldRefresh,
    required this.interval,
  });

  final bool shouldRefresh;
  final Duration interval;
}

class LongTaskStationRuntimeRefreshPolicyService {
  const LongTaskStationRuntimeRefreshPolicyService({
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    DefaultLongTaskHeartbeatPolicy? heartbeatPolicy,
    Duration fallbackInterval = const Duration(seconds: 45),
  }) : _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService(),
       _heartbeatPolicy =
           heartbeatPolicy ?? const DefaultLongTaskHeartbeatPolicy(),
       _fallbackInterval = fallbackInterval;

  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final DefaultLongTaskHeartbeatPolicy _heartbeatPolicy;
  final Duration _fallbackInterval;

  LongTaskStationRuntimeRefreshDecision decide(
    LongTaskStationSnapshot snapshot,
  ) {
    final activeRuns = snapshot.visibleRuns.where((run) => run.status.isActive);
    Duration? shortestInterval;
    for (final run in activeRuns) {
      final baseline = _runtimeBaselineCatalogService.byId(
        run.runtimeBaselineId,
      );
      final interval = baseline == null
          ? _fallbackInterval
          : _heartbeatPolicy.heartbeatIntervalFor(run, baseline);
      if (interval == Duration.zero) {
        continue;
      }
      if (shortestInterval == null || interval < shortestInterval) {
        shortestInterval = interval;
      }
    }
    if (shortestInterval == null) {
      return const LongTaskStationRuntimeRefreshDecision(
        shouldRefresh: false,
        interval: Duration.zero,
      );
    }
    return LongTaskStationRuntimeRefreshDecision(
      shouldRefresh: true,
      interval: shortestInterval,
    );
  }
}
