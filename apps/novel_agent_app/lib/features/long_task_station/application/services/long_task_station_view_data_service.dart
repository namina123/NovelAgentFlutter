import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/activity_time_label_service.dart';
import '../../../../shared/services/runtime_label_service.dart';
import '../models/long_task_station_snapshot.dart';
import '../../presentation/models/long_task_station_view_data.dart';

class LongTaskStationViewDataService {
  const LongTaskStationViewDataService({
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    LongTaskRunStateMachine? runStateMachine,
    RuntimeLabelService? runtimeLabelService,
    ActivityTimeLabelService? activityTimeLabelService,
  }) : _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService(),
       _runStateMachine = runStateMachine ?? const LongTaskRunStateMachine(),
       _runtimeLabelService =
           runtimeLabelService ?? const RuntimeLabelService(),
       _activityTimeLabelService =
           activityTimeLabelService ?? const ActivityTimeLabelService();

  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final LongTaskRunStateMachine _runStateMachine;
  final RuntimeLabelService _runtimeLabelService;
  final ActivityTimeLabelService _activityTimeLabelService;

  LongTaskStationViewData build(LongTaskStationSnapshot snapshot) {
    final visibleRuns = snapshot.visibleRuns;
    final entries = visibleRuns
        .map(
          (run) => LongTaskRunEntryViewData(
            id: run.id,
            title: run.project.title,
            subtitle: _entrySubtitle(run),
            projectPath: run.project.rootPath,
            statusLabel: _runtimeLabelService.longTaskRunStatusLabel(
              run.status,
            ),
            taskLabel: run.activeTaskTitle.trim().isEmpty
                ? '当前无活动任务'
                : run.activeTaskTitle.trim(),
            recentActivityLabel: _recentActivityLabel(run),
            badges: _entryBadges(run),
            requiresAttention: run.requiresManualAttention,
            isActive: run.isActive,
            isSelected: run.id == snapshot.selectedRunId,
          ),
        )
        .toList(growable: false);
    final pausedCount = visibleRuns
        .where((run) => run.status == LongTaskRunStatus.paused)
        .length;
    final attentionCount = visibleRuns
        .where((run) => run.requiresManualAttention)
        .length;
    final activeCount = visibleRuns.where((run) => run.isActive).length;
    final isProjectScoped =
        snapshot.isCurrentProjectFilterActive &&
        snapshot.hasCurrentProjectScope;
    return LongTaskStationViewData(
      title: '长任务总站',
      description: isProjectScoped
          ? '统一查看当前项目的长任务运行实例，以及相关任务节点、检查点与审稿/返工结果。'
          : '统一查看跨项目的长任务运行实例，并从这里继续查看任务节点、检查点与审稿/返工结果。',
      scopeLabel: isProjectScoped ? '当前项目' : '全部项目',
      statusMessage: snapshot.statusMessage,
      supervisorStatusLabel: snapshot.isSupervisorRunning ? '监督器运行中' : '监督器未启动',
      isLoading: snapshot.isLoading,
      canFilterToCurrentProject: snapshot.hasCurrentProjectScope,
      isCurrentProjectFilterActive: isProjectScoped,
      currentProjectFilterLabel: '仅看当前项目',
      totalCount: visibleRuns.length,
      activeCount: activeCount,
      pausedCount: pausedCount,
      attentionCount: attentionCount,
      runs: entries,
      selectedRun: _detail(
        snapshot.selectedRun,
        snapshot.selectedRunDetail,
        detailStatusMessage: snapshot.detailStatusMessage,
        isDetailLoading: snapshot.isDetailLoading,
      ),
    );
  }

  LongTaskRunDetailViewData? _detail(
    RunInstance? run,
    ProjectLongTaskStationDetail? detail, {
    required String detailStatusMessage,
    required bool isDetailLoading,
  }) {
    if (run == null) {
      return null;
    }
    final baseline = _runtimeBaselineCatalogService.byId(run.runtimeBaselineId);
    final activeTask = detail?.activeTask;
    final blocker = detail?.blocker;
    final chain = detail?.chain;
    return LongTaskRunDetailViewData(
      id: run.id,
      projectTitle: run.project.title,
      projectPath: run.project.rootPath,
      runtimeBaselineTitle: baseline?.title ?? run.runtimeBaselineId,
      runtimeBaselineDescription:
          baseline?.description ?? '当前运行实例尚未匹配到已登记的运行基准。',
      modeId: run.modeId,
      workflowStrategyId: run.workflowStrategyId,
      statusLabel: _runtimeLabelService.longTaskRunStatusLabel(run.status),
      stopReasonLabel: _runtimeLabelService.blockerLabel(run.stopReason),
      storageStrategyLabel: _runtimeLabelService.storageStrategyLabel(
        run.project.storageStrategy,
      ),
      runtimeModeLabel: _runtimeLabelService.runtimeModeLabel(run.modeId),
      policyBadges: _policyBadges(baseline),
      activeTaskLabel:
          activeTask?.title ??
          (run.activeTaskTitle.trim().isEmpty
              ? '当前无活动任务'
              : run.activeTaskTitle.trim()),
      activeTaskPath: activeTask?.relativePath ?? '',
      activeTaskStatusLabel: activeTask == null
          ? '未定位'
          : _runtimeLabelService.taskStatusLabel(activeTask.status),
      activeTaskSummary: activeTask?.summary.trim().isNotEmpty == true
          ? activeTask!.summary
          : (activeTask?.subtitle ?? ''),
      note: run.note.trim().isEmpty ? '暂无备注。' : run.note.trim(),
      createdAtLabel: _formatTime(run.createdAt),
      updatedAtLabel: _formatTime(run.updatedAt),
      lastHeartbeatAtLabel: _formatOptionalTime(run.lastHeartbeatAt),
      startedAtLabel: _formatOptionalTime(run.startedAt),
      stoppedAtLabel: _formatOptionalTime(run.stoppedAt),
      detailStatusMessage: detailStatusMessage,
      isDetailLoading: isDetailLoading,
      blockerLabel: blocker == null
          ? '暂无阻塞'
          : _runtimeLabelService.blockerLabel(blocker.code),
      blockerNote: blocker?.note ?? '当前没有明显阻塞。',
      blockerDetail: blocker?.detail ?? '',
      blockerActionHint: blocker?.controlSummary ?? '',
      taskChainTitle: chain?.title ?? '当前任务链',
      taskChainSubtitle: chain?.subtitle ?? '尚未读到可用链路。',
      taskChainItems: chain == null
          ? const <LongTaskRunChainItemViewData>[]
          : chain.items.map(_chainItem).toList(growable: false),
      latestCheckpointReview: _relatedItem(
        detail?.latestCheckpointReview,
        actionLabel: '查看检查点',
      ),
      latestReviewReport: _relatedItem(
        detail?.latestReviewReport,
        actionLabel: '查看审稿结果',
      ),
      latestRepairTask: _relatedItem(
        detail?.latestRepairTask,
        actionLabel: '打开返工任务',
      ),
      narrativeActivation: _relatedItem(
        detail?.narrativeSummary?.activation,
        actionLabel: '查看激活报告',
      ),
      narrativeDelivery: _relatedItem(
        detail?.narrativeSummary?.delivery,
        actionLabel: '打开交付章节',
      ),
      narrativeReview: _relatedItem(
        detail?.narrativeSummary?.review,
        actionLabel: '查看审稿结果',
      ),
      narrativeContinuity: _relatedItem(
        detail?.narrativeSummary?.continuity,
        actionLabel: '查看变更摘要',
      ),
      narrativeProjectionItems: detail?.narrativeSummary?.projectionItems
              .map(
                (item) => _relatedItem(item, actionLabel: '打开投影')!,
              )
              .toList(growable: false) ??
          const <LongTaskRunRelatedItemViewData>[],
      narrativePermissionItems: detail?.narrativeSummary?.permissionItems
              .map(
                (item) => _relatedItem(item, actionLabel: '打开确认记录')!,
              )
              .toList(growable: false) ??
          const <LongTaskRunRelatedItemViewData>[],
      requiresManualAttention: run.requiresManualAttention,
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

  LongTaskRunChainItemViewData _chainItem(
    ProjectLongTaskStationChainItem item,
  ) {
    final prefix = item.isActive
        ? '当前任务'
        : (item.isNextRunnable ? '下一步' : item.taskType);
    final statusLabel = _runtimeLabelService.taskStatusLabel(item.status);
    final blockingHint = item.isBlockingCheckpoint ? ' · 检查点阻塞' : '';
    return LongTaskRunChainItemViewData(
      id: item.id,
      title: item.title,
      subtitle:
          '$prefix · ${item.sortOrder.toString().padLeft(3, '0')} · $statusLabel$blockingHint',
      relativePath: item.relativePath,
      statusLabel: statusLabel,
      isActive: item.isActive,
      isNextRunnable: item.isNextRunnable,
      isBlockingCheckpoint: item.isBlockingCheckpoint,
    );
  }

  LongTaskRunRelatedItemViewData? _relatedItem(
    ProjectLongTaskStationItemSummary? item, {
    required String actionLabel,
  }) {
    if (item == null) {
      return null;
    }
    final summary = item.summary.trim().isEmpty ? item.subtitle : item.summary;
    return LongTaskRunRelatedItemViewData(
      title: item.title,
      subtitle: item.subtitle,
      summary: summary,
      relativePath: item.relativePath,
      actionLabel: actionLabel,
    );
  }

  String _entrySubtitle(RunInstance run) {
    final baseline = _runtimeBaselineCatalogService.byId(run.runtimeBaselineId);
    final baselineTitle = baseline?.title ?? run.runtimeBaselineId;
    return '$baselineTitle · ${_runtimeLabelService.runtimeModeLabel(run.modeId)}';
  }

  List<String> _entryBadges(RunInstance run) {
    final badges = <String>[
      _runtimeLabelService.longTaskRunStatusLabel(run.status),
    ];
    if (run.requiresManualAttention) {
      badges.add('需处理');
    }
    if (run.stopReason.trim().isNotEmpty) {
      badges.add(_runtimeLabelService.blockerLabel(run.stopReason));
    }
    return badges;
  }

  String _recentActivityLabel(RunInstance run) {
    final activityAt = run.lastHeartbeatAt ?? run.startedAt ?? run.updatedAt;
    return _activityTimeLabelService.labelForRecentActivity(activityAt);
  }

  List<String> _policyBadges(RuntimeBaseline? baseline) {
    if (baseline == null) {
      return const <String>[];
    }
    final badges = <String>[];
    if (baseline.unattended) {
      badges.add('托管运行');
    }
    if (baseline.autoAdvanceChapters) {
      badges.add('自动推进');
    }
    if (baseline.keepAliveAcrossProjectSwitch) {
      badges.add('跨项目保活');
    }
    return badges;
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
