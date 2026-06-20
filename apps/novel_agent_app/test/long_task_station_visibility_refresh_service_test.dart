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

    test('revisible initialized session refreshes only when auto refresh is on', () {
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
