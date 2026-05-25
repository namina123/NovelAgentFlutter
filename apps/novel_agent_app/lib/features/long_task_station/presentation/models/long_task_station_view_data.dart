class LongTaskStationViewData {
  const LongTaskStationViewData({
    required this.title,
    required this.description,
    required this.statusMessage,
    required this.supervisorStatusLabel,
    required this.isLoading,
    required this.totalCount,
    required this.activeCount,
    required this.pausedCount,
    required this.attentionCount,
    required this.runs,
    required this.selectedRun,
  });

  final String title;
  final String description;
  final String statusMessage;
  final String supervisorStatusLabel;
  final bool isLoading;
  final int totalCount;
  final int activeCount;
  final int pausedCount;
  final int attentionCount;
  final List<LongTaskRunEntryViewData> runs;
  final LongTaskRunDetailViewData? selectedRun;

  factory LongTaskStationViewData.initial() {
    return const LongTaskStationViewData(
      title: '长任务总站',
      description: '统一查看跨项目的长任务运行实例。',
      statusMessage: '等待加载全局长任务运行实例。',
      supervisorStatusLabel: '监督器未启动',
      isLoading: false,
      totalCount: 0,
      activeCount: 0,
      pausedCount: 0,
      attentionCount: 0,
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
    required this.statusLabel,
    required this.taskLabel,
    required this.isSelected,
  });

  final String id;
  final String title;
  final String subtitle;
  final String statusLabel;
  final String taskLabel;
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
    required this.activeTaskLabel,
    required this.note,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    required this.lastHeartbeatAtLabel,
    required this.startedAtLabel,
    required this.stoppedAtLabel,
    required this.canPause,
    required this.canResume,
    required this.canStop,
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
  final String activeTaskLabel;
  final String note;
  final String createdAtLabel;
  final String updatedAtLabel;
  final String lastHeartbeatAtLabel;
  final String startedAtLabel;
  final String stoppedAtLabel;
  final bool canPause;
  final bool canResume;
  final bool canStop;
}
