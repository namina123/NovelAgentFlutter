import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectWorkflowTaskSelectionService {
  ProjectWorkflowTaskSelectionService({
    required TaskSelectionService taskSelectionService,
    required LongTaskPathPolicyService longTaskPathPolicyService,
  }) : _taskSelectionService = taskSelectionService,
       _longTaskPathPolicyService = longTaskPathPolicyService;

  final TaskSelectionService _taskSelectionService;
  final LongTaskPathPolicyService _longTaskPathPolicyService;

  List<JsonMap> workflowScopedTasks(List<JsonMap> tasks) {
    // 中文注释: workflow 主链优先只看正式 plan 任务，避免普通遗留任务把长任务下一步选路带偏。
    final plannedTasks = tasks
        .where(belongsToWorkflowPlan)
        .toList(growable: false);
    if (plannedTasks.isEmpty) {
      return tasks;
    }
    final recognizedPlannedTasks = plannedTasks
        .where(isRecognizedWorkflowPlanTask)
        .toList(growable: false);
    return recognizedPlannedTasks.isNotEmpty
        ? recognizedPlannedTasks
        : plannedTasks;
  }

  List<JsonMap> workflowPrimaryTasks(List<JsonMap> tasks) {
    // 中文注释: checkpoint follow-up 仍然是正式任务，但默认不应卡住主链章节推进。
    final primaryTasks = tasks
        .where((task) => !isDeferredCheckpointFollowupTask(task))
        .toList(growable: false);
    return primaryTasks.isEmpty ? tasks : primaryTasks;
  }

  JsonMap nextRunnablePrimaryTask({
    required List<JsonMap> primaryTasks,
    required List<JsonMap> allTasks,
  }) {
    // 中文注释: 主链可运行任务先按任务选择器收口，再在候选集里寻找真正可执行的一项。
    if (primaryTasks.isEmpty) {
      return const <String, Object?>{};
    }
    final selectionPool = <JsonMap>[
      ...primaryTasks,
      ...allTasks.where(
        (task) =>
            !primaryTasks.contains(task) &&
            ValueReaders.stringValue(task['status']) ==
                TaskRuntimeConstants.statusSucceeded,
      ),
    ];
    return _taskSelectionService.nextRunnableTaskFromTasks(selectionPool);
  }

  JsonMap nextBlockingDeferredCheckpointFollowupTask(
    List<JsonMap> tasks, {
    required List<JsonMap> primaryTasks,
  }) {
    // 中文注释: 若主链任务被自动派生的 checkpoint follow-up 依赖卡住，队列需要先跑这些 follow-up 解锁主链。
    final deferredById = <String, JsonMap>{};
    for (final task in tasks) {
      if (!isDeferredCheckpointFollowupTask(task)) {
        continue;
      }
      final taskId = ValueReaders.stringValue(task['id']).trim();
      if (taskId.isEmpty) {
        continue;
      }
      deferredById[taskId] = task;
    }
    if (deferredById.isEmpty) {
      return const <String, Object?>{};
    }
    final blockingDeferredTasks = <JsonMap>[];
    final addedIds = <String>{};
    for (final task in primaryTasks) {
      final status = ValueReaders.stringValue(task['status']).trim();
      if (TaskRuntimeConstants.terminalStatuses.contains(status)) {
        continue;
      }
      for (final dependency in ValueReaders.stringList(task['depends_on'])) {
        final deferredTask = deferredById[dependency];
        if (deferredTask == null) {
          continue;
        }
        if (addedIds.add(dependency)) {
          blockingDeferredTasks.add(deferredTask);
        }
      }
    }
    if (blockingDeferredTasks.isEmpty) {
      return const <String, Object?>{};
    }
    final candidatePool = <JsonMap>[
      ...blockingDeferredTasks,
      ...tasks.where(
        (task) =>
            ValueReaders.stringValue(task['status']).trim() ==
            TaskRuntimeConstants.statusSucceeded,
      ),
    ];
    return _taskSelectionService.nextRunnableTaskFromTasks(candidatePool);
  }

  bool belongsToWorkflowPlan(JsonMap task) {
    // 中文注释: workflow plan 判断是正式调度边界，不应该散落到 runtime 私有 helper 里继续复制。
    final metadata = ValueReaders.mapValue(task['metadata']);
    if (ValueReaders.stringValue(metadata['plan_id']).trim().isNotEmpty) {
      return true;
    }
    if (ValueReaders.stringValue(metadata['generated_by']).trim().isNotEmpty) {
      return true;
    }
    if (ValueReaders.stringValue(metadata['origin']).trim().isNotEmpty) {
      return true;
    }
    final id = ValueReaders.stringValue(task['id']).trim();
    final relativePath = ValueReaders.stringValue(task['relative_path']).trim();
    return id.startsWith('plan_') || relativePath.contains('plan_');
  }

  bool isRecognizedWorkflowPlanTask(JsonMap task) {
    // 中文注释: 已识别的 workflow plan 任务需要有更稳定的路径或来源信息，避免把半成品草稿误当正式队列。
    final metadata = ValueReaders.mapValue(task['metadata']);
    if (ValueReaders.stringValue(metadata['origin']).trim().isNotEmpty) {
      return true;
    }
    final generatedBy = ValueReaders.stringValue(
      metadata['generated_by'],
    ).trim();
    if (generatedBy == 'LongTaskPlanner' || generatedBy == 'LongTaskRevision') {
      return true;
    }
    final planId = ValueReaders.stringValue(metadata['plan_id']).trim();
    if (planId.isEmpty) {
      return true;
    }
    return hasCanonicalWorkflowTaskPath(task);
  }

  bool hasCanonicalWorkflowTaskPath(JsonMap task) {
    // 中文注释: canonical task path 统一由路径策略服务判定，避免 runtime 自己发明另一套命名真相。
    final taskId = ValueReaders.stringValue(task['id']).trim();
    if (taskId.isEmpty) {
      return false;
    }
    final expectedPath =
        'tasks/${_longTaskPathPolicyService.safeId(taskId, fallbackPrefix: 'task')}.json';
    return ValueReaders.stringValue(
          task['relative_path'],
        ).trim().replaceAll('\\', '/') ==
        expectedPath;
  }

  bool isDeferredCheckpointFollowupTask(JsonMap task) {
    // 中文注释: 自动派生的 checkpoint follow-up 任务需要单独识别，避免它默认吞掉主链下一步选择权。
    return ValueReaders.stringValue(
          ValueReaders.mapValue(task['metadata'])['origin'],
        ).trim() ==
        'checkpoint_review_suggestion';
  }
}
