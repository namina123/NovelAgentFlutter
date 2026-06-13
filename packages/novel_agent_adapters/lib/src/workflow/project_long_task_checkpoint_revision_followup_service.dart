import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_review_report_service.dart';
import '../storage/project_task_repository.dart';
import 'project_long_task_checkpoint_review_task_service.dart';
import 'project_long_task_review_repair_task_service.dart';

class ProjectLongTaskCheckpointRevisionFollowupService {
  ProjectLongTaskCheckpointRevisionFollowupService({
    required ProjectTaskRepository taskRepository,
    required ProjectLongTaskCheckpointReviewTaskService
    checkpointReviewTaskService,
    ProjectLongTaskReviewRepairTaskService? reviewRepairTaskService,
  }) : _taskRepository = taskRepository,
       _checkpointReviewTaskService = checkpointReviewTaskService,
       _reviewRepairTaskService =
           reviewRepairTaskService ??
           ProjectLongTaskReviewRepairTaskService(
             taskRepository: taskRepository,
             reviewReportService: ProjectReviewReportService(
               workspacePort: taskRepository.workspacePort,
               taskRepository: taskRepository,
             ),
           );

  final ProjectTaskRepository _taskRepository;
  final ProjectLongTaskCheckpointReviewTaskService _checkpointReviewTaskService;
  final ProjectLongTaskReviewRepairTaskService _reviewRepairTaskService;

  Future<JsonMap> requestFollowup({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap checkpointReview,
    required String checkpointReviewPath,
  }) async {
    // 中文注释: 普通 checkpoint 继续派生 follow-up review；review 型 checkpoint 则直接物化正式 repair 任务接管阻塞位。
    if (ValueReaders.stringValue(task['task_type']).trim() == 'review') {
      return _requestReviewRepairFollowup(
        project: project,
        task: task,
        checkpointReviewPath: checkpointReviewPath,
      );
    }
    final created = await _checkpointReviewTaskService.createTasks(
      project: project,
      task: task,
      checkpointReview: checkpointReview,
      rewireDependents: true,
    );
    final relatedTasks = await _relatedReviewTasks(
      project,
      checkpointReview: checkpointReview,
      checkpointReviewPath: checkpointReviewPath,
    );
    final updatedTask = await _saveRequestedState(
      project,
      task,
      checkpointReviewPath: checkpointReviewPath,
      relatedTasks: relatedTasks,
    );
    return <String, Object?>{
      'ok': true,
      'checkpoint_review_path': checkpointReviewPath,
      'task': updatedTask,
      'review_tasks': relatedTasks,
      'created_tasks': ValueReaders.mapList(created['tasks']),
      'skipped': ValueReaders.mapList(created['skipped']),
      'suggestions': ValueReaders.mapList(created['suggestions']),
      'changed_paths': _mergePaths(
        ValueReaders.stringList(created['changed_paths']),
        <String>[ValueReaders.stringValue(updatedTask['relative_path'])],
      ),
    };
  }

  Future<JsonMap> _requestReviewRepairFollowup({
    required ProjectDescriptor project,
    required JsonMap task,
    required String checkpointReviewPath,
  }) async {
    final created = await _reviewRepairTaskService.createTask(
      project: project,
      task: task,
    );
    if (!ValueReaders.boolValue(created['ok'])) {
      return <String, Object?>{
        'ok': false,
        'checkpoint_review_path': checkpointReviewPath,
        'error': ValueReaders.stringValue(
          created['error'],
          'Failed to create review repair task.',
        ),
        'changed_paths': ValueReaders.objectList(created['changed_paths']),
      };
    }
    final followupTask = ValueReaders.mapValue(created['task']);
    final followupTasks = followupTask.isEmpty
        ? const <JsonMap>[]
        : <JsonMap>[followupTask];
    final sourceTaskId = ValueReaders.stringValue(task['id']).trim();
    final rewired = await _rewireDependents(
      project,
      predecessorTaskId: sourceTaskId,
      followupTasks: followupTasks,
    );
    final transitioned = await _taskRepository.transitionTask(
      project,
      _taskSelector(task),
      TaskRuntimeConstants.statusSucceeded,
      note: '用户根据当前审稿结果请求返工，后续修订任务已接管。',
      extra: <String, Object?>{
        'requested_checkpoint_review_path': checkpointReviewPath,
      },
    );
    final updatedTask = await _saveRequestedState(
      project,
      ValueReaders.mapValue(transitioned['task']).isEmpty
          ? task
          : ValueReaders.mapValue(transitioned['task']),
      checkpointReviewPath: checkpointReviewPath,
      relatedTasks: followupTasks,
    );
    return <String, Object?>{
      'ok': true,
      'checkpoint_review_path': checkpointReviewPath,
      'task': updatedTask,
      'tasks': followupTasks,
      'followup_tasks': followupTasks,
      'review_tasks': const <Object?>[],
      'created_tasks': ValueReaders.boolValue(created['duplicated'])
          ? const <Object?>[]
          : ValueReaders.mapValue(created['task']).isEmpty
              ? const <Object?>[]
              : <Object?>[ValueReaders.mapValue(created['task'])],
      'rewired_tasks': rewired,
      'changed_paths': _mergePaths(
        _mergePaths(
          ValueReaders.stringList(created['changed_paths']),
          <String>[ValueReaders.stringValue(updatedTask['relative_path'])],
        ),
        rewired
            .map((item) => ValueReaders.stringValue(item['relative_path']))
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false),
      ),
    };
  }

  Future<List<JsonMap>> _relatedReviewTasks(
    ProjectDescriptor project, {
    required JsonMap checkpointReview,
    required String checkpointReviewPath,
  }) async {
    final checkpointReviewId = ValueReaders.stringValue(
      checkpointReview['id'],
    ).trim();
    final result = <JsonMap>[];
    for (final task in await _taskRepository.listTasks(project)) {
      if (ValueReaders.stringValue(task['task_type']) != 'review') {
        continue;
      }
      final metadata = ValueReaders.mapValue(task['metadata']);
      if (ValueReaders.stringValue(metadata['origin']) !=
          'checkpoint_review_suggestion') {
        continue;
      }
      final matchedById =
          checkpointReviewId.isNotEmpty &&
          ValueReaders.stringValue(metadata['checkpoint_review_id']) ==
              checkpointReviewId;
      final matchedByPath =
          ValueReaders.stringValue(metadata['checkpoint_review_path']) ==
          checkpointReviewPath;
      if (matchedById || matchedByPath) {
        result.add(task);
      }
    }
    result.sort((left, right) {
      final leftPriority = ValueReaders.intValue(
        ValueReaders.mapValue(left['metadata'])['priority_rank'],
        9999,
      );
      final rightPriority = ValueReaders.intValue(
        ValueReaders.mapValue(right['metadata'])['priority_rank'],
        9999,
      );
      final priorityCompare = leftPriority.compareTo(rightPriority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return ValueReaders.stringValue(
        left['relative_path'],
      ).compareTo(ValueReaders.stringValue(right['relative_path']));
    });
    return result;
  }

  Future<JsonMap> _saveRequestedState(
    ProjectDescriptor project,
    JsonMap task, {
    required String checkpointReviewPath,
    required List<JsonMap> relatedTasks,
  }) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    final requestedAt = DateTime.now().toIso8601String();
    final nextTask = ValueReaders.deepCopyMap(task)
      ..['metadata'] = <String, Object?>{
        ...metadata,
        'followup_request_state': 'requested',
        'followup_request_checkpoint_review_path': checkpointReviewPath,
        'followup_request_task_ids': relatedTasks
            .map((item) => ValueReaders.stringValue(item['id']))
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false),
        'followup_request_task_paths': relatedTasks
            .map((item) => ValueReaders.stringValue(item['relative_path']))
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false),
        'followup_requested_at': requestedAt,
      }
      ..['followup_request_state'] = 'requested'
      ..['followup_request_checkpoint_review_path'] = checkpointReviewPath
      ..['followup_requested_at'] = requestedAt;
    return _taskRepository.saveTask(project, nextTask);
  }

  Future<List<JsonMap>> _rewireDependents(
    ProjectDescriptor project, {
    required String predecessorTaskId,
    required List<JsonMap> followupTasks,
  }) async {
    if (predecessorTaskId.isEmpty || followupTasks.isEmpty) {
      return const <JsonMap>[];
    }
    final followupTaskIds = followupTasks
        .map((task) => ValueReaders.stringValue(task['id']).trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (followupTaskIds.isEmpty) {
      return const <JsonMap>[];
    }
    final followupTaskIdSet = followupTaskIds.toSet();
    final updated = <JsonMap>[];
    for (final task in await _taskRepository.listTasks(project)) {
      final taskId = ValueReaders.stringValue(task['id']).trim();
      if (taskId.isEmpty ||
          taskId == predecessorTaskId ||
          followupTaskIdSet.contains(taskId)) {
        continue;
      }
      final dependsOn = ValueReaders.stringList(task['depends_on']);
      if (!dependsOn.contains(predecessorTaskId)) {
        continue;
      }
      final nextDependsOn = <String>[];
      for (final dependency in dependsOn) {
        if (dependency == predecessorTaskId) {
          for (final followupTaskId in followupTaskIds) {
            if (!nextDependsOn.contains(followupTaskId)) {
              nextDependsOn.add(followupTaskId);
            }
          }
          continue;
        }
        if (dependency.trim().isNotEmpty &&
            !nextDependsOn.contains(dependency)) {
          nextDependsOn.add(dependency);
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

  JsonMap _taskSelector(JsonMap task) {
    return <String, Object?>{
      'relative_path': ValueReaders.stringValue(task['relative_path']),
      'task_id': ValueReaders.stringValue(task['id']),
    };
  }

  List<String> _mergePaths(List<String> left, List<String> right) {
    final result = <String>[...left];
    for (final item in right) {
      final clean = item.trim();
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }
}
