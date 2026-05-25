import 'task_center_action_group_view_data.dart';

class TaskCenterViewData {
  const TaskCenterViewData({
    required this.title,
    required this.intro,
    required this.help,
    required this.status,
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
    required this.modeOptions,
    required this.defaultMode,
    required this.defaultOutlinePath,
    required this.defaultSeedPrompt,
    required this.defaultChapterCount,
    required this.defaultCheckpointInterval,
    required this.actionGroups,
    required this.guidanceRevisitBody,
  });

  final String title;
  final String intro;
  final String help;
  final String status;
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
  final List<TaskRuntimeModeOptionViewData> modeOptions;
  final String defaultMode;
  final String defaultOutlinePath;
  final String defaultSeedPrompt;
  final int defaultChapterCount;
  final int defaultCheckpointInterval;
  final List<TaskCenterActionGroupViewData> actionGroups;
  final String guidanceRevisitBody;

  factory TaskCenterViewData.initial() {
    return const TaskCenterViewData(
      title: '长任务中心',
      intro: '',
      help: '',
      status: '',
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
      modeOptions: <TaskRuntimeModeOptionViewData>[],
      defaultMode: '',
      defaultOutlinePath: '',
      defaultSeedPrompt: '',
      defaultChapterCount: 6,
      defaultCheckpointInterval: 3,
      actionGroups: <TaskCenterActionGroupViewData>[],
      guidanceRevisitBody: '',
    );
  }
}

class TaskCenterRunItemViewData {
  const TaskCenterRunItemViewData({
    required this.relativePath,
    required this.title,
    required this.subtitle,
    this.isSelected = false,
  });

  final String relativePath;
  final String title;
  final String subtitle;
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
  });

  final String mode;
  final String outlinePath;
  final String seedPrompt;
  final int chapterCount;
  final int checkpointInterval;
}
