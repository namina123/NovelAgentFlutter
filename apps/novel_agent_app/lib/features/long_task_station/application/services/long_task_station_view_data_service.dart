import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/long_task_station_snapshot.dart';
import '../../presentation/models/long_task_station_view_data.dart';

class LongTaskStationViewDataService {
  const LongTaskStationViewDataService({
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    LongTaskRunStateMachine? runStateMachine,
  }) : _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService(),
       _runStateMachine = runStateMachine ?? const LongTaskRunStateMachine();

  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final LongTaskRunStateMachine _runStateMachine;

  LongTaskStationViewData build(LongTaskStationSnapshot snapshot) {
    final entries = snapshot.runs
        .map(
          (run) => LongTaskRunEntryViewData(
            id: run.id,
            title: run.project.title,
            subtitle: _entrySubtitle(run),
            statusLabel: _statusLabel(run.status),
            taskLabel: run.activeTaskTitle.trim().isEmpty
                ? '当前无活动任务'
                : run.activeTaskTitle.trim(),
            isSelected: run.id == snapshot.selectedRunId,
          ),
        )
        .toList(growable: false);
    final pausedCount = snapshot.runs
        .where((run) => run.status == LongTaskRunStatus.paused)
        .length;
    final attentionCount = snapshot.runs
        .where((run) => run.requiresManualAttention)
        .length;
    final activeCount = snapshot.runs.where((run) => run.isActive).length;
    return LongTaskStationViewData(
      title: '长任务总站',
      description: '统一查看跨项目的长任务运行实例，并从这里发起暂停、恢复或停止。',
      statusMessage: snapshot.statusMessage,
      supervisorStatusLabel: snapshot.isSupervisorRunning ? '监督器运行中' : '监督器未启动',
      isLoading: snapshot.isLoading,
      totalCount: snapshot.runs.length,
      activeCount: activeCount,
      pausedCount: pausedCount,
      attentionCount: attentionCount,
      runs: entries,
      selectedRun: _detail(snapshot.selectedRun),
    );
  }

  LongTaskRunDetailViewData? _detail(RunInstance? run) {
    if (run == null) {
      return null;
    }
    final baseline = _runtimeBaselineCatalogService.byId(run.runtimeBaselineId);
    return LongTaskRunDetailViewData(
      id: run.id,
      projectTitle: run.project.title,
      projectPath: run.project.rootPath,
      runtimeBaselineTitle: baseline?.title ?? run.runtimeBaselineId,
      runtimeBaselineDescription:
          baseline?.description ?? '当前运行实例尚未匹配到已登记的运行基准。',
      modeId: run.modeId,
      workflowStrategyId: run.workflowStrategyId,
      statusLabel: _statusLabel(run.status),
      storageStrategyLabel: _storageStrategyLabel(run.project.storageStrategy),
      activeTaskLabel: run.activeTaskTitle.trim().isEmpty
          ? '当前无活动任务'
          : run.activeTaskTitle.trim(),
      note: run.note.trim().isEmpty ? '暂无备注。' : run.note.trim(),
      createdAtLabel: _formatTime(run.createdAt),
      updatedAtLabel: _formatTime(run.updatedAt),
      lastHeartbeatAtLabel: _formatOptionalTime(run.lastHeartbeatAt),
      startedAtLabel: _formatOptionalTime(run.startedAt),
      stoppedAtLabel: _formatOptionalTime(run.stoppedAt),
      canPause: _runStateMachine.canTransition(
        run.status,
        LongTaskRunStatus.paused,
      ),
      canResume: _runStateMachine.canTransition(
        run.status,
        LongTaskRunStatus.running,
      ),
      canStop: _runStateMachine.canTransition(
        run.status,
        LongTaskRunStatus.stopped,
      ),
    );
  }

  String _entrySubtitle(RunInstance run) {
    final baseline = _runtimeBaselineCatalogService.byId(run.runtimeBaselineId);
    final baselineTitle = baseline?.title ?? run.runtimeBaselineId;
    return '${_statusLabel(run.status)} · $baselineTitle';
  }

  String _statusLabel(LongTaskRunStatus status) {
    switch (status) {
      case LongTaskRunStatus.draftingGuidance:
        return '引导中';
      case LongTaskRunStatus.readyToStart:
        return '待启动';
      case LongTaskRunStatus.running:
        return '运行中';
      case LongTaskRunStatus.waitingGate:
        return '等待关口';
      case LongTaskRunStatus.paused:
        return '已暂停';
      case LongTaskRunStatus.recovering:
        return '恢复中';
      case LongTaskRunStatus.failedManualAttention:
        return '等待人工处理';
      case LongTaskRunStatus.stopped:
        return '已停止';
    }
  }

  String _storageStrategyLabel(ProjectStorageStrategy strategy) {
    switch (strategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return 'Markdown 项目';
      case ProjectStorageStrategy.sqliteProjectStore:
        return 'SQLite 项目';
    }
  }

  String _formatOptionalTime(DateTime? value) {
    if (value == null) {
      return '未记录';
    }
    return _formatTime(value);
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }
}
