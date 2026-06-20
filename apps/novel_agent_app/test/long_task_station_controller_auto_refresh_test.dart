import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/app/diagnostics/navigation_trace_service.dart';
import 'package:novel_agent_app/features/long_task_station/application/controllers/long_task_station_controller.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('LongTaskStationController auto refresh', () {
    test('schedules refresh only when enabled and active run exists', () async {
      final trace = NavigationTraceService();
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
        navigationTraceService: trace,
      );
      controller.attachNavigationCallbacks(
        openProjectRequested: (_) async {},
        openResourceRequested: (_, _) async {},
        showTaskCenterRequested: () async {},
        readCurrentProjectPathRequested: () => 'D:/novels/demo',
      );

      controller.setAutoRefreshEnabled(true);
      await controller.onVisibilityRequested();

      expect(controller.isAutoRefreshScheduled, isTrue);
      final snapshot = trace.snapshot();
      expect(snapshot.pageInitializedCount, 1);
      expect(snapshot.pageRefreshCompletedCount, 1);

      controller.dispose();
    });

    test('does not schedule refresh when only paused run exists', () async {
      final trace = NavigationTraceService();
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
        navigationTraceService: trace,
      );
      controller.attachNavigationCallbacks(
        openProjectRequested: (_) async {},
        openResourceRequested: (_, _) async {},
        showTaskCenterRequested: () async {},
        readCurrentProjectPathRequested: () => 'D:/novels/demo',
      );

      controller.setAutoRefreshEnabled(true);
      await controller.onVisibilityRequested();

      expect(controller.isAutoRefreshScheduled, isFalse);
      expect(trace.snapshot().pageRefreshCompletedCount, 1);

      controller.dispose();
    });

    test('cancels scheduled refresh when disabled', () async {
      final trace = NavigationTraceService();
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
        navigationTraceService: trace,
      );
      controller.attachNavigationCallbacks(
        openProjectRequested: (_) async {},
        openResourceRequested: (_, _) async {},
        showTaskCenterRequested: () async {},
        readCurrentProjectPathRequested: () => 'D:/novels/demo',
      );

      controller.setAutoRefreshEnabled(true);
      await controller.onVisibilityRequested();
      expect(controller.isAutoRefreshScheduled, isTrue);

      controller.setAutoRefreshEnabled(false);

      expect(controller.isAutoRefreshScheduled, isFalse);
      expect(trace.snapshot().pageRefreshCompletedCount, 1);

      controller.dispose();
    });

    test('approving pending research refreshes selected run detail', () async {
      final trace = NavigationTraceService();
      var approved = false;
      final run = _run(
        runId: 'run-1',
        projectPath: 'D:/novels/demo',
        baselineId: 'continuous_autonomous',
        status: LongTaskRunStatus.paused,
      );
      final supervisor = _FakeLongTaskSupervisor(
        sequences: <List<RunInstance>>[
          <RunInstance>[run],
          <RunInstance>[run],
        ],
      );
      final actionService = _FakePendingResearchActionService(
        onApprove: (requestId) {
          approved = requestId == 'research_request_1';
        },
      );
      final controller = LongTaskStationController(
        longTaskSupervisor: supervisor,
        detailService: _NoopDetailService(),
        pendingResearchActionService: actionService,
        detailLoader: (_) async =>
            _detailWithPendingResearch(includePendingResearch: !approved),
        navigationTraceService: trace,
      );
      controller.attachNavigationCallbacks(
        openProjectRequested: (_) async {},
        openResourceRequested: (_, _) async {},
        showTaskCenterRequested: () async {},
        readCurrentProjectPathRequested: () => 'D:/novels/demo',
      );

      await controller.onVisibilityRequested();
      expect(
        controller.viewData.selectedRun!.informationPermissionItems,
        isNotEmpty,
      );

      await controller.onPendingResearchApproved('research_request_1');

      expect(actionService.approvedRequestIds, <String>['research_request_1']);
      expect(
        controller.viewData.selectedRun!.informationPermissionItems,
        isEmpty,
      );
      expect(controller.viewData.statusMessage, '已确认资料请求。');
      expect(trace.snapshot().pageRefreshCompletedCount, 2);
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

class _FakePendingResearchActionService
    extends ProjectPendingResearchActionService {
  _FakePendingResearchActionService({
    void Function(String requestId)? onApprove,
  }) : _onApprove = onApprove,
       super(workspacePort: _ThrowingWorkspacePort());

  final void Function(String requestId)? _onApprove;
  final List<String> approvedRequestIds = <String>[];

  @override
  Future<JsonMap> approve(
    ProjectDescriptor project, {
    required String requestId,
    String actorId = 'pending_research_action_service',
    String note = '',
  }) async {
    approvedRequestIds.add(requestId);
    _onApprove?.call(requestId);
    return <String, Object?>{'ok': true, 'request_id': requestId};
  }
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

ProjectLongTaskStationDetail _detailWithPendingResearch({
  required bool includePendingResearch,
}) {
  return ProjectLongTaskStationDetail(
    activeTask: null,
    chain: null,
    latestCheckpointReview: null,
    latestReviewReport: null,
    latestRepairTask: null,
    narrativeSummary: ProjectLongTaskStationNarrativeSummary(
      activation: null,
      delivery: null,
      review: null,
      continuity: null,
      information: null,
      projectionItems: const <ProjectLongTaskStationItemSummary>[],
      permissionItems: const <ProjectLongTaskStationItemSummary>[],
      informationProjectionItems: const <ProjectLongTaskStationItemSummary>[],
      informationPermissionItems: includePendingResearch
          ? const <ProjectLongTaskStationItemSummary>[
              ProjectLongTaskStationItemSummary(
                id: 'research_request_1',
                title: '资料待确认',
                relativePath:
                    '.novel_agent/information/research_requests/research_request_1.json',
                status: 'awaiting_user_confirmation',
                subtitle: '等待确认',
                summary: '旧城钟楼在北境民俗中的象征意义',
              ),
            ]
          : const <ProjectLongTaskStationItemSummary>[],
    ),
    blocker: const ProjectLongTaskStationBlockerSummary(
      code: 'waiting_user',
      note: '当前运行已经停在需要确认的节点。',
      detail: '',
      controlSummary: '建议先确认资料请求。',
      blockingCheckpointTitles: <String>[],
      runRecordPath: 'tracking/long_task_runs/run-1.json',
    ),
  );
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
