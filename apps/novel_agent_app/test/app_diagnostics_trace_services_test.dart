import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/diagnostics/controller_notify_trace_service.dart';
import 'package:novel_agent_app/app/diagnostics/navigation_trace_service.dart';
import 'package:novel_agent_app/app/diagnostics/project_hydration_trace_service.dart';
import 'package:novel_agent_app/app/diagnostics/ui_stall_probe.dart';
import 'package:novel_agent_app/app/routing/app_destination.dart';

void main() {
  group('App diagnostics trace services', () {
    test('navigation trace counts navigation and page lifecycle events', () {
      final trace = NavigationTraceService();

      trace.beginNavigation(
        from: AppDestination.workbench,
        to: AppDestination.longTaskStation,
        reason: 'showLongTaskStation',
      );
      trace.markDestinationVisible(AppDestination.longTaskStation);
      trace.markPageInitialized(AppDestination.longTaskStation);
      trace.markPageRefreshCompleted(AppDestination.longTaskStation);
      trace.markPageRefreshCompleted(
        AppDestination.longTaskStation,
        label: 'repeat_refresh',
      );

      final snapshot = trace.snapshot();
      expect(snapshot.navigationBeginCount, 1);
      expect(snapshot.destinationVisibleCount, 1);
      expect(snapshot.pageInitializedCount, 1);
      expect(snapshot.pageRefreshCompletedCount, 2);
      expect(snapshot.pageRefreshFailedCount, 0);
      expect(snapshot.recentEvents, isNotEmpty);
    });

    test('controller notify trace tracks per-controller counts', () {
      final trace = ControllerNotifyTraceService();

      trace.record(
        controllerName: 'AppShellController',
        reason: 'notify',
        destination: 'workbench',
        projectPath: 'D:/novels/demo',
      );
      trace.record(
        controllerName: 'AppShellController',
        reason: 'notify',
        destination: 'taskCenter',
        projectPath: 'D:/novels/demo',
      );
      trace.record(
        controllerName: 'LongTaskStationController',
        reason: 'refresh',
        destination: 'longTaskStation',
        projectPath: 'D:/novels/demo',
      );

      final snapshot = trace.snapshot();
      expect(snapshot.totalNotifyCount, 3);
      expect(snapshot.notifyCountByController['AppShellController'], 2);
      expect(snapshot.notifyCountByController['LongTaskStationController'], 1);
      expect(snapshot.recentEvents.last.sequence, 3);
    });

    test('project hydration trace records stages, writes and destination jumps', () {
      final trace = ProjectHydrationTraceService();

      trace.beginHydration(token: 7, projectPath: 'D:/novels/demo');
      trace.markStageStarted(
        token: 7,
        projectPath: 'D:/novels/demo',
        stageLabel: '运行时配置恢复',
      );
      trace.recordStageWrite(
        token: 7,
        projectPath: 'D:/novels/demo',
        stageLabel: '运行时配置恢复',
        detail: 'runtime_profile_state',
      );
      trace.markStageCompleted(
        token: 7,
        projectPath: 'D:/novels/demo',
        stageLabel: '运行时配置恢复',
        elapsed: const Duration(milliseconds: 12),
      );
      trace.recordDestinationChangeDuringHydration(
        token: 7,
        projectPath: 'D:/novels/demo',
        from: AppDestination.workbench,
        to: AppDestination.settings,
      );
      trace.completeHydration(
        token: 7,
        projectPath: 'D:/novels/demo',
        elapsed: const Duration(milliseconds: 42),
      );

      final snapshot = trace.snapshot();
      expect(snapshot.beginCount, 1);
      expect(snapshot.stageStartCount, 1);
      expect(snapshot.stageWriteCount, 1);
      expect(snapshot.stageCompleteCount, 1);
      expect(snapshot.destinationChangeCount, 1);
      expect(snapshot.completeCount, 1);
      expect(snapshot.activeSession, isNull);
      expect(snapshot.completedSessions, hasLength(1));
      expect(
        snapshot.completedSessions.single.writeCountByStage['运行时配置恢复'],
        1,
      );
    });

    test('ui stall probe captures only frames over the threshold', () {
      final probe = UiStallProbe(
        stallThreshold: const Duration(milliseconds: 16),
      );

      probe.recordFrameDuration(
        totalSpan: const Duration(milliseconds: 12),
        label: 'fast_frame',
      );
      probe.recordFrameDuration(
        totalSpan: const Duration(milliseconds: 41),
        buildSpan: const Duration(milliseconds: 17),
        rasterSpan: const Duration(milliseconds: 9),
        label: 'slow_frame',
      );

      final snapshot = probe.snapshot();
      expect(snapshot.frameCount, 2);
      expect(snapshot.stallCount, 1);
      expect(snapshot.recentStalls, hasLength(1));
      expect(snapshot.recentStalls.single.label, 'slow_frame');
      expect(snapshot.recentStalls.single.totalSpan.inMilliseconds, 41);
    });
  });
}
