import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/activity_time_label_service.dart';
import '../../../../shared/services/long_task_station_item_humanizer_service.dart';
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
    LongTaskStopDiagnosisProjectionService? stopDiagnosisProjectionService,
    LongTaskStationItemHumanizerService? itemHumanizerService,
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
       _stopDiagnosisProjectionService =
           stopDiagnosisProjectionService ??
           const LongTaskStopDiagnosisProjectionService(),
       _itemHumanizerService =
           itemHumanizerService ?? const LongTaskStationItemHumanizerService(),
       _exposureTier = exposureTier;

  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final LongTaskRunStateMachine _runStateMachine;
  final RuntimeLabelService _runtimeLabelService;
  final ActivityTimeLabelService _activityTimeLabelService;
  final RuntimeExposurePolicyService _runtimeExposurePolicyService;
  final LongTaskStopDiagnosisProjectionService _stopDiagnosisProjectionService;
  final LongTaskStationItemHumanizerService _itemHumanizerService;
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
    final stopDiagnosis = _stopDiagnosis(run, detail: detail, blocker: blocker);
    final expressionConstraintStatus = _expressionConstraintStatus(detail);
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
      stopDiagnosis: stopDiagnosis,
      expressionConstraintStatus: expressionConstraintStatus,
      overviewBlocks: _overviewBlocks(
        run,
        detail,
        activeTask: activeTask,
        blocker: blocker,
        chain: chain,
        stopDiagnosis: stopDiagnosis,
        expressionConstraintStatus: expressionConstraintStatus,
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
      attentionCalloutTitle: _attentionCalloutTitle(
        run: run,
        stopDiagnosis: stopDiagnosis,
        pendingUserAction: pendingUserAction,
      ),
      attentionCalloutSummary: _attentionCalloutSummary(
        run: run,
        blocker: blocker,
        stopDiagnosis: stopDiagnosis,
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
    required LongTaskRunStopDiagnosisViewData? stopDiagnosis,
    required LongTaskRunExpressionConstraintStatusViewData?
    expressionConstraintStatus,
  }) {
    return <LongTaskRunOverviewBlockViewData>[
      _progressOverviewBlock(
        run,
        activeTask: activeTask,
        chain: chain,
        stopDiagnosis: stopDiagnosis,
        expressionConstraintStatus: expressionConstraintStatus,
      ),
      _currentActionOverviewBlock(
        run,
        activeTask: activeTask,
        blocker: blocker,
        stopDiagnosis: stopDiagnosis,
        expressionConstraintStatus: expressionConstraintStatus,
      ),
      _pendingActionOverviewBlock(
        detail,
        blocker: blocker,
        expressionConstraintStatus: expressionConstraintStatus,
      ),
      _recentOutputOverviewBlock(
        detail,
        expressionConstraintStatus: expressionConstraintStatus,
      ),
    ];
  }

  LongTaskRunOverviewBlockViewData _progressOverviewBlock(
    RunInstance run, {
    required ProjectLongTaskStationItemSummary? activeTask,
    required ProjectLongTaskStationChainSummary? chain,
    required LongTaskRunStopDiagnosisViewData? stopDiagnosis,
    required LongTaskRunExpressionConstraintStatusViewData?
    expressionConstraintStatus,
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
      if (stopDiagnosis != null)
        LongTaskRunMetaItemViewData(label: '停点分类', value: stopDiagnosis.label),
      if (expressionConstraintStatus != null)
        LongTaskRunMetaItemViewData(
          label: '表达规则',
          value: expressionConstraintStatus.label,
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
    required LongTaskRunStopDiagnosisViewData? stopDiagnosis,
    required LongTaskRunExpressionConstraintStatusViewData?
    expressionConstraintStatus,
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
      if (stopDiagnosis != null)
        LongTaskRunMetaItemViewData(label: '当前停点', value: stopDiagnosis.label),
      if (expressionConstraintStatus != null)
        LongTaskRunMetaItemViewData(
          label: '表达规则状态',
          value: expressionConstraintStatus.label,
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
          : stopDiagnosis?.summary.trim().isNotEmpty == true
          ? stopDiagnosis!.summary.trim()
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
    required LongTaskRunExpressionConstraintStatusViewData?
    expressionConstraintStatus,
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
          (expressionConstraintStatus?.blocksRepair == true
              ? (expressionConstraintStatus!.summary.trim().isEmpty
                    ? expressionConstraintStatus.label
                    : expressionConstraintStatus.summary.trim())
              : (blocker?.controlSummary.trim().isNotEmpty == true
                    ? blocker!.controlSummary.trim()
                    : '当前没有待确认事项。')),
      entries: entries,
      resources: pendingUserAction == null
          ? const <LongTaskRunRelatedItemViewData>[]
          : <LongTaskRunRelatedItemViewData>[pendingUserAction],
    );
  }

  LongTaskRunOverviewBlockViewData _recentOutputOverviewBlock(
    ProjectLongTaskStationDetail? detail, {
    required LongTaskRunExpressionConstraintStatusViewData?
    expressionConstraintStatus,
  }) {
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
      ?expressionConstraintStatus?.currentItem,
      ...?expressionConstraintStatus?.recentItems,
    ];
    final deduped = <LongTaskRunRelatedItemViewData>[];
    final seen = <String>{};
    for (final item in relatedItems) {
      final key = _recentOutputDedupKey(item);
      if (seen.add(key)) {
        deduped.add(item);
      }
    }
    final dedicatedResultKeys = _dedicatedRelatedResultKeys(detail);
    final visibleResources = deduped
        .where(
          (item) => !dedicatedResultKeys.contains(_recentOutputDedupKey(item)),
        )
        .toList(growable: false);
    final onlyBottomResultsRemain =
        visibleResources.isEmpty && dedicatedResultKeys.isNotEmpty;
    return LongTaskRunOverviewBlockViewData(
      title: '最近产物',
      summary: visibleResources.isEmpty
          ? (onlyBottomResultsRemain
                ? '最近审稿、检查点或返工结果已整理到下方最近关联结果。'
                : '当前还没有可回看的最近产物。')
          : '可以直接打开最近生成的正文、审稿或检查点结果。',
      entries: <LongTaskRunMetaItemViewData>[
        LongTaskRunMetaItemViewData(
          label: '最近可查看内容',
          value: visibleResources.isEmpty
              ? (onlyBottomResultsRemain ? '请看下方结果区' : '暂无')
              : '${visibleResources.length} 项',
        ),
        if (expressionConstraintStatus != null)
          LongTaskRunMetaItemViewData(
            label: '表达规则摘要',
            value: expressionConstraintStatus.label,
          ),
      ],
      resources: visibleResources,
    );
  }

  LongTaskRunStopDiagnosisViewData? _stopDiagnosis(
    RunInstance run, {
    required ProjectLongTaskStationDetail? detail,
    required ProjectLongTaskStationBlockerSummary? blocker,
  }) {
    final projection = _stopDiagnosisProjectionService.project(
      stopOutcome: run.stopOutcome,
      recoveryState: run.recoveryState,
      legacyReason: blocker?.code ?? run.stopReason,
      runStatus: run.status.id,
      note: blocker?.note ?? run.note,
      reviewSummary: _firstNonBlank(<String>[
        detail?.latestReviewReport?.summary ?? '',
        detail?.latestCheckpointReview?.summary ?? '',
        detail?.narrativeSummary?.review?.summary ?? '',
      ]),
      informationSummary: _firstNonBlank(<String>[
        detail?.narrativeSummary?.information?.summary ?? '',
      ]),
      detail: blocker?.detail ?? '',
      metadata: <String, Object?>{'source': 'long_task_station_view_data'},
    );
    if (!projection.present) {
      return null;
    }
    return LongTaskRunStopDiagnosisViewData(
      code: projection.code,
      category: projection.category,
      label: projection.label,
      summary: projection.summary,
      detail: projection.detail,
    );
  }

  LongTaskRunExpressionConstraintStatusViewData? _expressionConstraintStatus(
    ProjectLongTaskStationDetail? detail,
  ) {
    final narrativeSummary = detail?.narrativeSummary;
    final current = narrativeSummary?.expressionConstraint;
    final recentItems =
        narrativeSummary?.recentExpressionConstraintItems
            .map(
              (item) => _relatedItem(
                item,
                actionLabel: '查看章节状态',
                titleOverride: item.title,
              ),
            )
            .whereType<LongTaskRunRelatedItemViewData>()
            .toList(growable: false) ??
        const <LongTaskRunRelatedItemViewData>[];
    if (current == null && recentItems.isEmpty) {
      return null;
    }
    final category = current?.status.trim().isNotEmpty == true
        ? current!.status.trim()
        : 'configured';
    final label = _expressionConstraintStatusLabel(category);
    final summary = current?.summary.trim().isNotEmpty == true
        ? current!.summary.trim()
        : (current?.subtitle ?? '');
    return LongTaskRunExpressionConstraintStatusViewData(
      category: category,
      label: label,
      summary: summary,
      currentItem: current == null
          ? null
          : _relatedItem(
              current,
              actionLabel: '查看表达规则',
              titleOverride: '表达规则状态',
            ),
      recentItems: recentItems,
      blocksRepair: category == 'repair_blocked',
      suggestsStrengthen: category == 'suggest_strengthen',
      isDisabled: category == 'disabled',
    );
  }

  String _expressionConstraintStatusLabel(String category) {
    switch (category.trim()) {
      case 'applied':
        return '表达规则：已应用';
      case 'suggest_strengthen':
        return '表达规则：建议加强';
      case 'repair_blocked':
        return '表达规则：已阻塞修订';
      case 'disabled':
        return '表达规则：已关闭';
      case 'skipped':
      case 'inactive':
        return '表达规则：未应用';
      case 'configured':
        return '表达规则：已配置';
      default:
        return '表达规则：状态待确认';
    }
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

  String _attentionCalloutTitle({
    required RunInstance run,
    required LongTaskRunStopDiagnosisViewData? stopDiagnosis,
    required LongTaskRunRelatedItemViewData? pendingUserAction,
  }) {
    if (pendingUserAction != null ||
        stopDiagnosis?.category == LongTaskStopOutcomeCategories.waitingUser) {
      return '当前运行停在待确认节点。';
    }
    if (run.requiresManualAttention) {
      return '当前运行停在待处理节点。';
    }
    return '这里有一条建议操作链。';
  }

  String _attentionCalloutSummary({
    required RunInstance run,
    required ProjectLongTaskStationBlockerSummary? blocker,
    required LongTaskRunStopDiagnosisViewData? stopDiagnosis,
  }) {
    final segments = <String>[];
    final stopSummary = stopDiagnosis?.summary.trim() ?? '';
    final blockerNote = blocker?.note.trim() ?? '';
    final blockerAction = blocker?.controlSummary.trim() ?? '';
    if (stopSummary.isNotEmpty) {
      segments.add(stopSummary);
    } else if (blockerNote.isNotEmpty && blockerNote != '当前没有明显阻塞。') {
      segments.add(blockerNote);
    }
    if (blockerAction.isNotEmpty) {
      segments.add(blockerAction);
    }
    if (segments.isEmpty) {
      return run.isActive
          ? '当前运行仍在推进，可以继续查看当前任务与最近结果。'
          : '可以从这里继续推进，或先查看当前任务与最近的审稿结果。';
    }
    return segments.join(' ');
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
        normalized == 'waiting_gate' ||
        normalized == 'waiting_user_choice' ||
        normalized == 'information_waiting_user' ||
        normalized == 'delivery_waiting_user_choice';
  }

  bool _isFailureBlocker(String code) {
    final normalized = code.trim();
    return normalized == 'failed' ||
        normalized == 'step_failed' ||
        normalized == 'manual_attention' ||
        normalized == 'delivery_manual_attention' ||
        normalized == 'content_quality_failed';
  }

  String _recentOutputDedupKey(LongTaskRunRelatedItemViewData item) {
    if (item.pendingResearchRequestId.trim().isNotEmpty) {
      return 'pending:${item.pendingResearchRequestId.trim()}';
    }
    if (item.relativePath.trim().isNotEmpty) {
      return 'path:${item.relativePath.trim()}';
    }
    return 'text:${item.title.trim()}|${item.subtitle.trim()}|${item.summary.trim()}';
  }

  Set<String> _dedicatedRelatedResultKeys(ProjectLongTaskStationDetail? detail) {
    return <String>{
      if (detail?.latestCheckpointReview != null)
        _recentOutputDedupKey(
          _relatedItem(detail!.latestCheckpointReview, actionLabel: '查看检查点')!,
        ),
      if (detail?.latestReviewReport != null)
        _recentOutputDedupKey(
          _relatedItem(detail!.latestReviewReport, actionLabel: '查看审稿结果')!,
        ),
      if (detail?.latestRepairTask != null)
        _recentOutputDedupKey(
          _relatedItem(detail!.latestRepairTask, actionLabel: '打开返工任务')!,
        ),
    };
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
    final subtitle = _relatedItemSubtitle(item);
    final summary = item.summary.trim().isEmpty ? subtitle : item.summary;
    return LongTaskRunRelatedItemViewData(
      title: _itemHumanizerService.title(item, titleOverride: titleOverride),
      subtitle: subtitle,
      summary: summary,
      relativePath: item.relativePath,
      actionLabel: actionLabel,
      pendingResearchRequestId: _pendingResearchRequestId(item),
    );
  }

  String _pendingResearchRequestId(ProjectLongTaskStationItemSummary item) {
    final relativePath = item.relativePath.replaceAll('\\', '/').trim();
    if (!relativePath.startsWith(
      '.novel_agent/information/research_requests/',
    )) {
      return '';
    }
    return item.id.trim();
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

  String _firstNonBlank(Iterable<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return '';
  }

  String _narrativeSectionTitle() {
    return _exposureTier == RuntimeExposureTier.diagnostic ? '开放叙事摘要' : '运行摘要';
  }

  String _narrativeItemLabel(String key) {
    if (_exposureTier == RuntimeExposureTier.diagnostic) {
      switch (key) {
        case 'activation':
          return '上下文激活';
        case 'delivery':
          return '交付结果';
        case 'review':
          return '审稿结论';
        case 'continuity':
          return '连续性变更';
        case 'information':
          return '资料状态';
      }
    }
    switch (key) {
      case 'activation':
        return '本轮上下文';
      case 'delivery':
        return '正文交付';
      case 'review':
        return '审稿结果';
      case 'continuity':
        return '连续性记录';
      case 'information':
        return '资料与设定';
      default:
        return '运行摘要';
    }
  }

  String _relatedItemSubtitle(ProjectLongTaskStationItemSummary item) {
    return _itemHumanizerService.subtitle(item);
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
