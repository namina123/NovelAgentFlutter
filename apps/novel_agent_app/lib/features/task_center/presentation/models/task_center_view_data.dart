import 'task_center_action_group_view_data.dart';

class TaskCenterViewData {
  const TaskCenterViewData({
    required this.title,
    required this.intro,
    required this.help,
    required this.status,
    required this.runtimeBaselineTitle,
    required this.runtimeModeLabel,
    required this.runtimePolicyBadges,
    required this.tasks,
    required this.selectedTaskId,
    required this.detailBody,
    required this.queueSummary,
    required this.schedulerSummary,
    required this.chainMarkdown,
    required this.longTaskRuns,
    required this.taskQueueRuns,
    required this.selectedLongTaskRunPath,
    required this.selectedTaskQueueRunPath,
    required this.longTaskRunLog,
    required this.taskQueueRunLog,
    required this.resumeBriefBody,
    required this.modeOptions,
    required this.defaultMode,
    required this.defaultOutlinePath,
    required this.defaultSeedPrompt,
    required this.defaultChapterCount,
    required this.defaultCheckpointInterval,
    required this.defaultChapterLength,
    required this.actionGroups,
    required this.guidanceRevisitBody,
    this.longTaskCreationAvailable = false,
  });

  final String title;
  final String intro;
  final String help;
  final String status;
  final String runtimeBaselineTitle;
  final String runtimeModeLabel;
  final List<String> runtimePolicyBadges;
  final List<TaskCenterTaskItemViewData> tasks;
  final String selectedTaskId;
  final String detailBody;
  final String queueSummary;
  final String schedulerSummary;
  final String chainMarkdown;
  final List<TaskCenterRunItemViewData> longTaskRuns;
  final List<TaskCenterRunItemViewData> taskQueueRuns;
  final String selectedLongTaskRunPath;
  final String selectedTaskQueueRunPath;
  final String longTaskRunLog;
  final String taskQueueRunLog;
  final String resumeBriefBody;
  final List<TaskRuntimeModeOptionViewData> modeOptions;
  final String defaultMode;
  final String defaultOutlinePath;
  final String defaultSeedPrompt;
  final int defaultChapterCount;
  final int defaultCheckpointInterval;
  final TaskCenterChapterLengthConfigViewData defaultChapterLength;
  final List<TaskCenterActionGroupViewData> actionGroups;
  final String guidanceRevisitBody;
  final bool longTaskCreationAvailable;

  factory TaskCenterViewData.initial() {
    return const TaskCenterViewData(
      title: '长任务中心',
      intro: '',
      help: '',
      status: '',
      runtimeBaselineTitle: '',
      runtimeModeLabel: '',
      runtimePolicyBadges: <String>[],
      tasks: <TaskCenterTaskItemViewData>[],
      selectedTaskId: '',
      detailBody: '',
      queueSummary: '',
      schedulerSummary: '',
      chainMarkdown: '',
      longTaskRuns: <TaskCenterRunItemViewData>[],
      taskQueueRuns: <TaskCenterRunItemViewData>[],
      selectedLongTaskRunPath: '',
      selectedTaskQueueRunPath: '',
      longTaskRunLog: '',
      taskQueueRunLog: '',
      resumeBriefBody: '',
      modeOptions: <TaskRuntimeModeOptionViewData>[],
      defaultMode: '',
      defaultOutlinePath: '',
      defaultSeedPrompt: '',
      defaultChapterCount: 6,
      defaultCheckpointInterval: 3,
      defaultChapterLength: TaskCenterChapterLengthConfigViewData.fallback(),
      actionGroups: <TaskCenterActionGroupViewData>[],
      guidanceRevisitBody: '',
      longTaskCreationAvailable: false,
    );
  }
}

class TaskCenterRunItemViewData {
  const TaskCenterRunItemViewData({
    required this.relativePath,
    required this.title,
    required this.subtitle,
    this.statusLabel = '',
    this.phaseLabel = '',
    this.progressPercent = 0,
    this.activeTaskTitle = '',
    this.updatedAt = '',
    this.isWaitingUser = false,
    this.controlSummary = '',
    this.isSelected = false,
  });

  final String relativePath;
  final String title;
  final String subtitle;
  final String statusLabel;
  final String phaseLabel;
  final int progressPercent;
  final String activeTaskTitle;
  final String updatedAt;
  final bool isWaitingUser;
  final String controlSummary;
  final bool isSelected;
}

class TaskCenterTaskItemViewData {
  const TaskCenterTaskItemViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.relativePath,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String relativePath;
  final bool isSelected;
}

class TaskRuntimeModeOptionViewData {
  const TaskRuntimeModeOptionViewData({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class TaskWorkflowCreateRequestViewData {
  const TaskWorkflowCreateRequestViewData({
    required this.mode,
    required this.outlinePath,
    required this.seedPrompt,
    required this.chapterCount,
    required this.checkpointInterval,
    required this.chapterLength,
  });

  final String mode;
  final String outlinePath;
  final String seedPrompt;
  final int chapterCount;
  final int checkpointInterval;
  final TaskCenterChapterLengthConfigViewData chapterLength;
}

class TaskCenterChapterLengthConfigViewData {
  const TaskCenterChapterLengthConfigViewData({
    required this.enableChapterWordConstraints,
    required this.chapterWordTarget,
    required this.chapterWordMin,
    required this.chapterWordMax,
    required this.sampleChapterWordTarget,
    required this.sampleChapterWordMin,
    required this.sampleChapterWordMax,
  });

  final bool enableChapterWordConstraints;
  final int chapterWordTarget;
  final int chapterWordMin;
  final int chapterWordMax;
  final int sampleChapterWordTarget;
  final int sampleChapterWordMin;
  final int sampleChapterWordMax;

  const TaskCenterChapterLengthConfigViewData.fallback()
    : enableChapterWordConstraints = true,
      chapterWordTarget = 2000,
      chapterWordMin = 1600,
      chapterWordMax = 2600,
      sampleChapterWordTarget = 1800,
      sampleChapterWordMin = 1400,
      sampleChapterWordMax = 2400;
}
