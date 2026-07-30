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
    // 中文注释: 即使没开自动刷新，重新进入总站也至少刷一次——否则用户看到的是离开时的过时快照。
    // onVisibilityRequested 只在导航进入时调用一次，不会每帧触发，因此这是"重入刷新一次"而非持续轮询。
    return const LongTaskStationVisibilityRefreshDecision(
      shouldInitialize: false,
      shouldRefresh: true,
    );
  }
}
