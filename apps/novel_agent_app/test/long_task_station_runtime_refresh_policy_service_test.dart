import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/long_task_station/application/models/long_task_station_snapshot.dart';
import 'package:novel_agent_app/features/long_task_station/application/services/long_task_station_runtime_refresh_policy_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('LongTaskStationRuntimeRefreshPolicyService', () {
    test(
      'returns shortest active heartbeat interval for visible active runs',
      () {
        final service = LongTaskStationRuntimeRefreshPolicyService();
        final snapshot = LongTaskStationSnapshot.initial().copyWith(
          runs: <RunInstance>[
            _run(
              runId: 'run-running',
              projectPath: 'D:/novels/demo',
              baselineId: 'continuous_autonomous',
              status: LongTaskRunStatus.running,
            ),
            _run(
              runId: 'run-recovering',
              projectPath: 'D:/novels/demo',
              baselineId: 'chapter_collaboration_autorun',
              status: LongTaskRunStatus.recovering,
            ),
          ],
          currentProjectPath: 'D:/novels/demo',
          isCurrentProjectFilterActive: true,
        );

        final decision = service.decide(snapshot);

        expect(decision.shouldRefresh, isTrue);
        expect(decision.interval, const Duration(seconds: 15));
      },
    );

    test('does not refresh when visible runs are non-active', () {
      final service = LongTaskStationRuntimeRefreshPolicyService();
      final snapshot = LongTaskStationSnapshot.initial().copyWith(
        runs: <RunInstance>[
          _run(
            runId: 'run-paused',
            projectPath: 'D:/novels/demo',
            baselineId: 'continuous_autonomous',
            status: LongTaskRunStatus.paused,
          ),
        ],
      );

      final decision = service.decide(snapshot);

      expect(decision.shouldRefresh, isFalse);
      expect(decision.interval, Duration.zero);
    });

    test('respects current project filter when deciding refresh', () {
      final service = LongTaskStationRuntimeRefreshPolicyService();
      final snapshot = LongTaskStationSnapshot.initial().copyWith(
        runs: <RunInstance>[
          _run(
            runId: 'run-other-project',
            projectPath: 'D:/novels/other',
            baselineId: 'continuous_autonomous',
            status: LongTaskRunStatus.running,
          ),
        ],
        currentProjectPath: 'D:/novels/current',
        isCurrentProjectFilterActive: true,
      );

      final decision = service.decide(snapshot);

      expect(decision.shouldRefresh, isFalse);
      expect(decision.interval, Duration.zero);
    });
  });
}

RunInstance _run({
  required String runId,
  required String projectPath,
  required String baselineId,
  required LongTaskRunStatus status,
}) {
  final baseline = const RuntimeBaselineCatalogService().byId(baselineId)!;
  return const RunInstanceFactoryService().createLongTaskInstance(
    runId: runId,
    project: ProjectDescriptor(
      id: runId,
      name: runId,
      rootPath: projectPath,
      projectType: 'long_novel',
      storageStrategy: ProjectStorageStrategy.markdownProjectStore,
    ),
    runtimeBaseline: baseline,
    modeId: 'seed_autopilot_novel',
    workflowStrategyId: 'resumable_long_task',
    initialStatus: status,
    now: DateTime.parse('2026-05-31T10:00:00.000Z'),
  );
}
