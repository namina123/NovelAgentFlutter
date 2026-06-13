import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_review_report_service.dart';
import '../storage/project_task_repository.dart';

class ProjectLongTaskCheckpointReviewTaskService {
  ProjectLongTaskCheckpointReviewTaskService({
    required ProjectReviewReportService reviewReportService,
    required ProjectTaskRepository taskRepository,
    LongTaskCheckpointReviewTaskSuggestionService? suggestionService,
  }) : _reviewReportService = reviewReportService,
       _taskRepository = taskRepository,
       _suggestionService =
           suggestionService ?? LongTaskCheckpointReviewTaskSuggestionService();

  final ProjectReviewReportService _reviewReportService;
  final ProjectTaskRepository _taskRepository;
  final LongTaskCheckpointReviewTaskSuggestionService _suggestionService;

  Future<JsonMap> createTasks({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap checkpointReview,
    bool rewireDependents = true,
  }) async {
    // 中文注释: adapter 层负责把纯建议转成真实任务文件，并过滤重复或无效来源路径。
    final suggestions = _suggestionService.buildSuggestions(
      task: task,
      checkpointReview: checkpointReview,
    );
    final existingTasks = await _taskRepository.listTasks(project);
    final existingKeys = _existingSuggestionKeys(existingTasks);
    final createdTasks = <JsonMap>[];
    final relatedTasks = <JsonMap>[];
    final changedPaths = <String>[];
    final skipped = <JsonMap>[];
    final sourceTaskId = ValueReaders.stringValue(task['id']).trim();
    for (final suggestion in suggestions) {
      final sourcePath = ValueReaders.stringValue(
        suggestion['source_path'],
      ).trim();
      if (sourcePath.isEmpty) {
        skipped.add(<String, Object?>{
          ...suggestion,
          'skip_reason': 'missing_source_path',
        });
        continue;
      }
      final content = await _taskRepository.readTextFile(project, sourcePath);
      if (content == null || content.trim().isEmpty) {
        skipped.add(<String, Object?>{
          ...suggestion,
          'skip_reason': 'source_not_ready',
        });
        continue;
      }
      final key = _suggestionKey(suggestion);
      if (existingKeys.contains(key)) {
        final existingTask = _existingTaskForSuggestion(
          existingTasks,
          suggestion,
        );
        if (existingTask.isNotEmpty) {
          final ensured = await _ensureDependsOnSourceTask(
            project,
            reviewTask: existingTask,
            sourceTaskId: sourceTaskId,
          );
          if (ensured.changed) {
            changedPaths.add(
              ValueReaders.stringValue(ensured.task['relative_path']),
            );
          }
          relatedTasks.add(ensured.task);
        }
        skipped.add(<String, Object?>{
          ...suggestion,
          'skip_reason': 'duplicate',
        });
        continue;
      }
      final created = await _reviewReportService.createReviewTask(
        project,
        suggestion,
      );
      final taskMap = ValueReaders.mapValue(created['task']);
      if (taskMap.isNotEmpty) {
        final ensured = await _ensureDependsOnSourceTask(
          project,
          reviewTask: taskMap,
          sourceTaskId: sourceTaskId,
        );
        createdTasks.add(ensured.task);
        relatedTasks.add(ensured.task);
        changedPaths.add(
          ValueReaders.stringValue(ensured.task['relative_path']),
        );
        existingKeys.add(key);
      }
    }
    final rewired = rewireDependents
        ? await _rewireDependents(
            project,
            predecessorTaskId: sourceTaskId,
            reviewTasks: relatedTasks,
          )
        : const <JsonMap>[];
    return <String, Object?>{
      'ok': true,
      'suggestions': suggestions,
      'tasks': relatedTasks,
      'created_tasks': createdTasks,
      'skipped': skipped,
      'rewired_tasks': rewired,
      'changed_paths': <Object?>[
        ...changedPaths,
        ...rewired.map(
          (item) => ValueReaders.stringValue(item['relative_path']),
        ),
      ],
    };
  }

  Set<String> _existingSuggestionKeys(List<JsonMap> tasks) {
    final result = <String>{};
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['task_type']) != 'review') {
        continue;
      }
      final metadata = ValueReaders.mapValue(task['metadata']);
      if (ValueReaders.stringValue(metadata['origin']) !=
          'checkpoint_review_suggestion') {
        continue;
      }
      final sourcePath = ValueReaders.stringValue(
        metadata['source_path'],
      ).trim();
      final reviewType = ValueReaders.stringValue(
        metadata['review_type'],
      ).trim();
      final checkpointReviewId = ValueReaders.stringValue(
        metadata['checkpoint_review_id'],
      ).trim();
      if (sourcePath.isEmpty ||
          reviewType.isEmpty ||
          checkpointReviewId.isEmpty) {
        continue;
      }
      result.add('$checkpointReviewId::$sourcePath::$reviewType');
    }
    return result;
  }

  String _suggestionKey(JsonMap suggestion) {
    final metadata = ValueReaders.mapValue(suggestion['metadata']);
    return '${ValueReaders.stringValue(metadata['checkpoint_review_id'])}'
        '::${ValueReaders.stringValue(suggestion['source_path'])}'
        '::${ValueReaders.stringValue(suggestion['review_type'])}';
  }

  JsonMap _existingTaskForSuggestion(List<JsonMap> tasks, JsonMap suggestion) {
    final expectedKey = _suggestionKey(suggestion);
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['task_type']) != 'review') {
        continue;
      }
      final metadata = ValueReaders.mapValue(task['metadata']);
      if (ValueReaders.stringValue(metadata['origin']) !=
          'checkpoint_review_suggestion') {
        continue;
      }
      final currentKey =
          '${ValueReaders.stringValue(metadata['checkpoint_review_id'])}'
          '::${ValueReaders.stringValue(metadata['source_path'])}'
          '::${ValueReaders.stringValue(metadata['review_type'])}';
      if (currentKey == expectedKey) {
        return task;
      }
    }
    return const <String, Object?>{};
  }

  Future<_TaskEnsureResult> _ensureDependsOnSourceTask(
    ProjectDescriptor project, {
    required JsonMap reviewTask,
    required String sourceTaskId,
  }) async {
    if (sourceTaskId.isEmpty) {
      return _TaskEnsureResult(task: reviewTask, changed: false);
    }
    final dependsOn = ValueReaders.stringList(reviewTask['depends_on']);
    if (dependsOn.contains(sourceTaskId)) {
      return _TaskEnsureResult(task: reviewTask, changed: false);
    }
    final nextDependsOn = <String>[
      sourceTaskId,
      ...dependsOn,
    ].where((item) => item.trim().isNotEmpty).toSet().toList(growable: false);
    final saved = await _taskRepository.saveTask(
      project,
      ValueReaders.deepCopyMap(reviewTask)..['depends_on'] = nextDependsOn,
    );
    return _TaskEnsureResult(task: saved, changed: true);
  }

  Future<List<JsonMap>> _rewireDependents(
    ProjectDescriptor project, {
    required String predecessorTaskId,
    required List<JsonMap> reviewTasks,
  }) async {
    if (predecessorTaskId.isEmpty || reviewTasks.isEmpty) {
      return const <JsonMap>[];
    }
    final reviewTaskIds = reviewTasks
        .map((task) => ValueReaders.stringValue(task['id']).trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (reviewTaskIds.isEmpty) {
      return const <JsonMap>[];
    }
    final reviewTaskIdSet = reviewTaskIds.toSet();
    final updated = <JsonMap>[];
    for (final task in await _taskRepository.listTasks(project)) {
      final taskId = ValueReaders.stringValue(task['id']).trim();
      if (taskId.isEmpty ||
          taskId == predecessorTaskId ||
          reviewTaskIdSet.contains(taskId)) {
        continue;
      }
      final dependsOn = ValueReaders.stringList(task['depends_on']);
      final alreadyGated = dependsOn.any(reviewTaskIdSet.contains);
      if (!dependsOn.contains(predecessorTaskId) && !alreadyGated) {
        continue;
      }
      final nextDependsOn = <String>[];
      for (final dependency in dependsOn) {
        if (dependency == predecessorTaskId) {
          for (final reviewTaskId in reviewTaskIds) {
            if (!nextDependsOn.contains(reviewTaskId)) {
              nextDependsOn.add(reviewTaskId);
            }
          }
          continue;
        }
        if (dependency.trim().isNotEmpty &&
            !nextDependsOn.contains(dependency)) {
          nextDependsOn.add(dependency);
        }
      }
      if (!dependsOn.contains(predecessorTaskId)) {
        for (final reviewTaskId in reviewTaskIds) {
          if (!nextDependsOn.contains(reviewTaskId)) {
            nextDependsOn.add(reviewTaskId);
          }
        }
      }
      final saved = await _taskRepository.saveTask(
        project,
        ValueReaders.deepCopyMap(task)..['depends_on'] = nextDependsOn,
      );
      updated.add(saved);
    }
    return List<JsonMap>.unmodifiable(updated);
  }
}

class _TaskEnsureResult {
  const _TaskEnsureResult({required this.task, required this.changed});

  final JsonMap task;
  final bool changed;
}
