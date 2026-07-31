class LongTaskStationViewData {
  const LongTaskStationViewData({
    required this.title,
    required this.description,
    required this.scopeLabel,
    required this.statusMessage,
    required this.supervisorStatusLabel,
    required this.isLoading,
    required this.canFilterToCurrentProject,
    required this.isCurrentProjectFilterActive,
    required this.currentProjectFilterLabel,
    required this.totalCount,
    required this.activeCount,
    required this.pausedCount,
    required this.attentionCount,
    required this.resumableCount,
    required this.runs,
    required this.selectedRun,
  });

  final String title;
  final String description;
  final String scopeLabel;
  final String statusMessage;
  final String supervisorStatusLabel;
  final bool isLoading;
  final bool canFilterToCurrentProject;
  final bool isCurrentProjectFilterActive;
  final String currentProjectFilterLabel;
  final int totalCount;
  final int activeCount;
  final int pausedCount;
  final int attentionCount;
  final int resumableCount;
  final List<LongTaskRunEntryViewData> runs;
  final LongTaskRunDetailViewData? selectedRun;

  factory LongTaskStationViewData.initial() {
    return const LongTaskStationViewData(
      title: '长任务总站',
      description: '统一查看跨项目的长任务运行实例。',
      scopeLabel: '全部项目',
      statusMessage: '等待加载全局长任务运行实例。',
      supervisorStatusLabel: '监督器未启动',
      isLoading: false,
      canFilterToCurrentProject: false,
      isCurrentProjectFilterActive: false,
      currentProjectFilterLabel: '仅看当前项目',
      totalCount: 0,
      activeCount: 0,
      pausedCount: 0,
      attentionCount: 0,
      resumableCount: 0,
      runs: <LongTaskRunEntryViewData>[],
      selectedRun: null,
    );
  }
}

class LongTaskRunEntryViewData {
  const LongTaskRunEntryViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.projectPath,
    required this.statusLabel,
    required this.taskLabel,
    required this.recentActivityLabel,
    required this.badges,
    required this.requiresAttention,
    required this.isActive,
    required this.isSelected,
  });

  final String id;
  final String title;
  final String subtitle;
  final String projectPath;
  final String statusLabel;
  final String taskLabel;
  final String recentActivityLabel;
  final List<String> badges;
  final bool requiresAttention;
  final bool isActive;
  final bool isSelected;
}

class LongTaskRunDetailViewData {
  const LongTaskRunDetailViewData({
    required this.id,
    required this.projectTitle,
    required this.projectPath,
    required this.runtimeBaselineTitle,
    required this.runtimeBaselineDescription,
    required this.modeId,
    required this.workflowStrategyId,
    required this.statusLabel,
    required this.storageStrategyLabel,
    required this.runtimeModeLabel,
    required this.policyBadges,
    required this.activeTaskLabel,
    required this.activeTaskPath,
    required this.activeTaskStatusLabel,
    required this.activeTaskSummary,
    required this.note,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    required this.lastHeartbeatAtLabel,
    required this.startedAtLabel,
    required this.stoppedAtLabel,
    required this.detailStatusMessage,
    required this.isDetailLoading,
    required this.blockerLabel,
    required this.blockerNote,
    required this.blockerDetail,
    required this.blockerActionHint,
    required this.taskChainTitle,
    required this.taskChainSubtitle,
    required this.taskChainItems,
    required this.latestCheckpointReview,
    required this.latestReviewReport,
    required this.latestRepairTask,
    required this.narrativeActivation,
    required this.narrativeDelivery,
    required this.narrativeReview,
    required this.narrativeContinuity,
    required this.informationSummary,
    required this.narrativeProjectionItems,
    required this.narrativePermissionItems,
    required this.informationProjectionItems,
    required this.informationPermissionItems,
    required this.requiresManualAttention,
    required this.canPause,
    required this.canResume,
    required this.canStop,
    this.stopDiagnosis,
    this.expressionConstraintStatus,
    this.overviewBlocks = const <LongTaskRunOverviewBlockViewData>[],
    this.primaryMetadata = const <LongTaskRunMetaItemViewData>[],
    this.diagnosticMetadata = const <LongTaskRunMetaItemViewData>[],
    this.resumeActionLabel = '继续推进',
    this.attentionCalloutTitle = '',
    this.attentionCalloutSummary = '',
    this.pendingUserActionLabel = '等待确认',
    this.pendingUserAction,
    this.preferredRecentOutput,
    this.narrativeSectionTitle = '运行摘要',
    this.narrativeActivationLabel = '本轮上下文',
    this.narrativeDeliveryLabel = '正文交付',
    this.narrativeReviewLabel = '审稿结果',
    this.narrativeContinuityLabel = '连续性记录',
    this.informationSummaryLabel = '资料与设定',
    this.narrativeProjectionSectionTitle = '可读摘要',
    this.informationProjectionSectionTitle = '资料摘要',
    this.narrativePermissionSectionTitle = '权限确认',
    this.informationPermissionSectionTitle = '信息待确认',
    this.relatedResultsSectionTitle = '最近关联结果',
    this.diagnosticSectionTitle = '运行诊断',
  });

  final String id;
  final String projectTitle;
  final String projectPath;
  final String runtimeBaselineTitle;
  final String runtimeBaselineDescription;
  final String modeId;
  final String workflowStrategyId;
  final String statusLabel;
  final String storageStrategyLabel;
  final String runtimeModeLabel;
  final List<String> policyBadges;
  final String activeTaskLabel;
  final String activeTaskPath;
  final String activeTaskStatusLabel;
  final String activeTaskSummary;
  final String note;
  final String createdAtLabel;
  final String updatedAtLabel;
  final String lastHeartbeatAtLabel;
  final String startedAtLabel;
  final String stoppedAtLabel;
  final String detailStatusMessage;
  final bool isDetailLoading;
  final String blockerLabel;
  final String blockerNote;
  final String blockerDetail;
  final String blockerActionHint;
  final String taskChainTitle;
  final String taskChainSubtitle;
  final List<LongTaskRunChainItemViewData> taskChainItems;
  final LongTaskRunRelatedItemViewData? latestCheckpointReview;
  final LongTaskRunRelatedItemViewData? latestReviewReport;
  final LongTaskRunRelatedItemViewData? latestRepairTask;
  final LongTaskRunRelatedItemViewData? narrativeActivation;
  final LongTaskRunRelatedItemViewData? narrativeDelivery;
  final LongTaskRunRelatedItemViewData? narrativeReview;
  final LongTaskRunRelatedItemViewData? narrativeContinuity;
  final LongTaskRunRelatedItemViewData? informationSummary;
  final List<LongTaskRunRelatedItemViewData> narrativeProjectionItems;
  final List<LongTaskRunRelatedItemViewData> narrativePermissionItems;
  final List<LongTaskRunRelatedItemViewData> informationProjectionItems;
  final List<LongTaskRunRelatedItemViewData> informationPermissionItems;
  final bool requiresManualAttention;
  final bool canPause;
  final bool canResume;
  final bool canStop;
  final LongTaskRunStopDiagnosisViewData? stopDiagnosis;
  final LongTaskRunExpressionConstraintStatusViewData?
  expressionConstraintStatus;
  final List<LongTaskRunOverviewBlockViewData> overviewBlocks;
  final List<LongTaskRunMetaItemViewData> primaryMetadata;
  final List<LongTaskRunMetaItemViewData> diagnosticMetadata;
  final String resumeActionLabel;
  final String attentionCalloutTitle;
  final String attentionCalloutSummary;
  final String pendingUserActionLabel;
  final LongTaskRunRelatedItemViewData? pendingUserAction;
  final LongTaskRunRelatedItemViewData? preferredRecentOutput;
  final String narrativeSectionTitle;
  final String narrativeActivationLabel;
  final String narrativeDeliveryLabel;
  final String narrativeReviewLabel;
  final String narrativeContinuityLabel;
  final String informationSummaryLabel;
  final String narrativeProjectionSectionTitle;
  final String informationProjectionSectionTitle;
  final String narrativePermissionSectionTitle;
  final String informationPermissionSectionTitle;
  final String relatedResultsSectionTitle;
  final String diagnosticSectionTitle;
}

class LongTaskRunStopDiagnosisViewData {
  const LongTaskRunStopDiagnosisViewData({
    required this.code,
    required this.category,
    required this.label,
    this.summary = '',
    this.detail = '',
  });

  final String code;
  final String category;
  final String label;
  final String summary;
  final String detail;
}

class LongTaskRunExpressionConstraintStatusViewData {
  const LongTaskRunExpressionConstraintStatusViewData({
    required this.category,
    required this.label,
    this.summary = '',
    this.currentItem,
    this.recentItems = const <LongTaskRunRelatedItemViewData>[],
    this.blocksRepair = false,
    this.suggestsStrengthen = false,
    this.isDisabled = false,
  });

  final String category;
  final String label;
  final String summary;
  final LongTaskRunRelatedItemViewData? currentItem;
  final List<LongTaskRunRelatedItemViewData> recentItems;
  final bool blocksRepair;
  final bool suggestsStrengthen;
  final bool isDisabled;
}

class LongTaskRunOverviewBlockViewData {
  const LongTaskRunOverviewBlockViewData({
    required this.title,
    this.summary = '',
    this.entries = const <LongTaskRunMetaItemViewData>[],
    this.resources = const <LongTaskRunRelatedItemViewData>[],
  });

  final String title;
  final String summary;
  final List<LongTaskRunMetaItemViewData> entries;
  final List<LongTaskRunRelatedItemViewData> resources;
}

class LongTaskRunMetaItemViewData {
  const LongTaskRunMetaItemViewData({required this.label, required this.value});

  final String label;
  final String value;
}

class LongTaskRunChainItemViewData {
  const LongTaskRunChainItemViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.relativePath,
    required this.statusLabel,
    required this.isActive,
    required this.isNextRunnable,
    required this.isBlockingCheckpoint,
  });

  final String id;
  final String title;
  final String subtitle;
  final String relativePath;
  final String statusLabel;
  final bool isActive;
  final bool isNextRunnable;
  final bool isBlockingCheckpoint;
}

class LongTaskRunRelatedItemViewData {
  const LongTaskRunRelatedItemViewData({
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.relativePath,
    required this.actionLabel,
    this.pendingResearchRequestId = '',
  });

  final String title;
  final String subtitle;
  final String summary;
  final String relativePath;
  final String actionLabel;
  final String pendingResearchRequestId;

  bool get supportsPendingResearchActions =>
      pendingResearchRequestId.trim().isNotEmpty;
}
