import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../app/diagnostics/navigation_trace_service.dart';
import '../../../../app/routing/app_destination.dart';
import '../../../workbench/presentation/contracts/pending_research_action_handler.dart';
import '../../presentation/contracts/long_task_station_action_handler.dart';
import '../../presentation/models/long_task_station_view_data.dart';
import '../models/long_task_station_session.dart';
import '../models/long_task_station_snapshot.dart';
import '../services/long_task_station_runtime_refresh_policy_service.dart';
import '../services/long_task_station_visibility_refresh_service.dart';
import '../services/long_task_station_view_data_service.dart';

typedef LongTaskStationDetailLoader =
    Future<ProjectLongTaskStationDetail> Function(RunInstance run);

class LongTaskStationController extends ChangeNotifier
    implements LongTaskStationActionHandler, PendingResearchActionHandler {
  LongTaskStationController({
    required LongTaskSupervisor longTaskSupervisor,
    required ProjectLongTaskStationDetailService detailService,
    ProjectPendingResearchActionService? pendingResearchActionService,
    LongTaskStationViewDataService? viewDataService,
    LongTaskStationRuntimeRefreshPolicyService? runtimeRefreshPolicyService,
    LongTaskStationVisibilityRefreshService? visibilityRefreshService,
    LongTaskStationDetailLoader? detailLoader,
    NavigationTraceService? navigationTraceService,
  }) : _longTaskSupervisor = longTaskSupervisor,
       _detailService = detailService,
       _pendingResearchActionService = pendingResearchActionService,
       _viewDataService =
           viewDataService ?? const LongTaskStationViewDataService(),
       _runtimeRefreshPolicyService =
           runtimeRefreshPolicyService ??
           const LongTaskStationRuntimeRefreshPolicyService(),
       _visibilityRefreshService =
           visibilityRefreshService ??
           const LongTaskStationVisibilityRefreshService(),
       _detailLoader = detailLoader,
       _navigationTraceService = navigationTraceService,
       _snapshot = LongTaskStationSnapshot.initial(),
       _viewData = LongTaskStationViewData.initial(),
       _session = LongTaskStationSession.initial();

  final LongTaskSupervisor _longTaskSupervisor;
  final ProjectLongTaskStationDetailService _detailService;
  final ProjectPendingResearchActionService? _pendingResearchActionService;
  final LongTaskStationViewDataService _viewDataService;
  final LongTaskStationRuntimeRefreshPolicyService _runtimeRefreshPolicyService;
  final LongTaskStationVisibilityRefreshService _visibilityRefreshService;
  final LongTaskStationDetailLoader? _detailLoader;
  final NavigationTraceService? _navigationTraceService;
  Future<void> Function(RunInstance run)? _openProjectRequested;
  Future<void> Function(RunInstance run, String relativePath)?
  _openResourceRequested;
  Future<void> Function()? _showTaskCenterRequested;
  String Function()? _readCurrentProjectPathRequested;
  Future<void> Function()? _refreshCompletedCallback;
  // 中文注释: 队列控制由壳层注入，总站不直接依赖 ProjectWorkflowRuntimeService，避免子域反向依赖巨石。
  Future<JsonMap> Function(RunInstance run)? _pauseRunRequested;
  Future<JsonMap> Function(RunInstance run)? _resumeRunRequested;
  Future<JsonMap> Function(RunInstance run)? _stopRunRequested;

  LongTaskStationSnapshot _snapshot;
  LongTaskStationViewData _viewData;
  LongTaskStationSession _session;
  bool _initialized = false;
  bool _disposed = false;
  bool _autoRefreshEnabled = false;
  Timer? _autoRefreshTimer;
  bool _autoRefreshInFlight = false;

  LongTaskStationViewData get viewData => _viewData;
  bool get isInitialized => _initialized;

  bool get isVisible => _session.isVisible;

  Future<ProjectLongTaskStationDetail> loadDetailForRun(RunInstance run) {
    return (_detailLoader?.call(run) ?? _detailService.loadForRun(run));
  }

  @visibleForTesting
  bool get isAutoRefreshScheduled => _autoRefreshTimer != null;

  void attachNavigationCallbacks({
    required Future<void> Function(RunInstance run) openProjectRequested,
    required Future<void> Function(RunInstance run, String relativePath)
    openResourceRequested,
    required Future<void> Function() showTaskCenterRequested,
    required String Function() readCurrentProjectPathRequested,
  }) {
    // 中文注释: 总站跳转只保存壳层回调，不直接依赖工作台或页面控制器实现。
    _openProjectRequested = openProjectRequested;
    _openResourceRequested = openResourceRequested;
    _showTaskCenterRequested = showTaskCenterRequested;
    _readCurrentProjectPathRequested = readCurrentProjectPathRequested;
  }

  void attachQueueControlCallbacks({
    required Future<JsonMap> Function(RunInstance run) pauseRunRequested,
    required Future<JsonMap> Function(RunInstance run) resumeRunRequested,
    required Future<JsonMap> Function(RunInstance run) stopRunRequested,
  }) {
    // 中文注释: 暂停/恢复/停止必须落到 workflow 的 run record + 队列入口（与任务中心同语义），
    // 不能只改全局 registry 状态，否则“恢复”只是假绿。
    _pauseRunRequested = pauseRunRequested;
    _resumeRunRequested = resumeRunRequested;
    _stopRunRequested = stopRunRequested;
  }

  void attachRefreshCompletedCallback(Future<void> Function() callback) {
    // 中文注释: 总站刷新完成后允许壳层补刷其他投影视图，但仍保持总站控制器只暴露窄回调。
    _refreshCompletedCallback = callback;
  }

  Future<void> initialize() async {
    // 中文注释: 子域控制器独立初始化自己的全局运行列表，避免把 feature 首屏刷新逻辑塞回壳层。
    if (_initialized) {
      return;
    }
    _navigationTraceService?.markPageInitialized(
      AppDestination.longTaskStation,
      label: 'long_task_station_initialize',
    );
    _initialized = true;
    _session = _session.copyWith(isInitialized: true, isVisible: true);
    await refresh();
  }

  Future<void> onVisibilityRequested() async {
    // 中文注释: 可见性进入只交给控制器判断“首次初始化”还是“恢复刷新”，页面和壳层不再直接碰初始化细节。
    _session = _session.copyWith(
      isVisible: true,
      isInitialized: _initialized,
      autoRefreshEnabled: _autoRefreshEnabled,
    );
    final decision = _visibilityRefreshService.decide(_session);
    if (decision.shouldInitialize) {
      await initialize();
      return;
    }
    if (decision.shouldRefresh) {
      await refresh();
    }
  }

  void setAutoRefreshEnabled(bool enabled) {
    if (_autoRefreshEnabled == enabled) {
      return;
    }
    _autoRefreshEnabled = enabled;
    _session = _session.copyWith(autoRefreshEnabled: enabled);
    if (!_autoRefreshEnabled) {
      _cancelAutoRefreshTimer();
      return;
    }
    if (_initialized) {
      _scheduleAutoRefreshIfNeeded();
    }
  }

  Future<void> refresh() async {
    _cancelAutoRefreshTimer();
    _session = _session.copyWith(
      isVisible: true,
      isInitialized: _initialized,
      autoRefreshEnabled: _autoRefreshEnabled,
    );
    final currentProjectPath = _currentProjectPath();
    final filterToCurrentProject =
        _snapshot.isCurrentProjectFilterActive && currentProjectPath.isNotEmpty;
    _snapshot = _snapshot.copyWith(
      currentProjectPath: currentProjectPath,
      isCurrentProjectFilterActive: filterToCurrentProject,
      isLoading: true,
      isSupervisorRunning: _longTaskSupervisor.isRunning,
      statusMessage: '正在加载全局长任务运行实例...',
    );
    _rebuildView();
    try {
      final runs = await _longTaskSupervisor.listAllRuns();
      final filteredRuns = _filterVisibleRuns(
        runs: runs,
        currentProjectPath: currentProjectPath,
        isCurrentProjectFilterActive: filterToCurrentProject,
      );
      final selectedRunId = _resolveSelectedRunId(
        runs: filteredRuns,
        previousSelectedRunId: _snapshot.selectedRunId,
      );
      _snapshot = _snapshot.copyWith(
        runs: runs,
        selectedRunId: selectedRunId,
        clearSelectedRunDetail: selectedRunId.trim().isEmpty,
        detailStatusMessage: selectedRunId.trim().isEmpty
            ? '当前没有可查看的运行实例。'
            : '正在读取运行详情...',
        statusMessage: _statusMessage(
          runs: runs,
          visibleRuns: filteredRuns,
          filterToCurrentProject: filterToCurrentProject,
        ),
        isLoading: false,
        isDetailLoading: selectedRunId.trim().isNotEmpty,
        isSupervisorRunning: _longTaskSupervisor.isRunning,
      );
      _rebuildView();
      await _loadSelectedRunDetail();
      await _notifyRefreshCompleted();
      _scheduleAutoRefreshIfNeeded();
      _session = _session.copyWith(isInitialized: true);
      _navigationTraceService?.markPageRefreshCompleted(
        AppDestination.longTaskStation,
        label: 'long_task_station_refresh',
      );
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        isDetailLoading: false,
        isSupervisorRunning: _longTaskSupervisor.isRunning,
        statusMessage: '加载全局长任务运行实例失败：$error',
      );
      _session = _session.copyWith(isInitialized: true);
      _rebuildView();
      _navigationTraceService?.markPageRefreshFailed(
        AppDestination.longTaskStation,
        error: error,
        label: 'long_task_station_refresh',
      );
    }
  }

  @override
  void onLongTaskStationRefreshRequested() {
    refresh();
  }

  @override
  void onLongTaskStationRunSelected(String runId) {
    final selectedRunId = runId.trim();
    _snapshot = _snapshot.copyWith(
      selectedRunId: selectedRunId,
      clearSelectedRunDetail: true,
      detailStatusMessage: selectedRunId.isEmpty
          ? '请选择一个运行实例查看详情。'
          : '正在读取运行详情...',
      isDetailLoading: selectedRunId.isNotEmpty,
    );
    _rebuildView();
    _loadSelectedRunDetail();
  }

  @override
  void onLongTaskStationPauseRequested(String runId) {
    unawaited(
      _applyQueueControl(
        runId,
        actionLabel: '暂停',
        operation: _pauseRunRequested,
        successMessage: (run) => '长任务运行已暂停：${run.project.title}',
      ),
    );
  }

  @override
  void onLongTaskStationResumeRequested(String runId) {
    unawaited(
      _applyQueueControl(
        runId,
        actionLabel: '恢复',
        operation: _resumeRunRequested,
        successMessage: (run) =>
            '长任务运行已恢复推进：${run.project.title}（按批次推进，可随时再恢复下一批）',
      ),
    );
  }

  @override
  void onLongTaskStationStopRequested(String runId) {
    unawaited(
      _applyQueueControl(
        runId,
        actionLabel: '停止',
        operation: _stopRunRequested,
        successMessage: (run) => '长任务运行已停止：${run.project.title}',
      ),
    );
  }

  @override
  void onLongTaskStationOpenProjectRequested(String runId) {
    _runProjectNavigation(
      runId,
      navigate: (run, detail, snapshot) async {
        final callback = _openProjectRequested;
        if (callback != null) {
          await callback(run);
        }
      },
    );
  }

  @override
  void onLongTaskStationResourceRequested(String runId, String relativePath) {
    _runProjectNavigation(
      runId,
      navigate: (run, detail, _) async {
        final callback = _openResourceRequested;
        if (callback == null) {
          return;
        }
        final resolvedPath = relativePath.trim().isNotEmpty
            ? relativePath.trim()
            : detail?.activeTask?.relativePath ?? '';
        await callback(run, resolvedPath);
      },
    );
  }

  @override
  void onLongTaskStationCurrentProjectFilterToggled(bool selected) {
    final nextFilter = selected && _snapshot.hasCurrentProjectScope;
    final visibleRuns = _filterVisibleRuns(
      runs: _snapshot.runs,
      currentProjectPath: _snapshot.currentProjectPath,
      isCurrentProjectFilterActive: nextFilter,
    );
    final nextSelectedRunId = _resolveSelectedRunId(
      runs: visibleRuns,
      previousSelectedRunId: _snapshot.selectedRunId,
    );
    final selectionChanged = nextSelectedRunId != _snapshot.selectedRunId;
    _snapshot = _snapshot.copyWith(
      isCurrentProjectFilterActive: nextFilter,
      selectedRunId: nextSelectedRunId,
      clearSelectedRunDetail: selectionChanged,
      detailStatusMessage: nextSelectedRunId.trim().isEmpty
          ? '当前没有可查看的运行实例。'
          : (selectionChanged ? '正在读取运行详情...' : _snapshot.detailStatusMessage),
      statusMessage: _statusMessage(
        runs: _snapshot.runs,
        visibleRuns: visibleRuns,
        filterToCurrentProject: nextFilter,
      ),
      isDetailLoading: nextSelectedRunId.trim().isNotEmpty && selectionChanged,
    );
    _rebuildView();
    if (selectionChanged && nextSelectedRunId.trim().isNotEmpty) {
      _loadSelectedRunDetail();
    }
  }

  @override
  void onLongTaskStationTaskCenterRequested() {
    final callback = _showTaskCenterRequested;
    if (callback == null) {
      return;
    }
    unawaited(callback());
  }

  @override
  Future<void> onPendingResearchApproved(String requestId) async {
    await _applyPendingResearchAction(
      requestId,
      successMessage: '已确认资料请求。',
      action: (service, project, cleanRequestId) => service.approve(
        project,
        requestId: cleanRequestId,
        actorId: 'long_task_station_gui',
        note: '在长任务总站中确认继续研究',
      ),
    );
  }

  @override
  Future<void> onPendingResearchRejected(String requestId) async {
    await _applyPendingResearchAction(
      requestId,
      successMessage: '已拒绝资料请求。',
      action: (service, project, cleanRequestId) => service.reject(
        project,
        requestId: cleanRequestId,
        actorId: 'long_task_station_gui',
        note: '在长任务总站中拒绝继续研究',
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelAutoRefreshTimer();
    super.dispose();
  }

  Future<void> _applyQueueControl(
    String runId, {
    required String actionLabel,
    required Future<JsonMap> Function(RunInstance run)? operation,
    required String Function(RunInstance run) successMessage,
  }) async {
    final targetRunId = runId.trim();
    if (targetRunId.isEmpty) {
      return;
    }
    final run = _findRun(targetRunId);
    if (run == null) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        statusMessage: '未找到目标运行实例，可能已被移除。',
      );
      _rebuildView();
      return;
    }
    final callback = operation;
    if (callback == null) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        statusMessage: '长任务队列控制尚未接入，无法$actionLabel。',
      );
      _rebuildView();
      return;
    }
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      statusMessage: '正在$actionLabel运行实例...',
    );
    _rebuildView();
    try {
      final result = await callback(run);
      final ok = ValueReaders.boolValue(result['ok']);
      if (!ok) {
        final error = ValueReaders.stringValue(
          result['message'],
          ValueReaders.stringValue(
            result['error'],
            '$actionLabel失败，请稍后重试或从任务中心操作。',
          ),
        );
        await refresh();
        _snapshot = _snapshot.copyWith(
          selectedRunId: run.id,
          statusMessage: error,
        );
        _rebuildView();
        return;
      }
      await refresh();
      final message = ValueReaders.stringValue(
        result['message'],
        successMessage(run),
      );
      _snapshot = _snapshot.copyWith(
        selectedRunId: run.id,
        statusMessage: message,
      );
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        isDetailLoading: false,
        statusMessage: '$actionLabel运行实例失败：$error',
      );
      _rebuildView();
    }
  }

  RunInstance? _findRun(String runId) {
    final targetRunId = runId.trim();
    if (targetRunId.isEmpty) {
      return null;
    }
    for (final item in _snapshot.runs) {
      if (item.id == targetRunId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _applyPendingResearchAction(
    String requestId, {
    required String successMessage,
    required Future<JsonMap> Function(
      ProjectPendingResearchActionService service,
      ProjectDescriptor project,
      String requestId,
    )
    action,
  }) async {
    final cleanRequestId = requestId.trim();
    final service = _pendingResearchActionService;
    final run = _snapshot.selectedRun;
    if (cleanRequestId.isEmpty || service == null || run == null) {
      return;
    }
    final project = ProjectDescriptor(
      id: run.project.projectId,
      name: run.project.title,
      rootPath: run.project.rootPath,
      projectType: run.project.projectTypeId,
      storageStrategy: run.project.storageStrategy,
    );
    _snapshot = _snapshot.copyWith(
      isDetailLoading: true,
      detailStatusMessage: '正在更新资料请求...',
      statusMessage: '正在更新资料请求...',
    );
    _rebuildView();
    try {
      final result = await action(service, project, cleanRequestId);
      if (!ValueReaders.boolValue(result['ok'])) {
        final error = ValueReaders.stringValue(result['error'], '资料请求更新失败。');
        _snapshot = _snapshot.copyWith(
          isDetailLoading: false,
          detailStatusMessage: error,
          statusMessage: error,
        );
        _rebuildView();
        return;
      }
      await refresh();
      _snapshot = _snapshot.copyWith(
        statusMessage: successMessage,
        detailStatusMessage: successMessage,
      );
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isDetailLoading: false,
        detailStatusMessage: '资料请求更新失败：$error',
        statusMessage: '资料请求更新失败：$error',
      );
      _rebuildView();
    }
  }

  Future<void> _loadSelectedRunDetail() async {
    final run = _snapshot.selectedRun;
    if (run == null) {
      _snapshot = _snapshot.copyWith(
        clearSelectedRunDetail: true,
        isDetailLoading: false,
        detailStatusMessage: '请选择一个运行实例查看详情。',
      );
      _rebuildView();
      return;
    }
    final targetRunId = run.id;
    try {
      final detail = await loadDetailForRun(run);
      if (_snapshot.selectedRunId != targetRunId) {
        return;
      }
      _snapshot = _snapshot.copyWith(
        selectedRunDetail: detail,
        detailStatusMessage: '已加载项目链路详情。',
        isDetailLoading: false,
      );
      _rebuildView();
    } catch (error) {
      if (_snapshot.selectedRunId != targetRunId) {
        return;
      }
      _snapshot = _snapshot.copyWith(
        clearSelectedRunDetail: true,
        detailStatusMessage: '读取运行详情失败：$error',
        isDetailLoading: false,
      );
      _rebuildView();
    }
  }

  void _runProjectNavigation(
    String runId, {
    required Future<void> Function(
      RunInstance run,
      ProjectLongTaskStationDetail? detail,
      LongTaskStationSnapshot snapshot,
    )
    navigate,
  }) {
    final targetRunId = runId.trim();
    if (targetRunId.isEmpty) {
      return;
    }
    RunInstance? run;
    for (final item in _snapshot.runs) {
      if (item.id == targetRunId) {
        run = item;
        break;
      }
    }
    if (run == null) {
      return;
    }
    navigate(run, _snapshot.selectedRunDetail, _snapshot);
  }

  String _resolveSelectedRunId({
    required List<RunInstance> runs,
    required String previousSelectedRunId,
  }) {
    final cleanPreviousSelectedRunId = previousSelectedRunId.trim();
    if (cleanPreviousSelectedRunId.isNotEmpty) {
      for (final run in runs) {
        if (run.id == cleanPreviousSelectedRunId) {
          return cleanPreviousSelectedRunId;
        }
      }
    }
    return runs.isEmpty ? '' : runs.first.id;
  }

  String _currentProjectPath() {
    final callback = _readCurrentProjectPathRequested;
    if (callback == null) {
      return '';
    }
    return callback().trim();
  }

  List<RunInstance> _filterVisibleRuns({
    required List<RunInstance> runs,
    required String currentProjectPath,
    required bool isCurrentProjectFilterActive,
  }) {
    if (!isCurrentProjectFilterActive || currentProjectPath.isEmpty) {
      return runs;
    }
    return runs
        .where((run) => run.project.rootPath.trim() == currentProjectPath)
        .toList(growable: false);
  }

  String _statusMessage({
    required List<RunInstance> runs,
    required List<RunInstance> visibleRuns,
    required bool filterToCurrentProject,
  }) {
    if (runs.isEmpty) {
      return '当前没有全局长任务运行实例。';
    }
    if (!filterToCurrentProject) {
      return '已加载 ${runs.length} 个全局长任务运行实例。';
    }
    if (visibleRuns.isEmpty) {
      return '当前项目暂无运行实例，已保留全局长任务总站视图。';
    }
    return '当前项目共有 ${visibleRuns.length} 个运行实例，已收口到总站查看。';
  }

  void _rebuildView() {
    _viewData = _viewDataService.build(_snapshot);
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _scheduleAutoRefreshIfNeeded() {
    if (_disposed || !_autoRefreshEnabled) {
      return;
    }
    _cancelAutoRefreshTimer();
    final decision = _runtimeRefreshPolicyService.decide(_snapshot);
    if (!decision.shouldRefresh) {
      return;
    }
    _autoRefreshTimer = Timer(
      decision.interval,
      () => unawaited(_runAutoRefreshTick()),
    );
  }

  Future<void> _runAutoRefreshTick() async {
    if (_disposed || _autoRefreshInFlight) {
      return;
    }
    _autoRefreshTimer = null;
    _autoRefreshInFlight = true;
    try {
      await refresh();
    } finally {
      _autoRefreshInFlight = false;
    }
  }

  void _cancelAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _notifyRefreshCompleted() async {
    final callback = _refreshCompletedCallback;
    if (callback == null) {
      return;
    }
    try {
      await callback();
    } catch (error, stackTrace) {
      debugPrint(
        'LongTaskStationController refresh callback failed: '
        '$error\n$stackTrace',
      );
    }
  }
}
