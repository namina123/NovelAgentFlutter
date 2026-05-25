import 'package:flutter/foundation.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/contracts/long_task_station_action_handler.dart';
import '../../presentation/models/long_task_station_view_data.dart';
import '../models/long_task_station_snapshot.dart';
import '../services/long_task_station_view_data_service.dart';

class LongTaskStationController extends ChangeNotifier
    implements LongTaskStationActionHandler {
  LongTaskStationController({
    required LongTaskSupervisor longTaskSupervisor,
    LongTaskStationViewDataService? viewDataService,
  }) : _longTaskSupervisor = longTaskSupervisor,
       _viewDataService =
           viewDataService ?? const LongTaskStationViewDataService(),
       _snapshot = LongTaskStationSnapshot.initial(),
       _viewData = LongTaskStationViewData.initial();

  final LongTaskSupervisor _longTaskSupervisor;
  final LongTaskStationViewDataService _viewDataService;

  LongTaskStationSnapshot _snapshot;
  LongTaskStationViewData _viewData;
  bool _initialized = false;
  bool _disposed = false;

  LongTaskStationViewData get viewData => _viewData;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    // 中文注释: 子域控制器独立初始化自己的全局运行列表，避免把 feature 首屏刷新逻辑塞回壳层。
    if (_initialized) {
      return;
    }
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      isSupervisorRunning: _longTaskSupervisor.isRunning,
      statusMessage: '正在加载全局长任务运行实例...',
    );
    _rebuildView();
    try {
      final runs = await _longTaskSupervisor.listAllRuns();
      final selectedRunId = _resolveSelectedRunId(
        runs: runs,
        previousSelectedRunId: _snapshot.selectedRunId,
      );
      _snapshot = _snapshot.copyWith(
        runs: runs,
        selectedRunId: selectedRunId,
        statusMessage: runs.isEmpty
            ? '当前没有全局长任务运行实例。'
            : '已加载 ${runs.length} 个全局长任务运行实例。',
        isLoading: false,
        isSupervisorRunning: _longTaskSupervisor.isRunning,
      );
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        isSupervisorRunning: _longTaskSupervisor.isRunning,
        statusMessage: '加载全局长任务运行实例失败：$error',
      );
      _rebuildView();
    }
  }

  @override
  void onLongTaskStationRefreshRequested() {
    refresh();
  }

  @override
  void onLongTaskStationRunSelected(String runId) {
    _snapshot = _snapshot.copyWith(selectedRunId: runId.trim());
    _rebuildView();
  }

  @override
  void onLongTaskStationPauseRequested(String runId) {
    _applyTransition(
      runId,
      actionLabel: '暂停',
      transition: () => _longTaskSupervisor.pauseRun(
        runId,
        note: 'paused_from_long_task_station',
      ),
    );
  }

  @override
  void onLongTaskStationResumeRequested(String runId) {
    _applyTransition(
      runId,
      actionLabel: '恢复',
      transition: () => _longTaskSupervisor.resumeRun(
        runId,
        note: 'resumed_from_long_task_station',
      ),
    );
  }

  @override
  void onLongTaskStationStopRequested(String runId) {
    _applyTransition(
      runId,
      actionLabel: '停止',
      transition: () => _longTaskSupervisor.stopRun(
        runId,
        note: 'stopped_from_long_task_station',
        stopReason: 'user_requested_from_station',
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _applyTransition(
    String runId, {
    required String actionLabel,
    required Future<RunInstance?> Function() transition,
  }) async {
    final targetRunId = runId.trim();
    if (targetRunId.isEmpty) {
      return;
    }
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      statusMessage: '正在$actionLabel运行实例...',
    );
    _rebuildView();
    try {
      final updated = await transition();
      if (updated == null) {
        _snapshot = _snapshot.copyWith(
          isLoading: false,
          statusMessage: '未找到目标运行实例，可能已被移除。',
        );
        _rebuildView();
        return;
      }
      await refresh();
      _snapshot = _snapshot.copyWith(
        selectedRunId: updated.id,
        statusMessage: '已$actionLabel运行实例：${updated.project.title}',
      );
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        statusMessage: '$actionLabel运行实例失败：$error',
      );
      _rebuildView();
    }
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

  void _rebuildView() {
    _viewData = _viewDataService.build(_snapshot);
    if (!_disposed) {
      notifyListeners();
    }
  }
}
