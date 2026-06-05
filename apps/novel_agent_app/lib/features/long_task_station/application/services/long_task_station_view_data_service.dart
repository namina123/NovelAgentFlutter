import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/activity_time_label_service.dart';
import '../../../../shared/services/runtime_exposure_policy_service.dart';
import '../../../../shared/services/runtime_label_service.dart';
import '../models/long_task_station_snapshot.dart';
import '../../presentation/models/long_task_station_view_data.dart';

class LongTaskStationViewDataService {
  const LongTaskStationViewDataService({
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    LongTaskRunStateMachine? runStateMachine,
    RuntimeLabelService? runtimeLabelService,
    ActivityTimeLabelService? activityTimeLabelService,
    RuntimeExposurePolicyService? runtimeExposurePolicyService,
    RuntimeExposureTier exposureTier = RuntimeExposureTier.standard,
  }) : _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService(),
       _runStateMachine = runStateMachine ?? const LongTaskRunStateMachine(),
       _runtimeLabelService =
           runtimeLabelService ?? const RuntimeLabelService(),
       _activityTimeLabelService =
           activityTimeLabelService ?? const ActivityTimeLabelService(),
       _runtimeExposurePolicyService =
           runtimeExposurePolicyService ?? const RuntimeExposurePolicyService(),
       _exposureTier = exposureTier;

  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final LongTaskRunStateMachine _runStateMachine;
  final RuntimeLabelService _runtimeLabelService;
  final ActivityTimeLabelService _activityTimeLabelService;
  final RuntimeExposurePolicyService _runtimeExposurePolicyService;
  final RuntimeExposureTier _exposureTier;

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
    final exposesInternal = _runtimeExposurePolicyService
        .exposesInternalRuntimeTerms(_exposureTier);
    final pendingUserAction = _pendingUserAction(detail, blocker: blocker);
    final preferredRecentOutput = _preferredRecentOutput(detail);
    final canResume = _runStateMachine.canTransition(
      run.status,
      LongTaskRunStatus.running,
    );
    return LongTaskRunDetailViewData(
      id: run.id,
      projectTitle: run.project.title,
      projectPath: run.project.rootPath,
      runtimeBaselineTitle: exposesInternal
          ? (baseline?.title ?? run.runtimeBaselineId)
          : '',
      runtimeBaselineDescription:
          baseline?.description ?? '当前运行实例尚未匹配到已登记的运行基准。',
      modeId: exposesInternal ? run.modeId : '',
      workflowStrategyId: exposesInternal ? run.workflowStrategyId : '',
      statusLabel: _runtimeLabelService.longTaskRunStatusLabel(run.status),
      stopReasonLabel: _runtimeLabelService.blockerLabel(run.stopReason),
      storageStrategyLabel: exposesInternal
          ? _runtimeLabelService.storageStrategyLabel(
              run.project.storageStrategy,
            )
          : '',
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
        titleOverride: _narrativeItemLabel('activation'),
      ),
      narrativeDelivery: _relatedItem(
        detail?.narrativeSummary?.delivery,
        actionLabel: '打开交付章节',
        titleOverride: _narrativeItemLabel('delivery'),
      ),
      narrativeReview: _relatedItem(
        detail?.narrativeSummary?.review,
        actionLabel: '查看审稿结果',
        titleOverride: _narrativeItemLabel('review'),
      ),
      narrativeContinuity: _relatedItem(
        detail?.narrativeSummary?.continuity,
        actionLabel: '查看变更摘要',
        titleOverride: _narrativeItemLabel('continuity'),
      ),
      informationSummary: _relatedItem(
        detail?.narrativeSummary?.information,
        actionLabel: '查看信息摘要',
        titleOverride: _narrativeItemLabel('information'),
      ),
      narrativeProjectionItems:
          detail?.narrativeSummary?.projectionItems
              .map((item) => _relatedItem(item, actionLabel: '打开投影')!)
              .toList(growable: false) ??
          const <LongTaskRunRelatedItemViewData>[],
      narrativePermissionItems:
          detail?.narrativeSummary?.permissionItems
              .map((item) => _relatedItem(item, actionLabel: '打开确认记录')!)
              .toList(growable: false) ??
          const <LongTaskRunRelatedItemViewData>[],
      informationProjectionItems:
          detail?.narrativeSummary?.informationProjectionItems
              .map((item) => _relatedItem(item, actionLabel: '打开投影')!)
              .toList(growable: false) ??
          const <LongTaskRunRelatedItemViewData>[],
      informationPermissionItems:
          detail?.narrativeSummary?.informationPermissionItems
              .map((item) => _relatedItem(item, actionLabel: '打开确认记录')!)
              .toList(growable: false) ??
          const <LongTaskRunRelatedItemViewData>[],
      requiresManualAttention: run.requiresManualAttention,
      canPause: _runStateMachine.canTransition(
        run.status,
        LongTaskRunStatus.paused,
      ),
      canResume: canResume,
      canStop: _runStateMachine.canTransition(
        run.status,
        LongTaskRunStatus.stopped,
      ),
      overviewBlocks: _overviewBlocks(
        run,
        detail,
        activeTask: activeTask,
        blocker: blocker,
        chain: chain,
      ),
      primaryMetadata: _primaryMetadata(
        run,
        activeTask: activeTask,
        baseline: baseline,
      ),
      diagnosticMetadata: _diagnosticMetadata(run, baseline: baseline),
      resumeActionLabel: _resumeActionLabel(
        run: run,
        blocker: blocker,
        canResume: canResume,
      ),
      pendingUserActionLabel: _pendingUserActionLabel(blocker),
      pendingUserAction: pendingUserAction,
      preferredRecentOutput: preferredRecentOutput,
      narrativeSectionTitle: _narrativeSectionTitle(),
      narrativeActivationLabel: _narrativeItemLabel('activation'),
      narrativeDeliveryLabel: _narrativeItemLabel('delivery'),
      narrativeReviewLabel: _narrativeItemLabel('review'),
      narrativeContinuityLabel: _narrativeItemLabel('continuity'),
      informationSummaryLabel: _narrativeItemLabel('information'),
      narrativeProjectionSectionTitle: _narrativeProjectionSectionTitle(),
      informationProjectionSectionTitle: _informationProjectionSectionTitle(),
      narrativePermissionSectionTitle: _narrativePermissionSectionTitle(),
      informationPermissionSectionTitle: _informationPermissionSectionTitle(),
      relatedResultsSectionTitle: '最近关联结果',
    );
  }

  List<LongTaskRunOverviewBlockViewData> _overviewBlocks(
    RunInstance run,
    ProjectLongTaskStationDetail? detail, {
    required ProjectLongTaskStationItemSummary? activeTask,
    required ProjectLongTaskStationBlockerSummary? blocker,
    required ProjectLongTaskStationChainSummary? chain,
  }) {
    return <LongTaskRunOverviewBlockViewData>[
      _progressOverviewBlock(run, activeTask: activeTask, chain: chain),
      _currentActionOverviewBlock(
        run,
        activeTask: activeTask,
        blocker: blocker,
      ),
      _pendingActionOverviewBlock(detail, blocker: blocker),
      _recentOutputOverviewBlock(detail),
    ];
  }

  LongTaskRunOverviewBlockViewData _progressOverviewBlock(
    RunInstance run, {
    required ProjectLongTaskStationItemSummary? activeTask,
    required ProjectLongTaskStationChainSummary? chain,
  }) {
    final entries = <LongTaskRunMetaItemViewData>[
      LongTaskRunMetaItemViewData(
        label: '当前状态',
        value: _runtimeLabelService.longTaskRunStatusLabel(run.status),
      ),
      LongTaskRunMetaItemViewData(
        label: '当前任务',
        value:
            activeTask?.title ??
            (run.activeTaskTitle.trim().isEmpty
                ? '当前无活动任务'
                : run.activeTaskTitle.trim()),
      ),
      LongTaskRunMetaItemViewData(
        label: '任务状态',
        value: activeTask == null
            ? '未定位'
            : _runtimeLabelService.taskStatusLabel(activeTask.status),
      ),
      LongTaskRunMetaItemViewData(
        label: '任务链',
        value: chain?.subtitle ?? '尚未读到可用链路。',
      ),
    ];
    return LongTaskRunOverviewBlockViewData(
      title: '当前进度',
      summary: activeTask?.summary.trim().isNotEmpty == true
          ? activeTask!.summary.trim()
          : run.note.trim().isEmpty
          ? '当前运行会继续沿着已选任务链推进。'
          : run.note.trim(),
      entries: entries,
    );
  }

  LongTaskRunOverviewBlockViewData _currentActionOverviewBlock(
    RunInstance run, {
    required ProjectLongTaskStationItemSummary? activeTask,
    required ProjectLongTaskStationBlockerSummary? blocker,
  }) {
    final entries = <LongTaskRunMetaItemViewData>[
      LongTaskRunMetaItemViewData(
        label: '正在处理',
        value: activeTask?.title ?? '当前无活动任务',
      ),
      LongTaskRunMetaItemViewData(
        label: '下一步建议',
        value: blocker?.controlSummary.trim().isNotEmpty == true
            ? blocker!.controlSummary.trim()
            : '可以继续查看当前任务或直接推进。',
      ),
    ];
    if (activeTask?.relativePath.trim().isNotEmpty == true) {
      entries.add(
        LongTaskRunMetaItemViewData(
          label: '任务位置',
          value: activeTask!.relativePath,
        ),
      );
    }
    return LongTaskRunOverviewBlockViewData(
      title: '当前动作',
      summary: activeTask?.subtitle.trim().isNotEmpty == true
          ? activeTask!.subtitle.trim()
          : blocker?.note ?? '当前没有明显阻塞。',
      entries: entries,
      resources: activeTask == null
          ? const <LongTaskRunRelatedItemViewData>[]
          : <LongTaskRunRelatedItemViewData>[
              LongTaskRunRelatedItemViewData(
                title: '当前任务',
                subtitle: activeTask.subtitle,
                summary: activeTask.summary,
                relativePath: activeTask.relativePath,
                actionLabel: '查看当前任务',
              ),
            ],
    );
  }

  LongTaskRunOverviewBlockViewData _pendingActionOverviewBlock(
    ProjectLongTaskStationDetail? detail, {
    required ProjectLongTaskStationBlockerSummary? blocker,
  }) {
    final pendingUserAction = _pendingUserAction(detail, blocker: blocker);
    final entries = <LongTaskRunMetaItemViewData>[
      LongTaskRunMetaItemViewData(
        label: '是否需要你处理',
        value: pendingUserAction == null ? '当前无需额外确认' : '需要先处理后再继续',
      ),
      LongTaskRunMetaItemViewData(
        label: '处理原因',
        value: blocker?.note ?? '当前没有明显阻塞。',
      ),
    ];
    if (blocker?.detail.trim().isNotEmpty == true) {
      entries.add(
        LongTaskRunMetaItemViewData(
          label: '补充说明',
          value: blocker!.detail.trim(),
        ),
      );
    }
    return LongTaskRunOverviewBlockViewData(
      title: '需要你处理',
      summary:
          pendingUserAction?.summary ??
          (blocker?.controlSummary.trim().isNotEmpty == true
              ? blocker!.controlSummary.trim()
              : '当前没有待确认事项。'),
      entries: entries,
      resources: pendingUserAction == null
          ? const <LongTaskRunRelatedItemViewData>[]
          : <LongTaskRunRelatedItemViewData>[pendingUserAction],
    );
  }

  LongTaskRunOverviewBlockViewData _recentOutputOverviewBlock(
    ProjectLongTaskStationDetail? detail,
  ) {
    final preferredRecentOutput = _preferredRecentOutput(detail);
    final relatedItems = <LongTaskRunRelatedItemViewData>[
      ?preferredRecentOutput,
      ?_relatedItem(detail?.latestCheckpointReview, actionLabel: '查看检查点'),
      ?_relatedItem(detail?.latestReviewReport, actionLabel: '查看审稿结果'),
      ?_relatedItem(
        detail?.narrativeSummary?.delivery,
        actionLabel: '查看最近产物',
        titleOverride: _narrativeItemLabel('delivery'),
      ),
    ];
    final deduped = <LongTaskRunRelatedItemViewData>[];
    final seen = <String>{};
    for (final item in relatedItems) {
      final key = '${item.title}|${item.relativePath}|${item.actionLabel}';
      if (seen.add(key)) {
        deduped.add(item);
      }
    }
    return LongTaskRunOverviewBlockViewData(
      title: '最近产物',
      summary: deduped.isEmpty ? '当前还没有可回看的最近产物。' : '可以直接打开最近生成的正文、审稿或检查点结果。',
      entries: <LongTaskRunMetaItemViewData>[
        LongTaskRunMetaItemViewData(
          label: '最近可查看内容',
          value: deduped.isEmpty ? '暂无' : '${deduped.length} 项',
        ),
      ],
      resources: deduped,
    );
  }

  LongTaskRunRelatedItemViewData? _pendingUserAction(
    ProjectLongTaskStationDetail? detail, {
    required ProjectLongTaskStationBlockerSummary? blocker,
  }) {
    if (_isWaitingForUser(blocker?.code ?? '')) {
      if (detail?.narrativeSummary?.permissionItems.isNotEmpty == true) {
        return _relatedItem(
          detail!.narrativeSummary!.permissionItems.first,
          actionLabel: '等待确认',
        );
      }
      if (detail?.narrativeSummary?.informationPermissionItems.isNotEmpty ==
          true) {
        return _relatedItem(
          detail!.narrativeSummary!.informationPermissionItems.first,
          actionLabel: '等待确认',
        );
      }
      if (detail?.latestCheckpointReview != null) {
        return _relatedItem(
          detail!.latestCheckpointReview,
          actionLabel: '等待确认',
        );
      }
    }
    return null;
  }

  LongTaskRunRelatedItemViewData? _preferredRecentOutput(
    ProjectLongTaskStationDetail? detail,
  ) {
    if (detail?.narrativeSummary?.delivery != null) {
      return _relatedItem(
        detail!.narrativeSummary!.delivery,
        actionLabel: '查看最近产物',
        titleOverride: _narrativeItemLabel('delivery'),
      );
    }
    if (detail?.latestReviewReport != null) {
      return _relatedItem(detail!.latestReviewReport, actionLabel: '查看最近产物');
    }
    if (detail?.latestCheckpointReview != null) {
      return _relatedItem(
        detail!.latestCheckpointReview,
        actionLabel: '查看最近产物',
      );
    }
    return null;
  }

  String _resumeActionLabel({
    required RunInstance run,
    required ProjectLongTaskStationBlockerSummary? blocker,
    required bool canResume,
  }) {
    if (!canResume) {
      return '继续推进';
    }
    final blockerCode = blocker?.code ?? run.stopReason;
    if (_isFailureBlocker(blockerCode) || run.requiresManualAttention) {
      return '重试当前步骤';
    }
    return '继续推进';
  }

  String _pendingUserActionLabel(
    ProjectLongTaskStationBlockerSummary? blocker,
  ) {
    if (_isWaitingForUser(blocker?.code ?? '')) {
      return '等待确认';
    }
    return '查看待处理';
  }

  bool _isWaitingForUser(String code) {
    final normalized = code.trim();
    return normalized == 'waiting_user' ||
        normalized == 'waiting_user_checkpoint' ||
        normalized == 'waiting_gate';
  }

  bool _isFailureBlocker(String code) {
    final normalized = code.trim();
    return normalized == 'failed' ||
        normalized == 'step_failed' ||
        normalized == 'manual_attention';
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
    String? titleOverride,
  }) {
    if (item == null) {
      return null;
    }
    final summary = item.summary.trim().isEmpty ? item.subtitle : item.summary;
    return LongTaskRunRelatedItemViewData(
      title: titleOverride ?? item.title,
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

  List<LongTaskRunMetaItemViewData> _primaryMetadata(
    RunInstance run, {
    required ProjectLongTaskStationItemSummary? activeTask,
    required RuntimeBaseline? baseline,
  }) {
    return <LongTaskRunMetaItemViewData>[
      LongTaskRunMetaItemViewData(label: '项目路径', value: run.project.rootPath),
      LongTaskRunMetaItemViewData(
        label: '写作方式',
        value: _runtimeLabelService.runtimeModeLabel(run.modeId),
      ),
      if (baseline?.description.trim().isNotEmpty == true)
        LongTaskRunMetaItemViewData(
          label: '方式说明',
          value: baseline!.description,
        ),
      LongTaskRunMetaItemViewData(
        label: '当前任务',
        value:
            activeTask?.title ??
            (run.activeTaskTitle.trim().isEmpty
                ? '当前无活动任务'
                : run.activeTaskTitle.trim()),
      ),
      if (activeTask?.status.trim().isNotEmpty == true)
        LongTaskRunMetaItemViewData(
          label: '任务状态',
          value: _runtimeLabelService.taskStatusLabel(activeTask!.status),
        ),
      if (activeTask?.summary.trim().isNotEmpty == true)
        LongTaskRunMetaItemViewData(
          label: '任务摘要',
          value: activeTask!.summary.trim(),
        ),
    ];
  }

  List<LongTaskRunMetaItemViewData> _diagnosticMetadata(
    RunInstance run, {
    required RuntimeBaseline? baseline,
  }) {
    if (!_runtimeExposurePolicyService.exposesInternalRuntimeTerms(
      _exposureTier,
    )) {
      return const <LongTaskRunMetaItemViewData>[];
    }
    return <LongTaskRunMetaItemViewData>[
      if (baseline?.title.trim().isNotEmpty == true)
        LongTaskRunMetaItemViewData(label: '运行基准', value: baseline!.title),
      if (run.workflowStrategyId.trim().isNotEmpty)
        LongTaskRunMetaItemViewData(
          label: '工作流 ID',
          value: run.workflowStrategyId,
        ),
      if (run.modeId.trim().isNotEmpty)
        LongTaskRunMetaItemViewData(label: '模式 ID', value: run.modeId),
      LongTaskRunMetaItemViewData(
        label: '保存方式',
        value: _runtimeLabelService.storageStrategyLabel(
          run.project.storageStrategy,
        ),
      ),
    ];
  }

  String _narrativeSectionTitle() {
    return _exposureTier == RuntimeExposureTier.diagnostic ? '开放叙事摘要' : '运行摘要';
  }

  String _narrativeItemLabel(String key) {
    if (_exposureTier == RuntimeExposureTier.diagnostic) {
      switch (key) {
        case 'activation':
          return 'Activation';
        case 'delivery':
          return 'Delivery';
        case 'review':
          return 'Review';
        case 'continuity':
          return 'Continuity';
        case 'information':
          return 'Information';
      }
    }
    switch (key) {
      case 'activation':
        return '本轮上下文';
      case 'delivery':
        return '正文交付';
      case 'review':
        return '审查结果';
      case 'continuity':
        return '连续性记录';
      case 'information':
        return '资料与设定';
      default:
        return '运行摘要';
    }
  }

  String _narrativeProjectionSectionTitle() {
    return _exposureTier == RuntimeExposureTier.diagnostic ? '开放叙事投影' : '可读摘要';
  }

  String _informationProjectionSectionTitle() {
    return _exposureTier == RuntimeExposureTier.diagnostic ? '信息投影' : '资料摘要';
  }

  String _narrativePermissionSectionTitle() {
    return _exposureTier == RuntimeExposureTier.diagnostic ? '权限确认' : '需要你确认';
  }

  String _informationPermissionSectionTitle() {
    return _exposureTier == RuntimeExposureTier.diagnostic ? '信息待确认' : '资料待确认';
  }
}
