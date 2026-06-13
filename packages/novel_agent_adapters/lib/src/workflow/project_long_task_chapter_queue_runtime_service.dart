import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';

class ProjectLongTaskChapterQueueRuntimeService {
  ProjectLongTaskChapterQueueRuntimeService({
    required ProjectTaskRepository taskRepository,
    LongTaskModeService? modeService,
    LongTaskPathPolicyService? pathPolicyService,
    TaskDefinitionService? taskDefinitionService,
    BuildLongTaskRevisionPlanUseCase? buildLongTaskRevisionPlanUseCase,
    LongTaskRevisionApplyService? longTaskRevisionApplyService,
    LongTaskPlanMarkdownRenderer? planMarkdownRenderer,
    LongTaskPlanningArtifactPathService? planningArtifactPathService,
  }) : _taskRepository = taskRepository,
       _modeService = modeService ?? LongTaskModeService(),
       _pathPolicyService = pathPolicyService ?? LongTaskPathPolicyService(),
       _taskDefinitionService =
           taskDefinitionService ?? TaskDefinitionService(),
       _buildLongTaskRevisionPlanUseCase =
           buildLongTaskRevisionPlanUseCase ??
           BuildLongTaskRevisionPlanUseCase(
             revisionPlanService: LongTaskRevisionPlanService(
               dynamicTaskFactoryService: LongTaskDynamicTaskFactoryService(
                 modeService: modeService ?? LongTaskModeService(),
                 pathPolicyService:
                     pathPolicyService ?? LongTaskPathPolicyService(),
               ),
             ),
           ),
       _longTaskRevisionApplyService =
           longTaskRevisionApplyService ??
           LongTaskRevisionApplyService(
             runPathService: LongTaskRunPathService(
               pathPolicyService:
                   pathPolicyService ?? LongTaskPathPolicyService(),
             ),
             transitionService: TaskTransitionService(),
             taskDefinitionService:
                 taskDefinitionService ?? TaskDefinitionService(),
           ),
       _planMarkdownRenderer =
           planMarkdownRenderer ?? LongTaskPlanMarkdownRenderer(),
       _planningArtifactPathService =
           planningArtifactPathService ??
           const LongTaskPlanningArtifactPathService();

  final ProjectTaskRepository _taskRepository;
  final LongTaskModeService _modeService;
  final LongTaskPathPolicyService _pathPolicyService;
  final TaskDefinitionService _taskDefinitionService;
  final BuildLongTaskRevisionPlanUseCase _buildLongTaskRevisionPlanUseCase;
  final LongTaskRevisionApplyService _longTaskRevisionApplyService;
  final LongTaskPlanMarkdownRenderer _planMarkdownRenderer;
  final LongTaskPlanningArtifactPathService _planningArtifactPathService;

  JsonMap materializeInitialPlanWindow(
    String mode,
    JsonMap plan,
    List<JsonMap> tasks,
  ) {
    final cleanMode = _modeService.normalizeMode(mode);
    final materializedTasks =
        cleanMode == TaskRuntimeConstants.modeSeedToFullNovel
        ? _initialSeedToFullWindow(tasks)
        : tasks;
    final projectedPlan = _planWithMaterializedTasks(
      plan,
      materializedTasks,
      totalTaskCount: tasks.length,
    );
    return <String, Object?>{
      'tasks': materializedTasks,
      'plan': projectedPlan,
      'markdown': _planMarkdownRenderer.renderMarkdown(projectedPlan),
    };
  }

  Future<JsonMap> ensureMaterializedQueueForNextTask(
    ProjectDescriptor project,
    List<JsonMap> tasks,
  ) async {
    final queueTasks = tasks
        .where(_isMaterializedSeedQueueTask)
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
    if (queueTasks.isEmpty) {
      return _noopResult();
    }
    final planId = _singlePlanId(queueTasks);
    if (planId.isEmpty) {
      return _noopResult();
    }
    final planPath = 'tracking/long_task/$planId.plan.json';
    final plan = await _taskRepository.loadRecord(project, planPath);
    if (plan.isEmpty ||
        _modeService.normalizeMode(ValueReaders.stringValue(plan['mode'])) !=
            TaskRuntimeConstants.modeSeedToFullNovel) {
      return _noopResult();
    }
    if (!_canExtendSeedQueue(queueTasks)) {
      return _noopResult();
    }
    final planOptions = ValueReaders.mapValue(plan['options']);
    final chapterCount = ValueReaders.intValue(
      planOptions['chapter_count'],
      8,
    ).clamp(1, 200);
    final highestMaterializedChapter = _highestChapterNumber(queueTasks);
    if (highestMaterializedChapter >= chapterCount) {
      return _noopResult();
    }
    final checkpointInterval = ValueReaders.intValue(
      planOptions['checkpoint_interval'],
      3,
    ).clamp(0, 30);
    var nextTasks = ValueReaders.mapList(
      tasks,
    ).map(ValueReaders.deepCopyMap).toList(growable: true);
    final changedTasks = <JsonMap>[];
    final changedPaths = <String>[];
    final changedTaskIds = <String>[];
    final createdAt = DateTime.now().toIso8601String();
    final endChapter = checkpointInterval <= 0
        ? highestMaterializedChapter + 1
        : _nextCheckpointBoundary(
            startChapter: highestMaterializedChapter + 1,
            chapterCount: chapterCount,
            checkpointInterval: checkpointInterval,
          );
    var dependencyTaskId = _lastTaskId(nextTasks);
    for (
      var chapterNumber = highestMaterializedChapter + 1;
      chapterNumber <= endChapter;
      chapterNumber += 1
    ) {
      final appended = _applyRevision(
        currentTasks: nextTasks,
        command: 'append_chapter',
        record: _revisionRecord(plan, dependencyTaskId),
        arguments: _appendChapterArguments(
          tasks: nextTasks,
          options: planOptions,
          dependencyTaskId: dependencyTaskId,
          chapterNumber: chapterNumber,
        ),
        createdAt: createdAt,
      );
      if (!ValueReaders.boolValue(appended['ok'])) {
        return appended;
      }
      nextTasks = ValueReaders.mapList(
        appended['tasks'],
      ).map(ValueReaders.deepCopyMap).toList(growable: true);
      changedTasks.addAll(
        ValueReaders.mapList(
          appended['changed_tasks'],
        ).map(ValueReaders.deepCopyMap),
      );
      _mergeStrings(
        changedPaths,
        ValueReaders.stringList(appended['changed_paths']),
      );
      _mergeStrings(
        changedTaskIds,
        ValueReaders.stringList(appended['changed_task_ids']),
      );
      dependencyTaskId = _lastTaskId(nextTasks);
    }
    final shouldInsertCheckpoint =
        checkpointInterval > 0 &&
        endChapter < chapterCount &&
        endChapter % checkpointInterval == 0;
    if (shouldInsertCheckpoint) {
      final inserted = _applyRevision(
        currentTasks: nextTasks,
        command: 'insert_checkpoint',
        record: _revisionRecord(plan, dependencyTaskId),
        arguments: _appendCheckpointArguments(
          planId: ValueReaders.stringValue(plan['id']),
          tasks: nextTasks,
          dependencyTaskId: dependencyTaskId,
          chapterNumber: endChapter,
        ),
        createdAt: createdAt,
      );
      if (!ValueReaders.boolValue(inserted['ok'])) {
        return inserted;
      }
      nextTasks = ValueReaders.mapList(
        inserted['tasks'],
      ).map(ValueReaders.deepCopyMap).toList(growable: true);
      changedTasks.addAll(
        ValueReaders.mapList(
          inserted['changed_tasks'],
        ).map(ValueReaders.deepCopyMap),
      );
      _mergeStrings(
        changedPaths,
        ValueReaders.stringList(inserted['changed_paths']),
      );
      _mergeStrings(
        changedTaskIds,
        ValueReaders.stringList(inserted['changed_task_ids']),
      );
    }
    if (changedTasks.isEmpty) {
      return _noopResult();
    }
    await _taskRepository.saveTasks(project, changedTasks);
    final nextPlan = _planWithMaterializedTasks(
      plan,
      nextTasks,
      totalTaskCount: ValueReaders.intValue(
        plan['planned_task_count'],
        queueTasks.length,
      ),
    );
    final planMarkdownPath = 'tracking/long_task/$planId.plan.md';
    await _taskRepository.saveRecord(project, planPath, nextPlan);
    await _taskRepository.writeTextFile(
      project,
      planMarkdownPath,
      _planMarkdownRenderer.renderMarkdown(nextPlan),
    );
    _mergeStrings(changedPaths, <String>[planPath, planMarkdownPath]);
    return <String, Object?>{
      'ok': true,
      'materialized': true,
      'tasks': nextTasks,
      'changed_tasks': changedTasks,
      'changed_paths': changedPaths,
      'changed_task_ids': changedTaskIds,
    };
  }

  List<JsonMap> _initialSeedToFullWindow(List<JsonMap> tasks) {
    if (tasks.isEmpty) {
      return const <JsonMap>[];
    }
    final chapterIndex = tasks.indexWhere(
      (task) => ValueReaders.stringValue(task['task_type']) == 'chapter',
    );
    if (chapterIndex < 0) {
      return tasks;
    }
    final checkpointIndex = tasks.indexWhere(
      (task) =>
          ValueReaders.stringValue(task['task_type']) == 'checkpoint' &&
          ValueReaders.intValue(
                ValueReaders.mapValue(task['metadata'])['sort_order'],
              ) >
              ValueReaders.intValue(
                ValueReaders.mapValue(
                  tasks[chapterIndex]['metadata'],
                )['sort_order'],
              ),
    );
    final endIndex = checkpointIndex >= 0
        ? checkpointIndex + 1
        : chapterIndex + 1;
    return tasks
        .take(endIndex)
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
  }

  JsonMap _applyRevision({
    required List<JsonMap> currentTasks,
    required String command,
    required JsonMap record,
    required JsonMap arguments,
    required String createdAt,
  }) {
    final revision = _buildLongTaskRevisionPlanUseCase.execute(
      record,
      currentTasks,
      command,
      arguments: arguments,
      createdAt: createdAt,
    );
    if (!ValueReaders.boolValue(revision['ok'])) {
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          revision['error'],
          'Failed to build long task revision plan.',
        ),
      };
    }
    final applied = _longTaskRevisionApplyService.applyRevisionPlan(
      currentTasks,
      revision,
      createdAt: createdAt,
    );
    if (!ValueReaders.boolValue(applied['ok'])) {
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          applied['error'],
          'Failed to apply long task revision plan.',
        ),
      };
    }
    final changedTaskIds = ValueReaders.stringList(applied['changed_task_ids']);
    return <String, Object?>{
      ...applied,
      'changed_tasks': ValueReaders.mapList(applied['tasks'])
          .where(
            (task) =>
                changedTaskIds.contains(ValueReaders.stringValue(task['id'])),
          )
          .map(ValueReaders.deepCopyMap)
          .toList(growable: false),
    };
  }

  JsonMap _revisionRecord(JsonMap plan, String lastTaskId) {
    return <String, Object?>{
      'id': '${ValueReaders.stringValue(plan['id'])}_materialize',
      'plan_id': ValueReaders.stringValue(plan['id']),
      'mode': TaskRuntimeConstants.modeSeedToFullNovel,
      'last_task_id': lastTaskId,
    };
  }

  JsonMap _appendChapterArguments({
    required List<JsonMap> tasks,
    required JsonMap options,
    required String dependencyTaskId,
    required int chapterNumber,
  }) {
    final lastTask = _taskById(tasks, dependencyTaskId);
    final seedPrompt = ValueReaders.stringValue(
      options['seed_prompt'],
      ValueReaders.stringValue(options['outline_text']),
    ).trim();
    final runtimeBaselineId = ValueReaders.stringValue(
      options['runtime_baseline_id'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(lastTask['metadata'])['runtime_baseline_id'],
      ),
    ).trim();
    final persistentContextPaths = _persistentContextPaths(tasks, lastTask);
    return <String, Object?>{
      ...options,
      'runtime_baseline_id': runtimeBaselineId,
      'after_task_id': dependencyTaskId,
      'chapter_number': chapterNumber,
      'chapter': '第${chapterNumber.toString().padLeft(2, '0')}章',
      'task_title': '第${chapterNumber.toString().padLeft(2, '0')}章',
      'title': '第${chapterNumber.toString().padLeft(2, '0')}章',
      'goal': '按已确认规格、总纲和章纲生成本章正式正文。',
      'brief': seedPrompt.isEmpty
          ? '根据规划任务生成的作品规格、总纲和章纲写作。'
          : '根据规划任务生成的作品规格、总纲和章纲写作。初始种子：$seedPrompt',
      'stage': 'draft',
      'source_paths': <Object?>[
        LongTaskPlanningArtifactPathService.projectSpecPath,
        _planningArtifactPathService.storyOutlinePath(),
        _planningArtifactPathService.chapterPlanPath(),
        ...persistentContextPaths,
      ],
      'persistent_context_paths': persistentContextPaths,
      'tool_hint':
          '先读取项目规格、总纲、章纲、摘要和必要设定；如果规划尚未充分，请先调用 present_user_options 或写入大纲，而不是硬写正文。正文达到正式交付条件后，用 submit_chapter_delivery 收口。',
    };
  }

  JsonMap _appendCheckpointArguments({
    required String planId,
    required List<JsonMap> tasks,
    required String dependencyTaskId,
    required int chapterNumber,
  }) {
    final lastTask = _taskById(tasks, dependencyTaskId);
    final outputPaths = ValueReaders.stringList(lastTask['output_paths']);
    final persistentContextPaths = _persistentContextPaths(tasks, lastTask);
    return <String, Object?>{
      'id': '${planId}_checkpoint_${chapterNumber.toString().padLeft(3, '0')}',
      'after_task_id': dependencyTaskId,
      'title': '检查点：第 $chapterNumber 章后确认',
      'goal': '等待用户检查当前产物、调整方向或确认继续。',
      'brief': '这是自动物化的长任务检查点。',
      'source_paths': <Object?>[
        'summaries',
        ...outputPaths,
        ...persistentContextPaths,
      ],
      'output_paths': outputPaths,
      'persistent_context_paths': persistentContextPaths,
      'runtime_baseline_id': ValueReaders.stringValue(
        ValueReaders.mapValue(lastTask['metadata'])['runtime_baseline_id'],
      ),
    };
  }

  JsonMap _planWithMaterializedTasks(
    JsonMap plan,
    List<JsonMap> tasks, {
    required int totalTaskCount,
  }) {
    final next = ValueReaders.deepCopyMap(plan);
    final normalizedTasks = tasks
        .map(_taskDefinitionService.normalizeTask)
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
    next['created_tasks'] = normalizedTasks;
    next['planned_task_count'] = totalTaskCount;
    next['materialized_task_count'] = normalizedTasks.length;
    next['queue_materialization'] = 'incremental';
    next['updated_at'] = DateTime.now().toIso8601String();
    return next;
  }

  bool _canExtendSeedQueue(List<JsonMap> tasks) {
    final succeededCheckpointDependencyIds = <String>{};
    for (final task in tasks) {
      final taskId = ValueReaders.stringValue(task['id']).trim();
      if (taskId.isNotEmpty &&
          ValueReaders.stringValue(task['status']) ==
              TaskRuntimeConstants.statusSucceeded &&
          ValueReaders.stringValue(task['task_type']) == 'checkpoint') {
        succeededCheckpointDependencyIds.addAll(
          ValueReaders.stringList(task['depends_on']),
        );
      }
    }
    for (final task in tasks) {
      final status = ValueReaders.stringValue(task['status']);
      if (TaskRuntimeConstants.terminalStatuses.contains(status)) {
        continue;
      }
      if (!_isCheckpointCoveredSourceTask(
        task,
        succeededCheckpointDependencyIds,
      )) {
        return false;
      }
    }
    return true;
  }

  bool _isCheckpointCoveredSourceTask(
    JsonMap task,
    Set<String> succeededCheckpointDependencyIds,
  ) {
    final taskId = ValueReaders.stringValue(task['id']).trim();
    if (taskId.isEmpty) {
      return false;
    }
    final taskType = ValueReaders.stringValue(task['task_type']).trim();
    if (!<String>{'planning', 'chapter'}.contains(taskType)) {
      return false;
    }
    return succeededCheckpointDependencyIds.contains(taskId);
  }

  String _singlePlanId(List<JsonMap> tasks) {
    final planIds = <String>{};
    for (final task in tasks) {
      if (_modeService.normalizeMode(ValueReaders.stringValue(task['mode'])) !=
          TaskRuntimeConstants.modeSeedToFullNovel) {
        return '';
      }
      final planId = ValueReaders.stringValue(
        ValueReaders.mapValue(task['metadata'])['plan_id'],
      ).trim();
      if (planId.isNotEmpty) {
        planIds.add(planId);
      }
    }
    return planIds.length == 1 ? planIds.first : '';
  }

  int _highestChapterNumber(List<JsonMap> tasks) {
    var result = 0;
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['task_type']) != 'chapter') {
        continue;
      }
      final chapter = ValueReaders.stringValue(task['chapter']);
      final match = RegExp(r'(\d+)').firstMatch(chapter);
      final number = int.tryParse(match?.group(1) ?? '') ?? 0;
      if (number > result) {
        result = number;
      }
    }
    return result;
  }

  int _nextCheckpointBoundary({
    required int startChapter,
    required int chapterCount,
    required int checkpointInterval,
  }) {
    for (
      var chapterNumber = startChapter;
      chapterNumber <= chapterCount;
      chapterNumber += 1
    ) {
      if (chapterNumber % checkpointInterval == 0) {
        return chapterNumber;
      }
    }
    return chapterCount;
  }

  String _lastTaskId(List<JsonMap> tasks) {
    if (tasks.isEmpty) {
      return '';
    }
    final sorted = tasks.map(ValueReaders.deepCopyMap).toList(growable: false)
      ..sort((left, right) {
        final leftOrder = ValueReaders.intValue(
          ValueReaders.mapValue(left['metadata'])['sort_order'],
        );
        final rightOrder = ValueReaders.intValue(
          ValueReaders.mapValue(right['metadata'])['sort_order'],
        );
        if (leftOrder != rightOrder) {
          return leftOrder.compareTo(rightOrder);
        }
        return ValueReaders.stringValue(
          left['id'],
        ).compareTo(ValueReaders.stringValue(right['id']));
      });
    return ValueReaders.stringValue(sorted.last['id']);
  }

  JsonMap _taskById(List<JsonMap> tasks, String taskId) {
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['id']) == taskId) {
        return task;
      }
    }
    return const <String, Object?>{};
  }

  List<String> _persistentContextPaths(List<JsonMap> tasks, JsonMap lastTask) {
    final explicit = _pathPolicyService.stringList(
      ValueReaders.mapValue(lastTask['metadata'])['persistent_context_paths'],
    );
    if (explicit.isNotEmpty) {
      return explicit;
    }
    for (final task in tasks) {
      final metadata = ValueReaders.mapValue(task['metadata']);
      final inherited = _pathPolicyService.stringList(
        metadata['persistent_context_paths'],
      );
      if (inherited.isNotEmpty) {
        return inherited;
      }
    }
    return const <String>[];
  }

  void _mergeStrings(List<String> target, List<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty && !target.contains(clean)) {
        target.add(clean);
      }
    }
  }

  bool _isDeferredCheckpointFollowupTask(JsonMap task) {
    if (ValueReaders.stringValue(task['task_type']) != 'review') {
      return false;
    }
    return ValueReaders.stringValue(
          ValueReaders.mapValue(task['metadata'])['origin'],
        ).trim() ==
        'checkpoint_review_suggestion';
  }

  bool _isMaterializedSeedQueueTask(JsonMap task) {
    if (_isDeferredCheckpointFollowupTask(task)) {
      return false;
    }
    final taskId = ValueReaders.stringValue(task['id']).trim();
    if (!taskId.startsWith('plan_')) {
      return false;
    }
    final expectedPath =
        'tasks/${_pathPolicyService.safeId(taskId, fallbackPrefix: 'task')}.json';
    final relativePath = ValueReaders.stringValue(
      task['relative_path'],
    ).trim().replaceAll('\\', '/');
    return relativePath == expectedPath;
  }

  JsonMap _noopResult() {
    return const <String, Object?>{
      'ok': true,
      'materialized': false,
      'tasks': <Object?>[],
      'changed_tasks': <Object?>[],
      'changed_paths': <Object?>[],
      'changed_task_ids': <Object?>[],
    };
  }
}
