import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/long_task_station/application/models/long_task_station_session.dart';
import 'package:novel_agent_app/features/long_task_station/application/services/long_task_station_visibility_refresh_service.dart';

void main() {
  group('LongTaskStationVisibilityRefreshService', () {
    test('initial visibility requests initialization', () {
      const service = LongTaskStationVisibilityRefreshService();
      final decision = service.decide(
        const LongTaskStationSession(
          isVisible: true,
          isInitialized: false,
          autoRefreshEnabled: false,
        ),
      );

      expect(decision.shouldInitialize, isTrue);
      expect(decision.shouldRefresh, isFalse);
    });

    test('revisible initialized session refreshes when auto refresh is on', () {
      const service = LongTaskStationVisibilityRefreshService();
      final decision = service.decide(
        const LongTaskStationSession(
          isVisible: true,
          isInitialized: true,
          autoRefreshEnabled: true,
        ),
      );

      expect(decision.shouldInitialize, isFalse);
      expect(decision.shouldRefresh, isTrue);
    });

    test('re-entry into initialized station refreshes once even with auto refresh off', () {
      // 中文注释: 即便没开自动刷新，重新进入总站也要至少刷一次，避免展示离开时的过时快照。
      const service = LongTaskStationVisibilityRefreshService();
      final decision = service.decide(
        const LongTaskStationSession(
          isVisible: true,
          isInitialized: true,
          autoRefreshEnabled: false,
        ),
      );

      expect(decision.shouldInitialize, isFalse);
      expect(decision.shouldRefresh, isTrue);
    });

    test('hidden session never schedules visibility work', () {
      const service = LongTaskStationVisibilityRefreshService();
      final decision = service.decide(
        const LongTaskStationSession(
          isVisible: false,
          isInitialized: true,
          autoRefreshEnabled: true,
        ),
      );

      expect(decision.shouldInitialize, isFalse);
      expect(decision.shouldRefresh, isFalse);
    });
  });
}
