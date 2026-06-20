import '../models/long_task_station_session.dart';

class LongTaskStationVisibilityRefreshDecision {
  const LongTaskStationVisibilityRefreshDecision({
    required this.shouldInitialize,
    required this.shouldRefresh,
  });

  final bool shouldInitialize;
  final bool shouldRefresh;
}

class LongTaskStationVisibilityRefreshService {
  const LongTaskStationVisibilityRefreshService();

  LongTaskStationVisibilityRefreshDecision decide(
    LongTaskStationSession session,
  ) {
    if (!session.isVisible) {
      return const LongTaskStationVisibilityRefreshDecision(
        shouldInitialize: false,
        shouldRefresh: false,
      );
    }
    if (!session.isInitialized) {
      return const LongTaskStationVisibilityRefreshDecision(
        shouldInitialize: true,
        shouldRefresh: false,
      );
    }
    if (session.autoRefreshEnabled) {
      return const LongTaskStationVisibilityRefreshDecision(
        shouldInitialize: false,
        shouldRefresh: true,
      );
    }
    return const LongTaskStationVisibilityRefreshDecision(
      shouldInitialize: false,
      shouldRefresh: false,
    );
  }
}
