import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/long_task_station/application/controllers/long_task_station_controller.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('LongTaskStationController queue control', () {
    test('resume invokes workflow callback with run, not registry-only flip',
        () async {
      final run = _run(
        runId: 'run-1',
        projectPath: 'D:/novels/demo',
        relativePath: 'tracking/long_task_runs/run-1.json',
        status: LongTaskRunStatus.paused,
      );
      final supervisor = _FakeLongTaskSupervisor(
        sequences: <List<RunInstance>>[
          <RunInstance>[run],
          <RunInstance>[
            run.copyWith(status: LongTaskRunStatus.running),
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
        showTaskCenterRequested: () async {},
        readCurrentProjectPathRequested: () => 'D:/novels/demo',
      );

      RunInstance? resumedRun;
      var resumeCalls = 0;
      controller.attachQueueControlCallbacks(
        pauseRunRequested: (_) async => const <String, Object?>{'ok': true},
        resumeRunRequested: (target) async {
          resumeCalls += 1;
          resumedRun = target;
          return <String, Object?>{
            'ok': true,
            'message': '队列已恢复推进',
          };
        },
        stopRunRequested: (_) async => const <String, Object?>{'ok': true},
      );

      await controller.onVisibilityRequested();
      controller.onLongTaskStationResumeRequested('run-1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(resumeCalls, 1);
      expect(resumedRun?.id, 'run-1');
      expect(
        ValueReaders.stringValue(resumedRun?.metadata['record_relative_path']),
        'tracking/long_task_runs/run-1.json',
      );
      expect(controller.viewData.statusMessage, contains('队列已恢复推进'));
      controller.dispose();
    });

    test('resume without queue callback surfaces honest failure', () async {
      final run = _run(
        runId: 'run-1',
        projectPath: 'D:/novels/demo',
        relativePath: 'tracking/long_task_runs/run-1.json',
        status: LongTaskRunStatus.paused,
      );
      final controller = LongTaskStationController(
        longTaskSupervisor: _FakeLongTaskSupervisor(
          sequences: <List<RunInstance>>[
            <RunInstance>[run],
          ],
        ),
        detailService: _NoopDetailService(),
        detailLoader: _loadEmptyDetail,
      );
      controller.attachNavigationCallbacks(
        openProjectRequested: (_) async {},
        openResourceRequested: (_, _) async {},
        showTaskCenterRequested: () async {},
        readCurrentProjectPathRequested: () => 'D:/novels/demo',
      );

      await controller.onVisibilityRequested();
      controller.onLongTaskStationResumeRequested('run-1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.viewData.statusMessage, contains('尚未接入'));
      controller.dispose();
    });

    test('resume failure message is shown and does not claim success',
        () async {
      final run = _run(
        runId: 'run-1',
        projectPath: 'D:/novels/demo',
        relativePath: 'tracking/long_task_runs/run-1.json',
        status: LongTaskRunStatus.paused,
      );
      final controller = LongTaskStationController(
        longTaskSupervisor: _FakeLongTaskSupervisor(
          sequences: <List<RunInstance>>[
            <RunInstance>[run],
            <RunInstance>[run],
          ],
        ),
        detailService: _NoopDetailService(),
        detailLoader: _loadEmptyDetail,
      );
      controller.attachNavigationCallbacks(
        openProjectRequested: (_) async {},
        openResourceRequested: (_, _) async {},
        showTaskCenterRequested: () async {},
        readCurrentProjectPathRequested: () => 'D:/novels/demo',
      );
      controller.attachQueueControlCallbacks(
        pauseRunRequested: (_) async => const <String, Object?>{'ok': true},
        resumeRunRequested: (_) async => <String, Object?>{
          'ok': false,
          'error': 'already_running',
          'message': '该项目已有长任务正在运行，请等待当前批次结束或先停止。',
        },
        stopRunRequested: (_) async => const <String, Object?>{'ok': true},
      );

      await controller.onVisibilityRequested();
      controller.onLongTaskStationResumeRequested('run-1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.viewData.statusMessage, contains('已有长任务正在运行'));
      controller.dispose();
    });
  });
}

class _FakeLongTaskSupervisor extends LongTaskSupervisor {
  _FakeLongTaskSupervisor({required List<List<RunInstance>> sequences})
    : _sequences = sequences,
      super(
        runRegistry: _NoopRunRegistry(),
        watchdogDispatchPort: _NoopWatchdogDispatchPort(),
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

class _NoopWatchdogDispatchPort implements LongTaskWatchdogDispatchPort {
  @override
  bool get isWatchdogRunning => false;

  @override
  void clearDispatchState(String runId) {}
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
  required String relativePath,
  required LongTaskRunStatus status,
}) {
  final baseline = const RuntimeBaselineCatalogService()
      .byId('continuous_autonomous')!;
  final created = const RunInstanceFactoryService().createLongTaskInstance(
    runId: runId,
    project: ProjectDescriptor(
      id: runId,
      name: 'demo',
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
  return created.copyWith(
    metadata: <String, Object?>{
      ...created.metadata,
      'record_relative_path': relativePath,
    },
  );
}
