import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/long_task_station/application/controllers/long_task_station_controller.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('LongTaskStationController auto refresh', () {
    test('schedules refresh only when enabled and active run exists', () async {
      final supervisor = _FakeLongTaskSupervisor(
        sequences: <List<RunInstance>>[
          <RunInstance>[
            _run(
              runId: 'run-1',
              projectPath: 'D:/novels/demo',
              baselineId: 'chapter_collaboration_autorun',
              status: LongTaskRunStatus.running,
            ),
          ],
        ],
      );
      final controller = LongTaskStationController(
        longTaskSupervisor: supervisor,
        detailService: _NoopDetailService(),
        detailLoader: _loadEmptyDetail,
      );
      controller.attachNavigationCallbacks(
        openProjectRequested: (_) async {},
        openResourceRequested: (_, _) async {},
        readCurrentProjectPathRequested: () => 'D:/novels/demo',
      );

      controller.setAutoRefreshEnabled(true);
      await controller.initialize();

      expect(controller.isAutoRefreshScheduled, isTrue);

      controller.dispose();
    });

    test('does not schedule refresh when only paused run exists', () async {
      final supervisor = _FakeLongTaskSupervisor(
        sequences: <List<RunInstance>>[
          <RunInstance>[
            _run(
              runId: 'run-1',
              projectPath: 'D:/novels/demo',
              baselineId: 'continuous_autonomous',
              status: LongTaskRunStatus.paused,
            ),
          ],
        ],
      );
      final controller = LongTaskStationController(
        longTaskSupervisor: supervisor,
        detailService: _NoopDetailService(),
        detailLoader: _loadEmptyDetail,
      );
      controller.attachNavigationCallbacks(
        openProjectRequested: (_) async {},
        openResourceRequested: (_, _) async {},
        readCurrentProjectPathRequested: () => 'D:/novels/demo',
      );

      controller.setAutoRefreshEnabled(true);
      await controller.initialize();

      expect(controller.isAutoRefreshScheduled, isFalse);

      controller.dispose();
    });

    test('cancels scheduled refresh when disabled', () async {
      final supervisor = _FakeLongTaskSupervisor(
        sequences: <List<RunInstance>>[
          <RunInstance>[
            _run(
              runId: 'run-1',
              projectPath: 'D:/novels/demo',
              baselineId: 'continuous_autonomous',
              status: LongTaskRunStatus.running,
            ),
          ],
        ],
      );
      final controller = LongTaskStationController(
        longTaskSupervisor: supervisor,
        detailService: _NoopDetailService(),
        detailLoader: _loadEmptyDetail,
      );
      controller.attachNavigationCallbacks(
        openProjectRequested: (_) async {},
        openResourceRequested: (_, _) async {},
        readCurrentProjectPathRequested: () => 'D:/novels/demo',
      );

      controller.setAutoRefreshEnabled(true);
      await controller.initialize();
      expect(controller.isAutoRefreshScheduled, isTrue);

      controller.setAutoRefreshEnabled(false);

      expect(controller.isAutoRefreshScheduled, isFalse);

      controller.dispose();
    });
  });
}

class _FakeLongTaskSupervisor extends LongTaskSupervisor {
  _FakeLongTaskSupervisor({required List<List<RunInstance>> sequences})
    : _sequences = sequences,
      super(
        runRegistry: _NoopRunRegistry(),
        heartbeatScheduler: _NoopHeartbeatScheduler(),
      );

  final List<List<RunInstance>> _sequences;
  int _index = 0;

  @override
  Future<List<RunInstance>> listAllRuns() async {
    if (_sequences.isEmpty) {
      return const <RunInstance>[];
    }
    final current = _sequences[_index.clamp(0, _sequences.length - 1)];
    if (_index < _sequences.length - 1) {
      _index += 1;
    }
    return current;
  }
}

class _NoopRunRegistry implements LongTaskRunRegistry {
  @override
  Future<void> delete(String runId) async {}

  @override
  Future<RunInstance?> findById(String runId) async => null;

  @override
  Future<List<RunInstance>> listActive() async => const <RunInstance>[];

  @override
  Future<List<RunInstance>> listAll() async => const <RunInstance>[];

  @override
  Future<List<RunInstance>> listByProject(String projectKey) async =>
      const <RunInstance>[];

  @override
  Future<void> save(RunInstance instance) async {}
}

class _NoopHeartbeatScheduler implements LongTaskHeartbeatScheduler {
  @override
  bool get isRunning => false;

  @override
  void clearDispatchState(String runId) {}

  @override
  Future<List<LongTaskHeartbeatEvent>> pollOnce({
    DateTime? now,
    LongTaskHeartbeatEventHandler? onEvent,
  }) async => const <LongTaskHeartbeatEvent>[];

  @override
  void start({
    Duration pollInterval = const Duration(seconds: 10),
    LongTaskHeartbeatEventHandler? onEvent,
  }) {}

  @override
  Future<void> stop() async {}
}

class _NoopDetailService extends ProjectLongTaskStationDetailService {
  _NoopDetailService()
    : super(
        taskRepository: ProjectTaskRepository(
          workspacePort: _ThrowingWorkspacePort(),
        ),
        reviewReportService: ProjectReviewReportService(
          workspacePort: _ThrowingWorkspacePort(),
          taskRepository: ProjectTaskRepository(
            workspacePort: _ThrowingWorkspacePort(),
          ),
        ),
      );
}

class _ThrowingWorkspacePort implements ProjectWorkspacePort {
  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

Future<ProjectLongTaskStationDetail> _loadEmptyDetail(RunInstance run) async =>
    const ProjectLongTaskStationDetail(
      activeTask: null,
      chain: null,
      latestCheckpointReview: null,
      latestReviewReport: null,
      latestRepairTask: null,
      narrativeSummary: null,
      blocker: ProjectLongTaskStationBlockerSummary(
        code: '',
        note: '',
        detail: '',
        controlSummary: '',
        blockingCheckpointTitles: <String>[],
        runRecordPath: '',
      ),
    );

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
